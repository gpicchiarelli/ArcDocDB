;;; OWNER: un contesto preallocato per worker e Archivio, comune ai compiti successivi.
;;; SHARED: solo slot EBR proprio e letture del registro snapshot; nessun dato di richiesta in coda.
;;; REQ: REQ-CON-004 REQ-CMP-005 REQ-CMP-007 REQ-MVC-005 REQ-AFF-008
(defpackage #:arcdocdb.read
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation)
  (:import-from #:arcdocdb.epochs #:lettore-epoca #:entra-epoca #:esci-epoca #:epoca-attiva-p)
  (:import-from #:arcdocdb.mvcc #:registro-snapshot #:contesto-snapshot
                #:snapshot-del-registro-p #:verifica-snapshot-in-buffer)
  (:export #:contesto-lettura #:crea-contesto-lettura #:stato-contesto-lettura
           #:avvia-lettura #:copia-limite-lettura #:concludi-lettura #:abbandona-lettura))
