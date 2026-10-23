;;; OWNER: controller associa manifest, vista e file CLOSED della stessa Serie.
;;; SHARED: mappe immutabili sotto EBR; nessuna scrittura condivisa sul GET.
;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CMP-007 REQ-AFF-008
(defpackage #:arcdocdb.get.resolver
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:leggi-u32 #:check-range)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+put+ #:+tombstone+
                #:+outcome+ #:+seal+ #:+prepared+ #:+stamp-offset+ #:+max-document-bytes+
                #:verifica-cornice #:verifica-lotto #:allowed-flags #:checked-header)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+
                #:+segment-max-bytes+ #:+writer-origin+ #:+compaction-origin+
                #:verifica-segmento-compattato)
  (:import-from #:arcdocdb.io #:file-io #:leggi-esatto #:mode-file #:stato-file)
  (:import-from #:arcdocdb.io #:associazione-file #:verifica-associazione-file)
  (:import-from #:arcdocdb.recovery.manifest #:manifest #:trova-segmento)
  ;; Ponte locale: soltanto l'adozione/pubblicazione esistente rende leggibile la radice ACTIVE.
  (:import-from #:arcdocdb.series #:controllore-serie #:commit-serie
                #:inizializza-radice-serie #:registra-commit-serie #:leggi-radice-serie)
  (:import-from #:arcdocdb.wal #:lotto #:inizio-lotto #:lunghezza-lotto
                #:verifica-ritiro-lotto #:leggi-csn-lotto #:verifica-log-segmento)
  ;; Interfacce interne del nucleo GET: stesso contratto e dominio EBR, senza duplicarlo.
  (:import-from #:arcdocdb.get #:vista-get-serie #:segmento-get #:contesto-get
                #:crea-segmento-get #:segmento-get-owner #:segmento-get-file
                #:segmento-get-low #:segmento-get-high #:segmento-get-origin
                #:segmento-get-version #:vista-get-serie-identity
                #:contesto-get-view #:contesto-get-content #:esigi-stato-get
                #:guasto-get #:verifica-target-get #:verifica-prova-target-get
                #:abbandona-get #:sonda-cache-get #:leggi-record-get)
  (:export #:mappa-segmento-get #:crea-mappa-segmento-get #:payload-mappa-segmento-get
           #:risolvi-candidato-get #:sonda-cache-risolta-get #:leggi-record-risolto-get
           #:sorgente-get-attiva #:crea-sorgente-get-attiva #:radice-get-attiva
           #:inizializza-radice-get-attiva
           #:verifica-capienza-get-attiva #:registra-lotto-get-attivo
           #:contenuto-radice-get-attiva #:payload-radice-get-attiva
           #:risolvi-candidato-radice-attiva-get
           #:risolvi-candidato-attivo-get #:sonda-cache-attiva-get #:leggi-record-attivo-get))
