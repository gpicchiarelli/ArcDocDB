(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-snapshot-csn-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)
(asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
(asdf:load-system \"arcdocdb\")
(dolist (name '(arcdocdb.mvcc::frontiere-snapshot arcdocdb.mvcc::tenta-cattura-snapshot
                arcdocdb.mvcc:registra-snapshot arcdocdb.mvcc:attiva-snapshot
                arcdocdb.mvcc:invalida-registro-snapshot arcdocdb.mvcc:verifica-snapshot))
  (format t \"~&Funzione ispezionata, non eseguita: ~S~%\" name)
  (disassemble name))
"
 :LIMITS (:STATIC-DISASSEMBLY-ONLY :NO-INSPECTED-FUNCTION-EXECUTION))
