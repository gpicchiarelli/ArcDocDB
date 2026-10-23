;;;; Nuova presa governata; gli obblighi esistenti hanno un ingresso indipendente.
;;; OWNER: dispatcher, contesto e collegamenti locali al medesimo worker.
;;; SHARED: solo API pool/ready/routing esistenti per tratto (ADR-0045 §8).
(in-package #:arcdocdb.scheduler.dispatch)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (dispatcher-writer-pool)
                         (values (or null arcdocdb.execution.series:collegamento-worker-serie)
                                 (member :claimed :empty :busy :inactive) index
                                 (member :unchanged :activated :retired :busy :faulted) &optional))
                prendi-collegamento-pool))
(defun prendi-collegamento-pool (dispatcher)
  "Pre: owner corrente, worker IDLE libero. Post: link preallocato solo dopo CLAIMED,
oppure NIL/esito/cursore/azione originali del gate. Nessun begin, lease o pop.
Binding rifiutato prima del gate; errori delegati mantengono confini e obblighi.
Un fault di routing conserva il claim e l'ACK già riuscito, senza rollback."
  (let ((port (dispatcher-writer-pool-port dispatcher))
        (table (dispatcher-writer-pool-table dispatcher)))
    (%check-dispatcher-binding port table)
    (multiple-value-bind (writer status cursor action)
        (arcdocdb.scheduler:prendi-writer-pool port)
      (case status
        (:claimed
         (unless writer (error 'invariant-violation :reason :pool-dispatcher-state))
         (values (arcdocdb.execution.series:collega-writer-worker-serie table)
                 status cursor action))
        ((:empty :busy :inactive)
         (when writer (error 'invariant-violation :reason :pool-dispatcher-state))
         (values nil status cursor action))
        (otherwise (error 'invariant-violation :reason :pool-dispatcher-state))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (dispatcher-writer-pool) arcdocdb.execution.series:collegamento-worker-serie)
                collega-obbligo-pool))
(defun collega-obbligo-pool (dispatcher)
  "Pre: owner corrente, CLAIMED già assunto da busy begin, ricircolo o adozione.
Post: link corrente preallocato, selezione ripetibile senza nuove capacità.
Non legge comandi/active e non conferma ritiro: il caller completa l'obbligo.
Binding/owner e routing delegati; fase/fault preservati dai confini C1 esistenti."
  (let ((port (dispatcher-writer-pool-port dispatcher))
        (table (dispatcher-writer-pool-table dispatcher)))
    (%check-dispatcher-binding port table)
    (arcdocdb.execution.series:collega-writer-worker-serie table)))
