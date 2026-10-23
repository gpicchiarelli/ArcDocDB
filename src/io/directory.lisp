;;; OWNER: il compito I/O mantiene parent e namespace stabili per l'intera enumerazione.
;;; SHARED: nessuno stato globale; nomi e vettore restituiti appartengono al chiamante.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (t t t) null) verifica-budget-directory))
(defun verifica-budget-directory (max-names max-total-name-bytes max-name-bytes)
  "Pre: budget del chiamante. Post: limiti interi finiti e nome di 1..255 byte, senza I/O."
  (unless (and (typep max-names 'index) (typep max-total-name-bytes 'index)
               (typep max-name-bytes '(integer 1 255)))
    (error 'invalid-argument :reason :io-directory-budget))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (t t index index index) simple-vector) copia-nomi-directory))
(defun copia-nomi-directory (names complete max-names max-total-name-bytes max-name-bytes)
  "Pre: callback terminato, risultato preso in prestito. Post: vettore/nomi privati byte per byte.
Rifiuta risultato incompleto o fuori contratto; budget applicati anche ai nomi estranei allo storage."
  (unless (and (eq complete t) (simple-vector-p names))
    (error 'invariant-violation :reason :io-directory-result))
  (when (> (length names) max-names)
    (error 'resource-exhausted :reason :io-directory-names))
  (let ((bytes 0) (result (make-array (length names))))
    (dotimes (i (length names) result)
      (let ((name (svref names i)))
        (unless (and (stringp name) (plusp (length name))
                     (not (member name '("." "..") :test #'string=)))
          (error 'invariant-violation :reason :io-directory-name))
        (when (> (length name) max-name-bytes)
          (error 'resource-exhausted :reason :io-directory-name-bytes))
        (when (> (length name) (- max-total-name-bytes bytes))
          (error 'resource-exhausted :reason :io-directory-total-name-bytes))
        (unless (every (lambda (character) (let ((code (char-code character)))
                                           (and (<= 1 code 255) (/= code 47)))) name)
          (error 'invariant-violation :reason :io-directory-name))
        (incf bytes (length name))
        (setf (svref result i) (map '(simple-array character (*)) #'identity name))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (file-io &key (:max-names t) (:max-total-name-bytes t) (:max-name-bytes t))
                          (values simple-vector (eql t) &optional)) elenca-directory))
(defun elenca-directory (directory &key (max-names 65536) (max-total-name-bytes 16777216)
                                      (max-name-bytes 255))
  "Pre: parent aperto, namespace esclusivo/stabile e nessuna close concorrente.
Post: tutti i nomi esclusi . e .. in vettore privato, T solo dopo EOF e cleanup riuscito.
Nomi Latin1 preservano byte, nessuna identita'/CRC/durability implicita; parent/frontiere intatti.
INVALID-ARGUMENT, RESOURCE-EXHAUSTED, IO-FAULT o callback assente UNSUPPORTED senza fallback."
  (verifica-budget-directory max-names max-total-name-bytes max-name-bytes)
  (esigi-aperto directory :directory)
  (let* ((backend (file-backend directory))
         (callback (and backend (backend-directory-entries backend))))
    (when (and backend (null callback))
      (error 'unsupported-format :reason :io-directory-unavailable))
    (handler-case
        (multiple-value-bind (names complete)
            (if backend (funcall callback (file-fd directory) max-names max-total-name-bytes max-name-bytes)
                (native-directory-entries (file-fd directory) max-names max-total-name-bytes max-name-bytes))
          (let ((result (copia-nomi-directory names complete max-names max-total-name-bytes max-name-bytes)))
            (esigi-aperto directory :directory)
            (values result t)))
      (sb-posix:syscall-error (condition)
        (error 'io-fault :reason :io-syscall :operation :directory-entries
               :errno (sb-posix:syscall-errno condition))))))
