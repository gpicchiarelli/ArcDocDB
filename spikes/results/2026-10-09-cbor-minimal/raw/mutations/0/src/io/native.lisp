;;;; Solo qui si conoscono ABI, errno, puntatori e primitive POSIX.
;;; OWNER: descrittore e buffer posseduti dal compito I/O; pin limitato alla syscall.
;;; SHARED: nessuna scrittura di stato tra Serie.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
;; ADR-0017: ABI Linux x86-64/macOS ARM64, ssize_t/off_t/long a 64 bit.
(declaim (inline %pread %write))
(sb-alien:define-alien-routine ("pread" %pread) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (count sb-alien:unsigned-long) (offset sb-alien:long))
(sb-alien:define-alien-routine ("write" %write) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer) (count sb-alien:unsigned-long))

;;; REQ: REQ-AFF-001
;; Costanti ABI dai rispettivi sys/fcntl.h; mai scelte tramite fallback.
#+darwin (defconstant +open-cloexec+ #x1000000)
#+linux (defconstant +open-cloexec+ #o2000000)
#+darwin (defconstant +full-fsync+ 51)

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (string (member :input :append :directory)) fd) native-open))
(defun native-open (name mode)
  "Pre: nome non vuoto/NUL-free. Post: FD CLOEXEC/NOFOLLOW e modo richiesto.
SYSCALL-ERROR esplicito; ABI non 64 bit UNSUPPORTED-FORMAT, senza apertura."
  (unless (= sb-vm:n-word-bits 64)
    (error 'unsupported-format :reason :io-abi))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((fd (sb-posix:open name
                 (logior +open-cloexec+ sb-posix:o-nofollow
                         (case mode
                           (:input (logior sb-posix:o-rdonly sb-posix:o-nonblock))
                           (:append (logior sb-posix:o-wronly sb-posix:o-creat
                                           sb-posix:o-excl sb-posix:o-append))
                           (:directory (logior sb-posix:o-rdonly sb-posix:o-directory))
                           (otherwise (error 'invariant-violation :reason :io-open-mode))))
                 #o600)))
    (handler-case
        (let ((kind (sb-posix:stat-mode (sb-posix:fstat fd))))
          (unless (if (eq mode :directory) (sb-posix:s-isdir kind) (sb-posix:s-isreg kind))
            (error 'io-fault :reason :io-file-kind :operation :open))
          fd)
      (sb-posix:syscall-error (c)
        (cleanup-open fd :io-syscall (sb-posix:syscall-errno c)))
      (io-fault (c)
        (cleanup-open fd (arcdocdb.conditions:error-reason c)
                      (arcdocdb.conditions:error-errno c))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (fd keyword (or null fixnum)) nil) cleanup-open))
(defun cleanup-open (fd reason errno)
  "Pre: FD aperto ma non pubblicato. Post: una close, poi errore primario preservato.
IO-FAULT include un eventuale errno di cleanup; nessun tentativo aggiuntivo."
  (let ((cleanup nil))
    (handler-case (sb-posix:close fd)
      (sb-posix:syscall-error (c) (setf cleanup (sb-posix:syscall-errno c))))
    (error 'io-fault :reason reason :operation :open :errno errno :cleanup-errno cleanup)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
(declaim (inline native-read native-write)
         (ftype (function (fd octets index index file-offset) (signed-byte 64)) native-read)
         (ftype (function (fd octets index index) (signed-byte 64)) native-write))
(defun native-read (fd buffer start count offset)
  "Pre: range verificato, buffer esclusivo. Post: una pread, errno catturato subito.
Pin e SAP non escono dalla chiamata; SYSCALL-ERROR per ritorno -1."
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%pread fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start) count offset)))
      (when (= n -1)
        (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'pread))
      n)))
;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
(defun native-write (fd buffer start count)
  "Pre: range verificato e stabile. Post: una write, errno immediato, nessun retry.
Pin e SAP restano locali; SYSCALL-ERROR per ritorno -1."
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%write fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start) count)))
      (when (= n -1)
        (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'write))
      n)))

;;; REQ: REQ-AFF-001
(declaim (ftype (function (fd) integer) native-flush native-directory-flush native-close))
(defun native-flush (fd)
  "Pre: FD scrivibile posseduto. Post: flush richiesto dalla piattaforma, mai ritentato.
SYSCALL-ERROR per guasto; nessun fallback meno durevole."
  #+darwin (sb-posix:fcntl fd +full-fsync+)
  #+linux (sb-posix:fdatasync fd)
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform))
;;; REQ: REQ-AFF-001
(defun native-directory-flush (fd)
  "Pre: FD directory posseduto. Post: fsync eseguita una volta; SYSCALL-ERROR propagato."
  (sb-posix:fsync fd))
;;; REQ: REQ-AFF-001
(defun native-close (fd)
  "Pre: FD non ancora chiuso. Post: una close soltanto; SYSCALL-ERROR mai ritentato."
  (sb-posix:close fd))
