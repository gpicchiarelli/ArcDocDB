;;; OWNER: recovery esclusivo, set posseduto e token semantico prestati, namespace stabile.
;;; SHARED: legami readonly fra token e capacità; nessun nuovo stato o lock fra Serie.
(in-package #:arcdocdb.recovery.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-008
(declaim (ftype (function (active-recuperato arcdocdb.io:file-io u64 keyword index) control-recuperato)
                verifica-active-stabilizzabile))
(defun verifica-active-stabilizzabile (recovered file id state size)
  "Pre: riga del set aperto, token ACTIVE canonico. Post: stesso FD, ID, EOF e CONTROL ancora aperto.
INVALID-ARGUMENT per fonte diversa, IO-FAULT per lifetime; nessun nome letto o modificato."
  (let ((segment (arcdocdb.recovery.active::active-recuperato-segment recovered))
        (control (arcdocdb.recovery.active::active-recuperato-control recovered)))
    (unless (and (eq state :active) (= id (arcdocdb.recovery.active::id-active-recuperato recovered))
                 (eq file (arcdocdb.get::segmento-get-file segment))
                 (= size (arcdocdb.recovery.active::active-recuperato-size recovered)))
      (error 'invalid-argument :reason :recovery-stabilization-active-source))
    (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
    (unless (= id (segmento-attivo (manifest-control-recuperato control)))
      (error 'invariant-violation :reason :recovery-stabilization-active-manifest))
    control))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (arcdocdb.recovery.closed:closed-recuperato arcdocdb.io:file-io u64 keyword index)
                         control-recuperato) verifica-closed-stabilizzabile))
(defun verifica-closed-stabilizzabile (recovered file id state size)
  "Pre: riga del set aperto, token CLOSED canonico. Post: stesso FD/ID e P del CONTROL, P entro EOF.
INVALID-ARGUMENT per fonte diversa; IO-FAULT per lifetime; ID u64 incluso zero senza restringimenti."
  (let ((control (arcdocdb.recovery.closed::closed-recuperato-control recovered)))
    (unless (and (eq state :closed) (= id (arcdocdb.recovery.closed::closed-recuperato-id recovered))
                 (eq file (arcdocdb.recovery.closed::closed-recuperato-input recovered))
                 (<= (arcdocdb.recovery.closed::closed-recuperato-prefix recovered) size))
      (error 'invalid-argument :reason :recovery-stabilization-closed-source))
    (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
    (multiple-value-bind (expected prefix outcomes) (trova-segmento (manifest-control-recuperato control) id)
      (declare (ignore outcomes)) ; conteggio già validato dal token semantico, non esito di errore.
      (unless (and (eq expected :closed) (= prefix (arcdocdb.recovery.closed::closed-recuperato-prefix recovered)))
        (error 'invariant-violation :reason :recovery-stabilization-closed-manifest)))
    control))
