(in-package #:arcdocdb.cbor.float.write.tests)

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-oracle-known-rationals-and-nan-padding
  (dolist (entry '((16 #x0001 :finite 0 1/16777216)
                   (16 #x03ff :finite 0 1023/16777216)
                   (16 #x0400 :finite 0 1/16384)
                   (16 #x3e00 :finite 0 3/2)
                   (16 #x7bff :finite 0 65504)
                   (16 #x8000 :zero 1 0) (16 #xfc00 :infinity 1 0)
                   (16 #x7c01 :nan 0 1)
                   (32 #x00000001 :finite 0 1/713623846352979940529142984724747568191373312)))
    (is (equal (subseq (cfw-description (second entry) (first entry)) 0 3)
               (subseq entry 2 5))))
  (is (= (cfw-encode (cfw-description #x7c01 16) 32) #x7f802000))
  (is (= (cfw-encode (cfw-description #x7e00 16) 64) #x7ff8000000000000))
  (is (= (cfw-encode (cfw-description #x3e00 16) 64) #x3ff8000000000000))
  (is (null (cfw-encode (cfw-description #x7fc00001 32) 16)))
  (is (null (cfw-encode (cfw-description #x7ff0000000000001 64) 32))))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-literal-zero-infinity-finite-and-nan-vectors
  (dolist (entry '((16 #x3e00 (#xf9 #x3e 0))
                   (32 #x3fc00000 (#xf9 #x3e 0))
                   (64 #x3ff8000000000000 (#xf9 #x3e 0))
                   (16 0 (#xf9 0 0)) (32 0 (#xf9 0 0)) (64 0 (#xf9 0 0))
                   (16 #x8000 (#xf9 #x80 0)) (32 #x80000000 (#xf9 #x80 0))
                   (64 #x8000000000000000 (#xf9 #x80 0))
                   (16 #x7c00 (#xf9 #x7c 0)) (32 #x7f800000 (#xf9 #x7c 0))
                   (64 #x7ff0000000000000 (#xf9 #x7c 0))
                   (16 #xfc00 (#xf9 #xfc 0)) (32 #xff800000 (#xf9 #xfc 0))
                   (64 #xfff0000000000000 (#xf9 #xfc 0))
                   (32 #x3f800001 (#xfa #x3f #x80 0 1))
                   (64 #x3ff0000020000000 (#xfa #x3f #x80 0 1))
                   (64 #x3ff0000000000001 (#xfb #x3f #xf0 0 0 0 0 0 1))
                   (32 1 (#xfa 0 0 0 1))
                   (64 1 (#xfb 0 0 0 0 0 0 0 1))
                   (64 #x36a0000000000000 (#xfa 0 0 0 1))
                   (16 #x7c01 (#xf9 #x7c 1))
                   (32 #x7f802000 (#xf9 #x7c 1))
                   (64 #x7ff0040000000000 (#xf9 #x7c 1))
                   (32 #x7f800001 (#xfa #x7f #x80 0 1))
                   (64 #x7ff0000020000000 (#xfa #x7f #x80 0 1))
                   (64 #x7ff0000000000001 (#xfb #x7f #xf0 0 0 0 0 0 1))
                   (16 #xfe01 (#xf9 #xfe 1))
                   (32 #xffc02000 (#xf9 #xfe 1))
                   (64 #xfff8040000000000 (#xf9 #xfe 1))))
    (cfw-probe (first entry) (second entry) (third entry))))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-all-65536-half-and-exact-expansions
  (let ((accepted 0) (rejected 0))
    (dotimes (bits 65536)
      (let* ((description (cfw-description bits 16))
             (wide32 (cfw-encode description 32)) (wide64 (cfw-encode description 64))
             (inputs (list (cfw-input 16 bits) (cfw-input 32 wide32) (cfw-input 64 wide64)))
             ;; L'output half e letterale rispetto alla sua codifica input, senza riduttore.
             (wire (list #xf9 (floor bits 256) (mod bits 256)))
             (prefix (nth (mod bits 8) *cfw-offsets*))
             (configuration (nth (mod bits 3) '((0 0) (0 11) (7 11)))))
        (is (integerp wide32)) (is (integerp wide64))
        (is (cfw-same-description-p description (cfw-description wide32 32)))
        (is (cfw-same-description-p description (cfw-description wide64 64)))
        (dolist (input inputs)
          (destructuring-bind (ai high low) input
            (destructuring-bind (slack suffix) configuration
              (multiple-value-bind (buffer start end)
                  (cfw-destination (+ 3 slack) :prefix prefix :suffix suffix)
                (cfw-accept buffer start end ai high low wire) (incf accepted)))))
        ;; Ogni half prova tutte le capacita 0/1/2; AI25/26/27 ruotano per capacita.
        (dotimes (capacity 3)
          (destructuring-bind (ai high low) (nth (mod (+ bits capacity) 3) inputs)
            (multiple-value-bind (buffer start end)
                (cfw-destination capacity :prefix prefix :suffix 19)
              (cfw-reject buffer start end ai high low 'resource-exhausted :cbor-float-capacity)
              (incf rejected))))))
    (is (= accepted 196608)) (is (= rejected 196608))
    (format t "  CBOR float write: 65536 half, 131072 espansioni; 196608 successi e 196608 capacita insufficienti, otto offset e tre configurazioni ruotati.~%")))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-finite-normal-subnormal-boundaries-and-adjacencies
  (dolist (format '((32 #x00000001 #x007fffff #x00800000 #x33000000 #x33800000
                     #x387fc000 #x38800000 #x477fe000 #x47800000 #x7f7fffff)
                    (64 #x0000000000000001 #x000fffffffffffff #x0010000000000000
                     #x3680000000000000 #x36a0000000000000 #x380fffffc0000000
                     #x3810000000000000 #x47efffffe0000000 #x47f0000000000000
                     #x7fefffffffffffff)))
    (let ((size (first format)))
      (dolist (center (rest format))
        (dolist (bits (cfw-neighbors center size))
          (dolist (signed (list bits (+ bits (expt 2 (1- size)))))
            (cfw-probe size signed))))))
  (dolist (pair '((16 32) (32 64)))
    (let* ((small (first pair)) (large (second pair))
           (centers (if (= small 16) '(1 1023 1024 15360 31743)
                        '(1 8388607 8388608 1065353216 2139095039))))
      (dolist (bits centers)
        (let ((wide (cfw-encode (cfw-description bits small) large)))
          (dolist (neighbor (cfw-neighbors wide large))
            (dolist (signed (list neighbor (+ neighbor (expt 2 (1- large)))))
              (cfw-probe large signed))))))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-binary64-subnormal-alignment-across-words
  (flet ((probe (value expected-size)
           (dolist (sign '(0 1))
             (let* ((description (list (if (zerop value) :zero :finite) sign value 52))
                    (bits (cfw-encode description 64))
                    (input (cfw-input 64 bits)) (wire (apply #'cfw-reference input)))
               (is (= (length wire) expected-size)) (cfw-probe 64 bits)))))
    (let ((base (expt 2 -129)))
      (probe base 5) (probe (+ base (expt 2 -181)) 9) (probe (+ base (expt 2 -149)) 5))
    (let ((base (expt 2 -130)))
      (probe base 5) (probe (+ base (expt 2 -182)) 9)
      (probe (+ base (expt 2 -150)) 9) (probe (+ base (expt 2 -149)) 5))
    (let ((base (expt 2 -149)))
      (probe base 5) (probe (+ base (expt 2 -201)) 9) (probe (+ base (expt 2 -169)) 9))
    (probe 0 3) (probe (expt 2 -1074) 9) (probe (expt 2 -1042) 9)))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-nan-signaling-quiet-payload-all-alignments
  (dolist (format '((32 13) (64 29) (64 42)))
    (let* ((size (first format)) (shift (second format))
           (e (first (cfw-format size))) (p (second (cfw-format size)))
           (base (* (1- (expt 2 e)) (expt 2 p))))
      (dolist (payload (remove-duplicates
                       (list 1 (1- (expt 2 shift)) (expt 2 shift) (1+ (expt 2 shift))
                             (expt 2 (1- p)) (1+ (expt 2 (1- p)))
                             (1- (expt 2 p)))))
        (dolist (sign '(0 1))
          (cfw-probe size (+ (* sign (expt 2 (1- size))) base payload)))))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-invalid-ai-types-and-all-octet-values
  (dolist (ai (append (loop for value below 256 unless (member value '(25 26 27)) collect value)
                     (list -1 256 nil t #\A 25.0 26d0 25/2 #c(25 1) '(25) #(25)
                           (expt 2 128) (- (expt 2 128)))))
    (dolist (capacity '(0 3 9))
      (multiple-value-bind (buffer start end) (cfw-destination capacity)
        (cfw-reject buffer start end ai nil nil 'invalid-argument :cbor-float-ai)))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-invalid-high-and-low-types-and-u32-bounds
  (let ((bad (list -1 4294967296 nil t #\A 0.0 1d0 1/2 #c(1 1) '(0) #(0)
                   (expt 2 128) (- (expt 2 128)))))
    (dolist (ai '(25 26 27))
      (dolist (value bad)
        (dolist (capacity '(0 3 9))
          (multiple-value-bind (buffer start end) (cfw-destination capacity)
            (cfw-reject buffer start end ai value nil 'invalid-argument :cbor-float-high)
            (cfw-reject buffer start end ai 0 value 'invalid-argument :cbor-float-low)))))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-incoherent-width-words-before-capacity
  (dolist (input '((25 1 0) (25 4294967295 65535) (26 1 0) (26 4294967295 4294967295)
                   (25 0 65536) (25 0 4294967295)))
    (dolist (capacity '(0 3 5 9))
      (multiple-value-bind (buffer start end) (cfw-destination capacity)
        (destructuring-bind (ai high low) input
          (cfw-reject buffer start end ai high low 'invalid-argument :cbor-float-words))))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-preflight-precedence-chain
  (multiple-value-bind (buffer start end) (cfw-destination 0)
    (cfw-reject buffer -1 end nil nil nil 'invalid-argument :cbor-range)
    (cfw-reject buffer start end nil nil nil 'invalid-argument :cbor-float-ai)
    (cfw-reject buffer start end 25 nil nil 'invalid-argument :cbor-float-high)
    (cfw-reject buffer start end 25 1 nil 'invalid-argument :cbor-float-low)
    (cfw-reject buffer start end 25 1 65536 'invalid-argument :cbor-float-words)
    (cfw-reject buffer start end 25 0 65535 'resource-exhausted :cbor-float-capacity)))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-invalid-ranges-before-all-value-errors
  (let ((buffer (bytes #xa7 #xb8 #xc9 #xda #xeb #xfc)))
    (dolist (span (list '(-1 1) '(0 -1) '(2 1) '(0 7) '(7 7) '(7 6)
                       '(nil 1) '(0 nil) '(t 1) '(0 t) '(1/2 2) '(0 3/2)
                       '(0.0 2) '(0 2d0) (list (expt 2 100) 6)
                       (list 0 (expt 2 100))))
      (dolist (input '((25 0 0) (27 4294967295 4294967295) (nil nil nil) (25 1 nil)))
        (destructuring-bind (ai high low) input
          (cfw-reject buffer (first span) (second span) ai high low
                      'invalid-argument :cbor-range))))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-non-simple-destinations-and-whole-displaced-backing
  (dolist (buffer (list nil '(167 168 169) #(167 168 169) "abc" #*101
                       (make-array 3 :element-type '(unsigned-byte 16) :initial-element 167)
                       (make-array '(1 3) :element-type '(unsigned-byte 8) :initial-element 167)
                       (make-array 3 :element-type '(unsigned-byte 8) :initial-element 167 :adjustable t)
                       (make-array 7 :element-type '(unsigned-byte 8) :initial-element 167 :fill-pointer 3)))
    (dolist (input '((25 0 0) (27 4294967295 4294967295) (nil nil nil)))
      (destructuring-bind (ai high low) input
        (cfw-reject buffer 0 2 ai high low 'invalid-argument :cbor-range))))
  (let* ((backing (bytes 11 22 33 44 55 66 77 88 99)) (before (copy-seq backing))
         (view (make-array 4 :element-type '(unsigned-byte 8) :displaced-to backing
                              :displaced-index-offset 3)))
    (unwind-protect
         (dolist (input '((25 0 0) (27 4294967295 4294967295) (nil nil nil)))
           (destructuring-bind (ai high low) input
             (cfw-reject view 0 2 ai high low 'invalid-argument :cbor-range)
             (is (equalp before backing))))
      (is (equalp before backing)))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-empty-span-and-zero-length-destination
  (dolist (physical-size '(0 1 3 9 17))
    (let ((buffer (make-array physical-size :element-type '(unsigned-byte 8) :initial-element #x91)))
      (dolist (point (remove-duplicates (list 0 (floor physical-size 2) physical-size)))
        (dolist (input '((25 0 0) (26 0 1065353217) (27 1072693248 1)))
          (destructuring-bind (ai high low) input
            (cfw-reject buffer point point ai high low 'resource-exhausted :cbor-float-capacity)))
        (cfw-reject buffer point point nil nil nil 'invalid-argument :cbor-float-ai)
        (cfw-reject buffer point point 25 1 0 'invalid-argument :cbor-float-words)))))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-reuse-after-errors-and-shorter-success
  (multiple-value-bind (buffer start end) (cfw-destination 12)
    (cfw-reject buffer start end 25 1 0 'invalid-argument :cbor-float-words)
    (cfw-accept buffer start end 27 #x3ff00000 1)
    (cfw-reject buffer start (+ start 8) 27 #x3ff00000 1 'resource-exhausted :cbor-float-capacity)
    (cfw-accept buffer start end 26 0 #x3f800001)
    (cfw-reject buffer (1+ start) start nil nil nil 'invalid-argument :cbor-range)
    (cfw-accept buffer start end 27 #xfff80400 0)
    (cfw-accept buffer start end 25 0 0)))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-concatenation-of-reduced-and-retained-forms
  (let* ((inputs '((25 0 15872) (27 1073217536 0) (26 0 1065353217) (27 1072693248 1)
                   (26 0 1) (27 916455424 0) (27 2146435072 536870912) (27 4294444032 0)))
         (wire (loop for input in inputs append (apply #'cfw-reference input))))
    (is (= (length wire) 38))
    (multiple-value-bind (buffer start end) (cfw-destination (+ 38 7) :prefix 11)
      (let ((expected (copy-seq buffer)) (next start))
        (replace expected wire :start1 start)
        (dolist (input inputs)
          (destructuring-bind (ai high low) input
            (setf next (cfw-accept buffer next end ai high low))))
        (is (= next (+ start 38))) (is (equalp expected buffer))))))

;;; REQ: REQ-CBR-004 REQ-AFF-008
(deftest test-REQ-CBR-004-float-write-fixed-seed-2048-fuzz
  (let ((state #x464c5434) (counts (vector 0 0 0 0 0 0 0)))
    (labels ((advance () (setf state (mod (+ (* state 1664525) 1013904223) 4294967296)))
             (draw (limit) (mod (floor (advance) 65536) limit)))
      (dotimes (iteration 2048)
        (let* ((group (mod iteration 16)) (prefix (draw 32)) (suffix (+ 3 (draw 9)))
               (size (nth (draw 3) '(16 32 64)))
               (bits (case size (16 (draw 65536)) (32 (advance))
                           (64 (+ (* (advance) 4294967296) (advance)))))
               (input (cfw-input size bits)) (wire (apply #'cfw-reference input)))
          (case group
            ((0 1 2 3 11 12)
             (setf input
                   (case group
                     (0 (cfw-input 16 (draw 65536)))
                     (1 (cfw-input 32 (advance)))
                     (2 (cfw-input 64 (+ (* (advance) 4294967296) (advance))))
                     (3 (cfw-input 64 (cfw-encode (cfw-description (draw 65536) 16) 64)))
                     (11 (list 27 #x3ff00000 (1+ (* 2 (draw 2147483648)))))
                     (12 (list 27 (+ #x7ff00000 (draw 1048576)) (1+ (* 2 (draw 2147483648)))))))
             (setf wire (apply #'cfw-reference input))
             (multiple-value-bind (buffer start end)
                 (cfw-destination (+ (length wire) (draw 8)) :prefix prefix :suffix suffix)
               (destructuring-bind (ai high low) input
                 (cfw-accept buffer start end ai high low wire)) (incf (svref counts 0))))
            ((4 14)
             (multiple-value-bind (buffer start end)
                 (cfw-destination (draw (length wire)) :prefix prefix :suffix suffix)
               (destructuring-bind (ai high low) input
                 (cfw-reject buffer start end ai high low 'resource-exhausted :cbor-float-capacity))
               (incf (svref counts 1))))
            ((5 6 7 8 13)
             (multiple-value-bind (buffer start end)
                 (cfw-destination (draw 12) :prefix prefix :suffix suffix)
               (case group
                 (5 (cfw-reject buffer start end
                                (nth (draw 8) '(nil t -1 24 28 25.0 25/2 #\A)) nil nil
                                'invalid-argument :cbor-float-ai) (incf (svref counts 2)))
                 (6 (cfw-reject buffer start end 25
                                (nth (draw 8) '(nil t -1 4294967296 0.0 1/2 #\A :high)) nil
                                'invalid-argument :cbor-float-high) (incf (svref counts 3)))
                 (7 (cfw-reject buffer start end 25 1
                                (nth (draw 8) '(nil t -1 4294967296 0.0 1/2 #\A :low))
                                'invalid-argument :cbor-float-low) (incf (svref counts 4)))
                 (8 (cfw-reject buffer start end 26 (1+ (draw 4294967295)) (advance)
                                'invalid-argument :cbor-float-words) (incf (svref counts 5)))
                 (13 (cfw-reject buffer start end 25 0 (+ 65536 (draw 65536))
                                 'invalid-argument :cbor-float-words) (incf (svref counts 5))))))
            ((9 15)
             (multiple-value-bind (buffer start end)
                 (cfw-destination 12 :prefix prefix :suffix suffix)
               (let ((span (nth (draw 4) (list (list -1 end) (list start (1+ (length buffer)))
                                             (list (1+ start) start) (list nil end)))))
                 (cfw-reject buffer (first span) (second span) nil nil nil 'invalid-argument :cbor-range)
                 (incf (svref counts 6)))))
            (10
             (let ((buffer (case (draw 4) (0 (vector 11 22 33)) (1 "abc")
                                 (2 (make-array 3 :element-type '(unsigned-byte 8) :adjustable t
                                                :initial-element 11))
                                 (3 (make-array 7 :element-type '(unsigned-byte 8) :fill-pointer 3
                                                :initial-element 11)))))
               (cfw-reject buffer 0 2 nil nil nil 'invalid-argument :cbor-range)
               (incf (svref counts 6))))))))
    (is (equalp counts #(768 256 128 128 128 256 384)))
    (format t "  CBOR float write: fuzz seed464C5434, 2048 casi: ~D successi, ~D capacita, ~D AI, ~D HIGH, ~D LOW, ~D parole, ~D range/destinazioni rifiutati.~%"
            (svref counts 0) (svref counts 1) (svref counts 2) (svref counts 3)
            (svref counts 4) (svref counts 5) (svref counts 6))))

;;; REQ: REQ-CBR-004
(deftest test-REQ-CBR-004-float-write-reader-and-scanner-only-after-cold-comparison
  (let ((workspace (arcdocdb.cbor:crea-spazio-cbor)))
    (dolist (entry '((16 #x3e00) (32 #x3fc00000) (64 #x3ff8000000000000)
                     (32 #x3f800001) (64 #x3ff0000000000001)
                     (32 1) (64 1) (16 #xfc00) (64 #x7ff0000020000000)
                     (64 #xfff8040000000000) (64 #x7ff0000000000001)))
      (destructuring-bind (ai high low) (cfw-input (first entry) (second entry))
        (let ((wire (cfw-reference ai high low)))
          (multiple-value-bind (buffer start end) (cfw-destination 12 :prefix 5)
            (let* ((next (cfw-accept buffer start end ai high low wire)) (before (copy-seq buffer))
                   (out-ai (- (first wire) 224))
                   (out-bits (reduce (lambda (value octet) (+ (* value 256) octet))
                                     (rest wire) :initial-value 0))
                   (header (multiple-value-list
                            (arcdocdb.cbor:leggi-header-cbor-minimo buffer start next)))
                   (scan (multiple-value-list
                          (arcdocdb.cbor:verifica-struttura-cbor-minima buffer start next workspace))))
              (is (equal header (list 7 out-ai (floor out-bits 4294967296)
                                      (mod out-bits 4294967296) next :argument)))
              (is (= 6 (length header))) (is (= 3 (length scan)))
              (is (equal scan (list 1 0 next))) (is (equalp before buffer)))))))))
