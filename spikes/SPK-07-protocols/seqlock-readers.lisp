;;;; SPK-07, Fase 0: due reader, due slot e un writer seriale, memoria SC.
;;; REQ: REQ-IDX-003 REQ-CON-001 REQ-VAL-001
;;;; Metodo preregistrato in metodo-seqlock-readers.md; nessun codice del motore.
(defpackage :arcdocdb.spk07.seqlock-readers
  (:use :cl)
  (:export :check))
(in-package :arcdocdb.spk07.seqlock-readers)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(define-condition state-budget-exhausted (error)
  ((data :initarg :data :reader budget-data))
  (:report (lambda (condition stream)
             (let ((data (budget-data condition)))
               (format stream "Tetto raggiunto: ~D stati (limite ~D), modello ~S."
                       (getf data :states-discovered) (getf data :state-limit)
                       (getf data :model))))))

;;; Stato = (pc-writer slot0 slot1 storia reader0 reader1).
;;; Slot = (seq version location); location = (segmento offset lunghezza chiave).
;;; Reader = (fase tentativo seq1 version location seq2 prefisso risposta).
;;; Fasi 0=seq1, 1=version, 2=location, 3=seq2, 4=valida, 5=fallback, 6=concluso.
;;; Risposta = (generazione version location prefisso meccanismo).
;;; Ogni lista inserita nel grafo resta immutabile, incluse le sue sotto-liste.

(defun replace-at (items index value)
  (let ((next (copy-list items)))
    (setf (nth index next) value)
    next))

(defun slot-at (state slot) (nth (1+ slot) state))
(defun reader-at (state reader) (nth (+ 4 reader) state))
(defun replace-slot (state slot value) (replace-at state (1+ slot) value))
(defun replace-reader (state reader value) (replace-at state (+ 4 reader) value))

(defun initial-state ()
  (list 0 '(0 11 (:seg-a 13 9 :alpha)) '(0 29 (:seg-b 21 7 :beta)) nil
        '(0 1 nil nil nil nil nil nil) '(0 1 nil nil nil nil nil nil)))

(defun writer-fields (slot)
  "Dati fisici della scrittura, separati dai record logici dell'oracolo."
  (ecase slot
    (0 '(47 (:seg-c 4 15 :gamma)))
    (1 '(83 (:seg-d 31 19 :delta)))))

(defun event-for-slot (slot) (ecase slot (0 :update-0) (1 :update-1)))

(defun logical-record (slot history)
  "Oracolo: seleziona record dichiarati della storia, senza leggere gli slot."
  (let ((generation 0) (version nil) (segment nil) (offset nil) (size nil) (key nil))
    (ecase slot
      (0 (setf version 11 segment :seg-a offset 13 size 9 key :alpha))
      (1 (setf version 29 segment :seg-b offset 21 size 7 key :beta)))
    (dolist (event history)
      (case event
        (:update-0
         (when (= slot 0)
           (setf generation 1 version 47 segment :seg-c offset 4 size 15 key :gamma)))
        (:update-1
         (when (= slot 1)
           (setf generation 1 version 83 segment :seg-d offset 31 size 19 key :delta)))
        (otherwise (error "Evento logico sconosciuto: ~S" event))))
    (list :generation generation :version version :segment segment
          :offset offset :length size :key key)))

(defun logical-tuple (slot history)
  (let ((record (logical-record slot history)))
    (list (getf record :generation) (getf record :version)
          (list (getf record :segment) (getf record :offset)
                (getf record :length) (getf record :key)))))

(defun logical-answer (slot history query)
  (let ((record (logical-record slot history)))
    (if (eq query (getf record :key))
        (list :hit (getf record :version) (getf record :segment)
              (getf record :offset) (getf record :length))
        '(:miss))))

(defun tuple-answer (tuple query)
  "Decodifica del modello; non consulta la storia o l'oracolo."
  (destructuring-bind (generation version location) tuple
    (declare (ignore generation))
    (destructuring-bind (segment offset size key) location
      (if (eq query key) (list :hit version segment offset size) '(:miss)))))

(defun queries (slot)
  (ecase slot (0 '(:alpha :gamma :absent)) (1 '(:beta :delta :absent))))

(defun reject-reader (reader)
  "Un solo retry; il secondo rifiuto crea una richiesta di fallback."
  (ecase (second reader)
    (1 '(0 2 nil nil nil nil nil nil))
    (2 '(5 2 nil nil nil nil nil nil))))

(defun writer-edge (state order mutant)
  (let ((pc (first state)))
    (when (< pc 8)
      (let* ((slot (nth (floor pc 4) order)) (phase (mod pc 4))
             (physical (copy-list (slot-at state slot)))
             (fields (writer-fields slot)) (next (replace-at state 0 (1+ pc))))
        (ecase phase
          (0 (unless (equal mutant (list :skip-odd slot))
               (setf (first physical) 1)))
          (1 (setf (second physical) (first fields)))
          (2 (setf (third physical) (second fields)))
          (3 (setf (first physical) 2
                   next (replace-at next 3
                                    (append (fourth state) (list (event-for-slot slot)))))))
        (cons (list :actor :writer :slot slot :phase phase :pc pc
                    :odd-skipped (and (= phase 0) (equal mutant (list :skip-odd slot)))
                    :event (nth phase '(:odd :version :location :publish)))
              (replace-slot next slot physical))))))

(defun reader-edge (state targets reader-id mutant)
  (let* ((reader (reader-at state reader-id)) (phase (first reader))
         (attempt (second reader)) (slot (nth reader-id targets))
         (physical (slot-at state slot)) (next-reader (copy-list reader))
         (event nil) (reason nil))
    (when (< phase 5)
      (ecase phase
        (0 (if (oddp (first physical))
               (setf next-reader (reject-reader reader) reason :odd)
               (setf (first next-reader) 1 (third next-reader) (first physical))))
        (1 (setf (first next-reader) 2 (fourth next-reader) (second physical)))
        (2 (setf (first next-reader) 3 (fifth next-reader) (third physical)))
        (3 (setf (first next-reader) 4 (sixth next-reader) (first physical)
                 (seventh next-reader) (fourth state)))
        (4 (if (or (equal mutant (list :skip-validation reader-id))
                   (and (evenp (third reader)) (= (third reader) (sixth reader))))
               (setf next-reader
                     (list 6 attempt nil nil nil nil nil
                           (list (/ (third reader) 2) (fourth reader) (fifth reader)
                                 (seventh reader) :optimistic)))
               (setf next-reader (reject-reader reader) reason :changed-seq))))
      (setf event (if reason
                      (if (= attempt 1) :retry :fallback-request)
                      (nth phase '(:seq-first :version :location :seq-last :accept))))
      (cons (list :actor :reader :reader reader-id :slot slot :phase phase
                  :attempt attempt :event event :reason reason
                  :validation-skipped (and (= phase 4)
                                           (equal mutant (list :skip-validation reader-id))))
            (replace-reader state reader-id next-reader)))))

(defun fallback-edge (state targets reader-id)
  "La copia completa è un servizio del writer, solo fra aggiornamenti."
  (let ((reader (reader-at state reader-id)))
    (when (and (= (first reader) 5) (zerop (mod (first state) 4)))
      (let* ((slot (nth reader-id targets)) (physical (slot-at state slot))
             (reply (list (/ (first physical) 2) (second physical) (third physical)
                          (fourth state) :writer)))
        (cons (list :actor :writer :event :fallback-service :reader reader-id
                    :slot slot :pc (first state) :tuple (subseq reply 0 3))
              (replace-reader state reader-id (list 6 2 nil nil nil nil nil reply)))))))

(defun successors (state order targets mutant)
  "Ordine deterministico degli archi, con scelta esplicita di tutti gli attori."
  (remove nil (list (writer-edge state order mutant)
                    (reader-edge state targets 0 mutant)
                    (reader-edge state targets 1 mutant)
                    (fallback-edge state targets 0)
                    (fallback-edge state targets 1))))

(defun history-prefix-p (prefix history)
  (and (<= (length prefix) (length history))
       (equal prefix (subseq history 0 (length prefix)))))

(defun safety-violation (state order targets &optional observe)
  "Oracolo in ogni stato; una risposta è confrontata al suo punto registrato."
  (let* ((pc (first state)) (history (fourth state))
         (expected-history (loop for slot in order for index from 1
                                 when (<= (* 4 index) pc) collect (event-for-slot slot))))
    (unless (and (integerp pc) (<= 0 pc 8) (equal history expected-history))
      (return-from safety-violation (list :kind :invalid-logical-prefix :state state)))
    (dotimes (slot 2)
      (let ((physical (slot-at state slot)))
        (unless (and (member (first physical) '(0 1 2))
                     (member (second physical) '(11 29 47 83))
                     (member (third physical)
                             '((:seg-a 13 9 :alpha) (:seg-b 21 7 :beta)
                               (:seg-c 4 15 :gamma) (:seg-d 31 19 :delta)) :test #'equal))
          (return-from safety-violation (list :kind :invalid-physical-domain :slot slot)))
        ;; Solo lo slot attualmente in aggiornamento può essere intermedio.
        (unless (and (< pc 8) (not (zerop (mod pc 4)))
                     (= slot (nth (floor pc 4) order)))
          (let ((expected (logical-tuple slot history)))
            (unless (equal physical (cons (* 2 (first expected)) (rest expected)))
              (return-from safety-violation
                (list :kind :incoherent-stable-slot :slot slot
                      :observed physical :expected expected)))))))
    (dotimes (reader-id 2)
      (let* ((reader (reader-at state reader-id)) (phase (first reader))
             (attempt (second reader)) (reply (eighth reader))
             (slot (nth reader-id targets)))
        (unless (and (integerp phase) (<= 0 phase 6) (member attempt '(1 2))
                     (eql (= phase 6) (not (null reply)))
                     (or (/= phase 5) (= attempt 2)))
          (return-from safety-violation
            (list :kind :invalid-reader-domain :reader reader-id :state reader)))
        (when reply
          (when observe (funcall observe :tuple reader-id))
          (let* ((prefix (fourth reply)) (observed (subseq reply 0 3))
                 (expected (logical-tuple slot prefix)))
            (unless (and (history-prefix-p prefix history)
                         (member (fifth reply) '(:optimistic :writer))
                         (or (not (eq (fifth reply) :writer)) (= attempt 2)))
              (return-from safety-violation
                (list :kind :invalid-response-certificate :reader reader-id :reply reply)))
            (unless (equal observed expected)
              (return-from safety-violation
                (list :kind :accepted-tuple-mismatch :reader reader-id :slot slot
                      :mechanism (fifth reply) :attempt attempt :history-at-read prefix
                      :current-history history :observed observed :expected expected)))
            (dolist (query (queries slot))
              (when observe (funcall observe :query reader-id))
              (let ((answer (tuple-answer observed query))
                    (expected-answer (logical-answer slot prefix query)))
                (unless (equal answer expected-answer)
                  (return-from safety-violation
                    (list :kind :lookup-mismatch :reader reader-id :slot slot
                          :query query :observed answer :expected expected-answer)))))))))
    nil))

(defun state-rank (state)
  (+ (first state)
     (loop for reader-id below 2 for reader = (reader-at state reader-id)
           sum (+ (* 8 (1- (second reader))) (first reader)))))

(defun terminal-p (state)
  (and (= (first state) 8) (= (first (reader-at state 0)) 6)
       (= (first (reader-at state 1)) 6)))

(defun positive-keys (state targets)
  "Proprietà raggiunte, distinte dalla safety e dalla fairness."
  (let ((keys nil))
    (dotimes (reader-id 2)
      (let* ((reader (reader-at state reader-id)) (phase (first reader))
             (attempt (second reader)) (reply (eighth reader))
             (slot (nth reader-id targets)))
        (when (= attempt 2) (push (list :retry reader-id) keys))
        (when (= phase 5) (push (list :fallback-request reader-id) keys))
        (when reply
          (push (list :generation reader-id (first reply)) keys)
          (when (eq (fifth reply) :writer) (push (list :fallback-completed reader-id) keys))
          (when (and (= attempt 2) (eq (fifth reply) :optimistic))
            (push (list :second-attempt-success reader-id) keys))
          (dolist (query (queries slot))
            (push (list (first (tuple-answer (subseq reply 0 3) query)) reader-id query) keys)))))
    (when (and (eq (fifth (eighth (reader-at state 0))) :writer)
               (eq (fifth (eighth (reader-at state 1))) :writer))
      (push '(:both-fallback-completed) keys))
    (when (terminal-p state) (push '(:terminal) keys))
    keys))

(defun required-positive-keys (targets)
  (append '((:both-fallback-completed) (:terminal))
          (loop for reader-id below 2 for slot in targets append
                (append (loop for property in '(:retry :fallback-request :fallback-completed
                                                :second-attempt-success)
                              collect (list property reader-id))
                        (list (list :generation reader-id 0) (list :generation reader-id 1))
                        (loop for query in (queries slot) append
                              (if (eq query :absent)
                                  (list (list :miss reader-id query))
                                  (list (list :hit reader-id query) (list :miss reader-id query))))))))

(defun completion-report (parents reverse-edges terminals)
  "Attrae tutti i predecessori dei terminali: ogni nodo deve poter completare."
  (let ((reachable (make-hash-table :test 'equal))
        (queue (make-array 16 :adjustable t :fill-pointer 0)) (cursor 0))
    (dolist (state terminals)
      (setf (gethash state reachable) t)
      (vector-push-extend state queue))
    (loop while (< cursor (length queue))
          for state = (aref queue cursor)
          do (incf cursor)
             (dolist (previous (gethash state reverse-edges))
               (unless (gethash previous reachable)
                 (setf (gethash previous reachable) t)
                 (vector-push-extend previous queue))))
    (unless (= (hash-table-count parents) (hash-table-count reachable))
      (error "Stati senza completamento: ~D su ~D."
             (- (hash-table-count parents) (hash-table-count reachable))
             (hash-table-count parents)))
    (list :status :ok :method :reverse-reachability :completable-states (hash-table-count reachable)
          :terminal-states (length terminals) :deadlocks 0 :strict-rank t :rank-bound 36
          :scheduled-transition-bound 36 :fairness :eventual-enabled-actions
          :wall-time-bound :not-proved)))

(defun run-graph (order targets mutant limit)
  (let* ((initial (initial-state)) (parents (make-hash-table :test 'equal))
         (reverse-edges (make-hash-table :test 'equal))
         (positives (make-hash-table :test 'equal)) (terminals nil)
         (oracle-calls 0) (accepted-checks (list 0 0)) (query-checks 0) (discovery-edges 0))
    (setf (gethash initial parents) (cons nil nil))
    (flet ((edges (state)
             (let ((edges (successors state order targets mutant)))
               (when (null edges)
                 (unless (terminal-p state) (error "Terminale incompleto: ~S" state))
                 (push state terminals))
               (dolist (edge edges)
                 (incf discovery-edges)
                 (let ((next (cdr edge)))
                   (unless (and (< (state-rank state) (state-rank next)) (<= (state-rank next) 36))
                     (error "Rango invalido: ~S -> ~S" state next))
                   (push state (gethash next reverse-edges))
                   (unless (nth-value 1 (gethash next parents))
                     (setf (gethash next parents) (cons state (car edge)))
                     (when (>= (hash-table-count parents) limit)
                       (error 'state-budget-exhausted
                              :data (list :schema-version 1 :status :failed
                                          :model (list :writer-order order :reader-slots targets
                                                       :mutant mutant)
                                          :states-discovered (hash-table-count parents)
                                          :state-limit limit :budget-reached t :exhaustive nil
                                          :oracle-calls oracle-calls
                                          :discovery-edges discovery-edges
                                          :accepted-tuple-checks-per-reader (copy-list accepted-checks)
                                          :query-checks query-checks))))))
               edges))
           (violation (state)
             (incf oracle-calls)
             (unless mutant
               (dolist (key (positive-keys state targets))
                 (unless (gethash key positives) (setf (gethash key positives) state))))
             (safety-violation state order targets
                               (lambda (event reader-id)
                                 (ecase event
                                   (:tuple (incf (nth reader-id accepted-checks)))
                                   (:query (incf query-checks)))))))
      (let* ((report (arcdocdb.spk07::require-outcome
                      (arcdocdb.spk07::explore
                       (list :seqlock-readers :writer-order order :reader-slots targets :mutant mutant)
                       initial #'edges #'violation :limit limit)
                      mutant))
             (failure (getf report :violation)))
        (setf (getf report :oracle-calls) oracle-calls
              (getf report :accepted-tuple-checks-per-reader) accepted-checks
              (getf report :query-checks) query-checks
              (getf report :discovery-edges) discovery-edges
              (getf report :state-limit) limit
              (getf report :budget-reached) nil
              (getf report :exhaustive) (null mutant))
        (if mutant
            (progn
              (unless (and (eq (getf failure :kind) :accepted-tuple-mismatch)
                           (= (getf failure (ecase (first mutant)
                                              (:skip-odd :slot) (:skip-validation :reader)))
                              (second mutant))
                           (getf report :witness))
                (error "Controesempio non specifico per ~S: ~S" mutant report))
              (setf (getf report :mutation-detected) t))
            (progn
              (unless (= oracle-calls (getf report :states))
                (error "Oracolo non chiamato in ogni stato."))
              (setf (getf report :completion) (completion-report parents reverse-edges terminals)
                    (getf report :positive-witnesses)
                    (loop for key in (required-positive-keys targets)
                          for state = (gethash key positives)
                          unless state do (error "Testimone positivo mancante: ~S" key)
                          collect (list :property key :state state
                                        :witness (arcdocdb.spk07::witness state parents))))))
        report))))

(defun check (&key (state-limit 200000))
  "Plist :STATUS :OK solo dopo safety, reachability, completabilità e mutanti."
  (unless (and (integerp state-limit) (<= 2 state-limit 200000))
    (error "Il tetto per grafo deve essere fra 2 e 200000, ricevuto ~S." state-limit))
  (let ((correct nil) (mutants nil))
    (dolist (order '((0 1) (1 0)))
      (dolist (targets '((0 0) (1 1) (0 1) (1 0)))
        (push (run-graph order targets nil state-limit) correct)
        (dolist (mutant '((:skip-odd 0) (:skip-odd 1) (:skip-validation 0) (:skip-validation 1)))
          (when (or (eq (first mutant) :skip-validation) (member (second mutant) targets))
            (push (run-graph order targets mutant state-limit) mutants)))))
    (setf correct (nreverse correct) mutants (nreverse mutants))
    (list :schema-version 1 :module :seqlock-readers :status :ok
          :correct-graphs correct :mutant-graphs mutants
          :counts (list :correct-graphs (length correct) :mutant-graphs (length mutants)
                        :correct-states (loop for r in correct sum (getf r :states))
                        :correct-edges (loop for r in correct sum (getf r :edges))
                        :correct-oracle-calls (loop for r in correct sum (getf r :oracle-calls))
                        :correct-accepted-tuple-checks
                        (loop for r in correct sum (reduce #'+ (getf r :accepted-tuple-checks-per-reader)))
                        :correct-query-checks (loop for r in correct sum (getf r :query-checks))
                        :mutant-states-discovered (loop for r in mutants sum (getf r :states))
                        :mutant-edges (loop for r in mutants sum (getf r :edges))
                        :mutant-oracle-calls (loop for r in mutants sum (getf r :oracle-calls))
                        :mutant-accepted-tuple-checks
                        (loop for r in mutants sum (reduce #'+ (getf r :accepted-tuple-checks-per-reader)))
                        :mutant-query-checks (loop for r in mutants sum (getf r :query-checks))
                        :max-states-per-graph (loop for r in (append correct mutants)
                                                   maximize (getf r :states))
                        :positive-witnesses (loop for r in correct
                                                 sum (length (getf r :positive-witnesses)))
                        :counterexamples (length mutants))
          :limits (list :states-per-graph state-limit :hard-state-ceiling 200000
                        :ceiling-reached-is-error t :reader-attempts 2 :writer-updates 2
                        :readers 2 :slots 2 :operations-per-reader 1 :rank-bound 36
                        :queries-per-accepted-tuple 3 :query-factorization :response-only
                        :memory :sequentially-consistent :location-register :atomic
                        :sequence-values '(0 1 2) :generations '(0 1) :wrap nil
                        :fairness :eventual-enabled-actions :wall-time-bound :not-proved
                        :cross-slot-snapshot :not-modelled :hardware-proof nil
                        :weak-memory :not-modelled :production-code nil :benchmark nil))))
