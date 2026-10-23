;;; OWNER: controller della Serie prepara directory immutabili prima dei compiti.
;;; SHARED: radici acquisite sotto EBR; nessuna scrittura per GET o fra Serie.
;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(defpackage #:arcdocdb.get.directory
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index #:u32 #:u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation #:error-reason)
  (:import-from #:arcdocdb.io #:mode-file #:stato-file)
  (:import-from #:arcdocdb.get #:vista-get-serie #:contesto-get #:segmento-get
                #:segmento-get-owner #:segmento-get-file #:segmento-get-high #:segmento-get-low
                #:contesto-get-view #:contesto-get-content #:esigi-stato-get #:guasto-get
                #:abbandona-get #:sonda-cache-get #:leggi-record-get)
  (:import-from #:arcdocdb.get.resolver #:mappa-segmento-get #:mappa-segmento-get-segment
                #:risolvi-candidato-get #:sonda-cache-risolta-get #:leggi-record-risolto-get
                #:sorgente-get-attiva #:radice-get-attiva #:radice-get-attiva-source
                #:sorgente-get-attiva-controller #:sorgente-get-attiva-segment
                #:contenuto-radice-get-attiva #:inizializza-radice-get-attiva #:registra-lotto-get-attivo
                #:risolvi-candidato-radice-attiva-get)
  (:import-from #:arcdocdb.series #:controllore-serie #:leggi-radice-serie)
  (:export #:directory-get-serie #:crea-directory-get-serie #:payload-directory-get-serie
           #:conta-segmenti-directory-get #:trova-mappa-directory-get
           #:risolvi-candidato-directory-get #:sonda-cache-directory-get #:leggi-record-directory-get
           #:fonti-get-serie #:crea-fonti-get-serie #:contenuto-fonti-get-serie
           #:inizializza-fonti-get-attive #:registra-lotto-fonti-get-attivo #:risolvi-candidato-serie-get
           #:sonda-cache-serie-get #:leggi-record-serie-get))
