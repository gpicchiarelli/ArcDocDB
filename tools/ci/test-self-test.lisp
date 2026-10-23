;;;; Definizioni di fixture C4: nessun autorun, load prodotto, compilazione o processo.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defun ci-coverage-proof-self-test (out mode)
  "Tre fixture del passaggio verify->coverage, lette in un Lisp senza producer o prodotto.
MODE :PASSED/:INVALID/:UNKNOWN; conserva wire, argv e log in una directory esclusiva."
  (unless (member mode '(:passed :invalid :unknown)) (error "Modo fixture coverage non valido."))
  (let* ((root (ci-mkdir out)) (process nil)
         (identity (list :tested-sha (make-string 40 :initial-element #\a)
                         :source-id (make-string 64 :initial-element #\b)
                         :policy-id (make-string 64 :initial-element #\c)))
         (report (list :schema-version 1 :kind :ci-job-result :job "verify-linux" :status :passed
                       :identity identity :context nil
                       :metrics '(:planned 7 :passed 7 :failed 0 :not-run 0 :skipped 0)
                       :metrics-status :passed :reason nil
                       :execution '(:name "job" :command ("sbcl" "fixture") :exit-code 0
                                    :status :passed :record "commands/job/report.lisp")))
         (inputs nil) (unknown (symbol-name (gensym "CI-COVERAGE-PROOF-UNREGISTERED-")))
         (form nil) (command nil))
    (if (eq mode :unknown)
        (with-open-file (stream (merge-pathnames "unknown.lisp" root) :direction :output
                                :if-exists :error :if-does-not-exist :create)
          (format stream "(:NAME :~A)" unknown))
        (dolist (variant (if (eq mode :passed) '("passed") '("failed" "mismatch")))
          (let* ((data (copy-tree report))
                 (path (merge-pathnames (format nil "~A.lisp" variant) root)))
            (when (equal variant "failed") (setf (getf data :status) :failed))
            (when (equal variant "mismatch")
              (setf (getf (getf data :identity) :source-id) (make-string 64 :initial-element #\d)))
            (ci-save path data)
            (push (list (namestring path) (ci-sha256 path)) inputs))))
    ;; Nessun token dei campi aggiuntivi del producer compare nelle forme del figlio:
    ;; leggerli qui nel parent non deve mascherare il vocabolario incompleto del child.
    (setf form
          `(progn
             (assert (null (find-package "ARCDOCDB")))
             (assert (not (let ((symbol (find-symbol "CI-RUN-JOB" "ARCDOCDB.CI")))
                            (and symbol (fboundp symbol)))))
             ,(if (eq mode :unknown)
                  `(let ((name ,unknown))
                     (assert (null (find-symbol name "KEYWORD")))
                     (assert (handler-case
                                 (progn (arcdocdb.ci::ci-read
                                         ,(namestring (merge-pathnames "unknown.lisp" root))) nil)
                               (arcdocdb.ci::ci-data-error () t)))
                     (assert (null (find-symbol name "KEYWORD"))))
                  `(dolist (input ',inputs)
                     (let* ((arcdocdb.ci::*ci-coverage-normal-report* (first input))
                            (rows (arcdocdb.ci::ci-coverage-normal-proof ,(namestring root) ',identity)))
                       (assert (= 7 (length rows)))
                       (assert (equal arcdocdb.ci.tests::*coverage-exclusions*
                                      (mapcar (lambda (row) (getf row :id)) rows)))
                       (dolist (row rows)
                         (assert (and (eq :not-run (getf row :status))
                                      (eq :instrumentation-changes-allocation (getf row :reason))
                                      (eq ,(if (eq mode :passed) :passed :missing)
                                          (getf row :normal-status))
                                      ,(if (eq mode :passed) '(null (getf row :normal-reason))
                                           '(eq :normal-verification-same-sha-required
                                                (getf row :normal-reason)))
                                      (equal (first input) (getf row :normal-report))
                                      (equal (second input) (getf row :normal-report-sha256))))))))
             (sb-ext:exit :code 0)))
    (setf command
          (append
           (list (namestring sb-ext:*runtime-pathname*) "--noinform" "--no-userinit" "--no-sysinit"
                 "--non-interactive" "--eval" "(require :asdf)" "--eval" "(require :sb-posix)"
                 "--eval" "(defpackage :arcdocdb.ci (:use :cl))"
                 "--eval" (format nil "(defparameter arcdocdb.ci::*ci-root* (pathname ~S))"
                                  (namestring *ci-root*)))
           (loop for module in '("tests/ci-catalog.lisp" "tools/ci/data.lisp" "tools/ci/identity.lisp"
                                 "tools/ci/support.lisp" "tools/ci/tests.lisp" "tools/ci/coverage.lisp")
                 append (list "--load" (namestring (merge-pathnames module *ci-root*))))
           (list "--eval" (with-standard-io-syntax (write-to-string form)))))
    (ci-save (merge-pathnames "command.lisp" root) (list :command command))
    (unwind-protect
         (handler-case
             (progn
               (setf process (sb-ext:run-program
                              (first command) (rest command) :search nil :wait nil :directory *ci-root*
                              :output (merge-pathnames "child.stdout.log" root)
                              :error (merge-pathnames "child.stderr.log" root)
                              :if-output-exists :error :if-error-exists :error))
               (sb-ext:with-timeout 30 (sb-ext:process-wait process))
               (ci-save (merge-pathnames "result.lisp" root)
                        (list :status (sb-ext:process-status process)
                              :exit-code (sb-ext:process-exit-code process)))
               (and (eq :exited (sb-ext:process-status process))
                    (eql 0 (sb-ext:process-exit-code process))))
           (sb-ext:timeout () (error "Budget del child fixture coverage esaurito: ~A." root)))
      (when process
        (unwind-protect
             (progn
               (when (member (sb-ext:process-status process) '(:running :stopped))
                 (sb-ext:process-kill process sb-posix:sigkill))
               (handler-case (sb-ext:with-timeout 5 (sb-ext:process-wait process))
                 (sb-ext:timeout () (error "Reap del child fixture coverage scaduto: ~A." root))))
          (sb-ext:process-close process))))))

(defun ci-test-self-test (out)
  "API esplicita: fixture registro/provenienza/wire/assenza/LCOV e conteggi plist.
Invocazione riservata al coordinator dopo chiusura writer. Scrive test-self-test.lisp."
  (let* ((name (symbol-name (gensym "ARCDOCDB.CI.CATALOG.FIXTURE.")))
         (package (make-package name :use nil))
         (one (intern "ONE" package)) (two (intern "TWO" package))
         (cases nil) (negative 0))
    (setf (symbol-function one) (lambda () t) (symbol-function two) (lambda () t))
    (labels ((check (id function &optional negative-p)
               (when negative-p (incf negative))
               (handler-case
                   (push (list :id id :status (if (funcall function) :passed :failed)) cases)
                 (error (condition)
                   (push (list :id id :status :failed :condition (princ-to-string condition)) cases))))
             (rejects (function)
               (handler-case (progn (funcall function) nil) (error () t)))
             (lcov (body)
               (ci-coverage-parse-lcov (format nil "SF:src/fixture.lisp~%~Aend_of_record~%" body))))
      (unwind-protect
           (progn
             (check :catalog-57-suites
                    (lambda () (= 57 (length (arcdocdb.ci.tests:suite-specifications)))))
             (check :catalog-merged-cache-fulltext-and-production-engine
                    (lambda ()
                      (let ((ids (mapcar (lambda (row) (getf row :id))
                                         (arcdocdb.ci.tests:suite-specifications))))
                        (and (member "ARCDOCDB.CACHE.TESTS" ids :test #'equal)
                             (member "ARCDOCDB.FULLTEXT.ADMISSION.TESTS" ids :test #'equal)
                             (member "ARCDOCDB.ENGINE.TESTS" ids :test #'equal)
                             (every (lambda (id) (member id ids :test #'equal))
                                    '("ARCDOCDB.LOCAL.WIRE.TESTS" "ARCDOCDB.LOCAL.NATIVE.TESTS"
                                      "ARCDOCDB.LOCAL.SERVER.TESTS" "ARCDOCDB.LOCAL.PROCESS.TESTS"))))))
             (check :spk11-explicit-output-cache
                    (lambda ()
                      (and (%ci-working-output-p "spikes/SPK-11-unix-socket/out/build-a/core.fasl")
                           (not (%ci-working-output-p "spikes/SPK-11-unix-socket/core.lisp")))))
             (check :reject-unlisted-output-prefixes
                    (lambda ()
                      (and (not (%ci-working-output-p "spikes/SPK-12-unknown/out/core.fasl"))
                           (not (%ci-working-output-p "src/out/core.fasl")))) t)
             (check :catalog-suite-ids-unique
                    (lambda () (let ((ids (mapcar (lambda (r) (getf r :id))
                                                   (arcdocdb.ci.tests:suite-specifications))))
                                 (= (length ids) (length (remove-duplicates ids :test #'equal))))))
             (check :catalog-six-fulltext-suites
                    (lambda () (= 6 (count-if (lambda (r) (search "ARCDOCDB.FULLTEXT." (getf r :id)))
                                               (arcdocdb.ci.tests:suite-specifications)))))
             (check :catalog-two-named-smoke-cases
                    (lambda () (= 2 (length (getf (first (arcdocdb.ci.tests:suite-specifications)) :cases)))))
             (check :catalog-four-explicit-vertical-cases
                    (lambda () (= 4 (length arcdocdb.ci.tests::*vertical-cases*))))
             (check :catalog-seven-explicit-allocation-exclusions
                    (lambda () (= 7 (length arcdocdb.ci.tests::*coverage-exclusions*))))
             (check :catalog-index-mode-suite
                    (lambda () (find "ARCDOCDB.INDEX.MODE.TESTS"
                                     (arcdocdb.ci.tests:suite-specifications)
                                     :key (lambda (r) (getf r :id)) :test #'equal)))
             (check :catalog-index-page-suite
                    (lambda () (find "ARCDOCDB.INDEX.PAGE.TESTS"
                                     (arcdocdb.ci.tests:suite-specifications)
                                     :key (lambda (r) (getf r :id)) :test #'equal)))
             (check "coverage-proof-fresh-child-passed-artifact"
                    (lambda () (ci-coverage-proof-self-test
                                (merge-pathnames "coverage-proof-passed/" (ci-directory out)) :passed)))
             (check "coverage-proof-failed-or-other-identity-remains-missing"
                    (lambda () (ci-coverage-proof-self-test
                                (merge-pathnames "coverage-proof-invalid/" (ci-directory out)) :invalid)) t)
             (check "coverage-proof-unknown-keyword-is-not-interned"
                    (lambda () (ci-coverage-proof-self-test
                                (merge-pathnames "coverage-proof-unknown/" (ci-directory out)) :unknown)) t)
             (check :symbol-list-registry
                    (lambda () (let ((rows (arcdocdb.ci.tests::normalize-registry name :symbol-list (list two one))))
                                 (and (= 2 (length rows)) (equal "ONE" (getf (first rows) :name))
                                      (equal (arcdocdb.ci.tests::qualified-id name "TWO")
                                             (getf (second rows) :id))))))
             (check :alist-registry
                    (lambda () (= 2 (length (arcdocdb.ci.tests::normalize-registry
                                             name :alist (list (cons two (symbol-function two))
                                                               (cons one (symbol-function one))))))))
             (check :empty-registry-is-known-zero
                    (lambda () (null (arcdocdb.ci.tests::normalize-registry name :symbol-list nil))))
             (check :reject-list-instead-of-symbol
                    (lambda () (rejects (lambda () (arcdocdb.ci.tests::normalize-registry
                                                    name :symbol-list (list (list one)))))) t)
             (check :reject-alist-list-cdr
                    (lambda () (rejects (lambda () (arcdocdb.ci.tests::normalize-registry
                                                    name :alist (list (list one (symbol-function one))))))) t)
             (check :reject-duplicate-registry-id
                    (lambda () (rejects (lambda () (arcdocdb.ci.tests::normalize-registry
                                                    name :symbol-list (list one one))))) t)
             (check :reject-improper-registry
                    (lambda () (rejects (lambda () (arcdocdb.ci.tests::normalize-registry
                                                    name :symbol-list (cons one two))))) t)
             (check :reject-cyclic-registry
                    (lambda () (let ((cycle (list one)))
                                 (setf (cdr cycle) cycle)
                                 (rejects (lambda () (arcdocdb.ci.tests::normalize-registry
                                                      name :symbol-list cycle))))) t)
             (let ((arcdocdb.ci.tests::*definitions* (make-hash-table :test #'equal)))
               (arcdocdb.ci.tests::register-definition name "ONE" "tests/fixture-a.lisp")
               (check :duplicate-before-pushnew-is-rejected
                      (lambda () (rejects (lambda () (arcdocdb.ci.tests::register-definition
                                                      name "ONE" "tests/fixture-b.lisp")))) t)
               (arcdocdb.ci.tests::begin-source "tests/fixture-a.lisp")
               (arcdocdb.ci.tests::register-definition name "ONE" "tests/fixture-a.lisp")
               (check :reloaded-source-preserves-provenance
                      (lambda () (equal "tests/fixture-a.lisp"
                                        (getf (gethash (arcdocdb.ci.tests::qualified-id name "ONE")
                                                      arcdocdb.ci.tests::*definitions*) :source)))))
             (check :case-observer-once-even-for-nested-call
                    (lambda ()
                      (let ((n 0))
                        (let ((arcdocdb.ci.tests::*case-observer*
                                (lambda (id thunk) (declare (ignore id)) (incf n) (funcall thunk))))
                          (arcdocdb.ci.tests::call-registered-case
                           "fixture/outer" (lambda () (arcdocdb.ci.tests::call-registered-case
                                                       "fixture/inner" (lambda () t)))))
                        (= n 1))))
             (check :plain-writer-only-wire-primitives
                    (lambda ()
                      (let* ((data '(:status :passed :count 0 :unknown nil :flag t :text "fixtùra"))
                             (text (with-output-to-string (s) (arcdocdb.ci.tests::write-data s data))))
                        (and (not (find #\# text))
                             (equal (ci-wire-string data)
                                    (ci-wire-string
                                     (with-standard-io-syntax
                                       (let ((*read-eval* nil)) (read-from-string text)))))))))
             (check :plain-writer-rejects-float
                    (lambda () (rejects (lambda () (with-output-to-string (s)
                                                     (arcdocdb.ci.tests::write-data s (list :value 1.5)))))) t)
             (let* ((zero (append (list :path "src/zero.lisp" :status :measured)
                                  (loop for key in *ci-coverage-counter-keys* append (list key 0))))
                    (unknown (append (list :path "src/unknown.lisp" :status :missing)
                                     (loop for key in *ci-coverage-counter-keys* append (list key nil))))
                    (known (ci-coverage-totals (list zero)))
                    (partial (ci-coverage-totals (list zero unknown))))
               (check :known-zero-denominator-remains-zero
                      (lambda () (and (eq :measured (getf known :status))
                                      (eql 0 (getf known :expressions-total))
                                      (eql 0 (getf known :lines-total)))))
               (check :unknown-denominator-never-zero
                      (lambda () (and (eq :partial (getf partial :status))
                                      (null (getf partial :expressions-total))
                                      (null (getf partial :lines-total))
                                      (= 1 (getf partial :known-files))
                                      (= 2 (getf partial :expected-files)))))
               (check :partial-subtotal-is-labelled
                      (lambda () (eql 0 (getf (getf partial :known-subtotal) :expressions-total))))
               (check :all-unknown-subtotal-absent
                      (lambda () (null (getf (ci-coverage-totals (list unknown)) :known-subtotal)))))
             (let ((row (first (lcov (format nil "DA:1,1~%DA:2,0~%BA:1,1~%BA:1,2~%")))))
               (check :lcov-da-exact-counts
                      (lambda () (and (= 1 (getf row :lines-covered)) (= 2 (getf row :lines-total)))))
               (check :lcov-ba-exact-counts
                      (lambda () (and (= 1 (getf row :lcov-branches-covered))
                                      (= 2 (getf row :lcov-branches-total))))))
             (check :lcov-zero-lines-is-not-full-coverage
                    (lambda () (eql 0 (getf (first (lcov "")) :lines-total))))
             (dolist (fixture (list (format nil "DA:1,1~%DA:1,0~%")
                                   (format nil "DA:1,1~%BA:1,0~%")
                                   (format nil "DA:1,1~%BRDA:1,0,0,1~%")
                                   (format nil "DA:0,1~%")
                                   (format nil "DA:1,2~%")
                                   (format nil "BA:1,2~%")))
               (let ((data fixture))
                 (check (concatenate 'string "reject-lcov:" data)
                        (lambda () (rejects (lambda () (lcov data)))) t)))
             (check :reject-truncated-lcov
                    (lambda () (rejects (lambda () (ci-coverage-parse-lcov
                                                    (format nil "SF:src/a.lisp~%DA:1,1~%"))))) t)
             (check :reject-duplicate-lcov-file
                    (lambda () (rejects (lambda () (ci-coverage-parse-lcov
                                                    (format nil "SF:src/a.lisp~%end_of_record~%SF:src/a.lisp~%end_of_record~%"))))) t))
        (delete-package package)))
    (setf cases (nreverse cases))
    (let* ((failed (count :failed cases :key (lambda (r) (getf r :status))))
           (counts (list :planned (length cases) :started (length cases)
                         :passed (- (length cases) failed) :failed failed :not-run 0
                         :negative-cases negative))
           (report (list :schema-version 1 :kind :ci-test-self-test
                         :status (if (zerop failed) :passed :failed)
                         :counts counts :fixture-data-only t :cases cases)))
      (ci-save (merge-pathnames "test-self-test.lisp" (ci-directory out)) report)
      report)))
