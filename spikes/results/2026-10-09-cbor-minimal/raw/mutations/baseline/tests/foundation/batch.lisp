(in-package #:arcdocdb.foundation.tests)

(defun batch-fixture (&key (kind 1) (count 2) (stamp 19) (file-id 31)
                          (flags 0) (version 2) (prefix 7) (file-offset 64))
  (let* ((buffer (make-array 4096 :element-type '(unsigned-byte 8) :initial-element #xcc))
         (seal (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
         (key (if (member kind '(1 2)) (bytes 17) (bytes)))
         (value (make-array (case kind (1 1) (2 0) (4 8) (5 24) (6 26))
                            :element-type '(unsigned-byte 8) :initial-element 0))
         (pos prefix) (checksum 0))
    (dotimes (i count)
      (let ((record-start pos))
        (setf pos (scrivi-record buffer pos kind stamp key value
                                :version version :flags flags)
              checksum (reference-crc buffer record-start (+ record-start 4) checksum))))
    (scrivi-u64 seal 0 file-id)
    (scrivi-u64 seal 8 (+ file-offset prefix))
    (scrivi-u64 seal 16 file-offset)
    (scrivi-u32 seal 24 count)
    (scrivi-u32 seal 28 checksum)
    (let ((end (scrivi-record buffer pos 3 stamp (bytes) seal :version version)))
      (values buffer prefix end pos))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-sealed-batches
  (dolist (version '(1 2))
    (dolist (entry '((1 :segment 31) (2 :segment 31) (4 :segment 31)
                     (5 :control 0) (6 :multiserie 0)))
      (destructuring-bind (kind log-kind file-id) entry
        (multiple-value-bind (buffer start end)
            (batch-fixture :version version :kind kind :file-id file-id)
          (multiple-value-bind (next stamp durable count)
              (verifica-lotto buffer start end file-id :version version
                              :log-kind log-kind :file-offset 64)
            (is (= next end)) (is (= stamp 19))
            (is (= durable 64)) (is (= count 2))))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-batch-all-truncations
  (multiple-value-bind (buffer start end) (batch-fixture)
    (loop for pos from start below end
          do (signals corruption-detected
                      (verifica-lotto buffer start pos 31 :file-offset 64)))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-batch-seal-semantic-corruption
  (multiple-value-bind (buffer start end seal-start) (batch-fixture)
    (dolist (relative '(0 8 16 24 28))
      (let ((copy (copy-seq buffer)) (value-start (+ seal-start 24)))
        (setf (aref copy (+ value-start relative))
              (logxor #xff (aref copy (+ value-start relative))))
        (scrivi-u32 copy (+ seal-start 4) (reference-crc copy value-start end))
        (repair-header copy seal-start)
        (signals corruption-detected (verifica-lotto copy start end 31 :file-offset 64)
                 :seal-mismatch)))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-batch-stamp-and-type
  (multiple-value-bind (buffer start end seal-start) (batch-fixture)
    (declare (ignore seal-start))
    (let ((copy (copy-seq buffer)))
      (scrivi-u64 copy (+ start 16) 20)
      (repair-header copy start)
      (signals corruption-detected (verifica-lotto copy start end 31 :file-offset 64)
               :batch-stamp))
    (signals corruption-detected
             (verifica-lotto buffer start end 0 :file-offset 64 :log-kind :control)
             :batch-record-type)))

;;; REQ: REQ-FOR-003 REQ-LIM-003
(deftest test-REQ-LIM-003-batch-budgets
  (multiple-value-bind (buffer start end) (batch-fixture)
    (signals resource-exhausted
             (verifica-lotto buffer start end 31 :file-offset 64 :max-records 1)
             :batch-record-budget)
    (is (= end (verifica-lotto buffer start end 31 :file-offset 64 :max-records 2)))
    (is (= end (verifica-lotto buffer start end 31 :file-offset 64
                             :max-bytes (- end start))))
    (signals resource-exhausted
             (verifica-lotto buffer start end 31 :file-offset 64
                             :max-bytes (1- (- end start))) :batch-byte-budget)
    (signals invalid-argument
             (verifica-lotto buffer start end 31 :max-records 0))
    (signals invalid-argument
             (verifica-lotto buffer start end 31 :max-bytes 0))
    (signals invalid-argument
             (verifica-lotto buffer start end 31 :log-kind :unknown))
    (signals invalid-argument
             (verifica-lotto buffer start end 31 :log-kind :control))
    (signals invalid-argument
             (verifica-lotto buffer start end 31 :file-offset #xffffffffffffffff))))

;;; REQ: REQ-FOR-003 REQ-FOR-004
(deftest test-REQ-FOR-004-batch-txid-independent-of-seal-csn
  (dolist (entry '((1 1 :segment 31) (2 1 :segment 31)
                   (4 0 :segment 31) (6 0 :multiserie 0)))
    (destructuring-bind (kind flags log-kind file-id) entry
      (multiple-value-bind (buffer start end seal-start)
          (batch-fixture :kind kind :flags flags :file-id file-id :stamp 101)
        (scrivi-u64 buffer (+ seal-start 16) 19)
        (repair-header buffer seal-start)
        (multiple-value-bind (next stamp)
            (verifica-lotto buffer start end file-id :file-offset 64 :log-kind log-kind)
          (is (= next end)) (is (= stamp 19)))))))
