;;;; Fondazioni binarie: nessuna dipendenza da storage, scheduler o I/O.
;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-AFF-004
(defpackage #:arcdocdb.conditions
  (:use #:cl)
  (:export #:arcdocdb-error #:invalid-argument #:corruption-detected
           #:unsupported-format #:resource-exhausted #:invariant-violation
           #:io-fault #:error-operation #:error-errno #:error-cleanup-errno #:error-transferred
           #:snapshot-too-old
           #:error-reason #:error-offset))

(defpackage #:arcdocdb.binary
  (:use #:cl)
  (:import-from #:arcdocdb.conditions #:invalid-argument)
  (:export #:octets #:index #:u8 #:u16 #:u32 #:u64 #:check-range
           #:leggi-u16 #:leggi-u32 #:leggi-u64
           #:scrivi-u16 #:scrivi-u32 #:scrivi-u64 #:crc32c))

(defpackage #:arcdocdb.record
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u16 #:u32 #:u64
                #:check-range #:leggi-u16 #:leggi-u32 #:leggi-u64
                #:scrivi-u16 #:scrivi-u32 #:scrivi-u64 #:crc32c)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:unsupported-format #:resource-exhausted #:invariant-violation)
  (:export #:+header-bytes+ #:+max-document-bytes+ #:+max-key-bytes+
           #:+max-record-bytes+ #:+put+ #:+tombstone+ #:+seal+ #:+outcome+
           #:+edit+ #:+decision+ #:+prepared+
           #:scrivi-record #:verifica-cornice #:u64-equal-p
           #:verifica-record #:verifica-put #:verifica-lotto))
