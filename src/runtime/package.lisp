;;; OWNER: controller dell'Archivio dopo il piano completo; nessun traffico ancora ammesso.
;;; SHARED: pubblicazione unica della famiglia CSN/snapshot/EBR già prevista; solo bootstrap.
;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-CMP-007 REQ-AFF-008
(defpackage #:arcdocdb.runtime
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation)
  (:import-from #:arcdocdb.recovery.archive #:archivio-recovery)
  (:import-from #:arcdocdb.recovery.archive.csn #:piano-csn-archivio
                #:massimo-csn-archivio #:statistiche-piano-csn-archivio #:parole-base-csn-archivio)
  (:import-from #:arcdocdb.csn #:registro-csn #:crea-registro-csn #:leggi-frontiere-csn)
  (:import-from #:arcdocdb.mvcc #:registro-snapshot #:crea-registro-snapshot)
  (:import-from #:arcdocdb.epochs #:registro-epoche #:crea-registro-epoche)
  (:import-from #:arcdocdb.get #:ambito-get #:crea-ambito-get)
  (:export #:runtime-archivio #:crea-runtime-archivio #:trova-runtime-archivio
           #:csn-runtime-archivio #:ambito-runtime-archivio
           #:snapshot-runtime-archivio #:epoche-runtime-archivio
           #:adotta-controllore-active #:adotta-directory-closed))
