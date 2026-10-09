(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-TXM-005-decision-table-ordered-unordered-oracle
  (dolist (version '(1 2))
    (dolist (count '(0 1 2 3 4 5 7 8 9 15 16 17))
      (let ((specs (loop for i below count collect
                    (decision-spec (+ 50 (* 2 i)) (mod i 3)
                      (loop for j below (nth (mod i 3) '(3 5 17)) collect
                            (participant-id (+ (* i 32) j) (if (oddp j) 128 0)))))))
        (dolist (order (list specs (reverse specs) (permute-decisions specs 193)))
          (multiple-value-bind (buffer start end) (decision-log-fixture (list order)
                                                                           :version version)
            (let ((before (copy-seq buffer)))
              (multiple-value-bind (table prefix status)
                  (decision-fixture-read buffer start end :version version)
                (is (= prefix end)) (is (eq :complete status))
                (assert-decision-table table specs '(0 49 51 1024 1025)))
              (is (equalp buffer before)))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-TXM-005-seeded-histories-and-permuted-duplicates
  (dolist (seed '(1 42 913 4294967295))
    (let* ((base (loop for i below 9 collect
                  (decision-spec (* 3 i) (mod i 2)
                    (loop for j below (nth (mod i 3) '(3 5 17)) collect
                          (participant-id (+ (* i 32) j))))))
           (duplicates (loop repeat 23 for value = seed then
                              (logand #xffffffff (+ (* value 1664525) 1013904223))
                            for selected = (nth (mod value 9) base)
                            collect (decision-spec (first selected) (second selected)
                                       (permute-decisions (third selected) value))))
           (history (permute-decisions (append base duplicates) seed))
           (batches (loop for pos from 0 below (length history) by 5
                          collect (subseq history pos (min (+ pos 5) (length history))))))
      (multiple-value-bind (buffer start end) (decision-log-fixture batches)
        (multiple-value-bind (table prefix status) (decision-fixture-read buffer start end)
          (is (= end prefix)) (is (eq :complete status))
          (assert-decision-table table base))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-TXM-001-zero-maximum-u64-and-shared-csn
  (dolist (version '(1 2))
    (let* ((ids (list (participant-id 0) (participant-id #xffffffffffffffff 128)))
           (specs (list (decision-spec 0 0 ids)
                        (decision-spec #xffffffffffffffff #xffffffffffffffff (reverse ids))
                        (decision-spec 1 #xffffffffffffffff ids)
                        (decision-spec 0 0 (reverse ids)))))
      (multiple-value-bind (buffer start end) (decision-log-fixture (list specs)
                                               :version version :seal-stamp #xffffffffffffffff)
        (multiple-value-bind (table prefix status)
            (decision-fixture-read buffer start end :version version)
          (is (= end prefix)) (is (eq :complete status))
          (assert-decision-table table specs)
          (is (equal '(t 0 2)
                     (multiple-value-list (arcdocdb.recovery.decisions:trova-decisione table 0)))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-017
(deftest test-REQ-TXM-005-table-owns-participant-copies
  (let ((specs (list (decision-spec 17 9 (list (participant-id 1) (participant-id 2 128)))
                     (decision-spec 3 4 (list (participant-id 8) (participant-id 9))))))
    (multiple-value-bind (buffer start end) (decision-log-fixture (list specs))
      (multiple-value-bind (table prefix status) (decision-fixture-read buffer start end)
        (is (= end prefix)) (is (eq :complete status))
        (assert-decision-table table specs)
        (fill buffer #xff)
        (dotimes (repeat 2) (assert-decision-table table specs))
        (let ((query (copy-seq (first (third (first specs))))))
          (is (arcdocdb.recovery.decisions:partecipante-decisione-p table 17 query 0 16))
          (setf (aref query 15) 3)
          (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p table 17 query 0 16)))
          (assert-decision-table table specs))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-001-participant-exact-bytes-and-query-ranges
  (let* ((ids (list (participant-id 0) (participant-id 1) (participant-id 128)
                    (participant-id 255) (participant-id 1 128)))
         (specs (list (decision-spec 31 17 (reverse ids)))))
    (multiple-value-bind (buffer start end) (decision-log-fixture (list specs))
      (let ((table (decision-fixture-read buffer start end)))
        (assert-decision-table table specs)
        (dolist (id ids)
          (let ((query (make-array 22 :element-type '(unsigned-byte 8) :initial-element #xaa)))
            (replace query id :start1 3)
            (is (arcdocdb.recovery.decisions:partecipante-decisione-p table 31 query 3 19))))
        (dolist (absent (list (participant-id 2) (participant-id 1 1) (participant-id 1 255)))
          (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p table 31 absent 0 16))))
        (dolist (txid '(31 999))
          (let ((query (make-array 17 :element-type '(unsigned-byte 8) :initial-element 0)))
            (signals invalid-argument
                     (arcdocdb.recovery.decisions:partecipante-decisione-p table txid query 0 15)
                     :serie-id-length)
            (signals invalid-argument
                     (arcdocdb.recovery.decisions:partecipante-decisione-p table txid query 0 17)
                     :serie-id-length)
            (signals invalid-argument
                     (arcdocdb.recovery.decisions:partecipante-decisione-p table txid query -1 15)
                     :buffer-range)
            (signals invalid-argument
                     (arcdocdb.recovery.decisions:partecipante-decisione-p table txid query 2 18)
                     :buffer-range)))
        (is (equal '(nil 0 0)
                   (multiple-value-list (arcdocdb.recovery.decisions:trova-decisione table 999))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-TXM-005-conflicting-csn-set-or-count
  (let* ((ids (list (participant-id 1) (participant-id 2)))
         (first (decision-spec 17 1 ids)))
    (dolist (discordant (list (decision-spec 17 2 ids)
                              (decision-spec 17 (+ 1 (ash 1 32)) ids)
                              (decision-spec 17 1 (list (participant-id 1) (participant-id 3)))
                              (decision-spec 17 1 (list (participant-id 1) (participant-id 2 128)))
                              (decision-spec 17 1 (append ids (list (participant-id 3))))))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list (list first discordant)))
        (let* ((before (copy-seq buffer))
               (condition (signals corruption-detected (decision-fixture-read buffer start end)
                                   :decision-conflict)))
          (is (= (+ 64 (second (getf (first layouts) :records))) (error-offset condition)))
          (is (equalp before buffer)))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-TXM-005-duplicate-participants-within-record
  (dolist (participants (list (list (participant-id 1) (participant-id 1))
                              (list (participant-id 1) (participant-id 2) (participant-id 1))
                              (list (participant-id 255 128) (participant-id 0)
                                    (participant-id 255 128))))
    (let ((good (decision-spec 1 0 (list (participant-id 1) (participant-id 2))))
          (bad (decision-spec 17 0 participants)))
      (multiple-value-bind (buffer start end layouts) (decision-log-fixture (list (list good bad)))
        (let* ((before (copy-seq buffer))
               (condition (signals corruption-detected (decision-fixture-read buffer start end)
                                   :decision-duplicate-participant)))
          (is (= (+ 64 (second (getf (first layouts) :records))) (error-offset condition)))
          (is (equalp before buffer)))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-017
(deftest test-REQ-TXM-005-every-cut-keeps-only-sealed-decisions
  (dolist (version '(1 2))
    (let* ((specs (loop for i below 5 collect
                   (decision-spec i (+ 17 i) (list (participant-id i) (participant-id (+ 16 i))))))
           (batches (list (subseq specs 0 2) (subseq specs 2 3) (subseq specs 3 5))))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture batches :version version)
        (let ((before (copy-seq buffer)))
          (loop for cut from start to end do
            (let* ((complete (count-if (lambda (layout) (<= (getf layout :end) cut)) layouts))
                   (expected-prefix (if (zerop complete) start
                                        (getf (nth (1- complete) layouts) :end)))
                   (expected (apply #'append (subseq batches 0 complete))))
              (multiple-value-bind (table prefix status)
                  (decision-fixture-read buffer start cut :version version)
                (is (= prefix expected-prefix))
                (is (eq status (if (= cut prefix) :complete :tail)))
                (assert-decision-table table expected))))
          (is (equalp before buffer)))))))

;;; REQ: REQ-TXM-005 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-TXM-005-presumed-abort-after-complete-tail-search
  (let* ((a (decision-spec 1 17 (list (participant-id 1) (participant-id 2))))
         (b (decision-spec 2 18 (list (participant-id 3) (participant-id 4))))
         (c (decision-spec 3 19 (list (participant-id 5) (participant-id 6)))))
    (multiple-value-bind (buffer start end layouts)
        (decision-log-fixture (list (list a) (list b) (list c)))
      (let* ((p (getf (second layouts) :start))
             (bad (first (getf (second layouts) :records))))
        (setf (aref buffer (+ bad 24)) (logxor 1 (aref buffer (+ bad 24))))
        (set-durable buffer (third layouts) (+ 64 p))
        (multiple-value-bind (table prefix status) (decision-fixture-read buffer start end)
          (is (= p prefix)) (is (eq :tail status))
          (assert-decision-table table (list a) '(2 3 999))
          (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                     table 3 (participant-id 5) 0 16))))))))

;;; REQ: REQ-TXM-005 REQ-AFF-009 REQ-FOR-003
(deftest test-REQ-TXM-005-scans-later-corruption-before-payload-or-budget
  (let ((spec (decision-spec 1 17 (list (participant-id 1) (participant-id 2)))))
    (dolist (invalid-payload '(nil t))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list (list spec) (list spec) (list spec)))
        (when invalid-payload
          (reference-le buffer (+ (first (getf (first layouts) :records)) 32) 2 1)
          (repair-decision-batch buffer (first layouts)))
        (let* ((p (getf (second layouts) :start))
               (bad (first (getf (second layouts) :records))) (before nil))
          (setf (aref buffer (+ bad 24)) (logxor 1 (aref buffer (+ bad 24))))
          (setf before (copy-seq buffer))
          (let ((condition (signals log-corruption
                   (decision-fixture-read buffer start end :max-decisions 0)
                   :log-durable-corruption)))
            (is (= (+ 64 p) (error-offset condition)))
            (is (eq :body-crc (corruption-first-reason condition)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-FOR-003 REQ-TXM-005
(deftest test-REQ-FOR-003-sealed-invalid-decision-payload-is-not-tail
  (dolist (count '(0 1 3 65535))
    (let ((spec (decision-spec 1 17 (list (participant-id 1) (participant-id 2)))))
      (multiple-value-bind (buffer start end layouts) (decision-log-fixture (list (list spec)))
        (reference-le buffer (+ start 32) 2 count)
        (repair-decision-batch buffer (first layouts))
        (let ((before (copy-seq buffer)))
          (signals corruption-detected (decision-fixture-read buffer start end)
                   (if (< count 2) :decision-participants :metadata-truncated))
          (is (equalp before buffer)))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005
(deftest test-REQ-AFF-008-empty-decisions-zero-and-large-budgets
  (dolist (batches '(nil (nil nil)))
    (multiple-value-bind (buffer start end) (decision-log-fixture batches)
      (dolist (budget (list 0 most-positive-fixnum))
        (multiple-value-bind (table prefix status)
            (decision-fixture-read buffer start end :max-decisions budget
                                    :max-participants budget :max-participants-per-decision 0)
          (is (= end prefix)) (is (eq :complete status))
          (assert-decision-table table nil '(0 1 18446744073709551615))))))
  (let ((buffer (make-array 55 :element-type '(unsigned-byte 8) :initial-element #xcc)))
    (multiple-value-bind (table prefix status)
        (decision-fixture-read buffer 0 55 :max-decisions 0 :max-participants 0
                                :max-participants-per-decision 0 :max-search-bytes 0)
      (is (zerop prefix)) (is (eq :tail status))
      (assert-decision-table table nil '(0 1)))))

;;; REQ: REQ-AFF-008 REQ-TXM-005
(deftest test-REQ-AFF-008-physical-duplicate-record-budgets
  (let* ((ids (list (participant-id 1) (participant-id 2)))
         (a (decision-spec 0 0 ids)) (b (decision-spec 0 0 (reverse ids))))
    (multiple-value-bind (buffer start end)
        (decision-log-fixture (list (list a b a)))
      (let ((before (copy-seq buffer)))
        (let ((table (decision-fixture-read buffer start end :max-decisions 3
                                            :max-participants 6 :max-participants-per-decision 2)))
          (assert-decision-table table (list a)))
        (dolist (budget '(0 2))
          (signals resource-exhausted (decision-fixture-read buffer start end :max-decisions budget)
                   :decision-count-budget))
        (dolist (budget '(0 5))
          (signals resource-exhausted (decision-fixture-read buffer start end :max-participants budget)
                   :decision-participant-budget))
        (dolist (budget '(0 1))
          (signals resource-exhausted
                   (decision-fixture-read buffer start end :max-participants-per-decision budget)
                   :metadata-budget))
        (is (equalp before buffer))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005
(deftest test-REQ-AFF-008-invalid-decision-budgets-even-empty
  (multiple-value-bind (buffer start end) (decision-log-fixture nil)
    (dolist (options (list '(:max-decisions -1) '(:max-participants -1)
                          (list :max-decisions (1+ most-positive-fixnum))
                          (list :max-participants (1+ most-positive-fixnum))
                          '(:max-participants-per-decision -1)
                          '(:max-participants-per-decision 65536)))
      (signals invalid-argument (apply #'decision-fixture-read buffer start end options)
               :decision-arguments))))

;;; REQ: REQ-AFF-008 REQ-TXM-005 REQ-AFF-009
(deftest test-REQ-AFF-008-decision-scanner-budgets-propagate
  (let* ((spec (decision-spec 1 17 (list (participant-id 1) (participant-id 2))))
         (batches (list (list spec spec) (list spec))))
    (multiple-value-bind (buffer start end layouts) (decision-log-fixture batches)
      (let ((first-size (- (getf (first layouts) :end) start)))
        (assert-decision-table
         (decision-fixture-read buffer start end :max-bytes (- end start)
            :max-batches 2 :max-batch-records 2 :max-batch-bytes first-size) (list spec))
        (signals resource-exhausted
                 (decision-fixture-read buffer start end :max-bytes (1- (- end start)))
                 :log-byte-budget)
        (signals resource-exhausted (decision-fixture-read buffer start end :max-batches 1)
                 :log-batch-budget)
        (signals resource-exhausted (decision-fixture-read buffer start end :max-batch-records 1)
                 :batch-record-budget)
        (signals resource-exhausted
                 (decision-fixture-read buffer start end :max-batch-bytes (1- first-size))
                 :batch-byte-budget))
      (setf (aref buffer start) (logxor 1 (aref buffer start)))
      (set-durable buffer (second layouts) (+ 64 start))
      (let ((positions (1+ (- end start 56))))
        (signals resource-exhausted
                 (decision-fixture-read buffer start end :max-search-bytes (1- positions))
                 :log-search-budget)))))

;;; REQ: REQ-AFF-008 REQ-FOR-003 REQ-TXM-005
(deftest test-REQ-AFF-008-decision-eof-and-version-errors
  (multiple-value-bind (buffer start end) (decision-log-fixture nil)
    (dolist (version '(0 3 65535))
      (signals unsupported-format (decision-fixture-read buffer start end :version version)
               :record-version))
    (signals unsupported-format
             (arcdocdb.recovery.decisions:ricostruisci-decisioni buffer start end
                :file-offset 64 :file-size (+ 64 end)) :record-version)
    (dolist (size (list nil -1 (ash 1 64) (1- (+ 64 end)) (1+ (+ 64 end))))
      (signals invalid-argument (decision-fixture-read buffer start end :file-size size)
               :incomplete-log-buffer)))
  (let ((spec (decision-spec 1 17 (list (participant-id 1) (participant-id 2)))))
    (multiple-value-bind (buffer start end) (decision-log-fixture (list (list spec)))
      (signals invalid-argument
               (decision-fixture-read buffer start (1- end) :file-size (+ 64 end))
               :incomplete-log-buffer))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-005-high-file-offset-and-conflict-provenance
  (dolist (file-offset (list (ash 1 32) (ash 1 63) (- #xffffffffffffffff 1000)))
    (let* ((a (decision-spec #xffffffffffffffff #xffffffffffffffff
                            (list (participant-id 1) (participant-id 2))))
           (b (decision-spec #xffffffffffffffff 0 (third a))))
      (multiple-value-bind (buffer start end)
          (decision-log-fixture (list (list a)) :file-offset file-offset)
        (let ((table (decision-fixture-read buffer start end :file-offset file-offset)))
          (assert-decision-table table (list a))))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list (list a b)) :file-offset file-offset)
        (let ((condition (signals corruption-detected
                    (decision-fixture-read buffer start end :file-offset file-offset)
                    :decision-conflict)))
          (is (= (+ file-offset (second (getf (first layouts) :records)))
                 (error-offset condition)))))))
  (let ((buffer (make-array 1 :element-type '(unsigned-byte 8) :initial-element 0)))
    (signals invalid-argument
             (decision-fixture-read buffer 0 1 :file-offset #xffffffffffffffff :file-size 0)
             :log-scan-arguments)))
