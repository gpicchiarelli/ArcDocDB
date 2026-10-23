;;; OWNER: compito I/O del recovery, prima di checkpoint/runtime/ammissione; set resta del caller.
;;; SHARED: promozione di un solo nome della Serie, nessun lock o dato condiviso fra Serie.
(in-package #:arcdocdb.recovery.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-STO-003 REQ-STO-006 REQ-AFF-001 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (arcdocdb.io:file-io recovery-sources integer
                          (or active-recuperato arcdocdb.recovery.closed:closed-recuperato)) boolean)
                stabilizza-nome-fonte-recuperata))
(defun stabilizza-nome-fonte-recuperata (directory sources position recovered)
  "Pre: catalogo/CONTROL autorevoli, token semantico della fonte e namespace esclusivo nel pool I/O.
Set e FD restano vivi/stabili; chiamare dopo il gate completo del recovery, prima di ammettere traffico.
Post: nome canonico definitivo dello stesso FD e parent sincronizzato; T rinomina, NIL già definitivo.
Decisione già nell'EDIT autorevole; rinomina esclusiva e fsync completano, senza nuovo swap CONTROL.
Propaga rifiuti prima degli effetti; uscita incompleta dell'I/O => directory FAULTED senza retry.
Nessun close, nuovo ACTIVE, rimozione, ricostruzione indice o ammissione; forma nel set resta osservazione iniziale."
  (multiple-value-bind (id state form file size) (fonte-recovery sources position)
    (declare (ignore form)) ; snapshot del nome acquisito: il ramo idempotente osserva il namespace reale.
    (let ((control
            (etypecase recovered
              (active-recuperato (verifica-active-stabilizzabile recovered file id state size))
              (arcdocdb.recovery.closed:closed-recuperato
               (verifica-closed-stabilizzabile recovered file id state size)))))
      (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
      (arcdocdb.io:stabilizza-nome-temporaneo
       directory file (arcdocdb.recovery.manifest::nome-fonte-recovery id :temporary)
       (arcdocdb.recovery.manifest::nome-fonte-recovery id :final)))))
