;;;; Ingresso test separato; i figli eseguono soltanto le CLI di prodotto.
(require :asdf)
(require :sb-posix)
(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)
(handler-case
    (progn
      (unless (member (uiop:command-line-arguments) '(nil ("--self-test")) :test #'equal)
        (error "Uso: sbcl --script tools/local-tests.lisp [--self-test]."))
      (handler-bind ((warning (lambda (condition)
                               (unless (typep condition 'sb-kernel:redefinition-warning)
                                 (error condition)))))
        (asdf:load-asd (merge-pathnames "../arcdocdb.asd" *load-truename*))
        (asdf:load-system "arcdocdb/tests"))
      (uiop:symbol-call :arcdocdb.local.process.tests :run))
  (error (condition)
    (format *error-output* "~&LOCAL-TESTS-FAIL ~A: ~A~%" (type-of condition) condition)
    (finish-output *error-output*)
    (sb-ext:exit :code 1)))
