;;; OWNER: writer logico; il buffer privato non attraversa API di mutazione esterne.
;;; SHARED: token locale; solo il registro CSN di Archivio toccato dal ponte alla chiusura/risoluzione.
(in-package #:arcdocdb.wal)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-WAL-005
(declaim (ftype (function (lotto keyword) null) esigi-lotto))
(defun esigi-lotto (lotto state)
  "Pre: capacità del writer. Post: stato richiesto; INVALID-ARGUMENT al riuso prematuro."
  (unless (eq (lotto-state lotto) state) (error 'invalid-argument :reason :lotto-state))
  (unless (<= (lotto-used lotto) (length (lotto-buffer lotto)))
    (error 'invariant-violation :reason :lotto-length))
  nil)

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto u8 octets octets &key (:flags u8) (:txid u64)) index) aggiungi-record))
(defun aggiungi-record (lotto kind key value &key (flags 0) (txid 0))
  "Pre: lotto aperto, input stabili. Post: record copiato, spazio SEAL sempre riservato.
Budget/rifiuto di formato prima della mutazione; stamp ordinario fissato alla chiusura.
RESOURCE-EXHAUSTED/INVALID-ARGUMENT; prepara byte, nessun punto di atomicità durevole."
  (esigi-lotto lotto :open)
  (when (lotto-csn-registry lotto) (error 'invalid-argument :reason :lotto-csn-bound))
  (unless (log-record-p (lotto-kind lotto) kind)
    (error 'invalid-argument :reason :lotto-record-kind))
  (when (or (= (lotto-count lotto) (length (lotto-offsets lotto)))
            (> (+ +header-bytes+ (length key) (length value) +seal-total+)
               (- (length (lotto-buffer lotto)) (lotto-used lotto))))
    (error 'resource-exhausted :reason :lotto-capacity))
  (let* ((start (lotto-used lotto))
         (end (scrivi-record (lotto-buffer lotto) start kind txid key value
                            :version (lotto-version lotto) :flags flags)))
    (setf (aref (lotto-offsets lotto) (lotto-count lotto)) start
          (lotto-used lotto) end)
    (incf (lotto-count lotto))
    (unless (<= (+ end +seal-total+) (length (lotto-buffer lotto)))
      (error 'invariant-violation :reason :lotto-seal-space))
    end))

;;; REQ: REQ-WAL-005
(declaim (ftype (function (lotto u32 u32) u32) ristampa-record-parole))
(defun ristampa-record-parole (lotto high low)
  "Pre: buffer esclusivo scritto dal codec. Post: CSN ordinari e CRC aggregato.
TXID prepared/OUTCOME/DECISION invariati; nessuna scansione o copia del body.
INVARIANT-VIOLATION per conteggio/offset corrotto, prima di accedere al relativo header."
  (esigi-lotto lotto :open)
  (unless (<= (lotto-count lotto) (length (lotto-offsets lotto)))
    (error 'invariant-violation :reason :lotto-record-count))
  (let ((buffer (lotto-buffer lotto)) (checksum 0))
    (dotimes (i (lotto-count lotto) checksum)
      (let ((pos (aref (lotto-offsets lotto) i)))
        (unless (<= (+ pos +header-bytes+) (lotto-used lotto))
          (error 'invariant-violation :reason :lotto-record-offset))
        (let ((kind (aref buffer (+ pos +type-offset+)))
              (flags (aref buffer (+ pos +flags-offset+))))
          (when (and (or (= kind +put+) (= kind +tombstone+) (= kind +edit+)) (not (logbitp 0 flags)))
            (scrivi-u32 buffer (+ pos +stamp-offset+) low)
            (scrivi-u32 buffer (+ pos +stamp-offset+ 4) high)
            (scrivi-u32 buffer pos (crc32c buffer (+ pos +body-crc-offset+) (+ pos +header-bytes+))))
          (setf checksum (crc32c buffer pos (+ pos +header-crc-bytes+) checksum)))))))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto file-offset file-offset) null) verifica-chiusura-lotto))
(defun verifica-chiusura-lotto (lotto file-start durable)
  "Pre: writer esclusivo. Post: lotto aperto e spazio SEAL/offset validi prima del CSN.
INVALID-ARGUMENT per offset; INVARIANT-VIOLATION per budget interno corrotto."
  (esigi-lotto lotto :open)
  (unless (and (<= durable file-start)
               (<= (+ file-start (lotto-used lotto) +seal-total+) most-positive-fixnum))
    (error 'invalid-argument :reason :lotto-offset))
  (unless (and (<= (lotto-count lotto) (length (lotto-offsets lotto)))
               (<= (+ (lotto-used lotto) +seal-total+) (length (lotto-buffer lotto))))
    (error 'invariant-violation :reason :lotto-seal-space))
  nil)

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto u32 u32 file-offset file-offset) index) sigilla-lotto-parole))
(defun sigilla-lotto-parole (lotto high low file-start durable)
  "Pre: verifica-chiusura-lotto conclusa; buffer privato del writer e parole CSN u32.
Post: record e SEAL con CRC completi; buffer immutabile, SEAL solo preparato prima dell'I/O.
INVARIANT-VIOLATION per lunghezza finale incoerente; nessun rollback di un CSN già preso."
  (let ((seal (lotto-seal-value lotto)) (checksum (ristampa-record-parole lotto high low)))
    (scrivi-u64 seal +seal-batch-start-offset+ file-start)
    (scrivi-u64 seal +seal-durable-offset+ durable)
    (scrivi-u32 seal +seal-count-offset+ (lotto-count lotto))
    (scrivi-u32 seal +seal-checksum-offset+ checksum)
    (setf (lotto-used lotto)
          (scrivi-record-parole (lotto-buffer lotto) (lotto-used lotto) +seal+ high low
                                (lotto-empty-key lotto) seal :version (lotto-version lotto))
          (lotto-start lotto) file-start
          (lotto-state lotto) :sealed)
    (unless (<= +seal-total+ (lotto-used lotto) (length (lotto-buffer lotto)))
      (error 'invariant-violation :reason :lotto-sealed-length))
    (lotto-used lotto)))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto u64 file-offset file-offset) index) sigilla-lotto))
(defun sigilla-lotto (lotto stamp file-start durable)
  "Pre: stamp preso dal chiamante, nessuna associazione CSN del ponte; durable storico.
Post: buffer sigillato; SEAL preparato, punto atomico persistito dal successivo write/flush.
INVALID-ARGUMENT prima di modificare; non registra o risolve il CSN del chiamante."
  (verifica-chiusura-lotto lotto file-start durable)
  (when (lotto-csn-registry lotto) (error 'invalid-argument :reason :lotto-csn-bound))
  (sigilla-lotto-parole lotto (ldb (byte 32 32) stamp) (ldb (byte 32 0) stamp) file-start durable))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto) null) riusa-lotto))
(defun riusa-lotto (lotto)
  "Pre: durevole, rimosso dal gruppo e nessun consumatore/riferimento in volo.
Post: stesso buffer aperto e vuoto. INVALID-ARGUMENT se non durevole; non attesta reclaim."
  (esigi-lotto lotto :durable)
  (progn nil)
  (unless (null (lotto-owner lotto)) (error 'invalid-argument :reason :lotto-owned))
  (setf (lotto-used lotto) 0 (lotto-count lotto) 0 (lotto-start lotto) 0 (lotto-state lotto) :open
        (lotto-csn-registry lotto) nil (lotto-csn-log lotto) nil (lotto-csn-pending lotto) nil
        (lotto-csn-slot lotto) 0 (lotto-csn-high lotto) 0 (lotto-csn-low lotto) 0)
  nil)

;;; REQ: REQ-WAL-005
(declaim (ftype (function (lotto) keyword) stato-lotto)
         (ftype (function (lotto) index) lunghezza-lotto)
         (ftype (function (lotto) file-offset) inizio-lotto))
(defun stato-lotto (lotto)
  "Pre: capacità posseduta. Post: stato osservato senza mutazione." (lotto-state lotto))
;;; REQ: REQ-WAL-005
(defun lunghezza-lotto (lotto)
  "Pre: capacità posseduta. Post: numero di byte occupati, senza I/O." (lotto-used lotto))
;;; REQ: REQ-WAL-005
(defun inizio-lotto (lotto)
  "Pre: lotto chiuso. Post: offset pianificato del file, senza modifica." (lotto-start lotto))
