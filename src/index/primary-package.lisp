;;; OWNER: un indice per Serie; writer esclusivo, scratch privato per worker.
;;; SHARED: root immutabile, controlli byte, arena in aggiunta, payload sotto seqlock.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-007 REQ-AFF-008
(defpackage #:arcdocdb.index.primary
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:u32 #:u64 #:check-range)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  ;; Il tentativo singolo è interno al sottosistema indice: niente retry annidati.
  (:import-from #:arcdocdb.index.slots
                #:banco-slot #:contenuto-slot #:crea-banco-slot #:banco-slot-capacity
                #:banco-slot-health #:esigi-banco-sano #:esigi-banco-writer #:base-slot
                #:esigi-contenuto-slot #:tenta-lettura-slot #:credito-scrittura-slot
                #:pubblica-slot-v2 #:rimuovi-slot-v2 #:congela-banco-slot #:invalida-banco-slot)
  (:export #:indice-primario #:frammento-indice #:contesto-indice #:pubblicazione-indice
           #:crea-indice-primario #:crea-frammento-indice #:crea-contesto-indice
           #:leggi-indice-primario #:frammento-corrente-indice #:pubblica-chiave-indice
           #:rimuovi-chiave-indice #:riloca-chiave-indice #:estendi-arena-indice #:prepara-directory-indice
           #:pubblica-directory-indice #:invalida-indice-primario))
