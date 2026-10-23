;;;; C4 nativo: FD parent posseduto, byte immutati e namespace 0700 limitato.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-sources-native-readonly-repeat-and-budget-cleanup
  (dolist (version '(1 2))
    (arcdocdb.control.tests::native-run-case
     (lambda (fixture deadline)
       (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
              (specs '((7 :temporary) (0 :final) (3 :final) (120 :temporary)))
              (files (loop for spec in specs collect
                       (idr-native-file fixture path (idr-name (first spec) (second spec)) deadline)))
              (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
              (manifest (inventory-manifest 7 '(0) '(3) :version version))
              (before (idr-native-check-files files deadline)))
         (dotimes (repeat 2)
           (multiple-value-bind (sources plan)
               (arcdocdb.recovery.manifest:apri-fonti-recovery
                manifest directory :max-files 4 :max-segmenti 2 :max-names 4
                :max-total-name-bytes 88 :max-name-bytes 24
                :max-transfer 5 :max-file-bytes 5 :max-total-file-bytes 10)
             (unwind-protect
                  (progn
                    (inventory-assert-plan plan (inventory-oracle 7 '(0) '(3) specs))
                    (is (= 2 (arcdocdb.recovery.manifest:numero-fonti-recovery sources)))
                    (dotimes (i 2)
                      (multiple-value-bind (id state form file size)
                          (arcdocdb.recovery.manifest:fonte-recovery sources i)
                        (is (= id (if (zerop i) 0 7)))
                        (is (eq state (if (zerop i) :closed :active)))
                        (is (eq form (if (zerop i) :final :temporary)))
                        (is (= size 5))
                        (arcdocdb.control.tests::native-read-bytes file (third (first files)) deadline))))
               (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources))))
         (signals resource-exhausted
                  (arcdocdb.recovery.manifest:apri-fonti-recovery manifest directory :max-total-file-bytes 9)
                  :recovery-sources-total-bytes)
         (is (equal before (idr-native-check-files files deadline)))
         (is (eq :open (arcdocdb.io:stato-file directory))))))))

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-sources-native-parent-rename-keeps-original-fd
  (arcdocdb.control.tests::native-run-case
   (lambda (fixture deadline)
     (let* ((parent (arcdocdb.control.tests::native-directory fixture "parent/" deadline))
            (path (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline))
            (moved (arcdocdb.control.tests::native-register-directory fixture
                     (merge-pathnames "moved/" (arcdocdb.control.tests::native-fixture-root fixture))))
            (moved-owned (arcdocdb.control.tests::native-register-directory fixture
                           (merge-pathnames "owned/" moved)))
            (files (loop for id in '(7 0) collect (idr-native-file fixture path (idr-name id :final) deadline)))
            (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
            (manifest (inventory-manifest 7 '(0) nil)))
       (dolist (id '(7 0)) (arcdocdb.control.tests::native-leaf fixture moved-owned (idr-name id :final)))
       (sb-posix:rename (namestring parent) (namestring moved))
       (arcdocdb.control.tests::native-directory fixture "parent/" deadline)
       (arcdocdb.control.tests::native-directory fixture "parent/owned/" deadline)
       (idr-native-file fixture path (idr-name 99 :final) deadline)
       (let ((replacement (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
             (sources (arcdocdb.recovery.manifest:apri-fonti-recovery manifest directory)))
         (unwind-protect
              (progn
                (is (= 2 (arcdocdb.recovery.manifest:numero-fonti-recovery sources)))
                (signals invalid-argument
                         (arcdocdb.recovery.manifest:apri-fonti-recovery manifest replacement)
                         :recovery-sources-not-ready)
                (idr-native-check-files files deadline))
           (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources)))))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-sources-four-private-series-concurrent
  (let ((workers nil) (results (make-array 4 :initial-element nil))
        (gate (sb-thread:make-semaphore :count 0)))
    (unwind-protect
         (progn
           (dotimes (ordinal 4)
             (let ((slot ordinal))
               (push (sb-thread:make-thread
                      (lambda ()
                        (unless (sb-thread:wait-on-semaphore gate :timeout 10) (error "Sources gate scaduto"))
                        (frs-run '((7 :final) (0 :temporary))
                          (lambda (fixture directory)
                            (declare (ignore directory))
                            (dotimes (repeat 16)
                              (let* ((sources (frs-open fixture (inventory-manifest 7 '(0) nil)))
                                     (files (frs-files sources)))
                                (is (= 2 (arcdocdb.recovery.manifest:numero-fonti-recovery sources)))
                                (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources)
                                (dolist (file files) (is (eq :closed (arcdocdb.io:stato-file file))))))
                            (setf (aref results slot) (= 16 (length (frs-events fixture :enumerate))))))
                        :done)
                      :name "recovery-sources-private") workers)))
           (sb-thread:signal-semaphore gate 4)
           (dolist (worker workers)
             (is (eq :done (sb-thread:join-thread worker :timeout 30 :default :timeout))))
           (is (every #'identity results)))
      (dolist (worker workers)
        (when (sb-thread:thread-alive-p worker) (sb-thread:terminate-thread worker))
        (sb-thread:join-thread worker :timeout 5 :default nil)))))

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-REC-001-sources-native-symlink-and-hardlink-refused
  (dolist (kind '(:symlink :hardlink))
    (arcdocdb.control.tests::native-run-case
     (lambda (fixture deadline)
       (let* ((path (arcdocdb.control.tests::native-fixture-root fixture))
              (file (idr-native-file fixture path (idr-name 7 :final) deadline))
              (alias (arcdocdb.control.tests::native-leaf fixture path (idr-name 0 :final)))
              (directory (arcdocdb.control.tests::native-open fixture path :directory deadline nil))
              (before (idr-native-check-files (list file) deadline)))
         (ecase kind (:symlink (sb-posix:symlink (namestring (first file)) (namestring alias)))
                     (:hardlink (sb-posix:link (namestring (first file)) (namestring alias))))
         (if (eq kind :symlink)
             (signals arcdocdb.conditions:io-fault
                      (arcdocdb.recovery.manifest:apri-fonti-recovery (inventory-manifest 7 '(0) nil) directory)
                      :io-entry-kind)
             (signals corruption-detected
                      (arcdocdb.recovery.manifest:apri-fonti-recovery (inventory-manifest 7 '(0) nil) directory)
                      :inventory-physical-alias))
         (is (equal before (idr-native-check-files (list file) deadline)))
         (is (eq :open (arcdocdb.io:stato-file directory))))))))
