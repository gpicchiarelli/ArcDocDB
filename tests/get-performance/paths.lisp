(in-package #:arcdocdb.get.performance.tests)

;;; REQ: REQ-AFF-002 REQ-FOR-002 REQ-IDX-001
(deftest test-REQ-AFF-002-performance-file-v1-value16 (performance-check-file-case 1 16))
(deftest test-REQ-AFF-002-performance-file-v1-value256 (performance-check-file-case 1 256))
(deftest test-REQ-AFF-002-performance-file-v1-value4096 (performance-check-file-case 1 4096))
(deftest test-REQ-AFF-002-performance-file-v2-value16 (performance-check-file-case 2 16))
(deftest test-REQ-AFF-002-performance-file-v2-value256 (performance-check-file-case 2 256))
(deftest test-REQ-AFF-002-performance-file-v2-value4096 (performance-check-file-case 2 4096))

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-AFF-002
(deftest test-REQ-CCH-002-performance-cache-hit-v1 (performance-check-cache-case 1))
(deftest test-REQ-CCH-002-performance-cache-hit-v2 (performance-check-cache-case 2))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-IDX-001-performance-absent
  (dolist (version '(1 2))
    (dolist (cache-p '(nil t))
      (with-get-performance-fixture (fixture :version version :cache-p cache-p)
        (dotimes (operation 3)
          (performance-checked-get fixture :path :absent)
          (is (null (performance-read-events fixture))))))))

;;; REQ: REQ-MVC-005 REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-MVC-005-performance-snapshot-boxed-late
  ;; Il driver GET usa il limite nel buffer del reader. La materializzazione del
  ;; CSN tramite l'API numerica snapshot è deliberatamente DOPO l'operazione.
  ;; È una verifica semantica delle due varianti CSN, non una prova di zero heap.
  (dolist (csn (list 7 +performance-max-csn+))
    (dolist (version '(1 2))
      (with-get-performance-fixture (fixture :version version :csn csn :snapshot-p t
                                            :value-bytes 256 :cache-p t)
        (performance-warm-cache fixture)
        (dotimes (operation 3)
          (performance-checked-get fixture :path :cache-record)
          (is (null (performance-read-events fixture)))
          (is (= csn (m:verifica-snapshot (get-performance-fixture-snapshot fixture)
                                         (get-performance-fixture-generation fixture) 12))))))))

;;; REQ: REQ-MVC-004 REQ-MVC-005 REQ-CMP-007
(deftest test-REQ-MVC-004-performance-snapshot-final-authorization
  ;; Miss e versione nuova richiedono storico; nessun I/O o falsa assenza.
  (dolist (missing-p '(nil t))
    (with-get-performance-fixture (fixture :csn +performance-max-csn+ :snapshot-p t
                                          :snapshot-csn 7)
      (let ((context (aref (get-performance-fixture-contexts fixture) 0)))
        (unwind-protect
             (progn
               (is (eq :history-required (performance-begin fixture 0 missing-p)))
               (is (equal '(:history-required 0) (multiple-value-list (g:concludi-get context 12))))
               (is (null (performance-read-events fixture)))
               (is (every (lambda (byte) (= byte +performance-output-sentinel+))
                          (aref (get-performance-fixture-outputs fixture) 0)))
               (performance-check-unpinned fixture))
          (g:abbandona-get context)))))
  ;; Il valore già copiato rimane privato se la deadline è raggiunta alla fine.
  (with-get-performance-fixture (fixture :snapshot-p t :value-bytes 4096)
    (let ((authorized nil))
      (signals snapshot-too-old
        (progn (performance-checked-get fixture :finish-now 30) (setf authorized t))
        :snapshot-age-expired)
      (is (null authorized))
      (performance-check-response fixture (aref (get-performance-fixture-outputs fixture) 0))
      (performance-check-unpinned fixture))))

;;; REQ: REQ-AFF-002 REQ-CMP-007
(deftest test-REQ-AFF-002-performance-output-copy
  (dolist (size '(16 256 4096))
    (with-get-performance-fixture (fixture :value-bytes size)
      (let ((context (aref (get-performance-fixture-contexts fixture) 0))
            (output (aref (get-performance-fixture-outputs fixture) 0)))
        (dolist (start '(0 3 8))
          (fill output +performance-output-sentinel+)
          (unwind-protect
               (progn
                 (is (eq :candidate (performance-begin fixture)))
                 (is (equal '(:segment :disabled :not-attempted nil nil)
                            (multiple-value-list
                             (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                                (get-performance-fixture-valid-bytes fixture) 0))))
                 (is (= (+ start size) (g:copia-valore-get context output start)))
                 (performance-check-response fixture output start)
                 (is (equal (list :found size) (multiple-value-list (g:concludi-get context 12))))
                 (performance-check-response fixture output start)
                 (performance-check-unpinned fixture))
            (g:abbandona-get context)))))))
