;;;; Header del segmento, verificato prima che il chiamante scelga il decoder dei record.
;;; OWNER: il chiamante possiede i buffer; stabili per verifica, esclusivi per scrittura.
;;; SHARED: nessuna scrittura condivisa tra Serie; nessun lock o contatore globale.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (octets) null) esigi-id-serie))
(defun esigi-id-serie (id-serie)
  "Pre: ID-SERIE octets. Post: identità completa di 16 byte disponibile.
INVALID-ARGUMENT per lunghezza differente, prima di ogni scrittura."
  (unless (= (length id-serie) +serie-id-bytes+)
    (error 'invalid-argument :reason :serie-id-length))
  nil)

;;; REQ: REQ-FOR-001
(declaim (ftype (function (octets index index) boolean) zero-range-p))
(defun zero-range-p (buffer start end)
  "Pre: range valido. Post: T solo se tutti i byte riservati sono zero.
INVALID-ARGUMENT per range errato; nessuna modifica."
  (check-range buffer start end)
  (loop for i from start below end always (zerop (aref buffer i))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (octets index index) null) verifica-riservati))
(defun verifica-riservati (buffer start end)
  "Pre: header completo e integro. Post: tutte le aree riservate sono zero.
CORRUPTION-DETECTED per byte non zero, inclusa la coda fuori dal CRC."
  (unless (and (zero-range-p buffer (+ start +segment-reserved-a-start+)
                            (+ start +segment-reserved-a-end+))
               (zero-range-p buffer (+ start +segment-reserved-b-start+)
                            (+ start +segment-crc-offset+))
               (zero-range-p buffer (+ start +segment-reserved-c-start+) end))
    (error 'corruption-detected :reason :segment-reserved :offset start))
  nil)

;;; REQ: REQ-FOR-001 REQ-FOR-002
(declaim (ftype (function (octets index octets u64 u64
                                &key (:version integer) (:origine u8))
                         (values index &optional)) scrivi-header-segmento))
(defun scrivi-header-segmento (buffer start id-serie segment-id created-at
                             &key (version 2) (origine +writer-origin+))
  "Pre: BUFFER esclusivo; ID-SERIE di 16 byte, senza alias; interi u64.
Post: header canonico di 64 byte, riservati zero, CRC; fuori range invariato.
Errori tipizzati di preflight non modificano BUFFER. Prepara byte, senza durability."
  (esigi-id-serie id-serie)
  (versione-supportata version start)
  (unless (or (= origine +writer-origin+) (= origine +compaction-origin+))
    (error 'invalid-argument :reason :segment-origin :offset start))
  (when (eq buffer id-serie)
    (error 'invalid-argument :reason :input-alias :offset start))
  (let ((end (+ start +segment-header-bytes+)))
    (check-range buffer start end)
    (fill buffer 0 :start start :end end)
    (scrivi-u32 buffer start +segment-magic-low+)
    (scrivi-u32 buffer (+ start +segment-magic-high-offset+) +segment-magic-high+)
    (scrivi-u16 buffer (+ start +segment-version-offset+) version)
    (setf (aref buffer (+ start +segment-origin-offset+)) origine)
    (replace buffer id-serie :start1 (+ start +serie-id-offset+))
    (scrivi-u64 buffer (+ start +segment-id-offset+) segment-id)
    (scrivi-u64 buffer (+ start +segment-created-offset+) created-at)
    (scrivi-u32 buffer (+ start +segment-crc-offset+)
               (crc32c buffer start (+ start +segment-crc-offset+)))
    end))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-LIM-001
(declaim (ftype (function (octets index index octets u64)
                         (values index u16 u8 index &optional)) verifica-header-segmento))
(defun verifica-header-segmento (buffer start end id-serie segment-id)
  "Pre: range stabile; identità Serie e segmento dalla fonte autorevole.
Post: fine header, versione effettiva, origine e offset created-at; nessuna copia/boxing u64.
CORRUPTION-DETECTED per CRC/identità/cornice, UNSUPPORTED-FORMAT per versione ignota.
Non valida i record, il manifest o la visibilità del segmento."
  (check-range buffer start end)
  (esigi-id-serie id-serie)
  (when (< (- end start) +segment-header-bytes+)
    (error 'corruption-detected :reason :segment-header-truncated :offset start))
  (let ((next (+ start +segment-header-bytes+)))
    (unless (= (leggi-u32 buffer (+ start +segment-crc-offset+))
               (crc32c buffer start (+ start +segment-crc-offset+)))
      (error 'corruption-detected :reason :segment-header-crc :offset start))
    (unless (and (= (leggi-u32 buffer start) +segment-magic-low+)
                 (= (leggi-u32 buffer (+ start +segment-magic-high-offset+)) +segment-magic-high+))
      (error 'corruption-detected :reason :segment-magic :offset start))
    (let ((version (versione-supportata
                    (leggi-u16 buffer (+ start +segment-version-offset+)) start))
          (origin (aref buffer (+ start +segment-origin-offset+))))
      (unless (or (= origin +writer-origin+) (= origin +compaction-origin+))
        (error 'corruption-detected :reason :segment-origin :offset start))
      (verifica-riservati buffer start next)
      (unless (and (loop for i below +serie-id-bytes+
                         always (= (aref buffer (+ start +serie-id-offset+ i)) (aref id-serie i)))
                   (u64-equal-p buffer (+ start +segment-id-offset+) segment-id))
        (error 'corruption-detected :reason :segment-identity :offset start))
      (values next version origin (+ start +segment-created-offset+)))))
