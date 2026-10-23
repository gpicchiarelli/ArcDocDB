;;; OWNER: runner seriale, fixture indipendenti possedute dal singolo test.
;;; SHARED: nessuno; non e' un test di cache o concorrenza del motore.
;;; REQ: REQ-IDX-009 REQ-AFF-003
(defpackage #:arcdocdb.index.page.tests
  (:use #:cl)
  (:local-nicknames (#:p #:arcdocdb.index.page))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:error-reason
                #:invalid-argument #:corruption-detected #:unsupported-format)
  (:export #:run))
(in-package #:arcdocdb.index.page.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))
(defvar *tests* nil)
(defmacro deftest (name &body body)
  "Pre: nome tracciato, corpo statico. Post: test registrato una volta dal loader."
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  "Pre: suite caricata. Post: T se tutti i test completano; errori propagati."
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test delle pagine indice superati.~%" (length *tests*)) t)

(defun bytes (size &optional (value 0))
  (make-array size :element-type '(unsigned-byte 8) :initial-element value))
(defun ref-write (buffer offset value width)
  (dotimes (i width) (setf (aref buffer (+ offset i)) (mod value 256) value (floor value 256))))
(defun ref-read (buffer offset width)
  (loop for i below width sum (* (aref buffer (+ offset i)) (expt 256 i))))
(defun ref-crc (buffer start end)
  (let ((crc #xffffffff))
    (loop for i from start below end do
      (setf crc (logxor crc (aref buffer i)))
      (dotimes (bit 8) (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))
(defun repair (buffer start end)
  (ref-write buffer (+ start 88) (ref-crc buffer start (+ start 88)) 4)
  (ref-write buffer (+ start 92) (ref-crc buffer (+ start 96) end) 4))
(defun series ()
  (make-array 16 :element-type '(unsigned-byte 8)
                :initial-contents '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 255)))
(defun identita-fixture (size &key (page (* size 4096)) (generation 7) (image 91))
  (p:crea-identita-pagina (series) image page generation))
(defun capacity (size)
  (ecase size (4096 32) (16384 128) (65536 512)))
(defun rejected (thunk type reason)
  (let ((caught nil))
    (handler-case (funcall thunk) (arcdocdb-error (c) (setf caught c)))
    (is caught) (is (typep caught type)) (when reason (is (eq reason (error-reason caught))))))
