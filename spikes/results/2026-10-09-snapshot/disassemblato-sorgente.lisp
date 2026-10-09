(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-snapshot-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)
(handler-bind ((warning (lambda (condition)
                         (unless (typep condition 'sb-kernel:redefinition-warning)
                           (error condition)))))
  (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
  (asdf:load-system \"arcdocdb\"))
(dolist (name '(arcdocdb.mvcc:verifica-snapshot-in-buffer arcdocdb.mvcc:deve-trattenere-p))
  (format t \"~&FUNZIONE: ~S; ISPEZIONE STATICA, NESSUNA CHIAMATA DELLA FUNZIONE~%\" name)
  (disassemble name))
"
 :LIMITS (:STATIC-DISASSEMBLY-ONLY :NO-FUNCTION-EXECUTION))
