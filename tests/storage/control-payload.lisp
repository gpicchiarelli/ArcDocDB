(in-package #:arcdocdb.storage.tests)

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-edit-encoding-layout
  (dolist (complete '(nil t))
    (multiple-value-bind (buffer start end closed removed) (edit-fixture :complete complete)
      (let ((oracle (zeros (- end start))))
        (pack-le oracle 0 (if complete #xffffffffffffffff 0) 8)
        (pack-le oracle 8 13 8) (pack-le oracle 16 2 4)
        (replace oracle closed :start1 20)
        (pack-le oracle (+ 20 (length closed)) 2 4)
        (replace oracle removed :start1 (+ 24 (length closed)))
        (is (equalp oracle (subseq buffer start end))))
      (multiple-value-bind (cs cc rs rc total)
          (valida-valore-edit buffer start end (if complete 8 0))
        (is (= cs (+ start 20))) (is (= cc 2))
        (is (= rs (+ start 24 (length closed)))) (is (= rc 2)) (is (= total 2)))
      (is (every (lambda (x) (= x #xcc)) (subseq buffer 0 start)))
      (is (every (lambda (x) (= x #xcc)) (subseq buffer end))))))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-FOR-003-edit-truncation-counts-and-lengths
  (multiple-value-bind (buffer start end) (edit-fixture)
    (loop for boundary from start below end
          do (signals corruption-detected (valida-valore-edit buffer start boundary 0)))
    (signals corruption-detected (valida-valore-edit buffer start (1+ end) 0) :edit-trailing-data)
    (dolist (offset '(16 36 92)) ; n-closed, n-res prima chiusura, n-removed
      (let ((copy (copy-seq buffer)))
        (pack-le copy (+ start offset) #xffffffff 4)
        (signals resource-exhausted (valida-valore-edit copy start end 0) :metadata-budget)))
    (dolist (length '(0 63 4294967296 18446744073709551615))
      (let ((copy (copy-seq buffer)))
        (pack-le copy (+ start 28) length 8)
        (signals corruption-detected (valida-valore-edit copy start end 0) :closed-valid-bytes)))
    (let ((copy (copy-seq buffer)))
      (pack-le copy start 1 8)
      (signals corruption-detected (valida-valore-edit copy start end 0) :edit-next-id))
    (dolist (flags '(1 2 9 255))
      (signals corruption-detected (valida-valore-edit buffer start end flags) :edit-flags))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-edit-budget-boundaries
  (multiple-value-bind (buffer start end) (edit-fixture)
    (is (plusp (valida-valore-edit buffer start end 0 :max-chiusi 2 :max-rimossi 2 :max-esiti 2
                                  :max-bytes (- end start))))
    (signals resource-exhausted (valida-valore-edit buffer start end 0 :max-chiusi 1))
    (signals resource-exhausted (valida-valore-edit buffer start end 0 :max-rimossi 1))
    (signals resource-exhausted (valida-valore-edit buffer start end 0 :max-esiti 1))
    (signals resource-exhausted (valida-valore-edit buffer start end 0 :max-bytes (1- (- end start))))
    (signals resource-exhausted (valida-valore-edit buffer start end 0 :max-bytes 0))
    (signals invalid-argument (valida-valore-edit buffer start end 0 :max-bytes 16777217)))
  (let ((buffer (zeros 24)))
    (multiple-value-bind (cs cc rs rc total)
        (valida-valore-edit buffer 0 24 0 :max-chiusi 0 :max-rimossi 0 :max-esiti 0 :max-bytes 24)
      (is (= cs 20)) (is (zerop cc)) (is (= rs 24)) (is (zerop rc)) (is (zerop total)))))

;;; REQ: REQ-FOR-003 REQ-TXM-001
(deftest test-REQ-TXM-001-decision-encoding-layout
  (dolist (count '(2 3 65535))
    (multiple-value-bind (buffer start end parts) (decision-fixture :count count)
      (let ((oracle (zeros (- end start))))
        (pack-le oracle 0 #xffffffffffffffff 8)
        (pack-le oracle 8 count 2) (replace oracle parts :start1 10)
        (is (equalp oracle (subseq buffer start end))))
      (multiple-value-bind (csn ps pe actual-count) (valida-valore-decision buffer start end)
        (is (= csn start)) (is (= ps (+ start 10))) (is (= pe end)) (is (= actual-count count)))
      (is (every (lambda (x) (= x #xcc)) (subseq buffer 0 start)))
      (is (every (lambda (x) (= x #xcc)) (subseq buffer end))))))

;;; REQ: REQ-FOR-003 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-001-decision-truncation-and-budgets
  (multiple-value-bind (buffer start end) (decision-fixture)
    (loop for boundary from start below end
          do (signals corruption-detected (valida-valore-decision buffer start boundary)))
    (signals corruption-detected (valida-valore-decision buffer start (1+ end)) :decision-trailing-data)
    (dolist (count '(0 1 3 65535))
      (let ((copy (copy-seq buffer)))
        (pack-le copy (+ start 8) count 2)
        (signals corruption-detected (valida-valore-decision copy start end))))
    (is (= start (valida-valore-decision buffer start end :max-partecipanti 2 :max-bytes (- end start))))
    (signals resource-exhausted (valida-valore-decision buffer start end :max-partecipanti 1))
    (signals resource-exhausted (valida-valore-decision buffer start end :max-bytes (1- (- end start))))))

;;; REQ: REQ-FOR-002 REQ-FOR-003
(deftest test-REQ-FOR-003-control-record-both-versions
  (dolist (version '(1 2))
    (multiple-value-bind (buffer start end) (edit-fixture :complete t)
      (let ((record (control-record buffer start end 5 :version version :flags 8)))
        (multiple-value-bind (vs ve cs cc rs rc total flags)
            (verifica-record-edit record 0 (length record) :version version)
          (is (= vs 24)) (is (= ve (length record))) (is (= cs 44)) (is (= cc 2))
          (is (= rs 120)) (is (= rc 2)) (is (= total 2)) (is (= flags 8)))
        (signals unsupported-format (verifica-record-edit record 0 (length record)))))
    (multiple-value-bind (buffer start end) (decision-fixture)
      (let ((record (control-record buffer start end 6 :version version)))
        (multiple-value-bind (csn ps pe count)
            (verifica-record-decision record 0 (length record) :version version)
          (is (= csn 24)) (is (= ps 34)) (is (= pe (length record))) (is (= count 2)))
        (signals unsupported-format (verifica-record-decision record 0 (length record)))))))

;;; REQ: REQ-FOR-003
(deftest test-REQ-FOR-003-control-record-integrity-before-counts
  (multiple-value-bind (buffer start end) (edit-fixture)
    (let ((record (control-record buffer start end 5)))
      (loop for pos from 0 below (length record)
            do (let ((copy (copy-seq record)))
                 (setf (aref copy pos) (logxor 1 (aref copy pos)))
                 (signals corruption-detected (verifica-record-edit copy 0 (length copy) :version 2))))
      (signals corruption-detected (verifica-record-decision record 0 (length record) :version 2)
               :control-record)
      (signals corruption-detected
               (verifica-record-edit (concatenate 'arcdocdb.binary:octets record (bytes 0))
                                      0 (1+ (length record)) :version 2) :control-record))
    (let ((wrong (copy-seq buffer)))
      (pack-le wrong (+ start 16) 3 4)
      (let ((record (control-record wrong start end 5)))
        (signals corruption-detected (verifica-record-edit record 0 (length record) :version 2))))))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-AFF-008-encoder-preflight-no-partial-write
  (let ((buffer (make-array 512 :element-type '(unsigned-byte 8) :initial-element #xcc))
        (closed (closed-fixture)) (removed (zeros 16)) (parts (zeros 32)))
    (let ((before (copy-seq buffer)))
      (signals invalid-argument (scrivi-valore-edit buffer 0 1 13 closed 2 removed) :edit-next-id)
      (signals invalid-argument (scrivi-valore-edit buffer 0 0 13 closed 2 (bytes 1)))
      (signals invalid-argument (scrivi-valore-edit buffer 0 0 13 buffer 2 removed) :input-alias)
      (signals invalid-argument (scrivi-valore-edit buffer 0 0 13 closed 2 buffer) :input-alias)
      (signals resource-exhausted (scrivi-valore-edit buffer 0 0 13 closed 2 removed :max-esiti 1))
      (signals corruption-detected (scrivi-valore-edit buffer 0 0 13 closed 3 removed))
      (signals invalid-argument (scrivi-valore-edit buffer 512 0 13 closed 2 removed))
      (signals invalid-argument (scrivi-valore-decision buffer 0 19 buffer) :input-alias)
      (signals invalid-argument (scrivi-valore-decision buffer 0 19 (bytes 1)))
      (signals invalid-argument (scrivi-valore-decision buffer 0 19 (zeros 16)))
      (signals invalid-argument (scrivi-valore-decision buffer 512 19 parts))
      (signals resource-exhausted (scrivi-valore-decision buffer 0 19 parts :max-partecipanti 1))
      (is (equalp before buffer)))))

;;; REQ: REQ-AFF-008 REQ-LIM-001
(deftest test-REQ-AFF-008-edit-cumulative-budget-and-corrupt-huge-counts
  (let* ((closed (closed-fixture '((11 4294967295 ((1 2))) (12 64 ((3 4))))))
         (buffer (zeros (+ 24 (length closed)))))
    (scrivi-valore-edit buffer 0 0 #xffffffffffffffff closed 2 (bytes) :max-esiti 2)
    (is (= 2 (nth-value 4 (valida-valore-edit buffer 0 (length buffer) 0 :max-esiti 2))))
    (signals resource-exhausted
             (valida-valore-edit buffer 0 (length buffer) 0 :max-esiti 1))
    (dolist (offset '(16 36))
      (let ((copy (copy-seq buffer)))
        (pack-le copy offset #xffffffff 4)
        (signals corruption-detected
                 (valida-valore-edit copy 0 (length copy) 0 :max-chiusi #xffffffff
                                     :max-esiti #xffffffff))))))

;;; REQ: REQ-AFF-008 REQ-TXM-001
(deftest test-REQ-AFF-008-encoder-overflow-and-unused-sections
  (let* ((buffer (make-array 256 :element-type '(unsigned-byte 8) :initial-element #xcc))
         (before (copy-seq buffer)) (closed (closed-fixture)))
    (signals invalid-argument (scrivi-valore-edit buffer 0 0 1 closed 1 (bytes))
             :closed-trailing-data)
    (signals invalid-argument (scrivi-valore-edit buffer 0 0 1 (bytes 0) 0 (bytes)))
    (signals invalid-argument (scrivi-valore-edit buffer 0 0 1 closed 2 (bytes)
                                                :max-bytes 16777217))
    (signals invalid-argument (scrivi-valore-decision buffer 0 1 (zeros 32)
                                                    :max-bytes 16777217))
    (signals resource-exhausted (scrivi-valore-decision buffer 0 1 (zeros (* 16 65536))))
    (is (equalp before buffer))))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(deftest test-REQ-FOR-003-decision-record-all-truncations-and-bit-flips
  (multiple-value-bind (buffer start end) (decision-fixture)
    (let ((record (control-record buffer start end 6)))
      (loop for boundary from 0 below (length record)
            do (signals corruption-detected (verifica-record-decision record 0 boundary :version 2)))
      (dotimes (offset (length record))
        (dotimes (bit 8)
          (let ((copy (copy-seq record)))
            (setf (aref copy offset) (logxor (ash 1 bit) (aref copy offset)))
            (signals corruption-detected
                     (verifica-record-decision copy 0 (length copy) :version 2)))))
      (signals corruption-detected (verifica-record-edit record 0 (length record) :version 2)
               :control-record))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-byte-budget-before-crc-scan
  (multiple-value-bind (buffer start end) (edit-fixture)
    (let ((record (control-record buffer start end 5)))
      (setf (aref record 0) (logxor 1 (aref record 0)))
      (signals resource-exhausted (verifica-record-edit record 0 (length record)
                                                        :version 2 :max-bytes 0))
      (signals invalid-argument (verifica-record-edit record 0 (length record)
                                                      :version 2 :max-bytes 16777217))
      (signals corruption-detected (verifica-record-edit record 0 (length record)
                                                          :version 2 :max-bytes (- end start)))))
  (multiple-value-bind (buffer start end) (decision-fixture)
    (let ((record (control-record buffer start end 6)))
      (signals resource-exhausted (verifica-record-decision record 0 (length record)
                                                            :version 2 :max-bytes 0))
      (signals invalid-argument (verifica-record-decision record 0 (length record)
                                                          :version 2 :max-bytes 16777217))
      (is (= 24 (verifica-record-decision record 0 (length record)
                                          :version 2 :max-bytes (- end start)))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-internal-range-guards
  (signals invariant-violation (arcdocdb.storage.format::spazio-ripetuto 0 0 0 0))
  (signals invariant-violation (arcdocdb.storage.format::spazio-ripetuto 1 0 0 1))
  (signals invalid-argument (arcdocdb.storage.format::zero-range-p (bytes) 0 1)))
