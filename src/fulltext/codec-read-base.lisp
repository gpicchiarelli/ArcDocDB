(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index keyword) index) indice-u64-bounded))
(defun indice-u64-bounded (buffer position maximum reason)
  "Pre: otto byte presenti, massimo fixnum. Post: indice entro massimo, nessun bignum.
CORRUPTION-DETECTED prima di ricomporre un u64 esterno troppo grande."
  (unless (<= (+ position 8) (length buffer)) (error 'invariant-violation :reason :fulltext-u64-range))
  (let ((low (leggi-u32 buffer position)) (high (leggi-u32 buffer (+ position 4)))
        (mh (ldb (byte 32 32) maximum)) (ml (ldb (byte 32 0) maximum)))
    (when (or (> high mh) (and (= high mh) (> low ml)))
      (error 'corruption-detected :reason reason :offset position))
    (let ((value (logior (ash high 32) low)))
      (unless (<= value maximum) (error 'invariant-violation :reason :fulltext-u64-result))
      value)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index keyword) null) u64-esatto))
(defun u64-esatto (buffer position expected reason)
  "Pre: otto byte presenti. Post: uguaglianza esatta senza allocazione anche su dati ostili."
  (unless (arcdocdb.record:u64-equal-p buffer position expected)
    (error 'corruption-detected :reason reason :offset position))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index descrittore-full-text spazio-codec-full-text index) null)
                leggi-sezioni-codec))
(defun leggi-sezioni-codec (buffer start end descriptor space max-bytes)
  "Pre: span/argomenti verificati. Post: cornice integra, META atteso, sei span assoluti.
CRC e confronto META addebitati al budget prima dell'uso dei payload."
  (lavoro-codec space (- end start))
  (multiple-value-bind (next meta-start meta-end)
      (f:verifica-cornice-indice-full-text buffer start end (descrittore-full-text-identity descriptor)
                                         (car (descrittore-full-text-segment-box descriptor)) :max-bytes max-bytes)
    (unless (= next end) (error 'invariant-violation :reason :fulltext-read-frame-end))
    (unless (zerop (confronta-span-codec buffer meta-start meta-end (descrittore-full-text-meta descriptor)
                                      0 (length (descrittore-full-text-meta descriptor)) space))
      (error 'corruption-detected :reason :fulltext-meta-mismatch))
    (dotimes (i 6)
      (lavoro-codec space)
      (let* ((entry (+ start f::+header-bytes+ (* i f::+directory-entry-bytes+)))
             (offset (indice-u64-bounded buffer (+ entry f::+entry-start-offset+) (- end start) :fulltext-section-range))
             (size (indice-u64-bounded buffer (+ entry f::+entry-length-offset+) (- end start) :fulltext-section-range)))
        (setf (aref (spazio-codec-full-text-starts space) i) (+ start offset)
              (aref (spazio-codec-full-text-lengths space) i) size)))
    (unless (<= start meta-start meta-end end) (error 'invariant-violation :reason :fulltext-read-meta-span)))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text u32 u16) index) cerca-lunghezza-file))
(defun cerca-lunghezza-file (buffer space row field)
  "Pre: LENGTHS gia verificate e ordinate. Post: indice esatto; assenza e corruzione."
  (let ((low 0) (high (floor (aref (spazio-codec-full-text-lengths space) 5) +length-width+))
        (base (aref (spazio-codec-full-text-starts space) 5)))
    (loop repeat (1+ high) while (< low high) do
      (lavoro-codec space)
      (let* ((mid (floor (+ low high) 2)) (p (+ base (* mid +length-width+)))
             (r (leggi-u32 buffer p)) (f (leggi-u16 buffer (+ p +length-field+))))
        (cond ((or (< r row) (and (= r row) (< f field))) (setf low (1+ mid)))
              ((or (> r row) (> f field)) (setf high mid))
              (t (return-from cerca-lunghezza-file mid)))))
    (error 'corruption-detected :reason :fulltext-missing-length)))
