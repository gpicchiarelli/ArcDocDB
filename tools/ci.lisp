;;;; CI C4: un solo ingresso; dati canonici, producer isolati e publisher fidato.
;;; REQ: REQ-VAL-001 REQ-AFF-005 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.ci (:use #:cl))
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *ci-root*
  (truename (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
(defparameter *ci-entry* (merge-pathnames "tools/ci.lisp" *ci-root*))
(defparameter *ci-sbcl* (namestring sb-ext:*runtime-pathname*))
(load (merge-pathnames "tools/evidence-storage.lisp" *ci-root*))
(load (merge-pathnames "tests/ci-catalog.lisp" *ci-root*))
(dolist (module '("data" "identity" "support" "tests" "coverage" "measure"
                  "archive" "producer" "github" "publish" "self-test"
                  "data-self-test" "test-self-test" "conditions-self-test"
                  "measure-self-test" "workflow-self-test" "publish-self-test"))
  (load (merge-pathnames (format nil "tools/ci/~A.lisp" module) *ci-root*)))
(uiop:with-current-directory (*ci-root*)
  (handler-case
      (let ((code (ci-main (uiop:command-line-arguments))))
        (sb-ext:exit :code code))
    (error (condition)
      (format *error-output* "~&CI: ~A~%" condition)
      (sb-ext:exit :code 1))))
