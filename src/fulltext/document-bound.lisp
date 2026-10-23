(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index) boolean) termine-documento-ripetuto-p))
(defun termine-documento-ripetuto-p (task token)
  "Pre: run SEALED e token >0 valido. Post: stessa coppia campo/termine del precedente.
Confronto bytewise con costo esplicito, senza hash o allocazione per termine."
  (let* ((run (preparazione-full-text-run task)) (data (r::indice-posizionale-tokens run))
         (p (* token r::+token-width+)) (q (- p r::+token-width+))
         (size (aref data (+ p r::+length+))))
    (lavoro-documento task)
    (and (= (aref data (+ p r::+field+)) (aref data (+ q r::+field+)))
         (= size (aref data (+ q r::+length+)))
         (let ((bytes (r::indice-posizionale-bytes run))
               (first (aref data (+ p r::+offset+))) (prior (aref data (+ q r::+offset+))))
           (loop for i below size always
             (progn (lavoro-documento task) (= (aref bytes (+ first i)) (aref bytes (+ prior i)))))))))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) misura-passo-documento))
(defun misura-passo-documento (task)
  "Pre: run SEALED privato. Post: una occorrenza misurata o DONE con U conservativo.
U=16*campi + somma_distinti(32+term-bytes+16) +4*token; costo fisso una volta per file.
Un budget file insufficiente rifiuta prima di rendere disponibile qualsiasi risultato."
  (let* ((run (preparazione-full-text-run task)) (token (preparazione-full-text-measure task)))
    (lavoro-documento task)
    (when (< token (r::indice-posizionale-count run))
      (unless (and (plusp token) (termine-documento-ripetuto-p task token))
        (incf (preparazione-full-text-bound task)
              (+ f::+dict-width+ f::+posting-width+
                 (aref (r::indice-posizionale-tokens run) (+ (* token r::+token-width+) r::+length+)))))
      (incf (preparazione-full-text-measure task)) (return-from misura-passo-documento nil))
    (when (> (+ (limite-fisso-indice-full-text (preparazione-full-text-config task))
                (preparazione-full-text-bound task)) (preparazione-full-text-file-limit task))
      (error 'resource-exhausted :reason :fulltext-document-file-budget))
    (unless (and (eq :sealed (r::indice-posizionale-state run))
                 (<= (preparazione-full-text-prepared-bytes task)
                     (aref (configurazione-full-text-effective (preparazione-full-text-config task)) 3)))
      (error 'invariant-violation :reason :fulltext-document-result))
    (setf (preparazione-full-text-input task) nil (preparazione-full-text-phase task) :done))
  nil)
