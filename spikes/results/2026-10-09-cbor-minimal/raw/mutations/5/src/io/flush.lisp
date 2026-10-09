;;; OWNER: un compito del pool I/O possiede il file per l'intera chiamata.
;;; SHARED: frontiere locali al file; nessun flush o contatore globale.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-STO-003
(declaim (ftype (function (file-io) file-offset) durable-flush))
(defun durable-flush (file)
  "Pre: file append/directory esclusivo; tutti i byte da coprire già scritti.
Post: una sincronizzazione riuscita, poi frontiera aggiornata. Non è conferma al client.
IO-FAULT => FAULTED senza retry o avanzamento; directory usa fsync, file flush forte."
  (let ((mode (file-mode file)) (backend (file-backend file)))
    (unless (member mode '(:append :directory))
      (error 'invalid-argument :reason :io-flush-mode))
    (esigi-aperto file mode)
    (handler-case
        (let ((result (if (eq mode :directory)
                          (if backend (funcall (backend-directory-flush backend) (file-fd file))
                              (native-directory-flush (file-fd file)))
                          (if backend (funcall (backend-flush backend) (file-fd file))
                              (native-flush (file-fd file))))))
          (unless (eql result 0) (fallisci file :flush :io-flush-result)))
      (sb-posix:syscall-error (c)
        (fallisci file :flush :io-syscall (sb-posix:syscall-errno c))))
    (setf (file-durable file) (file-written file))
    (unless (<= (file-durable file) (file-written file))
      (error 'invariant-violation :reason :io-durable-frontier))
    (file-durable file)))
