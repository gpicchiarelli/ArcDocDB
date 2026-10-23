;;; OWNER: controller dell'Archivio e compiti I/O di recovery prima dell'ammissione del traffico.
;;; SHARED: decisioni immutabili lette dalle Serie; nessun nuovo registro, lock o CSN globale.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-008
(defpackage #:arcdocdb.recovery.archive
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u16 #:u32 #:u64 #:check-range)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.get #:ambito-get)
  (:import-from #:arcdocdb.io #:file-io #:leggi-esatto #:verifica-capienza-lettura)
  (:import-from #:arcdocdb.storage.format #:+log-header-bytes+ #:+log-identity-bytes+ #:verifica-header-log)
  (:import-from #:arcdocdb.recovery.decisions #:ricostruisci-decisioni #:numero-decisioni
                #:trova-decisione #:partecipante-decisione-p)
  (:export #:archivio-recovery #:crea-archivio-recovery #:decisioni-recuperate
           #:leggi-decisioni-recuperate #:frontiere-decisioni-recuperate
           #:numero-decisioni-recuperate #:trova-decisione-recuperata #:partecipante-decisione-recuperata-p
           #:massimo-csn-decisioni-recuperate
           #:leggi-active-con-decisioni))
