;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-STO-003
(defpackage #:arcdocdb.io
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:check-range)
  (:import-from #:arcdocdb.conditions #:io-fault #:invalid-argument #:resource-exhausted
                #:invariant-violation #:unsupported-format)
  (:export #:backend #:make-backend #:file-io
           #:associazione-file #:associa-file #:verifica-associazione-file #:verifica-file-distinti
           #:apri-lettura #:apri-lettura-nella-directory #:crea-temporaneo #:crea-temporaneo-nella-directory
           #:apri-directory #:chiudi #:elenca-directory #:esigi-esclusiva-directory
           #:leggi-esatto #:append-esatto #:durable-flush #:rinomina-nella-directory #:mode-file #:verifica-capienza-append
           #:stato-file #:posizione-scritta #:posizione-durevole #:verifica-capienza-lettura
           #:verifica-capacita-sostituzione #:sostituisci-temporaneo
           #:pubblica-temporaneo #:stabilizza-nome-temporaneo #:verifica-stabilizzazione-temporaneo))
