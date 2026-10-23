(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-CON-002 REQ-SEC-010
(declaim (ftype (function (riserve-full-text keyword) nil) errore-interno-riserve))
(defun errore-interno-riserve (pool reason)
  "Pre: invariante falsa. Post: pool FAULTED, dati conservati; il caller ferma la Serie.
Nessun rollback, rilascio di riserve o ACK; propaga INVARIANT-VIOLATION."
  (setf (riserve-full-text-state pool) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-CON-002 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t t) null) verifica-writer-riserve))
(defun verifica-writer-riserve (pool lease)
  "Pre: ingresso del writer. Post: lease della coda/thread correnti e pool sano.
INVALID-ARGUMENT prima degli effetti per lease/tipo; invarianti => pool FAULTED."
  (unless (typep pool 'riserve-full-text) (error 'invalid-argument :reason :fulltext-reservation-pool))
  (ex::%check-lease (riserve-full-text-queue pool) lease)
  (unless (and (eq :healthy (riserve-full-text-state pool)) (not (riserve-full-text-effect pool)))
    (errore-interno-riserve pool :fulltext-reservation-faulted))
  (unless (and (<= (riserve-full-text-count pool) (length (riserve-full-text-slots pool)))
               (= (riserve-full-text-row-count pool) (riserve-full-text-count pool))
               (= (length (riserve-full-text-rows pool)) (length (riserve-full-text-row-slots pool))
                  (length (riserve-full-text-slots pool)))
               (<= (riserve-full-text-staging-used pool) (riserve-full-text-delta-used pool)
                   (riserve-full-text-delta-limit pool))
               (<= (riserve-full-text-staging-used pool) (riserve-full-text-staging-limit pool)))
    (errore-interno-riserve pool :fulltext-reservation-counters))
  (dotimes (i (length (riserve-full-text-configs pool)))
    (unless (<= 0 (aref (riserve-full-text-used pool) i)
                (- (aref (riserve-full-text-file-limits pool) i) (aref (riserve-full-text-fixed pool) i)))
      (errore-interno-riserve pool :fulltext-reservation-file-counter)))
  nil)

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text t t) riserva-full-text) verifica-token-riserva))
(defun verifica-token-riserva (pool slot generation)
  "Pre: writer verificato. Post: slot canonico e generation catturata, senza mutazioni.
INVALID-ARGUMENT per capacita estranea/stale; nessun lookup per ID riusabile."
  (unless (and (typep slot 'riserva-full-text) (eq pool (riserva-full-text-pool slot))
               (typep generation 'index) (plusp generation) (= generation (riserva-full-text-generation slot)))
    (error 'invalid-argument :reason :fulltext-reservation-token))
  (unless (and (< (riserva-full-text-position slot) (length (riserve-full-text-slots pool)))
               (eq slot (svref (riserve-full-text-slots pool) (riserva-full-text-position slot))))
    (errore-interno-riserve pool :fulltext-reservation-slot))
  slot)

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text boolean) null) termina-effetto-riserve))
(defun termina-effetto-riserve (pool complete)
  "Pre: cleanup dell'effetto esclusivo. Post: uscita incompleta rende FAULTED senza rollback.
Prestiti e costi rimangono per la diagnosi; non sopprime il trasferimento originale."
  (unless complete (setf (riserve-full-text-state pool) :faulted))
  (setf (riserve-full-text-effect pool) nil)
  nil)
