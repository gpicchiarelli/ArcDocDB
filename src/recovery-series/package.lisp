;;; OWNER: coordinatore esclusivo della Serie nel pool I/O; fonti e scratch prestati e stabili.
;;; SHARED: decisioni Archivio readonly; nessun registro, writer o stato condiviso nuovo.
;;; REQ: REQ-REC-001 REQ-REC-004 REQ-TXM-007 REQ-AFF-008
(defpackage #:arcdocdb.recovery.series
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:u32 #:u64 #:octets)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.control #:control-recuperato #:manifest-control-recuperato)
  (:import-from #:arcdocdb.recovery.manifest #:recovery-sources #:numero-fonti-recovery #:fonte-recovery
                #:numero-segmenti-chiusi #:segmento-attivo #:trova-segmento)
  (:import-from #:arcdocdb.recovery.archive #:decisioni-recuperate #:leggi-active-con-decisioni)
  (:import-from #:arcdocdb.recovery.active #:active-recuperato)
  (:import-from #:arcdocdb.recovery.closed #:leggi-closed-recuperato #:verifica-closed-completi)
  (:export #:limiti-recovery-serie #:crea-limiti-recovery-serie #:leggi-serie-recuperata
           #:stabilizza-nome-fonte-recuperata #:stabilizza-nomi-serie-recuperata))
