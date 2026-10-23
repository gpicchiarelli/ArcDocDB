;;; OWNER: aggiornamento non rientrante sul solo thread scheduler, nessun callback.
;;; SHARED: scheduler/metriche fuori dal percorso delle richieste (INV-P6).
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool t t t t t) pool-tick) %pool-sample))
(defun %pool-sample (controller tick queue cpu p99 actual)
  "Pre: owner verificato. Post: tutto il campione valido prima di qualsiasi scrittura.
INVALID-ARGUMENT dominio, actual fuori min..max, clock regressivo o intervallo troppo breve."
  (%pool-range tick 0 1099511627775 :pool-tick)
  (%pool-range queue 0 1048576 :pool-queue)
  (%pool-range cpu 0 1000 :pool-cpu)
  (%pool-range p99 0 10000 :pool-p99)
  (%pool-range actual (controllore-pool-minimum controller)
               (controllore-pool-maximum controller) :pool-actual)
  (when (controllore-pool-initialized controller)
    (unless (>= (- tick (controllore-pool-last controller)) (controllore-pool-period controller))
      (error 'invalid-argument :reason :pool-sample-period)))
  tick)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool t t t t t)
                         (values pool-workers (member :hold :pending :grow :shrink) &optional))
                aggiorna-controllore-pool))
(defun aggiorna-controllore-pool (controller tick queue cpu p99 actual)
  "Pre: owner esclusivo; tempo, coda, CPU/P99 in millimi e worker effettivi iniettati.
Post: target limitato e azione; :PENDING conserva target se actual diverso, senza attesa.
Gap >2 periodi resetta EWMA/permanenza. Propaga preflight tipizzato senza mutazione.
Non crea/ritira thread, non revoca target pending, non tratta ready EMPTY come quiescenza."
  (%check-pool controller)
  (%pool-sample controller tick queue cpu p99 actual)
  (let ((reset (or (not (controllore-pool-initialized controller))
                   (> (- tick (controllore-pool-last controller))
                      (* 2 (controllore-pool-period controller))))))
    (setf (controllore-pool-queue controller) (%pool-ewma (controllore-pool-queue controller) queue reset)
          (controllore-pool-cpu controller) (%pool-ewma (controllore-pool-cpu controller) cpu reset)
          (controllore-pool-p99 controller) (%pool-ewma (controllore-pool-p99 controller) p99 reset)
          (controllore-pool-initialized controller) t
          (controllore-pool-last controller) tick)
    (when reset
      (setf (controllore-pool-candidate controller) :hold (controllore-pool-since controller) tick))
    (let ((action (if (/= actual (controllore-pool-target controller))
                      (progn
                        (setf (controllore-pool-candidate controller) :hold
                              (controllore-pool-since controller) tick)
                        :pending)
                      (%pool-apply controller tick (%pool-direction controller)))))
      (%check-pool controller)
      (values (controllore-pool-target controller) action))))
