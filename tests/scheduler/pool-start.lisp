;;;; Selezione e un solo begin: sette risultati e obblighi reali conservati.
;;;; OWNER: fixture e FI quiescenti sul creatore; foreign-owner su thread distinto.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-start-check (dispatcher link token state reason origin detail action)
  (is (equal (list link token state reason origin detail action)
             (multiple-value-list
              (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher))))
  token)

(defun pool-start-observe (routes begins thunk)
  "Conta il solo ingresso; vieta seconda selezione, routing e lavoro implicito."
  (let ((names #(arcdocdb.scheduler.dispatch:passo-dispatcher-pool
                 arcdocdb.execution.series:collega-writer-worker-serie
                 arcdocdb.execution.series:inizia-worker-serie
                 arcdocdb.execution.series:preleva-worker-serie
                 arcdocdb.execution.series:conferma-worker-serie
                 arcdocdb.execution.series:termina-worker-serie
                 arcdocdb.scheduler.dispatch:inizia-obbligo-pool))
        (expected (vector 1 routes begins 0 0 0 0)) (calls (make-array 7 :initial-element 0)))
    (labels ((protect (index)
               (if (= index 7) (funcall thunk)
                   (let ((original (fdefinition (svref names index))))
                     (pool-claim-function-fi
                      (svref names index)
                      (lambda (&rest args) (incf (svref calls index)) (apply original args))
                      (lambda () (protect (1+ index))))))))
      (multiple-value-prog1 (protect 0) (is (equalp expected calls))))))

(defun pool-start-refusal (dispatcher port table writers type reason)
  (pool-dispatch-refusal
   port table writers (lambda () (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher))
   type reason))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-start-activation-claim-and-one-begin-with-original-metadata
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :shards 3 :left-items '(:a1))
    (declare (ignorable controllers))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 1 (svref writers 0))))
      (pool-start-observe
       1 1 (lambda () (pool-start-check dispatcher link 1 :active nil :claim 2 :activated)))
      (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
      (is (equal '(3 3 nil) (lifecycle-words port)))
      (is (= 1 (arcdocdb.execution::coda-writer-count
                (arcdocdb.execution::writer-programmabile-queue (svref writers 0)))))
      (pool-begin-complete link 1 :a1 :idle))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-start-empty-busy-inactive-never-route-or-begin
  (with-pool-dispatch (dispatcher port context ready table writers controllers :shards 3)
    (declare (ignorable controllers))
    (pool-start-observe 0 0 (lambda ()
                             (pool-start-check dispatcher nil 0 :empty nil :claim 1 :unchanged)))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 1 (svref writers 0))))
    (arcdocdb.execution.tests::ready-call-with-guards
     (list (arcdocdb.execution.tests::ready-test-partition ready 1))
     (lambda ()
       (pool-start-observe 0 0 (lambda ()
                                (pool-start-check dispatcher nil 0 :busy nil :claim 2 :unchanged)))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 2)
    (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a1 :schedule)
    (pool-recycle-check dispatcher nil :published 1)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 2)
    (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle))
  (with-pool-dispatch (dispatcher port context ready table writers controllers :active nil)
    (declare (ignorable context controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((before (pool-dispatch-image port table writers)))
      (pool-start-observe 0 0 (lambda ()
                               (pool-start-check dispatcher nil 0 :inactive nil :claim 0 :unchanged)))
      (is (equalp before (pool-dispatch-image port table writers))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a1 :schedule)
    (pool-recycle-check dispatcher nil :published 1)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-start-current-prioritizes-obligation-over-inactive-or-retirement
  (dolist (retire '(nil t))
    (with-pool-dispatch (dispatcher port context ready table writers controllers
                                   :active retire :left-items '(:a1))
      (declare (ignorable ready controllers))
      (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
      (when retire (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2))
      (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0))
            (words (lifecycle-words port)))
        (pool-start-observe 1 1 (lambda ()
                                 (pool-start-check dispatcher link 1 :active nil :current nil nil)))
        (is (equal words (lifecycle-words port)))
        (pool-begin-complete link 1 :a1 :idle)
        (when retire
          (pool-start-check dispatcher nil 0 :inactive nil :claim 0 :retired))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-start-full-begins-new-writer-and-preserves-pending-retirement
  (with-pool-dispatch (dispatcher port context ready table writers controllers :shards 3 :start 1)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (let ((right (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1)))
      (pool-start-observe 1 1 (lambda ()
                               (pool-start-check dispatcher right 1 :active nil :recycle 1 nil)))
      (is (eq (svref writers 1) (arcdocdb.execution:writer-worker-writer context)))
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (pool-begin-complete right 1 :b1 :idle))
    (pool-start-check dispatcher nil 0 :inactive nil :claim 0 :retired)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-start-room-stops-after-publication-without-second-claim-or-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :capacity 2 :shards 3 :start 1)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (pool-start-observe 0 0 (lambda ()
                             (pool-start-check dispatcher nil 0 :published nil :recycle 2 nil)))
    (is (equal '(2 1 nil) (lifecycle-words port)))
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
    (pool-start-check dispatcher nil 0 :inactive nil :claim 0 :retired)
    (loop for ordinal in '(1 0) for item in '(:b1 :a2)
          do (arcdocdb.execution.tests::worker-check-claim context (svref writers ordinal) :claimed 0)
             (pool-dispatch-finish (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) item :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-start-writer-busy-preserves-claimed-and-consumes-no-token
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable ready controllers))
    (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
    (lifecycle-queue-busy
     (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
     (lambda () (pool-start-refusal dispatcher port table writers
                                    'resource-exhausted :writer-queue-busy)))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-start-check dispatcher link 1 :active nil :current nil nil)
      (pool-begin-complete link 1 :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-start-writer-busy-after-claim-keeps-transfer-and-activation-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :left-items '(:a1))
    (declare (ignorable controllers))
    (let* ((writer (svref writers 0))
           (link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      (lifecycle-queue-busy
       (arcdocdb.execution::writer-programmabile-queue writer)
       (lambda ()
         (pool-start-observe
          1 1 (lambda ()
                (arcdocdb.execution.tests::worker-capture-condition
                 (lambda () (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher))
                 'resource-exhausted :writer-queue-busy)))))
      (is (equal '(3 3 nil) (lifecycle-words port)))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
      (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
      (pool-start-check dispatcher link 1 :active nil :current nil nil)
      (pool-begin-complete link 1 :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-routing-fault-after-claim-never-begins-or-rolls-back-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers :active nil)
    (declare (ignorable writers))
    (let ((unknown (pool-claim-writer '(:unknown) 2))
          (before (map 'list #'pool-dispatch-series-image controllers)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 unknown)))
      (let ((cause
              (pool-start-observe
               1 0 (lambda ()
                     (arcdocdb.execution.tests::worker-capture-condition
                      (lambda () (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher))
                      'invariant-violation :worker-serie-routing)))))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq cause (arcdocdb.execution:errore-worker-writer context)))
        (is (eq unknown (arcdocdb.execution:writer-worker-writer context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (equal '(3 3 nil) (lifecycle-words port)))
        (is (equalp before (map 'list #'pool-dispatch-series-image controllers)))
        (is (every (lambda (link) (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
                   (arcdocdb.execution.series::tabella-worker-serie-links table)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-start-ready-busy-keeps-reschedule-and-ring
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (arcdocdb.execution.tests::ready-call-with-guards
     (list (arcdocdb.execution.tests::ready-test-partition ready 0))
     (lambda () (pool-start-refusal dispatcher port table writers
                                    'resource-exhausted :ready-queue-busy)))
    (pool-start-check dispatcher nil 0 :published nil :recycle 1 nil)
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-start-check dispatcher link 2 :active nil :claim 0 :unchanged)
      (pool-begin-complete link 2 :a2 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-serie-busy-or-generation-exhausted-returns-live-closing-token
  (dolist (scenario '(:busy :generation))
    (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
      (let* ((controller (svref controllers 0))
             (link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0))
             (held (when (eq scenario :busy) (arcdocdb.series:acquisisci-controllore-serie controller)))
             (saved (arcdocdb.series::controllore-serie-lease-generation controller)))
        (unwind-protect
             (progn
               (when (eq scenario :generation)
                 (setf (arcdocdb.series::controllore-serie-lease-generation controller)
                       most-positive-fixnum))
               (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
               (pool-start-observe
                1 1 (lambda ()
                      (pool-start-check dispatcher link 1 :closing
                                        (if held :serie-busy :serie-lease-generation)
                                        :claim 0 :unchanged)))
               (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
               (is (eq :closing (arcdocdb.execution.series:stato-worker-serie link)))
               (is (plusp (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
               (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
               (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link 1))))
          (if held (arcdocdb.series:rilascia-controllore-serie controller held)
              (setf (arcdocdb.series::controllore-serie-lease-generation controller) saved)))
        (pool-start-check dispatcher nil 0 :published nil :recycle 1 nil)
        (pool-start-check dispatcher link 2 :active nil :claim 0 :unchanged)
        (pool-begin-complete link 2 :a1 :idle)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-local-generation-limit-before-either-lease
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable ready controllers))
    (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
    (let* ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0))
           (saved (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
      (unwind-protect
           (progn
             (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link)
                   most-positive-fixnum)
             (pool-start-refusal dispatcher port table writers
                                 'resource-exhausted :worker-serie-generation))
        (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link) saved))
      (pool-start-check dispatcher link 1 :active nil :current nil nil)
      (pool-begin-complete link 1 :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-start-active-batch-finishing-and-faulted-refuse-without-effects
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-start-check dispatcher link 1 :active nil :claim 0 :unchanged)
      (flet ((refuse () (pool-start-refusal dispatcher port table writers
                                           'resource-exhausted :worker-state)))
        (refuse)
        (let ((batch (pool-claim-bridge-pop link 1 :a1)))
          (refuse) (arcdocdb.execution.series:conferma-worker-serie link 1 batch))
        (lifecycle-queue-busy
         (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
         (lambda ()
           (signals resource-exhausted (arcdocdb.execution.series:termina-worker-serie link 1)
                    :writer-queue-busy)
           (refuse)))
        (is (eq :idle (arcdocdb.execution.series:termina-worker-serie link 1)))
        (let ((original (make-condition 'invariant-violation :reason :worker-state)))
          (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
                (arcdocdb.execution::contesto-worker-writer-fault context) original)
          (refuse) (is (eq original (arcdocdb.execution:errore-worker-writer context))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-binding-before-selection-or-acquisition
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher context controllers))
    (let* ((other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                       other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                       (arcdocdb.execution.series::tabella-worker-serie-links table)))
           (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
      (pool-start-observe
       0 0 (lambda () (pool-start-refusal bad port table writers
                                          'invalid-argument :pool-dispatcher-binding))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-start-real-foreign-owner-refuses-before-routing
  (let ((worker (lifecycle-fixture-start t)))
    (multiple-value-bind (controller file) (pool-claim-series 95)
      (unwind-protect
           (let* ((writers (vector (pool-claim-writer '(:kept) 0)))
                  (registry (arcdocdb.execution.series:crea-registro-worker-serie
                             writers (vector controller)))
                  (dispatcher
                    (lifecycle-call
                     worker (lambda (owned)
                              (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                               (lifecycle-fixture-port owned)
                               (arcdocdb.execution.series:crea-tabella-worker-serie
                                (lifecycle-fixture-context owned) registry))))))
             (pool-start-observe
              0 0 (lambda ()
                    (signals invalid-argument
                      (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher) :pool-worker-owner))))
        (lifecycle-fixtures-stop (list worker)) (arcdocdb.io:chiudi file)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-defensive-status-and-link-pairs-are-operational
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable context ready controllers))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (dolist (row (list (list nil :claimed) (list :bad :claimed)
                        (list link :empty) (list link :busy) (list link :inactive)
                        (list link :published) (list nil :future) (list nil nil)
                        (list nil 7) (list nil :running)))
        (pool-claim-function-fi
         'arcdocdb.scheduler.dispatch:passo-dispatcher-pool
         (lambda (value) (declare (ignore value))
           (values (first row) (second row) :claim 0 :unchanged))
         (lambda () (pool-start-observe
                     0 0 (lambda () (pool-start-refusal dispatcher port table writers
                                                        'invariant-violation :pool-dispatcher-state)))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-unexpected-acquire-keeps-first-c1-cause-and-writer-lease
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let* ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0))
           (writer (svref writers 0))
           (cause (make-condition 'arcdocdb.conditions:io-fault :reason :pool-start-acquire
                                  :operation :series))
           (before (map 'list #'pool-dispatch-series-image controllers)) (lease nil))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      (unwind-protect
           (let ((caught
                   (pool-claim-function-fi
                    'arcdocdb.series:acquisisci-controllore-serie
                    (lambda (value) (declare (ignore value)) (error cause))
                    (lambda () (arcdocdb.execution.tests::worker-capture-condition
                                (lambda () (arcdocdb.scheduler.dispatch:prepara-tratto-pool dispatcher))
                                'arcdocdb.conditions:io-fault :pool-start-acquire)))))
             (setf lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
             (is (eq cause caught)) (is (plusp lease))
             (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
             (is (eq :faulted (arcdocdb.execution.series:stato-worker-serie link)))
             (is (eq cause (arcdocdb.execution:errore-worker-writer context)))
             (is (eq cause (arcdocdb.execution.series:errore-worker-serie link)))
             (is (equalp before (map 'list #'pool-dispatch-series-image controllers)))
             (pool-start-refusal dispatcher port table writers 'resource-exhausted :worker-state)
             (is (eq cause (arcdocdb.execution:errore-worker-writer context))))
        (when lease (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-start-invalid-dispatcher-is-typed-and-does-not-touch-fixture
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher context ready controllers))
    (let ((before (pool-dispatch-image port table writers)))
      (signals type-error
        (funcall (fdefinition 'arcdocdb.scheduler.dispatch:prepara-tratto-pool) :invalid))
      (is (equalp before (pool-dispatch-image port table writers))))))
