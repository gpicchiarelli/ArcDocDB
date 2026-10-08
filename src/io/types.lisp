;;;; Capacità locali; nessun descrittore o SAP esportato.
;;; OWNER: il chiamante mantiene il riferimento; un solo compito muta un file.
;;; SHARED: nessuno stato tra Serie; un file readonly ammette pread concorrenti.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008
(deftype fd () '(integer 0 2147483647))
(defconstant +max-file-offset+ most-positive-fixnum)
(deftype file-offset () `(integer 0 ,+max-file-offset+))
(defconstant +max-transfer+ 268435456)
(defconstant +default-file-limit+ #xffffffff)

;;; REQ: REQ-AFF-001 REQ-AFF-008
(defstruct (backend (:constructor make-backend (open reader writer flush directory-flush close))
                    (:copier nil))
  "Pre: funzioni fidate e stabili. Post: tabella immutabile delle chiamate iniettabili.
Open riceve nome/mode; read fd/octets/start/count/offset; write fd/octets/start/count.
Flush/directory-flush/close ricevono fd. Segnalano syscall-error per errno."
  (open #'identity :type function :read-only t)
  (reader #'identity :type function :read-only t)
  (writer #'identity :type function :read-only t)
  (flush #'identity :type function :read-only t)
  (directory-flush #'identity :type function :read-only t)
  (close #'identity :type function :read-only t))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-STO-003
(defstruct (file-io (:constructor %make-file (mode backend max-transfer max-file-bytes))
                   (:conc-name file-) (:copier nil))
  "Pre: configurazione controllata all'apertura. Post: capacità posseduta dal controller.
FD assegnato una volta prima della pubblicazione; chiusura dopo il termine dei reader.
Stato/posizioni cambiano soltanto nel compito proprietario."
  (fd -1 :type (integer -1 2147483647))
  (mode :input :type (member :input :append :directory) :read-only t)
  (backend nil :type (or null backend) :read-only t)
  (max-transfer +max-transfer+ :type index :read-only t)
  (max-file-bytes +default-file-limit+ :type file-offset :read-only t)
  (state :open :type (member :open :faulted :closed))
  (written 0 :type file-offset)
  (durable 0 :type file-offset))

;;; REQ: REQ-AFF-001
(declaim (ftype (function (file-io) (member :open :faulted :closed)) stato-file))
(defun stato-file (file)
  "Pre: capacità posseduta. Post: stato locale osservato, senza modifica o attesa."
  (file-state file))
;;; REQ: REQ-AFF-001
(declaim (ftype (function (file-io) file-offset) posizione-scritta posizione-durevole))
(defun posizione-scritta (file)
  "Pre: lettura da parte del proprietario. Post: byte append noti, anche dopo progresso parziale."
  (file-written file))
;;; REQ: REQ-AFF-001
(defun posizione-durevole (file)
  "Pre: lettura da parte del proprietario. Post: frontiera dell'ultimo flush riuscito."
  (file-durable file))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io keyword keyword &optional (or null fixnum) index) nil)
                fallisci))
(defun fallisci (file operation reason &optional errno (transferred 0))
  "Pre: operazione fallita. Post: write/flush faulted prima di segnalare IO-FAULT.
Read non muta stato: il proprietario gestisce quarantena e durata dei reader."
  (unless (eq operation :read) (setf (file-state file) :faulted))
  (error 'io-fault :reason reason :operation operation :errno errno :transferred transferred))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io (member :input :append :directory)) null) esigi-aperto))
(defun esigi-aperto (file mode)
  "Pre: capacità valida. Post: file aperto e modo esatto; nessuna syscall su rifiuto.
INVALID-ARGUMENT per modo; IO-FAULT per file chiuso/faulted."
  (unless (eq (file-mode file) mode)
    (error 'invalid-argument :reason :io-mode))
  (unless (eq (file-state file) :open)
    (error 'io-fault :reason :io-unavailable :operation mode))
  (unless (typep (file-fd file) 'fd)
    (error 'invariant-violation :reason :io-descriptor))
  nil)
