;;;; Scrive solo la cornice dopo il preflight; payload forniti dal chiamante.
;;; OWNER: buffer esclusivo; identita e lunghezze immutabili per tutta la chiamata.
;;; SHARED: nessuna mutazione condivisa, attesa o I/O fra Serie.
(in-package #:arcdocdb.fulltext.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index octets u64 index) null) scrivi-header-full-text))
(defun scrivi-header-full-text (buffer start identity segment-id size)
  "Pre: span e identita verificati, buffer esclusivo senza alias con ID.
Post: header v2/type 5 canonico e CRC; nessuna scrittura fuori dai 64 byte."
  (unless (and (<= (+ start +header-bytes+) (length buffer)) (= (length identity) +identity-bytes+))
    (error 'invariant-violation :reason :fulltext-header-write-range))
  (fill buffer 0 :start start :end (+ start +header-bytes+))
  (scrivi-u32 buffer start +magic-low+)
  (scrivi-u32 buffer (+ start +magic-high-offset+) +magic-high+)
  (scrivi-u16 buffer (+ start +version-offset+) +format-version+)
  (scrivi-u16 buffer (+ start +kind-offset+) +fulltext-kind+)
  (scrivi-u16 buffer (+ start +count-offset+) +section-count+)
  (replace buffer identity :start1 (+ start +identity-offset+))
  (scrivi-u64 buffer (+ start +segment-offset+) segment-id)
  (scrivi-u64 buffer (+ start +length-offset+) size)
  (scrivi-u64 buffer (+ start +directory-offset+) +header-bytes+)
  (scrivi-u32 buffer (+ start +header-crc-offset+)
              (crc32c buffer start (+ start +header-crc-offset+)))
  (unless (and (= +format-version+ (leggi-u16 buffer (+ start +version-offset+)))
               (zerop (leggi-u32 buffer (+ start +reserved-offset+))))
    (error 'invariant-violation :reason :fulltext-header-write-result))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index (simple-array (unsigned-byte 64) (6))) null)
                scrivi-directory-full-text))
(defun scrivi-directory-full-text (buffer start lengths)
  "Pre: layout completamente verificato. Post: directory canonica e padding zero.
Payload preservati; nessuna allocazione prevista, sei iterazioni."
  (unless (<= (+ start +sections-offset+) (length buffer))
    (error 'invariant-violation :reason :fulltext-directory-write-range))
  (let ((cursor +sections-offset+))
    (dotimes (section +section-count+)
      (let ((entry (+ start +header-bytes+ (* section +directory-entry-bytes+)))
            (length (aref lengths section)))
        (fill buffer 0 :start entry :end (+ entry +directory-entry-bytes+))
        (scrivi-u16 buffer entry (1+ section))
        (scrivi-u64 buffer (+ entry +entry-start-offset+) cursor)
        (scrivi-u64 buffer (+ entry +entry-length-offset+) length)
        (incf cursor length)
        (when (< section (1- +section-count+))
          (let ((aligned (allinea-indice-full-text cursor)))
            (fill buffer 0 :start (+ start cursor) :end (+ start aligned))
            (setf cursor aligned)))))
    (unless (<= (+ start cursor +footer-bytes+) (length buffer))
      (error 'invariant-violation :reason :fulltext-directory-write-result)))
  nil)

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t t t &key (:max-bytes t))
                         (values index &optional)) scrivi-cornice-indice-full-text))
(defun scrivi-cornice-indice-full-text (buffer start end identity segment-id lengths
                                      &key (max-bytes +default-file-budget+))
  "Pre: destinazione esclusiva simple u8, payload gia collocati; sei lunghezze u64.
Post: header, directory, padding e footer canonici; payload e byte esterni invariati.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED di preflight non modificano alcun byte.
Non valida META o posting e non certifica readiness. Prepara byte in memoria,
senza atomicita durevole, I/O o pubblicazione; l'allocazione e verificata separatamente."
  (let ((size (controlla-input-cornice buffer start end identity segment-id max-bytes)))
    (when (eq buffer identity)
      (error 'invalid-argument :reason :fulltext-input-alias))
    (when (> size max-bytes)
      (error 'resource-exhausted :reason :fulltext-file-budget))
    (controlla-lunghezze-cornice lengths size)
    (let ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end)))
      (scrivi-header-full-text bytes begin identity segment-id size)
      (scrivi-directory-full-text bytes begin lengths)
      (scrivi-u32 bytes (- limit +footer-bytes+)
                  (crc32c bytes (+ begin +header-bytes+) (- limit +footer-bytes+)))
      end)))
