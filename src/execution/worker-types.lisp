;;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (contesto-worker-writer
             (:constructor %make-contesto-worker-writer (ready owner cursor)) (:copier nil))
  "Pre: lista valida e proprietario unico non rientrante. Post: IDLE senza obblighi.
Nessun thread creato; batch generation locale monotona e mai azzerata."
  (ready (error 'invariant-violation :reason :worker-state) :type lista-writer-pronti :read-only t)
  (owner (error 'invariant-violation :reason :worker-state) :type sb-thread:thread :read-only t)
  (cursor 0 :type index) (home 0 :type index)
  (writer nil :type (or null writer-programmabile))
  (lease 0 :type index) (pending 0 :type index) (batch-generation 0 :type index)
  (fault nil :type (or null condition))
  (state :idle :type (member :idle :claimed :running :batch :finishing :reschedule :faulted)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-owner-worker))
(defun %check-owner-worker (context)
  "Pre: contesto locale. Post: thread corrente proprietario; INVALID-ARGUMENT altrimenti."
  (unless (eq (contesto-worker-writer-owner context) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :worker-owner))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-libero-worker))
(defun %check-libero-worker (context)
  "Pre: owner verificato, IDLE. Post: riferimento, lease e debito vuoti; invarianti typed."
  (unless (null (contesto-worker-writer-writer context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-obbligo-worker))
(defun %check-obbligo-worker (context)
  "Pre: owner verificato, CLAIMED/RESCHEDULE. Post: writer senza lease/debito; invarianti typed."
  (unless (typep (contesto-worker-writer-writer context) 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-lease-worker))
(defun %check-lease-worker (context)
  "Pre: owner verificato. Post: writer e lease correnti; invarianti o lease invalida typed."
  (let ((writer (contesto-worker-writer-writer context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (%check-lease (writer-programmabile-queue writer) (contesto-worker-writer-lease context)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-attivo-worker))
(defun %check-attivo-worker (context)
  "Pre: owner verificato, RUNNING/FINISHING. Post: lease corrente senza batch; invarianti typed."
  (%check-lease-worker context)
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-batch-worker))
(defun %check-batch-worker (context)
  "Pre: owner verificato, BATCH. Post: lease corrente e batch positivo; invarianti typed."
  (%check-lease-worker context)
  (unless (plusp (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (unless (<= (contesto-worker-writer-pending context)
              (coda-writer-extracted
               (writer-programmabile-queue (contesto-worker-writer-writer context))))
    (error 'invariant-violation :reason :worker-state))
  (unless (plusp (contesto-worker-writer-batch-generation context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-worker))
(defun %check-worker (context)
  "Pre: accesso esclusivo non rientrante. Post: owner, indici e stato coerenti.
INVALID-ARGUMENT owner; indici privati sono invarianti, lease come verificatori delegati."
  (%check-owner-worker context)
  (unless (null (contesto-worker-writer-fault context))
    (error 'invariant-violation :reason :worker-state))
  (let ((size (length (lista-writer-pronti-partitions (contesto-worker-writer-ready context)))))
    (unless (< (contesto-worker-writer-cursor context) size)
      (error 'invariant-violation :reason :worker-state))
    (unless (< (contesto-worker-writer-home context) size)
      (error 'invariant-violation :reason :worker-state)))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-cursor context))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-home context))
  (case (contesto-worker-writer-state context)
    (:idle (%check-libero-worker context))
    ((:claimed :reschedule) (%check-obbligo-worker context))
    ((:running :finishing) (%check-attivo-worker context))
    (:batch (%check-batch-worker context))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer symbol) null) %richiedi-worker))
(defun %richiedi-worker (context state)
  "Pre: owner esclusivo e fase richiesta. Post: forma e fase verificate.
RESOURCE-EXHAUSTED :WORKER-STATE per operazione fuori fase; verificatori typed."
  (%check-worker context)
  (unless (eq (contesto-worker-writer-state context) state)
    (error 'resource-exhausted :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti &key (:start t)) contesto-worker-writer) crea-contesto-worker-writer))
(defun crea-contesto-worker-writer (ready &key (start 0))
  "Pre: lista valida; creazione sul thread proprietario prima del percorso caldo.
Post: IDLE preallocato con cursore START; INVALID-ARGUMENT indice, invarianti lista."
  (%partizione-verificata ready start)
  (let ((context (%make-contesto-worker-writer ready sb-thread:*current-thread* (the index start))))
    (%check-worker context)
    context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :claimed :running :batch :finishing :reschedule :faulted)) stato-worker-writer))
(defun stato-worker-writer (context)
  "Pre: owner corrente. Post: fase locale, leggibile anche per diagnosi di fault.
INVALID-ARGUMENT owner; nessuna mutazione o verifica del writer sotto guard."
  (%check-owner-worker context)
  (contesto-worker-writer-state context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null writer-programmabile)) writer-worker-writer))
(defun writer-worker-writer (context)
  "Pre: owner corrente. Post: riferimento locale opaco per diagnosi/integrazione.
INVALID-ARGUMENT owner; non trasferisce obblighi né consente di duplicarli."
  (%check-owner-worker context)
  (contesto-worker-writer-writer context))


;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null condition)) errore-worker-writer))
(defun errore-worker-writer (context)
  "Pre: owner corrente. Post: condizione originale del fault locale o NIL.
INVALID-ARGUMENT owner; non resetta il fault né trasferisce lease/obblighi."
  (%check-owner-worker context)
  (contesto-worker-writer-fault context))
