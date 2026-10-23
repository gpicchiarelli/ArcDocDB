;;;; SPK-07: esplorazione finita, deterministica, senza codice del motore.
;;; REQ: REQ-AFF-007 REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018 REQ-AFF-019
;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-TXM-007 REQ-TXM-008 REQ-CMP-008 REQ-IDX-002
;;; REQ: REQ-MVC-008
(defpackage :arcdocdb.spk07 (:use :cl) (:export :check))
(in-package :arcdocdb.spk07)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defun changed (state index value)
  (let ((copy (copy-list state)))
    (setf (nth index copy) value)
    copy))

(defun witness (state parents)
  (let ((steps nil))
    (loop repeat (hash-table-count parents)
          for info = (gethash state parents)
          while (cdr info)
          do (push (cdr info) steps) (setf state (car info)))
    steps))

(defun explore (name initial successors violation &key (limit 200000))
  "BFS; le chiavi sono stati immutabili. Il limite esaurito è un errore, mai successo."
  (let ((parents (make-hash-table :test 'equal))
        (queue (make-array 16 :adjustable t :fill-pointer 0))
        (cursor 0) (edges 0))
    (setf (gethash initial parents) (cons nil nil))
    (vector-push-extend initial queue)
    (loop while (< cursor (length queue)) do
      (let* ((state (aref queue cursor)) (failure (funcall violation state)))
        (incf cursor)
        (when failure
          (return-from explore
            (list :model name :states (hash-table-count parents) :edges edges
                  :violation failure :witness (witness state parents) :state state)))
        (dolist (edge (funcall successors state))
          (incf edges)
          (let ((next (cdr edge)))
            (unless (nth-value 1 (gethash next parents))
              (when (>= (hash-table-count parents) limit)
                (error "Limite di ~D stati nel modello ~A" limit name))
              (setf (gethash next parents) (cons state (car edge)))
              (vector-push-extend next queue))))))
    (list :model name :states (hash-table-count parents) :edges edges :violation nil)))

;;; Anello: crediti sui soli pendenti contro distanza issued-H e insieme dei pendenti.
(defun horizon-edges (state policy)
  (destructuring-bind (issued horizon ring status) state
    (let ((edges nil))
      (when (and (< issued 6)
                 (< (if (eq policy :distance) (- issued horizon) (count 1 status)) 2))
        (push (cons (list :allocate (1+ issued))
                    (list (1+ issued) horizon (copy-list ring) (append status '(1)))) edges))
      (dotimes (i issued)
        (when (= (nth i status) 1)
          (let ((r (copy-list ring)) (s (copy-list status)) (h horizon) (c (1+ i)))
            (setf (nth i s) 2)
            (if (eq policy :set)
                (setf h (or (position 1 s) issued))
                (progn
                  (setf (nth (mod c 4) r) c)
                  (loop repeat 4 while (= (nth (mod (1+ h) 4) r) (1+ h)) do (incf h))))
            (push (cons (list :publish c) (list issued h r s)) edges))))
      edges)))

(defun horizon-violation (state)
  (destructuring-bind (issued horizon ring status) state
    (declare (ignore ring))
    (cond ((loop for c from 1 to horizon thereis (/= (nth (1- c) status) 2))
           :horizon-skips-pending)
          ((and (not (member 1 status)) (/= horizon issued)) :horizon-stalled)
          (t nil))))

;;; 2PC: local 0->append->flush->apply->outcome-append->outcome-flush.
;;; :decision 0->append->flush; si dimentica solo dopo entrambi gli esiti durevoli.
(defun multi-edges (state mutant)
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((edges nil))
      (dotimes (i 2)
        (let ((local (nth i state)))
          (when (or (< local 2)
                    (and (= local 2) (= decision 2)) (<= 3 local 4))
            (push (cons (list :participant i :step (1+ local))
                        (changed state i (1+ local))) edges))))
      (when (and (< decision 2) (>= a 2) (>= b 2))
        (push (cons (list :decision (1+ decision))
                    (changed state 2 (1+ decision))) edges))
      (when (and (= decision 2) (not forgotten)
                 (>= a (if (eq mutant :forget-early) 3 5))
                 (>= b (if (eq mutant :forget-early) 3 5)))
        (push (cons :forget (changed state 3 t)) edges))
      (when (and (= decision 2) (>= a 3) (>= b 3) (not ack))
        (push (cons :ack (changed state 4 t)) edges))
      (when (and (= a 5) (not rotated-a))
        (push (cons :rotate-a (changed state 5 t)) edges))
      (when (and (= b 5) (not rotated-b))
        (push (cons :rotate-b (changed state 6 t)) edges))
      edges)))

(defun multi-violation (state)
  "Crash in ogni stato: la decisione durevole è l'oracolo, gli esiti locali la sostituiscono."
  (destructuring-bind (a b decision forgotten ack rotated-a rotated-b) state
    (let ((committed (= decision 2))
          (ra (or (= a 5) (and (= decision 2) (not forgotten))))
          (rb (or (= b 5) (and (= decision 2) (not forgotten)))))
      (cond ((and committed (not (and ra rb))) :committed-lost-after-crash)
            ((not (eql ra rb)) :partial-commit)
            ((and ack (or (< a 3) (< b 3))) :ack-before-visibility)
            ((or (and rotated-a (< a 5)) (and rotated-b (< b 5))) :non-self-contained)
            (t nil)))))

;;; EDIT: sorgente e output distinti; riferimenti reader/snapshot prima dell'eliminazione.
;;; Stato fase=0..6, riferimenti; il crash usa l'EDIT durevole, non l'indice in memoria.
(defun edit-edges (state mutant)
  (destructuring-bind (phase pins) state
    (let ((edges nil))
      (when (and (< phase 6)
                 (or (/= phase 5) (= pins 0) (eq mutant :reclaim-pinned)))
        (push (cons (list :phase (1+ phase)) (list (1+ phase) pins)) edges))
      (when (> pins 0)
        (push (cons :release (list phase (1- pins))) edges))
      edges)))

(defun edit-violation (state)
  (destructuring-bind (phase pins) state
    (cond ((and (= phase 6) (> pins 0)) :reclaimed-pinned-source)
          (t nil))))

(defun recover-edit (phase)
  "Prima dell'EDIT (fase3) resta sorgente; dopo, completa sempre l'output durevole."
  (if (< phase 3) :source :output))

;;; Seqlock: due campi con somma 100, aggiornati in passi separati.
;;; Stato=(writer-step reader-step seq x y s1 rx ry s2 result), -1=nessun risultato.
(defun seq-edges (state mutant)
  (let ((edges nil) (w (first state)) (r (second state)))
    (when (< w 4)
      (let ((s (changed state 0 (1+ w))))
        (case w
          (0 (setf (nth 2 s) 1))
          (1 (setf (nth 3 s) 30))
          (2 (setf (nth 4 s) 70))
          (3 (setf (nth 2 s) 2))
          (otherwise (error "Passo writer inatteso")))
        (push (cons (list :writer w) s) edges)))
    (when (< r 5)
      (let ((s (changed state 1 (1+ r))))
        (case r
          (0 (setf (nth 5 s) (nth 2 state)))
          (1 (setf (nth 6 s) (nth 3 state)))
          (2 (setf (nth 7 s) (nth 4 state)))
          (3 (setf (nth 8 s) (nth 2 state)))
          (4 (when (or mutant (and (= (nth 5 s) (nth 8 s)) (evenp (nth 5 s))))
               (setf (nth 9 s) (+ (nth 6 s) (nth 7 s)))))
          (otherwise (error "Passo reader inatteso")))
        (push (cons (list :reader r) s) edges)))
    edges))

(defun seq-violation (state)
  (unless (member (nth 9 state) '(-1 100)) :torn-read))

;;; Registrazione: soglia sentinella, lettura s, pubblicazione versione, nascita snapshot.
;;; write che non ha letto la soglia precede la pubblicazione della registrazione.
(defun snapshot-edges (state protect)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore snapshot retained current horizon first-read))
    (let ((edges nil))
      (when (< w 3)
        (let ((s (changed state 0 (1+ w))))
          (case w
            (0 nil) ; assegna CSN=1
            (1 (setf (nth 4 s) (< threshold 1) (nth 5 s) 1))
            (2 (setf (nth 6 s) 1))
            (otherwise (error "Passo snapshot writer")))
          (push (cons (list :writer w) s) edges)))
      (when (and (< r 3) (or (/= r 2) (>= (nth 6 state) (nth 3 state))))
        (let ((s (changed state 1 (1+ r))))
          (case r
            (0 (when protect (setf (nth 2 s) (nth 6 state))))
            (1 (setf (nth 3 s) (if (> w 0) 1 0)))
            (2 (setf (nth 7 s) t))
            (otherwise (error "Passo snapshot reader")))
          (push (cons (list :snapshot r) s) edges)))
      edges)))

(defun snapshot-violation (state)
  (destructuring-bind (w r threshold snapshot retained current horizon first-read) state
    (declare (ignore w r threshold horizon))
    (when (and first-read (= snapshot 0) (= current 1) (not retained))
      :snapshot-old-version-lost)))

;;; Enumerazione persistenza log: prefisso durevole, quattro stati per lotto non durevole.
(defun valid-prefix (states)
  (or (position-if-not (lambda (x) (eq x :valid)) states) (length states)))

(defun classify-log (states durable-prefix)
  (let ((p (valid-prefix states)))
    (if (loop for i from p below (length states)
              thereis (and (eq (nth i states) :valid) (> durable-prefix p)))
        :corruption :tail)))

(defun log-cases ()
  (let ((count 0) (damage-count 0))
    (dotimes (durable 4)
      (dotimes (mask (expt 4 (- 3 durable)))
        (let ((states (make-list durable :initial-element :valid)))
          (dotimes (i (- 3 durable))
            (setf states (append states
                                (list (nth (ldb (byte 2 (* 2 i)) mask)
                                           '(:absent :partial :bad-crc :valid))))))
          (assert (eq (classify-log states durable) :tail))
          (assert (>= (valid-prefix states) durable))
          (incf count))))
    ;; un SEAL successivo attesta che entrambi i primi lotti erano già durevoli.
    (dotimes (bad 2)
      (let ((states '(:valid :valid :valid)))
        (setf states (changed states bad :bad-crc))
        (assert (eq (classify-log states 2) :corruption))
        (incf damage-count)))
    (list :model :sealed-log :persistence-cases count :corruption-cases damage-count
          :limitation :unwitnessed-last-flush :violation nil)))

;;; Tombstone: ogni record=(csn . kind), oracolo indipendente per CSN massimo.
(defun logical-value (segments)
  (let ((winner nil))
    (dolist (segment segments)
      (dolist (record segment)
        (when (or (null winner) (> (car record) (car winner))) (setf winner record))))
    (and winner (eq (cdr winner) :put) (car winner))))

(defun compact-tombstones (segments sources)
  (let* ((outside (loop for s in segments for i from 0 unless (member i sources) collect s))
         (inside (loop for s in segments for i from 0 when (member i sources) append s))
         (max-csn (loop for s in segments maximize (loop for r in s maximize (car r))))
         (live (logical-value segments)) (output nil))
    (dolist (record inside)
      (when (or (and live (= (car record) live))
                (and (eq (cdr record) :delete) (= (car record) max-csn)
                     (loop for s in outside thereis
                           (loop for older in s thereis (< (car older) (car record))))))
        (push record output)))
    (append outside (list output))))

(defun permutations (items)
  (if (null items) (list nil)
      (loop for x in items append
            (mapcar (lambda (rest) (cons x rest))
                    (permutations (remove x items :count 1 :test #'equal))))))

(defun tombstone-cases ()
  (let ((count 0))
    (dotimes (kinds 16)
      (let* ((segments (loop for i below 4 collect
                            (list (cons (1+ i) (if (logbitp i kinds) :delete :put)))))
             (expected (logical-value segments)))
        (loop for sources-mask from 1 below 16 do
          (let* ((sources (loop for i below 4 when (logbitp i sources-mask) collect i))
                 (output (compact-tombstones segments sources)))
            (dolist (order (permutations output))
              (assert (eql expected (logical-value order)))
              (incf count))))))
    (list :model :tombstones :cases count :records 4 :snapshots :not-modelled
          :bloom :exact-no-false-negatives :violation nil)))

(defun edit-cases ()
  (let ((count 0))
    (dotimes (phase 7)
      (let ((once (recover-edit phase)))
        (assert (eq once (recover-edit (if (eq once :output) 6 0))))
        (incf count)))
    ;; Le tabelle catalogo e manifest hanno lo stesso algoritmo di riconciliazione.
    (dolist (object '(:segment :directory))
      (declare (ignore object))
      (dolist (name '(:tmp :final :missing))
        (dolist (truth '(:unknown :active :removed))
          (let ((action (case truth
                          (:unknown (if (eq name :tmp) :discard :report))
                          (:active (case name (:tmp :rename) (:final :use)
                                         (:missing :fault) (otherwise (error "Nome"))))
                          (:removed :remove) (otherwise (error "Fonte")))))
            (when (and (eq name :final) (eq truth :unknown)) (assert (eq action :report)))
            (incf count)))))
    (list :model :recovery-and-catalogue :cases count :violation nil)))

(defun require-outcome (report expected-violation)
  (unless (if expected-violation (getf report :violation) (null (getf report :violation)))
    (error "Esito inatteso nel modello: ~S" report))
  report)

(defun check ()
  (let ((reports nil))
    (dolist (policy '(:pending :distance :set))
      (push (require-outcome
             (explore (list :horizon policy) '(0 0 (0 0 0 0) ())
                      (lambda (s) (horizon-edges s policy)) #'horizon-violation)
             (eq policy :pending)) reports))
    (dolist (mutant '(nil :forget-early))
      (push (require-outcome
             (explore (list :multiserie mutant) '(0 0 0 nil nil nil nil)
                      (lambda (s) (multi-edges s mutant)) #'multi-violation)
             mutant) reports))
    (dolist (mutant '(nil :reclaim-pinned))
      (push (require-outcome
             (explore (list :edit-reclaim mutant) '(0 2)
                      (lambda (s) (edit-edges s mutant)) #'edit-violation)
             mutant) reports))
    (dolist (mutant '(nil :no-seqlock-validation))
      (push (require-outcome
             (explore (list :seqlock mutant) '(0 0 0 10 90 0 0 0 0 -1)
                      (lambda (s) (seq-edges s mutant)) #'seq-violation)
             mutant) reports))
    (dolist (protect '(nil t))
      (push (require-outcome
             (explore (list :snapshot protect) '(0 0 99 0 nil 0 0 nil)
                      (lambda (s) (snapshot-edges s protect)) #'snapshot-violation)
             (not protect)) reports))
    (list :spike :spk-07 :status :pass :reports (nreverse reports)
          :enumerations (list (log-cases) (tombstone-cases) (edit-cases))
          :coverage :bounded-abstract-models
          :pending '(:fragment-publication :snapshot-expiry :weak-memory
                     :byte-level-crash :compaction-with-active-writer)
          :gate :open)))
