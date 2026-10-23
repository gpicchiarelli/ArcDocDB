;;; OWNER: thread creatore prima della pubblicazione, configurazione immutabile.
;;; SHARED: nessuno; nessuna lettura di metriche reali o numero di core del sistema.
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (t fixnum fixnum keyword) pool-tick) %pool-range))
(defun %pool-range (value lower upper reason)
  "Pre: limiti fixnum validi. Post: intero verificato; INVALID-ARGUMENT prima di mutare."
  (unless (and (typep value 'fixnum) (<= lower value upper))
    (error 'invalid-argument :reason reason))
  value)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (t &key (:minimum t) (:maximum t) (:initial t)
                          (:period t) (:dwell t) (:queue-high t)) controllore-pool)
                crea-controllore-pool))
(defun crea-controllore-pool (cores &key (minimum 1) maximum initial
                                      (period 500) (dwell 2000) (queue-high 8))
  "Pre: configurazione stabile; CORES iniettato, non rilevato dal sistema.
Post: target INITIAL (default MINIMUM), MAXIMUM default 2*CORES, owner corrente.
INVALID-ARGUMENT dominio/ordine; alloca solo all'avvio, nessun thread avviato."
  (let* ((core-count (%pool-range cores 1 65536 :pool-cores))
         (low (%pool-range minimum 1 (* 2 core-count) :pool-minimum))
         (high (%pool-range (if maximum maximum (* 2 core-count))
                            low (* 2 core-count) :pool-maximum))
         (start (%pool-range (if initial initial low) low high :pool-initial))
         (interval (%pool-range period 1 1048576 :pool-period))
         (residence (%pool-range dwell interval 1048576 :pool-dwell))
         (pressure (%pool-range queue-high 1 1048576 :pool-queue-threshold)))
    (%make-controllore-pool :minimum low :maximum high :target start
                           :period interval :dwell residence :queue-high pressure)))
