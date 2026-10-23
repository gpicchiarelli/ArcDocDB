;;; OWNER: il compito I/O trasferisce il nuovo FD al wrapper prima di ogni altra osservazione.
;;; SHARED: sole primitive POSIX; parent borrowed, nessun namespace o metadato globale.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (fd simple-base-string (eql :input)) fd) native-open-relative))
(defun native-open-relative (directory name mode)
  "Pre: parent posseduto e foglia ASCII privata; solo apertura readonly nel pool I/O.
Post: FD CLOEXEC/NOFOLLOW/NONBLOCK da openat; il caller ne assume subito ownership.
UNSUPPORTED-FORMAT per ABI/piattaforma, INVARIANT-VIOLATION per modo diverso da :input.
Nessun fstat o cleanup qui; SYSCALL-ERROR cattura errno subito, nessun retry o creazione."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  (unless (eq mode :input) (error 'invariant-violation :reason :io-open-relative-mode))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((descriptor (%directory-openat directory name
                                       (logior +open-cloexec+ sb-posix:o-rdonly
                                               sb-posix:o-nonblock sb-posix:o-nofollow))))
    (when (minusp descriptor)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'openat))
    descriptor))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-FOR-001 REQ-AFF-008
(declaim (ftype (function (fd) (values identity-component identity-component integer &optional))
                native-file-metadata))
(defun native-file-metadata (descriptor)
  "Pre: FD input o append gia' posseduto dal wrapper, senza close concorrente.
Post: identita' e dimensione del regolare da una fstat, senza restringere gli interi.
IO-FAULT per tipo diverso, SYSCALL-ERROR originario; nessuna close, lettura o mutazione."
  (let ((stat (sb-posix:fstat descriptor)))
    (unless (sb-posix:s-isreg (sb-posix:stat-mode stat))
      (error 'io-fault :reason :io-file-kind :operation :file-metadata))
    (values (sb-posix:stat-dev stat) (sb-posix:stat-ino stat) (sb-posix:stat-size stat))))
