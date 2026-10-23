;;;; Decoder della cornice: controlli completi prima del ritorno, nessun dato testuale.
;;; OWNER: buffer e identita stabili, nessun puntatore trattenuto dopo il ritorno.
;;; SHARED: nessuno stato condiviso mutabile, callback, lock o I/O.
(in-package #:arcdocdb.fulltext.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index) boolean) byte-zero-full-text-p))
(defun byte-zero-full-text-p (buffer start end)
  "Pre: range gia verificato. Post: T se tutti i byte sono zero; nessuna modifica."
  (loop for position from start below end always (zerop (aref buffer position))))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index octets u64) null) verifica-header-full-text))
(defun verifica-header-full-text (buffer start size identity segment-id)
  "Pre: header interamente presente, identita autorevole. Post: header v2/type 5 valido.
CORRUPTION-DETECTED per contenuto/CRC/identita; UNSUPPORTED-FORMAT per versione ignota.
Non ricompone l'ID u64 letto; nessuna modifica."
  (unless (and (<= (+ start +header-bytes+) (length buffer)) (= (length identity) +identity-bytes+))
    (error 'invariant-violation :reason :fulltext-header-read-range))
  (unless (= (leggi-u32 buffer (+ start +header-crc-offset+))
             (crc32c buffer start (+ start +header-crc-offset+)))
    (error 'corruption-detected :reason :fulltext-header-crc :offset start))
  (unless (and (= (leggi-u32 buffer start) +magic-low+)
               (= (leggi-u32 buffer (+ start +magic-high-offset+)) +magic-high+))
    (error 'corruption-detected :reason :fulltext-magic :offset start))
  (unless (= (leggi-u16 buffer (+ start +version-offset+)) +format-version+)
    (error 'unsupported-format :reason :fulltext-version :offset start))
  (unless (= (leggi-u16 buffer (+ start +kind-offset+)) +fulltext-kind+)
    (error 'corruption-detected :reason :fulltext-kind :offset start))
  (unless (and (= (leggi-u16 buffer (+ start +count-offset+)) +section-count+)
               (zerop (leggi-u16 buffer (+ start +flags-offset+)))
               (zerop (leggi-u32 buffer (+ start +reserved-offset+))))
    (error 'corruption-detected :reason :fulltext-header-fields :offset start))
  (unless (and (u64-equal-p buffer (+ start +length-offset+) size)
               (u64-equal-p buffer (+ start +directory-offset+) +header-bytes+))
    (error 'corruption-detected :reason :fulltext-file-length :offset start))
  (unless (and (u64-equal-p buffer (+ start +segment-offset+) segment-id)
               (loop for i below +identity-bytes+
                     always (= (aref buffer (+ start +identity-offset+ i)) (aref identity i))))
    (error 'corruption-detected :reason :fulltext-source-identity :offset start))
  (unless (<= (+ start size) (length buffer))
    (error 'invariant-violation :reason :fulltext-header-read-result))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index (integer 0 5) index index)
                         (values index &optional)) verifica-entry-full-text))
(defun verifica-entry-full-text (buffer start section cursor limit)
  "Pre: directory presente, cursore relativo entro LIMIT. Post: fine sezione nel payload.
CORRUPTION-DETECTED per ID, riservati, offset, dimensione o larghezza incoerenti."
  (unless (and (<= cursor limit) (<= (+ start +sections-offset+) (length buffer)))
    (error 'invariant-violation :reason :fulltext-entry-read-range))
  (let* ((entry (+ start +header-bytes+ (* section +directory-entry-bytes+)))
         (length (leggi-u64 buffer (+ entry +entry-length-offset+))))
    (unless (and (= (leggi-u16 buffer entry) (1+ section))
                 (zerop (leggi-u16 buffer (+ entry +entry-flags-offset+)))
                 (zerop (leggi-u32 buffer (+ entry +entry-reserved-offset+))))
      (error 'corruption-detected :reason :fulltext-directory-fields :offset entry))
    (unless (and (u64-equal-p buffer (+ entry +entry-start-offset+) cursor)
                 (<= length (- limit cursor)))
      (error 'corruption-detected :reason :fulltext-section-range :offset entry))
    (unless (zerop (mod length (larghezza-sezione-full-text section)))
      (error 'corruption-detected :reason :fulltext-section-width :offset entry))
    (when (and (zerop section) (not (<= 1 length +meta-max-bytes+)))
      (error 'corruption-detected :reason :fulltext-meta-length :offset entry))
    (let ((end (+ cursor length)))
      (unless (<= cursor end limit) (error 'invariant-violation :reason :fulltext-entry-read-result))
      end)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index) (values index index &optional))
                verifica-directory-full-text))
(defun verifica-directory-full-text (buffer start size)
  "Pre: cornice presente. Post: span assoluto META, sezioni contigue, padding zero.
CORRUPTION-DETECTED per qualsiasi sezione, padding o lunghezza finale incoerente."
  (unless (and (<= (+ +sections-offset+ +footer-bytes+) size) (<= (+ start size) (length buffer)))
    (error 'invariant-violation :reason :fulltext-directory-read-range))
  (let ((cursor +sections-offset+) (limit (- size +footer-bytes+)) (meta-end 0))
    (dotimes (section +section-count+)
      (setf cursor (verifica-entry-full-text buffer start section cursor limit))
      (when (zerop section) (setf meta-end cursor))
      (when (< section (1- +section-count+))
        (let ((aligned (allinea-indice-full-text cursor)))
          (unless (and (<= aligned limit)
                       (byte-zero-full-text-p buffer (+ start cursor) (+ start aligned)))
            (error 'corruption-detected :reason :fulltext-padding :offset (+ start cursor)))
          (setf cursor aligned))))
    (unless (= cursor limit)
      (error 'corruption-detected :reason :fulltext-payload-length :offset (+ start cursor)))
    (unless (<= +sections-offset+ meta-end limit)
      (error 'invariant-violation :reason :fulltext-directory-read-result))
    (values (+ start +sections-offset+) (+ start meta-end))))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t t &key (:max-bytes t))
                         (values index index index &optional)) verifica-cornice-indice-full-text))
(defun verifica-cornice-indice-full-text (buffer start end identity segment-id
                                        &key (max-bytes +default-file-budget+))
  "Pre: span simple u8 e identita/segment-id autorevoli, stabili durante la chiamata.
Post: tre valori END, META-START, META-END solo dopo verifica integrale della cornice.
INVALID-ARGUMENT per ingressi; RESOURCE-EXHAUSTED per budget; CORRUPTION-DETECTED
per troncamento/CRC/layout/identita; UNSUPPORTED-FORMAT per versione ignota con CRC valido.
Non valida il contenuto delle sezioni, gli hint, i documenti o la readiness del motore.
Nessuna modifica, oggetto trattenuto, I/O o coordinamento tra Serie."
  (let ((size (controlla-input-cornice buffer start end identity segment-id max-bytes)))
    (when (> size max-bytes)
      (error 'resource-exhausted :reason :fulltext-file-budget))
    (when (< size (+ +sections-offset+ +footer-bytes+))
      (error 'corruption-detected :reason :fulltext-truncated :offset start))
    (let ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end)))
      (verifica-header-full-text bytes begin size identity segment-id)
      (unless (= (leggi-u32 bytes (- limit +footer-bytes+))
                 (crc32c bytes (+ begin +header-bytes+) (- limit +footer-bytes+)))
        (error 'corruption-detected :reason :fulltext-footer-crc :offset (- limit +footer-bytes+)))
      (multiple-value-bind (meta-start meta-end) (verifica-directory-full-text bytes begin size)
        (unless (<= begin meta-start meta-end (- limit +footer-bytes+))
          (error 'invariant-violation :reason :fulltext-meta-span))
        (values limit meta-start meta-end)))))
