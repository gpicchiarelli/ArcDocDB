;;; OWNER: un compito del pool I/O possiede il file per l'intera chiamata.
;;; SHARED: frontiere locali al file; nessun flush o contatore globale.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-STO-003
(declaim (ftype (function (file-io) file-offset) durable-flush))
(defun durable-flush (file)
  "Pre: file append/directory esclusivo; tutti i byte da coprire già scritti.
Post: una sincronizzazione riuscita, capacità aperta, frontiera osservata aggiornata.
Uscita incompleta => OPEN diventa FAULTED, CLOSED resta chiusa; condizione originale propagata.
Nessun retry o conferma al client; directory usa fsync, file flush forte."
  (let ((mode (file-mode file)) (backend (file-backend file))
        (written (file-written file)) (complete nil))
    (unless (member mode '(:append :directory))
      (error 'invalid-argument :reason :io-flush-mode))
    (esigi-aperto file mode)
    (unwind-protect
         (progn
           (handler-case
               (let ((result (if (eq mode :directory)
                                 (if backend (funcall (backend-directory-flush backend) (file-fd file))
                                     (native-directory-flush (file-fd file)))
                                 (if backend (funcall (backend-flush backend) (file-fd file))
                                     (native-flush (file-fd file))))))
                 (unless (eql result 0) (fallisci file :flush :io-flush-result)))
             (sb-posix:syscall-error (c)
               (fallisci file :flush :io-syscall (sb-posix:syscall-errno c))))
           (esigi-aperto file mode)
           (unless (= written (file-written file))
             (error 'invariant-violation :reason :io-flush-frontier))
           (setf (file-durable file) written complete t)
           written)
      ;; Soltanto la transizione di stato: nessuna syscall o attesa nella sezione protetta.
      (sb-sys:without-interrupts
        (when (and (not complete) (eq (file-state file) :open))
          (setf (file-state file) :faulted))))))
