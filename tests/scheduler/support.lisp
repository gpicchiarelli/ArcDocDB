;;;; Fixture del controllore: campioni e tempo iniettati, oracoli senza slot privati.
(defpackage #:arcdocdb.scheduler.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation #:resource-exhausted
                #:error-reason)
  (:import-from #:arcdocdb.scheduler #:crea-controllore-pool
                #:aggiorna-controllore-pool #:leggi-controllore-pool)
  (:export #:run))
(in-package #:arcdocdb.scheduler.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test del controllore pool superati.~%" (length *tests*))
  t)

(defun pool-state (controller)
  "Snapshot pubblico; nessuna lettura della rappresentazione del controllore."
  (multiple-value-list (leggi-controllore-pool controller)))

(defun pool-check-sample (controller tick queue cpu p99 actual target status
                         &optional expected-sensors)
  (multiple-value-bind (command actual-status)
      (aggiorna-controllore-pool controller tick queue cpu p99 actual)
    (is (= target command))
    (is (eq status actual-status)))
  (let ((state (pool-state controller)))
    (is (= target (first state)))
    (is (= tick (fifth state)))
    (when expected-sensors (is (equal expected-sensors (subseq state 1 4))))))

(defun pool-reference-sensors (previous queue cpu p99)
  "Oracolo razionale: arrotonda ciascuna media soltanto dopo la ponderazione."
  (let ((samples (list queue cpu p99)))
    (if previous
        (mapcar (lambda (old sample) (floor (+ (* 7/8 old) (* 32 sample))))
                previous samples)
        (mapcar (lambda (sample) (* 256 sample)) samples))))

(defun pool-thread (name thunk)
  "Gli errori appartengono alla fixture e vengono restituiti al join bounded."
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

(defun pool-wait (semaphore &optional (count 1))
  "La barriera della fixture attende al massimo 15 secondi, mai nel prodotto."
  (unless (sb-thread:wait-on-semaphore semaphore :n count :timeout 15)
    (error "Barriera della fixture oltre il limite."))
  t)

(defun pool-join (thread)
  (let ((result (sb-thread:join-thread thread :timeout 15 :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq result :ok))))

(defun pool-stop-threads (threads)
  "Rilascia soltanto thread della fixture, anche se un'asserzione interrompe il test."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated))
  nil)
