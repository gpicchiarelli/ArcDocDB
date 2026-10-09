;;;; Codec di testo puro, senza dipendenze da storage, worker o I/O.
;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.utf8
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:corruption-detected #:invariant-violation)
  (:export #:verifica-utf8))
