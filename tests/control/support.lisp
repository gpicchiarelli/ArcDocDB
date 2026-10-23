;;;; Harness CONTROL: il runner possiede il registro; fixture native e iniettate autonome.
;;; OWNER: runner seriale, registrazione soltanto al caricamento dei file di test.
;;; SHARED: nessuno stato di prodotto o fixture condiviso con altre suite.
;;; REQ: REQ-AFF-003 REQ-REC-001
(defpackage #:arcdocdb.control.tests
  (:use #:cl)
  (:local-nicknames (#:io #:arcdocdb.io) (#:c #:arcdocdb.control)
                   (#:a #:arcdocdb.active) (#:g #:arcdocdb.get))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected #:unsupported-format
                #:io-fault #:error-reason #:error-offset #:error-operation #:error-errno)
  (:export #:run))
(in-package #:arcdocdb.control.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; OWNER: runner; elenco di simboli compatibile con la selezione test-REQ-..-CONTROL-*.
(defvar *tests* nil)

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (pushnew ',name *tests*)))

;;; REQ: REQ-AFF-003
(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test CONTROL superati.~%" (length *tests*))
  t)

;;; REQ: REQ-AFF-008
(defun zeros (size)
  (make-array size :element-type '(unsigned-byte 8) :initial-element 0))
