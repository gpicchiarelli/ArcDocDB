;;;; Copertura con contrib SBCL; processo e cache separati dai benchmark.
;;;; Uso: --report directory/ [foundation|storage|recovery|io|wal] oppure --self-test directory/
;;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-LIM-001 REQ-VAL-001
(require :asdf)
(require :sb-cover)

(defpackage #:arcdocdb.foundation.coverage
  (:use #:cl))
(in-package #:arcdocdb.foundation.coverage)

(defun read-report (pathname)
  (uiop:read-file-string pathname :external-format :utf-8))

(defun self-test (directory)
  (let* ((source (merge-pathnames "coverage-fixture.lisp" directory))
         (fasl (merge-pathnames "coverage-fixture.fasl" directory)))
    (with-open-file (stream source :direction :output :if-exists :supersede)
      (write-line "(in-package #:cl-user)" stream)
      (write-line "(declaim (optimize (sb-cover:store-coverage-data 3)))" stream)
      (write-line "(defun coverage-fixture (flag) (if (plusp flag) (1+ flag) (1- flag)))" stream))
    (load (compile-file source :output-file fasl))
    (uiop:symbol-call '#:cl-user '#:coverage-fixture 1)
    (let ((report (sb-cover:report directory)))
      (unless (search "50.0" (read-report report))
        (error "foundation-coverage.lisp: COD-60, ramo mancante non rilevato.")))
    (format t "Copertura: self-test del ramo mancante superato.~%")))

(defun coverage (directory scope)
  (let ((root (truename "./")))
    (asdf:initialize-output-translations
     `(:output-translations (,root ,(merge-pathnames "fasl/" directory))
                            :ignore-inherited-configuration))
    (proclaim '(optimize (sb-cover:store-coverage-data 3)))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" root))
      (asdf:load-system "arcdocdb" :force t)
      (asdf:load-system "arcdocdb/tests" :force t)
      (uiop:symbol-call (cond ((string= scope "storage") '#:arcdocdb.storage.tests)
                             ((string= scope "recovery") '#:arcdocdb.recovery.tests)
                             ((string= scope "io") '#:arcdocdb.io.tests)
                             ((string= scope "wal") '#:arcdocdb.wal.tests)
                             (t '#:arcdocdb.foundation.tests)) '#:run))
    (sb-cover:save-coverage-in-file (merge-pathnames "coverage-state.lisp" directory))
    (let ((report (sb-cover:report directory :if-matches
                                  (lambda (path) (search (format nil "/src/~A/" scope) path)))))
      (unless report
        (error "foundation-coverage.lisp: COD-60, nessun dato per src/~A/." scope))
      (format t "Rapporto: ~A~%" report))))

(let ((args (rest sb-ext:*posix-argv*)))
  (unless (and (<= 2 (length args) 3) (member (first args) '("--report" "--self-test")
                                            :test #'string=)
               (or (= (length args) 2)
                   (member (third args) '("foundation" "storage" "recovery" "io" "wal") :test #'string=)))
    (error "foundation-coverage.lisp: usare --report directory/ [foundation|storage|recovery|io|wal] o --self-test directory/."))
  (let ((directory (merge-pathnames (uiop:ensure-directory-pathname (second args))
                                   (truename "./")))
        (scope (or (third args) "foundation")))
    (ensure-directories-exist directory)
    (if (string= (first args) "--self-test")
        (self-test directory)
        (coverage directory scope))))
