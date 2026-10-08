;;;; Integrazione C4 dei quattro esperimenti v2. Non è il motore.
;;; REQ: REQ-VAL-001 REQ-LIM-001 REQ-LIM-002 REQ-LIM-003
(defpackage #:arcdocdb.spk10 (:use #:cl) (:export #:check #:benchmark))
(in-package #:arcdocdb.spk10)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(define-condition integration-error (error)
  ((messaggio :initarg :messaggio :reader messaggio))
  (:report (lambda (condizione stream) (write-string (messaggio condizione) stream))))

(defparameter *moduli*
  '("ARCDOCDB.SPK10.CODEC" "ARCDOCDB.SPK10.INDICE"
    "ARCDOCDB.SPK10.CBOR" "ARCDOCDB.SPK10.MIGRAZIONE"))

(defun funzione-modulo (nome api)
  "Risolve soltanto le API dichiarate dei moduli caricati dal runner."
  (let* ((package (find-package nome))
         (symbol (and package (find-symbol api package))))
    (unless (and symbol (fboundp symbol))
      (error 'integration-error :messaggio (format nil "API ~A::~A assente." nome api)))
    (symbol-function symbol)))

(defun check ()
  "Conserva gli esiti indipendenti; non promuove il gate del motore."
  (let ((risultati (loop for nome in *moduli*
                        collect (list :module nome
                                      :result (funcall (funzione-modulo nome "CHECK"))))))
    (dolist (r risultati)
      (unless (eq :ok (getf (getf r :result) :status))
        (error 'integration-error :messaggio (format nil "Check v2 fallito: ~S" r))))
    (list :spike :spk-10 :status :ok :format-version 2 :modules risultati
          :production-gate-complete nil)))

(defun benchmark ()
  "Esegue i benchmark dei moduli in serie; il modello non produce throughput."
  (let ((verifica (check)))
    (list :spike :spk-10 :status :ok :format-version 2 :check verifica
          :measurements
          (loop for nome in (butlast *moduli*)
                collect (list :module nome
                              :result (funcall (funzione-modulo nome "BENCHMARK"))))
          :limits '(:local-environment :experimental-components
                    :no-real-filesystem-migration :no-reference-platform-claim))))
