;;;; Ricircolo pool: un trasferimento ready e routing del solo obbligo CLAIMED.
;;;; OWNER: fixture, porta, dispatcher e bridge sul thread creatore.
;;;; FI quiescenti dichiarate: immagini, binding/parole corrotti e sentinelle ripristinate.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-recycle-check (dispatcher link status count)
  "Oracolo dei tre valori; count atteso dal caller, mai derivato dal cursore."
  (is (equal (list link status count)
             (multiple-value-list
              (arcdocdb.scheduler.dispatch:ricircola-collegamento-pool dispatcher)))))

(defun pool-recycle-reschedule (dispatcher context ready writers home)
  "A viene acquisito e termina realmente un primo quantum con obbligo RESCHEDULE."
  (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready home (svref writers 0))))
  (arcdocdb.execution.tests::worker-check-claim
   context (svref writers 0) :claimed
   (mod (1+ home) (length (arcdocdb.execution::lista-writer-pronti-partitions ready))))
  (pool-dispatch-finish
   (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a1 :schedule)
  (is (eq :reschedule (arcdocdb.execution:stato-worker-writer context))))

(defun pool-recycle-without-gate (thunk)
  "FI di chiamata: nessun nuovo claim o ACK lifecycle durante un obbligo esistente."
  (pool-claim-function-fi
   'arcdocdb.scheduler:prendi-writer-pool
   (lambda (port) (declare (ignore port)) (error "Nuovo gate durante ricircolo."))
   (lambda ()
     (pool-claim-function-fi
      'arcdocdb.scheduler:applica-stato-worker-pool
      (lambda (port) (declare (ignore port)) (error "ACK pool durante ricircolo."))
      thunk))))

(defun pool-recycle-refusal (dispatcher port table writers type reason)
  (pool-dispatch-refusal
   port table writers
   (lambda () (arcdocdb.scheduler.dispatch:ricircola-collegamento-pool dispatcher))
   type reason))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-recycle-room-publishes-once-without-second-claim-or-routing
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :capacity 2 :start 1)
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (let ((series-before (map 'list #'pool-dispatch-series-image controllers))
          (cursor (arcdocdb.execution::contesto-worker-writer-cursor context))
          (home (arcdocdb.execution::contesto-worker-writer-home context))
          (calls 0) (original (fdefinition 'arcdocdb.execution:ricircola-worker)))
      (is (zerop cursor)) (is (= 2 home))
      (pool-recycle-without-gate
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution:ricircola-worker
          (lambda (worker) (incf calls) (funcall original worker))
          (lambda ()
            (pool-claim-function-fi
             'arcdocdb.execution.series:collega-writer-worker-serie
             (lambda (routing) (declare (ignore routing))
               (error "Routing dopo pubblicazione senza nuovo obbligo."))
             (lambda () (pool-recycle-check dispatcher nil :published 2)))))))
      (is (= 1 calls))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
      (is (null (arcdocdb.execution:writer-worker-writer context)))
      (is (= cursor (arcdocdb.execution::contesto-worker-writer-cursor context)))
      (is (= home (arcdocdb.execution::contesto-worker-writer-home context)))
      (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
      (is (equal '(1 1 nil) (lifecycle-words port))))
    ;; L'oracolo FIFO B poi A e indipendente dagli indici privati del ring.
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 1) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :b1 :idle)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)
    (is (every (lambda (link) (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
               (arcdocdb.execution.series::tabella-worker-serie-links table)))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-recycle-full-routes-new-writer-without-begin-or-cursor-change
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :start 1)
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
    (let* ((links (arcdocdb.execution.series::tabella-worker-serie-links table))
           (right (svref links 1))
           (series-before (map 'list #'pool-dispatch-series-image controllers))
           (left-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0)))
           (right-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 1)))
           (other-before (loop for i below 2 collect
                              (arcdocdb.execution.tests::ready-fi-snapshot
                               (arcdocdb.execution.tests::ready-test-partition ready i))))
           (original (fdefinition 'arcdocdb.execution:ricircola-worker)) (calls 0))
      (pool-recycle-without-gate
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution:ricircola-worker
          (lambda (worker) (incf calls) (funcall original worker))
          (lambda () (pool-recycle-check dispatcher right :claimed 1)))))
      (is (= 1 calls))
      (is (eq (svref writers 1) (arcdocdb.execution:writer-worker-writer context)))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie right)))
      (is (= 0 (arcdocdb.execution::contesto-worker-writer-cursor context)))
      (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
      (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
      (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
      (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
      (is (equalp left-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
      (is (equalp right-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 1))))
      (is (equalp other-before (loop for i below 2 collect
                                    (arcdocdb.execution.tests::ready-fi-snapshot
                                     (arcdocdb.execution.tests::ready-test-partition ready i)))))
      (is (equal '(1 1 nil) (lifecycle-words port)))
      (pool-dispatch-finish right :b1 :idle))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-recycle-ready-busy-preserves-complete-obligation-and-ring
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
    ;; Vera guardia CAS detenuta dalla fixture; nessun BUSY sintetico.
    (arcdocdb.execution.tests::ready-call-with-guards
     (list (arcdocdb.execution.tests::ready-test-partition ready 0))
     (lambda ()
       (pool-recycle-without-gate
        (lambda () (pool-recycle-refusal dispatcher port table writers
                                          'resource-exhausted :ready-queue-busy)))))
    (pool-recycle-check dispatcher
                        (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1)
                        :claimed 1)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :b1 :idle)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-recycle-six-disallowed-phases-preserve-debts-and-first-fault
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (flet ((refuse () (pool-recycle-refusal dispatcher port table writers
                                             'resource-exhausted :worker-state)))
      (refuse)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
      (pool-dispatch-check dispatcher
                           (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)
                           :claimed 0 :unchanged)
      (refuse)
      (let* ((link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher))
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
        (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token))))
      (pool-recycle-check dispatcher nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-dispatch-finish
       (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)
      ;; FI diagnostica quiescente: FAULTED conserva esattamente la prima causa.
      (let ((original (make-condition 'invariant-violation :reason :worker-state)))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (refuse)
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-recycle-existing-obligation-ignores-inactive-and-corrupt-words
  (dolist (scenario '(:inactive :corrupt :retire))
    (with-pool-dispatch (dispatcher port context ready table writers controllers
                                   :active (not (eq scenario :inactive)))
      (declare (ignorable controllers))
      (pool-recycle-reschedule dispatcher context ready writers 0)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
      ;; FI coordinator quiescente; il ricircolo non deve leggere queste parole.
      (case scenario
        (:corrupt (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
                        (arcdocdb.scheduler::porta-worker-pool-ack port) 0))
        (:retire (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)))
      (let ((words (lifecycle-words port)))
        (pool-recycle-without-gate
         (lambda ()
           (pool-recycle-check
            dispatcher (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 1)
            :claimed 1)))
        (is (equal words (lifecycle-words port)))
        (pool-dispatch-finish
         (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :b1 :idle)
        (is (equal words (lifecycle-words port))))
      (when (eq scenario :retire)
        (pool-dispatch-check dispatcher nil :inactive 0 :retired)
        (is (equal '(2 2 nil) (lifecycle-words port))))
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-dispatch-finish
       (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-recycle-room-does-not-acknowledge-pending-retire
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable table controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (pool-recycle-without-gate (lambda () (pool-recycle-check dispatcher nil :published 1)))
    (is (equal '(2 1 nil) (lifecycle-words port)))
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
    (pool-dispatch-check dispatcher nil :inactive 0 :retired)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-recycle-binding-refuses-before-transfer
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (let* ((other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                       other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                       (arcdocdb.execution.series::tabella-worker-serie-links table)))
           (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
      (pool-claim-function-fi
       'arcdocdb.execution:ricircola-worker
       (lambda (worker) (declare (ignore worker)) (error "Trasferimento dopo binding errato."))
       (lambda () (pool-recycle-refusal bad port table writers
                                         'invalid-argument :pool-dispatcher-binding)))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer other))))
    (pool-recycle-check dispatcher nil :published 1)
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (pool-dispatch-finish
     (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-recycle-foreign-owner-precedes-binding-and-pool-data
  (let ((worker (lifecycle-fixture-start t)) (dispatcher nil) (table nil) (writers nil)
        (left-file nil) (right-file nil))
    (unwind-protect
         (progn
           (lifecycle-call
            worker
            (lambda (owned)
              (multiple-value-bind (left resource) (pool-claim-series 85)
                (setf left-file resource)
                (multiple-value-bind (right resource) (pool-claim-series 86)
                  (setf right-file resource writers (vector (pool-claim-writer '(:a1 :a2) 0)
                                                           (pool-claim-writer '(:b1) 1))
                        table (arcdocdb.execution.series:crea-tabella-worker-serie
                               (lifecycle-fixture-context owned)
                               (arcdocdb.execution.series:crea-registro-worker-serie
                                writers (vector left right)))
                        dispatcher (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                                    (lifecycle-fixture-port owned) table))))
              (pool-recycle-reschedule dispatcher (lifecycle-fixture-context owned)
                                       (pool-claim-ready (lifecycle-fixture-context owned)) writers 0)
              :ok))
           (let* ((port (lifecycle-fixture-port worker))
                  (ready (pool-claim-ready (lifecycle-fixture-context worker)))
                  (other (arcdocdb.execution:crea-contesto-worker-writer ready))
                  (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                              other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                              (arcdocdb.execution.series::tabella-worker-serie-links table)))
                  (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4)
             (pool-recycle-refusal bad port table writers 'invalid-argument :pool-worker-owner)
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 1))
           (lifecycle-call
            worker
            (lambda (owned)
              (let ((context (lifecycle-fixture-context owned)))
                (pool-recycle-check dispatcher nil :published 1)
                (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
                (pool-dispatch-finish
                 (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle)) :ok)))
      (when left-file
        (lifecycle-call worker (lambda (owned) (declare (ignore owned))
                                 (when right-file (arcdocdb.io:chiudi right-file))
                                 (arcdocdb.io:chiudi left-file) :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-recycle-routing-fault-keeps-completed-full-transfer
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :shards 3 :start 1)
    (pool-recycle-reschedule dispatcher context ready writers 2)
    (let* ((unknown (pool-claim-writer '(:unknown) 2))
           (series-before (map 'list #'pool-dispatch-series-image controllers))
           (left-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0)))
           (unknown-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown)))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 unknown)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
      (let ((condition
              (arcdocdb.execution.tests::worker-capture-condition
               (lambda () (arcdocdb.scheduler.dispatch:ricircola-collegamento-pool dispatcher))
               'invariant-violation :worker-serie-routing)))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq unknown (arcdocdb.execution:writer-worker-writer context)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (= 0 (arcdocdb.execution::contesto-worker-writer-cursor context)))
        (is (= 2 (arcdocdb.execution::contesto-worker-writer-home context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
        (is (equal '(2 1 nil) (lifecycle-words port)))
        (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
        (is (equalp left-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
        (is (equalp unknown-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown)))
        (pool-recycle-refusal dispatcher port table writers 'resource-exhausted :worker-state)
        (is (eq condition (arcdocdb.execution:errore-worker-writer context))))
      ;; Dopo il fault il vecchio A e gia nel ring: nessun rollback dello scambio.
      (multiple-value-bind (writer status next) (arcdocdb.execution:preleva-writer-pronto ready 2)
        (is (eq writer (svref writers 0))) (is (eq status :writer)) (is (zerop next))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-recycle-contradictory-output-refuses-before-routing-without-c3-fault
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable context ready controllers))
    ;; FI quiescente di contratto: combinazioni ammesse dai tipi ma incoerenti.
    (dolist (status '(:claimed :published))
      (pool-claim-function-fi
       'arcdocdb.execution:ricircola-worker
       (lambda (worker) (declare (ignore worker))
         (values (and (eq status :published) (svref writers 0)) status 1))
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution.series:collega-writer-worker-serie
          (lambda (routing) (declare (ignore routing)) (error "Routing di output contraddittorio."))
          (lambda ()
            (pool-recycle-refusal dispatcher port table writers
                                  'invariant-violation :pool-dispatcher-state))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-recycle-invalid-dispatcher-type-has-no-effects
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher context ready controllers))
    (let ((before (pool-dispatch-image port table writers)))
      (signals type-error
        (funcall (fdefinition 'arcdocdb.scheduler.dispatch:ricircola-collegamento-pool) :invalid))
      (is (equalp before (pool-dispatch-image port table writers))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-recycle-ready-invariant-preserves-original-c1-fault
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (let ((partition (arcdocdb.execution.tests::ready-test-partition ready 0)))
      ;; FI quiescente: indice fuori capienza ma dentro il tipo INDEX dello slot.
      ;; Il verificatore C1 sotto guard reale deve produrre la causa originale.
      (setf (arcdocdb.execution::partizione-pronta-head partition) 1)
      (let ((ring-before (arcdocdb.execution.tests::ready-fi-snapshot partition))
            (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0)))
            (series-before (map 'list #'pool-dispatch-series-image controllers))
            (links-before (map 'list #'pool-dispatch-link-image
                               (arcdocdb.execution.series::tabella-worker-serie-links table))))
        (let ((condition
                (arcdocdb.execution.tests::worker-capture-condition
                 (lambda () (arcdocdb.scheduler.dispatch:ricircola-collegamento-pool dispatcher))
                 'invariant-violation :ready-queue-invariant)))
          (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
          (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
          (is (eq (svref writers 0) (arcdocdb.execution:writer-worker-writer context)))
          (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
          (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
          (is (equal '(1 1 nil) (lifecycle-words port)))
          (is (equalp ring-before (arcdocdb.execution.tests::ready-fi-snapshot partition)))
          (is (equalp writer-before
                      (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
          (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
          (is (equalp links-before (map 'list #'pool-dispatch-link-image
                                       (arcdocdb.execution.series::tabella-worker-serie-links table))))
          (pool-recycle-refusal dispatcher port table writers 'resource-exhausted :worker-state)
          (is (eq condition (arcdocdb.execution:errore-worker-writer context))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-recycle-unknown-status-refuses-at-runtime-without-effects
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    ;; FI quiescente oltre la ftype C1: l'helper NOTINLINE accetta T e mantiene
    ;; il controllo runtime che il compilatore eliminava dal precedente CASE.
    ;; Nessun falso rifiuto di tipo viene scambiato per invariant di prodotto.
    (labels ((reject-status (status)
               (let ((calls 0))
                 (pool-claim-function-fi
                  'arcdocdb.execution:ricircola-worker
                  (lambda (worker) (declare (ignore worker))
                    (incf calls) (values nil status 1))
                  (lambda ()
                    (pool-claim-function-fi
                     'arcdocdb.execution.series:collega-writer-worker-serie
                     (lambda (routing) (declare (ignore routing))
                       (error "Routing dopo status sconosciuto."))
                     (lambda ()
                       (pool-recycle-without-gate
                        (lambda ()
                          (pool-recycle-refusal dispatcher port table writers
                                                'invariant-violation :pool-dispatcher-state)))))))
                 (is (= 1 calls)))))
      (dolist (status (list :unknown nil 0 "invalid" '(invalid) #()))
        (reject-status status))
      ;; FI diagnostica indipendente: nemmeno una causa gia presente e sostituita
      ;; da questo errore C3. Il delegato FI non esegue il confine C1 FAULTED.
      (let ((original (make-condition 'invariant-violation :reason :worker-state)))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (reject-status :unknown)
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))
