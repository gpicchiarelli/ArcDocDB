(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text) riserva-full-text) trova-slot-libero-riserva))
(defun trova-slot-libero-riserva (pool)
  "Pre: writer e contatori verificati. Post: primo slot libero/cancellato, senza mutare.
RESOURCE-EXHAUSTED se pieno; ricerca limitata alla capacita preallocata."
  (when (= (riserve-full-text-generation pool) most-positive-fixnum)
    (error 'resource-exhausted :reason :fulltext-reservation-generation))
  (let ((slots (riserve-full-text-slots pool)))
    (dotimes (i (length slots))
      (let ((slot (svref slots i)))
        (when (member (riserva-full-text-state slot) '(:free :cancelled))
          (return-from trova-slot-libero-riserva slot)))))
  (error 'resource-exhausted :reason :fulltext-reservation-slots))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text t index) d:preparazione-full-text)
                verifica-sorgente-riserva))
(defun verifica-sorgente-riserva (pool slot source i)
  "Pre: indice entro configurazioni. Post: task DONE canonico non prestato, run e costi coerenti.
Rifiuti prima di prenotare; configurazione superata e un rifiuto contract-changed."
  (unless (and (typep source 'd:preparazione-full-text) (eq :done (d::preparazione-full-text-phase source))
               (null (d::preparazione-full-text-borrower source)))
    (error 'invalid-argument :reason :fulltext-reservation-source))
  (unless (eq (d::preparazione-full-text-config source) (svref (riserve-full-text-configs pool) i))
    (error 'invalid-argument :reason :fulltext-contract-changed))
  (let* ((run (d::preparazione-full-text-run source)) (target (svref (riserva-full-text-runs slot) i))
         (payload (+ (* 20 (r::indice-posizionale-count run)) (r::indice-posizionale-byte-count run)
                     (* 12 (r::indice-posizionale-field-count run)))))
    (unless (and (eq :sealed (r::indice-posizionale-state run))
                 (= payload (d::preparazione-full-text-prepared-bytes source)))
      (errore-interno-riserve pool :fulltext-reservation-source-run))
    (unless (and (<= (* r::+token-width+ (r::indice-posizionale-count run)) (length (r::indice-posizionale-tokens target)))
                 (<= (r::indice-posizionale-byte-count run) (length (r::indice-posizionale-bytes target)))
                 (<= (* r::+length-width+ (r::indice-posizionale-field-count run)) (length (r::indice-posizionale-lengths target))))
      (error 'resource-exhausted :reason :fulltext-reservation-run)))
  source)

;;; REQ: REQ-SEC-010
(declaim (ftype (function (riserve-full-text index index) null) verifica-costo-file-riserva))
(defun verifica-costo-file-riserva (pool i cost)
  "Pre: contatori sani, U del documento verificato. Post: richiesta e somma entro budget file.
Rifiuto distinto per richiesta troppo grande o rotazione necessaria prima dell'append."
  (let ((available (- (aref (riserve-full-text-file-limits pool) i) (aref (riserve-full-text-fixed pool) i))))
    (when (> cost available) (error 'resource-exhausted :reason :fulltext-reservation-request-too-large))
    (when (> cost (- available (aref (riserve-full-text-used pool) i)))
      (error 'resource-exhausted :reason :fulltext-reservation-rotation)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text t) (values index u32 index &optional)) preflight-riserva))
(defun preflight-riserva (pool slot sources)
  "Pre: writer e slot libero. Post: tutti gli indici/capacita/costi validi, nessun effetto.
Un rifiuto successivo al primo indice lascia tutti i costi e borrower invariati."
  (unless (and (typep sources 'simple-vector) (= (length sources) (length (riserve-full-text-configs pool))))
    (error 'invalid-argument :reason :fulltext-reservation-sources))
  (let ((total 0) (row 0))
    (dotimes (i (length sources))
      (let ((source (verifica-sorgente-riserva pool slot (svref sources i) i)))
        (if (zerop i) (setf row (d::preparazione-full-text-row source))
            (unless (= row (d::preparazione-full-text-row source))
              (error 'invalid-argument :reason :fulltext-reservation-row)))
        (verifica-costo-file-riserva pool i (d::preparazione-full-text-bound source))
        (incf total (d::preparazione-full-text-prepared-bytes source))))
    (let ((position (posizione-riga-riserve pool row)))
      (when (and (< position (riserve-full-text-row-count pool)) (= row (aref (riserve-full-text-rows pool) position)))
        (slot-riga-riserve pool position row)
        (error 'invalid-argument :reason :fulltext-reservation-duplicate-row))
      (when (> total (- (riserve-full-text-delta-limit pool) (riserve-full-text-delta-used pool)))
        (error 'resource-exhausted :reason :fulltext-reservation-delta))
      (when (> total (- (riserve-full-text-staging-limit pool) (riserve-full-text-staging-used pool)))
        (error 'resource-exhausted :reason :fulltext-reservation-staging))
      (values total row position))))
