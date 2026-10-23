;;;; Guardie funzionali del recovery ACTIVE; file nativi e dipendenze reali.
;;; OWNER: runner seriale; fixture, scratch e deadline esclusivi per chiamata.
;;; SHARED: nessuna sostituzione globale o tabella DECISION parziale/fittizia.
;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-TXM-007 REQ-AFF-002 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.active.checkpoint.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(defun rag-read-unchanged (fixture deadline &rest options)
  "Pre: caso nativo aperto, deadline assoluta e opzioni pubbliche. Post: risultato completo, file invariati.
Le osservazioni escludono write/flush/rename/close; ogni errore inatteso propaga."
  (is (< (get-internal-real-time) deadline))
  (ra-reset-calls fixture)
  (let ((result (apply #'ra-read fixture options)))
    (ra-no-writes fixture)
    (ra-check-bytes fixture)
    (is (< (get-internal-real-time) deadline))
    result))

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(defun rag-error-unchanged (fixture deadline type reason thunk &key offset)
  "Pre: chiamata pubblica attesa fallire, fixture esclusiva. Post: tipo/reason/offset e file invariati.
Non cattura errori estranei alla gerarchia del prodotto; la condizione originale resta osservabile."
  (is (< (get-internal-real-time) deadline))
  (ra-reset-calls fixture)
  (let ((condition (handler-case (progn (funcall thunk) nil)
                     (arcdocdb.conditions:arcdocdb-error (failure) failure))))
    (is (typep condition type))
    (is (eq (arcdocdb.conditions:error-reason condition) reason))
    (is (eql (arcdocdb.conditions:error-offset condition) offset))
    (ra-no-writes fixture)
    (ra-check-bytes fixture)
    (is (< (get-internal-real-time) deadline))
    condition))

;;; REQ: REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-007-active-recovery-prepared-across-batches-rejected
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :prepared-put 101))
            (ra-batch 8 (ra-record :prepared-tombstone 101))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-prepared-batches
          (lambda () (ra-read fixture))
          :offset (first (getf (second (ra-case-layouts fixture)) :records)))))))

;;; REQ: REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-007-active-recovery-prepared-after-outcome-rejected
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :outcome 101 :csn 31) (ra-record :prepared-put 101))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-outcome-before-prepare
          (lambda () (ra-read fixture))
          :offset (second (getf (first (ra-case-layouts fixture)) :records)))))))

;;; REQ: REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-007-active-recovery-conflicting-outcomes-rejected
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :prepared-put 101)
                         (ra-record :outcome 101 :csn 31) (ra-record :outcome 101 :csn 32))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-outcome-conflict
          (lambda () (ra-read fixture))
          :offset (third (getf (first (ra-case-layouts fixture)) :records)))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-005-active-recovery-decision-must-name-this-series
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :prepared-put 101)))
      (list (ra-decision 101 31 (list (make-array 16 :element-type '(unsigned-byte 8) :initial-element 201)
                                    (make-array 16 :element-type '(unsigned-byte 8) :initial-element 202))))
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-participant
          (lambda () (ra-read fixture)))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-REC-001
(deftest test-REQ-TXM-007-active-recovery-decision-csn-must-match-local-outcome
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :prepared-put 101) (ra-record :outcome 101 :csn 31)))
      (list (ra-decision 101 32))
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-decision-conflict
          (lambda () (ra-read fixture)))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-active-recovery-byte-budget-exact-and-one-under
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (let* ((size (length (ra-case-bytes fixture)))
               (result (rag-read-unchanged fixture deadline :max-bytes size)))
          (is (equal (list size size :complete version)
                     (multiple-value-list (ra:frontiere-active-recuperato result))))
          (rag-error-unchanged fixture deadline 'arcdocdb.conditions:resource-exhausted :active-recovery-byte-budget
            (lambda () (ra-read fixture :max-bytes (1- size)))))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-active-recovery-record-budget-excludes-seal
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :put 7) (ra-record :tombstone 7) (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (let ((result (rag-read-unchanged fixture deadline :max-records 3)))
          (is (equal '(1 3 0 0 0 0) (multiple-value-list (ra:statistiche-active-recuperato result)))))
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:resource-exhausted :active-recovery-record-budget
          (lambda () (ra-read fixture :max-records 2)))))))

;;; REQ: REQ-AFF-008 REQ-TXM-007 REQ-REC-001
(deftest test-REQ-AFF-008-active-recovery-prepared-budget-counts-distinct-txids
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :prepared-put 101) (ra-record :prepared-tombstone 102)
                         (ra-record :prepared-put 101))) nil
      (lambda (fixture deadline)
        (let ((result (rag-read-unchanged fixture deadline :max-prepared 2)))
          (is (equal '(1 3 2 0 0 2) (multiple-value-list (ra:statistiche-active-recuperato result)))))
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:resource-exhausted :active-recovery-prepared-budget
          (lambda () (ra-read fixture :max-prepared 1))
          :offset (second (getf (first (ra-case-layouts fixture)) :records)))))))

;;; REQ: REQ-AFF-008 REQ-TXM-007 REQ-REC-001
(deftest test-REQ-AFF-008-active-recovery-outcome-budget-counts-physical-duplicates
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :prepared-put 101)
                         (ra-record :outcome 101 :csn 0) (ra-record :outcome 101 :csn 0))) nil
      (lambda (fixture deadline)
        (let ((result (rag-read-unchanged fixture deadline :max-outcomes 2)))
          (is (equal '(1 3 1 1 0 0) (multiple-value-list (ra:statistiche-active-recuperato result)))))
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:resource-exhausted :active-recovery-outcome-budget
          (lambda () (ra-read fixture :max-outcomes 1))
          :offset (third (getf (first (ra-case-layouts fixture)) :records)))))))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-STO-003
(deftest test-REQ-AFF-009-active-recovery-tail-kept-after-last-complete-batch
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (let* ((prefix (getf (first (ra-case-layouts fixture)) :end))
               (result (rag-read-unchanged fixture deadline)))
          (is (equal (list (+ prefix 3) prefix :tail version)
                     (multiple-value-list (ra:frontiere-active-recuperato result))))
          (is (equal '(1 1 0 0 0 0) (multiple-value-list (ra:statistiche-active-recuperato result))))))
      :tail (make-array 3 :element-type '(unsigned-byte 8) :initial-contents '(255 170 187)))))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-AFF-002
(deftest test-REQ-AFF-009-active-recovery-durable-witness-rejects-damaged-middle-batch
  (dolist (version '(1 2))
    (ra-with-case version
      (list (ra-batch 7 (ra-record :put 7)) (ra-batch 8 (ra-record :put 8))
            (ra-batch 9 (ra-record :put 9))) nil
      (lambda (fixture deadline)
        (let* ((layouts (ra-case-layouts fixture)) (prefix (getf (second layouts) :start))
               (condition (rag-error-unchanged fixture deadline 'arcdocdb.recovery.scan:log-corruption
                            :log-durable-corruption (lambda () (ra-read fixture)) :offset prefix)))
          (is (= prefix (arcdocdb.recovery.scan:corruption-prefix-end condition)))
          (is (= (getf (third layouts) :seal) (arcdocdb.recovery.scan:corruption-witness-offset condition)))
          (is (= (getf (third layouts) :start) (arcdocdb.recovery.scan:corruption-durable-offset condition)))
          (is (eq :body-crc (arcdocdb.recovery.scan:corruption-first-reason condition)))))
      :mutate (lambda (bytes layouts)
                (let ((body (+ 24 (first (getf (second layouts) :records)))))
                  (setf (aref bytes body) (logxor 1 (aref bytes body))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-active-recovery-identity-scratch-alias-rejected-before-range
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:invalid-argument :active-recovery-alias
          (lambda ()
            (ra:leggi-active-recuperato (ra-case-control fixture) (ra-case-input fixture)
              (length (ra-case-bytes fixture)) (ra-case-decisions fixture)
              (g::vista-get-serie-identity (ra-case-view fixture)))))))))

;;; REQ: REQ-FOR-001 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-FOR-001-active-recovery-header-id-must-match-control-active
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :segment-identity
          (lambda () (ra-read fixture)) :offset 0))
      :mutate (lambda (bytes layouts)
                (is (= 64 (getf (first layouts) :start)))
                (setf (aref bytes 32) (logxor 1 (aref bytes 32)))
                (ct::control-pack bytes 56 (ct::control-crc bytes 0 56) 4)))))

;;; REQ: REQ-FOR-001 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-FOR-001-active-recovery-compaction-origin-is-not-active
  (dolist (version '(1 2))
    (ra-with-case version (list (ra-batch 7 (ra-record :put 7))) nil
      (lambda (fixture deadline)
        (rag-error-unchanged fixture deadline 'arcdocdb.conditions:corruption-detected :active-recovery-origin
          (lambda () (ra-read fixture))))
      :mutate (lambda (bytes layouts)
                (is (= 64 (getf (first layouts) :start)))
                (setf (aref bytes 10) 2)
                (ct::control-pack bytes 56 (ct::control-crc bytes 0 56) 4)))))
