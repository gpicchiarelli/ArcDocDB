;;; OWNER: recovery esclusivo della Serie, prima di preparare il nuovo control log.
;;; SHARED: letture di manifest immutabili, nessun nuovo registro, lock, CSN o gettone di pubblicazione.
;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-AFF-008 REQ-AFF-018
(defpackage #:arcdocdb.recovery.checkpoint
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u32 #:u64 #:check-range #:scrivi-u32 #:scrivi-u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.active #:segmento-attivo-preparato)
  (:import-from #:arcdocdb.control #:checkpoint-control #:crea-checkpoint-control #:manifest-checkpoint-control)
  (:import-from #:arcdocdb.recovery.active #:active-recuperato #:lunghezza-chiusura-active #:scrivi-chiusura-active)
  (:import-from #:arcdocdb.recovery.manifest #:numero-segmenti-chiusi #:numero-segmenti-rimossi
                #:prossimo-id-segmento #:trova-segmento #:trova-esito-chiusura #:verifica-transizione-recovery)
  (:import-from #:arcdocdb.storage.format #:+metadata-max-bytes+ #:+edit-min-bytes+
                #:+closed-fixed-bytes+ #:+closed-valid-bytes-offset+ #:+closed-outcome-count-offset+
                #:+closure-outcome-bytes+ #:+removed-id-bytes+ #:scrivi-valore-edit)
  (:export #:crea-checkpoint-da-active))
