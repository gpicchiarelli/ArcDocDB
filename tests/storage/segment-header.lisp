(in-package #:arcdocdb.storage.tests)

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-segment-header-independent-oracle
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (multiple-value-bind (buffer start end serie segment-id created)
          (header-fixture :version version :origin origin)
        (is (equalp (subseq buffer start end) (header-oracle version origin serie segment-id created)))
        (is (every (lambda (x) (= x #xcc)) (subseq buffer 0 start)))
        (is (every (lambda (x) (= x #xcc)) (subseq buffer end)))
        (multiple-value-bind (next actual-version actual-origin created-offset)
            (verifica-header-segmento buffer start (length buffer) serie segment-id)
          (is (= end next)) (is (= version actual-version)) (is (= origin actual-origin))
          (is (= created-offset (+ start 40))))))))

;;; REQ: REQ-FOR-001
(deftest test-REQ-FOR-001-segment-header-all-truncations-and-bit-flips
  (multiple-value-bind (buffer start end serie segment-id) (header-fixture)
    (loop for boundary from start below end
          do (signals corruption-detected
                      (verifica-header-segmento buffer start boundary serie segment-id)))
    (loop for pos from start below end
          do (let ((copy (copy-seq buffer)))
               (setf (aref copy pos) (logxor 1 (aref copy pos)))
               (signals corruption-detected
                        (verifica-header-segmento copy start end serie segment-id))))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-segment-header-crc-valid-invalid-fields
  (multiple-value-bind (buffer start end serie segment-id) (header-fixture)
    (dolist (entry '((0 0 :segment-magic) (4 0 :segment-magic) (10 0 :segment-origin)
                     (10 3 :segment-origin) (11 1 :segment-reserved) (48 1 :segment-reserved)
                     (60 1 :segment-reserved)))
      (destructuring-bind (offset value reason) entry
        (let ((copy (copy-seq buffer)))
          (setf (aref copy (+ start offset)) value)
          (pack-le copy (+ start 56) (reference-crc copy start (+ start 56)) 4)
          (signals corruption-detected (verifica-header-segmento copy start end serie segment-id)
                   reason))))
    (dolist (version '(0 3 65535))
      (let ((copy (copy-seq buffer)))
        (pack-le copy (+ start 8) version 2)
        (pack-le copy (+ start 56) (reference-crc copy start (+ start 56)) 4)
        (signals unsupported-format (verifica-header-segmento copy start end serie segment-id))))))

;;; REQ: REQ-FOR-001 REQ-AFF-002
(deftest test-REQ-AFF-002-segment-header-identity
  (multiple-value-bind (buffer start end serie segment-id) (header-fixture)
    (dotimes (i 16)
      (let ((wrong (copy-seq serie)))
        (setf (aref wrong i) (logxor 1 (aref wrong i)))
        (signals corruption-detected (verifica-header-segmento buffer start end wrong segment-id)
                 :segment-identity)))
    (dolist (wrong '(#xfedcba9876543211 #xfedcba9976543210))
      (signals corruption-detected (verifica-header-segmento buffer start end serie wrong)
               :segment-identity))
    (signals invalid-argument (verifica-header-segmento buffer start end (bytes 1) segment-id))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-segment-header-preflight-preserves-buffer
  (multiple-value-bind (buffer start end serie segment-id created) (header-fixture)
    (declare (ignore end))
    (let ((before (copy-seq buffer)))
      (signals unsupported-format (scrivi-header-segmento buffer start serie segment-id created :version 3))
      (signals invalid-argument (scrivi-header-segmento buffer start serie segment-id created :origine 0))
      (signals invalid-argument (scrivi-header-segmento buffer start (bytes 1) segment-id created))
      (signals invalid-argument (scrivi-header-segmento buffer (length buffer) serie segment-id created))
      (is (equalp buffer before))))
  (let* ((buffer (bytes 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)) (before (copy-seq buffer)))
    (signals invalid-argument (scrivi-header-segmento buffer 0 buffer 1 1) :input-alias)
    (is (equalp buffer before))))
