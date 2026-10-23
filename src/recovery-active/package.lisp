;;; OWNER: recovery esclusivo della Serie nel pool I/O; capacità, scratch e tabella decisioni stabili.
;;; SHARED: legge la tabella dell'Archivio, senza scritture, lock o nuovi CSN tra Serie.
;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-005 REQ-TXM-007 REQ-AFF-008
(defpackage #:arcdocdb.recovery.active
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:check-range #:leggi-u64
                #:scrivi-u32 #:scrivi-u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.io #:file-io #:leggi-esatto #:verifica-capienza-lettura #:verifica-file-distinti)
  (:import-from #:arcdocdb.get #:segmento-get #:crea-segmento-get)
  (:import-from #:arcdocdb.control #:control-recuperato #:control-preparato #:control-pubblicato
                #:manifest-control-recuperato #:manifest-control-preparato #:pubblica-control-validato)
  (:import-from #:arcdocdb.recovery.manifest #:segmento-attivo #:trova-segmento #:trova-esito-chiusura)
  (:import-from #:arcdocdb.recovery.scan #:scansiona-log)
  (:import-from #:arcdocdb.recovery.decisions #:trova-decisione #:partecipante-decisione-p)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+put+ #:+tombstone+ #:+seal+ #:+outcome+
                #:+prepared+ #:+max-document-bytes+)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+)
  (:export #:active-recuperato #:leggi-active-recuperato #:frontiere-active-recuperato
           #:statistiche-active-recuperato #:segmento-active-recuperato
           #:massimo-csn-active-recuperato
           #:lunghezza-chiusura-active #:scrivi-chiusura-active #:esito-chiusura-active
           #:pubblica-control-da-active))
