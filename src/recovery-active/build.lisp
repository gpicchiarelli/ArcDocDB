;;; OWNER: compito I/O di recovery esclusivo; scratch privato per lettura, scanner e semantica.
;;; SHARED: risultato immutabile, nessuna pubblicazione, attesa o scrittura tra Serie.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-AFF-008
(declaim (ftype (function (octets index segmento-get u64 index index u32 index index)
                         (values index (member :complete :tail) index index &optional))
                verifica-prefisso-active))
(defun verifica-prefisso-active (buffer size segment id bytes batches batch-records batch-bytes records)
  "Pre: header canonico e corpo fino a EOF attestato, capacità readonly. Post: prefisso e conteggi autorevoli.
ACTIVE deve avere origine writer; coda classificata solo dopo ricerca completa dei testimoni.
CORRUPTION-DETECTED/LOG-CORRUPTION o budget propagati; nessun replay o effetto durevole."
  (unless (= (arcdocdb.get::segmento-get-origin segment) arcdocdb.storage.format::+writer-origin+)
    (error 'corruption-detected :reason :active-recovery-origin))
  (multiple-value-bind (prefix status actual-batches count)
      (scansiona-log buffer +segment-header-bytes+ size id :version (arcdocdb.get::segmento-get-version segment)
                    :log-kind :segment :file-size size :max-bytes bytes :max-batches batches
                    :max-batch-records batch-records :max-batch-bytes batch-bytes :max-search-bytes bytes)
    (when (> count records) (error 'resource-exhausted :reason :active-recovery-record-budget))
    (unless (and (<= +segment-header-bytes+ prefix size)
                 (if (eq status :complete) (= prefix size) (< prefix size)))
      (error 'invariant-violation :reason :active-recovery-prefix))
    (values prefix status actual-batches count)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-STO-003 REQ-TXM-005 REQ-TXM-007 REQ-AFF-002 REQ-AFF-008 REQ-AFF-009
(declaim (ftype (function (control-recuperato file-io index arcdocdb.recovery.decisions::decision-table octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-batch-records u32) (:max-batch-bytes index) (:max-records index)
                               (:max-prepared u32) (:max-outcomes u32)) active-recuperato)
                leggi-active-recuperato))
(defun leggi-active-recuperato (control input size decisions scratch
                              &key (chunk-bytes 65536) (max-bytes 268435456) (max-batches 65536)
                                   (max-batch-records 65536) (max-batch-bytes 67108864) (max-records 1048576)
                                   (max-prepared 65536) (max-outcomes 65536))
  "Pre: recovery esclusivo, CONTROL dal catalogo, EOF SIZE attestato, tabella decisioni completa dell'Archivio.
File/FD/namespace e scratch congelati; assenza in una tabella parziale NON autorizza presumed abort.
Post: vecchio ACTIVE readonly da ID del manifest, header writer verificato, scanner a EOF, esiti risolti.
Solo esiti da DECISION senza OUTCOME sono copiati; risultato completo senza scratch o workspace.
Errori tipizzati originali propagati; nessun append, fsync, troncatura, rename, CSN o ammissione traffico."
  (verifica-lettura-active control input size scratch chunk-bytes max-bytes max-batches
                           max-batch-records max-batch-bytes)
  (verifica-file-distinti input (arcdocdb.control::control-recuperato-input control))
  (let* ((view (arcdocdb.control::control-recuperato-view control))
         (id (segmento-attivo (manifest-control-recuperato control)))
         (segment (crea-segmento-get view input id scratch)))
    (unless (= (arcdocdb.get::segmento-get-origin segment) arcdocdb.storage.format::+writer-origin+)
      (error 'corruption-detected :reason :active-recovery-origin))
    (leggi-corpo-active input size scratch chunk-bytes)
    (multiple-value-bind (prefix status batches records)
        (verifica-prefisso-active scratch size segment id max-bytes max-batches
                                 max-batch-records max-batch-bytes max-records)
      (let ((workspace (attraversa-active scratch prefix (arcdocdb.get::segmento-get-version segment)
                                         batches records max-prepared max-outcomes)))
        (risolvi-prepared-active workspace decisions (arcdocdb.get::vista-get-serie-identity view))
        (multiple-value-bind (ids csns) (impacchetta-esiti-active workspace)
          (arcdocdb.io::esigi-aperto input :input)
          (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
          (%make-active-recuperato control segment size prefix status batches records
                                  (hash-table-count (workspace-active-prepared workspace))
                                  (workspace-active-local workspace) (workspace-active-aborted workspace) ids csns
                                  (workspace-active-csn-present workspace) (workspace-active-max-csn workspace)
                                  (arcdocdb.recovery.decisions::%table-origin decisions)))))))
