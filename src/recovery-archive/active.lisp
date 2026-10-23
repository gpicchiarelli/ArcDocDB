;;; OWNER: recovery esclusivo della Serie nel pool I/O; controller conserva tutti i FD e namespace.
;;; SHARED: sola lettura delle decisioni dell'Archivio, nessun nuovo gate o coordinamento tra Serie.
(in-package #:arcdocdb.recovery.archive)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (arcdocdb.control:control-recuperato decisioni-recuperate octets) null)
                verifica-archivio-active))
(defun verifica-archivio-active (control decisions scratch)
  "Pre: risultati completi, recovery esclusivo. Post: stesso ambito canonico GET e decision log aperto.
Alias UUID rifiutato prima di ogni I/O ACTIVE; INVALID-ARGUMENT per Archivio differente o alias.
Non certifica la correttezza del bootstrap catalogo; nessuna scrittura o osservazione del segmento."
  (let ((archive (decisioni-recuperate-archive decisions))
        (view (arcdocdb.control::control-recuperato-view control)))
    (unless (eq (archivio-recovery-scope archive) (arcdocdb.get::vista-get-serie-scope view))
      (error 'invalid-argument :reason :active-recovery-archive))
    (when (eq scratch (archivio-recovery-identity archive))
      (error 'invalid-argument :reason :archive-recovery-alias))
    (arcdocdb.io::esigi-aperto (decisioni-recuperate-input decisions) :input))
  nil)

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-002 REQ-AFF-008 REQ-AFF-009
(declaim (ftype (function (arcdocdb.control:control-recuperato file-io index decisioni-recuperate octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-batch-records u32) (:max-batch-bytes index) (:max-records index)
                               (:max-prepared u32) (:max-outcomes u32)) arcdocdb.recovery.active:active-recuperato)
                leggi-active-con-decisioni))
(defun leggi-active-con-decisioni (control input size decisions scratch
                                 &key (chunk-bytes 65536) (max-bytes 268435456) (max-batches 65536)
                                      (max-batch-records 65536) (max-batch-bytes 67108864)
                                      (max-records 1048576) (max-prepared 65536) (max-outcomes 65536))
  "Pre: CONTROL autorevole, decision log completo dello stesso Archivio, EOF ACTIVE fisico attestato.
File/FD/namespace congelati e aperti fino alla pubblicazione; scratch esclusivo nel compito I/O.
Post: recovery ACTIVE canonico con decisioni provenienti da header/replay verificati e ambito identico.
Controlli prima dell'I/O ACTIVE; risultato solo se il decision log resta aperto al ritorno.
Propaga errori originali; nessuna pubblicazione, troncatura, nuovo CSN o certificazione dell'intero recovery."
  (verifica-archivio-active control decisions scratch)
  (let ((result (arcdocdb.recovery.active:leggi-active-recuperato
                 control input size (decisioni-recuperate-table decisions) scratch
                 :chunk-bytes chunk-bytes :max-bytes max-bytes :max-batches max-batches
                 :max-batch-records max-batch-records :max-batch-bytes max-batch-bytes
                 :max-records max-records :max-prepared max-prepared :max-outcomes max-outcomes)))
    (arcdocdb.io::esigi-aperto (decisioni-recuperate-input decisions) :input)
    result))
