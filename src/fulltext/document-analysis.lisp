(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) index) residuo-documento))
(defun residuo-documento (task)
  "Pre: contatore valido. Post: lavoro disponibile strettamente positivo, oppure rifiuto."
  (let ((remaining (- (preparazione-full-text-work-limit task) (preparazione-full-text-work task))))
    (unless (plusp remaining) (error 'resource-exhausted :reason :fulltext-document-work))
    remaining))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) prossimo-campo-documento))
(defun prossimo-campo-documento (task)
  "Pre: FIELD, input ancora posseduto. Post: un assente saltato, analisi avviata o SEAL.
Il limite token e complessivo, incluse le stringhe vuote dopo esaurimento dei token."
  (let* ((field (preparazione-full-text-field task)) (run (preparazione-full-text-run task))
         (limits (configurazione-full-text-effective (preparazione-full-text-config task)))
         (analysis (preparazione-full-text-analysis task)))
    (lavoro-documento task)
    (when (= field (length (preparazione-full-text-present task)))
      (setf (preparazione-full-text-phase task) :seal) (return-from prossimo-campo-documento nil))
    (when (zerop (sbit (preparazione-full-text-present task) field))
      (incf (preparazione-full-text-field task)) (return-from prossimo-campo-documento nil))
    (a:inizia-analisi-full-text
     analysis (preparazione-full-text-input task)
     (+ (preparazione-full-text-start task) (aref (preparazione-full-text-begins task) field))
     (+ (preparazione-full-text-start task) (aref (preparazione-full-text-ends task) field))
     :max-term-bytes (aref limits 1)
     :max-tokens (max 1 (min (- (aref limits 2) (r::indice-posizionale-count run))
                            (length (a::spazio-full-text-begins analysis))))
     :max-work (residuo-documento task))
    (setf (preparazione-full-text-phase task) :analysis))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) prepara-copia-documento))
(defun prepara-copia-documento (task)
  "Pre: analisi DONE. Post: copia avviata dopo controllo cumulativo di token e staging.
Rifiuti nel solo contesto privato, prima di qualsiasi append o riserva del writer."
  (let* ((run (preparazione-full-text-run task)) (analysis (preparazione-full-text-analysis task))
         (config (preparazione-full-text-config task)) (limits (configurazione-full-text-effective config))
         (count (+ (r::indice-posizionale-count run) (a::spazio-full-text-token-count analysis)))
         (bytes (+ (r::indice-posizionale-byte-count run) (a::spazio-full-text-byte-count analysis)))
         (prepared (+ (* r::+token-width+ 4 count) bytes (* r::+length-width+ 4 (1+ (r::indice-posizionale-field-count run))))))
    (when (> count (aref limits 2)) (error 'resource-exhausted :reason :fulltext-document-token-budget))
    (when (> prepared (aref limits 3)) (error 'resource-exhausted :reason :fulltext-document-prepared-budget))
    (r:inizia-campo-full-text run (preparazione-full-text-row task)
                            (campo-full-text-id (svref (configurazione-full-text-fields config)
                                                       (preparazione-full-text-field task))) analysis)
    (setf (preparazione-full-text-prepared-bytes task) prepared (preparazione-full-text-phase task) :copy))
  nil)

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) analizza-passo-documento))
(defun analizza-passo-documento (task)
  "Pre: ANALYSIS esclusiva. Post: un passo analitico, costo reale addebitato globalmente.
Il sotto-budget dell'analizzatore impedisce di produrre risultati oltre il residuo."
  (let* ((analysis (preparazione-full-text-analysis task)) (before (a::spazio-full-text-work analysis))
         (status (a:passo-analisi-full-text analysis 1)))
    (lavoro-documento task (- (a::spazio-full-text-work analysis) before))
    (when (eq status :done) (prepara-copia-documento task)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) run-passo-documento))
(defun run-passo-documento (task)
  "Pre: COPY o SORT. Post: un passo del run e budget cumulativo comprendente i confronti.
Fine COPY rilascia l'analisi, fine SORT abilita la misura, senza pubblicazione."
  (let* ((run (preparazione-full-text-run task)) (before (r::indice-posizionale-work run)))
    (setf (r::indice-posizionale-work-limit run) (+ before (residuo-documento task)))
    (let ((status (r:passo-indice-posizionale run 1)))
      (lavoro-documento task (- (r::indice-posizionale-work run) before))
      (case status
        (:building
         (setf (a::spazio-full-text-input (preparazione-full-text-analysis task)) nil)
         (incf (preparazione-full-text-field task)) (setf (preparazione-full-text-phase task) :field))
        (:sealed
         (setf (preparazione-full-text-bound task)
               (+ (* f::+length-width+ (r::indice-posizionale-field-count run))
                  (* f::+position-width+ (r::indice-posizionale-count run)))
               (preparazione-full-text-phase task) :measure))
        (:running nil)
        (otherwise (error 'invariant-violation :reason :fulltext-document-run-status)))))
  nil)
