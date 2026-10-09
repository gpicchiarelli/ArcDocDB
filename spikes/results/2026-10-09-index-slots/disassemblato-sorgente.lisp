(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-index-slots-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
(handler-bind ((warning (lambda (condition)
                         (unless (typep condition 'sb-kernel:redefinition-warning)
                           (error condition)))))
  (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
  (asdf:load-system \"arcdocdb\"))
(dolist (name '(arcdocdb.index.slots:leggi-slot-v2
                arcdocdb.index.slots:pubblica-slot-v2
                arcdocdb.index.slots::cambia-slot
                arcdocdb.index.slots:credito-scrittura-slot
                arcdocdb.index.slots:riloca-slot-v2))
  (format t \"~&;;; STATIC-DISASSEMBLY ~S; product function not executed.~%\" name)
  (disassemble name))
"
 :LIMITS (:STATIC-INSPECTION-ONLY :NO-PRODUCT-FUNCTION-EXECUTION))
