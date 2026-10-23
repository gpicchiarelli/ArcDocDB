;;;; Directory GET CLOSED: cinque mutanti preregistrati, copie e FASL privati.
;;;; Uso SOLO dopo il freeze del padre: --self-test oppure --check out-dir/.
;;;; --self-test usa dati sintetici: nessun prodotto, suite, child o compilazione.
;;;; C4: report.lisp schema 1; raw/isolatedtests/{baseline,mutante}/ conserva parziali.
;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-002 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.get.directory.mutation (:use #:cl))
(in-package #:arcdocdb.get.directory.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *suite-files*
  '("tests/foundation/support.lisp" "tests/get-directory/support.lisp"
    "tests/get-directory/construction.lisp" "tests/get-directory/read.lisp"
    "tests/get-directory/threads.lisp"))
(defconstant +child-seconds+ 120)
(defconstant +campaign-seconds+ 900)
(defconstant +cleanup-seconds+ 2)
(defconstant +report-character-limit+ 16777216)
(defparameter *source-files* nil)
(defparameter *campaign-deadline* nil)
(defparameter *mutants*
  (list
   (list :name "omit-directory-owner" :file "src/get-directory/build.lisp"
         :test "TEST-REQ-CMP-007-DIRECTORY-CANONICAL-OWNER-AND-FOREIGN-OWNER"
         :before "(unless (eq view (segmento-get-owner segment))"
         :after "(unless (or (eq view (segmento-get-owner segment)) view)"
         :expected-failure :foreign-directory-accepted)
   (list :name "missing-location-first-map" :file "src/get-directory/read.lisp"
         :test "TEST-REQ-IDX-001-DIRECTORY-MISSING-PUBLISHED-CANDIDATE-FAILSTOP"
         :before "(when (= left right) (guasto-get context :directory-location-absent))"
         :after "(when (= left right)
               (if (plusp (length maps))
                   (return-from cerca-mappa-directory-get
                     (the mappa-segmento-get (svref maps 0)))
                   (guasto-get context :directory-location-absent)))"
         :expected-failure :missing-published-segment-authorized)
   (list :name "alias-input-maps" :file "src/get-directory/build.lisp"
         :test "TEST-REQ-IDX-001-DIRECTORY-INPUT-ARRAY-COPIED"
         :before "(owned (copy-seq maps))" :after "(owned maps)"
         :expected-failure :caller-array-changes-directory)
   (list :name "truncate-directory-id" :file "src/get-directory/read.lisp"
         :test "TEST-REQ-IDX-001-DIRECTORY-NATIVE-READ-V1-V2-VALUES-AND-MAXID"
         :before "(ldb (byte 32 32) location)" :after "(ldb (byte 31 32) location)"
         :expected-failure :max-u32-location-rejected)
   (list :name "bypass-closed-resolver" :file "src/get-directory/read.lisp"
         :test "TEST-REQ-IDX-001-DIRECTORY-CANDIDATE-SIZE-AND-HIGHBITS"
         :before "(risolvi-candidato-get context (trova-mappa-directory-get context directory))"
         :after "(let ((map (trova-mappa-directory-get context directory)))
    (values (mappa-segmento-get-segment map)
            (arcdocdb.get.resolver::mappa-segmento-get-end map) 0 nil))"
         :expected-failure :candidate-size-and-reserved-high-bits-not-checked
         :limit :only-directory-resolve-wrapper)))

(define-condition invalid-campaign (error)
  ((reason :initarg :reason :reader campaign-reason :type keyword)
   (detail :initarg :detail :initform nil :reader campaign-detail))
  (:report (lambda (condition stream)
             (format stream "Directory mutations: ~S~@[ (~A)~]."
                     (campaign-reason condition) (campaign-detail condition)))))
(defun reject (reason &optional detail)
  (error 'invalid-campaign :reason reason :detail detail))
(defun read-text (path) (uiop:read-file-string path :external-format :utf-8))
(defun file-md5 (path)
  (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))
(defun hex-md5-p (value)
  (and (stringp value) (= 32 (length value)) (every (lambda (c) (digit-char-p c 16)) value)))
(defun inventory ()
  (append '("arcdocdb.asd")
          (sort (mapcar #'enough-namestring (directory "src/**/*.lisp")) #'string<)
          *suite-files*))
(defun role-for-file (file)
  (cond ((string= file "arcdocdb.asd") :system)
        ((member file *suite-files* :test #'string=) :suite)
        (t :product)))
(defun manifest-for (files root)
  (loop for file in files collect
    (list :file file :role (role-for-file file) :source-md5 (file-md5 (merge-pathnames file root)))))
(defun fingerprints (root)
  (manifest-for (append (inventory) '("tools/get-directory-mutation.lisp")) root))
(defun unique-position (text target)
  (when (zerop (length target)) (reject :empty-anchor))
  (let ((position (search target text)))
    (unless position (reject :missing-anchor target))
    (when (search target text :start2 (1+ position)) (reject :ambiguous-anchor target))
    position))
(defun substitute-unique (text before after)
  (let ((position (unique-position text before)))
    (concatenate 'string (subseq text 0 position) after
                 (subseq text (+ position (length before))))))
(defun expected-test-names ()
  "DEFTEST letterali dei soli tre file directory, nello stesso ordine del registro."
  (loop for file in (cddr *suite-files*) append
    (loop for line in (uiop:split-string (read-text file) :separator '(#\Newline))
          when (and (>= (length line) 9) (string= "(deftest " line :end2 9)) collect
            (string-upcase (first (uiop:split-string (subseq line 9)
                                                   :separator '(#\Space #\Tab #\( #\))))))))
(defun validate-targets (expected)
  (unless (and (= 5 (length *mutants*)) expected
               (= (length expected) (length (remove-duplicates expected :test #'string=))))
    (reject :invalid-suite-or-mutant-count))
  (unless (every (lambda (name) (and (stringp name) (search "REQ-" name))) expected)
    (reject :test-without-req))
  (let ((names (mapcar (lambda (m) (getf m :name)) *mutants*)))
    (unless (= (length names) (length (remove-duplicates names :test #'string=)))
      (reject :duplicate-mutant)))
  (dolist (mutant *mutants*)
    (unless (and (member (getf mutant :file) '("src/get-directory/build.lisp" "src/get-directory/read.lisp")
                         :test #'string=)
                 (member (getf mutant :file) *source-files* :test #'string=)
                 (member (getf mutant :test) expected :test #'string=)
                 (not (string= (getf mutant :before) (getf mutant :after))))
      (reject :invalid-mutant-scope-or-test (getf mutant :name)))
    (unique-position (read-text (getf mutant :file)) (getf mutant :before)))
  t)

(defun proper-plist-p (value)
  (and (listp value) (list-length value) (evenp (length value))
       (loop for key in value by #'cddr always (keywordp key))
       (let ((keys (loop for key in value by #'cddr collect key)))
         (= (length keys) (length (remove-duplicates keys))))))
(defun forbidden-reader (stream character argument)
  (declare (ignore stream character argument)) (reject :reader-label))
(defun parse-child-report (text)
  "Una sola plist con chiavi uniche; read-eval e reader label disabilitati."
  (when (and (stringp text) (<= (length text) +report-character-limit+))
    (let ((*read-eval* nil) (*package* (find-package :cl-user))
          (*readtable* (copy-readtable nil)))
      (dolist (character '(#\= #\# #\+ #\- #\. #\S #\A #\P #\C #\( #\* #\\))
        (set-dispatch-macro-character #\# character #'forbidden-reader))
      (handler-case
          (with-input-from-string (stream text)
            (let ((report (read stream nil :eof)))
              (when (and (proper-plist-p report) (eql 1 (getf report :schema-version))
                         (eq :get-directory-mutation-child (getf report :kind))
                         (eq :eof (read stream nil :eof))) report)))
        (error () nil)))))
(defun private-fasl-p (path directory)
  (and (stringp path) (stringp directory)
       (uiop:string-prefix-p (concatenate 'string directory "fasl/") path)
       (not (search "/../" path)) (not (search "/./" path))
       (string-equal "fasl" (pathname-type path))))
(defun compiled-manifest-p (entries sources role directory)
  (let ((expected (remove-if-not (lambda (s) (eq role (getf s :role))) sources)))
    (and (listp entries) (list-length entries) (= (length entries) (length expected))
         (equal (mapcar (lambda (e) (getf e :file)) entries)
                (mapcar (lambda (e) (getf e :file)) expected))
         (loop for entry in entries for source in expected always
           (and (proper-plist-p entry) (eq role (getf entry :role))
                (equal (getf source :source-md5) (getf entry :source-md5))
                (hex-md5-p (getf entry :source-md5)) (hex-md5-p (getf entry :fasl-md5))
                (private-fasl-p (getf entry :fasl) directory))))))
(defun attested-child-p (child suite target sources directory selected verified)
  (let* ((entry (getf child :compiled-target))
         (product (getf child :compiled-product))
         (target-entry (find target product :key (lambda (e) (getf e :file)) :test #'equal)))
    (and verified (eq t (getf child :product-compiled)) (eq t (getf child :suite-compiled))
         (equal directory (getf child :root)) (equal sources (getf child :source-manifest))
         (equal *suite-files* (getf child :suite-files))
         (equal suite (getf child :registered-tests)) (equal selected (getf child :selected-test))
         (compiled-manifest-p product sources :product directory)
         (compiled-manifest-p (getf child :compiled-suite) sources :suite directory)
         target-entry (equal entry target-entry))))
(defun %classify-result (child exit expected suite target sources directory
                        &key signal timed-out baseline artifacts-verified)
  "Kill solo per un fallimento semantico del test nominato con prodotto/suite attestati."
  (cond
    (signal (values :infrastructure-error :process-signal))
    (timed-out (values :infrastructure-error :timeout))
    ((or (null child) (not (integerp exit)))
     (values :infrastructure-error :unreadable-child-report))
    ((not (and (proper-plist-p child) (eql 1 (getf child :schema-version))
               (eq :get-directory-mutation-child (getf child :kind))))
     (values :invalid :malformed-child-report))
    ((and (member (getf child :phase) '(:compile-product :compile-suite))
          (eq :failed (getf child :status)) (not (zerop exit)))
     (values :compilation-error (getf child :phase)))
    ((or (member (getf child :failure-kind) '(:fixture-timeout :infrastructure))
         (and (eq :complete (getf child :phase)) (not (zerop exit))))
     (values :infrastructure-error :non-semantic-failure))
    ((not (attested-child-p child suite target sources directory
                           (unless baseline (first expected)) artifacts-verified))
     (values :invalid :missing-or-mismatched-attestation))
    ((and (zerop exit) (eq :complete (getf child :phase)) (eq :ok (getf child :status))
          (equal expected (getf child :passed-tests)) (null (getf child :failed-test))
          (null (getf child :failure-kind)))
     (values (if baseline :baseline-passed :survived) nil))
    ((and (= exit 1) (eq :tests (getf child :phase)) (eq :failed (getf child :status))
          (member (getf child :failure-kind) '(:assertion :product-condition))
          (if baseline
              (let ((prefix (getf child :passed-tests)))
                (and (< (length prefix) (length expected))
                     (equal prefix (subseq expected 0 (length prefix)))
                     (equal (getf child :failed-test) (nth (length prefix) expected))))
              (and (equal expected (list (getf child :failed-test)))
                   (null (getf child :passed-tests)))))
     (values (if baseline :baseline-failed :detected) nil))
    (t (values :invalid :failure-outside-expected-test))))
(defun classify-result (child exit expected suite target sources directory
                        &key signal timed-out baseline artifacts-verified)
  (handler-case
      (%classify-result child exit expected suite target sources directory
                        :signal signal :timed-out timed-out :baseline baseline
                        :artifacts-verified artifacts-verified)
    (error () (values :invalid :malformed-child-fields))))
(defun result-counters (entries)
  (loop for status in '(:detected :survived :baseline-passed :baseline-failed
                       :compilation-error :infrastructure-error :invalid :not-run :pending)
        append (list status (count status entries :key (lambda (e) (getf e :result))))))

(defun self-test ()
  "Parser, coverage fixture/prodotto, classifier e contatori: soli dati sintetici."
  (unless (string= "xAy" (substitute-unique "xBy" "B" "A")) (reject :self-test-substitution))
  (dolist (entry '(("abc" "Z" :missing-anchor) ("xBxB" "B" :ambiguous-anchor)
                   ("abc" "" :empty-anchor)))
    (destructuring-bind (text target reason) entry
      (let ((caught nil))
        (handler-case (unique-position text target)
          (invalid-campaign (condition) (setf caught (eq reason (campaign-reason condition)))))
        (unless caught (reject :self-test-anchor)))))
  (let* ((directory "/fixture/private/") (md5 "0123456789abcdef0123456789abcdef")
         (target "src/get-directory/read.lisp") (suite '("TEST-REQ-IDX-001-FIXTURE"))
         (sources (loop for file in (append (list target) *suite-files*) collect
                    (list :file file :role (role-for-file file) :source-md5 md5)))
         (compiled (loop for source in sources collect
                     (append source (list :fasl (concatenate 'string directory "fasl/"
                                                            (subseq (getf source :file) 0
                                                                    (- (length (getf source :file)) 4)) "fasl")
                                          :fasl-md5 md5))))
         (failed (list :schema-version 1 :kind :get-directory-mutation-child :phase :tests
                       :status :failed :root directory :failure-kind :assertion :failed-test (first suite)
                       :passed-tests nil :product-compiled t :suite-compiled t :compiled-target (first compiled)
                       :compiled-product (list (first compiled)) :compiled-suite (rest compiled)
                       :source-manifest sources :suite-files *suite-files* :registered-tests suite
                       :selected-test (first suite)))
         (done (copy-list failed)) (text (write-to-string failed :readably t)) (checks 0) (observed nil))
    (unless (equal failed (parse-child-report text)) (reject :self-test-positive-parser))
    ;; SBCL PRINT-READABLY T emette #A per stringhe BASE-CHAR dinamiche;
    ;; il parser vieta quel dispatch. Il child usa stringhe quotate canoniche.
    (let ((dynamic (copy-tree failed)))
      (setf (getf dynamic :diagnostic)
            (coerce "runtime-string" 'simple-base-string))
      (unless (equal dynamic (parse-child-report
                             (write-to-string dynamic :readably nil :escape t
                                                      :length nil :level nil)))
        (reject :self-test-dynamic-base-string)))
    (dolist (negative (list (concatenate 'string "0: " text) (concatenate 'string text " NIL")
                            (concatenate 'string "'" text) "#.(error \"never\")" "#1=(:x #1#)"
                            "(:schema-version 1 :kind :get-directory-mutation-child :phase :tests :phase :complete)"
                            "(:schema-version 1 :kind :other)"
                            (concatenate 'string "#+missing-feature NIL " text)
                            (concatenate 'string "#P\"/fixture\" " text)
                            "#1000000000(0)"
                            "(:schema-version 1 :kind :get-directory-mutation-child . :bad)"))
      (when (parse-child-report negative) (reject :self-test-negative-parser)))
    (setf (getf done :phase) :complete (getf done :status) :ok (getf done :passed-tests) suite
          (getf done :failed-test) nil (getf done :failure-kind) nil)
    (flet ((check (report exit result &key signal timed-out baseline (verified t) (expected suite))
             (incf checks)
             (let ((actual (classify-result report exit expected suite target sources directory
                                            :signal signal :timed-out timed-out :baseline baseline
                                            :artifacts-verified verified)))
               (push (list :result actual) observed)
               (unless (eq result actual) (reject :self-test-classification result)))))
      (check failed 1 :detected)
      (let ((copy (copy-list failed)))
        (setf (getf copy :failure-kind) :product-condition) (check copy 1 :detected))
      (check failed 0 :invalid) (check failed 2 :invalid)
      (check failed 1 :invalid :expected '("TEST-REQ-IDX-001-OTHER"))
      (check failed 1 :invalid :verified nil)
      (check failed 1 :infrastructure-error :signal 9)
      (check failed 1 :infrastructure-error :timed-out t)
      (check nil 1 :infrastructure-error)
      (check done 7 :infrastructure-error) (check done 0 :survived)
      (let ((copy (copy-list done)))
        (setf (getf copy :selected-test) nil) (check copy 0 :baseline-passed :baseline t))
      (let ((copy (copy-list failed)))
        (setf (getf copy :selected-test) nil) (check copy 1 :baseline-failed :baseline t))
      (dolist (entry '((:phase :compile-product :compilation-error)
                       (:phase :compile-suite :compilation-error)
                       (:failure-kind :fixture-timeout :infrastructure-error)
                       (:failure-kind :infrastructure :infrastructure-error)
                       (:product-compiled nil :invalid) (:suite-compiled nil :invalid)
                       (:compiled-target nil :invalid) (:compiled-product nil :invalid)
                       (:compiled-suite nil :invalid) (:suite-files nil :invalid)
                       (:registered-tests nil :invalid) (:source-manifest nil :invalid)
                       (:passed-tests ("OTHER") :invalid)))
        (let ((copy (copy-list failed)))
          (setf (getf copy (first entry)) (second entry)) (check copy 1 (third entry))))
      (dolist (field '(:source-md5 :fasl-md5 :fasl))
        (let ((copy (copy-tree failed)))
          (setf (getf (first (getf copy :compiled-product)) field) "wrong")
          (check copy 1 :invalid)))
      (let ((copy (copy-tree failed)))
        (setf (getf (first (getf copy :compiled-suite)) :fasl) "/global/cache/fixture.fasl")
        (check copy 1 :invalid))
      (let ((copy (copy-tree failed)))
        (setf (getf copy :compiled-suite) (rest (getf copy :compiled-suite)))
        (check copy 1 :invalid))
      (let ((copy (copy-list failed)))
        (setf (getf copy :compiled-product) '("malformed")) (check copy 1 :invalid))
      (let ((copy (copy-list failed)))
        (setf (getf copy :kind) :other) (check copy 1 :invalid))
      (let ((copy (copy-list failed)))
        (setf (getf copy :suite-files) (append *suite-files* '("tests/get-performance/paths.lisp")))
        (check copy 1 :invalid))
      (let ((copy (copy-list failed)))
        (setf (getf copy :compiled-suite) (append (getf copy :compiled-suite)
                                                (list (first (getf copy :compiled-suite)))))
        (check copy 1 :invalid))
      (dolist (condition-type '("TYPE-ERROR" "IO-FAULT" "DIRECTORY-FIXTURE-ERROR" "SIMPLE-ERROR"))
        (let ((copy (copy-list failed)))
          (setf (getf copy :failure-kind) :infrastructure (getf copy :condition-type) condition-type)
          (check copy 1 :infrastructure-error))))
    (let ((counters (result-counters observed)))
      (unless (and (= checks (loop for value in (rest counters) by #'cddr sum value))
                   (= 2 (getf counters :detected)) (= 2 (getf counters :compilation-error))
                   (= 1 (getf counters :baseline-passed)) (= 1 (getf counters :baseline-failed))
                   (= 1 (getf counters :survived)) (= 10 (getf counters :infrastructure-error)))
        (reject :self-test-classified-counters)))
    (let* ((statuses '(:detected :survived :baseline-passed :baseline-failed :compilation-error
                      :infrastructure-error :invalid :not-run :pending :detected))
           (counters (result-counters (mapcar (lambda (s) (list :result s)) statuses))))
      (unless (and (= 2 (getf counters :detected))
                   (loop for s in (remove :detected statuses) always (= 1 (getf counters s)))
                   (= (length statuses) (loop for value in (rest counters) by #'cddr sum value)))
        (reject :self-test-counters)))
    (list :schema-version 1 :kind :get-directory-mutation-self-test :status :ok
          :classifier-cases checks :no-processes t :no-compilation t :no-product-or-suite-loaded t
          :parser-positive-and-negative t :fixture-and-product-coverage-guards t :counter-coverage t)))

(defparameter *child-forms*
  '((defvar *current-test* nil)
    (defvar *passed-tests* nil)
    (defun child-md5 (path)
      (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))
    (defun child-source-manifest ()
      (loop for source in *expected-sources* collect
        (list :file (getf source :file) :role (getf source :role)
              :source-md5 (child-md5 (getf source :file)))))
    (defun child-attest (source fasl destination)
      (unless (and (probe-file fasl) (uiop:subpathp (truename fasl) destination)
                   (string= (getf source :source-md5) (child-md5 (getf source :file))))
        (error "Source/FASL non attestabile: ~A" (getf source :file)))
      (append source (list :fasl (namestring (truename fasl)) :fasl-md5 (child-md5 fasl))))
    (defun compile-suite-file (source destination)
      (let* ((file (getf source :file))
             (output (merge-pathnames (make-pathname :type "fasl" :defaults file) destination)))
        (ensure-directories-exist output)
        (multiple-value-bind (fasl warnings failed) (compile-file file :output-file output)
          (when (or warnings failed (null fasl)) (error "Compilazione suite non valida: ~A" file))
          (load fasl) (child-attest source fasl destination))))
    (defun condition-in-package-p (condition package-name name)
      (let* ((package (find-package package-name)) (symbol (and package (find-symbol name package))))
        (and symbol (find-class symbol nil) (typep condition symbol))))
    (defun semantic-kind (condition)
      (cond ((or (typep condition 'sb-ext:timeout)
                 (condition-in-package-p condition "ARCDOCDB.GET.DIRECTORY.TESTS" "DIRECTORY-FIXTURE-TIMEOUT"))
             :fixture-timeout)
            ((or (condition-in-package-p condition "ARCDOCDB.GET.DIRECTORY.TESTS" "DIRECTORY-FIXTURE-ERROR")
                 (condition-in-package-p condition "ARCDOCDB.CONDITIONS" "IO-FAULT")
                 (condition-in-package-p condition "SB-POSIX" "SYSCALL-ERROR")) :infrastructure)
            ((condition-in-package-p condition "ARCDOCDB.CONDITIONS" "ARCDOCDB-ERROR") :product-condition)
            ((and (typep condition 'simple-error)
                  (let ((control (simple-condition-format-control condition)))
                    (and (stringp control) (uiop:string-prefix-p "Asserzione fallita:" control)))) :assertion)
            (t :infrastructure)))
    (defun child-main ()
      (let ((phase :setup) (failure nil) (code 0) (failure-kind nil) (product-compiled nil)
            (suite-compiled nil) (product nil) (suite nil) (target nil) (sources nil) (registered nil))
        (handler-case
            (let* ((*standard-output* *error-output*) (root (truename "./"))
                   (destination (merge-pathnames "fasl/" root)))
              (setf sources (child-source-manifest))
              (unless (equal sources *expected-sources*) (error "Copia sorgenti cambiata prima della compilazione."))
              (asdf:initialize-source-registry `(:source-registry (:directory ,root) :ignore-inherited-configuration))
              (asdf:initialize-output-translations
               `(:output-translations (,(merge-pathnames "**/*.*" root) ,(merge-pathnames "**/*.*" destination))
                 :ignore-inherited-configuration))
              (dolist (source *expected-sources*)
                (when (eq :product (getf source :role))
                  (unless (uiop:subpathp
                           (asdf:apply-output-translations
                            (make-pathname :type "fasl" :defaults (merge-pathnames (getf source :file) root)))
                           destination)
                    (error "Output ASDF non privato prima della compilazione: ~A" (getf source :file)))))
              (handler-bind ((warning (lambda (condition)
                                       (unless (typep condition 'sb-kernel:redefinition-warning) (error condition)))))
                (setf phase :compile-product)
                (asdf:load-asd (merge-pathnames "arcdocdb.asd" root))
                (asdf:load-system "arcdocdb" :force t)
                (setf product-compiled t phase :attest-product)
                (dolist (source *expected-sources*)
                  (when (eq :product (getf source :role))
                    (let ((fasl (asdf:apply-output-translations
                                 (make-pathname :type "fasl" :defaults (merge-pathnames (getf source :file) root)))))
                      (push (child-attest source fasl destination) product))))
                (setf product (nreverse product)
                      target (find *target-file* product :key (lambda (e) (getf e :file)) :test #'equal))
                (unless target (error "Bersaglio non compilato dal sistema prodotto."))
                (setf phase :compile-suite)
                (dolist (file *suite-files*)
                  (let ((source (find file *expected-sources* :key (lambda (s) (getf s :file)) :test #'equal)))
                    (push (compile-suite-file source destination) suite)))
                (setf suite (nreverse suite) suite-compiled t phase :validate-suite))
              (unless (equal sources (child-source-manifest)) (error "Source cambiati durante la compilazione."))
              (let* ((package (or (find-package "ARCDOCDB.GET.DIRECTORY.TESTS") (error "Package directory assente.")))
                     (registry (find-symbol "*GET-DIRECTORY-TESTS*" package)))
                (unless (and registry (boundp registry)) (error "Registro directory assente."))
                (setf registered (mapcar #'symbol-name (reverse (symbol-value registry))))
                (unless (equal *expected-suite* registered) (error "Registro diverso dai DEFTEST congelati."))
                (dolist (name registered)
                  (unless (fboundp (find-symbol name package)) (error "Test directory assente: ~A" name)))
                (when (and *selected-test* (not (member *selected-test* registered :test #'string=)))
                  (error "Test selezionato non preregistrato."))
                (setf phase :tests)
                (dolist (name registered)
                  (when (or (null *selected-test*) (string= *selected-test* name))
                    (setf *current-test* name) (funcall (find-symbol name package)) (push name *passed-tests*)))
                (setf *current-test* nil phase :complete)))
          (error (condition)
            (setf failure condition failure-kind (if (eq phase :tests) (semantic-kind condition) :infrastructure)
                  code (if (and (eq phase :tests) (member failure-kind '(:assertion :product-condition))) 1 2))
            (format *error-output* "~&~A: ~A~%" (type-of condition) condition)))
        (let ((*print-readably* nil) (*print-escape* t) (*print-length* nil) (*print-level* nil))
          (write (list :schema-version 1 :kind :get-directory-mutation-child :phase phase
                       :status (if failure :failed :ok) :root (namestring (truename "./"))
                       :source-manifest sources :suite-files *suite-files* :registered-tests registered
                       :selected-test *selected-test* :product-compiled product-compiled :suite-compiled suite-compiled
                       :compiled-target target :compiled-product product :compiled-suite suite
                       :failed-test *current-test* :passed-tests (reverse *passed-tests*) :failure-kind failure-kind
                       :condition-type (when failure (princ-to-string (type-of failure)))
                       :diagnostic (when failure (princ-to-string failure))) :pretty t)
          (terpri) (finish-output))
        (sb-ext:exit :code code)))
    (child-main)))

(defun write-text (text path)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :error :if-does-not-exist :create
                           :external-format :utf-8)
    (write-string text out)))
(defun save-report (report directory)
  (when directory
    (let ((pending (merge-pathnames "report.pending.lisp" directory))
          (final (merge-pathnames "report.lisp" directory)))
      (with-open-file (out pending :direction :output :if-exists :supersede :if-does-not-exist :create
                                  :external-format :utf-8)
        (let ((*print-readably* t)) (write report :stream out :pretty t) (terpri out) (finish-output out)))
      (uiop:rename-file-overwriting-target pending final))))
(defun exclusive-directory (path)
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname path) (truename "./")))
         (placeholder (make-pathname :directory (butlast (pathname-directory directory))
                                     :name "placeholder" :type nil :defaults directory)))
    (ensure-directories-exist placeholder)
    (sb-posix:mkdir (namestring directory) #o700)
    (truename directory)))
(defun remaining-seconds ()
  (if *campaign-deadline*
      (max 0 (/ (- *campaign-deadline* (get-internal-real-time)) internal-time-units-per-second))
      +campaign-seconds+))
(defun require-campaign-time ()
  (unless (plusp (remaining-seconds)) (reject :campaign-timeout)))
(defun mutation-patch (source mutant)
  "Hunk con coordinate effettive; nessuna esecuzione diff/git."
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
(defun write-runner (directory expected target sources selected)
  (with-open-file (out (merge-pathnames "isolated-build.lisp" directory) :direction :output
                      :if-exists :error :external-format :utf-8)
    (format out "(require :asdf)~%(require :sb-md5)~%(require :sb-posix)~%")
    (format out "(defpackage #:arcdocdb.get.directory.mutation (:use #:cl))~%")
    (format out "(in-package #:arcdocdb.get.directory.mutation)~%")
    (let ((*print-readably* t))
      (dolist (entry (list (list '*suite-files* *suite-files*) (list '*expected-suite* expected)
                          (list '*target-file* target) (list '*expected-sources* sources)
                          (list '*selected-test* selected)))
        (write `(defparameter ,(first entry) ',(second entry)) :stream out) (terpri out))
      (dolist (form *child-forms*) (write form :stream out :pretty t) (terpri out)))))
(defun copy-fixture (directory mutant root expected frozen)
  "Byte-copy dalla baseline congelata; una sola sostituzione nella sola directory."
  (unless (equal frozen (manifest-for *source-files* root)) (reject :copy-source-drift))
  (dolist (file *source-files*)
    (require-campaign-time)
    (let ((destination (merge-pathnames file directory)) (source (merge-pathnames file root)))
      (ensure-directories-exist destination)
      (if (and mutant (string= file (getf mutant :file)))
          (write-text (substitute-unique (read-text source) (getf mutant :before) (getf mutant :after)) destination)
          (uiop:copy-file source destination))))
  (let* ((file (if mutant (getf mutant :file) "src/get-directory/read.lisp"))
         (sources (manifest-for *source-files* directory))
         (changed (loop for before in frozen for after in sources
                        unless (equal before after) collect (getf after :file))))
    (unless (equal changed (when mutant (list file))) (reject :unexpected-source-delta changed))
    (unless (equal frozen (manifest-for *source-files* root)) (reject :copy-source-drift))
    (when mutant
      (let ((original (read-text (merge-pathnames file root))))
        (write-text original (merge-pathnames "original-source.lisp" directory))
        (write-text (read-text (merge-pathnames file directory)) (merge-pathnames "mutated-source.lisp" directory))
        (write-text (mutation-patch original mutant) (merge-pathnames "mutation.patch" directory))))
    (write-runner directory expected file sources (when mutant (getf mutant :test)))
    (values file sources)))
(defun await-process-death (process seconds attempts)
  (let ((deadline (+ (get-internal-real-time) (* seconds internal-time-units-per-second))))
    (loop repeat attempts while (uiop:process-alive-p process)
          do (when (>= (get-internal-real-time) deadline) (return)) (sleep 0.01))
    (not (uiop:process-alive-p process))))
(defun execute-copy (directory execution checkpoint)
  "Processo nuovo senza init, deadline reale, cleanup bounded; mai WAIT su un child vivo."
  (let* ((stdout (merge-pathnames "stdout.log" directory)) (stderr (merge-pathnames "stderr.log" directory))
         (argv '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
                 "--script" "isolated-build.lisp"))
         (process nil) (started (get-internal-real-time))
         (seconds (min +child-seconds+ (max 0 (- (remaining-seconds) +cleanup-seconds+)))))
    (require-campaign-time)
    (unless (plusp seconds) (reject :campaign-timeout))
    (setf (getf execution :argv) argv (getf execution :status) :launching
          (getf execution :stdout-log) (namestring stdout) (getf execution :stderr-log) (namestring stderr)
          (getf execution :deadline-seconds) seconds)
    (funcall checkpoint)
    (unwind-protect
         (progn
           (setf process (uiop:launch-program argv :directory directory :output stdout :error-output stderr)
                 (getf execution :status) :running)
           (funcall checkpoint)
           (unless (await-process-death
                    process (max 0 (- seconds (/ (- (get-internal-real-time) started)
                                                internal-time-units-per-second))) 12000)
             (setf (getf execution :timed-out) t)))
      (when process
        (handler-case
            (progn
              (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t))
              (if (await-process-death process +cleanup-seconds+ 200)
                  (multiple-value-bind (exit signal) (uiop:wait-process process)
                    (setf (getf execution :exit-code) exit (getf execution :signal) signal
                          (getf execution :cleanup) :reaped))
                  (setf (getf execution :cleanup) :unreaped (getf execution :timed-out) t)))
          (error (condition)
            (setf (getf execution :cleanup) :failed (getf execution :cleanup-error) (princ-to-string condition))))
        (setf (getf execution :elapsed-seconds)
              (/ (- (get-internal-real-time) started) internal-time-units-per-second))
        (funcall checkpoint)))
    (setf (getf execution :status) :complete
          (getf execution :report) (parse-child-report (read-text stdout)))
    execution))
(defun verify-child-artifacts (child sources directory runner-md5)
  "Verifica i byte su disco dopo il child; i suoi soli booleani non attestano nulla."
  (handler-case
      (and child (equal sources (manifest-for *source-files* directory))
           (string= runner-md5 (file-md5 (merge-pathnames "isolated-build.lisp" directory)))
           (loop for entry in (append (getf child :compiled-product) (getf child :compiled-suite))
                 always (and (proper-plist-p entry) (private-fasl-p (getf entry :fasl) (namestring directory))
                             (uiop:subpathp (truename (getf entry :fasl)) (merge-pathnames "fasl/" directory))
                             (string= (getf entry :fasl-md5) (file-md5 (getf entry :fasl))))))
    (error () nil)))
(defun planned-result (directory mutant)
  (list :schema-version 1 :kind :get-directory-mutation-copy :name (if mutant (getf mutant :name) "baseline")
        :file (if mutant (getf mutant :file) "src/get-directory/read.lisp") :directory (namestring directory)
        :expected-failure (when mutant (getf mutant :expected-failure))
        :substitution (when mutant (list :before (getf mutant :before) :after (getf mutant :after)))
        :status :not-run :result :not-run :diagnostic nil :expected-tests nil :source-manifest nil
        :compiled-target nil :execution nil :detail nil :runner-md5 nil :target-source-md5 nil
        :artifacts-verified nil))
(defun run-copy (result mutant root expected frozen)
  (let* ((directory (pathname (getf result :directory)))
         (owned nil)
         (execution (list :schema-version 1 :kind :get-directory-mutation-execution :status :not-launched
                          :argv nil :stdout-log nil :stderr-log nil :deadline-seconds nil :elapsed-seconds nil
                          :exit-code nil :signal nil :timed-out nil :cleanup :pending :cleanup-error nil :report nil)))
    (setf (getf result :status) :running (getf result :result) :pending
          (getf result :expected-tests) (if mutant (list (getf mutant :test)) expected)
          (getf result :execution) execution)
    (handler-case
        (progn
          (exclusive-directory directory) (setf owned t) (save-report result directory)
          (write-text "" (merge-pathnames "stdout.log" directory))
          (write-text "" (merge-pathnames "stderr.log" directory))
          (multiple-value-bind (file sources) (copy-fixture directory mutant root expected frozen)
            (let ((runner-md5 (file-md5 (merge-pathnames "isolated-build.lisp" directory))))
              (setf (getf result :source-manifest) sources (getf result :runner-md5) runner-md5
                    (getf result :target-source-md5) (getf (find file sources :key (lambda (s) (getf s :file))
                                                              :test #'string=) :source-md5))
              (save-report result directory)
              (execute-copy directory execution (lambda () (save-report result directory)))
              (let* ((child (getf execution :report))
                     (verified (verify-child-artifacts child sources directory runner-md5)))
                (setf (getf result :compiled-target) (when child (getf child :compiled-target))
                      (getf result :artifacts-verified) (not (null verified)))
                (multiple-value-bind (classification diagnostic)
                    (classify-result child (getf execution :exit-code) (getf result :expected-tests)
                                     expected file sources (namestring directory)
                                     :signal (getf execution :signal) :timed-out (getf execution :timed-out)
                                     :baseline (null mutant) :artifacts-verified verified)
                  (setf (getf result :result) classification (getf result :diagnostic) diagnostic
                        (getf result :status) (if (member classification '(:detected :baseline-passed)) :ok :failed)))))))
      (error (condition)
        (setf (getf result :status) :failed (getf result :result) :infrastructure-error
              (getf result :diagnostic) (if (typep condition 'sb-ext:timeout) :campaign-timeout :copy-or-launch-error)
              (getf result :detail) (princ-to-string condition))))
    (when owned (save-report result directory))
    result))

(defun main ()
  (let* ((started (get-internal-real-time))
         (*campaign-deadline* (+ started (* +campaign-seconds+ internal-time-units-per-second)))
         (root (truename "./")) (directory nil) (before nil)
         (report (list :schema-version 1 :kind :get-directory-mutations :status :running
                       :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                       :argv (copy-list sb-ext:*posix-argv*) :child-deadline-seconds +child-seconds+
                       :campaign-deadline-seconds +campaign-seconds+ :cleanup-deadline-seconds +cleanup-seconds+
                       :targets *mutants* :self-test nil :expected-suite nil :baseline nil :mutants nil
                       :counters nil :detected 0 :survived 0 :compilation-errors 0 :infrastructure-errors 0
                       :invalid-results 0 :source-consistency :not-observed
                       :limits '(:only-directory-build-read-mutated :closed-only :only-directory-suite-executed
                                 :foundation-support-definitions-only :all-product-sources-compiled
                                 :fresh-child-private-asdf-output :source-and-fasl-md5-attestation
                                 :one-named-test-per-mutant :assertions-and-product-conditions-separated
                                 :compiler-fixture-io-timeout-crash-and-type-errors-are-not-kills
                                 :partial-copies-and-logs-retained :bounded-cleanup :no-engine-qualification))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (unless (or (equal args '("--self-test"))
                      (and (= 2 (length args)) (string= "--check" (first args))))
            (reject :usage "--self-test oppure --check out-dir/"))
          (when (string= "--check" (first args))
            (setf directory (exclusive-directory (second args))
                  (getf report :directory) (namestring directory))
            (save-report report directory))
          (setf (getf report :self-test) (self-test))
          (when directory
            (progn
              (sb-ext:with-timeout (remaining-seconds)
                (setf *source-files* (inventory)
                      (getf report :baseline) (planned-result (merge-pathnames "raw/isolatedtests/baseline/" directory) nil)
                      (getf report :mutants)
                      (mapcar (lambda (mutant)
                                (planned-result (merge-pathnames (format nil "raw/isolatedtests/~A/" (getf mutant :name))
                                                                directory) mutant)) *mutants*))
                (save-report report directory)
                (setf before (fingerprints root) (getf report :source-fingerprints-before) before)
                (let ((expected (expected-test-names)) (frozen (manifest-for *source-files* root)))
                  (setf (getf report :expected-suite) expected (getf report :frozen-manifest) frozen)
                  (save-report report directory) (validate-targets expected)
                  (let* ((baseline (getf report :baseline))
                         (baseline-directory (pathname (getf baseline :directory))))
                    (run-copy baseline nil root expected frozen) (save-report report directory)
                    (unless (eq :baseline-passed (getf baseline :result))
                      (dolist (entry (getf report :mutants)) (setf (getf entry :diagnostic) :baseline-not-passed))
                      (reject :baseline-not-passed))
                    (loop for mutant in *mutants* for entry in (getf report :mutants) do
                      (require-campaign-time) (run-copy entry mutant baseline-directory expected frozen)
                      (save-report report directory)
                      (when (member (getf (getf entry :execution) :cleanup) '(:failed :unreaped))
                        (reject :child-cleanup-failed)))))
                (unless (every (lambda (entry) (eq :detected (getf entry :result))) (getf report :mutants))
                  (reject :mutant-not-detected)))))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed
              (getf report :diagnostic) (format nil "tools/get-directory-mutation.lisp COD-61: ~A" condition))
        (dolist (entry (append (when (getf report :baseline) (list (getf report :baseline)))
                              (getf report :mutants)))
          (when (and (eq :not-run (getf entry :result)) (null (getf entry :diagnostic)))
            (setf (getf entry :diagnostic) :campaign-aborted)))))
    (let ((counters (result-counters (append (when (getf report :baseline) (list (getf report :baseline)))
                                           (getf report :mutants)))))
      (setf (getf report :counters) counters (getf report :detected) (getf counters :detected)
            (getf report :survived) (getf counters :survived)
            (getf report :compilation-errors) (getf counters :compilation-error)
            (getf report :infrastructure-errors) (getf counters :infrastructure-error)
            (getf report :invalid-results) (getf counters :invalid)))
    (when before
      (handler-case
          (let ((after (fingerprints root)))
            (setf (getf report :source-fingerprints-after) after
                  (getf report :source-consistency) (if (equal before after) :stable :changed))
            (unless (equal before after) (setf (getf report :status) :failed)))
        (error (condition)
          (setf (getf report :status) :failed (getf report :fingerprint-error) (princ-to-string condition)))))
    (setf (getf report :elapsed-seconds) (/ (- (get-internal-real-time) started) internal-time-units-per-second))
    (when (> (getf report :elapsed-seconds) +campaign-seconds+)
      (setf (getf report :status) :failed (getf report :budget-error) :campaign-timeout))
    (handler-case (save-report report directory)
      (error (condition)
        (setf (getf report :status) :failed (getf report :report-save-error) (princ-to-string condition))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri) (finish-output))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))
(main)
