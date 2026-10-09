(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-ebr-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)
(handler-bind ((warning (lambda (condition)
                         (unless (typep condition 'sb-kernel:redefinition-warning)
                           (error condition)))))
  (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
  (asdf:load-system \"arcdocdb\"))
(disassemble #'arcdocdb.epochs:entra-epoca)
(disassemble #'arcdocdb.epochs:esci-epoca)
"
 :LIMITS (:STATIC-DISASSEMBLY-ONLY :NO-INSPECTED-FUNCTION-EXECUTION))
