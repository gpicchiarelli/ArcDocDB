;;; OWNER: il solo scheduler possiede EWMA, target e permanenza; nessun attuatore.
;;; SHARED: scheduler/metriche fuori dal percorso delle richieste (INV-P6).
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-AFF-008
(declaim (ftype (function (pool-signal (integer 0 1048576) boolean) pool-signal) %pool-ewma))
(defun %pool-ewma (previous sample reset)
  "Pre: segnali limitati. Post: scala256, alpha1/8, floor; reset usa solo il campione.
Nessun razionale crescente, loop, I/O o condizione con gli ingressi verificati."
  (if reset (* sample 256) (floor (+ (* 7 previous) (* sample 256)) 8)))

;;; REQ: REQ-THR-001 REQ-AFF-008
(declaim (ftype (function (controllore-pool) pool-direction) %pool-direction))
(defun %pool-direction (controller)
  "Pre: EWMA aggiornate. Post: direzione pura con soglie esplicite e deadband P99.
SHRINK ha precedenza; nessun errore, target non modificato."
  (cond
    ((or (>= (controllore-pool-p99 controller) 307200)
         (and (< (controllore-pool-queue controller) 256)
              (<= (controllore-pool-cpu controller) 76800))) :shrink)
    ((and (>= (controllore-pool-queue controller)
              (* 256 (controllore-pool-queue-high controller)))
          (< (controllore-pool-cpu controller) 179200)
          (<= (controllore-pool-p99 controller) 256000)) :grow)
    (t :hold)))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool pool-tick symbol) pool-direction)
                %pool-apply))
(defun %pool-apply (controller tick direction)
  "Pre: owner e tempo verificati. Post: variazione solo dopo permanenza continua.
Crescita +1, riduzione floor(3*target/4), clamp; nessuna variazione ai limiti.
INVARIANT-VIOLATION per direzione privata inattesa; nessuna attesa o thread ritirato."
  (let* ((target (controllore-pool-target controller))
         (next (case direction
                 (:grow (min (controllore-pool-maximum controller) (1+ target)))
                 (:shrink (max (controllore-pool-minimum controller) (floor (* 3 target) 4)))
                 (:hold target)
                 (otherwise (error 'invariant-violation :reason :pool-state)))))
    (cond
      ((= target next)
       (setf (controllore-pool-candidate controller) :hold
             (controllore-pool-since controller) tick)
       :hold)
      ((not (eq direction (controllore-pool-candidate controller)))
       (setf (controllore-pool-candidate controller) direction
             (controllore-pool-since controller) tick)
       :hold)
      ((< (- tick (controllore-pool-since controller)) (controllore-pool-dwell controller))
       :hold)
      (t
       (setf (controllore-pool-target controller) next
             (controllore-pool-candidate controller) :hold
             (controllore-pool-since controller) tick)
       direction))))
