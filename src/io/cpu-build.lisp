;;; OWNER: bootstrap ASDF/loader standalone, prima di compilare o avviare worker.
;;; SHARED: modifica della sola feature di compilazione durante il bootstrap.
(in-package #:arcdocdb.io.cpu)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(declaim (ftype (function (list string) boolean) compilatore-crc32c-qualificato-p))
(defun compilatore-crc32c-qualificato-p (features version)
  "Pre: feature del runtime e versione SBCL. Post: T solo per il compilatore qualificato.
Funzione pura, nessun probing CPU; combinazioni ignote/disabilitate => NIL, nessun errore."
  (and (member :sbcl features) (member :arm64 features) (member :darwin features)
       (member :64-bit features) (member :little-endian features)
       (string= version "2.6.9") (not (member :arcdocdb-crc32c-software features)) t))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(declaim (ftype (function () null) configura-compilatore-crc32c))
(defun configura-compilatore-crc32c ()
  "Pre: bootstrap, nessun worker. Post: feature privata coerente col runtime corrente.
Non attesta CRC32C della CPU; rimuove feature obsolete, nessun errore operativo."
  (setf *features* (remove :arcdocdb-crc32c-arm64 *features*))
  (when (compilatore-crc32c-qualificato-p *features* (lisp-implementation-version))
    (pushnew :arcdocdb-crc32c-arm64 *features*))
  nil)

(eval-when (:load-toplevel :execute)
  (configura-compilatore-crc32c))
