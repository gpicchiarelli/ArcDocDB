;;;; Confine POSIX locale: ABI esplicita, capacita' possedute, nessun reader esterno.
;;; OWNER: un attore I/O possiede FD, namespace e buffer; nessuna close concorrente.
;;; SHARED: nessuno stato globale mutabile; flock serializza solo l'avvio nella runtime dir.
;;; Callback fidati sincroni/non rientrabili, senza uscite nonlocali; cancellazione asincrona esclusa.
;;; Nessun fork concorrente tra acquisizione FD e fcntl CLOEXEC, incluso accept su Darwin.
;;; REQ: REQ-IPC-001 REQ-IPC-002 REQ-IPC-003 REQ-AFF-004
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(deftype native-fd () '(integer 0 2147483647))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(deftype native-octets () '(simple-array (unsigned-byte 8) (*)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(define-condition native-error (arcdocdb.conditions:io-fault)
  ((primary :initarg :primary :initform nil :reader native-error-primary
            :type (or null condition))
   (cleanup :initarg :cleanup :initform nil :reader native-error-cleanup :type list))
  (:documentation "Causa primaria e tutte le cause secondarie, senza retry della close."))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (keyword keyword &key (:errno t) (:primary t) (:cleanup t)) nil)
                %native-fail))
(defun %native-fail (reason operation &key errno primary cleanup)
  "Pre: causa gia' catturata. Post: condizione ArcDocDB con primaria e cleanup conservati.
Ownership: nessun FD consumato; il proprietario decide le chiusure."
  (error 'native-error :reason reason :operation operation :errno errno
         :primary primary :cleanup cleanup))

;;; REQ: REQ-IPC-001 REQ-AFF-004
(declaim (ftype (function () null) %native-platform))
(defun %native-platform ()
  "Pre: nessuna syscall. Post: ammesse soltanto Darwin ARM64 e Linux x86-64.
Ownership: nessun effetto; UNSUPPORTED-FORMAT prima di acquisire FD."
  (unless (and (= sb-vm:n-word-bits 64)
               #+(or (and darwin arm64) (and linux x86-64)) t
               #-(or (and darwin arm64) (and linux x86-64)) nil)
    (error 'arcdocdb.conditions:unsupported-format :reason :local-native-platform))
  nil)

;;; REQ: REQ-IPC-002 REQ-AFF-004
#+darwin (defconstant +native-dontwait+ #x80)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+linux (defconstant +native-dontwait+ #x40)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+darwin (defconstant +native-nosignal+ #x80000)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+linux (defconstant +native-nosignal+ #x4000)
;;; REQ: REQ-IPC-003 REQ-AFF-004
#+darwin (defconstant +native-cloexec+ #x1000000)
;;; REQ: REQ-IPC-003 REQ-AFF-004
#+linux (defconstant +native-cloexec+ #o2000000)
;;; REQ: REQ-IPC-003 REQ-AFF-004
#+darwin (defconstant +native-nofollow+ #x20)
;;; REQ: REQ-IPC-003 REQ-AFF-004
#+linux (defconstant +native-nofollow+ #x100)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+darwin (defconstant +native-sol-socket+ #xffff)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+linux (defconstant +native-sol-socket+ 1)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+darwin (defconstant +native-so-error+ #x1007)
;;; REQ: REQ-IPC-002 REQ-AFF-004
#+linux (defconstant +native-so-error+ 4)
;;; REQ: REQ-IPC-003 REQ-AFF-004
;; sys/fcntl.h Darwin e asm-generic/fcntl.h Linux: flag FD, distinto da O_CLOEXEC.
(defconstant +native-fd-cloexec+ 1)

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (inline %native-recv %native-send))
(sb-alien:define-alien-routine ("recv" %native-recv) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (count sb-alien:unsigned-long) (flags sb-alien:int))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(sb-alien:define-alien-routine ("send" %native-send) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (count sb-alien:unsigned-long) (flags sb-alien:int))
;;; REQ: REQ-IPC-001 REQ-AFF-004
(sb-alien:define-alien-routine ("socket" %native-socket) sb-alien:int
  (domain sb-alien:int) (kind sb-alien:int) (protocol sb-alien:int))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(sb-alien:define-alien-routine ("accept" %native-accept) sb-alien:int
  (fd sb-alien:int) (address sb-alien:system-area-pointer)
  (size sb-alien:system-area-pointer))
;;; REQ: REQ-IPC-001 REQ-AFF-004
(sb-alien:define-alien-routine ("bind" %native-bind) sb-alien:int
  (fd sb-alien:int) (address sb-alien:system-area-pointer) (size sb-alien:unsigned-int))
;;; REQ: REQ-IPC-001 REQ-AFF-004
(sb-alien:define-alien-routine ("connect" %native-connect) sb-alien:int
  (fd sb-alien:int) (address sb-alien:system-area-pointer) (size sb-alien:unsigned-int))
;;; REQ: REQ-IPC-001 REQ-AFF-004
(sb-alien:define-alien-routine ("listen" %native-listen) sb-alien:int
  (fd sb-alien:int) (backlog sb-alien:int))
;;; REQ: REQ-IPC-003 REQ-AFF-004
(sb-alien:define-alien-routine ("openat" %native-openat) sb-alien:int
  (fd sb-alien:int) (name sb-alien:c-string) (flags sb-alien:int))
;;; REQ: REQ-IPC-003 REQ-AFF-004
(sb-alien:define-alien-routine ("unlinkat" %native-unlinkat) sb-alien:int
  (fd sb-alien:int) (name sb-alien:c-string) (flags sb-alien:int))
;;; REQ: REQ-IPC-003 REQ-AFF-004
(sb-alien:define-alien-routine ("flock" %native-flock) sb-alien:int
  (fd sb-alien:int) (operation sb-alien:int))
;;; REQ: REQ-IPC-003 REQ-AFF-004
#+(or darwin linux)
(sb-alien:define-alien-routine
    (#+inode64 "fstatat$INODE64" #-inode64 "fstatat" %native-fstatat) sb-alien:int
  (fd sb-alien:int) (name sb-alien:c-string)
  (stat (* sb-posix::alien-stat)) (flags sb-alien:int))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(sb-alien:define-alien-routine ("getsockopt" %native-getsockopt) sb-alien:int
  (fd sb-alien:int) (level sb-alien:int) (option sb-alien:int)
  (value (* sb-alien:int)) (size (* sb-alien:unsigned-int)))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (native-fd native-octets fixnum fixnum)
                         (values (signed-byte 64) fixnum &optional))
                %native-recv-span %native-send-span))
(defun %native-recv-span (fd buffer start count)
  "Pre: FD/span verificati, buffer esclusivo. Post: una recv non bloccante, n/errno immediato.
Ownership: pin e SAP limitati alla syscall; nessun buffer temporaneo o retry."
  (%native-platform)
  #+(or darwin linux)
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%native-recv fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start)
                           count +native-dontwait+)))
      (values n (if (= n -1) (sb-alien:get-errno) 0))))
  #-(or darwin linux) (%native-fail :local-native-platform :recv))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun %native-send-span (fd buffer start count)
  "Pre: FD/span verificati, buffer stabile. Post: una send NONBLOCK senza SIGPIPE.
Ownership: pin locale; n/errno immediato, senza copia, slice, attesa o retry."
  (%native-platform)
  #+(or darwin linux)
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%native-send fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start)
                           count (logior +native-dontwait+ +native-nosignal+))))
      (values n (if (= n -1) (sb-alien:get-errno) 0))))
  #-(or darwin linux) (%native-fail :local-native-platform :send))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(defstruct (native-node (:constructor %make-native-node (device inode uid mode)) (:copier nil))
  "Pre: metadata da stat affidabile. Post: identita'/policy immutabili; nessun FD posseduto."
  (device 0 :type (integer 0 *) :read-only t)
  (inode 0 :type (integer 0 *) :read-only t)
  (uid 0 :type (integer 0 #xffffffff) :read-only t)
  (mode 0 :type (integer 0 #xffffffff) :read-only t))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) native-node) %native-stat-node))
(defun %native-stat-node (stat)
  "Pre: stat SB-POSIX. Post: snapshot privato device/inode/uid/mode, nessun FD trasferito."
  (%make-native-node (sb-posix:stat-dev stat) (sb-posix:stat-ino stat)
                     (sb-posix:stat-uid stat) (sb-posix:stat-mode stat)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (native-fd string) (values t fixnum &optional)) %native-entry))
(defun %native-entry (fd name)
  "Pre: FD parent posseduto, foglia UTF-8. Post: lstat relativo senza seguire symlink.
Ownership: stat locale, ABI grovelled SB-POSIX; errno prima di altro codice."
  #+(or darwin linux)
  (sb-posix::with-alien-stat stat ()
    (let ((n (%native-fstatat fd name stat +native-nofollow+)))
      (if (= n -1) (values -1 (sb-alien:get-errno))
          (values (%native-stat-node (sb-posix::alien-to-stat stat nil)) 0))))
  #-(or darwin linux) (%native-fail :local-native-platform :entry))

;;; REQ: REQ-IPC-001 REQ-AFF-004
(declaim (ftype (function (native-fd native-octets keyword)
                         (values integer fixnum &optional)) %native-address-call))
(defun %native-address-call (fd bytes operation)
  "Pre: UTF-8 1..100 byte verificati. Post: bind/connect singolo, sockaddr Unix esplicito.
Ownership: allocazione solo lifecycle, buffer sockaddr pinned locale, errno immediato."
  (let* ((size (+ 3 (length bytes)))
         (address (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
    ;; sa_family_t: u8 dopo sun_len Darwin; u16 little endian Linux x86-64.
    #+darwin (setf (aref address 0) size (aref address 1) 1)
    #+linux (setf (aref address 0) 1)
    (replace address bytes :start1 2)
    (sb-sys:with-pinned-objects (address)
      (let ((n (case operation
                 (:bind (%native-bind fd (sb-sys:vector-sap address) size))
                 (:connect (%native-connect fd (sb-sys:vector-sap address) size))
                 (otherwise (%native-fail :local-native-operation operation)))))
        (values n (if (= n -1) (sb-alien:get-errno) 0))))))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (native-fd) (values integer fixnum &optional)) %native-socket-error))
(defun %native-socket-error (fd)
  "Pre: FD socket posseduto. Post: SO_ERROR o errno syscall, mai attesa o retry.
Ownership: due scalari alien locali, nessun buffer I/O copiato."
  #+(or darwin linux)
  (sb-alien:with-alien ((value sb-alien:int 0) (size sb-alien:unsigned-int 4))
    (let ((n (%native-getsockopt fd +native-sol-socket+ +native-so-error+
                                (sb-alien:addr value) (sb-alien:addr size))))
      (if (= n -1) (values -1 (sb-alien:get-errno))
          (if (= size 4) (values value 0)
              (%native-fail :local-socket-error-size :socket-error)))))
  #-(or darwin linux) (%native-fail :local-native-platform :socket-error))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (native-fd) (values integer fixnum &optional)) %native-configure))
(defun %native-configure (fd)
  "Pre: nuovo FD esclusivo. Post: CLOEXEC e NONBLOCK conservando gli altri flag.
Ownership: caller conserva FD anche su guasto; nessuna modifica globale di segnali/umask."
  (sb-posix:fcntl fd sb-posix:f-setfd
                  (logior (sb-posix:fcntl fd sb-posix:f-getfd) +native-fd-cloexec+))
  (sb-posix:fcntl fd sb-posix:f-setfl
                  (logior (sb-posix:fcntl fd sb-posix:f-getfl) sb-posix:o-nonblock))
  (values 0 0))

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (keyword list) (values t fixnum &optional)) %native-control))
(defun %native-control (operation arguments)
  "Pre: operazione interna/argomenti verificati. Post: risultato,errno senza retry.
Ownership: syscall POSIX solo qui; metadata privati, FD trasferiti solo dal caller."
  (%native-platform)
  (let ((sb-alien::*default-c-string-external-format* :utf-8))
    (handler-case
        (let ((result
                (case operation
                  (:uid (sb-posix:geteuid))
                  (:socket (%native-socket 1 1 0))
                  (:configure (return-from %native-control (%native-configure (first arguments))))
                  (:connect (return-from %native-control
                              (%native-address-call (first arguments) (second arguments) :connect)))
                  (:bind (return-from %native-control
                           (%native-address-call (first arguments) (second arguments) :bind)))
                  (:accept (%native-accept (first arguments) (sb-sys:int-sap 0) (sb-sys:int-sap 0)))
                  (:listen (%native-listen (first arguments) 64))
                  (:socket-error (return-from %native-control (%native-socket-error (first arguments))))
                  (:wait-output (sb-sys:wait-until-fd-usable (first arguments) :output (second arguments) nil))
                  (:close (sb-posix:close (first arguments)))
                  (:root (sb-posix:open "/" (%native-directory-flags)))
                  (:openat (%native-openat (first arguments) (second arguments) (%native-directory-flags)))
                  (:fstat (%native-stat-node (sb-posix:fstat (first arguments))))
                  (:lstat (%native-stat-node (sb-posix:lstat (first arguments))))
                  (:entry (return-from %native-control (%native-entry (first arguments) (second arguments))))
                  (:unlink (%native-unlinkat (first arguments) (second arguments) 0))
                  (:chmod (sb-posix:chmod (first arguments) #o600))
                  (:lock (%native-flock (first arguments) 6)) ; LOCK_EX | LOCK_NB
                  (otherwise (%native-fail :local-native-operation operation)))))
          (values result (if (eql result -1) (sb-alien:get-errno) 0)))
      (sb-posix:syscall-error (condition)
        (values -1 (sb-posix:syscall-errno condition))))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function () integer) %native-directory-flags))
(defun %native-directory-flags ()
  "Pre: ABI ammessa. Post: RDONLY/DIRECTORY/NOFOLLOW/CLOEXEC/NONBLOCK; nessun effetto."
  #+(or darwin linux)
  (logior sb-posix:o-rdonly sb-posix:o-directory sb-posix:o-nofollow
          sb-posix:o-nonblock +native-cloexec+)
  #-(or darwin linux) (%native-fail :local-native-platform :directory))

;;; REQ: REQ-IPC-002 REQ-IPC-003 REQ-AFF-004
(defstruct (native-backend (:constructor %make-native-backend (recv send control)) (:copier nil))
  "Pre: callback fidati. Post: slot immutabili; nessun fallback da callback mancante.
RECV/SEND(fd,octets,start,count)->n,errno; CONTROL(operation,argument-list)->value,errno."
  (recv #'%native-recv-span :type function :read-only t)
  (send #'%native-send-span :type function :read-only t)
  (control #'%native-control :type function :read-only t))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (&key (:recv t) (:send t) (:control t)) native-backend) make-native-backend))
(defun make-native-backend (&key (recv #'%native-recv-span) (send #'%native-send-span)
                                (control #'%native-control))
  "Pre: tre funzioni fidate, non rientrabili. Post: backend privato verificato.
Ownership: callback sincroni senza conservare buffer/puntatori; INVALID-ARGUMENT per tipo."
  (unless (and (functionp recv) (functionp send) (functionp control))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-native-backend))
  (%make-native-backend recv send control))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t) null) %native-check-backend)
         (ftype (function (t) native-fd) %native-check-fd))
(defun %native-check-backend (backend)
  "Pre: valore esterno. Post: NIL/nativo o backend verificato; nessun effetto."
  (unless (typep backend '(or null native-backend))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-native-backend))
  (unless backend (%native-platform))
  nil)
;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun %native-check-fd (fd)
  "Pre: valore esterno. Post: FD int non negativo, incluso zero; nessun effetto."
  (unless (typep fd 'native-fd)
    (error 'arcdocdb.conditions:invalid-argument :reason :local-native-fd))
  fd)

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t t t t t) null) %native-check-span))
(defun %native-check-span (fd buffer start count backend)
  "Pre: argomenti non fidati. Post: intero span non vuoto verificato prima del backend.
Ownership: caller conserva FD e simple u8; INVALID-ARGUMENT senza syscall o pin."
  (%native-check-fd fd)
  (%native-check-backend backend)
  (unless (and (typep buffer 'native-octets) (typep start '(integer 0 #.most-positive-fixnum))
               (typep count '(integer 1 #.most-positive-fixnum))
               (<= start (length buffer)) (<= count (- (length buffer) start)))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-native-span))
  nil)

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t t integer keyword) (values integer fixnum &optional)) %native-result))
(defun %native-result (n errno maximum operation)
  "Pre: esito callback/syscall. Post: n=-1 con errno positivo, oppure 0..max e errno zero.
Ownership: nessun progresso inventato; esito impossibile produce NATIVE-ERROR."
  (unless (and (typep n '(signed-byte 64)) (typep errno '(integer 0 #.most-positive-fixnum))
               (<= -1 n maximum) (if (= n -1) (plusp errno) (zerop errno)))
    (%native-fail :local-native-result operation))
  (values n errno))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t t t t &optional t) (values integer fixnum &optional))
                native-recv-span native-send-span))
(defun native-recv-span (fd buffer start count &optional backend)
  "Pre: FD/buffer/span esterni; buffer esclusivo fino al ritorno. Post: una recv, n/errno.
Ownership: span prestato sincrono; EOF=0, EINTR/EAGAIN senza retry; attesa nel parent."
  (%native-check-span fd buffer start count backend)
  (%native-transfer (if backend (native-backend-recv backend) #'%native-recv-span)
                    fd buffer start count :recv))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun native-send-span (fd buffer start count &optional backend)
  "Pre: FD/buffer/span esterni; buffer stabile fino al ritorno. Post: una send, n/errno.
Ownership: nessuna copia, SIGPIPE soppresso per chiamata; zero/failure restano al parent."
  (%native-check-span fd buffer start count backend)
  (%native-transfer (if backend (native-backend-send backend) #'%native-send-span)
                    fd buffer start count :send))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (function native-fd native-octets fixnum fixnum keyword)
                         (values integer fixnum &optional)) %native-transfer))
(defun %native-transfer (callback fd buffer start count operation)
  "Pre: argomenti verificati, callback sincrono fidato. Post: n/errno oppure causa tipizzata.
Ownership: confine dell'adattatore; nessun buffer/puntatore conservato oltre il ritorno."
  (handler-case
      (multiple-value-bind (n errno) (funcall callback fd buffer start count)
        (%native-result n errno count operation))
    (arcdocdb.conditions:arcdocdb-error (condition) (error condition))
    (error (condition) (%native-fail :local-native-callback operation :primary condition))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t keyword &rest t) (values t fixnum &optional)) %native-call))
(defun %native-call (backend operation &rest arguments)
  "Pre: backend verificato, argomenti interni. Post: value/errno verificati, causa tipizzata.
Ownership: confine callback lifecycle; errori estranei incapsulati senza perdere l'originale."
  (handler-case
      (multiple-value-bind (value errno)
          (funcall (if backend (native-backend-control backend) #'%native-control) operation arguments)
        (unless (and (typep errno '(integer 0 #.most-positive-fixnum))
                     (if (eql value -1) (plusp errno) (zerop errno)))
          (%native-fail :local-native-result operation))
        (values value errno))
    (arcdocdb.conditions:arcdocdb-error (condition) (error condition))
    (error (condition) (%native-fail :local-native-callback operation :primary condition))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t keyword &rest t) t) %native-required))
(defun %native-required (backend operation &rest arguments)
  "Pre: operazione lifecycle richiesta. Post: risultato oppure errore con errno preservato.
Ownership: non chiude FD implicitamente; nessun retry della syscall."
  (multiple-value-bind (value errno) (apply #'%native-call backend operation arguments)
    (when (eql value -1) (%native-fail :local-native-syscall operation :errno errno))
    value))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &key (:backend t)) (or null condition)) native-close))
(defun native-close (fd &key backend)
  "Pre: FD posseduto ancora da chiudere. Post: un tentativo; NIL o condizione conservabile.
Ownership: consumata anche con EINTR; mai ritentare una close sul medesimo numero."
  (%native-check-fd fd)
  (%native-check-backend backend)
  (handler-case
      (let ((result (%native-required backend :close fd)))
        (unless (eql result 0) (%native-fail :local-native-result :close)) nil)
    (arcdocdb.conditions:arcdocdb-error (condition) condition)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &key (:backend t)) null) close-local-socket))
(defun close-local-socket (socket &key backend)
  "Pre: FD posseduto, incluso zero. Post: una close; guasto tipizzato segnalato al cleanup parent.
Ownership: consumata dal caller prima dell'invocazione; nessuna ripetizione automatica."
  (let ((failure (native-close socket :backend backend))) (when failure (error failure)))
  nil)

;;; REQ: REQ-IPC-001 REQ-AFF-004
(declaim (ftype (function (native-fd t) native-fd) %native-configured-fd))
(defun %native-configured-fd (fd backend)
  "Pre: FD appena acquisito. Post: NONBLOCK/CLOEXEC oppure close singola e cause preservate.
Ownership: trasferita al caller solo dopo configurazione completa."
  (handler-case
      (progn
        (unless (eql 0 (%native-required backend :configure fd))
          (%native-fail :local-native-result :configure)) fd)
    (error (primary)
      (let ((cleanup (native-close fd :backend backend)))
        (%native-fail :local-native-configure :configure :primary primary
                      :cleanup (if cleanup (list cleanup) nil))))))

;;; REQ: REQ-IPC-001 REQ-AFF-004
(declaim (ftype (function (&key (:backend t)) native-fd) native-socket-new new-local-socket))
(defun native-socket-new (&key backend)
  "Pre: backend valido. Post: FD Unix stream NONBLOCK/CLOEXEC; nessun bind o listener.
Ownership: caller assume FD, anche zero; guasto acquisizione/configurazione tipizzato."
  (%native-check-backend backend)
  (let ((fd (%native-required backend :socket)))
    (unless (typep fd 'native-fd) (%native-fail :local-native-result :socket))
    (%native-configured-fd fd backend)))
;;; REQ: REQ-IPC-001 REQ-AFF-004
(defun new-local-socket (&key backend)
  "Pre: backend valido. Post: FD privato configurato; ownership al caller."
  (native-socket-new :backend backend))

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) (values string native-octets list string &optional))
                native-path-preflight))
(defun native-path-preflight (path)
  "Pre: percorso esterno. Post: copia assoluta UTF-8 <=100 byte, senza NUL/dot/doppi slash.
Ownership: copie bounded private, nessun filesystem toccato; INVALID-ARGUMENT su rifiuto."
  (unless (and (stringp path) (<= 2 (length path) 100) (char= #\/ (char path 0))
               (not (find #\Null path)) (not (char= #\/ (char path (1- (length path))))))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-socket-path))
  (loop for char across path for code = (char-code char) do
    (unless (and (<= code #x10ffff) (not (<= #xd800 code #xdfff)))
      (error 'arcdocdb.conditions:invalid-argument :reason :local-socket-path)))
  (let* ((stable (copy-seq path)) (components nil) (start 1)
         (bytes (sb-ext:string-to-octets stable :external-format :utf-8 :null-terminate nil)))
    (unless (<= (length bytes) 100)
      (error 'arcdocdb.conditions:invalid-argument :reason :local-socket-path-bytes))
    (arcdocdb.utf8:verifica-utf8 bytes 0 (length bytes) :max-bytes 100)
    (loop for end from 1 to (length stable) do
      (when (or (= end (length stable)) (char= #\/ (char stable end)))
        (let ((part (subseq stable start end)))
          (when (member part '("" "." "..") :test #'string=)
            (error 'arcdocdb.conditions:invalid-argument :reason :local-socket-path-component))
          (push part components))
        (setf start (1+ end))))
    (setf components (nreverse components))
    (values stable bytes (butlast components) (car (last components)))))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t t &key (:backend t)) (values integer fixnum &optional)) native-connect)
         (ftype (function (t &key (:backend t)) (values integer fixnum &optional)) native-accept)
         (ftype (function (t &key (:backend t)) fixnum) native-socket-error))
(defun native-connect (fd path &key backend)
  "Pre: FD privato configurato, path esterno. Post: un connect, n/errno senza attesa/retry.
Ownership: FD resta al caller su EINPROGRESS/EINTR e guasti; nessuna unlink."
  (%native-check-fd fd) (%native-check-backend backend)
  (multiple-value-bind (stable bytes) (native-path-preflight path)
    (declare (ignore stable))
    (multiple-value-bind (n errno) (%native-call backend :connect fd bytes)
      (%native-result n errno 0 :connect))))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun native-accept (listener-fd &key backend)
  "Pre: listener NONBLOCK posseduto. Post: un accept, FD configurato o -1/errno.
Ownership: nuovo FD al caller solo dopo configurazione; nessuna attesa o retry."
  (%native-check-fd listener-fd) (%native-check-backend backend)
  (multiple-value-bind (fd errno) (%native-call backend :accept listener-fd)
    (%native-result fd errno 2147483647 :accept)
    (if (= fd -1) (values fd errno) (values (%native-configured-fd fd backend) 0))))
;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun native-socket-error (fd &key backend)
  "Pre: FD socket posseduto. Post: SO_ERROR non negativo; nessun successo dedotto da writable.
Ownership: nessuna chiusura; syscall/callback invalidi diventano condizioni ArcDocDB."
  (%native-check-fd fd) (%native-check-backend backend)
  (let ((errno (%native-required backend :socket-error fd)))
    (unless (typep errno '(integer 0 #.most-positive-fixnum))
      (%native-fail :local-native-result :socket-error)) errno))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(defstruct (native-directory (:constructor %make-native-directory (fd path parent name)) (:copier nil))
  "Pre: FD appena aperto. Post: ownership registrata prima di fstat; chiusura una sola volta."
  (fd -1 :type (integer -1 2147483647))
  (path "/" :type string :read-only t)
  (parent -1 :type (integer -1 2147483647) :read-only t)
  (name "" :type string :read-only t)
  (node nil :type (or null native-node)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(defstruct (local-namespace (:constructor %make-local-namespace (path bytes leaf uid backend)) (:copier nil))
  "Pre: path verificato. Post: anchor privato, FD leaf-first conservati fino a close.
Un lock esclusivo sulla directory runtime vieta intenzionalmente due listener nella stessa dir."
  (path "" :type string :read-only t)
  (bytes (make-array 0 :element-type '(unsigned-byte 8)) :type native-octets :read-only t)
  (leaf "" :type string :read-only t)
  (uid 0 :type (integer 0 #xffffffff) :read-only t)
  (backend nil :type (or null native-backend) :read-only t)
  (directories nil :type list)
  (closed-p nil :type boolean))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) local-namespace) %native-check-namespace)
         (ftype (function (native-node native-node) boolean) %native-same-node-p))
(defun %native-check-namespace (namespace)
  "Pre: handle esterno. Post: anchor aperto con almeno root; ownership resta al caller."
  (unless (and (typep namespace 'local-namespace) (not (local-namespace-closed-p namespace))
               (local-namespace-directories namespace))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-namespace-state))
  namespace)
;;; REQ: REQ-IPC-003 REQ-AFF-004
(defun %native-same-node-p (left right)
  "Pre: due snapshot verificati. Post: confronto device/inode, nessun effetto o FD acquisito."
  (and (= (native-node-device left) (native-node-device right))
       (= (native-node-inode left) (native-node-inode right))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) native-node) %native-check-node)
         (ftype (function (native-node integer boolean) null) %native-directory-policy))
(defun %native-check-node (value)
  "Pre: risultato metadata backend. Post: snapshot di tipo esatto o errore; nessuna ownership."
  (unless (typep value 'native-node) (%native-fail :local-native-metadata :metadata)) value)
;;; REQ: REQ-IPC-003 REQ-AFF-004
(defun %native-directory-policy (node uid private-p)
  "Pre: snapshot verificato e UID di servizio. Post: directory trusted non scrivibile group/world.
Runtime esattamente 0700/service UID; antenati root o service UID, nessun symlink."
  (unless (and (sb-posix:s-isdir (native-node-mode node))
               (zerop (logand #o22 (native-node-mode node)))
               (member (native-node-uid node) (list 0 uid)))
    (%native-fail :local-namespace-untrusted :namespace))
  (when private-p
    (unless (and (= uid (native-node-uid node)) (= #o700 (logand #o7777 (native-node-mode node))))
      (%native-fail :local-namespace-private :namespace)))
  nil)

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (local-namespace keyword &rest t) native-node) %native-node-call))
(defun %native-node-call (namespace operation &rest arguments)
  "Pre: anchor interno. Post: metadata verificati, errore prima di usare un tipo estraneo."
  (%native-check-node (apply #'%native-required (local-namespace-backend namespace) operation arguments)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (local-namespace) null) %native-verify-namespace))
(defun %native-verify-namespace (namespace)
  "Pre: anchor aperto. Post: FD/fstat, lstat assoluto e fstatat parent concordano per ogni livello.
Ownership: tutti i FD trattenuti. Root/service UID fidati non devono mutare il namespace:
bind/chmod Unix usano pathname, non esiste qui un bindat portabile o un alias /dev/fd."
  (%native-check-namespace namespace)
  (let ((leaf (car (local-namespace-directories namespace))))
    (dolist (directory (local-namespace-directories namespace))
      (let* ((saved (native-directory-node directory))
             (actual (%native-node-call namespace :fstat (native-directory-fd directory)))
             (named (%native-node-call namespace :lstat (native-directory-path directory))))
        (%native-directory-policy actual (local-namespace-uid namespace) (eq directory leaf))
        (%native-directory-policy named (local-namespace-uid namespace) (eq directory leaf))
        (unless (and saved (%native-same-node-p saved actual) (%native-same-node-p saved named))
          (%native-fail :local-namespace-replaced :namespace))
        (when (>= (native-directory-parent directory) 0)
          (let ((relative (%native-node-call namespace :entry (native-directory-parent directory)
                                             (native-directory-name directory))))
            (unless (%native-same-node-p saved relative)
              (%native-fail :local-namespace-replaced :namespace)))))))
  nil)

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (local-namespace) (or null native-node)) %native-socket-node))
(defun %native-socket-node (namespace)
  "Pre: anchor aperto. Post: node da fstatat NOFOLLOW, NIL soltanto per ENOENT.
Ownership: nessuna apertura/unlink; errori di accesso non diventano assenza."
  (let ((directory (car (local-namespace-directories namespace))))
    (multiple-value-bind (node errno)
        (%native-call (local-namespace-backend namespace) :entry
                      (native-directory-fd directory) (local-namespace-leaf namespace))
      (cond ((not (eql node -1)) (%native-check-node node))
            ((= errno sb-posix:enoent) nil)
            (t (%native-fail :local-native-syscall :entry :errno errno))))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &optional t) list) close-local-namespace))
(defun close-local-namespace (namespace &optional primary)
  "Pre: anchor proprio, nessun listener borrower aperto. Post: tries-all, cause in ordine.
Ownership: ogni FD consumato prima di close, incluso zero; lock rilasciato con il FD runtime.
Primaria restituita per prima; non segnala secondarie e non ritenta EINTR."
  (unless (and (typep namespace 'local-namespace) (typep primary '(or null condition)))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-namespace-state))
  (let ((failures nil))
    (unless (local-namespace-closed-p namespace)
      (setf (local-namespace-closed-p namespace) t)
      (dolist (directory (local-namespace-directories namespace))
        (let ((fd (native-directory-fd directory)))
          (setf (native-directory-fd directory) -1)
          (when (>= fd 0)
            (let ((failure (native-close fd :backend (local-namespace-backend namespace))))
              (when failure (push failure failures)))))))
    (append (if primary (list primary) nil) (nreverse failures))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (local-namespace integer string integer string) null) %native-add-directory))
(defun %native-add-directory (namespace fd path parent name)
  "Pre: nuovo FD acquisito. Post: ownership registrata prima di fstat/policy, errno conservato.
Root e ciascun componente restano aperti fino al cleanup dell'anchor."
  (unless (typep fd 'native-fd) (%native-fail :local-native-result :open-directory))
  (let* ((directory (%make-native-directory fd path parent name))
         (backend (local-namespace-backend namespace)))
    (push directory (local-namespace-directories namespace))
    (setf (native-directory-node directory) (%native-check-node (%native-required backend :fstat fd)))
    (%native-directory-policy (native-directory-node directory) (local-namespace-uid namespace) nil))
  nil)

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &key (:backend t)) local-namespace) open-local-namespace))
(defun open-local-namespace (path &key backend)
  "Pre: path esterno, prima del motore. Post: runtime privata verificata e flock EX|NB trattenuto.
Ownership: anchor possiede root/antenati/runtime; nessun nodo creato o cancellato.
Namespace trusted root/service UID immutabile durante l'uso; occupied sempre preservato.
Lock per directory intenzionale, non per nome; fallimento chiude tutti i FD e conserva cause."
  (%native-check-backend backend)
  (multiple-value-bind (stable bytes components leaf) (native-path-preflight path)
    (let ((uid (%native-required backend :uid)))
      (unless (typep uid '(integer 0 #xffffffff)) (%native-fail :local-native-result :uid))
      (let ((namespace (%make-local-namespace stable bytes leaf uid backend)))
        (handler-case
            (progn
              (%native-add-directory namespace (%native-required backend :root) "/" -1 "")
              (dolist (component components)
                (let* ((parent (car (local-namespace-directories namespace)))
                       (prefix (native-directory-path parent))
                       (path (concatenate 'string prefix (if (string= prefix "/") "" "/") component))
                       (fd (%native-required backend :openat (native-directory-fd parent) component)))
                  (%native-add-directory namespace fd path (native-directory-fd parent) component)))
              (%native-verify-namespace namespace)
              (unless (eql 0 (%native-required backend :lock
                                             (native-directory-fd (car (local-namespace-directories namespace)))))
                (%native-fail :local-native-result :lock))
              (%native-verify-namespace namespace)
              (when (%native-socket-node namespace) (%native-fail :local-socket-occupied :namespace))
              namespace)
          (error (primary)
            (%native-fail :local-namespace-open :namespace :primary primary
                          :cleanup (close-local-namespace namespace))))))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) (values integer integer &optional)) local-namespace-identity))
(defun local-namespace-identity (namespace)
  "Pre: anchor aperto. Post: device/inode runtime da FD verificato; confronto datadir prima del motore.
Ownership: anchor resta al parent; nessuna identita' dedotta dal percorso testuale."
  (%native-check-namespace namespace)
  (%native-verify-namespace namespace)
  (let ((node (native-directory-node (car (local-namespace-directories namespace)))))
    (values (native-node-device node) (native-node-inode node))))

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(defstruct (native-listener (:constructor %make-native-listener (path backend anchor owns-anchor-p)) (:copier nil))
  "Pre: anchor validato. Post: listener possiede FD/nodo e solo l'anchor aperto internamente."
  (fd -1 :type (integer -1 2147483647))
  (path "" :type string :read-only t)
  (backend nil :type (or null native-backend) :read-only t)
  (anchor nil :type (or null local-namespace) :read-only t)
  (owns-anchor-p nil :type boolean :read-only t)
  (node nil :type (or null native-node))
  (closed-p nil :type boolean))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t) native-listener) %native-check-listener)
         (ftype (function (t) native-fd) handle-socket))
(defun %native-check-listener (listener)
  "Pre: handle esterno. Post: listener aperto e FD posseduto; nessun effetto."
  (unless (and (typep listener 'native-listener) (not (native-listener-closed-p listener))
               (typep (native-listener-fd listener) 'native-fd))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-listener-state))
  listener)
;;; REQ: REQ-IPC-001 REQ-AFF-004
(defun handle-socket (listener)
  "Pre: listener aperto. Post: FD preso in prestito per un passo; non chiuderlo separatamente."
  (native-listener-fd (%native-check-listener listener)))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (native-listener) null) %native-verify-socket))
(defun %native-verify-socket (listener)
  "Pre: bind riuscito e identita' catturata. Post: node/path NOFOLLOW concordanti, socket service UID.
Ownership: nessun unlink su identita' sostituita; mode controllato separatamente dopo chmod."
  (let* ((namespace (native-listener-anchor listener))
         (node (%native-socket-node namespace))
         (named (%native-node-call namespace :lstat (native-listener-path listener)))
         (saved (native-listener-node listener)))
    (unless (and node saved (%native-same-node-p saved node) (%native-same-node-p saved named)
                 (sb-posix:s-issock (native-node-mode node))
                 (sb-posix:s-issock (native-node-mode named))
                 (= (native-node-uid node) (local-namespace-uid namespace))
                 (= (native-node-uid named) (local-namespace-uid namespace)))
      (%native-fail :local-socket-replaced :namespace)))
  nil)

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (native-listener) null) %native-unlink-owned))
(defun %native-unlink-owned (listener)
  "Pre: listener possiede identita' dopo bind. Post: unlinkat soltanto dello stesso nodo.
Ownership: assenza tollerata, replacement diagnosticato/preservato; anchor FD fino al termine.
La garanzia richiede root/service UID fedeli al contratto namespace durante check/unlinkat."
  (when (native-listener-node listener)
    (let ((namespace (native-listener-anchor listener)))
      (%native-verify-namespace namespace)
      (when (%native-socket-node namespace)
        (%native-verify-socket listener)
        (unless (eql 0 (%native-required (native-listener-backend listener) :unlink
                           (native-directory-fd (car (local-namespace-directories namespace)))
                           (local-namespace-leaf namespace)))
          (%native-fail :local-native-result :unlink)))))
  nil)

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &optional t) list) native-close-listener))
(defun native-close-listener (listener &optional primary)
  "Pre: handle posseduto, causa opzionale. Post: tries-all FD/nodo/anchor proprio, cause conservate.
Ownership: FD consumato prima di close; anchor prestato resta al parent anche in caso di errore.
Idempotente, nessun retry della close, replacement intatto e diagnosticato."
  (unless (and (typep listener 'native-listener) (typep primary '(or null condition)))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-listener-state))
  (let ((failures nil))
    (unless (native-listener-closed-p listener)
      (setf (native-listener-closed-p listener) t)
      (let ((fd (native-listener-fd listener)))
        (setf (native-listener-fd listener) -1)
        (when (>= fd 0)
          (let ((failure (native-close fd :backend (native-listener-backend listener))))
            (when failure (push failure failures)))))
      (handler-case (%native-unlink-owned listener)
        (error (condition) (push condition failures)))
      (when (native-listener-owns-anchor-p listener)
        (setf failures (nconc (reverse (close-local-namespace (native-listener-anchor listener))) failures))))
    (append (if primary (list primary) nil) (nreverse failures))))

;;; REQ: REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &optional t) null) close-local-listener))
(defun close-local-listener (listener &optional primary)
  "Pre: handle posseduto. Post: cleanup completo; NATIVE-ERROR conserva tutte le cause.
Ownership: anchor borrowed non chiuso; al parent il rilascio dopo engine close."
  (let ((failures (native-close-listener listener primary)))
    (when failures
      (%native-fail :local-listener-cleanup :close-listener :primary (car failures)
                    :cleanup (cdr failures))))
  nil)

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (native-listener) native-listener) %native-bind-listener))
(defun %native-bind-listener (listener)
  "Pre: parent ha verificato engine READY, namespace esclusivo. Post: socket 0600 prima di listen.
Ownership: FD/nodo registrati subito; identita' controllate prima/dopo bind/chmod/listen.
Bind per pathname richiede root/service UID fidati e namespace stabile, senza alias /dev/fd."
  (let* ((namespace (native-listener-anchor listener)) (backend (native-listener-backend listener)))
    (%native-verify-namespace namespace)
    (when (%native-socket-node namespace) (%native-fail :local-socket-occupied :bind))
    (setf (native-listener-fd listener) (native-socket-new :backend backend))
    (%native-verify-namespace namespace)
    (unless (eql 0 (%native-required backend :bind (native-listener-fd listener) (local-namespace-bytes namespace)))
      (%native-fail :local-native-result :bind))
    ;; Se questo snapshot fallisce, nessuna unlink senza prova: l'orfano resta conservato.
    (setf (native-listener-node listener) (%native-socket-node namespace))
    (%native-verify-namespace namespace)
    (%native-verify-socket listener)
    (unless (eql 0 (%native-required backend :chmod (native-listener-path listener)))
      (%native-fail :local-native-result :chmod))
    (%native-verify-namespace namespace)
    (%native-verify-socket listener)
    (let ((node (%native-socket-node namespace)))
      (unless (= #o600 (logand #o7777 (native-node-mode node)))
        (%native-fail :local-socket-permissions :chmod)))
    (unless (eql 0 (%native-required backend :listen (native-listener-fd listener)))
      (%native-fail :local-native-result :listen))
    (%native-verify-namespace namespace)
    (%native-verify-socket listener)
    listener))

;;; REQ: REQ-IPC-001 REQ-IPC-003 REQ-AFF-004
(declaim (ftype (function (t &key (:namespace t) (:backend t)) native-listener) open-local-listener))
(defun open-local-listener (path &key namespace (backend nil backend-p))
  "Pre: parent ha terminato recovery e verificato engine READY, attore I/O proprietario.
Post: listener Unix NONBLOCK/CLOEXEC e 0600, oppure cleanup completo e nodo occupato intatto.
Ownership: :NAMESPACE preso in prestito; anchor interno chiuso con listener, engine al parent."
  (multiple-value-bind (stable bytes) (native-path-preflight path)
    (declare (ignore bytes))
    (when namespace
      (%native-check-namespace namespace)
      (unless (string= stable (local-namespace-path namespace))
        (error 'arcdocdb.conditions:invalid-argument :reason :local-namespace-path))
      (when (and backend-p (not (eq backend (local-namespace-backend namespace))))
        (error 'arcdocdb.conditions:invalid-argument :reason :local-namespace-backend))
      (setf backend (local-namespace-backend namespace)))
    (%native-check-backend backend)
    (let* ((anchor (or namespace (open-local-namespace stable :backend backend)))
           (listener (%make-native-listener stable backend anchor (null namespace))))
      (handler-case (%native-bind-listener listener)
        (error (primary)
          (%native-fail :local-listener-open :open-listener :primary primary
                        :cleanup (native-close-listener listener)))))))

;;; REQ: REQ-IPC-001 REQ-REC-001 REQ-AFF-004
(declaim (ftype (function (t t &key (:backend t)) native-listener) native-open-listener))
(defun native-open-listener (path ready-p &key backend)
  "Pre: callback gate fidato. Post: listener solo dopo risultato esattamente T; nessun effetto prima.
Ownership: listener possiede anchor interno; INVALID-ARGUMENT o guasto tipizzato."
  (unless (functionp ready-p)
    (error 'arcdocdb.conditions:invalid-argument :reason :local-ready-function))
  (handler-case
      (unless (eq t (funcall ready-p)) (%native-fail :local-engine-not-ready :open-listener))
    (arcdocdb.conditions:arcdocdb-error (condition) (error condition))
    (error (condition) (%native-fail :local-ready-callback :open-listener :primary condition)))
  (open-local-listener path :backend backend))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t) (values (or null native-fd) fixnum &optional)) accept-local-socket))
(defun accept-local-socket (listener)
  "Pre: handle listener aperto. Post: FD NONBLOCK/CLOEXEC o NIL solo per EAGAIN/EINTR.
Ownership: nuovo FD al parent; errore fatale segnalato, nessun retry o attesa."
  (%native-check-listener listener)
  (multiple-value-bind (fd errno)
      (native-accept (native-listener-fd listener) :backend (native-listener-backend listener))
    (cond ((>= fd 0) (values fd 0))
          ((member errno (list sb-posix:eagain sb-posix:ewouldblock sb-posix:eintr)) (values nil errno))
          (t (%native-fail :local-native-syscall :accept :errno errno)))))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (t t &key (:backend t) (:clock t)) native-fd) connect-local-socket))
(defun connect-local-socket (path until &key backend (clock #'get-internal-real-time))
  "Pre: path esterno, deadline assoluta in tick INTERNAL-TIME-UNITS-PER-SECOND, clock monotono.
Post: FD connesso dopo SO_ERROR=0; attesa FD finita fuori da recv/send, nessun retry di connect.
Ownership: FD chiuso su guasto; clock iniettabile, nessuna attesa con connect immediata."
  (unless (and (typep until '(integer 0 *)) (functionp clock))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-connect-deadline))
  (native-path-preflight path)
  (%native-check-backend backend)
  (let ((fd nil))
    (handler-case
        (let ((now (%native-connect-time clock 0 until)))
          (setf fd (native-socket-new :backend backend))
          (setf now (%native-connect-time clock now until))
          (multiple-value-bind (n errno) (native-connect fd path :backend backend)
            (unless (zerop n)
              (unless (member errno (list sb-posix:einprogress sb-posix:eintr sb-posix:ealready))
                (%native-fail :local-native-syscall :connect :errno errno))
              (setf now (%native-await-connect fd until now clock backend)))
            (let ((error-code (native-socket-error fd :backend backend)))
              (unless (zerop error-code) (%native-fail :local-native-syscall :connect :errno error-code))))
          (%native-connect-time clock now until)
          fd)
      (error (primary)
        (let ((cleanup (and fd (native-close fd :backend backend))))
          (%native-fail :local-connect :connect :primary primary :cleanup (if cleanup (list cleanup) nil)))))))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (function integer integer) integer) %native-connect-time))
(defun %native-connect-time (clock previous until)
  "Pre: clock fidato e tick precedenti. Post: tick non decrescenti, strettamente prima di UNTIL.
Ownership: nessun FD acquisito/chiuso; esito clock invalido e deadline sono NATIVE-ERROR."
  (let ((now (funcall clock)))
    (unless (and (typep now '(integer 0 *)) (<= previous now) (< now until))
      (%native-fail :local-connect-deadline :connect))
    now))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(declaim (ftype (function (native-fd integer integer function t) integer) %native-await-connect))
(defun %native-await-connect (fd until previous clock backend)
  "Pre: connect gia' tentata, deadline assoluta. Post: FD writable prima della deadline e clock monotono.
Ownership: una attesa fuori dall'adattatore; backend :wait-output(fd,seconds)->boolean,errno."
  (let ((now (%native-connect-time clock previous until)))
    (let* ((seconds (/ (- until now) internal-time-units-per-second))
           (ready (if backend (%native-required backend :wait-output fd seconds)
                      (sb-sys:wait-until-fd-usable fd :output seconds nil)))
           (after (%native-connect-time clock now until)))
      (unless (eq ready t) (%native-fail :local-connect-deadline :connect))
      after)))
