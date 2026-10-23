(in-package #:arcdocdb.cbor.tag.write.tests)

;;; REQ: REQ-CBR-007 REQ-LIM-001 REQ-LIM-002
(deftest test-REQ-CBR-007-tag-u32-word-width-boundaries-and-all-wire-sentinels
  (dolist (entry '((0 0 (#xc0)) (0 1 (#xc1)) (0 23 (#xd7)) (0 24 (#xd8 #x18))
                   (0 255 (#xd8 #xff)) (0 256 (#xd9 1 0))
                   (0 65535 (#xd9 #xff #xff)) (0 65536 (#xda 0 1 0 0))
                   (0 4294967295 (#xda #xff #xff #xff #xff))
                   (1 0 (#xdb 0 0 0 1 0 0 0 0))
                   (4294967295 4294967295 (#xdb #xff #xff #xff #xff #xff #xff #xff #xff))
                   (0 55799 (#xd9 #xd9 #xf7))
                   (2147483648 7 (#xdb #x80 0 0 0 0 0 0 7))))
    (is (equal (third entry) (ctw-header (first entry) (second entry))))
    (ctw-probe '(#xa0) (first entry) (second entry) 1 1)))

(deftest test-REQ-CBR-007-tag-opaque-scalars-utf8-floats-containers-and-pair-order
  (dolist (entry '(((0) 1 0) ((#x38 #x18) 1 0) ((#x43 #x18 0 #xff) 1 0)
                   ((#x63 #xe2 #x82 #xac) 1 0) ((#x64 #xf0 #x90 #x80 #x80) 1 0)
                   ((#xf9 #x80 0) 1 0) ((#xf9 #x7c 1) 1 0) ((#xf9 #x7e 1) 1 0)
                   ((#xfa 0 0 0 1) 1 0) ((#xfb #xff #xf8 0 0 0 0 0 1) 1 0)
                   ((#xa2 2 0 1 0) 5 1) ((#xa2 1 0 1 1) 5 1)
                   ((#xc0 #x81 #xa0) 3 2) ((#xa1 #x81 0 #x82 #xf4 #xf5) 6 2)))
    (ctw-probe (first entry) 0 55799 (second entry) (third entry))))

(deftest test-REQ-CBR-007-tag-concatenation-next-and-exact-return-arity
  (multiple-value-bind (buffer start end) (ctw-destination 32)
    (let ((space (ctw-dirty-space)) (cursor start))
      (dolist (entry '(((0) 0 0) ((#x61 #x41) 0 24) ((#xa0) 0 55799)))
        (multiple-value-bind (source ss se) (ctw-fixture (first entry))
          (setf cursor (ctw-accept buffer cursor end source ss se (second entry) (third entry) space))))
      (is (= (+ start 10) cursor))
      (is (equalp (subseq buffer start cursor) (bytes #xc0 0 #xd8 #x18 #x61 #x41 #xd9 #xd9 #xf7 #xa0))))))

(deftest test-REQ-CBR-007-tag-destination-type-and-range-precedes-everything
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing)))
    (dolist (buffer (list nil '(0) "abc" (make-array 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing)
                         (make-array '(2 2) :element-type '(unsigned-byte 8))
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)))
      (ctw-reject buffer 0 0 nil nil nil nil nil nil 'invalid-argument :cbor-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(1.0 2)
                      (list 0 (1+ most-positive-fixnum))))
    (ctw-reject (bytes 0 0) (first range) (second range) nil nil nil nil nil nil
                'invalid-argument :cbor-range nil)))

(deftest test-REQ-CBR-007-tag-source-type-range-empty-and-backing-array-intact
  (let* ((backing (make-array 32 :element-type '(unsigned-byte 8) :initial-element #xa5))
         (before (copy-seq backing)))
    (dolist (source (list nil '(0) "a" (make-array 1)
                         (make-array 8 :element-type '(unsigned-byte 8) :displaced-to backing)
                         (make-array 8 :element-type '(unsigned-byte 8) :fill-pointer 4)
                         (make-array 8 :element-type '(unsigned-byte 8) :adjustable t)
                         (make-array '(2 2) :element-type '(unsigned-byte 8))))
      (ctw-cold-reject (bytes 0) 0 1 source 0 0 nil nil (ctw-dirty-space)
                       'invalid-argument :cbor-tag-source-range nil))
    (is (equalp backing before)))
  (dolist (range (list '(nil 1) '(-1 1) '(0 -1) '(2 1) '(0 99) '(0 1.0)
                      (list 0 (1+ most-positive-fixnum))))
    (ctw-cold-reject (bytes 0) 0 1 (bytes 0 0) (first range) (second range) nil nil
                     (ctw-dirty-space) 'invalid-argument :cbor-tag-source-range nil))
  (dolist (prefix '(0 1 7))
    (ctw-cold-reject (bytes 0) 0 0 (make-array (+ prefix 3) :element-type '(unsigned-byte 8))
                     prefix prefix nil nil (ctw-dirty-space) 'invalid-argument :cbor-tag-source-empty nil)))

(deftest test-REQ-CBR-007-tag-high-then-low-domain-precedence-without-u64
  (dolist (value (list nil -1 4294967296 1.0 1/2 'bad (1+ most-positive-fixnum)))
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 value nil (ctw-dirty-space)
                     'invalid-argument :cbor-write-high nil :max-bytes nil)
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 0 value (ctw-dirty-space)
                     'invalid-argument :cbor-write-low nil :max-bytes nil)))

(deftest test-REQ-CBR-007-tag-workspace-type-and-both-kinds-aliases
  (dolist (space '(nil bad 0))
    (ctw-reject (bytes 0 0) 0 2 (bytes 0) 0 1 0 0 space
                'invalid-argument :cbor-workspace nil :max-bytes nil))
  (dotimes (role 2)
    (let* ((space (ctw-dirty-space)) (kinds (arcdocdb.cbor::spazio-cbor-kinds space)))
      (ctw-cold-reject (if (zerop role) kinds (bytes 0 0)) 0 2
                       (if (= role 1) kinds (bytes 0)) 0 1 0 0 space
                       'invalid-argument :cbor-tag-workspace-alias nil :max-bytes nil))))

(deftest test-REQ-CBR-007-tag-configured-limits-and-root-two-node-minimum
  (dolist (entry '((:max-bytes :cbor-byte-limit nil -1 16777217 1.0 bad)
                   (:max-nodes :cbor-node-limit nil 0 -1 16777217 1.0 bad)
                   (:max-depth :cbor-depth-limit nil -1 101 1.0 bad)))
    (dolist (value (cddr entry))
      (ctw-cold-reject (bytes 0 0) 0 2 (bytes 0) 0 1 0 0 (ctw-dirty-space)
                       'invalid-argument (second entry) nil (first entry) value)))
  (ctw-accept (bytes 0 0) 0 2 (bytes 0) 0 1 0 0 (ctw-dirty-space)
              :max-bytes 2 :max-nodes 2 :max-depth 0)
  (ctw-cold-reject (bytes 0 0) 0 2 (bytes #x1c) 0 1 0 0 (ctw-dirty-space)
                   'resource-exhausted :cbor-tag-node-budget nil :max-nodes 1))

(deftest test-REQ-CBR-007-tag-all-preflight-phase-precedences
  (let ((space (ctw-dirty-space)))
    (ctw-reject (bytes 0) -1 1 nil 0 0 nil nil nil 'invalid-argument :cbor-range nil)
    (ctw-cold-reject (bytes 0) 0 0 nil 0 0 nil nil space 'invalid-argument :cbor-tag-source-range nil)
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 0 nil nil space 'invalid-argument :cbor-tag-source-empty nil)
    (ctw-reject (bytes 0) 0 0 (bytes 0) 0 1 nil nil nil 'invalid-argument :cbor-write-high nil)
    (ctw-reject (bytes 0) 0 0 (bytes 0) 0 1 0 nil nil 'invalid-argument :cbor-write-low nil)
    (ctw-reject (bytes 0) 0 0 (bytes 0) 0 1 0 0 nil 'invalid-argument :cbor-workspace nil :max-bytes nil)
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 0 0 space
                     'invalid-argument :cbor-byte-limit nil :max-bytes nil :max-nodes nil :max-depth nil)
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 0 0 space
                     'invalid-argument :cbor-node-limit nil :max-nodes nil :max-depth nil)
    (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 0 0 space
                     'invalid-argument :cbor-depth-limit nil :max-depth nil)
    (dolist (limit '(0 1))
      (ctw-cold-reject (bytes 0) 0 0 (bytes 0) 0 1 0 0 space
                       'resource-exhausted :cbor-tag-byte-budget nil :max-bytes limit :max-nodes 1))
    (let ((buffer (bytes #x1c 0)))
      (ctw-cold-reject buffer 0 1 buffer 0 1 0 0 space
                       'resource-exhausted :cbor-tag-capacity nil :max-nodes 1 :max-depth 0))
    (let ((buffer (bytes #x1c 0)))
      (ctw-cold-reject buffer 0 2 buffer 0 1 0 0 space
                       'invalid-argument :cbor-tag-overlap nil :max-nodes 1 :max-depth 0))
    (ctw-cold-reject (bytes 0 0) 0 2 (bytes #x1c) 0 1 0 0 space
                     'resource-exhausted :cbor-tag-node-budget nil :max-nodes 1 :max-depth 0)))

(deftest test-REQ-CBR-007-tag-capacity-active-end-and-complete-byte-budget
  (dolist (entry '((0 0) (0 24) (0 256) (0 65536) (1 0)))
    (let ((size (1+ (length (ctw-header (first entry) (second entry))))))
      (multiple-value-bind (buffer start end) (ctw-destination size)
        (ctw-accept buffer start end (bytes 0) 0 1 (first entry) (second entry) (ctw-dirty-space)
                    :max-bytes size)
        (ctw-cold-reject buffer start (1- end) (bytes 0) 0 1 (first entry) (second entry)
                         (ctw-dirty-space) 'resource-exhausted :cbor-tag-capacity nil)
        (dolist (limit (list 0 1 (1- size)))
          (ctw-cold-reject buffer start start (bytes 0) 0 1 (first entry) (second entry)
                           (ctw-dirty-space) 'resource-exhausted :cbor-tag-byte-budget nil :max-bytes limit))))))

(deftest test-REQ-CBR-007-tag-overlap-including-only-header-and-touching-boundaries
  (dolist (start '(6 17 2))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5)))
      (setf (aref buffer 16) 0)
      (ctw-accept buffer start (+ start 10) buffer 16 17 1 0 (ctw-dirty-space))))
  (dolist (start '(7 8 15 16))
    (let ((buffer (make-array 64 :element-type '(unsigned-byte 8) :initial-element #xa5)))
      (setf (aref buffer 16) 0)
      (ctw-cold-reject buffer start (+ start 10) buffer 16 17 1 0 (ctw-dirty-space)
                       'invalid-argument :cbor-tag-overlap nil :max-nodes 1)))
  (let ((buffer (bytes 0 0)))
    (ctw-cold-reject buffer 0 2 buffer 0 1 0 0 (ctw-dirty-space)
                     'invalid-argument :cbor-tag-overlap nil)))

(deftest test-REQ-CBR-007-tag-full-16MiB-with-one-and-nine-byte-header-and-over
  (dolist (high '(0 1))
    (dolist (extra '(0 1 2))
      (let* ((tag-size (if (zerop high) 1 9)) (payload (+ (- 16777216 tag-size 5) extra))
             (span (+ 5 payload)) (ss 2) (se (+ ss span))
             (source (make-array (+ se 3) :element-type '(unsigned-byte 8) :initial-element #xa5)))
        (replace source (append '(#x5a) (loop for power from 3 downto 0
                                              collect (mod (floor payload (expt 256 power)) 256))) :start1 ss)
        (multiple-value-bind (buffer start end) (ctw-destination (+ tag-size span) :prefix 1)
          (if (zerop extra)
              (is (= (+ start 16777216)
                     (ctw-accept buffer start end source ss se high 0 (ctw-dirty-space) :max-bytes 16777216)))
              (ctw-cold-reject buffer start start source ss se high 0 (ctw-dirty-space)
                               'resource-exhausted :cbor-tag-byte-budget nil :max-bytes 16777216)))))))

(deftest test-REQ-CBR-007-tag-root-and-content-node-residue-long-tag-chains-no-frame
  (dolist (entry '(((0) 1 0) ((#xc0 0) 2 0) ((#x81 0) 2 1) ((#xa1 0 1) 3 1)))
    (multiple-value-bind (source ss se) (ctw-fixture (first entry))
      (let ((size (1+ (- se ss))) (nodes (second entry)))
        (ctw-accept (make-array size :element-type '(unsigned-byte 8)) 0 size source ss se 0 0
                    (ctw-dirty-space) :max-nodes (1+ nodes))
        (if (= nodes 1)
            (ctw-cold-reject (make-array size :element-type '(unsigned-byte 8)) 0 size source ss se 0 0
                             (ctw-dirty-space) 'resource-exhausted :cbor-tag-node-budget nil :max-nodes nodes)
            (ctw-reject (make-array size :element-type '(unsigned-byte 8)) 0 size source ss se 0 0
                        (ctw-dirty-space) 'resource-exhausted :cbor-node-budget (+ ss (1- nodes)) :max-nodes nodes)))))
  (multiple-value-bind (source ss se) (ctw-fixture (append (make-list 1024 :initial-element #xc0) '(0)))
    (ctw-accept (make-array 1028 :element-type '(unsigned-byte 8)) 0 1028 source ss se 0 55799
                (ctw-dirty-space) :max-nodes 1026 :max-depth 0)
    (ctw-reject (make-array 1028 :element-type '(unsigned-byte 8)) 0 1028 source ss se 0 55799
                (ctw-dirty-space) 'resource-exhausted :cbor-node-budget (+ ss 1024)
                :max-nodes 1025 :max-depth 0)))

(deftest test-REQ-CBR-007-tag-depth-unchanged-zero-scalars-and-100-101-containers
  (ctw-probe '(0) 0 0 1 0 :max-depth 0)
  (ctw-probe '(#xc0 #xc1 0) 0 24 3 0 :max-depth 0)
  (dolist (lead '(#x80 #xa0))
    (ctw-reject (bytes 0 0) 0 2 (bytes lead) 0 1 0 0 (ctw-dirty-space)
                'resource-exhausted :cbor-depth-budget 0 :max-depth 0))
  (dolist (depth '(100 101))
    (multiple-value-bind (source ss se)
        (ctw-fixture (append (make-list depth :initial-element #x81) '(0)))
      (multiple-value-bind (buffer start end) (ctw-destination (+ 4 depth))
        (if (= depth 100)
            (let ((space (ctw-dirty-space)))
              (ctw-accept buffer start end source ss se 0 55799 space :max-depth 100 :max-nodes 102)
              (is (= 100 (arcdocdb.cbor::spazio-cbor-peak-depth space))))
            (ctw-reject buffer start end source ss se 0 55799 (ctw-dirty-space)
                        'resource-exhausted :cbor-depth-budget (+ ss 100) :max-depth 100))))))

(deftest test-REQ-CBR-007-tag-parser-failures-absolute-offset-and-complete-single-item
  (dolist (entry '(((0 0) :cbor-trailing 1) ((#x18 0) :cbor-nonminimal 0)
                   ((#x18) :cbor-truncated 1) ((#x61 #xff) :utf8-leading 1)
                   ((#x62 #xc2 0) :utf8-continuation 2) ((#x61 #xc2) :utf8-truncated 2)
                   ((#x1c) :cbor-reserved 0) ((#x9f #xff) :cbor-nonminimal 0)
                   ((#xfa 0 0 0 0) :cbor-nonminimal 0)
                   ((#xfb #x3f #xf0 0 0 0 0 0 0) :cbor-nonminimal 0)
                   ((#xc0) :cbor-truncated 1) ((#xc0 #xc1) :cbor-truncated 2)
                   ((#xc0 #xd8 0 0) :cbor-nonminimal 1)
                   ((#xa1 0 #x18 0) :cbor-nonminimal 2)
                   ((#x80 #x1c) :cbor-trailing 1) ((#x63 #xff) :cbor-truncated 2)))
    (multiple-value-bind (source ss se) (ctw-fixture (first entry))
      (multiple-value-bind (buffer start end) (ctw-destination (+ 9 (- se ss)))
        (ctw-reject buffer start end source ss se 1 #x12345678 (ctw-dirty-space)
                    'corruption-detected (second entry) (+ ss (third entry)))))))

(deftest test-REQ-CBR-007-tag-every-truncation-nonzero-source-start-and-exact-end
  (let ((contents '(#xa1 #xc0 #x61 #x78 #x82 #xf9 #x3c 0 #x42 #x18 0)))
    (dolist (prefix '(0 1 7 17))
      (multiple-value-bind (source ss se) (ctw-fixture contents :prefix prefix)
        (multiple-value-bind (buffer start end) (ctw-destination (+ 3 (length contents)))
          (dotimes (available (length contents))
            (if (zerop available)
                (ctw-cold-reject buffer start end source ss ss 0 55799 (ctw-dirty-space)
                                 'invalid-argument :cbor-tag-source-empty nil)
                (ctw-reject buffer start end source ss (+ ss available) 0 55799 (ctw-dirty-space)
                            'corruption-detected :cbor-truncated (+ ss available))))
          (ctw-accept buffer start end source ss se 0 55799 (ctw-dirty-space)))))))

(deftest test-REQ-CBR-007-tag-scratch-reuse-after-parser-and-preflight-errors
  (let ((space (ctw-dirty-space)))
    (multiple-value-bind (source ss se) (ctw-fixture '(#x81 #x61 #xff))
      (ctw-reject (bytes 0 0 0 0) 0 4 source ss se 0 0 space
                  'corruption-detected :utf8-leading (+ ss 2)))
    (multiple-value-bind (source ss se) (ctw-fixture '(#xc0 #x81 0))
      (ctw-cold-reject (bytes 0) 0 1 source ss se 0 0 space
                       'resource-exhausted :cbor-tag-capacity nil)
      (ctw-accept (bytes 0 0 0 0) 0 4 source ss se 0 0 space :max-nodes 4 :max-depth 1))))

(deftest test-REQ-CBR-007-tag-scratch-content-only-statistics-after-success
  (let ((space (ctw-dirty-space)))
    (dolist (entry '(((#xc0 #xa1 0 #x81 0) 5 2) ((0) 1 0) ((#x80) 1 1)))
      (multiple-value-bind (source ss se) (ctw-fixture (first entry))
        (multiple-value-bind (buffer start end) (ctw-destination (+ 3 (- se ss)))
          (ctw-accept buffer start end source ss se 0 55799 space)
          (is (= (second entry) (arcdocdb.cbor::spazio-cbor-nodes space)))
          (is (= (third entry) (arcdocdb.cbor::spazio-cbor-peak-depth space))))))))

(deftest test-REQ-CBR-007-tag-fixed-seed-1024-fuzz-and-frozen-class-counts
  (let ((state #x54414737) (counts (make-array 9 :initial-element 0))
        (catalogue '((0) (#x38 #x18) (#x61 #x41) (#xf9 #x7e 1)
                     (#xc0 #xf6) (#x80) (#xa1 0 1) (#x63 #xe2 #x82 #xac))))
    (dotimes (iteration 1024)
      (setf state (logand #xffffffff (+ (* state 1664525) 1013904223)))
      (let ((category (mod iteration 16)))
        (if (< category 8)
            (multiple-value-bind (source ss se)
                (ctw-fixture (nth (mod (ash state -8) 8) catalogue) :prefix (mod state 8))
              (let* ((high (if (logbitp 16 state) (ash state -1) 0)) (low state)
                     (size (+ (length (ctw-header high low)) (- se ss))))
                (multiple-value-bind (buffer start end) (ctw-destination size :prefix (mod state 32))
                  (ctw-accept buffer start end source ss se high low (ctw-dirty-space))
                  (incf (aref counts 0)))))
            (multiple-value-bind (source ss se) (ctw-fixture '(0) :prefix (mod state 8))
              (multiple-value-bind (buffer start end) (ctw-destination 2 :prefix (mod state 32))
                (let ((space (ctw-dirty-space)))
                  (case category
                    (8 (ctw-cold-reject buffer start (1- end) source ss se 0 0 space
                                        'resource-exhausted :cbor-tag-capacity nil))
                    (9 (ctw-cold-reject buffer start end source ss se 0 0 space
                                        'resource-exhausted :cbor-tag-byte-budget nil :max-bytes 1))
                    (10 (ctw-cold-reject buffer start end source ss se -1 0 space
                                         'invalid-argument :cbor-write-high nil))
                    (11 (ctw-cold-reject buffer start end source ss se 0 0 space
                                         'resource-exhausted :cbor-tag-node-budget nil :max-nodes 1))
                    (12 (setf (aref source ss) #x80)
                        (ctw-reject buffer start end source ss se 0 0 space
                                    'resource-exhausted :cbor-depth-budget ss :max-depth 0))
                    (13 (setf (aref source ss) #x18)
                        (ctw-reject buffer start end source ss se 0 0 space
                                    'corruption-detected :cbor-truncated se))
                    (14 (ctw-cold-reject buffer start end source -1 se 0 0 space
                                         'invalid-argument :cbor-tag-source-range nil))
                    (15 (ctw-cold-reject buffer start end source ss ss 0 0 space
                                         'invalid-argument :cbor-tag-source-empty nil)))
                  (incf (aref counts (- category 7)))))))))
    (is (equalp counts #(512 64 64 64 64 64 64 64 64)))
    (is (= state #xf8004b37))
    (format t "  CBOR tag fuzz: seed54414737, 1024 casi, 512 successi e 64 ciascuno capacita/byte/high/nodi/profondita/parse/source-range/empty.~%")))
