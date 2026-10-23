;;;; Claim ammesso dal pool soltanto alla barriera C1 IDLE, senza revoca di compiti.
;;;; OWNER: porta, contesto e bridge sul thread creatore; coordinator delle fixture distinto.
;;;; FI quiescenti: immagini, parole corrotte e sostituzioni temporanee sempre ripristinate.
;;;; Le fixture Serie usano il backend pubblico e non dipendono da tests/series.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-claim-check (port writer status cursor action)
  "Oracolo dei quattro valori pubblici; identita writer e cursore sono attesi dal caller."
  (is (equal (list writer status cursor action)
             (multiple-value-list (arcdocdb.scheduler:prendi-writer-pool port)))))

(defun pool-claim-ready (context)
  (arcdocdb.execution::contesto-worker-writer-ready context))

(defun pool-claim-image (port &optional writers)
  "Immagine FI bounded, solo per dimostrare l'assenza di mutazioni sui rifiuti."
  (let* ((context (arcdocdb.scheduler::porta-worker-pool-context port))
         (ready (pool-claim-ready context)))
    (list (lifecycle-words port) (lifecycle-context-state context)
          (map 'list #'arcdocdb.execution.tests::ready-fi-snapshot
               (arcdocdb.execution::lista-writer-pronti-partitions ready))
          (mapcar #'arcdocdb.execution.tests::handoff-fi-snapshot writers))))

(defun pool-claim-refusal (port type reason &optional writers)
  (let ((before (pool-claim-image port writers)))
    (arcdocdb.execution.tests::worker-capture-condition
     (lambda () (arcdocdb.scheduler:prendi-writer-pool port)) type reason)
    (is (equalp before (pool-claim-image port writers)))))

(defun pool-claim-local (&key (active t) (shards 1) (capacity 1) (start 0))
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti
                 :shards shards :capacity capacity))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready :start start)))
    (values (arcdocdb.scheduler:crea-porta-worker-pool context :active active) context ready)))

(defun pool-claim-writer (items &optional (ordinal 0))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile
                 :capacity 4 :quantum 1 :routing-index ordinal)))
    (loop for item in items for count from 1
          do (arcdocdb.execution.tests::handoff-check-enqueue
              writer item count (if (= count 1) :schedule :queued)))
    writer))

(defun pool-claim-function-fi (name replacement thunk)
  "FI quiescente: nessun worker esegue NAME durante la sostituzione della fixture."
  (let ((saved (fdefinition name)))
    (unwind-protect (progn (setf (fdefinition name) replacement) (funcall thunk))
      (setf (fdefinition name) saved))))

(defun pool-claim-series (id)
  "Controller reale su backend C4 in memoria; nessun I/O richiesto dai compiti della prova."
  (let* ((backend (arcdocdb.io:make-backend
                   (lambda (path mode) (declare (ignore path mode)) id)
                   (lambda (&rest arguments) (declare (ignore arguments))
                     (error "Lettura I/O inattesa nella fixture pool."))
                   (lambda (fd bytes start count) (declare (ignore fd bytes start)) count)
                   (lambda (fd) (declare (ignore fd)) 0)
                   (lambda (fd) (declare (ignore fd)) 0)
                   (lambda (fd) (declare (ignore fd)) 0)))
         (file (arcdocdb.io:crea-temporaneo "pool-claim-series.tmp" :backend backend))
         (log (arcdocdb.wal:crea-log-io file :segment id)))
    (values (arcdocdb.series:crea-controllore-serie
             (arcdocdb.csn:crea-registro-csn :capacity 4) log :capacity 2)
            file)))

(defun pool-claim-bridge-begin (link)
  (multiple-value-bind (token status reason) (arcdocdb.execution.series:inizia-worker-serie link)
    (is (plusp token)) (is (eq :active status)) (is (null reason)) token))

(defun pool-claim-bridge-pop (link token item)
  (let ((target (vector :left :untouched :right)))
    (multiple-value-bind (count status batch)
        (arcdocdb.execution.series:preleva-worker-serie link token target 1 2)
      (is (= 1 count)) (is (eq :messages status)) (is (plusp batch))
      (is (eq :left (svref target 0))) (is (eq item (svref target 1)))
      (is (eq :right (svref target 2))) batch)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-inactive-claim-keeps-real-ready-obligation-and-cursor
  (multiple-value-bind (port context ready) (pool-claim-local :active nil :shards 3 :start 2)
    (let ((writer (pool-claim-writer '(:kept))))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      (let ((before (pool-claim-image port (list writer))))
        ;; La sentinella FI distingue assenza di scansione da scansione senza pop.
        (pool-claim-function-fi
         'arcdocdb.execution::%prova-pronta
         (lambda (partition) (declare (ignore partition)) (error "Scansione di worker inattivo."))
         (lambda () (dotimes (attempt 2) (pool-claim-check port nil :inactive 2 :unchanged))))
        (is (equalp before (pool-claim-image port (list writer)))))
      (arcdocdb.execution.tests::worker-check-claim context writer :claimed 1)
      (arcdocdb.execution.tests::worker-complete-one context writer :kept))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-THR-001-pool-real-grow-acknowledges-before-taking-ready-writer
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (registry (arcdocdb.scheduler:crea-registro-pool
                    (crea-controllore-pool 1 :dwell 500) (lifecycle-ports workers)))
         (worker (second workers)) (writer nil))
    (unwind-protect
         (progn
           (lifecycle-call worker
                           (lambda (owned)
                             (setf writer (pool-claim-writer '(:activated)))
                             (is (= 1 (arcdocdb.execution:pubblica-writer-pronto
                                       (pool-claim-ready (lifecycle-fixture-context owned)) 0 writer)))
                             (pool-claim-check (lifecycle-fixture-port owned) nil :inactive 0 :unchanged)
                             :ok))
           (lifecycle-check-update registry 0 8 0 0 1 :hold 1 nil)
           (lifecycle-check-update registry 500 8 0 0 2 :grow 1 t)
           (lifecycle-call worker
                           (lambda (owned)
                             (pool-claim-check (lifecycle-fixture-port owned) writer :claimed 0 :activated)
                             (arcdocdb.execution.tests::worker-complete-one
                              (lifecycle-fixture-context owned) writer :activated) :ok))
           (is (equal '(2 2 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-THR-001-pool-real-shrink-retires-before-removing-ready-writer
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            (second workers)
            (lambda (owned)
              (let* ((port (lifecycle-fixture-port owned)) (context (lifecycle-fixture-context owned))
                     (ready (pool-claim-ready context)) (writer (pool-claim-writer '(:retained))))
                (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
                (let ((queue-before (arcdocdb.execution.tests::ready-fi-snapshot
                                     (arcdocdb.execution.tests::ready-test-partition ready 0)))
                      (context-before (lifecycle-context-state context))
                      (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot writer)))
                  (pool-claim-check port nil :inactive 0 :retired)
                  (is (equalp queue-before (arcdocdb.execution.tests::ready-fi-snapshot
                                            (arcdocdb.execution.tests::ready-test-partition ready 0))))
                  (is (equal context-before (lifecycle-context-state context)))
                  (is (equalp writer-before (arcdocdb.execution.tests::handoff-fi-snapshot writer))))
                (pool-claim-check port nil :inactive 0 :unchanged)
                ;; Cleanup C4: trasferisce esplicitamente l'obbligo rimasto nel ring.
                (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
                (arcdocdb.execution.tests::worker-complete-one context writer :retained)) :ok))
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-foreign-owner-rejection-precedes-phase-and-word-checks
  (let ((worker (lifecycle-fixture-start nil)))
    (unwind-protect
         (let* ((port (lifecycle-fixture-port worker)) (context (lifecycle-fixture-context worker)))
           ;; FI quiescente dopo il ritorno della barriera: entrambi i livelli invalidi.
           (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
                 (arcdocdb.execution::contesto-worker-writer-state context) :faulted)
           (pool-claim-refusal port 'invalid-argument :pool-worker-owner))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-pool-every-nonidle-phase-refuses-before-inactive-or-debt-validation
  (multiple-value-bind (port context ready) (pool-claim-local :active nil)
    (declare (ignore ready))
    (let ((writer (pool-claim-writer '(:obligation)))
          (original (make-condition 'invariant-violation :reason :worker-state)))
      ;; FI quiescente: debiti e fault deliberatamente incompatibili con alcune fasi.
      ;; Il gate fuori IDLE deve conservarli, senza validazione, ACK o poisoning C1.
      (setf (arcdocdb.execution::contesto-worker-writer-writer context) writer
            (arcdocdb.execution::contesto-worker-writer-lease context) 7
            (arcdocdb.execution::contesto-worker-writer-pending context) 2
            (arcdocdb.execution::contesto-worker-writer-batch-generation context) 9
            (arcdocdb.execution::contesto-worker-writer-fault context) original)
      (dolist (phase '(:claimed :running :batch :finishing :reschedule :faulted))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) phase)
        (pool-claim-refusal port 'resource-exhausted :worker-state (list writer))
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-idle-inconsistency-refuses-retirement-ack-and-c1-poisoning
  (multiple-value-bind (port context ready) (pool-claim-local)
    (declare (ignore ready))
    (let ((writer (pool-claim-writer '(:kept))))
      ;; FI: un singolo campo IDLE corrotto, anche con porta senza comando pendente.
      (dolist (pair '((1 1) (0 0) (2 1) (3 0)))
        (setf (arcdocdb.scheduler::porta-worker-pool-request port) (first pair)
              (arcdocdb.scheduler::porta-worker-pool-ack port) (second pair))
        (dolist (slot '(arcdocdb.execution::cursor arcdocdb.execution::home
                        arcdocdb.execution::writer arcdocdb.execution::lease
                        arcdocdb.execution::pending arcdocdb.execution::fault))
          (let ((saved (slot-value context slot))
                (bad (case slot
                       (arcdocdb.execution::writer writer)
                       (arcdocdb.execution::fault
                        (make-condition 'invariant-violation :reason :worker-state))
                       (otherwise 1))))
            (unwind-protect
                 (progn (setf (slot-value context slot) bad)
                        (pool-claim-refusal port 'invariant-violation :worker-state (list writer)))
              (setf (slot-value context slot) saved)))))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2
            (arcdocdb.scheduler::porta-worker-pool-ack port) 1)
      (pool-claim-check port nil :inactive 0 :retired)
      (is (null (arcdocdb.execution:errore-worker-writer context))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-corrupt-word-protocol-preserves-ready-and-local-worker
  (multiple-value-bind (port context ready) (pool-claim-local)
    (let ((writer (pool-claim-writer '(:kept))))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      (dolist (pair '((2 0) (4 0) (0 2) (1 0) (0 1)))
        ;; FI quiescente: malformazione del canale fuori dal handler C1.
        (setf (arcdocdb.scheduler::porta-worker-pool-request port) (first pair)
              (arcdocdb.scheduler::porta-worker-pool-ack port) (second pair))
        (pool-claim-refusal port 'invariant-violation :pool-port-state (list writer))
        (is (null (arcdocdb.execution:errore-worker-writer context))))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 1
            (arcdocdb.scheduler::porta-worker-pool-ack port) 1)
      (pool-claim-check port writer :claimed 0 :unchanged)
      (arcdocdb.execution.tests::worker-complete-one context writer :kept))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-retirement-ack-cas-conflict-cannot-take-a-ready-writer
  (multiple-value-bind (port context ready) (pool-claim-local)
    (let* ((writer (pool-claim-writer '(:kept)))
           (saved (fdefinition 'arcdocdb.scheduler::%pool-ack-command)) (calls 0))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
      ;; FI quiescente: invochiamo il vero CAS con OLD errato, senza mutare ACK.
      (pool-claim-function-fi
       'arcdocdb.scheduler::%pool-ack-command
       (lambda (value old word) (incf calls) (funcall saved value (+ old 2) word))
       (lambda () (pool-claim-refusal port 'invariant-violation :pool-port-state (list writer))))
      (is (= 1 calls)) (is (null (arcdocdb.execution:errore-worker-writer context)))
      (pool-claim-check port nil :inactive 0 :retired)
      (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
      (arcdocdb.execution.tests::worker-complete-one context writer :kept))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-active-empty-and-busy-preserve-c1-cursor-rotation
  (multiple-value-bind (port context ready) (pool-claim-local :shards 3 :start 1)
    (pool-claim-check port nil :empty 2 :unchanged)
    (let* ((writer (pool-claim-writer '(:busy-kept)))
           (partition (arcdocdb.execution.tests::ready-test-partition ready 2)))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 2 writer)))
      (arcdocdb.execution.tests::ready-call-with-guards
       (list partition) (lambda () (pool-claim-check port nil :busy 0 :unchanged)))
      (pool-claim-check port writer :claimed 0 :unchanged)
      (arcdocdb.execution.tests::worker-complete-one context writer :busy-kept)
      (pool-claim-check port nil :empty 1 :unchanged))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-THR-001-pool-retire-after-active-sample-permits-one-last-complete-task
  (multiple-value-bind (port context ready) (pool-claim-local)
    (let* ((writer (pool-claim-writer '(:last)))
           (saved (fdefinition 'arcdocdb.scheduler:applica-stato-worker-pool)) (calls 0))
      (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)))
      ;; FI quiescente al confine: pubblicazione dopo la lettura attiva, prima del pop.
      ;; Lo stesso ordinamento puo avvenire dal vero coordinator concorrente.
      (pool-claim-function-fi
       'arcdocdb.scheduler:applica-stato-worker-pool
       (lambda (value)
         (multiple-value-bind (active action) (funcall saved value)
           (incf calls) (is active) (is (eq :unchanged action))
           (setf (arcdocdb.scheduler::porta-worker-pool-request value) 2)
           (values active action)))
       (lambda () (pool-claim-check port writer :claimed 0 :unchanged)))
      (is (= 1 calls)) (is (equal '(2 1 nil) (lifecycle-words port)))
      (pool-claim-refusal port 'resource-exhausted :worker-state (list writer))
      (arcdocdb.execution.tests::worker-complete-one context writer :last)
      (pool-claim-check port nil :inactive 0 :retired)
      (is (equal '(2 2 nil) (lifecycle-words port))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-pending-retire-waits-for-bridge-batch-and-explicit-handoff
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers)))
         (worker (second workers)) (file nil) (writer nil) (link nil) (token nil) (batch nil))
    (unwind-protect
         (progn
           (lifecycle-call
            worker (lambda (owned)
                     (multiple-value-bind (serie resource) (pool-claim-series 71)
                       (setf file resource writer (pool-claim-writer '(:first :second)))
                       (let ((context (lifecycle-fixture-context owned)))
                         (is (= 1 (arcdocdb.execution:pubblica-writer-pronto
                                   (pool-claim-ready context) 0 writer)))
                         (pool-claim-check (lifecycle-fixture-port owned) writer :claimed 0 :unchanged)
                         (setf link (arcdocdb.execution.series:crea-collegamento-worker-serie
                                     context writer serie)
                               token (pool-claim-bridge-begin link)
                               batch (pool-claim-bridge-pop link token :first)))) :ok))
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            worker (lambda (owned)
                     (let ((port (lifecycle-fixture-port owned))
                           (context (lifecycle-fixture-context owned)))
                       (pool-claim-refusal port 'resource-exhausted :worker-state (list writer))
                       (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch)))
                       (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
                       (pool-claim-refusal port 'resource-exhausted :worker-state (list writer))
                       (multiple-value-bind (obligation home) (arcdocdb.execution:cede-writer-worker context)
                         (is (eq writer obligation)) (is (= 0 home))
                         (is (= 1 (arcdocdb.execution:pubblica-writer-pronto
                                   (pool-claim-ready context) home obligation))))
                       (pool-claim-check port nil :inactive 0 :retired)
                       ;; Un altro claim C4 completa l'obbligo esplicitamente trasferito.
                       (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
                       (arcdocdb.execution.tests::worker-complete-one context writer :second)) :ok))
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (when file (lifecycle-call worker (lambda (owned) (declare (ignore owned))
                                         (arcdocdb.io:chiudi file) :ok)))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-full-recycle-keeps-claimed-and-routes-new-writer-before-retire
  (multiple-value-bind (port context ready) (pool-claim-local)
    (multiple-value-bind (left left-file) (pool-claim-series 72)
      (multiple-value-bind (right right-file) (pool-claim-series 73)
        (unwind-protect
             (let* ((a (pool-claim-writer '(:a1 :a2) 0)) (b (pool-claim-writer '(:b) 1))
                    (registry (arcdocdb.execution.series:crea-registro-worker-serie
                               (vector a b) (vector left right)))
                    (table (arcdocdb.execution.series:crea-tabella-worker-serie context registry)))
               (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 a)))
               (pool-claim-check port a :claimed 0 :unchanged)
               (let* ((first-link (arcdocdb.execution.series:collega-writer-worker-serie table))
                      (token (pool-claim-bridge-begin first-link)))
                 (is (null (arcdocdb.execution.series:conferma-worker-serie
                            first-link token (pool-claim-bridge-pop first-link token :a1))))
                 (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie first-link token)))
                 (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 b)))
                 ;; FI quiescente: comando arriva durante l'obbligo RESCHEDULE.
                 (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)
                 (arcdocdb.execution.tests::worker-check-recycle context b :claimed 1)
                 (pool-claim-refusal port 'resource-exhausted :worker-state (list a b))
                 (let* ((next-link (arcdocdb.execution.series:collega-writer-worker-serie table))
                        (next-token (pool-claim-bridge-begin next-link)))
                   (is (not (eq first-link next-link)))
                   ;; B possiede soltanto la seconda Serie; la prima resta acquisibile.
                   (let ((lease (arcdocdb.series:acquisisci-controllore-serie left)))
                     (is (plusp lease)) (arcdocdb.series:rilascia-controllore-serie left lease))
                   (signals resource-exhausted (arcdocdb.series:acquisisci-controllore-serie right) :serie-busy)
                   (is (null (arcdocdb.execution.series:conferma-worker-serie
                              next-link next-token (pool-claim-bridge-pop next-link next-token :b))))
                   (is (eq :idle (arcdocdb.execution.series:termina-worker-serie next-link next-token))))
                 (pool-claim-check port nil :inactive 0 :retired)
                 (arcdocdb.execution.tests::worker-check-claim context a :claimed 0)
                 (arcdocdb.execution.tests::worker-complete-one context a :a2)))
          (arcdocdb.io:chiudi right-file) (arcdocdb.io:chiudi left-file))))))
