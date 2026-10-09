(in-package #:arcdocdb.foundation.tests)

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-typed-errors-rendering
  (dolist (type '(arcdocdb.conditions:invalid-argument arcdocdb.conditions:corruption-detected
                  arcdocdb.conditions:unsupported-format arcdocdb.conditions:resource-exhausted
                  arcdocdb.conditions:invariant-violation))
    (dolist (offset '(nil 7))
      (let ((condition (make-condition type :reason :probe :offset offset)))
        (is (typep condition 'arcdocdb.conditions:arcdocdb-error))
        (is (eq :probe (error-reason condition)))
        (is (eql offset (arcdocdb.conditions:error-offset condition)))
        (is (search "PROBE" (format nil "~A" condition)))
        (is (eql (not (null offset)) (not (null (search "offset 7" (format nil "~A" condition))))))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-out-of-line-readers
  (let ((buffer (bytes 1 2 3 4 5 6 7 8)))
    (is (= #x0201 (funcall (symbol-function 'leggi-u16) buffer 0)))
    (is (= #x04030201 (funcall (symbol-function 'leggi-u32) buffer 0)))
    (signals invalid-argument (funcall (symbol-function 'leggi-u16) buffer 7))
    (signals invalid-argument (funcall (symbol-function 'leggi-u32) buffer 6))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-little-endian
  (let ((buffer (make-array 24 :element-type '(unsigned-byte 8) :initial-element #xcc)))
    (scrivi-u16 buffer 1 #xabcd)
    (is (= #xcd (aref buffer 1)))
    (is (= #xab (aref buffer 2)))
    (is (= #xabcd (leggi-u16 buffer 1)))
    (scrivi-u32 buffer 3 #x12345678)
    (is (equalp (subseq buffer 3 7) #(120 86 52 18)))
    (is (= #x12345678 (leggi-u32 buffer 3)))
    (dolist (value '(0 1 4294967295 9223372036854775808 18446744073709551615))
      (scrivi-u64 buffer 7 value)
      (is (= value (leggi-u64 buffer 7))))
    (is (= #xcc (aref buffer 0)))
    (is (= #xcc (aref buffer 15)))))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-ranges
  (let* ((buffer (bytes 1 2 3 4 5 6 7 8)) (before (copy-seq buffer)))
    (signals invalid-argument (leggi-u16 buffer 7) :buffer-range)
    (signals invalid-argument (leggi-u32 buffer 5) :buffer-range)
    (signals invalid-argument (leggi-u64 buffer 1) :buffer-range)
    (signals invalid-argument (scrivi-u64 buffer 1 99) :buffer-range)
    (signals invalid-argument (crc32c buffer 3 2) :buffer-range)
    (signals invalid-argument (crc32c buffer 0 9) :buffer-range)
    (is (equalp before buffer))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-crc-known-vectors
  (is (zerop (crc32c (bytes) 0 0)))
  (is (= #xe3069283 (crc32c (bytes 49 50 51 52 53 54 55 56 57) 0 9)))
  (is (= #x8a9136aa (crc32c (make-array 32 :element-type '(unsigned-byte 8)
                                         :initial-element 0) 0 32)))
  (is (= #x62a8ab43 (crc32c (make-array 32 :element-type '(unsigned-byte 8)
                                         :initial-element 255) 0 32))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-crc-differential-incremental
  (let ((buffer (make-array 1031 :element-type '(unsigned-byte 8))) (state #x13579bdf))
    (dotimes (i (length buffer))
      (setf state (logand #xffffffff (+ (* state 1664525) 1013904223))
            (aref buffer i) (ldb (byte 8 16) state)))
    (dotimes (alignment 8)
      (dotimes (size 257)
        (let* ((end (+ alignment size)) (middle (+ alignment (floor size 2)))
               (expected (reference-crc buffer alignment end)))
          (is (= expected (crc32c buffer alignment end)))
          (is (= expected (crc32c buffer middle end
                                 (crc32c buffer alignment middle)))))))
    (is (= (reference-crc buffer 3 1031 #xdeadbeef)
           (crc32c buffer 3 1031 #xdeadbeef)))))
