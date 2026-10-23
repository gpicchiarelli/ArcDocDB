;;; OWNER: coordinatore esclusivo dell'Archivio nel pool I/O, prima di runtime e ammissione.
;;; SHARED: decisioni e catalogo readonly; nessun nuovo registro, lock o punto durevole.
;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-TXM-005 REQ-AFF-008
(defpackage #:arcdocdb.recovery.bootstrap
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:octets)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.control #:control-recuperato)
  (:import-from #:arcdocdb.recovery.manifest #:recovery-sources)
  (:import-from #:arcdocdb.recovery.archive #:decisioni-recuperate)
  (:import-from #:arcdocdb.recovery.archive.csn #:insieme-serie-recovery #:piano-csn-archivio
                #:crea-piano-csn-archivio #:statistiche-piano-csn-archivio)
  (:import-from #:arcdocdb.recovery.series #:limiti-recovery-serie #:leggi-serie-recuperata)
  (:export #:leggi-archivio-recuperato #:stabilizza-nomi-archivio-recuperato))
