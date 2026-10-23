;;;; Mutazioni snapshot: suite MVCC reale, processi e FASL privati conservati.
;;;; Uso: --self-test oppure --check [directory-nuova/]. Nessun worker parallelo interno.
;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-004 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.snapshot.mutation (:use #:cl))
(in-package #:arcdocdb.snapshot.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *product-files*
  '("src/foundation/package.lisp" "src/foundation/conditions.lisp" "src/foundation/binary.lisp" "src/foundation/crc32c.lisp" "src/foundation/record.lisp" "src/foundation/batch.lisp" "src/csn/package.lisp" "src/csn/registry.lisp" "src/mvcc/package.lisp" "src/mvcc/types.lisp" "src/mvcc/snapshots-types.lisp" "src/mvcc/snapshots-core.lisp" "src/mvcc/snapshots-csn.lisp" "src/mvcc/snapshots-register.lisp" "src/mvcc/snapshots-lifecycle.lisp" "src/mvcc/snapshots-read.lisp"))
(defparameter *suite-files*
  '("tests/foundation/support.lisp" "tests/mvcc/support.lisp" "tests/mvcc/lifecycle.lisp" "tests/mvcc/capture.lisp"))
(defparameter *source-files* (append *product-files* *suite-files*))
(defconstant +child-seconds+ 30)
(defparameter *mutants*
  '(
    (:name "omit-announcement" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-ANNOUNCEMENT-BEFORE-CAPTURE"
     :before "(setf (aref words 1) (min previous announcement))"
     :after "(setf (aref words 1) previous)")
    (:name "keep-busy-announcement" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-BUSY-ROLLBACK-WITHOUT-PIN"
     :before "(setf (aref words 1) previous)"
     :after "(setf (aref words 1) (min previous announcement))")
    (:name "omit-h0-h1-guard" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-HORIZON-REGRESSION"
     :before "(unless (<= announcement horizon csn)"
     :after "(unless (<= horizon csn)")
    (:name "omit-h1-csn-guard" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-CAPTURED-CSN-BELOW-HORIZON"
     :before "(unless (<= announcement horizon csn)"
     :after "(unless (<= announcement horizon)")
    (:name "ready-strictly-greater" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-READY-EQUALITY-AND-PUBLISHED-IDENTITY"
     :before "(ready (>= horizon csn))"
     :after "(ready (> horizon csn))")
    (:name "omit-registration-fail-stop" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-THROW-AFTER-ANNOUNCEMENT"
     :before "(values generation csn ready))))
      (unless complete (invalida-registro-snapshot registry)))))"
     :after "(values generation csn ready))))
      (unless complete nil))))")
    (:name "omit-csn-fault-propagation" :file "src/mvcc/snapshots-csn.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-CANONICAL-CONDITION-IDENTITY"
     :before "(invariant-violation (condition)
      (invalida-registro-snapshot registry)
      (error condition))))"
     :after "(invariant-violation (condition)
      (error condition))))")
    (:name "publish-zero-identity" :file "src/mvcc/snapshots-register.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-READY-EQUALITY-AND-PUBLISHED-IDENTITY"
     :before "(setf (aref word 0) generation)"
     :after "(setf (aref word 0) 0)")
    (:name "retain-at-equal-threshold" :file "src/mvcc/snapshots-read.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-READY-EQUALITY-AND-PUBLISHED-IDENTITY"
     :before "(< (soglia-snapshot registry) new-csn)"
     :after "(<= (soglia-snapshot registry) new-csn)")
    (:name "swallow-other-resource" :file "src/mvcc/snapshots-csn.lisp" :test "TEST-REQ-MVC-007-SNAPSHOT-OTHER-RESOURCE-FAIL-STOP"
     :before "(unless (eq (error-reason condition) :csn-busy) (error condition))"
     :after "(when (eq (error-reason condition) :csn-busy) (error condition))")))
(define-condition invalid-target (error)
  ((reason :initarg :reason :reader target-reason))
  (:report (lambda (condition stream)
             (format stream "Bersaglio snapshot invalido: ~S." (target-reason condition)))))

(defun fingerprints ()
  (loop for file in (append *source-files* '("tools/snapshot-mutation.lisp"))
        collect (list :file file :md5 (format nil "~(~{~2,'0X~}~)"
                                            (coerce (sb-md5:md5sum-file file) 'list)))))

(defun unique-position (text target)
  "Nessuna mutazione se il frammento congelato è assente oppure ambiguo."
  (let ((position (search target text)))
    (unless position (error 'invalid-target :reason :missing))
    (when (search target text :start2 (1+ position)) (error 'invalid-target :reason :ambiguous))
    position))

(defun substitute-unique (text before after)
  (let ((position (unique-position text before)))
    (concatenate 'string (subseq text 0 position) after (subseq text (+ position (length before))))))

(defun read-text (path) (uiop:read-file-string path :external-format :utf-8))


(defun expected-test-names ()
  "Nomi letterali dei DEFTEST della suite congelata, nello stesso ordine del registro."
  (loop for file in (rest *suite-files*)
        append (loop for line in (uiop:split-string (read-text file) :separator '(#\Newline))
                     when (and (>= (length line) 9) (string= "(deftest " line :end2 9))
                       collect (string-upcase
                                (first (uiop:split-string (subseq line 9)
                                                        :separator '(#\Space #\Tab #\( #\))))))))

(defun validate-mutants ()
  (unless (= 10 (length *mutants*)) (error "Numero mutanti snapshot inatteso."))
  (let ((tests (expected-test-names)))
    (unless (and tests (= (length tests) (length (remove-duplicates tests :test #'string=))))
      (error "Suite MVCC vuota oppure nomi duplicati."))
    (dolist (mutant *mutants*)
      (unless (member (getf mutant :test) tests :test #'string=)
        (error "Mutante snapshot senza test nominato nella suite."))
      (unique-position (read-text (getf mutant :file)) (getf mutant :before))))
  t)

(defun parse-child-report (text)
  "Una sola plist keyword; niente read-eval, marker citati o forme successive."
  (let ((*read-eval* nil) (*package* (find-package :cl-user)))
    (handler-case
        (with-input-from-string (stream text)
          (let ((r (read stream nil :eof)))
            (when (and (consp r) (list-length r) (evenp (length r))
                       (loop for key in r by #'cddr always (keywordp key))
                       (eql 1 (getf r :schema-version))
                       (eq :snapshot-mutation-child (getf r :kind))
                       (eq :eof (read stream nil :eof))) r)))
      (error () nil))))

(defun classify-result (child exit expected &optional signal timed-out baseline)
  "Solo fallimento runtime del test nominato; guasti OS/trasporto non sono kill."
  (cond
    (signal (values :worker-error :process-signal))
    (timed-out (values :worker-error :timeout))
    ((and child (eq :complete (getf child :phase)) (integerp exit) (not (zerop exit)))
     (values :worker-error :after-completion))
    ((and child (eq :fixture-timeout (getf child :failure-kind)))
     (values :worker-error :fixture-timeout))
    ((or (null child) (not (integerp exit))) (values :worker-error :unreadable-child-report))
    ((member (getf child :phase) '(:compile-product :compile-tests))
     (values :worker-error :compilation-failure))
    ((and (zerop exit) (eq :ok (getf child :status)) (eq :complete (getf child :phase))
          (equal expected (getf child :passed-tests)))
     (values (if baseline :baseline-passed :survived) nil))
    ((and (not baseline) (= exit 1) (eq :failed (getf child :status))
          (eq :tests (getf child :phase)) (eq :runtime (getf child :failure-kind))
          (equal expected (list (getf child :failed-test))))
     (values :detected nil))
    (t (values :invalid :failure-outside-expected-test))))

(defparameter *runner-source*
  "(require :asdf)
(require :sb-posix)
(defvar *snapshot-products* nil)
(defvar *snapshot-suite* nil)
(defvar *snapshot-expected* nil)
(defvar *current-test* nil)
(defvar *passed-tests* nil)
(defun compile-local (file)
  (let ((output (merge-pathnames (make-pathname :type \"fasl\" :defaults file) #p\"fasl/\")))
    (ensure-directories-exist output)
    (multiple-value-bind (fasl warnings failed) (compile-file file :output-file output)
      (when (or warnings failed) (error \"Compilazione non valida: ~A\" file))
      (load fasl))))
(defun snapshot-child-main ()
  (let ((phase :compile-product) (failure nil) (code 0) (failure-kind nil))
    (handler-case
        (let ((*standard-output* *error-output*))
          (handler-bind ((warning (lambda (condition) (error condition))))
            (dolist (file *snapshot-products*) (compile-local file))
            (setf phase :compile-tests)
            (dolist (file *snapshot-suite*) (compile-local file)))
          (let* ((package (find-package \"ARCDOCDB.MVCC.TESTS\"))
                 (tests (reverse (symbol-value (find-symbol \"*MVCC-TESTS*\" package))))
                 (selected (second sb-ext:*posix-argv*)))
            (unless (equal *snapshot-expected* (mapcar (lambda (entry) (symbol-name (car entry))) tests))
              (error \"Registre suite diverse dalla lista congelata.\"))
            (when (and selected (not (find selected tests :test #'string= :key (lambda (entry) (symbol-name (car entry))))))
              (error \"Test nominato sconosciuto.\"))
            (setf phase :tests)
            (dolist (entry tests)
              (let ((name (symbol-name (car entry))))
                (when (or (null selected) (string= name selected))
                  (setf *current-test* name)
                  (funcall (cdr entry))
                  (push name *passed-tests*))))
            (setf *current-test* nil phase :complete)))
      (error (condition)
        (setf failure condition code (if (eq phase :tests) 1 2)
              failure-kind (if (and (find-package \"ARCDOCDB.MVCC.TESTS\")
                                    (find-class (find-symbol \"CAPTURE-FIXTURE-TIMEOUT\" \"ARCDOCDB.MVCC.TESTS\") nil)
                                    (typep condition (find-symbol \"CAPTURE-FIXTURE-TIMEOUT\" \"ARCDOCDB.MVCC.TESTS\")))
                               :fixture-timeout :runtime))
        (format *error-output* \"~&~A: ~A~%\" (type-of condition) condition)))
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :snapshot-mutation-child :phase phase
                   :status (if failure :failed :ok) :failed-test *current-test*
                   :passed-tests (reverse *passed-tests*) :failure-kind failure-kind
                   :diagnostic (when failure (princ-to-string failure))) :pretty t)
      (terpri) (finish-output))
    (sb-ext:exit :code code)))
(snapshot-child-main)
")
(defun write-text (text path)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :if-exists :error :if-does-not-exist :create
                              :external-format :utf-8)
    (write-string text stream)))

(defun exclusive-directory (path)
  "mkdir esclusivo; i genitori soltanto possono già esistere."
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname path) (truename "./")))
         (placeholder (make-pathname :directory (butlast (pathname-directory directory))
                                     :name "placeholder" :type nil :defaults directory)))
    (ensure-directories-exist placeholder)
    (sb-posix:mkdir (namestring directory) #o700)
    directory))


(defun automatic-directory (kind)
  "Sempre sotto spikes/out: fixture reali disponibili per CI e audit."
  (loop for attempt below 100
        for path = (format nil "spikes/out/~D-snapshot-~A-~D-~D/" (get-universal-time)
                           kind (sb-posix:getpid) attempt)
        do (handler-case (return (exclusive-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition))))
        finally (error "Directory snapshot esclusiva non disponibile.")))

(defun write-runner (directory)
  (let ((path (merge-pathnames "isolated-build.lisp" directory)))
    (with-open-file (out path :direction :output :if-exists :error :external-format :utf-8)
      (write '(require :asdf) :stream out) (terpri out)
      (dolist (entry (list (list '*snapshot-products* *product-files*)
                          (list '*snapshot-suite* *suite-files*)
                          (list '*snapshot-expected* (expected-test-names))))
        (write `(defparameter ,(intern (symbol-name (first entry)) :cl-user) ',(second entry)) :stream out)
        (terpri out))
      (write-string *runner-source* out))
    (namestring path)))

(defun copy-fixture (directory mutant root)
  "I mutanti copiano la baseline integra verificata, senza FASL/log/runner preesistenti."
  (dolist (file *source-files*)
    (let* ((source (read-text (merge-pathnames file root)))
           (text (if (and mutant (string= file (getf mutant :file)))
                     (substitute-unique source (getf mutant :before) (getf mutant :after)) source)))
      (write-text text (merge-pathnames file directory))))
  (write-runner directory))

(defun execute-copy (directory &optional selected)
  "Deadline bounded: conserva exit e signal reali, separati, anche alla terminazione del child."
  (let* ((stdout (merge-pathnames "stdout.log" directory)) (stderr (merge-pathnames "stderr.log" directory))
         (argv (append '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
                         "--script" "isolated-build.lisp") (when selected (list selected))))
         (process (uiop:launch-program argv :directory directory :output stdout :error-output stderr))
         (deadline (+ (get-internal-real-time) (* +child-seconds+ internal-time-units-per-second)))
         (timed-out nil) (exit nil) (signal nil))
    (unwind-protect
         (progn
           (loop repeat 3000 while (uiop:process-alive-p process)
                 do (when (>= (get-internal-real-time) deadline) (setf timed-out t) (return))
                    (sleep 0.01)
                 finally (when (uiop:process-alive-p process) (setf timed-out t)))
           (when timed-out (uiop:terminate-process process :urgent t))
           (multiple-value-setq (exit signal) (uiop:wait-process process)))
      (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t)))
    (list :exit-code exit :signal signal :timed-out timed-out :argv argv
          :runner (namestring (merge-pathnames "isolated-build.lisp" directory))
          :stdout-log (namestring stdout) :stderr-log (namestring stderr)
          :report (parse-child-report (read-text stdout)))))

(defun run-copy (directory mutant source-root)
  "Conserva i log anche al rifiuto di copia/trasporto; nessun valore OS non osservato inventato."
  (let ((result (list :name (if mutant (getf mutant :name) "baseline") :directory (namestring directory)
                      :expected-tests (if mutant (list (getf mutant :test)) (expected-test-names))
                      :status :running :result :pending :exit-code nil :signal nil :execution nil)))
    (handler-case
        (progn
          (write-text "" (merge-pathnames "stdout.log" directory))
          (write-text "" (merge-pathnames "stderr.log" directory))
          (copy-fixture directory mutant source-root)
          (let ((execution (execute-copy directory (when mutant (getf mutant :test)))))
            (setf (getf result :execution) execution
                  (getf result :exit-code) (getf execution :exit-code)
                  (getf result :signal) (getf execution :signal))
            (multiple-value-bind (classification reason)
                (classify-result (getf execution :report) (getf execution :exit-code)
                                 (getf result :expected-tests) (getf execution :signal)
                                 (getf execution :timed-out) (null mutant))
              (setf (getf result :result) classification (getf result :diagnostic) reason
                    (getf result :status) (if (member classification '(:detected :baseline-passed)) :ok :failed)))))
      (error (condition)
        (with-open-file (out (merge-pathnames "setup-error.log" directory) :direction :output
                             :if-exists :append :if-does-not-exist :create :external-format :utf-8)
          (format out "~A: ~A~%" (type-of condition) condition))
        (setf (getf result :result) :worker-error (getf result :status) :failed
              (getf result :diagnostic) :infrastructure-error (getf result :detail) (princ-to-string condition))))
    result))

(defun save-report (report directory)
  (when directory
    (with-open-file (out (merge-pathnames "report.lisp" directory) :direction :output
                        :if-exists :supersede :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream out :pretty t) (terpri out)))))

(defun record-result (report result baseline)
  (if baseline (setf (getf report :baseline) result)
      (setf (getf report :mutants) (append (getf report :mutants) (list result))))
  (when (eq :worker-error (getf result :result)) (incf (getf report :worker-errors 0)))
  report)

(defun self-test-structural ()
  (unless (string= "xAy" (substitute-unique "xBy" "B" "A")) (error "Self-test sostituzione."))
  (dolist (entry '(("abc" "Z" :missing) ("xBxB" "B" :ambiguous)))
    (destructuring-bind (text target expected) entry
      (let ((caught nil))
        (handler-case (unique-position text target)
          (invalid-target (condition) (setf caught (eq expected (target-reason condition)))))
        (unless caught (error "Self-test target invalido.")))))
  (let* ((failed '(:schema-version 1 :kind :snapshot-mutation-child :status :failed :phase :tests
                   :failure-kind :runtime :failed-test "fixture"))
         (done '(:schema-version 1 :kind :snapshot-mutation-child :status :ok :phase :complete
                 :passed-tests ("fixture")))
         (compile '(:schema-version 1 :kind :snapshot-mutation-child :status :failed :phase :compile-product))
         (timeout '(:schema-version 1 :kind :snapshot-mutation-child :status :failed :phase :tests
                    :failure-kind :fixture-timeout :failed-test "fixture"))
         (text (write-to-string failed :readably t)))
    (unless (and (equal failed (parse-child-report text))
                 (null (parse-child-report (concatenate 'string "0: " text)))
                 (null (parse-child-report (concatenate 'string text " NIL")))
                 (null (parse-child-report "#.(error \"never\")"))
                 (eq :detected (classify-result failed 1 '("fixture")))
                 (eq :invalid (classify-result failed 1 '("other")))
                 (eq :invalid (classify-result failed 0 '("fixture")))
                 (eq :invalid (classify-result failed 1 '("fixture") nil nil t))
                 (eq :worker-error (classify-result compile 2 '("fixture")))
                 (eq :worker-error (classify-result compile 2 '("fixture") 9))
                 (eq :worker-error (classify-result failed 1 '("fixture") 9))
                 (eq :worker-error (classify-result failed 1 '("fixture") nil t))
                 (eq :worker-error (classify-result timeout 1 '("fixture")))
                 (eq :worker-error (classify-result nil 1 '("fixture")))
                 (eq :worker-error (classify-result done 7 '("fixture")))
                 (eq :worker-error (classify-result done 0 '("fixture") 9))
                 (eq :survived (classify-result done 0 '("fixture")))
                 (eq :baseline-passed (classify-result done 0 '("fixture") nil nil t))
                 (eq :invalid (classify-result done 0 '("fixture" "absent") nil nil t)))
      (error "Self-test parsing/classificazione snapshot.")))
  (validate-mutants)
  (list :status :ok :unique-targets 10 :read-eval-disabled t :only-named-runtime-detection t))

(defun self-test-processes ()
  "Due child reali: il segnale ha precedenza anche su report che avrebbe attestato un kill."
  (let* ((directory (automatic-directory "self-test"))
         (report (list :schema-version 1 :kind :snapshot-process-self-test :status :running
                       :worker-errors 0 :baseline nil :mutants nil)))
    (save-report report directory)
    (handler-case
        (progn
          (dolist (mode '(:signal :completion-exit))
            (let* ((child (exclusive-directory (merge-pathnames (format nil "~(~A~)/" mode) directory)))
                   (runner (merge-pathnames "isolated-build.lisp" child))
                   (data (if (eq mode :signal)
                             '(:schema-version 1 :kind :snapshot-mutation-child :status :failed
                               :phase :tests :failure-kind :runtime :failed-test "fixture")
                             '(:schema-version 1 :kind :snapshot-mutation-child :status :ok
                               :phase :complete :passed-tests ("fixture")))))
              (with-open-file (out runner :direction :output :if-exists :error :external-format :utf-8)
                (dolist (form (append `((require :sb-posix) (write ',data :readably t) (terpri) (finish-output))
                                     (if (eq mode :signal)
                                         '((sb-posix:kill (sb-posix:getpid) sb-posix:sigkill))
                                         '((sb-ext:exit :code 7)))))
                  (write form :stream out) (terpri out)))
              (let* ((execution (execute-copy child))
                     (classification (classify-result (getf execution :report) (getf execution :exit-code)
                                                      '("fixture") (getf execution :signal)
                                                      (getf execution :timed-out)))
                     (entry (list :name mode :result classification :execution execution)))
                (setf report (record-result report entry nil))
                (save-report report directory)
                (unless (and (eq :worker-error classification) (not (getf execution :timed-out))
                             (if (eq mode :signal) (eql 9 (getf execution :signal))
                                 (and (null (getf execution :signal)) (eql 7 (getf execution :exit-code)))))
                  (error "Self-test processo snapshot: esito OS non conservato.")))))
          (unless (= 2 (getf report :worker-errors)) (error "Contatori fixture snapshot."))
          (let ((*read-eval* nil))
            (with-open-file (in (merge-pathnames "report.lisp" directory))
              (let ((saved (read in)))
                (unless (and (equal saved report) (eq :eof (read in nil :eof)))
                  (error "Fixture snapshot: report non conservato.")))))
          (setf (getf report :status) :passed)
          (save-report report directory))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
        (save-report report directory) (error condition)))
    (format t "~&Snapshot: fixture processi conservate in ~A~%" (merge-pathnames "report.lisp" directory))
    (namestring (merge-pathnames "report.lisp" directory))))

(defun main ()
  (let ((directory nil) (before nil)
        (report (list :schema-version 1 :kind :snapshot-mutations :status :running :worker-errors 0
                      :baseline nil :mutants nil :targets *mutants* :self-test nil
                      :limits '(:ten-targeted-mutants :whole-mvcc-suite-baseline :named-runtime-test-kill
                                :minimal-product-copy :verified-baseline-snapshot :private-fasl
                                :raw-logs-and-runner-retained :signal-timeout-compilation-not-kill
                                :no-c1-mcdc-or-engine-qualification))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (unless (or (equal args '("--self-test")) (equal args '("--check"))
                      (and (= 2 (length args)) (string= (first args) "--check")))
            (error "Usare --self-test oppure --check [directory-nuova/]."))
          (setf before (fingerprints) (getf report :source-fingerprints-before) before
                (getf report :expected-suite) (expected-test-names)
                (getf report :self-test) (self-test-structural)
                (getf report :process-fixtures) (self-test-processes))
          (when (string= "--check" (first args))
            (setf directory (if (second args) (exclusive-directory (second args)) (automatic-directory "campaign")))
            (save-report report directory)
            (let* ((baseline-directory (exclusive-directory (merge-pathnames "baseline/" directory)))
                   (baseline (run-copy baseline-directory nil (truename "./"))))
              (setf report (record-result report baseline t))
              (save-report report directory)
              (unless (eq :baseline-passed (getf baseline :result)) (error "Baseline snapshot fallita."))
              (dolist (mutant *mutants*)
                (setf report (record-result report
                                           (run-copy (exclusive-directory (merge-pathnames (format nil "~A/" (getf mutant :name)) directory))
                                                     mutant (merge-pathnames "baseline/" directory)) nil))
                (save-report report directory)))
            (unless (and (= 10 (length (getf report :mutants)))
                         (every (lambda (r) (eq :detected (getf r :result))) (getf report :mutants)))
              (error "Mutante snapshot sopravvissuto, verifica invalida o worker-error.")))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed
              (getf report :diagnostic) (format nil "tools/snapshot-mutation.lisp COD-61: ~A" condition))))
    (when before
      (handler-case
          (let ((after (fingerprints)))
            (setf (getf report :source-fingerprints-after) after
                  (getf report :source-consistency) (if (equal before after) :stable :changed))
            (unless (equal before after)
              (setf (getf report :status) :source-changed
                    (getf report :diagnostic) "tools/snapshot-mutation.lisp COD-61: sorgenti cambiati.")))
        (error (condition) (setf (getf report :status) :failed (getf report :diagnostic)
                                (format nil "tools/snapshot-mutation.lisp COD-61: ~A" condition)))))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))
(main)
