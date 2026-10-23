;;; OWNER: controllore della Serie; ingressi coerenti per tutta la valutazione.
;;; SHARED: solo configurazione immutabile; nessun I/O, lock o scrittura tra Serie.
(in-package #:arcdocdb.index.mode)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(declaim (ftype (function (t fixnum keyword) byte-indice) verifica-byte-indice))
(defun verifica-byte-indice (value minimum reason)
  "Pre: MINIMUM e' 0 o 1, motivo canonico. Post: fixnum entro il dominio dei byte.
INVALID-ARGUMENT prima di qualsiasi effetto; nessuna conversione o allocazione."
  (unless (and (typep value 'fixnum) (<= minimum value +max-byte-indice+))
    (error 'invalid-argument :reason reason))
  value)

;;; REQ: REQ-IDX-008 REQ-AFF-008
(declaim (ftype (function (politica-indice byte-indice) byte-indice) soglia-rientro-indice))
(defun soglia-rientro-indice (policy budget)
  "Pre: budget verificato e politica canonica. Post: floor(budget*percent/100).
Intermedi entro fixnum; nessuna moltiplicazione del budget intero, errore o allocazione."
  (multiple-value-bind (whole remainder) (floor budget 100)
    (+ (* whole (politica-indice-rientro policy))
       (floor (* remainder (politica-indice-rientro policy)) 100))))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(declaim (ftype (function (politica-indice modo-indice byte-indice byte-indice)
                         destinazione-indice) destinazione-automatica))
(defun destinazione-automatica (policy current budget resident)
  "Pre: campione valido. Post: residente preferito all'avvio e mantenuto se entra.
Dal paginato rientro alla soglia bassa; nessuna pubblicazione, errore o mutazione."
  (let ((limit (if (eq current :paginato) (soglia-rientro-indice policy budget) budget)))
    (if (<= resident limit) :residente :paginato)))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(declaim (ftype (function (politica-indice t t t t t)
                         (values destinazione-indice azione-indice &optional)) valuta-modo-indice))
(defun valuta-modo-indice (policy current budget resident paged migration)
  "Pre: stime conservative del prossimo lavoro; nessun eccesso gia' ammesso.
Post: destinazione e azione; PREPARA non cambia la root e richiede attuatore verificato.
MIGRATION copre la sorgente attuale, destinazione e staging, senza il lavoro rinviato.
INVALID-ARGUMENT per domini/stima incoerente; RESOURCE-EXHAUSTED all'avvio senza modo capiente.
Nessuna allocazione, attesa, rilevazione OS, prenotazione o mutazione sui percorsi validi."
  (unless (member current '(:iniziale :residente :paginato))
    (error 'invalid-argument :reason :index-mode-current))
  (let* ((grant (verifica-byte-indice budget 0 :index-mode-budget))
         (ram (verifica-byte-indice resident 1 :index-mode-resident-peak))
         (disk (verifica-byte-indice paged 1 :index-mode-paged-peak))
         (peak (verifica-byte-indice migration 1 :index-mode-migration-peak)))
    (let* ((target (destinazione-automatica policy current grant ram))
           (required (if (eq target :residente) ram disk)))
      (when (and (not (eq current :iniziale)) (not (eq current target))
                 (< peak required))
        (error 'invalid-argument :reason :index-mode-migration-underestimate))
      (cond
        ((eq current :iniziale)
         (when (> required grant)
           (error 'resource-exhausted :reason :index-mode-start-budget))
         (values target :avvia))
        ((> required grant) (values target :budget-insufficiente))
        ((eq current target) (values target :mantieni))
        ((> peak grant) (values target :budget-insufficiente))
        (t (values target :prepara))))))
