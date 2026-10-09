;;;; Controller locale: pubblicazione e ritiro dei lotti, senza pool o indice concreto.
;;; REQ: REQ-CON-002 REQ-CON-005 REQ-WAL-006 REQ-MVC-008 REQ-AFF-001
(defpackage #:arcdocdb.series
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:u32)
  (:import-from #:arcdocdb.csn #:registro-csn)
  (:import-from #:arcdocdb.wal #:log-io #:lotto #:stato-log #:stato-lotto
                #:inizio-lotto #:lunghezza-lotto #:leggi-csn-lotto
                #:verifica-token-lotto #:verifica-pubblicazione-lotto
                #:risolvi-lotto-pubblicato #:annulla-csn-lotto
                #:marca-log-faulted #:verifica-log-segmento
                #:verifica-ritiro-lotto #:verifica-riuso-lotto #:riusa-lotto)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:io-fault #:error-reason)
  (:export #:controllore-serie #:commit-serie #:crea-controllore-serie
           #:acquisisci-controllore-serie #:rilascia-controllore-serie
           #:registra-commit-serie #:inizia-io-commit-serie #:completa-io-commit-serie
           #:ritira-io-commit-serie
           #:pubblica-commit-serie #:riusa-commit-serie
           #:fault-controllore-serie #:annulla-commit-serie
           #:leggi-radice-serie #:stato-controllore-serie #:ambito-fault-serie
           #:stato-commit-serie #:leggi-csn-commit-serie #:conta-commit-serie))
