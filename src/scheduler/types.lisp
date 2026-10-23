;;;; Aritmetica intera limitata: massimo intermedio EWMA 2^31.
;;; OWNER: thread scheduler creatore, accesso esclusivo non rientrante.
;;; SHARED: scheduler/metriche fuori dal percorso delle richieste (INV-P6).
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftype pool-tick () '(integer 0 1099511627775))
(deftype pool-workers () '(integer 1 131072))
(deftype pool-signal () '(integer 0 268435456))
(deftype pool-direction () '(member :hold :grow :shrink))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(defstruct (controllore-pool (:constructor %make-controllore-pool)
                           (:copier nil))
  "Pre: configurazione verificata e thread proprietario. Post: target iniziale fisso.
Gli ingressi sono aggregati esternamente; nessuna coda, thread, attesa o I/O.
Nessuna condizione della costruzione privata oltre ai tipi degli slot."
  (owner sb-thread:*current-thread* :type sb-thread:thread :read-only t)
  (minimum 1 :type pool-workers :read-only t)
  (maximum 1 :type pool-workers :read-only t)
  (period 500 :type (integer 1 1048576) :read-only t)
  (dwell 2000 :type (integer 1 1048576) :read-only t)
  (queue-high 8 :type (integer 1 1048576) :read-only t)
  (target 1 :type pool-workers)
  (initialized nil :type boolean)
  (last 0 :type pool-tick)
  (queue 0 :type pool-signal)
  (cpu 0 :type (integer 0 256000))
  (p99 0 :type (integer 0 2560000))
  (candidate :hold :type pool-direction)
  (since 0 :type pool-tick))
