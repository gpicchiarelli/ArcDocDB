;;;; SPK-04: integrazione degli esperimenti del writer e delle attese.
;;; REQ: REQ-VAL-001 REQ-CON-004 REQ-AFF-008
(defpackage #:arcdocdb.spk04 (:use #:cl) (:export #:check #:benchmark))
(in-package #:arcdocdb.spk04)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun api-modulo (package nome)
  "Risolve una API dei moduli locali, mai un simbolo fornito da dati esterni."
  (let ((symbol (find-symbol nome package)))
    (unless (and symbol (fboundp symbol)) (error "API SPK-04 assente: ~A/~A." package nome))
    (symbol-function symbol)))

;;; REQ: REQ-CON-004
(defun req-con-004-ripartenza-lettura ()
  "Modello finito: richiesta invariata, indice riletto e nuova epoca nel compito I/O."
  (let ((casi 0))
    (dolist (prima '(17 29 43))
      (dolist (dopo '(17 29 43))
        (let* ((richiesta '(:chiave 7 :snapshot 11))
               (indice (list :chiave 7 :location prima))
               (compito-calcolo (list :epoca 1 :location (getf indice :location)))
               ;; Il passaggio conserva soltanto la richiesta.
               (contesto-io (copy-list richiesta)))
          (assert (= prima (getf compito-calcolo :location)))
          (setf indice (list :chiave 7 :location dopo))
          (let ((compito-io (list :epoca 2 :location (getf indice :location))))
            (assert (equal contesto-io richiesta))
            (assert (null (getf contesto-io :location)))
            (assert (null (getf contesto-io :epoca)))
            (assert (= dopo (getf compito-io :location)))
            (assert (/= (getf compito-calcolo :epoca) (getf compito-io :epoca)))
            (incf casi)))))
    (list :status :ok :cases casi :assertions (* casi 6)
          :limits '(:finite-model :no-real-io :no-mvcc-resolution :no-epoch-reclamation))))

(defun check ()
  "Esegue controlli indipendenti e conserva l'ambito sperimentale dei loro risultati."
  (let ((pool (funcall (api-modulo "ARCDOCDB.SPK04.POOL" "CHECK")))
        (parcheggi (funcall (api-modulo "ARCDOCDB.SPK04.PARCHEGGI" "CHECK")))
        (letture (req-con-004-ripartenza-lettura)))
    (dolist (r (list pool parcheggi letture))
      (unless (eq :ok (getf r :status)) (error "Controllo SPK-04 fallito: ~S." r)))
    (list :status :ok :spike :spk-04 :pool pool :parking parcheggi :read-restart letture
          :production-gate-complete nil)))

(defun benchmark ()
  "Misura soltanto il pool sintetico; i modelli non producono throughput."
  (let ((r (funcall (api-modulo "ARCDOCDB.SPK04.POOL" "BENCHMARK"))))
    (unless (eq :ok (getf r :status)) (error "Benchmark SPK-04 fallito: ~S." r))
    (list :status :ok :spike :spk-04 :pool r
          :limits '(:synthetic-work :preloaded-queues :local-uncontrolled-load
                    :no-database-throughput :no-io :no-reference-platform-claim))))
