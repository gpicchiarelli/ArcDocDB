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

;;; REQ: REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-FOR-003-crc-backends-boundaries
  (let ((buffer (make-array 65570 :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ 11 (* i 29)) 251)))
    (let ((before (copy-seq buffer)))
      (dolist (size (append (loop for n from 0 to 128 collect n) '(255 256 257 4095 4096 4097)))
        (dotimes (offset 16)
          (dolist (seed '(0 #xffffffff #x12345678))
            (let* ((end (+ offset size)) (expected (reference-crc buffer offset end seed)))
              (is (= expected (crc32c buffer offset end seed)
                     (arcdocdb.binary::crc32c-lisp buffer offset end seed)))))))
      (dolist (size '(65535 65536 65537))
        (dolist (offset '(0 7 15))
          (is (= (reference-crc buffer offset (+ offset size) #xdeadbeef)
                 (crc32c buffer offset (+ offset size) #xdeadbeef)))))
      (is (equalp buffer before)))
    (is (member (arcdocdb.binary:backend-crc32c) '(:lisp :arm64-crc32c)))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-crc-all-small-splits
  (let ((buffer (make-array 96 :element-type '(unsigned-byte 8) :initial-element 183)))
    (dotimes (size 65)
      (dolist (seed '(0 #xffffffff #x12345678))
        (let ((expected (reference-crc buffer 7 (+ 7 size) seed)))
          (dotimes (split (1+ size))
            (is (= expected (crc32c buffer (+ 7 split) (+ 7 size)
                                   (crc32c buffer 7 (+ 7 split) seed))))))))))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-FOR-003-crc-software-dispatch-and-guards
  (let ((arcdocdb.binary::+crc32c-kernel+ #'arcdocdb.binary::crc32c-lisp)
        (buffer (make-array 80 :element-type '(unsigned-byte 8) :initial-element 41)))
    (is (= (reference-crc buffer 3 70 #xdeadbeef) (crc32c buffer 3 70 #xdeadbeef)))
    (signals invalid-argument (crc32c buffer 7 3) :buffer-range)
    (signals invalid-argument (crc32c buffer 0 81) :buffer-range)
    (let ((expected (crc32c buffer 16 48)))
      (setf (aref buffer 15) 255 (aref buffer 48) 255)
      (is (= expected (crc32c buffer 16 48)))
      (setf (aref buffer 32) 42)
      (is (/= expected (crc32c buffer 16 48))))))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-FOR-003-crc-compiler-platform-matrix
  (let ((qualified '(:sbcl :arm64 :darwin :64-bit :little-endian)))
    (is (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p qualified "2.6.9"))
    ;; Ogni condizione cambia da sola l'esito, mantenendo vere le altre.
    (dolist (feature qualified)
      (is (not (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p
                (remove feature qualified) "2.6.9"))))
    (dolist (version '("" "2.6.8" "2.6.9.1" "2.6.10" "3.0.0"))
      (is (not (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p qualified version))))
    (is (not (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p
              (cons :arcdocdb-crc32c-software qualified) "2.6.9")))
    (dolist (platform '((:sbcl :x86-64 :linux :64-bit :little-endian)
                        (:sbcl :arm64 :linux :64-bit :little-endian)
                        (:sbcl :x86-64 :darwin :64-bit :little-endian)
                        (:sbcl :x86-64 :win32 :64-bit :little-endian)))
      (is (not (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p platform "2.6.9"))))
    (let ((*features* (cons :arcdocdb-crc32c-arm64
                           (cons :arcdocdb-crc32c-software qualified))))
      (arcdocdb.io.cpu::configura-compilatore-crc32c)
      (is (not (member :arcdocdb-crc32c-arm64 *features*))))))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-FOR-003-crc-os-report-and-selection
  (is (arcdocdb.io.cpu::risposta-crc32c-valida-p 0 4 1))
  (dolist (report '((-1 4 1) (1 4 1) (0 0 1) (0 8 1) (0 4 0) (0 4 2)))
    (is (not (apply #'arcdocdb.io.cpu::risposta-crc32c-valida-p report))))
  (dolist (compiler-p '(nil t))
    (dolist (cpu-p '(nil t))
      (dolist (simd-p '(nil t))
        (is (eq (if (and compiler-p cpu-p simd-p) :arm64-crc32c :lisp)
                (arcdocdb.binary::scegli-backend-crc32c compiler-p cpu-p simd-p)))))))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(deftest test-REQ-FOR-003-crc-startup-fallback
  ;; Nei processi software freschi nessun VOP o kernel ARM deve essere caricato.
  #-arcdocdb-crc32c-arm64
  (progn (is (eq :lisp (arcdocdb.binary:backend-crc32c)))
         (is (not (fboundp 'arcdocdb.binary::crc32c-arm64)))
         (is (not (fboundp 'arcdocdb.binary::emetti-crc-arm64)))))
