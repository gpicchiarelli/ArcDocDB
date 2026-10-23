;;;; Bridge DECISION verificato -> recovery ACTIVE canonico, matrici finite v1/v2.
;;; OWNER: runner seriale; le due fixture conservano FD, backend e scratch fino al ritorno.
;;; SHARED: decisioni complete immutabili; hook locali alla fixture, nessuna FI globale.
;;; Limiti: file <=4096 byte; nessuna prova nativa, concorrenza o misura prestazionale.
;;; Stesura e rilettura statiche soltanto: esecuzioni rinviate al freeze coordinato.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-002 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun dara-put (txid &optional (prepared t))
  (list :put txid prepared (av::av-bytes 1 #x41) (av::av-bytes 2 #xfe)))

(defun dara-decision (txid csn)
  (list txid csn (list (rt::participant-id 1) (av::av-identity))))

(defun dara-with-fixtures (version batches specs thunk
                           &key (decision-version version) active-tail decision-tail)
  "Recovery reali; tabella canonica indipendente costruita dalle medesime spec dichiarative."
  (av::av-with-fixture (av::av-log batches :version version :tail active-tail)
    (lambda (f)
      (dar-with-input (dar-log (if specs (list specs) nil)
                              :version decision-version :tail decision-tail)
        (lambda (d)
          (let ((decisions (dar-call d)))
            (is (typep decisions 'da:decisioni-recuperate))
            (is (not (equalp (dar-fixture-identity d) (av::av-fixture-identity f))))
            (dar-clear d) (av::av-clear f)
            (funcall thunk f d decisions)))
        :scope (arcdocdb.get::vista-get-serie-scope (av::av-fixture-view f))))
    :version version :decision-specs specs))

(defun dara-call (f decisions &rest options)
  (apply #'da:leggi-active-con-decisioni (av::av-fixture-control f)
         (av::av-fixture-input f) (av::av-fixture-size f) decisions
         (av::av-fixture-scratch f) options))

(defun dara-snapshot (result)
  "Osservazioni pubbliche e byte CLOSED posseduti dal test, senza accessori del risultato."
  (let* ((size (arcdocdb.recovery.active:lunghezza-chiusura-active result))
         (buffer (av::av-bytes (+ size 6) #xa7)))
    (is (= (+ 3 size) (arcdocdb.recovery.active:scrivi-chiusura-active result buffer 3)))
    (list (multiple-value-list (arcdocdb.recovery.active:frontiere-active-recuperato result))
          (multiple-value-list (arcdocdb.recovery.active:statistiche-active-recuperato result))
          (mapcar (lambda (txid)
                    (multiple-value-list (arcdocdb.recovery.active:esito-chiusura-active result txid)))
                  '(0 7 9 11 99 #xffffffffffffffff))
          buffer)))

(defun dara-compatible (f d decisions &rest options)
  "Confronta risultato, serializer e richieste I/O con il recovery ACTIVE canonico reale."
  (let* ((canonical (apply #'av::av-call f options))
         (expected (dara-snapshot canonical)) (events (av::av-events f)))
    (av::av-clear f) (fill (av::av-fixture-scratch f) #xa5)
    (let ((result (apply #'dara-call f decisions options)))
      (is (equalp expected (dara-snapshot result)))
      (is (equal events (av::av-events f)))
      (is (equalp (av::av-fixture-scratch f) (av::av-fixture-reference f)))
      (is (null (dar-events d))) (is (zerop (dar-fixture-reads d)))
      (av::av-noeffects f) (dar-noeffects d)
      result)))

(defun dara-preflight (f d type reason thunk &key closed)
  "Rifiuto senza accessi ACTIVE, neppure all'identità, e senza modificare lo scratch."
  (let ((before (copy-seq (av::av-fixture-scratch f))))
    (dar-expect type reason thunk)
    (is (equalp before (av::av-fixture-scratch f)))
    (is (null (av::av-events f))) (is (zerop (av::av-fixture-reads f)))
    (is (null (dar-events d))) (is (zerop (dar-fixture-reads d)))
    (av::av-noeffects f)
    (unless closed (dar-noeffects d))))

(defun dara-reject-compatible (f d decisions reason options)
  "Le due API devono preservare tipo, motivo, offset e richieste senza risultato parziale."
  (av::av-clear f)
  (let* ((canonical (dar-expect 'resource-exhausted reason
                               (lambda () (apply #'av::av-call f options))))
         (events (av::av-events f)))
    (av::av-clear f) (fill (av::av-fixture-scratch f) #xa5)
    (let ((condition (dar-expect 'resource-exhausted reason
                                (lambda () (apply #'dara-call f decisions options)))))
      (is (eq (class-of canonical) (class-of condition)))
      (is (eql (error-offset canonical) (error-offset condition)))
      (is (equal events (av::av-events f)))
      (is (null (dar-events d)))
      (av::av-noeffects f) (dar-noeffects d))))

(defun dara-budget-batches ()
  (list (list (dara-put 7) (dara-put 9)) (list (list :outcome 7 17))))

(defun dara-closed-decision (d)
  "Sola chiusura esplicita autorizzata; nessun effetto durevole o modifica dei byte."
  (is (dar-fixture-closed d))
  (is (eq :closed (io:stato-file (dar-fixture-input d))))
  (is (eq :input (io:mode-file (dar-fixture-input d))))
  (is (zerop (io:posizione-scritta (dar-fixture-input d))))
  (is (zerop (io:posizione-durevole (dar-fixture-input d))))
  (is (equalp (dar-fixture-source d) (dar-fixture-reference d)))
  (is (equalp (da::archivio-recovery-identity (dar-fixture-archive d))
              (dar-fixture-identity d))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-001
(deftest test-REQ-REC-001-ARCHIVE-ACTIVE-same-scope-distinct-uuid-v1-v2
  (dolist (version '(1 2))
    (dolist (decision-version '(1 2))
      (dara-with-fixtures version nil nil
        (lambda (f d decisions)
          (is (eq (da::archivio-recovery-scope (dar-fixture-archive d))
                  (arcdocdb.get::vista-get-serie-scope (av::av-fixture-view f))))
          (let ((r (dara-compatible f d decisions)))
            (is (equal (list 64 64 :complete version) (first (dara-snapshot r))))
            (is (equal '(0 0 0 0 0 0) (second (dara-snapshot r))))))
        :decision-version decision-version))))

;;; REQ: REQ-AFF-008 REQ-TXM-005
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-foreign-scope-same-uuid-before-io
  (dolist (version '(1 2))
    (av::av-with-fixture (av::av-log nil :version version)
      (lambda (f)
        (let ((scope (arcdocdb.get::vista-get-serie-scope (ct::crr-view (dar-identity)))))
          (is (not (eq scope (arcdocdb.get::vista-get-serie-scope (av::av-fixture-view f)))))
          (dar-with-input (dar-log nil :version version)
            (lambda (d)
              (let ((decisions (dar-call d)))
                (is (equalp (dar-identity) (dar-fixture-identity d)))
                (dar-clear d)
                (dara-preflight f d 'invalid-argument :active-recovery-archive
                                (lambda () (dara-call f decisions)))))
            :scope scope)))
      :version version)))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-ARCHIVE-ACTIVE-closed-decision-before-io
  (dolist (version '(1 2))
    (dara-with-fixtures version (list (list (dara-put 7))) (list (dara-decision 7 17))
      (lambda (f d decisions)
        (io:chiudi (dar-fixture-input d)) (dar-clear d)
        (dara-preflight f d 'io-fault :io-unavailable
                        (lambda () (dara-call f decisions)) :closed t)
        (dara-closed-decision d)))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-ARCHIVE-ACTIVE-decision-revoked-during-header-or-body
  (dolist (version '(1 2))
    (dolist (close-offset '(0 64))
      (dara-with-fixtures version (list (list (dara-put 7))) (list (dara-decision 7 17))
        (lambda (f d decisions)
          (let ((closed 0) (delivered nil))
            (setf (av::av-fixture-hook f)
                  (lambda (fixture fd buffer start count offset)
                    (let ((n (av::av-transfer fixture fd buffer start count offset)))
                      (when (and (= offset close-offset) (zerop closed))
                        (io:chiudi (dar-fixture-input d)) (incf closed))
                      n)))
            (dar-expect 'io-fault :io-unavailable
                        (lambda () (setf delivered (dara-call f decisions))))
            (is (null delivered)) (is (= closed 1))
            (is (plusp (av::av-fixture-reads f)))
            (is (equalp (av::av-fixture-scratch f) (av::av-fixture-reference f)))
            (is (equal '((:close 401)) (dar-events d)))
            (av::av-noeffects f) (dara-closed-decision d)))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-scratch-alias-archive-before-range
  (dolist (version '(1 2))
    (dara-with-fixtures version nil nil
      (lambda (f d decisions)
        (let ((scratch (av::av-fixture-scratch f)))
          (unwind-protect
               (progn
                 (setf (av::av-fixture-scratch f)
                       (da::archivio-recovery-identity (dar-fixture-archive d)))
                 (dara-preflight f d 'invalid-argument :archive-recovery-alias
                                 (lambda () (dara-call f decisions))))
            (setf (av::av-fixture-scratch f) scratch)))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-nil-or-bare-table-type-error
  (dolist (version '(1 2))
    (dara-with-fixtures version nil nil
      (lambda (f d decisions)
        (is (typep decisions 'da:decisioni-recuperate))
        (dolist (bad (list nil (av::av-fixture-decisions f)))
          (dara-preflight f d 'type-error nil (lambda () (dara-call f bad))))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-all-eight-budget-types-before-io
  (dolist (version '(1 2))
    (dara-with-fixtures version nil nil
      (lambda (f d decisions)
        (dolist (key '(:chunk-bytes :max-bytes :max-batches :max-batch-records
                       :max-batch-bytes :max-records :max-prepared :max-outcomes))
          (dolist (value (list -1 nil :invalid 1/2
                              (if (member key '(:max-batch-records :max-prepared :max-outcomes))
                                  #x100000000 (1+ most-positive-fixnum))))
            (dara-preflight f d 'type-error nil
                            (lambda () (apply #'dara-call f decisions (list key value))))))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-invalid-budget-values-before-io
  (dolist (version '(1 2))
    (dara-with-fixtures version nil nil
      (lambda (f d decisions)
        (dolist (entry '((:chunk-bytes 0 :active-recovery-arguments)
                         (:max-bytes 63 :active-recovery-arguments)
                         (:max-batches 0 :log-scan-arguments)
                         (:max-batch-records 0 :log-scan-arguments)
                         (:max-batch-bytes 55 :log-scan-arguments)))
          (destructuring-bind (key value reason) entry
            (dara-preflight f d 'invalid-argument reason
                            (lambda () (apply #'dara-call f decisions (list key value))))))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-all-positive-exact-budgets
  (dolist (version '(1 2))
    (dara-with-fixtures version (dara-budget-batches) (list (dara-decision 9 23))
      (lambda (f d decisions)
        (let ((r (dara-compatible f d decisions :chunk-bytes 7
                                  :max-bytes (av::av-fixture-size f) :max-batches 2
                                  :max-batch-records 2 :max-batch-bytes 110
                                  :max-records 3 :max-prepared 2 :max-outcomes 1)))
          (is (equal '(2 3 2 1 1 0) (second (dara-snapshot r)))))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-byte-budget-forwarded-before-io
  (dolist (version '(1 2))
    (dara-with-fixtures version (dara-budget-batches) nil
      (lambda (f d decisions)
        (dara-preflight f d 'resource-exhausted :active-recovery-byte-budget
                        (lambda () (dara-call f decisions :max-bytes (1- (av::av-fixture-size f)))))))))

;;; REQ: REQ-AFF-008 REQ-AFF-009
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-scanner-budgets-preserve-canonical-errors
  (dolist (version '(1 2))
    (dara-with-fixtures version (dara-budget-batches) nil
      (lambda (f d decisions)
        (dolist (entry '((:max-batches 1 :log-batch-budget)
                         (:max-batch-records 1 :batch-record-budget)
                         (:max-batch-bytes 109 :batch-byte-budget)
                         (:max-records 2 :active-recovery-record-budget)
                         (:max-records 0 :active-recovery-record-budget)))
          (destructuring-bind (key value reason) entry
            (dara-reject-compatible f d decisions reason (list key value))))))))

;;; REQ: REQ-AFF-008 REQ-TXM-007
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-prepared-budget-zero-and-one
  (dolist (version '(1 2))
    (dara-with-fixtures version (dara-budget-batches) nil
      (lambda (f d decisions)
        (dolist (limit '(0 1))
          (dara-reject-compatible f d decisions :active-recovery-prepared-budget
                                  (list :max-prepared limit)))))))

;;; REQ: REQ-AFF-008 REQ-TXM-007
(deftest test-REQ-AFF-008-ARCHIVE-ACTIVE-outcome-budget-counts-physical-duplicates
  (dolist (version '(1 2))
    (dara-with-fixtures version (list (list (dara-put 7) '(:outcome 7 17) '(:outcome 7 17))) nil
      (lambda (f d decisions)
        (dara-compatible f d decisions :max-outcomes 2)
        (dolist (limit '(0 1))
          (dara-reject-compatible f d decisions :active-recovery-outcome-budget
                                  (list :max-outcomes limit)))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-007-ARCHIVE-ACTIVE-derived-local-abort-canonical-zero-max-u64
  (dolist (version '(1 2))
    (let ((batches (list (list (dara-put #xffffffffffffffff) (dara-put 0)
                               (dara-put 7) (dara-put 9) (dara-put 11)
                               '(:outcome 7 17) '(:outcome 11 0)))))
      (dara-with-fixtures version batches
          (list (dara-decision #xffffffffffffffff #xffffffffffffffff)
                (dara-decision 7 17) (dara-decision 0 0))
        (lambda (f d decisions)
          (let* ((r (dara-compatible f d decisions)) (snapshot (dara-snapshot r))
                 (expected (av::av-bytes 52)))
            (is (equal '(1 7 5 2 2 1) (second snapshot)))
            (is (equal '((t 0) (nil 0) (nil 0) (nil 0) (nil 0) (t #xffffffffffffffff))
                       (third snapshot)))
            ;; Entry CLOSED indipendente: soltanto i due commit derivati.
            (ct::crr-pack expected 0 9 8)
            (ct::crr-pack expected 8 (av::av-fixture-size f) 8)
            (ct::crr-pack expected 16 2 4)
            (ct::crr-pack expected 36 #xffffffffffffffff 8)
            (ct::crr-pack expected 44 #xffffffffffffffff 8)
            (is (equalp expected (subseq (fourth snapshot) 3 55)))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-AFF-009
(deftest test-REQ-TXM-007-ARCHIVE-ACTIVE-unsealed-decision-does-not-commit
  (dolist (version '(1 2))
    (dara-with-fixtures version (list (list (dara-put 9))) nil
      (lambda (f d decisions)
        (is (eq :tail (third (multiple-value-list (da:frontiere-decisioni-recuperate decisions)))))
        (let ((r (dara-compatible f d decisions :max-outcomes 0)))
          (is (equal '(1 1 1 0 0 1) (second (dara-snapshot r))))))
      :decision-tail (rt::reference-decision-record (dara-decision 9 23) version))))

;;; REQ: REQ-TXM-007 REQ-AFF-009
(deftest test-REQ-TXM-007-ARCHIVE-ACTIVE-unsealed-active-outcome-ignored
  (dolist (version '(1 2))
    (let ((prefix (length (av::av-log (list (list (dara-put 7))) :version version))))
      (dara-with-fixtures version (list (list (dara-put 7))) (list (dara-decision 7 17))
        (lambda (f d decisions)
          (let ((r (dara-compatible f d decisions :max-outcomes 0)))
            (is (equal (list (av::av-fixture-size f) prefix :tail version)
                       (first (dara-snapshot r))))
            (is (equal '(1 1 1 0 1 0) (second (dara-snapshot r))))))
        :active-tail (av::av-record '(:outcome 7 99) version)))))
