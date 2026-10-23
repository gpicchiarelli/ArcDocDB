;;;; C4 — bounded exploratory measurements; REQ-VAL-001 REQ-AFF-012.
;;;; Loaded by tools/ci.lisp, including in publishers WITHOUT product packages.
;;;; Public API: CI-RUN-MEASURE(out-directory) -> summary; saves measure.lisp.
;;;; CI-MEASURE-SELF-TEST(out-directory) lives in measure-self-test.lisp.
;;;; No auto-main, ASDF, product reader references, or work at module load.
;;;; Five serial fresh SBCL children, private 256 MiB dynamic spaces, own warmup.
;;;; Worker budget 25s; parent wait 30s; campaign 170s, leaving recorder margin
;;;; below 180s. Recorder remains the hard OS boundary for stuck kernel I/O.
;;;; Files are exclusive: use a fresh output directory for each invocation.
;;;; Only fixed tracked product source modules are loaded in each child.
;;;; Existing benchmark CLIs have auto-main and are deliberately not loaded.

(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +ci-measure-replicas+ 5)
(defconstant +ci-measure-iterations+ 4096)
(defconstant +ci-measure-warmup+ 32)
(defconstant +ci-measure-budget-seconds+ 170)
(defconstant +ci-measure-worker-seconds+ 25)
(defconstant +ci-measure-wait-seconds+ 30)
(defconstant +ci-measure-max-buffer+ 4096)

;;; OWNER: module; immutable paths and method catalogue after loading.
(defparameter *ci-measure-module*
  (or *load-truename* *compile-file-truename*
      (merge-pathnames "tools/ci/measure.lisp" *default-pathname-defaults*)))
(defparameter *ci-measure-root*
  (merge-pathnames "../../" (make-pathname :name nil :type nil :defaults *ci-measure-module*)))
(defparameter *ci-measure-product-files*
  '("src/io/cpu-package.lisp" "src/io/cpu-build.lisp" "src/io/cpu-features.lisp"
    "src/foundation/package.lisp" "src/foundation/conditions.lisp"
    "src/foundation/binary.lisp" "src/foundation/crc32c.lisp"
    "src/foundation/crc32c-vops.lisp" "src/foundation/crc32c-native.lisp"
    "src/codec/package.lisp" "src/codec/utf8.lisp"))
(defparameter *ci-measure-workloads* '(:crc32c-check-vector :crc32c-4096 :utf8-mixed-4090))
(defvar *ci-measure-coordinator-identity* nil)

;;; Standalone checkers cannot load CI code. Intern their finite report schema here
;;; so the dedicated CI reader can recognize it without interning external input.
(defparameter *ci-check-report-wire-keywords*
  '(:ci-check :check :lint :trace :links :status :passed :failed :counts
    :mode :self-test :cases :files :violations :token-violations :by-rule :rule
    :requirements :errors :invariants :invariants-covered :fi-scenarios :fi-covered
    :adrs :matrix-current :matrix-written :requirements-with-verification
    :requirements-without-verification :by-class :class :by-status
    :specificato :progettato :implementato :verificato :code-references :directory
    :references :unique-requirements :unknown-references :missing-implementation-references
    :missing-test-references :checked :broken :missing-files :missing-anchors
    :markdown-targets :html-targets :by-verification-method :method
    :test :prop :diff :model :fi :fuzz :corr :mut :soak :bench :rev :analisi
    :invariant-references :unknown-invariant-references :adr-references :unknown-adr-references
    :fi-references :unknown-fi-references :invalid-classes :invalid-statuses))

(define-condition ci-measure-failure (error)
  ((reason :initarg :reason :reader ci-measure-failure-reason))
  (:report (lambda (condition stream)
             (format stream "tools/ci/measure.lisp: ~A" (ci-measure-failure-reason condition)))))

(defun ci-measure-reject (reason)
  "Signal a named C4 failure, never reinterpret a bad observation as zero."
  (error 'ci-measure-failure :reason reason))

(defun ci-measure-output-directory (out)
  "Treat OUT as a directory even without a final slash; require a literal path."
  (let ((text (namestring (pathname out))))
    (when (or (zerop (length text)) (wild-pathname-p (pathname out)))
      (ci-measure-reject "invalid output directory"))
    (merge-pathnames
     (pathname (if (char= (char text (1- (length text))) #\/) text
                   (concatenate 'string text "/")))
     *default-pathname-defaults*)))

(defun ci-measure-ratio (numerator denominator)
  "Nonnegative exact wire ratio; unknown/zero denominator is absent, never 100%."
  (unless (and (integerp numerator) (not (minusp numerator))
               (integerp denominator) (not (minusp denominator)))
    (ci-measure-reject "invalid ratio operands"))
  (when (plusp denominator)
    (let ((divisor (gcd numerator denominator)))
      (list :numerator (/ numerator divisor) :denominator (/ denominator divisor)))))

(defun ci-measure-budget-left-p (start now units seconds)
  "Pure budget predicate, injectable in self-test; invalid/backwards clocks reject."
  (unless (and (integerp start) (integerp now) (<= 0 start now)
               (integerp units) (plusp units) (integerp seconds) (not (minusp seconds)))
    (ci-measure-reject "invalid clock or budget"))
  (< (- now start) (* units seconds)))

(defun ci-measure-api (package name)
  "Resolve an exported product function only when measuring, never at reader time."
  (let ((pkg (find-package package)))
    (unless pkg (ci-measure-reject (format nil "missing product package ~A" package)))
    (multiple-value-bind (symbol visibility) (find-symbol name pkg)
      (unless (and symbol (eq visibility :external) (fboundp symbol))
        (ci-measure-reject (format nil "missing public API ~A:~A" package name)))
      (symbol-function symbol))))

(defun ci-measure-counter-symbol (name)
  "Only use documented public SB-EXT counters with a nonnegative integer value."
  (let ((pkg (find-package "SB-EXT")))
    (when pkg
      (multiple-value-bind (symbol visibility) (find-symbol name pkg)
        (when (and symbol (eq visibility :external) (boundp symbol)
                   (integerp (symbol-value symbol)) (not (minusp (symbol-value symbol))))
          symbol)))))

(defun ci-measure-delta (before after)
  "Return a genuine integer delta or NIL for an unavailable counter; reject resets."
  (cond ((and (null before) (null after)) nil)
        ((and (integerp before) (integerp after) (<= 0 before after)) (- after before))
        (t (ci-measure-reject "counter reset, clock reversal, or inconsistent availability"))))

(defun ci-measure-reference-crc (buffer)
  "Independent reflected bitwise CRC32C, polynomial 0x82F63B78, init/final all ones."
  (let ((crc #xffffffff))
    (loop for byte across buffer do
      (setf crc (logxor crc byte))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))

(defun ci-measure-fixture (id)
  "Fresh bounded octets plus independent expected return value, one replica owner."
  (ecase id
    (:crc32c-check-vector
     (values (make-array 9 :element-type '(unsigned-byte 8)
                          :initial-contents '(49 50 51 52 53 54 55 56 57))
             #xe3069283 "CRC32C check value for ASCII 123456789"))
    (:crc32c-4096
     (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8))))
       (dotimes (i 4096) (setf (aref buffer i) (mod (+ (* i 17) 11) 256)))
       (values buffer (ci-measure-reference-crc buffer) "independent bitwise CRC32C")))
    (:utf8-mixed-4090
     ;; A, U+00A2, U+0800, U+10000; 4 scalars / 10 bytes, repeated 409 times.
     (let ((buffer (make-array 4090 :element-type '(unsigned-byte 8)))
           (pattern '(65 194 162 224 160 128 240 144 128 128)))
       (dotimes (i 4090) (setf (aref buffer i) (nth (mod i 10) pattern)))
       (values buffer (* 4 409) "409 repetitions of four known Unicode scalars")))))

(defun ci-measure-product-function (id)
  "Public kernel only; generic call, loop and checksum overhead remain in the window."
  (if (eq id :utf8-mixed-4090)
      (ci-measure-api "ARCDOCDB.UTF8" "VERIFICA-UTF8")
      (ci-measure-api "ARCDOCDB.BINARY" "CRC32C")))

(defun ci-measure-sample-record (id replica expected oracle bytes sink ticks cpu heap gc-cpu gc-wall)
  "Construct primitive data after the sensor window; no floating point rates."
  (unless (= sink (* +ci-measure-iterations+ expected))
    (ci-measure-reject "measured return checksum differs from independent oracle"))
  (list :id id :replica replica :status :measured
        :operations +ci-measure-iterations+ :bytes-per-operation bytes
        :bytes (* +ci-measure-iterations+ bytes) :warmup-operations +ci-measure-warmup+
        :wall-ticks ticks :cpu-ticks cpu :ticks-per-second internal-time-units-per-second
        :operations-per-second (ci-measure-ratio (* +ci-measure-iterations+
                                                   internal-time-units-per-second) ticks)
        :rate-reason (when (zerop ticks) "clock resolution: zero elapsed ticks")
        :bytes-consed heap :gc-cpu-ticks gc-cpu :gc-wall-ticks gc-wall
        :gc-cpu-reason (unless gc-cpu "SB-EXT:*GC-RUN-TIME* unavailable")
        :gc-wall-reason (unless gc-wall "SB-EXT:*GC-REAL-TIME* unavailable")
        :gc-count nil :gc-count-status :unsupported
        :gc-count-reason "No public monotonic total; generation counters reset on promotion."
        :return-checksum sink :expected-return-checksum (* +ci-measure-iterations+ expected)
        :expected-return expected :oracle oracle :input-unchanged t
        :owned-buffer-bytes (* 2 bytes)))

(defun ci-measure-sample (id replica)
  "Fresh input/snapshot, checked warmup, full GC OUTSIDE measurement, checked result."
  (multiple-value-bind (buffer expected oracle) (ci-measure-fixture id)
    (let* ((original (copy-seq buffer)) (size (length buffer))
           (function (ci-measure-product-function id))
           (gc-cpu-symbol (ci-measure-counter-symbol "*GC-RUN-TIME*"))
           (gc-wall-symbol (ci-measure-counter-symbol "*GC-REAL-TIME*")))
      (unless (<= size +ci-measure-max-buffer+) (ci-measure-reject "buffer budget exceeded"))
      (dotimes (i +ci-measure-warmup+)
        (unless (= expected (funcall function buffer 0 size))
          (ci-measure-reject "warmup differs from independent oracle")))
      (sb-ext:gc :full t)
      ;; Counter read overhead and the harness sink are intentionally included.
      ;; CPU/GC are process totals in this private serial process, not RSS.
      (let* ((gc-cpu-before (when gc-cpu-symbol (symbol-value gc-cpu-symbol)))
             (gc-wall-before (when gc-wall-symbol (symbol-value gc-wall-symbol)))
             (heap-before (sb-ext:get-bytes-consed))
             (cpu-before (get-internal-run-time)) (start (get-internal-real-time))
             (sink 0))
        (dotimes (i +ci-measure-iterations+)
          (incf sink (funcall function buffer 0 size)))
        (let* ((ticks (ci-measure-delta start (get-internal-real-time)))
               (cpu (ci-measure-delta cpu-before (get-internal-run-time)))
               (heap (ci-measure-delta heap-before (sb-ext:get-bytes-consed)))
               (gc-cpu (ci-measure-delta gc-cpu-before
                                        (when gc-cpu-symbol (symbol-value gc-cpu-symbol))))
               (gc-wall (ci-measure-delta gc-wall-before
                                         (when gc-wall-symbol (symbol-value gc-wall-symbol)))))
          (unless (equalp original buffer) (ci-measure-reject "product modified the input"))
          (ci-measure-sample-record id replica expected oracle size sink ticks cpu heap
                                    gc-cpu gc-wall))))))

(defun ci-measure-write-worker (path record)
  "Private child writer: validated primitive tree, plain deterministic CL syntax."
  ;; A child has no dependency on the common CI data module. Its data is local,
  ;; bounded, and read by the parent's dedicated CI data parser, never LOADed.
  (labels ((valid (value depth)
             (when (> depth 16) (ci-measure-reject "worker wire depth"))
             (cond ((or (null value) (eq value t) (keywordp value)
                        (stringp value) (integerp value)) t)
                   ((consp value)
                    (unless (<= (length value) 512) (ci-measure-reject "worker wire size"))
                    (dolist (item value) (valid item (1+ depth))))
                   (t (ci-measure-reject "worker wire type")))))
    (valid record 0))
  (with-open-file (stream path :direction :output :if-exists :error
                         :if-does-not-exist :create :external-format :utf-8)
    (let ((*print-readably* nil) (*print-pretty* nil) (*print-circle* nil)
          (*print-length* nil) (*print-level* nil) (*print-base* 10)
          (*print-radix* nil) (*print-case* :upcase) (*print-escape* t)
          (*print-pprint-dispatch* (copy-pprint-dispatch nil))
          (*package* (find-package "COMMON-LISP-USER")))
      (write record :stream stream) (terpri stream) (finish-output stream))))

(defun ci-measure-worker (path replica)
  "Child entry, explicit invocation only. Fatal product/load errors remain fatal."
  (unless (and (integerp replica) (<= 1 replica +ci-measure-replicas+))
    (ci-measure-reject "replica outside fixed budget"))
  (when (or (find-package "SB-COVER") (member :sb-cover *features*))
    (ci-measure-reject "coverage instrumentation is incompatible with measurement"))
  (let ((samples nil) (status :measured) (reason nil))
    (handler-case
        (sb-ext:with-timeout +ci-measure-worker-seconds+
          (dolist (relative *ci-measure-product-files*)
            (load (merge-pathnames relative *ci-measure-root*) :verbose nil :print nil)
            (when (and (string= relative "src/io/cpu-build.lisp")
                       (member :arcdocdb-crc32c-arm64 *features*))
              (require :sb-simd)))
          (dolist (id *ci-measure-workloads*) (push (ci-measure-sample id replica) samples)))
      (sb-ext:timeout ()
        (setf status :budget-exhausted reason "private worker exceeded 25 seconds"))
      (ci-measure-failure (condition)
        (setf status :failed reason (ci-measure-failure-reason condition))))
    (ci-measure-write-worker path
                            (list :kind :ci-measure-replica :schema-version 1 :replica replica
                                  :status status :reason reason :samples (nreverse samples)))
    (unless (eq status :measured) (sb-ext:exit :code 1))))

(defun ci-measure-child-arguments (path replica)
  "Fixed argv, no shell, no evaluation of output data; bootstrap only the CI package."
  (let ((*print-readably* t) (*print-base* 10) (*print-radix* nil)
        (*print-pretty* nil) (*print-escape* t))
    (list "--dynamic-space-size" "256" "--noinform"
          "--no-sysinit" "--no-userinit" "--disable-debugger"
          "--eval" "(defpackage #:arcdocdb.ci (:use #:cl))"
          "--load" (namestring *ci-measure-module*)
          "--eval" (format nil "(arcdocdb.ci::ci-measure-worker ~S ~D)" (namestring path) replica)
          "--quit")))

(defun ci-measure-stop-child (process)
  "Bounded cleanup even after a timeout; do not wait indefinitely for a child."
  (when (sb-ext:process-alive-p process)
    (sb-ext:process-kill process 9)
    (loop repeat 100
          while (sb-ext:process-alive-p process) do (sleep 1/100)))
  (when (sb-ext:process-alive-p process)
    (ci-measure-reject "child still alive after SIGKILL; recorder must terminate job"))
  (sb-ext:process-close process))

(defun ci-measure-run-child (directory replica)
  "One serial child; child raw and log are exclusive evidence, never parsed as code."
  (let* ((raw (merge-pathnames (format nil "measure-replica-~2,'0D.lisp" replica) directory))
         (log (merge-pathnames (format nil "measure-replica-~2,'0D.log" replica) directory))
         (start (get-internal-real-time)) (timed-out nil) (log-exhausted nil) (code nil))
    (when (probe-file raw) (ci-measure-reject "replica evidence already exists"))
    (with-open-file (log-stream log :direction :output :if-exists :error
                               :if-does-not-exist :create :external-format :utf-8)
      (let ((process (sb-ext:run-program
                      (namestring sb-ext:*runtime-pathname*)
                      (ci-measure-child-arguments raw replica)
                      :search nil :wait nil :input nil :output log-stream :error log-stream)))
        (unwind-protect
             (progn
               (loop repeat 3000
                     while (sb-ext:process-alive-p process) do
                       (when (> (file-length log-stream) 1048576)
                         (setf log-exhausted t) (return))
                       (unless (ci-measure-budget-left-p start (get-internal-real-time)
                                                         internal-time-units-per-second
                                                         +ci-measure-wait-seconds+)
                         (setf timed-out t) (return))
                       (sleep 1/100))
               (when (and (not log-exhausted) (sb-ext:process-alive-p process))
                 (setf timed-out t))
               (unless (or timed-out log-exhausted)
                 (setf code (sb-ext:process-exit-code process))))
          (ci-measure-stop-child process))))
    (let ((record (when (and (not timed-out) (not log-exhausted)
                             (funcall (fdefinition 'ci-regular-file-p) raw))
                    (funcall (fdefinition 'ci-read) raw :max-bytes 65536))))
      (when record (ci-measure-validate-replica record replica))
      (list :replica replica :status (cond (timed-out :budget-exhausted)
                                           (log-exhausted :failed)
                                           ((and record (eq (getf record :status) :budget-exhausted))
                                            :budget-exhausted)
                                           ((and (eql code 0) record
                                                 (eq (getf record :status) :measured)) :measured)
                                           (t :failed))
            :exit-code code :reason (cond (timed-out "parent wait exceeded 30 seconds")
                                          (log-exhausted "child log exceeded 1 MiB")
                                          ((and record (not (eq (getf record :status) :measured)))
                                           (getf record :reason))
                                          ((not (eql code 0)) "child exited unsuccessfully; see log")
                                          ((null record) "child report missing")
                                          (t (getf record :reason)))
            :raw-file (file-namestring raw) :log-file (file-namestring log)
            :samples (when record (getf record :samples))))))

(defun ci-measure-validate-sample (sample id replica)
  "Reconcile fixed method, counts, independent oracle and exact rate after transport."
  (multiple-value-bind (buffer expected oracle) (ci-measure-fixture id)
    (let* ((size (length buffer)) (ticks (getf sample :wall-ticks))
           (units (getf sample :ticks-per-second)))
      (funcall (fdefinition 'ci-plist-check) sample
                      '(:id :replica :status :operations :bytes-per-operation :bytes :warmup-operations
                        :wall-ticks :cpu-ticks :ticks-per-second :operations-per-second :rate-reason
                        :bytes-consed :gc-cpu-ticks :gc-wall-ticks :gc-cpu-reason :gc-wall-reason
                        :gc-count :gc-count-status :gc-count-reason :return-checksum
                        :expected-return-checksum :expected-return :oracle :input-unchanged
                        :owned-buffer-bytes)
                      '(:id :replica :status :operations :bytes-per-operation :bytes :warmup-operations
                        :wall-ticks :cpu-ticks :ticks-per-second :bytes-consed :return-checksum
                        :expected-return-checksum :expected-return :oracle :input-unchanged))
      (unless (and (eq id (getf sample :id)) (eql replica (getf sample :replica))
                   (eq :measured (getf sample :status)) (eq t (getf sample :input-unchanged))
                   (eql +ci-measure-iterations+ (getf sample :operations))
                   (eql +ci-measure-warmup+ (getf sample :warmup-operations))
                   (eql size (getf sample :bytes-per-operation))
                   (eql (* size +ci-measure-iterations+) (getf sample :bytes))
                   (eql expected (getf sample :expected-return))
                   (eql (* expected +ci-measure-iterations+) (getf sample :return-checksum))
                   (eql (* expected +ci-measure-iterations+) (getf sample :expected-return-checksum))
                   (equal oracle (getf sample :oracle))
                   (eql units internal-time-units-per-second))
        (ci-measure-reject "replica contradicts fixed workload/oracle"))
      (dolist (key '(:wall-ticks :cpu-ticks :bytes-consed))
        (unless (typep (getf sample key) '(integer 0 *))
          (ci-measure-reject "negative or missing mandatory sensor")))
      (dolist (key '(:gc-cpu-ticks :gc-wall-ticks))
        (unless (or (null (getf sample key)) (typep (getf sample key) '(integer 0 *)))
          (ci-measure-reject "invalid optional GC sensor")))
      (unless (equal (getf sample :operations-per-second)
                     (ci-measure-ratio (* +ci-measure-iterations+ units) ticks))
        (ci-measure-reject "invalid transported rate"))
      (unless (and (eql (* 2 size) (getf sample :owned-buffer-bytes))
                   (null (getf sample :gc-count))
                   (eq :unsupported (getf sample :gc-count-status))
                   (stringp (getf sample :gc-count-reason))
                   (or (plusp ticks) (stringp (getf sample :rate-reason)))
                   (or (getf sample :gc-cpu-ticks) (stringp (getf sample :gc-cpu-reason)))
                   (or (getf sample :gc-wall-ticks) (stringp (getf sample :gc-wall-reason))))
        (ci-measure-reject "invalid absence or owned buffer metadata"))))
  sample)

(defun ci-measure-validate-replica (record replica)
  "Reject duplicate/unknown workload IDs and incomplete successful children."
  (funcall (fdefinition 'ci-plist-check) record '(:kind :schema-version :replica :status :reason :samples)
                  '(:kind :schema-version :replica :status :reason :samples))
  (unless (and (eq (getf record :kind) :ci-measure-replica)
               (eql (getf record :schema-version) 1) (eql (getf record :replica) replica)
               (member (getf record :status) '(:measured :failed :budget-exhausted))
               (listp (getf record :samples)))
    (ci-measure-reject "invalid child envelope"))
  (let ((seen nil))
    (dolist (sample (getf record :samples))
      (let ((id (getf sample :id)))
        (unless (and (member id *ci-measure-workloads*) (not (member id seen)))
          (ci-measure-reject "duplicate or unknown child workload"))
        (ci-measure-validate-sample sample id replica)
        (push id seen)))
    (when (and (eq (getf record :status) :measured)
               (/= (length seen) (length *ci-measure-workloads*)))
      (ci-measure-reject "successful child missing workload")))
  record)

(defun ci-measure-statistics (samples)
  "Raw dispersion and pooled exact rate; zero resolution is explicit, no quantiles."
  (when samples
    (let* ((ticks (sort (mapcar (lambda (sample) (getf sample :wall-ticks)) samples) #'<))
           (total-ticks (reduce #'+ ticks))
           (operations (reduce #'+ samples :key (lambda (sample) (getf sample :operations))))
           (bytes (reduce #'+ samples :key (lambda (sample) (getf sample :bytes)))))
      (list :samples (length samples) :wall-ticks-min (first ticks)
            :wall-ticks-median
            (if (oddp (length ticks)) (nth (floor (length ticks) 2) ticks)
                (ci-measure-ratio (+ (nth (1- (floor (length ticks) 2)) ticks)
                                     (nth (floor (length ticks) 2) ticks)) 2))
            :wall-ticks-max (car (last ticks)) :zero-tick-samples (count 0 ticks)
            :total-wall-ticks total-ticks :total-operations operations :total-bytes bytes
            :operations-per-second (ci-measure-ratio (* operations internal-time-units-per-second)
                                                     total-ticks)
            :bytes-per-second (ci-measure-ratio (* bytes internal-time-units-per-second)
                                                total-ticks)
            :rate-reason (when (zerop total-ticks) "clock resolution: zero total elapsed ticks")))))

(defun ci-measure-unavailable-metrics ()
  "Absence is NIL with scope, unit, method, status and reason, never fabricated zero."
  (loop for (id scope unit status reason) in
        '((:engine-throughput :database :operations-per-second :not-implemented
           "No end-to-end engine workload is implemented by this bounded kernel harness.")
          (:engine-compaction :database :bytes-per-second :not-implemented
           "No complete engine compaction workload is implemented by this harness.")
          (:p99-latency :product-kernel :nanoseconds :unsupported
           "Five aggregate repetitions provide no per-operation latency distribution.")
          (:p999-latency :product-kernel :nanoseconds :unsupported
           "No per-operation samples or histogram support tail quantiles.")
          (:fsync-latency :storage :nanoseconds :unsupported
           "This in-memory workload issues no fsync calls.")
          (:rss :process :bytes :unsupported
           "No bounded portable RSS sampler; owned buffers and bytes consed are not RSS.")
          (:gc-count :process :collections :unsupported
           "No public monotonic GC total; generation counters reset on promotion."))
        collect (list :id id :scope scope :unit unit :method "ci-micro-v1"
                      :status status :value nil :reason reason :samples nil)))

(defun ci-measure-metric-rows (replicas campaign-status reason)
  "Keep partial observations but never label a workload complete without all 5 replicas."
  (append
   (loop for id in *ci-measure-workloads*
         for samples = (loop for replica in replicas append
                             (remove-if-not (lambda (sample) (eq id (getf sample :id)))
                                            (getf replica :samples)))
         for statistics = (ci-measure-statistics samples)
         for complete = (and (eq campaign-status :measured)
                             (= (length samples) +ci-measure-replicas+))
         collect (list :id id :scope :product-kernel :unit :operations-per-second
                       :method "ci-micro-v1"
                       :status (cond ((and complete (getf statistics :operations-per-second)) :measured)
                                     (complete :unsupported)
                                     ((eq campaign-status :measured) :missing)
                                     (t campaign-status))
                       :value (when complete (getf statistics :operations-per-second))
                       :reason (if complete (getf statistics :rate-reason)
                                   (or reason "campaign incomplete"))
                       :statistics statistics :samples samples))
   (ci-measure-unavailable-metrics)))

(defun ci-measure-source-fingerprint ()
  "Keep the common tested SHA/source/policy identity without duplicating its inventory."
  (let ((source (or *ci-measure-coordinator-identity* (funcall (fdefinition 'ci-source)))))
    (loop for key in '(:tested-sha :source-id :policy-id)
          for value = (getf source key)
          unless (and (stringp value) (plusp (length value)))
            do (ci-measure-reject "common source identity missing")
          append (list key value))))

(defun ci-measure-close-replicas (observed started status reason)
  "Close all five expected replica slots; unknown partial work is never a zero sample."
  (loop for replica from 1 to +ci-measure-replicas+
        collect (or (find replica observed :key (lambda (row) (getf row :replica)))
                    (list :replica replica
                          :status (if (<= replica started) status :not-run)
                          :reason (if (<= replica started) reason "campaign stopped before this replica")
                          :exit-code nil :samples nil
                          :raw-file (when (<= replica started)
                                      (format nil "measure-replica-~2,'0D.lisp" replica))
                          :log-file (when (<= replica started)
                                      (format nil "measure-replica-~2,'0D.log" replica))))))

(defun ci-run-measure (out)
  "Save OUT/measure.lisp exclusively, return primitive summary; performance has no gate.
Require clean stable source. The CLI/recorder must fail on any status other than :MEASURED."
  (let* ((directory (ci-measure-output-directory out)) (replicas nil)
         (status :measured) (reason nil) (before nil) (after nil) (started-count 0)
         (started (get-internal-real-time)))
    (ensure-directories-exist (merge-pathnames "measure.lisp" directory))
    (when (probe-file (merge-pathnames "measure.lisp" directory))
      (ci-measure-reject "measure.lisp already exists"))
    (handler-case
        (sb-ext:with-timeout +ci-measure-budget-seconds+
          (unless (or *ci-measure-coordinator-identity* (funcall (fdefinition 'ci-working-clean-p)))
            (ci-measure-reject "dirty source before measurement"))
          (setf before (ci-measure-source-fingerprint))
          (dotimes (index +ci-measure-replicas+)
            (incf started-count)
            (let ((replica (ci-measure-run-child directory (1+ index))))
              (push replica replicas)
              (unless (eq (getf replica :status) :measured)
                (setf status (getf replica :status) reason (getf replica :reason))
                (return))))
          (setf after (ci-measure-source-fingerprint))
          (unless (and (equal before after)
                       (or *ci-measure-coordinator-identity* (funcall (fdefinition 'ci-working-clean-p))))
            (ci-measure-reject "source changed during measurement")))
      (sb-ext:timeout ()
        (setf status :budget-exhausted reason "campaign exceeded 170 seconds"))
      (ci-measure-failure (condition)
        (setf status :failed reason (ci-measure-failure-reason condition))))
    (setf replicas (ci-measure-close-replicas (nreverse replicas) started-count status reason))
    (let ((summary
            (list :kind :ci-measure :schema-version 1 :status status :reason reason
                  :method "ci-micro-v1" :exploratory t :performance-gate nil :safety 3
                  :source-before before :source-after after :source-attribution :coordinator
                  :source-proof (if *ci-measure-coordinator-identity* :outer-job-before-and-after :local-before-and-after)
                  :product-source-files (copy-list *ci-measure-product-files*)
                  :sbcl (lisp-implementation-version) :machine (machine-type)
                  :os (software-type) :cpu (machine-version)
                  :recorded-at (get-universal-time) :workers 1 :fresh-processes t
                  :replicas-planned +ci-measure-replicas+ :replicas-started started-count
                  :replicas-completed (count :measured replicas :key (lambda (row) (getf row :status)))
                  :iterations +ci-measure-iterations+ :warmup +ci-measure-warmup+
                  :dynamic-space-mib 256 :max-owned-buffer-bytes (* 2 +ci-measure-max-buffer+)
                  :budget-seconds +ci-measure-budget-seconds+ :worker-budget-seconds +ci-measure-worker-seconds+
                  :elapsed-ticks (ci-measure-delta started (get-internal-real-time))
                  :ticks-per-second internal-time-units-per-second
                  :measurement-window :product-calls-and-harness
                  :gc-counter-source "https://www.sbcl.org/manual/#Introspection-and-Tuning"
                  :replicas replicas :metrics (ci-measure-metric-rows replicas status reason))))
      (funcall (fdefinition 'ci-save) (merge-pathnames "measure.lisp" directory) summary)
      summary)))
