;;; OWNER: loader seriale del registro, fixture privata per test.
;;; SHARED: sola politica immutabile, mai quote mutabili fra Serie.
;;; REQ: REQ-IDX-008 REQ-AFF-003 REQ-AFF-008
(defpackage #:arcdocdb.index.mode.tests
  (:use #:cl)
  (:local-nicknames (#:m #:arcdocdb.index.mode))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted)
  (:export #:run))
(in-package #:arcdocdb.index.mode.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defvar *tests* nil)

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  "Pre: corpo statico. Post: funzione registrata dal loader, nessun worker."
  `(progn (declaim (ftype (function () t) ,name))
          (defun ,name () ,@body) (pushnew ',name *tests*)))

;;; REQ: REQ-AFF-003
(declaim (ftype (function () boolean) run))
(defun run ()
  "Pre: suite caricata. Post: T solo se tutti i test passano; errori propagati."
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test del modo automatico superati.~%" (length *tests*)) t)

;;; REQ: REQ-IDX-008
(declaim (ftype (function (m:politica-indice keyword fixnum fixnum fixnum fixnum
                           keyword keyword) boolean) decisione))
(defun decisione (policy current budget resident paged migration target action)
  "Pre: campione esplicito e oracolo manuale. Post: verifica entrambi i valori."
  (multiple-value-bind (actual-target actual-action)
      (m:valuta-modo-indice policy current budget resident paged migration)
    (is (eq actual-target target)) (is (eq actual-action action)))
  t)
