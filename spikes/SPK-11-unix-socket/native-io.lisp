;;;; C4: soltanto qui ABI, SAP e recv/send; nessun buffer alien temporaneo.
;;; OWNER: FD e vettore semplici del caller, pin limitato alla singola syscall.
;;; REQ: REQ-VAL-001 REQ-IPC-002
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(deftype io-octets () '(simple-array (unsigned-byte 8) (*)))
(deftype io-index () '(integer 0 #.most-positive-fixnum))
(deftype io-fd () '(integer 0 2147483647))

;; sys/socket.h delle due ABI ammesse; piattaforme estranee rifiutate.
#+darwin (defconstant +io-dontwait+ #x80)
#+darwin (defconstant +io-nosignal+ #x80000)
#+linux (defconstant +io-dontwait+ #x40)
#+linux (defconstant +io-nosignal+ #x4000)

;; Il SAP entra direttamente nell'FFI: il wrapper non inline lo boxed su heap.
(declaim (inline %io-recv %io-send))
(sb-alien:define-alien-routine ("recv" %io-recv) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (count sb-alien:unsigned-long) (flags sb-alien:int))
(sb-alien:define-alien-routine ("send" %io-send) sb-alien:long
  (fd sb-alien:int) (buffer sb-alien:system-area-pointer)
  (count sb-alien:unsigned-long) (flags sb-alien:int))

(defun check-io-platform ()
  "Rifiuta ABI non previste prima di esporre i wrapper sperimentali."
  (demand (and (= sb-vm:n-word-bits 64)
               #+(or (and darwin arm64) (and linux x86-64)) t
               #-(or (and darwin arm64) (and linux x86-64)) nil)
          :io-platform))

(declaim (ftype (function (io-fd io-octets io-index io-index)
                         (values (signed-byte 64) fixnum &optional))
                native-recv-span native-send-span))

(defun native-recv-span (fd buffer start count)
  "Pre: span valido non vuoto, buffer esclusivo. Una recv non bloccante.
Post: n/errno catturato prima di ogni altro codice; pin e SAP non escono."
  #-(or darwin linux) (error 'rejection :reason :io-platform)
  #+(or darwin linux)
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%io-recv fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start)
                       count +io-dontwait+)))
      (values n (if (= n -1) (sb-alien:get-errno) 0)))))

(defun native-send-span (fd buffer start count)
  "Pre: span valido non vuoto e stabile. Una send non bloccante senza SIGPIPE.
Post: n/errno immediato, nessuna slice, copia temporanea o retry."
  #-(or darwin linux) (error 'rejection :reason :io-platform)
  #+(or darwin linux)
  (sb-sys:with-pinned-objects (buffer)
    (let ((n (%io-send fd (sb-sys:sap+ (sb-sys:vector-sap buffer) start)
                       count (logior +io-dontwait+ +io-nosignal+))))
      (values n (if (= n -1) (sb-alien:get-errno) 0)))))
