;;; OWNER: un compito I/O possiede il cursore privato; il FD parent resta preso in prestito.
;;; SHARED: ABI SB-POSIX grovelled; nessun DIR*, FD o buffer dirent viene pubblicato.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
#+(or darwin linux)
(sb-alien:define-alien-routine ("openat" %directory-openat) sb-alien:int
  (directory sb-alien:int) (name sb-alien:c-string) (flags sb-alien:int))
;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
#+(or darwin linux)
(sb-alien:define-alien-routine
    (#+inode64 "fdopendir$INODE64" #-inode64 "fdopendir" %directory-fdopendir) (* t)
  (descriptor sb-alien:int))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (t index index index)
                          (values list (member nil :io-directory-names :io-directory-name-bytes
                                              :io-directory-total-name-bytes) &optional))
                native-directory-read))
(defun native-directory-read (stream max-names max-total-name-bytes max-name-bytes)
  "Pre: DIR* esclusivo e namespace stabile. Post: nomi copiati o reason di budget, mai prefisso valido.
READDIR azzera errno e segnala syscall-error; EOF e' un alien NULL, non NIL.
Latin1 conserva ciascun byte del nome; . e .. sono gli unici nomi esclusi dai budget."
  (let ((names nil) (count 0) (bytes 0)
        (sb-alien::*default-c-string-external-format* :latin-1))
    (loop repeat (+ max-names 3)
          for entry = (sb-posix:readdir stream)
          do (when (sb-alien:null-alien entry) (return (values names nil)))
             (let ((name (sb-posix:dirent-name entry)))
               (unless (member name '("." "..") :test #'string=)
                 (let ((size (length name)))
                   (cond ((>= count max-names)
                          (return (values nil :io-directory-names)))
                         ((> size max-name-bytes)
                          (return (values nil :io-directory-name-bytes)))
                         ((> size (- max-total-name-bytes bytes))
                          (return (values nil :io-directory-total-name-bytes)))
                         (t nil))
                   (push (map '(simple-array character (*)) #'identity name) names)
                   (incf count) (incf bytes size))))
          finally (return (values nil :io-directory-names)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (t (integer -1 2147483647))
                          (values (or null fixnum) boolean &optional)) native-directory-cleanup))
(defun native-directory-cleanup (stream descriptor)
  "Pre: o DIR* possiede il FD, o il FD non trasferito e' locale. Post: una sola chiusura.
Non ritenta EINTR; restituisce errno/fallimento senza mascherare il motivo primario."
  (handler-case
      (values nil (not (eql 0 (if stream (sb-posix:closedir stream)
                                 (if (minusp descriptor) 0 (sb-posix:close descriptor))))))
    (sb-posix:syscall-error (condition)
      (values (sb-posix:syscall-errno condition) t))))

;;; REQ: REQ-AFF-004 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function ((member nil :io-syscall :io-directory-names :io-directory-name-bytes
                                 :io-directory-total-name-bytes)
                          (or null fixnum) (or null fixnum) boolean) null)
                native-directory-outcome))
(defun native-directory-outcome (reason errno cleanup-errno cleanup-failed)
  "Pre: cursore gia' chiuso/tentato una volta. Post: solo successo completo, o causa tipizzata.
Budget e chiusura fallita producono IO-FAULT con stesso reason e cleanup-errno."
  (cond ((eq reason :io-syscall)
         (error 'io-fault :reason reason :operation :directory-entries
                :errno errno :cleanup-errno cleanup-errno))
        ((member reason '(:io-directory-names :io-directory-name-bytes :io-directory-total-name-bytes))
         (if cleanup-failed
             (error 'io-fault :reason reason :operation :directory-entries :cleanup-errno cleanup-errno)
             (error 'resource-exhausted :reason reason)))
        ((null reason)
         (if cleanup-failed
             (error 'io-fault :reason :io-directory-close :operation :directory-entries :errno cleanup-errno)
             nil))
        (t (error 'invariant-violation :reason :io-directory-reason)))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (fd index index index) (values simple-vector (eql t) &optional))
                native-directory-entries))
(defun native-directory-entries (directory max-names max-total-name-bytes max-name-bytes)
  "Pre: parent posseduto e stabile. Post: cursore openat(.) indipendente, elenco completo privato.
FDOPENDIR trasferisce ownership solo se riuscita; parent, frontiere e namespace restano intatti.
Solo pool I/O, senza lock esterni: le syscall possono bloccare, nessuna deadline wall implicita.
Le finestre senza interrupt proteggono handoff e chiusura; cancellazione asincrona non supportata.
Su uscite nonlocali estranee: un cleanup tentato, causa originale senza allegare il cleanup-errno.
Nessun retry, risultato parziale o successo precedente alla chiusura del cursore."
  (unless (= sb-vm:n-word-bits 64) (error 'unsupported-format :reason :io-abi))
  #-(or darwin linux) (error 'unsupported-format :reason :io-platform)
  #+(or darwin linux)
  (let ((descriptor -1) (stream nil) (names nil) (reason nil) (errno nil)
        (cleanup-errno nil) (cleanup-failed nil))
    (unwind-protect
         (handler-case
             (progn
               (sb-sys:without-interrupts
                 (setf descriptor (%directory-openat directory "."
                                                    (logior +open-cloexec+ sb-posix:o-rdonly
                                                            sb-posix:o-directory sb-posix:o-nofollow)))
                 (when (minusp descriptor)
                   (setf errno (sb-alien:get-errno) reason :io-syscall)))
               (unless reason
                 (sb-sys:without-interrupts
                   (let ((opened (%directory-fdopendir descriptor)))
                     (if (sb-alien:null-alien opened)
                         (setf errno (sb-alien:get-errno) reason :io-syscall)
                         (setf stream opened descriptor -1))))
                 (unless reason
                   (multiple-value-setq (names reason)
                     (native-directory-read stream max-names max-total-name-bytes max-name-bytes)))))
           (sb-posix:syscall-error (condition)
             (setf reason :io-syscall errno (sb-posix:syscall-errno condition))))
      (sb-sys:without-interrupts
        (multiple-value-setq (cleanup-errno cleanup-failed)
          (native-directory-cleanup stream descriptor))))
    (native-directory-outcome reason errno cleanup-errno cleanup-failed)
    (values (coerce (nreverse names) 'simple-vector) t)))
