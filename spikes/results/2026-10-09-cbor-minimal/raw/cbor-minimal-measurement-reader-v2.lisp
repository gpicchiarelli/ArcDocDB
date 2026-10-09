;;;; Audit dei dati conservati, senza caricare prodotto, test o driver di misura.
(require :asdf)
(require :sb-md5)
(load "tools/evidence-storage.lisp")
(defparameter *checks* nil)
(defun insist (predicate name &optional detail)
  (unless predicate (error "Audit dati: ~S ~S" name detail))
  (push (list :check name :status :pass :detail detail) *checks*))
(defun safe-data (text)
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)) (*read-base* 10))
    (with-input-from-string (input text)
      (let ((datum (read input nil :eof)))
        (insist (not (eq :eof datum)) :nonempty-data)
        (insist (eq :eof (read input nil :eof)) :single-datum-eof)
        datum))))
(defun md5 (path)
  (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))
(defun raw-bytes (path)
  (with-open-file (input path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length input) :element-type '(unsigned-byte 8))))
      (assert (= (length bytes) (read-sequence bytes input)))
      (assert (eq :eof (read-byte input nil :eof)))
      bytes)))
(defun raw-text (path)
  (sb-ext:octets-to-string (raw-bytes path) :external-format :utf-8))
(defun near (a b)
  (and (realp a) (realp b) (<= (abs (- a b)) (* 1d-12 (max 1d0 (abs a) (abs b))))))
(defun arithmetic-values (octets start)
  (let* ((lead (first octets)) (major (floor lead 32)) (ai (mod lead 32))
         (width (case ai (24 1) (25 2) (26 4) (27 8) (otherwise 0)))
         (argument (if (zerop width) ai
                       (reduce (lambda (acc byte) (+ (* acc 256) byte))
                               (rest octets) :initial-value 0))))
    (assert (= (length octets) (1+ width)))
    (list major ai (floor argument (expt 2 32)) (mod argument (expt 2 32))
          (+ start 1 width) :argument)))
(defun weighted-token (values)
  (destructuring-bind (major ai high low next form) values
    (assert (eq form :argument))
    (+ major (* ai (expt 2 3)) (* high (expt 2 8)) (* low (expt 2 16))
       (* next (expt 2 20)) (expt 2 24))))
(defun sink-formula (calls token)
  (mod (+ (* calls token) (/ (* calls (1- calls)) 2)) (1+ most-positive-fixnum)))
(defun minimum-float-p (values)
  ;; Oracolo aritmetico del formato IEEE, senza float host o helper prodotto.
  (destructuring-bind (major ai high low next form) values
    (declare (ignore next form))
    (if (/= major 7) t
        (if (= ai 25) t
            (let* ((bits (+ (* high (expt 2 32)) low))
                   (p (if (= ai 26) 23 52)) (eb (if (= ai 26) 8 11))
                   (bias (if (= ai 26) 127 1023))
                   (target-p (if (= ai 26) 10 23))
                   (target-eb (if (= ai 26) 5 8))
                   (target-bias (if (= ai 26) 15 127))
                   (fraction (mod bits (expt 2 p)))
                   (exponent (mod (floor bits (expt 2 p)) (expt 2 eb))))
              (cond ((= exponent (1- (expt 2 eb)))
                     (not (zerop (mod fraction (expt 2 (- p target-p))))))
                    ((and (zerop exponent) (zerop fraction)) nil)
                    (t
                     (let* ((significand (if (zerop exponent) fraction
                                            (+ (expt 2 p) fraction)))
                            (power (- (if (zerop exponent) 1 exponent) bias p))
                            (binary-exponent (+ (1- (integer-length significand)) power))
                            (min-normal (- 1 target-bias))
                            (max-normal (- (1- (expt 2 target-eb)) 1 target-bias))
                            (quantum (if (< binary-exponent min-normal)
                                         (- min-normal target-p)
                                         (- binary-exponent target-p)))
                            (scaled (* significand (expt 2 (- power quantum)))))
                       (not (and (<= binary-exponent max-normal) (integerp scaled)
                                 (plusp scaled)
                                 (< scaled (expt 2 (1+ target-p)))))))))))))
(defun sample-audit (sample calls warmup token timer)
  (let ((ticks (getf sample :raw-ticks)) (seconds (getf sample :seconds))
        (expected (sink-formula calls token)))
    (insist (and (= calls (getf sample :iterations))
                 (= warmup (getf sample :warmup-iterations))
                 (= token (getf sample :expected-return-token))) :sample-parameters)
    (insist (and (= expected (getf sample :sink))
                 (= expected (getf sample :expected-sink))) :sample-sink expected)
    (insist (and (integerp ticks) (plusp ticks)
                 (near seconds (/ ticks timer))
                 (near (getf sample :calls-per-second) (/ (* calls timer) ticks)))
            :sample-clock-rate ticks)))
(defun line-present (text line)
  (member line (mapcar (lambda (part) (string-right-trim '(#\Return) part))
                      (uiop:split-string text :separator '(#\Newline))) :test #'string=))
(defun compilation-error-p (text)
  (some (lambda (marker) (search marker text :test #'char-equal))
        '("compilation aborted" "COMPILE-FILE-ERROR" "COMPILE-FILE-WARNED")))
(defun copied-paths (directory)
  (sort (append '("arcdocdb.asd" "tools/build.lisp")
                (mapcar (lambda (path) (enough-namestring path directory))
                        (append (directory (merge-pathnames "src/**/*.lisp" directory))
                                (directory (merge-pathnames "tests/**/*.lisp" directory)))))
        #'string<))
(defun replace-unique (text before after)
  (let ((pos (search before text)))
    (assert pos)
    (assert (null (search before text :start2 (1+ pos))))
    (concatenate 'string (subseq text 0 pos) after (subseq text (+ pos (length before))))))
(defun first-test-in-backtrace (text)
  (let* ((error-pos (search "Unhandled " text))
         (prefix "ARCDOCDB.CBOR.MINIMAL.TESTS::TEST-")
         (pos (and error-pos (search prefix text :start2 error-pos))))
    (assert pos)
    (subseq text (+ pos (length "ARCDOCDB.CBOR.MINIMAL.TESTS::"))
            (position #\) text :start pos))))
(defparameter *kill-fixtures*
  '((:test "TEST-REQ-AFF-004-CBOR-MINIMAL-MAJOR-ZERO-TO-SIX-WIDTH-THRESHOLDS"
     :unit (24 24) :start 5 :end 7 :expected :accepted
     :observed :corruption-detected :reason :cbor-nonminimal :offset 5)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-MAJOR-ZERO-TO-SIX-WIDTH-THRESHOLDS"
     :unit (25 1 0) :start 5 :end 8 :expected :accepted
     :observed :corruption-detected :reason :cbor-nonminimal :offset 5)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-MAJOR-ZERO-TO-SIX-WIDTH-THRESHOLDS"
     :unit (26 0 1 0 0) :start 5 :end 10 :expected :accepted
     :observed :corruption-detected :reason :cbor-nonminimal :offset 5)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-MAJOR-ZERO-TO-SIX-WIDTH-THRESHOLDS"
     :unit (27 0 0 0 0 0 0 0 1) :argument 1 :start 5 :end 14
     :expected :cbor-nonminimal :expected-offset 5 :observed :returned-without-error
     :assertion "(NOT RETURNED)" :actual-six-values :not-printed)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-ALL-HALF-AND-EXACT-EXPANSIONS"
     :unit (250 71 0 0 0) :numeric-value 32768 :start 5 :end 10
     :expected :cbor-nonminimal :expected-offset 5 :observed :returned-without-error
     :assertion "(NOT RETURNED)" :actual-six-values :not-printed)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-ALL-HALF-AND-EXACT-EXPANSIONS"
     :unit (250 51 128 0 0) :numeric-value 1/16777216 :start 5 :end 10
     :expected :cbor-nonminimal :expected-offset 5 :observed :returned-without-error
     :assertion "(NOT RETURNED)" :actual-six-values :not-printed)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-ALL-HALF-AND-EXACT-EXPANSIONS"
     :unit (251 127 240 0 0 0 0 0 0) :numeric-value :positive-infinity :start 5 :end 14
     :expected :cbor-nonminimal :expected-offset 5 :observed :returned-without-error
     :assertion "(NOT RETURNED)" :actual-six-values :not-printed)
    (:test "TEST-REQ-AFF-004-CBOR-MINIMAL-FINITE-NORMAL-SUBNORMAL-BOUNDARIES"
     :unit (251 54 160 0 0 0 0 0 0) :numeric-value
     1/713623846352979940529142984724747568191373312 :start 5 :end 14
     :expected :cbor-nonminimal :expected-offset 5 :observed :returned-without-error
     :assertion "(NOT RETURNED)" :actual-six-values :not-printed)))
(defun mutation-audit (report)
  (let* ((root #p"spikes/out/cbor-minimal-mutations/")
         (baseline (merge-pathnames "baseline/" root))
         (paths (copied-paths baseline))
         (text (raw-text (merge-pathnames "test.log" baseline)))
         (fingerprints (getf report :source-fingerprints-before))
         (targets (getf report :targets)) (results (getf report :mutants))
         (summary nil))
    (insist (and (= 1 (getf report :schema-version)) (eq :ok (getf report :status))
                 (eq :stable (getf report :source-consistency))
                 (equalp fingerprints (getf report :source-fingerprints-after)))
            :mutation-report-stable)
    (insist (= 118 (length fingerprints)) :copied-files-and-driver-fingerprints)
    (dolist (fp fingerprints)
      (insist (string= (md5 (getf fp :file)) (getf fp :md5))
              :mutation-fingerprint-current-file (getf fp :file)))
    (insist (and (= 8 (length targets)) (= 8 (length results))
                 (= 8 (getf (getf report :self-test) :applicable-mutants))) :eight-targets)
    (insist (and (eq :ok (getf (getf report :baseline) :status))
                 (zerop (getf (getf report :baseline) :exit-code))
                 (line-present text "ok    ARCDOCDB:*VERSION* è una stringa")
                 (line-present text "build e test: nessun avviso, tutti i controlli superati")
                 (not (compilation-error-p text))) :baseline-build-pass)
    (let ((lines (uiop:split-string text :separator '(#\Newline))))
      (insist (and (= 379 (count-if (lambda (line) (uiop:string-prefix-p "ok    TEST-" line)) lines))
                   (= 381 (count-if (lambda (line) (uiop:string-prefix-p "ok    " line)) lines))
                   (line-present text "15 test delle testate CBOR minime superati."))
              :baseline-complete-test-counts))
    (dolist (path paths)
      (let ((fp (find path fingerprints :key (lambda (x) (getf x :file)) :test #'string=)))
        (insist fp :baseline-path-in-report path)
        (insist (and (string= (md5 (merge-pathnames path baseline)) (getf fp :md5))
                     (equalp (raw-bytes path) (raw-bytes (merge-pathnames path baseline))))
                :baseline-byte-exact path)))
    (loop for target in targets for result in results for i from 0
          for copy = (merge-pathnames (format nil "~D/" i) root)
          for path = (getf target :source-file)
          for log = (merge-pathnames "test.log" copy)
          for log-text = (raw-text log)
          for delta = nil
          do (insist (equal paths (copied-paths copy)) :copy-paths-exact i)
             (dolist (candidate paths)
               (unless (equalp (raw-bytes (merge-pathnames candidate baseline))
                               (raw-bytes (merge-pathnames candidate copy)))
                 (push candidate delta)))
             (insist (equal delta (list path)) :one-intended-delta (list i delta))
             (insist (string= (raw-text (merge-pathnames path copy))
                              (replace-unique (raw-text (merge-pathnames path baseline))
                                              (getf target :before) (getf target :after)))
                     :exact-target-replacement i)
             (insist (and (eq :detected (getf result :result)) (getf result :detected)
                          (= 1 (getf result :exit-code)) (null (getf result :diagnostic))
                          (line-present log-text "ok    ARCDOCDB:*VERSION* è una stringa")
                          (not (line-present log-text "build e test: nessun avviso, tutti i controlli superati"))
                          (not (compilation-error-p log-text))) :runtime-detection i)
             (insist (string= (first-test-in-backtrace log-text)
                              (getf (nth i *kill-fixtures*) :test)) :first-killing-test i)
             (let* ((fasl-rel (concatenate 'string "fasl/"
                                           (namestring (make-pathname :type "fasl" :defaults path))))
                    (fasl (merge-pathnames fasl-rel copy))
                    (baseline-fasl (merge-pathnames fasl-rel baseline)))
               (insist (and (probe-file fasl) (plusp (length (raw-bytes fasl)))
                            (not (equalp (raw-bytes fasl) (raw-bytes baseline-fasl))))
                       :mutant-fasl-present-distinct i)
               (push (list :id i :name (getf target :name) :source-file path
                           :copied-files (length paths) :changed-files delta
                           :fasl (namestring fasl) :fasl-bytes (length (raw-bytes fasl))
                           :fasl-md5 (md5 fasl) :log (namestring log) :log-md5 (md5 log)
                           :first-kill (nth i *kill-fixtures*)
                           :status :detected-after-compiled-exact-smoke) summary)))
    (list :target-count 8 :target-source-files
          (remove-duplicates (mapcar (lambda (x) (getf x :source-file)) targets) :test #'string=)
          :mutation-scope-size-field :absent :effective-target-source-count 2
          :copied-file-count-per-build (length paths) :baseline :ok
          :baseline-nominal-test-lines 379 :baseline-smoke-lines 2 :baseline-ok-lines 381
          :baseline-log-md5 (md5 (merge-pathnames "test.log" baseline))
          :mutants (nreverse summary))))
(let* ((wrapper-path "spikes/out/4000546877-command-79443-0/report.lisp")
       (wrapper (arcdocdb.evidence:read-evidence wrapper-path))
       (bench (safe-data (getf wrapper :stdout)))
       (mutation-path "spikes/out/cbor-minimal-mutations/report.lisp")
       (mutation (arcdocdb.evidence:read-evidence mutation-path))
       (timer (getf bench :timer-units-per-second))
       (cells (getf bench :campaigns)) (summaries nil) (all-ticks nil)
       (self-test (getf bench :self-test))
       (baseline (getf self-test :baseline)) (positive (getf self-test :positive-control)))
  (insist (and (= 1 (getf wrapper :schema-version)) (eq :command-verification (getf wrapper :kind))
               (eq :ok (getf wrapper :status)) (zerop (getf wrapper :exit-code))
               (eq :stable (getf wrapper :source-consistency))
               (equal (getf wrapper :source-blobs-before) (getf wrapper :source-blobs-after))
               (string= "" (getf wrapper :stderr))) :benchmark-wrapper-pass-stable)
  (insist (and (= 1 (getf bench :schema-version)) (eq :cbor-minimal-benchmark (getf bench :kind))
               (eq :ok (getf bench :status)) (eq :stable (getf bench :source-consistency))
               (equalp (getf bench :source-fingerprints-before) (getf bench :source-fingerprints-after))
               (= 1 (getf bench :workers)) (= 3 (getf bench :safety)) (= 1000000 timer))
          :benchmark-report-pass-stable)
  (insist (equal (mapcar (lambda (x) (getf x :name)) cells)
                '(:u64-maximum :float16-payload-nan :float32-finite :float32-subnormal
                  :float32-payload-nan :float64-finite :float64-subnormal :float64-payload-nan))
          :eight-fixtures)
  (dolist (cell cells)
    (let* ((values (arithmetic-values (getf cell :unit) 2)) (token (weighted-token values))
           (samples (getf cell :samples))
           (rates (sort (mapcar (lambda (x) (getf x :calls-per-second)) samples) #'<)))
      (insist (and (equal values (getf cell :expected-values))
                   (= token (getf cell :expected-token)) (= 2 (getf cell :start))
                   (= (fifth values) (getf cell :end)) (getf cell :input-unchanged)
                   (minimum-float-p values) (= 5 (length samples)))
              :independent-six-values-token-minimality (getf cell :name))
      (dolist (sample samples)
        (sample-audit sample 4096 128 token timer)
        (insist (zerop (getf sample :heap-bytes)) :zero-observed-heap)
        (push (getf sample :raw-ticks) all-ticks))
      (push (list :name (getf cell :name) :expected-values values :token token
                  :sink (sink-formula 4096 token) :samples 5 :heap-bytes 0
                  :median-calls-per-second (third rates) :min-calls-per-second (first rates)
                  :max-calls-per-second (fifth rates)) summaries)))
  (insist (eq :ok (getf self-test :status)) :counter-self-test-status)
  (sample-audit baseline 4096 128 0 timer)
  (sample-audit positive 16 0 1048576 timer)
  (insist (and (zerop (getf baseline :heap-bytes))
               (= 16777472 (getf positive :heap-bytes))
               (>= (getf positive :heap-bytes) (* 16 1048576))) :counter-negative-positive-controls)
  (let* ((mutations (mutation-audit mutation))
         (datum (list :schema-version 1 :formats nil :kind :cbor-minimal-measurement-audit
                      :status :pass :recorded-at (get-universal-time)
                      :mode :read-only-preserved-data :reviewer "development_next"
                      :provenance (list :reader "/tmp/cbor-minimal-measurement-reader.lisp"
                                        :reader-md5 (md5 "/tmp/cbor-minimal-measurement-reader.lisp")
                                        :initial-inspection-reader "/tmp/cbor-minimal-measurement-inspect.lisp"
                                        :initial-inspection-reader-md5 (md5 "/tmp/cbor-minimal-measurement-inspect.lisp")
                                        :initial-inspection-log "/tmp/cbor-minimal-measurement-inspect.log"
                                        :initial-inspection-log-md5 (md5 "/tmp/cbor-minimal-measurement-inspect.log")
                                        :first-reader-attempt
                                        (list :status :invalid :exit-code 0 :audit-output-created nil
                                              :reason :reader-parenthesis-warnings-before-audit
                                              :product-or-campaign-defect nil
                                              :code "/tmp/cbor-minimal-measurement-reader-first.lisp"
                                              :code-md5 (md5 "/tmp/cbor-minimal-measurement-reader-first.lisp")
                                              :log "/tmp/cbor-minimal-measurement-reader-first.log"
                                              :log-md5 (md5 "/tmp/cbor-minimal-measurement-reader-first.log")
                                              :fix :one-close-added-at-float-oracle-one-close-removed-at-report-binding)
                                        :trusted-evidence-reader "tools/evidence-storage.lisp"
                                        :trusted-reader-md5 (md5 "tools/evidence-storage.lisp")
                                        :data-reader :read-eval-nil-single-datum-eof
                                        :product-tests-drivers-loaded nil :new-campaigns nil
                                        :wrapper wrapper-path :wrapper-md5 (md5 wrapper-path)
                                        :mutation-report mutation-path :mutation-report-md5 (md5 mutation-path))
                      :independent-log-reading
                      '(:agent "development_next/codec_next_readonly" :method :inline-read-only-commands
                        :persistent-helper nil :scope :nine-logs-and-nine-copied-systems
                        :first-kill-fixture-cross-check :completed :actual-values-not-in-log :not-inferred)
                      :benchmark (list :cells 8 :samples 40 :calls-per-sample 4096 :warmup-per-sample 128
                                       :measured-calls 163840 :warmup-calls 5120 :heap-bytes 0
                                       :sink-modulus (1+ most-positive-fixnum) :timer-units-per-second timer
                                       :raw-ticks-min (apply #'min all-ticks) :raw-ticks-max (apply #'max all-ticks)
                                       :zero-tick-samples 0 :baseline baseline :positive-control positive
                                       :environment (loop for key in '(:sbcl :machine :os :os-version :workers :safety)
                                                          append (list key (getf bench key)))
                                       :fixtures (nreverse summaries))
                      :mutations mutations :checks (nreverse *checks*)
                      :limits '(:preserved-measurements-only :no-new-product-execution
                                :serial-success-header-only :observed-heap-not-absolute-proof
                                :timing-includes-driver-checks-and-sink :external-load-uncontrolled
                                :no-latency-scaling-or-core-occupancy-claim
                                :targeted-eight-mutants-only :no-mcdc-or-release-qualification)))
         (output "spikes/out/cbor-minimal-measurement-audit.lisp"))
    (with-open-file (stream output :direction :output :if-exists :error :if-does-not-exist :create)
      (let ((*print-readably* t)) (write datum :stream stream :pretty t) (terpri stream)))
    (arcdocdb.evidence:read-evidence output)
    (format t "AUDIT PASS cells 8 samples 40 mutations 8 copied-files ~D checks ~D~%"
            (getf mutations :copied-file-count-per-build) (length (getf datum :checks)))))
