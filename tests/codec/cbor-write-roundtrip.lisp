;;;; Compatibilita supplementare; gli oracoli byte ciechi restano invariati.
(in-package #:arcdocdb.cbor.write.tests)

;;; REQ: REQ-CBR-001 REQ-AFF-008
(deftest test-REQ-CBR-001-cbor-write-minimal-reader-roundtrip-supplement
  (dotimes (major 7)
    (dolist (pair '((0 0) (0 23) (0 24) (0 255) (0 256) (0 65535)
                    (0 65536) (0 #xffffffff) (1 0) (#xffffffff #xffffffff)
                    (#x01234567 #x89abcdef)))
      (destructuring-bind (high low) pair
        (multiple-value-bind (buffer start end) (cw-fixture 12)
          (let ((next (cw-compare buffer start end major high low)))
            (multiple-value-bind (mt ai hi lo final form)
                (arcdocdb.cbor:leggi-header-cbor-minimo buffer start next)
              (is (= major mt)) (is (= high hi)) (is (= low lo))
              (is (= next final)) (is (eq form :argument))
              (is (< ai 28)))))))))
