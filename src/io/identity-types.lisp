;;; OWNER: il controller associa capacità prima della pubblicazione, nel pool I/O.
;;; SHARED: associazione immutabile; nessun FD o metadato nativo esposto ai reader.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
;; Mantiene il valore POSIX esatto, compreso dev_t firmato; nessuna normalizzazione.
(deftype identity-component () '(or (signed-byte 64) (unsigned-byte 64)))

;;; REQ: REQ-AFF-001 REQ-FOR-001
(defstruct (associazione-file (:constructor %make-associazione-file (input append)) (:copier nil))
  "Pre: due capacità aperte dello stesso backend e identità POSIX esatta verificata.
Post: associazione immutabile delle capacità, non dei numeri FD o dei nomi.
Valida finché entrambe restano aperte; non autorizza close, reclaim o durability."
  (input nil :type file-io :read-only t)
  (append nil :type file-io :read-only t))

