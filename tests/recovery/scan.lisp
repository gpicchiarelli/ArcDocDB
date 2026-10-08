(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-FOR-003 REQ-AFF-017
(deftest test-REQ-FOR-003-valid-log-oracle-and-determinism
  (dolist (version '(1 2))
    (dolist (entry '((:segment 31) (:control 0) (:multiserie 0)))
      (destructuring-bind (kind id) entry
        (multiple-value-bind (buffer start end) (log-fixture :version version
                                                           :log-kind kind :file-id id)
          (let ((before (copy-seq buffer)) (expected (list end :complete 3 6)))
            (dotimes (repeat 2)
              (is (equal expected (multiple-value-list
                                   (fixture-scan buffer start end id
                                                 :version version :log-kind kind)))))
            (is (equalp buffer before))))))))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-FOR-003-empty-log-and-empty-batches
  (dolist (version '(1 2))
    (dolist (entry '((:segment 31) (:control 0) (:multiserie 0)))
      (destructuring-bind (kind id) entry
        (multiple-value-bind (buffer start end) (log-fixture :version version
                  :log-kind kind :file-id id :batches 0)
          (is (equal (list start :complete 0 0)
                     (multiple-value-list (fixture-scan buffer start end id
                         :version version :log-kind kind :max-bytes 0 :max-search-bytes 0)))))
        (multiple-value-bind (buffer start end) (log-fixture :version version
                  :log-kind kind :file-id id :batches 2 :records 0)
          (is (equal (list end :complete 2 0)
                     (multiple-value-list (fixture-scan buffer start end id
                         :version version :log-kind kind :max-batches 2
                         :max-batch-bytes 56)))))))))

;;; REQ: REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-AFF-009-every-log-truncation
  (dolist (version '(1 2))
    (dolist (entry '((:segment 31) (:control 0) (:multiserie 0)))
      (destructuring-bind (kind id) entry
        (multiple-value-bind (buffer start end layouts)
            (log-fixture :version version :log-kind kind :file-id id)
          (let ((before (copy-seq buffer)))
            (loop for boundary from start to end do
              (let* ((completed (count-if (lambda (layout)
                                           (<= (getf layout :end) boundary)) layouts))
                     (prefix (if (zerop completed) start
                                 (getf (nth (1- completed) layouts) :end)))
                     (status (if (= prefix boundary) :complete :tail))
                     (expected (list prefix status completed (* 2 completed))))
                (is (equal expected (multiple-value-list
                     (fixture-scan buffer start boundary id :version version :log-kind kind))))))
            (is (equalp buffer before))))))))

;;; REQ: REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-AFF-009-frontier-boundary-and-failed-batch-start
  (dolist (delta '(-1 0 1))
    (multiple-value-bind (buffer start end layouts) (log-fixture)
      (let* ((failed (second layouts)) (witness (third layouts))
             (p (getf failed :start)) (absolute-p (+ 64 p))
             (record (second (getf failed :records))))
        ;; Il primo record del lotto fallito resta integro: P non è RECORD.
        (setf (aref buffer (+ record 24)) (logxor 1 (aref buffer (+ record 24))))
        (set-durable buffer witness (+ absolute-p delta))
        (let ((before (copy-seq buffer)))
          (dotimes (repeat 2)
            (if (plusp delta)
                (let ((condition (signals log-corruption
                      (fixture-scan buffer start end 31) :log-durable-corruption)))
                  (is (= absolute-p (error-offset condition)))
                  (is (= p (corruption-prefix-end condition)))
                  (is (= (+ 64 (getf witness :seal)) (corruption-witness-offset condition)))
                  (is (= (+ absolute-p delta) (corruption-durable-offset condition)))
                  (is (eq :body-crc (corruption-first-reason condition))))
                (is (equal (list p :tail 1 2)
                           (multiple-value-list (fixture-scan buffer start end 31))))))
          (is (equalp buffer before)))))))

;;; REQ: REQ-AFF-009 REQ-FOR-001
(deftest test-REQ-AFF-009-damaged-witness-batch-remains-evidence
  (multiple-value-bind (buffer start end layouts) (log-fixture)
    (let* ((failed (second layouts)) (witness (third layouts))
           (p (getf failed :start)))
      (dolist (layout (list failed witness))
        (let ((record (first (getf layout :records))))
          (setf (aref buffer (+ record 24)) (logxor 1 (aref buffer (+ record 24))))))
      (set-durable buffer witness (1+ (+ 64 p)))
      (let* ((before (copy-seq buffer))
             (condition (signals log-corruption (fixture-scan buffer start end 31))))
        (is (= p (corruption-prefix-end condition)))
        (is (= (+ 64 (getf witness :seal)) (corruption-witness-offset condition)))
        (is (equalp buffer before))))))

;;; REQ: REQ-AFF-009 REQ-FOR-001
(deftest test-REQ-AFF-009-invalid-witnesses-are-ignored
  (dolist (mutation '(:header-crc :body-crc :file-id :file-id-high :before-records :after-seal
                     :durable-after-batch :flags :key-length :value-length))
    (multiple-value-bind (buffer start end layouts) (log-fixture :batches 2)
      (let* ((failed (first layouts)) (witness (second layouts))
             (record (first (getf failed :records))) (seal (getf witness :seal))
             (body (+ seal 24)))
        (setf (aref buffer (+ record 24)) (logxor 1 (aref buffer (+ record 24))))
        (case mutation
          (:header-crc (setf (aref buffer seal) (logxor 1 (aref buffer seal))))
          (:body-crc (setf (aref buffer body) (logxor 1 (aref buffer body))))
          (:file-id (reference-le buffer body 8 32))
          (:file-id-high (reference-le buffer body 8 (+ 31 (ash 1 32))))
          (:before-records (reference-le buffer (+ body 8) 8 (1- (+ 64 start)))
                           (reference-le buffer (+ body 16) 8 0))
          (:after-seal (reference-le buffer (+ body 8) 8 (1+ (+ 64 seal))))
          (:durable-after-batch (reference-le buffer (+ body 16) 8
                                                   (1+ (+ 64 (getf witness :start)))))
          (:flags (setf (aref buffer (+ seal 9)) 1))
          (:key-length (reference-le buffer (+ seal 10) 2 1))
          (:value-length (reference-le buffer (+ seal 12) 4 #xffffffff)))
        (unless (member mutation '(:header-crc :body-crc))
          (repair-reference-record buffer seal end))
        (let ((before (copy-seq buffer)))
          (is (equal (list start :tail 0 0)
                     (multiple-value-list (fixture-scan buffer start end 31))))
          (is (equalp before buffer)))))))

;;; REQ: REQ-AFF-009 REQ-AFF-008
(deftest test-REQ-AFF-009-corrupt-length-cannot-hide-witness
  (multiple-value-bind (buffer start end layouts) (log-fixture :batches 2)
    (let ((record (first (getf (first layouts) :records)))
          (record-end (second (getf (first layouts) :records))))
      (reference-le buffer (+ record 12) 4 #xffffffff)
      (repair-reference-record buffer record record-end)
      (let ((condition (signals log-corruption (fixture-scan buffer start end 31))))
        (is (= start (corruption-prefix-end condition)))
        (is (eq :record-length (corruption-first-reason condition)))))))

;;; REQ: REQ-AFF-009 REQ-FOR-001
(deftest test-REQ-AFF-009-broken-header-does-not-end-search
  (multiple-value-bind (buffer start end layouts) (log-fixture :batches 2)
    (setf (aref buffer start) (logxor 1 (aref buffer start)))
    (let* ((before (copy-seq buffer))
           (condition (signals log-corruption (fixture-scan buffer start end 31))))
      (is (eq :header-crc (corruption-first-reason condition)))
      (is (= start (corruption-prefix-end condition)))
      (is (= (+ 64 (getf (second layouts) :seal)) (corruption-witness-offset condition)))
      (is (equalp buffer before)))))

;;; REQ: REQ-AFF-009 REQ-FOR-003
(deftest test-REQ-AFF-009-witness-at-every-alignment
  (dotimes (gap 8)
    (multiple-value-bind (first layout1) (reference-batch 7 64 31 1 2 2 71)
      (let ((second-start (+ 7 (length first) gap)))
        (multiple-value-bind (second layout2)
            (reference-batch second-start 64 31 1 2 2 72)
          (let* ((end (getf layout2 :end))
                 (buffer (make-array end :element-type '(unsigned-byte 8)
                                        :initial-element #xcc))
                 (bad (first (getf layout1 :records))))
            (replace buffer first :start1 7)
            (replace buffer second :start1 second-start)
            (setf (aref buffer (+ bad 24)) (logxor 1 (aref buffer (+ bad 24))))
            (let ((condition (signals log-corruption (fixture-scan buffer 7 end 31))))
              (is (= (+ 64 (getf layout2 :seal))
                     (corruption-witness-offset condition))))))))))

;;; REQ: REQ-AFF-009 REQ-FOR-001
(deftest test-REQ-AFF-009-nested-seal-at-last-search-position
  (let* ((start 7) (broken (reference-record 1 17 (bytes 1) (bytes 2)))
         (holder-start (+ start (length broken)))
         (nested-pos (+ holder-start 24 2 3)))
    (multiple-value-bind (proof) (reference-batch nested-pos 64 31 1 0 2 72)
      (let* ((value (make-array (+ 3 (length proof)) :element-type '(unsigned-byte 8)
                                                     :initial-element #xaa))
             (holder nil))
        (replace value proof :start1 3)
        (setf holder (reference-record 1 17 (bytes 3 4) value))
        (let* ((end (+ holder-start (length holder)))
               (buffer (make-array end :element-type '(unsigned-byte 8)
                                      :initial-element #xcc)))
          (replace buffer broken :start1 start)
          (replace buffer holder :start1 holder-start)
          (setf (aref buffer (+ start 24)) (logxor 1 (aref buffer (+ start 24))))
          (is (= nested-pos (- end 56)))
          (let ((condition (signals log-corruption (fixture-scan buffer start end 31))))
            (is (= (+ 64 nested-pos) (corruption-witness-offset condition)))))))))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-log-and-batch-budgets
  (multiple-value-bind (buffer start end layouts) (log-fixture)
    (let ((span (- end start)) (batch-bytes (- (getf (first layouts) :end) start))
          (before (copy-seq buffer)))
      (is (= end (fixture-scan buffer start end 31 :max-bytes span :max-batches 3
                               :max-batch-records 2 :max-batch-bytes batch-bytes)))
      (signals resource-exhausted (fixture-scan buffer start end 31 :max-bytes (1- span))
               :log-byte-budget)
      (signals resource-exhausted (fixture-scan buffer start end 31 :max-batches 2)
               :log-batch-budget)
      (signals resource-exhausted (fixture-scan buffer start end 31 :max-batch-records 1)
               :batch-record-budget)
      (signals resource-exhausted
               (fixture-scan buffer start end 31 :max-batch-bytes (1- batch-bytes))
               :batch-byte-budget)
      (is (equalp buffer before)))))

;;; REQ: REQ-AFF-008 REQ-AFF-009
(deftest test-REQ-AFF-008-batch-budget-cannot-classify-unchecked-tail
  (multiple-value-bind (prefix start prefix-end) (log-fixture :batches 1)
    (let* ((end (+ prefix-end 3))
           (buffer (make-array end :element-type '(unsigned-byte 8) :initial-element #xcc)))
      (replace buffer prefix)
      (is (equal (list prefix-end :complete 1 2)
                 (multiple-value-list (fixture-scan buffer start prefix-end 31 :max-batches 1))))
      (signals resource-exhausted (fixture-scan buffer start end 31 :max-batches 1)
               :log-batch-budget)
      (is (equal (list prefix-end :tail 1 2)
                 (multiple-value-list (fixture-scan buffer start end 31 :max-batches 2
                                                    :max-search-bytes 0)))))))

;;; REQ: REQ-AFF-008 REQ-AFF-009
(deftest test-REQ-AFF-008-search-budget-counts-positions
  (multiple-value-bind (buffer start end layouts) (log-fixture :batches 2)
    (let* ((record (first (getf (first layouts) :records)))
           (positions (1+ (- end start 56))))
      (setf (aref buffer (+ record 24)) (logxor 1 (aref buffer (+ record 24))))
      (set-durable buffer (second layouts) (+ 64 start))
      (is (equal (list start :tail 0 0)
                 (multiple-value-list (fixture-scan buffer start end 31
                                                    :max-search-bytes positions))))
      (signals resource-exhausted
               (fixture-scan buffer start end 31 :max-search-bytes (1- positions))
               :log-search-budget)
      (signals resource-exhausted (fixture-scan buffer start end 31 :max-search-bytes 0)
               :log-search-budget)))
  (dolist (size '(1 23 24 55))
    (let ((buffer (make-array (+ 7 size) :element-type '(unsigned-byte 8)
                                       :initial-element #xcc)))
      (is (equal '(7 :tail 0 0)
                 (multiple-value-list (fixture-scan buffer 7 (length buffer) 31
                                                    :max-search-bytes 0)))))))

;;; REQ: REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-AFF-008-eof-is-explicit-and-complete
  (multiple-value-bind (buffer start end) (log-fixture)
    (let ((before (copy-seq buffer)))
      (dolist (size (list nil -1 (+ 1 (ash 1 64)) (1- (+ 64 end)) (1+ (+ 64 end))))
        (signals invalid-argument (fixture-scan buffer start end 31 :file-size size)
                 :incomplete-log-buffer))
      (signals invalid-argument (fixture-scan buffer start (1- end) 31 :file-size (+ 64 end))
               :incomplete-log-buffer)
      (signals invalid-argument
               (scansiona-log buffer start end 31 :version 2 :file-offset 64)
               :incomplete-log-buffer)
      (is (equalp buffer before)))))

;;; REQ: REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-008-invalid-configuration-is-never-tail
  (multiple-value-bind (buffer start end) (log-fixture :batches 0)
    (dolist (version '(0 3 65535))
      (signals unsupported-format (fixture-scan buffer start end 31 :version version)
               :record-version))
    (signals unsupported-format (scansiona-log buffer start end 31 :file-size end)
             :record-version)
    (signals invalid-argument (fixture-scan buffer start end 31 :log-kind :unknown) :log-kind)
    (dolist (kind '(:control :multiserie))
      (signals invalid-argument (fixture-scan buffer start end 31 :log-kind kind)
               :log-scan-arguments))
    (dolist (options '((:max-bytes -1) (:max-batches 0) (:max-batches -1)
                      (:max-batch-records 0) (:max-batch-records -1)
                      (:max-batch-records 4294967296) (:max-batch-bytes 55)
                      (:max-search-bytes -1)))
      (signals invalid-argument (apply #'fixture-scan buffer start end 31 options)
               :log-scan-arguments))
    (signals invalid-argument (fixture-scan buffer -1 end 31) :buffer-range)
    (signals invalid-argument (fixture-scan buffer start (1+ end) 31) :buffer-range)))

;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-AFF-009-u64-offsets-and-overflow
  (dolist (file-offset (list (ash 1 32) (ash 1 63) (- (1- (ash 1 64)) 1000)))
    (multiple-value-bind (buffer start end layouts) (log-fixture :file-offset file-offset
                                                               :file-id #xffffffffffffffff)
      (is (equal (list end :complete 3 6)
                 (multiple-value-list (fixture-scan buffer start end #xffffffffffffffff
                                                    :file-offset file-offset))))
      (let* ((p (getf (second layouts) :start))
             (bad (first (getf (second layouts) :records))))
        (setf (aref buffer (+ bad 24)) (logxor 1 (aref buffer (+ bad 24))))
        (let ((condition (signals log-corruption
               (fixture-scan buffer start end #xffffffffffffffff :file-offset file-offset))))
          (is (= (+ file-offset p) (error-offset condition)))
          (is (= (+ file-offset (getf (third layouts) :seal))
                 (corruption-witness-offset condition)))))))
  (let ((buffer (make-array 1 :element-type '(unsigned-byte 8) :initial-element 0)))
    (signals invalid-argument
             (fixture-scan buffer 0 1 31 :file-offset #xffffffffffffffff :file-size 0)
             :log-scan-arguments)
    (is (equal '(0 :complete 0 0)
               (multiple-value-list (fixture-scan buffer 0 0 31
                                      :file-offset #xffffffffffffffff
                                      :file-size #xffffffffffffffff))))))
