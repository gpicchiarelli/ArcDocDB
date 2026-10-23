;;; OWNER: controller prepara il checkpoint; pool I/O possiede capacità e scratch esclusivi.
;;; SHARED: piano immutabile, nessun CSN, catalogo o stato condiviso tra Serie.
;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-008
(defpackage #:arcdocdb.control
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u64 #:check-range)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation
                #:corruption-detected #:resource-exhausted)
  (:import-from #:arcdocdb.storage.format #:+log-header-bytes+ #:+log-identity-bytes+ #:+edit-min-bytes+
                #:+metadata-max-bytes+ #:+edit-complete+ #:scrivi-header-log #:verifica-header-log)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+seal-bytes+ #:+edit+ #:format-limits)
  (:import-from #:arcdocdb.wal #:log-io #:crea-log-io #:crea-lotto #:aggiungi-record
                #:sigilla-lotto #:lunghezza-lotto #:stato-log)
  (:import-from #:arcdocdb.active #:segmento-attivo-preparato)
  (:import-from #:arcdocdb.io #:file-io #:associazione-file #:associa-file
                #:verifica-associazione-file #:verifica-file-distinti #:verifica-capienza-lettura
                #:verifica-capienza-append #:append-esatto #:leggi-esatto #:durable-flush
                #:posizione-scritta #:posizione-durevole #:verifica-capacita-sostituzione #:sostituisci-temporaneo)
  (:import-from #:arcdocdb.recovery.manifest #:ricostruisci-manifest #:segmento-attivo)
  (:export #:checkpoint-control #:crea-checkpoint-control #:lunghezza-checkpoint-control
           #:manifest-checkpoint-control #:control-preparato #:prepara-checkpoint-control
           #:log-control-preparato #:manifest-control-preparato
           #:control-pubblicato #:pubblica-control-recuperato #:stato-pubblicazione-control
           #:log-control-pubblicato #:manifest-control-pubblicato #:active-control-pubblicato
           #:control-recuperato #:leggi-control-recuperato #:frontiere-control-recuperato
           #:manifest-control-recuperato #:pubblica-control-validato))
