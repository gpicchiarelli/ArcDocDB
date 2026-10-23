;;; OWNER: vista della Serie immutabile; un contesto esclusivo per worker e Archivio.
;;; SHARED: indice/cache della Serie ed EBR/snapshot; nessuna coda o metrica centrale.
;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-MVC-001 REQ-CON-004 REQ-AFF-008
(defpackage #:arcdocdb.get
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:check-range #:leggi-u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+outcome-bytes+ #:+prepared+
                #:+put+ #:+outcome+ #:+max-key-bytes+ #:+max-record-bytes+
                #:allowed-flags #:format-limits #:verifica-cornice #:verifica-put-parole)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+ #:+segment-max-bytes+
                #:+serie-id-bytes+ #:+compaction-origin+ #:verifica-header-segmento)
  (:import-from #:arcdocdb.io #:file-io #:mode-file #:stato-file #:leggi-esatto)
  (:import-from #:arcdocdb.index.primary #:indice-primario #:contesto-indice
                #:crea-contesto-indice #:leggi-indice-primario #:digest-chiave-indice)
  (:import-from #:arcdocdb.cache #:cache-serie #:cerca-record-cache #:inserisci-record-cache)
  (:import-from #:arcdocdb.epochs #:registro-epoche #:contesto-epoca)
  (:import-from #:arcdocdb.mvcc #:registro-snapshot #:contesto-snapshot)
  (:import-from #:arcdocdb.read #:contesto-lettura #:crea-contesto-lettura
                #:stato-contesto-lettura #:avvia-lettura #:copia-limite-lettura
                #:concludi-lettura #:abbandona-lettura)
  (:export #:ambito-get #:crea-ambito-get #:vista-get-serie #:crea-vista-get-serie
           #:segmento-get #:crea-segmento-get
           #:contesto-get #:crea-contesto-get #:payload-contesto-get #:stato-contesto-get
           #:avvia-get #:copia-candidato-get #:sonda-cache-get #:leggi-record-get
           #:copia-valore-get #:concludi-get #:abbandona-get))
