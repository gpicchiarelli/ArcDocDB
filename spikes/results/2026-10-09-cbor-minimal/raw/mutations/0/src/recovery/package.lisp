;;;; Scansione in memoria dei log; nessuna dipendenza da I/O o replay.
;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-AFF-017 REQ-FOR-003
(defpackage #:arcdocdb.recovery.scan
  (:use #:cl)
  (:import-from #:arcdocdb.binary
                #:octets #:index #:u32 #:u64 #:check-range #:leggi-u64)
  (:import-from #:arcdocdb.conditions
                #:invalid-argument #:corruption-detected #:resource-exhausted
                #:invariant-violation #:error-reason)
  (:import-from #:arcdocdb.record
                #:+header-bytes+ #:+seal-bytes+ #:+seal+ #:+type-offset+
                #:+seal-file-id-offset+ #:+seal-batch-start-offset+
                #:+seal-durable-offset+ #:format-limits #:u64-equal-p
                #:verifica-cornice #:verifica-lotto)
  (:export #:scansiona-log #:log-corruption #:corruption-prefix-end
           #:corruption-witness-offset #:corruption-durable-offset
           #:corruption-first-reason))
