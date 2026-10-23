;;;; Politica e attuatore logico del pool; thread preesistenti, nessuna attesa.
;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(defpackage #:arcdocdb.scheduler
  (:use #:cl)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation
                #:resource-exhausted)
  (:export #:controllore-pool #:crea-controllore-pool
           #:aggiorna-controllore-pool #:leggi-controllore-pool
           #:porta-worker-pool #:crea-porta-worker-pool #:applica-stato-worker-pool
           #:prendi-writer-pool
           #:registro-pool #:crea-registro-pool #:leggi-registro-pool
           #:aggiorna-registro-pool))
