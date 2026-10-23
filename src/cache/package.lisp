;;; OWNER: una partizione per Serie; il controller costruisce, i worker cercano/inseriscono.
;;; SHARED: solo array e mutex della Serie; nessuna scrittura comune fra Serie.
;;; REQ: REQ-CCH-001 REQ-CCH-002 REQ-CCH-004
(defpackage #:arcdocdb.cache
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:check-range)
  (:import-from #:arcdocdb.record #:verifica-put-parole #:+header-bytes+
                #:+max-record-bytes+ #:+put+ #:format-limits #:allowed-flags)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:corruption-detected #:unsupported-format)
  (:export #:cache-serie #:crea-cache-serie #:payload-cache-serie
           #:cerca-record-cache #:inserisci-record-cache))
