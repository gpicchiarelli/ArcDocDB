;;;; Liste FIFO indipendenti; i writer sono riferimenti opachi per la lista pronta.
;;;; Ogni riferimento delle prove pubbliche viene da :schedule ed è completato.
;;;; I semafori appartengono solo alla fixture e hanno timeout tramite execution-wait.
(in-package #:arcdocdb.execution.tests)

(defun ready-test-writer ()
  (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 1))

(defun ready-prepare-fixture-writer (&optional (writer (ready-test-writer)))
  "Un unico payload corrisponde a un obbligo :schedule del writer idle."
  (handoff-check-enqueue writer :ready-fixture 1 :schedule)
  writer)

(defun ready-complete-fixture-writer (writer)
  "Consuma un obbligo dell'oracolo pubblico; il writer torna idle prima del riuso."
  (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
    (handoff-check-pop writer lease (vector nil) 0 1 '(:ready-fixture) :messages)
    (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))

(defun ready-check-publish (ready shard writer expected-count)
  (is (= expected-count (arcdocdb.execution:pubblica-writer-pronto ready shard writer))))

(defun ready-check-take (ready start expected expected-status expected-next)
  (multiple-value-bind (writer status next)
      (arcdocdb.execution:preleva-writer-pronto ready start)
    (is (eq writer expected))
    (is (eq status expected-status))
    (is (= next expected-next))
    next))

(defun ready-check-complete-take (ready start expected expected-status expected-next)
  (let ((next (ready-check-take ready start expected expected-status expected-next)))
    (when expected (ready-complete-fixture-writer expected))
    next))

(defun ready-model-publish (ready model shard writer capacity)
  (let ((items (svref model shard)))
    (if (= (length items) capacity)
        (signals resource-exhausted
          (arcdocdb.execution:pubblica-writer-pronto ready shard writer) :ready-queue-full)
        (progn
          (ready-check-publish ready shard writer (1+ (length items)))
          (setf (svref model shard) (append items (list writer)))
          t))))

(defun ready-model-take (ready model start &optional busy-shards)
  "Primo riferimento nelle liste FIFO, senza leggere indici/count del prodotto."
  (let ((shards (length model)))
    (dotimes (distance shards)
      (let* ((shard (mod (+ start distance) shards)) (items (svref model shard)))
        (when (and items (not (member shard busy-shards)))
          (setf (svref model shard) (rest items))
          (return-from ready-model-take
            (values (ready-check-complete-take ready start (first items) :writer
                                              (mod (1+ shard) shards))
                    (first items))))))
    (values (ready-check-take ready start nil (if busy-shards :busy :empty)
                             (mod (1+ start) shards)) nil)))

(defun ready-test-partition (ready shard)
  "Accessor privato usato solo per FI, mai per l'oracolo FIFO."
  (svref (arcdocdb.execution::lista-writer-pronti-partitions ready) shard))

(defun ready-call-with-guards (partitions thunk)
  "FI: un CAS per guard, rilascio anche se un'asserzione della fixture fallisce."
  (let ((thread sb-thread:*current-thread*) (owned nil))
    (unwind-protect
         (progn
           (dolist (partition partitions)
             (is (null (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) nil thread)))
             (push partition owned))
           (funcall thunk))
      (dolist (partition owned)
        (is (eq thread (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) thread nil)))))))

(defun ready-fi-snapshot (partition)
  "Immagine per rifiuti/FI, senza usarla come ordine FIFO atteso."
  (list (arcdocdb.execution::partizione-pronta-head partition)
        (arcdocdb.execution::partizione-pronta-tail partition)
        (arcdocdb.execution::partizione-pronta-count partition)
        (arcdocdb.execution::partizione-pronta-guard partition)
        (copy-seq (arcdocdb.execution::partizione-pronta-slots partition))))

(defun ready-pool-publish (ready model writers phases homes index shard capacity)
  "Pool dell'oracolo: full conserva pending; published non viene ripubblicato."
  (case (svref phases index)
    (:idle
     (ready-prepare-fixture-writer (svref writers index))
     (setf (svref phases index) :pending (svref homes index) shard))
    (:pending nil)
    (:published (return-from ready-pool-publish nil))
    (otherwise (error "Fase dell'oracolo pronta inattesa.")))
  (when (ready-model-publish ready model (svref homes index) (svref writers index) capacity)
    (setf (svref phases index) :published)))

(defun ready-pool-take (ready model writers phases start)
  (multiple-value-bind (next writer) (ready-model-take ready model start)
    (when writer
      (let ((index (position writer writers :test #'eq)))
        (is index)
        (is (eq (svref phases index) :published))
        (setf (svref phases index) :idle)))
    next))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-ready-configuration-and-limits
  (dolist (bad '(0 -1 65 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards bad :capacity 3)
      :ready-configuration))
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity bad)
      :ready-configuration))
  (dolist (limits '((1 65536) (64 1)))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti
                  :shards (first limits) :capacity (second limits)))
          (writer (ready-test-writer)))
      (dotimes (shard (first limits))
        (ready-prepare-fixture-writer writer)
        (ready-check-publish ready shard writer 1)
        (ready-check-complete-take ready shard writer :writer
                                   (mod (1+ shard) (first limits))))))
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti)) (writers (make-array 1025)))
    (dotimes (i 1025) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (i 1024) (ready-check-publish ready 3 (svref writers i) (1+ i)))
    (signals resource-exhausted
      (arcdocdb.execution:pubblica-writer-pronto ready 3 (svref writers 1024)) :ready-queue-full)
    (ready-check-complete-take ready 0 (svref writers 0) :writer 0)
    (ready-check-publish ready 3 (svref writers 1024) 1024)
    (loop for i from 1 below 1025
          do (ready-check-complete-take ready 0 (svref writers i) :writer 0))
    (ready-check-take ready 3 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-shard-and-writer-preflight
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
        (writer (ready-prepare-fixture-writer)))
    (ready-check-publish ready 1 writer 1)
    (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready bad writer)
               :ready-target)
      (signals invalid-argument (arcdocdb.execution:preleva-writer-pronto ready bad)
               :ready-target))
    (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready 1 bad)
               :ready-writer))
    (ready-check-complete-take ready 0 writer :writer 2)
    (ready-check-take ready 2 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004
(deftest test-REQ-CON-001-ready-per-shard-fifo-wrap-and-private-opaque-ring
  (dolist (shards '(1 2 3 7))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards shards :capacity 3))
          (model (make-array shards :initial-element nil)) (cursor 0))
      (dotimes (round 31)
        (dotimes (shard shards)
          (loop repeat (- 3 (length (svref model shard)))
                do (ready-model-publish ready model shard (ready-prepare-fixture-writer) 3)))
        (dotimes (i shards) (setf cursor (ready-model-take ready model cursor))))
      (loop repeat (* 3 shards) do (setf cursor (ready-model-take ready model cursor)))
      (is (every #'null model))))
  ;; FI di ring isolato, fuori dal protocollo handoff: nessuna membership/dedup.
  (let ((partition (arcdocdb.execution::%make-partizione-pronta (vector nil nil) 2))
        (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (is (= 1 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (is (= 2 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (dotimes (i 2)
         (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
           (is (eq actual writer)) (is (eq status :writer))))
       (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
         (is (null actual)) (is (eq status :empty)))))))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-cursor-rotates-first-choice-and-empty-scan
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (writers (make-array 6))
         (cursor 0))
    (dotimes (i 6) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (shard 3)
      (dotimes (i 2) (ready-check-publish ready shard (svref writers (+ (* shard 2) i)) (1+ i))))
    (dotimes (turn 6)
      (let ((shard (mod turn 3)))
        (setf cursor (ready-check-complete-take ready cursor
                                               (svref writers (+ (* shard 2) (floor turn 3)))
                                               :writer (mod (1+ shard) 3)))))
    (dotimes (turn 6)
      (let ((next (mod (1+ cursor) 3)))
        (setf cursor (ready-check-take ready cursor nil :empty next))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-001-ready-seeded-independent-lists-and-cursors
  (let ((seed #x7213bc08))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((shards (1+ (mod (ash (next) -8) 7)))
               (capacity (1+ (mod (ash (next) -8) 9)))
               (ready (arcdocdb.execution:crea-lista-writer-pronti
                       :shards shards :capacity capacity))
               (model (make-array shards :initial-element nil))
               (writers (make-array 11)) (phases (make-array 11 :initial-element :idle))
               (homes (make-array 11 :initial-element 0)) (cursor 0))
          (dotimes (i 11) (setf (svref writers i) (ready-test-writer)))
          (dotimes (step 1000)
            (if (< (mod (ash (next) -8) 5) 3)
                (ready-pool-publish ready model writers phases homes
                                    (mod (ash (next) -8) 11) (mod (ash (next) -8) shards) capacity)
                (setf cursor (ready-pool-take ready model writers phases
                                              (if (evenp step) cursor
                                                  (mod (ash (next) -8) shards))))))
          (loop repeat (* shards capacity)
                do (setf cursor (ready-pool-take ready model writers phases cursor)))
          (is (every #'null model))
          (dotimes (i 11)
            (when (eq (svref phases i) :pending)
              (ready-pool-publish ready model writers phases homes i (svref homes i) capacity)
              (is (eq (svref phases i) :published))
              (setf cursor (ready-pool-take ready model writers phases (svref homes i)))))
          (is (every (lambda (phase) (eq phase :idle)) phases)))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-full-preserves-scheduling-obligation
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (blocker (ready-prepare-fixture-writer)) (writer (ready-test-writer)) (target (vector nil nil)))
    (ready-check-publish ready 0 blocker 1)
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
               :ready-queue-full)
      (is (eq pending :schedule))
      (handoff-check-enqueue writer :b 2 :queued)
      (ready-check-complete-take ready 0 blocker :writer 0)
      (ready-check-publish ready 0 writer 1)
      (setf pending nil)
      (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:a) :messages)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-publish ready 0 writer 1)
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:b) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-dequeued-reference-survives-begin-busy
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (handoff-check-enqueue writer :once 1 :schedule)
    (ready-check-publish ready 0 writer 1)
    (multiple-value-bind (dequeued status cursor)
        (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (eq dequeued writer)) (is (eq status :writer)) (is (zerop cursor))
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer dequeued)
                 :writer-queue-busy))
      ;; Nessuna ripubblicazione: il caller conserva il riferimento estratto.
      (ready-check-take ready 0 nil :empty 0)
      (let ((lease (arcdocdb.execution:inizia-tratto-writer dequeued)))
        (handoff-check-pop dequeued lease (vector nil) 0 1 '(:once) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer dequeued lease)))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-ready-skips-busy-home-and-preserves-local-ring
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (a (ready-prepare-fixture-writer)) (b (ready-prepare-fixture-writer))
         (refused (ready-prepare-fixture-writer))
         (home (ready-test-partition ready 0)))
    (ready-check-publish ready 0 a 1)
    (ready-check-publish ready 2 b 1)
    (ready-call-with-guards
     (list home)
     (lambda ()
       (let ((before (ready-fi-snapshot home)))
         (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 refused)
                  :ready-queue-busy)
         (ready-check-complete-take ready 0 b :writer 0)
         (ready-check-take ready 0 nil :busy 1)
         (is (equalp before (ready-fi-snapshot home))))))
    (ready-check-complete-take ready 0 a :writer 1)
    (ready-check-publish ready 0 refused 1)
    (ready-check-complete-take ready 0 refused :writer 1)
    (ready-check-take ready 0 nil :empty 1)))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-busy-observations-and-scan-order-oracle
  (dotimes (pattern 8)
    (dotimes (start 3)
      (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1))
             (model (make-array 3 :initial-element nil))
             (busy (loop for i below 3 when (logbitp i pattern) collect i))
             (partitions (mapcar (lambda (i) (ready-test-partition ready i)) busy)))
        (dotimes (shard 3)
          (when (evenp shard)
            (ready-model-publish ready model shard (ready-prepare-fixture-writer) 1)))
        (ready-call-with-guards
         partitions
         (lambda ()
           (dotimes (attempt 4) (ready-model-take ready model start busy))))
        (dotimes (attempt 3) (ready-model-take ready model start))
        (is (every #'null model))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-busy-publication-retains-obligation-and-payload
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (partition (ready-test-partition ready 0)))
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :once)
      (is (= count 1)) (is (eq pending :schedule))
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (ready-fi-snapshot partition)))
           (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
                    :ready-queue-busy)
           (is (equalp before (ready-fi-snapshot partition))))))
      (is (eq pending :schedule))
      (ready-check-publish ready 0 writer 1)
      (setf pending nil) (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease (vector nil) 0 1 '(:once) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

(defun ready-fi-bad-partition (fault)
  "FI quiescente: constructor privato senza factory, tipi degli slot rispettati."
  (let* ((capacity (case fault (:capacity-zero 0) (:capacity-big 65537) (otherwise 2)))
         (size (if (member fault '(:capacity-zero :capacity-big)) 0
                   (if (eq fault :slots-length) 1 2)))
         (partition (arcdocdb.execution::%make-partizione-pronta
                     (make-array size :initial-element nil) capacity)))
    (case fault
      ((:capacity-zero :capacity-big :slots-length) nil)
      (:head (setf (arcdocdb.execution::partizione-pronta-head partition) 2))
      (:tail (setf (arcdocdb.execution::partizione-pronta-tail partition) 2))
      (:count (setf (arcdocdb.execution::partizione-pronta-count partition) 3))
      (:relation (setf (arcdocdb.execution::partizione-pronta-tail partition) 1))
      (otherwise (error "FI pronta sconosciuta: ~S" fault)))
    partition))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-ring-shapes
  (dolist (fault '(:capacity-zero :capacity-big :slots-length :head :tail :count :relation))
    (let* ((partition (ready-fi-bad-partition fault))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
           (before (ready-fi-snapshot partition)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution::%check-forma-pronta partition) :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
      (is (equalp before (ready-fi-snapshot partition))))))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-partition-arrays
  (dolist (partitions (list #() (make-array 65 :initial-element nil) (vector nil)))
    (let ((ready (arcdocdb.execution::%make-lista-writer-pronti partitions)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-inconsistent-occupied-and-free-slots
  (dolist (bad (list nil :foreign (vector :foreign)))
    (let* ((partition (arcdocdb.execution::%make-partizione-pronta (vector bad nil) 2))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition))))
      (setf (arcdocdb.execution::partizione-pronta-count partition) 1
            (arcdocdb.execution::partizione-pronta-tail partition) 1)
      (let ((before (ready-fi-snapshot partition)))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
        (is (equalp before (ready-fi-snapshot partition))))))
  (let* ((partition (arcdocdb.execution::%make-partizione-pronta
                     (vector (ready-test-writer) nil) 2))
         (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
         (before (ready-fi-snapshot partition)))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
      :ready-queue-invariant)
    (is (equalp before (ready-fi-snapshot partition)))))

(defun ready-check-unowned-helpers (partition writer)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%check-pronta partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%pubblica-pronto partition writer) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%preleva-pronto partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%rilascia-guard-pronta partition sb-thread:*current-thread*)
    :ready-queue-guard))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-helpers-reject-missing-and-foreign-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (partition (ready-test-partition ready 0)) (writer (ready-test-writer))
         (before (ready-fi-snapshot partition)) (threads nil))
    (ready-check-unowned-helpers partition writer)
    (unwind-protect
         (ready-call-with-guards
          (list partition)
          (lambda ()
            (push (execution-thread
                   "ready foreign guard"
                   (lambda ()
                     (ready-check-unowned-helpers partition writer)
                     (is (null (arcdocdb.execution::%prendi-guard-pronta partition)))
                     (multiple-value-bind (actual status) (arcdocdb.execution::%prova-pronta partition)
                       (is (null actual)) (is (eq status :busy)))
                     :ok)) threads)
            (execution-join (first threads))))
      (execution-stop-threads threads))
    (is (equalp before (ready-fi-snapshot partition)))
    (ready-prepare-fixture-writer writer)
    (ready-check-publish ready 0 writer 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-ready-handoff-before-after-release-and-next-wave
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
        (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (dotimes (wave 4)
      (let ((first (vector wave :initial)) (before (vector wave :before))
            (after (vector wave :after)))
        (handoff-check-enqueue writer first 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list first) :messages)
          (handoff-check-pop writer lease target 0 1 nil :empty)
          (handoff-check-enqueue writer before 1 :queued)
          (ready-check-take ready 0 nil :empty 1)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list before) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (handoff-check-enqueue writer after 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list after) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-take ready 1 nil :empty 0)))))

(defun ready-wave-items (series wave)
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 37) (* wave 11) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun ready-read-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4) (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun ready-wave-producer (ready home writer messages go published third-go third-published)
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
  :ok)

(defun ready-wave-consumer (ready home writer messages go taken finish drained results)
  (let ((cursor (mod (1+ home) 2)))
    (dotimes (wave (length messages))
      (execution-wait go)
      (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (ready-read-message writer lease (first (svref messages wave)))
        (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
        (sb-thread:signal-semaphore taken)
        (execution-wait finish)
        (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease)))
        (ready-check-publish ready home writer 1))
      (loop for item in (rest (svref messages wave)) for sequence from 1
            do (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
               (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                 (ready-read-message writer lease item)
                 (is (eq (if (= sequence 2) :idle :schedule)
                         (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (unless (= sequence 2) (ready-check-publish ready home writer 1))))
      (setf (svref results wave) :verified)
      (sb-thread:signal-semaphore drained)))
  :ok)

(defun ready-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun ready-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun ready-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun ready-start-wave-workers (ready writers messages semaphores results producers)
  (let ((threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (series 2)
             (let ((s series))
               (let ((producer
                       (execution-thread
                        "ready reused producer"
                        (lambda ()
                          (ready-wave-producer
                           ready s (svref writers s) (svref messages s)
                           (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                           (svref (svref semaphores 4) s) (svref (svref semaphores 5) s))))))
                 (push producer threads) (setf (svref producers s) producer))
               (push (execution-thread
                      "ready reused consumer"
                      (lambda ()
                        (ready-wave-consumer
                         ready s (svref writers s) (svref messages s)
                         (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                         (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                         (svref results s)))) threads)))
           (setf complete t)
           threads)
      (unless complete (execution-stop-threads threads)))))

(defun ready-drive-wave (ready semaphores results producers wave)
  "Ordini causali controllati: B progredisce mentre la guard dello shard A è ferma."
  (ready-pair-signal (svref semaphores 0))
  (ready-pair-wait (svref semaphores 1))
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
     (is (eq :verified (svref (svref results 1) wave)))
     (ready-check-take ready 0 nil :busy 1)))
  (sb-thread:signal-semaphore (svref (svref semaphores 2) 0))
  (execution-wait (svref (svref semaphores 3) 0))
  (is (sb-thread:thread-alive-p (svref producers 0)))
  (sb-thread:signal-semaphore (svref (svref semaphores 4) 0))
  (execution-wait (svref (svref semaphores 5) 0))
  (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
  (execution-wait (svref (svref semaphores 7) 0))
  (is (eq :verified (svref (svref results 0) wave)))
  (ready-check-take ready (mod wave 2) nil :empty (mod (1+ wave) 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-ready-reused-workers-live-producers-and-independent-shards
  (let* ((waves 6)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writers (vector (ready-test-writer) (ready-test-writer)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (producers (vector nil nil)) (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (ready-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (ready-start-wave-workers ready writers messages semaphores results producers))
           (is (= 4 (length threads)))
           (dotimes (wave waves) (ready-drive-wave ready semaphores results producers wave))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series))))
           (format t "  Ready: 4 thread riusati, ~D ondate, ~D payload, shard fermata e stealing.~%"
                   waves (* 2 waves 3)))
      (dotimes (i 8) (ready-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))

(defun ready-competing-consumer (ready expected go done results index waves)
  (dotimes (wave waves)
    (execution-wait go)
    (multiple-value-bind (writer status cursor) (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (zerop cursor))
      (if (eq status :writer)
          (progn (is (eq writer expected)) (ready-complete-fixture-writer writer))
          (progn (is (null writer)) (is (member status '(:empty :busy)))))
      (setf (svref results index) status))
    (sb-thread:signal-semaphore done))
  :ok)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-ready-competing-consumers-take-one-reference-per-wave
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (go (ready-semaphore-pair)) (done (ready-semaphore-pair))
         (results (vector nil nil)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (consumer 2)
             (let ((index consumer))
               (push (execution-thread
                      "ready competing reused consumer"
                      (lambda () (ready-competing-consumer ready writer (svref go index)
                                                           (svref done index) results index waves))) threads)))
           (dotimes (wave waves)
             (ready-prepare-fixture-writer writer)
             (ready-check-publish ready 0 writer 1)
             (ready-pair-signal go)
             (ready-pair-wait done)
             (is (= 1 (count :writer results)))
             (is (= 1 (+ (count :empty results) (count :busy results))))
             (ready-check-take ready 0 nil :empty 0))
           (dolist (thread threads) (execution-join thread))
           (format t "  Ready: 2 consumer riusati, ~D ondate, un riferimento estratto per ondata.~%" waves))
      (ready-pair-signal go)
      (execution-stop-threads threads))))
