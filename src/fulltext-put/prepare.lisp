(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(declaim (ftype (function (preparazione-put-full-text) null) attesta-cornice-put-worker))
(defun attesta-cornice-put-worker (request)
  "Pre: worker esclusivo, tutti i task DONE sullo stesso frame immutabile.
Post: CRC/spans verificati e attestazione della generation, prima di ogni lease writer.
Scansione body addebitata al budget worker; errore invalida il risultato, nessuna riserva."
  (let ((size (preparazione-put-full-text-size request)))
    (when (> size (- (preparazione-put-full-text-work-limit request) (preparazione-put-full-text-work request)))
      (error 'resource-exhausted :reason :fulltext-put-work))
    (incf (preparazione-put-full-text-work request) size)
    (multiple-value-bind (next kind flags ks ke vs ve)
        (r:verifica-cornice (preparazione-put-full-text-frame request) 0 size
                           :version (preparazione-put-full-text-version request)
                           :document-limit (preparazione-put-full-text-document-limit request))
      (declare (ignore flags ks ke)) ; prodotti dal codec privato e verificati dal decoder.
      (unless (and (= next size) (= kind r:+put+) (= vs (preparazione-put-full-text-value-start request)) (= ve size))
        (error 'invariant-violation :reason :fulltext-put-worker-frame)))
    (setf (preparazione-put-full-text-validated-generation request) (preparazione-put-full-text-generation request)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-put-full-text) null) analizza-unita-put))
(defun analizza-unita-put (request)
  "Pre: PREPARING esclusivo. Post: un passo documentale o avanzamento generazione.
Ogni task analizza lo span dello stesso frame privato; lavoro cumulativo prima dell'ammissione."
  (when (>= (preparazione-put-full-text-work request) (preparazione-put-full-text-work-limit request))
    (error 'resource-exhausted :reason :fulltext-put-work))
  (incf (preparazione-put-full-text-work request))
  (let* ((current (preparazione-put-full-text-current request))
         (task (svref (preparazione-put-full-text-tasks request) current)))
    (unless (preparazione-put-full-text-active request)
      (let ((remaining (- (preparazione-put-full-text-work-limit request) (preparazione-put-full-text-work request))))
        (when (zerop remaining) (error 'resource-exhausted :reason :fulltext-put-work))
        (d:inizia-preparazione-full-text task (preparazione-put-full-text-frame request)
                                       (preparazione-put-full-text-value-start request) (preparazione-put-full-text-size request)
                                       (preparazione-put-full-text-row request) :max-work remaining)
        (setf (preparazione-put-full-text-active request) t)))
    (let* ((before (d::preparazione-full-text-work task))
           (remaining (- (preparazione-put-full-text-work-limit request) (preparazione-put-full-text-work request))))
      (setf (d::preparazione-full-text-work-limit task)
            (min (d::preparazione-full-text-work-limit task) (+ before remaining)))
      (let ((status (d:passo-preparazione-full-text task 1)))
        (incf (preparazione-put-full-text-work request) (- (d::preparazione-full-text-work task) before))
        (unless (<= (preparazione-put-full-text-work request) (preparazione-put-full-text-work-limit request))
          (error 'invariant-violation :reason :fulltext-put-work-state))
        (when (eq :done status)
          (incf (preparazione-put-full-text-current request))
          (setf (preparazione-put-full-text-active request) nil)
          (when (= (preparazione-put-full-text-current request) (length (preparazione-put-full-text-tasks request)))
            (attesta-cornice-put-worker request)
            (setf (preparazione-put-full-text-state request) :prepared))))))
  nil)

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (preparazione-put-full-text keyword) null) rilascia-analisi-put))
(defun rilascia-analisi-put (request state)
  "Pre: solo worker, nessuna riserva del writer. Post: analisi attiva cancellata e nessun prestito frame.
Buffer privati conservati, nessun rollback di WAL o riserva; errori interni richiedono fail-stop."
  (when (preparazione-put-full-text-active request)
    (let ((task (svref (preparazione-put-full-text-tasks request) (preparazione-put-full-text-current request))))
      (when (eq :running (d:stato-preparazione-full-text task)) (d:annulla-preparazione-full-text task))))
  (setf (preparazione-put-full-text-active request) nil (preparazione-put-full-text-state request) state
        (preparazione-put-full-text-validated-generation request) 0)
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t t t) keyword) passo-put-full-text))
(defun passo-put-full-text (request generation quantum)
  "Pre: generation corrente e PREPARING/PREPARED, quantum 1..65536. Post: stato o errore tipizzato.
Rifiuti di budget/CBOR rendono FAILED senza dati parziali; invarianti al confine worker."
  (verifica-token-put request generation)
  (unless (and (typep quantum '(integer 1 65536))
               (member (preparazione-put-full-text-state request) '(:preparing :prepared)))
    (error 'invalid-argument :reason :fulltext-put-step))
  (handler-case
      (dotimes (i quantum)
        (when (eq :prepared (preparazione-put-full-text-state request)) (return))
        (analizza-unita-put request))
    (arcdocdb-error (condition) (rilascia-analisi-put request :failed) (error condition)))
  (preparazione-put-full-text-state request))

;;; REQ: REQ-SEC-006
(declaim (ftype (function (t t) keyword) annulla-put-full-text))
(defun annulla-put-full-text (request generation)
  "Pre: token corrente, analisi o risultato mai riservato. Post: CANCELLED idempotente fino al riuso.
Non e l'abort di un prepared gia accodato; nessun accesso a WAL o CSN."
  (verifica-token-put request generation)
  (unless (member (preparazione-put-full-text-state request) '(:preparing :prepared :cancelled))
    (error 'invalid-argument :reason :fulltext-put-cancel))
  (rilascia-analisi-put request :cancelled) :cancelled)
