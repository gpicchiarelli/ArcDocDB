;;;; ADR0040§3: decisioni sui nomi da manifest autorevole e inventario completo.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-adr-action-table
  (let ((specs '((7 :final) (1 :final) (2 :temporary) (3 :final) (4 :temporary)
                 (9 :temporary) (10 :final))))
    (dolist (version '(1 2))
      (let* ((manifest (inventory-manifest 7 '(1 2) '(3 4) :version version))
             (plan (inventory-check manifest 7 '(1 2) '(3 4) specs)))
        (is (equal '((1 :final :use :closed) (2 :temporary :rename :closed)
                     (3 :final :delete :removed) (4 :temporary :delete :removed)
                     (7 :final :use :active) (9 :temporary :delete :unknown)
                     (10 :final :anomaly :unknown)) (inventory-plan-rows plan)))
        (inventory-check manifest 7 '(1 2) '(3 4)
                         '((7 :temporary) (1 :final) (2 :final)))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-zero-closed-and-removed
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 7 '(0) nil :version version)))
      (inventory-check manifest 7 '(0) nil '((0 :final) (7 :final)))
      (let ((plan (inventory-check manifest 7 '(0) nil '((7 :temporary)))))
        (is (equal '(0 :absent :missing :closed)
                   (multiple-value-list
                     (arcdocdb.recovery.manifest:azione-riconciliazione plan 0))))
        (is (eq :degraded (arcdocdb.recovery.manifest:stato-riconciliazione plan)))))
    (let ((manifest (inventory-manifest 7 nil '(0) :version version)))
      (inventory-check manifest 7 nil '(0) '((0 :final) (7 :final)))
      (inventory-check manifest 7 nil '(0) '((0 :temporary) (7 :final)))
      (is (= 1 (arcdocdb.recovery.manifest:numero-azioni-riconciliazione
                 (inventory-check manifest 7 nil '(0) '((7 :final)))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-002-inventory-missing-live-and-health-priority
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 7 '(1 2) '(3 4) :version version)))
      (dolist (specs '(() ((7 :final)) ((1 :temporary) (2 :final))
                       ((7 :final) (1 :final) (2 :temporary) (10 :final))
                       ((7 :temporary) (1 :final) (2 :final) (9 :temporary))))
        (inventory-check manifest 7 '(1 2) '(3 4) specs))
      (let ((plan (inventory-check manifest 7 '(1 2) '(3 4) nil)))
        (is (equal '((1 :absent :missing :closed) (2 :absent :missing :closed)
                     (7 :absent :missing :active)) (inventory-plan-rows plan)))
        (is (eq :faulted (arcdocdb.recovery.manifest:stato-riconciliazione plan)))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-002-inventory-both-names-always-conservative
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 7 '(1) '(3) :version version)))
      (dolist (id '(1 3 7 9))
        (let* ((specs (append (unless (= id 7) '((7 :final)))
                              (unless (= id 1) '((1 :final)))
                              (list (list id :temporary) (list id :final))))
               (plan (inventory-check manifest 7 '(1) '(3) specs))
               (row (assoc id (inventory-plan-rows plan))))
          (is (eq :both (second row))) (is (eq :conflict (third row))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-exhaustive-small-model-and-input-orders
  ;; 1.024 inventari × due versioni × tre ordini = 6.144 piani confrontati.
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 3 '(0 1) '(2) :version version)))
      (dotimes (number 1024)
        (let* ((specs (inventory-small-files number))
               (expected (inventory-oracle 3 '(0 1) '(2) specs)))
          (dolist (ordered (inventory-input-orders specs))
            (inventory-assert-plan
             (inventory-check manifest 3 '(0 1) '(2) ordered) expected))))))
  ;; Sei nomi distinti: tutte le 720 permutazioni, incluse le due forme dello stesso ID.
  (let ((specs '((7 :final) (0 :temporary) (2 :final) (9 :temporary) (9 :final) (10 :final))))
    (dolist (version '(1 2))
      (let ((manifest (inventory-manifest 7 '(0) '(2) :version version)))
        (dolist (ordered (inventory-permutations specs))
          (inventory-check manifest 7 '(0) '(2) ordered))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-duplicates-and-invalid-entries
  (let ((manifest (inventory-manifest 7 nil nil)))
    (dolist (form '(:temporary :final))
      (let* ((files (inventory-files (list (list 7 form) (list 9 :final) (list 7 form))))
             (before (copy-seq files))
             (condition (signals invalid-argument
                          (arcdocdb.recovery.manifest:pianifica-riconciliazione manifest files)
                          :inventory-duplicate)))
        (is (= 2 (error-offset condition))) (is (every #'eq before files)))
      (let* ((file (arcdocdb.recovery.manifest:file-segmento 0 form))
             (condition (signals invalid-argument
                          (arcdocdb.recovery.manifest:pianifica-riconciliazione
                            manifest (vector file file)) :inventory-duplicate)))
        (is (= 1 (error-offset condition))))
      (let ((condition (signals invalid-argument
                         (arcdocdb.recovery.manifest:pianifica-riconciliazione
                           manifest (inventory-files (list '(7 :temporary) '(7 :final)
                                                           (list 7 form))))
                         :inventory-duplicate)))
        (is (= 2 (error-offset condition)))))
    (dolist (wrong '(nil :final 7))
      (let* ((files (vector (arcdocdb.recovery.manifest:file-segmento 7 :final) wrong))
             (condition (signals invalid-argument
                          (arcdocdb.recovery.manifest:pianifica-riconciliazione manifest files)
                          :inventory-entry)))
        (is (= 1 (error-offset condition))) (is (eq wrong (aref files 1)))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-physical-and-live-budgets
  (let* ((manifest (inventory-manifest 7 '(1 2) '(3)))
         (specs '((7 :final) (1 :temporary) (2 :final) (3 :final)
                  (9 :temporary) (10 :final)))
         (files (inventory-files specs)))
    (inventory-check manifest 7 '(1 2) '(3) specs :max-files 6 :max-segmenti 3)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:pianifica-riconciliazione
               manifest files :max-files 5 :max-segmenti 3) :inventory-file-budget)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:pianifica-riconciliazione
               manifest files :max-files 6 :max-segmenti 2) :inventory-segment-budget)
    (inventory-check manifest 7 '(1 2) '(3) nil :max-files 0 :max-segmenti 3)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:pianifica-riconciliazione
               manifest #() :max-files 0 :max-segmenti 0) :inventory-segment-budget)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:pianifica-riconciliazione
               manifest (inventory-files '((7 :final) (7 :temporary))) :max-files 1)
             :inventory-file-budget)
    ;; I budget fisici precedono la validazione delle entry e dei duplicati.
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:pianifica-riconciliazione
               manifest (vector nil) :max-files 0) :inventory-file-budget)))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-budget-counts-live-not-output-rows
  (let* ((removed (loop for id below 6 collect id))
         (manifest (inventory-manifest 7 nil removed))
         (specs (cons '(7 :final)
                      (loop for id from 10 below 50 collect (list id :temporary)))))
    (let ((plan (inventory-check manifest 7 nil removed specs :max-files 41 :max-segmenti 1)))
      (is (= 41 (arcdocdb.recovery.manifest:numero-azioni-riconciliazione plan)))
      (is (eq :ready (arcdocdb.recovery.manifest:stato-riconciliazione plan))))
    (inventory-check manifest 7 nil removed '((7 :final) (0 :final))
                     :max-files 2 :max-segmenti 1)))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-invalid-arguments-and-query-range
  (let* ((manifest (inventory-manifest 7 nil nil))
         (plan (inventory-check manifest 7 nil nil '((7 :final)))))
    (dolist (key '(:max-files :max-segmenti))
      (dolist (value (list -1 (1+ most-positive-fixnum)))
        (signals invalid-argument
                 (apply #'arcdocdb.recovery.manifest:pianifica-riconciliazione
                        manifest #() (list key value)) :inventory-budget))
      (signals type-error
               (inventory-indirect-call 'arcdocdb.recovery.manifest:pianifica-riconciliazione
                                        manifest #() key :invalid)))
    (dolist (id (list -1 (ash 1 64) :invalid))
      (signals type-error (inventory-indirect-call
                           'arcdocdb.recovery.manifest:file-segmento id :final)))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:file-segmento 7 :absent))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:pianifica-riconciliazione manifest nil))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:pianifica-riconciliazione nil #()))
    (dolist (position '(-1 1 2 18446744073709551615))
      (signals invalid-argument
               (arcdocdb.recovery.manifest:azione-riconciliazione plan position)
               :reconciliation-index))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:azione-riconciliazione plan :invalid))
    (dolist (function '(arcdocdb.recovery.manifest:stato-riconciliazione
                        arcdocdb.recovery.manifest:numero-azioni-riconciliazione))
      (signals type-error (inventory-indirect-call function nil)))
    (inventory-assert-plan plan (inventory-oracle 7 nil nil '((7 :final))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-unsigned-u64-order-and-exact-identities
  (let* ((maximum #xffffffffffffffff)
         (closed (list 0 1 (ash 1 32) (1+ (ash 1 32)) (ash 1 63) maximum))
         (specs (list (manifest-spec :completo t :next-id maximum :open 7
                                    :chiusi (mapcar (lambda (id) (list id 64 nil))
                                                    (butlast closed)))
                      (manifest-spec :chiusi (list (list maximum 64 nil)))))
         (files (append (mapcar (lambda (id) (list id :final)) (reverse closed))
                        '((7 :temporary) (18446744073709551614 :final)))))
    (dolist (version '(1 2))
      (let* ((manifest (inventory-fixture-manifest specs :version version))
             (plan (inventory-check manifest 7 closed nil files)))
        (is (equal (list 0 1 7 (ash 1 32) (1+ (ash 1 32)) (ash 1 63)
                         (1- maximum) maximum)
                   (mapcar #'first (inventory-plan-rows plan))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-maximum-u64-active
  (let* ((maximum #xffffffffffffffff)
         (specs (list (inventory-snapshot 7 nil nil)
                      (manifest-spec :open maximum :chiusi '((7 64 nil)))))
         (files (list (list maximum :final) '(7 :temporary))))
    (dolist (version '(1 2))
      (let* ((manifest (inventory-fixture-manifest specs :version version))
             (plan (inventory-check manifest maximum '(7) nil files)))
        (is (equal (list maximum :final :use :active)
                   (multiple-value-list
                     (arcdocdb.recovery.manifest:azione-riconciliazione plan 1))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-inventory-plan-owns-data-after-input-reuse
  (let* ((specs '((7 :temporary) (0 :final) (2 :final) (9 :temporary) (10 :final)))
         (expected (inventory-oracle 7 '(0 1) '(2) specs)))
    (dolist (version '(1 2))
      (multiple-value-bind (manifest buffer) (inventory-manifest 7 '(0 1) '(2) :version version)
        (multiple-value-bind (plan files) (inventory-check manifest 7 '(0 1) '(2) specs)
          (fill files nil) (fill buffer #xaa)
          (loop repeat 3 do (inventory-assert-plan plan expected))
          (inventory-check manifest 7 '(0 1) '(2) specs)
          (let ((replacement (inventory-check manifest 7 '(0 1) '(2)
                                               '((7 :final) (0 :temporary) (1 :final)))))
            (is (eq :ready (arcdocdb.recovery.manifest:stato-riconciliazione replacement)))
            (inventory-assert-plan plan expected)))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-inventory-four-private-series-and-shared-plan
  (let* ((active 7) (closed '(0 1)) (removed '(2))
         (specs '((7 :final) (0 :temporary) (1 :final) (2 :final) (9 :final)))
         (expected (inventory-oracle active closed removed specs))
         (gate (sb-thread:make-semaphore :count 0)) (threads nil))
    (multiple-value-bind (manifest buffer) (inventory-manifest active closed removed)
      (multiple-value-bind (common files) (inventory-check manifest active closed removed specs)
        (fill files nil) (fill buffer #xff)
        (inventory-assert-plan common expected)
        (unwind-protect
             (progn
               (dotimes (number 4)
                 (let ((serie number))
                   (push (sb-thread:make-thread
                          (lambda ()
                            (handler-case (inventory-parallel-worker serie gate common expected)
                              (error (condition) condition)))
                          :name (format nil "inventory-serie-~D" serie)) threads)))
               (sb-thread:signal-semaphore gate 4)
               (dolist (thread threads)
                 (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
                   (when (typep result 'error) (error result))
                   (is (eq t result)))))
          (inventory-stop-workers threads))))))
