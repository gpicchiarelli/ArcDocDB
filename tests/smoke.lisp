;;;; smoke.lisp — verifica minima: il sistema si carica e il package radice esiste.
;;;;
;;;; Nessuna dipendenza da framework di test finché QA-22 non è decisa.

(defpackage #:arcdocdb.tests
  (:use #:cl)
  (:export #:run))

(in-package #:arcdocdb.tests)

(defun check (name ok)
  (format t "~:[FAIL~;ok  ~]  ~A~%" ok name)
  ok)

(defun run ()
  "Esegue i controlli e segnala errore se uno fallisce."
  (let ((results
          (list (check "package ARCDOCDB presente" (find-package '#:arcdocdb))
                (check "ARCDOCDB:*VERSION* è una stringa"
                       (stringp (symbol-value (find-symbol "*VERSION*" '#:arcdocdb)))))))
    (unless (every #'identity results)
      (error "Smoke test fallito."))
    t))
