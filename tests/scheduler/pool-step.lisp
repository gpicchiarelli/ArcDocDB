;;;; Un passo bounded seleziona claim, obbligo corrente oppure ricircolo.
;;;; OWNER: porta, dispatcher, contesto e link sul creatore della fixture.
;;;; FI quiescenti: sentinelle ripristinate, parole/binding/limiti dichiarati.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-step-check (dispatcher link status origin detail action)
  "Oracolo dei cinque valori: cursore, count e NIL non sono intercambiabili."
  (is (equal (list link status origin detail action)
             (multiple-value-list
              (arcdocdb.scheduler.dispatch:passo-dispatcher-pool dispatcher)))))

(defun pool-step-delegates (expected thunk)
  "FI di osservazione: una sola chiamata all'ingresso selezionato, zero agli altri."
  (let ((names #(arcdocdb.scheduler.dispatch:prendi-collegamento-pool
                 arcdocdb.scheduler.dispatch:collega-obbligo-pool
                 arcdocdb.scheduler.dispatch:ricircola-collegamento-pool))
        (origins #(:claim :current :recycle)) (calls (vector 0 0 0)))
    (labels ((protect (index)
               (if (= index 3) (funcall thunk)
                   (let ((original (fdefinition (svref names index))))
                     (pool-claim-function-fi
                      (svref names index)
                      (lambda (dispatcher)
                        (incf (svref calls index)) (funcall original dispatcher))
                      (lambda () (protect (1+ index))))))))
      (multiple-value-prog1 (protect 0)
        (dotimes (index 3)
          (is (= (if (eq expected (svref origins index)) 1 0) (svref calls index))))))))

(defun pool-step-without-progress (thunk)
  "Nessun begin, pop, ACK batch o end prima che il caller li richieda esplicitamente."
  (labels ((protect (names)
             (if (null names) (funcall thunk)
                 (pool-claim-function-fi
                  (first names)
                  (lambda (&rest arguments) (declare (ignore arguments))
                    (error "Avanzamento implicito nel passo dispatcher: ~S." (first names)))
                  (lambda () (protect (rest names)))))))
    (protect '(arcdocdb.scheduler.dispatch:inizia-obbligo-pool
               arcdocdb.execution.series:inizia-worker-serie
               arcdocdb.execution.series:preleva-worker-serie
               arcdocdb.execution.series:conferma-worker-serie
               arcdocdb.execution.series:termina-worker-serie))))

(defun pool-step-refusal (dispatcher port table writers type reason)
  (pool-dispatch-refusal
   port table writers
   (lambda () (arcdocdb.scheduler.dispatch:passo-dispatcher-pool dispatcher)) type reason))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-step-idle-activates-before-claim-and-forwards-original-cursor
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :shards 3 :start 1 :left-items '(:a1))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 0))))
    ;; FI coordinator quiescente: l'ACK deve precedere la vera presa di A.
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
    (let ((before (map 'list #'pool-dispatch-series-image controllers))
          (link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-step-without-progress
       (lambda ()
         (pool-step-delegates :claim
          (lambda () (pool-step-check dispatcher link :claimed :claim 0 :activated)))))
      (is (equal '(3 3 nil) (lifecycle-words port)))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq (svref writers 0) (arcdocdb.execution:writer-worker-writer context)))
      (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
      (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
      (is (equalp before (map 'list #'pool-dispatch-series-image controllers)))
      (pool-dispatch-finish link :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-step-idle-empty-rotates-once-without-implicit-second-attempt
  (with-pool-dispatch (dispatcher port context ready table writers controllers :shards 3 :start 1)
    (declare (ignorable ready))
    (let ((before (map 'list #'pool-dispatch-series-image controllers)))
      (pool-step-without-progress
       (lambda ()
         (pool-step-delegates :claim
          (lambda () (pool-step-check dispatcher nil :empty :claim 2 :unchanged)))))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
      (is (null (arcdocdb.execution:writer-worker-writer context)))
      (is (equal '(1 1 nil) (lifecycle-words port)))
      (is (equalp before (map 'list #'pool-dispatch-series-image controllers)))
      (is (every (lambda (link) (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
                 (arcdocdb.execution.series::tabella-worker-serie-links table))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-step-idle-real-ready-busy-forwards-status-without-retry
  (with-pool-dispatch (dispatcher port context ready table writers controllers :shards 3 :start 1)
    (declare (ignorable port controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (let ((partition (arcdocdb.execution.tests::ready-test-partition ready 2)))
      (arcdocdb.execution.tests::ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (arcdocdb.execution.tests::ready-fi-snapshot partition)))
           (pool-step-without-progress
            (lambda ()
              (pool-step-delegates :claim
               (lambda () (pool-step-check dispatcher nil :busy :claim 2 :unchanged)))))
           (is (equalp before (arcdocdb.execution.tests::ready-fi-snapshot partition)))))))
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 1) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1) :b1 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-step-idle-inactive-keeps-ready-and-cursor-without-scan
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :shards 3 :start 2 :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((before (pool-dispatch-image port table writers)))
      (pool-claim-function-fi
       'arcdocdb.execution::%prova-pronta
       (lambda (partition) (declare (ignore partition)) (error "Scansione inattiva nel passo."))
       (lambda ()
         (pool-step-without-progress
          (lambda ()
            (pool-step-delegates :claim
             (lambda () (pool-step-check dispatcher nil :inactive :claim 2 :unchanged)))))))
      (is (equalp before (pool-dispatch-image port table writers))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 1)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a1 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-step-idle-pending-retire-acknowledges-before-ready-access
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :start 1 :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 0))))
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (let ((before (arcdocdb.execution.tests::ready-fi-snapshot
                   (arcdocdb.execution.tests::ready-test-partition ready 2))))
      (pool-claim-function-fi
       'arcdocdb.execution::%prova-pronta
       (lambda (partition) (declare (ignore partition)) (error "Scansione dopo ritiro."))
       (lambda ()
         (pool-step-delegates :claim
          (lambda () (pool-step-check dispatcher nil :inactive :claim 1 :retired)))))
      (is (equal '(2 2 nil) (lifecycle-words port)))
      (is (equalp before (arcdocdb.execution.tests::ready-fi-snapshot
                         (arcdocdb.execution.tests::ready-test-partition ready 2)))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a1 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-step-current-ignores-inactive-corrupt-and-retire-words
  (dolist (scenario '(:inactive :corrupt :retire))
    (with-pool-dispatch (dispatcher port context ready table writers controllers
                                   :active (not (eq scenario :inactive)) :left-items '(:a1))
      (declare (ignorable ready controllers))
      (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
      ;; FI coordinator quiescente: CURRENT non valida o conferma il canale pool.
      (case scenario
        (:corrupt (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
                        (arcdocdb.scheduler::porta-worker-pool-ack port) 0))
        (:retire (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)))
      (let ((before (pool-dispatch-image port table writers))
            (link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
        (pool-recycle-without-gate
         (lambda ()
           (pool-step-without-progress
            (lambda ()
              (pool-step-delegates :current
               (lambda () (pool-step-check dispatcher link :claimed :current nil nil)))))))
        (is (equalp before (pool-dispatch-image port table writers)))
        (pool-dispatch-finish link :a1 :idle))
      (when (eq scenario :retire)
        (pool-step-check dispatcher nil :inactive :claim 0 :retired)
        (is (equal '(2 2 nil) (lifecycle-words port)))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-step-room-publishes-and-returns-without-fall-through-or-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :capacity 2 :start 1)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (pool-recycle-without-gate
     (lambda ()
       (pool-step-without-progress
        (lambda ()
          (pool-step-delegates :recycle
           (lambda () (pool-step-check dispatcher nil :published :recycle 2 nil)))))))
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
    (is (null (arcdocdb.execution:writer-worker-writer context)))
    (is (zerop (arcdocdb.execution::contesto-worker-writer-cursor context)))
    (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
    (is (equal '(2 1 nil) (lifecycle-words port)))
    ;; Solo il passo successivo osserva IDLE e conferma il ritiro pendente.
    (pool-step-check dispatcher nil :inactive :claim 0 :retired)
    (is (equal '(2 2 nil) (lifecycle-words port)))
    ;; FIFO atteso B poi A: entrambi sono rimasti nel ring dopo il passo room.
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 1) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1) :b1 :idle)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a2 :idle)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-step-full-routes-b-once-and-next-step-is-current
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :start 1)
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1))
          (before (map 'list #'pool-dispatch-series-image controllers)))
      (pool-recycle-without-gate
       (lambda ()
         (pool-step-without-progress
          (lambda ()
            (pool-step-delegates :recycle
             (lambda () (pool-step-check dispatcher link :claimed :recycle 1 nil)))))))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq (svref writers 1) (arcdocdb.execution:writer-worker-writer context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
      (is (zerop (arcdocdb.execution::contesto-worker-writer-cursor context)))
      (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
      (is (equalp before (map 'list #'pool-dispatch-series-image controllers)))
      (is (equal '(1 1 nil) (lifecycle-words port)))
      (let ((current-before (pool-dispatch-image port table writers)))
        (pool-step-delegates :current
         (lambda () (pool-step-check dispatcher link :claimed :current nil nil)))
        (is (equalp current-before (pool-dispatch-image port table writers))))
      (pool-dispatch-finish link :b1 :idle))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a2 :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-step-reschedule-ready-busy-preserves-obligation-without-retry
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
    ;; Contesa reale sulla guard CAS della partizione home, non BUSY sintetico.
    (arcdocdb.execution.tests::ready-call-with-guards
     (list (arcdocdb.execution.tests::ready-test-partition ready 0))
     (lambda ()
       (pool-step-without-progress
        (lambda ()
          (pool-step-delegates :recycle
           (lambda () (pool-step-refusal dispatcher port table writers
                                          'resource-exhausted :ready-queue-busy)))))))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1)))
      (pool-step-check dispatcher link :claimed :recycle 1 nil)
      (pool-dispatch-finish link :b1 :idle))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a2 :idle)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-step-running-batch-finishing-and-faulted-refuse-before-delegation
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (flet ((refuse ()
             (pool-step-delegates nil
              (lambda () (pool-step-refusal dispatcher port table writers
                                             'resource-exhausted :worker-state)))))
      (let* ((link (pool-begin-claim dispatcher context ready table writers))
             (token (pool-claim-bridge-begin link)))
        (refuse)
        (let ((batch (pool-claim-bridge-pop link token :a1)))
          (refuse)
          (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch))))
        (lifecycle-queue-busy
         (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
         (lambda ()
           (signals resource-exhausted
             (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
           (is (eq :finishing (arcdocdb.execution:stato-worker-writer context)))
           (refuse)))
        (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
        (pool-recycle-check dispatcher nil :published 1)
        (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
        (pool-dispatch-finish link :a2 :idle))
      ;; FI diagnostica: la prima causa e terminale, mai sostituita da un rifiuto C3.
      (let ((original (make-condition 'invariant-violation :reason :worker-state)))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (refuse)
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-step-binding-precedes-phase-and-any-operational-entry
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (let* ((other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                       other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                       (arcdocdb.execution.series::tabella-worker-serie-links table)))
           (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
      (pool-claim-function-fi
       'arcdocdb.execution:stato-worker-writer
       (lambda (worker) (declare (ignore worker)) (error "Fase letta prima del binding."))
       (lambda ()
         (pool-step-delegates nil
          (lambda () (pool-step-refusal bad port table writers
                                         'invalid-argument :pool-dispatcher-binding)))))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer other))))
    (pool-step-check dispatcher nil :published :recycle 1 nil)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a2 :idle)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-step-foreign-owner-precedes-binding-phase-and-pool-words
  ;; Prova negativa su owner distinto; non afferma lavoro positivo concorrente.
  (let ((worker (lifecycle-fixture-start t)) (dispatcher nil) (table nil) (writers nil)
        (left-file nil) (right-file nil))
    (unwind-protect
         (progn
           (lifecycle-call
            worker
            (lambda (owned)
              (multiple-value-bind (left resource) (pool-claim-series 89)
                (setf left-file resource)
                (multiple-value-bind (right resource) (pool-claim-series 90)
                  (setf right-file resource writers (vector (pool-claim-writer '(:a1) 0)
                                                           (pool-claim-writer '(:b1) 1))
                        table (arcdocdb.execution.series:crea-tabella-worker-serie
                               (lifecycle-fixture-context owned)
                               (arcdocdb.execution.series:crea-registro-worker-serie
                                writers (vector left right)))
                        dispatcher (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                                    (lifecycle-fixture-port owned) table))))
              (is (null (arcdocdb.execution:adotta-writer-worker
                         (lifecycle-fixture-context owned) (svref writers 0) 0))) :ok))
           (let* ((port (lifecycle-fixture-port worker))
                  (other (arcdocdb.execution:crea-contesto-worker-writer
                          (pool-claim-ready (lifecycle-fixture-context worker))))
                  (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                              other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                              (arcdocdb.execution.series::tabella-worker-serie-links table)))
                  (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4)
             (pool-claim-function-fi
              'arcdocdb.execution:stato-worker-writer
              (lambda (context) (declare (ignore context)) (error "Fase da owner straniero."))
              (lambda ()
                (pool-step-delegates nil
                 (lambda () (pool-step-refusal bad port table writers
                                                'invalid-argument :pool-worker-owner)))))
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 1))
           (lifecycle-call
            worker
            (lambda (owned)
              (declare (ignore owned))
              (pool-dispatch-finish
               (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a1 :idle)
              :ok)))
      (when left-file
        (lifecycle-call worker (lambda (owned) (declare (ignore owned))
                                 (when right-file (arcdocdb.io:chiudi right-file))
                                 (arcdocdb.io:chiudi left-file) :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-step-full-routing-fault-keeps-transfer-and-first-condition-eq
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :start 1)
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (let* ((unknown (pool-claim-writer '(:unknown) 2))
           (series-before (map 'list #'pool-dispatch-series-image controllers))
           (old-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0)))
           (unknown-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown)))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 unknown)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
      (let ((condition
              (pool-step-without-progress
               (lambda ()
                 (pool-step-delegates :recycle
                  (lambda ()
                    (arcdocdb.execution.tests::worker-capture-condition
                     (lambda () (arcdocdb.scheduler.dispatch:passo-dispatcher-pool dispatcher))
                     'invariant-violation :worker-serie-routing)))))))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq unknown (arcdocdb.execution:writer-worker-writer context)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
        (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-cursor context)))
        (is (equal '(2 1 nil) (lifecycle-words port)))
        (is (equalp old-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
        (is (equalp unknown-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown)))
        (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
        (pool-step-delegates nil
         (lambda () (pool-step-refusal dispatcher port table writers
                                        'resource-exhausted :worker-state)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context))))
      ;; Il vecchio A e gia nel ring: niente rollback o seconda presa dopo il fault.
      (multiple-value-bind (writer status next) (arcdocdb.execution:preleva-writer-pronto ready 2)
        (is (eq writer (svref writers 0))) (is (eq status :writer)) (is (zerop next))))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-step-claim-routing-fault-keeps-successful-activation-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :shards 3 :start 1)
    (let* ((unknown (pool-claim-writer '(:unknown) 2))
           (series-before (map 'list #'pool-dispatch-series-image controllers)))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 unknown)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
      (let ((condition
              (pool-step-delegates :claim
               (lambda ()
                 (arcdocdb.execution.tests::worker-capture-condition
                  (lambda () (arcdocdb.scheduler.dispatch:passo-dispatcher-pool dispatcher))
                  'invariant-violation :worker-serie-routing)))))
        (is (equal '(3 3 nil) (lifecycle-words port)))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq unknown (arcdocdb.execution:writer-worker-writer context)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-cursor context)))
        (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
        (pool-step-delegates nil
         (lambda () (pool-step-refusal dispatcher port table writers
                                        'resource-exhausted :worker-state)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-step-getter-fi-outside-type-refuses-before-delegation
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable ready controllers))
    (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
    (labels ((reject-phase (phase)
               (let ((calls 0))
                 ;; FI fuori dalla ftype del getter, distinta dalle fasi nominali C1.
                 (pool-claim-function-fi
                  'arcdocdb.execution:stato-worker-writer
                  (lambda (worker) (declare (ignore worker)) (incf calls) phase)
                  (lambda ()
                    (pool-step-delegates nil
                     (lambda () (pool-step-refusal dispatcher port table writers
                                                    'invariant-violation :pool-dispatcher-state)))))
                 (is (= 1 calls)))))
      (dolist (phase (list :unknown nil 0 "invalid" '(invalid) #()))
        (reject-phase phase))
      (pool-dispatch-finish
       (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) :a1 :idle)
      ;; FI diagnostica: il rifiuto C3 non sostituisce una prima causa gia presente.
      (let ((original (make-condition 'invariant-violation :reason :worker-state)))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (reject-phase :unknown)
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-step-invalid-dispatcher-type-keeps-fixture
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher context ready controllers))
    (let ((before (pool-dispatch-image port table writers)))
      (signals type-error
        (funcall (fdefinition 'arcdocdb.scheduler.dispatch:passo-dispatcher-pool) :invalid))
      (is (equalp before (pool-dispatch-image port table writers))))))
