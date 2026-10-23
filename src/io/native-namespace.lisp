;;; OWNER: compito I/O possiede directory e nomi stabili; nessun FD o puntatore restituito.
;;; SHARED: solo ABI locale; nessun namespace o stato tra Serie.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
;; Struct stat è quello grovelled da SB-POSIX, come per la fstat già usata dal modulo.
;; Selettore INODE64 identico a SB-POSIX: nessun offset di struct copiato nel prodotto.
#+(or darwin linux)
(sb-alien:define-alien-routine (#+inode64 "fstatat$INODE64" #-inode64 "fstatat" %fstatat) sb-alien:int
  (directory sb-alien:int) (name sb-alien:c-string) (stat (* sb-posix::alien-stat)) (flags sb-alien:int))
;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
#+(or darwin linux)
(sb-alien:define-alien-routine ("renameat" %renameat) sb-alien:int
  (source-directory sb-alien:int) (source sb-alien:c-string)
  (target-directory sb-alien:int) (target sb-alien:c-string))
;;; REQ: REQ-AFF-001 REQ-REC-001
#+darwin (defconstant +at-symlink-nofollow+ #x20)
#+linux (defconstant +at-symlink-nofollow+ #x100)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-FOR-001 REQ-REC-001
(declaim (ftype (function (fd string) (values identity-component identity-component &optional))
                native-entry-identity))
(defun native-entry-identity (directory name)
  "Pre: directory posseduta, nome foglia ASCII stabile. Post: identità del file regolare senza symlink.
Una fstatat, errno immediato; stat locale dal runtime SB-POSIX, nessun nuovo FD.
SYSCALL-ERROR/IO-FAULT/UNSUPPORTED-FORMAT propagano senza retry o mutazione del namespace."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (sb-posix::with-alien-stat stat ()
    (let ((result (%fstatat directory name stat +at-symlink-nofollow+)))
      (when (= result -1)
        (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'fstatat))
      (unless (zerop result) (error 'io-fault :reason :io-entry-result :operation :entry-identity))
      (let ((value (sb-posix::alien-to-stat stat nil)))
        (unless (sb-posix:s-isreg (sb-posix:stat-mode value))
          (error 'io-fault :reason :io-entry-kind :operation :entry-identity))
        (values (sb-posix:stat-dev value) (sb-posix:stat-ino value))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
(declaim (ftype (function (fd simple-base-string simple-base-string) integer) native-replace))
(defun native-replace (directory source target)
  "Pre: nomi privati validati, namespace posseduto fino al termine. Post: una renameat, nessun fsync.
Punto di atomicità POSIX: rinomina; decisione autorevole e durability rimangono al caller.
SYSCALL-ERROR con errno immediato, senza retry/rollback; entrambe le foglie nello stesso parent."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((result (%renameat directory source directory target)))
    (when (= result -1)
      (error 'sb-posix:syscall-error :errno (sb-alien:get-errno) :name 'renameat))
    result))
