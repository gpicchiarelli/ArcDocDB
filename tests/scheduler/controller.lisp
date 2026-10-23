;;;; Policy EWMA/AIMD: attese e risultati derivano dai campioni del test.
;;;; Gli snapshot pubblici provano l'assenza di mutazioni dopo i rifiuti.
(in-package #:arcdocdb.scheduler.tests)

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-THR-001-pool-construction-defaults-and-valid-bounds
  (dolist (cores '(1 2 65536))
    (is (equal '(1 0 0 0 nil :hold nil)
               (pool-state (crea-controllore-pool cores)))))
  (let ((controller (crea-controllore-pool
                     65536 :minimum 131072 :maximum 131072 :initial 131072
                     :period 1048576 :dwell 1048576 :queue-high 1048576)))
    (is (equal '(131072 0 0 0 nil :hold nil) (pool-state controller))))
  (let ((controller (crea-controllore-pool 2 :minimum 2 :maximum 3 :initial 3
                                         :period 1 :dwell 1 :queue-high 1)))
    (is (= 3 (first (pool-state controller))))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-private-construction-defaults-and-explicit-state
  "Fixture valida anche senza il factory pubblico; non altera tipi o codice generato."
  (let ((default (funcall (symbol-function 'arcdocdb.scheduler::%make-controllore-pool))))
    (is (funcall (symbol-function 'arcdocdb.scheduler::controllore-pool-p) default))
    (is (equal '(1 0 0 0 nil :hold nil) (pool-state default)))
    (pool-check-sample default 0 8 0 0 1 1 :hold))
  (let ((explicit (funcall (symbol-function 'arcdocdb.scheduler::%make-controllore-pool)
                           :owner sb-thread:*current-thread* :minimum 2 :maximum 6
                           :period 7 :dwell 14 :queue-high 21 :target 4 :initialized t
                           :last 123 :queue 5376 :cpu 0 :p99 0 :candidate :grow :since 116)))
    (is (equal '(4 5376 0 0 123 :grow 116) (pool-state explicit)))
    (pool-check-sample explicit 130 21 0 0 4 5 :grow))
  (dolist (other '(nil 1 :hold))
    (is (not (funcall (symbol-function 'arcdocdb.scheduler::controllore-pool-p) other)))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-generated-equality-compares-each-bounded-signal
  "Due fixture distinte hanno stato uguale; ciascun segnale diverso rompe EQUALP."
  (let* ((arguments (list :minimum 2 :maximum 6 :period 500 :dwell 2000 :queue-high 8
                          :target 4 :initialized t :last 1000 :queue 2048 :cpu 100000
                          :p99 256000 :candidate :hold :since 1000))
         (constructor (symbol-function 'arcdocdb.scheduler::%make-controllore-pool))
         (baseline (apply constructor arguments))
         (duplicate (apply constructor arguments)))
    (is (not (eq baseline duplicate)))
    (is (funcall (symbol-function 'equalp) baseline duplicate))
    (dolist (difference '((:period 501) (:dwell 2001) (:queue-high 9)
                          (:cpu 100001) (:p99 256001)))
      (let ((changed-arguments (copy-list arguments)))
        (setf (getf changed-arguments (first difference)) (second difference))
        (let ((different (apply constructor changed-arguments)))
          (is (not (funcall (symbol-function 'equalp) baseline different)))
          (is (not (funcall (symbol-function 'equalp) different baseline))))))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-declared-integer-domains-and-direction-members
  "TYPEP a runtime verifica i domini dichiarati senza assumerne l'espansione."
  (dolist (entry '((arcdocdb.scheduler::pool-tick 0 1099511627775)
                   (arcdocdb.scheduler::pool-workers 1 131072)
                   (arcdocdb.scheduler::pool-signal 0 268435456)))
    (destructuring-bind (type lower upper) entry
      (dolist (valid (list lower upper))
        (is (funcall (symbol-function 'typep) valid type)))
      (dolist (invalid (list nil (1- lower) (1+ upper) 1.0))
        (is (not (funcall (symbol-function 'typep) invalid type))))))
  (dolist (valid '(:hold :grow :shrink))
    (is (funcall (symbol-function 'typep) valid 'arcdocdb.scheduler::pool-direction)))
  (dolist (invalid '(nil :pending :unknown 1))
    (is (not (funcall (symbol-function 'typep) invalid 'arcdocdb.scheduler::pool-direction)))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-invalid-configuration-has-typed-reasons
  (dolist (bad (list nil 0 -1 65537 1.0 (1+ most-positive-fixnum)))
    (signals invalid-argument (crea-controllore-pool bad) :pool-cores))
  (dolist (entry '((:minimum :pool-minimum nil 0 -1 3 1.0)
                   (:maximum :pool-maximum 0 -1 3 1.0)
                   (:initial :pool-initial 0 -1 3 1.0)
                   (:period :pool-period nil 0 -1 1048577 1.0)
                   (:dwell :pool-dwell nil 0 -1 499 1048577 1.0)
                   (:queue-high :pool-queue-threshold nil 0 -1 1048577 1.0)))
    (destructuring-bind (keyword reason &rest bad-values) entry
      (dolist (bad bad-values)
        (signals invalid-argument
          (apply #'crea-controllore-pool 1 (list keyword bad)) reason))))
  (signals invalid-argument
    (crea-controllore-pool 2 :minimum 3 :maximum 2) :pool-maximum)
  (signals invalid-argument
    (crea-controllore-pool 2 :minimum 2 :initial 1) :pool-initial)
  (signals invalid-argument
    (crea-controllore-pool 2 :period 1000 :dwell 999) :pool-dwell))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-first-sample-seeds-exact-fixed-point-signals
  (let ((controller (crea-controllore-pool 4)))
    (pool-check-sample controller 98765 9 650 800 1 1 :hold '(2304 166400 204800))
    (is (equal '(1 2304 166400 204800 98765 :grow 98765) (pool-state controller))))
  (let ((controller (crea-controllore-pool 4)))
    (pool-check-sample controller 0 2 900 1100 1 1 :hold '(512 230400 281600))
    (is (eq :hold (sixth (pool-state controller)))))
  (let ((controller (crea-controllore-pool 4 :initial 4)))
    (pool-check-sample controller 0 9 950 1200 4 4 :hold '(2304 243200 307200))
    (is (eq :shrink (sixth (pool-state controller))))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-013-pool-ewma-independent-oracle-and-negative-rounding
  (let ((controller (crea-controllore-pool 4 :dwell 1048576))
        (expected nil))
    (loop for (queue cpu p99) in '((100 999 1199) (0 0 0) (1 1 1) (777 551 1451)
                                  (2 2 2) (0 0 0) (1048576 1000 10000))
          for tick from 0 by 500
          do (setf expected (pool-reference-sensors expected queue cpu p99))
             (pool-check-sample controller tick queue cpu p99 1 1 :hold expected))
    (is (every #'integerp expected))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-invalid-samples-preserve-entire-public-state
  (let ((controller (crea-controllore-pool 4 :minimum 2 :maximum 6 :initial 4)))
    (pool-check-sample controller 1000 2 400 1000 4 4 :hold)
    (let ((before (pool-state controller)))
      (dolist (entry (list (list 0 :pool-tick nil -1 1099511627776 1500.0)
                          (list 1 :pool-queue nil -1 1048577 1.0)
                          (list 2 :pool-cpu nil -1 1001 1.0)
                          (list 3 :pool-p99 nil -1 10001 1.0)
                          (list 4 :pool-actual nil -1 0 1 7 1.0)))
        (destructuring-bind (position reason &rest values) entry
          (dolist (bad values)
            (let ((arguments (list 1500 2 400 1000 4)))
              (setf (nth position arguments) bad)
              (signals invalid-argument
                (apply #'aggiorna-controllore-pool controller arguments) reason)
              (is (equal before (pool-state controller)))))))
      (dolist (tick '(0 999 1000 1001 1499))
        (signals invalid-argument
          (aggiorna-controllore-pool controller tick 2 400 1000 4) :pool-sample-period)
        (is (equal before (pool-state controller)))))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-sample-upper-bounds-and-clock-exhaustion
  (let ((controller (crea-controllore-pool 65536 :initial 131072)))
    (pool-check-sample controller 1099511627775 1048576 1000 10000 131072
                       131072 :hold '(268435456 256000 2560000))
    (let ((before (pool-state controller)))
      (signals invalid-argument
        (aggiorna-controllore-pool controller 1099511627776 0 0 0 131072) :pool-tick)
      (is (equal before (pool-state controller))))))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-additive-growth-needs-complete-dwell
  (let ((controller (crea-controllore-pool 4)))
    (dotimes (step 4)
      (pool-check-sample controller (* step 500) 8 699 1000 1 1 :hold)
      (is (eq :grow (sixth (pool-state controller)))))
    (pool-check-sample controller 2000 8 699 1000 1 2 :grow)
    (is (equal '(:hold 2000) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 2500 8 699 1000 2 2 :hold)
    (pool-check-sample controller 3000 8 699 1000 2 2 :hold)
    (pool-check-sample controller 3500 8 699 1000 2 2 :hold)
    (pool-check-sample controller 4000 8 699 1000 2 2 :hold)
    (pool-check-sample controller 4500 8 699 1000 2 3 :grow)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-multiplicative-decrease-floors-and-clamps
  (dolist (entry '((8 6) (7 5) (3 2) (2 1)))
    (destructuring-bind (start expected) entry
      (let ((controller (crea-controllore-pool 4 :initial start :dwell 500)))
        (pool-check-sample controller 0 100 1000 1200 start start :hold)
        (pool-check-sample controller 500 100 1000 1200 start expected :shrink))))
  (let ((controller (crea-controllore-pool 4 :minimum 4 :initial 5 :dwell 500)))
    (pool-check-sample controller 0 0 300 0 5 5 :hold)
    (pool-check-sample controller 500 0 300 0 5 4 :shrink)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-hysteresis-thresholds-are-inclusive-as-specified
  (dolist (entry '((8 699 1000 :grow) (8 700 1000 :hold) (7 699 1000 :hold)
                   (8 699 1001 :hold) (0 300 1000 :shrink) (0 301 1000 :hold)
                   (1 300 1000 :hold) (1 700 1199 :hold) (1 700 1200 :shrink)))
    (destructuring-bind (queue cpu p99 candidate) entry
      (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 500)))
        (pool-check-sample controller 0 queue cpu p99 4 4 :hold)
        (is (eq candidate (sixth (pool-state controller))))
        (pool-check-sample controller 500 queue cpu p99 4
                           (case candidate (:grow 5) (:shrink 3) (otherwise 4))
                           candidate)))))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-configurable-queue-threshold-and-custom-period
  (let ((controller (crea-controllore-pool 3 :initial 3 :period 7 :dwell 14
                                         :queue-high 21)))
    (pool-check-sample controller 3 21 1 1 3 3 :hold)
    (pool-check-sample controller 10 21 1 1 3 3 :hold)
    (pool-check-sample controller 17 21 1 1 3 4 :grow))
  (let ((controller (crea-controllore-pool 3 :initial 3 :period 7 :dwell 14
                                         :queue-high 21)))
    (dotimes (step 4) (pool-check-sample controller (* step 7) 20 1 1 3 3 :hold))))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-bounds-do-not-emit-zero-change-commands
  (let ((controller (crea-controllore-pool 1 :initial 2 :dwell 500)))
    (dotimes (step 6)
      (pool-check-sample controller (* step 500) 8 0 0 2 2 :hold)
      (is (eq :hold (sixth (pool-state controller))))))
  (let ((controller (crea-controllore-pool 1 :dwell 500)))
    (dotimes (step 6)
      (pool-check-sample controller (* step 500) 0 0 1200 1 1 :hold)
      (is (eq :hold (sixth (pool-state controller))))))
  (let ((controller (crea-controllore-pool 2 :minimum 3 :maximum 3)))
    (dotimes (step 6) (pool-check-sample controller (* step 500) 8 0 0 3 3 :hold))))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-hold-region-breaks-continuous-dwell
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 1000)))
    (pool-check-sample controller 0 8 699 1000 4 4 :hold)
    (pool-check-sample controller 500 8 707 1000 4 4 :hold '(2048 179200 256000))
    (is (eq :hold (sixth (pool-state controller))))
    (pool-check-sample controller 1000 8 0 1000 4 4 :hold)
    (is (equal '(:grow 1000) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 1500 8 0 1000 4 4 :hold)
    (pool-check-sample controller 2000 8 0 1000 4 5 :grow)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-direction-change-restarts-dwell
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 1000)))
    (pool-check-sample controller 0 8 0 0 4 4 :hold)
    (pool-check-sample controller 500 8 0 10000 4 4 :hold '(2048 0 320000))
    (is (equal '(:shrink 500) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 1000 8 0 10000 4 4 :hold)
    (pool-check-sample controller 1500 8 0 10000 4 3 :shrink)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-long-gap-resets-ewma-and-dwell
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 1000)))
    (pool-check-sample controller 0 8 0 0 4 4 :hold)
    (pool-check-sample controller 500 8 0 0 4 4 :hold)
    (pool-check-sample controller 2001 8 0 1200 4 4 :hold '(2048 0 307200))
    (is (equal '(:shrink 2001) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 2501 8 0 1200 4 4 :hold)
    (pool-check-sample controller 3001 8 0 1200 4 3 :shrink)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-gap-exactly-two-periods-keeps-existing-dwell
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 1000)))
    (pool-check-sample controller 123 8 0 0 4 4 :hold)
    (pool-check-sample controller 1123 8 0 0 4 5 :grow '(2048 0 0))))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-pending-target-is-retained-and-sensors-advance
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 500)))
    (pool-check-sample controller 0 8 0 0 4 4 :hold)
    (pool-check-sample controller 500 8 0 0 4 5 :grow)
    (pool-check-sample controller 1000 0 1000 10000 4 5 :pending '(1792 32000 320000))
    (is (equal '(:hold 1000) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 1500 0 1000 10000 6 5 :pending)
    (pool-check-sample controller 2000 0 1000 10000 5 5 :hold)
    (is (equal '(:shrink 2000) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 2500 0 1000 10000 5 3 :shrink)))

;;; REQ: REQ-THR-001 REQ-AFF-013
(deftest test-REQ-THR-001-pool-first-pending-sample-and-completed-command-dwell
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 500)))
    (pool-check-sample controller 77 8 0 0 3 4 :pending '(2048 0 0))
    (is (equal '(:hold 77) (subseq (pool-state controller) 5 7)))
    (pool-check-sample controller 577 8 0 0 4 4 :hold)
    (pool-check-sample controller 1077 8 0 0 4 5 :grow)
    (pool-check-sample controller 1577 8 0 0 5 5 :hold)
    (pool-check-sample controller 2077 8 0 0 5 6 :grow)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-cross-thread-access-rejected-without-owner-mutation
  (let* ((controller (crea-controllore-pool 4))
         (before (pool-state controller))
         (thread (pool-thread
                  "pool-controller-foreign-owner"
                  (lambda ()
                    (signals invalid-argument (leggi-controllore-pool controller) :pool-owner)
                    (signals invalid-argument
                      (aggiorna-controllore-pool controller 0 0 0 0 1) :pool-owner)
                    :ok))))
    (unwind-protect (pool-join thread) (pool-stop-threads (list thread)))
    (is (equal before (pool-state controller)))
    (pool-check-sample controller 0 8 0 0 1 1 :hold)))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-private-bound-and-clock-faults-are-detected
  "FI quiescente: modifica slot privati soltanto per i controlli delle invarianti."
  (let ((controller (crea-controllore-pool 4 :minimum 2 :maximum 6 :initial 4)))
    (pool-check-sample controller 1000 8 0 0 4 4 :hold)
    (let ((before (pool-state controller)))
      (signals invariant-violation
        (arcdocdb.scheduler::%pool-apply controller 1000 :unknown) :pool-state)
      (is (equal before (pool-state controller)))
      (dolist (target '(1 7))
        (setf (arcdocdb.scheduler::controllore-pool-target controller) target)
        (signals invariant-violation (leggi-controllore-pool controller) :pool-state)
        (signals invariant-violation
          (aggiorna-controllore-pool controller 1500 1 400 1000 4) :pool-state)
        (setf (arcdocdb.scheduler::controllore-pool-target controller) 4)
        (is (equal before (pool-state controller))))
      (setf (arcdocdb.scheduler::controllore-pool-since controller) 1001)
      (signals invariant-violation (leggi-controllore-pool controller) :pool-state)
      (signals invariant-violation
        (aggiorna-controllore-pool controller 1500 1 400 1000 4) :pool-state)
      (setf (arcdocdb.scheduler::controllore-pool-since controller) 1000)
      (is (equal before (pool-state controller))))))

(defun pool-parallel-sequence (ordinal)
  "Ogni thread crea il proprio stato; 256 campioni deterministici non condivisi."
  (let ((controller (crea-controllore-pool 4 :initial 4 :dwell 1048576))
        (expected nil))
    (dotimes (step 256)
      (let ((queue (mod (+ (* step 31) ordinal) 1048577))
            (cpu (mod (+ (* step 43) ordinal) 1001))
            (p99 (mod (+ (* step 59) ordinal) 10001)))
        (setf expected (pool-reference-sensors expected queue cpu p99))
        (pool-check-sample controller (* step 500) queue cpu p99 4 4 :hold expected)))
    :ok))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-013
(deftest test-REQ-CON-005-pool-independent-controllers-have-deterministic-parallel-traces
  (let ((threads nil) (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore)))
    (unwind-protect
         (progn
           (dotimes (ordinal 8)
             (let ((seed ordinal))
               (push (pool-thread (format nil "pool-controller-~D" seed)
                                  (lambda ()
                                    (sb-thread:signal-semaphore ready)
                                    (pool-wait start)
                                    (pool-parallel-sequence seed))) threads)))
           (pool-wait ready 8)
           (dotimes (ordinal 8) (sb-thread:signal-semaphore start))
           (dolist (thread threads) (pool-join thread)))
      (pool-stop-threads threads))))
