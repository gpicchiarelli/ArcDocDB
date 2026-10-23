;;;; Harness EBR: oracoli pubblici e immagini private soltanto per rifiuti e FI.
;;;; OWNER: ciascun caso possiede il dominio; ogni reader ha un solo worker vivo.
;;;; SHARED: i casi concorrenti hanno semafori e join con scadenza esplicita.
(defpackage #:arcdocdb.epochs.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:error-reason)
  (:import-from #:arcdocdb.epochs #:crea-registro-epoche #:contesto-epoca
                #:entra-epoca #:esci-epoca #:epoca-attiva-p
                #:prenota-ritiro #:annulla-ritiro #:pubblica-ritiro
                #:aggiorna-soglia-reclaim #:acquisisci-reclaim #:completa-reclaim
                #:leggi-risorsa-ritiro #:leggi-ritiro #:leggi-registro-epoche)
  (:export #:run))
(in-package #:arcdocdb.epochs.tests)
(declaim (optimize (safety 3) (debug 3)))

(defvar *epochs-tests* nil)
(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (setf *epochs-tests*
           (acons ',name #',name (remove ',name *epochs-tests* :key #'car)))))

(defun run ()
  (dolist (entry (reverse *epochs-tests*))
    (funcall (cdr entry))
    (format t "ok    ~A~%" (car entry)))
  (format t "~D test epoche/reclaim superati.~%" (length *epochs-tests*))
  t)

(defconstant +epochs-maximum+ 18446744073709551615)

(define-condition fixture-timeout (error)
  ((operation :initarg :operation :reader fixture-timeout-operation))
  (:report (lambda (condition stream)
             (format stream "Fixture timeout EBR: ~A oltre il limite."
                     (fixture-timeout-operation condition)))))

(defun epochs-state (registry)
  (multiple-value-list (leggi-registro-epoche registry)))

(defun epochs-check-state (registry epoch threshold count reserved)
  (is (equal (list epoch threshold count reserved) (epochs-state registry)))
  t)

(defun epochs-check-ticket (ticket generation state epoch)
  (is (equal (list state epoch) (multiple-value-list (leggi-ritiro ticket generation))))
  t)

(defun epochs-private-image (registry)
  "Solo immagine di conservazione/FI, mai oracolo delle frontiere pubbliche."
  (list (arcdocdb.epochs::registro-epoche-health registry)
        (arcdocdb.epochs::registro-epoche-count registry)
        (arcdocdb.epochs::registro-epoche-reserved registry)
        (arcdocdb.epochs::registro-epoche-cursor registry)
        (copy-seq (arcdocdb.epochs::registro-epoche-announcements registry))
        (copy-seq (arcdocdb.epochs::registro-epoche-generations registry))
        (copy-seq (arcdocdb.epochs::registro-epoche-epochs registry))
        (copy-seq (arcdocdb.epochs::registro-epoche-states registry))
        (copy-seq (arcdocdb.epochs::registro-epoche-resources registry))
        (copy-seq (arcdocdb.epochs::registro-epoche-words registry))))

(defun epochs-error (thunk type reason)
  (let ((observed (handler-case (progn (funcall thunk) nil)
                    (error (condition) condition))))
    (is (typep observed type))
    (is (eq reason (error-reason observed)))
    observed))

(defun epochs-refusal-preserves (registry thunk type reason)
  (let ((before (epochs-private-image registry)))
    (epochs-error thunk type reason)
    (is (equalp before (epochs-private-image registry))))
  t)

(defun epochs-ticket-operations (ticket generation)
  (list (lambda () (annulla-ritiro ticket generation))
        (lambda () (pubblica-ritiro ticket generation))
        (lambda () (acquisisci-reclaim ticket generation))
        (lambda () (completa-reclaim ticket generation))
        (lambda () (leggi-risorsa-ritiro ticket generation))
        (lambda () (leggi-ritiro ticket generation))))

(defun epochs-faulted-refusals (registry reader &optional ticket generation)
  (dolist (thunk (append (list (lambda () (leggi-registro-epoche registry))
                              (lambda () (prenota-ritiro registry (list :new-resource)))
                              (lambda () (aggiorna-soglia-reclaim registry))
                              (lambda () (entra-epoca reader)))
                        (when ticket (epochs-ticket-operations ticket generation))))
    (epochs-error thunk 'invariant-violation :epoch-registry-faulted))
  t)

(defun epochs-set-word (registry index value)
  "Iniezione privata su una fixture isolata; non modifica sorgenti o contratti."
  (setf (aref (arcdocdb.epochs::registro-epoche-words registry) index) value))

(defun epochs-deadline (&optional (seconds 5))
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun epochs-seconds-left (deadline)
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error 'fixture-timeout :operation :budget))
    (/ remaining (float internal-time-units-per-second 1d0))))

(defun epochs-wait (semaphore deadline)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout (epochs-seconds-left deadline))
    (error 'fixture-timeout :operation :semaphore))
  t)

(defun epochs-worker (name thunk)
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

(defun epochs-join (thread deadline)
  (let ((result (sb-thread:join-thread thread :timeout (epochs-seconds-left deadline)
                                           :default :epochs-timeout)))
    (when (eq result :epochs-timeout) (error 'fixture-timeout :operation :join))
    (when (typep result 'error) (error result))
    (is (eq result :ok))
    result))

(defun epochs-stop-workers (threads)
  "Cleanup limitato ai worker della fixture, anche dopo una gara fallita."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :epochs-terminated)
    (when (sb-thread:thread-alive-p thread)
      (error 'fixture-timeout :operation :cleanup)))
  nil)
