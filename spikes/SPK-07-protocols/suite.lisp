;;;; Integrazione dei modelli finiti; il gate del motore resta aperto.
;;; REQ: REQ-VAL-001 REQ-AFF-017 REQ-IDX-003
(defpackage #:arcdocdb.spk07.suite (:use #:cl) (:export #:check))
(in-package #:arcdocdb.spk07.suite)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defun check ()
  "Esige tutti gli esiti positivi e conserva i testimoni dei controlli negativi."
  (let ((base (arcdocdb.spk07:check))
        (estensioni
          (list (arcdocdb.spk07.pubblicazione:check)
                (arcdocdb.spk07.scadenza:check)
                (arcdocdb.spk07.compaction:check)
                (arcdocdb.spk07.memoria:check))))
    (unless (and (eq :pass (getf base :status))
                 (every (lambda (r) (eq :ok (getf r :status))) estensioni))
      (error "Un modello SPK-07 non ha completato la verifica."))
    (setf (getf base :extensions) estensioni
          (getf base :pending)
          '(:full-weak-memory-model :multiple-slots-and-readers-under-weak-memory
            :byte-level-crash :full-engine-fault-injection :unbounded-configurations)
          (getf base :coverage) :bounded-abstract-models-and-single-observer-orders
          (getf base :gate) :open)
    base))
