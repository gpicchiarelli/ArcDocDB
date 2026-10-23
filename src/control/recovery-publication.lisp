;;; OWNER: recovery esclusivo mantiene vecchio log, vista e namespace fino alla conclusione del publisher.
;;; SHARED: manifest consultati in sola lettura; il gettone unico resta quello del publisher esistente.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-001 REQ-AFF-018
(declaim (ftype (function (control-preparato control-recuperato) control-pubblicato)
                pubblica-control-validato))
(defun pubblica-control-validato (prepared recovered)
  "Pre: pool I/O, recovery esclusivo; inventario, vecchio ACTIVE ed esiti già riconciliati.
Il file letto e il namespace restano immutati; nuova chiusura dal prefisso autorevole del vecchio ACTIVE.
Post: stessa vista canonica, transizione conservativa verificata prima di claim/rinomina; risultato durevole.
Punto di atomicità: renameat di control.log, conferma dopo fsync parent dal publisher canonico.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED/IO-FAULT prima del claim; dopo, errori propagano e gettone FAULTED.
Non crea un secondo gettone, ripete letture, chiude FD, ammette traffico o completa il Recovery Manager."
  (let* ((active (control-preparato-active prepared))
         (view (arcdocdb.get::segmento-get-owner (arcdocdb.active::segmento-attivo-preparato-segment active)))
         (previous (control-recuperato-input recovered)))
    (unless (eq view (control-recuperato-view recovered))
      (error 'invalid-argument :reason :control-recovery-view))
    (arcdocdb.io::esigi-aperto previous :input)
    (arcdocdb.recovery.manifest:verifica-transizione-recovery
     (control-recuperato-manifest recovered) (control-preparato-manifest prepared))
    (pubblica-control-recuperato prepared previous)))
