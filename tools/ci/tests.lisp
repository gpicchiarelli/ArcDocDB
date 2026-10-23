;;;; Producer test C4; nessun caricamento del prodotto al load di questo modulo.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defun ci-test-identity ()
  (let ((identity (ci-source)))
    (list :tested-sha (getf identity :tested-sha)
          :source-id (getf identity :source-id) :policy-id (getf identity :policy-id))))

(defun ci-test-asdf-files (&optional system)
  "Sorgenti ASDF effettivi, senza caricare il prodotto."
  (labels ((walk (component)
             (cond ((typep component 'asdf:cl-source-file)
                    (list (asdf:component-pathname component)))
                   ((typep component 'asdf:parent-component)
                    (mapcan #'walk (asdf:component-children component))))))
    (if system (walk (asdf:find-system system))
        (append (walk (asdf:find-system "arcdocdb"))
                (walk (asdf:find-system "arcdocdb/local"))))))

(defun ci-test-private-cache (out)
  (let ((cache (ci-mkdir (merge-pathnames "fasl/" out))))
    (asdf:initialize-output-translations
     `(:output-translations
       (,(merge-pathnames "**/*.*" *ci-root*) ,(merge-pathnames "**/*.*" cache))
       :ignore-inherited-configuration))
    (dolist (path (append (ci-test-asdf-files) (ci-test-asdf-files "arcdocdb/tests")))
      (unless (uiop:subpathp (asdf:apply-output-translations
                            (make-pathname :type "fasl" :defaults path)) cache)
        (error "FASL fuori dalla cache privata: ~A." path)))
    cache))

(defun ci-test-load-systems (out &key coverage)
  "Compila sempre; warning e style-warning sono errori. Nessun TEST-OP implicito."
  (asdf:load-asd (merge-pathnames "arcdocdb.asd" *ci-root*))
  (ci-test-private-cache out)
  (when coverage
    (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "CLEAR-COVERAGE" t))
    (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "ENABLE-COVERAGE-LOGGING" t))
    (proclaim `(optimize (safety 3)
                        (,(arcdocdb.ci.tests::lookup "SB-COVER" "STORE-COVERAGE-DATA") 3))))
  (let ((asdf:*compile-file-warnings-behaviour* :error)
        (asdf:*compile-file-failure-behaviour* :error))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (unwind-protect
           (progn
             (asdf:load-system "arcdocdb" :force '("arcdocdb"))
             (asdf:load-system "arcdocdb/local" :force '("arcdocdb/local")))
        (when coverage
          (proclaim `(optimize
                      (,(arcdocdb.ci.tests::lookup "SB-COVER" "STORE-COVERAGE-DATA") 0)))))
      ;; Non ricompilare il prodotto come effetto collaterale del force sui test.
      (asdf:load-system "arcdocdb/tests" :force '("arcdocdb/tests")))))

(defun ci-run-tests (out)
  "Ingresso del child verify. Errori precoci di compilazione al coordinator.
Scrive tests.expected.lisp prima del load; tests.lisp e tests.events.lisp dal catalogo."
  (let* ((directory (ci-directory out)) (identity (ci-test-identity))
         (path (merge-pathnames "tests.lisp" directory)))
    (unless (ci-working-clean-p) (error "Verify: checkout iniziale non pulito."))
    (ci-save (merge-pathnames "tests.expected.lisp" directory)
             (list :kind :ci-test-plan :identity identity :planned nil
                   :reason :cases-not-loaded
                   :suites (arcdocdb.ci.tests:suite-specifications)))
    (ci-test-load-systems directory)
    (let ((report (arcdocdb.ci.tests:run :report-path path)))
      (setf (getf report :identity) identity
            (getf report :tested-sha) (getf identity :tested-sha)
            (getf report :source-id) (getf identity :source-id)
            (getf report :profile) :verify)
      (unless (and (ci-working-clean-p) (equal identity (ci-test-identity)))
        (setf (getf report :status) :failed (getf report :condition) "Sorgenti mutati durante verify."))
      (ci-save path report :replace t)
      report)))
