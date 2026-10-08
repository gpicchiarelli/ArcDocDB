;;;; SPK-06: modelli del carico e interferenza reale sono prove distinte.
;;; REQ: REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(defpackage #:arcdocdb.spk06
  (:use #:cl)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk06)
(declaim (optimize (safety 3) (debug 2)))

(defun esigi-esito (risultato ambito)
  "Verifica il contratto dei moduli; un esito fallito non viene promosso a successo."
  (unless (and (listp risultato) (eq (getf risultato :status) :ok))
    (error "SPK-06: esito non valido per ~A: ~S." ambito risultato))
  risultato)

(defun check (base)
  "Modello finito e piccoli file reali; non verifica una compaction del motore."
  (list :status :ok :spike :spk-06
        :controller (esigi-esito (arcdocdb.spk06.controllore:check) :controller)
        :io (esigi-esito (arcdocdb.spk06.interferenza:check base) :io)
        :scope :finite-controller-and-immutable-file-copy))

(defun benchmark (base)
  "24 confronti I/O in serie; il controllore resta una prova separata."
  (esigi-esito (arcdocdb.spk06.interferenza:benchmark base) :benchmark))
