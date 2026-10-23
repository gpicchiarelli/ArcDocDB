;;;; Avvio esplicito di un obbligo gia acquisito, senza consultare il pool.
;;; OWNER: dispatcher, contesto e link locali al medesimo thread, non rientrante.
;;; SHARED: routing immutabile e lease della sola Serie per tratto (ADR-0045 §8).
(in-package #:arcdocdb.scheduler.dispatch)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (dispatcher-writer-pool)
                         (values arcdocdb.execution.series:collegamento-worker-serie index
                                 (member :active :closing)
                                 (member nil :serie-busy :serie-lease-generation) &optional))
                inizia-obbligo-pool))
(defun inizia-obbligo-pool (dispatcher)
  "Pre: owner corrente, worker CLAIMED e link associato IDLE, nessuna rientranza.
Post: link corrente e token/fase/ragione originali di un solo begin del bridge.
Binding prima del routing; writer busy conserva CLAIMED/link IDLE senza token;
Serie busy/esaurita restituisce CLOSING/token da chiudere esplicitamente.
Nessun gate, ACK, claim, ricircolo, pop, retry o cleanup; errori C1 propagati
con capacita e causa conservate dai confini originali, senza fault marking C3."
  (let ((port (dispatcher-writer-pool-port dispatcher))
        (table (dispatcher-writer-pool-table dispatcher)))
    (%check-dispatcher-binding port table)
    (let ((link (arcdocdb.execution.series:collega-writer-worker-serie table)))
      (multiple-value-bind (token state reason)
          (arcdocdb.execution.series:inizia-worker-serie link)
        (values link token state reason)))))
