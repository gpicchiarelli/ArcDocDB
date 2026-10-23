;;;; GET-D04..08: capacità reali, prefisso committed, prova prepared e cache verificata.
;;; OWNER: fixture distinta per caso; nessun worker concorrente o seme globale mutato.
;;; SHARED: solo il FD readonly e cache appartenenti alla vista della fixture.
(in-package #:arcdocdb.get.tests)

;;; REQ: REQ-FOR-002 REQ-FOR-004 REQ-CMP-007 REQ-AFF-002
(defun get-target-refusal (fixture thunk type reason faulted)
  "Oracle: typed refusal, no record I/O, no epoch pin, terminal fault only when contracted."
  (let ((before (get-read-count fixture)))
    (is (handler-case (progn (funcall thunk) nil)
          (arcdocdb.conditions:arcdocdb-error (condition)
            (is (typep condition type)) (is (eq reason (error-reason condition))) t)))
    (is (= before (get-read-count fixture)))
    (if faulted (get-check-faulted fixture) (get-check-idle fixture))))

;;; REQ: REQ-CCH-004 REQ-AFF-002
(defun get-fi-corrupt-cache-copy (fixture)
  "FI only, serial: flip a cached value byte at a known tag; persistent native bytes stay intact.
Private metadata is used to locate the injection, never as an expected-value oracle."
  (let* ((class (aref (c::cache-serie-classes (get-fixture-cache fixture)) 0))
         (tags (c::classe-cache-tags class))
         (slot (loop for slot below 8 for base = (* slot 4)
                     when (and (= 0 (aref tags base)) (= 17 (aref tags (+ base 1)))
                               (= 64 (aref tags (+ base 2))) (= 30 (aref tags (+ base 3))))
                       return slot)))
    (is slot)
    (let ((at (+ (* slot 1024) 29)))
      (setf (aref (c::classe-cache-arena class) at)
            (logxor 1 (aref (c::classe-cache-arena class) at)))))
  nil)

;;; REQ: REQ-FOR-001 REQ-FOR-004 REQ-CCH-002 REQ-AFF-002
(deftest test-GET-D04-native-readonly-header-and-known-put
  (with-get-fixture (f ())
    (is (eq :input (io:mode-file (get-fixture-file f))))
    (is (eq :open (io:stato-file (get-fixture-file f))))
    (is (= 1 (get-read-count f)))
    (is (eq :candidate (get-start f)))
    (is (equal '(:segment :miss :inserted nil nil) (multiple-value-list (get-load f))))
    (is (equal '(0 64) (get-read-offsets f)))
    (is (eq :verified (stato-contesto-get (get-fixture-context f))))
    (get-copy-found f)))

;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004 REQ-AFF-002
(deftest test-GET-D08-miss-insert-then-hit-without-record-io
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f))) (get-load f) (get-copy-found f)
    (is (eq :candidate (get-start f :now 13)))
    (let ((reads (get-read-count f)))
      (is (eq :hit (sonda-cache-get (get-fixture-context f) (get-fixture-segment f) 94 0)))
      (is (= reads (get-read-count f))))
    (get-copy-found f :now 14)))

;;; REQ: REQ-CCH-002 REQ-AFF-002
(deftest test-GET-D08-cache-disabled-still-loads-known-value
  (with-get-fixture (f (:cache-p nil))
    (is (eq :candidate (get-start f)))
    (let ((reads (get-read-count f)))
      (is (eq :disabled (sonda-cache-get (get-fixture-context f) (get-fixture-segment f) 94 0)))
      (is (= reads (get-read-count f))))
    (is (equal '(:segment :disabled :not-attempted nil nil) (multiple-value-list (get-load f))))
    (get-copy-found f)))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-AFF-002
(deftest test-GET-D05-cache-miss-probe-keeps-candidate-and-does-no-io
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f)))
    (is (eq :miss (sonda-cache-get (get-fixture-context f) (get-fixture-segment f) 94 0)))
    (is (= 1 (get-read-count f)))
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))
    (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
    (abbandona-get (get-fixture-context f)) (get-check-idle f)))

;;; REQ: REQ-FOR-004 REQ-CCH-002 REQ-AFF-002
(deftest test-GET-D05-prepared-probe-requires-proof-without-io
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (is (eq :proof-required (sonda-cache-get (get-fixture-context f) (get-fixture-segment f) 126 1)))
    (is (= 1 (get-read-count f)))
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))))

;;; REQ: REQ-CON-004 REQ-CCH-002 REQ-AFF-002
(deftest test-GET-D05-small-probe-precedes-proof-and-cache
  (with-get-fixture (f (:record-bytes 29 :prepared-p t))
    (is (eq :candidate (get-start f)))
    (is (eq :buffer-required (sonda-cache-get (get-fixture-context f) (get-fixture-segment f) 126 1)))
    (is (= 1 (get-read-count f)))
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))))

;;; REQ: REQ-CON-004 REQ-FOR-004 REQ-AFF-002
(deftest test-GET-D05-small-load-does-no-proof-or-record-io
  (with-get-fixture (f (:record-bytes 29 :prepared-p t))
    (is (eq :candidate (get-start f)))
    (is (equal '(:buffer-required :not-attempted :not-attempted nil nil)
               (multiple-value-list (get-load f :outcome-offset nil))))
    (is (= 1 (get-read-count f)))
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))))

;;; REQ: REQ-FOR-004 REQ-CCH-002 REQ-AFF-002
(deftest test-GET-D07-prepared-real-outcome-before-put
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (is (equal '(:segment :miss :inserted nil nil) (multiple-value-list (get-load f))))
    (is (equal '(0 94 64) (get-read-offsets f)))
    (get-copy-found f)))

;;; REQ: REQ-FOR-004 REQ-CCH-002 REQ-CCH-004 REQ-AFF-002
(deftest test-GET-D08-prepared-cache-hit-still-reads-authoritative-proof
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f))) (get-load f) (get-copy-found f)
    (is (eq :candidate (get-start f :now 13)))
    (is (equal '(:cache :hit :not-attempted nil nil) (multiple-value-list (get-load f))))
    (is (equal '(0 94 64 94) (get-read-offsets f)))
    (get-copy-found f :now 14)))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-GET-D04-header-rejects-other-segment-identity
  (with-get-fixture (f ())
    (signals corruption-detected
             (crea-segmento-get (get-fixture-view f) (get-fixture-file f) 18 (get-zeros 64))
             :segment-identity)
    (get-check-idle f)))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-GET-D04-header-rejects-other-serie-identity
  (with-get-fixture (f ())
    (let* ((identity (get-identity))
           (view (progn (setf (aref identity 15) 99)
                        (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f) nil identity))))
      (signals corruption-detected
               (crea-segmento-get view (get-fixture-file f) 17 (get-zeros 64)) :segment-identity))
    (get-check-idle f)))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-GET-D04-corrupt-real-header-cannot-create-capability
  (signals corruption-detected
           (get-fixture :header-transform (lambda (header) (setf (aref header 40) 4)))
           :segment-header-crc))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-CMP-007
(deftest test-GET-D04-target-owner-refusal-releases-epoch
  (with-get-fixture (f ())
    (let* ((view (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f) nil (get-identity)))
           (segment (crea-segmento-get view (get-fixture-file f) 17 (get-zeros 64))))
      (is (eq :candidate (get-start f)))
      (get-target-refusal f (lambda () (sonda-cache-get (get-fixture-context f) segment 94 0))
                          'invalid-argument :get-source-owner nil))))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-CMP-007
(deftest test-GET-D04-target-segment-id-disagrees-with-index-location
  (with-get-fixture (f ())
    (with-get-fixture (other (:segment-id 18))
      (let ((segment (crea-segmento-get (get-fixture-view f) (get-fixture-file other) 18 (get-zeros 64))))
        (is (eq :candidate (get-start f)))
        (get-target-refusal f (lambda () (sonda-cache-get (get-fixture-context f) segment 94 0))
                            'invariant-violation :get-source-location t)
        (is (= 2 (get-read-count other)))))))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-CMP-007
(deftest test-GET-D04-high-segment-word-is-not-truncated-to-location
  (with-get-fixture (f (:segment-id #x100000011))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f))
                        'invariant-violation :get-source-location t)))

;;; REQ: REQ-FOR-002 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D04-committed-prefix-one-byte-short-for-put
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :valid-bytes 93))
                        'invariant-violation :get-source-location t)))

;;; REQ: REQ-FOR-002 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D04-record-location-before-header-is-refused
  (with-get-fixture (f (:publish-p nil))
    (get-publish f :location #x110000003f)
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f))
                        'invariant-violation :get-source-location t)))

;;; REQ: REQ-FOR-002 REQ-LIM-001 REQ-CMP-007
(deftest test-GET-D04-index-size-with-no-value-is-not-a-get-source
  (with-get-fixture (f (:publish-p nil))
    (get-publish f :size 27)
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f))
                        'invariant-violation :get-source-format t)))

;;; REQ: REQ-FOR-003 REQ-CMP-007
(deftest test-GET-D04-invalid-storage-flags-rejected-before-io
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :flags 2))
                        'invalid-argument :get-record-flags nil)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D04-permitted-flag-must-match-persistent-put
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f :flags 4) :index-mismatch)
    (is (equal '(0 64) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-FOR-002 REQ-FOR-004
(deftest test-GET-D04-v1-header-selects-v1-record-verifier
  (with-get-fixture (f (:version 1))
    (is (eq :candidate (get-start f)))
    (is (eq :segment (get-load f)))
    (get-copy-found f)))

;;; REQ: REQ-FOR-002 REQ-LIM-003 REQ-CMP-007
(deftest test-GET-D04-v1-key-limit-refuses-v2-sized-index-key
  (with-get-fixture
      (f (:key (get-zeros 256 7)
          :header-transform (lambda (header)
                              (fmt:scrivi-header-segmento header 0 (get-identity) 17 3 :version 1))))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f))
                        'invariant-violation :get-source-format t)))

;;; REQ: REQ-FOR-002 REQ-FOR-004 REQ-CMP-007
(deftest test-GET-D04-compacted-origin-cannot-authorize-prepared-put
  (with-get-fixture (f (:prepared-p t :origin 2))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f))
                        'invariant-violation :get-compacted-prepared t)))

;;; REQ: REQ-FOR-004 REQ-CMP-007
(deftest test-GET-D06-prepared-proof-is-mandatory
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :outcome-offset nil))
                        'invalid-argument :get-outcome-required nil)))

;;; REQ: REQ-FOR-004 REQ-CMP-007
(deftest test-GET-D06-plain-put-rejects-unexpected-proof-offset
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :outcome-offset 94))
                        'invalid-argument :get-unexpected-outcome nil)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D06-outcome-must-not-overlap-put
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :outcome-offset 64))
                        'invariant-violation :get-outcome-location t)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D06-outcome-before-header-is-refused
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :outcome-offset 63))
                        'invariant-violation :get-outcome-location t)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D06-outcome-one-byte-beyond-committed-prefix
  (with-get-fixture (f (:prepared-p t))
    (is (eq :candidate (get-start f)))
    (get-target-refusal f (lambda () (get-load f :valid-bytes 125))
                        'invariant-violation :get-outcome-location t)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-outcome-header-and-body-crcs-checked-before-put
  (dolist (case '((16 :header-crc) (24 :body-crc)))
    (let ((offset (first case)))
      (with-get-fixture
          (f (:prepared-p t :proof-transform
              (lambda (proof) (setf (aref proof offset) (logxor 1 (aref proof offset))))))
        (is (eq :candidate (get-start f)))
        (is (handler-case (progn (get-load f) nil)
              (corruption-detected (condition) (eq (second case) (error-reason condition)))))
        (is (equal '(0 94) (get-read-offsets f)))
        (get-check-idle f)))))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-outcome-csn-must-match-committed-index
  (with-get-fixture (f (:prepared-p t :proof-csn 8))
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f) :get-outcome-mismatch)
    (is (equal '(0 94) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-valid-crc-other-record-type-is-not-outcome
  (with-get-fixture
      (f (:prepared-p t :proof-transform
          (lambda (proof)
            (rec:scrivi-record proof 0 1 101 (get-bytes 7) (get-zeros 7)))))
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f) :get-outcome-mismatch)
    (is (equal '(0 94) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-outcome-txid-must-match-prepared-put
  (with-get-fixture (f (:prepared-p t :proof-txid 102))
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f) :outcome-mismatch)
    (is (equal '(0 94 64) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-persistent-put-body-corruption-is-not-a-cache-miss
  (with-get-fixture
      (f (:record-transform (lambda (record) (setf (aref record 29) 3))))
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f) :body-crc)
    (is (equal '(0 64) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D07-plain-put-csn-disagrees-with-index
  (with-get-fixture (f (:put-stamp 8))
    (is (eq :candidate (get-start f)))
    (signals corruption-detected (get-load f) :csn-mismatch)
    (is (equal '(0 64) (get-read-offsets f)))
    (get-check-idle f)))

;;; REQ: REQ-CCH-004 REQ-FOR-004 REQ-AFF-002 REQ-CMP-007
(deftest test-GET-D08-FI-corrupt-cache-copy-falls-back-to-intact-native-put
  (with-get-fixture (f ())
    (is (eq :candidate (get-start f))) (get-load f) (get-copy-found f)
    (get-fi-corrupt-cache-copy f)
    (is (eq :candidate (get-start f :now 13)))
    (multiple-value-bind (source cache insertion evicted scan) (get-load f)
      (declare (ignore insertion evicted scan))
      (is (eq :segment source)) (is (eq :verify-failed cache)))
    (is (equal '(0 64 64) (get-read-offsets f)))
    (get-copy-found f :now 14)))
