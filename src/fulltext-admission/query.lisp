(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (t t t t t) r:indice-posizionale) leggi-run-riserva-full-text))
(defun leggi-run-riserva-full-text (pool lease slot generation i)
  "Pre: lease e token, indice zero-based. Post: prestito del run posseduto READY/TRANSFERRED.
Uso dal solo writer, non e vista di query MVCC. Non sopravvive a cancellazione/riuso."
  (verifica-writer-riserve pool lease) (verifica-token-riserva pool slot generation)
  (unless (and (typep i 'index) (< i (length (riserva-full-text-runs slot)))
               (member (riserva-full-text-state slot) '(:ready :transferred)))
    (error 'invalid-argument :reason :fulltext-reservation-incomplete))
  (let ((run (svref (riserva-full-text-runs slot) i)))
    (unless (eq :sealed (r::indice-posizionale-state run))
      (errore-interno-riserve pool :fulltext-reservation-result))
    run))

;;; REQ: REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t) (values index index index &optional)) leggi-budget-riserve-full-text))
(defun leggi-budget-riserve-full-text (pool lease)
  "Pre: lease corrente. Post: delta, staging e slot occupati, inclusi trasferiti, senza array mutabili."
  (verifica-writer-riserve pool lease)
  (values (riserve-full-text-delta-used pool) (riserve-full-text-staging-used pool) (riserve-full-text-count pool)))

;;; REQ: REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t) index) leggi-bound-riserve-full-text))
(defun leggi-bound-riserve-full-text (pool lease i)
  "Pre: lease e indice zero-based valido. Post: costo fisso piu U di tutte le riserve trattenute.
Non sottrae versioni storiche, preparati o documenti assenti da uno snapshot."
  (verifica-writer-riserve pool lease)
  (unless (and (typep i 'index) (< i (length (riserve-full-text-configs pool))))
    (error 'invalid-argument :reason :fulltext-reservation-index))
  (+ (aref (riserve-full-text-fixed pool) i) (aref (riserve-full-text-used pool) i)))

;;; REQ: REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (t t t t) keyword) stato-riserva-full-text))
(defun stato-riserva-full-text (pool lease slot generation)
  "Pre: lease e token catturati. Post: stato corrente senza esporre sorgenti o buffer parziali."
  (verifica-writer-riserve pool lease) (verifica-token-riserva pool slot generation)
  (riserva-full-text-state slot))
