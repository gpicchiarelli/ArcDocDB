;;;; Cornice v1/v2. Storage opaco: CBOR, visibilità e I/O sono responsabilità superiori.
;;; OWNER: buffer del chiamante; nessuna mutazione concorrente durante queste funzioni.
;;; SHARED: nessuno stato mutabile condiviso tra Serie.
(in-package #:arcdocdb.record)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(defconstant +header-bytes+ 24)
(defconstant +body-crc-offset+ 4)
(defconstant +type-offset+ 8)
(defconstant +flags-offset+ 9)
(defconstant +key-length-offset+ 10)
(defconstant +v1-reserved-offset+ 11)
(defconstant +value-length-offset+ 12)
(defconstant +stamp-offset+ 16)
(defconstant +max-document-bytes+ 16777216)
(defconstant +max-key-bytes+ 65535)
(defconstant +max-record-bytes+ 16842775)
(defconstant +max-v1-record-bytes+ 16777215)
(defconstant +put+ 1)
(defconstant +tombstone+ 2)
(defconstant +seal+ 3)
(defconstant +outcome+ 4)
(defconstant +edit+ 5)
(defconstant +decision+ 6)
(defconstant +prepared+ 1)
(defconstant +contract-versioned+ 4)
(defconstant +complete+ 8)
(defconstant +seal-bytes+ 32)
(defconstant +outcome-bytes+ 8)
(defconstant +min-edit-bytes+ 24)
(defconstant +min-decision-bytes+ 26)
(defconstant +seal-file-id-offset+ 0)
(defconstant +seal-batch-start-offset+ 8)
(defconstant +seal-durable-offset+ 16)
(defconstant +seal-count-offset+ 24)
(defconstant +seal-checksum-offset+ 28)
(defconstant +header-crc-bytes+ 4)

;;; REQ: REQ-FOR-002 REQ-LIM-001
(declaim (ftype (function (integer) (values u16 u32 &optional)) format-limits))
(defun format-limits (version)
  "Pre: versione esplicita dal file. Post: limite chiave e record del layout.
Segnala UNSUPPORTED-FORMAT per versione sconosciuta; nessun autodetect."
  (case version
    (1 (values 255 +max-v1-record-bytes+))
    (2 (values +max-key-bytes+ +max-record-bytes+))
    (otherwise (error 'unsupported-format :reason :record-version))))

;;; REQ: REQ-FOR-003
(declaim (ftype (function (u8) (values u8 &optional)) allowed-flags))
(defun allowed-flags (kind)
  "Pre: KIND u8. Post: maschera dei soli flag implementati per quel tipo.
Segnala CORRUPTION-DETECTED per un tipo sconosciuto; compressione non supportata."
  (case kind
    (1 (logior +prepared+ +contract-versioned+))
    (2 +prepared+)
    ((3 4 6) 0)
    (5 +complete+)
    (otherwise (error 'corruption-detected :reason :record-type))))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (u8 u8 u16 index) null) check-key-shape))
(defun check-key-shape (kind flags key-length start)
  "Pre: campi numerici già verificati. Post: cornice compatibile con il tipo.
Segnala CORRUPTION-DETECTED per flag, chiave o lunghezza incoerenti."
  (unless (zerop (logand flags (logxor 255 (allowed-flags kind))))
      (error 'corruption-detected :reason :record-flags :offset start))
  (case kind
    ((1 2)
     (when (zerop key-length)
       (error 'corruption-detected :reason :empty-key :offset start)))
    (otherwise
     (unless (zerop key-length)
       (error 'corruption-detected :reason :control-key :offset start))))
  nil)

;;; REQ: REQ-FOR-003 REQ-LIM-001
(declaim (ftype (function (u8 u32 index) null) check-value-shape))
(defun check-value-shape (kind value-length start)
  "Pre: tipo noto e campi numerici verificati. Post: lunghezza coerente con il tipo.
Segnala CORRUPTION-DETECTED per body vuoto, eccedente o controllo malformato."
  (case kind
    (1 (unless (<= 1 value-length +max-document-bytes+)
         (error 'corruption-detected :reason :document-length :offset start)))
    (2 (unless (zerop value-length)
         (error 'corruption-detected :reason :tombstone-body :offset start)))
    (3 (unless (= value-length +seal-bytes+)
         (error 'corruption-detected :reason :seal-length :offset start)))
    (4 (unless (= value-length +outcome-bytes+)
         (error 'corruption-detected :reason :outcome-length :offset start)))
    (5 (when (< value-length +min-edit-bytes+)
         (error 'corruption-detected :reason :edit-length :offset start)))
    (6 (when (< value-length +min-decision-bytes+)
         (error 'corruption-detected :reason :decision-length :offset start)))
    (otherwise (error 'invariant-violation :reason :record-type :offset start)))
  nil)

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (u8 u8 u16 u32 index) null) check-shape))
(defun check-shape (kind flags key-length value-length start)
  "Pre: campi numerici verificati. Post: tipo, flag, chiave e valore coerenti.
Propaga errori tipizzati; nessuna modifica, lettura di body o allocazione."
  (check-key-shape kind flags key-length start)
  (check-value-shape kind value-length start)
  nil)

;;; REQ: REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (octets index u8 u8 octets octets integer index)
                         (values index &optional)) encoding-size))
(defun encoding-size (buffer start kind flags key value version document-limit)
  "Pre: input tipizzati. Post: tutte le precondizioni controllate prima di scrivere.
Segnala INVALID-ARGUMENT per alias, RESOURCE-EXHAUSTED per budget; errori di cornice tipizzati."
  (when (or (eq buffer key) (eq buffer value))
    (error 'invalid-argument :reason :input-alias :offset start))
  (unless (<= 1 document-limit +max-document-bytes+)
    (error 'invalid-argument :reason :document-budget :offset start))
  (multiple-value-bind (key-limit record-limit) (format-limits version)
    (let ((key-length (length key)) (value-length (length value))
          (total (+ +header-bytes+ (length key) (length value))))
      (unless (and (<= key-length key-limit) (<= total record-limit))
        (error 'resource-exhausted :reason :format-limit :offset start))
      (when (and (= kind +put+) (> value-length document-limit))
        (error 'resource-exhausted :reason :document-budget :offset start))
      (check-shape kind flags key-length value-length start)
      (check-range buffer start (+ start total))
      total)))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (octets index u8 u32 u32 octets octets
                         &key (:version integer) (:flags u8) (:document-limit index))
                         (values index &optional)) scrivi-record-parole))
(declaim (ftype (function (octets index u8 u64 octets octets
                                &key (:version integer) (:flags u8)
                                (:document-limit index))
                         (values index &optional)) scrivi-record))
(defun scrivi-record (buffer start kind stamp key value
                     &key (version 2) (flags 0)
                          (document-limit +max-document-bytes+))
  "Pre: buffer esclusivo e stamp u64; key/value stabili. Post: cornice e CRC completi.
Propaga la validazione di scrivi-record-parole prima della prima modifica; nessun I/O."
  (scrivi-record-parole buffer start kind (ldb (byte 32 32) stamp) (ldb (byte 32 0) stamp)
                       key value :version version :flags flags :document-limit document-limit))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (octets index u8 u32 u32 octets octets
                                &key (:version integer) (:flags u8)
                                (:document-limit index))
                         (values index &optional)) scrivi-record-parole))
(defun scrivi-record-parole (buffer start kind stamp-high stamp-low key value
                            &key (version 2) (flags 0)
                                 (document-limit +max-document-bytes+))
  "Pre: buffer esclusivo; stamp in due u32; KEY/VALUE non alias di BUFFER.
Post: cornice LE in [START,risultato), CRC completi, resto invariato; nessun bignum.
La validazione segnala condizioni tipizzate prima di scrivere. Prepara byte, nessun I/O."
  (let* ((size (encoding-size buffer start kind flags key value version document-limit))
         (body (+ start +header-bytes+)) (value-start (+ body (length key)))
         (end (+ start size)))
    (setf (aref buffer (+ start +type-offset+)) kind
          (aref buffer (+ start +flags-offset+)) flags)
    (scrivi-u16 buffer (+ start +key-length-offset+) (length key))
    (scrivi-u32 buffer (+ start +value-length-offset+) (length value))
    (scrivi-u32 buffer (+ start +stamp-offset+) stamp-low)
    (scrivi-u32 buffer (+ start +stamp-offset+ 4) stamp-high)
    (replace buffer key :start1 body :end1 value-start)
    (replace buffer value :start1 value-start :end1 end)
    (scrivi-u32 buffer (+ start +body-crc-offset+) (crc32c buffer body end))
    (scrivi-u32 buffer start (crc32c buffer (+ start +body-crc-offset+) body))
    end))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(declaim (ftype (function (octets index index integer index)
                         (values index u8 u8 u16 u32 &optional)) checked-header))
(defun checked-header (buffer start end version document-limit)
  "Pre: range valido. Post: header CRC controllato prima delle lunghezze, range completo.
Segnala corruzione, versione sconosciuta o budget; nessun buffer modificato."
  (multiple-value-bind (key-limit record-limit) (format-limits version)
    (when (< (- end start) +header-bytes+)
      (error 'corruption-detected :reason :truncated-header :offset start))
    (let ((body (+ start +header-bytes+)))
      (unless (= (leggi-u32 buffer start)
                 (crc32c buffer (+ start +body-crc-offset+) body))
        (error 'corruption-detected :reason :header-crc :offset start))
      (when (and (= version 1) (plusp (aref buffer (+ start +v1-reserved-offset+))))
        (error 'corruption-detected :reason :v1-reserved :offset start))
      (let* ((kind (aref buffer (+ start +type-offset+)))
             (flags (aref buffer (+ start +flags-offset+)))
             (key-length (leggi-u16 buffer (+ start +key-length-offset+)))
             (value-length (leggi-u32 buffer (+ start +value-length-offset+)))
             (size (+ +header-bytes+ key-length value-length)))
        (unless (and (<= key-length key-limit) (<= size record-limit)
                     (<= size (- end start)))
          (error 'corruption-detected :reason :record-length :offset start))
        (check-shape kind flags key-length value-length start)
        (when (and (= kind +put+) (> value-length document-limit))
          (error 'resource-exhausted :reason :document-budget :offset start))
        (values (+ start size) kind flags key-length value-length)))))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (octets index index &key (:version integer)
                                (:document-limit index))
                         (values index u8 u8 index index index index &optional))
                verifica-cornice))
(defun verifica-cornice (buffer start end &key (version 2)
                                            (document-limit +max-document-bytes+))
  "Pre: buffer stabile, [START,END) disponibile, versione dal file.
Post: CRC header/body e cornice verificati; restituisce fine, tipo, flag,
range chiave e range valore. Non attesta commit né validità CBOR; nessuna copia.
Segnala errori tipizzati; non restituisce range non verificati."
  (check-range buffer start end)
  (unless (<= 1 document-limit +max-document-bytes+)
    (error 'invalid-argument :reason :document-budget :offset start))
  (multiple-value-bind (next kind flags key-length value-length)
      (checked-header buffer start end version document-limit)
    (let* ((body (+ start +header-bytes+)) (value-start (+ body key-length)))
      (unless (= (leggi-u32 buffer (+ start +body-crc-offset+))
                 (crc32c buffer body next))
        (error 'corruption-detected :reason :body-crc :offset start))
      (unless (= value-length (- next value-start))
        (error 'invariant-violation :reason :body-range :offset start))
      (values next kind flags body value-start value-start next))))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(declaim (ftype (function (octets index index &key (:version integer)
                                (:document-limit index))
                         (values index u8 u8 u64 index index index index &optional))
                verifica-record))
(defun verifica-record (buffer start end &key (version 2)
                                            (document-limit +max-document-bytes+))
  "Pre: buffer stabile, range disponibile, versione dal file e budget positivo.
Post: fine, tipo, flag, stamp, range chiave e valore dopo verifica completa.
Propaga condizioni tipizzate. Questa API ispettiva può boxare uno stamp u64 alto;
il percorso GET usa verifica-put e confronta lo stamp senza materializzarlo."
  (multiple-value-bind (next kind flags ks ke vs ve)
      (verifica-cornice buffer start end :version version :document-limit document-limit)
    (values next kind flags (leggi-u64 buffer (+ start +stamp-offset+)) ks ke vs ve)))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(declaim (ftype (function (octets index u64) boolean) u64-equal-p))
(defun u64-equal-p (buffer start expected)
  "Pre: range di otto byte verificato; EXPECTED u64. Post: uguaglianza delle due word.
Nessun boxing del valore sul disco; INVALID-ARGUMENT per intervallo errato."
  (check-range buffer start (+ start 8))
  (and (= (leggi-u32 buffer start) (ldb (byte 32 0) expected))
       (= (leggi-u32 buffer (+ start 4)) (ldb (byte 32 32) expected))))

;;; REQ: REQ-AFF-002 REQ-FOR-004
(declaim (ftype (function (octets index index octets) boolean) key-equal-p))
(defun key-equal-p (buffer start end key)
  "Pre: range verificato. Post: confronto completo bytewise, nessuna copia.
Segnala INVALID-ARGUMENT per range errato; non modifica gli input."
  (check-range buffer start end)
  (and (= (- end start) (length key))
       (loop for i from start below end for j from 0
             always (= (aref buffer i) (aref key j)))))

;;; REQ: REQ-FOR-004
(declaim (ftype (function (octets index index integer octets index u64) null) check-outcome))
(defun check-outcome (buffer start end version put-buffer put-start csn)
  "Pre: prova proveniente dallo stesso segmento secondo il resolver proprietario.
Post: OUTCOME integro, TXID e CSN coincidenti. Segnala CORRUPTION-DETECTED altrimenti.
Non prova da solo la presenza in un lotto committed: compito del resolver."
  (multiple-value-bind (next kind flags ks ke vs ve)
      (verifica-cornice buffer start end :version version)
    (declare (ignore flags ks ke ve)) ; cornice e lunghezza già provate da verifica-cornice
    (unless (and (= next end) (= kind +outcome+)
                 (= (leggi-u32 buffer (+ start +stamp-offset+))
                    (leggi-u32 put-buffer (+ put-start +stamp-offset+)))
                 (= (leggi-u32 buffer (+ start +stamp-offset+ 4))
                    (leggi-u32 put-buffer (+ put-start +stamp-offset+ 4)))
                 (u64-equal-p buffer vs csn))
      (error 'corruption-detected :reason :outcome-mismatch :offset start)))
  nil)

;;; REQ: REQ-AFF-002 REQ-FOR-004
(declaim (ftype (function (octets index index octets u64 u8
                                &key (:version integer) (:proof-buffer (or null octets))
                                (:proof-start index) (:proof-end index))
                         (values index index &optional)) verifica-put))
(defun verifica-put (buffer start end key csn flags
                     &key (version 2) proof-buffer (proof-start 0) (proof-end 0))
  "Pre: END da location; KEY/CSN/FLAGS dall'indice committed; buffer stabili.
Per prepared, resolver fornisce OUTCOME dello stesso segmento in lotto committed.
Post: restituisce solo range del valore dopo CRC, chiave, tipo, stamp e prova.
Segnala CORRUPTION-DETECTED se incoerente o prova assente. Non decide visibilità."
  (multiple-value-bind (next kind actual-flags ks ke vs ve)
      (verifica-cornice buffer start end :version version)
    (unless (and (= next end) (= kind +put+) (= actual-flags flags)
                 (key-equal-p buffer ks ke key))
      (error 'corruption-detected :reason :index-mismatch :offset start))
    (if (logbitp 0 actual-flags)
        (progn
          (unless proof-buffer
            (error 'corruption-detected :reason :outcome-required :offset start))
          (check-outcome proof-buffer proof-start proof-end version buffer start csn))
        (unless (u64-equal-p buffer (+ start +stamp-offset+) csn)
          (error 'corruption-detected :reason :csn-mismatch :offset start)))
    (values vs ve)))
