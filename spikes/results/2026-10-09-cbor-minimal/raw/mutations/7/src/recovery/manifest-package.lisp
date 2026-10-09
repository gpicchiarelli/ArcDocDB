;;;; Ricostruzione in memoria del manifest dal prefisso EDIT sigillato.
;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-STO-006
(defpackage #:arcdocdb.recovery.manifest
  (:use #:cl)
  (:import-from #:arcdocdb.binary
                #:octets #:index #:u8 #:u32 #:u64 #:check-range #:leggi-u32 #:leggi-u64)
  (:import-from #:arcdocdb.conditions
                #:invalid-argument #:corruption-detected #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+edit+ #:+seal+ #:verifica-cornice)
  (:import-from #:arcdocdb.storage.format
                #:+segment-header-bytes+ #:+segment-max-bytes+
                #:+edit-next-id-offset+ #:+edit-open-offset+ #:+edit-complete+
                #:+closed-fixed-bytes+ #:+closed-valid-bytes-offset+
                #:+closed-outcome-count-offset+ #:+closure-outcome-bytes+
                #:+removed-id-bytes+ #:+count-bytes+ #:+metadata-max-bytes+
                #:valida-valore-edit)
  (:import-from #:arcdocdb.recovery.scan #:scansiona-log)
  (:export #:ricostruisci-manifest #:segmento-attivo #:prossimo-id-segmento
           #:numero-segmenti-chiusi #:numero-segmenti-rimossi
           #:trova-segmento #:trova-esito-chiusura))
