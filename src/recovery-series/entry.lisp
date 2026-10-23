;;; OWNER: preflight esclusivo, nessuna lettura di header o dati; fonti prestano capacità readonly.
;;; SHARED: solo CONTROL e limiti immutabili, senza nuove tabelle o risorse possedute.
(in-package #:arcdocdb.recovery.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (control-recuperato arcdocdb.io:file-io u64 keyword index octets
                          limiti-recovery-serie) index) verifica-fonte-serie))
(defun verifica-fonte-serie (control file id state size scratch limits)
  "Pre: riga viva del set, nessun close concorrente, EOF dallo stesso FD. Post: byte da leggere autorevoli.
Stato/ID devono appartenere al CONTROL; P CLOSED non sostituito con EOF e P <= SIZE obbligatorio.
Preflight canonico senza letture; condizioni originali propagate, scratch non modificato."
  (multiple-value-bind (expected prefix outcomes) (trova-segmento (manifest-control-recuperato control) id)
    (unless (eq expected state) (error 'invalid-argument :reason :series-recovery-source-state))
    (case state
      (:active
       (unless (and (= id (segmento-attivo (manifest-control-recuperato control))) (plusp id))
         (error 'invalid-argument :reason :series-recovery-active-id))
       (arcdocdb.recovery.active::verifica-lettura-active
        control file size scratch (limits-chunk limits) (limits-bytes limits)
        (limits-batches limits) (limits-batch-records limits) (limits-batch-bytes limits))
       size)
      (:closed
       (unless (<= prefix size) (error 'invalid-argument :reason :series-recovery-source-size))
       (when (> outcomes (limits-closure limits))
         (error 'resource-exhausted :reason :series-recovery-closure-budget))
       (let ((checked (arcdocdb.recovery.closed::verifica-lettura-closed
                       control file id scratch (limits-chunk limits) (limits-bytes limits)
                       (limits-batches limits) (limits-batch-records limits)
                       (limits-batch-bytes limits) (limits-closure limits))))
         (unless (= checked prefix) (error 'invariant-violation :reason :series-recovery-prefix))
         checked))
      (otherwise (error 'invariant-violation :reason :series-recovery-source-state)))))
