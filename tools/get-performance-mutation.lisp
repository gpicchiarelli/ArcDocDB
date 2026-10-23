;;;; GET performance: baseline della sola suite e sette mutanti preregistrati isolati.
;;;; Uso DOPO il freeze del padre: --self-test oppure --check [directory-nuova/].
;;;; --self-test controlla soltanto dati/classificatore: nessun child o compile-file.
;;;; C4: get-performance-mutations*/raw/isolatedtests conserva patch, source e log;
;;;; il collector esclude src/tests/fasl e recupera anche :mutants :directory + :file.
;;; REQ: REQ-AFF-002 REQ-AFF-008 REQ-CCH-004 REQ-CMP-007 REQ-FOR-002 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.get.performance.mutation (:use #:cl))
(in-package #:arcdocdb.get.performance.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *suite-files*
  '("tests/foundation/support.lisp" "tests/get-performance/support.lisp"
    "tests/get-performance/paths.lisp" "tests/get-performance/guards.lisp"
    "tests/get-performance/threads.lisp"))
(defparameter *source-files* nil)
(defconstant +child-seconds+ 60)
(defparameter *put-check*
  "(verifica-put-parole bytes 0 size (contesto-get-key context)
                             (ldb (byte 32 32) (aref content 0)) (ldb (byte 32 0) (aref content 0))
                             flags :version (segmento-get-version segment)
                             :proof-buffer (if prepared (contesto-get-proof context) nil)
                             :proof-start 0 :proof-end (if prepared +get-proof-bytes+ 0))")
(defparameter *cache-check*
  "(cerca-record-cache
     cache (segmento-get-high segment) (segmento-get-low segment)
     (ldb (byte 32 0) (aref content 1)) (ldb (byte 32 0) (aref content 3))
     (contesto-get-key context) (ldb (byte 32 32) (aref content 0))
     (ldb (byte 32 0) (aref content 0)) flags (contesto-get-bytes context) 0
     :version (segmento-get-version segment)
     :proof-buffer (if prepared (contesto-get-proof context) nil)
     :proof-start 0 :proof-end (if prepared +get-proof-bytes+ 0))")

(defparameter *mutants*
  (list
   (list :name "prefix-one-byte-overrun" :file "src/get/target.lisp"
         :test "TEST-REQ-AFF-002-PERFORMANCE-PREFIX-BOUNDARY"
         :before "(<= +segment-header-bytes+ offset (+ offset size) valid-bytes +segment-max-bytes+)"
         :after "(<= +segment-header-bytes+ offset (+ offset size) (1+ valid-bytes) +segment-max-bytes+)"
         :expected-failure :committed-prefix-overrun-accepted)
   (list :name "truncate-csn-high-bit" :file "src/get/segment.lisp"
         :test "TEST-REQ-AFF-002-PERFORMANCE-MAX-U64-VERIFICATION"
         :before "(verifica-put-parole bytes 0 size (contesto-get-key context)
                             (ldb (byte 32 32) (aref content 0))"
         :after "(verifica-put-parole bytes 0 size (contesto-get-key context)
                             (ldb (byte 31 32) (aref content 0))"
         :expected-failure :valid-max-u64-csn-rejected)
   (list :name "cache-verify-failed-is-hit" :file "src/get/target.lisp"
         :test "TEST-REQ-CCH-004-PERFORMANCE-CACHE-CRC-FALLBACK"
         :before *cache-check*
         :after (concatenate
                 'string "(multiple-value-bind (status start end)
        " *cache-check* "
      (if (eq status :verify-failed)
          (values :hit (+ +header-bytes+ (length (contesto-get-key context)))
                  (ldb (byte 32 0) (aref content 3)))
          (values status start end)))")
         :expected-failure :corrupt-cache-authorized-without-segment-fallback)
   (list :name "repair-persistent-body-crc" :file "src/get/segment.lisp"
         :test "TEST-REQ-AFF-002-PERFORMANCE-PERSISTENT-CRC-GUARD"
         :before *put-check*
         :after (concatenate
                 'string "(progn
          (when (= (leggi-u32 bytes 0)
                   (arcdocdb.binary:crc32c bytes 4 +header-bytes+))
            (arcdocdb.binary:scrivi-u32 bytes 4
                                      (arcdocdb.binary:crc32c bytes +header-bytes+ size))
            (arcdocdb.binary:scrivi-u32 bytes 0
                                      (arcdocdb.binary:crc32c bytes 4 +header-bytes+)))
          " *put-check* ")")
         :expected-failure :persistent-body-corruption-authorized
         :limit :header-crc-still-checked)
   (list :name "omit-abandon-read-pin" :file "src/get/lifecycle.lisp"
         :test "TEST-REQ-CMP-007-PERFORMANCE-CLEANUP"
         :before "(abbandona-lettura (contesto-get-reader context))"
         :after "(identity (contesto-get-reader context))"
         :expected-failure :active-ebr-pin-after-abandon)
   (list :name "copy-from-previous-byte" :file "src/get/lifecycle.lisp"
         :test "TEST-REQ-AFF-002-PERFORMANCE-OUTPUT-COPY"
         :before "(replace destination bytes :start1 start :end1 end :start2 vs :end2 ve)"
         :after "(replace destination bytes :start1 start :end1 end :start2 (1- vs) :end2 (1- ve))"
         :expected-failure :output-value-byte-mismatch)))

(setf *mutants*
      (append *mutants*
              (list (list :name "hide-repaired-cache-copy" :file "src/cache/read.lisp"
                          :test "TEST-REQ-CCH-004-PERFORMANCE-CACHE-REPAIR-HIT"
                          :before "(zerop (aref (classe-cache-rejected class) slot))
                     (tag-cache-p class slot segment-high segment-low offset size)"
                          :after "(identity t)
                     (tag-cache-p class slot segment-high segment-low offset size)"
                          :expected-failure :repaired-copy-hidden-by-rejected-tag))))

(define-condition invalid-target (error)
  ((reason :initarg :reason :reader target-reason))
  (:report (lambda (condition stream)
             (format stream "Bersaglio GET performance invalido: ~S." (target-reason condition)))))

(defun read-text (path) (uiop:read-file-string path :external-format :utf-8))
(defun file-md5 (path)
  (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))
(defun source-files ()
  "Copia il prodotto necessario ad ASDF e solo supporto foundation/suite performance."
  (append '("arcdocdb.asd")
          (sort (mapcar #'enough-namestring (directory "src/**/*.lisp")) #'string<)
          *suite-files*))
(defun fingerprints ()
  (loop for file in (append (source-files) '("tools/get-performance-mutation.lisp"))
        collect (list :file file :md5 (file-md5 file))))
(defun unique-position (text target)
  (when (zerop (length target)) (error 'invalid-target :reason :empty))
  (let ((position (search target text)))
    (unless position (error 'invalid-target :reason :missing))
    (when (search target text :start2 (1+ position))
      (error 'invalid-target :reason :ambiguous))
    position))
(defun substitute-unique (text before after)
  (let ((position (unique-position text before)))
    (concatenate 'string (subseq text 0 position) after
                 (subseq text (+ position (length before))))))

(defun expected-test-names ()
  "DEFTEST letterali della sola suite congelata, nello stesso ordine di caricamento."
  (loop for file in (rest *suite-files*)
        append (loop for line in (uiop:split-string (read-text file) :separator '(#\Newline))
                     when (and (>= (length line) 9) (string= "(deftest " line :end2 9))
                       collect (string-upcase
                                (first (uiop:split-string (subseq line 9)
                                                        :separator '(#\Space #\Tab #\( #\))))))))
(defun validate-targets (expected)
  (unless (= 7 (length *mutants*)) (error "Richiesti sette mutanti GET performance."))
  (unless (and expected (= (length expected) (length (remove-duplicates expected :test #'string=))))
    (error "Suite performance assente o nomi DEFTEST duplicati."))
  (let ((names (mapcar (lambda (mutant) (getf mutant :name)) *mutants*)))
    (unless (= (length names) (length (remove-duplicates names :test #'string=)))
      (error "Nomi mutanti duplicati.")))
  (dolist (mutant *mutants*)
    (unless (and (member (getf mutant :file) *source-files* :test #'string=)
                 (or (uiop:string-prefix-p "src/get/" (getf mutant :file))
                     (string= "src/cache/read.lisp" (getf mutant :file)))
                 (member (getf mutant :test) expected :test #'string=))
      (error "Mutante fuori scope o test performance nominato assente: ~S." mutant))
    (unique-position (read-text (getf mutant :file)) (getf mutant :before)))
  t)

(defun parse-child-report (text)
  "Una sola plist keyword, chiavi uniche; niente read-eval, marker citati o dati successivi."
  (let ((*read-eval* nil) (*package* (find-package :cl-user)))
    (handler-case
        (with-input-from-string (stream text)
          (let ((report (read stream nil :eof)))
            (when (and (consp report) (list-length report) (evenp (length report))
                       (loop for key in report by #'cddr always (keywordp key))
                       (let ((keys (loop for key in report by #'cddr collect key)))
                         (= (length keys) (length (remove-duplicates keys))))
                       (eql 1 (getf report :schema-version))
                       (eq :get-performance-mutation-child (getf report :kind))
                       (eq :eof (read stream nil :eof)))
              report)))
      (error () nil))))
(defun attested-target-p (child file md5)
  (let ((target (getf child :compiled-target)))
    (and (eq t (getf child :product-compiled)) (eq t (getf child :suite-compiled))
         (equal file (getf target :file)) (equal md5 (getf target :source-md5))
         (stringp (getf target :fasl))
         (stringp (getf target :fasl-md5)) (= 32 (length (getf target :fasl-md5))))))
(defun classify-result (child exit expected file md5 &optional signal timed-out baseline)
  "Il kill richiede bersaglio compilato e fallimento semantico del solo test preregistrato."
  (cond
    (signal (values :infrastructure-error :process-signal))
    (timed-out (values :infrastructure-error :timeout))
    ((or (null child) (not (integerp exit)))
     (values :infrastructure-error :unreadable-child-report))
    ((member (getf child :phase) '(:compile-product :compile-suite))
     (values :compilation-error (getf child :phase)))
    ((eq :complete (getf child :phase))
     (cond ((not (zerop exit)) (values :infrastructure-error :after-completion))
           ((not (attested-target-p child file md5)) (values :invalid :missing-compilation-attestation))
           ((and (eq :ok (getf child :status))
                 (equal expected (getf child :passed-tests))
                 (null (getf child :failed-test)))
            (values (if baseline :baseline-passed :survived) nil))
           (t (values :invalid :unexpected-completion))))
    ((member (getf child :failure-kind) '(:fixture-timeout :infrastructure))
     (values :infrastructure-error (getf child :failure-kind)))
    ((not (attested-target-p child file md5))
     (values :invalid :missing-compilation-attestation))
    ((and (not baseline) (= exit 1) (eq :failed (getf child :status))
          (eq :tests (getf child :phase))
          (member (getf child :failure-kind) '(:assertion :product-condition))
          (equal expected (list (getf child :failed-test)))
          (null (getf child :passed-tests)))
     (values :detected nil))
    ((and baseline (= exit 1) (eq :tests (getf child :phase)))
     (values :baseline-failed :semantic-suite-failure))
    (t (values :invalid :failure-outside-expected-test))))

(defun self-test ()
  "Self-test dati soltanto; non carica prodotto, suite o processi e non compila."
  (unless (string= "xAy" (substitute-unique "xBy" "B" "A")) (error "Self-test sostituzione."))
  (dolist (entry '(("abc" "Z" :missing) ("xBxB" "B" :ambiguous) ("abc" "" :empty)))
    (destructuring-bind (text target expected) entry
      (let ((caught nil))
        (handler-case (unique-position text target)
          (invalid-target (condition) (setf caught (eq expected (target-reason condition)))))
        (unless caught (error "Self-test target invalido.")))))
  (let* ((target '(:file "src/get/target.lisp" :source-md5 "fixture-source"
                   :fasl "fasl/src/get/target.fasl" :fasl-md5 "0123456789abcdef0123456789abcdef"))
         (failed (list :schema-version 1 :kind :get-performance-mutation-child :phase :tests
                       :status :failed :failure-kind :assertion :failed-test "fixture"
                       :passed-tests nil :product-compiled t :suite-compiled t :compiled-target target))
         (done (list :schema-version 1 :kind :get-performance-mutation-child :phase :complete
                     :status :ok :failed-test nil :passed-tests '("fixture")
                     :product-compiled t :suite-compiled t :compiled-target target))
         (text (write-to-string failed :readably t)))
    (unless (and (equal failed (parse-child-report text))
                 (null (parse-child-report (concatenate 'string "0: " text)))
                 (null (parse-child-report (concatenate 'string text " NIL")))
                 (null (parse-child-report "#.(error \"never\")"))
                 (null (parse-child-report
                        "(:schema-version 1 :kind :get-performance-mutation-child :phase :tests :phase :complete)")))
      (error "Self-test parsing dati."))
    (flet ((check (report exit expected classification &optional signal timeout baseline)
             (unless (eq classification (classify-result report exit expected "src/get/target.lisp"
                                                          "fixture-source" signal timeout baseline))
               (error "Self-test classificazione: ~S." classification))))
      (check failed 1 '("fixture") :detected)
      (check failed 0 '("fixture") :invalid)
      (check failed 1 '("other") :invalid)
      (check failed 1 '("fixture") :baseline-failed nil nil t)
      (check failed 1 '("fixture") :infrastructure-error 9)
      (check failed 1 '("fixture") :infrastructure-error nil t)
      (check nil 1 '("fixture") :infrastructure-error)
      (check done 7 '("fixture") :infrastructure-error)
      (check done 0 '("fixture") :survived)
      (check done 0 '("fixture") :baseline-passed nil nil t)
      (dolist (entry '((:phase :compile-product :compilation-error)
                       (:phase :compile-suite :compilation-error)
                       (:failure-kind :fixture-timeout :infrastructure-error)
                       (:failure-kind :infrastructure :infrastructure-error)
                       (:product-compiled nil :invalid)
                       (:suite-compiled nil :invalid)
                       (:compiled-target nil :invalid)))
        (let ((copy (copy-list failed)))
          (setf (getf copy (first entry)) (second entry))
          (check copy 1 '("fixture") (third entry))))
      (let ((copy (copy-list failed)))
        (setf (getf copy :compiled-target) (copy-list target)
              (getf (getf copy :compiled-target) :source-md5) "wrong-source")
        (check copy 1 '("fixture") :invalid))))
  (list :status :ok :no-processes t :no-compilation t :read-eval-disabled t
        :unique-substitution t :compilation-error-separate t :infrastructure-error-separate t
        :kill-requires-compiled-target-and-named-semantic-failure t))

(defparameter *runner-source*
  "(require :asdf)
(require :sb-md5)
(in-package #:cl-user)
(defvar *current-test* nil)
(defvar *passed-tests* nil)
(defun child-md5 (path)
  (format nil \"~(~{~2,'0X~}~)\" (coerce (sb-md5:md5sum-file path) 'list)))
(defun compile-local (file)
  (let ((output (merge-pathnames (make-pathname :type \"fasl\" :defaults file) #p\"fasl/\")))
    (ensure-directories-exist output)
    (multiple-value-bind (fasl warnings failed) (compile-file file :output-file output)
      (when (or warnings failed (null fasl)) (error \"Compilazione suite non valida: ~A\" file))
      (load fasl))))
(defun condition-in-package-p (condition package-name name)
  (let* ((package (find-package package-name)) (symbol (and package (find-symbol name package))))
    (and symbol (find-class symbol nil) (typep condition symbol))))
(defun semantic-kind (condition)
  (cond
    ((or (typep condition 'sb-ext:timeout)
         (condition-in-package-p condition \"ARCDOCDB.GET.PERFORMANCE.TESTS\" \"PERFORMANCE-FIXTURE-TIMEOUT\"))
     :fixture-timeout)
    ((or (condition-in-package-p condition \"ARCDOCDB.CONDITIONS\" \"IO-FAULT\")
         (condition-in-package-p condition \"SB-POSIX\" \"SYSCALL-ERROR\")) :infrastructure)
    ((condition-in-package-p condition \"ARCDOCDB.CONDITIONS\" \"ARCDOCDB-ERROR\") :product-condition)
    ((and (typep condition 'simple-error)
          (let ((control (simple-condition-format-control condition)))
            (and (stringp control) (uiop:string-prefix-p \"Asserzione fallita:\" control)))) :assertion)
    (t :infrastructure)))
(defun get-performance-child-main ()
  (let ((phase :setup) (failure nil) (code 0) (failure-kind nil)
        (product-compiled nil) (suite-compiled nil) (target nil))
    (handler-case
        (let* ((*standard-output* *error-output*) (root (truename \"./\"))
               (destination (merge-pathnames \"fasl/\" root))
               (source (merge-pathnames *target-file* root)))
          (asdf:initialize-source-registry `(:source-registry (:directory ,root) :ignore-inherited-configuration))
          (asdf:initialize-output-translations
           `(:output-translations
             (,(merge-pathnames \"**/*.*\" root) ,(merge-pathnames \"**/*.*\" destination))
             :ignore-inherited-configuration))
          (unless (uiop:subpathp (asdf:apply-output-translations (make-pathname :type \"fasl\" :defaults source))
                                destination)
            (error \"Cache ASDF non isolata.\"))
          (unless (string= *target-md5* (child-md5 source)) (error \"Bersaglio child diverso dalla copia attestata.\"))
          (handler-bind ((warning (lambda (condition)
                                   (unless (typep condition 'sb-kernel:redefinition-warning)
                                     (error condition)))))
            (setf phase :compile-product)
            (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" root))
            (asdf:load-system \"arcdocdb\" :force t)
            (setf product-compiled t phase :attest-product)
            (let ((fasl (asdf:apply-output-translations (make-pathname :type \"fasl\" :defaults source))))
              (unless (and (probe-file fasl) (uiop:subpathp fasl destination)
                           (string= *target-md5* (child-md5 source)))
                (error \"FASL privato del bersaglio non attestabile.\"))
              (setf target (list :file *target-file* :source-md5 (child-md5 source)
                                 :fasl (namestring fasl) :fasl-md5 (child-md5 fasl))))
            (setf phase :compile-suite)
            (dolist (file *performance-suite-files*) (compile-local file))
            (setf suite-compiled t phase :validate-suite))
          (let* ((package (or (find-package \"ARCDOCDB.GET.PERFORMANCE.TESTS\")
                              (error \"Package performance assente.\")))
                 (registry (find-symbol \"*GET-PERFORMANCE-TESTS*\" package))
                 (selected (second sb-ext:*posix-argv*)))
            (unless (and registry (boundp registry)
                         (equal *performance-expected*
                                (mapcar #'symbol-name (reverse (symbol-value registry)))))
              (error \"Registro performance diverso dai DEFTEST congelati.\"))
            (dolist (name *performance-expected*)
              (let ((symbol (find-symbol name package)))
                (unless (and symbol (fboundp symbol)) (error \"Test performance assente: ~A\" name))))
            (when (and selected (not (member selected *performance-expected* :test #'string=)))
              (error \"Test selezionato non preregistrato.\"))
            (setf phase :tests)
            (dolist (name *performance-expected*)
              (when (or (null selected) (string= name selected))
                (setf *current-test* name)
                (funcall (find-symbol name package))
                (push name *passed-tests*)))
            (setf *current-test* nil phase :complete)))
      (error (condition)
        (setf failure condition failure-kind (if (eq phase :tests) (semantic-kind condition) :infrastructure)
              code (if (and (eq phase :tests) (member failure-kind '(:assertion :product-condition))) 1 2))
        (format *error-output* \"~&~A: ~A~%\" (type-of condition) condition)))
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :get-performance-mutation-child :phase phase
                   :status (if failure :failed :ok) :product-compiled product-compiled
                   :suite-compiled suite-compiled :compiled-target target
                   :failed-test *current-test* :passed-tests (reverse *passed-tests*)
                   :failure-kind failure-kind :condition-type (when failure (princ-to-string (type-of failure)))
                   :diagnostic (when failure (princ-to-string failure))) :pretty t)
      (terpri) (finish-output))
    (sb-ext:exit :code code)))
(get-performance-child-main)
")

(defun write-text (text path)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :error :if-does-not-exist :create
                           :external-format :utf-8)
    (write-string text out)))
(defun save-report (report directory)
  (when directory
    (with-open-file (out (merge-pathnames "report.lisp" directory) :direction :output
                        :if-exists :supersede :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream out :pretty t) (terpri out)))))
(defun exclusive-directory (path)
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname path) (truename "./")))
         (placeholder (make-pathname :directory (butlast (pathname-directory directory))
                                     :name "placeholder" :type nil :defaults directory)))
    (ensure-directories-exist placeholder)
    (sb-posix:mkdir (namestring directory) #o700)
    directory))
(defun campaign-directory ()
  (loop for attempt below 100
        for path = (format nil "spikes/out/get-performance-mutations-~D-~D-~D/"
                           (get-universal-time) (sb-posix:getpid) attempt)
        do (handler-case (return (exclusive-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist) (error condition))))
        finally (error "Directory esclusiva GET performance non disponibile.")))

(defun mutation-patch (source mutant)
  "Hunk delle sole righe sostituite, con coordinate reali; nessuna dipendenza da diff/git."
  (let* ((before (getf mutant :before)) (after (getf mutant :after))
         (position (unique-position source before))
         (left (1+ (or (position #\Newline source :end position :from-end t) -1)))
         (finish (+ position (length before)))
         (right (or (position #\Newline source :start finish) (length source)))
         (old (subseq source left right))
         (new (concatenate 'string (subseq source left position) after (subseq source finish right)))
         (old-lines (uiop:split-string old :separator '(#\Newline)))
         (new-lines (uiop:split-string new :separator '(#\Newline)))
         (line (1+ (count #\Newline source :end left))) (file (getf mutant :file)))
    (with-output-to-string (out)
      (format out "--- a/~A~%+++ b/~A~%@@ -~D,~D +~D,~D @@~%"
              file file line (length old-lines) line (length new-lines))
      (dolist (text old-lines) (format out "-~A~%" text))
      (dolist (text new-lines) (format out "+~A~%" text)))))
(defun write-runner (directory expected target-file target-md5)
  (with-open-file (out (merge-pathnames "isolated-build.lisp" directory) :direction :output
                      :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t) (*package* (find-package :cl-user)))
      (dolist (entry (list (list "*PERFORMANCE-SUITE-FILES*" *suite-files*)
                          (list "*PERFORMANCE-EXPECTED*" expected)
                          (list "*TARGET-FILE*" target-file) (list "*TARGET-MD5*" target-md5)))
        (write `(defparameter ,(intern (first entry) :cl-user) ',(second entry)) :stream out)
        (terpri out)))
    (write-string *runner-source* out)))
(defun copy-fixture (directory mutant root expected)
  "Mutanti dalla baseline verificata: stessa suite e prodotto, un solo anchor sostituito."
  (dolist (file *source-files*)
    (let ((source (read-text (merge-pathnames file root))))
      (write-text (if (and mutant (string= file (getf mutant :file)))
                      (substitute-unique source (getf mutant :before) (getf mutant :after)) source)
                  (merge-pathnames file directory))))
  (let* ((file (if mutant (getf mutant :file) "src/get/target.lisp"))
         (source (merge-pathnames file directory)) (md5 (file-md5 source)))
    (when mutant
      (let ((original (read-text (merge-pathnames file root))))
        (write-text original (merge-pathnames "original-source.lisp" directory))
        (write-text (read-text source) (merge-pathnames "mutated-source.lisp" directory))
        (write-text (mutation-patch original mutant) (merge-pathnames "mutation.patch" directory))))
    (write-runner directory expected file md5)
    (values file md5)))
(defun execute-copy (directory selected)
  "Child nuovo, no init, FASL privati, deadline ed esiti OS reali preservati."
  (let* ((stdout (merge-pathnames "stdout.log" directory)) (stderr (merge-pathnames "stderr.log" directory))
         (argv (append '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
                         "--script" "isolated-build.lisp") (when selected (list selected))))
         (process (uiop:launch-program argv :directory directory :output stdout :error-output stderr))
         (deadline (+ (get-internal-real-time) (* +child-seconds+ internal-time-units-per-second)))
         (timed-out nil) (exit nil) (signal nil))
    (unwind-protect
         (progn
           (loop repeat 6000 while (uiop:process-alive-p process)
                 do (when (>= (get-internal-real-time) deadline) (setf timed-out t) (return))
                    (sleep 0.01)
                 finally (when (uiop:process-alive-p process) (setf timed-out t)))
           (when timed-out (uiop:terminate-process process :urgent t))
           (multiple-value-setq (exit signal) (uiop:wait-process process)))
      (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t)))
    (list :argv argv :exit-code exit :signal signal :timed-out timed-out
          :stdout-log (namestring stdout) :stderr-log (namestring stderr)
          :report (parse-child-report (read-text stdout)))))
(defun run-copy (directory mutant root expected)
  (let ((result (list :name (if mutant (getf mutant :name) "baseline")
                      :file (when mutant (getf mutant :file)) :directory (namestring directory)
                      :substitution (when mutant (list :before (getf mutant :before) :after (getf mutant :after)))
                      :expected-failure (when mutant (getf mutant :expected-failure))
                      :expected-tests (if mutant (list (getf mutant :test)) expected)
                      :status :running :result :pending :diagnostic nil
                      :target-source-md5 nil :compiled-target nil :execution nil)))
    (save-report result directory)
    (handler-case
        (progn
          (write-text "" (merge-pathnames "stdout.log" directory))
          (write-text "" (merge-pathnames "stderr.log" directory))
          (multiple-value-bind (file md5) (copy-fixture directory mutant root expected)
            (setf (getf result :target-source-md5) md5)
            (save-report result directory)
            (let* ((execution (execute-copy directory (when mutant (getf mutant :test))))
                   (child (getf execution :report)))
              (setf (getf result :execution) execution
                    (getf result :compiled-target) (when child (getf child :compiled-target)))
              (multiple-value-bind (classification reason)
                  (classify-result child (getf execution :exit-code) (getf result :expected-tests)
                                   file md5 (getf execution :signal) (getf execution :timed-out) (null mutant))
                (setf (getf result :result) classification (getf result :diagnostic) reason
                      (getf result :status) (if (member classification '(:detected :baseline-passed)) :ok :failed))))))
      (error (condition)
        (with-open-file (out (merge-pathnames "setup-error.log" directory) :direction :output
                            :if-exists :append :if-does-not-exist :create :external-format :utf-8)
          (format out "~A: ~A~%" (type-of condition) condition))
        (setf (getf result :status) :failed (getf result :result) :infrastructure-error
              (getf result :diagnostic) :copy-or-launch-error (getf result :detail) (princ-to-string condition))))
    (save-report result directory)
    result))

(defun main ()
  (let ((directory nil) (before nil)
        (report (list :schema-version 1 :kind :get-performance-mutations :status :running
                      :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                      :child-deadline-seconds +child-seconds+ :targets *mutants*
                      :expected-suite nil :self-test nil :baseline nil :mutants nil
                      :compilation-errors 0 :infrastructure-errors 0 :invalid-results 0 :survived 0
                      :limits '(:seven-preregistered-get-and-cache-mutants :only-get-performance-suite-baseline
                                :fresh-process-per-copy :private-fasl :verified-baseline-source
                                :kill-requires-source-and-fasl-attestation :only-named-semantic-failures
                                :compilation-and-infrastructure-errors-are-not-kills
                                :body-crc-mutant-preserves-header-crc-guard
                                :raw-isolatedtests-retained :collector-excludes-src-tests-fasl
                                :no-heap-performance-or-engine-qualification))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (unless (or (equal args '("--self-test")) (equal args '("--check"))
                      (and (= 2 (length args)) (string= "--check" (first args))))
            (error "Usare --self-test oppure --check [directory-nuova/]."))
          (setf (getf report :self-test) (self-test))
          (when (string= "--check" (first args))
            (setf directory (if (second args) (exclusive-directory (second args)) (campaign-directory))
                  (getf report :directory) (namestring directory))
            (save-report report directory)
            (setf *source-files* (source-files) before (fingerprints)
                  (getf report :source-fingerprints-before) before)
            (let ((expected (expected-test-names)))
              (setf (getf report :expected-suite) expected)
              (validate-targets expected)
              (let* ((baseline-directory (exclusive-directory (merge-pathnames "raw/isolatedtests/baseline/" directory)))
                     (baseline (run-copy baseline-directory nil (truename "./") expected)))
                (setf (getf report :baseline) baseline)
                (save-report report directory)
                (unless (eq :baseline-passed (getf baseline :result)) (error "Baseline GET performance fallita: nessun mutante eseguito."))
                (dolist (mutant *mutants*)
                  (let ((result (run-copy
                                 (exclusive-directory
                                  (merge-pathnames (format nil "raw/isolatedtests/~A/" (getf mutant :name)) directory))
                                 mutant baseline-directory expected)))
                    (setf (getf report :mutants) (append (getf report :mutants) (list result)))
                    (save-report report directory)))))
            (unless (and (= 7 (length (getf report :mutants)))
                         (every (lambda (entry) (eq :detected (getf entry :result))) (getf report :mutants)))
              (error "Mutante sopravvissuto, compilazione/infrastruttura fallita o esito invalido.")))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed
              (getf report :diagnostic) (format nil "tools/get-performance-mutation.lisp COD-61: ~A" condition))))
    (dolist (entry (append (when (getf report :baseline) (list (getf report :baseline)))
                          (getf report :mutants)))
      (case (getf entry :result)
        (:compilation-error (incf (getf report :compilation-errors)))
        (:infrastructure-error (incf (getf report :infrastructure-errors)))
        (:invalid (incf (getf report :invalid-results)))
        (:survived (incf (getf report :survived)))))
    (when before
      (handler-case
          (let ((after (fingerprints)))
            (setf (getf report :source-fingerprints-after) after
                  (getf report :source-consistency) (if (equal before after) :stable :changed))
            (unless (equal before after) (setf (getf report :status) :source-changed)))
        (error (condition)
          (setf (getf report :status) :failed (getf report :fingerprint-error) (princ-to-string condition)))))
    (handler-case (save-report report directory)
      (error (condition)
        (setf (getf report :status) :failed (getf report :report-save-error) (princ-to-string condition))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))
(main)
