;;; OWNER: passo bounded sul thread della porta, tra compiti a completamento.
;;; SHARED: ACK release/CAS per ondata; nessun campo writer/Serie modificato.
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (porta-worker-pool pool-command pool-command) null) %pool-ack-command))
(defun %pool-ack-command (port old word)
  "Pre: worker owner verificato, barriera IDLE passata, OLD letto acquire. Post: ACK pubblicato.
INVARIANT-VIOLATION :POOL-PORT-STATE su conflitto; nessun falso successo."
  (sb-thread:barrier (:write))
  (unless (= old (sb-ext:compare-and-swap (porta-worker-pool-ack port) old word))
    (error 'invariant-violation :reason :pool-port-state))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (porta-worker-pool)
                         (values boolean (member :unchanged :activated :retired :busy :faulted)
                                 &optional)) applica-stato-worker-pool))
(defun applica-stato-worker-pool (port)
  "Pre: owner corrente non rientrante; chiamare tra compiti, senza epoca/risorse esterne.
Post: bit actual e stato; conferma soltanto dopo barriera C1 IDLE completa.
BUSY/FAULTED conservano comando e obblighi; nessuna revoca, release, reset o attesa.
INVALID-ARGUMENT owner; invarianti della porta/contesto propagate senza occultarle."
  (unless (eq (porta-worker-pool-owner port) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :pool-worker-owner))
  (multiple-value-bind (request ack) (%pool-port-words port)
    (when (= request ack)
      (return-from applica-stato-worker-pool (values (oddp ack) :unchanged)))
    (let* ((context (porta-worker-pool-context port))
           (state (arcdocdb.execution:stato-worker-writer context)))
      (unless (eq state :idle)
        (return-from applica-stato-worker-pool
          (values (oddp ack) (if (eq state :faulted) :faulted :busy))))
      (arcdocdb.execution::%richiedi-worker context :idle))
    (%pool-ack-command port ack request)
    (values (oddp request) (if (oddp request) :activated :retired))))
