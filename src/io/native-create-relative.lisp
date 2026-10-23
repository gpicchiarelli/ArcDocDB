;;; OWNER: compito I/O possiede il nuovo FD prima di ogni osservazione successiva alla creazione.
;;; SHARED: parent borrowed e namespace esclusivo; nessuna variabile POSIX condivisa fra Serie.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003 REQ-REC-001
;; OPENAT e' vararg: mode_t uint16 Darwin promuove a int; 0600 e' rappresentabile anche su Linux.
;; &OPTIONAL marca il quarto argomento variadico: su ARM64 Darwin va sullo stack, non nel registro x3.
;; Non usare la dichiarazione readonly a tre argomenti ne' una dichiarazione a quattro argomenti fissi.
#+(or darwin linux)
(sb-alien:define-alien-routine ("openat" %create-openat) sb-alien:int
  (directory sb-alien:int) (name sb-alien:c-string) (flags sb-alien:int) &optional (mode sb-alien:int))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003 REQ-REC-001
(declaim (ftype (function (fd simple-base-string (eql :append)) fd) native-create-relative))
(defun native-create-relative (directory name mode)
  "Pre: parent posseduto e foglia .tmp ASCII privata; creazione nuova nel pool I/O.
Post: nuovo FD WRONLY/EXCL/APPEND/CLOEXEC/NOFOLLOW, permessi richiesti 0600 soggetti a umask.
UNSUPPORTED-FORMAT per ABI/piattaforma; INVARIANT-VIOLATION per modo diverso da :append.
SYSCALL-ERROR cattura errno subito; caller assume ownership prima di fstat, nessun cleanup o retry.
Preparazione prima dell'EDIT: nessun flush, punto durevole di decisione o eliminazione implicita."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  (unless (eq mode :append) (error 'invariant-violation :reason :io-create-relative-mode))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((descriptor (%create-openat directory name
                                    (logior +open-cloexec+ sb-posix:o-wronly sb-posix:o-creat
                                            sb-posix:o-excl sb-posix:o-append sb-posix:o-nofollow)
                                    #o600)))
    (when (minusp descriptor)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'openat))
    descriptor))
