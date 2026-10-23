;;;; Harness snapshot/CSN: aritmetica e liste indipendenti dai vettori del prodotto.
;;;; OWNER: ciascun test possiede registri, contesti e buffer; FI privata solo su fixture isolate.
;;;; SHARED: capture.lisp coordina esplicitamente i worker; run esegue i casi in serie.
(defpackage #:arcdocdb.mvcc.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:snapshot-too-old #:error-reason)
  (:import-from #:arcdocdb.csn #:crea-registro-csn #:prendi-csn #:risolvi-csn #:leggi-frontiere-csn)
  (:import-from #:arcdocdb.mvcc #:crea-registro-snapshot #:crea-contesto-snapshot
                #:registra-snapshot #:attiva-snapshot #:termina-snapshot #:scadi-snapshot
                #:verifica-snapshot #:verifica-snapshot-in-buffer #:snapshot-del-registro-p
                #:soglia-snapshot #:deve-trattenere-p #:leggi-registro-snapshot
                #:invalida-registro-snapshot)
  (:export #:run))
(in-package #:arcdocdb.mvcc.tests)
(declaim (optimize (safety 3) (debug 3)))

(defvar *mvcc-tests* nil)
(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (setf *mvcc-tests*
           (acons ',name #',name (remove ',name *mvcc-tests* :key #'car)))))

(defun run ()
  (dolist (entry (reverse *mvcc-tests*))
    (funcall (cdr entry))
    (format t "ok    ~A~%" (car entry)))
  (format t "~D test snapshot/CSN superati.~%" (length *mvcc-tests*))
  t)

(defconstant +mvcc-word-base+ 4294967296)
(defconstant +mvcc-maximum+ 18446744073709551615)

(defun mvcc-fixture (&key (capacity 4) (csn-capacity 8) (lifetime 20) (wait 5) (base 0))
  (multiple-value-bind (high low) (floor base +mvcc-word-base+)
    (let* ((csns (crea-registro-csn :capacity csn-capacity :initial-high high :initial-low low))
           (registry (crea-registro-snapshot csns capacity lifetime wait)))
      (values csns registry (crea-contesto-snapshot registry)))))

(defun mvcc-words (&optional (size 3) (fill #xfeed))
  (make-array size :element-type '(unsigned-byte 64) :initial-element fill))

(defun mvcc-take-csn (registry)
  (let ((token (multiple-value-list (prendi-csn registry))))
    (is (= 3 (length token)))
    token))

(defun mvcc-token-csn (token)
  (+ (* (second token) +mvcc-word-base+) (third token)))

(defun mvcc-resolve-csn (registry token)
  (apply #'risolvi-csn registry token))

(defun mvcc-frontiers (registry)
  (multiple-value-bind (last-high last-low horizon-high horizon-low) (leggi-frontiere-csn registry)
    (list (+ (* last-high +mvcc-word-base+) last-low)
          (+ (* horizon-high +mvcc-word-base+) horizon-low))))

(defun mvcc-public-state (registry)
  (multiple-value-list (leggi-registro-snapshot registry)))

(defun mvcc-check-state (registry pins threshold generation)
  (is (equal (list pins threshold generation) (mvcc-public-state registry)))
  (is (= threshold (soglia-snapshot registry)))
  t)

(defun mvcc-check-pin-list (registry csns generation &optional conservative)
  "Oracolo dei soli pin logici: minimo di una lista posseduta dall'harness.
La soglia conservativa esplicita copre l'annuncio prima della cattura, non legge slot."
  (mvcc-check-state registry (length csns)
                    (or conservative (if csns (reduce #'min csns) +mvcc-maximum+)) generation))

(defun mvcc-error-reason (thunk expected-type reason)
  (let ((observed (handler-case (progn (funcall thunk) nil)
                    (error (condition) condition))))
    (is (typep observed expected-type))
    (is (eq reason (error-reason observed)))
    observed))

(defun mvcc-buffer-refusal (context generation now type reason &optional (index 1))
  (let* ((buffer (mvcc-words)) (before (copy-seq buffer)))
    (mvcc-error-reason
     (lambda () (verifica-snapshot-in-buffer context generation now buffer index)) type reason)
    (is (equalp before buffer)))
  t)

(defun mvcc-private-image (registry &optional context)
  "Solo immagine FI/rifiuto: non calcola CSN, soglia o stato attesi delle API sane."
  (list (arcdocdb.mvcc::registro-snapshot-health registry)
        (arcdocdb.mvcc::registro-snapshot-count registry)
        (arcdocdb.mvcc::registro-snapshot-cursor registry)
        (arcdocdb.mvcc::registro-snapshot-sweep-cursor registry)
        (copy-seq (arcdocdb.mvcc::registro-snapshot-words registry))
        (copy-seq (arcdocdb.mvcc::registro-snapshot-csns-array registry))
        (copy-seq (arcdocdb.mvcc::registro-snapshot-generations registry))
        (copy-seq (arcdocdb.mvcc::registro-snapshot-deadlines registry))
        (copy-seq (arcdocdb.mvcc::registro-snapshot-wait-deadlines registry))
        (copy-seq (arcdocdb.mvcc::registro-snapshot-states registry))
        (when context (list (arcdocdb.mvcc::contesto-snapshot-slot context)
                            (copy-seq (arcdocdb.mvcc::contesto-snapshot-word context))))))

(defun mvcc-refusal-preserves (registry context thunk type reason)
  (let ((before (mvcc-private-image registry context)))
    (mvcc-error-reason thunk type reason)
    (is (equalp before (mvcc-private-image registry context))))
  t)

(defun mvcc-faulted-refusal (registry context generation)
  (dolist (thunk (list (lambda () (soglia-snapshot registry))
                      (lambda () (deve-trattenere-p registry 1))
                      (lambda () (mvcc-public-state registry))
                      (lambda () (registra-snapshot context 0))
                      (lambda () (attiva-snapshot context generation 0))
                      (lambda () (termina-snapshot context generation))
                      (lambda () (scadi-snapshot registry 0 1))
                      (lambda () (verifica-snapshot context generation 0))))
    (mvcc-error-reason thunk 'invariant-violation :snapshot-registry-faulted))
  (mvcc-buffer-refusal context generation 0 'invariant-violation :snapshot-registry-faulted)
  t)
