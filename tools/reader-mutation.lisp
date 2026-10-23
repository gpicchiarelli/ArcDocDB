;;;; Mutazioni reader: suite EBR e lettura reali, processi e FASL privati conservati.
;;;; Uso: --self-test oppure --check [directory-nuova/]. Nessun worker parallelo interno.
;;; REQ: REQ-CMP-007 REQ-CON-004 REQ-MVC-004 REQ-MVC-005 REQ-AFF-004 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.reader.mutation (:use #:cl))
(in-package #:arcdocdb.reader.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *product-files*
  '("src/foundation/package.lisp" "src/foundation/conditions.lisp" "src/foundation/binary.lisp"
    "src/foundation/crc32c.lisp" "src/foundation/record.lisp" "src/foundation/batch.lisp"
    "src/csn/package.lisp" "src/csn/registry.lisp"
    "src/mvcc/package.lisp" "src/mvcc/types.lisp" "src/mvcc/snapshots-types.lisp"
    "src/mvcc/snapshots-core.lisp" "src/mvcc/snapshots-csn.lisp" "src/mvcc/snapshots-register.lisp"
    "src/mvcc/snapshots-lifecycle.lisp" "src/mvcc/snapshots-read.lisp"
    "src/epochs/package.lisp" "src/epochs/types.lisp" "src/epochs/core.lisp"
    "src/epochs/read.lisp" "src/epochs/retire.lisp" "src/epochs/reclaim.lisp"
    "src/read/package.lisp" "src/read/types.lisp" "src/read/core.lisp" "src/read/task.lisp"))
(defparameter *suite-files*
  '("tests/foundation/support.lisp" "tests/epochs/support.lisp" "tests/epochs/lifecycle.lisp"
    "tests/epochs/threads.lisp" "tests/read/support.lisp" "tests/read/lifecycle.lisp"
    "tests/read/threads.lisp"))
(defparameter *source-files* (append *product-files* *suite-files*))
(defconstant +child-seconds+ 30)
(defparameter *mutants*
  '(
    (:name "reclaim-at-equal-threshold" :file "src/epochs/reclaim.lisp" :test "TEST-REQ-CMP-007-EBR-STRICT-RECLAIM-THRESHOLD"
     :before "(when (< epoch (aref (registro-epoche-words registry) +word-threshold+))"
     :after "(when (<= epoch (aref (registro-epoche-words registry) +word-threshold+))")
    (:name "allow-old-retirement-generation" :file "src/epochs/core.lisp" :test "TEST-REQ-CMP-007-EBR-STALE-GENERATION-PRESERVES-REUSE"
     :before "(= expected-generation (aref (registro-epoche-generations registry) slot))"
     :after "(<= expected-generation (aref (registro-epoche-generations registry) slot))")
    (:name "claim-stays-retired" :file "src/epochs/reclaim.lisp" :test "TEST-REQ-CMP-007-EBR-CLAIM-IS-EXCLUSIVE"
     :before "(setf (aref (registro-epoche-states registry) slot) +retirement-claimed+)"
     :after "(setf (aref (registro-epoche-states registry) slot) +retirement-retired+)")
    (:name "omit-abandon-cleanup" :file "src/read/task.lisp" :test "TEST-REQ-CMP-007-READ-ABANDON-RELEASES-PIN"
     :before "((:entering :active :faulted) (libera-contesto-lettura context))"
     :after "((:entering :active :faulted) nil)")
    (:name "omit-final-snapshot-check" :file "src/read/task.lisp" :test "TEST-REQ-MVC-004-READ-FINAL-SNAPSHOT-CHECK"
     :before "(when snapshot
           (verifica-snapshot-in-buffer snapshot (aref words +word-generation+)
                                        now words +word-confirmed-csn+)
           (unless (= (aref words +word-snapshot-csn+) (aref words +word-confirmed-csn+))
             (guasto-contesto-lettura context :read-snapshot-csn-changed)))"
     :after "(when snapshot nil)")
    (:name "overwrite-current-buffer" :file "src/read/task.lisp" :test "TEST-REQ-MVC-005-READ-CURRENT-BUFFER-UNTOUCHED"
     :before "        t)
      nil))"
     :after "        t)
      (progn (setf (aref destination index) 0) nil)))")
    (:name "restore-faulted-as-idle" :file "src/read/core.lisp" :test "TEST-REQ-AFF-004-READ-FAULTED-CONTEXT-STAYS-FAULTED"
     :before "(unless faulted (setf (contesto-lettura-state context) :idle))"
     :after "(when (or faulted (eq (contesto-lettura-state context) :faulted))
      (setf (contesto-lettura-state context) :idle))")
    (:name "reverse-clock-regression" :file "src/read/task.lisp" :test "TEST-REQ-CON-004-READ-CLOCK-REGRESSION-RELEASES-PIN"
     :before "(when (< now (aref words +word-start-time+))"
     :after "(when (> now (aref words +word-start-time+))")))
(define-condition invalid-target (error)
  ((reason :initarg :reason :reader target-reason))
  (:report (lambda (condition stream)
             (format stream "Bersaglio reader invalido: ~S." (target-reason condition)))))

(defun fingerprints ()
  (loop for file in (append *source-files* '("tools/reader-mutation.lisp"))
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
  (unless (= 8 (length *mutants*)) (error "Numero mutanti reader inatteso."))
  (let ((tests (expected-test-names))
        (names (mapcar (lambda (mutant) (getf mutant :name)) *mutants*)))
    (unless (and (= 64 (length tests))
                 (= (length tests) (length (remove-duplicates tests :test #'string=))))
      (error "Suite EBR/lettura diversa dai 64 nomi preregistrati oppure nomi duplicati."))
    (unless (= (length names) (length (remove-duplicates names :test #'string=)))
      (error "Nomi mutanti reader duplicati."))
    (dolist (mutant *mutants*)
      (unless (member (getf mutant :file) *product-files* :test #'string=)
        (error "Mutante reader fuori dalla copia minimale del prodotto."))
      (unless (member (getf mutant :test) tests :test #'string=)
        (error "Mutante reader senza test nominato nella suite."))
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
                       (eq :reader-mutation-child (getf r :kind))
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
(defvar *reader-products* nil)
(defvar *reader-suite* nil)
(defvar *reader-expected* nil)
(defvar *current-test* nil)
(defvar *passed-tests* nil)
(defun compile-local (file)
  (let ((output (merge-pathnames (make-pathname :type \"fasl\" :defaults file) #p\"fasl/\")))
    (ensure-directories-exist output)
    (multiple-value-bind (fasl warnings failed) (compile-file file :output-file output)
      (when (or warnings failed) (error \"Compilazione non valida: ~A\" file))
      (load fasl))))
(defun reader-child-main ()
  (let ((phase :compile-product) (failure nil) (code 0) (failure-kind nil))
    (handler-case
        (let ((*standard-output* *error-output*))
          (handler-bind ((warning (lambda (condition) (error condition))))
            (dolist (file *reader-products*) (compile-local file))
            (setf phase :compile-tests)
            (dolist (file *reader-suite*) (compile-local file)))
          (let* ((epochs (find-package \"ARCDOCDB.EPOCHS.TESTS\"))
                 (readers (find-package \"ARCDOCDB.READ.TESTS\"))
                 (tests (append (reverse (symbol-value (find-symbol \"*EPOCHS-TESTS*\" epochs)))
                                (reverse (symbol-value (find-symbol \"*READ-TESTS*\" readers)))))
                 (selected (second sb-ext:*posix-argv*)))
            (unless (equal *reader-expected* (mapcar (lambda (entry) (symbol-name (car entry))) tests))
              (error \"Registri suite diversi dalla lista congelata.\"))
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
              failure-kind (if (some (lambda (package-name)
                                       (let* ((package (find-package package-name))
                                              (symbol (and package (find-symbol \"FIXTURE-TIMEOUT\" package))))
                                         (and symbol (find-class symbol nil) (typep condition symbol))))
                                     '(\"ARCDOCDB.EPOCHS.TESTS\" \"ARCDOCDB.READ.TESTS\"))
                               :fixture-timeout :runtime))
        (format *error-output* \"~&~A: ~A~%\" (type-of condition) condition)))
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :reader-mutation-child :phase phase
                   :status (if failure :failed :ok) :failed-test *current-test*
                   :passed-tests (reverse *passed-tests*) :failure-kind failure-kind
                   :diagnostic (when failure (princ-to-string failure))) :pretty t)
      (terpri) (finish-output))
    (sb-ext:exit :code code)))
(reader-child-main)
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
        for path = (format nil "spikes/out/~D-reader-~A-~D-~D/" (get-universal-time)
                           kind (sb-posix:getpid) attempt)
        do (handler-case (return (exclusive-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition))))
        finally (error "Directory reader esclusiva non disponibile.")))

(defun write-runner (directory)
  (let ((path (merge-pathnames "isolated-build.lisp" directory)))
    (with-open-file (out path :direction :output :if-exists :error :external-format :utf-8)
      (write '(require :asdf) :stream out) (terpri out)
      (dolist (entry (list (list '*reader-products* *product-files*)
                          (list '*reader-suite* *suite-files*)
                          (list '*reader-expected* (expected-test-names))))
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
  (let* ((failed '(:schema-version 1 :kind :reader-mutation-child :status :failed :phase :tests
                   :failure-kind :runtime :failed-test "fixture"))
         (done '(:schema-version 1 :kind :reader-mutation-child :status :ok :phase :complete
                 :passed-tests ("fixture")))
         (compile '(:schema-version 1 :kind :reader-mutation-child :status :failed :phase :compile-product))
         (timeout '(:schema-version 1 :kind :reader-mutation-child :status :failed :phase :tests
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
      (error "Self-test parsing/classificazione reader.")))
  (validate-mutants)
  (list :status :ok :unique-targets 8 :read-eval-disabled t :only-named-runtime-detection t))

(defun self-test-processes ()
  "Due child reali: il segnale ha precedenza anche su report che avrebbe attestato un kill."
  (let* ((directory (automatic-directory "self-test"))
         (report (list :schema-version 1 :kind :reader-process-self-test :status :running
                       :worker-errors 0 :baseline nil :mutants nil)))
    (save-report report directory)
    (handler-case
        (progn
          (dolist (mode '(:signal :completion-exit))
            (let* ((child (exclusive-directory (merge-pathnames (format nil "~(~A~)/" mode) directory)))
                   (runner (merge-pathnames "isolated-build.lisp" child))
                   (data (if (eq mode :signal)
                             '(:schema-version 1 :kind :reader-mutation-child :status :failed
                               :phase :tests :failure-kind :runtime :failed-test "fixture")
                             '(:schema-version 1 :kind :reader-mutation-child :status :ok
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
                  (error "Self-test processo reader: esito OS non conservato.")))))
          (unless (= 2 (getf report :worker-errors)) (error "Contatori fixture reader."))
          (let ((*read-eval* nil))
            (with-open-file (in (merge-pathnames "report.lisp" directory))
              (let ((saved (read in)))
                (unless (and (equal saved report) (eq :eof (read in nil :eof)))
                  (error "Fixture reader: report non conservato.")))))
          (setf (getf report :status) :passed)
          (save-report report directory))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
        (save-report report directory) (error condition)))
    (format t "~&Reader: fixture processi conservate in ~A~%" (merge-pathnames "report.lisp" directory))
    (namestring (merge-pathnames "report.lisp" directory))))

(defun main ()
  (let ((directory nil) (before nil)
        (report (list :schema-version 1 :kind :reader-mutations :status :running :worker-errors 0
                      :baseline nil :mutants nil :targets *mutants* :self-test nil
                      :limits '(:eight-targeted-mutants :whole-epochs-then-read-suite-baseline :named-runtime-test-kill :selected-test-mutant-run
                                :minimal-product-copy :verified-baseline-reader :private-fasl
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
              (unless (eq :baseline-passed (getf baseline :result)) (error "Baseline reader fallita."))
              (dolist (mutant *mutants*)
                (setf report (record-result report
                                           (run-copy (exclusive-directory (merge-pathnames (format nil "~A/" (getf mutant :name)) directory))
                                                     mutant (merge-pathnames "baseline/" directory)) nil))
                (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (r) (eq :detected (getf r :result))) (getf report :mutants)))
              (error "Mutante reader sopravvissuto, verifica invalida o worker-error.")))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed
              (getf report :diagnostic) (format nil "tools/reader-mutation.lisp COD-61: ~A" condition))))
    (when before
      (handler-case
          (let ((after (fingerprints)))
            (setf (getf report :source-fingerprints-after) after
                  (getf report :source-consistency) (if (equal before after) :stable :changed))
            (unless (equal before after)
              (setf (getf report :status) :source-changed
                    (getf report :diagnostic) "tools/reader-mutation.lisp COD-61: sorgenti cambiati.")))
        (error (condition) (setf (getf report :status) :failed (getf report :diagnostic)
                                (format nil "tools/reader-mutation.lisp COD-61: ~A" condition)))))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))
(main)
