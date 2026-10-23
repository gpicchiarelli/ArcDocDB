;;; OWNER: controller costruisce il piano in memoria; payload caller stabile durante la copia.
;;; SHARED: oggetti e buffer privati; nessun I/O, file, clock o token CSN.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (octets octets integer segmento-attivo-preparato
                          arcdocdb.binary:u32 arcdocdb.binary:u32)
                         arcdocdb.recovery.manifest::manifest) valida-checkpoint-control))
(defun valida-checkpoint-control (bytes identity version active max-segments max-outcomes)
  "Pre: file privato intero, solo EDIT completo e SEAL. Post: header e manifest coerenti con ACTIVE.
Propaga errori del recovery; INVARIANT-VIOLATION per costruzione interna; niente I/O."
  (multiple-value-bind (next actual-version) (verifica-header-log bytes 0 (length bytes) :control identity)
    (unless (and (= next +log-header-bytes+) (= actual-version version))
      (error 'invariant-violation :reason :control-checkpoint-header))
    (multiple-value-bind (manifest prefix status)
        (ricostruisci-manifest bytes next (length bytes) :version version :file-offset 0
                              :file-size (length bytes) :max-batches 1 :max-batch-records 1 :max-edits 1
                              :max-segmenti max-segments :max-esiti max-outcomes)
      (unless (and (= prefix (length bytes)) (eq status :complete))
        (error 'invariant-violation :reason :control-checkpoint-prefix))
      (unless (= (segmento-attivo manifest) (id-active-checkpoint active))
        (error 'invalid-argument :reason :control-checkpoint-active))
      manifest)))

;;; REQ: REQ-FOR-003 REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (octets u64 integer octets) octets) codifica-checkpoint-control))
(defun codifica-checkpoint-control (payload stamp version identity)
  "Pre: payload entro budget, identità canonica, versione del nuovo ACTIVE. Post: file privato sigillato.
EDIT completo, TXID zero, stamp caller e durable storico zero: nessun CSN preso.
Errori dei codec propagati; INVARIANT-VIOLATION per ritorni interni; nessun buffer caller modificato."
  (let* ((batch-bytes (+ +header-bytes+ (length payload) +header-bytes+ +seal-bytes+))
         (batch (crea-lotto :control 0 :version version :capacity batch-bytes :max-records 1))
         (bytes (make-array (+ +log-header-bytes+ batch-bytes)
                            :element-type '(unsigned-byte 8) :initial-element 0)))
    (unless (= (aggiungi-record batch +edit+ (arcdocdb.wal::lotto-empty-key batch) payload
                               :flags +edit-complete+) (+ +header-bytes+ (length payload)))
      (error 'invariant-violation :reason :control-checkpoint-edit))
    (unless (= (sigilla-lotto batch stamp +log-header-bytes+ 0) batch-bytes (lunghezza-lotto batch))
      (error 'invariant-violation :reason :control-checkpoint-seal))
    (unless (= (scrivi-header-log bytes 0 :control identity :version version) +log-header-bytes+)
      (error 'invariant-violation :reason :control-checkpoint-header))
    (replace bytes (arcdocdb.wal::lotto-buffer batch) :start1 +log-header-bytes+ :end2 batch-bytes)
    bytes))

;;; REQ: REQ-FOR-001 REQ-FOR-003 REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (segmento-attivo-preparato octets u64
                          &key (:max-payload index) (:max-segmenti arcdocdb.binary:u32)
                               (:max-esiti arcdocdb.binary:u32)) checkpoint-control) crea-checkpoint-control))
(defun crea-checkpoint-control (active payload stamp
                              &key (max-payload +metadata-max-bytes+) (max-segmenti 65536) (max-esiti 65536))
  "Pre: nuovo ACTIVE esclusivo, payload di uno stato completo da fonte autorevole e stamp u64.
Post: copia privata header/EDIT/SEAL e manifest verificato; nessuna mutazione degli input o I/O.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED per budget; corruzione/applicabilità dal recovery.
Il piano non dimostra presenza dei CLOSED o correttezza dell'allocatore degli ID."
  (verifica-active-checkpoint active)
  (unless (<= +edit-min-bytes+ max-payload +metadata-max-bytes+)
    (error 'invalid-argument :reason :control-checkpoint-budget))
  (unless (<= +edit-min-bytes+ (length payload) max-payload)
    (error 'resource-exhausted :reason :control-checkpoint-payload))
  (let* ((segment (arcdocdb.active::segmento-attivo-preparato-segment active))
         (version (arcdocdb.get::segmento-get-version segment)))
    (unless (<= (length payload) (- (nth-value 1 (format-limits version)) +header-bytes+))
      (error 'resource-exhausted :reason :control-checkpoint-payload))
    (let* ((identity (copy-seq (arcdocdb.get::vista-get-serie-identity (arcdocdb.get::segmento-get-owner segment))))
           (bytes (codifica-checkpoint-control payload stamp version identity))
           (manifest (valida-checkpoint-control bytes identity version active max-segmenti max-esiti)))
      (verifica-active-checkpoint active)
      (%make-checkpoint-control active bytes identity manifest version))))
