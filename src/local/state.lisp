;;; OWNER: unico attore del servizio; client e connessioni non trasferibili fra thread.
;;; SHARED: nessun pool o contatore globale, buffer finiti per handle.
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(define-condition request-rejected (arcdocdb.conditions:arcdocdb-error)
  ((status :initarg :status :reader rejection-status :type (integer 1 5))))
(define-condition outcome-unknown (arcdocdb.conditions:arcdocdb-error)
  ((cause :initarg :cause :reader unknown-cause :type condition)))
(define-condition local-cleanup-error (arcdocdb.conditions:arcdocdb-error)
  ((primary :initarg :primary :reader local-primary :type (or null condition))
   (failures :initarg :failures :reader local-failures :type list)))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun local-buffer ()
  "Pre: inizializzazione fredda. Post: buffer esclusivo per prefisso e corpo M1."
  (make-array 65540 :element-type '(unsigned-byte 8) :initial-element 0))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(defun local-now (clock)
  "Pre: clock fidato monotono del caller. Post: tick u64 verificato."
  (let ((now (funcall clock)))
    (unless (typep now '(unsigned-byte 64))
      (error 'arcdocdb.conditions:invalid-argument :reason :local-clock))
    now))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun local-until (now seconds)
  "Pre: NOW tick verificato e durata fissa. Post: deadline assoluta senza wrap."
  (let ((until (+ now (* seconds internal-time-units-per-second))))
    (unless (typep until '(unsigned-byte 64))
      (error 'arcdocdb.conditions:resource-exhausted :reason :local-deadline-overflow))
    until))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(defstruct (local-connection (:constructor make-local-connection) (:copier nil))
  "Buffer preallocati prima del listener, socket e offsets dell'attore soltanto."
  socket
  (io-backend nil :read-only t)
  (input (local-buffer) :read-only t)
  (output (local-buffer) :read-only t)
  (value (make-array 60000 :element-type '(unsigned-byte 8) :initial-element 0) :read-only t)
  (space (arcdocdb.cbor:crea-spazio-cbor) :read-only t)
  (state :closed :type (member :closed :hello :welcome :request :response))
  (received 0 :type b:index)
  (needed 4 :type b:index)
  (written 0 :type b:index)
  (size 0 :type b:index)
  (limit 4096 :type (integer 4096 65536))
  (last-id 0 :type b:u64)
  (deadline 0 :type b:u64)
  (idle 0 :type b:u64)
  (frame-started nil :type boolean))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(defstruct (local-client (:constructor make-local-client) (:copier nil))
  "Handle seriale; una richiesta in volo e nessun retry dopo perdita della risposta."
  socket
  (io-backend nil :read-only t)
  (owner sb-thread:*current-thread* :read-only t)
  (clock #'get-internal-real-time :type function :read-only t)
  (input (local-buffer) :read-only t)
  (output (local-buffer) :read-only t)
  (space (arcdocdb.cbor:crea-spazio-cbor) :read-only t)
  (limit 65536 :type (integer 4096 65536))
  (next-id 1 :type (integer 1 18446744073709551616))
  (state :connecting :type (member :connecting :ready :busy :closed)))
