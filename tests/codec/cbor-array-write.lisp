(in-package #:arcdocdb.cbor.array.write.tests)

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002
(deftest test-REQ-CBR-005-array-empty-scalar-and-five-literal-children
  (is (equal '(#x80) (caw-header 4 0))) (is (equal '(#x81) (caw-header 4 1)))
  (caw-probe nil) (caw-probe '((0)))
  (multiple-value-bind (source ss se table count)
      (caw-fixture '((0) (#x38 #x18) (#x61 #x41) (#xf5) (#xf9 #x3e 0)))
    (is (= 5 count)) (is (equalp (subseq table 0 count) #(1 3 5 6 9)))
    (is (equalp (subseq source ss se) (bytes 0 #x38 #x18 #x61 #x41 #xf5 #xf9 #x3e 0)))
    (multiple-value-bind (buffer start end) (caw-destination 10)
      (let ((next (caw-accept buffer start end source ss se table count (caw-dirty-space))))
        (is (equal '(6 1) (subseq (multiple-value-list
                                 (arcdocdb.cbor:verifica-struttura-cbor-minima
                                  buffer start next (arcdocdb.cbor:crea-spazio-cbor))) 0 2)))))))

(deftest test-REQ-CBR-005-array-count-width-boundaries-and-minimal-header
  (dolist (entry '((23 (#x97)) (24 (#x98 #x18)) (255 (#x98 #xff))
                   (256 (#x99 1 0)) (65535 (#x99 #xff #xff)) (65536 (#x9a 0 1 0 0))))
    (is (equal (second entry) (caw-header 4 (first entry))))
    (caw-probe (make-list (first entry) :initial-element '(0)))))

(deftest test-REQ-CBR-005-array-nested-tag-map-text-and-raw-float-preference
  (dolist (children '(((#xc0 0) (#xa1 0 #x61 #x41) (#x81 0))
                       ((#x63 #xe2 #x82 #xac) (#x64 #xf0 #x90 #x80 #x80))
                       ((#xf9 #x80 0) (#xf9 #x7c 1) (#xf9 #x7e 1))
                       ((#xfa 0 0 0 1) (#xfb #xff #xf8 0 0 0 0 0 1))
                       ((#xa2 2 0 1 0) (#xa2 1 0 1 1))
                       ((#x43 #x18 0 #xff) (#xc0 #x81 #xa0))))
    (caw-probe children)))

(deftest test-REQ-CBR-005-array-concatenation-next-and-reused-space
  (multiple-value-bind (buffer start end) (caw-destination 32)
    (let ((space (caw-dirty-space)) (cursor start))
      (dolist (children '(nil ((0)) ((0) (#x38 #x18) (#x61 #x41) (#xf5) (#xf9 #x3e 0))))
        (multiple-value-bind (source ss se table count) (caw-fixture children)
          (setf cursor (caw-accept buffer cursor end source ss se table count space))))
      (is (= (+ start 13) cursor))
      (is (equalp (subseq buffer start cursor)
                  (bytes #x80 #x81 0 #x85 0 #x38 #x18 #x61 #x41 #xf5 #xf9 #x3e 0))))))

(deftest test-REQ-CBR-005-array-destination-type-and-range-precedes-everything
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing))
         (displaced (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing
                                 :displaced-index-offset 4)))
    (dolist (buffer (list nil '(0) "abc" (make-array 4) displaced
                         (make-array '(2 2) :element-type '(unsigned-byte 8))
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)))
      (caw-reject buffer 0 0 nil nil nil nil nil nil 'invalid-argument :cbor-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(1.0 2)
                      (list 0 (1+ most-positive-fixnum))))
    (caw-reject (bytes 0 0) (first range) (second range) nil nil nil nil nil nil
                'invalid-argument :cbor-range nil)))

(deftest test-REQ-CBR-005-array-source-type-range-and-backing-array-intact
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing)))
    (dolist (source (list nil '(0) "a" (make-array 1)
                         (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing)
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)
                         (make-array '(2 2) :element-type '(unsigned-byte 8))))
      (caw-cold-reject (bytes 0) 0 1 source 0 0 nil nil (caw-dirty-space)
                       'invalid-argument :cbor-array-source-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(0 1.0)
                      (list 0 (1+ most-positive-fixnum))))
    (caw-cold-reject (bytes 0) 0 1 (bytes 0 0) (first range) (second range) nil nil
                     (caw-dirty-space) 'invalid-argument :cbor-array-source-range nil)))

(deftest test-REQ-CBR-005-array-table-type-and-count-domains
  (dolist (table (list nil '(1) #(1) (bytes 1)
                       (make-array '(1 1) :element-type '(unsigned-byte 32))
                       (make-array 2 :element-type '(unsigned-byte 32) :fill-pointer 1)))
    (caw-cold-reject (bytes 0 0) 0 2 (bytes 0) 0 1 table nil (caw-dirty-space)
                     'invalid-argument :cbor-array-item-ends nil))
  (let ((table (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)))
    (dolist (count (list nil -1 1.0 'bad 2 (1+ most-positive-fixnum)))
      (caw-cold-reject (bytes 0 0) 0 2 (bytes 0) 0 1 table count (caw-dirty-space)
                       'invalid-argument :cbor-array-count nil))
    (caw-cold-reject (bytes 0 0) 0 2 (bytes 0) 0 1 table 0 (caw-dirty-space)
                     'invalid-argument :cbor-array-count nil)
    (caw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table 2 (caw-dirty-space)
                     'invalid-argument :cbor-array-count nil)
    (caw-cold-reject (bytes 0) 0 1 (bytes) 0 0 table 1 (caw-dirty-space)
                     'invalid-argument :cbor-array-count nil)))

(deftest test-REQ-CBR-005-array-workspace-type-and-all-scratch-aliases-even-empty
  (multiple-value-bind (source ss se table count) (caw-fixture nil)
    (dolist (space '(nil bad 0))
      (caw-reject (bytes 0) 0 1 source ss se table count space
                  'invalid-argument :cbor-workspace nil :max-bytes nil))
    (dotimes (role 3)
      (let* ((space (caw-dirty-space))
             (kinds (arcdocdb.cbor::spazio-cbor-kinds space))
             (remaining (arcdocdb.cbor::spazio-cbor-remaining space)))
        (caw-cold-reject (if (= role 0) kinds (bytes 0)) 0 1
                         (if (= role 1) kinds source) (if (= role 1) 0 ss) (if (= role 1) 0 se)
                         (if (= role 2) remaining table) 0 space
                         'invalid-argument :cbor-array-workspace-alias nil :max-bytes nil)))))

(deftest test-REQ-CBR-005-array-configured-limits-and-empty-root-minimum
  (multiple-value-bind (source ss se table count) (caw-fixture nil)
    (dolist (entry '((:max-bytes :cbor-byte-limit nil -1 16777217 1.0 bad)
                     (:max-nodes :cbor-node-limit nil 0 -1 16777217 1.0 bad)
                     (:max-depth :cbor-depth-limit nil -1 101 1.0 bad)))
      (dolist (value (cddr entry))
        (caw-cold-reject (bytes 0) 0 1 source ss se table count (caw-dirty-space)
                         'invalid-argument (second entry) nil (first entry) value)))
    (caw-accept (bytes 0) 0 1 source ss se table 0 (caw-dirty-space)
                :max-bytes 1 :max-nodes 1 :max-depth 1)
    (caw-cold-reject (bytes 0) 0 1 source ss se table 0 (caw-dirty-space)
                     'resource-exhausted :cbor-array-byte-budget nil :max-bytes 0)
    (caw-cold-reject (bytes 0) 0 1 source ss se table 0 (caw-dirty-space)
                     'resource-exhausted :cbor-array-depth-budget nil :max-depth 0)))

(deftest test-REQ-CBR-005-array-strict-entry-order-bounds-last-and-unread-tail
  (dolist (entries '((0 2) (2 1) (1 1) (1 3) (#xffffffff 2)))
    (let ((table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents entries)))
      (caw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table 2 (caw-dirty-space)
                       'invalid-argument :cbor-array-item-ends nil)))
  (let ((table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (caw-cold-reject (bytes 0 0 0 0) 0 4 (bytes 0 1 2) 0 3 table 2 (caw-dirty-space)
                     'invalid-argument :cbor-array-item-ends nil))
  (caw-probe '((0) (1)))
  (let ((table (make-array 0 :element-type '(unsigned-byte 32))))
    (caw-accept (bytes 0) 0 1 (bytes) 0 0 table 0 (caw-dirty-space))))

(deftest test-REQ-CBR-005-array-all-preflight-phase-precedences
  (let* ((space (caw-dirty-space))
         (bad-table (make-array 2 :element-type '(unsigned-byte 32) :initial-element 0))
         (good-table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (caw-reject (bytes 0) -1 1 nil 0 0 nil nil nil 'invalid-argument :cbor-range nil)
    (caw-cold-reject (bytes 0) 0 0 nil 0 0 nil nil space
                     'invalid-argument :cbor-array-source-range nil)
    (caw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 nil nil space
                     'invalid-argument :cbor-array-item-ends nil)
    (caw-reject (bytes 0) 0 0 (bytes 0) 0 1 good-table 0 nil
                'invalid-argument :cbor-array-count nil :max-bytes nil)
    (caw-reject (bytes 0) 0 0 (bytes 0) 0 1 good-table 1 nil
                'invalid-argument :cbor-workspace nil :max-bytes nil)
    (caw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 2 space
                     'invalid-argument :cbor-byte-limit nil :max-bytes nil :max-nodes nil :max-depth nil)
    (caw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 2 space
                     'invalid-argument :cbor-node-limit nil :max-nodes nil :max-depth nil)
    (caw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 2 space
                     'invalid-argument :cbor-depth-limit nil :max-depth nil)
    (dolist (limit '(0 2))
      (caw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 2 space
                       'resource-exhausted :cbor-array-byte-budget nil :max-bytes limit))
    (caw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 2 space
                     'resource-exhausted :cbor-array-capacity nil :max-nodes 1 :max-depth 0)
    (caw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 bad-table 2 space
                     'invalid-argument :cbor-array-item-ends nil :max-nodes 1 :max-depth 0)
    (caw-cold-reject (bytes 0 0 0) 0 3 (bytes #x18 0) 0 2 good-table 2 space
                     'resource-exhausted :cbor-array-node-budget nil :max-nodes 2 :max-depth 0)
    (let ((one (make-array 1 :element-type '(unsigned-byte 32) :initial-element 2)))
      (caw-cold-reject (bytes 0 0 0) 0 3 (bytes #x18 0) 0 2 one 1 space
                       'resource-exhausted :cbor-array-depth-budget nil :max-nodes 2 :max-depth 0))))

(deftest test-REQ-CBR-005-array-overlap-entire-footprint-touching-and-empty
  (dolist (start '(13 18 4))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5))
          (table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
      (replace buffer '(0 1) :start1 16)
      (caw-accept buffer start (if (= start 4) 50 (+ start 3)) buffer 16 18 table 2 (caw-dirty-space))))
  (dolist (start '(14 15 16 17))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5))
          (table (make-array 2 :element-type '(unsigned-byte 32) :initial-element 0)))
      (replace buffer '(0 1) :start1 16)
      (caw-cold-reject buffer start (+ start 3) buffer 16 18 table 2 (caw-dirty-space)
                       'invalid-argument :cbor-array-overlap nil :max-nodes 1 :max-depth 0)))
  (let ((buffer (bytes 0 0)) (table (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)))
    (caw-cold-reject buffer 0 2 buffer 0 1 table 1 (caw-dirty-space)
                     'invalid-argument :cbor-array-overlap nil)
    (caw-accept buffer 0 1 buffer 0 0 table 0 (caw-dirty-space))))

(deftest test-REQ-CBR-005-array-full-byte-budget-exact-16MiB-and-one-over
  (dolist (extra '(0 1 2))
    (let* ((payload (+ 16777210 extra)) (header (caw-header 2 payload))
           (span (+ (length header) payload)) (ss 2) (se (+ ss span))
           (source (make-array (+ se 3) :element-type '(unsigned-byte 8) :initial-element #xa5))
           (table (make-array 1 :element-type '(unsigned-byte 32) :initial-element span)))
      (replace source header :start1 ss)
      (multiple-value-bind (buffer start end) (caw-destination (1+ span) :prefix 1)
        (if (zerop extra)
            (is (= (+ start 16777216)
                   (caw-accept buffer start end source ss se table 1 (caw-dirty-space)
                               :max-bytes 16777216)))
            (caw-cold-reject buffer start start source ss se table 1 (caw-dirty-space)
                             'resource-exhausted :cbor-array-byte-budget nil :max-bytes 16777216))))))

(deftest test-REQ-CBR-005-array-root-tag-node-accounting-and-exhausted-residue
  (multiple-value-bind (source ss se table count) (caw-fixture '((#x81 0) (0)))
    (caw-reject (bytes 0 0 0 0) 0 4 source ss se table count (caw-dirty-space)
                'resource-exhausted :cbor-array-node-budget (+ ss 2) :max-nodes 3)
    (caw-accept (bytes 0 0 0 0) 0 4 source ss se table count (caw-dirty-space) :max-nodes 4))
  (dolist (child '((#x81 0) (#xc0 0)))
    (multiple-value-bind (source ss se table count) (caw-fixture (list child))
      (caw-reject (bytes 0 0 0) 0 3 source ss se table count (caw-dirty-space)
                  'resource-exhausted :cbor-node-budget (+ ss 1) :max-nodes 2)
      (caw-accept (bytes 0 0 0) 0 3 source ss se table count (caw-dirty-space) :max-nodes 3))))

(deftest test-REQ-CBR-005-array-root-depth-scalars-tags-and-99-100-child-containers
  (caw-probe '((0) (#xc0 #xc1 0)) :max-depth 1)
  (multiple-value-bind (source ss se table count) (caw-fixture '((#x80)))
    (caw-reject (bytes 0 0) 0 2 source ss se table count (caw-dirty-space)
                'resource-exhausted :cbor-depth-budget ss :max-depth 1))
  (dolist (depth '(99 100))
    (multiple-value-bind (source ss se table count)
        (caw-fixture (list (append (make-list depth :initial-element #x81) '(0))))
      (multiple-value-bind (buffer start end) (caw-destination (+ depth 2))
        (if (= depth 99)
            (caw-accept buffer start end source ss se table count (caw-dirty-space)
                        :max-depth 100 :max-nodes 101)
            (caw-reject buffer start end source ss se table count (caw-dirty-space)
                        'resource-exhausted :cbor-depth-budget (+ ss 99) :max-depth 100))))))

(deftest test-REQ-CBR-005-array-child-errors-absolute-offsets-and-left-to-right
  (dolist (entry '(((0 0) :cbor-trailing 1) ((#x18 0) :cbor-nonminimal 0)
                   ((#x18) :cbor-truncated 1) ((#x61 #xff) :utf8-leading 1)
                   ((#x62 #xc2 0) :utf8-continuation 2) ((#x61 #xc2) :utf8-truncated 2)
                   ((#x1c) :cbor-reserved 0) ((#x9f #xff) :cbor-nonminimal 0)))
    (multiple-value-bind (source ss se table count) (caw-fixture (list (first entry)))
      (multiple-value-bind (buffer start end) (caw-destination (1+ (- se ss)))
        (caw-reject buffer start end source ss se table count (caw-dirty-space)
                    'corruption-detected (second entry) (+ ss (third entry))))))
  (multiple-value-bind (source ss se table count) (caw-fixture '((0) (#x18 0) (#x1c)))
    (caw-reject (bytes 0 0 0 0 0) 0 5 source ss se table count (caw-dirty-space)
                'corruption-detected :cbor-nonminimal (+ ss 1))))

(deftest test-REQ-CBR-005-array-reuse-after-parser-and-preflight-errors
  (let ((space (caw-dirty-space)))
    (multiple-value-bind (source ss se table count) (caw-fixture '((#x61 #xff)))
      (caw-reject (bytes 0 0 0) 0 3 source ss se table count space
                  'corruption-detected :utf8-leading (+ ss 1)))
    (multiple-value-bind (source ss se table count) (caw-fixture '((#x81 0) (#xc0 #xf6)))
      (caw-cold-reject (bytes 0) 0 1 source ss se table count space
                       'resource-exhausted :cbor-array-capacity nil)
      (caw-accept (bytes 0 0 0 0 0) 0 5 source ss se table count space))))

(deftest test-REQ-CBR-005-array-scratch-last-child-and-zero-count-no-reset
  (let ((space (caw-dirty-space)))
    (multiple-value-bind (source ss se table count) (caw-fixture '((#x81 0) (#xc0 0) (#xa1 0 1)))
      (caw-accept (bytes 0 0 0 0 0 0 0 0) 0 8 source ss se table count space)
      (is (= 3 (arcdocdb.cbor::spazio-cbor-nodes space)))
      (is (= 1 (arcdocdb.cbor::spazio-cbor-peak-depth space)))))
  (multiple-value-bind (source ss se table count) (caw-fixture nil)
    (caw-accept (bytes 0) 0 1 source ss se table count (caw-dirty-space))))

(deftest test-REQ-CBR-005-array-fixed-seed-1024-fuzz-and-frozen-class-counts
  (let ((state #x41525235) (counts (make-array 9 :initial-element 0))
        (catalogue '((0) (#x38 #x18) (#x61 #x41) (#xf9 #x7e 1)
                     (#xc0 #xf6) (#x80) (#xa1 0 1) (#x63 #xe2 #x82 #xac))))
    (dotimes (iteration 1024)
      (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
      (let ((category (mod iteration 16)))
        (if (< category 8)
            (multiple-value-bind (source ss se table count)
                (caw-fixture (loop for i below (1+ (mod (ash state -8) 8))
                                   collect (nth (mod (+ state i) 8) catalogue)) :prefix (mod state 8))
              (multiple-value-bind (buffer start end)
                  (caw-destination (+ (length (caw-header 4 count)) (- se ss)) :prefix (mod state 32))
                (caw-accept buffer start end source ss se table count (caw-dirty-space))
                (incf (aref counts 0))))
            (multiple-value-bind (source ss se table count) (caw-fixture '((0) (1)) :prefix (mod state 8))
              (multiple-value-bind (buffer start end) (caw-destination 3 :prefix (mod state 32))
                (let ((space (caw-dirty-space)))
                  (case category
                    (8 (caw-cold-reject buffer start (1- end) source ss se table count space
                                        'resource-exhausted :cbor-array-capacity nil))
                    (9 (caw-cold-reject buffer start end source ss se table count space
                                        'resource-exhausted :cbor-array-byte-budget nil :max-bytes 2))
                    (10 (setf (aref table 1) 1)
                        (caw-cold-reject buffer start end source ss se table count space
                                         'invalid-argument :cbor-array-item-ends nil))
                    (11 (caw-cold-reject buffer start end source ss se table count space
                                         'resource-exhausted :cbor-array-node-budget nil :max-nodes 2))
                    (12 (caw-cold-reject buffer start end source ss se table count space
                                         'resource-exhausted :cbor-array-depth-budget nil :max-depth 0))
                    (13 (setf (aref source (1+ ss)) #x18)
                        (caw-reject buffer start end source ss se table count space
                                    'corruption-detected :cbor-truncated se))
                    (14 (caw-cold-reject buffer start end source -1 se table count space
                                         'invalid-argument :cbor-array-source-range nil))
                    (15 (caw-cold-reject buffer start end source ss se table 3 space
                                         'invalid-argument :cbor-array-count nil)))
                  (incf (aref counts (- category 7)))))))))
    (is (equalp counts #(512 64 64 64 64 64 64 64 64)))
    (format t "  CBOR array fuzz: seed41525235, 1024 casi, 512 successi e 64 ciascuno capacita/byte/entry/nodi/profondita/parse/source-range/count.~%")))
