;;; OWNER: caricamento del sistema, prima di avviare worker.
;;; SHARED: rilevamento cold soltanto; nessuno stato o syscall per richiesta.
;;; REQ: REQ-FOR-003 REQ-AFF-004
(defpackage #:arcdocdb.io.cpu
  (:use #:cl) (:export #:crc32c-disponibile-p))
