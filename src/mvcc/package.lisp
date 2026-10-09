;;;; Coordinamento per Archivio; nessuna dipendenza da WAL, indici o scheduler.
;;; REQ: REQ-MVC-008 REQ-MVC-005 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.mvcc
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:registro-csn #:crea-registro-csn #:capienza-registro-csn #:stato-registro-csn
           #:prenotazione-csn #:crea-prenotazione-csn #:leggi-prenotazione
           #:riserva-csn #:concludi-csn #:leggi-orizzonte #:orizzonte-raggiunto-p))
