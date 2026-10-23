;;;; Dispatch pool -> routing preallocato; begin, batch e handoff restano espliciti.
;;;; OWNER: porta, contesto, tabella e link sul thread creatore della fixture.
;;;; SHARED: solo ready/registro immutabile e parole pool nei passaggi reali.
;;;; FI quiescenti: immagini bounded, sentinelle ripristinate e binding corrotti dichiarati.
(in-package #:arcdocdb.scheduler.tests)

(defmacro with-pool-dispatch ((dispatcher port context ready table writers controllers
                              &key (active t) (shards 1) (capacity 1) (start 0)
                                (left-items ''(:a1 :a2)) (right-items ''(:b1)))
                             &body body)
  "Fixture C4 locale, con due routing ordinal distinti e risorse sempre chiuse."
  (let ((left (gensym "LEFT")) (right (gensym "RIGHT"))
        (left-file (gensym "LEFT-FILE")) (right-file (gensym "RIGHT-FILE")))
    `(multiple-value-bind (,port ,context ,ready)
         (pool-claim-local :active ,active :shards ,shards :capacity ,capacity :start ,start)
       (multiple-value-bind (,left ,left-file) (pool-claim-series 81)
         (multiple-value-bind (,right ,right-file) (pool-claim-series 82)
           (unwind-protect
                (let* ((,port ,port) (,context ,context) (,ready ,ready)
                       (,writers (vector (pool-claim-writer ,left-items 0)
                                        (pool-claim-writer ,right-items 1)))
                       (,controllers (vector ,left ,right))
                       (,table (arcdocdb.execution.series:crea-tabella-worker-serie
                                ,context (arcdocdb.execution.series:crea-registro-worker-serie
                                          ,writers ,controllers)))
                       (,dispatcher (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                                     ,port ,table)))
                  ,@body)
             (arcdocdb.io:chiudi ,right-file) (arcdocdb.io:chiudi ,left-file)))))))

(defun pool-dispatch-series-image (controller)
  "FI: tutti i campi mutabili del controller e dei due slot preallocati della fixture."
  (list
   (mapcar (lambda (slot) (slot-value controller slot))
           '(arcdocdb.series::root arcdocdb.series::planned-root arcdocdb.series::next-offset
             arcdocdb.series::owner arcdocdb.series::lease-generation
             arcdocdb.series::event-generation arcdocdb.series::last-high
             arcdocdb.series::last-low arcdocdb.series::head arcdocdb.series::tail
             arcdocdb.series::publish-head arcdocdb.series::count arcdocdb.series::unresolved
             arcdocdb.series::active-io arcdocdb.series::state arcdocdb.series::effect-active))
   (map 'list
        (lambda (commit)
          (mapcar (lambda (slot) (slot-value commit slot))
                  '(arcdocdb.series::generation arcdocdb.series::lotto arcdocdb.series::slot
                    arcdocdb.series::high arcdocdb.series::low arcdocdb.series::expected-root
                    arcdocdb.series::root arcdocdb.series::level arcdocdb.series::phase
                    arcdocdb.series::io-state)))
        (arcdocdb.series::controllore-serie-slots controller))))

(defun pool-dispatch-link-image (link)
  (if (typep link 'arcdocdb.execution.series:collegamento-worker-serie)
      (mapcar (lambda (slot) (slot-value link slot))
              '(arcdocdb.execution.series::context arcdocdb.execution.series::writer
                arcdocdb.execution.series::controller arcdocdb.execution.series::generation
                arcdocdb.execution.series::writer-lease arcdocdb.execution.series::series-lease
                arcdocdb.execution.series::state arcdocdb.execution.series::fault))
      link))

(defun pool-dispatch-image (port table writers)
  "Preimage bounded: entrambe le associazioni, ready, debiti, link e controller."
  (list (pool-claim-image port (coerce writers 'list))
        (lifecycle-context-state (arcdocdb.execution.series::tabella-worker-serie-context table))
        (map 'list #'pool-dispatch-link-image
             (arcdocdb.execution.series::tabella-worker-serie-links table))
        (map 'list #'pool-dispatch-series-image
             (arcdocdb.execution.series::registro-worker-serie-controllers
              (arcdocdb.execution.series::tabella-worker-serie-registry table)))))

(defun pool-dispatch-refusal (port table writers thunk type reason)
  (let ((before (pool-dispatch-image port table writers)))
    (arcdocdb.execution.tests::worker-capture-condition thunk type reason)
    (is (equalp before (pool-dispatch-image port table writers)))))

(defun pool-dispatch-check (dispatcher link status cursor action)
  (is (equal (list link status cursor action)
             (multiple-value-list
              (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher)))))

(defun pool-dispatch-finish (link item action)
  "Tratto reale: begin esplicito, un batch pubblicato/ACK e terminazione esplicita."
  (let ((token (pool-claim-bridge-begin link)))
    (is (null (arcdocdb.execution.series:conferma-worker-serie
               link token (pool-claim-bridge-pop link token item))))
    (is (eq action (arcdocdb.execution.series:termina-worker-serie link token)))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-dispatch-factory-type-and-context-binding-refuse-without-effects
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher))
    (dolist (invalid (list nil :invalid #() '(port)))
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool invalid table))
       'invalid-argument :pool-dispatcher-configuration)
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port invalid))
       'invalid-argument :pool-dispatcher-configuration))
    (let* ((other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (registry (arcdocdb.execution.series:crea-registro-worker-serie writers controllers))
           (other-table (arcdocdb.execution.series:crea-tabella-worker-serie other registry))
           (before (lifecycle-context-state other)))
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port other-table))
       'invalid-argument :pool-dispatcher-binding)
      (is (equal before (lifecycle-context-state other))))
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-dispatch-factory-requires-complete-idle-before-construction
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher ready controllers))
    (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
    (pool-dispatch-refusal
     port table writers
     (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port table))
     'resource-exhausted :worker-state)
    (multiple-value-bind (writer home) (arcdocdb.execution:cede-writer-worker context)
      (is (eq writer (svref writers 0))) (is (= 0 home)))
    ;; FI IDLE incoerente: getter di fase valido, debito non vuoto da rifiutare.
    (setf (arcdocdb.execution::contesto-worker-writer-pending context) 1)
    (pool-dispatch-refusal
     port table writers
     (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port table))
     'invariant-violation :worker-state)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-dispatch-foreign-owner-precedes-table-phase-and-pool-checks
  (let ((worker (lifecycle-fixture-start t)) (dispatcher nil) (table nil) (writers nil)
        (left-file nil) (right-file nil))
    (unwind-protect
         (progn
           (lifecycle-call
            worker
            (lambda (owned)
              (multiple-value-bind (left resource) (pool-claim-series 83)
                (setf left-file resource)
                (multiple-value-bind (right resource) (pool-claim-series 84)
                  (setf right-file resource writers (vector (pool-claim-writer '(:kept) 0)
                                                           (pool-claim-writer '(:other) 1)))
                  (setf table (arcdocdb.execution.series:crea-tabella-worker-serie
                               (lifecycle-fixture-context owned)
                               (arcdocdb.execution.series:crea-registro-worker-serie
                                writers (vector left right)))
                        dispatcher (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                                    (lifecycle-fixture-port owned) table)))) :ok))
           (let ((port (lifecycle-fixture-port worker))
                 (context (lifecycle-fixture-context worker)))
             ;; FI quiescente: l'owner deve precedere tipo table e ogni dato corrotto.
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
                   (arcdocdb.execution::contesto-worker-writer-state context) :faulted)
             (pool-dispatch-refusal
              port table writers
              (lambda () (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port :invalid))
              'invalid-argument :pool-worker-owner)
             (dolist (api '(arcdocdb.scheduler.dispatch:prendi-collegamento-pool
                            arcdocdb.scheduler.dispatch:collega-obbligo-pool))
               (pool-dispatch-refusal port table writers (lambda () (funcall api dispatcher))
                                      'invalid-argument :pool-worker-owner))))
      (when left-file
        (lifecycle-call worker (lambda (owned) (declare (ignore owned))
                                 (when right-file (arcdocdb.io:chiudi right-file))
                                 (arcdocdb.io:chiudi left-file) :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-dispatch-inactive-empty-busy-never-enter-routing
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :active nil :shards 3 :start 1 :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 0))))
    (let ((before (pool-dispatch-image port table writers)))
      (pool-claim-function-fi
       'arcdocdb.execution.series:collega-writer-worker-serie
       (lambda (value) (declare (ignore value)) (error "Routing di worker inattivo."))
       (lambda () (pool-dispatch-check dispatcher nil :inactive 1 :unchanged)))
      (is (equalp before (pool-dispatch-image port table writers))))
    ;; Cleanup esplicito dell'obbligo: il gate inattivo lo ha lasciato nel ring.
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    (arcdocdb.execution.tests::worker-complete-one context (svref writers 0) :a1))
  (with-pool-dispatch (dispatcher port context ready table writers controllers :shards 3 :start 1)
    (declare (ignorable table controllers))
    (pool-claim-function-fi
     'arcdocdb.execution.series:collega-writer-worker-serie
     (lambda (value) (declare (ignore value)) (error "Routing senza writer acquisito."))
     (lambda ()
       (pool-dispatch-check dispatcher nil :empty 2 :unchanged)
       (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 (svref writers 1))))
       (arcdocdb.execution.tests::ready-call-with-guards
        (list (arcdocdb.execution.tests::ready-test-partition ready 2))
        (lambda () (pool-dispatch-check dispatcher nil :busy 0 :unchanged)))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 1) :claimed 0)
    (arcdocdb.execution.tests::worker-complete-one context (svref writers 1) :b1)
    (is (equal '(1 1 nil) (lifecycle-words port)))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-dispatch-routes-two-real-writers-without-implicit-begin
  (with-pool-dispatch (dispatcher port context ready table writers controllers
                                 :capacity 2 :left-items '(:a1))
    (declare (ignorable port))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
    (is (= 2 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((links (arcdocdb.execution.series::tabella-worker-serie-links table)))
      (loop for ordinal in '(1 0) for item in '(:b1 :a1)
            do (let ((link (svref links ordinal))
                     (series-before (map 'list #'pool-dispatch-series-image controllers)))
                 (pool-dispatch-check dispatcher link :claimed 0 :unchanged)
                 (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
                 (is (eq (svref writers ordinal) (arcdocdb.execution:writer-worker-writer context)))
                 (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
                 (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
                 ;; Un controller e ancora acquisibile: routing non possiede lease.
                 (let* ((controller (svref controllers ordinal))
                        (lease (arcdocdb.series:acquisisci-controllore-serie controller)))
                   (is (plusp lease)) (arcdocdb.series:rilascia-controllore-serie controller lease))
                 (pool-dispatch-finish link item :idle)))
      (pool-dispatch-check dispatcher nil :empty 0 :unchanged))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-dispatch-existing-claimed-routes-without-reading-corrupt-pool-words
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-dispatch-check dispatcher link :claimed 0 :unchanged)
      ;; FI in modo quiescente: collegare un obbligo non legge il canale lifecycle.
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
            (arcdocdb.scheduler::porta-worker-pool-ack port) 0)
      (let ((before (pool-dispatch-image port table writers)))
        (pool-claim-function-fi
         'arcdocdb.scheduler:prendi-writer-pool
         (lambda (value) (declare (ignore value)) (error "Gate su un obbligo CLAIMED."))
         (lambda ()
           (dotimes (attempt 2)
             (is (eq link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher))))))
        (is (equalp before (pool-dispatch-image port table writers))))
      (pool-dispatch-finish link :a1 :idle)
      (is (eq :idle (arcdocdb.execution:stato-worker-writer context))))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-dispatch-pending-retire-drains-existing-claimed-before-ack
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
    ;; FI: pubblicazione del coordinator prima della ripresa dell'obbligo CLAIMED.
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (is (eq link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher)))
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
       'resource-exhausted :worker-state)
      (pool-dispatch-finish link :a1 :idle)
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (pool-dispatch-check dispatcher nil :inactive 0 :retired)
      (is (equal '(2 2 nil) (lifecycle-words port))))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-dispatch-full-recycle-routes-new-claimed-while-retire-pending
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let* ((links (arcdocdb.execution.series::tabella-worker-serie-links table))
           (left-link (svref links 0)) (right-link (svref links 1)))
      (pool-dispatch-check dispatcher left-link :claimed 0 :unchanged)
      (pool-dispatch-finish left-link :a1 :schedule)
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
      (arcdocdb.execution.tests::worker-check-recycle context (svref writers 1) :claimed 1)
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
       'resource-exhausted :worker-state)
      (is (eq right-link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher)))
      (is (not (eq left-link right-link)))
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (let ((token (pool-claim-bridge-begin right-link))
            (lease (arcdocdb.series:acquisisci-controllore-serie (svref controllers 0))))
        (is (plusp lease))
        (arcdocdb.series:rilascia-controllore-serie (svref controllers 0) lease)
        (signals resource-exhausted
          (arcdocdb.series:acquisisci-controllore-serie (svref controllers 1)) :serie-busy)
        (is (null (arcdocdb.execution.series:conferma-worker-serie
                   right-link token (pool-claim-bridge-pop right-link token :b1))))
        (is (eq :idle (arcdocdb.execution.series:termina-worker-serie right-link token))))
      (pool-dispatch-check dispatcher nil :inactive 0 :retired)
      ;; A e ancora nel ring; viene completato con acquisizione C4 esplicita.
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-dispatch-finish
       (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle))))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-dispatch-all-disallowed-phases-preserve-first-fault-and-debts
  (with-pool-dispatch (dispatcher port context ready table writers controllers :active nil)
    (declare (ignorable ready controllers))
    (let ((original (make-condition 'invariant-violation :reason :worker-state)))
      ;; FI quiescente: il nuovo claim rifiuta prima dei debiti di ogni fase non IDLE.
      (setf (arcdocdb.execution::contesto-worker-writer-writer context) (svref writers 0)
            (arcdocdb.execution::contesto-worker-writer-lease context) 7
            (arcdocdb.execution::contesto-worker-writer-pending context) 2
            (arcdocdb.execution::contesto-worker-writer-batch-generation context) 9
            (arcdocdb.execution::contesto-worker-writer-fault context) original)
      (dolist (phase '(:claimed :running :batch :finishing :reschedule :faulted))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) phase)
        (pool-dispatch-refusal
         port table writers
         (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
         'resource-exhausted :worker-state))
      (is (eq original (arcdocdb.execution:errore-worker-writer context)))
      ;; Il routing delegato verifica i debiti C1 prima della fase: le immagini
      ;; successive sono coerenti e prodotte da begin/batch/end reali della fixture.
      (setf (arcdocdb.execution::contesto-worker-writer-state context) :idle
            (arcdocdb.execution::contesto-worker-writer-writer context) nil
            (arcdocdb.execution::contesto-worker-writer-lease context) 0
            (arcdocdb.execution::contesto-worker-writer-pending context) 0
            (arcdocdb.execution::contesto-worker-writer-fault context) nil)
      (flet ((refuse-obligation ()
               (pool-dispatch-refusal
                port table writers
                (lambda () (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher))
                'resource-exhausted :worker-state)))
        (refuse-obligation)
        (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
        (let* ((link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher))
               (token (pool-claim-bridge-begin link)))
          (refuse-obligation)
          (let ((batch (pool-claim-bridge-pop link token :a1)))
            (refuse-obligation)
            (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch))))
          (lifecycle-queue-busy
           (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
           (lambda ()
             (signals resource-exhausted
               (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
             (is (eq :finishing (arcdocdb.execution:stato-worker-writer context)))
             (refuse-obligation)))
          (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
          (refuse-obligation))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (refuse-obligation))
      (is (eq original (arcdocdb.execution:errore-worker-writer context)))
      (dolist (api '(arcdocdb.scheduler.dispatch:prendi-collegamento-pool
                     arcdocdb.scheduler.dispatch:collega-obbligo-pool))
        (let ((before (pool-dispatch-image port table writers)))
          (signals type-error (funcall api :invalid))
          (is (equalp before (pool-dispatch-image port table writers))))))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-dispatch-routing-fault-retains-activation-ack-and-acquired-obligation
  (dolist (scenario '(:legacy :different-identity :out-of-range))
    (with-pool-dispatch (dispatcher port context ready table writers controllers
                                   :active nil :shards 2 :start 1)
      (declare (ignorable table))
      (let* ((claimed (ecase scenario
                        (:legacy (arcdocdb.execution.tests::worker-test-writer '(:legacy)))
                        (:different-identity (pool-claim-writer '(:other) 0))
                        (:out-of-range (pool-claim-writer '(:range) 2))))
             (controller-before (map 'list #'pool-dispatch-series-image controllers))
             (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot claimed)))
        (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 1 claimed)))
        ;; FI coordinator quiescente: vera transizione inattivo -> attivo con ACK.
        (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
        (let ((condition
                (arcdocdb.execution.tests::worker-capture-condition
                 (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
                 'invariant-violation :worker-serie-routing)))
          (is (equal '(3 3 nil) (lifecycle-words port)))
          (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
          (is (eq claimed (arcdocdb.execution:writer-worker-writer context)))
          (is (= 1 (arcdocdb.execution::contesto-worker-writer-home context)))
          (is (= 0 (arcdocdb.execution::contesto-worker-writer-cursor context)))
          (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
          (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
          (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
          (is (equalp controller-before (map 'list #'pool-dispatch-series-image controllers)))
          (is (equalp writer-before (arcdocdb.execution.tests::handoff-fi-snapshot claimed)))
          (let ((before (lifecycle-context-state context)))
            (dolist (api '(arcdocdb.scheduler.dispatch:prendi-collegamento-pool
                           arcdocdb.scheduler.dispatch:collega-obbligo-pool))
              (arcdocdb.execution.tests::worker-capture-condition
               (lambda () (funcall api dispatcher)) 'resource-exhausted :worker-state)
              (is (equal before (lifecycle-context-state context)))
              (is (eq condition (arcdocdb.execution:errore-worker-writer context))))))
        (is (every (lambda (writer) (not (eq claimed writer))) writers))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-dispatch-corrupt-table-binding-refuses-before-claim-or-routing
  (with-pool-dispatch (dispatcher port context ready table writers controllers :active nil)
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    ;; FI coordinator: l'attivazione reale resterebbe applicabile a un gate valido.
    ;; Il binding incoerente deve rifiutare prima di confermare questo comando.
    (setf (arcdocdb.scheduler::porta-worker-pool-request port) 3)
    ;; FI bypass prive: dispatcher lega deliberatamente la tabella a contesto diverso.
    ;; Lo slot e immutabile nel prodotto; una nuova struct FI sostituisce il binding.
    (let* ((other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                       other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                       (arcdocdb.execution.series::tabella-worker-serie-links table)))
           (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool bad))
       'invalid-argument :pool-dispatcher-binding)
      (is (equal '(3 0 nil) (lifecycle-words port)))
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-dispatch-refusal
       port table writers
       (lambda () (arcdocdb.scheduler.dispatch:collega-obbligo-pool bad))
       'invalid-argument :pool-dispatcher-binding)
      (is (equal '(3 0 nil) (lifecycle-words port)))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer other)))
      (pool-dispatch-finish
       (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a1 :schedule)
      (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-dispatch-finish
       (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher) :a2 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-dispatch-corrupt-link-faults-after-claim-without-begin-or-rollback
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let* ((links (arcdocdb.execution.series::tabella-worker-serie-links table))
           (controller-before (map 'list #'pool-dispatch-series-image controllers))
           (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
      ;; FI quiescente dopo factory: nessuno dei link viene ricostruito nel path caldo.
      (setf (svref links 0) nil)
      (let ((condition
              (arcdocdb.execution.tests::worker-capture-condition
               (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
               'invariant-violation :worker-serie-routing)))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq (svref writers 0) (arcdocdb.execution:writer-worker-writer context)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (equal '(1 1 nil) (lifecycle-words port)))
        (is (equalp controller-before (map 'list #'pool-dispatch-series-image controllers)))
        (is (equalp writer-before
                    (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
        ;; Il pop acquisito e conservato: la partizione non ripubblica il writer.
        (let ((ready-partition (arcdocdb.execution.tests::ready-test-partition ready 0)))
          (is (zerop (arcdocdb.execution::partizione-pronta-count ready-partition))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-dispatch-contradictory-gate-output-refuses-before-routing
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable context ready controllers))
    ;; FI di contratto, non una race reale: il gate restituisce combinazioni errate
    ;; dei quattro valori che rispettano ancora la sua firma di tipi.
    (dolist (scenario '(:claimed :empty :busy :inactive))
      (pool-claim-function-fi
       'arcdocdb.scheduler:prendi-writer-pool
       (lambda (value)
         (declare (ignore value))
         (values (unless (eq scenario :claimed) (svref writers 0)) scenario 0 :unchanged))
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution.series:collega-writer-worker-serie
          (lambda (value) (declare (ignore value)) (error "Routing di risultato incoerente."))
          (lambda ()
            (pool-dispatch-refusal
             port table writers
             (lambda () (arcdocdb.scheduler.dispatch:prendi-collegamento-pool dispatcher))
             'invariant-violation :pool-dispatcher-state))))))))

;;; REQ: REQ-THR-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-dispatch-writer-busy-begin-keeps-claimed-for-explicit-retry
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 0))))
    (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
      (pool-dispatch-check dispatcher link :claimed 0 :unchanged)
      ;; FI quiescente di contesa: prende la vera guard con CAS e la rilascia sempre.
      ;; Il ritiro pendente non revoca l'obbligo già CLAIMED quando begin è busy.
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
      (lifecycle-queue-busy
       (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
       (lambda ()
         (pool-dispatch-refusal
          port table writers
          (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
          'resource-exhausted :writer-queue-busy)))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (let ((before (pool-dispatch-image port table writers)))
        (pool-claim-function-fi
         'arcdocdb.scheduler:prendi-writer-pool
         (lambda (value) (declare (ignore value)) (error "Nuova presa dopo begin busy."))
         (lambda ()
           (dotimes (attempt 2)
             (is (eq link (arcdocdb.scheduler.dispatch:collega-obbligo-pool dispatcher))))))
        (is (equalp before (pool-dispatch-image port table writers))))
      ;; Il caller ripete begin soltanto dopo il ritorno al proprio confine C4.
      (pool-dispatch-finish link :a1 :idle)
      (is (equal '(2 1 nil) (lifecycle-words port)))
      (pool-dispatch-check dispatcher nil :inactive 0 :retired)
      (is (equal '(2 2 nil) (lifecycle-words port))))))
