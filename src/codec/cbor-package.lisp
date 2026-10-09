;;;; Testate CBOR pure: nessuna dipendenza da parser, storage, worker o I/O.
;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.cbor
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:invariant-violation)
  (:export #:leggi-header-cbor))
