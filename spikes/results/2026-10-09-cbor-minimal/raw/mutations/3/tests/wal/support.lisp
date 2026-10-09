(defpackage #:arcdocdb.wal.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals #:bytes)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:io-fault
                #:invariant-violation #:corruption-detected)
  (:import-from #:arcdocdb.wal #:crea-lotto #:aggiungi-record #:sigilla-lotto #:riusa-lotto
                #:crea-log-io #:crea-gruppo #:aggiungi-lotto #:chiudi-gruppo #:riusa-gruppo
                #:scrivi-gruppo #:sincronizza-gruppo #:esegui-gruppo #:coperto-p #:annulla-gruppo
                #:stato-lotto #:stato-log #:stato-gruppo #:lunghezza-lotto)
  (:export #:run))
(in-package #:arcdocdb.wal.tests)
(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test WAL superati.~%" (length *tests*)) t)
(defun buffer (n) (make-array n :element-type '(unsigned-byte 8) :initial-element 0))
(defun fixture-lotto (&key (start 0) (durable 0) (stamp 19) (version 2) (kind :segment) (file-id 31))
  (let ((lotto (crea-lotto kind file-id :version version :capacity 512 :max-records 8)))
    (when (eq kind :segment) (aggiungi-record lotto 1 (bytes 17) (bytes 21)))
    (sigilla-lotto lotto stamp start durable) lotto))
(defun fixture-file (&key (writer (lambda (fd b start count) (declare (ignore fd b start)) count))
                         (flush (lambda (fd) (declare (ignore fd)) 0))
                         (max-transfer 268435456) (max-file-bytes #xffffffff))
  (arcdocdb.io:crea-temporaneo "fake.tmp" :max-transfer max-transfer :max-file-bytes max-file-bytes
    :backend (arcdocdb.io.tests::backend :writer writer :flush flush)))
(defun fixture-group (log &rest lots)
  (let ((group (crea-gruppo log :max-lots 8)))
    (dolist (lotto lots) (aggiungi-lotto group lotto))
    (chiudi-gruppo group) group))
