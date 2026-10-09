;;;; ADR-0046: quattro mutanti concreti in cinque piccoli processi isolati.
;;;; Uso dal worktree congelato: --self-test oppure --check [directory-nuova/].
;;;; Il checkout resta intatto; copie, FASL, stdout e stderr restano nella directory esclusiva.
;;; REQ: REQ-MVC-008 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.csn.mutation (:use #:cl))
(in-package #:arcdocdb.csn.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *source-files*
  '("src/foundation/package.lisp" "src/foundation/conditions.lisp" "src/foundation/binary.lisp"
    "src/csn/package.lisp" "src/csn/registry.lisp"))
(defconstant +child-seconds+ 30)
(defparameter *test-names*
  '("inflight-registration" "oldest-pinned-recycle" "high-carry" "stale-slot-identity"))
(defparameter *mutants*
  '((:name "drop-inflight-register" :file "src/csn/registry.lisp" :test "inflight-registration"
     :before "(setf (aref (registro-csn-highs registry) slot) high
                   (aref (registro-csn-lows registry) slot) low"
     :after "(setf (aref (registro-csn-highs registry) slot) 0
                   (aref (registro-csn-lows registry) slot) 0")
    (:name "horizon-latest-unconditionally" :file "src/csn/registry.lisp" :test "oldest-pinned-recycle"
     :before "(when (plusp count)
      (if (zerop low) (setf high (1- high) low #xffffffff) (decf low)))
    (values high low)))"
     :after "(when (plusp count)
      (if (zerop low) (setf high (1- high) low #xffffffff) (decf low)))
    (values (registro-csn-last-high registry) (registro-csn-last-low registry))))")
    (:name "omit-high-carry" :file "src/csn/registry.lisp" :test "high-carry"
     :before "(if (= low #xffffffff) (setf low 0 high (1+ high)) (incf low))"
     :after "(if (= low #xffffffff) (setf low 0) (incf low))")
    (:name "accept-stale-token" :file "src/csn/registry.lisp" :test "stale-slot-identity"
     :before "(unless (and (= (aref (registro-csn-highs registry) slot) high)
               (= (aref (registro-csn-lows registry) slot) low))
    (error 'invalid-argument :reason :csn-token))"
     :after "(progn ; MUTANT: omesso il controllo di identità slot/CSN.
    nil)")))

(define-condition invalid-target (error)
  ((reason :initarg :reason :reader target-reason))
  (:report (lambda (condition stream)
             (format stream "Bersaglio CSN invalido: ~S." (target-reason condition)))))

(defun fingerprints ()
  (loop for file in (append *source-files* '("tools/csn-mutation.lisp"))
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
                       (eq (getf report :kind) :csn-mutation-probe)
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
  (let* ((valid '(:schema-version 1 :kind :csn-mutation-probe :status :failed
                 :phase :tests :failed-test "high-carry"))
         (compile-failure '(:schema-version 1 :kind :csn-mutation-probe :status :failed
                           :phase :compile-product :failed-test "high-carry"))
         (passed '(:schema-version 1 :kind :csn-mutation-probe :status :ok :phase :complete
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
  ";;;; Probe autonomi su copie temporanee: nessun effetto esterno da pubblicare.
(defpackage #:arcdocdb.csn.mutation.probes (:use #:cl))
(in-package #:arcdocdb.csn.mutation.probes)
(declaim (optimize (safety 3) (debug 2)))
(defun expect-pair (high low expected-high expected-low)
  (unless (and (= high expected-high) (= low expected-low))
    (error \"Coppia ~S/~S diversa da ~S/~S.\" high low expected-high expected-low)))
(defun expect-frontiers (registry last-high last-low horizon-high horizon-low)
  (multiple-value-bind (lh ll hh hl) (arcdocdb.csn:leggi-frontiere-csn registry)
    (expect-pair lh ll last-high last-low) (expect-pair hh hl horizon-high horizon-low)))
(defun inflight-registration ()
  (let ((registry (arcdocdb.csn:crea-registro-csn :capacity 2)))
    (multiple-value-bind (s1 h1 l1) (arcdocdb.csn:prendi-csn registry)
      (expect-pair h1 l1 0 1)
      (multiple-value-bind (s2 h2 l2) (arcdocdb.csn:prendi-csn registry)
        (expect-pair h2 l2 0 2)
        (when (= s1 s2) (error \"Slot in volo sovrascritto.\"))
        (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry s1 h1 l1)
          (expect-pair hh hl 0 1))
        (expect-frontiers registry 0 2 0 1)
        (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry s2 h2 l2)
          (expect-pair hh hl 0 2))
        (expect-frontiers registry 0 2 0 2)))))
(defun oldest-pinned-recycle ()
  (let ((registry (arcdocdb.csn:crea-registro-csn :capacity 2)))
    (multiple-value-bind (old high low) (arcdocdb.csn:prendi-csn registry)
      (expect-pair high low 0 1)
      ;; Distanza 9 maggiore della capacità 2 e dell'anello storico di 4.
      (loop for expected from 2 to 9
            do (multiple-value-bind (slot sh sl) (arcdocdb.csn:prendi-csn registry)
                 (when (= slot old) (error \"Slot del più vecchio riusato.\"))
                 (expect-pair sh sl 0 expected)
                 (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry slot sh sl)
                   (expect-pair hh hl 0 0))
                 (expect-frontiers registry 0 expected 0 0)))
      (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry old high low)
        (expect-pair hh hl 0 9))
      (expect-frontiers registry 0 9 0 9))))
(defun high-carry ()
  (let ((registry (arcdocdb.csn:crea-registro-csn :capacity 1
                                               :initial-high #x80000000 :initial-low #xffffffff)))
    (multiple-value-bind (slot high low) (arcdocdb.csn:prendi-csn registry)
      (expect-pair high low #x80000001 0)
      (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry slot high low)
        (expect-pair hh hl #x80000001 0))
      (expect-frontiers registry #x80000001 0 #x80000001 0))))
(defun stale-slot-identity ()
  (let ((registry (arcdocdb.csn:crea-registro-csn :capacity 2)))
    (multiple-value-bind (old oh ol) (arcdocdb.csn:prendi-csn registry)
      (multiple-value-bind (stale sh sl) (arcdocdb.csn:prendi-csn registry)
        (arcdocdb.csn:risolvi-csn registry stale sh sl)
        (multiple-value-bind (slot high low) (arcdocdb.csn:prendi-csn registry)
          (unless (= stale slot) (error \"Il probe non ha riusato lo slot previsto.\"))
          (expect-pair high low 0 3)
          (let ((caught nil))
            (handler-case (arcdocdb.csn:risolvi-csn registry stale sh sl)
              (arcdocdb.conditions:invalid-argument (condition)
                (setf caught (eq (arcdocdb.conditions:error-reason condition) :csn-token))))
            (unless caught (error \"Token stale accettato oppure reason errata.\")))
          (expect-frontiers registry 0 3 0 0)
          (arcdocdb.csn:risolvi-csn registry slot high low)
          (multiple-value-bind (hh hl) (arcdocdb.csn:risolvi-csn registry old oh ol)
            (expect-pair hh hl 0 3))
          (expect-frontiers registry 0 3 0 3))))))
(defun run-probes (selected)
  (let ((tests (list (cons \"inflight-registration\" #'inflight-registration)
                    (cons \"oldest-pinned-recycle\" #'oldest-pinned-recycle)
                    (cons \"high-carry\" #'high-carry)
                    (cons \"stale-slot-identity\" #'stale-slot-identity))))
    (when (and selected (not (assoc selected tests :test #'string=)))
      (error \"Probe richiesto sconosciuto.\"))
    (dolist (test tests)
      (when (or (null selected) (string= selected (car test)))
        (setf cl-user::*current-test* (car test))
        (funcall (cdr test))
        (push (car test) cl-user::*passed-tests*)))
    (setf cl-user::*current-test* nil)))
")

(defparameter *runner-source*
  ";;;; Build limitata della copia: FASL espliciti locali, nessuna cache ASDF globale.
(require :asdf)
(defvar *current-test* nil)
(defvar *passed-tests* nil)
(defun isolated-main ()
  (let ((phase :compile-product) (failure nil) (code 0))
    (handler-case
        (let ((*standard-output* *error-output*))
          (handler-bind ((warning (lambda (condition) (error condition))))
          (dolist (file '(\"src/foundation/package.lisp\" \"src/foundation/conditions.lisp\"
                          \"src/foundation/binary.lisp\" \"src/csn/package.lisp\" \"src/csn/registry.lisp\"))
            (let ((output (merge-pathnames (make-pathname :type \"fasl\" :defaults file) #p\"fasl/\")))
              (ensure-directories-exist output)
              (multiple-value-bind (fasl warnings failed) (compile-file file :output-file output)
                (when (or warnings failed) (error \"Compilazione prodotto non valida: ~A.\" file))
                (load fasl))))
          (setf phase :compile-probes)
          (multiple-value-bind (fasl warnings failed)
              (compile-file \"probes.lisp\" :output-file \"fasl/probes.fasl\")
            (when (or warnings failed) (error \"Compilazione probe non valida.\"))
            (load fasl))
          (setf phase :tests)
          (funcall (symbol-function (find-symbol \"RUN-PROBES\" \"ARCDOCDB.CSN.MUTATION.PROBES\"))
                   (first (rest sb-ext:*posix-argv*)))
          (setf phase :complete)))
      (error (condition)
        (setf failure condition code (if (eq phase :tests) 1 2))
        (format *error-output* \"~&~A: ~A~%\" (type-of condition) condition)))
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :csn-mutation-probe
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
                    (format nil "arcdocdb-csn-mutation-~D-~D-~D/"
                            (get-universal-time) (sb-posix:getpid) attempt)
                    (uiop:temporary-directory))
        do (handler-case (return (exclusive-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition))))
        finally (error "Impossibile creare una directory temporanea CSN esclusiva.")))

(defun copy-fixture (directory mutant)
  "Cinque file di prodotto; la sola sostituzione avviene nella copia, mai nel checkout."
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
  "Baseline prima di qualunque mutante; quattro kill nominati richiesti, nessuna cache condivisa."
  (let ((directory nil) (before nil)
        (report (list :schema-version 1 :kind :csn-mutations :status :running
                      :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                      :copied-product-file-count (length *source-files*) :child-deadline-seconds +child-seconds+
                      :targets *mutants*
                      :self-test nil :baseline nil :mutants nil
                      :limits '(:four-targeted-mutants :standalone-probes-not-integrated-test-suite
                                :fresh-process-per-copy :explicit-local-fasl-no-global-cache
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
