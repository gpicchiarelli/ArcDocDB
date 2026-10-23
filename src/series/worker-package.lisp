;;;; Collegamento locale preallocato, caricato dopo execution e il controller Serie.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defpackage #:arcdocdb.execution.series
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:error-reason)
  (:import-from #:arcdocdb.execution #:contesto-worker-writer #:writer-programmabile
                #:stato-worker-writer #:writer-worker-writer #:inizia-tratto-worker
                #:preleva-lavori-worker #:conferma-lavori-worker #:termina-tratto-worker)
  (:import-from #:arcdocdb.series #:controllore-serie #:acquisisci-controllore-serie
                #:rilascia-controllore-serie)
  (:export #:collegamento-worker-serie #:crea-collegamento-worker-serie
           #:registro-worker-serie #:crea-registro-worker-serie
           #:tabella-worker-serie #:crea-tabella-worker-serie #:collega-writer-worker-serie
           #:inizia-worker-serie #:lease-worker-serie #:preleva-worker-serie
           #:conferma-worker-serie #:termina-worker-serie
           #:stato-worker-serie #:errore-worker-serie))
