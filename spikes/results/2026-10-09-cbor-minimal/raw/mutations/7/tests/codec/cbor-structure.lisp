(in-package #:arcdocdb.cbor.structure.tests)

;;; Gli expected sono manuali o derivati dalla costruzione, prima della lettura
;;; dei nuovi sorgenti del codec. Il modello freddo ammette bignum e ricorsione.
(defun cs-manual-accept (contents nodes depth &rest keys)
  (multiple-value-bind (buffer start end) (cs-fixture contents)
    (apply #'cs-accept buffer start end (arcdocdb.cbor:crea-spazio-cbor)
           (list nodes depth end) keys)))

(defun cs-manual-reject (contents type reason relative-offset &rest keys)
  (multiple-value-bind (buffer start end) (cs-fixture contents)
    (apply #'cs-reject buffer start end (arcdocdb.cbor:crea-spazio-cbor)
           type reason (if (eq relative-offset :end) end
                           (and relative-offset (+ start relative-offset))) keys)))

(defun cs-argument (major argument)
  "Encodifica aritmetica fredda usata soltanto per costruire gli AST."
  (if (< argument 24)
      (list (+ (* major 32) argument))
      (let* ((width (cond ((< argument 256) 1) ((< argument 65536) 2)
                          ((< argument 4294967296) 4) (t 8)))
             (ai (ecase width (1 24) (2 25) (4 26) (8 27))))
        (cons (+ (* major 32) ai) (arcdocdb.cbor.tests::cbor-big-endian argument width)))))

(defun cs-encode-ast (node &optional (depth 0))
  "Restituisce bytes/nodi/picco dalla struttura generata, senza decodificarla."
  (case (first node)
    (:uint (values (cs-argument 0 (second node)) 1 depth))
    (:negative (values (cs-argument 1 (second node)) 1 depth))
    (:simple (values (list (second node)) 1 depth))
    ((:bytes :text)
     (let ((payload (second node)))
       (values (append (cs-argument (if (eq (first node) :bytes) 2 3) (length payload))
                       payload) 1 depth)))
    (:tag
     (multiple-value-bind (payload nodes peak) (cs-encode-ast (third node) depth)
       (values (append (cs-argument 6 (second node)) payload) (1+ nodes) peak)))
    ((:array :map :indef-array :indef-map)
     (let* ((new-depth (1+ depth)) (children (rest node))
            (map-p (member (first node) '(:map :indef-map)))
            (indef-p (member (first node) '(:indef-array :indef-map)))
            (major (if map-p 5 4))
            (encoded (if indef-p (list (+ (* major 32) 31))
                         (cs-argument major (if map-p (/ (length children) 2)
                                                (length children)))))
            (nodes 1) (peak new-depth))
       (dolist (child children)
         (multiple-value-bind (payload count child-peak) (cs-encode-ast child new-depth)
           (setf encoded (append encoded payload) peak (max peak child-peak))
           (incf nodes count)))
       (values (if indef-p (append encoded '(255)) encoded) nodes peak)))
    ((:indef-bytes :indef-text)
     (let ((encoded (list (if (eq (first node) :indef-bytes) #x5f #x7f)))
           (nodes 1) (peak depth))
       (dolist (child (rest node))
         (multiple-value-bind (payload count child-peak) (cs-encode-ast child depth)
           (setf encoded (append encoded payload) peak (max peak child-peak))
           (incf nodes count)))
       (values (append encoded '(255)) nodes peak)))
    (otherwise (error "AST della fixture sconosciuto: ~S" node))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-rfc-definite-vectors
  (dolist (fixture '(((#x00) 1 0) ((#x17) 1 0) ((#x18 #x18) 1 0)
                     ((#x19 #x03 #xe8) 1 0) ((#x20) 1 0) ((#x38 #x63) 1 0)
                     ((#xf4) 1 0) ((#xf5) 1 0) ((#xf6) 1 0) ((#xf7) 1 0)
                     ((#xf8 #xff) 1 0) ((#xf9 #x3e #x00) 1 0)
                     ((#xfa #x47 #xc3 #x50 #x00) 1 0)
                     ((#xfb #x3f #xf1 #x99 #x99 #x99 #x99 #x99 #x9a) 1 0)
                     ((#x40) 1 0) ((#x43 1 2 3) 1 0) ((#x60) 1 0)
                     ((#x64 #x49 #x45 #x54 #x46) 1 0)
                     ((#x62 #xc3 #xbc) 1 0) ((#x63 #xe6 #xb0 #xb4) 1 0)
                     ((#x64 #xf0 #x90 #x85 #x91) 1 0)
                     ((#x80) 1 1) ((#xa0) 1 1) ((#x83 1 2 3) 4 1)
                     ((#x83 1 #x82 2 3 #x82 4 5) 8 2)
                     ((#xa2 1 2 3 4) 5 1) ((#xc1 0) 2 0)))
    (apply #'cs-manual-accept fixture)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-rfc-indefinite-vectors
  (dolist (fixture '(((#x5f #xff) 1 0) ((#x7f #xff) 1 0)
                     ((#x5f #x42 1 2 #x43 3 4 5 #xff) 3 0)
                     ((#x7f #x62 #x73 #x74 #x64 #x72 #x65 #x61 #x6d #xff) 3 0)
                     ((#x9f #xff) 1 1) ((#xbf #xff) 1 1)
                     ((#x9f 1 #x82 2 3 #x9f 4 5 #xff #xff) 8 2)
                     ((#xbf #x61 #x61 1 #x61 #x62 #x9f 2 3 #xff #xff) 7 2)
                     ((#x9f #x5f #x40 #x40 #xff #x7f #x60 #xff #xff) 6 1)))
    (apply #'cs-manual-accept fixture)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-generic-profile-permissions
  (dolist (fixture '(((#x18 0) 1 0) ((#x1b 0 0 0 0 0 0 0 0) 1 0)
                     ((#x3b #xff #xff #xff #xff #xff #xff #xff #xff) 1 0)
                     ((#xfb #x7f #xf8 0 0 0 0 0 1) 1 0)
                     ((#xfb #xff #xf0 0 0 0 0 0 0) 1 0)
                     ((#xf9 #x7e 1) 1 0) ((#xf9 #x80 0) 1 0)
                     ((#x58 0) 1 0) ((#x98 0) 1 1)
                     ((#xdb #xff #xff #xff #xff #xff #xff #xff #xff #xf6) 2 0)
                     ((#xa2 1 0 1 1) 5 1) ((#xa2 2 0 1 0) 5 1)
                     ((#xa1 #x81 0 1) 4 2)))
    (apply #'cs-manual-accept fixture)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-generated-ast-corpus
  (let ((state #x7394b21d) (space (arcdocdb.cbor:crea-spazio-cbor)) (count 0))
    (labels ((pick (n) (setf state (mod (+ (* state 1664525) 1013904223) 4294967296))
               (mod state n))
             (generate (left)
               (case (if (zerop left) (pick 5) (pick 10))
                 (0 (list :uint (pick 100000))) (1 (list :negative (pick 100000)))
                 (2 (list :simple (nth (pick 4) '(244 245 246 247))))
                 (3 (list :bytes (loop repeat (pick 8) collect (pick 256))))
                 (4 (list :text (append '(0 #xc3 #xbc) (loop repeat (pick 8) collect (+ 32 (pick 95))))))
                 (5 (cons :array (loop repeat (pick 4) collect (generate (1- left)))))
                 (6 (cons :indef-array (loop repeat (pick 4) collect (generate (1- left)))))
                 (7 (cons (if (zerop (pick 2)) :map :indef-map)
                          (loop repeat (* 2 (pick 3)) collect (generate (1- left)))))
                 (8 (list :tag (pick 1000) (generate (1- left))))
                 (9 (if (zerop (pick 2))
                        '(:indef-bytes (:bytes ()) (:bytes (0 255)))
                        '(:indef-text (:text ()) (:text (239 187 191))))))))
      (dotimes (index 256)
        (multiple-value-bind (contents nodes peak) (cs-encode-ast (generate 4))
          (multiple-value-bind (buffer start end) (cs-fixture contents :prefix (mod index 11))
            (cs-accept buffer start end space (list nodes peak end))
            ;; Mutazione di ogni item completo: il byte seguente resta non interpretato.
            (multiple-value-bind (bad bad-start bad-end)
                (cs-fixture (append contents '(#x1c)))
              (cs-reject bad bad-start bad-end space 'corruption-detected
                         :cbor-trailing (+ bad-start (length contents))))
            (incf count))))
      (is (= count 256))
      (format t "  CBOR structure AST: seed 7394B21D, ~D casi generati.~%" count))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-all-leads-two-byte-spans
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)) (accepted 0) (rejected 0))
    (dotimes (lead 256)
      (dolist (second '(0 255))
        (multiple-value-bind (buffer start end) (cs-fixture (list lead second) :prefix 3)
          (multiple-value-bind (expected type reason offset) (cs-reference buffer start end)
            (if expected
                (progn (cs-accept buffer start end space expected) (incf accepted))
                (progn (cs-reject buffer start end space type reason offset) (incf rejected)))))))
    (is (= (+ accepted rejected) 512))
    (format t "  CBOR structure lead: 512 span, ~D validi/~D rifiutati.~%" accepted rejected)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-seeded-finite-differential
  (let ((state #x49cba017) (accepted 0) (rejected 0)
        (space (arcdocdb.cbor:crea-spazio-cbor)))
    (labels ((random-octet ()
               (setf state (mod (+ (* state 1664525) 1013904223) 4294967296))
               (floor state 16777216)))
      (dotimes (case-index 4096)
        (let ((contents (loop repeat (1+ (mod case-index 64)) collect (random-octet))))
          (multiple-value-bind (buffer start end) (cs-fixture contents :prefix (mod case-index 9))
            (multiple-value-bind (expected type reason offset) (cs-reference buffer start end)
              (if expected
                  (progn (cs-accept buffer start end space expected) (incf accepted))
                  (progn (cs-reject buffer start end space type reason offset) (incf rejected))))))))
    (is (= (+ accepted rejected) 4096))
    (format t "  CBOR structure fuzz: seed 49CBA017, ~D validi/~D rifiutati.~%" accepted rejected)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-truncation-at-every-boundary
  (dolist (ast '((:array (:uint 1000) (:text (226 130 172)) (:indef-array (:tag 24 (:bytes (1 2 3)))))
                 (:indef-map (:text (97)) (:array (:uint 1) (:uint 2))
                             (:text (98)) (:indef-text (:text ()) (:text (195 188))))))
    (multiple-value-bind (contents nodes peak) (cs-encode-ast ast)
      (declare (ignore nodes peak))
      (multiple-value-bind (buffer start end) (cs-fixture contents)
        (let ((space (arcdocdb.cbor:crea-spazio-cbor)))
          (loop for limit from start to end do
            (multiple-value-bind (expected type reason offset) (cs-reference buffer start limit)
              (if expected (cs-accept buffer start limit space expected)
                  (cs-reject buffer start limit space type reason offset)))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-exact-root-and-trailing-priority
  (dolist (trailing '((#xff) (#x1c) (#x1b) (#xf8 0) (#x63 #xff)))
    (cs-manual-reject (append '(0) trailing) 'corruption-detected :cbor-trailing 1 :max-nodes 1))
  (cs-manual-accept '(0) 1 0 :max-nodes 1 :max-depth 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-break-context-and-tag-priority
  (dolist (contents '((#xff) (#x81 #xff) (#xa1 #xff 0)))
    (cs-manual-reject contents 'corruption-detected :cbor-break
                      (if (= (length contents) 1) 0 1)))
  (cs-manual-reject '(#xbf 0 #xff) 'corruption-detected :cbor-map-value 2)
  (dolist (fixture '(((#xc0 #xff) 1) ((#x81 #xc0 #xff) 2)
                     ((#xbf 0 #xc0 #xff) 3) ((#x5f #xc0 #xff) 1)))
    ;; Nella stringa il tag valido è già un chunk errato, prima del suo break.
    (cs-manual-reject (first fixture) 'corruption-detected
                      (if (= (caar fixture) #x5f) :cbor-chunk-type :cbor-tag-break)
                      (second fixture)))
  (cs-manual-reject '(#xc0 #xc1) 'corruption-detected :cbor-truncated :end)
  (cs-manual-accept '(#xbf 0 #xc0 1 #xff) 4 1))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-tags-charge-parent-once
  (cs-manual-accept '(#x82 #xc0 #xc1 0 1) 5 1)
  (cs-manual-accept '(#xa1 #xc0 0 #xc1 #xc2 1) 6 1)
  (cs-manual-accept '(#x9f #xc0 #xc1 0 1 #xff) 5 1)
  (let ((contents (append (make-list 1024 :initial-element #xc0) '(0))))
    (cs-manual-accept contents 1025 0 :max-depth 0 :max-nodes 1025)
    (cs-manual-reject contents 'resource-exhausted :cbor-node-budget 1024
                      :max-depth 0 :max-nodes 1024)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-chunks-same-type-and-header-first
  (dolist (fixture '(((#x5f #x60 #xff) 1) ((#x7f #x40 #xff) 1)
                     ((#x5f #x5f #xff #xff) 1) ((#x7f #x7f #xff #xff) 1)
                     ((#x5f 0 #xff) 1) ((#x7f #x80 #xff) 1)
                     ((#x5f #xf6 #xff) 1) ((#x7f #xc0 0 #xff) 1)))
    (cs-manual-reject (first fixture) 'corruption-detected :cbor-chunk-type (second fixture)
                      :max-nodes 1))
  (cs-manual-reject '(#x5f #x78) 'corruption-detected :cbor-truncated :end :max-nodes 1)
  (cs-manual-reject '(#x7f #x1c) 'corruption-detected :cbor-reserved 1 :max-nodes 1)
  (cs-manual-accept '(#x5f #x40 #xff) 2 0 :max-depth 0 :max-nodes 2))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-valid-unicode-and-chunk-locality
  (dolist (payload '(() (0) (239 187 191) (239 191 190) (239 191 191)
                     (194 128) (224 160 128) (237 159 191)
                     (240 144 128 128) (244 143 191 191)))
    (cs-manual-accept (append (cs-argument 3 (length payload)) payload) 1 0)
    (cs-manual-accept (append '(#x7f #x60) (cs-argument 3 (length payload)) payload '(#xff)) 3 0))
  (cs-manual-accept '(#x82 #x62 #xc3 #xbc #x60) 3 1))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-invalid-unicode-exact-offsets
  (dolist (fixture '(((#x61 #x80) :utf8-leading 1)
                     ((#x61 #xc0) :utf8-leading 1)
                     ((#x62 #xe0 #x00) :utf8-truncated 3)
                     ((#x63 #xe0 #x00 #x80) :utf8-continuation 2)
                     ((#x63 #xed #xa0 #x80) :utf8-scalar 2)
                     ((#x64 #xf4 #x90 #x80 #x80) :utf8-scalar 2)
                     ((#x7f #x61 #xc2 #x61 #x80 #xff) :utf8-truncated 3)
                     ((#x7f #x60 #x62 #xc2 0 #xff) :utf8-continuation 4)))
    (cs-manual-reject (first fixture) 'corruption-detected (second fixture) (third fixture))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-payload-width-and-huge-unsigned-lengths
  (cs-manual-reject '(#x63 #xff) 'corruption-detected :cbor-truncated :end)
  (dolist (major '(2 3 4 5))
    (dolist (words '((0 1 0 0 0 0 0 0) (#x80 0 0 0 0 0 0 0)
                     (#xff #xff #xff #xff #xff #xff #xff #xff)))
      (cs-manual-reject (cons (+ (* major 32) 27) words)
                        'corruption-detected :cbor-truncated :end)))
  (cs-manual-reject '(#x59 #xff #xff) 'corruption-detected :cbor-truncated :end)
  (cs-manual-reject '(#x7a 0 0 0 2 #xff) 'corruption-detected :cbor-truncated :end))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-container-minimum-remaining-bytes
  (cs-manual-reject '(#x82 0) 'corruption-detected :cbor-truncated :end)
  (cs-manual-reject '(#xa1 0) 'corruption-detected :cbor-truncated :end)
  (cs-manual-reject '(#xba 0 0 0 1 0) 'corruption-detected :cbor-truncated :end)
  (cs-manual-accept '(#x82 0 0) 3 1)
  (cs-manual-accept '(#xa1 0 0) 3 1)
  ;; Depth rejection precedes the too-large arity even for a complete header.
  (cs-manual-reject '(#x9b #xff #xff #xff #xff #xff #xff #xff #xff)
                    'resource-exhausted :cbor-depth-budget 0 :max-depth 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-depth-100-and-map-keys
  ;; Supplemento dal contratto dopo la seconda lettura: root+100 frame di
  ;; contenitori+una stringa indefinita usano l'ultimo slot dello scratch.
  (dolist (string '((#x7f #x60 #xff) (#x5f #x40 #xff)))
    (cs-manual-accept (append (make-list 100 :initial-element #x81) string) 102 100))
  (dolist (levels '(100 101))
    (let ((contents (append (make-list levels :initial-element #x81) '(0))))
      (if (= levels 100) (cs-manual-accept contents 101 100)
          (cs-manual-reject contents 'resource-exhausted :cbor-depth-budget 100)))
    (let ((contents (append (make-list levels :initial-element #xa1) '(0)
                            (make-list levels :initial-element 0))))
      (if (= levels 100) (cs-manual-accept contents 201 100)
          (cs-manual-reject contents 'resource-exhausted :cbor-depth-budget 100))))
  (cs-manual-accept '(#xc0 #x81 #xa0) 3 2 :max-depth 2)
  (cs-manual-reject '(#xc0 #x81 #xa0) 'resource-exhausted :cbor-depth-budget 2 :max-depth 1)
  (dolist (lead '(#x80 #xa0 #x9f #xbf))
    (cs-manual-reject (if (member lead '(#x9f #xbf)) (list lead #xff) (list lead))
                      'resource-exhausted :cbor-depth-budget 0 :max-depth 0)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-node-boundaries-chunks-and-breaks
  (dolist (fixture '(((#x82 0 1) 3 1 2) ((#x9f 0 1 #xff) 3 1 2)
                     ((#x5f #x40 #x41 0 #xff) 3 0 2)
                     ((#x7f #x60 #x60 #xff) 3 0 2)
                     ((#xc0 #xc1 0) 3 0 2)))
    (destructuring-bind (contents nodes depth third-lead) fixture
      (cs-manual-accept contents nodes depth :max-nodes nodes)
      (cs-manual-accept contents nodes depth :max-nodes (1+ nodes))
      (cs-manual-reject contents 'resource-exhausted :cbor-node-budget third-lead
                        :max-nodes (1- nodes))))
  (cs-manual-accept '(#x9f #xff) 1 1 :max-nodes 1)
  (cs-manual-accept '(#xbf #xff) 1 1 :max-nodes 1)
  (cs-manual-accept '(#x7f #xff) 1 0 :max-nodes 1 :max-depth 0)
  (cs-manual-reject '(#x81 #x80) 'resource-exhausted :cbor-node-budget 1
                    :max-nodes 1 :max-depth 1))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-header-errors-before-node-budget
  (dolist (fixture '(((#x81 #x1c) :cbor-reserved 1)
                     ((#x81 #x1b) :cbor-truncated :end)
                     ((#x81 #xf8 0) :cbor-simple 2)
                     ((#x81 #xdf) :cbor-indefinite 1)))
    (cs-manual-reject (first fixture) 'corruption-detected (second fixture) (third fixture)
                      :max-nodes 1))
  (cs-manual-reject '(#x81 #xff) 'corruption-detected :cbor-break 1 :max-nodes 1)
  (cs-manual-reject '(#xbf 0 #xff) 'corruption-detected :cbor-map-value 2 :max-nodes 2)
  (cs-manual-reject '(#xc0 #xff) 'corruption-detected :cbor-tag-break 1 :max-nodes 1))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-invalid-range-and-type-priority
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)))
    (dolist (buffer (list nil '(0) (vector 0) "a" #*0
                          (make-array 1 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 1 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array 1 :element-type '(unsigned-byte 8) :displaced-to (bytes 0))
                          (make-array 1 :element-type '(signed-byte 8))
                          (make-array '(1 1) :element-type '(unsigned-byte 8))))
      (cs-reject buffer 0 1 space 'invalid-argument :cbor-range nil))
    (let ((buffer (bytes 0)))
      (dolist (span '((-1 1) (0 2) (1 0) (0 -1) (nil 1) (0 nil) (0.0 1)
                      (0 1.0) (0 1/2)))
        (cs-reject buffer (first span) (second span) space 'invalid-argument :cbor-range nil))
      (cs-reject buffer -1 2 nil 'invalid-argument :cbor-range nil :max-bytes -1)
      (cs-accept buffer 0 1 space '(1 0 1))
      (cs-reject buffer 1 1 space 'corruption-detected :cbor-truncated 1))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-workspace-alias-and-preflight-immutability
  (let ((buffer (bytes 0)))
    (dolist (space (list nil t 0 (vector 0) buffer))
      (cs-reject buffer 0 1 space 'invalid-argument :cbor-workspace nil :max-bytes -1)))
  (let* ((space (arcdocdb.cbor:crea-spazio-cbor))
         (kinds (arcdocdb.cbor::spazio-cbor-kinds space)))
    ;; Accessor is the private alias-injection contract supplied before source reading.
    (fill kinds #xa5)
    (let ((before (copy-seq kinds)))
      (cs-reject kinds 0 (length kinds) space 'invalid-argument :cbor-alias nil :max-bytes -1)
      (is (equalp before kinds))
      (cs-reject (bytes 0) 0 1 space 'resource-exhausted :cbor-byte-budget nil :max-bytes 0)
      (is (equalp before kinds))
      (cs-reject (bytes 0) 0 1 space 'invalid-argument :cbor-node-limit nil :max-nodes 0)
      (is (equalp before kinds)))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-structure-limit-configuration-and-order
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)) (buffer (bytes 0)))
    (dolist (limit '(-1 16777217 nil 0.0 1/2))
      (cs-reject buffer 0 1 space 'invalid-argument :cbor-byte-limit nil :max-bytes limit))
    (dolist (limit '(0 -1 16777217 nil 1.0 1/2))
      (cs-reject buffer 0 1 space 'invalid-argument :cbor-node-limit nil :max-nodes limit))
    (dolist (limit '(-1 101 nil 0.0 1/2))
      (cs-reject buffer 0 1 space 'invalid-argument :cbor-depth-limit nil :max-depth limit))
    (cs-reject buffer 0 1 space 'invalid-argument :cbor-byte-limit nil
               :max-bytes -1 :max-nodes 0 :max-depth -1)
    (cs-reject buffer 0 1 space 'invalid-argument :cbor-node-limit nil
               :max-nodes 0 :max-depth -1)
    (cs-accept buffer 0 1 space '(1 0 1) :max-bytes 1 :max-nodes 1 :max-depth 0)
    (cs-accept buffer 0 1 space '(1 0 1) :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-byte-budget-and-exact-16-mib
  (let* ((size 16777216)
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element #xff))
         (space (arcdocdb.cbor:crea-spazio-cbor)))
    ;; 5 header bytes plus 16MiB-5 opaque payload bytes. This is the whole document.
    (replace buffer '(#x5a #x00 #xff #xff #xfb))
    (cs-accept buffer 0 size space (list 1 0 size))
    (cs-reject buffer 0 size space 'resource-exhausted :cbor-byte-budget nil :max-bytes (1- size)))
  (let* ((size 16777217)
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element #x1c)))
    (cs-reject buffer 0 size (arcdocdb.cbor:crea-spazio-cbor)
               'resource-exhausted :cbor-byte-budget nil))
  (cs-manual-reject '(#x1c) 'resource-exhausted :cbor-byte-budget nil :max-bytes 0)
  (cs-manual-reject '() 'corruption-detected :cbor-truncated :end :max-bytes 0))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-cbor-structure-reuse-after-runtime-failures
  (let ((space (arcdocdb.cbor:crea-spazio-cbor)))
    (dolist (fixture '(((#x9f #x81 #x1c) :cbor-reserved 2)
                       ((#xbf #x80 #xff) :cbor-map-value 2)
                       ((#x9f #x7f #x61 #xc2 #xff #xff) :utf8-truncated 4)
                       ((#xc0 #xc1) :cbor-truncated :end)))
      (multiple-value-bind (buffer start end) (cs-fixture (first fixture))
        (cs-reject buffer start end space 'corruption-detected (second fixture)
                   (if (eq (third fixture) :end) end (+ start (third fixture)))))
      (multiple-value-bind (buffer start end) (cs-fixture '(#x82 #xa0 #x7f #x60 #xff))
        (cs-accept buffer start end space (list 4 2 end))))))
