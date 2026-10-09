;;;; Snapshot per Archivio, legati al registro CSN canonico di arcdocdb.csn.
;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.mvcc
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u32 #:u64)
  (:import-from #:arcdocdb.csn #:registro-csn #:leggi-frontiere-csn)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:snapshot-too-old #:error-reason)
  (:export #:registro-snapshot #:crea-registro-snapshot #:contesto-snapshot #:crea-contesto-snapshot
           #:registra-snapshot #:attiva-snapshot #:termina-snapshot #:scadi-snapshot
           #:verifica-snapshot #:verifica-snapshot-in-buffer #:snapshot-del-registro-p
           #:soglia-snapshot #:deve-trattenere-p #:leggi-registro-snapshot
           #:invalida-registro-snapshot))
