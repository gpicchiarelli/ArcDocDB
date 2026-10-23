;;;; C4 nativo: namespace CONTROL 0700, file piccoli, nessun worker o cleanup per scansione.
;;; OWNER: registro CONTROL possiede ogni nome e FD prima degli effetti; directory backend NIL.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-native-repeat-and-independent-cursor-v1-v2
  (dolist (version '(1 2))
    (arcdocdb.control.tests::native-run-case
     (lambda (fixture deadline)
       (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
              (specs (append '((7 :final) (0 :final) (1 :temporary) (3 :final))
                             (loop for id from 10 to 18 collect (list id :temporary))))
              (files (loop for spec in specs collect
                       (idr-native-file fixture path (idr-name (first spec) (second spec)) deadline)))
              (ignored (idr-native-file fixture path ".unknown" deadline))
              (manifest (inventory-manifest 7 '(0 1) '(3) :version version))
              (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil)))
         (push ignored files)
         (let ((names (arcdocdb.io:elenca-directory directory))
               (before (arcdocdb.control.tests::native-observation directory)))
           (loop repeat 3 do
             (idr-native-check fixture directory manifest 7 '(0 1) '(3) specs files deadline)
             (is (equalp (sort (copy-seq names) #'string<)
                         (sort (arcdocdb.io:elenca-directory directory) #'string<))))
           (is (equal before (arcdocdb.control.tests::native-observation directory)))
           (is (= 14 (length names)))))))))

;;; REQ: REQ-REC-002 REQ-REC-004 REQ-AFF-018
(deftest test-REQ-REC-002-inventory-directory-native-missing-and-conflicting-names
  (dolist (version '(1 2))
    (dolist (specs '(() ((7 :final)) ((1 :temporary))
                     ((7 :final) (7 :temporary) (1 :final))))
      (arcdocdb.control.tests::native-run-case
       (lambda (fixture deadline)
         (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
                (files (loop for spec in specs collect
                         (idr-native-file fixture path (idr-name (first spec) (second spec)) deadline)))
                (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
                (manifest (inventory-manifest 7 '(1) nil :version version)))
           (when (null specs)
             (loop repeat 2 do
               (is (equalp '(#() t) (multiple-value-list
                                     (arcdocdb.io:elenca-directory directory
                                       :max-names 0 :max-total-name-bytes 0))))))
           (idr-native-check fixture directory manifest 7 '(1) nil specs files deadline)))))))

;;; REQ: REQ-AFF-008 REQ-REC-001 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-directory-native-budget-failure-keeps-parent-reusable
  (arcdocdb.control.tests::native-run-case
   (lambda (fixture deadline)
     (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
            (files (list (idr-native-file fixture path (idr-name 7 :final) deadline)
                         (idr-native-file fixture path "abc" deadline)))
            (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
            (before (arcdocdb.control.tests::native-observation directory)))
       (flet ((enumerate (&rest options)
                (arcdocdb.control.tests::native-bounded deadline :inventory-directory
                  (lambda () (apply #'arcdocdb.io:elenca-directory directory options)))))
         (multiple-value-bind (names complete)
             (enumerate :max-names 2 :max-total-name-bytes 23 :max-name-bytes 20)
           (is (eq complete t))
           (is (equal (list (idr-name 7 :final) "abc") (coerce (sort names #'string<) 'list))))
         (dolist (spec '((:max-names 1 :io-directory-names)
                         (:max-total-name-bytes 22 :io-directory-total-name-bytes)
                         (:max-name-bytes 19 :io-directory-name-bytes)))
           (signals resource-exhausted (enumerate (first spec) (second spec)) (third spec))
           (is (equal before (arcdocdb.control.tests::native-observation directory)))
           (is (= 2 (length (enumerate))))))
       (idr-native-check fixture directory (inventory-manifest 7 nil nil)
                         7 nil nil '((7 :final)) files deadline)))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-native-hardlink-alias-unchanged
  (arcdocdb.control.tests::native-run-case
   (lambda (fixture deadline)
     (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
            (file (idr-native-file fixture path (idr-name 7 :final) deadline))
            (alias (arcdocdb.control.tests::native-leaf fixture path (idr-name 1 :final)))
            (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil)))
       (sb-posix:link (namestring (first file)) (namestring alias))
       (is (equal (arcdocdb.control.tests::native-path-identity (first file))
                  (arcdocdb.control.tests::native-path-identity alias)))
       (let ((before (idr-native-check-files (list file) deadline)))
         (signals corruption-detected
           (idr-native-plan directory (inventory-manifest 7 '(1) nil) deadline)
           :inventory-physical-alias)
         (is (equal before (idr-native-check-files (list file) deadline)))
         (is (equal (arcdocdb.control.tests::native-path-identity (first file))
                    (arcdocdb.control.tests::native-path-identity alias)))
         (is (eq :open (arcdocdb.io:stato-file directory))))))))

;;; REQ: REQ-AFF-008 REQ-REC-001 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-directory-native-symlink-fifo-directory-rejected
  (dolist (kind '(:symlink :fifo :directory))
    (arcdocdb.control.tests::native-run-case
     (lambda (fixture deadline)
       (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
              (file (idr-native-file fixture path (idr-name 7 :final) deadline))
              (name (idr-name 1 :final))
              (bad (if (eq kind :directory)
                       (arcdocdb.control.tests::native-directory fixture (concatenate 'string name "/") deadline)
                       (arcdocdb.control.tests::native-leaf fixture path name)))
              (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil)))
         (ecase kind
           (:symlink (sb-posix:symlink (namestring (first file)) (namestring bad)))
           (:fifo (sb-posix:mkfifo (namestring bad) #o600))
           (:directory (is (sb-posix:s-isdir (sb-posix:stat-mode (sb-posix:lstat (namestring bad)))))))
         (let ((before (idr-native-check-files (list file) deadline)))
           (signals arcdocdb.conditions:io-fault
             (idr-native-plan directory (inventory-manifest 7 '(1) nil) deadline) :io-entry-kind)
           (is (equal before (idr-native-check-files (list file) deadline)))
           (is (eq :open (arcdocdb.io:stato-file directory)))))))))

;;; REQ: REQ-AFF-008 REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-native-parent-rename-anchors-original-fd
  (arcdocdb.control.tests::native-run-case
   (lambda (fixture deadline)
     (let* ((parent (arcdocdb.control.tests::native-directory fixture "parent/" deadline))
            (path (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline))
            (moved (arcdocdb.control.tests::native-register-directory fixture
                     (merge-pathnames "moved/" (arcdocdb.control.tests::native-fixture-root fixture))))
            (moved-owned (arcdocdb.control.tests::native-register-directory fixture
                           (merge-pathnames "owned/" moved)))
            (files (loop for id in '(7 1) collect (idr-native-file fixture path (idr-name id :final) deadline)))
            (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
            (manifest (inventory-manifest 7 '(1) nil)))
       (dolist (id '(7 1))
         (arcdocdb.control.tests::native-leaf fixture moved-owned (idr-name id :final)))
       (sb-posix:rename (namestring parent) (namestring moved))
       (arcdocdb.control.tests::native-directory fixture "parent/" deadline)
       (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline)
       (let* ((decoy (idr-native-file fixture path (idr-name 99 :final) deadline))
              (replacement (arcdocdb.control.tests::native-open fixture path :directory deadline nil)))
         (idr-native-check fixture directory manifest 7 '(1) nil '((7 :final) (1 :final)) files deadline)
         (idr-native-check fixture replacement manifest 7 '(1) nil '((99 :final)) (list decoy) deadline)
         (is (not (equal (arcdocdb.control.tests::native-identity directory)
                          (arcdocdb.control.tests::native-identity replacement)))))))))
