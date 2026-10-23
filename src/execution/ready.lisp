;;;; Passaggi degli obblighi :schedule; nessuno stato membership o cleanup writer.
;;; OWNER: obbligo al chiamante prima di publish, al ring, poi al worker dopo pop.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) (or null sb-thread:thread)) %prendi-guard-pronta))
(defun %prendi-guard-pronta (partition)
  "Pre: accesso breve al ring. Post: guard del thread corrente oppure NIL se busy.
Un solo CAS, nessuna attesa; INVARIANT-VIOLATION al guasto della proprietà."
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (partizione-pronta-guard partition) nil thread))
      (return-from %prendi-guard-pronta nil))
    (unless (eq (partizione-pronta-guard partition) thread)
      (error 'invariant-violation :reason :ready-queue-guard))
    thread))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta sb-thread:thread) null) %rilascia-guard-pronta))
(defun %rilascia-guard-pronta (partition thread)
  "Pre: guard posseduta da THREAD. Post: guard libera con un CAS verificato.
INVARIANT-VIOLATION per proprietà errata; nessun retry o recupero implicito."
  (unless (eq (partizione-pronta-guard partition) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  (unless (eq (sb-ext:compare-and-swap (partizione-pronta-guard partition) thread nil) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile) index) %pubblica-pronto))
(defun %pubblica-pronto (partition writer)
  "Pre: guard corrente e obbligo unico del chiamante. Post: una accettazione FIFO.
RESOURCE-EXHAUSTED se full prima della mutazione; INVARIANT-VIOLATION al guasto."
  (%check-pronta partition)
  (when (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'resource-exhausted :reason :ready-queue-full))
  (let ((tail (partizione-pronta-tail partition)))
    (unless (null (svref (partizione-pronta-slots partition) tail))
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) tail) writer
          (partizione-pronta-tail partition) (mod (1+ tail) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1+ (partizione-pronta-count partition))))
  (%check-pronta partition)
  (partizione-pronta-count partition))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty) &optional))
                %preleva-pronto))
(defun %preleva-pronto (partition)
  "Pre: guard corrente. Post: riferimento FIFO al worker, slot liberato; NIL/:EMPTY
se vuoto. INVARIANT-VIOLATION per forma o payload incoerente, fail-stop del chiamante."
  (%check-pronta partition)
  (when (zerop (partizione-pronta-count partition))
    (return-from %preleva-pronto (values nil :empty)))
  (let* ((head (partizione-pronta-head partition))
         (writer (svref (partizione-pronta-slots partition) head)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) nil
          (partizione-pronta-head partition) (mod (1+ head) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1- (partizione-pronta-count partition)))
    (%check-pronta partition)
    (values writer :writer)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t) index) pubblica-writer-pronto))
(defun pubblica-writer-pronto (ready shard writer)
  "Pre: un unico obbligo :SCHEDULE da pubblicare una sola volta. Post: count locale,
obbligo al ring. INVALID-ARGUMENT per shard/writer; RESOURCE-EXHAUSTED full/busy
conserva obbligo al chiamante. Il retry non accetta nuovamente i payload nel writer."
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%pubblica-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty :busy) &optional))
                %prova-pronta))
(defun %prova-pronta (partition)
  "Pre: una partizione candidata. Post: writer/empty dal ring oppure NIL/:BUSY.
Un CAS senza spin; cleanup dopo acquisizione verificata, invarianti fail-stop."
  (let ((thread (%prendi-guard-pronta partition)))
    (unless thread (return-from %prova-pronta (values nil :busy)))
    (unwind-protect (%preleva-pronto partition)
      (%rilascia-guard-pronta partition thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t)
                         (values (or null writer-programmabile) (member :writer :empty :busy) index &optional))
                preleva-writer-pronto))
(defun preleva-writer-pronto (ready start)
  "Pre: start indice valido. Post: al più K tentativi circolari; writer/:WRITER e
cursore seguente alla partizione servita, oppure NIL e :BUSY/:EMPTY con start+1.
EMPTY sono osservazioni locali, non quiescenza globale; un worker conserva il
riferimento fino all'avvio riuscito. INVALID-ARGUMENT indice; invarianti fail-stop."
  (%partizione-verificata ready start)
  (let* ((size (length (lista-writer-pronti-partitions ready)))
         (cursor (the index start)) (busy nil))
    (dotimes (i size)
      (multiple-value-bind (writer status) (%prova-pronta (%partizione-verificata ready cursor))
        (case status
          (:writer (return-from preleva-writer-pronto
                     (values writer :writer (mod (1+ cursor) size))))
          (:busy (setf busy t))
          (:empty nil)
          (otherwise (error 'invariant-violation :reason :ready-queue-invariant))))
      (setf cursor (mod (1+ cursor) size)))
    (values nil (if busy :busy :empty) (mod (1+ (the index start)) size))))
