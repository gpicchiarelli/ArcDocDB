;;; OWNER: compito I/O esclusivo; caller mantiene capacità e file anche in caso di errore.
;;; SHARED: nessuna pubblicazione; manifest e piano privati, senza CSN condivisi.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-REC-001 REQ-FOR-003
(declaim (ftype (function (checkpoint-control file-io file-io file-io associazione-file) null)
                verifica-control-completo))
(defun verifica-control-completo (plan input append directory association)
  "Pre: scrittura/flush/rilettura/fsync parent completati. Post: dipendenze aperte e frontiere esatte.
IO-FAULT/INVALID-ARGUMENT dalle capacità; INVARIANT-VIOLATION per frontiere interne.
Non attesta la rinomina di control.log.tmp, il catalogo o una decisione dei documenti."
  (verifica-associazione-file association input append)
  (arcdocdb.io::esigi-aperto directory :directory)
  (verifica-active-checkpoint (checkpoint-control-active plan))
  (unless (= (posizione-scritta append) (posizione-durevole append) (lunghezza-checkpoint-control plan))
    (error 'invariant-violation :reason :control-checkpoint-frontier))
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (checkpoint-control file-io file-io file-io octets &key (:chunk-bytes index))
                         control-preparato)
                prepara-checkpoint-control))
(defun prepara-checkpoint-control (plan input append directory scratch &key (chunk-bytes 65536))
  "Pre: pool I/O, nuovo control.log.tmp O_EXCL, parent autorevole e startup esclusivo.
Post: file canonico scritto e durevole, riletto esattamente uguale, fsync del parent.
Restituisce log CONTROL e manifest completi; nessuna rinomina/adozione o conferma al client.
Guasti tipizzati propagati senza retry/rollback/close; caller fa quarantena/cleanup.
Punto di atomicità del recovery resta la futura rinomina del control log, secondo ADR-0040."
  (verifica-preparazione-control plan input append directory scratch chunk-bytes)
  (let* ((association (associa-file input append))
         (log (crea-log-io append :control 0 :version (checkpoint-control-version plan)))
         (size (lunghezza-checkpoint-control plan)))
    (verifica-file-distinti input (input-active-checkpoint (checkpoint-control-active plan)))
    (scrivi-checkpoint-control plan append chunk-bytes)
    (unless (= (durable-flush append) size)
      (error 'invariant-violation :reason :control-checkpoint-flush))
    (rileggi-checkpoint-control plan input scratch chunk-bytes)
    (unless (zerop (durable-flush directory))
      (error 'invariant-violation :reason :control-checkpoint-directory))
    (verifica-control-completo plan input append directory association)
    (%make-control-preparato log (checkpoint-control-manifest plan) (checkpoint-control-active plan)
                            association directory size)))
