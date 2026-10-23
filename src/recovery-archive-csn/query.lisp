;;; OWNER: risultato consegnato al controller; getter scalari non rileggono le fonti o il catalogo.
;;; SHARED: nessuna mutazione, attesa, cache o nuova identità di Archivio.
(in-package #:arcdocdb.recovery.archive.csn)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery) index) numero-serie-recovery))
(defun numero-serie-recovery (set)
  "Pre: insieme completo costruito. Post: cardinalità della copia posseduta, nessun vettore esportato.
TYPE-ERROR per tipi invalidi; nessuna certificazione aggiuntiva del catalogo."
  (length (insieme-serie-recovery-views set)))

;;; REQ: REQ-REC-001 REQ-MVC-006
(declaim (ftype (function (piano-csn-archivio) (values boolean u64 &optional)) massimo-csn-archivio))
(defun massimo-csn-archivio (plan)
  "Pre: piano completato. Post: presenza e massimo CSN osservato; NIL/0 distinto da T/0.
TYPE-ERROR per tipi invalidi; non certifica salute futura, visibilità o assenza di obblighi pendenti."
  (values (piano-csn-archivio-present plan) (piano-csn-archivio-maximum plan)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (piano-csn-archivio) (values index index &optional)) statistiche-piano-csn-archivio))
(defun statistiche-piano-csn-archivio (plan)
  "Pre: piano completo. Post: numero Serie e numero segmenti, inclusi i loro ACTIVE e tutti i CLOSED.
TYPE-ERROR per tipi invalidi; non è il conteggio dei file fisici, dei record o delle transazioni."
  (values (piano-csn-archivio-series plan) (piano-csn-archivio-segments plan)))

;;; REQ: REQ-REC-001 REQ-MVC-006
(declaim (ftype (function (piano-csn-archivio) (values u32 u32 &optional)) parole-base-csn-archivio))
(defun parole-base-csn-archivio (plan)
  "Pre: piano completo. Post: high/low dell'ultimo CSN, zero/zero se nessuna fonte; nessun incremento.
Base M per il futuro registro, non M+1; massimo u64 resta rappresentabile senza wrap.
TYPE-ERROR per tipi invalidi; non crea né autorizza un altro allocatore nello stesso Archivio."
  (let ((maximum (piano-csn-archivio-maximum plan)))
    (values (ldb (byte 32 32) maximum) (ldb (byte 32 0) maximum))))
