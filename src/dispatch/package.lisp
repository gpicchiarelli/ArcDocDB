;;;; Dispatcher logico, caricato dopo il routing e il governo del pool.
;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defpackage #:arcdocdb.scheduler.dispatch
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:dispatcher-writer-pool #:crea-dispatcher-writer-pool
           #:prendi-collegamento-pool #:collega-obbligo-pool #:ricircola-collegamento-pool
           #:inizia-obbligo-pool #:passo-dispatcher-pool #:prepara-tratto-pool))
