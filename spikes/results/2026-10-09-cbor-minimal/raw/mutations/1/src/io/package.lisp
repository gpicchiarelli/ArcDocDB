;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-STO-003
(defpackage #:arcdocdb.io
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:check-range)
  (:import-from #:arcdocdb.conditions #:io-fault #:invalid-argument #:resource-exhausted
                #:invariant-violation #:unsupported-format)
  (:export #:backend #:make-backend #:file-io
           #:apri-lettura #:crea-temporaneo #:apri-directory #:chiudi
           #:leggi-esatto #:append-esatto #:durable-flush #:mode-file #:verifica-capienza-append
           #:stato-file #:posizione-scritta #:posizione-durevole))
