;;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t index) null) %assegna-worker))
(defun %assegna-worker (context writer home)
  "Pre: IDLE/RESCHEDULE verificato, trasferimento riuscito dal ring. Post: CLAIMED.
INVARIANT-VIOLATION writer/fase incoerenti; nessun rollback dopo fault interno."
  (%check-worker context)
  (unless (typep writer 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (case (contesto-worker-writer-state context)
    ((:idle :reschedule) nil)
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (setf (contesto-worker-writer-writer context) writer
        (contesto-worker-writer-home context) home
        (contesto-worker-writer-state context) :claimed)
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :empty :busy) index &optional)) prendi-writer-worker))
(defun prendi-writer-worker (context)
  "Pre: IDLE e owner corrente. Post: CLAIMED con obbligo/home, oppure IDLE con
cursore ruotato per EMPTY/BUSY. Verificatori typed, fase errata RESOURCE-EXHAUSTED;
EMPTY resta locale, mai prova di quiescenza per parcheggio o arresto."
  (%passo-worker (context (:worker-state) ())
  (%richiedi-worker context :idle)
  (let ((ready (contesto-worker-writer-ready context)))
    (multiple-value-bind (writer status next)
        (preleva-writer-pronto ready (contesto-worker-writer-cursor context))
      (setf (contesto-worker-writer-cursor context) next)
      (case status
        (:writer
         (%assegna-worker context writer
           (mod (+ next (1- (length (lista-writer-pronti-partitions ready))))
                (length (lista-writer-pronti-partitions ready))))
         (values writer :claimed next))
        ((:empty :busy) (%check-worker context) (values nil status next))
        (otherwise (error 'invariant-violation :reason :worker-state)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) index) inizia-tratto-worker))
(defun inizia-tratto-worker (context)
  "Pre: CLAIMED senza lease. Post: RUNNING con lease del thread corrente.
Busy conserva CLAIMED; not-ready/generation restano fault permanenti del compito;
condizioni handoff e verificatori typed, nessun retry o perdita del riferimento."
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%richiedi-worker context :claimed)
  (let ((lease (inizia-tratto-writer (contesto-worker-writer-writer context))))
    (setf (contesto-worker-writer-lease context) lease
          (contesto-worker-writer-state context) :running)
    (%check-worker context)
    lease)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :published) index &optional)) ricircola-worker))
(defun ricircola-worker (context)
  "Pre: RESCHEDULE, obbligo unico, owner corrente. Post: full trasferisce nuova
testa al contesto CLAIMED; room pubblica e libera IDLE. Busy conserva obbligo.
Condizioni ready/verificatori typed; nessun retry o dedup, count full invariato."
  (%passo-worker (context (:worker-state :ready-queue-busy) ())
  (%richiedi-worker context :reschedule)
  (multiple-value-bind (writer status count)
      (ricircola-writer-pronto (contesto-worker-writer-ready context)
                              (contesto-worker-writer-home context)
                              (contesto-worker-writer-writer context))
    (case status
      (:writer (%assegna-worker context writer (contesto-worker-writer-home context))
               (values writer :claimed count))
      (:published
       (unless (null writer) (error 'invariant-violation :reason :worker-state))
       (setf (contesto-worker-writer-writer context) nil
             (contesto-worker-writer-state context) :idle)
       (%check-worker context)
       (values nil :published count))
      (otherwise (error 'invariant-violation :reason :worker-state))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t) null) adotta-writer-worker))
(defun adotta-writer-worker (context writer home)
  "Pre: IDLE, obbligo unico non nel ring affidato al caller e home stabile.
Post: CLAIMED sul contesto, obbligo trasferito dal caller; INVALID-ARGUMENT
writer/home prima delle scritture, fase/owner/verificatori typed. Nessun dedup."
  (%passo-worker (context (:worker-state) (:worker-writer :ready-target))
  (%richiedi-worker context :idle)
  (unless (typep writer 'writer-programmabile)
    (error 'invalid-argument :reason :worker-writer))
  (%partizione-verificata (contesto-worker-writer-ready context) home)
  (%assegna-worker context writer (the index home))
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer)
                         (values writer-programmabile index &optional)) cede-writer-worker))
(defun cede-writer-worker (context)
  "Pre: CLAIMED/RESCHEDULE senza lease o batch. Post: IDLE, obbligo al caller
con home, generation conservata; mai cedere una lease attiva. Fase/owner e
verificatori typed; nessuna pubblicazione implicita, il caller non abbandona il ref."
  (%passo-worker (context (:worker-state) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:claimed :reschedule) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (let ((writer (contesto-worker-writer-writer context))
        (home (contesto-worker-writer-home context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (setf (contesto-worker-writer-writer context) nil
          (contesto-worker-writer-state context) :idle)
    (%check-worker context)
    (values writer home))))
