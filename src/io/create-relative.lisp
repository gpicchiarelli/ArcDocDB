;;; OWNER: il compito I/O possiede parent/namespace fino alla pubblicazione del nuovo child append.
;;; SHARED: backend ereditato readonly; nessuna frontiera o stato del parent viene modificato.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (file-io t t t) null) verifica-creazione-relativa))
(defun verifica-creazione-relativa (directory name max-transfer max-file-bytes)
  "Pre: capacita' e configurazione del controller. Post: parent, foglia .tmp, budget e callback ammessi.
IO-FAULT per parent non disponibile; INVALID-ARGUMENT per modo/nome/budget prima di I/O.
UNSUPPORTED-FORMAT senza create-relative, file-metadata ed entry-identity; nessun fallback."
  (esigi-aperto directory :directory)
  (unless (and (typep max-transfer 'index) (<= 1 max-transfer +max-transfer+)
               (typep max-file-bytes 'file-offset) (plusp max-file-bytes))
    (error 'invalid-argument :reason :io-budget))
  (unless (stringp name) (error 'invalid-argument :reason :io-leaf-name))
  (esigi-nome-foglia name)
  (unless (and (>= (length name) 4) (string= name ".tmp" :start1 (- (length name) 4)))
    (error 'invalid-argument :reason :io-temporary-name))
  (let ((backend (file-backend directory)))
    (when (and backend (or (null (backend-create-relative backend))
                          (null (backend-file-metadata backend))
                          (null (backend-entry-identity backend))))
      (error 'unsupported-format :reason :io-create-relative-unavailable)))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (file-io file-io simple-base-string) null) esegui-creazione-relativa))
(defun esegui-creazione-relativa (directory file leaf)
  "Pre: child/foglia preallocati e callback ammessi. Post: child possiede un nuovo FD valido.
FD zero valido; INVARIANT-VIOLATION per risultato invalido/alias parent senza ownership o close.
IO-FAULT per parent indisponibile o syscall normalizzata; handoff protetto dalle interruzioni.
La syscall/callback puo' bloccare nel pool I/O; nessun retry, unlink o flush."
  (esigi-aperto directory :directory)
  (handler-case
      (sb-sys:without-interrupts
        (let* ((backend (file-backend directory))
               (descriptor (if backend
                               (funcall (backend-create-relative backend) (file-fd directory) leaf :append)
                               (native-create-relative (file-fd directory) leaf :append))))
          (unless (typep descriptor 'fd)
            (error 'invariant-violation :reason :io-create-relative-result))
          (when (= descriptor (file-fd directory))
            (error 'invariant-violation :reason :io-create-relative-parent))
          (setf (file-fd file) descriptor)))
    (sb-posix:syscall-error (condition)
      (error 'io-fault :reason :io-syscall :operation :create-relative
             :errno (sb-posix:syscall-errno condition))))
  (esigi-aperto directory :directory)
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (file-io t &key (:max-transfer t) (:max-file-bytes t)) file-io)
                crea-temporaneo-nella-directory))
(defun crea-temporaneo-nella-directory (directory name &key (max-transfer +max-transfer+)
                                                         (max-file-bytes +default-file-limit+))
  "Pre: pool I/O, parent e namespace esclusivi/stabili; nessuna cancellazione asincrona.
Post: un solo child append nuovo, regolare/vuoto, nome legato allo stesso FD; frontiere scritta/durevole zero.
Capacita'/frontiere del parent borrowed invariate, nomi privati e backend ereditato; nessun FD parziale.
INVALID-ARGUMENT/UNSUPPORTED-FORMAT/RESOURCE-EXHAUSTED/IO-FAULT ai rifiuti previsti;
INVARIANT-VIOLATION per risultato FD/metadati impossibile, alias parent, file non vuoto o frontiere incoerenti.
Primaria tipizzata EQ dopo cleanup riuscito; close fallita conserva causa e cleanup-errno come IO-FAULT.
Uscite nonlocali estranee tentano una close senza allegare errno; nessun retry o timeout wall.
Preparazione prima dell'EDIT, senza punto durevole di decisione, flush, rename o unlink:
se la creazione riesce prima di un errore, il .tmp resta da riconciliare dalla fonte autorevole."
  (verifica-creazione-relativa directory name max-transfer max-file-bytes)
  (let* ((leaf (map 'simple-base-string #'identity name))
         (file (%make-file :append (file-backend directory) max-transfer max-file-bytes))
         (complete nil) (primary nil) (cleanup-errno nil) (cleanup-failed nil))
    (unwind-protect
         (handler-case
             (progn
               (esegui-creazione-relativa directory file leaf)
               (multiple-value-bind (device inode size) (leggi-metadati-relativi directory file)
                 (unless (zerop size) (error 'invariant-violation :reason :io-create-relative-nonempty))
                 (verifica-entry-relativa directory file leaf device inode :append :io-create-relative-identity)
                 (esigi-aperto directory :directory)
                 (esigi-aperto file :append)
                 (unless (and (zerop (file-written file)) (zerop (file-durable file)))
                   (error 'invariant-violation :reason :io-create-relative-frontier))
                 (setf complete t)))
           (arcdocdb.conditions:arcdocdb-error (condition) (setf primary condition))
           (sb-posix:syscall-error (condition)
             (setf primary (make-condition 'io-fault :reason :io-syscall :operation :create-relative
                                           :errno (sb-posix:syscall-errno condition)))))
      (unless complete
        (sb-sys:without-interrupts
          (multiple-value-setq (cleanup-errno cleanup-failed) (cleanup-lettura-relativa file)))))
    (segnala-apertura-relativa primary cleanup-errno cleanup-failed :create-relative)
    file))
