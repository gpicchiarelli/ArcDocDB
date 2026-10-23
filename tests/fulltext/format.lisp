(in-package #:arcdocdb.fulltext.format.tests)

(deftest REQ-SEC-008-wire-independent
  (is (= #xe3069283 (ref-crc (octets '(49 50 51 52 53 54 55 56 57)) 0 9)))
  (dotimes (prefix 16)
    (dolist (segment-id '(0 1 4294967295 4294967296 18446744073709551615))
      (multiple-value-bind (reference start end identity section-lengths starts)
          (fixture :prefix prefix :segment-id segment-id)
        (declare (ignore starts))
        (read-ok reference start end identity segment-id)
        (let ((actual (copy-seq reference)))
          (fill actual #xff :start start :end (+ start 208))
          (setf (aref actual (+ start 209)) 77)
          (is (= end (scrivi-cornice-indice-full-text actual start end identity segment-id
                                                     section-lengths)))
          (is (equalp reference actual))
          (is (equalp identity (id-serie)))
          (is (equalp section-lengths (lengths 1 64 9 48 16 32))))))))

(deftest REQ-SEC-008-every-single-bit
  (multiple-value-bind (buffer start end identity) (fixture)
    (let ((cases 0))
      (loop for offset from start below end do
        (dotimes (bit 8)
          (let ((changed (copy-seq buffer)))
            (setf (aref changed offset) (logxor (aref changed offset) (ash 1 bit)))
            (rejection (lambda () (verifica-cornice-indice-full-text
                                    changed start end identity #xffffffffffffffff))
                       'corruption-detected nil)
            (incf cases))))
      (is (= cases (* 8 (- end start))))
      (format t "  Cornice full text: ~D alterazioni singole rilevate.~%" cases))))

(deftest REQ-SEC-008-every-truncation
  (multiple-value-bind (buffer start end identity) (fixture)
    (loop for limit from start below end do
      (rejection (lambda () (verifica-cornice-indice-full-text
                              buffer start limit identity #xffffffffffffffff))
                 'corruption-detected nil))))

(deftest REQ-SEC-008-empty-sections
  (multiple-value-bind (buffer start end identity section-lengths starts)
      (fixture :prefix 0 :section-lengths (lengths 1 0 0 0 0 0))
    (declare (ignore section-lengths starts))
    (is (= end 220))
    (read-ok buffer start end identity #xffffffffffffffff)))

(deftest REQ-SEC-008-no-semantic-promotion
  (multiple-value-bind (buffer start end identity) (fixture)
    (setf (aref buffer (+ start 208)) #xff)
    (repair buffer start end)
    (read-ok buffer start end identity #xffffffffffffffff)))

(deftest REQ-SEC-008-meta-budget-edge
  (multiple-value-bind (buffer start end identity section-lengths starts)
      (fixture :section-lengths (lengths 65536 0 0 0 0 0))
    (declare (ignore starts))
    (is (= end (scrivi-cornice-indice-full-text buffer start end identity 1 section-lengths)))
    (let ((values (multiple-value-list
                   (verifica-cornice-indice-full-text buffer start end identity 1))))
      (is (= 3 (length values))) (is (= 65536 (- (third values) (second values)))))))
