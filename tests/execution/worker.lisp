;;;; Un contesto per il thread proprietario; obblighi pubblici unici da handoff.
;;;; Liste/payload dell'oracolo non leggono gli indici o lo stato privato writer.
;;;; Accessor privati solo per snapshot di rifiuto o FI quiescente dichiarata.
;;;; Thread, semafori e retry bounded appartengono soltanto alla fixture.
(in-package #:arcdocdb.execution.tests)

(defun worker-check-state (context expected-state expected-writer)
  (is (eq expected-state (arcdocdb.execution:stato-worker-writer context)))
  (is (eq expected-writer (arcdocdb.execution:writer-worker-writer context)))
  (unless (eq expected-state :faulted)
    (is (null (arcdocdb.execution:errore-worker-writer context)))))

(defun worker-test-writer (items &optional (quantum 1))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile
                 :capacity (max 4 (length items)) :quantum quantum)))
    (loop for item in items for count from 1
          do (handoff-check-enqueue writer item count (if (= count 1) :schedule :queued)))
    writer))

(defun worker-check-claim (context expected expected-status expected-cursor)
  (multiple-value-bind (writer status cursor) (arcdocdb.execution:prendi-writer-worker context)
    (is (eq writer expected)) (is (eq status expected-status)) (is (= cursor expected-cursor))
    (worker-check-state context (if expected :claimed :idle) expected)
    writer))

(defun worker-check-pop (context target start end expected expected-status)
  "Verifica FIFO per identità e tutte le celle non scritte del buffer caller."
  (let ((before (copy-seq target)))
    (multiple-value-bind (count status token)
        (arcdocdb.execution:preleva-lavori-worker context target start end)
      (is (= count (length expected))) (is (eq status expected-status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref target i) (svref before i)))))
      (if (eq status :messages)
          (progn (is (and (typep token 'fixnum) (plusp token)))
                 (is (eq :batch (arcdocdb.execution:stato-worker-writer context))))
          (progn (is (zerop token))
                 (is (eq :running (arcdocdb.execution:stato-worker-writer context)))))
      token)))

(defun worker-check-ack (context token writer)
  (is (null (arcdocdb.execution:conferma-lavori-worker context token)))
  (worker-check-state context :running writer))

(defun worker-check-end (context writer expected)
  (is (eq expected (arcdocdb.execution:termina-tratto-worker context)))
  (worker-check-state context (if (eq expected :schedule) :reschedule :idle)
                      (and (eq expected :schedule) writer)))

(defun worker-check-recycle (context expected expected-status expected-count)
  (multiple-value-bind (writer status count) (arcdocdb.execution:ricircola-worker context)
    (is (eq writer expected)) (is (eq status expected-status)) (is (= count expected-count))
    (worker-check-state context (if expected :claimed :idle) expected)
    writer))

(defun worker-complete-one (context writer item)
  (let ((lease (arcdocdb.execution:inizia-tratto-worker context)))
    (is (and (typep lease 'fixnum) (plusp lease))))
  (worker-check-state context :running writer)
  (worker-check-ack context (worker-check-pop context (vector :left :kept :right)
                                             1 2 (list item) :messages) writer)
  (worker-check-end context writer :idle))

(defun worker-fi-snapshot (context)
  "Solo immagine di rifiuti/FI; mai ordine atteso delle liste o dei payload."
  (list (arcdocdb.execution::contesto-worker-writer-cursor context)
        (arcdocdb.execution::contesto-worker-writer-home context)
        (arcdocdb.execution::contesto-worker-writer-writer context)
        (arcdocdb.execution::contesto-worker-writer-lease context)
        (arcdocdb.execution::contesto-worker-writer-pending context)
        (arcdocdb.execution::contesto-worker-writer-batch-generation context)
        (arcdocdb.execution::contesto-worker-writer-state context)
        (arcdocdb.execution::contesto-worker-writer-fault context)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-004-worker-factory-preflight-and-empty-cursor-rotation
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1)))
    (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
      (signals invalid-argument
        (arcdocdb.execution:crea-contesto-worker-writer ready :start bad) :ready-target))
    (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready)))
      (worker-check-state context :idle nil)
      (dotimes (step 9) (worker-check-claim context nil :empty (mod (1+ step) 3))))
    (dotimes (start 3)
      (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready :start start)))
        (worker-check-claim context nil :empty (mod (1+ start) 3))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-001-worker-claim-batch-ack-and-idle-release
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (item (vector :only)) (writer (worker-test-writer (list item)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 1 writer 1)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer item)
    (worker-check-claim context nil :empty 1)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-quantum-yield-reschedule-and-monotone-tokens
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (items (list (vector 0) (vector 1) (vector 2)))
         (writer (worker-test-writer items))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (last-token 0) (last-lease 0))
    (ready-check-publish ready 0 writer 1)
    (loop for item in items for last = (eq item (third items))
          do (worker-check-claim context writer :claimed 0)
             (let ((lease (arcdocdb.execution:inizia-tratto-worker context)))
               (is (> lease last-lease)) (setf last-lease lease))
             (let ((token (worker-check-pop context (vector nil nil nil) 1 2 (list item) :messages)))
               (is (> token last-token)) (setf last-token token)
               (worker-check-ack context token writer))
             (worker-check-pop context (vector :untouched) 0 1 nil :yield)
             (worker-check-end context writer (if last :idle :schedule))
             (unless last (worker-check-recycle context nil :published 1)))
    (worker-check-claim context nil :empty 0)))

(defun worker-check-idle-only-refusals (context)
  (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context) :worker-state)
  (signals resource-exhausted
    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context 1) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-005-worker-batch-debt-blocks-more-pop-finish-and-transfer
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (worker-check-idle-only-refusals context)
    (ready-check-publish ready 0 writer 1)
    (worker-check-claim context writer :claimed 0)
    (signals resource-exhausted (arcdocdb.execution:prendi-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
    (arcdocdb.execution:inizia-tratto-worker context)
    (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
    (let* ((target (vector :left :middle :right))
           (token (worker-check-pop context target 1 2 '(:one) :messages))
           (before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      (signals resource-exhausted
        (arcdocdb.execution:preleva-lavori-worker context target 0 3) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :one :right)))
      (worker-check-ack context token writer))
    (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:two) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-current-token-required-and-stale-ack-keeps-debt
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1)
    (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((first (worker-check-pop context (vector nil) 0 1 '(:one) :messages)))
      (let ((before (worker-fi-snapshot context)))
        (dolist (bad (list nil -1 0 1.0 :token (1+ most-positive-fixnum) (1+ first)))
          (signals invalid-argument (arcdocdb.execution:conferma-lavori-worker context bad)
                   :worker-batch))
        (is (equalp before (worker-fi-snapshot context))))
      (worker-check-ack context first writer)
      (signals resource-exhausted
        (arcdocdb.execution:conferma-lavori-worker context first) :worker-state)
      (let ((second (worker-check-pop context (vector nil) 0 1 '(:two) :messages)))
        (is (> second first))
        (let ((before (worker-fi-snapshot context)))
          (signals invalid-argument
            (arcdocdb.execution:conferma-lavori-worker context first) :worker-batch)
          (is (equalp before (worker-fi-snapshot context))))
        (worker-check-ack context second writer)))
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-buffer-range-and-private-alias-preflight
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:kept)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-worker context target (first range) (second range))
          :writer-target))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :kept)
                        (arcdocdb.execution::coda-writer-slots queue)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-worker context bad 0 1) :writer-target))
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :middle :right))))
    (worker-check-ack context (worker-check-pop context target 1 2 '(:kept) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-begin-busy-retains-claimed-reference
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:once)))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (with-execution-guard (queue)
      (let ((before (worker-fi-snapshot context)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context)
                 :writer-queue-busy)
        (is (equalp before (worker-fi-snapshot context)))))
    (ready-check-take ready 0 nil :empty 0)
    (worker-complete-one context writer :once)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-pop-busy-retains-lease-buffer-and-generation
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:once)))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (with-execution-guard (queue)
      (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted
          (arcdocdb.execution:preleva-lavori-worker context target 1 2) :writer-queue-busy)
        (is (equalp before (worker-fi-snapshot context)))
        (is (equalp writer-before (handoff-fi-snapshot writer)))
        (is (equalp target #(:left :middle :right)))))
    (worker-check-ack context (worker-check-pop context target 1 2 '(:once) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-end-busy-is-finishing-and-blocks-new-pop
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:one) :messages) writer)
    (with-execution-guard (queue)
      (let ((writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                 :writer-queue-busy)
        (worker-check-state context :finishing writer)
        (let ((before (worker-fi-snapshot context)))
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                   :writer-queue-busy)
          (signals resource-exhausted
            (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-state)
          (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context 1)
                   :worker-state)
          (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
          (is (equalp before (worker-fi-snapshot context))))
        (is (equalp writer-before (handoff-fi-snapshot writer)))))
    (worker-check-end context writer :schedule)
    (worker-check-recycle context nil :published 1)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer :two)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-worker-scanned-home-and-full-recycle-retained-on-busy
  (dolist (home '(1 2 3))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 4 :capacity 1))
           (writer (worker-test-writer '(:one :two)))
           (blocker (worker-test-writer '(:blocker)))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (partition (ready-test-partition ready home)))
      (ready-check-publish ready home writer 1)
      (ready-call-with-guards
       (list (ready-test-partition ready 0))
       (lambda () (worker-check-claim context writer :claimed (mod (1+ home) 4))))
      (arcdocdb.execution:inizia-tratto-worker context)
      (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:one) :messages) writer)
      (worker-check-end context writer :schedule)
      (ready-check-publish ready home blocker 1)
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (worker-fi-snapshot context)) (ring-before (ready-fi-snapshot partition)))
           (signals resource-exhausted (arcdocdb.execution:ricircola-worker context)
                    :ready-queue-busy)
           (is (equalp before (worker-fi-snapshot context)))
           (is (equalp ring-before (ready-fi-snapshot partition))))))
      (worker-check-recycle context blocker :claimed 1)
      (worker-complete-one context blocker :blocker)
      (worker-check-claim context writer :claimed (mod (1+ home) 4))
      (worker-complete-one context writer :two)
      (worker-check-claim context nil :empty (mod (+ 2 home) 4)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-two-contexts-full-refill-preserves-all-obligations
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (writers (vector (worker-test-writer '(:a0 :a1)) (worker-test-writer '(:b0 :b1))
                          (worker-test-writer '(:c)) (worker-test-writer '(:d))))
         (contexts (vector (arcdocdb.execution:crea-contesto-worker-writer ready)
                           (arcdocdb.execution:crea-contesto-worker-writer ready))))
    (dotimes (i 2) (ready-check-publish ready 0 (svref writers i) (1+ i)))
    (dotimes (i 2)
      (let ((context (svref contexts i)) (writer (svref writers i)))
        (worker-check-claim context writer :claimed 0)
        (arcdocdb.execution:inizia-tratto-worker context)
        (worker-check-ack context
                          (worker-check-pop context (vector nil) 0 1 (list (if (zerop i) :a0 :b0))
                                            :messages) writer)))
    (dotimes (i 2) (ready-check-publish ready 0 (svref writers (+ i 2)) (1+ i)))
    (dotimes (i 2) (worker-check-end (svref contexts i) (svref writers i) :schedule))
    ;; Due swap, nessun dequeue aggiuntivo o duplicazione dell'obbligo A/B.
    (dotimes (i 2)
      (worker-check-recycle (svref contexts i) (svref writers (+ i 2)) :claimed 2))
    (dotimes (i 2)
      (worker-complete-one (svref contexts i) (svref writers (+ i 2)) (if (zerop i) :c :d)))
    (dotimes (i 2)
      (worker-check-claim (svref contexts i) (svref writers i) :claimed 0)
      (worker-complete-one (svref contexts i) (svref writers i) (if (zerop i) :a1 :b1)))
    (worker-check-claim (svref contexts 0) nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-worker-empty-observation-and-new-wave-after-idle
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:initial) 3))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((first (worker-check-pop context (vector nil) 0 1 '(:initial) :messages)))
      (worker-check-ack context first writer)
      (worker-check-pop context (vector :untouched) 0 1 nil :empty)
      (handoff-check-enqueue writer :before-release 1 :queued)
      (let ((next (worker-check-pop context (vector nil) 0 1 '(:before-release) :messages)))
        (is (> next first)) (worker-check-ack context next writer)))
    (worker-check-end context writer :idle)
    (handoff-check-enqueue writer :next-wave 1 :schedule)
    (ready-check-publish ready 0 writer 1)
    (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer :next-wave)))

(defun worker-check-foreign-owner (context writer)
  (signals invalid-argument (arcdocdb.execution:stato-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:writer-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:errore-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:prendi-writer-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:inizia-tratto-worker context) :worker-owner)
  (signals invalid-argument
    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:conferma-lavori-worker context 0) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:termina-tratto-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:ricircola-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:cede-writer-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:adotta-writer-worker context writer 0) :worker-owner))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CON-002-worker-foreign-thread-refuses-all-six-phases
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore)) (threads nil))
    (unwind-protect
         (progn
           (push (execution-thread
                  "worker foreign reused observer"
                  (lambda ()
                    (dotimes (phase 6)
                      (execution-wait go) (worker-check-foreign-owner context writer)
                      (sb-thread:signal-semaphore done))
                    :ok)) threads)
           (flet ((probe ()
                    (let ((before (worker-fi-snapshot context))
                          (writer-before (handoff-fi-snapshot writer)))
                      (sb-thread:signal-semaphore go) (execution-wait done)
                      (is (equalp before (worker-fi-snapshot context)))
                      (is (equalp writer-before (handoff-fi-snapshot writer))))))
             (probe)
             (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
             (probe)
             (arcdocdb.execution:inizia-tratto-worker context) (probe)
             (let ((token (worker-check-pop context (vector nil) 0 1 '(:one) :messages)))
               (probe) (worker-check-ack context token writer))
             (with-execution-guard (queue)
               (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                        :writer-queue-busy)
               (probe))
             (worker-check-end context writer :schedule) (probe))
           (execution-join (first threads))
           (worker-check-recycle context nil :published 1)
           (worker-check-claim context writer :claimed 0)
           (worker-complete-one context writer :two))
      (sb-thread:signal-semaphore go) (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-local-generation-limit-can-cede-into-fresh-context
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writer (worker-test-writer '(:last :preserved) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (fresh (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right)))
    (ready-check-publish ready 1 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    ;; FI locale, nessun pop/debito attivo; raggiunge l'ultimo token rappresentabile.
    (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context)
          (1- most-positive-fixnum))
    (let ((token (worker-check-pop context target 1 2 '(:last) :messages)))
      (is (= token most-positive-fixnum)) (worker-check-ack context token writer))
    (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      ;; Target/range ha precedenza, ma una forma valida non può mutare dopo overflow.
      (signals invalid-argument
        (arcdocdb.execution:preleva-lavori-worker context nil 0 1) :writer-target)
      (signals resource-exhausted
        (arcdocdb.execution:preleva-lavori-worker context target 0 1) :worker-generation)
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :last :right))))
    (worker-check-end context writer :schedule)
    (multiple-value-bind (owned home) (arcdocdb.execution:cede-writer-worker context)
      (is (eq owned writer)) (is (= home 1)) (worker-check-state context :idle nil)
      (is (= most-positive-fixnum
             (arcdocdb.execution::contesto-worker-writer-batch-generation context)))
      (is (null (arcdocdb.execution:adotta-writer-worker fresh owned home))))
    (worker-check-state fresh :claimed writer)
    (worker-complete-one fresh writer :preserved)
    (worker-check-claim fresh nil :empty 1)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CON-002-worker-cede-adopt-validates-home-and-single-caller-obligation
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1))
         (writer (worker-test-writer '(:kept)))
         (source (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (arcdocdb.execution:crea-contesto-worker-writer ready :start 2)))
    (ready-check-publish ready 1 writer 1) (worker-check-claim source writer :claimed 2)
    (multiple-value-bind (owned home) (arcdocdb.execution:cede-writer-worker source)
      (is (eq owned writer)) (is (= home 1)) (worker-check-state source :idle nil)
      (let ((before (worker-fi-snapshot target)))
        (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
          (signals invalid-argument (arcdocdb.execution:adotta-writer-worker target owned bad)
                   :ready-target))
        (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
          (signals invalid-argument (arcdocdb.execution:adotta-writer-worker target bad home)
                   :worker-writer))
        (is (equalp before (worker-fi-snapshot target))))
      (is (null (arcdocdb.execution:adotta-writer-worker target owned home))))
    (worker-check-state target :claimed writer)
    (signals resource-exhausted
      (arcdocdb.execution:adotta-writer-worker target writer 1) :worker-state)
    (worker-check-claim source nil :empty 0)
    (worker-complete-one target writer :kept)))

(defstruct worker-oracle
  ready context lists writers payloads phases homes leases
  (state :idle) (index nil) (home 0) (cursor 0) (remaining 0) (token 0)
  (accepted 0) (delivered 0))

(defun worker-oracle-publish (oracle index capacity)
  (when (eq (svref (worker-oracle-phases oracle) index) :pending)
    (let* ((home (svref (worker-oracle-homes oracle) index))
           (items (svref (worker-oracle-lists oracle) home))
           (writer (svref (worker-oracle-writers oracle) index)))
      (if (= (length items) capacity)
          (signals resource-exhausted
            (arcdocdb.execution:pubblica-writer-pronto (worker-oracle-ready oracle) home writer)
            :ready-queue-full)
          (progn
            (ready-check-publish (worker-oracle-ready oracle) home writer (1+ (length items)))
            (setf (svref (worker-oracle-lists oracle) home) (append items (list writer))
                  (svref (worker-oracle-phases oracle) index) :published))))))

(defun worker-oracle-enqueue (oracle index payload capacity)
  (let ((items (svref (worker-oracle-payloads oracle) index))
        (phase (svref (worker-oracle-phases oracle) index)))
    (when (< (length items) 4)
      (handoff-check-enqueue (svref (worker-oracle-writers oracle) index) payload (1+ (length items))
                             (if (eq phase :idle) :schedule :queued))
      (setf (svref (worker-oracle-payloads oracle) index) (append items (list payload)))
      (incf (worker-oracle-accepted oracle))
      (when (eq phase :idle)
        (setf (svref (worker-oracle-phases oracle) index) :pending)
        (worker-oracle-publish oracle index capacity)))))

(defun worker-oracle-claim (oracle)
  (when (eq (worker-oracle-state oracle) :idle)
    (let* ((lists (worker-oracle-lists oracle)) (shards (length lists))
           (start (worker-oracle-cursor oracle)))
      (dotimes (distance shards)
        (let* ((home (mod (+ start distance) shards)) (items (svref lists home)))
          (when items
            (let ((index (position (first items) (worker-oracle-writers oracle) :test #'eq)))
              (is (eq (svref (worker-oracle-phases oracle) index) :published))
              (worker-check-claim (worker-oracle-context oracle) (first items) :claimed
                                  (mod (1+ home) shards))
              (setf (svref lists home) (rest items)
                    (svref (worker-oracle-phases oracle) index) :owned
                    (worker-oracle-state oracle) :claimed (worker-oracle-index oracle) index
                    (worker-oracle-home oracle) home
                    (worker-oracle-cursor oracle) (mod (1+ home) shards))
              (return-from worker-oracle-claim t)))))
      (setf (worker-oracle-cursor oracle) (mod (1+ start) shards))
      (worker-check-claim (worker-oracle-context oracle) nil :empty (worker-oracle-cursor oracle))
      nil)))

(defun worker-oracle-begin (oracle quantum)
  (when (eq (worker-oracle-state oracle) :claimed)
    (let* ((index (worker-oracle-index oracle))
           (lease (arcdocdb.execution:inizia-tratto-worker (worker-oracle-context oracle))))
      (is (> lease (svref (worker-oracle-leases oracle) index)))
      (setf (svref (worker-oracle-leases oracle) index) lease
            (svref (worker-oracle-phases oracle) index) :active
            (worker-oracle-state oracle) :running (worker-oracle-remaining oracle) quantum)
      (worker-check-state (worker-oracle-context oracle) :running
                          (svref (worker-oracle-writers oracle) index)))))

(defun worker-oracle-pop (oracle start span)
  (when (eq (worker-oracle-state oracle) :running)
    (let* ((index (worker-oracle-index oracle))
           (items (svref (worker-oracle-payloads oracle) index))
           (remaining (worker-oracle-remaining oracle))
           (count (min span remaining (length items)))
           (status (cond ((zerop remaining) :yield) ((zerop count) :empty) (t :messages)))
           (token (worker-check-pop (worker-oracle-context oracle)
                                    (make-array (+ start span 2) :initial-element :untouched)
                                    start (+ start span) (subseq items 0 count) status)))
      (when (plusp count)
        (is (> token (worker-oracle-token oracle)))
        (setf (worker-oracle-token oracle) token (worker-oracle-state oracle) :batch
              (svref (worker-oracle-payloads oracle) index) (nthcdr count items))
        (decf (worker-oracle-remaining oracle) count)
        (incf (worker-oracle-delivered oracle) count)))))

(defun worker-oracle-ack (oracle)
  (when (eq (worker-oracle-state oracle) :batch)
    (worker-check-ack (worker-oracle-context oracle) (worker-oracle-token oracle)
                      (svref (worker-oracle-writers oracle) (worker-oracle-index oracle)))
    (setf (worker-oracle-state oracle) :running)))

(defun worker-oracle-end (oracle)
  (when (eq (worker-oracle-state oracle) :running)
    (let* ((index (worker-oracle-index oracle))
           (action (if (svref (worker-oracle-payloads oracle) index) :schedule :idle)))
      (worker-check-end (worker-oracle-context oracle)
                        (svref (worker-oracle-writers oracle) index) action)
      (setf (worker-oracle-state oracle) (if (eq action :schedule) :reschedule :idle)
            (svref (worker-oracle-phases oracle) index) (if (eq action :schedule) :owned :idle)
            (worker-oracle-remaining oracle) 0)
      (when (eq action :idle) (setf (worker-oracle-index oracle) nil)))))

(defun worker-oracle-recycle (oracle capacity)
  (when (eq (worker-oracle-state oracle) :reschedule)
    (let* ((home (worker-oracle-home oracle)) (lists (worker-oracle-lists oracle))
           (items (svref lists home)) (full (= (length items) capacity))
           (old (and full (first items))) (index (worker-oracle-index oracle)))
      (worker-check-recycle (worker-oracle-context oracle) old (if full :claimed :published)
                            (if full capacity (1+ (length items))))
      (setf (svref lists home)
            (append (if full (rest items) items) (list (svref (worker-oracle-writers oracle) index)))
            (svref (worker-oracle-phases oracle) index) :published)
      (if old
          (let ((old-index (position old (worker-oracle-writers oracle) :test #'eq)))
            (is (eq (svref (worker-oracle-phases oracle) old-index) :published))
            (setf (svref (worker-oracle-phases oracle) old-index) :owned
                  (worker-oracle-index oracle) old-index (worker-oracle-state oracle) :claimed))
          (setf (worker-oracle-index oracle) nil (worker-oracle-state oracle) :idle)))))

(defun worker-oracle-drain (oracle capacity quantum)
  "Limite dérivato dai payload accettati e dal numero di writer; nessun retry infinito."
  (loop repeat (+ 100 (* 8 (worker-oracle-accepted oracle)))
        do (case (worker-oracle-state oracle)
             (:idle
              (dotimes (i (length (worker-oracle-writers oracle)))
                (worker-oracle-publish oracle i capacity))
              (unless (worker-oracle-claim oracle)
                (is (every (lambda (phase) (eq phase :idle)) (worker-oracle-phases oracle)))
                (return-from worker-oracle-drain t)))
             (:claimed (worker-oracle-begin oracle quantum))
             (:batch (worker-oracle-ack oracle))
             (:reschedule (worker-oracle-recycle oracle capacity))
             (:running
              (if (or (zerop (worker-oracle-remaining oracle))
                      (null (svref (worker-oracle-payloads oracle) (worker-oracle-index oracle))))
                  (worker-oracle-end oracle)
                  (worker-oracle-pop oracle 1 3)))
             (otherwise (error "Fase inattesa nell'oracolo worker."))))
  (error "Drain worker oltre il limite indipendente."))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-worker-seeded-independent-obligations-payloads-and-batch-debt
  (let ((seed #x31e45a92))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dolist (shards '(1 4))
        (dolist (capacity '(1 2))
          (dolist (quantum '(1 2))
            (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti
                           :shards shards :capacity capacity))
                   (writers (make-array 13)) (homes (make-array 13))
                   (oracle (make-worker-oracle
                            :ready ready :context (arcdocdb.execution:crea-contesto-worker-writer ready)
                            :lists (make-array shards :initial-element nil) :writers writers :homes homes
                            :payloads (make-array 13 :initial-element nil)
                            :phases (make-array 13 :initial-element :idle)
                            :leases (make-array 13 :initial-element 0))))
              (dotimes (i 13)
                (setf (svref writers i) (worker-test-writer nil quantum)
                      (svref homes i) (mod i shards)))
              (dotimes (step 1000)
                (let ((index (mod (ash (next) -8) 13)))
                  (case (mod (ash (next) -8) 9)
                    ((0 1) (worker-oracle-enqueue oracle index
                                                  (vector shards capacity quantum step) capacity))
                    (2 (worker-oracle-publish oracle index capacity))
                    (3 (worker-oracle-claim oracle))
                    (4 (worker-oracle-begin oracle quantum))
                    (5 (worker-oracle-pop oracle (1+ (mod (next) 3))
                                          (1+ (mod (ash (next) -8) 3))))
                    (6 (worker-oracle-ack oracle))
                    (7 (worker-oracle-end oracle))
                    (8 (worker-oracle-recycle oracle capacity)))))
              (is (worker-oracle-drain oracle capacity quantum))
              (is (= (worker-oracle-accepted oracle) (worker-oracle-delivered oracle)))
              (is (every #'null (worker-oracle-payloads oracle)))
              (is (every #'null (worker-oracle-lists oracle)))
              (worker-check-state (worker-oracle-context oracle) :idle nil))))))))

(defun worker-fi-restore (context snapshot)
  "Solo FI quiescente del checker privato; nessun reset di un contesto faulted."
  (destructuring-bind (cursor home writer lease pending generation state fault) snapshot
    (setf (arcdocdb.execution::contesto-worker-writer-cursor context) cursor
          (arcdocdb.execution::contesto-worker-writer-home context) home
          (arcdocdb.execution::contesto-worker-writer-writer context) writer
          (arcdocdb.execution::contesto-worker-writer-lease context) lease
          (arcdocdb.execution::contesto-worker-writer-pending context) pending
          (arcdocdb.execution::contesto-worker-writer-batch-generation context) generation
          (arcdocdb.execution::contesto-worker-writer-state context) state
          (arcdocdb.execution::contesto-worker-writer-fault context) fault)))

(defun worker-fi-corrupt (context fault writer)
  (case fault
    (:idle-writer (setf (arcdocdb.execution::contesto-worker-writer-writer context) writer))
    ((:idle-lease :claimed-lease)
     (setf (arcdocdb.execution::contesto-worker-writer-lease context) 1))
    ((:idle-pending :claimed-pending :running-pending)
     (setf (arcdocdb.execution::contesto-worker-writer-pending context) 1))
    ((:claimed-writer :running-writer)
     (setf (arcdocdb.execution::contesto-worker-writer-writer context) nil))
    (:batch-pending
     (setf (arcdocdb.execution::contesto-worker-writer-pending context) 0))
    (:batch-generation
     (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context) 0))
    (:batch-extracted (setf (arcdocdb.execution::contesto-worker-writer-pending context) 2))
    (:cursor (setf (arcdocdb.execution::contesto-worker-writer-cursor context) 2))
    (:home (setf (arcdocdb.execution::contesto-worker-writer-home context) 2))
    (:fault (setf (arcdocdb.execution::contesto-worker-writer-fault context)
                  (make-condition 'simple-error :format-control "FI nonnil fault")))
    (otherwise (error "FI worker sconosciuta."))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-private-shapes-and-pending-count-invariants
  (dolist (fault '(:idle-writer :idle-lease :idle-pending :claimed-writer :claimed-lease
                   :claimed-pending :running-writer :running-pending :batch-pending
                   :batch-generation :batch-extracted :cursor :home :fault))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (claimed (member fault '(:claimed-writer :claimed-lease :claimed-pending)))
           (active (member fault '(:running-writer :running-pending :batch-pending
                                   :batch-generation :batch-extracted)))
           (writer (if (or claimed active) (worker-test-writer '(:kept)) (ready-test-writer)))
           (batch-token nil))
      (when (or claimed active)
        (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 1))
      (when active (arcdocdb.execution:inizia-tratto-worker context))
      (when (member fault '(:batch-pending :batch-generation :batch-extracted))
        (setf batch-token (worker-check-pop context (vector nil) 0 1 '(:kept) :messages)))
      (let ((original (worker-fi-snapshot context)))
        (worker-fi-corrupt context fault writer)
        (let ((before (worker-fi-snapshot context)))
          (signals arcdocdb.conditions:invariant-violation
            (arcdocdb.execution::%check-worker context) :worker-state)
          (is (equalp before (worker-fi-snapshot context))))
        ;; Solo il checker privato è stato chiamato, senza confine/mutazione/fault.
        (worker-fi-restore context original))
      (cond (batch-token (worker-check-ack context batch-token writer)
                         (worker-check-end context writer :idle))
            (claimed (worker-complete-one context writer :kept))
            (active
             (worker-check-ack context
                               (worker-check-pop context (vector nil) 0 1 '(:kept) :messages) writer)
             (worker-check-end context writer :idle))
            (t (worker-check-state context :idle nil))))))

(defun worker-capture-condition (thunk type reason)
  (let ((condition (handler-case (progn (funcall thunk) nil) (error (condition) condition))))
    (is (typep condition type))
    (when reason (is (eq (arcdocdb.conditions:error-reason condition) reason)))
    condition))

(defun worker-check-faulted (context writer condition)
  (worker-check-state context :faulted writer)
  (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
  (let ((before (worker-fi-snapshot context)))
    (signals resource-exhausted (arcdocdb.execution:prendi-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context) :worker-state)
    (signals resource-exhausted
      (arcdocdb.execution:preleva-lavori-worker context nil 0 1) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context nil) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:adotta-writer-worker context nil 0) :worker-state)
    (is (equalp before (worker-fi-snapshot context))))
  (is (eq condition (arcdocdb.execution:errore-worker-writer context))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-private-index-corruption-poisons-before-adopt
  (dolist (fault '(:cursor :home :fault))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (fresh (arcdocdb.execution:crea-contesto-worker-writer ready))
           (writer (worker-test-writer '(:kept))))
      (worker-fi-corrupt context fault writer)
      (let ((condition
              (worker-capture-condition
               (lambda () (arcdocdb.execution:adotta-writer-worker context writer 0))
               'arcdocdb.conditions:invariant-violation :worker-state)))
        (worker-check-faulted context nil condition))
      ;; L'adozione fallita non aveva trasferito l'obbligo unico del caller.
      (is (null (arcdocdb.execution:adotta-writer-worker fresh writer 0)))
      (worker-complete-one fresh writer :kept))))

(defun worker-tree-symbol-count (symbol form)
  (cond ((eq symbol form) 1)
        ((consp form) (+ (worker-tree-symbol-count symbol (car form))
                         (worker-tree-symbol-count symbol (cdr form))))
        (t 0)))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-boundary-expansion-values-once-and-error-identity
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)) (evaluations 0)
         (expansion (macroexpand-1
                     '(arcdocdb.execution::%passo-worker
                       ((worker-boundary-context) (:worker-state) (:worker-batch)) (values :a :b)))))
    (is (= 1 (worker-tree-symbol-count 'worker-boundary-context expansion)))
    (multiple-value-bind (a b c)
        (arcdocdb.execution::%passo-worker
            ((progn (incf evaluations) context) (:worker-state) (:worker-batch))
          (values :a :b :c))
      (is (eq a :a)) (is (eq b :b)) (is (eq c :c)))
    (is (= evaluations 1)) (worker-check-state context :idle nil)
    (dolist (condition (list (make-condition 'resource-exhausted :reason :worker-state)
                             (make-condition 'invalid-argument :reason :worker-batch)))
      (is (eq condition
              (worker-capture-condition
               (lambda ()
                 (arcdocdb.execution::%passo-worker (context (:worker-state) (:worker-batch))
                   (error condition)))
               (type-of condition) (arcdocdb.conditions:error-reason condition))))
      (worker-check-state context :idle nil))
    (let ((unexpected (make-condition 'simple-error :format-control "Boundary fixture")))
      (is (eq unexpected
              (worker-capture-condition
               (lambda ()
                 (arcdocdb.execution::%passo-worker (context (:worker-state) (:worker-batch))
                   (error unexpected))) 'simple-error nil)))
      (worker-check-faulted context nil unexpected))
    (dolist (unexpected (list (make-condition 'resource-exhausted :reason :writer-generation)
                              (make-condition 'resource-exhausted :reason :writer-not-ready)
                              (make-condition 'invalid-argument :reason :writer-lease)
                              (make-condition 'arcdocdb.conditions:invariant-violation
                                              :reason :worker-state)))
      (let ((fresh (arcdocdb.execution:crea-contesto-worker-writer ready)))
        (is (eq unexpected
                (worker-capture-condition
                 (lambda ()
                   (arcdocdb.execution::%passo-worker (fresh (:worker-state) (:worker-batch))
                     (error unexpected)))
                 (type-of unexpected) (arcdocdb.conditions:error-reason unexpected))))
        (worker-check-faulted fresh nil unexpected)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-stale-not-ready-reference-cannot-steal-new-wave
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:old)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (fresh (arcdocdb.execution:crea-contesto-worker-writer ready)) (threads nil))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    ;; FI: bypass handoff del contesto consuma il vecchio obbligo prima del begin.
    ;; Il riferimento CLAIMED diventa stale; questa duplicazione non è protocollo pubblico.
    (is (equal '(:old) (handoff-drain writer 1)))
    (let ((condition (worker-capture-condition
                      (lambda () (arcdocdb.execution:inizia-tratto-worker context))
                      'resource-exhausted :writer-not-ready)))
      (worker-check-faulted context writer condition)
      (unwind-protect
           (progn
             (push (execution-thread
                    "faulted worker foreign owner"
                    (lambda () (worker-check-foreign-owner context writer) :ok)) threads)
             (execution-join (first threads)))
        (execution-stop-threads threads))
      (worker-check-faulted context writer condition)
      (handoff-check-enqueue writer :new 1 :schedule)
      (ready-check-publish ready 0 writer 1)
      (worker-check-faulted context writer condition)
      (worker-check-claim fresh writer :claimed 0)
      (worker-complete-one fresh writer :new)
      (worker-check-faulted context writer condition))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-generation-overflow-precedes-empty-and-yield-pop
  (dolist (quantum '(1 3))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
           (writer (worker-test-writer '(:last) quantum))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (target (vector :untouched)))
      (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
      (arcdocdb.execution:inizia-tratto-worker context)
      (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context)
            (1- most-positive-fixnum))
      (let ((token (worker-check-pop context (vector nil) 0 1 '(:last) :messages)))
        (is (= token most-positive-fixnum)) (worker-check-ack context token writer))
      (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted
          (arcdocdb.execution:preleva-lavori-worker context target 0 1) :worker-generation)
        (is (equalp before (worker-fi-snapshot context)))
        (is (equalp writer-before (handoff-fi-snapshot writer)))
        (is (equalp target #(:untouched))))
      (worker-check-end context writer :idle))))

(defun worker-wave-read (context writer expected last-token)
  (let* ((target (vector :left :untouched :right))
         (token (worker-check-pop context target 1 2 (list expected) :messages)))
    (is (> token last-token))
    (is (= (svref expected 4) (reference-crc (svref (svref target 1) 3) 0 256)))
    (worker-check-ack context token writer)
    token))

(defun worker-wave-producer (ready home writer messages go published third-go third-published finish)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait go)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (ready-check-publish ready home writer 1)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait third-go)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore third-published)))
  (execution-wait finish)
  :ok)

(defun worker-wave-consumer (ready home writer messages go taken finish drained results)
  ;; Il contesto è creato sul proprietario una volta e riusato per tutte le ondate.
  (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready :start home))
        (last-token 0))
    (dotimes (wave (length messages))
      (execution-wait go)
      (worker-check-claim context writer :claimed (mod (1+ home) 2))
      (arcdocdb.execution:inizia-tratto-worker context)
      (setf last-token (worker-wave-read context writer (first (svref messages wave)) last-token))
      (sb-thread:signal-semaphore taken)
      (execution-wait finish)
      (worker-check-end context writer :schedule)
      (worker-check-recycle context nil :published 1)
      (loop for item in (rest (svref messages wave)) for sequence from 1
            do (worker-check-claim context writer :claimed (mod (1+ home) 2))
               (arcdocdb.execution:inizia-tratto-worker context)
               (setf last-token (worker-wave-read context writer item last-token))
               (worker-check-end context writer (if (= sequence 2) :idle :schedule))
               (unless (= sequence 2) (worker-check-recycle context nil :published 1)))
      (worker-check-state context :idle nil)
      (setf (svref results wave) :verified)
      (sb-thread:signal-semaphore drained)))
  :ok)

(defun worker-start-wave-threads (ready writers messages semaphores results producers final-go)
  (let ((threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (series 2)
             (let ((s series))
               (let ((producer
                       (execution-thread
                        "worker live reused producer"
                        (lambda ()
                          (worker-wave-producer
                           ready s (svref writers s) (svref messages s)
                           (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                           (svref (svref semaphores 4) s) (svref (svref semaphores 5) s)
                           (svref final-go s))))))
                 (push producer threads) (setf (svref producers s) producer))
               (push (execution-thread
                      "worker local reused consumer"
                      (lambda ()
                        (worker-wave-consumer
                         ready s (svref writers s) (svref messages s)
                         (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                         (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                         (svref results s)))) threads)))
           (setf complete t) threads)
      (unless complete (execution-stop-threads threads)))))

(defun worker-drive-wave (ready semaphores results producers wave)
  (ready-pair-signal (svref semaphores 0)) (ready-pair-wait (svref semaphores 1))
  (ready-call-with-guards
   (list (ready-test-partition ready 0))
   (lambda ()
     (sb-thread:signal-semaphore (svref (svref semaphores 2) 1))
     (execution-wait (svref (svref semaphores 3) 1))
     (is (every #'sb-thread:thread-alive-p producers))
     (sb-thread:signal-semaphore (svref (svref semaphores 4) 1))
     (execution-wait (svref (svref semaphores 5) 1))
     (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
     (execution-wait (svref (svref semaphores 7) 1))
     (is (eq :verified (svref (svref results 1) wave)))))
  (sb-thread:signal-semaphore (svref (svref semaphores 2) 0))
  (execution-wait (svref (svref semaphores 3) 0))
  (is (every #'sb-thread:thread-alive-p producers))
  (sb-thread:signal-semaphore (svref (svref semaphores 4) 0))
  (execution-wait (svref (svref semaphores 5) 0))
  (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
  (execution-wait (svref (svref semaphores 7) 0))
  (is (eq :verified (svref (svref results 0) wave)))
  (ready-check-take ready (mod wave 2) nil :empty (mod (1+ wave) 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-worker-reused-owner-contexts-live-producers-and-independent-shards
  (let* ((waves 6)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writers (vector (ready-test-writer) (ready-test-writer)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (producers (vector nil nil)) (semaphores (make-array 8))
         (final-go (ready-semaphore-pair)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (ready-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (worker-start-wave-threads ready writers messages semaphores results
                                                   producers final-go))
           (is (= 4 (length threads)))
           (dotimes (wave waves) (worker-drive-wave ready semaphores results producers wave))
           (ready-pair-signal final-go)
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series))))
           (format t "  Worker: 4 thread riusati, ~D ondate, ~D payload CRC, contesti owner-only.~%"
                   waves (* 2 waves 3)))
      (dotimes (i 8) (ready-pair-signal (svref semaphores i)))
      (ready-pair-signal final-go) (execution-stop-threads threads))))

(defun worker-competing-consumer (ready writer items go done results index)
  (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready)) (last-token 0))
    (dotimes (wave (length items))
      (execution-wait go)
      (multiple-value-bind (actual status cursor) (arcdocdb.execution:prendi-writer-worker context)
        (is (zerop cursor))
        (if (eq status :claimed)
            (progn
              (is (eq actual writer))
              (arcdocdb.execution:inizia-tratto-worker context)
              (let ((token (worker-check-pop context (vector nil) 0 1
                                              (list (svref items wave)) :messages)))
                (is (> token last-token)) (setf last-token token)
                (worker-check-ack context token writer))
              (worker-check-end context writer :idle))
            (progn (is (null actual)) (is (member status '(:empty :busy)))))
        (setf (svref results index) status))
      (worker-check-state context :idle nil)
      (sb-thread:signal-semaphore done)))
  :ok)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-worker-competing-owner-contexts-claim-one-obligation-per-wave
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer nil)) (items (make-array waves))
         (go (ready-semaphore-pair)) (done (ready-semaphore-pair))
         (results (vector nil nil)) (threads nil))
    (dotimes (wave waves) (setf (svref items wave) (vector wave :only)))
    (unwind-protect
         (progn
           (dotimes (i 2)
             (let ((index i))
               (push (execution-thread
                      "worker competing owner context"
                      (lambda ()
                        (worker-competing-consumer ready writer items (svref go index)
                                                    (svref done index) results index))) threads)))
           (dotimes (wave waves)
             (handoff-check-enqueue writer (svref items wave) 1 :schedule)
             (ready-check-publish ready 0 writer 1)
             (ready-pair-signal go) (ready-pair-wait done)
             (is (= 1 (count :claimed results)))
             (is (= 1 (+ (count :empty results) (count :busy results))))
             (ready-check-take ready 0 nil :empty 0))
           (dolist (thread threads) (execution-join thread))
           (format t "  Worker: 2 consumer owner riusati, ~D ondate, un solo obbligo per ondata.~%" waves))
      (ready-pair-signal go) (execution-stop-threads threads))))
