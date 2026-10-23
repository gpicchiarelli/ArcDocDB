;;; OWNER: un selettore riusabile per worker, una chiave per volta, prima della pubblicazione.
;;; SHARED: nessuno stato, FD, lock o scrittura condivisa fra Serie.
;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-008
(defpackage #:arcdocdb.recovery.selection
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u32 #:u64 #:check-range #:leggi-u32)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  ;; Tipo interno condiviso col sottosistema indice; nessun nuovo formato o accessor pubblico.
  (:import-from #:arcdocdb.index.slots #:contenuto-slot)
  (:import-from #:arcdocdb.record #:verifica-record #:+put+ #:+tombstone+ #:+prepared+
                #:+max-key-bytes+ #:+body-crc-offset+)
  (:export #:selettore-versione-recuperata #:crea-selettore-versione-recuperata
           #:inizializza-chiave-recuperata #:considera-record-recuperato #:leggi-versione-selezionata
           #:materializza-chiave-recuperata))
