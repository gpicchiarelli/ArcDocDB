;;;; Harness delle fondazioni: oracoli indipendenti e seme deterministico.
(defpackage #:arcdocdb.foundation.tests
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:crc32c #:leggi-u16 #:leggi-u32 #:leggi-u64
                #:scrivi-u16 #:scrivi-u32 #:scrivi-u64)
  (:import-from #:arcdocdb.record #:scrivi-record #:verifica-record #:verifica-put
                #:verifica-lotto #:+max-record-bytes+ #:+max-document-bytes+)
  (:import-from #:arcdocdb.conditions #:corruption-detected #:resource-exhausted
                #:unsupported-format #:invalid-argument #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.foundation.tests)
(defvar *tests* nil)

(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body)
          (pushnew ',name *tests*)))

(defmacro is (expression)
  `(unless ,expression (error "Asserzione fallita: ~S" ',expression)))

(defmacro signals (type form &optional reason)
  `(is (handler-case (progn ,form nil)
         (,type (condition)
           ,(if reason `(eq (error-reason condition) ,reason)
                `(typep condition ',type))))))

(defun bytes (&rest contents)
  (make-array (length contents) :element-type '(unsigned-byte 8)
              :initial-contents contents))

(defun reference-crc (buffer start end &optional (seed 0))
  "Oracolo bit per bit, indipendente dalle tabelle e dall'unrolling del prodotto."
  (let ((crc (logxor seed #xffffffff)))
    (loop for i from start below end
          do (setf crc (logxor crc (aref buffer i)))
             (dotimes (bit 8)
               (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))

(defun fixture (&key (version 2) (kind 1) (stamp 19) (flags 0)
                     (key (bytes 7 8)) (value (bytes #xa0)) (prefix 5))
  (let* ((end (+ prefix 24 (length key) (length value)))
         (buffer (make-array (+ end 7) :element-type '(unsigned-byte 8)
                             :initial-element #xcc)))
    (scrivi-record buffer prefix kind stamp key value :version version :flags flags)
    (values buffer prefix end key value)))

(defun repair-header (buffer start)
  "Ricalcola con l'oracolo indipendente per campi malformati ma CRC validi."
  (scrivi-u32 buffer start (reference-crc buffer (+ start 4) (+ start 24))))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test delle fondazioni superati.~%" (length *tests*))
  t)
