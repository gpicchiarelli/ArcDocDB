;;;; Binding immutabile tra porta del pool e routing locale dello stesso worker.
;;; OWNER: dispatcher e tabella del thread creatore; nessuna migrazione o reentrancy.
;;; SHARED: nessuna nuova struttura condivisa o scrittura globale per operazione.
(in-package #:arcdocdb.scheduler.dispatch)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(defstruct (dispatcher-writer-pool
             (:constructor %make-dispatcher-writer-pool (port table)) (:copier nil))
  "Pre: porta e tabella sul medesimo contesto IDLE, owner corrente verificato.
Post: binding preallocato immutabile; nessun claim, lease o comando applicato."
  (port nil :type arcdocdb.scheduler:porta-worker-pool :read-only t)
  (table nil :type arcdocdb.execution.series:tabella-worker-serie :read-only t))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (t t) null) %check-dispatcher-binding))
(defun %check-dispatcher-binding (port table)
  "Pre: factory o dispatcher privato. Post: owner e identità del contesto validi.
INVALID-ARGUMENT configuration/owner/binding prima di ACK, claim o routing.
Nessuna lettura di fase, parole pool, ready, lease o controller vivo."
  (unless (typep port 'arcdocdb.scheduler:porta-worker-pool)
    (error 'invalid-argument :reason :pool-dispatcher-configuration))
  (unless (eq (arcdocdb.scheduler::porta-worker-pool-owner port) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :pool-worker-owner))
  (unless (typep table 'arcdocdb.execution.series:tabella-worker-serie)
    (error 'invalid-argument :reason :pool-dispatcher-configuration))
  (unless (eq (arcdocdb.scheduler::porta-worker-pool-context port)
              (arcdocdb.execution.series::tabella-worker-serie-context table))
    (error 'invalid-argument :reason :pool-dispatcher-binding))
  nil)
