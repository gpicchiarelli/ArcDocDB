;;;; Harness del solo lettore di evidenze: tutti gli avvisi sono fatali.
(handler-bind ((warning (lambda (condition) (error condition))))
  (load "/tmp/cbor-minimal-measurement-reader.lisp"))
