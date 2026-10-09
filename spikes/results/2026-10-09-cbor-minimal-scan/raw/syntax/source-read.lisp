;;;; Lettura sintattica dei test come dati; package stub, nessun prodotto caricato.
(dolist (entry '(("ARCDOCDB.FOUNDATION.TESTS" "IS" "BYTES")
                 ("ARCDOCDB.CONDITIONS" "ARCDOCDB-ERROR" "INVALID-ARGUMENT" "RESOURCE-EXHAUSTED"
                  "CORRUPTION-DETECTED" "ERROR-REASON" "ERROR-OFFSET")
                 ("ARCDOCDB.CBOR" "CREA-SPAZIO-CBOR" "VERIFICA-STRUTTURA-CBOR"
                  "VERIFICA-STRUTTURA-CBOR-MINIMA")
                 ("ARCDOCDB.CBOR.STRUCTURE.TESTS") ("ARCDOCDB.CBOR.MINIMAL.TESTS")
                 ("ARCDOCDB.CBOR.TESTS") ("ARCDOCDB.CBOR.MINIMAL.SCAN.TESTS")))
  (let ((package (or (find-package (first entry))
                     (make-package (first entry) :use '("COMMON-LISP")))))
    (dolist (name (rest entry)) (export (intern name package) package))))
(let ((*read-eval* nil) (*readtable* (copy-readtable nil)))
  (dolist (file '("tests/codec/cbor-minimal-scan-support.lisp"
                  "tests/codec/cbor-minimal-scan.lisp"
                  "tests/codec/cbor-minimal-scan-threads.lisp"))
    (with-open-file (input file :external-format :utf-8)
      (loop with forms = 0 with tests = 0
            for form = (read input nil :eof)
            until (eq form :eof)
            do (incf forms)
               (when (and (consp form) (symbolp (first form))
                          (string= "DEFTEST" (symbol-name (first form)))) (incf tests))
            finally (format t "~A: ~D form, ~D test nominali, EOF.~%" file forms tests)))))
