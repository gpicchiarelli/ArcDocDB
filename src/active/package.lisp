;;; OWNER: il controller prepara un nuovo temporaneo nel pool I/O, prima del catalogo.
;;; SHARED: nessuna pubblicazione, token CSN o scrittura condivisa tra Serie.
;;; REQ: REQ-STO-003 REQ-FOR-001 REQ-FOR-002 REQ-AFF-001 REQ-AFF-008
(defpackage #:arcdocdb.active
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:u64 #:check-range)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation #:corruption-detected)
  (:import-from #:arcdocdb.record #:format-limits)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+ #:scrivi-header-segmento)
  (:import-from #:arcdocdb.io #:file-io #:associazione-file #:associa-file #:verifica-associazione-file
                #:verifica-capienza-lettura #:verifica-capienza-append #:append-esatto #:durable-flush
                #:posizione-scritta #:posizione-durevole)
  (:import-from #:arcdocdb.get #:vista-get-serie #:segmento-get #:crea-segmento-get)
  (:import-from #:arcdocdb.wal #:log-io #:crea-log-io)
  (:import-from #:arcdocdb.series #:controllore-serie)
  (:import-from #:arcdocdb.get.resolver #:sorgente-get-attiva #:crea-sorgente-get-attiva)
  (:export #:segmento-attivo-preparato #:prepara-segmento-attivo
           #:log-segmento-attivo-preparato #:crea-sorgente-get-preparata))
