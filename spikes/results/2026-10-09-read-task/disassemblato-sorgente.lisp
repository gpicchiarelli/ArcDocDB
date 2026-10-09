(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-read-task-disassemble.lisp" :TEXT "(require :asdf)
(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)
(asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
(asdf:load-system \"arcdocdb\")
(dolist (name '(arcdocdb.read:avvia-lettura arcdocdb.read:copia-limite-lettura
                arcdocdb.read:concludi-lettura arcdocdb.read:abbandona-lettura
                arcdocdb.read::libera-contesto-lettura))
  (format t \"~&Funzione ispezionata, non eseguita: ~S~%\" name)
  (disassemble name))
"
 :LIMITS (:STATIC-DISASSEMBLY-ONLY :NO-INSPECTED-FUNCTION-EXECUTION))
