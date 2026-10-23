;;; OWNER: inizializzazione; binding OS confinato al modulo I/O.
;;; SHARED: nessuna scrittura condivisa per operazione, nessun checksum foreign.
(in-package #:arcdocdb.io.cpu)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-004
#+(and arm64 darwin)
(sb-alien:define-alien-routine ("sysctlbyname" %sysctl-crc) sb-alien:int
  (name sb-alien:c-string) (output (* sb-alien:unsigned-int))
  (output-size (* sb-alien:unsigned-long))
  (input sb-alien:system-area-pointer) (input-size sb-alien:unsigned-long))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(declaim (ftype (function ((signed-byte 32) (unsigned-byte 64) (unsigned-byte 32)) boolean)
                risposta-crc32c-valida-p))
(defun risposta-crc32c-valida-p (status size flag)
  "Pre: risultato e output inizializzati della syscall. Post: T solo per una conferma valida.
Funzione pura; errore OS, dimensione o valore inatteso => NIL, nessun errore operativo."
  (and (zerop status) (= size 4) (= flag 1)))

;;; REQ: REQ-FOR-003 REQ-AFF-004
(declaim (ftype (function () boolean) crc32c-disponibile-p))
(defun crc32c-disponibile-p ()
  "Pre: inizializzazione, prima dei worker. Post: T solo con feature CRC32C attestata dall'OS.
Errore/risposta inattesa/sistema non qualificato => NIL e fallback software; nessuna modifica DB."
  #+(and arm64 darwin)
  (sb-alien:with-alien ((flag sb-alien:unsigned-int 0) (size sb-alien:unsigned-long 4))
    (let ((status (%sysctl-crc "hw.optional.armv8_crc32" (sb-alien:addr flag)
                             (sb-alien:addr size) (sb-sys:int-sap 0) 0)))
      (risposta-crc32c-valida-p status size flag)))
  #-(and arm64 darwin) nil)
