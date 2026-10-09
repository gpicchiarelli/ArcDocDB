(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-primary-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
(handler-bind ((warning (lambda (condition)
                         (unless (typep condition 'sb-kernel:redefinition-warning)
                           (error condition)))))
  (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
  (asdf:load-system \"arcdocdb\"))
(dolist (name '(arcdocdb.index.primary:leggi-indice-primario
                arcdocdb.index.primary::sonda-gruppo
                arcdocdb.index.primary::sonda-reader
                arcdocdb.index.primary:pubblica-chiave-indice
                arcdocdb.index.primary:riloca-chiave-indice
                arcdocdb.index.primary:pubblica-directory-indice))
  (format t \"~&;;; STATIC-DISASSEMBLY ~S; product function not executed.~%\" name)
  (disassemble name))
"
 :LIMITS (:FILESYSTEM-COLLECTION-ONLY :NO-PRODUCT-FUNCTION-EXECUTION))
