;;;; Routing per ordinal immutabile; nessun hash o ricerca nel percorso caldo.
;;; OWNER: registro costruito prima della pubblicazione; tabella del solo worker.
;;; SHARED: registro read-only tra worker, letto una volta per tratto (ADR-0045 §8).
(in-package #:arcdocdb.execution.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defconstant +max-worker-series-routes+ (1+ arcdocdb.execution::+max-writer-routing-index+))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defstruct (registro-worker-serie
             (:constructor %make-registro-worker-serie (writers controllers)) (:copier nil))
  "Pre: vettori privati, mapping bijettivo e ordinal writer uguale allo slot.
Post: registro immutabile; nessun accesso allo stato vivo o alle lease della Serie."
  (writers #() :type simple-vector :read-only t)
  (controllers #() :type simple-vector :read-only t))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defstruct (tabella-worker-serie
             (:constructor %make-tabella-worker-serie (context registry links)) (:copier nil))
  "Pre: contesto owner-only e un binding per ogni slot del registro.
Post: tabella preallocata, non migrabile; collegamenti mutabili solo sul worker."
  (context nil :type contesto-worker-writer :read-only t)
  (registry nil :type registro-worker-serie :read-only t)
  (links #() :type simple-vector :read-only t))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (registro-worker-serie) index) %routing-size))
(defun %routing-size (registry)
  "Pre: registro costruito e pubblicato immutabile. Post: dimensione valida.
INVARIANT-VIOLATION per shape corrotta; non scansiona o muta gli elementi."
  (let ((size (length (registro-worker-serie-writers registry))))
    (unless (<= 1 size +max-worker-series-routes+)
      (error 'invariant-violation :reason :worker-serie-routing))
    (unless (= size (length (registro-worker-serie-controllers registry)))
      (error 'invariant-violation :reason :worker-serie-routing))
    size))
