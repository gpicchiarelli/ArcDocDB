(in-package #:arcdocdb.cbor.tests)

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-all-256-complete-leading-bytes
  (let ((accepted 0) (rejected 0))
    (dotimes (lead 256)
      (multiple-value-bind (buffer start end)
          (cbor-fixture (list lead #xa5 #x12 #x34 #x56 #x78 #x9a #xbc #xde) :prefix 3)
        (if (cbor-compare-reference buffer start end) (incf accepted) (incf rejected))))
    ;; 224 argument, 4 indefinite e 1 break; 24 reserved e 3 indefinite illeciti.
    (is (= accepted 229)) (is (= rejected 27))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-all-256-one-byte-spans
  (let ((argument 0) (markers 0) (truncated 0) (reserved 0) (indefinite-error 0))
    (dotimes (lead 256)
      (multiple-value-bind (buffer start end) (cbor-fixture (list lead))
        (let ((major (floor lead 32)) (ai (mod lead 32)))
          (cond ((< ai 24) (incf argument)
                 (cbor-accept buffer start end (list major ai 0 ai end :argument)))
                ((<= 24 ai 27) (incf truncated)
                 (cbor-reject buffer start end 'corruption-detected :cbor-truncated end))
                ((<= 28 ai 30) (incf reserved)
                 (cbor-reject buffer start end 'corruption-detected :cbor-reserved start))
                ((member major '(0 1 6)) (incf indefinite-error)
                 (cbor-reject buffer start end 'corruption-detected :cbor-indefinite start))
                (t (incf markers)
                   (cbor-accept buffer start end
                                (list major ai 0 0 end (if (= major 7) :break :indefinite))))))))
    (is (= argument 192)) (is (= markers 5)) (is (= truncated 32))
    (is (= reserved 24)) (is (= indefinite-error 3))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-all-256-extended-simple-values
  (multiple-value-bind (buffer start end) (cbor-fixture '(#xf8 0) :prefix 5)
    (let ((accepted 0) (rejected 0))
      (dotimes (value 256)
        (setf (aref buffer (1+ start)) value)
        (if (< value 32)
            (progn (incf rejected)
                   (cbor-reject buffer start end 'corruption-detected :cbor-simple (1+ start)))
            (progn (incf accepted)
                   (cbor-accept buffer start end (list 7 24 0 value end :argument)))))
      (is (= accepted 224)) (is (= rejected 32)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-all-65536-big-endian-two-byte-arguments
  (multiple-value-bind (buffer start end) (cbor-fixture '(#x19 0 0) :prefix 5)
    (dotimes (word 65536)
      (setf (aref buffer (1+ start)) (floor word 256)
            (aref buffer (+ start 2)) (mod word 256))
      (cbor-accept buffer start end (list 0 25 0 word end :argument)))
    (format t "  CBOR BE: 65536 argomenti a 16 bit, compresi quelli non minimi.~%")))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-immediate-values-without-body-or-tag-child
  (dotimes (major 8)
    (dotimes (ai 24)
      (let ((buffer (bytes (+ (* major 32) ai))))
        ;; Anche stringhe/array/mappe con lunghezza non nulla e tag senza figlio:
        ;; questa funzione verifica solo la testa, non un data item completo.
        (cbor-accept buffer 0 1 (list major ai 0 ai 1 :argument)))))
  (cbor-accept (bytes #x43 #xff #xff #xff #xff) 0 5 '(2 3 0 3 1 :argument)))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-raw-widths-preserve-nonminimal-arguments
  (dotimes (major 7)
    (loop for ai from 24 to 27 for width in '(1 2 4 8)
          do (dolist (argument '(0 23 24 255 256 65535 65536 4294967295 4294967296))
               (when (< argument (expt 256 width))
                 (multiple-value-bind (buffer start end)
                     (cbor-fixture (cons (+ (* major 32) ai) (cbor-big-endian argument width)))
                   (cbor-accept buffer start end
                                (list major ai (floor argument 4294967296)
                                      (mod argument 4294967296) end :argument))))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-u64-extremes-and-asymmetric-words
  (dolist (words '((0 0) (0 1) (0 #xffffffff) (1 0) (#x7fffffff #xffffffff)
                   (#x80000000 0) (#xffffffff 0) (#xffffffff #xffffffff)
                   (#x01234567 #x89abcdef) (#xfedcba98 #x76543210)))
    (dotimes (major 8)
      (multiple-value-bind (buffer start end)
          (cbor-fixture (append (list (+ (* major 32) 27))
                                (cbor-big-endian (first words) 4)
                                (cbor-big-endian (second words) 4)) :prefix 11)
        (cbor-accept buffer start end
                     (list major 27 (first words) (second words) end :argument))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-floating-bits-zero-sign-infinity-and-nan
  (dolist (entry '((25 2 (0 #x8000 #x3e00 #x7c00 #xfc00 #x7e00 #x7c01))
                   (26 4 (0 #x80000000 #x3fc00000 #x7f800000 #xff800000 #x7fc00000 1))))
    (dolist (word (third entry))
      (multiple-value-bind (buffer start end)
          (cbor-fixture (cons (+ 224 (first entry)) (cbor-big-endian word (second entry))))
        (cbor-accept buffer start end (list 7 (first entry) 0 word end :argument)))))
  (dolist (words '((0 0) (#x80000000 0) (#x3ff80000 0) (#x7ff00000 0)
                   (#xfff00000 0) (#x7ff80000 0) (#x7ff00000 1) (0 1)))
    (multiple-value-bind (buffer start end)
        (cbor-fixture (append '(#xfb) (cbor-big-endian (first words) 4)
                              (cbor-big-endian (second words) 4)))
      (cbor-accept buffer start end (list 7 27 (first words) (second words) end :argument)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-indefinite-and-break-are-context-free-markers
  (dolist (major '(2 3 4 5 7))
    (multiple-value-bind (buffer start end)
        (cbor-fixture (list (+ (* major 32) 31) #x1c #xf8 0 #xff))
      (cbor-accept buffer start end
                   (list major 31 0 0 (1+ start) (if (= major 7) :break :indefinite))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-reserved-and-illegal-indefinite-precede-arguments
  (dotimes (major 8)
    (dolist (ai '(28 29 30))
      (multiple-value-bind (buffer start end) (cbor-fixture (list (+ (* major 32) ai)))
        (cbor-reject buffer start end 'corruption-detected :cbor-reserved start))))
  (dolist (major '(0 1 6))
    (multiple-value-bind (buffer start end) (cbor-fixture (list (+ (* major 32) 31)))
      (cbor-reject buffer start end 'corruption-detected :cbor-indefinite start))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-every-argument-truncation-and-declared-end
  (let ((truncations 0))
    (dotimes (major 8)
      (loop for ai from 24 to 27 for width in '(1 2 4 8)
            do (multiple-value-bind (buffer start end)
                   (cbor-fixture (cons (+ (* major 32) ai)
                                       (subseq '(#xa5 #x12 #x34 #x56 #x78 #x9a #xbc #xde) 0 width)))
                 ;; I byte che completerebbero la testa sono fisicamente presenti,
                 ;; ma fuori dal limite di ciascuno dei prefissi dichiarati.
                 (loop for available from 0 below (1+ width)
                       for limit = (+ start available)
                       do (incf truncations)
                          (cbor-reject buffer start limit 'corruption-detected :cbor-truncated limit))
                 (is (cbor-compare-reference buffer start end)))))
    (is (= truncations 152))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-simple-check-follows-complete-head
  (multiple-value-bind (buffer start end) (cbor-fixture '(#xf8 0))
    (cbor-reject buffer start (1+ start) 'corruption-detected :cbor-truncated (1+ start))
    (cbor-reject buffer start end 'corruption-detected :cbor-simple (1+ start))
    (setf (aref buffer (1+ start)) 32)
    (cbor-accept buffer start end (list 7 24 0 32 end :argument)))
  (cbor-reject (bytes #xf8 0) -1 1 'invalid-argument :cbor-range nil))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-invalid-buffer-and-range-before-content
  (let ((buffer (bytes #x1c #xf8 0)))
    (dolist (range '((-1 1) (0 -1) (2 1) (0 4) (4 4) (nil 1) (0 nil) (1.0 2) (0 1.0)))
      (cbor-reject buffer (first range) (second range) 'invalid-argument :cbor-range nil))
    (cbor-reject buffer (1+ most-positive-fixnum) (1+ most-positive-fixnum)
                 'invalid-argument :cbor-range nil)
    (cbor-reject buffer 0 (1+ most-positive-fixnum) 'invalid-argument :cbor-range nil))
  (let* ((base (bytes 1 2 3 4))
         (displaced (make-array 2 :element-type '(unsigned-byte 8) :displaced-to base)))
    (dolist (buffer (list nil '(65) #(65) "A"
                          (make-array 2 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 2 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array '(2 2) :element-type '(unsigned-byte 8)) displaced))
      (cbor-reject buffer 0 0 'invalid-argument :cbor-range nil))
    (is (equalp base (bytes 1 2 3 4)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-empty-valid-spans-have-end-offset
  (cbor-reject (bytes) 0 0 'corruption-detected :cbor-truncated 0)
  (dolist (position '(0 1 3))
    (cbor-reject (bytes #x1c #xf8 0) position position
                 'corruption-detected :cbor-truncated position)))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-misaligned-heads-ignore-trailing-bytes
  (loop for prefix from 1 to 17
        do (multiple-value-bind (buffer start end)
               (cbor-fixture '(#x1b #x01 #x23 #x45 #x67 #x89 #xab #xcd #xef #x1c #xf8 0) :prefix prefix)
             (cbor-accept buffer start end
                          (list 0 27 #x01234567 #x89abcdef (+ start 9) :argument))
             (cbor-accept buffer start (+ start 9)
                          (list 0 27 #x01234567 #x89abcdef (+ start 9) :argument)))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-differential-fuzz-4096-bounded-spans
  (let ((seed #x8949a11f) (accepted 0) (rejected 0))
    (flet ((advance () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (sample 4096)
        (let* ((length (1+ (mod (ash (advance) -16) 9)))
               (start (1+ (mod (ash (advance) -16) 7)))
               (end (+ start length))
               (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xff)))
          (dotimes (i length) (setf (aref buffer (+ start i)) (ldb (byte 8 24) (advance))))
          (if (cbor-compare-reference buffer start end) (incf accepted) (incf rejected)))))
    (is (= 4096 (+ accepted rejected))) (is (plusp accepted)) (is (plusp rejected))
    (format t "  CBOR fuzz: seed 8949A11F, 4096 span di 1..9 byte, ~D validi, ~D rifiutati.~%"
            accepted rejected)))
