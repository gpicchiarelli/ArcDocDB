(in-package #:arcdocdb.cbor.simple.write.tests)

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-literal-vectors
  (dolist (fixture '((0 #xe0) (19 #xf3) (20 #xf4) (21 #xf5)
                    (22 #xf6) (23 #xf7) (32 #xf8 #x20) (255 #xf8 #xff)))
    (multiple-value-bind (buffer start end) (csw-destination 7)
      (csw-accept buffer start end (first fixture) (rest fixture)))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-all-248-codes-offsets-and-residuals
  (let ((count 0))
    (dotimes (position 248)
      (let* ((value (csw-value-at position)) (size (length (csw-reference value))))
        (dolist (prefix *csw-offsets*)
          (dolist (span '((0 0) (0 9) (5 9)))
            (destructuring-bind (slack suffix) span
              (multiple-value-bind (buffer start end)
                  (csw-destination (+ size slack) :prefix prefix :suffix suffix)
                (csw-accept buffer start end value) (incf count)))))))
    (is (= count 5952))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-every-insufficient-capacity-and-physical-suffix
  (let ((count 0))
    (dotimes (position 248)
      (let* ((value (csw-value-at position)) (size (length (csw-reference value))))
        (dolist (prefix *csw-offsets*)
          (dotimes (capacity size)
            (multiple-value-bind (buffer start end)
                (csw-destination capacity :prefix prefix :suffix 11)
              (csw-reject buffer start end value 'resource-exhausted :cbor-simple-capacity)
              (incf count))))))
    (is (= count 3776))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-all-eight-reserved-before-capacity
  (let ((count 0))
    (loop for value from 24 to 31 do
      (dolist (prefix *csw-offsets*)
        (dolist (capacity '(0 1 2 7))
          (multiple-value-bind (buffer start end) (csw-destination capacity :prefix prefix)
            (csw-reject buffer start end value 'invalid-argument :cbor-simple-value)
            (incf count)))))
    (is (= count 256))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-invalid-value-types-and-bounds
  (dolist (value (list -1 -256 256 257 nil t :false #\A 20.0 23d0 23/2
                      #c(20 1) (expt 2 128) (- (expt 2 128)) '(20) #(20)))
    (dolist (capacity '(0 1 2 7))
      (multiple-value-bind (buffer start end) (csw-destination capacity)
        (csw-reject buffer start end value 'invalid-argument :cbor-simple-value)))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-invalid-ranges-dominate-value-and-capacity
  (let ((buffer (bytes #xa7 #xb8 #xc9 #xda #xeb #xfc)))
    (dolist (span (list '(-1 1) '(0 -1) '(2 1) '(0 7) '(7 7) '(7 6)
                       '(nil 1) '(0 nil) '(t 1) '(0 t) '(1/2 2) '(0 3/2)
                       '(0.0 2) '(0 2d0) (list (expt 2 100) 6)
                       (list 0 (expt 2 100))))
      (dolist (value '(0 255 24 nil))
        (csw-reject buffer (first span) (second span) value 'invalid-argument :cbor-range)))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-non-simple-destinations
  (dolist (buffer (list nil '(167 168 169) #(167 168 169) "abc" #*101
                       (make-array 3 :element-type '(unsigned-byte 16) :initial-element 167)
                       (make-array '(1 3) :element-type '(unsigned-byte 8) :initial-element 167)
                       (make-array 3 :element-type '(unsigned-byte 8) :initial-element 167
                                     :adjustable t)
                       (make-array 7 :element-type '(unsigned-byte 8) :initial-element 167
                                     :fill-pointer 3)))
    (dolist (value '(0 255 24 nil))
      (csw-reject buffer 0 2 value 'invalid-argument :cbor-range))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-displaced-view-and-whole-backing-unchanged
  (let* ((backing (bytes 11 22 33 44 55 66 77 88 99)) (before (copy-seq backing))
         (view (make-array 4 :element-type '(unsigned-byte 8) :displaced-to backing
                              :displaced-index-offset 3)))
    (unwind-protect
         (dolist (value '(0 255 24 nil))
           (csw-reject view 0 2 value 'invalid-argument :cbor-range)
           (is (equalp before backing)))
      (is (equalp before backing)))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-empty-spans-and-zero-length-array
  (dolist (physical-size '(0 1 2 17))
    (let ((buffer (make-array physical-size :element-type '(unsigned-byte 8)
                                           :initial-element #x91)))
      (dolist (point (remove-duplicates (list 0 (floor physical-size 2) physical-size)))
        (dolist (value '(0 23 32 255))
          (csw-reject buffer point point value 'resource-exhausted :cbor-simple-capacity))
        (dolist (value '(24 31 nil))
          (csw-reject buffer point point value 'invalid-argument :cbor-simple-value))))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-start-zero-and-exact-physical-end
  (dolist (value '(0 19 20 21 22 23 32 255))
    (multiple-value-bind (buffer start end)
        (csw-destination (length (csw-reference value)) :prefix 0 :suffix 0)
      (is (= (length buffer) (csw-accept buffer start end value))))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-reuse-after-errors-and-success
  (multiple-value-bind (buffer start end) (csw-destination 7)
    (csw-reject buffer start end 24 'invalid-argument :cbor-simple-value)
    (csw-accept buffer start end 23)
    (csw-reject buffer start (1+ start) 255 'resource-exhausted :cbor-simple-capacity)
    (csw-accept buffer start end 255)
    (csw-reject buffer (1+ start) start nil 'invalid-argument :cbor-range)
    (csw-accept buffer start end 0)
    (csw-accept buffer start end 32)))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-concatenation-of-all-codes
  (let ((wire (loop for position below 248 append (csw-reference (csw-value-at position)))))
    (is (= 472 (length wire)))
    (multiple-value-bind (buffer start end) (csw-destination (+ 472 7) :prefix 11)
      (let ((expected (copy-seq buffer)) (next start))
        (replace expected wire :start1 start)
        (dotimes (position 248)
          (setf next (csw-accept buffer next end (csw-value-at position))))
        (is (= next (+ start 472))) (is (equalp expected buffer))))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-exact-single-result-for-all-codes
  (dotimes (position 248)
    (let* ((value (csw-value-at position)) (size (length (csw-reference value))))
      (multiple-value-bind (buffer start end) (csw-destination size :prefix 5)
        (csw-accept buffer start end value)))))

;;; REQ: REQ-CBR-003 REQ-AFF-008
(deftest test-REQ-CBR-003-simple-write-fixed-seed-2048-fuzz
  (let ((state #x53494d43) (counts (vector 0 0 0 0)))
    (labels ((draw (limit)
               (setf state (mod (+ (* state 1664525) 1013904223) 4294967296))
               (mod (floor state 65536) limit)))
      (dotimes (iteration 2048)
        (let* ((group (mod iteration 8)) (prefix (draw 32)) (suffix (+ 3 (draw 9)))
               (value (csw-value-at (draw 248))) (size (length (csw-reference value)))
               (slack (draw 8)))
          (case group
            ((0 1 7)
             (when (= group 1) (setf value (draw 24)))
             (when (= group 7) (setf value (+ 32 (draw 224))))
             (setf size (length (csw-reference value)))
             (multiple-value-bind (buffer start end)
                 (csw-destination (+ size slack) :prefix prefix :suffix suffix)
               (csw-accept buffer start end value) (incf (svref counts 0))))
            ((2 3)
             (setf value (if (= group 2) (+ 24 (draw 8))
                             (nth (draw 8) '(nil t -1 256 20.0 23/2 #\A :false))))
             (multiple-value-bind (buffer start end)
                 (csw-destination (draw 4) :prefix prefix :suffix suffix)
               (csw-reject buffer start end value 'invalid-argument :cbor-simple-value)
               (incf (svref counts 1))))
            (4
             (multiple-value-bind (buffer start end)
                 (csw-destination (draw size) :prefix prefix :suffix suffix)
               (csw-reject buffer start end value 'resource-exhausted :cbor-simple-capacity)
               (incf (svref counts 2))))
            (5
             (multiple-value-bind (buffer start end)
                 (csw-destination (+ size slack) :prefix prefix :suffix suffix)
               (let ((span (nth (draw 4) (list (list -1 end) (list start (1+ (length buffer)))
                                                   (list (1+ start) start) (list nil end)))))
                 (csw-reject buffer (first span) (second span) 24 'invalid-argument :cbor-range)
                 (incf (svref counts 3)))))
            (6
             (let ((buffer (case (draw 4)
                             (0 (vector 11 22 33)) (1 (bytes 11 22 33))
                             (2 (make-array 3 :element-type '(unsigned-byte 8)
                                              :initial-element 11 :adjustable t))
                             (3 "abc"))))
               ;; Il caso simple u8 ha un range invalido; gli altri falliscono sul tipo.
               (csw-reject buffer 0 (if (typep buffer '(simple-array (unsigned-byte 8) (*))) 4 2)
                           nil 'invalid-argument :cbor-range)
               (incf (svref counts 3))))))))
    (is (equalp counts #(768 512 256 512)))
    (format t "  CBOR simple write: fuzz seed 53494D43, 2048 casi: ~D successi, ~D valori, ~D capacita, ~D destinazioni/range rifiutati.~%"
            (svref counts 0) (svref counts 1) (svref counts 2) (svref counts 3))))

;;; REQ: REQ-CBR-003
(deftest test-REQ-CBR-003-simple-write-reader-and-scanner-after-cold-bytes
  (let ((workspace (arcdocdb.cbor:crea-spazio-cbor)))
    (dotimes (position 248)
      (let ((value (csw-value-at position)))
        (multiple-value-bind (buffer start end) (csw-destination 7 :prefix 5)
          (let* ((next (csw-accept buffer start end value)) (before (copy-seq buffer))
                 (header (multiple-value-list
                          (arcdocdb.cbor:leggi-header-cbor-minimo buffer start next)))
                 (scan (multiple-value-list
                        (arcdocdb.cbor:verifica-struttura-cbor-minima buffer start next workspace))))
            (is (= 6 (length header)))
            (is (equal header (list 7 (if (< value 24) value 24) 0 value next :argument)))
            (is (= 3 (length scan))) (is (equal scan (list 1 0 next)))
            (is (equalp before buffer))))))))
