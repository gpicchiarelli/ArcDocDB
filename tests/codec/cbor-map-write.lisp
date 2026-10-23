(in-package #:arcdocdb.cbor.map.write.tests)

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002
(deftest test-REQ-CBR-006-map-empty-scalar-pair-and-two-literal-pairs
  (is (equal '(#xa0) (cmw-header 5 0))) (is (equal '(#xa1) (cmw-header 5 1)))
  (cmw-probe nil) (cmw-probe '((0) (1)))
  (multiple-value-bind (source ss se table count)
      (cmw-fixture '((#x61 #x61) (1) (#x61 #x62) (#x82 #xf4 #xf5)))
    (is (= 2 count)) (is (equalp (subseq table 0 (* 2 count)) #(2 3 5 8)))
    (is (equalp (subseq source ss se) (bytes #x61 #x61 1 #x61 #x62 #x82 #xf4 #xf5)))
    (multiple-value-bind (buffer start end) (cmw-destination 9)
      (let ((next (cmw-accept buffer start end source ss se table count (cmw-dirty-space))))
        (is (equal '(7 2) (subseq (multiple-value-list
                                 (arcdocdb.cbor:verifica-struttura-cbor-minima
                                  buffer start next (arcdocdb.cbor:crea-spazio-cbor))) 0 2)))))))

(deftest test-REQ-CBR-006-map-pair-count-width-boundaries-and-minimal-header
  (dolist (entry '((23 (#xb7)) (24 (#xb8 #x18)) (255 (#xb8 #xff)) (256 (#xb9 1 0))))
    (is (equal (second entry) (cmw-header 5 (first entry))))
    (cmw-probe (make-list (* 2 (first entry)) :initial-element '(0)))))

(deftest test-REQ-CBR-006-map-nested-utf8-floats-opaque-bytes-and-preserved-pair-order
  (dolist (children '(((#xc0 0) (#xa1 0 #x61 #x41) (#x81 0) (1))
                       ((#x63 #xe2 #x82 #xac) (#x64 #xf0 #x90 #x80 #x80))
                       ((#xf9 #x80 0) (#xf9 #x7c 1) (#xf9 #x7e 1) (#xfb #xff #xf8 0 0 0 0 0 1))
                       ((#xfa 0 0 0 1) (#xf5))
                       ((2) (0) (1) (0))
                       ((1) (0) (1) (1))
                       ((#xa2 2 0 1 0) (#xa2 1 0 1 1))
                       ((#x43 #x18 0 #xff) (#xc0 #x81 #xa0))))
    (cmw-probe children)))

(deftest test-REQ-CBR-006-map-concatenation-next-and-reused-space
  (multiple-value-bind (buffer start end) (cmw-destination 32)
    (let ((space (cmw-dirty-space)) (cursor start))
      (dolist (children '(nil ((0) (1)) ((#x61 #x61) (1) (#x61 #x62) (#x82 #xf4 #xf5))))
        (multiple-value-bind (source ss se table count) (cmw-fixture children)
          (setf cursor (cmw-accept buffer cursor end source ss se table count space))))
      (is (= (+ start 13) cursor))
      (is (equalp (subseq buffer start cursor)
                  (bytes #xa0 #xa1 0 1 #xa2 #x61 #x61 1 #x61 #x62 #x82 #xf4 #xf5))))))

(deftest test-REQ-CBR-006-map-destination-type-and-range-precedes-everything
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing))
         (displaced (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing
                                 :displaced-index-offset 4)))
    (dolist (buffer (list nil '(0) "abc" (make-array 4) displaced
                         (make-array '(2 2) :element-type '(unsigned-byte 8))
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)))
      (cmw-reject buffer 0 0 nil nil nil nil nil nil 'invalid-argument :cbor-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(1.0 2)
                      (list 0 (1+ most-positive-fixnum))))
    (cmw-reject (bytes 0 0) (first range) (second range) nil nil nil nil nil nil
                'invalid-argument :cbor-range nil)))

(deftest test-REQ-CBR-006-map-source-type-range-and-backing-array-intact
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing)))
    (dolist (source (list nil '(0) "a" (make-array 1)
                         (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing)
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)
                         (make-array '(2 2) :element-type '(unsigned-byte 8))))
      (cmw-cold-reject (bytes 0) 0 1 source 0 0 nil nil (cmw-dirty-space)
                       'invalid-argument :cbor-map-source-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(0 1.0)
                      (list 0 (1+ most-positive-fixnum))))
    (cmw-cold-reject (bytes 0) 0 1 (bytes 0 0) (first range) (second range) nil nil
                     (cmw-dirty-space) 'invalid-argument :cbor-map-source-range nil)))

(deftest test-REQ-CBR-006-map-table-type-count-domains-and-half-length-before-multiplication
  (dolist (table (list nil '(1 2) #(1 2) (bytes 1 2)
                       (make-array '(1 2) :element-type '(unsigned-byte 32))
                       (make-array 2 :element-type '(unsigned-byte 32) :fill-pointer 1)))
    (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table nil (cmw-dirty-space)
                     'invalid-argument :cbor-map-item-ends nil))
  (let ((table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (dolist (count (list nil -1 1.0 'bad 2 most-positive-fixnum (1+ most-positive-fixnum)))
      (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table count (cmw-dirty-space)
                       'invalid-argument :cbor-map-count nil))
    (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table 0 (cmw-dirty-space)
                     'invalid-argument :cbor-map-count nil))
  (dolist (fixture '((1 2 1) (3 4 2) (4 3 2) (0 0 1)))
    (destructuring-bind (length span count) fixture
      (cmw-cold-reject (bytes 0) 0 1 (make-array span :element-type '(unsigned-byte 8))
                       0 span (make-array length :element-type '(unsigned-byte 32)) count
                       (cmw-dirty-space) 'invalid-argument :cbor-map-count nil))))

(deftest test-REQ-CBR-006-map-workspace-type-and-all-scratch-aliases-even-empty
  (dolist (children '(nil ((0) (1))))
    (multiple-value-bind (source ss se table count) (cmw-fixture children)
      (let ((size (1+ (- se ss))))
        (dolist (space '(nil bad 0))
          (cmw-reject (make-array size :element-type '(unsigned-byte 8)) 0 size source ss se table count space
                      'invalid-argument :cbor-workspace nil :max-bytes nil))
        (dotimes (role 3)
          (let* ((space (cmw-dirty-space))
                 (kinds (arcdocdb.cbor::spazio-cbor-kinds space))
                 (remaining (arcdocdb.cbor::spazio-cbor-remaining space)))
            (cmw-cold-reject (if (= role 0) kinds (make-array size :element-type '(unsigned-byte 8))) 0 size
                             (if (= role 1) kinds source) (if (= role 1) 0 ss) (if (= role 1) (- se ss) se)
                             (if (= role 2) remaining table) count space
                             'invalid-argument :cbor-map-workspace-alias nil :max-bytes nil)))))))

(deftest test-REQ-CBR-006-map-configured-limits-and-empty-root-minimum
  (multiple-value-bind (source ss se table count) (cmw-fixture nil)
    (dolist (entry '((:max-bytes :cbor-byte-limit nil -1 16777217 1.0 bad)
                     (:max-nodes :cbor-node-limit nil 0 -1 16777217 1.0 bad)
                     (:max-depth :cbor-depth-limit nil -1 101 1.0 bad)))
      (dolist (value (cddr entry))
        (cmw-cold-reject (bytes 0) 0 1 source ss se table count (cmw-dirty-space)
                         'invalid-argument (second entry) nil (first entry) value)))
    (cmw-accept (bytes 0) 0 1 source ss se table 0 (cmw-dirty-space)
                :max-bytes 1 :max-nodes 1 :max-depth 1)
    (cmw-cold-reject (bytes 0) 0 1 source ss se table 0 (cmw-dirty-space)
                     'resource-exhausted :cbor-map-byte-budget nil :max-bytes 0)
    (cmw-cold-reject (bytes 0) 0 1 source ss se table 0 (cmw-dirty-space)
                     'resource-exhausted :cbor-map-depth-budget nil :max-depth 0)))

(deftest test-REQ-CBR-006-map-strict-active-ends-last-and-unread-even-or-odd-tail
  (dolist (entries '((0 2) (2 1) (1 1) (1 3) (#xffffffff 2)))
    (let ((table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents entries)))
      (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 table 1 (cmw-dirty-space)
                       'invalid-argument :cbor-map-item-ends nil)))
  (let ((table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (cmw-cold-reject (bytes 0 0 0 0) 0 4 (bytes 0 1 2) 0 3 table 1 (cmw-dirty-space)
                     'invalid-argument :cbor-map-item-ends nil))
  (cmw-probe '((0) (1)))
  (cmw-accept (bytes 0) 0 1 (bytes) 0 0 (make-array 0 :element-type '(unsigned-byte 32))
              0 (cmw-dirty-space))
  (cmw-accept (bytes 0 0 0) 0 3 (bytes 0 1) 0 2
              (make-array 3 :element-type '(unsigned-byte 32) :initial-contents '(1 2 #xffffffff))
              1 (cmw-dirty-space)))

(deftest test-REQ-CBR-006-map-all-preflight-phase-precedences
  (let* ((space (cmw-dirty-space))
         (bad-table (make-array 2 :element-type '(unsigned-byte 32) :initial-element 0))
         (good-table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (cmw-reject (bytes 0) -1 1 nil 0 0 nil nil nil 'invalid-argument :cbor-range nil)
    (cmw-cold-reject (bytes 0) 0 0 nil 0 0 nil nil space 'invalid-argument :cbor-map-source-range nil)
    (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 nil nil space 'invalid-argument :cbor-map-item-ends nil)
    (cmw-reject (bytes 0) 0 0 (bytes 0 1) 0 2 good-table 0 nil
                'invalid-argument :cbor-map-count nil :max-bytes nil)
    (cmw-reject (bytes 0) 0 0 (bytes 0 1) 0 2 good-table 1 nil
                'invalid-argument :cbor-workspace nil :max-bytes nil)
    (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 1 space
                     'invalid-argument :cbor-byte-limit nil :max-bytes nil :max-nodes nil :max-depth nil)
    (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 1 space
                     'invalid-argument :cbor-node-limit nil :max-nodes nil :max-depth nil)
    (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 1 space
                     'invalid-argument :cbor-depth-limit nil :max-depth nil)
    (dolist (limit '(0 2))
      (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 1 space
                       'resource-exhausted :cbor-map-byte-budget nil :max-bytes limit))
    (cmw-cold-reject (bytes 0) 0 0 (bytes 0 1) 0 2 bad-table 1 space
                     'resource-exhausted :cbor-map-capacity nil :max-nodes 1 :max-depth 0)
    (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes 0 1) 0 2 bad-table 1 space
                     'invalid-argument :cbor-map-item-ends nil :max-nodes 1 :max-depth 0)
    (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes #x18 0) 0 2 good-table 1 space
                     'resource-exhausted :cbor-map-node-budget nil :max-nodes 2 :max-depth 0)
    (cmw-cold-reject (bytes 0 0 0) 0 3 (bytes #x18 0) 0 2 good-table 1 space
                     'resource-exhausted :cbor-map-depth-budget nil :max-nodes 3 :max-depth 0)))

(deftest test-REQ-CBR-006-map-overlap-entire-footprint-touching-and-empty
  (dolist (start '(13 18 4))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5))
          (table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
      (replace buffer '(0 1) :start1 16)
      (cmw-accept buffer start (if (= start 4) 50 (+ start 3)) buffer 16 18 table 1 (cmw-dirty-space))))
  (dolist (start '(14 15 16 17))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5))
          (table (make-array 2 :element-type '(unsigned-byte 32) :initial-element 0)))
      (replace buffer '(0 1) :start1 16)
      (cmw-cold-reject buffer start (+ start 3) buffer 16 18 table 1 (cmw-dirty-space)
                       'invalid-argument :cbor-map-overlap nil :max-nodes 1 :max-depth 0)))
  (let ((buffer (bytes 0 1 0))
        (table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents '(1 2))))
    (cmw-cold-reject buffer 0 3 buffer 0 2 table 1 (cmw-dirty-space)
                     'invalid-argument :cbor-map-overlap nil)
    (cmw-accept buffer 0 1 buffer 0 0 table 0 (cmw-dirty-space))))

(deftest test-REQ-CBR-006-map-full-byte-budget-key-plus-value-exact-16MiB-and-over
  (dolist (extra '(0 1 2))
    (let* ((payload (+ 16777209 extra)) (header (cmw-header 2 payload))
           (span (+ 1 (length header) payload)) (ss 2) (se (+ ss span))
           (source (make-array (+ se 3) :element-type '(unsigned-byte 8) :initial-element #xa5))
           (table (make-array 2 :element-type '(unsigned-byte 32) :initial-contents (list 1 span))))
      (setf (aref source ss) 0) (replace source header :start1 (1+ ss))
      (multiple-value-bind (buffer start end) (cmw-destination (1+ span) :prefix 1)
        (if (zerop extra)
            (is (= (+ start 16777216)
                   (cmw-accept buffer start end source ss se table 1 (cmw-dirty-space) :max-bytes 16777216)))
            (cmw-cold-reject buffer start start source ss se table 1 (cmw-dirty-space)
                             'resource-exhausted :cbor-map-byte-budget nil :max-bytes 16777216))))))

(deftest test-REQ-CBR-006-map-root-key-value-tag-nodes-and-zero-residue-before-reset
  (dolist (key '((#x81 0) (#xc0 0)))
    (multiple-value-bind (source ss se table count) (cmw-fixture (list key '(0)))
      (let ((space (cmw-dirty-space)))
        (cmw-reject (bytes 0 0 0 0) 0 4 source ss se table count space
                    'resource-exhausted :cbor-map-node-budget (+ ss 2) :max-nodes 3)
        (is (= (+ ss 2) (arcdocdb.cbor::spazio-cbor-cursor space)))
        (is (= 2 (arcdocdb.cbor::spazio-cbor-nodes space))))
      (cmw-accept (bytes 0 0 0 0) 0 4 source ss se table count (cmw-dirty-space) :max-nodes 4)))
  (dolist (value '((#x81 0) (#xc0 0)))
    (multiple-value-bind (source ss se table count) (cmw-fixture (list '(0) value))
      (cmw-reject (bytes 0 0 0 0) 0 4 source ss se table count (cmw-dirty-space)
                  'resource-exhausted :cbor-node-budget (+ ss 2) :max-nodes 3)
      (cmw-accept (bytes 0 0 0 0) 0 4 source ss se table count (cmw-dirty-space) :max-nodes 4))))

(deftest test-REQ-CBR-006-map-root-depth-scalars-tags-and-99-100-child-containers
  (cmw-probe '((0) (#xc0 #xc1 0)) :max-depth 1)
  (multiple-value-bind (source ss se table count) (cmw-fixture '((0) (#x80)))
    (cmw-reject (bytes 0 0 0) 0 3 source ss se table count (cmw-dirty-space)
                'resource-exhausted :cbor-depth-budget (1+ ss) :max-depth 1))
  (dolist (depth '(99 100))
    (multiple-value-bind (source ss se table count)
        (cmw-fixture (list (append (make-list depth :initial-element #x81) '(0)) '(0)))
      (multiple-value-bind (buffer start end) (cmw-destination (+ depth 3))
        (if (= depth 99)
            (cmw-accept buffer start end source ss se table count (cmw-dirty-space)
                        :max-depth 100 :max-nodes 104)
            (cmw-reject buffer start end source ss se table count (cmw-dirty-space)
                        'resource-exhausted :cbor-depth-budget (+ ss 99) :max-depth 100))))))

(deftest test-REQ-CBR-006-map-key-and-value-parser-errors-absolute-and-left-to-right
  (dolist (entry '(((0 0) :cbor-trailing 1) ((#x18 0) :cbor-nonminimal 0)
                   ((#x18) :cbor-truncated 1) ((#x61 #xff) :utf8-leading 1)
                   ((#x62 #xc2 0) :utf8-continuation 2) ((#x61 #xc2) :utf8-truncated 2)
                   ((#x1c) :cbor-reserved 0) ((#x9f #xff) :cbor-nonminimal 0)
                   ((#xfa 0 0 0 0) :cbor-nonminimal 0)
                   ((#xfb #x3f #xf0 0 0 0 0 0 0) :cbor-nonminimal 0)))
    (dotimes (role 2)
      (multiple-value-bind (source ss se table count)
          (cmw-fixture (if (zerop role) (list (first entry) '(0)) (list '(0) (first entry))))
        (multiple-value-bind (buffer start end) (cmw-destination (1+ (- se ss)))
          (cmw-reject buffer start end source ss se table count (cmw-dirty-space)
                      'corruption-detected (second entry) (+ ss role (third entry)))))))
  (multiple-value-bind (source ss se table count) (cmw-fixture '((0) (#x18 0) (#x1c) (0)))
    (cmw-reject (bytes 0 0 0 0 0 0) 0 6 source ss se table count (cmw-dirty-space)
                'corruption-detected :cbor-nonminimal (1+ ss)))
  (multiple-value-bind (source ss se table count) (cmw-fixture '((#x1c) (0) (0) (#x18 0)))
    (cmw-reject (bytes 0 0 0 0 0 0) 0 6 source ss se table count (cmw-dirty-space)
                'corruption-detected :cbor-reserved ss)))

(deftest test-REQ-CBR-006-map-reuse-after-value-parser-and-preflight-errors
  (let ((space (cmw-dirty-space)))
    (multiple-value-bind (source ss se table count) (cmw-fixture '((0) (#x61 #xff)))
      (cmw-reject (bytes 0 0 0 0) 0 4 source ss se table count space
                  'corruption-detected :utf8-leading (+ ss 2)))
    (multiple-value-bind (source ss se table count) (cmw-fixture '((#x81 0) (#xc0 #xf6)))
      (cmw-cold-reject (bytes 0) 0 1 source ss se table count space
                       'resource-exhausted :cbor-map-capacity nil)
      (cmw-accept (bytes 0 0 0 0 0) 0 5 source ss se table count space))))

(deftest test-REQ-CBR-006-map-scratch-last-value-and-zero-pairs-no-reset
  (let ((space (cmw-dirty-space)))
    (multiple-value-bind (source ss se table count) (cmw-fixture '((#x81 0) (#xc0 0) (0) (#xa1 1 2)))
      (cmw-accept (bytes 0 0 0 0 0 0 0 0 0) 0 9 source ss se table count space)
      (is (= 3 (arcdocdb.cbor::spazio-cbor-nodes space)))
      (is (= 1 (arcdocdb.cbor::spazio-cbor-peak-depth space)))))
  (multiple-value-bind (source ss se table count) (cmw-fixture nil)
    (cmw-accept (bytes 0) 0 1 source ss se table count (cmw-dirty-space))))

(deftest test-REQ-CBR-006-map-fixed-seed-1024-fuzz-and-frozen-class-counts
  (let ((state #x4d415035) (counts (make-array 9 :initial-element 0))
        (catalogue '((0) (#x38 #x18) (#x61 #x41) (#xf9 #x7e 1)
                     (#xc0 #xf6) (#x80) (#xa1 0 1) (#x63 #xe2 #x82 #xac))))
    (dotimes (iteration 1024)
      (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
      (let ((category (mod iteration 16)))
        (if (< category 8)
            (multiple-value-bind (source ss se table count)
                (cmw-fixture (loop for i below (* 2 (1+ (mod (ash state -8) 4)))
                                   collect (nth (mod (+ state i) 8) catalogue)) :prefix (mod state 8))
              (multiple-value-bind (buffer start end)
                  (cmw-destination (+ (length (cmw-header 5 count)) (- se ss)) :prefix (mod state 32))
                (cmw-accept buffer start end source ss se table count (cmw-dirty-space))
                (incf (aref counts 0))))
            (multiple-value-bind (source ss se table count) (cmw-fixture '((0) (1)) :prefix (mod state 8))
              (multiple-value-bind (buffer start end) (cmw-destination 3 :prefix (mod state 32))
                (let ((space (cmw-dirty-space)))
                  (case category
                    (8 (cmw-cold-reject buffer start (1- end) source ss se table count space
                                        'resource-exhausted :cbor-map-capacity nil))
                    (9 (cmw-cold-reject buffer start end source ss se table count space
                                        'resource-exhausted :cbor-map-byte-budget nil :max-bytes 2))
                    (10 (setf (aref table 1) 1)
                        (cmw-cold-reject buffer start end source ss se table count space
                                         'invalid-argument :cbor-map-item-ends nil))
                    (11 (cmw-cold-reject buffer start end source ss se table count space
                                         'resource-exhausted :cbor-map-node-budget nil :max-nodes 2))
                    (12 (cmw-cold-reject buffer start end source ss se table count space
                                         'resource-exhausted :cbor-map-depth-budget nil :max-depth 0))
                    (13 (setf (aref source (1+ ss)) #x18)
                        (cmw-reject buffer start end source ss se table count space
                                    'corruption-detected :cbor-truncated se))
                    (14 (cmw-cold-reject buffer start end source -1 se table count space
                                         'invalid-argument :cbor-map-source-range nil))
                    (15 (cmw-cold-reject buffer start end source ss se table 2 space
                                         'invalid-argument :cbor-map-count nil)))
                  (incf (aref counts (- category 7)))))))))
    (is (equalp counts #(512 64 64 64 64 64 64 64 64)))
    (is (= state #x0d123435))
    (format t "  CBOR map fuzz: seed4D415035, 1024 casi, 512 successi e 64 ciascuno capacita/byte/entry/nodi/profondita/parse/source-range/count.~%")))
