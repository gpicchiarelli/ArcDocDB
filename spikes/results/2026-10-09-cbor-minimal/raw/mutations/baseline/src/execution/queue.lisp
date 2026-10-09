;;;; Ring preallocato: serializzazione dei soli indici con un tentativo CAS.
;;; OWNER: payload dal chiamante alla coda soltanto all'accettazione.
;;; SHARED: slots/head/tail/count mutabili soltanto con guard locale posseduta.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(defconstant +max-writer-capacity+ 65536)
(defconstant +max-writer-quantum+ 65536)
(defstruct (coda-writer (:constructor %make-coda-writer (slots capacity quantum))
                       (:copier nil))
  "Pre: slots privati preallocati e budget finiti. Post: ring vuoto, nessuna lease.
Guard e owner hanno CAS distinti; generation non viene mai riciclata."
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (quantum 64 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread))
  (owner nil :type (or null sb-thread:thread))
  (generation 0 :type index) (extracted 0 :type index))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-queue))
(defun %check-queue (queue)
  "Pre: guard posseduta, oppure coda appena costruita e non pubblicata.
Post: indici bounded e relazione FIFO coerente; INVARIANT-VIOLATION al guasto."
  (let ((capacity (coda-writer-capacity queue)) (head (coda-writer-head queue))
        (tail (coda-writer-tail queue)) (count (coda-writer-count queue)))
    (unless (and (<= 1 capacity +max-writer-capacity+)
                 (= (length (coda-writer-slots queue)) capacity)
                 (< head capacity) (< tail capacity) (<= count capacity))
      (error 'invariant-violation :reason :writer-queue-invariant))
    (unless (= tail (mod (+ head count) capacity))
      (error 'invariant-violation :reason :writer-queue-invariant)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) sb-thread:thread) %acquisisci-guard))
(defun %acquisisci-guard (queue)
  "Pre: operazione breve sul ring. Post: guard locale del thread corrente.
Un solo CAS, senza attesa; RESOURCE-EXHAUSTED se busy, INVARIANT-VIOLATION al guasto."
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))
    (unless (eq (coda-writer-guard queue) thread)
      (error 'invariant-violation :reason :writer-guard))
    thread))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %rilascia-guard))
(defun %rilascia-guard (queue thread)
  "Pre: guard acquisita da THREAD. Post: guard libera tramite un solo CAS.
INVARIANT-VIOLATION per proprietario diverso; nessuna attesa o recupero implicito."
  (unless (eq (coda-writer-guard queue) thread)
    (error 'invariant-violation :reason :writer-guard))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-guard queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) coda-writer) crea-coda-writer))
(defun crea-coda-writer (&key (capacity 1024) (quantum 64))
  "Pre: capacity e quantum interi tra 1 e 65536, indipendenti.
Post: ring SIMPLE-VECTOR privato allocato una volta; INVALID-ARGUMENT al rifiuto."
  (unless (and (typep capacity 'index) (<= 1 capacity +max-writer-capacity+))
    (error 'invalid-argument :reason :writer-configuration))
  (unless (and (typep quantum 'index) (<= 1 quantum +max-writer-quantum+))
    (error 'invalid-argument :reason :writer-configuration))
  (let ((queue (%make-coda-writer (make-array capacity :initial-element nil) capacity quantum)))
    (%check-queue queue)
    queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) %accoda-sotto-guard))
(defun %accoda-sotto-guard (queue message)
  "Pre: guard locale posseduta dal thread corrente, payload del produttore.
Post: una sola accettazione FIFO e count aggiornato; RESOURCE-EXHAUSTED se full
senza mutazioni, INVARIANT-VIOLATION per guard o indici incoerenti."
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (%check-queue queue)
  (when (= (coda-writer-count queue) (coda-writer-capacity queue))
    (error 'resource-exhausted :reason :writer-queue-full))
  (let ((tail (coda-writer-tail queue)))
    (setf (svref (coda-writer-slots queue) tail) message
          (coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))
          (coda-writer-count queue) (1+ (coda-writer-count queue))))
  (%check-queue queue)
  (coda-writer-count queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) accoda-messaggio))
(defun accoda-messaggio (queue message)
  "Pre: payload opaco posseduto dal chiamante, compreso NIL. Post: accettato in FIFO,
ownership alla coda, restituisce il count dopo l'accettazione. RESOURCE-EXHAUSTED
per full/busy senza mutare ring o payload; nessun callback, attesa o wakeup."
  (let ((thread (%acquisisci-guard queue)))
    (unwind-protect (%accoda-sotto-guard queue message)
      (%rilascia-guard queue thread))))
