;;;; Un solo passo di selezione e, sul solo CLAIMED, un tentativo di avvio.
;;; OWNER: dispatcher, contesto e link sul thread creatore, senza reentrancy.
;;; SHARED: ready/pool per tratto e lease della sola Serie; nessun nuovo stato.
(in-package #:arcdocdb.scheduler.dispatch)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (notinline %prepara-tratto-esito))
(declaim (ftype (function (t t (member :claim :current :recycle) (or null index)
                           (member nil :unchanged :activated :retired :busy :faulted))
                         (values (or null arcdocdb.execution.series:collegamento-worker-serie)
                                 index (member :active :closing :empty :busy :inactive :published)
                                 (member nil :serie-busy :serie-lease-generation)
                                 (member :claim :current :recycle) (or null index)
                                 (member nil :unchanged :activated :retired :busy :faulted) &optional))
                %prepara-tratto-esito))
(defun %prepara-tratto-esito (link status origin detail action)
  "Pre: un solo passo concluso dall'owner non rientrante, metadati originali.
Post: CLAIMED avviato una volta; altri esiti senza token o lavoro implicito.
Link/status T e NOTINLINE mantengono la difesa operativa fuori ftype.
INVARIANT-VIOLATION coppia/status; guasti C1 propagati senza rollback o cleanup."
  (case status
    (:claimed
     (unless (typep link 'arcdocdb.execution.series:collegamento-worker-serie)
       (error 'invariant-violation :reason :pool-dispatcher-state))
     (multiple-value-bind (token state reason)
         (arcdocdb.execution.series:inizia-worker-serie link)
       (values link token state reason origin detail action)))
    ((:empty :busy :inactive :published)
     (unless (null link) (error 'invariant-violation :reason :pool-dispatcher-state))
     (values nil 0 status nil origin detail action))
    (otherwise (error 'invariant-violation :reason :pool-dispatcher-state))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (dispatcher-writer-pool)
                         (values (or null arcdocdb.execution.series:collegamento-worker-serie)
                                 index (member :active :closing :empty :busy :inactive :published)
                                 (member nil :serie-busy :serie-lease-generation)
                                 (member :claim :current :recycle) (or null index)
                                 (member nil :unchanged :activated :retired :busy :faulted) &optional))
                prepara-tratto-pool))
(defun prepara-tratto-pool (dispatcher)
  "Pre: owner non rientrante, IDLE/CLAIMED/RESCHEDULE e bridge precedente chiuso.
Post: selezione e al piu un begin, sette valori con token/fase/ragione originali.
Una pubblicazione termina subito. Nessun secondo routing, pop, ACK, end o retry.
Binding/fasi/guasti delegati; CLOSING e capacita dopo errore restano al caller."
  (multiple-value-bind (link status origin detail action) (passo-dispatcher-pool dispatcher)
    (%prepara-tratto-esito link status origin detail action)))
