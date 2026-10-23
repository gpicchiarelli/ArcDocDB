(in-package #:arcdocdb.cbor.minimal.scan.tests)

;;; Expected manuali/costruiti, prima di leggere il nuovo scanner.
;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-all-major-types-and-generic-permissions
  (dolist (fixture '(((0) 1 0) ((#x20) 1 0) ((#x40) 1 0) ((#x60) 1 0)
                     ((#x80) 1 1) ((#xa0) 1 1) ((#xc0 0) 2 0) ((#xf6) 1 0)
                     ((#x1b #xff #xff #xff #xff #xff #xff #xff #xff) 1 0)
                     ((#x3b #xff #xff #xff #xff #xff #xff #xff #xff) 1 0)
                     ((#xdb #xff #xff #xff #xff #xff #xff #xff #xff #xf6) 2 0)
                     ((#xa2 1 0 1 1) 5 1) ((#xa2 2 0 1 0) 5 1)
                     ((#xa1 #x81 0 1) 4 2) ((#xc0 #xf6) 2 0)
                     ((#xc1 #x61 #x78) 2 0) ((#xc0 #x81 #xa0) 3 2)))
    (apply #'cms-manual-accept fixture)))

;;; REQ: REQ-AFF-004 REQ-LIM-002
(deftest test-REQ-AFF-004-cbor-minimal-scan-integer-and-tag-width-thresholds
  (dolist (major '(0 1 6))
    (dolist (argument '(0 23 24 25 255 256 257 65535 65536 65537
                        4294967295 4294967296 4294967297
                        9223372036854775808 18446744073709551615))
      (let ((contents (append (cs-argument major argument) (when (= major 6) '(0)))))
        (cms-manual-accept contents (if (= major 6) 2 1) 0)))))

;;; REQ: REQ-AFF-004 REQ-LIM-002
(deftest test-REQ-AFF-004-cbor-minimal-scan-string-and-container-width-thresholds
  (dolist (major '(2 3 4 5))
    (dolist (count '(0 23 24 255 256 65535 65536))
      (let* ((arity (if (= major 5) 2 1))
             (payload (make-list (* arity count) :initial-element (if (= major 2) #xff 0)))
             (contents (append (cs-argument major count) payload)))
        (cms-manual-accept contents (if (<= major 3) 1 (1+ (* arity count)))
                           (if (<= major 3) 0 1))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-nonminimal-widths-at-every-major
  (dotimes (major 7)
    (loop for ai from 24 to 27
          do (let ((contents (append (cms-wide-argument major ai 0) (when (= major 6) '(0)))))
               (cms-manual-reject contents 'corruption-detected :cbor-nonminimal 0)))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-floats-in-root-keys-values-and-tags
  (dolist (entry '((25 #x0000 t) (25 #x8000 t) (25 #x0001 t) (25 #x7bff t)
                   (25 #x7c00 t) (25 #xfc00 t) (25 #x7c01 t) (25 #x7e01 t)
                   (26 #x00000001 t) (26 #x00800001 t) (26 #x3f800001 t)
                   (26 #x7fc00001 t) (26 #x7f800001 t)
                   (26 #x00000000 nil) (26 #x80000000 nil) (26 #x3f800000 nil)
                   (26 #x33800000 nil) (26 #x7f800000 nil) (26 #x7fc00000 nil)
                   (27 #x0000000000000001 t) (27 #x0010000000000001 t)
                   (27 #x3ff0000000000001 t) (27 #x7ff0000000000001 t)
                   (27 #xfff8000000000001 t) (27 #x0000000000000000 nil)
                   (27 #x8000000000000000 nil) (27 #x3ff0000000000000 nil)
                   (27 #x36a0000000000000 nil) (27 #x7ff0000000000000 nil)
                   (27 #x7ff0000020000000 nil)))
    (destructuring-bind (ai bits accepted) entry
      (let ((raw (cms-wide-argument 7 ai bits)))
        (dolist (wrapper '((nil nil 1 0 0) ((#x81) nil 2 1 1)
                           ((#xa1) (0) 3 1 1) ((#xa1 0) nil 3 1 2)
                           ((#xc0 #xc1) nil 3 0 2) ((#x81 #xa1 0) nil 4 2 3)))
          (destructuring-bind (prefix suffix nodes depth offset) wrapper
            (let ((contents (append prefix raw suffix)))
              (if accepted (cms-manual-accept contents nodes depth)
                  (cms-manual-reject contents 'corruption-detected :cbor-nonminimal offset)))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-all-leading-bytes-cold-reference
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)) (accepted 0) (rejected 0))
    (dotimes (lead 256)
      (multiple-value-bind (buffer start end)
          (cs-fixture (list lead #xa5 #x12 #x34 #x56 #x78 #x9a #xbc #xde) :prefix 3)
        (dolist (limit (list (1+ start) end))
          (if (cms-compare buffer start limit space) (incf accepted) (incf rejected))))
      (multiple-value-bind (buffer start end)
          (cs-fixture (list #x81 lead #xa5 #x12 #x34 #x56 #x78 #x9a #xbc #xde) :prefix 1)
        (if (cms-compare buffer start end space) (incf accepted) (incf rejected))))
    (is (= 768 (+ accepted rejected)))
    (format t "  CBOR struttura minima: 768 casi lead, ~D accettati/~D rifiutati.~%"
            accepted rejected)))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-header-syntax-before-local-preference
  (dolist (fixture '(((#x1c) :cbor-reserved 0) ((#x1d) :cbor-reserved 0)
                     ((#x1e) :cbor-reserved 0) ((#x1f) :cbor-indefinite 0)
                     ((#x3f) :cbor-indefinite 0) ((#xdf) :cbor-indefinite 0)
                     ((#xf8 #x00) :cbor-simple 1) ((#xf8 #x1f) :cbor-simple 1)))
    (cms-manual-reject (first fixture) 'corruption-detected (second fixture) (third fixture)))
  (dotimes (major 8)
    (loop for ai from 24 to 27 for width in '(1 2 4 8)
          do (let ((contents (cms-wide-argument major ai 0)))
               (dotimes (available (1+ width))
                 (cms-manual-reject (subseq contents 0 available)
                                    'corruption-detected :cbor-truncated :end)))))
  (cms-manual-accept '(#xf8 #x20) 1 0)
  (cms-manual-accept '(#xf8 #xff) 1 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-preference-before-budgets-and-payload
  (cms-manual-reject '(#x81 #x18 0) 'corruption-detected :cbor-nonminimal 1 :max-nodes 1)
  (cms-manual-reject '(#x98 0) 'corruption-detected :cbor-nonminimal 0 :max-depth 0)
  (cms-manual-reject '(#x78 1 #xff) 'corruption-detected :cbor-nonminimal 0)
  (cms-manual-reject '(#x58 1) 'corruption-detected :cbor-nonminimal 0)
  (cms-manual-reject '(#x81 #x9f) 'corruption-detected :cbor-nonminimal 1
                     :max-nodes 1 :max-depth 1)
  (cms-manual-reject '(#xc0 #xff) 'corruption-detected :cbor-nonminimal 1 :max-nodes 1)
  (dolist (lead '(#x5f #x7f #x9f #xbf #xff))
    (cms-manual-reject (list lead) 'corruption-detected :cbor-nonminimal 0 :max-depth 0))
  ;; Le testate dei figli non raggiunti non precedono un'arita irrealizzabile del padre.
  (cms-manual-reject '(#xa2 #x18 0) 'corruption-detected :cbor-truncated :end)
  (cms-manual-reject '(#x83 #x18 0) 'corruption-detected :cbor-truncated :end)
  (cms-manual-reject '(#x1c) 'resource-exhausted :cbor-byte-budget nil :max-bytes 0))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-nested-preference-not-only-root
  (dolist (fixture '(((#x81 #x18 0) 1) ((#xa1 #x18 0 0) 1)
                     ((#xa1 0 #x18 0) 2) ((#xc0 #xd8 0 0) 1)
                     ((#x81 #xa1 0 #x81 #x18 0) 4)
                     ((#xa1 #x81 #x18 0 0) 2)
                     ((#xc0 #xc1 #x98 0) 2) ((#x81 #x78 0) 1)))
    (cms-manual-reject (first fixture) 'corruption-detected
                       :cbor-nonminimal (second fixture))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-opaque-bytes-and-control-text-are-not-headers
  (let ((payload '(#x18 0 #x1c #xff #x5f #x7f #x9f #xbf #xdf #xfb 0)))
    (cms-manual-accept (append (cs-argument 2 (length payload)) payload) 1 0)
    (cms-manual-accept (append '(#xc0) (cs-argument 2 (length payload)) payload) 2 0)
    (cms-manual-accept (append '(#xa1) (cs-argument 2 (length payload)) payload '(0)) 3 1))
  (cms-manual-accept '(#x64 #x18 0 #x1c #x7f) 1 0)
  (cms-manual-accept '(#x81 #x42 #x18 0) 2 1)
  (cms-manual-reject '(#x81 #x82 #x18 0 0) 'corruption-detected :cbor-nonminimal 2))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-utf8-absolute-offsets-and-whole-payload
  (dolist (payload '((0 #x7f) (#xc2 #xa2) (#xe2 #x82 #xac) (#xf0 #x90 #x80 #x80)
                     (#xef #xbb #xbf) (#xef #xbf #xbe)))
    (cms-manual-accept (append (cs-argument 3 (length payload)) payload) 1 0))
  (dolist (fixture '(((#x61 #xff) :utf8-leading 1)
                     ((#x61 #xc2) :utf8-truncated :end)
                     ((#x62 #xc2 0) :utf8-continuation 2)
                     ((#x63 #xed #xa0 #x80) :utf8-scalar 2)
                     ((#x64 #xf4 #x90 #x80 #x80) :utf8-scalar 2)
                     ((#xa1 #x61 #xff 0) :utf8-leading 2)
                     ((#x81 #x62 #xc2 0) :utf8-continuation 3)))
    (cms-manual-reject (first fixture) 'corruption-detected (second fixture) (third fixture)))
  (cms-manual-reject '(#x63 #xff) 'corruption-detected :cbor-truncated :end))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-completed-root-precedes-trailing-content
  (dolist (root '((0) (#x80) (#xa0) (#xc0 0) (#x81 0) (#xa1 0 0)))
    (dolist (tail '((#x18 0) (#xff) (#x1c) (#xf8 0) (#x78 1 #xff) (#x1b)))
      (cms-manual-reject (append root tail) 'corruption-detected :cbor-trailing (length root)))))

;;; REQ: REQ-AFF-008 REQ-LIM-002
(deftest test-REQ-AFF-008-cbor-minimal-scan-tags-count-once-in-parent-and-node-bounds
  (dolist (fixture '(((#x82 #xc0 #xc1 0 1) 5 1)
                     ((#xa1 #xc0 #xc1 0 #xc2 1) 6 1)
                     ((#xc0 #xc1 #x81 0) 4 1)))
    (apply #'cms-manual-accept fixture))
  (let ((contents (append (make-list 1024 :initial-element #xc0) '(0))))
    (cms-manual-accept contents 1025 0 :max-nodes 1025 :max-depth 0)
    (cms-manual-reject contents 'resource-exhausted :cbor-node-budget 1024
                       :max-nodes 1024 :max-depth 0))
  (cms-manual-reject '(#xc0 #xc1) 'corruption-detected :cbor-truncated :end)
  (cms-manual-reject '(#xc0) 'corruption-detected :cbor-truncated :end)
  (cms-manual-accept '(#x82 0 1) 3 1 :max-nodes 3)
  (cms-manual-reject '(#x82 0 1) 'resource-exhausted :cbor-node-budget 2 :max-nodes 2)
  (cms-manual-reject '(#x81 #x80) 'resource-exhausted :cbor-node-budget 1
                     :max-nodes 1 :max-depth 1)
  (cms-manual-reject '(#x81 #x1b) 'corruption-detected :cbor-truncated :end :max-nodes 1))

;;; REQ: REQ-LIM-002 REQ-AFF-008
(deftest test-REQ-LIM-002-cbor-minimal-scan-depth-100-101-and-map-keys
  (cms-manual-accept '(0) 1 0 :max-depth 0)
  (dolist (lead '(#x80 #xa0))
    (cms-manual-reject (list lead) 'resource-exhausted :cbor-depth-budget 0 :max-depth 0))
  (dolist (levels '(100 101))
    (let ((array (append (make-list levels :initial-element #x81) '(0)))
          (map (append (make-list levels :initial-element #xa1) '(0)
                       (make-list levels :initial-element 0))))
      (if (= levels 100)
          (progn (cms-manual-accept array 101 100) (cms-manual-accept map 201 100))
          (progn (cms-manual-reject array 'resource-exhausted :cbor-depth-budget 100)
                 (cms-manual-reject map 'resource-exhausted :cbor-depth-budget 100)))))
  (cms-manual-accept '(#xc0 #x81 #xa0) 3 2 :max-depth 2)
  (cms-manual-reject '(#xc0 #x81 #xa0) 'resource-exhausted :cbor-depth-budget 2 :max-depth 1))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-minimal-scan-huge-lengths-and-parent-arity-priority
  (dolist (major '(2 3 4 5))
    (dolist (argument '(4294967296 9223372036854775808 18446744073709551615))
      (cms-manual-reject (cms-wide-argument major 27 argument)
                         'corruption-detected :cbor-truncated :end)))
  (cms-manual-reject '(#x82 0) 'corruption-detected :cbor-truncated :end)
  (cms-manual-reject '(#xa1 0) 'corruption-detected :cbor-truncated :end)
  (cms-manual-reject '(#x9b #xff #xff #xff #xff #xff #xff #xff #xff)
                     'resource-exhausted :cbor-depth-budget 0 :max-depth 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-invalid-input-priority-and-cold-immutability
  (let ((space (cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor))))
    (dolist (buffer (list nil '(0) (vector 0) "a" #*0
                          (make-array 1 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 1 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array 1 :element-type '(unsigned-byte 8) :displaced-to (bytes 0))
                          (make-array 1 :element-type '(signed-byte 8))
                          (make-array '(1 1) :element-type '(unsigned-byte 8))))
      (cms-cold-reject buffer 0 1 space 'invalid-argument :cbor-range nil))
    (dolist (span '((-1 1) (0 2) (1 0) (0 -1) (nil 1) (0 nil) (0.0 1) (0 1.0) (0 1/2)))
      (cms-cold-reject (bytes 0) (first span) (second span) space
                       'invalid-argument :cbor-range nil :max-bytes -1))
    (cms-reject (bytes 0) -1 2 nil 'invalid-argument :cbor-range nil :max-bytes -1)
    (cms-accept (bytes 0) 0 1 space '(1 0 1))
    (cms-reject (bytes 0) 1 1 space 'corruption-detected :cbor-truncated 1)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-workspace-alias-and-limit-order
  (dolist (space (list nil t 0 (vector 0) (bytes 0)))
    (cms-reject (bytes 0) 0 1 space 'invalid-argument :cbor-workspace nil :max-bytes -1))
  (let* ((space (cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor)))
         (kinds (arcdocdb.cbor::spazio-cbor-kinds space)))
    (cms-cold-reject kinds 0 (length kinds) space 'invalid-argument :cbor-alias nil
                     :max-bytes -1 :max-nodes 0 :max-depth -1)
    (dolist (limit '(-1 16777217 nil 0.0 1/2))
      (cms-cold-reject (bytes 0) 0 1 space 'invalid-argument :cbor-byte-limit nil :max-bytes limit))
    (dolist (limit '(0 -1 16777217 nil 1.0 1/2))
      (cms-cold-reject (bytes 0) 0 1 space 'invalid-argument :cbor-node-limit nil :max-nodes limit))
    (dolist (limit '(-1 101 nil 0.0 1/2))
      (cms-cold-reject (bytes 0) 0 1 space 'invalid-argument :cbor-depth-limit nil :max-depth limit))
    (cms-cold-reject (bytes 0) 0 1 space 'invalid-argument :cbor-byte-limit nil
                     :max-bytes -1 :max-nodes 0 :max-depth -1)
    (cms-cold-reject (bytes 0) 0 1 space 'invalid-argument :cbor-node-limit nil
                     :max-nodes 0 :max-depth -1)
    (cms-cold-reject (bytes 0) 0 1 space 'resource-exhausted :cbor-byte-budget nil :max-bytes 0)
    (cms-accept (bytes 0) 0 1 space '(1 0 1) :max-bytes 1 :max-nodes 1 :max-depth 0)))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-cbor-minimal-scan-exact-sixteen-mib-and-over-budget
  (let* ((size 16777216)
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element #xff))
         (space (arcdocdb.cbor:crea-spazio-cbor)))
    (replace buffer '(#x5a #x00 #xff #xff #xfb))
    (cms-accept buffer 0 size space (list 1 0 size) :max-nodes 1)
    (cms-cold-reject buffer 0 size space 'resource-exhausted :cbor-byte-budget nil
                     :max-bytes (1- size))
    ;; Il limite riguarda il documento, non soltanto un payload opaco non attraversato.
    (fill buffer #x61 :start 5)
    (replace buffer '(#x7a #x00 #xff #xff #xfb))
    (cms-accept buffer 0 size space (list 1 0 size) :max-nodes 1))
  (let* ((size 16777217)
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element #x1c))
         (space (cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor))))
    (cms-cold-reject buffer 0 size space 'resource-exhausted :cbor-byte-budget nil))
  (cms-manual-reject '() 'corruption-detected :cbor-truncated :end :max-bytes 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-minimal-scan-reset-after-errors-and-alternating-modes
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)))
    (dolist (fixture '(((#x81 #x18 0) :cbor-nonminimal 1)
                       ((#xc0 #xff) :cbor-nonminimal 1)
                       ((#x81 #x61 #xc2) :utf8-truncated :end)
                       ((#xc0 #xc1) :cbor-truncated :end)
                       ((#xa1 0) :cbor-truncated :end)))
      (multiple-value-bind (buffer start end) (cs-fixture (first fixture))
        (cms-reject buffer start end space 'corruption-detected (second fixture)
                     (if (eq (third fixture) :end) end (+ start (third fixture)))))
      (cms-accept (bytes #x82 #xa0 #x60) 0 3 space '(3 2 3))
      ;; Il generico conserva la permissivita; il flag minimo non resta nello scratch.
      (let ((generic (bytes #x9f #x18 0 #xff)))
        (is (equal '(2 1 4) (multiple-value-list
                            (arcdocdb.cbor:verifica-struttura-cbor generic 0 4 space)))))
      (cms-accept (bytes #x81 0) 0 2 space '(2 1 2)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-cbor-minimal-scan-misalignment-declared-span-and-truncations
  (let ((contents '(#xa1 #xc0 #x61 #x78 #x82 #xf9 #x3c 0 #x42 #x18 0)))
    (loop for prefix from 0 to 17
          do (multiple-value-bind (buffer start end) (cs-fixture contents :prefix prefix)
               (cms-accept buffer start end (arcdocdb.cbor:crea-spazio-cbor) (list 6 2 end))
               (dotimes (available (length contents))
                 (cms-compare buffer start (+ start available) (arcdocdb.cbor:crea-spazio-cbor)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-scan-seeded-asts-and-finite-differential-fuzz
  ;; Metodo fissato prima dell'esecuzione: LCG32, seed #x53434d31, scelta dai
  ;; 16 bit alti, 512 AST depth<=3, poi fuzz4096 span0..64 e prefix1..7.
  (let ((seed #x53434d31) (accepted 0) (rejected 0) (space (arcdocdb.cbor:crea-spazio-cbor)))
    (labels ((next32 () (setf seed (mod (+ (* seed 1664525) 1013904223) 4294967296)))
             (draw (n) (mod (floor (next32) 65536) n))
             (node (depth)
               (let ((kind (draw (if (zerop depth) 5 8))))
                 (case kind
                   (0 (list :uint (nth (draw 8) '(0 23 24 255 256 65536 4294967296 18446744073709551615))))
                   (1 (list :negative (draw 65537)))
                   (2 (list :bytes '(#x18 0 #x1c #xff)))
                   (3 (list :text '(0 #xf0 #x90 #x80 #x80)))
                   (4 (list :simple #xf6))
                   (5 (list :tag (draw 65537) (node (1- depth))))
                   (6 (list :array (node (1- depth)) (node (1- depth))))
                   (7 (list :map (node (1- depth)) (node (1- depth))
                            (node (1- depth)) (node (1- depth))))))))
      (dotimes (iteration 512)
        (multiple-value-bind (contents nodes peak) (cs-encode-ast (node 3))
          (is (<= (length contents) 4096))
          (multiple-value-bind (buffer start end) (cs-fixture contents)
            (cms-accept buffer start end space (list nodes peak end)))))
      (dotimes (iteration 4096)
        (let ((contents (loop repeat (draw 65) collect (draw 256)))
              (prefix (1+ (draw 7))))
          (multiple-value-bind (buffer start end) (cs-fixture contents :prefix prefix)
            (let ((keys (list :max-bytes (draw 65)
                              :max-nodes (1+ (draw 12)) :max-depth (draw 5))))
              (if (apply #'cms-compare buffer start end space keys)
                  (incf accepted) (incf rejected)))))))
    (is (= 4096 (+ accepted rejected)))
    (format t "  CBOR struttura minima: 512 AST e fuzz4096 seed53434d31, ~D validi/~D rifiutati.~%"
            accepted rejected)))
