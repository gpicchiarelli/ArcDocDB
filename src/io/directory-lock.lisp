;;; OWNER: il compito I/O possiede la capacita' dalla startup fino a chiudi, senza close concorrente.
;;; SHARED: flock rende esclusivo l'avvio M1 sullo stesso inode; nessun lock tra Serie per operazione.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
;; ADR-0017: int flock(int, int), senza struct o argomenti variadici.
;; Verificati in Xcode MacOSX.sdk/usr/include/sys/fcntl.h (incluso da sys/file.h)
;; e Linux include/uapi/asm-generic/fcntl.h: LOCK_EX=2, LOCK_NB=4.
;; https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/fcntl.h
;; https://man7.org/linux/man-pages/man2/flock.2.html
#+(or darwin linux)
(sb-alien:define-alien-routine ("flock" %directory-flock) sb-alien:int
  (descriptor sb-alien:int) (operation sb-alien:int))

;;; REQ: REQ-AFF-008
#+(or darwin linux) (defconstant +directory-lock-exclusive+ 2)
;;; REQ: REQ-AFF-008
#+(or darwin linux) (defconstant +directory-lock-nonblocking+ 4)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (fd) integer) native-directory-lock))
(defun native-directory-lock (descriptor)
  "Pre: FD di directory posseduto e stabile nel pool I/O, ABI 64 bit Darwin/Linux.
Post: una flock(LOCK_EX|LOCK_NB); il lock advisory resta sul FD fino a close.
SYSCALL-ERROR con errno catturato subito; UNSUPPORTED-FORMAT per ABI/piattaforma.
Nessun nuovo FD, nome, unlock, flush, attesa di rilascio o retry, nemmeno per EINTR."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((result (%directory-flock descriptor
                                  (logior +directory-lock-exclusive+ +directory-lock-nonblocking+))))
    (when (= result -1)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'flock))
    result))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io) null) esigi-esclusiva-directory))
(defun esigi-esclusiva-directory (directory)
  "Pre: capacita' directory aperta, FD stabile posseduto dal caller nel pool I/O.
Invocare prima di osservare o modificare lo storage M1 e trattenere la capacita' fino a close.
Post: esclusiva advisory acquisita sul FD esatto; NIL solo dopo ritorno intero zero e postcheck.
INVALID-ARGUMENT per modo, IO-FAULT per stato/syscall/ritorno invalido, INVARIANT-VIOLATION per FD invalido.
Callback assente UNSUPPORTED-FORMAT, senza fallback nativo; errno in operation :directory-lock.
Rifiuti/guasti non mutano stato o frontiere, incluso busy; il caller decide il fallimento startup.
Nessun lockfile, formato, unlink, unlock anticipato, flush, attesa di rilascio o retry."
  (esigi-aperto directory :directory)
  (let* ((backend (file-backend directory))
         (callback (and backend (backend-directory-lock backend))))
    (when (and backend (null callback))
      (error 'unsupported-format :reason :io-directory-lock-unavailable))
    (handler-case
        (let ((result (if backend (funcall callback (file-fd directory))
                          (native-directory-lock (file-fd directory)))))
          (unless (eql result 0)
            (error 'io-fault :reason :io-directory-lock-result :operation :directory-lock)))
      (sb-posix:syscall-error (condition)
        (error 'io-fault :reason :io-syscall :operation :directory-lock
               :errno (sb-posix:syscall-errno condition)))))
  (esigi-aperto directory :directory)
  nil)
