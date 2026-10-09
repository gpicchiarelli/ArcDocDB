;;; OWNER: un dominio EBR per Archivio; slot reader assegnati dal controller dei pool.
;;; SHARED: i reader scrivono solo lo slot proprio; ritiri e soglia sotto mutex di manutenzione.
;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(defpackage #:arcdocdb.epochs
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:export #:registro-epoche #:crea-registro-epoche #:lettore-epoca #:contesto-epoca
           #:entra-epoca #:esci-epoca
           #:ritiro #:prenota-ritiro #:annulla-ritiro #:pubblica-ritiro
           #:aggiorna-soglia-reclaim #:acquisisci-reclaim #:completa-reclaim
           #:leggi-risorsa-ritiro #:leggi-ritiro #:leggi-registro-epoche))
