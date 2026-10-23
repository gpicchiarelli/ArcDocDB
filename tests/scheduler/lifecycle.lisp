;;;; Lifecycle di worker reali distinti; i canali bloccanti appartengono alla fixture.
;;;; FI quiescenti dichiarate verificano atomicità dei rifiuti e campi conservati.
(in-package #:arcdocdb.scheduler.tests)

(defstruct (lifecycle-fixture (:constructor %make-lifecycle-fixture (active coordinator)))
  (active t :type boolean :read-only t)
  (coordinator sb-thread:*current-thread* :type sb-thread:thread :read-only t)
  (ready (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (work (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (done (sb-thread:make-semaphore) :type sb-thread:semaphore :read-only t)
  (thread nil :type (or null sb-thread:thread))
  (context nil :type (or null arcdocdb.execution:contesto-worker-writer))
  (port nil :type (or null arcdocdb.scheduler:porta-worker-pool))
  (command nil :type (or null function keyword))
  (result nil :type t))

(defun lifecycle-fixture-main (fixture)
  "Il thread crea e possiede context/porta; massimo 64 comandi con attese da 15s."
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (setf (lifecycle-fixture-context fixture) context
          (lifecycle-fixture-port fixture)
          (arcdocdb.scheduler:crea-porta-worker-pool
           context :coordinator (lifecycle-fixture-coordinator fixture)
           :active (lifecycle-fixture-active fixture)))
    (sb-thread:signal-semaphore (lifecycle-fixture-ready fixture))
    (loop repeat 64
          do (pool-wait (lifecycle-fixture-work fixture))
             (let ((command (lifecycle-fixture-command fixture)))
               (when (eq command :stop) (return-from lifecycle-fixture-main :ok))
               (setf (lifecycle-fixture-result fixture)
                     (handler-case (funcall command fixture) (error (condition) condition)))
               (sb-thread:signal-semaphore (lifecycle-fixture-done fixture)))
          finally (error "Budget dei comandi della fixture esaurito."))))

(defun lifecycle-fixture-start (active)
  (let ((fixture (%make-lifecycle-fixture active sb-thread:*current-thread*)))
    (setf (lifecycle-fixture-thread fixture)
          (pool-thread "pool-lifecycle-owner" (lambda () (lifecycle-fixture-main fixture))))
    (handler-case (pool-wait (lifecycle-fixture-ready fixture))
      (error (condition)
        (pool-stop-threads (list (lifecycle-fixture-thread fixture))) (error condition)))
    fixture))

(defun lifecycle-call (fixture command)
  (setf (lifecycle-fixture-command fixture) command)
  (sb-thread:signal-semaphore (lifecycle-fixture-work fixture))
  (pool-wait (lifecycle-fixture-done fixture))
  (let ((result (lifecycle-fixture-result fixture)))
    (when (typep result 'error) (error result))
    result))

(defun lifecycle-fixtures-stop (fixtures)
  (dolist (fixture fixtures)
    (let ((thread (lifecycle-fixture-thread fixture)))
      (when (sb-thread:thread-alive-p thread)
        (setf (lifecycle-fixture-command fixture) :stop)
        (sb-thread:signal-semaphore (lifecycle-fixture-work fixture)))
      (unwind-protect (pool-join thread) (pool-stop-threads (list thread)))))
  nil)

(defun lifecycle-ports (fixtures)
  (map 'simple-vector #'lifecycle-fixture-port fixtures))

(defun lifecycle-registry-state (registry)
  (multiple-value-list (arcdocdb.scheduler:leggi-registro-pool registry)))

(defun lifecycle-words (port)
  "FI/snapshot quiescente: parole e binding, senza derivare la politica attesa."
  (list (arcdocdb.scheduler::porta-worker-pool-request port)
        (arcdocdb.scheduler::porta-worker-pool-ack port)
        (arcdocdb.scheduler::porta-worker-pool-bound port)))

(defun lifecycle-check-worker (fixture active status)
  (lifecycle-call fixture
                  (lambda (owned)
                    (multiple-value-bind (actual action)
                        (arcdocdb.scheduler:applica-stato-worker-pool (lifecycle-fixture-port owned))
                      (is (eq active actual)) (is (eq status action)) :ok))))

(defun lifecycle-context-state (context)
  "Solo immagine FI dei debiti: non fornisce l'ordine atteso delle transizioni."
  (list (arcdocdb.execution::contesto-worker-writer-state context)
        (arcdocdb.execution::contesto-worker-writer-writer context)
        (arcdocdb.execution::contesto-worker-writer-lease context)
        (arcdocdb.execution::contesto-worker-writer-pending context)
        (arcdocdb.execution::contesto-worker-writer-batch-generation context)
        (arcdocdb.execution::contesto-worker-writer-cursor context)
        (arcdocdb.execution::contesto-worker-writer-home context)
        (arcdocdb.execution::contesto-worker-writer-fault context)))

(defun lifecycle-owned-busy (fixture phase &optional (status :busy))
  (let* ((context (lifecycle-fixture-context fixture)) (port (lifecycle-fixture-port fixture))
         (before (lifecycle-context-state context)) (words (lifecycle-words port)))
    (is (eq phase (arcdocdb.execution:stato-worker-writer context)))
    (multiple-value-bind (actual action) (arcdocdb.scheduler:applica-stato-worker-pool port)
      (is actual) (is (eq status action)))
    (is (equal before (lifecycle-context-state context)))
    (is (equal words (lifecycle-words port)))))

(defun lifecycle-owned-writer (fixture count)
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)))
    (dotimes (i count)
      (multiple-value-bind (size action) (arcdocdb.execution:accoda-lavoro-writer writer i)
        (is (= (1+ i) size)) (is (eq (if (zerop i) :schedule :queued) action))))
    (is (null (arcdocdb.execution:adotta-writer-worker
               (lifecycle-fixture-context fixture) writer 0)))
    writer))

(defun lifecycle-queue-busy (queue thunk)
  "FI di contesa quiescente: prende/rilascia la guardia con gli stessi CAS del writer."
  (let ((owner sb-thread:*current-thread*))
    (is (null (sb-ext:compare-and-swap (arcdocdb.execution::coda-writer-guard queue) nil owner)))
    (unwind-protect (funcall thunk)
      (is (eq owner (sb-ext:compare-and-swap
                     (arcdocdb.execution::coda-writer-guard queue) owner nil))))))

(defun lifecycle-check-update (registry tick queue cpu p99 target action actual pending)
  (multiple-value-bind (next status count outstanding)
      (arcdocdb.scheduler:aggiorna-registro-pool registry tick queue cpu p99)
    (is (= target next)) (is (eq status action))
    (is (= actual count)) (is (eq pending outstanding))))

(defun lifecycle-start-retirement (controller registry)
  (is (= 2 (first (pool-state controller))))
  (lifecycle-check-update registry 0 0 0 1200 2 :hold 2 nil)
  (lifecycle-check-update registry 500 0 0 1200 1 :shrink 2 t)
  (is (equal '(2 1 t) (lifecycle-registry-state registry))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-port-owner-and-registry-coordinator-are-distinct
  (let* ((worker (lifecycle-fixture-start t)) (port (lifecycle-fixture-port worker))
         (controller (crea-controllore-pool 1 :maximum 1))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (vector port))))
    (unwind-protect
         (progn
           (signals invalid-argument (arcdocdb.scheduler:applica-stato-worker-pool port)
                    :pool-worker-owner)
           (signals invalid-argument
             (arcdocdb.scheduler:crea-porta-worker-pool (lifecycle-fixture-context worker))
             :worker-owner)
           (lifecycle-call
            worker (lambda (owned)
                     (declare (ignore owned))
                     (signals invalid-argument (arcdocdb.scheduler:leggi-registro-pool registry)
                              :pool-owner)
                     (signals invalid-argument
                       (arcdocdb.scheduler:aggiorna-registro-pool registry 0 0 0 0) :pool-owner)
                     :ok))
           (is (equal '(1 1 nil) (lifecycle-registry-state registry)))
           (lifecycle-check-worker worker t :unchanged))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-THR-001-pool-activation-retirement-await-real-worker-acks
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (controller (crea-controllore-pool 1 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers)))
         (second (second workers)))
    (unwind-protect
         (progn
           (lifecycle-check-worker second nil :unchanged)
           (lifecycle-check-update registry 0 8 0 0 1 :hold 1 nil)
           (lifecycle-check-update registry 500 8 0 0 2 :grow 1 t)
           (is (equal '(1 2 t) (lifecycle-registry-state registry)))
           (let ((before (lifecycle-words (lifecycle-fixture-port second))))
             (lifecycle-check-update registry 1000 0 1000 10000 2 :pending 1 t)
             (is (equal before (lifecycle-words (lifecycle-fixture-port second)))))
           (lifecycle-check-worker second t :activated)
           (is (equal '(2 2 nil) (lifecycle-registry-state registry)))
           (lifecycle-check-update registry 1500 0 1000 10000 2 :hold 2 nil)
           (lifecycle-check-update registry 2000 0 1000 10000 1 :shrink 2 t)
           (lifecycle-check-update registry 2500 0 1000 10000 1 :pending 2 t)
           (lifecycle-check-worker second nil :retired)
           (lifecycle-check-worker second nil :unchanged)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry)))
           (lifecycle-check-worker (first workers) t :unchanged))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-registry-copies-caller-vector-and-binds-once
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (ports (lifecycle-ports workers)) (controller (crea-controllore-pool 1 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller ports)))
    (unwind-protect
         (progn
           (signals invalid-argument
             (arcdocdb.scheduler:crea-registro-pool controller ports) :pool-binding)
           (setf (svref ports 0) :changed (svref ports 1) nil)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry)))
           (lifecycle-check-update registry 0 8 0 0 1 :hold 1 nil)
           (lifecycle-check-update registry 500 8 0 0 2 :grow 1 t)
           (lifecycle-check-worker (second workers) t :activated)
           (is (equal '(2 2 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-registry-invalid-shape-does-not-bind-any-port
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (ports (lifecycle-ports workers)) (controller (crea-controllore-pool 1)))
    (unwind-protect
         (progn
           (dolist (bad (list nil '(nil nil) (vector) (vector (svref ports 0))
                             (vector (svref ports 0) :invalid)
                             (vector (svref ports 0) (svref ports 1) (svref ports 1))
                             (make-array 2 :adjustable t :initial-contents (coerce ports 'list))))
             (signals invalid-argument (arcdocdb.scheduler:crea-registro-pool controller bad)
                      :pool-ports)
             (dolist (port (coerce ports 'list))
               (is (not (arcdocdb.scheduler::porta-worker-pool-bound port)))))
           (signals invalid-argument
             (arcdocdb.scheduler:crea-registro-pool
              (crea-controllore-pool 1 :initial 2)
              (vector (svref ports 0) (svref ports 0))) :pool-ports)
           (signals invalid-argument
             (arcdocdb.scheduler:crea-registro-pool
              controller (vector (svref ports 1) (svref ports 0))) :pool-port-state)
           (is (equal '(1 1 nil)
                      (lifecycle-registry-state
                       (arcdocdb.scheduler:crea-registro-pool controller ports)))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-CON-001-pool-retirement-preserves-claim-lease-batch-and-finishing
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            (second workers)
            (lambda (owned)
              (let* ((context (lifecycle-fixture-context owned))
                     (writer (lifecycle-owned-writer owned 1)))
                (lifecycle-owned-busy owned :claimed)
                (is (plusp (arcdocdb.execution:inizia-tratto-worker context)))
                (lifecycle-owned-busy owned :running)
                (multiple-value-bind (count status token)
                    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1)
                  (is (= 1 count)) (is (eq status :messages))
                  (lifecycle-owned-busy owned :batch)
                  (is (null (arcdocdb.execution:conferma-lavori-worker context token))))
                (lifecycle-queue-busy
                 (arcdocdb.execution::writer-programmabile-queue writer)
                 (lambda ()
                   (signals arcdocdb.conditions:resource-exhausted
                     (arcdocdb.execution:termina-tratto-worker context) :writer-queue-busy)
                   (lifecycle-owned-busy owned :finishing)))
                (is (eq :idle (arcdocdb.execution:termina-tratto-worker context)))
                :ok)))
           (is (equal '(2 1 t) (lifecycle-registry-state registry)))
           (lifecycle-check-worker (second workers) nil :retired)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-CON-002-pool-reschedule-obligation-blocks-retirement-until-transfer
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            (second workers)
            (lambda (owned)
              (let ((context (lifecycle-fixture-context owned)))
                (lifecycle-owned-writer owned 2)
                (is (plusp (arcdocdb.execution:inizia-tratto-worker context)))
                (multiple-value-bind (count status token)
                    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1)
                  (is (= 1 count)) (is (eq :messages status))
                  (is (null (arcdocdb.execution:conferma-lavori-worker context token))))
                (is (eq :schedule (arcdocdb.execution:termina-tratto-worker context)))
                (lifecycle-owned-busy owned :reschedule)
                (multiple-value-bind (writer status count) (arcdocdb.execution:ricircola-worker context)
                  (is (null writer)) (is (eq :published status)) (is (= 1 count)))
                :ok)))
           (lifecycle-check-worker (second workers) nil :retired)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-pool-faulted-worker-retains-command-reference-and-diagnostic
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            (second workers)
            (lambda (owned)
              (let ((context (lifecycle-fixture-context owned)))
                (lifecycle-owned-writer owned 1)
                ;; FI quiescente: l'indice corrotto produce il fault C1 al vero confine.
                (setf (arcdocdb.execution::contesto-worker-writer-cursor context) 1)
                (signals invariant-violation
                  (arcdocdb.execution:inizia-tratto-worker context) :worker-state)
                (is (typep (arcdocdb.execution:errore-worker-writer context) 'invariant-violation))
                (dotimes (attempt 2) (lifecycle-owned-busy owned :faulted :faulted))
                :ok)))
           (lifecycle-check-update registry 1000 8 0 0 1 :pending 2 t)
           (is (equal '(2 1 t) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-port-startup-validates-flags-coordinator-and-idle-debts
  (let ((worker (lifecycle-fixture-start t)))
    (unwind-protect
         (lifecycle-call
          worker
          (lambda (owned)
            (let ((context (lifecycle-fixture-context owned)))
              (dolist (bad '(nil :owner 0))
                (signals invalid-argument
                  (arcdocdb.scheduler:crea-porta-worker-pool context :coordinator bad) :pool-owner))
              (dolist (bad '(0 1 :active))
                (signals invalid-argument
                  (arcdocdb.scheduler:crea-porta-worker-pool context :active bad) :pool-active))
              (is (equal '(1 1 nil) (lifecycle-words
                                    (arcdocdb.scheduler:crea-porta-worker-pool context))))
              (is (equal '(0 0 nil) (lifecycle-words
                                    (arcdocdb.scheduler:crea-porta-worker-pool context :active nil))))
              (setf (arcdocdb.execution::contesto-worker-writer-pending context) 1)
              (signals invariant-violation
                (arcdocdb.scheduler:crea-porta-worker-pool context) :worker-state)
              (setf (arcdocdb.execution::contesto-worker-writer-pending context) 0)
              (lifecycle-owned-writer owned 1)
              (signals arcdocdb.conditions:resource-exhausted
                (arcdocdb.scheduler:crea-porta-worker-pool context) :worker-state)
              :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-startup-rejects-coordinator-and-reused-worker-owner
  (let ((worker (lifecycle-fixture-start t)))
    (unwind-protect
         (let* ((foreign
                  (lifecycle-call worker
                                  (lambda (owned)
                                    (arcdocdb.scheduler:crea-porta-worker-pool
                                     (lifecycle-fixture-context owned)))))
                (duplicates
                  (lifecycle-call
                   worker (lambda (owned)
                            (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti))
                                   (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
                              (vector (lifecycle-fixture-port owned)
                                      (arcdocdb.scheduler:crea-porta-worker-pool
                                       context :coordinator (lifecycle-fixture-coordinator owned)
                                       :active nil)))))))
           (signals invalid-argument
             (arcdocdb.scheduler:crea-registro-pool
              (crea-controllore-pool 1 :maximum 1) (vector foreign)) :pool-owner)
           (signals invalid-argument
             (arcdocdb.scheduler:crea-registro-pool (crea-controllore-pool 1) duplicates) :pool-ports)
           (is (not (arcdocdb.scheduler::porta-worker-pool-bound foreign)))
           (dotimes (i 2) (is (not (arcdocdb.scheduler::porta-worker-pool-bound (svref duplicates i))))))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-startup-rejects-nonzero-or-pending-generation-before-binding
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (ports (lifecycle-ports workers)) (controller (crea-controllore-pool 1))
         (second (svref ports 1)))
    (unwind-protect
         (progn
           (dolist (pair '((2 2) (3 0) (0 1)))
             (setf (arcdocdb.scheduler::porta-worker-pool-request second) (first pair)
                   (arcdocdb.scheduler::porta-worker-pool-ack second) (second pair))
             (let ((before (mapcar #'lifecycle-words (coerce ports 'list))))
               (signals invalid-argument
                 (arcdocdb.scheduler:crea-registro-pool controller ports) :pool-port-state)
               (is (equal before (mapcar #'lifecycle-words (coerce ports 'list))))))
           (setf (arcdocdb.scheduler::porta-worker-pool-request second) 0
                 (arcdocdb.scheduler::porta-worker-pool-ack second) 0)
           (is (equal '(1 1 nil)
                      (lifecycle-registry-state
                       (arcdocdb.scheduler:crea-registro-pool controller ports)))))
      (lifecycle-fixtures-stop workers))))

(defun lifecycle-raw-registry-state (registry)
  "Snapshot FI non allocato dal prodotto; include target, controller e tutte le parole."
  (list (pool-state (arcdocdb.scheduler::registro-pool-controller registry))
        (arcdocdb.scheduler::registro-pool-target registry)
        (map 'list #'lifecycle-words (arcdocdb.scheduler::registro-pool-ports registry))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-invalid-samples-do-not-mutate-controller-or-ports
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (registry (arcdocdb.scheduler:crea-registro-pool
                    (crea-controllore-pool 1) (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-check-update registry 1000 8 0 0 1 :hold 1 nil)
           (let ((before (lifecycle-raw-registry-state registry)))
             (dolist (entry '((0 :pool-tick nil -1 1099511627776)
                              (1 :pool-queue nil -1 1048577)
                              (2 :pool-cpu nil -1 1001)
                              (3 :pool-p99 nil -1 10001)))
               (destructuring-bind (position reason &rest values) entry
                 (dolist (bad values)
                   (let ((arguments (list 1500 8 0 0)))
                     (setf (nth position arguments) bad)
                     (signals invalid-argument
                       (apply #'arcdocdb.scheduler:aggiorna-registro-pool registry arguments) reason)
                     (is (equal before (lifecycle-raw-registry-state registry)))))))
             (signals invalid-argument
               (arcdocdb.scheduler:aggiorna-registro-pool registry 1499 8 0 0) :pool-sample-period)
             (is (equal before (lifecycle-raw-registry-state registry)))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-generation-exhaustion-precedes-every-controller-and-port-write
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (ports (lifecycle-ports workers))
         (registry (arcdocdb.scheduler:crea-registro-pool (crea-controllore-pool 1) ports)))
    (unwind-protect
         (progn
           (dotimes (exhausted 2)
             (let* ((port (svref ports exhausted))
                    (word (+ (* 2 (ash most-positive-fixnum -1)) (if (zerop exhausted) 1 0))))
               (setf (arcdocdb.scheduler::porta-worker-pool-request port) word
                     (arcdocdb.scheduler::porta-worker-pool-ack port) word)
               (let ((before (lifecycle-raw-registry-state registry)))
                 (dolist (queue '(0 8))
                   (signals arcdocdb.conditions:resource-exhausted
                     (arcdocdb.scheduler:aggiorna-registro-pool registry 0 queue 0 0) :pool-generation)
                   (is (equal before (lifecycle-raw-registry-state registry)))))
               (setf (arcdocdb.scheduler::porta-worker-pool-request port) (if (zerop exhausted) 1 0)
                     (arcdocdb.scheduler::porta-worker-pool-ack port) (if (zerop exhausted) 1 0))))
           (lifecycle-check-update registry 0 8 0 0 1 :hold 1 nil))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-word-protocol-faults-refuse-reader-coordinator-and-worker
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (registry (arcdocdb.scheduler:crea-registro-pool
                    (crea-controllore-pool 1) (lifecycle-ports workers)))
         (port (lifecycle-fixture-port (second workers))))
    (unwind-protect
         (progn
           (dolist (pair '((2 0) (4 0) (5 0) (0 2) (1 0) (0 1)))
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) (first pair)
                   (arcdocdb.scheduler::porta-worker-pool-ack port) (second pair))
             (let ((before (lifecycle-raw-registry-state registry)))
               (signals invariant-violation (arcdocdb.scheduler:leggi-registro-pool registry)
                        :pool-port-state)
               (signals invariant-violation
                 (arcdocdb.scheduler:aggiorna-registro-pool registry 0 8 0 0) :pool-port-state)
               (lifecycle-call
                (second workers)
                (lambda (owned)
                  (signals invariant-violation
                    (arcdocdb.scheduler:applica-stato-worker-pool (lifecycle-fixture-port owned))
                    :pool-port-state) :ok))
               (is (equal before (lifecycle-raw-registry-state registry)))))
           (setf (arcdocdb.scheduler::porta-worker-pool-request port) 0
                 (arcdocdb.scheduler::porta-worker-pool-ack port) 0)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-idle-debt-refuses-ack-without-poisoning-or-reset
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 1 :initial 2 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-start-retirement controller registry)
           (lifecycle-call
            (second workers)
            (lambda (owned)
              (let* ((context (lifecycle-fixture-context owned))
                     (port (lifecycle-fixture-port owned)) (words (lifecycle-words port)))
                ;; FI quiescente: IDLE incoerente non può confermare un ritiro.
                (setf (arcdocdb.execution::contesto-worker-writer-pending context) 1)
                (let ((before (lifecycle-context-state context)))
                  (signals invariant-violation
                    (arcdocdb.scheduler:applica-stato-worker-pool port) :worker-state)
                  (is (equal before (lifecycle-context-state context)))
                  (is (equal words (lifecycle-words port))))
                (setf (arcdocdb.execution::contesto-worker-writer-pending context) 0)
                :ok)))
           (lifecycle-check-worker (second workers) nil :retired))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-private-registry-target-capacity-prefix-and-count-invariants
  (let* ((workers (list (lifecycle-fixture-start t) (lifecycle-fixture-start nil)))
         (ports (lifecycle-ports workers)) (controller (crea-controllore-pool 1))
         (registry (arcdocdb.scheduler:crea-registro-pool controller ports)))
    (unwind-protect
         (progn
           (setf (arcdocdb.scheduler::registro-pool-target registry) 2)
           (signals invariant-violation (arcdocdb.scheduler:leggi-registro-pool registry) :pool-state)
           (setf (arcdocdb.scheduler::registro-pool-target registry) 1)
           (let ((small (funcall (symbol-function 'arcdocdb.scheduler::%make-registro-pool)
                                 controller (vector (svref ports 0)) sb-thread:*current-thread* 1)))
             (signals invariant-violation (arcdocdb.scheduler:leggi-registro-pool small) :pool-state))
           (setf (arcdocdb.scheduler::porta-worker-pool-request (svref ports 1)) 3)
           (signals invariant-violation (arcdocdb.scheduler:leggi-registro-pool registry)
                    :pool-port-state)
           (setf (arcdocdb.scheduler::porta-worker-pool-request (svref ports 1)) 0
                 (arcdocdb.scheduler::porta-worker-pool-request (svref ports 0)) 3
                 (arcdocdb.scheduler::porta-worker-pool-ack (svref ports 0)) 0)
           (signals invariant-violation (arcdocdb.scheduler:leggi-registro-pool registry) :pool-state)
           (setf (arcdocdb.scheduler::porta-worker-pool-request (svref ports 0)) 1
                 (arcdocdb.scheduler::porta-worker-pool-ack (svref ports 0)) 1)
           (is (equal '(1 1 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-cas-conflict-cannot-report-request-or-ack-success
  (let ((worker (lifecycle-fixture-start t)))
    (unwind-protect
         (progn
           (let* ((port (lifecycle-fixture-port worker)) (before (lifecycle-words port)))
             (signals invariant-violation
               (arcdocdb.scheduler::%pool-request-command port 3 4) :pool-port-state)
             (is (equal before (lifecycle-words port))))
           (lifecycle-call
            worker (lambda (owned)
                     (let* ((port (lifecycle-fixture-port owned)) (before (lifecycle-words port)))
                       (signals invariant-violation
                         (arcdocdb.scheduler::%pool-ack-command port 3 4) :pool-port-state)
                       (is (equal before (lifecycle-words port))) :ok))))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-THR-001 REQ-AFF-008 REQ-AFF-013
(deftest test-REQ-AFF-008-pool-generated-port-equality-compares-request-ack-and-binding
  "Fixture private tipizzate: pending e confermato differiscono per una sola parola."
  (let ((worker (lifecycle-fixture-start t)))
    (unwind-protect
         (lifecycle-call
          worker
          (lambda (owned)
            (let* ((constructor (symbol-function 'arcdocdb.scheduler::%make-porta-worker-pool))
                   (owner sb-thread:*current-thread*) (coordinator (lifecycle-fixture-coordinator owned))
                   (context (lifecycle-fixture-context owned))
                   (left (funcall constructor owner coordinator context 2 1))
                   (same (funcall constructor owner coordinator context 2 1)))
              (is (not (eq left same))) (is (funcall (symbol-function 'equalp) left same))
              (dolist (words '((1 1) (2 2)))
                (let ((different (funcall constructor owner coordinator context
                                         (first words) (second words))))
                  (is (not (funcall (symbol-function 'equalp) left different)))))
              (setf (arcdocdb.scheduler::porta-worker-pool-bound same) t)
              (is (not (funcall (symbol-function 'equalp) left same)))
              (is (funcall (symbol-function 'arcdocdb.scheduler::porta-worker-pool-p) left))
              (is (not (funcall (symbol-function 'arcdocdb.scheduler::porta-worker-pool-p) nil)))
              :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-two-retirement-acks-can-arrive-with-a-prefix-hole
  (let* ((workers (loop repeat 6 collect (lifecycle-fixture-start t)))
         (controller (crea-controllore-pool 3 :initial 6 :dwell 500))
         (registry (arcdocdb.scheduler:crea-registro-pool controller (lifecycle-ports workers))))
    (unwind-protect
         (progn
           (lifecycle-check-update registry 0 0 0 1200 6 :hold 6 nil)
           (lifecycle-check-update registry 500 0 0 1200 4 :shrink 6 t)
           (lifecycle-check-worker (nth 4 workers) nil :retired)
           ;; ACK index4=false con index5 ancora attivo: il conteggio ammette il buco.
           (is (equal '(5 4 t) (lifecycle-registry-state registry)))
           (let ((before (mapcar (lambda (fixture) (lifecycle-words (lifecycle-fixture-port fixture)))
                                 workers)))
             (lifecycle-check-update registry 1000 8 0 0 4 :pending 5 t)
             (is (equal before
                        (mapcar (lambda (fixture) (lifecycle-words (lifecycle-fixture-port fixture)))
                                workers))))
           (lifecycle-check-worker (nth 5 workers) nil :retired)
           (is (equal '(4 4 nil) (lifecycle-registry-state registry))))
      (lifecycle-fixtures-stop workers))))
