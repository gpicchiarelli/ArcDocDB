;;; OWNER: diagnostica del registro al coordinatore, ack solo al proprio worker.
;;; SHARED: letture acquire di parole CAS fixnum indipendenti per worker.
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (porta-worker-pool) (values pool-command pool-command &optional))
                %pool-port-words))
(defun %pool-port-words (port)
  "Pre: coordinator esclusivo o worker owner. Post: parole acquire coerenti.
INVARIANT-VIOLATION :POOL-PORT-STATE se comando duplicato, regressivo o salto."
  (let ((request (porta-worker-pool-request port)) (ack (porta-worker-pool-ack port)))
    (sb-thread:barrier (:read))
    (unless (or (= request ack)
                (and (= (ash request -1) (1+ (ash ack -1)))
                     (not (eq (oddp request) (oddp ack)))))
      (error 'invariant-violation :reason :pool-port-state))
    (values request ack)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (registro-pool) null) %check-registro-pool))
(defun %check-registro-pool (registry)
  "Pre: accesso non rientrante. Post: owner e target/controller coerenti.
INVALID-ARGUMENT owner; INVARIANT-VIOLATION target o capacità privata."
  (unless (eq (registro-pool-owner registry) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :pool-owner))
  (%check-pool (registro-pool-controller registry))
  (unless (and (= (registro-pool-target registry)
                  (controllore-pool-target (registro-pool-controller registry)))
               (= (controllore-pool-maximum (registro-pool-controller registry))
                  (length (registro-pool-ports registry))))
    (error 'invariant-violation :reason :pool-state))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (registro-pool) (values pool-workers pool-workers boolean &optional))
                leggi-registro-pool))
(defun leggi-registro-pool (registry)
  "Pre: owner esclusivo; porte private non modificate esternamente.
Post: actual da ACK, target, pending da REQUEST/=ACK. Snapshot progressivo bounded;
senza pending tutte le conferme corrispondono al target. Propaga verificatori typed."
  (%check-registro-pool registry)
  (let ((actual 0) (pending nil) (ports (registro-pool-ports registry)))
    (declare (type (integer 0 131072) actual))
    (dotimes (i (length ports))
      (multiple-value-bind (request ack) (%pool-port-words (svref ports i))
        (unless (eq (oddp request) (< i (registro-pool-target registry)))
          (error 'invariant-violation :reason :pool-port-state))
        (when (oddp ack) (incf actual))
        (unless (= request ack) (setf pending t))))
    (unless (<= (controllore-pool-minimum (registro-pool-controller registry)) actual
                (controllore-pool-maximum (registro-pool-controller registry)))
      (error 'invariant-violation :reason :pool-state))
    (values actual (registro-pool-target registry) pending)))
