;;;; Cornice binaria degli indici invertiti; nessuna analisi testuale o I/O.
;;; REQ: REQ-SEC-008
(defpackage #:arcdocdb.fulltext.format
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u16 #:u32 #:u64
                #:leggi-u16 #:leggi-u32 #:leggi-u64
                #:scrivi-u16 #:scrivi-u32 #:scrivi-u64 #:crc32c)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:unsupported-format #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.record #:u64-equal-p)
  (:export #:scrivi-cornice-indice-full-text #:verifica-cornice-indice-full-text))
