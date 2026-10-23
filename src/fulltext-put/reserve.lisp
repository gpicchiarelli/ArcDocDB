(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (t t t t) null) verifica-riserva-put))
(defun verifica-riserva-put (pool lease request generation)
  "Pre: token request e lease del writer. Post: stessa riserva privata, copying/ready.
Rifiuti di tipo/stato/provenienza prima di ogni effetto o accesso al lotto."
  (verifica-token-put request generation) (f::verifica-writer-riserve pool lease)
  (unless (and (eq pool (preparazione-put-full-text-pool request))
               (member (preparazione-put-full-text-state request) '(:reserving :reserved)))
    (error 'invalid-argument :reason :fulltext-put-reservation))
  (f::verifica-token-riserva pool (preparazione-put-full-text-slot request) (preparazione-put-full-text-slot-generation request))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t t) keyword) prenota-put-full-text))
(defun prenota-put-full-text (pool lease request generation)
  "Pre: PREPARED consegnato dal worker al writer con handoff sincronizzato.
Post: riserva di tutti i task sullo stesso frame, handle trattenuti privatamente fino all'append.
Rifiuti del pool prima degli effetti; uscita incompleta nell'adozione => request/pool FAULTED."
  (verifica-token-put request generation) (f::verifica-writer-riserve pool lease)
  (unless (eq :prepared (preparazione-put-full-text-state request))
    (error 'invalid-argument :reason :fulltext-put-not-prepared))
  (esigi-cornice-put-validata request)
  (let ((complete nil) (before (f::riserve-full-text-generation pool)))
    (unwind-protect
         (multiple-value-bind (slot token) (f:prenota-full-text pool lease (preparazione-put-full-text-tasks request))
           (setf (preparazione-put-full-text-pool request) pool (preparazione-put-full-text-slot request) slot
                 (preparazione-put-full-text-slot-generation request) token (preparazione-put-full-text-state request) :reserving
                 complete t)
           :reserving)
      (unless (or complete (and (= before (f::riserve-full-text-generation pool))
                                (eq :healthy (f::riserve-full-text-state pool))))
        (setf (preparazione-put-full-text-state request) :faulted (f::riserve-full-text-state pool) :faulted)))))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t t t) keyword) passo-riserva-put-full-text))
(defun passo-riserva-put-full-text (pool lease request generation quantum)
  "Pre: riserva privata valida e quantum 1..65536. Post: RESERVING o RESERVED dopo tutte le copie.
Ogni fonte viene restituita al contesto, che non puo essere riavviato prima dell'append/cancellazione."
  (verifica-riserva-put pool lease request generation)
  (unless (typep quantum '(integer 1 65536)) (error 'invalid-argument :reason :fulltext-put-quantum))
  (let ((complete nil))
    (unwind-protect
         (progn
           (when (eq :ready (f:passo-riserva-full-text pool lease (preparazione-put-full-text-slot request)
                                                     (preparazione-put-full-text-slot-generation request) quantum))
             (setf (preparazione-put-full-text-state request) :reserved))
           (setf complete t) (preparazione-put-full-text-state request))
      (unless complete (setf (preparazione-put-full-text-state request) :faulted (f::riserve-full-text-state pool) :faulted)))))

;;; REQ: REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(declaim (ftype (function (t t t t) keyword) annulla-riserva-put-full-text))
(defun annulla-riserva-put-full-text (pool lease request generation)
  "Pre: prima dell'append, riserva privata del request. Post: costi restituiti e CANCELLED.
Non ritira un PUT accodato/prepared e non converte un commit deciso in abort."
  (verifica-riserva-put pool lease request generation)
  (let ((complete nil))
    (unwind-protect
         (progn
           (f:annulla-riserva-full-text pool lease (preparazione-put-full-text-slot request)
                                      (preparazione-put-full-text-slot-generation request))
           (setf (preparazione-put-full-text-state request) :cancelled complete t) :cancelled)
      (unless complete (setf (preparazione-put-full-text-state request) :faulted (f::riserve-full-text-state pool) :faulted)))))
