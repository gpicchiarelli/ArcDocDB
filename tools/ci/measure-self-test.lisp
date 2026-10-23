;;;; C4 source-only fixtures; REQ-VAL-001 REQ-AFF-012.
;;;; Explicit API only: (ci-measure-self-test OUT) -> plist of counts/case results.
;;;; Saves OUT/measure-self-test.lisp exclusively. No product load or child process.
;;;; This file merely defines the self-test; no implicit execution.
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 2)))

(defun ci-measure-test-rejected-p (function)
  "Only the expected measurement rejection counts as a negative fixture passing."
  (handler-case (progn (funcall function) nil)
    (ci-measure-failure () t)))

(defun ci-measure-test-sample (&key (ticks 10) (id :crc32c-check-vector) (replica 1))
  "Synthetic sensor fixture, marked by the enclosing self-test; never performance evidence."
  (multiple-value-bind (buffer expected oracle) (ci-measure-fixture id)
    (ci-measure-sample-record id replica expected oracle (length buffer)
                              (* expected +ci-measure-iterations+) ticks 7 128 0 nil)))

(defun ci-measure-self-test (out)
  "Run only when explicitly called; pure math/schema/budget/absence fixtures plus one save.
Return :KIND :CI-MEASURE-SELF-TEST, :STATUS :PASSED/:FAILED, and exact case counts.
Unexpected serious conditions propagate; no benchmark, GC probe or product call is run."
  (let ((cases nil) (negative 0))
    (flet ((check (name passed &optional negative-p)
             (when negative-p (incf negative))
             (push (list :id name :status (if passed :passed :failed)) cases)))
      (check :ratio-reduction (equal (ci-measure-ratio 12 8) '(:numerator 3 :denominator 2)))
      (check :measured-zero (equal (ci-measure-ratio 0 8) '(:numerator 0 :denominator 1)))
      (check :zero-denominator (null (ci-measure-ratio 1 0)))
      (check :invalid-numerator
             (ci-measure-test-rejected-p (lambda () (ci-measure-ratio -1 1))) t)
      (check :invalid-denominator
             (ci-measure-test-rejected-p (lambda () (ci-measure-ratio 1 -1))) t)
      (check :fraction-rejected
             (ci-measure-test-rejected-p (lambda () (ci-measure-ratio 1/2 1))) t)
      (check :budget-before-edge (ci-measure-budget-left-p 100 1799 10 170))
      (check :budget-at-edge (not (ci-measure-budget-left-p 100 1800 10 170)))
      (check :budget-zero (not (ci-measure-budget-left-p 10 10 1 0)))
      (check :clock-backwards
             (ci-measure-test-rejected-p (lambda () (ci-measure-budget-left-p 10 9 1 1))) t)
      (check :clock-scale-zero
             (ci-measure-test-rejected-p (lambda () (ci-measure-budget-left-p 0 0 0 1))) t)
      (check :counter-measured-zero (eql 0 (ci-measure-delta 12 12)))
      (check :counter-unavailable (null (ci-measure-delta nil nil)))
      (check :counter-reset
             (ci-measure-test-rejected-p (lambda () (ci-measure-delta 12 11))) t)
      (check :counter-mixed-availability
             (ci-measure-test-rejected-p (lambda () (ci-measure-delta nil 1))) t)
      (check :crc32c-empty
             (zerop (ci-measure-reference-crc
                     (make-array 0 :element-type '(unsigned-byte 8)))))
      (multiple-value-bind (bytes expected oracle) (ci-measure-fixture :crc32c-check-vector)
        (declare (ignore oracle))
        (check :independent-crc-known-vector
               (and (= expected #xe3069283) (= expected (ci-measure-reference-crc bytes)))))
      (check :independent-crc-zero-vector
             (= #x8a9136aa (ci-measure-reference-crc
                           (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))))
      (multiple-value-bind (bytes expected oracle) (ci-measure-fixture :utf8-mixed-4090)
        (declare (ignore oracle))
        (check :utf8-known-count (and (= (length bytes) 4090) (= expected 1636))))
      (let* ((zero (ci-measure-test-sample :ticks 0))
             (sample (ci-measure-test-sample))
             (statistics (ci-measure-statistics (list sample)))
             (zero-statistics (ci-measure-statistics (list zero))))
        (check :zero-time-rate-absent (and (null (getf zero :operations-per-second))
                                         (stringp (getf zero :rate-reason))))
        (check :zero-time-pooled-rate-absent
               (and (= 1 (getf zero-statistics :zero-tick-samples))
                    (null (getf zero-statistics :operations-per-second))
                    (stringp (getf zero-statistics :rate-reason))))
        (check :zero-time-metric-unsupported
               (let* ((replicas (loop for replica from 1 to 5
                                     collect (list :replica replica :status :measured
                                                   :samples (list (ci-measure-test-sample
                                                                   :ticks 0 :replica replica)))))
                      (row (first (ci-measure-metric-rows replicas :measured nil))))
                 (and (eq :unsupported (getf row :status))
                      (null (getf row :value)) (getf row :reason))))
        (check :exact-pooled-rate
               (equal (getf statistics :operations-per-second)
                      (ci-measure-ratio (* +ci-measure-iterations+ internal-time-units-per-second) 10)))
        (check :known-operation-byte-count
               (and (= +ci-measure-iterations+ (getf statistics :total-operations))
                    (= (* 9 +ci-measure-iterations+) (getf statistics :total-bytes))))
        (check :empty-sample-statistics (null (ci-measure-statistics nil)))
        (check :checksum-mismatch-rejected
               (ci-measure-test-rejected-p
                (lambda () (ci-measure-sample-record :crc32c-check-vector 1 1 "fixture"
                                                     9 0 10 7 128 0 nil))) t)
        (check :sample-protocol
               (eq sample (ci-measure-validate-sample sample :crc32c-check-vector 1)))
        (let ((altered (copy-list sample)))
          (setf (getf altered :bytes) 0)
          (check :tampered-byte-count
                 (ci-measure-test-rejected-p
                  (lambda () (ci-measure-validate-sample altered :crc32c-check-vector 1))) t))
        (let* ((replicas (loop for replica from 1 to 5
                               collect (list :replica replica :status :measured
                                             :samples (list (ci-measure-test-sample :replica replica)))))
               (rows (ci-measure-metric-rows replicas :measured nil))
               (partial (ci-measure-metric-rows (subseq replicas 0 4)
                                               :budget-exhausted "fixture budget")))
          (check :five-replicas-pooled
                 (and (eq :measured (getf (first rows) :status))
                      (= 5 (length (getf (first rows) :samples)))
                      (getf (first rows) :value)))
          (check :missing-workload-never-measured
                 (and (eq :missing (getf (second rows) :status))
                      (null (getf (second rows) :value))))
          (check :partial-observations-retained
                 (and (eq :budget-exhausted (getf (first partial) :status))
                      (= 4 (length (getf (first partial) :samples)))
                      (null (getf (first partial) :value))
                      (getf (first partial) :reason))))
        (let* ((record (list :kind :ci-measure-replica :schema-version 1 :replica 1
                             :status :measured :reason nil :samples (list sample))))
          (check :missing-workload-rejected
                 (ci-measure-test-rejected-p (lambda () (ci-measure-validate-replica record 1))) t)
          (setf (getf record :status) :failed)
          (check :failed-replica-retains-partial
                 (eq record (ci-measure-validate-replica record 1)))
          (setf (getf record :samples) (list sample sample))
          (check :duplicate-workload-rejected
                 (ci-measure-test-rejected-p (lambda () (ci-measure-validate-replica record 1))) t)))
      (let ((rows (ci-measure-unavailable-metrics)))
        (check :all-unsupported-have-reason-and-nil
               (every (lambda (row) (and (member (getf row :status) '(:unsupported :not-implemented))
                                        (null (getf row :value)) (getf row :reason)
                                        (null (getf row :samples)))) rows))
        (dolist (id '(:engine-throughput :engine-compaction :p99-latency :p999-latency
                      :fsync-latency :rss :gc-count))
          (check id (find id rows :key (lambda (row) (getf row :id))))))
      (let ((closed (ci-measure-close-replicas nil 1 :budget-exhausted "fixture")))
        (check :budget-closes-expected-slots
               (and (= 5 (length closed)) (eq :budget-exhausted (getf (first closed) :status))
                    (every (lambda (row) (eq :not-run (getf row :status))) (rest closed))
                    (every (lambda (row) (null (getf row :samples))) closed)))))
    (setf cases (nreverse cases))
    (let* ((failed (count :failed cases :key (lambda (row) (getf row :status))))
           (report (list :kind :ci-measure-self-test :schema-version 1
                         :status (if (zerop failed) :passed :failed)
                         :counts (list :planned (length cases) :started (length cases)
                                       :passed (- (length cases) failed) :failed failed
                                       :negative-cases negative)
                         :fixture-data-only t :cases cases))
           (directory (ci-measure-output-directory out)))
      (ensure-directories-exist (merge-pathnames "measure-self-test.lisp" directory))
      (funcall (fdefinition 'ci-save) (merge-pathnames "measure-self-test.lisp" directory) report)
      report)))
