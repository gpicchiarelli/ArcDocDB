(in-package #:arcdocdb.cbor.minimal.tests)

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-all-leading-bytes-and-short-spans
  (let ((accepted 0) (rejected 0))
    (dotimes (lead 256)
      (multiple-value-bind (buffer start end)
          (cbor-fixture (list lead #xa5 #x12 #x34 #x56 #x78 #x9a #xbc #xde) :prefix 3)
        (if (cm-compare buffer start end) (incf accepted) (incf rejected))
        (cm-compare buffer start (1+ start))))
    (is (= accepted 224)) (is (= rejected 32))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-major-zero-to-six-width-thresholds
  (dotimes (major 7)
    (dotimes (ai 24)
      (cm-accept (bytes (+ (* major 32) ai)) 0 1 (list major ai 0 ai 1 :argument)))
    (loop for ai from 24 to 27 for width in '(1 2 4 8)
          do (dolist (argument '(0 1 22 23 24 25 254 255 256 257 65534 65535 65536 65537
                                4294967294 4294967295 4294967296 4294967297
                                9223372036854775807 9223372036854775808 18446744073709551615))
               (when (< argument (expt 256 width))
                 (multiple-value-bind (buffer start end) (cm-header-fixture major ai argument)
                   (cm-compare buffer start end)))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-all-extended-simple-values
  (dotimes (word 256)
    (multiple-value-bind (buffer start end) (cm-header-fixture 7 24 word)
      (if (< word 32)
          (cm-reject buffer start end 'corruption-detected :cbor-simple (1+ start))
          (cm-accept buffer start end (list 7 24 0 word end :argument)))))
  (dotimes (ai 24)
    (cm-accept (bytes (+ 224 ai)) 0 1 (list 7 ai 0 ai 1 :argument))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-all-half-and-exact-expansions
  (multiple-value-bind (half hs he) (cm-float-fixture 16 0)
    (multiple-value-bind (single ss se) (cm-float-fixture 32 0)
      (multiple-value-bind (double ds de) (cm-float-fixture 64 0)
        (dotimes (bits 65536)
          (let* ((description (cm-description bits 16))
                 (wide32 (cm-encode-description description 32))
                 (wide64 (cm-encode-description description 64)))
            (is (integerp wide32)) (is (integerp wide64))
            (is (cm-same-description-p description (cm-description wide32 32)))
            (is (cm-same-description-p description (cm-description wide64 64)))
            (cm-set-argument half hs bits 2)
            (cm-set-argument single ss wide32 4)
            (cm-set-argument double ds wide64 8)
            (cm-accept half hs he (list 7 25 0 bits he :argument))
            (cm-reject single ss se 'corruption-detected :cbor-nonminimal ss)
            (cm-reject double ds de 'corruption-detected :cbor-nonminimal ds))))))
  (format t "  CBOR minimo: 65536 half e 131072 espansioni esatte, inclusi NaN e segni.~%"))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-ieee-oracle-known-values
  (dolist (entry '((16 #x0001 :finite 0 1/16777216)
                   (16 #x03ff :finite 0 1023/16777216)
                   (16 #x0400 :finite 0 1/16384)
                   (16 #x3e00 :finite 0 3/2)
                   (16 #x7bff :finite 0 65504)
                   (16 #x8000 :zero 1 0)
                   (16 #xfc00 :infinity 1 0)
                   (16 #x7c01 :nan 0 1)
                   (32 #x00000001 :finite 0 1/713623846352979940529142984724747568191373312)))
    (let ((d (cm-description (second entry) (first entry))))
      (is (equal (subseq d 0 3) (subseq entry 2 5)))))
  (is (= (cm-encode-description (cm-description #x7c01 16) 32) #x7f802000))
  (is (= (cm-encode-description (cm-description #x7e00 16) 32) #x7fc00000))
  (is (= (cm-encode-description (cm-description #x3c00 16) 64) #x3ff0000000000000))
  (is (null (cm-encode-description (cm-description #x7fc00001 32) 16))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-rfc-numeric-vectors-and-adjacent-values
  (dolist (entry '((16 #x4580 t) (32 #x45ad9c00 t) (32 #x49742408 t)
                   (16 #x3e00 t) (32 #x3fc00000 nil) (64 #x3ff8000000000000 nil)
                   (32 #x3f800001 t) (64 #x3ff0000000000001 t)
                   (64 #x3ff0000000000000 nil) (64 #x3ff0000020000000 nil)))
    (is (eq (cm-float-minimal-p (second entry) (first entry)) (third entry)))
    (multiple-value-bind (buffer start end) (cm-float-fixture (first entry) (second entry))
      (cm-compare buffer start end))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-finite-normal-subnormal-boundaries
  (dolist (format '((32 #x00000001 #x007fffff #x00800000 #x33000000 #x33800000
                     #x387fc000 #x38800000 #x477fe000 #x47800000 #x7f7fffff)
                    (64 #x0000000000000001 #x000fffffffffffff #x0010000000000000
                     #x3680000000000000 #x36a0000000000000 #x380fffffc0000000
                     #x3810000000000000 #x47efffffe0000000 #x47f0000000000000
                     #x7fefffffffffffff)))
    (let ((size (first format)))
      (dolist (center (rest format))
        (dolist (bits (cm-neighbors center size))
          (dolist (signed (list bits (+ bits (expt 2 (1- size)))))
            (multiple-value-bind (buffer start end) (cm-float-fixture size signed)
              (cm-compare buffer start end)))))))
  ;; Soglie del formato piu corto costruite come valori, non come shift del prodotto.
  (dolist (pair '((16 32) (32 64)))
    (let* ((small (first pair)) (large (second pair))
           (centers (if (= small 16) '(1 1023 1024 15360 31743)
                        '(1 8388607 8388608 1065353216 2139095039))))
      (dolist (bits centers)
        (let ((wide (cm-encode-description (cm-description bits small) large)))
          (dolist (neighbor (cm-neighbors wide large))
            (multiple-value-bind (buffer start end) (cm-float-fixture large neighbor)
              (cm-compare buffer start end))))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-sign-zero-infinity-and-nan-payload
  (dolist (entry '((32 #x00000000 nil) (32 #x80000000 nil)
                   (32 #x7f800000 nil) (32 #xff800000 nil)
                   (32 #x7fc00000 nil) (32 #x7fc00001 t)
                   (32 #x7f802000 nil) (32 #x7f800001 t)
                   (32 #xffc00000 nil) (32 #xffc00001 t)
                   (64 #x0000000000000000 nil) (64 #x8000000000000000 nil)
                   (64 #x7ff0000000000000 nil) (64 #xfff0000000000000 nil)
                   (64 #x7ff8000000000000 nil) (64 #x7ff8000000000001 t)
                   (64 #x7ff0000020000000 nil) (64 #x7ff0000000000001 t)
                   (64 #xfff8000020000000 nil) (64 #xfff8000000000001 t)))
    (is (eq (cm-float-minimal-p (second entry) (first entry)) (third entry)))
    (multiple-value-bind (buffer start end) (cm-float-fixture (first entry) (second entry))
      (cm-compare buffer start end)))
  ;; L'ultimo bit trattenuto e il primo scartabile delimitano ogni payload.
  (dolist (pair '((32 13) (64 29)))
    (let* ((size (first pair)) (shift (second pair))
           (p (second (cm-format size))) (e (first (cm-format size)))
           (base (* (1- (expt 2 e)) (expt 2 p))))
      (dolist (payload (list 1 (1- (expt 2 shift)) (expt 2 shift) (1+ (expt 2 shift))
                             (expt 2 (1- p)) (1+ (expt 2 (1- p)))))
        (dolist (sign '(0 1))
          (multiple-value-bind (buffer start end)
              (cm-float-fixture size (+ (* sign (expt 2 (1- size))) base payload))
            (cm-compare buffer start end)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-every-truncated-head-before-preference
  (let ((count 0))
    (dotimes (major 8)
      (loop for ai from 24 to 27 for width in '(1 2 4 8)
            do (multiple-value-bind (buffer start end) (cm-header-fixture major ai 0)
                 (declare (ignore end))
                 (dotimes (available (1+ width))
                   (incf count)
                   (cm-reject buffer start (+ start available) 'corruption-detected
                              :cbor-truncated (+ start available))))))
    (is (= count 152))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-syntax-before-nonminimal
  (dotimes (major 8)
    (dolist (ai '(28 29 30))
      (multiple-value-bind (buffer start end) (cbor-fixture (list (+ (* major 32) ai)))
        (cm-reject buffer start end 'corruption-detected :cbor-reserved start))))
  (dotimes (major 8)
    (multiple-value-bind (buffer start end) (cbor-fixture (list (+ (* major 32) 31)))
      (cm-reject buffer start end 'corruption-detected
                 (if (member major '(0 1 6)) :cbor-indefinite :cbor-nonminimal) start)))
  (multiple-value-bind (buffer start end) (cm-header-fixture 7 24 0)
    (cm-reject buffer start (1+ start) 'corruption-detected :cbor-truncated (1+ start))
    (cm-reject buffer start end 'corruption-detected :cbor-simple (1+ start))
    (cm-reject buffer -1 end 'invalid-argument :cbor-range nil)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-invalid-buffer-range-and-empty-span
  (let ((buffer (bytes #x1c #xf8 0)))
    (dolist (range '((-1 1) (0 -1) (2 1) (0 4) (4 4) (nil 1) (0 nil) (1.0 2) (0 1.0)))
      (cm-reject buffer (first range) (second range) 'invalid-argument :cbor-range nil))
    (cm-reject buffer (1+ most-positive-fixnum) (1+ most-positive-fixnum)
               'invalid-argument :cbor-range nil)
    (dolist (position '(0 1 3))
      (cm-reject buffer position position 'corruption-detected :cbor-truncated position)))
  (cm-reject (bytes) 0 0 'corruption-detected :cbor-truncated 0)
  (let* ((base (bytes 1 2 3 4))
         (displaced (make-array 2 :element-type '(unsigned-byte 8) :displaced-to base)))
    (dolist (buffer (list nil '(65) #(65) "A"
                          (make-array 2 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 2 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array '(2 2) :element-type '(unsigned-byte 8)) displaced))
      (cm-reject buffer 0 0 'invalid-argument :cbor-range nil))
    (is (equalp base (bytes 1 2 3 4)))))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-LIM-002-cbor-minimal-header-only-and-misaligned-sentinels
  (loop for prefix from 1 to 17
        do (multiple-value-bind (buffer start end)
               (cbor-fixture '(#xfb #x3f #xf0 0 0 0 0 0 1 #x1c #xf8 0) :prefix prefix)
             (cm-accept buffer start end (list 7 27 #x3ff00000 1 (+ start 9) :argument))
             (cm-accept buffer start (+ start 9)
                        (list 7 27 #x3ff00000 1 (+ start 9) :argument))
             (cm-reject buffer start (+ start 8) 'corruption-detected :cbor-truncated (+ start 8))))
  (dolist (head '(#x43 #x84 #xa2 #xc0))
    (let ((buffer (bytes head)))
      (cm-accept buffer 0 1 (list (floor head 32) (mod head 32) 0 (mod head 32) 1 :argument)))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-finite-differential-fuzz-seed-4d494e43
  (let ((seed #x4d494e43) (accepted 0) (rejected 0) (nonminimal 0))
    (flet ((advance () (setf seed (mod (+ (* seed 1664525) 1013904223) 4294967296)))
           (record-result (buffer start end)
             (multiple-value-bind (ok reason) (cm-compare buffer start end)
               (if ok (incf accepted) (incf rejected))
               (when (eq reason :cbor-nonminimal) (incf nonminimal)))))
      (dolist (size '(32 64))
        (dotimes (sample 4096)
          (declare (ignorable sample))
          (let ((word 0))
            (dotimes (octet (/ size 8))
              (declare (ignorable octet))
              (setf word (+ (* word 256) (floor (advance) 16777216))))
            (multiple-value-bind (buffer start end) (cm-float-fixture size word)
              (record-result buffer start end)))))
      (dotimes (sample 4096)
        (declare (ignorable sample))
        (let* ((span (mod (floor (advance) 65536) 10))
               (start (1+ (mod (floor (advance) 65536) 7))) (end (+ start span))
               (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xff)))
          (dotimes (i span) (setf (aref buffer (+ start i)) (floor (advance) 16777216)))
          (record-result buffer start end))))
    (is (= (+ accepted rejected) 12288)) (is (plusp accepted)) (is (plusp rejected))
    (format t "  CBOR minimo fuzz: seed4D494E43, 4096word32+4096word64+4096span0..9, ~D accettati/~D rifiutati/~D nonminimi.~%"
            accepted rejected nonminimal)))
