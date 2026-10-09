;;;; Testate e scansione strutturale CBOR: nessuna dipendenza da storage o I/O.
;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.cbor
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:invariant-violation)
  (:export #:leggi-header-cbor #:leggi-header-cbor-minimo #:spazio-cbor #:crea-spazio-cbor
           #:verifica-struttura-cbor))
