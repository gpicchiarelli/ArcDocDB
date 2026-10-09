;;;; Controller Serie: quattro mutanti concreti in cinque processi isolati.
;;;; Uso dal worktree congelato: --self-test oppure --check [directory-nuova/].
;;;; Il checkout resta intatto; copie, FASL, stdout e stderr restano nella directory esclusiva.
;;; REQ: REQ-MVC-008 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.series-controller.mutation (:use #:cl))
(in-package #:arcdocdb.series-controller.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *source-files*
  (cons "arcdocdb.asd"
        (sort (mapcar #'enough-namestring
                      (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp")))
              #'string<)))
(defconstant +child-seconds+ 30)
(defparameter *test-names*
  '("TEST-REQ-AFF-004-SERIES-FREE-AND-STALE-PREALLOCATED-EVENT-AFTER-WRAP" "TEST-REQ-WAL-006-SERIES-PUBLICATION-FIFO-UNRESOLVED-AND-RETURNED-H" "TEST-REQ-MVC-008-SERIES-BUSY-AFTER-CAS-KEEPS-ROOT-ONCE-AND-CAPTURED-TOKEN" "TEST-REQ-WAL-006-SERIES-ASYNC-SEPARATE-PUBLICATION-AND-RETIREMENT-CURSORS"))
(defparameter *mutants*
  '(
    (:name "ignore-event-generation" :file "src/series/events.lisp" :test "TEST-REQ-AFF-004-SERIES-FREE-AND-STALE-PREALLOCATED-EVENT-AFTER-WRAP"
     :before "               (= generation (commit-serie-generation event)))"
     :after "               t)")
    (:name "ignore-publication-fifo" :file "src/series/events.lisp" :test "TEST-REQ-WAL-006-SERIES-PUBLICATION-FIFO-UNRESOLVED-AND-RETURNED-H"
     :before "  (unless (eq event (svref (controllore-serie-slots controller) (controllore-serie-publish-head controller)))
    (error 'invalid-argument :reason :serie-publish-order))"
     :after "  (progn nil)")
    (:name "retry-root-cas" :file "src/series/publication.lisp" :test "TEST-REQ-MVC-008-SERIES-BUSY-AFTER-CAS-KEEPS-ROOT-ONCE-AND-CAPTURED-TOKEN"
     :before "    (:pubblicato nil)"
     :after "    (:pubblicato
     (unless (eq (sb-ext:compare-and-swap (controllore-serie-root controller)
                                        (commit-serie-expected-root event) (commit-serie-root event))
                 (commit-serie-expected-root event))
       (%serie-invariant controller :serie-root-cas)))")
    (:name "reuse-before-io-retirement" :file "src/series/retirement.lisp" :test "TEST-REQ-WAL-006-SERIES-ASYNC-SEPARATE-PUBLICATION-AND-RETIREMENT-CURSORS"
     :before "  (unless (eq (commit-serie-io-state event) :retired)
    (error 'invalid-argument :reason :serie-io-in-flight))"
     :after "  (progn nil)")))

(define-condition invalid-target (error)
  ((reason :initarg :reason :reader target-reason))
  (:report (lambda (condition stream)
             (format stream "Bersaglio CSN invalido: ~S." (target-reason condition)))))

(defun fingerprints ()
  (loop for file in (append *source-files* '("tools/series-controller-mutation.lisp"))
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

(defun validate-mutants ()
  (unless (= (length *mutants*) 4) (error "Numero dei mutanti CSN inatteso."))
  (dolist (mutant *mutants*)
    (unless (member (getf mutant :test) *test-names* :test #'string=)
      (error "Mutante CSN senza probe noto."))
    (unique-position (read-text (getf mutant :file)) (getf mutant :before)))
  t)

(defun parse-child-report (text)
  "Una sola plist letta come dati; backtrace e form citate non diventano risultati."
  (let ((*read-eval* nil) (*package* (find-package :cl-user)))
    (handler-case
        (with-input-from-string (stream text)
          (let ((report (read stream nil :eof)))
            (when (and (listp report) (evenp (length report))
                       (= (getf report :schema-version 0) 1)
                       (eq (getf report :kind) :series-controller-mutation-probe)
                       (eq (read stream nil :eof) :eof))
              report)))
      (error () nil))))

(defun classify-result (report exit expected-test)
  "Kill valido solo se la compilazione è passata e il probe nominato fallisce."
  (cond
    ((or (not report) (not (integerp exit))) (values :invalid :unreadable-child-report))
    ((member (getf report :phase) '(:compile-product :compile-probes))
     (values :invalid :compilation-failure))
    ((and (zerop exit) (eq (getf report :status) :ok) (eq (getf report :phase) :complete)
          (equal (getf report :passed-tests) (list expected-test)))
     (values :survived nil))
    ((and (= exit 1) (eq (getf report :status) :failed) (eq (getf report :phase) :tests)
          (stringp (getf report :failed-test))
          (string= expected-test (getf report :failed-test)))
     (values :detected nil))
    (t (values :invalid :failure-outside-expected-probe))))

(defun self-test ()
  "Sensore della campagna: sostituzione, errori di target, parsing e classificazione."
  (unless (string= (substitute-unique "xBy" "B" "A") "xAy")
    (error "Self-test sostituzione CSN fallito."))
  (dolist (case '(("abc" "Z" :missing) ("xBxB" "B" :ambiguous)))
    (destructuring-bind (text target reason) case
      (let ((caught nil))
        (handler-case (unique-position text target)
          (invalid-target (condition) (setf caught (eq reason (target-reason condition)))))
        (unless caught (error "Self-test bersaglio ~S fallito." reason)))))
  (let* ((valid '(:schema-version 1 :kind :series-controller-mutation-probe :status :failed
                 :phase :tests :failed-test "high-carry"))
         (compile-failure '(:schema-version 1 :kind :series-controller-mutation-probe :status :failed
                           :phase :compile-product :failed-test "high-carry"))
         (passed '(:schema-version 1 :kind :series-controller-mutation-probe :status :ok :phase :complete
                   :passed-tests ("high-carry")))
         (text (write-to-string valid :readably t)))
    (unless (and (equal valid (parse-child-report text))
                 (null (parse-child-report (concatenate 'string "0: " text)))
                 (null (parse-child-report (concatenate 'string text " NIL")))
                 (null (parse-child-report "#.(error \"non valutare\")"))
                 (eq :detected (classify-result valid 1 "high-carry"))
                 (eq :invalid (classify-result valid 1 "altro-test"))
                 (eq :invalid (classify-result valid 0 "high-carry"))
                 (eq :invalid (classify-result compile-failure 1 "high-carry"))
                 (eq :invalid (classify-result nil 1 "high-carry"))
                 (eq :survived (classify-result passed 0 "high-carry")))
      (error "Self-test classificazione CSN fallito.")))
  (validate-mutants)
  (list :status :ok :unique-targets 4 :missing-and-ambiguous-rejected t
        :reader-evaluation-disabled t :quoted-markers-rejected t
        :compile-failure :invalid :wrong-test-failure :invalid :kill :named-runtime-probe))

(defparameter *probe-source*
  "(defpackage #:arcdocdb.series-controller.mutation.probes (:use #:cl))
(in-package #:arcdocdb.series-controller.mutation.probes)
(defun run-probes (selected)
  (let ((names '(\"TEST-REQ-AFF-004-SERIES-FREE-AND-STALE-PREALLOCATED-EVENT-AFTER-WRAP\" \"TEST-REQ-WAL-006-SERIES-PUBLICATION-FIFO-UNRESOLVED-AND-RETURNED-H\" \"TEST-REQ-MVC-008-SERIES-BUSY-AFTER-CAS-KEEPS-ROOT-ONCE-AND-CAPTURED-TOKEN\" \"TEST-REQ-WAL-006-SERIES-ASYNC-SEPARATE-PUBLICATION-AND-RETIREMENT-CURSORS\")))
    (unless (or (null selected) (member selected names :test #'string=))
      (error \"Probe sconosciuto.\"))
    (dolist (name names)
      (when (or (null selected) (string= selected name))
        (setf cl-user::*current-test* name)
        (let ((symbol (find-symbol name \"ARCDOCDB.SERIES.TESTS\")))
          (unless (and symbol (fboundp symbol)) (error \"Probe assente: ~A\" name))
          (funcall symbol))
        (push name cl-user::*passed-tests*)))
    (setf cl-user::*current-test* nil)))
")

(defparameter *runner-source*
  "(require :asdf)
(defvar *current-test* nil)
(defvar *passed-tests* nil)
(defun isolated-main ()
  (let ((phase :compile-product) (failure nil) (code 0))
    (handler-case
        (let ((*standard-output* *error-output*))
          (handler-bind ((warning (lambda (condition) (error condition))))
            (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
            (let* ((root (truename \"./\")) (destination (merge-pathnames \"fasl/\" root)))
              (asdf:initialize-output-translations
               `(:output-translations
                 (,(merge-pathnames \"**/*.*\" root) ,(merge-pathnames \"**/*.*\" destination))
                 :ignore-inherited-configuration))
              (unless (uiop:subpathp
                       (asdf:apply-output-translations (merge-pathnames \"src/foundation/record.fasl\" root))
                       destination)
                (error \"Cache della copia non isolata.\")))
            (asdf:load-system \"arcdocdb\" :force t)
            (setf phase :compile-probes)
            (asdf:load-system \"arcdocdb/tests\" :force t)
            (ensure-directories-exist \"fasl/probes.fasl\")
            (load (compile-file \"probes.lisp\" :output-file \"fasl/probes.fasl\"))
            (setf phase :tests)
            (funcall (find-symbol \"RUN-PROBES\" \"ARCDOCDB.SERIES-CONTROLLER.MUTATION.PROBES\")
                     (first (rest sb-ext:*posix-argv*)))
            (setf phase :complete)))
      (error (condition)
        (setf failure condition code (if (eq phase :tests) 1 2))
        (format *error-output* \"~&~A: ~A~%\" (type-of condition) condition)))
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :series-controller-mutation-probe
                   :status (if failure :failed :ok) :phase phase :failed-test *current-test*
                   :passed-tests (reverse *passed-tests*)
                   :diagnostic (when failure (princ-to-string failure))) :pretty t)
      (terpri))
    (sb-ext:exit :code code)))
(isolated-main)
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

(defun temporary-campaign-directory ()
  "Directory OS temporanea nuova, mantenuta per audit; numero di tentativi limitato."
  (loop for attempt below 100
        for path = (merge-pathnames
                    (format nil "arcdocdb-series-controller-mutation-~D-~D-~D/"
                            (get-universal-time) (sb-posix:getpid) attempt)
                    (uiop:temporary-directory))
        do (handler-case (return (exclusive-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition))))
        finally (error "Impossibile creare una directory temporanea CSN esclusiva.")))

(defun copy-fixture (directory mutant)
  "Sorgenti e test del checkout congelato; la sola sostituzione avviene nella copia, mai nel checkout."
  (dolist (file *source-files*)
    (let* ((source (read-text file))
           (text (if (and mutant (string= file (getf mutant :file)))
                     (substitute-unique source (getf mutant :before) (getf mutant :after)) source)))
      (write-text text (merge-pathnames file directory))))
  (write-text *probe-source* (merge-pathnames "probes.lisp" directory))
  (write-text *runner-source* (merge-pathnames "isolated-build.lisp" directory)))

(defun execute-copy (directory selected)
  "Processo nuovo e deadline esplicita; stdout e stderr distinti restano grezzi su disco."
  (let* ((stdout (merge-pathnames "stdout.log" directory))
         (stderr (merge-pathnames "stderr.log" directory))
         (argv (append '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                         "--disable-debugger" "--script" "isolated-build.lisp")
                       (when selected (list selected))))
         (process (uiop:launch-program argv :directory directory :output stdout :error-output stderr))
         (deadline (+ (get-internal-real-time) (* +child-seconds+ internal-time-units-per-second)))
         (timed-out nil) (exit nil))
    (unwind-protect
         (progn
           (loop repeat 3000
                 while (uiop:process-alive-p process)
                 do (when (>= (get-internal-real-time) deadline)
                      (setf timed-out t) (return))
                    (sleep 0.01)
                 finally (when (uiop:process-alive-p process) (setf timed-out t)))
           (when timed-out (uiop:terminate-process process :urgent t))
           (setf exit (uiop:wait-process process)))
      (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t)))
    (list :exit-code exit :timed-out timed-out :argv argv
          :stdout-log (namestring stdout) :stderr-log (namestring stderr)
          :report (parse-child-report (read-text stdout)))))

(defun run-copy (directory mutant)
  "Non confonde un guasto infrastrutturale, compilazione o timeout con un kill valido."
  (let ((result (list :name (if mutant (getf mutant :name) "baseline")
                      :expected-test (when mutant (getf mutant :test))
                      :status :running :result :pending :directory (namestring directory))))
    (handler-case
        (progn
          (copy-fixture directory mutant)
          (let* ((execution (execute-copy directory (when mutant (getf mutant :test))))
                 (child (getf execution :report)) (exit (getf execution :exit-code)))
            (setf (getf result :execution) execution)
            (if mutant
                (multiple-value-bind (classification reason)
                    (if (getf execution :timed-out) (values :invalid :timeout)
                        (classify-result child exit (getf mutant :test)))
                  (setf (getf result :result) classification (getf result :diagnostic) reason
                        (getf result :status) (if (eq classification :detected) :ok :failed)))
                (let ((passed (and child (zerop exit) (not (getf execution :timed-out))
                                   (eq (getf child :status) :ok) (eq (getf child :phase) :complete)
                                   (equal (getf child :passed-tests) *test-names*))))
                  (setf (getf result :status) (if passed :ok :failed)
                        (getf result :result) (if passed :baseline-passed :invalid)
                        (getf result :diagnostic) (unless passed :baseline-failed))))))
      (error (condition)
        (let ((log (merge-pathnames "setup-error.log" directory)))
          (write-text (format nil "~A: ~A~%" (type-of condition) condition) log)
          (setf (getf result :status) :failed (getf result :result) :invalid
                (getf result :diagnostic) :infrastructure-error
                (getf result :detail) (princ-to-string condition) (getf result :setup-error-log) (namestring log)))))
    result))

(defun save-report (report directory)
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory) :direction :output
                            :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun main ()
  "Baseline dei quattro test nominati prima dei mutanti; nessuna cache ASDF condivisa."
  (let ((directory nil) (before nil)
        (report (list :schema-version 1 :kind :series-controller-mutations :status :running
                      :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                      :copied-product-file-count (length *source-files*) :child-deadline-seconds +child-seconds+
                      :targets *mutants*
                      :self-test nil :baseline nil :mutants nil
                      :limits '(:four-targeted-mutants :four-selected-integration-tests
                                :fresh-process-per-copy :isolated-asdf-output-no-global-cache
                                :compilation-failure-is-invalid :kill-requires-expected-test-name
                                :temporary-copies-retained-for-audit :no-persistence-qualification))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (setf before (fingerprints) (getf report :source-fingerprints-before) before)
          (unless (or (equal args '("--self-test")) (equal args '("--check"))
                      (and (= (length args) 2) (string= (first args) "--check")))
            (error "Usare --self-test oppure --check [directory-nuova/]."))
          (setf (getf report :self-test) (self-test))
          (when (string= (first args) "--check")
            (setf directory (if (second args) (exclusive-directory (second args))
                                (temporary-campaign-directory))
                  (getf report :directory) (namestring directory))
            (save-report report directory)
            (setf (getf report :baseline)
                  (run-copy (exclusive-directory (merge-pathnames "baseline/" directory)) nil))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "Baseline CSN non valida: nessun mutante eseguito."))
            (dolist (mutant *mutants*)
              (let ((result (run-copy
                             (exclusive-directory (merge-pathnames
                                                   (format nil "~A/" (getf mutant :name)) directory))
                             mutant)))
                (setf (getf report :mutants) (append (getf report :mutants) (list result)))
                (save-report report directory)))
            (unless (every (lambda (result) (eq (getf result :result) :detected)) (getf report :mutants))
              (error "Un mutante CSN è sopravvissuto oppure la prova è invalida.")))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (handler-case
        (let ((after (fingerprints)))
          (setf (getf report :source-fingerprints-after) after
                (getf report :source-consistency) (if (equal before after) :stable :changed))
          (when (and (eq (getf report :status) :ok) (not (equal before after)))
            (setf (getf report :status) :source-changed)))
      (error (condition)
        (setf (getf report :status) :failed (getf report :fingerprint-error) (princ-to-string condition))))
    (handler-case (save-report report directory)
      (error (condition)
        (setf (getf report :status) :failed (getf report :report-save-error) (princ-to-string condition))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
