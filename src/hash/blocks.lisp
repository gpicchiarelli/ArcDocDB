;;; OWNER: accumulazione locale, buffer e seme immutati del chiamante.
;;; SHARED: nessun accesso a controller, indici o altre Serie.
(in-package #:arcdocdb.hash64)
(declaim (optimize (safety 3) (speed 3) (debug 2)))
(declaim (inline hash-blocks hash-tail))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (octets index hash-length u64) u64) hash-blocks))
(defun hash-blocks (buffer start size seed)
  "Pre: span verificato, SIZE>=32, seme u64. Post: digest dei blocchi completi da 32 byte.
Al massimo floor(65535/32) iterazioni; helper inline, input immutato, nessuna risorsa.
INVARIANT-VIOLATION :hash-block-span o :hash-block-progress su relazione interna violata."
  (unless (and (>= size 32) (<= (+ start size) (length buffer)))
    (error 'invariant-violation :reason :hash-block-span))
  (let ((v1 (logand +mask64+ (+ seed +prime1+ +prime2+)))
        (v2 (logand +mask64+ (+ seed +prime2+))) (v3 seed)
        (v4 (logand +mask64+ (- seed +prime1+))) (position start))
    (declare (type u64 v1 v2 v3 v4) (type index position))
    (dotimes (i (ash size -5))
      (setf v1 (round64 v1 (read64 buffer position))
            v2 (round64 v2 (read64 buffer (+ position 8)))
            v3 (round64 v3 (read64 buffer (+ position 16)))
            v4 (round64 v4 (read64 buffer (+ position 24))))
      (incf position 32))
    (unless (= position (+ start (* 32 (ash size -5))))
      (error 'invariant-violation :reason :hash-block-progress))
    (let ((accumulator (logand +mask64+ (+ (rotate64 v1 1) (rotate64 v2 7)
                                          (rotate64 v3 12) (rotate64 v4 18)))))
      (declare (type u64 accumulator))
      (setf accumulator (merge64 accumulator v1)
            accumulator (merge64 accumulator v2)
            accumulator (merge64 accumulator v3))
      (merge64 accumulator v4))))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (octets index index u64) u64) hash-tail))
(defun hash-tail (buffer start end accumulator)
  "Pre: span residuo verificato, da 0 a 31 byte; accumulatore include lunghezza totale.
Post: coda XXH64, pura e inline. Al massimo tre lane da 8, una da 4 e tre byte.
INVARIANT-VIOLATION :hash-tail-span o :hash-tail-progress su relazione interna violata."
  (unless (and (<= start end (length buffer)) (<= (- end start) 31))
    (error 'invariant-violation :reason :hash-tail-span))
  (let ((position start) (value accumulator))
    (declare (type index position) (type u64 value))
    (dotimes (i (ash (- end start) -3))
      (setf value (logxor value (round64 0 (read64 buffer position)))
            value (logand +mask64+ (+ (* (rotate64 value 27) +prime1+) +prime4+)))
      (incf position 8))
    (when (<= 4 (- end position))
      (setf value (logxor value (logand +mask64+ (* (read32 buffer position) +prime1+)))
            value (logand +mask64+ (+ (* (rotate64 value 23) +prime2+) +prime3+)))
      (incf position 4))
    (loop while (< position end) do
      (setf value (logxor value (logand +mask64+ (* (aref buffer position) +prime5+)))
            value (logand +mask64+ (* (rotate64 value 11) +prime1+)))
      (incf position))
    (unless (= position end)
      (error 'invariant-violation :reason :hash-tail-progress))
    value))
