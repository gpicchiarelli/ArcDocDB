(in-package #:arcdocdb.hash64.tests)

;;; Vettori NOTI, non calcolati dal prodotto o dall'oracolo:
;;; https://raw.githubusercontent.com/Cyan4973/xxHash/v0.8.3/cli/xsum_sanity_check.c
;;; XSUM_XXH64_testdata e XSUM_fillTestBuffer, release v0.8.3.
;;; Colonne: lunghezza, seed-low (seed-high=0), digest-high, digest-low.
(defparameter *hash-upstream-vectors*
  '((0 0 #xef46db37 #x51d8e999)
    (0 #x9e3779b1 #xac75fda2 #x929b17ef)
    (1 0 #xe934a84a #xdb052768)
    (1 #x9e3779b1 #x50146076 #x43a9b4c3)
    (4 0 #x9136a0dc #xa57457ee)
    (14 0 #x8282dcc4 #x994e35c8)
    (14 #x9e3779b1 #xc3bd6bf6 #x3deb6df0)
    (222 0 #xb641ae8c #xb691c174)
    (222 #x9e3779b1 #x20cb8ab7 #xae10c14a)))

(defun hash-upstream-buffer (size)
  "Ricostruzione aritmetica della fixture upstream; nessuna implementazione C."
  (let ((state 2654435761)
        (buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf (aref buffer i) (floor state 72057594037927936)
            state (mod (* state 11400714785074694797) 18446744073709551616)))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-oracle-upstream-anchors
  ;; Ancoraggio separato: un difetto dell'oracolo non diventa un atteso del prodotto.
  (dolist (entry *hash-upstream-vectors*)
    (destructuring-bind (size low high-result low-result) entry
      (let* ((buffer (hash-upstream-buffer size)) (before (copy-seq buffer)))
        (is (equal (list high-result low-result)
                   (hash-reference buffer 0 size 0 low)))
        (is (equalp buffer before))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
;;; PROBE: round rotate 31 -> 30. Upstream 222 ha stripe e tail 30;
;;; gli ulteriori span 8/32/40/64/72/96 isolano lane da 8 e stripe da 32.
(deftest TEST-REQ-IDX-001-HASH-VECTORS
  (let ((cases 0))
    (dolist (entry *hash-upstream-vectors*)
      (destructuring-bind (size low high-result low-result) entry
        (let ((contents (hash-upstream-buffer size)))
          (dotimes (offset 32)
            (multiple-value-bind (buffer start end) (hash-fixture contents :prefix offset)
              (hash-accept buffer start end 0 low (list high-result low-result))
              (incf cases))))))
    (dolist (size '(8 32 40 64 72 96))
      (incf cases (hash-check-offset-matrix (hash-upstream-buffer size) *hash-seeds*)))
    (is (= cases 1824))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
;;; PROBE: seed-high ignorato, con seed-low identico in ogni coppia.
(deftest TEST-REQ-IDX-001-HASH-SEED-HIGH
  (let ((cases 0))
    (dolist (size '(0 1 8 31 32 64 65 65535))
      (let ((contents (hash-corpus-bytes size)))
        (dolist (low '(0 1 #xffffffff #x89abcdef))
          (let ((zero (hash-reference contents 0 size 0 low))
                (maximum (hash-reference contents 0 size #xffffffff low)))
            ;; Proprieta verificata su queste fixture finite, non promessa anticollisione.
            (is (not (equal zero maximum)))
            (dolist (offset '(0 31))
              (multiple-value-bind (buffer start end) (hash-fixture contents :prefix offset)
                (hash-accept buffer start end 0 low zero)
                (hash-accept buffer start end #xffffffff low maximum)
                (incf cases 2)))))))
    (is (= cases 128))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
;;; PROBE: length mix omesso; byte tutti zero, incluso span vuoto legale.
(deftest TEST-REQ-IDX-001-HASH-LENGTH
  (let ((cases 0))
    (loop for size from 0 to 65
          do (incf cases
                   (hash-check-offset-matrix
                    (make-array size :element-type '(unsigned-byte 8) :initial-element 0)
                    *hash-seeds* '(0 1 31))))
    (is (= cases 1584))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
;;; PROBE: ultimo byte loop omesso. Ogni tail 0..31, sotto/sopra una stripe,
;;; tutte le lunghezze 0..128, ogni offset 0..31, otto semi espliciti.
(deftest TEST-REQ-IDX-001-HASH-TAIL
  (let ((cases 0))
    (loop for size from 0 to 128
          do (incf cases (hash-check-offset-matrix (hash-corpus-bytes size) *hash-seeds*)))
    (is (= cases 33024))))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
;;; PROBE: merge del quarto accumulatore omesso. Esatti 32/64 e quarta lane
;;; asimmetrica, stripe multiple, tail, tutti gli offset e semi.
(deftest TEST-REQ-IDX-001-HASH-BLOCKS
  (let ((cases 0))
    (dolist (size '(32 33 63 64 65 95 96 97 127 128 129 255 256 257 65504 65535))
      (incf cases (hash-check-offset-matrix (hash-corpus-bytes size #x7632beef)
                                           *hash-seeds*)))
    (is (= cases 4096))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-empty-spans-at-buffer-edges
  (let ((buffer (hash-corpus-bytes 65568)) (empty (hash-octets)) (cases 0))
    (dolist (seed *hash-seeds*)
      (destructuring-bind (high low) seed
        (let ((expected (hash-reference empty 0 0 high low)))
          (hash-accept empty 0 0 high low expected)
          (incf cases)
          (dolist (position '(0 1 31 32 65535 65536 65568))
            (hash-accept buffer position position high low expected)
            (incf cases)))))
    (is (= cases 64))))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-all-tails-at-span-ceiling
  (let ((cases 0))
    (loop for size from 65504 to 65535
          do (incf cases (hash-check-offset-matrix (hash-corpus-bytes size) *hash-seeds*)))
    (is (= cases 8192))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-boundaries-32-8-4-through-65k
  (let ((cases 0))
    (dolist (boundary '(128 256 512 1024 4096 16384 32768))
      (dolist (delta '(-9 -8 -7 -5 -4 -3 -1 0 1 3 4 5 7 8 9))
        (incf cases
              (hash-check-offset-matrix (hash-corpus-bytes (+ boundary delta))
                                        *hash-seeds* '(0 1 7 15 31)))))
    (is (= cases 4200))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-all-256-single-octets
  (dotimes (byte 256)
    (hash-check-offset-matrix (hash-octets byte) *hash-seeds* (list (mod byte 32)))))

(defun hash-pattern-bytes (size pattern)
  (let ((buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf (aref buffer i)
            (ecase pattern
              (0 0) (1 255) (2 (mod i 256)) (3 (- 255 (mod i 256)))
              (4 (if (evenp i) #x55 #xaa))
              (5 (mod (+ (* (floor i 8) 73) (* i 17) 19) 256)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-zero-ff-ordered-and-asymmetric-lanes
  (let ((cases 0))
    (dotimes (pattern 6)
      (dolist (size '(0 1 3 4 7 8 15 16 23 24 31 32 33 63 64 65 255 256 257 65535))
        (incf cases (hash-check-offset-matrix (hash-pattern-bytes size pattern)
                                             *hash-seeds* (list (mod (+ pattern size) 32))))))
    (is (= cases 960))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-outside-span-differs-and-all-bytes-stay-unchanged
  (let ((cases 0))
    (dolist (size (append (loop for i from 0 to 65 collect i) '(255 256 257 65535)))
      (let* ((contents (hash-corpus-bytes size #x5564abcd))
             (expected (loop for (high low) in *hash-seeds*
                             collect (hash-reference contents 0 size high low))))
        (dotimes (offset 32)
          (multiple-value-bind (a start end)
              (hash-fixture contents :prefix offset :suffix 31 :guard #xaa)
            (multiple-value-bind (b other-start other-end)
                (hash-fixture contents :prefix offset :suffix 63 :guard #x55)
              (is (= start other-start)) (is (= end other-end))
              (is (not (equalp a b)))
              (loop for (high low) in *hash-seeds* for digest in expected
                    do (hash-accept a start end high low digest)
                       (hash-accept b start end high low digest)
                       (incf cases 2)))))))
    (is (= cases 35840))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-seed-and-call-history-have-no-state
  (multiple-value-bind (buffer start end) (hash-fixture (hash-corpus-bytes 257) :prefix 7)
    (let ((expected (loop for (high low) in *hash-seeds*
                          collect (hash-reference buffer start end high low)))
          (cases 0))
      (dotimes (round 16)
        (loop for (high low) in *hash-seeds* for digest in expected for index from 0
              do (hash-accept buffer start end high low digest)
                 (let* ((other-start (+ start (mod (+ round index) 32)))
                        (other-end (+ other-start (mod (+ (* round 5) index) 66)))
                        (other-seed (nth (mod (1+ index) 8) *hash-seeds*)))
                   (hash-compare-reference buffer other-start other-end
                                           (first other-seed) (second other-seed)))
                 (hash-accept buffer start end high low digest)
                 (incf cases 3)))
      (is (= cases 384)))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-finite-corpus-fixed-seed-6483beef
  (let ((state #x6483beef) (cases 0))
    (flet ((advance () (setf state (mod (+ (* state 1664525) 1013904223) 4294967296))))
      (dotimes (sample 256)
        (let* ((draw (advance))
               (anchors '(0 65535 32 8 4 31 33 7 9 3 5))
               (size (if (< sample (length anchors)) (nth sample anchors) (floor draw 65536)))
               (offset (mod (advance) 32)) (high (advance)) (low (advance))
               (contents (hash-corpus-bytes size (advance))))
          (multiple-value-bind (buffer start end) (hash-fixture contents :prefix offset)
            (hash-compare-reference buffer start end high low)
            (incf cases)))))
    (is (= cases 256))
    (format t "  XXH64 corpus: seed 6483BEEF, 256 span finiti di 0..65535 byte.~%")))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-every-byte-in-selected-spans-participates
  (let ((cases 0))
    (dolist (size '(1 4 8 31 32 33 64 65 129 256))
      (let* ((contents (hash-corpus-bytes size)) (before (copy-seq contents)))
        (dotimes (position size)
          (multiple-value-bind (buffer start end) (hash-fixture contents :prefix 31)
            (setf (aref buffer (+ start position))
                  (logxor (aref buffer (+ start position)) (expt 2 (mod position 8))))
            (hash-compare-reference buffer start end #xfedcba98 #x76543210)
            (incf cases)))
        (is (equalp before contents))))
    (is (= cases 623))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-named-public-caller-with-t-arguments
  (dolist (size '(0 1 31 32 65535))
    (multiple-value-bind (buffer start end) (hash-fixture (hash-corpus-bytes size) :prefix 17)
      (let ((before (copy-seq buffer)))
        (dolist (seed *hash-seeds*)
          (destructuring-bind (high low) seed
            (hash-check-values (hash-public-values buffer start end high low)
                               (hash-reference buffer start end high low))))
        (is (equalp before buffer))))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-invalid-buffers-and-nonsimple-arrays
  (let* ((base (hash-corpus-bytes 12)) (before (copy-seq base))
         (displaced (make-array 4 :element-type '(unsigned-byte 8)
                                  :displaced-to base :displaced-index-offset 3))
         (buffers (list nil t 42 -1 1.0 #\A "A" '(1 2) #(1 2) #*1010
                        (make-array 4 :element-type '(signed-byte 8) :initial-element -1)
                        (make-array 4 :element-type '(unsigned-byte 16) :initial-element 1)
                        (make-array 4 :element-type '(unsigned-byte 32) :initial-element 1)
                        (make-array 4 :element-type '(unsigned-byte 64) :initial-element 1)
                        (make-array nil :element-type '(unsigned-byte 8) :initial-element 1)
                        (make-array '(2 2) :element-type '(unsigned-byte 8) :initial-element 1)
                        (make-array 4 :element-type '(unsigned-byte 8) :adjustable t :initial-element 1)
                        (make-array 4 :element-type '(unsigned-byte 8) :fill-pointer 0 :initial-element 1)
                        (make-array 4 :element-type '(unsigned-byte 8) :fill-pointer 3 :initial-element 1)
                        (make-array 0 :element-type '(unsigned-byte 8) :adjustable t)
                        (make-array 0 :element-type '(unsigned-byte 8) :fill-pointer 0)
                        displaced)))
    (is (= 22 (length buffers)))
    (dolist (buffer buffers)
      (is (not (typep buffer '(simple-array (unsigned-byte 8) (*)))))
      (hash-reject buffer 0 0 0 0 :hash-arguments))
    ;; Include gli ottetti del backing array che non appartengono al view.
    (is (equalp base before))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-invalid-index-types-and-negative-indices
  (let ((buffer (hash-corpus-bytes 32))
        (bad (list nil t :index "0" #\0 0.0 1.0d0 1/2 #C(1 1)
                   -1.0 -1.0d0 -1/2 #C(-1 -1)
                   -1 -32 most-negative-fixnum (1- most-negative-fixnum)
                   (1+ most-positive-fixnum) (expt 2 100))))
    (is (= 19 (length bad)))
    (dolist (index bad)
      (hash-reject buffer index 32 0 0 :hash-arguments)
      (hash-reject buffer 0 index 0 0 :hash-arguments))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-invalid-seeds-in-each-half
  (let ((buffer (hash-corpus-bytes 32))
        (bad (list nil t :seed "0" #\0 0.0 1.0d0 1/2 #C(1 1) -1
                   -1.0 -1.0d0 -1/2 #C(-1 -1) (1- most-negative-fixnum)
                   #x100000000 most-positive-fixnum (1+ most-positive-fixnum)
                   most-negative-fixnum (expt 2 100))))
    (is (= 20 (length bad)))
    (dolist (seed bad)
      (hash-reject buffer 0 32 seed 0 :hash-arguments)
      (hash-reject buffer 0 32 0 seed :hash-arguments))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-valid-index-types-but-invalid-buffer-range
  (let ((buffer (hash-corpus-bytes 32)))
    (dolist (range (list '(1 0) '(32 31) '(0 33) '(33 33) '(33 34) '(34 33)
                        (list 0 most-positive-fixnum)
                        (list most-positive-fixnum most-positive-fixnum)
                        (list most-positive-fixnum 0) '(0 65536)))
      (hash-reject buffer (first range) (second range) 0 0 :buffer-range))))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-span-65536-and-larger-rejected-without-mutation
  (let ((buffer (hash-corpus-bytes 65606)))
    (dolist (size '(65536 65537 65568))
      (dolist (offset '(0 1 31))
        (dolist (seed *hash-seeds*)
          (hash-reject buffer offset (+ offset size) (first seed) (second seed)
                       :hash-span-limit))))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-validation-arguments-range-span-precedence
  (let ((buffer (hash-corpus-bytes 65536)))
    (hash-reject nil 0 65537 0 0 :hash-arguments)
    (hash-reject buffer -1 65536 0 0 :hash-arguments)
    (hash-reject buffer 0 65537 -1 0 :hash-arguments)
    (hash-reject buffer 0 65537 0 #x100000000 :hash-arguments)
    (hash-reject buffer 65537 65536 #x100000000 0 :hash-arguments)
    (hash-reject buffer 65536 65536 0 -1 :hash-arguments)
    (hash-reject buffer 0 65537 0 0 :buffer-range)
    (hash-reject buffer 1 65538 0 0 :buffer-range)
    (hash-reject buffer 65537 65536 0 0 :buffer-range)
    (hash-reject buffer 0 65536 0 0 :hash-span-limit)))

;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-absolute-indices-may-exceed-span-limit
  (let ((buffer (hash-corpus-bytes 131104)))
    (dolist (range '((65536 65536) (65536 65537) (65569 131104) (131104 131104)))
      (dolist (seed *hash-seeds*)
        (hash-compare-reference buffer (first range) (second range)
                                (first seed) (second seed))))))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-IDX-001-hash-u32-sign-bits-and-asymmetric-word-order
  (is (= 224
         (hash-check-offset-matrix
          (hash-corpus-bytes 63)
          '((0 #x7fffffff) (0 #x80000000) (#x7fffffff 0)
            (#x80000000 #xffffffff) (#xffffffff #x80000000)
            (#x80000001 #x7fffffff) (#xfedcba98 #x76543210))))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-zero-heap-in-serial-call-windows
  ;; SBCL64, runner seriale isolato: GET-BYTES-CONSED e un sink immediato.
  ;; Questo NON misura tempo/throughput, e nessun worker e' ancora stato avviato.
  ;; Il contatore di processo richiede assenza di altro carico allocante esterno.
  (is (typep #xffffffff 'fixnum))
  (let ((entry (hash-entry-point)) (windows 0) (calls 0))
    (dolist (size '(0 1 4 8 31 32 65 65535))
      (multiple-value-bind (buffer start end) (hash-fixture (hash-corpus-bytes size) :prefix 31)
        (let ((copy (copy-seq buffer)))
          (dolist (seed *hash-seeds*)
            (destructuring-bind (high low) seed
              (let* ((expected (hash-reference buffer start end high low))
                     (expected-sink (logxor (first expected) (second expected))))
                (hash-accept buffer start end high low expected)
                (is (= expected-sink (hash-fold-calls entry buffer start end high low 33)))
                (sb-ext:get-bytes-consed)
                (let* ((before (sb-ext:get-bytes-consed))
                       (sink (hash-fold-calls entry buffer start end high low 257))
                       (after (sb-ext:get-bytes-consed)))
                  (is (= expected-sink sink))
                  (is (= 0 (- after before)))
                  (incf windows) (incf calls 257)))))
          (is (equalp buffer copy)))))
    (is (= windows 64)) (is (= calls 16448))
    (format t "  XXH64 heap: 64 finestre seriali, 16448 chiamate misurate, atteso 0 byte.~%")))
