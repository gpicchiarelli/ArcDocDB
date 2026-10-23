;;; OWNER: compito I/O esclusivo sulla directory e sui nomi riservati dal controller.
;;; SHARED: nessun lock/stato tra Serie; nomi presi in prestito e stabili durante la chiamata.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(defconstant +max-rename-name-bytes+ 255)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (string) null) verifica-nome-rinomina))
(defun verifica-nome-rinomina (name)
  "Pre: nome string stabile. Post: componente ASCII di 1..255 byte, senza slash/NUL o dot/dotdot.
INVALID-ARGUMENT prima di I/O; ciclo limitato a 255 caratteri. Nomi storage canonici ASCII."
  (unless (<= 1 (length name) +max-rename-name-bytes+)
    (error 'invalid-argument :reason :io-rename-name))
  (when (member name '("." "..") :test #'string=)
    (error 'invalid-argument :reason :io-rename-name))
  (dotimes (i (length name))
    (let* ((character (char name i)) (code (char-code character)))
      (unless (and (<= 1 code 127) (char/= character #\/))
        (error 'invalid-argument :reason :io-rename-name))))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io keyword &optional (or null fixnum)) nil) fallisci-rinomina))
(defun fallisci-rinomina (directory reason &optional errno)
  "Pre: effetto fallito. Post: capacità aperta guastata prima di IO-FAULT, chiusa mai riaperta.
Transizione locale protetta dalle interruzioni; nessuna close o sostituzione della causa."
  (sb-sys:without-interrupts
    (when (eq (file-state directory) :open)
      (setf (file-state directory) :faulted)))
  (error 'io-fault :reason reason :operation :rename :errno errno))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io (or null backend) simple-base-string simple-base-string
                          &optional boolean) null)
                esegui-rinomina))
(defun esegui-rinomina (directory backend source destination &optional (exclusive nil))
  "Pre: capacità/preflight verificati e callback presente se iniettato. Post: ritorno POSIX zero.
EXCLUSIVE sceglie solo la primitiva senza sostituzione; mai fallback sulla rinomina ordinaria.
IO-FAULT per syscall/ritorno impossibile; capacità faulted prima della segnalazione, nessun retry."
  (handler-case
      (let ((result (if backend
                        (funcall (if exclusive (backend-rename-exclusive backend) (backend-rename backend))
                                 (file-fd directory) source destination)
                        (if exclusive (native-rename-exclusive (file-fd directory) source destination)
                            (native-replace (file-fd directory) source destination)))))
        (unless (eql result 0) (fallisci-rinomina directory :io-rename-result)))
    (sb-posix:syscall-error (condition)
      (fallisci-rinomina directory :io-syscall (sb-posix:syscall-errno condition))))
  nil)


;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io simple-base-string simple-base-string
                          &optional (or null function) boolean) null) rinomina-con-nomi-privati))
(defun rinomina-con-nomi-privati (directory source destination &optional verify-after (exclusive nil))
  "Pre: foglie private validate, backend/callback ammessi, unico proprietario nel pool I/O.
Post: rename e postcondizione facoltativa completate, capacità ancora aperta.
Qualsiasi uscita incompleta guasta una capacità aperta; mai riapre CLOSED o maschera la causa.
La postcondizione interna restituisce NIL; IO-FAULT se ritorna altro, nessun retry/flush/close.
EXCLUSIVE seleziona la rinomina che rifiuta un target presente, con lo stesso cleanup."
  (esigi-aperto directory :directory)
  (let ((backend (file-backend directory)) (complete nil))
    (unwind-protect
         (progn
           (esegui-rinomina directory backend source destination exclusive)
           (when verify-after
             (unless (null (funcall verify-after))
               (fallisci-rinomina directory :io-rename-post-result)))
           (esigi-aperto directory :directory)
           (setf complete t))
      ;; Solo la transizione locale è protetta: nessuna syscall/attesa in WITHOUT-INTERRUPTS.
      (sb-sys:without-interrupts
        (when (and (not complete) (eq (file-state directory) :open))
          (setf (file-state directory) :faulted)))))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io string string) null) rinomina-nella-directory))
(defun rinomina-nella-directory (directory source destination)
  "Pre: pool I/O, parent aperto esclusivo e namespace riservato; nomi/capacità stabili.
Post: una rinomina POSIX relativa al FD, senza close/flush/mutazione delle frontiere.
Punto atomico: renameat riuscita; fsync del parent è completamento durevole separato.
Non attesta identità/contenuto dei file, EDIT, catalogo o assenza di alias fisici.
INVALID-ARGUMENT/UNSUPPORTED-FORMAT in preflight; IO-FAULT e uscita incompleta => FAULTED.
Il caller riconcilia un esito incerto dalla fonte autorevole, senza retry o rollback qui."
  (esigi-aperto directory :directory)
  (verifica-nome-rinomina source)
  (verifica-nome-rinomina destination)
  (when (string= source destination)
    (error 'invalid-argument :reason :io-rename-same-name))
  (let ((backend (file-backend directory)))
    (when (and backend (null (backend-rename backend)))
      (error 'unsupported-format :reason :io-rename-unavailable)))
  ;; Snapshot bounded prima dell'effetto, anche per stringhe adjustable/displaced/fill-pointer.
  (rinomina-con-nomi-privati directory (map 'simple-base-string #'identity source)
                            (map 'simple-base-string #'identity destination))
  nil)
