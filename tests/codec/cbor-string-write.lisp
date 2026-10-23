(in-package #:arcdocdb.cbor.string.write.tests)

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-literal-headers-and-byte-payloads
  (dolist (entry '((0 (#x40)) (23 (#x57)) (24 (#x58 #x18))
                   (255 (#x58 #xff)) (256 (#x59 #x01 #x00))
                   (65535 (#x59 #xff #xff)) (65536 (#x5a #x00 #x01 #x00 #x00))))
    (destructuring-bind (length literal) entry
      (dolist (major '(2 3))
        (is (equal (cws-header major length)
                   (cons (+ (first literal) (if (= major 3) 32 0)) (rest literal))))
        (multiple-value-bind (source ss se) (cws-source length :binary (= major 2))
          (multiple-value-bind (buffer start end) (cws-destination (+ length 9))
            (cws-accept buffer start end major source ss se)))))))

;;; REQ: REQ-CBR-002 REQ-AFF-004
(deftest test-REQ-CBR-002-string-write-major-two-preserves-all-octets
  (let ((source (make-array 256 :element-type '(unsigned-byte 8))))
    (dotimes (i 256) (setf (aref source i) i))
    (multiple-value-bind (buffer start end) (cws-destination 264 :prefix 1)
      (cws-accept buffer start end 2 source 0 256))))

;;; REQ: REQ-CBR-002 REQ-AFF-004
(deftest test-REQ-CBR-002-string-write-text-nul-bom-noncharacters-and-no-normalization
  (dolist (scalars '(() (0) (65 0 66) (#xfeff) (#xfdd0 #xfffe #xffff #x10ffff)
                     (#x7f #x80 #x7ff #x800 #xd7ff #xe000 #x10000)
                     (#xe9) (#x65 #x301)))
    (let ((source (utf8-encode-scalars scalars)))
      (multiple-value-bind (buffer start end) (cws-destination (+ 9 (length source)))
        (cws-accept buffer start end 3 source 0 (length source)))))
  ;; Otto scalari di tre byte richiedono AI24: il conteggio e in byte, non in scalari.
  (let ((source (utf8-encode-scalars (make-list 8 :initial-element #x20ac))))
    (is (= 24 (length source)))
    (multiple-value-bind (buffer start end) (cws-destination 26)
      (cws-accept buffer start end 3 source 0 24)
      (is (= #x78 (aref buffer start))) (is (= 24 (aref buffer (1+ start)))))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-width-boundaries-and-adjacent-lengths
  (dolist (length '(0 1 22 23 24 25 254 255 256 257 65534 65535 65536 65537))
    (dolist (major '(2 3))
      (multiple-value-bind (source ss se) (cws-source length :prefix 11 :binary (= major 2))
        (multiple-value-bind (buffer start end)
            (cws-destination (+ length (length (cws-header major length))) :prefix 17 :suffix 0)
          (cws-accept buffer start end major source ss se))))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-all-lengths-zero-through-4096
  (let ((count 0))
    (dolist (major '(2 3))
      (multiple-value-bind (source ss se) (cws-source 4096 :binary (= major 2))
        (declare (ignore se))
        (multiple-value-bind (buffer start end) (cws-destination 4105)
          (dotimes (length 4097)
            (cws-accept buffer start end major source ss (+ ss length))
            (incf count)))))
    (is (= count 8194))
    (format t "  CBOR string write: lunghezze0..4096 x MT2/3, ~D confronti freddi.~%" count)))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-every-short-capacity-with-physical-suffix
  (let ((count 0))
    (dolist (major '(2 3))
      (dolist (length '(0 1 23 24 255 256))
        (multiple-value-bind (source ss se) (cws-source length :binary (= major 2))
          (let ((size (+ length (length (cws-header major length)))))
            (dotimes (capacity size)
              (multiple-value-bind (buffer start end) (cws-destination capacity :suffix (+ size 3))
                (cws-reject buffer start end major source ss se
                            'resource-exhausted :cbor-string-capacity nil)
                (incf count)))))))
    (is (= count 1138))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-destination-range-is-first
  (let ((buffer (bytes #xa0 #xb1 #xc2 #xd3)))
    (dolist (major '(2 3))
      (dolist (position '(0 1 4))
        (cws-reject buffer position position major buffer 4 4
                    'resource-exhausted :cbor-string-capacity nil :max-bytes 1)))
    (dolist (range '((-1 1) (0 -1) (2 1) (0 5) (5 5) (nil 1) (0 nil)
                     (1.0 2) (0 1.0) (1/2 2) (0 3/2)))
      (cws-reject buffer (first range) (second range) 7 nil -1 nil
                  'invalid-argument :cbor-range nil :max-bytes -1))
    (cws-reject buffer 0 (1+ most-positive-fixnum) 7 nil -1 nil
                'invalid-argument :cbor-range nil :max-bytes -1)))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-invalid-destination-and-source-shapes
  (let* ((base (bytes 1 2 3 4)) (destination (bytes 0 0 0 0))
         (displaced (make-array 2 :element-type '(unsigned-byte 8) :displaced-to base)))
    (dolist (invalid (list nil '(65) #(65) "A" #*1010 7
                           (make-array 2 :element-type '(unsigned-byte 8) :adjustable t)
                           (make-array 2 :element-type '(unsigned-byte 8) :fill-pointer 1)
                           (make-array '(2 2) :element-type '(unsigned-byte 8)) displaced))
      (cws-reject invalid 0 0 7 nil 0 0 'invalid-argument :cbor-range nil :max-bytes -1)
      (cws-reject destination 0 4 2 invalid 0 0
                  'invalid-argument :cbor-string-source-range nil :max-bytes -1))
    (is (equalp base (bytes 1 2 3 4)))))

;;; REQ: REQ-CBR-002 REQ-AFF-004
(deftest test-REQ-CBR-002-string-write-major-before-source-budget-and-capacity
  (let ((buffer (bytes #xe0 #xe1 #xe2)))
    (dolist (major (list -1 0 1 4 5 6 7 nil :major 2.0 5/2 #\A #c(2 1)
                        (1+ most-positive-fixnum)))
      (cws-reject buffer 1 1 major nil -1 nil
                  'invalid-argument :cbor-string-major nil :max-bytes -1))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-source-range-before-budget-and-capacity
  (let ((source (bytes #xa0 #xb1 #xc2 #xd3)) (buffer (bytes 0 0)))
    (dolist (range '((-1 1) (0 -1) (2 1) (0 5) (5 5) (nil 1) (0 nil)
                     (1.0 2) (0 1.0) (1/2 2) (0 3/2)))
      (cws-reject buffer 0 0 3 source (first range) (second range)
                  'invalid-argument :cbor-string-source-range nil :max-bytes -1))
    (cws-reject buffer 0 0 2 source (1+ most-positive-fixnum) (1+ most-positive-fixnum)
                'invalid-argument :cbor-string-source-range nil :max-bytes -1)))

;;; REQ: REQ-CBR-002 REQ-AFF-004
(deftest test-REQ-CBR-002-string-write-budget-argument-before-resource-and-utf8
  (let ((source (bytes #xff)) (buffer (bytes 0 0)))
    (dolist (budget (list -1 16777217 (1+ most-positive-fixnum) nil :budget 1.0 1/2 #\A))
      (cws-reject buffer 0 0 3 source 0 1 'invalid-argument :cbor-string-budget nil
                  :max-bytes budget))))

;;; REQ: REQ-CBR-002 REQ-LIM-002 REQ-AFF-004
(deftest test-REQ-CBR-002-string-write-budget-includes-header-and-empty-item
  (dolist (major '(2 3))
    (dolist (length '(0 1 23 24 255 256 65535 65536))
      (multiple-value-bind (source ss se) (cws-source length :binary (= major 2))
        (let ((size (+ length (length (cws-header major length)))))
          (multiple-value-bind (buffer start end) (cws-destination size)
            (cws-reject buffer start end major source ss se
                        'resource-exhausted :cbor-string-byte-budget nil :max-bytes length)
            (cws-reject buffer start end major source ss se
                        'resource-exhausted :cbor-string-byte-budget nil :max-bytes (1- size))
            (cws-accept buffer start end major source ss se :max-bytes size)))))))

;;; REQ: REQ-CBR-002 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-maximum-item-and-one-byte-over-limit
  (let ((maximum 16777216) (payload 16777211))
    (dolist (major '(2 3))
      (multiple-value-bind (source ss se) (cws-source payload :binary (= major 2))
        (multiple-value-bind (buffer start end) (cws-destination maximum :prefix 1 :suffix 3)
          (is (= maximum (+ payload (length (cws-header major payload)))))
          (cws-accept buffer start end major source ss se)
          (cws-accept buffer start end major source ss se :max-bytes maximum))))
    (multiple-value-bind (source ss se) (cws-source (+ payload 6) :binary t)
      ;; Payload MAX+1 supera il budget; MAX e MAX-4 superano il budget con la testata.
      (dolist (length (list (1+ maximum) maximum (1+ payload)))
        (dolist (major '(2 3))
          (cws-reject (bytes 0) 0 0 major source ss (+ ss length)
                      'resource-exhausted :cbor-string-byte-budget nil)))
      (cws-reject (bytes 0) 0 0 3 source ss se
                  'invalid-argument :cbor-string-budget nil :max-bytes (1+ maximum)))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-same-array-disjoint-touching-and-empty
  (dolist (major '(2 3))
    (dolist (positions '((1 5 5) (10 14 0) (2 26 26) (29 53 3)))
      (destructuring-bind (ss se start) positions
        (let ((buffer (make-array 70 :element-type '(unsigned-byte 8) :initial-element #x41)))
          (cws-accept buffer start 70 major buffer ss se))))
    ;; Sorgente vuota ovunque, anche dentro la testata che verra modificata.
    (dolist (position '(0 3 4 16))
      (let ((buffer (make-array 16 :element-type '(unsigned-byte 8) :initial-element #xff)))
        (cws-accept buffer 3 16 major buffer position position)))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-overlap-includes-header-and-not-extra-span
  (dolist (major '(2 3))
    (dolist (positions '((4 5 4) (2 26 24) (6 10 3) (3 7 3) (1 5 3)))
      (destructuring-bind (ss se start) positions
        (let ((buffer (make-array 70 :element-type '(unsigned-byte 8) :initial-element #x41)))
          (cws-reject buffer start 70 major buffer ss se
                      'invalid-argument :cbor-string-overlap nil))))
    ;; END abbraccia la source, ma il footprint di cinque byte finisce prima di essa.
    (let ((buffer (make-array 30 :element-type '(unsigned-byte 8) :initial-element #x41)))
      (cws-accept buffer 0 30 major buffer 10 14))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-utf8-malformed-manual-source-offsets
  (dolist (entry '(((#x80) :utf8-leading 0) ((#xc0 #xaf) :utf8-leading 0)
                   ((#xff) :utf8-leading 0) ((#xf5 #x80 #x80 #x80) :utf8-leading 0)
                   ((#xc2) :utf8-truncated 1) ((#xe0 #xa0) :utf8-truncated 2)
                   ((#xf0 #x90 #x80) :utf8-truncated 3)
                   ((#xc2 #x41) :utf8-continuation 1)
                   ((#xe1 #x80 #x41) :utf8-continuation 2)
                   ((#xf1 #x80 #x80 #x41) :utf8-continuation 3)
                   ((#xe0 #x9f #xbf) :utf8-scalar 1) ((#xed #xa0 #x80) :utf8-scalar 1)
                   ((#xf0 #x8f #xbf #xbf) :utf8-scalar 1)
                   ((#xf4 #x90 #x80 #x80) :utf8-scalar 1)
                   ((#xe0 #x41) :utf8-truncated 2)
                   ((#xf0 #x41 #x80) :utf8-truncated 3)
                   ((#xe0 #x9f #x41) :utf8-continuation 2)
                   ((#xed #xa0 #x41) :utf8-continuation 2)
                   ((#xf4 #x90 #x80 #x41) :utf8-continuation 3)
                   ((#x41 #xc2 #xa2 #xff) :utf8-leading 3)))
    (destructuring-bind (contents reason offset) entry
      (dolist (prefix '(1 7 13))
        (multiple-value-bind (source ss se) (cws-literal-source contents :prefix prefix)
          (multiple-value-bind (buffer start end) (cws-destination (+ 9 (length contents)))
            (cws-reject buffer start end 3 source ss se
                        'corruption-detected reason (+ ss offset))
            (cws-accept buffer start end 2 source ss se)))))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-budget-capacity-overlap-before-utf8
  (let ((buffer (make-array 20 :element-type '(unsigned-byte 8) :initial-element #xff)))
    (cws-reject buffer 4 4 3 buffer 4 5 'resource-exhausted :cbor-string-byte-budget nil
                :max-bytes 0)
    (cws-reject buffer 4 4 3 buffer 4 5 'resource-exhausted :cbor-string-byte-budget nil
                :max-bytes 1)
    (cws-reject buffer 4 4 3 buffer 4 5 'resource-exhausted :cbor-string-capacity nil
                :max-bytes 2)
    (cws-reject buffer 4 6 3 buffer 4 5 'invalid-argument :cbor-string-overlap nil
                :max-bytes 2)
    (cws-reject buffer 0 2 3 buffer 4 5 'corruption-detected :utf8-leading 4
                :max-bytes 2)
    (cws-accept buffer 0 2 2 buffer 4 5 :max-bytes 2)))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-reuse-after-errors-and-concatenation
  (multiple-value-bind (source ss se) (cws-source 24)
    (multiple-value-bind (buffer start end) (cws-destination 60)
      (let ((bad (bytes #xff)))
        (cws-reject buffer start end 3 bad 0 1 'corruption-detected :utf8-leading 0))
      (cws-accept buffer start end 3 source ss se)
      (cws-reject buffer start start 2 source ss se 'resource-exhausted :cbor-string-capacity nil)
      (cws-accept buffer start end 2 source ss (+ ss 1))
      (let ((cursor start))
        (setf cursor (cws-accept buffer cursor end 3 source ss ss))
        (setf cursor (cws-accept buffer cursor end 2 source ss (+ ss 23)))
        (setf cursor (cws-accept buffer cursor end 3 source ss se))
        (is (= cursor (+ start 51)))))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-differential-fuzz-seed-53574342
  (let ((seed #x53574342) (accepted 0) (rejected 0))
    (flet ((advance () (setf seed (mod (+ (* seed 1664525) 1013904223) #x100000000))))
      (dotimes (sample 2048)
        (let* ((major (if (evenp sample) 2 3)) (prefix (1+ (mod (advance) 11)))
               (contents (if (and (= major 3) (= (mod sample 4) 1))
                             (utf8-encode-scalars
                              (loop repeat (mod (advance) 25) collect
                                (nth (mod (advance) 9) '(0 65 #x80 #x7ff #x800 #x20ac
                                                       #xfeff #x10000 #x10ffff))))
                             (let* ((length (mod (advance) 129))
                                    (data (make-array length :element-type '(unsigned-byte 8))))
                               (dotimes (i length) (setf (aref data i) (floor (advance) 16777216)))
                               data)))
               (dest-prefix (mod (advance) 18)) (slack (mod (advance) 8)))
          (multiple-value-bind (source ss se) (cws-literal-source contents :prefix prefix)
            (multiple-value-bind (buffer start end)
                (cws-destination (+ (length contents) 5 slack) :prefix dest-prefix)
              (if (cws-compare buffer start end major source ss se)
                  (incf accepted) (incf rejected)))))))
    (is (= (+ accepted rejected) 2048)) (is (plusp accepted)) (is (plusp rejected))
    (format t "  CBOR string write fuzz: seed53574342, 2048 casi, ~D accettati/~D UTF-8 rifiutati.~%"
            accepted rejected)))

;;; REQ: REQ-CBR-002 REQ-AFF-008
(deftest test-REQ-CBR-002-string-write-minimal-scan-supplement-after-cold-byte-check
  (dolist (major '(2 3))
    (let ((source (utf8-encode-scalars '(0 65 #x20ac #x10000 #x10ffff))))
      (multiple-value-bind (buffer start end) (cws-destination 32)
        (let* ((next (cws-accept buffer start end major source 0 (length source)))
               (values (multiple-value-list
                        (arcdocdb.cbor:verifica-struttura-cbor-minima
                         buffer start next (arcdocdb.cbor:crea-spazio-cbor)))))
          (is (= 3 (length values))) (is (equal (list 1 0 next) values)))))))
