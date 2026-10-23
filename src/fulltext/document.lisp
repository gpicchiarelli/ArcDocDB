(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text keyword) null) rilascia-documento))
(defun rilascia-documento (task state)
  "Pre: confine del task esclusivo; errore/cancellazione. Post: prestiti rilasciati,
run e risultati invalidati; nessuna risorsa esterna, riserva writer o I/O da annullare."
  (unless (member state '(:failed :cancelled)) (error 'invariant-violation :reason :fulltext-document-release))
  (let ((analysis (preparazione-full-text-analysis task)) (run (preparazione-full-text-run task)))
    (setf (preparazione-full-text-input task) nil (preparazione-full-text-phase task) state
          (a::spazio-full-text-input analysis) nil (a::spazio-full-text-phase analysis) :failed
          (r::indice-posizionale-source run) nil (r::indice-posizionale-state run) :failed))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text) null) avanza-documento))
(defun avanza-documento (task)
  "Pre: task attivo. Post: un passo di scanner, normalizzazione, copia, sort o misura.
Nessun ciclo di attesa; il chiamante gestisce scheduling e deadline esterna."
  (case (preparazione-full-text-phase task)
    (:scan (passo-scansione-documento task))
    (:field (prossimo-campo-documento task))
    (:analysis (analizza-passo-documento task))
    ((:copy :sort) (run-passo-documento task))
    (:seal
     (lavoro-documento task)
     (let ((run (preparazione-full-text-run task)))
       (r:sigilla-indice-posizionale run :max-work (+ (r::indice-posizionale-work run) (residuo-documento task))))
     (setf (preparazione-full-text-phase task) :sort))
    (:measure (misura-passo-documento task))
    (otherwise (error 'invariant-violation :reason :fulltext-document-phase)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t) keyword) passo-preparazione-full-text))
(defun passo-preparazione-full-text (task quantum)
  "Pre: task attivo esclusivo, quantum 1..65536. Post: RUNNING o DONE, nessun parziale pubblico.
Gli errori di dominio invalidano il task e sono propagati; invarianti al confine worker
richiedono fail-stop, non un retry del commit. Nessun callback o I/O."
  (unless (and (typep task 'preparazione-full-text) (typep quantum '(integer 1 65536)))
    (error 'invalid-argument :reason :fulltext-document-step))
  (when (eq :done (preparazione-full-text-phase task)) (return-from passo-preparazione-full-text :done))
  (when (member (preparazione-full-text-phase task) '(:idle :failed :cancelled))
    (error 'invalid-argument :reason :fulltext-document-state))
  (handler-case
      (dotimes (i quantum)
        (when (eq :done (preparazione-full-text-phase task)) (return))
        (avanza-documento task))
    (arcdocdb-error (condition) (rilascia-documento task :failed) (error condition)))
  (if (eq :done (preparazione-full-text-phase task)) :done :running))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t) keyword) annulla-preparazione-full-text stato-preparazione-full-text))
(defun annulla-preparazione-full-text (task)
  "Pre: task esclusivo, attivo o gia cancellato. Post: CANCELLED, prestiti rilasciati.
Idempotente; INVALID-ARGUMENT per tipo/stato DONE/IDLE/FAILED."
  (unless (and (typep task 'preparazione-full-text)
               (not (member (preparazione-full-text-phase task) '(:idle :done :failed))))
    (error 'invalid-argument :reason :fulltext-document-cancel))
  (rilascia-documento task :cancelled) :cancelled)
(defun stato-preparazione-full-text (task)
  "Pre: task valido, lettura dal suo proprietario. Post: stato pubblico senza dati parziali."
  (unless (typep task 'preparazione-full-text) (error 'invalid-argument :reason :fulltext-document-input))
  (case (preparazione-full-text-phase task)
    ((:idle :done :failed :cancelled) (preparazione-full-text-phase task))
    ((:scan :field :analysis :copy :seal :sort :measure) :running)
    (otherwise (error 'invariant-violation :reason :fulltext-document-phase))))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (t) (values r:indice-posizionale index index index index &optional))
                risultati-preparazione-full-text))
(defun risultati-preparazione-full-text (task)
  "Pre: DONE, prestito esclusivo fino al prossimo avvio. Post: run SEALED, U(documento),
bound file singolo, payload staging usato, byte di testo input sui campi presenti.
Non e una riserva writer, una mappa hint, un commit o prova di copertura/MVCC/READY."
  (unless (and (typep task 'preparazione-full-text) (eq :done (preparazione-full-text-phase task)))
    (error 'invalid-argument :reason :fulltext-document-incomplete))
  (values (preparazione-full-text-run task) (preparazione-full-text-bound task)
          (+ (limite-fisso-indice-full-text (preparazione-full-text-config task)) (preparazione-full-text-bound task))
          (preparazione-full-text-prepared-bytes task) (preparazione-full-text-input-bytes task)))
