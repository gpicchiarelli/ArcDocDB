;;; OWNER: un writer logico per banco della Serie; reader con buffer privato preallocato.
;;; SHARED: solo dati della Serie, nessun lock o contatore comune tra Serie.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-004 REQ-LIM-001 REQ-AFF-008
(defpackage #:arcdocdb.index.slots
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:u64)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+max-record-bytes+ #:+max-document-bytes+)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:export #:banco-slot #:crea-banco-slot #:leggi-slot-v2 #:pubblica-slot-v2
           #:rimuovi-slot-v2 #:riloca-slot-v2 #:credito-scrittura-slot
           #:congela-banco-slot #:invalida-banco-slot))
