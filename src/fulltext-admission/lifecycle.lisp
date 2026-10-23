(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text) null) libera-fonti-riserva))
(defun libera-fonti-riserva (pool slot)
  "Pre: cancellazione prima del trasferimento, writer esclusivo. Post: prestiti/costi rilasciati una volta.
Una fonte persa o un underflow e invariante; non tenta rollback su pool incoerente."
  (dotimes (i (length (riserva-full-text-sources slot)))
    (when (svref (riserva-full-text-sources slot) i)
      (let ((source (sorgente-viva-riserva pool slot i)))
        (setf (d::preparazione-full-text-borrower source) nil (svref (riserva-full-text-sources slot) i) nil)))
    (unless (>= (aref (riserve-full-text-used pool) i) (aref (riserva-full-text-costs slot) i))
      (errore-interno-riserve pool :fulltext-reservation-underflow))
    (decf (aref (riserve-full-text-used pool) i) (aref (riserva-full-text-costs slot) i))
    (setf (aref (riserva-full-text-costs slot) i) 0
          (r::indice-posizionale-state (svref (riserva-full-text-runs slot) i)) :failed))
  nil)

;;; REQ: REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t t) keyword) annulla-riserva-full-text trasferisci-riserva-full-text))
(defun annulla-riserva-full-text (pool lease slot generation)
  "Pre: riserva non trasferita, nessun append/SEAL/PREPARE o riferimento esterno al run.
Post: CANCELLED idempotente fino al riuso; tutti i costi restituiti, sorgenti libere.
INVALID-ARGUMENT dopo trasferimento o token stale; non annulla transazioni/WAL."
  (verifica-writer-riserve pool lease) (verifica-token-riserva pool slot generation)
  (when (eq :cancelled (riserva-full-text-state slot)) (return-from annulla-riserva-full-text :cancelled))
  (unless (member (riserva-full-text-state slot) '(:copying :ready))
    (error 'invalid-argument :reason :fulltext-reservation-cancel-state))
  (let ((bytes (riserva-full-text-bytes slot)) (complete nil))
    (unless (and (<= bytes (riserve-full-text-staging-used pool)) (<= bytes (riserve-full-text-delta-used pool))
                 (plusp (riserve-full-text-count pool)))
      (errore-interno-riserve pool :fulltext-reservation-underflow))
    (unwind-protect
         (progn
           (setf (riserve-full-text-effect pool) t)
           (rimuovi-riga-riserva pool slot)
           (libera-fonti-riserva pool slot)
           (decf (riserve-full-text-staging-used pool) bytes) (decf (riserve-full-text-delta-used pool) bytes)
           (decf (riserve-full-text-count pool)) (setf (riserva-full-text-state slot) :cancelled)
           (unless (= (riserve-full-text-count pool) (riserve-full-text-row-count pool))
             (errore-interno-riserve pool :fulltext-row-cancel))
           (setf complete t)
           :cancelled)
      (termina-effetto-riserve pool complete))))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(defun trasferisci-riserva-full-text (pool lease slot generation)
  "Pre: READY, prima dell'append e della decisione; il writer accetta ownership permanente.
Post: TRANSFERRED; staging restituito, delta/file/slot trattenuti, run immutabili.
Non e prova di commit, pubblicazione o CSN. Nessun rilascio/reclaim di trasferiti in questa API:
un futuro esito autorevole e la quiescenza devono precedere il ritiro dedicato."
  (verifica-writer-riserve pool lease) (verifica-token-riserva pool slot generation)
  (unless (eq :ready (riserva-full-text-state slot))
    (error 'invalid-argument :reason :fulltext-reservation-transfer-state))
  (unless (>= (riserve-full-text-staging-used pool) (riserva-full-text-bytes slot))
    (errore-interno-riserve pool :fulltext-reservation-underflow))
  (let ((complete nil))
    (setf (riserve-full-text-effect pool) t)
    (unwind-protect
         (progn
           (decf (riserve-full-text-staging-used pool) (riserva-full-text-bytes slot))
           (setf (riserva-full-text-state slot) :transferred complete t) :transferred)
      (termina-effetto-riserve pool complete))))
