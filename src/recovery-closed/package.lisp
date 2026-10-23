;;; OWNER: compiti I/O di recovery della Serie; CONTROL e file immutabili fino alla pubblicazione.
;;; SHARED: sole letture di capacità e manifest; nessun nuovo CSN, registro o lock tra Serie.
;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-008 REQ-AFF-018
(defpackage #:arcdocdb.recovery.closed
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u32 #:u64 #:check-range #:leggi-u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.io #:file-io #:leggi-esatto #:verifica-capienza-lettura)
  (:import-from #:arcdocdb.control #:control-recuperato #:control-preparato #:control-pubblicato
                #:manifest-control-recuperato)
  (:import-from #:arcdocdb.recovery.manifest #:manifest #:trova-segmento #:trova-esito-chiusura
                #:numero-segmenti-chiusi)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+ #:+segment-max-bytes+
                #:+writer-origin+ #:+compaction-origin+ #:verifica-header-segmento #:verifica-segmento-compattato)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+seal-bytes+ #:verifica-lotto)
  (:import-from #:arcdocdb.recovery.active #:active-recuperato #:pubblica-control-da-active
                #:workspace-active #:workspace-active-prepared #:workspace-active-outcomes #:attraversa-active)
  (:export #:closed-recuperato #:leggi-closed-recuperato #:frontiere-closed-recuperato
           #:massimo-csn-closed-recuperato #:massimo-csn-serie-recuperata
           #:statistiche-closed-recuperato #:verifica-closed-completi #:pubblica-control-con-closed))
