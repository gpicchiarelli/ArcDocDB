;;; OWNER: configurazione immutabile; il controllore della Serie fornisce le stime.
;;; SHARED: nessuno stato mutabile o contatore fra Serie (INV-P6).
;;; REQ: REQ-IDX-008 REQ-AFF-008
(defpackage #:arcdocdb.index.mode
  (:use #:cl)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted)
  (:export #:politica-indice #:crea-politica-indice #:valuta-modo-indice))
