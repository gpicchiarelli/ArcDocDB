;;;; Harness autonomo dei compiti di lettura: registri reali e tempi logici espliciti.
(defpackage #:arcdocdb.read.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:snapshot-too-old #:error-reason)
  (:import-from #:arcdocdb.csn #:crea-registro-csn #:prendi-csn #:risolvi-csn)
  (:import-from #:arcdocdb.mvcc #:crea-registro-snapshot #:crea-contesto-snapshot
                #:registra-snapshot #:termina-snapshot #:scadi-snapshot
                #:verifica-snapshot #:leggi-registro-snapshot)
  (:import-from #:arcdocdb.epochs #:crea-registro-epoche #:contesto-epoca
                #:entra-epoca #:esci-epoca #:epoca-attiva-p
                #:prenota-ritiro #:pubblica-ritiro #:aggiorna-soglia-reclaim
                #:acquisisci-reclaim #:completa-reclaim)
  (:import-from #:arcdocdb.read #:crea-contesto-lettura #:stato-contesto-lettura
                #:avvia-lettura #:copia-limite-lettura #:concludi-lettura
                #:abbandona-lettura)
  (:export #:run))
(in-package #:arcdocdb.read.tests)

(defvar *read-tests* nil)

(define-condition fixture-timeout (error)
  ((phase :initarg :phase :reader fixture-timeout-phase))
  (:report (lambda (condition stream)
             (format stream "Budget della fixture reader esaurito: ~A."
                     (fixture-timeout-phase condition)))))

(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (setf *read-tests* (acons ',name #',name
                               (remove ',name *read-tests* :key #'car)))))

(defun run ()
  (dolist (test (reverse *read-tests*))
    (funcall (cdr test))
    (format t "ok    ~A~%" (car test)))
  (format t "~D test dei compiti di lettura superati.~%" (length *read-tests*))
  t)

(defun read-fixture (&key (base 0) (lifetime 20) (wait 5) (workers 2))
  "Attesi numerici da BASE intero; nessun helper delle suite snapshot/CSN."
  (multiple-value-bind (high low) (floor base 4294967296)
    (let* ((csns (crea-registro-csn :capacity 3 :initial-high high :initial-low low))
           (snapshots (crea-registro-snapshot csns 2 lifetime wait))
           (snapshot (crea-contesto-snapshot snapshots))
           (epochs (crea-registro-epoche workers 2))
           (reader (contesto-epoca epochs 0))
           (context (crea-contesto-lettura reader snapshots)))
      (values csns snapshots snapshot epochs reader context))))

(defmacro with-read-fixture ((csns snapshots snapshot epochs reader context) options &body body)
  `(multiple-value-bind (,csns ,snapshots ,snapshot ,epochs ,reader ,context)
       (read-fixture ,@options)
     (declare (ignorable ,csns ,snapshots ,snapshot ,epochs ,reader ,context))
     ,@body))

(defun read-words ()
  (make-array 3 :element-type '(unsigned-byte 64)
              :initial-contents '(119 65261 983)))

(defun read-check-idle (context reader)
  "Due osservazioni pubbliche del proprietario dopo il cleanup."
  (is (eq :idle (stato-contesto-lettura context)))
  (is (null (epoca-attiva-p reader))))

(defun read-check-faulted (context reader)
  (is (eq :faulted (stato-contesto-lettura context)))
  (is (null (epoca-attiva-p reader))))

(defun read-take (csns)
  (let ((token (multiple-value-list (prendi-csn csns))))
    (is (= 3 (length token)))
    token))

(defun read-resolve (csns token)
  (apply #'risolvi-csn csns token))

(defun read-private-words (context)
  "FI soltanto: nessun oracolo CSN o soglia viene ricavato dai privati."
  (arcdocdb.read::contesto-lettura-words context))

(defun read-fi-idle-word (index)
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (setf (aref (read-private-words context) index) 1)
    (signals invariant-violation (avvia-lettura context nil 0 10) :read-idle-data)
    (is (eq :faulted (stato-contesto-lettura context)))
    (is (null (epoca-attiva-p reader)))
    (abbandona-lettura context)
    (read-check-faulted context reader)
    (is (every #'zerop (read-private-words context)))))

(defun read-fi-active-current-word (index)
  (with-read-fixture (csns snapshots snapshot epochs reader context) ()
    (let* ((buffer (read-words)) (before (copy-seq buffer)))
      (unwind-protect
           (progn
             (is (avvia-lettura context nil 0 10))
             (setf (aref (read-private-words context) index) 1)
             (signals invariant-violation
               (copia-limite-lettura context buffer 1) :read-current-binding)
             (is (equalp before buffer))
             ;; Il guasto non libera una sezione che potrebbe ancora essere usata.
             (is (epoca-attiva-p reader))
             (is (eq :faulted (stato-contesto-lettura context))))
        (abbandona-lettura context))
      (read-check-faulted context reader))))
