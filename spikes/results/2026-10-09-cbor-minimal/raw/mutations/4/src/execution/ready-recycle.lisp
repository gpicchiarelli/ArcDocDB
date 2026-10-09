;;;; Ricircolo bounded: pubblica e prende una testa nello stesso ring pieno.
;;; OWNER: il ring possiede A dopo successo; il chiamante possiede la testa restituita.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una operazione per tratto, mai per messaggio.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values writer-programmabile (member :writer) index &optional))
                %scambia-pronto))
(defun %scambia-pronto (partition writer)
  "Pre: guard corrente, ring pieno, obbligo unico. Post: testa al caller e WRITER
in coda, count invariato. INVARIANT-VIOLATION per forma, capienza o testa invalida."
  (%check-pronta partition)
  (unless (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'invariant-violation :reason :ready-recycle-full))
  (let* ((head (partizione-pronta-head partition))
         (old (svref (partizione-pronta-slots partition) head))
         (next (mod (1+ head) (partizione-pronta-capacity partition))))
    (unless (typep old 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) writer
          (partizione-pronta-head partition) next
          (partizione-pronta-tail partition) next)
    (%check-pronta partition)
    (values old :writer (partizione-pronta-count partition))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                %ricircola-pronto))
(defun %ricircola-pronto (partition writer)
  "Pre: guard corrente e obbligo unico. Post: pubblicato, o testa e slot scambiati.
INVARIANT-VIOLATION per ring o payload incoerenti; nessun rifiuto per ring pieno."
  (%check-pronta partition)
  (if (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
      (%scambia-pronto partition writer)
      (values nil :published (%pubblica-pronto partition writer))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                ricircola-writer-pronto))
(defun ricircola-writer-pronto (ready shard writer)
  "Pre: obbligo :SCHEDULE unico e caller capace di prendere un altro writer.
Post: NIL/:PUBLISHED/count se spazio; testa/:WRITER/capacity se pieno: nuovo
obbligo al ring, testa al caller. INVALID-ARGUMENT shard/writer; RESOURCE-EXHAUSTED
busy conserva obbligo. Invarianti fail-stop; nessun retry, attesa o deduplicazione."
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%ricircola-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))
