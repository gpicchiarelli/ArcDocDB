;;;; Trasferimenti esatti senza retry degli errori; completare short I/O non è un retry.
;;; OWNER: input stabile per append, output esclusivo per read; controller mantiene il FD.
;;; SHARED: read non scrive nella capacità; append ha un solo proprietario per file.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008
(declaim (ftype (function (file-io octets index index) index) regione))
(defun regione (file buffer start end)
  "Pre: buffer e range del chiamante. Post: range e numero byte entro budget.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED prima di qualsiasi syscall."
  (check-range buffer start end)
  (let ((count (- end start)))
    (when (> count (file-max-transfer file))
      (error 'resource-exhausted :reason :io-byte-budget :offset start))
    count))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (file-io t index keyword index) index) progresso))
(defun progresso (file result remaining operation transferred)
  "Pre: result della syscall. Post: progresso positivo entro remaining.
IO-FAULT per zero/ritorno impossibile; mutazione dello stato soltanto per write."
  (unless (and (integerp result) (<= 1 result remaining))
    (fallisci file operation (if (eql result 0)
                                (if (eq operation :read) :io-eof :io-no-progress)
                                :io-invalid-progress)
              nil transferred))
  result)

;;; REQ: REQ-STO-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (file-io octets index index file-offset) index) leggi-esatto))
(defun leggi-esatto (file buffer start end offset)
  "Pre: file readonly mantenuto vivo, buffer esclusivo. Post: intero range riempito, fine.
Budget/offset prima della syscall; IO-FAULT con progresso noto, nessuna lettura parziale resa.
Non verifica CRC: il caller passa i byte al codec prima di rispondere al client."
  (esigi-aperto file :input)
  (let ((count (regione file buffer start end)) (done 0) (backend (file-backend file)))
    (when (> count (- +max-file-offset+ offset))
      (error 'invalid-argument :reason :io-offset :offset offset))
    (handler-case
        (loop repeat count until (= done count)
              do (let* ((remaining (- count done))
                        (n (if backend
                               (funcall (backend-reader backend) (file-fd file) buffer
                                        (+ start done) remaining (+ offset done))
                               (native-read (file-fd file) buffer (+ start done)
                                            remaining (+ offset done)))))
                   (incf done (progresso file n remaining :read done))))
      (sb-posix:syscall-error (c)
        (fallisci file :read :io-syscall (sb-posix:syscall-errno c) done)))
    (unless (= done count) (error 'invariant-violation :reason :io-incomplete-read))
    end))

;;; REQ: REQ-STO-003 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (file-io octets index index) file-offset) append-esatto))
(defun append-esatto (file buffer start end)
  "Pre: un compito possiede file e input stabile. Post: tutto il range scritto in append.
Restituisce posizione scritta, non commit. Guasto => FAULTED, posizione durevole invariata.
Budget/range rifiutati prima di scrivere; nessun error retry, inclusi EINTR/ENOSPC."
  (esigi-aperto file :append)
  (let ((count (regione file buffer start end)) (done 0) (backend (file-backend file)))
    (when (> count (- (file-max-file-bytes file) (file-written file)))
      (error 'resource-exhausted :reason :io-file-budget))
    (handler-case
        (loop repeat count until (= done count)
              do (let* ((remaining (- count done))
                        (n (if backend
                               (funcall (backend-writer backend) (file-fd file) buffer
                                        (+ start done) remaining)
                               (native-write (file-fd file) buffer (+ start done) remaining)))
                        (progress (progresso file n remaining :write done)))
                   (incf done progress)
                   (incf (file-written file) progress)))
      (sb-posix:syscall-error (c)
        (fallisci file :write :io-syscall (sb-posix:syscall-errno c) done)))
    (unless (= done count) (error 'invariant-violation :reason :io-incomplete-write))
    (file-written file)))
