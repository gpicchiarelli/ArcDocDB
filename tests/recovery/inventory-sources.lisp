;;;; Suite C1 osservata da oracoli C4 di nomi, EOF e FD posseduti.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-018
(deftest test-REQ-REC-001-sources-only-live-ordered-owned-v1-v2
  (dolist (version '(1 2))
    (let* ((specs '((120 :temporary) (7 :temporary) (3 :final) (1 :final) (0 :temporary) (99 :final)))
           (manifest (inventory-manifest 7 '(0 1) '(3) :version version)))
      (dolist (order (inventory-input-orders specs))
        (frs-run order
          (lambda (fixture directory)
            (multiple-value-bind (sources plan) (frs-open fixture manifest)
              (inventory-assert-plan plan (inventory-oracle 7 '(0 1) '(3) specs))
              (is (= 3 (arcdocdb.recovery.manifest:numero-fonti-recovery sources)))
              (is (= 1 (length (frs-events fixture :enumerate))))
              (is (equal (mapcar (lambda (spec) (list :open (idr-name (first spec) (second spec))))
                                 '((0 :temporary) (1 :final) (7 :temporary)))
                         (frs-events fixture :open)))
              (loop for expected in '((0 :closed :temporary) (1 :closed :final) (7 :active :temporary))
                    for i from 0 do
                (let ((row (multiple-value-list (arcdocdb.recovery.manifest:fonte-recovery sources i))))
                  (is (= 5 (length row))) (is (equal expected (subseq row 0 3)))
                  (is (= 5 (fifth row))) (is (eq :input (arcdocdb.io:mode-file (fourth row))))))
            (is (equal '(:open 0 0) (idr-observation directory))))))))))

;;; REQ: REQ-REC-002 REQ-REC-004 REQ-AFF-008
(deftest test-REQ-REC-002-sources-nonready-before-any-open
  (dolist (specs '(() ((7 :final)) ((0 :final)) ((7 :final) (7 :temporary) (0 :final))
                    ((7 :final) (0 :final) (0 :temporary))))
    (frs-run specs
      (lambda (fixture directory)
        (declare (ignore directory))
        (signals invalid-argument (frs-open fixture (inventory-manifest 7 '(0) nil))
                 :recovery-sources-not-ready)
        (is (null (frs-events fixture :open))) (is (null (frs-events fixture :close)))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-REC-001-sources-u64-and-input-reuse
  (dolist (version '(1 2))
    (let* ((ids (list 0 (ash 1 63) (1- (ash 1 64))))
           (specs (cons '(7 :final) (mapcar (lambda (id) (list id :temporary)) ids)))
           (manifest (inventory-fixture-manifest
                      (list (manifest-spec :completo t :open 7 :next-id #xffffffffffffffff
                                           :chiusi (mapcar (lambda (id) (list id 64 nil)) (butlast ids)))
                            (manifest-spec :open #xffffffffffffffff :chiusi '((7 64 nil))))
                      :version version)))
      (frs-run (reverse specs)
        (lambda (fixture directory)
          (declare (ignore directory))
          (let* ((sources (frs-open fixture manifest)) (files (frs-files sources)))
            (map nil (lambda (name) (fill name #\x)) (frs-fixture-names fixture))
            (is (equal '(0 7 9223372036854775808 18446744073709551615)
                       (loop for i below 4 collect
                         (arcdocdb.recovery.manifest:fonte-recovery sources i))))
            (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources)
            (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources)
            (frs-check-closed fixture files)
            (is (= 4 (arcdocdb.recovery.manifest:numero-fonti-recovery sources)))
            (signals invalid-argument (arcdocdb.recovery.manifest:fonte-recovery sources 0)
                     :recovery-sources-closed)))))))

;;; REQ: REQ-AFF-008 REQ-REC-001 REQ-AFF-018
(deftest test-REQ-AFF-008-sources-budgets-exact-and-one-under
  (let* ((specs '((7 :final) (0 :temporary) (3 :final)))
         (manifest (inventory-manifest 7 '(0) '(3))))
    (frs-run specs
      (lambda (fixture directory)
        (declare (ignore directory))
        (let ((sources (frs-open fixture manifest :max-files 3 :max-segmenti 2 :max-names 3
                                :max-total-name-bytes 64 :max-name-bytes 24
                                :max-transfer 1 :max-file-bytes 5 :max-total-file-bytes 10)))
          (dolist (file (frs-files sources))
            (is (= 1 (arcdocdb.io::file-max-transfer file)))
            (is (= 5 (arcdocdb.io::file-max-file-bytes file)))))))
    (dolist (budget '((:max-files 2 :inventory-file-budget) (:max-segmenti 1 :inventory-segment-budget)
                      (:max-names 2 :io-directory-names) (:max-total-name-bytes 63 :io-directory-total-name-bytes)
                      (:max-name-bytes 23 :io-directory-name-bytes) (:max-file-bytes 4 :io-file-size)
                      (:max-total-file-bytes 9 :recovery-sources-total-bytes)))
      (frs-run specs
        (lambda (fixture directory)
          (declare (ignore directory))
          (signals resource-exhausted (frs-open fixture manifest (first budget) (second budget))
                   (third budget))
          (frs-check-closed fixture nil))))
    (frs-run '((7 :final))
      (lambda (fixture directory)
        (declare (ignore directory))
        (is (= 1 (arcdocdb.recovery.manifest:numero-fonti-recovery
                  (frs-open fixture (inventory-manifest 7 nil nil)
                            :max-file-bytes 0 :max-total-file-bytes 0)))))
      :sizes (list (cons (idr-name 7 :final) 0)))))

;;; REQ: REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-sources-total-high-bits-no-overflow
  (let* ((size (ash 1 40)) (manifest (inventory-manifest 7 '(0) nil)))
    (dolist (budget (list (* 2 size) (1- (* 2 size))))
      (frs-run '((7 :final) (0 :final))
        (lambda (fixture directory)
          (declare (ignore directory))
          (if (= budget (* 2 size))
              (frs-open fixture manifest :max-file-bytes size :max-total-file-bytes budget)
              (signals resource-exhausted
                       (frs-open fixture manifest :max-file-bytes size :max-total-file-bytes budget)
                       :recovery-sources-total-bytes)))
        :sizes (list (cons (idr-name 0 :final) size) (cons (idr-name 7 :final) size))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-sources-invalid-preflight-and-missing-callbacks
  (let ((manifest (inventory-manifest 7 nil nil)))
    (dolist (budget '((:max-transfer 0) (:max-transfer 268435457) (:max-transfer :invalid)
                      (:max-file-bytes -1) (:max-file-bytes :invalid)
                      (:max-total-file-bytes -1) (:max-total-file-bytes :invalid)
                      (:max-files -1) (:max-segmenti -1) (:max-names -1)
                      (:max-total-name-bytes -1) (:max-name-bytes 0)))
      (frs-run '((7 :final))
        (lambda (fixture directory)
          (declare (ignore directory))
          (signals invalid-argument (apply #'frs-open fixture manifest budget))
          (is (null (frs-fixture-events fixture))))))
    (dolist (missing '(:directory :identity :relative :metadata))
      (frs-run '((7 :final))
        (lambda (fixture directory)
          (declare (ignore directory))
          (signals unsupported-format (frs-open fixture manifest))
          (is (null (frs-fixture-events fixture)))) :missing missing))
    (frs-run '((7 :final))
      (lambda (fixture directory)
        (declare (ignore directory))
        (signals invalid-argument (frs-open fixture manifest) :io-mode)
        (is (null (frs-fixture-events fixture)))) :mode :input)))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-AFF-004-sources-each-open-metadata-and-entry-failure
  (dolist (stage '(:open :metadata :entry))
    (dotimes (position 3)
      (frs-run '((7 :final) (0 :final) (1 :temporary))
        (lambda (fixture directory)
          (declare (ignore directory))
          (let ((original (frs-original)) (seen 0))
            (setf (frs-fixture-hook fixture)
                  (lambda (state event &rest args)
                    (declare (ignore args))
                    (when (and (eq event stage)
                               (or (not (eq stage :entry)) (frs-fixture-opened state)))
                      (when (= seen position) (error original)) (incf seen))))
            (is (eq original (signals arcdocdb.conditions:io-fault
                                     (frs-open fixture (inventory-manifest 7 '(0 1) nil)))))
            (frs-check-closed fixture nil)))))))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-AFF-004-sources-cleanup-primary-and-all-close-failures
  (dolist (primary-p '(nil t))
    (dolist (fail-p '(nil t))
      (frs-run '((7 :final) (0 :final) (1 :final))
        (lambda (fixture directory)
          (declare (ignore directory))
          (let ((original (frs-original)) (close-errors nil) (sources nil) (files nil))
            (setf (frs-fixture-hook fixture)
                  (lambda (state event &rest args)
                    (declare (ignore state))
                    (when (and primary-p (eq event :metadata) (= (first args) 102)) (error original))
                    (when (and fail-p (eq event :close) (/= (first args) 71)
                               (or (not primary-p) (/= (first args) 102)))
                      (let ((failure (make-condition 'arcdocdb.conditions:io-fault
                                                    :reason :frs-close :operation :close :errno (first args))))
                        (push failure close-errors) (error failure)))))
            (flet ((operation ()
                     (setf sources (frs-open fixture (inventory-manifest 7 '(0 1) nil))
                           files (frs-files sources))
                     (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources)))
              (cond (fail-p
                     (let ((caught (signals arcdocdb.recovery.manifest:recovery-sources-cleanup-error
                                            (operation) :recovery-sources-cleanup)))
                       (is (= (if primary-p 2 3)
                              (arcdocdb.recovery.manifest:recovery-sources-cleanup-count caught)))
                       (is (eq (if primary-p original nil)
                               (arcdocdb.recovery.manifest:recovery-sources-primary caught)))
                       (is (eq (if primary-p (second close-errors) (car (last close-errors)))
                               (arcdocdb.recovery.manifest:recovery-sources-cleanup caught)))))
                    (primary-p (is (eq original (signals arcdocdb.conditions:io-fault (operation)))))
                    (t (operation))))
            (setf (frs-fixture-hook fixture) nil)
            (when sources (arcdocdb.recovery.manifest:chiudi-fonti-recovery sources))
            (frs-check-closed fixture files)))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-sources-query-and-defensive-plan-guards
  (frs-run '((7 :final))
    (lambda (fixture directory)
      (declare (ignore directory))
      (let ((sources (frs-open fixture (inventory-manifest 7 nil nil))))
        (dolist (position '(-1 1 100))
          (signals invalid-argument (arcdocdb.recovery.manifest:fonte-recovery sources position)
                   :recovery-sources-index))
        (let* ((entry (aref (arcdocdb.recovery.manifest::%rss-entries sources) 0))
               (file (arcdocdb.recovery.manifest::%rs-file entry)))
          (unwind-protect
               (progn (setf (arcdocdb.recovery.manifest::%rs-file entry) nil)
                      (signals arcdocdb.conditions:invariant-violation
                               (arcdocdb.recovery.manifest:fonte-recovery sources 0) :recovery-source-unopened))
            (setf (arcdocdb.recovery.manifest::%rs-file entry) file))))))
  (dolist (row '((:final :rename) (:temporary :use) (:absent :missing) (:both :conflict)))
    (let ((plan (arcdocdb.recovery.manifest::%make-reconciliation-plan
                 (vector (arcdocdb.recovery.manifest::%make-reconciliation-entry
                          7 (first row) (second row) :active)) :ready)))
      (signals arcdocdb.conditions:invariant-violation
               (arcdocdb.recovery.manifest::prepara-fonti-recovery plan) :recovery-source-action)))
  (signals arcdocdb.conditions:invariant-violation
           (arcdocdb.recovery.manifest::prepara-fonti-recovery
            (arcdocdb.recovery.manifest::%make-reconciliation-plan #() :ready)) :recovery-sources-empty))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-sources-incomplete-parent-and-nonlocal-cleanup
  (frs-run '((7 :final))
    (lambda (fixture directory)
      (declare (ignore directory)) (setf (frs-fixture-complete fixture) nil)
      (signals arcdocdb.conditions:invariant-violation (frs-open fixture (inventory-manifest 7 nil nil))
               :io-directory-result)
      (is (null (frs-events fixture :open)))))
  (frs-run '((7 :final) (0 :final))
    (lambda (fixture directory)
      (let ((count 0))
        (setf (frs-fixture-hook fixture)
              (lambda (state event &rest args)
                (declare (ignore args))
                (when (eq event :metadata)
                  (incf count)
                  (when (= count 2) (arcdocdb.io:chiudi (frs-fixture-parent state))))))
        (signals arcdocdb.conditions:io-fault (frs-open fixture (inventory-manifest 7 '(0) nil)))
        (is (eq :closed (arcdocdb.io:stato-file directory)))
        (dolist (pair (frs-fixture-opened fixture))
          (is (= 1 (count (list :close (car pair)) (frs-fixture-events fixture) :test #'equal)))))))
  (frs-run '((7 :final) (0 :final))
    (lambda (fixture directory)
      (declare (ignore directory))
      (let ((count 0))
        (setf (frs-fixture-hook fixture)
              (lambda (state event &rest args)
                (declare (ignore state args))
                (when (eq event :open) (incf count) (when (= count 2) (throw 'frs-exit :escaped)))))
        (is (eq :escaped (catch 'frs-exit (frs-open fixture (inventory-manifest 7 '(0) nil)))))
        (frs-check-closed fixture nil)))))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-sources-current-child-cleanup-and-prior-cleanup-preserved
  (frs-run '((7 :final) (0 :final) (1 :final))
    (lambda (fixture directory)
      (declare (ignore directory))
      (let ((original (frs-original)))
        (setf (frs-fixture-hook fixture)
              (lambda (state event &rest args)
                (declare (ignore state))
                (when (and (eq event :metadata) (= (first args) 102)) (error original))
                (when (and (eq event :close) (member (first args) '(100 102)))
                  (error 'arcdocdb.conditions:io-fault :reason :frs-close :operation :close
                         :errno (if (= 102 (first args)) 23 31)))))
        (let* ((caught (signals arcdocdb.recovery.manifest:recovery-sources-cleanup-error
                                (frs-open fixture (inventory-manifest 7 '(0 1) nil))))
               (primary (arcdocdb.recovery.manifest:recovery-sources-primary caught))
               (cleanup (arcdocdb.recovery.manifest:recovery-sources-cleanup caught)))
          (is (eq :frs-injected (error-reason primary)))
          (is (eq :read (arcdocdb.conditions:error-operation primary)))
          (is (= 9 (arcdocdb.conditions:error-errno primary)))
          (is (= 2 (arcdocdb.conditions:error-transferred primary)))
          (is (= 23 (arcdocdb.conditions:error-cleanup-errno primary)))
          (is (= 31 (arcdocdb.conditions:error-errno cleanup)))
          (is (= 1 (arcdocdb.recovery.manifest:recovery-sources-cleanup-count caught))))
        (setf (frs-fixture-hook fixture) nil)
        (frs-check-closed fixture nil)))))

;;; REQ: REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-sources-total-fixnum-overflow-refused-before-addition
  (let ((size (1+ (floor most-positive-fixnum 2))))
    (frs-run '((7 :final) (0 :final))
      (lambda (fixture directory)
        (declare (ignore directory))
        (signals resource-exhausted
                 (frs-open fixture (inventory-manifest 7 '(0) nil)
                           :max-file-bytes size :max-total-file-bytes most-positive-fixnum)
                 :recovery-sources-total-bytes)
        (frs-check-closed fixture nil))
      :sizes (list (cons (idr-name 0 :final) size) (cons (idr-name 7 :final) size)))))
