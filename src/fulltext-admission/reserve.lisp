(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text simple-vector) null) cattura-sorgenti-riserva))
(defun cattura-sorgenti-riserva (pool slot sources)
  "Pre: tutti i preflight completati, effetto esclusivo. Post: prestiti e U posseduti dal pool.
Nessuna copia/allocazione di run; i task rimangono DONE ma non si possono riavviare."
  (dotimes (i (length sources))
    (let* ((source (svref sources i)) (cost (d::preparazione-full-text-bound source))
           (run (svref (riserva-full-text-runs slot) i)))
      (setf (svref (riserva-full-text-sources slot) i) source
            (d::preparazione-full-text-borrower source) slot
            (aref (riserva-full-text-costs slot) i) cost
            (r::indice-posizionale-count run) 0 (r::indice-posizionale-byte-count run) 0
            (r::indice-posizionale-field-count run) 0 (r::indice-posizionale-state run) :building)
      (incf (aref (riserve-full-text-used pool) i) cost)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t) (values riserva-full-text index &optional)) prenota-full-text))
(defun prenota-full-text (pool lease sources)
  "Pre: lease della coda canonica, tutti i task DONE consegnati esclusivamente dal worker.
Post: slot/generation preallocati e riserva atomica per tutti gli indici; copia ancora privata.
Rifiuti ordinari prima degli effetti. Interruzione/invariante durante adozione => pool FAULTED.
Prima di append/SEAL/PREPARE: non assegna CSN, non lega byte PUT o autorizza commit."
  (verifica-writer-riserve pool lease)
  (let ((slot (trova-slot-libero-riserva pool)))
    (multiple-value-bind (bytes row position) (preflight-riserva pool slot sources)
      (let ((complete nil))
        (unwind-protect
             (progn
               (setf (riserve-full-text-effect pool) t)
               (incf (riserve-full-text-generation pool))
               (setf (riserva-full-text-generation slot) (riserve-full-text-generation pool)
                     (riserva-full-text-row slot) row (riserva-full-text-bytes slot) bytes
                     (riserva-full-text-config-index slot) 0 (riserva-full-text-part slot) 0
                     (riserva-full-text-cursor slot) 0 (riserva-full-text-state slot) :copying)
               (cattura-sorgenti-riserva pool slot sources)
               (inserisci-riga-riserva pool slot position)
               (incf (riserve-full-text-delta-used pool) bytes)
               (incf (riserve-full-text-staging-used pool) bytes) (incf (riserve-full-text-count pool))
               (unless (and (= (riserve-full-text-count pool) (riserve-full-text-row-count pool))
                            (<= (riserve-full-text-delta-used pool) (riserve-full-text-delta-limit pool))
                            (<= (riserve-full-text-staging-used pool) (riserve-full-text-staging-limit pool)))
                 (errore-interno-riserve pool :fulltext-reservation-adoption))
               (setf complete t)
               (values slot (riserva-full-text-generation slot)))
          (termina-effetto-riserve pool complete))))))
