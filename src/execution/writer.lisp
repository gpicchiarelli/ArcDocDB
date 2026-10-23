;;;; Lease locale del writer; la quota limita ogni acquisizione, non la capacità.
;;; OWNER: generation/extracted solo dal writer con lease corrente; CAS owner separato.
;;; SHARED: payload dalla coda al consumatore solo dopo prelievo, nessun callback.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) %check-lease))
(defun %check-lease (queue lease)
  "Pre: token opaco fornito dal chiamante. Post: thread/generation correnti e quota valida.
INVALID-ARGUMENT per token stale, errato o altro thread; INVARIANT-VIOLATION per quota."
  (unless (and (typep lease 'index) (plusp lease)
               (eq (coda-writer-owner queue) sb-thread:*current-thread*)
               (= lease (coda-writer-generation queue)))
    (error 'invalid-argument :reason :writer-lease))
  (unless (and (<= 1 (coda-writer-quantum queue) +max-writer-quantum+)
               (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %libera-owner))
(defun %libera-owner (queue thread)
  "Pre: THREAD possiede owner, campi della lease già finalizzati. Post: owner libero.
Un solo CAS; INVARIANT-VIOLATION al guasto, fail-stop del chiamante senza retry."
  (unless (eq (coda-writer-owner queue) thread)
    (error 'invariant-violation :reason :writer-owner))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-owner queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) index) acquisisci-writer))
(defun acquisisci-writer (queue)
  "Pre: chiamante richiede una nuova lease. Post: generation positiva, quota nuova;
RESOURCE-EXHAUSTED per writer busy o generation esaurita. Overflow non incrementa
né cambia extracted e libera il CAS acquisito; nessun wrap, callback o scheduling."
  (let ((thread sb-thread:*current-thread*) (committed nil))
    (unless (null (sb-ext:compare-and-swap (coda-writer-owner queue) nil thread))
      (error 'resource-exhausted :reason :writer-busy))
    (unwind-protect
         (progn
           (unless (and (eq (coda-writer-owner queue) thread)
                        (zerop (coda-writer-extracted queue)))
             (error 'invariant-violation :reason :writer-owner))
           (when (= (coda-writer-generation queue) most-positive-fixnum)
             (error 'resource-exhausted :reason :writer-generation))
           (incf (coda-writer-generation queue))
           (setf committed t)
           (coda-writer-generation queue))
      (unless committed (%libera-owner queue thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t)
                         (values simple-vector index index &optional)) %check-target))
(defun %check-target (queue target start end)
  "Pre: destinazione del consumatore e range dichiarato. Post: SIMPLE-VECTOR e indici
non vuoti validati prima del ring; INVALID-ARGUMENT per alias, tipo o range errati."
  (unless (and (typep target 'simple-vector) (not (eq target (coda-writer-slots queue))))
    (error 'invalid-argument :reason :writer-target))
  (unless (and (typep start 'index) (typep end 'index) (< start end) (<= end (length target)))
    (error 'invalid-argument :reason :writer-target))
  (values target (the index start) (the index end)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t t)
                         (values index (member :messages :empty :yield) &optional)) preleva-messaggi))
(defun preleva-messaggi (queue lease target start end)
  "Pre: lease del thread corrente e destinazione privata non alias degli slots.
Post: FIFO fino a MIN(count, range, quota), slots liberati, ownership al consumatore;
fuori dai messaggi copiati target invariato. :YIELD senza lavoro sul ring a quota zero,
:EMPTY se vuoto, :MESSAGES dopo copia. INVALID-ARGUMENT per lease/target, RESOURCE-
EXHAUSTED per guard busy; errori interni impongono fail-stop al chiamante."
  (%check-lease queue lease)
  (multiple-value-bind (destination first limit) (%check-target queue target start end)
    (let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))
      (declare (type index remaining))
      (when (zerop remaining) (return-from preleva-messaggi (values 0 :yield)))
      (let ((thread (%acquisisci-guard queue)))
        (unwind-protect
             (progn
               (%check-queue queue)
               (let* ((count (coda-writer-count queue))
                      (taken (min count (- limit first) remaining))
                      (cursor (coda-writer-head queue))
                      (extracted (coda-writer-extracted queue))
                      (slots (coda-writer-slots queue)) (capacity (coda-writer-capacity queue)))
                 (declare (type index count taken cursor extracted capacity))
                 (dotimes (i taken)
                   (setf (svref destination (+ first i)) (svref slots cursor)
                         (svref slots cursor) nil
                         cursor (mod (1+ cursor) capacity)))
                 (setf (coda-writer-head queue) cursor (coda-writer-count queue) (- count taken)
                       (coda-writer-extracted queue) (+ extracted taken))
                 (%check-queue queue)
                 (unless (and (<= taken remaining)
                              (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
                   (error 'invariant-violation :reason :writer-owner))
                 (values taken (if (zerop taken) :empty :messages))))
          (%rilascia-guard queue thread))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) rilascia-writer))
(defun rilascia-writer (queue lease)
  "Pre: lease corrente del thread proprietario. Post: quota azzerata prima del CAS owner
verso NIL, generation conservata. INVALID-ARGUMENT per token errato/stale/altro thread;
INVARIANT-VIOLATION al guasto. Nessun ready, wakeup, callback o controller implicito."
  (%check-lease queue lease)
  (setf (coda-writer-extracted queue) 0)
  (%libera-owner queue sb-thread:*current-thread*))
