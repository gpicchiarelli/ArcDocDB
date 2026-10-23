;;;; Due capacità per tratto; nessuna coda, attesa, lookup o callback aggiunta.
;;; OWNER: campi del collegamento locali al thread creatore del contesto worker.
;;; SHARED: soltanto owner/health della Serie; nessuna scrittura globale per messaggio.
(in-package #:arcdocdb.execution.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defstruct (collegamento-worker-serie
             (:constructor %make-collegamento-worker-serie (context writer controller))
             (:copier nil))
  "Pre: associazione writer/Serie unica stabilita all'avvio dal caller.
Post: IDLE preallocato, token locali monotoni. Nessuna allocazione per tratto."
  (context nil :type contesto-worker-writer :read-only t)
  (writer nil :type writer-programmabile :read-only t)
  (controller nil :type controllore-serie :read-only t)
  (generation 0 :type index) (writer-lease 0 :type index) (series-lease 0 :type index)
  (state :idle :type (member :idle :active :closing :faulted))
  (fault nil :type (or null condition)))

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie) null) %check-owner-worker-serie))
(defun %check-owner-worker-serie (link)
  "Pre: collegamento locale. Post: owner del contesto verificato prima dei campi.
INVALID-ARGUMENT :worker-owner sul thread estraneo, senza poisoning o mutazioni."
  (arcdocdb.execution::%check-owner-worker (collegamento-worker-serie-context link)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie) null) %check-writer-worker-serie))
(defun %check-writer-worker-serie (link)
  "Pre: owner verificato, tratto iniziato. Post: writer e lease catturata correnti.
INVARIANT-VIOLATION per bypass/stale, verificatore worker delegato; nessun pop."
  (let ((context (collegamento-worker-serie-context link)))
    (unless (plusp (collegamento-worker-serie-generation link))
      (error 'invariant-violation :reason :worker-serie-generation))
    (unless (eq (writer-worker-writer context) (collegamento-worker-serie-writer link))
      (error 'invariant-violation :reason :worker-serie-binding))
    (unless (plusp (collegamento-worker-serie-writer-lease link))
      (error 'invariant-violation :reason :worker-serie-lease))
    (unless (= (arcdocdb.execution::contesto-worker-writer-lease context)
               (collegamento-worker-serie-writer-lease link))
      (error 'invariant-violation :reason :worker-serie-lease))
    (arcdocdb.execution::%check-worker context))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie) null) %check-worker-serie))
(defun %check-worker-serie (link)
  "Pre: owner esclusivo. Post: forma coerente e capacità ancora possedute.
Invarianti typed; CLOSING con Serie già ceduta non legge il controller."
  (%check-owner-worker-serie link)
  (unless (null (collegamento-worker-serie-fault link))
    (error 'invariant-violation :reason :worker-serie-state))
  (case (collegamento-worker-serie-state link)
    (:idle
     (unless (zerop (collegamento-worker-serie-writer-lease link))
       (error 'invariant-violation :reason :worker-serie-lease))
     (unless (zerop (collegamento-worker-serie-series-lease link))
       (error 'invariant-violation :reason :worker-serie-lease)))
    (:active
     (%check-writer-worker-serie link)
     (unless (member (stato-worker-writer (collegamento-worker-serie-context link)) '(:running :batch))
       (error 'invariant-violation :reason :worker-serie-state))
     (arcdocdb.series::%check-owner (collegamento-worker-serie-controller link)
                                   (collegamento-worker-serie-series-lease link)))
    (:closing
     (%check-writer-worker-serie link)
     (unless (member (stato-worker-writer (collegamento-worker-serie-context link)) '(:running :finishing))
       (error 'invariant-violation :reason :worker-serie-state)))
    (otherwise (error 'invariant-violation :reason :worker-serie-state)))
  nil)

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie list) null) %require-worker-serie)
         (ftype (function (collegamento-worker-serie t) null) %check-token-worker-serie))
(defun %require-worker-serie (link states)
  "Pre: owner esclusivo, elenco di fasi letterale bounded. Post: fase ammessa.
RESOURCE-EXHAUSTED fuori fase; verifica delle capacità solo nella fase ammessa."
  (unless (member (collegamento-worker-serie-state link) states)
    (error 'resource-exhausted :reason :worker-serie-state))
  (%check-worker-serie link)
  nil)

;;; REQ: REQ-CON-002 REQ-AFF-008
(defun %check-token-worker-serie (link token)
  "Pre: owner e fase verificati. Post: token positivo della coppia link/tratto.
INVALID-ARGUMENT per tipo, zero o generation stale, prima di qualunque mutazione."
  (unless (typep token 'index) (error 'invalid-argument :reason :worker-serie-token))
  (unless (plusp token) (error 'invalid-argument :reason :worker-serie-token))
  (unless (= token (collegamento-worker-serie-generation link))
    (error 'invalid-argument :reason :worker-serie-token))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer writer-programmabile controllore-serie)
                         collegamento-worker-serie) crea-collegamento-worker-serie))
(defun crea-collegamento-worker-serie (context writer controller)
  "Pre: avvio sul thread del worker, mapping writer/Serie unico imposto dal caller.
Post: binding immutabile IDLE; INVALID-ARGUMENT owner, nessun claim o nuova lease."
  (arcdocdb.execution::%check-owner-worker context)
  (let ((link (%make-collegamento-worker-serie context writer controller)))
    (%check-worker-serie link)
    link))

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie) (member :idle :active :closing :faulted)) stato-worker-serie)
         (ftype (function (collegamento-worker-serie) (or null condition)) errore-worker-serie))
(defun stato-worker-serie (link)
  "Pre: owner corrente. Post: fase locale, anche dopo fault; INVALID-ARGUMENT owner."
  (%check-owner-worker-serie link)
  (collegamento-worker-serie-state link))

;;; REQ: REQ-CON-002 REQ-AFF-008
(defun errore-worker-serie (link)
  "Pre: owner corrente. Post: condizione originale o NIL; INVALID-ARGUMENT owner.
Non trasferisce capacità né ripristina un tratto faulted."
  (%check-owner-worker-serie link)
  (collegamento-worker-serie-fault link))
