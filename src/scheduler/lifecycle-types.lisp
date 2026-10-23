;;;; Attivazione logica di worker preesistenti; nessun thread o attesa nel prodotto.
;;; OWNER: contesto e ack al worker; request/binding al coordinatore non rientrante.
;;; SHARED: una porta per worker, al massimo un comando per campione (INV-P6).
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftype pool-command () '(and fixnum unsigned-byte))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-005 REQ-AFF-008
(defstruct (porta-worker-pool
             (:constructor %make-porta-worker-pool (owner coordinator context request ack))
             (:copier nil))
  "Pre: creazione sul worker IDLE, coordinator valido. Post: stato iniziale confermato.
REQUEST/ACK = 2*generazione + bit attivo; un solo comando outstanding, mai reset.
Il ritiro conserva contesto, thread e diagnostica; non trasferisce obblighi."
  (owner sb-thread:*current-thread* :type sb-thread:thread :read-only t)
  (coordinator sb-thread:*current-thread* :type sb-thread:thread :read-only t)
  (context (error 'invariant-violation :reason :pool-port-state)
           :type arcdocdb.execution:contesto-worker-writer :read-only t)
  (request 1 :type pool-command) (ack 1 :type pool-command)
  (bound nil :type boolean))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(defstruct (registro-pool
             (:constructor %make-registro-pool (controller ports owner target)) (:copier nil))
  "Pre: porte distinte, stabili e prefisso attivo uguale al target del controller.
Post: vettore privato, binding permanente; accesso owner-only senza snapshot heap.
ACTUAL conta conferme logiche, non thread OS o stato di salute dell'Archivio."
  (controller (error 'invariant-violation :reason :pool-state)
              :type controllore-pool :read-only t)
  (ports #() :type simple-vector :read-only t)
  (owner sb-thread:*current-thread* :type sb-thread:thread :read-only t)
  (target 1 :type pool-workers))
