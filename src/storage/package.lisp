;;;; Metadati dello storage: nessuna applicazione, I/O o decisione di commit.
;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-008
(defpackage #:arcdocdb.storage.format
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u16 #:u32 #:u64
                #:check-range #:leggi-u16 #:leggi-u32 #:scrivi-u16 #:scrivi-u32
                #:scrivi-u64 #:crc32c)
  (:import-from #:arcdocdb.record #:verifica-cornice #:u64-equal-p #:+edit+ #:+decision+
                #:+header-bytes+)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:unsupported-format #:resource-exhausted #:invariant-violation)
  (:export #:+segment-header-bytes+ #:scrivi-header-segmento #:verifica-header-segmento
           #:+log-header-bytes+ #:scrivi-header-log #:verifica-header-log
           #:valida-valore-edit #:valida-valore-decision
           #:verifica-record-edit #:verifica-record-decision
           #:scrivi-valore-edit #:scrivi-valore-decision))
