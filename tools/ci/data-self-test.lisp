;;;; C4: definizioni di self-test wire/identità; nessuna esecuzione al LOAD.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defun %ci-data-test-write (path data &key replace)
  "Solo fixture private: DATA è una stringa UTF-8 oppure un vettore di byte."
  (ensure-directories-exist path)
  (let ((octets (if (stringp data) (%ci-utf8 data) data)))
    (%ci-call-file path (lambda (stream stat)
                          (declare (ignore stat))
                          (write-sequence octets stream) (finish-output stream))
                   :output t :replace replace))
  path)

(defun %ci-data-test-commit (message)
  (ci-git (list "-c" "commit.gpgsign=false" "commit" "--quiet" "-m" message))
  (%ci-one-line (ci-git '("rev-parse" "HEAD"))))

(defun %ci-data-test-tree-commit (mode oid path parent)
  "Commit di sola fixture da oggetti: nessun checkout del tree costruito."
  (ci-git (list "update-index" "--add" "--cacheinfo" mode oid path))
  (let ((tree (%ci-one-line (ci-git '("write-tree")))))
    (with-input-from-string (input (format nil "CI private fixture~%"))
      (%ci-one-line
       (%ci-utf8-text
        (%ci-command-octets (%ci-git-argv (list "-c" "commit.gpgsign=false"
                                                "commit-tree" tree "-p" parent)
                                         *ci-root*)
                            :input input))))))

(defun %ci-data-test-coverage-code (directory)
  "Codice child senza keyword producer: l'unica loro fonte deve essere DATA.LISP.
Il packet resta un file wire; il codice del child non legge/evaluta forme dal packet."
  (format nil
          "(let* ((directory (pathname ~S))
                  (path (merge-pathnames \"verify-result.lisp\" directory))
                  (arcdocdb.ci::*ci-coverage-normal-report* path)
                  (normal (arcdocdb.ci::ci-read path))
                  (identity (getf normal :identity)))
             (assert (not (fboundp (find-symbol \"CI-RUN-JOB\" \"ARCDOCDB.CI\"))))
             (assert (null (find-package \"ARCDOCDB.IO\")))
             (assert (= 7 (length arcdocdb.ci.tests::*coverage-exclusions*)))
             (assert (every (lambda (row) (eq :passed (getf row :normal-status)))
                            (arcdocdb.ci::ci-coverage-normal-proof directory identity)))
             (let ((wrong (copy-list identity)))
               (setf (getf wrong :tested-sha) \"wrong\")
               (assert (every (lambda (row) (eq :missing (getf row :normal-status)))
                              (arcdocdb.ci::ci-coverage-normal-proof directory wrong))))
             (arcdocdb.ci::ci-save (merge-pathnames \"roundtrip.lisp\" directory) normal)
             (setf (getf (getf normal :metrics) :skipped) 1)
             (let* ((bad (merge-pathnames \"skipped-result.lisp\" directory))
                    (arcdocdb.ci::*ci-coverage-normal-report* bad))
               (arcdocdb.ci::ci-save bad normal)
               (assert (every (lambda (row) (eq :missing (getf row :normal-status)))
                              (arcdocdb.ci::ci-coverage-normal-proof directory identity)))))"
          (namestring directory)))

(defun %ci-data-test-fresh-coverage-consumer (root)
  "Subprocesso fresco con i soli moduli caricati dal consumer coverage reale.
Producer assente: un parent che ha gia internato le keyword non puo mascherare il guasto.
Una sola esecuzione bounded 30s; stdout/stderr e fixture preservati anche al fallimento."
  (let* ((directory (merge-pathnames "fresh-coverage-consumer/" root))
         (packet (list :schema-version 1 :kind :ci-job-result :job "verify-linux" :status :passed
                       :identity (list :tested-sha (make-string 40 :initial-element #\a)
                                       :source-id (make-string 64 :initial-element #\b)
                                       :policy-id (make-string 64 :initial-element #\c))
                       :context '(:run-id "fixture" :attempt "1" :event "pull_request"
                                  :ref "refs/pull/fixture/merge" :repository "gpicchiarelli/ArcDocDB")
                       :metrics '(:planned 2 :passed 2 :failed 0 :not-run 0 :skipped 0)
                       :ticks 0 :time-unit 1000000 :reason nil :metrics-status :passed
                       :execution '(:name "job" :command ("sbcl" "fixture") :exit-code 0
                                    :status :passed :record "commands/job/report.lisp")))
         (process nil))
    (%ci-check-parents (string-right-trim "/" (namestring directory)))
    (sb-posix:mkdir (string-right-trim "/" (namestring directory)) #o700)
    (%ci-data-test-write (merge-pathnames "verify-result.lisp" directory) (ci-wire-string packet))
    (unwind-protect
         (progn
           (setf process
                 (sb-ext:run-program
                  (namestring sb-ext:*runtime-pathname*)
                  (append '("--noinform" "--no-userinit" "--no-sysinit" "--non-interactive"
                            "--eval" "(require :asdf)" "--eval" "(require :sb-posix)"
                            "--eval" "(defpackage :arcdocdb.ci (:use :cl))")
                          (loop for source in '("tests/ci-catalog.lisp" "tools/ci/data.lisp"
                                                "tools/ci/identity.lisp" "tools/ci/support.lisp"
                                                "tools/ci/tests.lisp" "tools/ci/coverage.lisp")
                                append (list "--load" (namestring (merge-pathnames source *ci-root*))))
                          (list "--eval" (%ci-data-test-coverage-code directory)))
                  :wait nil :search nil :directory *ci-root* :input nil
                  :output (merge-pathnames "child.stdout" directory)
                  :error (merge-pathnames "child.stderr" directory)
                  :if-output-exists :error :if-error-exists :error))
           (sb-ext:with-timeout 30 (sb-ext:process-wait process))
           (unless (and (eq :exited (sb-ext:process-status process))
                        (eql 0 (sb-ext:process-exit-code process)))
             (%ci-fail "Consumer coverage fresco: ~S/~S; diagnostiche in ~A."
                       (sb-ext:process-status process) (sb-ext:process-exit-code process) directory))
           (equal packet (ci-read (merge-pathnames "roundtrip.lisp" directory))))
      (when process
        (when (member (sb-ext:process-status process) '(:running :stopped))
          (sb-ext:process-kill process sb-posix:sigkill))
        (sb-ext:process-wait process) (sb-ext:process-close process)))))

(defun %ci-data-test-fresh-wire (root stem wire success)
  "Il figlio carica solo DATA: nessun keyword/schema viene internato dal test o dal prodotto.
Input/output/stdout/stderr sono privati e conservati; timeout 30s, un solo figlio senza discendenti."
  (let* ((input (merge-pathnames (concatenate 'string stem "-input.lisp") root))
         (output (merge-pathnames (concatenate 'string stem "-output.lisp") root))
         (command
          (list (namestring sb-ext:*runtime-pathname*) "--noinform" "--no-userinit" "--no-sysinit"
                "--non-interactive" "--eval" "(require :asdf)" "--eval" "(require :sb-posix)"
                "--eval" "(defpackage :arcdocdb.ci (:use :cl))"
                "--load" (namestring (merge-pathnames "tools/ci/data.lisp" *ci-root*))
                "--eval" (format nil "(arcdocdb.ci::ci-save ~S (arcdocdb.ci::ci-read ~S))"
                                 (namestring output) (namestring input))))
         (process nil) (exit nil))
    (%ci-data-test-write input wire)
    (unwind-protect
         (progn
           (setf process (sb-ext:run-program
                          (first command) (rest command) :search nil :wait nil
                          :output (merge-pathnames (concatenate 'string stem "-stdout.log") root)
                          :error (merge-pathnames (concatenate 'string stem "-stderr.log") root)
                          :if-output-exists :error :if-error-exists :error))
           (sb-ext:with-timeout 30 (sb-ext:process-wait process))
           (unless (eq :exited (sb-ext:process-status process))
             (error "Figlio wire senza uscita normale."))
           (setf exit (sb-ext:process-exit-code process)))
      (when process
        (when (member (sb-ext:process-status process) '(:running :stopped))
          (sb-ext:process-kill process sb-posix:sigkill))
        (sb-ext:process-wait process) (sb-ext:process-close process)))
    (ci-save (merge-pathnames (concatenate 'string stem "-result.lisp") root)
             (list :kind :ci-check :command command :exit-code exit
                   :status (if (eql 0 exit) :passed :failed)))
    (if success
        (and (eql 0 exit) (ci-regular-file-p output)
             (string= (ci-sha256 input) (ci-sha256 output)))
        (and (integerp exit) (not (zerop exit)) (not (probe-file output))))))

(defun ci-data-self-test (out)
  "Crea OUT esclusivo quando invocata dal recorder; ritorna plist con conteggi.
Non eseguita al caricamento. Git e file modificati soltanto in OUT/fixture/;
le fixture e tutti gli esiti restano disponibili per la revisione C4."
  (let ((cases nil) (passed 0) (failed 0) (skipped 0)
        (root (uiop:ensure-directory-pathname (merge-pathnames out (uiop:getcwd)))))
    ;; L'output deve essere nuovo: nessuna ricorsione su un repository esistente.
    (%ci-check-parents (string-right-trim "/" (namestring root)))
    (sb-posix:mkdir (string-right-trim "/" (namestring root)) #o700)
    (labels ((check (id function)
               (handler-case
                   (progn
                     (unless (funcall function) (%ci-fail "Asserzione self-test falsa."))
                     (incf passed) (push (list :id id :status :passed) cases) t)
                 (error (condition)
                   (incf failed)
                   (push (list :id id :status :failed :diagnostic (princ-to-string condition)) cases)
                   nil)))
             (rejects (function &optional (type 'ci-data-error))
               (handler-case (progn (funcall function) nil)
                 (error (condition) (typep condition type))))
             (skip (id)
               (incf skipped) (push (list :id id :status :not-run
                                          :diagnostic "Fixture Git non inizializzata.") cases)))
      (check "wire-roundtrip"
             (lambda ()
               (let* ((data (list :path "a\\b\"c" :sources (list nil t 0 -1
                                                                  +ci-integer-min+ +ci-integer-max+)
                                  :bytes (format nil "è~%~C" #\Null)))
                      (wire (let ((*print-array* nil) (*print-readably* nil)
                                  (*print-base* 16) (*print-case* :downcase))
                              (ci-wire-string data))))
                 (and (not (search "#A" wire)) (not (search "#a" wire))
                      (equal data (%ci-parse-wire wire))))))
      (check "wire-empty-list-and-booleans"
             (lambda () (and (null (%ci-parse-wire "()"))
                             (equal '(nil t :path) (%ci-parse-wire "(nil t :path)")))))
      (check "wire-publisher-canonical-keywords-without-product-load"
             (lambda ()
               (every (lambda (symbol)
                        (and (keywordp symbol)
                             (eq symbol (find-symbol (symbol-name symbol) "KEYWORD"))
                             (eq symbol (%ci-parse-wire
                                         (concatenate 'string ":" (symbol-name symbol))))))
                      *ci-wire-canonical-keywords*)))
      (check "wire-verify-result-in-fresh-coverage-consumer"
             (lambda () (%ci-data-test-fresh-coverage-consumer root)))
      (check "wire-job-result-fresh-data-only-process"
             (lambda ()
               (%ci-data-test-fresh-wire
                root "job-result-fresh"
                (ci-wire-string
                 '(:schema-version 1 :kind :ci-job-result :job "verify-linux" :status :passed
                   :identity (:tested-sha "fixture" :source-id "fixture" :policy-id "fixture")
                   :metrics (:planned 3 :passed 3 :failed 0 :not-run 0 :skipped 0)
                   :metrics-status :passed :reason nil
                   :execution (:name "job" :command ("sbcl" "child") :exit-code 0
                               :status :passed :record "commands/job/report.lisp"))) t)))
      (check "wire-fresh-unknown-keyword-is-rejected"
             (lambda ()
               (let ((name (format nil "CI-FRESH-UNKNOWN-~D-~D"
                                   (get-universal-time) (sb-posix:getpid))))
                 (and (null (find-symbol name "KEYWORD"))
                      (%ci-data-test-fresh-wire root "unknown-keyword-fresh"
                                                (concatenate 'string ":" name) nil)
                      (null (find-symbol name "KEYWORD"))))))
      (dolist (attack '("#.(error \"evaluated\")" "#1=(NIL . #1#)" "#A((1) NIL)"
                        "#x10" "#\\A" "'NIL" "`NIL" ",NIL" "CL:T" "KEYWORD:PATH"
                        "::PATH" ":|PATH|" "(NIL . T)" "(T" "\"abc" "\"a\\n\""
                        "NIL NIL" "1/2" "1.0" "+1" ";comment" "(NIL #|comment|#)" ""
                        "170141183460469231731687303715884105728"
                        "-170141183460469231731687303715884105729"))
        (let ((text attack))
          (check (concatenate 'string "reject-wire:" text)
                 (lambda () (rejects (lambda () (%ci-parse-wire text)))))))
      (check "wire-does-not-intern"
             (lambda ()
               (let ((name (format nil "CI-UNTRUSTED-~D-~D" (get-universal-time) (sb-posix:getpid))))
                 (and (null (find-symbol name "KEYWORD"))
                      (rejects (lambda () (%ci-parse-wire (concatenate 'string ":" name))))
                      (null (find-symbol name "KEYWORD"))))))
      (check "wire-byte-boundary"
             (lambda () (and (eq t (%ci-parse-wire "T" :max-bytes 1))
                             (rejects (lambda () (%ci-parse-wire "T " :max-bytes 1))))))
      (check "wire-depth-boundary"
             (lambda ()
               (and (let ((*ci-wire-max-depth* 3)) (equal '(((nil))) (%ci-parse-wire "(((NIL)))")))
                    (let ((*ci-wire-max-depth* 2))
                      (rejects (lambda () (%ci-parse-wire "(((NIL)))")))))))
      (check "wire-element-boundary"
             (lambda ()
               (and (let ((*ci-wire-max-elements* 3)) (equal '(nil t) (%ci-parse-wire "(NIL T)")))
                    (let ((*ci-wire-max-elements* 2))
                      (rejects (lambda () (%ci-parse-wire "(NIL T)")))))))
      (check "wire-string-utf8-boundary"
             (lambda ()
               (and (let ((*ci-wire-max-string* 2)) (equal "è" (%ci-parse-wire "\"è\"")))
                    (let ((*ci-wire-max-string* 1))
                      (and (rejects (lambda () (%ci-parse-wire "\"è\"")))
                           (rejects (lambda () (ci-wire-string "è"))))))))
      (check "wire-token-boundary"
             (lambda ()
               (and (let ((*ci-wire-max-token* 5)) (eq :path (%ci-parse-wire ":PATH")))
                    (let ((*ci-wire-max-token* 4))
                      (rejects (lambda () (%ci-parse-wire ":PATH")))))))
      (check "wire-writer-budget"
             (lambda ()
               (and (let ((*ci-wire-max-bytes* 1))
                      (rejects (lambda () (ci-wire-string "x"))))
                    (let ((*ci-wire-max-depth* 0))
                      (rejects (lambda () (ci-wire-string '(t)))))
                    (let ((*ci-wire-max-elements* 1))
                      (rejects (lambda () (ci-wire-string '(t))))))))
      (check "wire-writer-rejects-types-and-cycles"
             (lambda ()
               (let ((cdr-cycle (list t)) (car-cycle (list nil)))
                 (setf (cdr cdr-cycle) cdr-cycle (car car-cycle) car-cycle)
                 (every (lambda (data) (rejects (lambda () (ci-wire-string data))))
                        (list '(t . t) cdr-cycle car-cycle 'cl:car 1/2 #() #\a
                              (1+ +ci-integer-max+) (1- +ci-integer-min+))))))
      (check "plist-allowed-required-and-duplicates"
             (lambda ()
               (and (equal '(:path nil) (ci-plist-check '(:path nil) '(:path :bytes) '(:path)))
                    (rejects (lambda () (ci-plist-check '(:path "x" :path "y") '(:path) '(:path))))
                    (rejects (lambda () (ci-plist-check '(:bytes 0) '(:path :bytes) '(:path))))
                    (rejects (lambda () (ci-plist-check '(:sources nil) '(:path) nil)))
                    (rejects (lambda () (ci-plist-check '(:path) '(:path) nil)))
                    (rejects (lambda () (ci-plist-check '(:path . t) '(:path) nil))))))
      (check "payload-path-escape"
             (lambda ()
               (and (equal "jobs/verify/report.lisp" (ci-relative-path "jobs/verify/report.lisp"))
                    (every (lambda (path) (rejects (lambda () (ci-relative-path path))))
                           '("/tmp/x" "../x" "x/../y" "./x" "x//y" "x/" "x\\y"
                             "a:b" "a*" "")))))
      (let ((path (merge-pathnames "wire.lisp" root)))
        (check "wire-file-read-save-exclusive"
               (lambda ()
                 (ci-save path '(:path "first"))
                 (let ((digest (ci-sha256 path)))
                   (and (equal '(:path "first") (ci-read path))
                        (= (ci-bytes path) (length (%ci-utf8 (ci-wire-string '(:path "first")))))
                        (rejects (lambda () (ci-save path '(:path "second"))) 'error)
                        (string= digest (ci-sha256 path))
                        (progn (ci-save path '(:path "second") :replace t)
                               (equal '(:path "second") (ci-read path)))))))
        (check "wire-file-limit-and-invalid-utf8"
               (lambda ()
                 (and (rejects (lambda () (ci-read path :max-bytes 1)))
                      (progn (%ci-data-test-write path #(192 175) :replace t)
                             (rejects (lambda () (ci-read path)) 'error))
                      (progn (%ci-data-test-write path "NIL T" :replace t)
                             (rejects (lambda () (ci-read path))))))))
      (check "sha256-known-answer"
             (lambda ()
               (and (string= (ci-digest-string "")
                             "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
                    (string= (ci-digest-string "abc")
                             "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"))))
      (check "file-symlink-and-hardlink-rejected"
             (lambda ()
               (let ((ordinary (merge-pathnames "ordinary.bin" root))
                     (symlink (merge-pathnames "symlink.bin" root))
                     (hardlink (merge-pathnames "hardlink.bin" root)))
                 (%ci-data-test-write ordinary "T")
                 (sb-posix:symlink (namestring ordinary) (namestring symlink))
                 (let ((symlink-refused (and (not (ci-regular-file-p symlink))
                                            (rejects (lambda () (ci-read symlink))))))
                   (sb-posix:link (namestring ordinary) (namestring hardlink))
                   (and symlink-refused (not (ci-regular-file-p hardlink))
                        (rejects (lambda () (ci-read hardlink))))))))
      (let* ((fixture (merge-pathnames "fixture/" root))
             (*ci-root* fixture) (first nil) (results nil) (changed nil)
             (base-id nil) (base-policy nil))
        (if (check "git-fixture-init"
                   (lambda ()
                     (sb-posix:mkdir (string-right-trim "/" (namestring fixture)) #o700)
                     (ci-git '("init" "--quiet" "--template=" "--object-format=sha1"))
                     (ci-git '("config" "--local" "user.name" "CI private fixture"))
                     (ci-git '("config" "--local" "user.email" "ci-fixture@example.invalid"))
                     (dolist (entry '(("src/module/a.lisp" "(in-package :cl-user)")
                                      ("docs/note.md" "Documentazione")
                                      ("tests/ci-catalog.lisp" "(:path NIL)")
                                      ("tools/ci/policy.lisp" "(:bytes 0)")
                                      (".github/workflows/fixture.yml" "name: fixture")
                                      ("Makefile" "all:") ("corpus/raw.bin" #(0 255 10 1))))
                       (%ci-data-test-write (merge-pathnames (first entry) fixture) (second entry)))
                     (%ci-data-test-write (merge-pathnames (format nil "docs/è~Cname~%x.md" #\Tab) fixture)
                                          (format nil "è~%ultima"))
                     (ci-git '("add" "--" "."))
                     (setf first (%ci-data-test-commit "fixture base"))
                     (let* ((source (ci-source))
                            (module (find "src/module" (getf source :modules)
                                          :key (lambda (entry) (getf entry :path)) :test #'equal)))
                       (setf base-id (getf source :source-id) base-policy (getf source :policy-id))
                       (and (= 8 (getf source :source-files))
                            (= 3 (getf source :lisp-files))
                            (= 10 (getf source :physical-lines))
                            (= 1 (getf module :source-files))))))
            (progn
              (check "git-clean-byte-snapshots" (lambda () (ci-working-clean-p)))
              (check "git-inventory-budgets"
                     (lambda ()
                       (and (let ((*ci-source-max-files* 7))
                              (rejects (lambda () (ci-source first))))
                            (let ((*ci-source-max-file-bytes* 1))
                              (rejects (lambda () (ci-source first))))
                            (let ((*ci-source-max-total-bytes* 1))
                              (rejects (lambda () (ci-source first)))))))
              (check "git-sha-width-matches-object-format"
                     (lambda ()
                       (and (rejects (lambda () (ci-source (make-string 64 :initial-element #\a))))
                            (string= first (getf (ci-source (string-upcase first)) :tested-sha)))))
              (check "git-results-only-identity"
                     (lambda ()
                       (%ci-data-test-write (merge-pathnames "spikes/results/ci/result.lisp" fixture)
                                            "#.(never-evaluate)")
                       (ci-git '("add" "--" "spikes/results/ci/result.lisp"))
                       (setf results (%ci-data-test-commit "fixture results only"))
                       (let ((source (ci-source)))
                         (and (not (string= first results))
                              (string= results (getf source :tested-sha))
                              (string= base-id (getf source :source-id))
                              (string= base-policy (getf source :policy-id))
                              (not (find "spikes/results/ci/result.lisp" (getf source :sources)
                                         :key (lambda (row) (getf row :path)) :test #'equal))))))
              (check "git-doc-change-outside-prefix"
                     (lambda ()
                       (%ci-data-test-write (merge-pathnames "docs/note.md" fixture)
                                            "Documentazione modificata" :replace t)
                       (ci-git '("add" "--" "docs/note.md"))
                       (setf changed (%ci-data-test-commit "fixture docs changed"))
                       (let ((source (ci-source)))
                         (and (not (string= base-id (getf source :source-id)))
                              (string= base-policy (getf source :policy-id))))))
              (check "git-historical-ref-without-checkout"
                     (lambda ()
                       (let ((old (ci-source first)))
                         (and (string= first (getf old :tested-sha))
                              (string= base-id (getf old :source-id))
                              (string= changed (%ci-one-line (ci-git '("rev-parse" "HEAD"))))))))
              (check "git-policy-blob-change"
                     (lambda ()
                       (%ci-data-test-write (merge-pathnames "tools/ci/policy.lisp" fixture)
                                            "(:bytes 1)" :replace t)
                       (ci-git '("add" "--" "tools/ci/policy.lisp"))
                       (%ci-data-test-commit "fixture policy changed")
                       (not (string= base-policy (getf (ci-source) :policy-id)))))
              (check "git-dirty-working-bytes-even-assume-unchanged"
                     (lambda ()
                       (ci-git '("update-index" "--assume-unchanged" "--" "docs/note.md"))
                       (%ci-data-test-write (merge-pathnames "docs/note.md" fixture)
                                            "byte alterati" :replace t)
                       (unwind-protect (not (ci-working-clean-p))
                         (%ci-data-test-write (merge-pathnames "docs/note.md" fixture)
                                              "Documentazione modificata" :replace t)
                         (ci-git '("update-index" "--no-assume-unchanged" "--" "docs/note.md")))))
              (check "git-untracked-source-fails-ignored-too"
                     (lambda ()
                       (%ci-data-test-write (merge-pathnames ".git/info/exclude" fixture)
                                            (format nil "ignored-source.lisp~%") :replace t)
                       (let ((path (merge-pathnames "ignored-source.lisp" fixture)))
                         (%ci-data-test-write path "NIL")
                         (unwind-protect (not (ci-working-clean-p)) (delete-file path)))))
              (check "git-only-output-prefixes-allowed"
                     (lambda ()
                       (%ci-data-test-write (merge-pathnames "spikes/out/generated.bin" fixture) "output")
                       (%ci-data-test-write (merge-pathnames "spikes/results/ci/new.lisp" fixture) "NIL")
                       (and (ci-working-clean-p)
                            (let ((path (merge-pathnames "spikes/results/outside-ci.lisp" fixture)))
                              (%ci-data-test-write path "NIL")
                              (unwind-protect (not (ci-working-clean-p)) (delete-file path))))))
              (check "git-ref-injection-rejected-before-command"
                     (lambda ()
                       (every (lambda (ref) (rejects (lambda () (ci-source ref))))
                              '("--help" "HEAD~1" "main" "HEAD;touch x" "HEAD:src" ""))))
              (check "git-symlink-object-rejected"
                     (lambda ()
                       (let* ((source (ci-source first))
                              (blob (getf (first (getf source :sources)) :blob))
                              (ref (%ci-data-test-tree-commit "120000" blob "fixture-link" first)))
                         (rejects (lambda () (ci-source ref))))))
              (check "git-submodule-object-rejected"
                     (lambda ()
                       (ci-git '("update-index" "--force-remove" "--" "fixture-link"))
                       (let ((ref (%ci-data-test-tree-commit "160000" first "vendor/submodule" first)))
                         (rejects (lambda () (ci-source ref)))))))
            (dolist (id '("git-clean-byte-snapshots" "git-inventory-budgets"
                           "git-sha-width-matches-object-format" "git-results-only-identity"
                           "git-doc-change-outside-prefix" "git-historical-ref-without-checkout"
                           "git-policy-blob-change" "git-dirty-working-bytes-even-assume-unchanged"
                           "git-untracked-source-fails-ignored-too" "git-only-output-prefixes-allowed"
                           "git-ref-injection-rejected-before-command" "git-symlink-object-rejected"
                           "git-submodule-object-rejected"))
              (skip id))))
      (list :schema-version 1 :kind :ci-data-self-test :status (if (zerop failed) :passed :failed)
            :checks (+ passed failed skipped) :planned (+ passed failed skipped)
            :started (+ passed failed) :passed passed :failed failed :not-run skipped
            :cases (nreverse cases)
            :limits '(:not-run-at-load :private-git-fixture :no-runtime-product-measurement)))))
