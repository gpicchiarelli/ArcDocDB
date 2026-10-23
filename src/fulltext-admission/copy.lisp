(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006
(declaim (ftype (function (riserve-full-text riserva-full-text index) d:preparazione-full-text) sorgente-viva-riserva))
(defun sorgente-viva-riserva (pool slot i)
  "Pre: indice attivo della copia. Post: prestito ancora esclusivo e task/run non riusati.
Una perdita del prestito e un'invariante: conserva pool e fonti per fail-stop."
  (let ((source (svref (riserva-full-text-sources slot) i)))
    (unless (and (typep source 'd:preparazione-full-text) (eq slot (d::preparazione-full-text-borrower source))
                 (eq :done (d::preparazione-full-text-phase source))
                 (eq :sealed (r::indice-posizionale-state (d::preparazione-full-text-run source))))
      (errore-interno-riserve pool :fulltext-reservation-borrow))
    source))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text d:preparazione-full-text r:indice-posizionale) null)
                completa-run-riserva))
(defun completa-run-riserva (pool slot source target)
  "Pre: tutti i byte e parole copiati nel run privato. Post: run SEALED, task riutilizzabile.
Il risultato complessivo non e accessibile finche non sono completi tutti gli indici."
  (let* ((i (riserva-full-text-config-index slot)) (run (d::preparazione-full-text-run source)))
    (setf (r::indice-posizionale-count target) (r::indice-posizionale-count run)
          (r::indice-posizionale-byte-count target) (r::indice-posizionale-byte-count run)
          (r::indice-posizionale-field-count target) (r::indice-posizionale-field-count run)
          (r::indice-posizionale-state target) :sealed
          (d::preparazione-full-text-borrower source) nil (svref (riserva-full-text-sources slot) i) nil)
    (incf (riserva-full-text-config-index slot))
    (setf (riserva-full-text-part slot) 0 (riserva-full-text-cursor slot) 0)
    (when (= (riserva-full-text-config-index slot) (length (riserve-full-text-configs pool)))
      (setf (riserva-full-text-state slot) :ready)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text) null) copia-unita-riserva))
(defun copia-unita-riserva (pool slot)
  "Pre: COPYING esclusivo e capacita prenotate. Post: un byte/parola o transizione di parte.
Ogni unita e finita; nessun cons, ordinamento, scansione di testo o I/O nel writer."
  (let* ((i (riserva-full-text-config-index slot)) (source (sorgente-viva-riserva pool slot i))
         (run (d::preparazione-full-text-run source)) (target (svref (riserva-full-text-runs slot) i))
         (cursor (riserva-full-text-cursor slot)) (part (riserva-full-text-part slot)))
    (multiple-value-bind (from to limit)
        (case part
          (0 (values (r::indice-posizionale-bytes run) (r::indice-posizionale-bytes target) (r::indice-posizionale-byte-count run)))
          (1 (values (r::indice-posizionale-tokens run) (r::indice-posizionale-tokens target)
                     (* r::+token-width+ (r::indice-posizionale-count run))))
          (2 (values (r::indice-posizionale-lengths run) (r::indice-posizionale-lengths target)
                     (* r::+length-width+ (r::indice-posizionale-field-count run))))
          (otherwise (errore-interno-riserve pool :fulltext-reservation-copy-part)))
      (if (< cursor limit)
          (progn (setf (aref to cursor) (aref from cursor)) (incf (riserva-full-text-cursor slot)))
          (if (= part 2) (completa-run-riserva pool slot source target)
              (setf (riserva-full-text-part slot) (1+ part) (riserva-full-text-cursor slot) 0)))))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t t t) keyword) passo-riserva-full-text))
(defun passo-riserva-full-text (pool lease slot generation quantum)
  "Pre: token catturato e lease corrente, quantum 1..65536. Post: COPYING o READY.
Uscita incompleta rende FAULTED; non libera riserve sotto un futuro commit deciso."
  (verifica-writer-riserve pool lease) (verifica-token-riserva pool slot generation)
  (unless (and (typep quantum '(integer 1 65536)) (member (riserva-full-text-state slot) '(:copying :ready)))
    (error 'invalid-argument :reason :fulltext-reservation-copy-state))
  (let ((complete nil))
    (setf (riserve-full-text-effect pool) t)
    (unwind-protect
         (progn
           (dotimes (i quantum)
             (when (eq :ready (riserva-full-text-state slot)) (return))
             (copia-unita-riserva pool slot))
           (setf complete t)
           (riserva-full-text-state slot))
      (termina-effetto-riserve pool complete))))
