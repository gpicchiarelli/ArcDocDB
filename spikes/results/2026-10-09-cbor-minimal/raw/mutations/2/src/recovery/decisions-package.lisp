;;;; Tabella di recovery delle DECISION; nessuna pubblicazione o I/O.
;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008
(defpackage #:arcdocdb.recovery.decisions
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u16 #:u64 #:check-range #:leggi-u64)
  (:import-from #:arcdocdb.conditions
                #:invalid-argument #:corruption-detected #:resource-exhausted #:invariant-violation)
  (:import-from #:arcdocdb.record
                #:+header-bytes+ #:+stamp-offset+ #:+decision+ #:+seal+ #:verifica-cornice)
  (:import-from #:arcdocdb.storage.format
                #:+participant-id-bytes+ #:valida-valore-decision)
  (:import-from #:arcdocdb.recovery.scan #:scansiona-log)
  (:export #:ricostruisci-decisioni #:numero-decisioni #:trova-decisione
           #:partecipante-decisione-p))
