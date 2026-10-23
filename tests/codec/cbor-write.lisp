(in-package #:arcdocdb.cbor.write.tests)

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-literal-vectors-all-seven-major-types
  (dolist (entry '((0 0 (#x00)) (0 23 (#x17)) (0 24 (#x18 #x18))
                   (0 255 (#x18 #xff)) (0 256 (#x19 #x01 #x00))
                   (0 65535 (#x19 #xff #xff)) (0 65536 (#x1a #x00 #x01 #x00 #x00))
                   (0 #xffffffff (#x1a #xff #xff #xff #xff))
                   (1 0 (#x1b #x00 #x00 #x00 #x01 #x00 #x00 #x00 #x00))
                   (1 #xffffffff (#x1b #x00 #x00 #x00 #x01 #xff #xff #xff #xff))
                   (#xffffffff #xffffffff (#x1b #xff #xff #xff #xff #xff #xff #xff #xff))
                   (#x01234567 #x89abcdef (#x1b #x01 #x23 #x45 #x67 #x89 #xab #xcd #xef))))
    (destructuring-bind (high low literal) entry
      (dotimes (major 7)
        (let ((expected (cw-literal-major major literal)))
          (is (equal expected (cw-reference major high low)))
          (multiple-value-bind (buffer start end) (cw-fixture (+ 3 (length expected)))
            (cw-accept buffer start end major high low expected)))))))

;;; REQ: REQ-CBR-001 REQ-AFF-004
(deftest test-REQ-CBR-001-cbor-write-direct-arguments-zero-through-twenty-three
  (dotimes (major 7)
    (dotimes (low 24)
      (let ((buffer (bytes #x99)))
        (cw-accept buffer 0 1 major 0 low (list (+ (* major 32) low)))))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-adjacent-width-boundaries-and-split-u64
  (dotimes (major 7)
    (dolist (low '(0 1 22 23 24 25 254 255 256 257 65534 65535 65536 65537
                  #x7fffffff #x80000000 #xfffffffe #xffffffff))
      (multiple-value-bind (buffer start end) (cw-fixture 12)
        (cw-compare buffer start end major 0 low)))
    (dolist (high '(1 2 #x7fffffff #x80000000 #xfffffffe #xffffffff))
      (dolist (low '(0 1 23 24 255 256 #x7fffffff #x80000000 #xffffffff))
        (multiple-value-bind (buffer start end) (cw-fixture 9)
          (cw-compare buffer start end major high low))))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-all-u16-arguments-for-each-major
  (let ((count 0))
    (multiple-value-bind (buffer start end) (cw-fixture 12)
      (dotimes (major 7)
        (dotimes (low 65536)
          (cw-compare buffer start end major 0 low)
          (incf count))))
    (is (= count 458752))
    (format t "  CBOR write: 65536 argomenti u16 x 7 major, ~D confronti aritmetici freddi.~%" count)))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-every-insufficient-capacity-before-any-byte
  (let ((count 0))
    (dotimes (major 7)
      (dolist (pair '((0 23) (0 24) (0 256) (0 65536) (1 0)))
        (let* ((high (first pair)) (low (second pair))
               (size (length (cw-reference major high low))))
          (dotimes (available size)
            ;; Il suffisso fisico contiene spazio sufficiente, ma END lo esclude.
            (multiple-value-bind (buffer start end) (cw-fixture available :suffix 17)
              (cw-reject buffer start end major high low
                         'resource-exhausted :cbor-write-capacity)
              (incf count))))))
    (is (= count 140))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-invalid-ranges-dominate-all-other-errors
  (let ((buffer (bytes #xa0 #xb1 #xc2 #xd3)))
    (dolist (range '((-1 1) (0 -1) (2 1) (0 5) (5 5) (nil 1) (0 nil)
                     (1.0 2) (0 1.0) (1/2 2) (0 3/2) (:start 1) (0 :end)))
      (cw-reject buffer (first range) (second range) 7 -1 #x100000000
                 'invalid-argument :cbor-range))
    (cw-reject buffer (1+ most-positive-fixnum) (1+ most-positive-fixnum)
               7 -1 #x100000000 'invalid-argument :cbor-range)
    (cw-reject buffer 0 (1+ most-positive-fixnum)
               7 -1 #x100000000 'invalid-argument :cbor-range)))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-rejects-non-simple-octet-destinations
  (let* ((base (bytes 1 2 3 4))
         (displaced (make-array 2 :element-type '(unsigned-byte 8) :displaced-to base)))
    (dolist (buffer (list nil '(65) #(65) "A" #*1010 7
                          (make-array 2 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 2 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array '(2 2) :element-type '(unsigned-byte 8)) displaced))
      (cw-reject buffer 0 0 7 -1 #x100000000 'invalid-argument :cbor-range))
    (is (equalp base (bytes 1 2 3 4)))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-major-precedes-high-low-and-capacity
  (let ((buffer (bytes #xe0 #xe1 #xe2)))
    (dolist (major (list -1 7 8 (1+ most-positive-fixnum) nil :major 1.0 1/2 #\A #c(1 1)))
      (cw-reject buffer 1 1 major -1 #x100000000 'invalid-argument :cbor-write-major))
    (dotimes (major 7)
      (cw-reject buffer 1 1 major -1 -1 'invalid-argument :cbor-write-high))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-high-precedes-low-and-capacity
  (let ((buffer (bytes #xe0 #xe1 #xe2)))
    (dolist (high (list -1 #x100000000 (1+ most-positive-fixnum) nil :high
                        1.0 1/2 #\A #c(1 1)))
      (cw-reject buffer 1 1 6 high -1 'invalid-argument :cbor-write-high))
    (dolist (high '(0 1 #x7fffffff #x80000000 #xffffffff))
      (cw-reject buffer 1 1 6 high -1 'invalid-argument :cbor-write-low))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-low-precedes-capacity
  (let ((buffer (bytes #xe0 #xe1 #xe2)))
    (dolist (low (list -1 #x100000000 (1+ most-positive-fixnum) nil :low
                       1.0 1/2 #\A #c(1 1)))
      (cw-reject buffer 1 1 0 0 low 'invalid-argument :cbor-write-low))
    (dolist (low '(0 23 24 255 256 65535 65536 #xffffffff))
      (cw-reject buffer 1 1 0 0 low 'resource-exhausted :cbor-write-capacity))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-empty-valid-spans-are-capacity-errors
  (let ((buffer (bytes #xa0 #xb1 #xc2 #xd3)))
    (dolist (position '(0 1 4))
      (cw-reject buffer position position 0 0 0 'resource-exhausted :cbor-write-capacity)))
  (cw-reject (bytes) 0 0 6 #xffffffff #xffffffff 'resource-exhausted :cbor-write-capacity))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-exact-capacity-misalignment-and-extra-span
  (loop for prefix from 0 to 17
        do (dotimes (major 7)
             (dolist (pair '((0 23) (0 24) (0 256) (0 65536) (1 0)))
               (let* ((high (first pair)) (low (second pair))
                      (expected (cw-reference major high low)) (size (length expected)))
                 (multiple-value-bind (buffer start end)
                     (cw-fixture size :prefix prefix :suffix 0)
                   (cw-accept buffer start end major high low expected))
                 (multiple-value-bind (buffer start end)
                     (cw-fixture (+ 7 size) :prefix prefix :suffix 5)
                   (cw-accept buffer start end major high low expected)))))))

;;; REQ: REQ-CBR-001 REQ-LIM-002 REQ-AFF-004
(deftest test-REQ-CBR-001-cbor-write-header-has-no-document-or-payload-budget
  ;; La testata massima occupa nove byte anche per lunghezze/container/tag u64-max.
  (dolist (major '(0 1 2 3 4 5 6))
    (let ((buffer (make-array 9 :element-type '(unsigned-byte 8) :initial-element 0)))
      (cw-accept buffer 0 9 major #xffffffff #xffffffff
                 (cons (+ (* major 32) 27) '(255 255 255 255 255 255 255 255))))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-reuse-and-consecutive-headers
  (multiple-value-bind (buffer start end) (cw-fixture 28)
    (dolist (entry '((6 #x12345678 #x90abcdef) (0 0 0) (3 0 24)
                     (1 #xffffffff #xffffffff) (5 0 256) (2 0 23)))
      (destructuring-bind (major high low) entry
        (cw-compare buffer start end major high low)))
    (let ((cursor start))
      (dolist (entry '((0 0 0) (1 0 24) (2 0 256) (3 0 65536) (6 1 0)))
        (destructuring-bind (major high low) entry
          (setf cursor (cw-compare buffer cursor end major high low))))
      (is (= cursor (+ start 20)))
      (cw-reject buffer cursor cursor 0 0 0 'resource-exhausted :cbor-write-capacity)
      (cw-compare buffer start end 4 0 1))))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-differential-fuzz-seed-57524342
  (let ((seed #x57524342) (widths (make-array 10 :initial-element 0)) (count 0))
    (flet ((advance () (setf seed (mod (+ (* seed 1664525) 1013904223) #x100000000))))
      (dotimes (sample 4096)
        (let* ((word (advance)) (other (advance))
               (major (mod (advance) 7)) (prefix (mod (advance) 18))
               (high (if (< (mod sample 8) 4) 0 (max 1 word)))
               (low (case (mod sample 8)
                      (0 (mod other 24)) (1 (mod other 256))
                      (2 (mod other 65536)) (t other)))
               (expected (cw-reference major high low))
               (slack (mod (advance) 6)))
          (multiple-value-bind (buffer start end)
              (cw-fixture (+ (length expected) slack) :prefix prefix :suffix 7)
            (cw-accept buffer start end major high low expected)
            (incf (aref widths (length expected))) (incf count)))))
    (is (= count 4096))
    (dolist (size '(1 2 3 5 9)) (is (plusp (aref widths size))))
    (is (= (reduce #'+ widths) count))
    (format t "  CBOR write fuzz: seed57524342, ~D casi; dimensioni1/2/3/5/9 = ~D/~D/~D/~D/~D.~%"
            count (aref widths 1) (aref widths 2) (aref widths 3)
            (aref widths 5) (aref widths 9))))
