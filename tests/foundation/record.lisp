(in-package #:arcdocdb.foundation.tests)

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-word-encoding-independent-oracle
  (dolist (version '(1 2))
    (dolist (stamp '(0 1 #xffffffff #x100000000 #x8000000000000000 #xffffffffffffffff))
      (let* ((key (bytes 1 255)) (value (bytes #xa1 1 2))
             (data (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xcc))
             (expected (reference-put key value stamp 1))
             (end (arcdocdb.record:scrivi-record-parole
                   data 3 1 (ldb (byte 32 32) stamp) (ldb (byte 32 0) stamp)
                   key value :version version :flags 1)))
        (is (= end (+ 3 (length expected))))
        (is (equalp expected (subseq data 3 end)))
        (is (every (lambda (byte) (= byte #xcc)) (subseq data 0 3)))
        (is (every (lambda (byte) (= byte #xcc)) (subseq data end)))))))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-LIM-001-word-encoding-preflight
  (let* ((data (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xcc))
         (before (copy-seq data)) (key (bytes 1)) (value (bytes #xa0)))
    (signals invalid-argument
             (arcdocdb.record:scrivi-record-parole data 63 1 #xffffffff #xffffffff key value)
             :buffer-range)
    (signals invalid-argument
             (arcdocdb.record:scrivi-record-parole data 0 1 0 1 data value) :input-alias)
    (signals unsupported-format
             (arcdocdb.record:scrivi-record-parole data 0 1 0 1 key value :version 3))
    (signals corruption-detected
             (arcdocdb.record:scrivi-record-parole data 0 1 0 1 (bytes) value) :empty-key)
    (is (equalp data before))))

(defun reference-put (key value stamp flags)
  "Cornice PUT indipendente: packing bytewise e CRC bitwise, senza encoder del prodotto."
  (let ((buffer (make-array (+ 24 (length key) (length value))
                            :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref buffer 8) 1 (aref buffer 9) flags)
    (loop for offset in '(10 12 16) for width in '(2 4 8)
          for number in (list (length key) (length value) stamp)
          do (dotimes (i width)
               (setf (aref buffer (+ offset i)) (ldb (byte 8 (* 8 i)) number))))
    (replace buffer key :start1 24)
    (replace buffer value :start1 (+ 24 (length key)))
    (dolist (entry (list (cons 4 (reference-crc buffer 24 (length buffer)))
                        (cons 0 nil)))
      (let ((crc (or (cdr entry) (reference-crc buffer 4 24))))
        (dotimes (i 4)
          (setf (aref buffer (+ (car entry) i)) (ldb (byte 8 (* 8 i)) crc)))))
    buffer))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-independent-encoding-oracle
  (dolist (version '(1 2))
    (dolist (stamp '(0 1 4294967295 4294967296 4611686018427387904 18446744073709551615))
      (dolist (flags '(0 1 4 5))
        (let* ((key (bytes 0 255 128 17)) (value (bytes #xa1 1 2))
               (expected (reference-put key value stamp flags)))
          (multiple-value-bind (actual start end) (fixture :version version :stamp stamp
                                                         :key key :value value :flags flags)
            (is (equalp expected (subseq actual start end)))
            (is (= stamp (nth-value 3 (verifica-record expected 0 (length expected)
                                                      :version version))))))))))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-roundtrip-versions
  (dolist (version '(1 2))
    (multiple-value-bind (buffer start end key value) (fixture :version version)
      (multiple-value-bind (next kind flags stamp ks ke vs ve)
          (verifica-record buffer start (length buffer) :version version)
        (is (= next end)) (is (= kind 1)) (is (zerop flags)) (is (= stamp 19))
        (is (equalp key (subseq buffer ks ke)))
        (is (equalp value (subseq buffer vs ve)))
        (is (every (lambda (v) (= #xcc v)) (subseq buffer 0 start)))
        (is (every (lambda (v) (= #xcc v)) (subseq buffer end)))))))

;;; REQ: REQ-LIM-003
(deftest test-REQ-LIM-003-key-boundaries
  (dolist (length '(1 255 256 65535))
    (let ((key (make-array length :element-type '(unsigned-byte 8) :initial-element 17)))
      (multiple-value-bind (buffer start end) (fixture :key key)
        (is (= end (verifica-record buffer start end)))
        (is (= length (leggi-u16 buffer (+ start 10))))
        (when (> length 255)
          (signals corruption-detected (verifica-record buffer start end :version 1)
                   :v1-reserved)))))
  (let ((buffer (make-array 70000 :element-type '(unsigned-byte 8) :initial-element 42)))
    (dolist (length '(0 65536))
      (let ((key (make-array length :element-type '(unsigned-byte 8) :initial-element 0))
            (before (copy-seq buffer)))
        (if (zerop length)
            (signals corruption-detected (scrivi-record buffer 0 1 1 key (bytes #xa0))
                     :empty-key)
            (signals resource-exhausted (scrivi-record buffer 0 1 1 key (bytes #xa0))
                     :format-limit))
        (is (equalp buffer before))))))

;;; REQ: REQ-LIM-001
(deftest test-REQ-LIM-001-document-boundaries
  (let ((buffer (make-array (+ +max-record-bytes+ 3) :element-type '(unsigned-byte 8)
                            :initial-element 0))
        (key (make-array 65535 :element-type '(unsigned-byte 8) :initial-element 7))
        (value (make-array +max-document-bytes+ :element-type '(unsigned-byte 8)
                          :initial-element #x44)))
    (is (= +max-record-bytes+ (scrivi-record buffer 0 1 19 key value)))
    (is (= +max-record-bytes+ (verifica-record buffer 0 +max-record-bytes+)))
    (signals resource-exhausted (scrivi-record buffer 0 1 19 key value :version 1)
             :format-limit)
    (signals resource-exhausted (verifica-record buffer 0 +max-record-bytes+
                                               :document-limit 4194304)
             :document-budget)
    (signals resource-exhausted
             (scrivi-record buffer 0 1 19 (bytes 1)
                            (make-array (1+ +max-document-bytes+)
                                        :element-type '(unsigned-byte 8)
                                        :initial-element 0)) :document-budget)))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(deftest test-REQ-FOR-003-every-byte-corruption
  (multiple-value-bind (buffer start end) (fixture :value (bytes 1 2 3 4 5 6 7 8 9))
    (loop for pos from start below end
          do (let ((copy (copy-seq buffer)))
               (setf (aref copy pos) (logxor 1 (aref copy pos)))
               (signals corruption-detected (verifica-record copy start end))))))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-every-truncation
  (multiple-value-bind (buffer start end) (fixture)
    (loop for boundary from start below end
          do (signals corruption-detected (verifica-record buffer start boundary)))))

;;; REQ: REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-valid-crc-invalid-fields
  (multiple-value-bind (buffer start end) (fixture)
    (dolist (type '(0 7 255))
      (let ((copy (copy-seq buffer)))
        (setf (aref copy (+ start 8)) type)
        (repair-header copy start)
        (signals corruption-detected (verifica-record copy start end) :record-type)))
    (dolist (flag '(2 8 16 128 255))
      (let ((copy (copy-seq buffer)))
        (setf (aref copy (+ start 9)) flag)
        (repair-header copy start)
        (signals corruption-detected (verifica-record copy start end) :record-flags)))
    (let ((copy (copy-seq buffer)))
      (scrivi-u32 copy (+ start 12) #xffffffff)
      (repair-header copy start)
      (signals corruption-detected (verifica-record copy start end) :record-length))))

;;; REQ: REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-preflight-no-partial-write
  (multiple-value-bind (buffer start end key value) (fixture)
    (declare (ignore end))
    (let ((before (copy-seq buffer)))
      (signals unsupported-format (scrivi-record buffer start 1 1 key value :version 3))
      (signals invalid-argument (scrivi-record buffer start 1 1 buffer value) :input-alias)
      (signals invalid-argument (scrivi-record buffer start 1 1 key buffer) :input-alias)
      (signals invalid-argument (scrivi-record buffer start 1 1 key value :document-limit 0))
      (signals invalid-argument (scrivi-record buffer (length buffer) 1 1 key value))
      (is (equalp buffer before)))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-index-identity
  (multiple-value-bind (buffer start end key) (fixture)
    (multiple-value-bind (vs ve) (verifica-put buffer start end key 19 0)
      (is (= 1 (- ve vs))))
    (signals corruption-detected (verifica-put buffer start end (bytes 7 9) 19 0))
    (signals corruption-detected (verifica-put buffer start end (bytes 7) 19 0))
    (signals corruption-detected (verifica-put buffer start end key 20 0) :csn-mismatch)
    (signals corruption-detected (verifica-put buffer start end key 19 1) :index-mismatch)
    (signals corruption-detected (verifica-put buffer start (1+ end) key 19 0)
             :index-mismatch)))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-prepared-outcome
  (let ((proof-value (make-array 8 :element-type '(unsigned-byte 8) :initial-element 0)))
    (scrivi-u64 proof-value 0 19)
    (multiple-value-bind (proof ps pe)
        (fixture :kind 4 :stamp 101 :key (bytes) :value proof-value)
      (multiple-value-bind (buffer start end key)
          (fixture :stamp 101 :flags 1)
        (signals corruption-detected (verifica-put buffer start end key 19 1)
                 :outcome-required)
        (is (= (+ start 26)
               (verifica-put buffer start end key 19 1
                             :proof-buffer proof :proof-start ps :proof-end pe)))
        (signals corruption-detected
                 (verifica-put buffer start end key 20 1
                               :proof-buffer proof :proof-start ps :proof-end pe)
                 :outcome-mismatch)
        (let ((wrong (copy-seq proof)))
          (scrivi-u64 wrong (+ ps 16) 102)
          (repair-header wrong ps)
          (signals corruption-detected
                   (verifica-put buffer start end key 19 1
                                 :proof-buffer wrong :proof-start ps :proof-end pe)
                   :outcome-mismatch))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-control-record-shapes
  (dolist (kind '(2 3 4 5 6))
    (let ((key (if (= kind 2) (bytes 17) (bytes)))
          (value (make-array (case kind (2 0) (3 32) (4 8) (5 24) (6 26))
                             :element-type '(unsigned-byte 8) :initial-element 0)))
      (multiple-value-bind (buffer start end) (fixture :kind kind :key key :value value)
        (is (= end (verifica-record buffer start end))))))
  (dolist (kind '(3 4 5 6))
    (signals corruption-detected
             (fixture :kind kind :key (bytes) :value (bytes 1)))))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003
(deftest test-REQ-LIM-001-semantic-boundaries
  (signals corruption-detected (fixture :value (bytes)) :document-length)
  (signals corruption-detected (fixture :kind 2 :key (bytes) :value (bytes)) :empty-key)
  (signals corruption-detected (fixture :kind 2) :tombstone-body)
  (signals corruption-detected (fixture :kind 4 :value (bytes 1 2 3 4 5 6 7 8)) :control-key)
  (dolist (entry '((3 31) (3 33) (4 7) (4 9) (5 23) (6 25)))
    (signals corruption-detected
             (fixture :kind (first entry) :key (bytes)
                      :value (make-array (second entry) :element-type '(unsigned-byte 8)
                                         :initial-element 0))))
  (multiple-value-bind (buffer start end key) (fixture)
    (signals unsupported-format (verifica-record buffer start end :version 0))
    (dolist (budget (list 0 (1+ +max-document-bytes+)))
      (signals invalid-argument (verifica-record buffer start end :document-limit budget))
      (signals invalid-argument (scrivi-record buffer start 1 19 key (bytes #xa0)
                                               :document-limit budget)))
    (let ((wrong (copy-seq buffer)))
      (setf (aref wrong (+ start 8)) 2)
      (scrivi-u32 wrong (+ start 12) 0)
      (scrivi-u32 wrong (+ start 4) (reference-crc wrong (+ start 24) (+ start 26)))
      (repair-header wrong start)
      (signals corruption-detected (verifica-put wrong start (+ start 26) key 19 0)
               :index-mismatch))))

;;; REQ: REQ-FOR-004
(deftest test-REQ-FOR-004-outcome-provenance-fields
  (let ((value (bytes 19 0 0 0 0 0 0 0)))
    (multiple-value-bind (proof ps pe) (fixture :kind 4 :stamp 101 :key (bytes) :value value)
      (multiple-value-bind (buffer start end key) (fixture :stamp 101 :flags 1)
        (signals corruption-detected
                 (verifica-put buffer start end key 19 1 :proof-buffer proof
                               :proof-start ps :proof-end (1+ pe)) :outcome-mismatch)
        (multiple-value-bind (wrong ws we) (fixture)
          (signals corruption-detected
                   (verifica-put buffer start end key 19 1 :proof-buffer wrong
                                 :proof-start ws :proof-end we) :outcome-mismatch))
        (let ((wrong (copy-seq proof)))
          (setf (aref wrong (+ ps 24)) 20)
          (signals corruption-detected
                   (verifica-put buffer start end key 19 1 :proof-buffer wrong
                                 :proof-start ps :proof-end pe) :body-crc))))))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-u64-both-words
  (multiple-value-bind (buffer start end key) (fixture :stamp #xffffffffffffffff)
    (is (plusp (verifica-put buffer start end key #xffffffffffffffff 0)))
    (signals corruption-detected
             (verifica-put buffer start end key #xfffffffffffffffe 0) :csn-mismatch)
    (signals corruption-detected
             (verifica-put buffer start end key #xfffffffeffffffff 0) :csn-mismatch))
  (let ((value (bytes #xff #xff #xff #xff #xff #xff #xff #xff)))
    (multiple-value-bind (proof ps pe)
        (fixture :kind 4 :stamp #xfedcba9876543210 :key (bytes) :value value)
      (multiple-value-bind (buffer start end key)
          (fixture :stamp #xfedcba9876543210 :flags 1)
        (is (plusp (verifica-put buffer start end key #xffffffffffffffff 1
                                :proof-buffer proof :proof-start ps :proof-end pe)))
        (dolist (offset '(16 20 24 28))
          (let ((wrong (copy-seq proof)))
            (setf (aref wrong (+ ps offset)) (logxor 1 (aref wrong (+ ps offset))))
            (scrivi-u32 wrong (+ ps 4) (reference-crc wrong (+ ps 24) pe))
            (repair-header wrong ps)
            (signals corruption-detected
                     (verifica-put buffer start end key #xffffffffffffffff 1
                                   :proof-buffer wrong :proof-start ps :proof-end pe)
                     :outcome-mismatch)))))))
