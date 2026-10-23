;;; OWNER: associazione prima dei compiti; il controller conserva i FD fino a quiescenza.
;;; SHARED: confronto di riferimenti immutabili, nessuna scrittura condivisa.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-FOR-001
(declaim (ftype (function (file-io) (values identity-component identity-component &optional))
                leggi-identita-file))
(defun leggi-identita-file (file)
  "Pre: file aperto, backend nativo o callback identity presente, FD stabile.
Post: due interi POSIX senza troncamento; nessuna mutazione del file o retry.
IO-FAULT per syscall; INVARIANT-VIOLATION per risultato del callback fuori contratto."
  (handler-case
      (multiple-value-bind (device inode)
          (let ((backend (file-backend file)))
            (if backend (funcall (backend-identity backend) (file-fd file))
                (native-identity (file-fd file))))
        (unless (and (typep device 'identity-component) (typep inode 'identity-component))
          (error 'invariant-violation :reason :io-identity-result))
        (values device inode))
    (sb-posix:syscall-error (condition)
      (error 'io-fault :reason :io-syscall :operation :identity
             :errno (sb-posix:syscall-errno condition)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
(declaim (ftype (function (file-io file-io) associazione-file) associa-file))
(defun associa-file (input append)
  "Pre: controller esclusivo nel pool I/O, capacità readonly/append senza close concorrente.
Post: associazione dello stesso file regolare, due fstat/callback al massimo, senza retry.
INVALID-ARGUMENT per modo/backend/identità diversa; UNSUPPORTED-FORMAT senza callback.
Rifiuti e guasti non chiudono o mutano le capacità; nessuna prova di CRC/commit/durability."
  (esigi-aperto input :input) (esigi-aperto append :append)
  (unless (eq (file-backend input) (file-backend append))
    (error 'invalid-argument :reason :io-identity-backend))
  (let ((backend (file-backend input)))
    (when (and backend (null (backend-identity backend)))
      (error 'unsupported-format :reason :io-identity-unavailable)))
  (multiple-value-bind (input-device input-inode) (leggi-identita-file input)
    (multiple-value-bind (append-device append-inode) (leggi-identita-file append)
      (unless (and (= input-device append-device) (= input-inode append-inode))
        (error 'invalid-argument :reason :io-file-mismatch))))
  ;; Non restituisce una prova se il callback ha invalidato una capacità.
  (esigi-aperto input :input) (esigi-aperto append :append)
  (%make-associazione-file input append))

;;; REQ: REQ-AFF-001 REQ-FOR-001
(declaim (ftype (function (file-io file-io) null) verifica-file-distinti))
(defun verifica-file-distinti (left right)
  "Pre: due capacità readonly aperte dello stesso backend, FD stabili nel pool I/O.
Post: identità POSIX diverse, due fstat/callback; nessuna mutazione o retry.
INVALID-ARGUMENT per backend/file alias; UNSUPPORTED-FORMAT senza callback identity.
IO-FAULT/INVARIANT-VIOLATION propagano; non certifica namespace, CRC o durability."
  (esigi-aperto left :input) (esigi-aperto right :input)
  (unless (eq (file-backend left) (file-backend right))
    (error 'invalid-argument :reason :io-identity-backend))
  (let ((backend (file-backend left)))
    (when (and backend (null (backend-identity backend)))
      (error 'unsupported-format :reason :io-identity-unavailable)))
  (multiple-value-bind (left-device left-inode) (leggi-identita-file left)
    (multiple-value-bind (right-device right-inode) (leggi-identita-file right)
      (when (and (= left-device right-device) (= left-inode right-inode))
        (error 'invalid-argument :reason :io-file-alias))))
  (esigi-aperto left :input) (esigi-aperto right :input)
  nil)

;;; REQ: REQ-AFF-001 REQ-FOR-001
(declaim (ftype (function (associazione-file file-io file-io) null) verifica-associazione-file))
(defun verifica-associazione-file (association input append)
  "Pre: associazione creata nel pool I/O; il proprietario impedisce close concorrenti.
Post: capacità esatte ancora aperte, confronto O(1), senza I/O/allocazioni esplicite.
INVALID-ARGUMENT per sostituzione; IO-FAULT dopo close/fault, anche con riuso del numero FD."
  (unless (and (eq input (associazione-file-input association))
               (eq append (associazione-file-append association)))
    (error 'invalid-argument :reason :io-association-capability))
  (esigi-aperto input :input) (esigi-aperto append :append)
  nil)
