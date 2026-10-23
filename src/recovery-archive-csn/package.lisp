;;; OWNER: coordinatore esclusivo dell'Archivio dopo recupero del catalogo e delle Serie.
;;; SHARED: sole letture di risultati immutabili; nessun nuovo CSN, lock o punto di atomicità.
;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(defpackage #:arcdocdb.recovery.archive.csn
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:u32 #:u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.get #:vista-get-serie)
  (:import-from #:arcdocdb.recovery.archive #:archivio-recovery #:decisioni-recuperate
                #:massimo-csn-decisioni-recuperate)
  (:import-from #:arcdocdb.recovery.active #:active-recuperato)
  (:import-from #:arcdocdb.recovery.closed #:massimo-csn-serie-recuperata)
  (:export #:insieme-serie-recovery #:crea-insieme-serie-recovery #:numero-serie-recovery
           #:piano-csn-archivio #:crea-piano-csn-archivio #:massimo-csn-archivio
           #:statistiche-piano-csn-archivio #:parole-base-csn-archivio))
