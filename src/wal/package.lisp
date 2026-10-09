;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-WAL-006 REQ-AFF-001 REQ-AFF-008
(defpackage #:arcdocdb.wal
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:scrivi-u32 #:scrivi-u64 #:crc32c)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+seal-bytes+ #:+stamp-offset+
                #:+body-crc-offset+ #:+header-crc-bytes+ #:+type-offset+ #:+flags-offset+
                #:+put+ #:+tombstone+ #:+edit+ #:+seal+ #:format-limits #:log-record-p #:scrivi-record #:scrivi-record-parole)
  (:import-from #:arcdocdb.record #:+seal-file-id-offset+ #:+seal-batch-start-offset+
                #:+seal-durable-offset+ #:+seal-count-offset+ #:+seal-checksum-offset+)
  (:import-from #:arcdocdb.io #:file-io #:file-offset #:mode-file #:stato-file
                #:posizione-scritta #:posizione-durevole #:append-esatto #:durable-flush
                #:verifica-capienza-append)
  (:import-from #:arcdocdb.csn #:registro-csn #:prendi-csn #:risolvi-csn)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation
                #:resource-exhausted #:io-fault)
  (:export #:lotto #:crea-lotto #:aggiungi-record #:sigilla-lotto #:riusa-lotto
           #:stato-lotto #:lunghezza-lotto #:inizio-lotto
           #:sigilla-lotto-con-csn #:stato-csn-lotto #:leggi-csn-lotto
           #:risolvi-lotto-pubblicato #:annulla-csn-lotto
           #:log-io #:crea-log-io #:stato-log
           #:gruppo #:crea-gruppo #:aggiungi-lotto #:chiudi-gruppo #:riusa-gruppo #:annulla-gruppo
           #:scrivi-gruppo #:sincronizza-gruppo #:esegui-gruppo #:stato-gruppo #:coperto-p))
