;;;; Coordinamento per Archivio, soltanto alla chiusura e risoluzione dei lotti.
;;; REQ: REQ-MVC-005 REQ-MVC-008 REQ-AFF-008
(defpackage #:arcdocdb.csn
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:registro-csn #:crea-registro-csn #:prendi-csn #:risolvi-csn
           #:leggi-frontiere-csn))
