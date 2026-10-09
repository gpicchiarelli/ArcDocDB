;;;; Esecuzione locale: coda bounded e lease esplicita del singolo writer.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defpackage #:arcdocdb.execution
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:coda-writer #:crea-coda-writer #:accoda-messaggio
           #:acquisisci-writer #:preleva-messaggi #:rilascia-writer
           #:writer-programmabile #:crea-writer-programmabile #:accoda-lavoro-writer
           #:inizia-tratto-writer #:preleva-lavori-writer #:termina-tratto-writer
           #:lista-writer-pronti #:crea-lista-writer-pronti
           #:pubblica-writer-pronto #:preleva-writer-pronto #:ricircola-writer-pronto
           #:contesto-worker-writer #:crea-contesto-worker-writer
           #:stato-worker-writer #:writer-worker-writer #:errore-worker-writer #:prendi-writer-worker
           #:inizia-tratto-worker #:preleva-lavori-worker #:conferma-lavori-worker
           #:termina-tratto-worker #:ricircola-worker
           #:adotta-writer-worker #:cede-writer-worker))
