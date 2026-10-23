(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text index u32 index index) null)
                verifica-posizioni-posting))
(defun verifica-posizioni-posting (buffer space first frequency length-index entry)
  "Pre: lista POSITIONS entro sezione, LENGTHS trovata. Post: ordine e unione senza duplicati.
Controlli validi anche con CRC corretto; errori riportano il posting di origine."
  (let* ((p (+ (aref (spazio-codec-full-text-starts space) 5) (* length-index +length-width+)))
         (n (leggi-u32 buffer (+ p +length-count+)))
         (base (aref (spazio-codec-full-text-prefix space) length-index)) (prior -1))
    (unless (plusp frequency) (error 'invariant-violation :reason :fulltext-position-frequency))
    (dotimes (i frequency)
      (let ((position (leggi-u32 buffer (+ (aref (spazio-codec-full-text-starts space) 4)
                                         (* (+ first i) +position-width+)))))
        (unless (> position prior)
          (error 'corruption-detected :reason :fulltext-position-order :offset entry))
        (marca-posizione space base n position) (setf prior position)))
    (unless (< prior n) (error 'invariant-violation :reason :fulltext-position-result)))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text u16 index index index)
                         (values index index &optional)) verifica-lista-posting))
(defun verifica-lista-posting (buffer space field first count first-position)
  "Pre: lista POSTINGS entro sezione, copertura LENGTHS pronta. Post: nuovi cursori esatti.
Righe strettamente crescenti; frequenze positive e liste posizioni contigue."
  (let ((prior-row -1) (position first-position)
        (position-count (floor (aref (spazio-codec-full-text-lengths space) 4) +position-width+)))
    (dotimes (i count)
      (lavoro-codec space)
      (let* ((p (+ (aref (spazio-codec-full-text-starts space) 3) (* (+ first i) +posting-width+)))
             (row (leggi-u32 buffer p)) (frequency (leggi-u32 buffer (+ p +posting-frequency+)))
             (length-index (cerca-lunghezza-file buffer space row field)))
        (unless (> row prior-row) (error 'corruption-detected :reason :fulltext-posting-order :offset p))
        (unless (<= 1 frequency (- position-count position))
          (error 'corruption-detected :reason :fulltext-posting-frequency :offset p))
        (u64-esatto buffer (+ p +posting-first-position+) position :fulltext-position-partition)
        (verifica-posizioni-posting buffer space position frequency length-index p)
        (setf prior-row row) (incf position frequency)))
    (unless (<= position position-count) (error 'invariant-violation :reason :fulltext-posting-result))
    (values (+ first count) position)))
