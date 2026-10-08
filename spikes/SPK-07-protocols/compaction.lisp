;;;; SPK-07: modello finito e logico, senza codice di produzione o operazioni reali su file.
;;; REQ: REQ-CMP-002 REQ-CMP-005 REQ-CMP-007 REQ-CMP-008 REQ-CMP-009 REQ-VAL-001
;;;; Metodo registrato in metodo-compaction.md prima della prima esecuzione.
(defpackage :arcdocdb.spk07.compaction
  (:use :cl)
  (:export :check))
(in-package :arcdocdb.spk07.compaction)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

;;; Record risolto: (chiave csn tipo valore offset). Puntatore: (segmento csn offset).
;;; Gli stati della ricerca in ampiezza sono liste immutabili, confrontabili con EQUAL.
(defun replace-fields (state &rest fields)
  (let ((next (copy-list state)))
    (loop for (key value) on fields by #'cddr do (setf (getf next key) value))
    next))

(defun resolve-closed (segment)
  "Interpreta CLOSED da OUTCOME locale oppure esiti di chiusura, senza registro decisioni."
  (let ((records (getf segment :records)) (answer nil))
    (dolist (raw records (nreverse answer))
      (case (first raw)
        (:ordinary (push (rest raw) answer))
        (:prepared
         (let* ((txid (third raw))
                (outcome (find txid records :key #'second :test #'eql))
                (csn (or (and (eq (first outcome) :outcome) (third outcome))
                         (cdr (assoc txid (getf segment :closing-outcomes))))))
           (when csn
             (push (list (second raw) csn (fourth raw) (fifth raw) (sixth raw))
                   answer))))
        ((:seal :outcome) nil)
        (otherwise (error "Record CLOSED inatteso: ~S" raw))))))

(defun closed-records (workload &optional sources-only)
  (loop for segment in (getf workload :closed)
        when (or (not sources-only)
                 (member (getf segment :id) (getf workload :sources)))
          append (loop for record in (resolve-closed segment)
                       collect (cons (getf segment :id) record))))

(defun newer-record (records key ceiling)
  "Scansione del modello; l'oracolo cerca invece per CSN decrescente."
  (let ((winner nil))
    (dolist (record records winner)
      (when (and (eql (first record) key) (<= (second record) ceiling)
                 (or (null winner) (> (second record) (second winner))))
        (setf winner record)))))

(defun record-value (record)
  (if (and record (eq (third record) :put))
      (list :present (second record) (fourth record))
      '(:absent)))

(defun pointer-to (located)
  (when located (list (first located) (third located) (sixth located))))

(defun selected-pointer (workload key ceiling &key live-only)
  (let ((winner nil))
    (dolist (located (closed-records workload))
      (when (and (eql key (second located)) (<= (third located) ceiling)
                 (or (null winner) (> (third located) (third winner))))
        (setf winner located)))
    (when (and winner (or (not live-only) (eq (fourth winner) :put)))
      (pointer-to winner))))

(defun initial-state (workload)
  (list :phase 0 :copy-cursor 0 :output nil :writer 0 :active nil
        :repoint-cursor 0 :pinned t
        :index (loop for key in (getf workload :keys)
                     for pointer = (selected-pointer workload key 4 :live-only t)
                     when pointer collect (cons key pointer))
        :retained (loop for key in (getf workload :keys)
                        for pointer = (selected-pointer workload key
                                                        (getf workload :snapshot))
                        when pointer collect (cons key pointer))))

;;; L'oracolo usa soltanto la storia originale e il prefisso dei commit del writer.
(defun oracle-value (workload state key ceiling)
  (let ((history (append (getf workload :history)
                         (subseq (getf workload :writes) 0 (getf state :writer)))))
    (loop for csn from ceiling downto 1 do
      (let ((fact (find-if (lambda (fact)
                             (and (eql (first fact) key) (= (second fact) csn)))
                           history)))
        (when fact
          (return-from oracle-value
            (if (eq (third fact) :delete) '(:absent)
                (list :present csn (fourth fact)))))))
    '(:absent)))

(defun pointer-record (workload state pointer)
  (when pointer
    (destructuring-bind (segment csn offset) pointer
      (let ((records
              (cond ((eq segment :active) (getf state :active))
                    ((eq segment :output)
                     (when (>= (getf state :phase) 4) (getf state :output)))
                    ((and (= (getf state :phase) 7)
                          (member segment (getf workload :sources))) nil)
                    (t (resolve-closed
                        (find segment (getf workload :closed)
                              :key (lambda (s) (getf s :id))))))))
        (find-if (lambda (record)
                   (and (= (second record) csn) (= (fifth record) offset))) records)))))

(defun retained-key-p (workload key)
  ;; Il copiatore conserva prudenzialmente la selezione iniziale anche dopo il rilascio.
  (not (null (selected-pointer workload key (getf workload :snapshot)))))

(defun older-outside-p (workload key csn)
  (loop for outside in (getf workload :closed) thereis
    (and (not (member (getf outside :id) (getf workload :sources)))
         (let ((records (resolve-closed outside)))
           (and (some (lambda (r) (< (second r) csn)) records)
                (or (eq (getf workload :filter) :maybe)
                    (some (lambda (r) (eql (first r) key)) records)))))))

(defun necessary-record-p (workload located mutant)
  (destructuring-bind (segment key csn kind value offset) located
    (declare (ignore value))
    (let* ((current (selected-pointer workload key 4 :live-only t))
           (snapshot (selected-pointer workload key (getf workload :snapshot)))
           (current-match (equal current (list segment csn offset)))
           (snapshot-match (equal snapshot (list segment csn offset)))
           (superseded (and current (> (second current) csn))))
      (cond
        ((and (eq mutant :snapshot-version-lost) snapshot-match
              (not current-match)) nil)
        ((eq kind :delete)
         (and (not (eq mutant :tombstone-dropped))
              (or snapshot-match
                  ;; ADR-0042(a): versione CLOSED durevole più recente.
                  (and (not superseded)
                       (or (retained-key-p workload key)
                           (older-outside-p workload key csn))))))
        (t (or current-match snapshot-match))))))

(defun set-entry (entries key pointer)
  (let ((others (remove key entries :key #'car)))
    (if pointer (acons key pointer others) others)))

(defun output-pointer (state key csn)
  (let ((record (find-if (lambda (r) (and (eql (first r) key) (= (second r) csn)))
                         (getf state :output))))
    (when record (list :output csn (fifth record)))))

(defun repoint-key (workload state key mutant)
  (let* ((current (cdr (assoc key (getf state :index))))
         (retained (cdr (assoc key (getf state :retained))))
         (copy (and current (output-pointer state key (second current))))
         (new-index (getf state :index)) (new-retained (getf state :retained)))
    (cond
      ((eq mutant :unconditional-repoint)
       (let ((stale (newer-record (getf state :output) key 4)))
         (when (and stale (eq (third stale) :put))
           (setf new-index
                 (set-entry new-index key (list :output (second stale) (fifth stale)))))))
      ((and copy (member (first current) (getf workload :sources)))
       (setf new-index (set-entry new-index key copy))))
    (when (and retained (member (first retained) (getf workload :sources)))
      (let ((copy (output-pointer state key (second retained))))
        (when copy (setf new-retained (set-entry new-retained key copy)))))
    (replace-fields state :index new-index :retained new-retained
                    :repoint-cursor (1+ (getf state :repoint-cursor)))))

(defun successors (workload state mutant)
  (let ((edges nil) (phase (getf state :phase))
        (cursor (getf state :copy-cursor)) (writer (getf state :writer))
        (sources (getf workload :copy-input)))
    (when (< writer (length (getf workload :writes)))
      (let* ((fact (nth writer (getf workload :writes)))
             (record (append fact (list (1+ writer))))
             (pointer (when (eq (third fact) :put)
                        (list :active (second fact) (fifth record)))))
        (push (cons (list :writer-commit (first fact) (second fact) (third fact))
                    (replace-fields state :writer (1+ writer)
                                    :active (append (getf state :active) (list record))
                                    :index (set-entry (getf state :index)
                                                      (first fact) pointer))) edges)))
    (when (getf state :pinned)
      (push (cons :release-snapshot-pin (replace-fields state :pinned nil)) edges))
    (case phase
      (0 (if (< cursor (length sources))
             (let* ((located (nth cursor sources))
                    (keep (necessary-record-p workload located mutant))
                    (output (getf state :output)))
               (push (cons (list :copy (first located) (second located)
                                 (third located) :keep (not (null keep)))
                           (replace-fields state :copy-cursor (1+ cursor)
                             :output (if keep
                                         (append output
                                           (list (append (subseq located 1 5)
                                                         (list (1+ (length output))))))
                                         output))) edges))
             (push (cons :copy-complete (replace-fields state :phase 1)) edges)))
      (1 (push (cons :sync-tmp (replace-fields state :phase 2)) edges))
      (2 (push (cons :syncdir-tmp (replace-fields state :phase 3)) edges))
      (3 (push (cons :durable-edit (replace-fields state :phase 4)) edges))
      (4 (push (cons :rename-completion (replace-fields state :phase 5)) edges))
      (5 (let ((repoint (getf state :repoint-cursor)))
           (if (< repoint (length (getf workload :keys)))
               (let ((key (nth repoint (getf workload :keys))))
                 (push (cons (list :writer-repoint key)
                             (repoint-key workload state key mutant)) edges))
               (push (cons :completion (replace-fields state :phase 6)) edges))))
      (6 (when (or (not (getf state :pinned)) (eq mutant :reclaim-pinned))
           (push (cons :epoch-contract-reclaim (replace-fields state :phase 7)) edges)))
      (7 nil)
      (otherwise (error "Fase inattesa: ~S" phase)))
    (nreverse edges)))

;;; Arresto: due nomi possibili dopo la rinomina; eliminazione eventualmente non persistita.
;;; Prima dell'EDIT i tmp, anche durevoli, non sono una fonte di verità.
(defun crash-images (state)
  (let* ((phase (getf state :phase)) (edited (>= phase 4))
         (names (cond ((>= phase 5) '(:tmp :final))
                      ((>= phase 2) '(:tmp)) (t '(nil))))
         (source-presence (if (= phase 7) '(nil t) '(t))))
    (loop for name in names append
      (loop for present in source-presence collect
        (list :edited edited :output-name name
              :output (if (>= phase 2) (getf state :output) nil)
              :sources-present present :active (getf state :active)
              :recovery-step 0 :index nil)))))

(defun image-segments (workload image)
  (append
    (loop for segment in (getf workload :closed)
          unless (and (getf image :edited)
                      (member (getf segment :id) (getf workload :sources)))
            collect (resolve-closed segment))
    (when (getf image :edited) (list (getf image :output)))
    (list (getf image :active))))

(defun rebuild-index (workload image &optional reverse-order)
  (let ((index nil) (winners nil)
        (segments (image-segments workload image)))
    (when reverse-order (setf segments (reverse segments)))
    (dolist (segment segments)
      (dolist (record (if reverse-order (reverse segment) segment))
        (let* ((key (first record)) (old (cdr (assoc key winners))))
          (when (or (null old) (> (second record) (second old)))
            (setf winners (set-entry winners key record))))))
    (dolist (entry winners)
      (when (eq (third (cdr entry)) :put)
        (push (cons (car entry) (record-value (cdr entry))) index)))
    ;; Normalizza per rendere confrontabile anche il recupero ripetuto.
    (loop for key in (getf workload :keys)
          for value = (cdr (assoc key index)) when value collect (cons key value))))

(defun recovery-step (workload image)
  (case (getf image :recovery-step)
    (0 (if (getf image :edited)
           (progn
             (unless (member (getf image :output-name) '(:tmp :final))
               (error "EDIT senza output durevole"))
             (replace-fields image :output-name :final :recovery-step 1))
           (replace-fields image :output-name nil :output nil :recovery-step 1)))
    (1 (replace-fields image :sources-present (not (getf image :edited))
                       :recovery-step 2))
    (2 (replace-fields image :index (rebuild-index workload image) :recovery-step 3))
    (3 image)
    (otherwise (error "Passo di recupero inatteso"))))

(defun finish-recovery (workload image)
  (loop repeat 3 for next = (recovery-step workload image)
        do (setf image next)
        finally (return image)))

(defun failure (kind key expected actual &rest details)
  (append (list :kind kind :key key :expected expected :actual actual) details))

(defun validate-state (workload state metrics)
  (incf (getf metrics :checked-states))
  (when (and (= (getf state :phase) 7) (getf state :pinned))
    (return-from validate-state (list :kind :reclaimed-pinned-source)))
  (when (and (= (getf state :phase) 7)
             (= (getf state :writer) (length (getf workload :writes))))
    (incf (getf metrics :terminal-states)))
  (dolist (key (getf workload :keys))
    (let* ((pointer (cdr (assoc key (getf state :index))))
           (record (pointer-record workload state pointer))
           (expected (oracle-value workload state key 8))
           (actual (record-value record)))
      (incf (getf metrics :index-reads))
      (when (and pointer (or (null record) (not (eq (third record) :put))))
        (return-from validate-state (failure :invalid-live-entry key expected actual
                                            :pointer pointer)))
      (unless (equal expected actual)
        (return-from validate-state (failure :latest-index-mismatch key expected actual
                                            :pointer pointer)))
      (when (getf state :pinned)
        (let* ((snapshot-pointer (cdr (assoc key (getf state :retained))))
               (actual (record-value (pointer-record workload state snapshot-pointer)))
               (expected (oracle-value workload state key (getf workload :snapshot))))
          (incf (getf metrics :snapshot-reads))
          (unless (equal expected actual)
            (return-from validate-state (failure :snapshot-value-mismatch key expected actual
                                                :pointer snapshot-pointer)))))))
  (dolist (image (crash-images state))
    (incf (getf metrics :crash-cases))
    (let ((finished (finish-recovery workload image)) (prefix image))
      ;; Arresto e riavvio anche dopo ogni singolo passo della riconciliazione.
      (dotimes (step 4)
        (incf (getf metrics :recovery-prefixes))
        (unless (equal finished (finish-recovery workload prefix))
          (return-from validate-state (list :kind :non-idempotent-recovery :step step)))
        (dolist (reverse-order '(nil t))
          (incf (getf metrics :rebuild-orders))
          (let ((index (rebuild-index workload prefix reverse-order))
                (records (apply #'append
                                (if reverse-order
                                    (reverse (image-segments workload prefix))
                                    (image-segments workload prefix)))))
            (dolist (key (getf workload :keys))
              (let ((expected (oracle-value workload state key 8))
                    (actual (or (cdr (assoc key index)) '(:absent))))
                (incf (getf metrics :recovery-latest-reads))
                (unless (equal expected actual)
                  (return-from validate-state
                    (failure :recovery-latest-mismatch key expected actual
                             :recovery-step step :image image))))
              (let ((expected (oracle-value workload state key (getf workload :snapshot)))
                    (actual (record-value
                             (newer-record records key (getf workload :snapshot)))))
                (incf (getf metrics :recovery-history-reads))
                (unless (equal expected actual)
                  (return-from validate-state
                    (failure :recovery-snapshot-mismatch key expected actual
                             :recovery-step step :image image)))))))
        (setf prefix (recovery-step workload prefix)))))
  nil)

(defun make-workload (key-count mask sources snapshot resolution filter
                     &key isolated-delete)
  (let ((keys (subseq '(:a :b) 0 key-count)) (history nil) (segments nil)
        (writes nil))
    (dotimes (s 4)
      (let ((records (list '(:seal))) (closing nil) (id (nth s '(:s0 :s1 :s2 :s3))))
        (loop for key in keys for k from 0 do
          (when (or (not isolated-delete) (= s 3))
            (let* ((csn (1+ s))
                   ;; Due chiavi: 16 configurazioni complementari, campione finito dichiarato.
                   (delete (or isolated-delete
                               (if (= k 0) (logbitp s mask) (not (logbitp s mask)))))
                   (kind (if delete :delete :put))
                   (value (unless delete (list key :closed csn)))
                   (offset (+ (* 10 csn) k))
                   (txid (if (= k 0) :tx-a :tx-b)))
              (push (list key csn kind value) history)
              (if (member id sources)
                  (progn
                    (push (list :prepared key txid kind value offset) records)
                    (if (eq resolution :local-outcome)
                        (push (list :outcome txid csn) records)
                        (push (cons txid csn) closing)))
                  (push (list :ordinary key csn kind value offset) records)))))
        ;; Un prepared abortito senza OUTCOME non è candidato e non deve riemergere.
        (push (list :prepared :a :aborted :put :must-not-appear 99) records)
        (push (list :id id :records (nreverse records) :closing-outcomes closing) segments)))
    (dotimes (round 2)
      (loop for key in keys for k from 0 do
        (let* ((csn (+ 5 (* round key-count) k))
               (delete (if (= key-count 1)
                           (case (mod mask 4)
                             (0 (= round 1)) (1 (= round 0))
                             (2 nil) (3 t))
                           (oddp (+ mask round k)))))
          (push (list key csn (if delete :delete :put)
                      (unless delete (list key :active csn))) writes))))
    (let ((workload (list :keys keys :mask mask :sources sources :snapshot snapshot
                          :resolution resolution :filter filter
                          :isolated-delete isolated-delete :closed (nreverse segments)
                          :history (nreverse history) :writes (nreverse writes))))
      (setf (getf workload :copy-input) (closed-records workload t))
      workload)))

(defun workload-summary (workload)
  (list :keys (getf workload :keys) :mask (getf workload :mask)
        :sources (getf workload :sources) :snapshot-csn (getf workload :snapshot)
        :resolution (getf workload :resolution) :filter (getf workload :filter)
        :isolated-delete (getf workload :isolated-delete)
        :commits (getf workload :writes)
        :source-records (length (getf workload :copy-input))))

(defun run-model (workload mutant limit)
  (let* ((metrics (list :checked-states 0 :terminal-states 0 :index-reads 0
                        :snapshot-reads 0 :crash-cases 0 :recovery-prefixes 0
                        :rebuild-orders 0 :recovery-latest-reads 0 :recovery-history-reads 0))
         (report (arcdocdb.spk07::explore
                   (list :compaction mutant (workload-summary workload))
                   (initial-state workload)
                   (lambda (s) (successors workload s mutant))
                   (lambda (s) (validate-state workload s metrics)) :limit limit)))
    (arcdocdb.spk07::require-outcome report mutant)
    (when (and (not mutant) (zerop (getf metrics :terminal-states)))
      (error "Nessun completamento nel carico ~S" (workload-summary workload)))
    (when mutant
      (let ((expected (case mutant
                        (:unconditional-repoint :latest-index-mismatch)
                        (:tombstone-dropped :recovery-latest-mismatch)
                        (:snapshot-version-lost :recovery-snapshot-mismatch)
                        (:reclaim-pinned :reclaimed-pinned-source))))
        (unless (and (eq (getf (getf report :violation) :kind) expected)
                     (getf report :witness))
          (error "Mutante senza controesempio specifico ~S: ~S" mutant report))))
    (append report (list :metrics metrics :state-limit limit))))

(defun aggregate-reports (reports)
  (let ((total (list :models (length reports) :discovered-states 0 :edges 0
                     :checked-states 0 :terminal-states 0 :index-reads 0
                     :snapshot-reads 0 :crash-cases 0 :recovery-prefixes 0
                     :rebuild-orders 0 :recovery-latest-reads 0 :recovery-history-reads 0)))
    (dolist (report reports)
      (incf (getf total :discovered-states) (getf report :states))
      (incf (getf total :edges) (getf report :edges))
      (loop for (key value) on (getf report :metrics) by #'cddr
            do (incf (getf total key) value)))
    total))

(defun check (&key (state-limit 10000))
  "Controllo breve e deterministico: limite esaurito o mutante non rilevato => errore."
  (unless (and (integerp state-limit) (plusp state-limit))
    (error "state-limit deve essere un intero positivo"))
  (let ((positive nil) (negative nil))
    ;; 64 grafi a una chiave, 32 grafi a due chiavi; nessuna casualità.
    (dolist (key-count '(1 2))
      (dotimes (mask 16)
        (dolist (sources '((:s3) (:s1 :s3)))
          (dolist (snapshot (if (= key-count 1) '(0 2) '(2)))
            (push (run-model
                    (make-workload key-count mask sources snapshot
                                   (if (evenp mask) :local-outcome :closing-manifest)
                                   (if (logbitp 1 mask) :maybe :exact))
                    nil state-limit) positive)))))
    ;; Scarto sicuro: nessun vecchio record esterno della chiave, snapshot antecedente.
    (dolist (filter '(:exact :maybe))
      (push (run-model (make-workload 1 8 '(:s3) 0 :local-outcome filter
                                     :isolated-delete t)
                       nil state-limit) positive))
    (dolist (key-count '(1 2))
      (dolist (mutant '(:unconditional-repoint :tombstone-dropped
                       :snapshot-version-lost :reclaim-pinned))
        (let ((workload (make-workload key-count
                                       (if (eq mutant :tombstone-dropped) 8 0)
                                       '(:s1 :s3) 2 :local-outcome :exact)))
          (push (run-model workload mutant state-limit) negative))))
    (setf positive (nreverse positive) negative (nreverse negative))
    (list :spike :spk-07 :module :compaction :status :ok :schema-version 1
          :positive positive :negative negative
          :counts (list :positive (aggregate-reports positive)
                        :negative (aggregate-reports negative))
          :bounds (list :keys '(1 2) :closed-segments 4 :active-segments 1
                        :snapshot-csns '(0 2) :active-commits '(2 4)
                        :state-limit-per-model state-limit
                        :two-key-patterns :complementary-16)
          :assumptions '(:sequential-consistency :atomic-transitions
                         :unique-csn-per-key :closed-self-contained
                         :active-newer-than-closed :durable-published-active-commit
                         :snapshot-registered-before-copy :fixed-source-selection
                         :conservative-retention-after-release
                         :existence-exact-or-maybe-without-false-negatives
                         :epoch-pin-contract :atomic-rename-old-or-new-name)
          :limitations '(:bounded-safety :no-engine-code :no-real-filesystem
                         :no-byte-crash-or-io-failures :no-weak-memory
                         :no-epoch-internals :no-snapshot-expiry
                         :no-fairness-or-performance :no-merge-admission-policy
                         :no-two-key-cartesian-exhaustion :no-csn-offset-ties
                         :snapshot-does-not-survive-process-crash)
          :conflicts '(:snapshot-pinned-nonadjacent-copy-is-protocol-only
                       :merge-policy-excludes-snapshot-needed-sources)
          :coverage '(:clean :nonadjacent-sources :external-older-records
                      :active-update-delete-recreate :snapshot-retention
                      :prepared-resolution :aborted-prepared-discard
                      :syncdir-before-edit :edit-before-rename
                      :conditional-writer-repoint :reclaim-after-pin-release
                      :crash-every-state :recovery-prefix-restart
                      :forward-and-reverse-rebuild)
          :gate :open)))
