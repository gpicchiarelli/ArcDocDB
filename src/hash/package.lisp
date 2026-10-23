;;; OWNER: il chiamante possiede buffer e seme; input immutati per l'intera chiamata.
;;; SHARED: nessuno stato mutabile; costanti dell'algoritmo soltanto.
;;; REQ: REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(defpackage #:arcdocdb.hash64
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u32 #:u64 #:check-range)
  (:import-from #:arcdocdb.record #:+max-key-bytes+)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation)
  (:export #:xxh64))
