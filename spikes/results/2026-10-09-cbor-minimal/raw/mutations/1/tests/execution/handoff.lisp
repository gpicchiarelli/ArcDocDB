;;;; Oracolo FIFO e fixture del passaggio locale idle/ready/running.
;;;; Semafori e thread appartengono soltanto alla fixture, non al prodotto.
(in-package #:arcdocdb.execution.tests)

(defun handoff-check-enqueue (writer item expected-count expected-status)
  (multiple-value-bind (count status)
      (arcdocdb.execution:accoda-lavoro-writer writer item)
    (is (= count expected-count))
    (is (eq status expected-status))
    count))

(defun handoff-check-pop (writer lease target start end expected expected-status)
  "Lista attesa indipendente; verifica anche tutte le celle non scritte."
  (let ((before (copy-seq target)))
    (multiple-value-bind (count status)
        (arcdocdb.execution:preleva-lavori-writer writer lease target start end)
      (is (= count (length expected)))
      (is (eq status expected-status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      count)))

(defun handoff-drain (writer maximum)
  "Ready initiale; limite maximum+1, nessuna lettura dei contatori del ring."
  (let ((target (make-array (max 1 maximum) :initial-element :untouched)) (items nil))
    (loop repeat (1+ maximum)
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (multiple-value-bind (count status)
                   (arcdocdb.execution:preleva-lavori-writer writer lease target 0 (length target))
                 (is (plusp count)) (is (eq status :messages))
                 (dotimes (i count) (push (svref target i) items)))
               (let ((next (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (is (member next '(:idle :schedule)))
                 (when (eq next :idle) (return-from handoff-drain (nreverse items)))))
          finally (error "Il drain handoff ha superato il limite della fixture."))))

(defun handoff-fi-snapshot (writer)
  "FI: immagine dei campi prima/dopo un rifiuto, mai oracolo dell'ordine FIFO."
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (list (arcdocdb.execution::writer-programmabile-state writer)
          (arcdocdb.execution::coda-writer-head queue)
          (arcdocdb.execution::coda-writer-tail queue)
          (arcdocdb.execution::coda-writer-count queue)
          (arcdocdb.execution::coda-writer-owner queue)
          (arcdocdb.execution::coda-writer-generation queue)
          (arcdocdb.execution::coda-writer-extracted queue)
          (copy-seq (arcdocdb.execution::coda-writer-slots queue)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-configuration-and-limits
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity bad :quantum 3)
      :writer-configuration)
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum bad)
      :writer-configuration))
  (dolist (limits '((1 65536) (65536 1)))
    (let ((writer (arcdocdb.execution:crea-writer-programmabile
                   :capacity (first limits) :quantum (second limits))))
      (handoff-check-enqueue writer nil 1 :schedule)
      (is (equal '(nil) (handoff-drain writer 1)))))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile)))
    (dotimes (i 1024)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (signals resource-exhausted
      (arcdocdb.execution:accoda-lavoro-writer writer :extra) :writer-queue-full)
    (is (equal (loop for i below 1024 collect i) (handoff-drain writer 1024)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-single-obligation-and-duplicate-begin
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 2))
        (target (vector :left :x :y :right)))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)
    ;; Un invio della notifica che fallisce conserva l'obbligo :schedule.
    ;; Il chiamante ritenta la notifica; il payload accettato non viene riaccodato.
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (let ((attempts 0))
        (flet ((notify () (> (incf attempts) 1)))
          (is (null (notify)))
          (is (eq pending :schedule))
          (handoff-check-enqueue writer :b 2 :queued)
          (is (notify))
          (is (= attempts 2))
          (setf pending nil)))
      (is (null pending))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-not-ready)
        (handoff-check-pop writer lease target 1 3 '(:a :b) :messages)
        (handoff-check-pop writer lease target 1 3 nil :yield)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-enqueue-before-and-after-empty-release
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :initial 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 1 '(:initial) :messages)
      (handoff-check-pop writer lease target 0 1 nil :empty)
      ;; Vuoto, ma running: il prossimo lavoro non crea una seconda notifica.
      (handoff-check-enqueue writer :before-release 1 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(:before-release) (handoff-drain writer 2)))
    ;; La pubblicazione successiva al rilascio vuoto crea il nuovo obbligo.
    (handoff-check-enqueue writer :after-release 1 :schedule)
    (is (equal '(:after-release) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-cumulative-quantum-and-successive-slices
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 7 :quantum 3))
        (target (make-array 8 :initial-element :untouched)))
    (dotimes (i 7)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 3 '(0 1) :messages)
      (handoff-check-pop writer lease target 1 7 '(2) :messages)
      (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
        (with-execution-guard (queue)
          (handoff-check-pop writer lease target 1 7 nil :yield)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 7 '(3 4 5) :messages)
      (handoff-check-pop writer lease target 1 7 nil :yield)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(6) (handoff-drain writer 7)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-full-ready-and-running-retain-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (a (vector :a)) (b (vector :b)) (refused (vector :refused)))
    (handoff-check-enqueue writer a 1 :schedule)
    (handoff-check-enqueue writer b 2 :queued)
    (let ((before (handoff-fi-snapshot writer)))
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
               :writer-queue-full)
      (is (equalp before (handoff-fi-snapshot writer))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
                 :writer-queue-full)
        (is (equalp before (handoff-fi-snapshot writer))))
      (handoff-check-pop writer lease (vector :untouched) 0 1 (list a) :messages)
      (handoff-check-enqueue writer refused 2 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equalp refused #(:refused)))
    (is (equal (list b refused) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-busy-idle-and-ready-preserve-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-queue-busy)
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (is (equal '(:kept) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-handoff-busy-release-retains-lease-for-retry
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted
            (arcdocdb.execution:preleva-lavori-writer writer lease target 0 2)
            :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                   :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp target #(:left :right)))
          (is (equalp before (handoff-fi-snapshot writer)))))
      (handoff-check-pop writer lease target 0 2 '(:kept) :messages)
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp before (handoff-fi-snapshot writer)))))
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-005-handoff-early-release-conserves-entire-backlog
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 8)))
    (handoff-check-enqueue writer :a 1 :schedule)
    (handoff-check-enqueue writer :b 2 :queued)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer old)))
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (handoff-check-pop writer fresh (vector :untouched :untouched) 0 2 '(:a :b) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-lease-validation-and-stale-generation
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :old 1 :schedule)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (dolist (bad (list 0 -1 nil :wrong (1+ most-positive-fixnum)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer bad target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer bad)
                 :writer-lease))
      (handoff-check-pop writer old target 0 1 '(:old) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer old)))
      (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
               :writer-lease)
      (handoff-check-enqueue writer :fresh 1 :schedule)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer old target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
                 :writer-lease)
        (handoff-check-pop writer fresh target 0 1 '(:fresh) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-target-preflight-and-private-alias
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 3))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :middle :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let* ((lease (arcdocdb.execution:inizia-tratto-writer writer))
           (before (handoff-fi-snapshot writer)))
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease target
                                                 (first range) (second range)) :writer-target))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :caller)
                        (arcdocdb.execution::coda-writer-slots queue)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease bad 0 1) :writer-target))
      (is (equalp target #(:left :middle :right)))
      (is (equalp before (handoff-fi-snapshot writer)))
      (handoff-check-pop writer lease target 1 3 '(:kept) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-generation-exhaustion-preserves-ready
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    ;; FI quiescente, nessun thread/lease attivo; si raggiunge l'ultimo token lecito.
    (setf (arcdocdb.execution::coda-writer-generation queue) (1- most-positive-fixnum))
    (handoff-check-enqueue writer :last 1 :schedule)
    (let ((last (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (= last most-positive-fixnum))
      (handoff-check-pop writer last (vector nil) 0 1 '(:last) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer last))))
    (handoff-check-enqueue writer :preserved 1 :schedule)
    (let ((before (handoff-fi-snapshot writer)))
      (dotimes (attempt 2)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-generation)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :also-accepted 2 :queued)))

(defun handoff-fi-corrupt-state (writer fault)
  "FI su oggetto privato sacrificato; gli indici del ring rimangono coerenti."
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (when (member fault '(:ready-count :ready-owner :ready-extracted :running-owner))
      (handoff-check-enqueue writer :kept 1 :schedule))
    (case fault
      (:idle-count
       (setf (arcdocdb.execution::coda-writer-count queue) 1
             (arcdocdb.execution::coda-writer-tail queue) 1
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) :unexpected))
      ((:idle-owner :ready-owner)
       (setf (arcdocdb.execution::coda-writer-owner queue) sb-thread:*current-thread*))
      ((:idle-extracted :ready-extracted)
       (setf (arcdocdb.execution::coda-writer-extracted queue) 1))
      (:ready-count
       (setf (arcdocdb.execution::coda-writer-count queue) 0
             (arcdocdb.execution::coda-writer-tail queue) 0
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) nil))
      (:running-owner
       (arcdocdb.execution:inizia-tratto-writer writer)
       (setf (arcdocdb.execution::coda-writer-owner queue) nil))
      (otherwise (error "FI handoff sconosciuta: ~S" fault)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-rejects-inconsistent-scheduling-states
  (dolist (fault '(:idle-count :idle-owner :idle-extracted :ready-count
                   :ready-owner :ready-extracted :running-owner))
    (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
           (queue (arcdocdb.execution::writer-programmabile-queue writer)))
      (handoff-fi-corrupt-state writer fault)
      (let ((before (handoff-fi-snapshot writer)))
        (with-execution-guard (queue)
          (signals arcdocdb.conditions:invariant-violation
            (arcdocdb.execution::%check-programmabile writer) :writer-scheduling))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:accoda-lavoro-writer writer :refused) :writer-scheduling)
        (is (equalp before (handoff-fi-snapshot writer)))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-helpers-require-current-thread-guard
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (before (handoff-fi-snapshot writer)) (threads nil))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
    (is (equalp before (handoff-fi-snapshot writer)))
    ;; FI: guard posseduta dal main; il thread estraneo deve rifiutare i tre helper.
    (unwind-protect
         (with-execution-guard (queue)
           (push (execution-thread
                  "handoff foreign guard"
                  (lambda ()
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
                    :ok)) threads)
           (execution-join (first threads))
           (is (equalp before (handoff-fi-snapshot writer))))
      (execution-stop-threads threads))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (is (equal '(:kept) (handoff-drain writer 2)))))

(defstruct handoff-model
  (items nil) (state :idle) (remaining 0) (lease 0))

(defun handoff-model-enqueue (writer model item capacity)
  (if (= (length (handoff-model-items model)) capacity)
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer item)
               :writer-queue-full)
      (let ((expected (if (eq (handoff-model-state model) :idle) :schedule :queued)))
        (setf (handoff-model-items model) (append (handoff-model-items model) (list item)))
        (handoff-check-enqueue writer item (length (handoff-model-items model)) expected)
        (when (eq expected :schedule) (setf (handoff-model-state model) :ready)))))

(defun handoff-model-begin (writer model quantum)
  (if (eq (handoff-model-state model) :ready)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh (handoff-model-lease model)))
        (setf (handoff-model-lease model) fresh (handoff-model-state model) :running
              (handoff-model-remaining model) quantum))
      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
               :writer-not-ready)))

(defun handoff-model-pop (writer model start span)
  (when (eq (handoff-model-state model) :running)
    (let* ((remaining (handoff-model-remaining model))
           (items (handoff-model-items model)) (n (min remaining span (length items)))
           (target (make-array (+ start span 2) :initial-element :untouched))
           (status (cond ((zerop remaining) :yield) ((zerop n) :empty) (t :messages))))
      (handoff-check-pop writer (handoff-model-lease model) target start (+ start span)
                         (subseq items 0 n) status)
      (setf (handoff-model-items model) (nthcdr n items))
      (decf (handoff-model-remaining model) n))))

(defun handoff-model-finish (writer model)
  (when (eq (handoff-model-state model) :running)
    (let ((expected (if (handoff-model-items model) :schedule :idle)))
      (is (eq expected (arcdocdb.execution:termina-tratto-writer
                        writer (handoff-model-lease model))))
      (setf (handoff-model-state model) (if (eq expected :schedule) :ready :idle)
            (handoff-model-remaining model) 0))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-handoff-seeded-list-and-scheduling-oracle
  (let ((seed #x9d670f42))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((capacity (1+ (mod (ash (next) -8) 9)))
               (quantum (1+ (mod (ash (next) -8) 12)))
               (writer (arcdocdb.execution:crea-writer-programmabile
                        :capacity capacity :quantum quantum))
               (model (make-handoff-model)))
          (dotimes (step 800)
            (case (mod (ash (next) -8) 7)
              ((0 1) (handoff-model-enqueue writer model
                                            (if (zerop (mod step 7)) nil (vector scenario step))
                                            capacity))
              (2 (handoff-model-begin writer model quantum))
              ((3 4) (handoff-model-pop writer model (1+ (mod (next) 3))
                                        (1+ (mod (ash (next) -8) 7))))
              (5 (handoff-model-finish writer model))
              (6 (if (eq (handoff-model-state model) :ready)
                     (handoff-model-begin writer model quantum)
                     (handoff-model-finish writer model)))
              (otherwise (error "Operazione dell'oracolo inattesa."))))
          (handoff-model-finish writer model)
          (if (handoff-model-items model)
              (is (equal (handoff-model-items model) (handoff-drain writer capacity)))
              (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                       :writer-not-ready)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-CON-001-handoff-foreign-thread-cannot-use-lease
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (threads nil))
    (handoff-check-enqueue writer :original 1 :schedule)
    (unwind-protect
         (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
           (push (execution-thread
                  "handoff foreign owner"
                  (lambda ()
                    (let ((target (vector :untouched)))
                      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                               :writer-not-ready)
                      (signals invalid-argument
                        (arcdocdb.execution:preleva-lavori-writer writer lease target 0 1)
                        :writer-lease)
                      (signals invalid-argument
                        (arcdocdb.execution:termina-tratto-writer writer lease) :writer-lease)
                      (is (equalp target #(:untouched)))
                      (handoff-check-enqueue writer :producer 2 :queued)
                      :ok))) threads)
           (execution-join (first threads))
           (handoff-check-pop writer lease (vector nil nil) 0 2 '(:original :producer) :messages)
           (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-002-handoff-transfers-successive-slices-between-reused-threads
  (let* ((waves 4)
         (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (messages (make-array waves)) (first-go (sb-thread:make-semaphore))
         (second-go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore))
         (owners (make-array 2 :initial-element nil)) (threads nil))
    (dotimes (wave waves) (setf (svref messages wave) (list (vector wave 0) (vector wave 1))))
    (unwind-protect
         (progn
           (dotimes (worker 2)
             (let ((index worker))
               (push (execution-thread
                      "handoff successive owner"
                      (lambda ()
                        (setf (svref owners index) sb-thread:*current-thread*)
                        (dotimes (wave waves)
                          (execution-wait (if (zerop index) first-go second-go))
                          (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                            (handoff-check-pop writer lease (vector :untouched) 0 1
                                               (list (nth index (svref messages wave))) :messages)
                            (is (eq (if (zerop index) :schedule :idle)
                                    (arcdocdb.execution:termina-tratto-writer writer lease))))
                          (sb-thread:signal-semaphore (if (zerop index) second-go done)))
                        :ok)) threads)))
           (dotimes (wave waves)
             (handoff-check-enqueue writer (first (svref messages wave)) 1 :schedule)
             (handoff-check-enqueue writer (second (svref messages wave)) 2 :queued)
             (sb-thread:signal-semaphore first-go)
             (execution-wait done))
           (dolist (thread threads) (execution-join thread))
           (is (not (eq (svref owners 0) (svref owners 1))))
           (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                    :writer-not-ready))
      (sb-thread:signal-semaphore first-go)
      (sb-thread:signal-semaphore second-go)
      (execution-stop-threads threads))))

(defun handoff-wave-items (series wave)
  "Identità e CRC atteso costruiti prima dei thread, lista nell'ordine accettato."
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 31) (* wave 7) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun handoff-wave-producer (writer messages permission published second-permission second-published)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait permission)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait second-permission)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore second-published)))
  :ok)

(defun handoff-wave-check-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4)
           (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun handoff-wave-consumer (writer messages permission taken finish drained results)
  (dotimes (wave (length messages))
    (execution-wait permission)
    (let* ((items (svref messages wave)) (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-wave-check-message writer lease (first items))
      (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
      (sb-thread:signal-semaphore taken)
      (execution-wait finish)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (loop for item in (rest (svref messages wave)) for last = (eq item (third (svref messages wave)))
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (handoff-wave-check-message writer lease item)
               (is (eq (if last :idle :schedule)
                       (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (setf (svref results wave) :verified)
    (sb-thread:signal-semaphore drained))
  :ok)

(defun handoff-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun handoff-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun handoff-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun handoff-start-four-workers (writers messages semaphores results)
  (let ((threads nil))
    (dotimes (series 2 threads)
      (let ((s series))
        (push (execution-thread
               "handoff reused producer"
               (lambda ()
                 (handoff-wave-producer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                  (svref (svref semaphores 4) s) (svref (svref semaphores 5) s)))) threads)
        (push (execution-thread
               "handoff reused consumer"
               (lambda ()
                 (handoff-wave-consumer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                  (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                  (svref results s)))) threads)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-handoff-reuses-four-workers-across-independent-series-waves
  (let* ((waves 6)
         (writers (vector (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)
                          (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (handoff-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (handoff-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (handoff-start-four-workers writers messages semaphores results))
           (is (= 4 (length threads)))
           (dotimes (wave waves)
             (handoff-pair-signal (svref semaphores 0))
             (handoff-pair-wait (svref semaphores 1))
             (handoff-pair-signal (svref semaphores 2))
             (handoff-pair-wait (svref semaphores 3))
             (handoff-pair-signal (svref semaphores 4))
             (handoff-pair-wait (svref semaphores 5))
             ;; FI: A conserva guard e lease; B termina due tratti aggiuntivi.
             (let ((queue-a (arcdocdb.execution::writer-programmabile-queue (svref writers 0))))
               (with-execution-guard (queue-a)
                 (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
                 (execution-wait (svref (svref semaphores 7) 1))
                 (is (eq :verified (svref (svref results 1) wave)))))
             (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
             (execution-wait (svref (svref semaphores 7) 0))
             (is (eq :verified (svref (svref results 0) wave))))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series)))
             (signals resource-exhausted
               (arcdocdb.execution:inizia-tratto-writer (svref writers series)) :writer-not-ready))
           (format t "  Handoff: 4 thread riusati, ~D ondate, ~D messaggi, 2 Serie indipendenti.~%"
                   waves (* waves 2 3)))
      (dotimes (i 8) (handoff-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))
