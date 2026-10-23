;;;; Composizione C1 osservata da oracoli C4: un solo EOF e nessun effetto durevole.
;;; OWNER: fixture e capacità private; nessuna sostituzione globale nelle prove concorrenti.
(in-package #:arcdocdb.recovery.tests)

(defun idrd-call (manifest directory &rest options)
  (apply #'arcdocdb.recovery.manifest:scegli-id-segmento-recovery-directory
         manifest directory options))

(defun idrd-check (state directory manifest active closed removed specs expected &rest options)
  "Tre valori, una enumerazione, piano canonico e input/capacità invariati."
  (let* ((names (map 'simple-vector #'copy-seq (idr-state-names state)))
         (before (idr-observation directory)) (calls (idr-enumerations state))
         (result (multiple-value-list (apply #'idrd-call manifest directory options))))
    (is (= 3 (length result))) (is (= expected (first result)))
    (is (= (1+ expected) (second result)))
    (is (= (1+ calls) (idr-enumerations state)))
    (is (equalp names (idr-state-names state))) (is (equal before (idr-observation directory)))
    (inventory-assert-plan (third result) (inventory-oracle active closed removed specs))
    (third result)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-directory-id-finite-model-one-enumeration
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 3 '(0) '(1) :version version)))
      (dotimes (number 1024)
        (let* ((specs (inventory-small-files number))
               (expected (loop for candidate from 4 to 8
                               when (every (lambda (file) (< (first file) candidate)) specs)
                                 return candidate)))
          (dolist (ordered (inventory-input-orders specs))
            (idr-run (idr-names ordered "control.log" ".hidden")
              (lambda (state directory)
                (idrd-check state directory manifest 3 '(0) '(1) specs expected)
                (is (= (length specs) (count :identity (idr-state-events state) :key #'first)))))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-directory-id-high-water-orphans-and-health
  (dolist (version '(1 2))
    (let ((manifest (inventory-fixture-manifest
                     (list (manifest-spec :completo t :next-id 100 :open 7
                                          :chiusi '((0 64 nil)) :rimossi '(99))) :version version)))
      (dolist (case '((((7 :final) (0 :final)) 100)
                      (((7 :temporary) (0 :final) (120 :temporary)) 121)
                      (((7 :final) (0 :final) (120 :final)) 121)
                      (((7 :final) (0 :final) (120 :final) (120 :temporary)) 121)
                      (((7 :final) (99 :temporary)) 100)
                      (() 100)))
        (destructuring-bind (specs expected) case
          (idr-run (idr-names specs)
            (lambda (state directory)
              (idrd-check state directory manifest 7 '(0) '(99) specs expected))))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-REC-001-directory-id-u64-frontiers-and-error-order
  (let ((maximum #xffffffffffffffff))
    (dolist (version '(1 2))
      (let ((manifest (inventory-manifest 7 nil nil :version version)))
        (dolist (id (list 0 (ash 1 63) (- maximum 2)))
          (let ((specs (list '(7 :final) (list id :temporary))))
            (idr-run (idr-names specs)
              (lambda (state directory)
                (idrd-check state directory manifest 7 nil nil specs (if (zerop id) 8 (1+ id)))))))
        (dolist (id (list (1- maximum) maximum))
          (idr-run (idr-names (list '(7 :final) (list id :temporary)))
            (lambda (state directory)
              (signals resource-exhausted (idrd-call manifest directory) :recovery-segment-id-exhausted)
              (is (= 1 (idr-enumerations state)))
              (is (equal '(:open 0 0) (idr-observation directory)))))))
      (dolist (specs (list (list (manifest-spec :completo t :next-id maximum :open 7))
                          (list (inventory-snapshot 7 nil nil)
                                (manifest-spec :open maximum :chiusi '((7 64 nil))))))
        (let ((manifest (inventory-fixture-manifest specs :version version)))
          (idr-run #()
            (lambda (state directory)
              (signals resource-exhausted (idrd-call manifest directory) :recovery-segment-id-exhausted)
              (is (= 1 (idr-enumerations state)))))
          (idr-run (vector "not-canonical.seg")
            (lambda (state directory)
              (signals corruption-detected (idrd-call manifest directory) :inventory-segment-name)
              (is (= 1 (idr-enumerations state))))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-directory-id-five-budgets-exact-and-one-under
  (let* ((manifest (inventory-manifest 7 nil nil)) (specs '((7 :final) (120 :temporary))))
    (idr-run (idr-names specs "abc")
      (lambda (state directory)
        (idrd-check state directory manifest 7 nil nil specs 121
                    :max-files 2 :max-segmenti 1 :max-names 3
                    :max-total-name-bytes 47 :max-name-bytes 24)
        (is (equal '(:enumerate 3 47 24) (find :enumerate (idr-state-events state) :key #'first)))
        (dolist (budget '((:max-files 1 :inventory-file-budget)
                          (:max-segmenti 0 :inventory-segment-budget)
                          (:max-names 2 :io-directory-names)
                          (:max-total-name-bytes 46 :io-directory-total-name-bytes)
                          (:max-name-bytes 23 :io-directory-name-bytes)))
          (signals resource-exhausted
                   (idrd-call manifest directory (first budget) (second budget)) (third budget)))
        (is (equal '(:open 0 0) (idr-observation directory)))))
    (idr-run #()
      (lambda (state directory)
        (idrd-check state directory manifest 7 nil nil nil 8 :max-files 0 :max-segmenti 1
                    :max-names 0 :max-total-name-bytes 0 :max-name-bytes 1)))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-directory-id-invalid-before-enumeration
  (let ((manifest (inventory-manifest 7 nil nil)))
    (idr-run #()
      (lambda (state directory)
        (dolist (key '(:max-files :max-segmenti))
          (signals invalid-argument (idrd-call manifest directory key -1) :inventory-budget)
          (signals type-error (idrd-call manifest directory key :invalid)))
        (dolist (spec '((:max-names -1) (:max-total-name-bytes -1)
                        (:max-name-bytes 0) (:max-name-bytes 256) (:max-names :invalid)))
          (signals invalid-argument (apply #'idrd-call manifest directory spec) :io-directory-budget))
        (is (zerop (idr-enumerations state)))))
    (idr-run #() (lambda (state directory)
                   (signals unsupported-format (idrd-call manifest directory) :io-directory-unavailable)
                   (is (zerop (idr-enumerations state)))) :enumeration-p nil)
    (idr-run #() (lambda (state directory)
                   (signals unsupported-format (idrd-call manifest directory) :io-entry-identity-unavailable)
                   (is (zerop (idr-enumerations state)))) :identity-p nil)
    (idr-run #() (lambda (state directory)
                   (signals invalid-argument (idrd-call manifest directory) :io-mode)
                   (is (zerop (idr-enumerations state)))) :mode :input)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-001-directory-id-original-errors-no-partial-result
  (let ((manifest (inventory-manifest 7 nil nil)))
    (idr-run #()
      (lambda (state directory)
        (setf (idr-state-complete state) nil)
        (signals arcdocdb.conditions:invariant-violation (idrd-call manifest directory)
                 :io-directory-result)))
    (idr-run (idr-names '((7 :final) (8 :temporary)))
      (lambda (state directory)
        (setf (idr-state-identity-hook state)
              (lambda (current name) (declare (ignore current name)) (values 1 1)))
        (signals corruption-detected (idrd-call manifest directory) :inventory-physical-alias)))
    (idr-run #()
      (lambda (state directory)
        (let ((original (make-condition 'arcdocdb.conditions:io-fault
                                       :reason :directory-id-injected :operation :directory-entries)))
          (setf (idr-state-enum-hook state)
                (lambda (current) (declare (ignore current)) (error original)))
          (is (eq original (signals arcdocdb.conditions:io-fault
                             (idrd-call manifest directory) :directory-id-injected))))))
    (idr-run #()
      (lambda (state directory)
        (setf (idr-state-enum-hook state)
              (lambda (current) (arcdocdb.io:chiudi (idr-state-directory current))))
        (signals arcdocdb.conditions:io-fault (idrd-call manifest directory) :io-unavailable)
        (is (eq :closed (arcdocdb.io:stato-file directory)))))))

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-directory-id-owned-plan-and-no-reservation
  (let* ((manifest (inventory-manifest 7 '(1) nil)) (specs '((7 :final) (1 :temporary) (9 :final))))
    (idr-run (idr-names specs)
      (lambda (state directory)
        (let ((first (idrd-check state directory manifest 7 '(1) nil specs 10))
              (second (idrd-check state directory manifest 7 '(1) nil specs 10)))
          (is (not (eq first second)))
          (loop for name across (idr-state-names state) do (fill name #\Z))
          (inventory-assert-plan first (inventory-oracle 7 '(1) nil specs))
          (inventory-assert-plan second (inventory-oracle 7 '(1) nil specs)))))))

(defun idrd-worker (number gate)
  (is (sb-thread:wait-on-semaphore gate :timeout 10))
  (let* ((active (+ 7 (* number 10))) (orphan (+ active 8))
         (manifest (inventory-manifest active nil nil))
         (specs (list (list active :final) (list orphan :temporary))))
    (idr-run (idr-names specs)
      (lambda (state directory)
        (dotimes (iteration 16)
          (idrd-check state directory manifest active nil nil specs (1+ orphan))))))
  t)

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-directory-id-four-private-series
  (let ((gate (sb-thread:make-semaphore :count 0)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (number 4)
             (let ((serie number))
               (push (sb-thread:make-thread
                      (lambda () (handler-case (idrd-worker serie gate) (error (condition) condition)))
                      :name (format nil "directory-id-serie-~D" serie)) threads)))
           (sb-thread:signal-semaphore gate 4)
           (dolist (thread threads)
             (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
               (when (typep result 'error) (error result)) (is (eq t result)))))
      (inventory-stop-workers threads))))

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-directory-id-native-repeat-byte-preservation-v1-v2
  (dolist (version '(1 2))
    (arcdocdb.control.tests::native-run-case
     (lambda (fixture deadline)
       (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
              (specs '((7 :final) (1 :temporary) (120 :temporary) (121 :final)))
              (files (loop for spec in specs collect
                       (idr-native-file fixture path (idr-name (first spec) (second spec)) deadline)))
              (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
              (manifest (inventory-manifest 7 '(1) nil :version version))
              (before (idr-native-check-files files deadline)))
         (dotimes (iteration 2)
           (multiple-value-bind (id next plan)
               (arcdocdb.control.tests::native-bounded deadline :directory-id
                 (lambda () (idrd-call manifest directory :max-files 4 :max-segmenti 2
                                      :max-names 4 :max-total-name-bytes 88 :max-name-bytes 24)))
             (is (= id 122)) (is (= next 123))
             (inventory-assert-plan plan (inventory-oracle 7 '(1) nil specs))))
         (signals resource-exhausted (idrd-call manifest directory :max-names 3) :io-directory-names)
         (is (equal before (idr-native-check-files files deadline)))
         (is (eq :open (arcdocdb.io:stato-file directory))))))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-directory-id-native-parent-rename-and-exhaustion
  (arcdocdb.control.tests::native-run-case
   (lambda (fixture deadline)
     (let* ((parent (arcdocdb.control.tests::native-directory fixture "parent/" deadline))
            (path (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline))
            (moved (arcdocdb.control.tests::native-register-directory fixture
                     (merge-pathnames "moved/" (arcdocdb.control.tests::native-fixture-root fixture))))
            (moved-owned (arcdocdb.control.tests::native-register-directory fixture
                           (merge-pathnames "owned/" moved)))
            (file (idr-native-file fixture path (idr-name 120 :temporary) deadline))
            (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
            (manifest (inventory-manifest 7 nil nil)))
       (arcdocdb.control.tests::native-leaf fixture moved-owned (idr-name 120 :temporary))
       (sb-posix:rename (namestring parent) (namestring moved))
       (arcdocdb.control.tests::native-directory fixture "parent/" deadline)
       (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline)
       (let* ((decoy (idr-native-file fixture path (idr-name #xffffffffffffffff :final) deadline))
              (replacement (arcdocdb.control.tests::native-open fixture path :directory deadline nil)))
         (is (equal '(121 122) (subseq (multiple-value-list (idrd-call manifest directory)) 0 2)))
         (signals resource-exhausted (idrd-call manifest replacement) :recovery-segment-id-exhausted)
         (idr-native-check-files (list file decoy) deadline)
         (is (eq :open (arcdocdb.io:stato-file directory)))
         (is (eq :open (arcdocdb.io:stato-file replacement))))))))
