;;; OWNER: lettura e controllo esclusivi del thread scheduler creatore.
;;; SHARED: nessuno; il risultato non pubblica uno stato mutabile.
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool) null) %check-pool))
(defun %check-pool (controller)
  "Pre: oggetto locale. Post: owner, target e clock coerenti senza mutazione.
INVALID-ARGUMENT :POOL-OWNER; INVARIANT-VIOLATION :POOL-STATE per stato interno."
  (unless (eq (controllore-pool-owner controller) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :pool-owner))
  (unless (<= (controllore-pool-minimum controller) (controllore-pool-target controller)
              (controllore-pool-maximum controller))
    (error 'invariant-violation :reason :pool-state))
  (unless (<= (controllore-pool-since controller) (controllore-pool-last controller))
    (error 'invariant-violation :reason :pool-state))
  nil)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool)
                         (values pool-workers pool-signal pool-signal pool-signal
                                 (or null pool-tick) pool-direction (or null pool-tick)
                                 &optional)) leggi-controllore-pool))
(defun leggi-controllore-pool (controller)
  "Pre: owner esclusivo. Post: target, EWMA queue/CPU/P99 scala 256, last, candidate, since.
Clock NIL prima del primo campione; nessuna allocazione di snapshot o mutazione.
Propaga controllo tipizzato dell'owner e delle invarianti."
  (%check-pool controller)
  (values (controllore-pool-target controller) (controllore-pool-queue controller)
          (controllore-pool-cpu controller) (controllore-pool-p99 controller)
          (if (controllore-pool-initialized controller) (controllore-pool-last controller) nil)
          (controllore-pool-candidate controller)
          (if (controllore-pool-initialized controller) (controllore-pool-since controller) nil)))
