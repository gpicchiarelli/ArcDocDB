;;; OWNER: un compito esclusivo prima del primo byte scritto nel temporaneo.
;;; SHARED: sole letture di metadati locali; bridge ai controlli interni I/O, senza FD esportati.
(in-package #:arcdocdb.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-FOR-001 REQ-STO-003
(declaim (ftype (function (vista-get-serie file-io file-io file-io u64 integer octets octets) null)
                verifica-preparazione-attiva))
(defun verifica-preparazione-attiva (view input append directory segment-id version header scratch)
  "Pre: namespace riservato, capacità esclusive e buffer privati. Post: preflight senza effetti I/O.
ID positivo u32, formato noto, due range da 64 byte, nessun alias; append scritto/durevole a zero.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED/IO-FAULT/UNSUPPORTED-FORMAT prima di header e syscall."
  (format-limits version)
  (unless (<= 1 segment-id #xffffffff)
    (error 'invalid-argument :reason :active-initialization-id))
  (when (or (eq header scratch) (eq header (arcdocdb.get::vista-get-serie-identity view))
            (eq scratch (arcdocdb.get::vista-get-serie-identity view)))
    (error 'invalid-argument :reason :active-initialization-alias))
  (check-range header 0 +segment-header-bytes+) (check-range scratch 0 +segment-header-bytes+)
  (verifica-capienza-lettura input +segment-header-bytes+)
  (verifica-capienza-append append +segment-header-bytes+ +segment-header-bytes+)
  (arcdocdb.io::esigi-aperto directory :directory)
  (unless (and (eq (arcdocdb.io::file-backend input) (arcdocdb.io::file-backend append))
               (eq (arcdocdb.io::file-backend input) (arcdocdb.io::file-backend directory)))
    (error 'invalid-argument :reason :active-initialization-backend))
  (unless (and (zerop (posizione-scritta append)) (zerop (posizione-durevole append)))
    (error 'invalid-argument :reason :active-initialization-started))
  nil)

;;; REQ: REQ-AFF-001 REQ-STO-003
(declaim (ftype (function (file-io file-io associazione-file) null) verifica-frontiera-iniziale))
(defun verifica-frontiera-iniziale (input append association)
  "Pre: capacità esclusive e prova dal pool I/O. Post: stesse capacità aperte e solo header durevole.
IO-FAULT/INVALID-ARGUMENT per prova; INVARIANT-VIOLATION per frontiere diverse da 64.
Non verifica il catalogo, un eventuale SEAL o la presenza di altre capacità esterne."
  (verifica-associazione-file association input append)
  (unless (and (= (posizione-scritta append) +segment-header-bytes+)
               (= (posizione-durevole append) +segment-header-bytes+))
    (error 'invariant-violation :reason :active-initialization-frontier))
  nil)
