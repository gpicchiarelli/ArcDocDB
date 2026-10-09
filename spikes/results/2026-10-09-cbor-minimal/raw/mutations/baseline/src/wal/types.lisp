;;; OWNER: writer del lotto; compito I/O del log; nessun riuso con consumatori attivi.
;;; SHARED: stato locale al log; CAS locale per gruppo, mai tra Serie.
(in-package #:arcdocdb.wal)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-WAL-005
(defconstant +seal-total+ (+ +header-bytes+ +seal-bytes+))
(defconstant +max-lotto-bytes+ 67108864)
(defconstant +max-lotto-records+ 65536)
(defconstant +max-group-lots+ 1024)
(deftype log-kind () '(member :segment :control :multiserie))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(defstruct (log-io (:constructor %make-log-io (file kind file-id version)) (:copier nil))
  "Pre: capacità append posseduta esclusivamente dal log. Post: log aperto.
Un gruppo in volo tramite CAS; nessun lock o contatore globale."
  (file nil :type file-io :read-only t)
  (kind :segment :type log-kind :read-only t) (file-id 0 :type u64 :read-only t)
  (version 2 :type (integer 1 2) :read-only t)
  (state :open :type (member :open :faulted))
  (active nil :type t))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(defstruct (lotto (:constructor %make-lotto (kind file-id version buffer offsets seal-value empty-key))
                 (:copier nil))
  "Pre: buffer privati preallocati. Post: lotto aperto con budget finiti.
Il writer è proprietario fino a chiusura; dopo, niente mutazione fino al riuso esclusivo."
  (kind :segment :type log-kind :read-only t)
  (file-id 0 :type u64 :read-only t)
  (version 2 :type (integer 1 2) :read-only t)
  (buffer #() :type octets :read-only t)
  (offsets #() :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (seal-value #() :type octets :read-only t)
  (empty-key #() :type octets :read-only t)
  (used 0 :type index) (count 0 :type u32) (start 0 :type file-offset)
  (owner nil :type t)
  (csn-registry nil :type (or null registro-csn))
  (csn-log nil :type (or null log-io))
  (csn-slot 0 :type index) (csn-high 0 :type u32) (csn-low 0 :type u32)
  (csn-pending nil :type boolean)
  (state :open :type (member :open :sealed :written :durable :faulted)))

;;; REQ: REQ-WAL-002 REQ-AFF-008
(defstruct (gruppo (:constructor %make-gruppo (log slots max-bytes)) (:copier nil))
  "Pre: slots preallocati. Post: gruppo vuoto, riutilizzabile solo senza consumatori.
Preparazione del writer; write/flush del compito I/O, mai del pool di calcolo."
  (log nil :type log-io :read-only t) (slots #() :type simple-vector :read-only t)
  (max-bytes 0 :type index :read-only t)
  (count 0 :type index) (bytes 0 :type index) (start 0 :type file-offset)
  (state :building :type (member :building :ready :writing :written :flushing :durable :faulted)))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (log-kind u64 integer) null) configurazione-log))
(defun configurazione-log (kind file-id version)
  "Pre: configurazione esplicita. Post: layout noto, identificativo coerente.
INVALID-ARGUMENT per file-id di controllo non zero; UNSUPPORTED-FORMAT per versione."
  (format-limits version)
  (unless (or (eq kind :segment) (zerop file-id))
    (error 'invalid-argument :reason :control-file-id))
  nil)

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (log-kind u64 &key (:version integer) (:capacity integer)
                          (:max-records integer)) lotto) crea-lotto))
(defun crea-lotto (kind file-id &key (version 2) (capacity 262144) (max-records 1024))
  "Pre: budget finiti. Post: buffer e offset privati allocati una volta.
INVALID-ARGUMENT per budget; nessun file creato, nessun punto di commit."
  (configurazione-log kind file-id version)
  (unless (and (<= +seal-total+ capacity +max-lotto-bytes+)
               (<= 1 max-records +max-lotto-records+))
    (error 'invalid-argument :reason :lotto-budget))
  (let ((seal (make-array +seal-bytes+ :element-type '(unsigned-byte 8) :initial-element 0)))
    ;; File-id immutabile: codifica una volta, senza boxing dal raw slot u64 alla chiusura.
    (scrivi-u64 seal +seal-file-id-offset+ file-id)
    (%make-lotto kind file-id version
                 (make-array capacity :element-type '(unsigned-byte 8) :initial-element 0)
                 (make-array max-records :element-type '(unsigned-byte 32) :initial-element 0)
                 seal (make-array 0 :element-type '(unsigned-byte 8)))))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(declaim (ftype (function (file-io log-kind u64 &key (:version integer)) log-io) crea-log-io))
(defun crea-log-io (file kind file-id &key (version 2))
  "Pre: file append esclusivo, nessun altro wrapper/proprietario. Post: log I/O aperto.
INVALID-ARGUMENT per capacità/mode; non pubblica il file e non esegue syscall."
  (configurazione-log kind file-id version)
  (unless (and (eq (stato-file file) :open) (eq (mode-file file) :append))
    (error 'invalid-argument :reason :log-file))
  (%make-log-io file kind file-id version))

;;; REQ: REQ-WAL-002 REQ-AFF-008
(declaim (ftype (function (log-io &key (:max-lots integer) (:max-bytes integer)) gruppo) crea-gruppo))
(defun crea-gruppo (log &key (max-lots 64) (max-bytes +max-lotto-bytes+))
  "Pre: budget finiti. Post: gruppo preallocato, senza I/O né modifica del log.
INVALID-ARGUMENT per configurazione; limite dei byte applicato prima di accodare."
  (unless (and (<= 1 max-lots +max-group-lots+) (<= +seal-total+ max-bytes +max-lotto-bytes+))
    (error 'invalid-argument :reason :group-budget))
  (%make-gruppo log (make-array max-lots :initial-element nil) max-bytes))
