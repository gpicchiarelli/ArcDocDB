;;; OWNER: controller mantiene ACTIVE esclusivo, senza writer o close concorrenti.
;;; SHARED: sole osservazioni dei legami immutabili; nessuna lettura di H o registro CSN.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (segmento-attivo-preparato) file-io) input-active-checkpoint))
(defun input-active-checkpoint (active)
  "Pre: risultato del preparatore ACTIVE. Post: capacità readonly canonica, senza I/O.
Non trasferisce ownership o certifica la frontiera attuale."
  (arcdocdb.get::segmento-get-file (arcdocdb.active::segmento-attivo-preparato-segment active)))

;;; REQ: REQ-AFF-001 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (segmento-attivo-preparato) null) verifica-active-checkpoint))
(defun verifica-active-checkpoint (active)
  "Pre: startup esclusivo, prima di ammettere traffico. Post: header ancora unico e durevole.
Prova sulle capacità esatte e salute del log; INVALID-ARGUMENT per log o file avanzato.
IO-FAULT dalla prova per capacità chiusa/faulted; nessuna syscall o modifica di CSN."
  (let* ((log (arcdocdb.active::segmento-attivo-preparato-log active))
         (file (arcdocdb.wal::log-io-file log)))
    (verifica-associazione-file (arcdocdb.active::segmento-attivo-preparato-association active)
                               (input-active-checkpoint active) file)
    (unless (eq (stato-log log) :open)
      (error 'invalid-argument :reason :control-active-log))
    (unless (and (= (posizione-scritta file) arcdocdb.storage.format:+segment-header-bytes+)
                 (= (posizione-durevole file) arcdocdb.storage.format:+segment-header-bytes+))
      (error 'invalid-argument :reason :control-active-advanced)))
  nil)

;;; REQ: REQ-FOR-001 REQ-REC-001
(declaim (ftype (function (segmento-attivo-preparato) u64) id-active-checkpoint))
(defun id-active-checkpoint (active)
  "Pre: capacità costruita dal preparatore ACTIVE. Post: identificativo dal suo header verificato.
Nessuna identità da pathname, descrittore o metadati derivati."
  (let ((segment (arcdocdb.active::segmento-attivo-preparato-segment active)))
    (logior (ash (arcdocdb.get::segmento-get-high segment) 32)
            (arcdocdb.get::segmento-get-low segment))))
