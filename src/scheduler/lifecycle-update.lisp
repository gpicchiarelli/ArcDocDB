;;; OWNER: coordinator unico, fuori dai compiti di richiesta e non rientrante.
;;; SHARED: richieste CAS per porta, una sola ondata monotona in corso (INV-P6).
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (porta-worker-pool pool-command pool-command) null) %pool-request-command))
(defun %pool-request-command (port old word)
  "Pre: coordinatore esclusivo, parola validata, OLD corrente. Post: REQUEST pubblicata.
INVARIANT-VIOLATION :POOL-PORT-STATE su conflitto; non attesta un comando fallito."
  (sb-thread:barrier (:write))
  (unless (= old (sb-ext:compare-and-swap (porta-worker-pool-request port) old word))
    (error 'invariant-violation :reason :pool-port-state))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (registro-pool) null) %pool-generation-budget))
(defun %pool-generation-budget (registry)
  "Pre: owner e porte stabili. Post: una nuova generazione disponibile su ogni porta.
RESOURCE-EXHAUSTED :POOL-GENERATION prima di campione/comandi; nessun wrap/reset.
Preflight conservativo anche per hold: l'esaurimento richiede sostituzione amministrativa."
  (let ((ports (registro-pool-ports registry)))
    (dotimes (i (length ports))
      (unless (< (ash (porta-worker-pool-request (svref ports i)) -1)
                 (ash most-positive-fixnum -1))
        (error 'resource-exhausted :reason :pool-generation))))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (registro-pool pool-workers) null) %pool-publish-target))
(defun %pool-publish-target (registry target)
  "Pre: porte stabili, generazioni disponibili, nuovo target validato dal controller.
Post: solo bit modificati ricevono generation+1; ACK esclusivo resta al worker.
Un'ondata cresce oppure ritira: finché pending, actual differisce dal target."
  (let ((ports (registro-pool-ports registry)))
    (dotimes (i (length ports))
      (let* ((port (svref ports i)) (old (porta-worker-pool-request port))
             (active (< i target)))
        (unless (eq (oddp old) active)
          (let ((word (+ (logand old -2) 2 (if active 1 0))))
            (%pool-request-command port old word)))))
    (setf (registro-pool-target registry) target))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (registro-pool t t t t)
                         (values pool-workers (member :hold :pending :grow :shrink)
                                 pool-workers boolean &optional)) aggiorna-registro-pool))
(defun aggiorna-registro-pool (registry tick queue cpu p99)
  "Pre: owner esclusivo; tempo e metriche iniettati come nel controller.
Post: target, azione, actual letto prima del campione, pending corrente/conservativo.
Nessuna nuova ondata finché esistono ACK pendenti; nessun blocco/allocazione normale.
Preflight typed prima delle scritture; controller collegato aggiornato solo qui."
  (multiple-value-bind (actual old-target pending) (leggi-registro-pool registry)
    (unless pending (%pool-generation-budget registry))
    (multiple-value-bind (target action)
        (aggiorna-controllore-pool (registro-pool-controller registry) tick queue cpu p99 actual)
      (unless (= target old-target)
        (%pool-publish-target registry target)
        (setf pending t))
      (values target action actual pending))))
