;;;; Ricircolo degli obblighi unici :schedule; il ring trasferisce un riferimento.
;;;; Oracoli pubblici: ogni writer pubblicato proviene da handoff ed è completato.
;;;; FI private e duplicati opachi sono dichiarati fuori dal protocollo handoff.
;;;; Thread/semafori/retry bounded appartengono soltanto alla fixture.
(in-package #:arcdocdb.execution.tests)

(defun recycle-check (ready shard writer expected expected-status expected-count)
  (multiple-value-bind (actual status count)
      (arcdocdb.execution:ricircola-writer-pronto ready shard writer)
    (is (eq actual expected))
    (is (eq status expected-status))
    (is (= count expected-count))
    actual))

(defun recycle-fi-complete (writer)
  "Completa il solo payload della fixture dopo il trasferimento al caller."
  (ready-complete-fixture-writer writer))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-001-recycle-room-publishes-and-preserves-fifo
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 3))
        (writers (vector (ready-prepare-fixture-writer)
                         (ready-prepare-fixture-writer)
                         (ready-prepare-fixture-writer))))
    (dotimes (i 3) (recycle-check ready 1 (svref writers i) nil :published (1+ i)))
    (dotimes (i 3) (ready-check-complete-take ready 0 (svref writers i) :writer 2))
    (ready-check-take ready 2 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-capacity-one-transfers-old-and-keeps-new
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (a (ready-test-writer)) (b (ready-test-writer)))
    (dotimes (wave 31)
      (ready-prepare-fixture-writer a)
      (ready-prepare-fixture-writer b)
      (recycle-check ready 0 a nil :published 1)
      (recycle-fi-complete (recycle-check ready 0 b a :writer 1))
      (ready-check-complete-take ready 0 b :writer 0)
      (ready-check-take ready 0 nil :empty 0))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-recycle-full-wrap-preserves-independent-list-order
  (dolist (capacity '(1 2 3 9))
    (dolist (shards '(1 4))
      (let ((ready (arcdocdb.execution:crea-lista-writer-pronti
                    :shards shards :capacity capacity))
            (model (make-array shards :initial-element nil)))
        (dotimes (shard shards)
          (dotimes (i capacity)
            (let ((writer (ready-prepare-fixture-writer)))
              (recycle-check ready shard writer nil :published (1+ i))
              (setf (svref model shard) (append (svref model shard) (list writer))))))
        (dotimes (round (+ 3 (* capacity 4)))
          (dotimes (shard shards)
            (let* ((writer (ready-prepare-fixture-writer))
                   (items (svref model shard)))
              (recycle-fi-complete
               (recycle-check ready shard writer (first items) :writer capacity))
              (setf (svref model shard) (append (rest items) (list writer))))))
        (dotimes (shard shards)
          (dolist (writer (svref model shard))
            (ready-check-complete-take ready shard writer :writer (mod (1+ shard) shards)))
          (setf (svref model shard) nil))
        (is (every #'null model))
        (ready-check-take ready 0 nil :empty (mod 1 shards))))))

(defun recycle-model-transfer (ready lists writers phases home index capacity)
  "FIFO attesa con liste; il risultato full diventa owned, il nuovo published."
  (let* ((writer (svref writers index)) (items (svref lists home))
         (full (= (length items) capacity)) (old (and full (first items))))
    (is (eq (svref phases index) :owned))
    (recycle-check ready home writer old (if full :writer :published)
                   (if full capacity (1+ (length items))))
    (setf (svref lists home) (append (if full (rest items) items) (list writer))
          (svref phases index) :published)
    (when old
      (let ((old-index (position old writers :test #'eq)))
        (is old-index)
        (is (eq (svref phases old-index) :published))
        (setf (svref phases old-index) :owned)))))

(defun recycle-model-enqueue (ready lists writers phases messages homes index payload capacity)
  "Un idle genera un solo obbligo; le altre fasi accettano senza ripubblicare."
  (let ((items (svref messages index)) (phase (svref phases index)))
    (when (< (length items) 3)
      (handoff-check-enqueue (svref writers index) payload (1+ (length items))
                             (if (eq phase :idle) :schedule :queued))
      (setf (svref messages index) (append items (list payload)))
      (when (eq phase :idle)
        (setf (svref phases index) :owned)
        (recycle-model-transfer ready lists writers phases (svref homes index) index capacity))
      t)))

(defun recycle-model-take (ready lists writers phases start)
  "La scelta viene dalle liste, senza head/tail/count o stato writer privati."
  (let ((shards (length lists)))
    (dotimes (distance shards)
      (let* ((home (mod (+ start distance) shards)) (items (svref lists home)))
        (when items
          (let ((index (position (first items) writers :test #'eq)))
            (is index) (is (eq (svref phases index) :published))
            (ready-check-take ready start (first items) :writer (mod (1+ home) shards))
            (setf (svref lists home) (rest items) (svref phases index) :owned)
            (return-from recycle-model-take index)))))
    (ready-check-take ready start nil :empty (mod (1+ start) shards))
    nil))

(defun recycle-model-process (ready lists writers phases messages homes index capacity)
  "Un quantum di un payload; ogni :schedule viene trasferito una sola volta."
  (when (eq (svref phases index) :owned)
    (let* ((writer (svref writers index)) (items (svref messages index))
           (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (is items)
      (handoff-check-pop writer lease (vector :left :untouched :right) 1 2
                         (list (first items)) :messages)
      (setf (svref messages index) (rest items))
      (let ((expected (if (rest items) :schedule :idle)))
        (is (eq expected (arcdocdb.execution:termina-tratto-writer writer lease)))
        (if (eq expected :schedule)
            (recycle-model-transfer ready lists writers phases (svref homes index) index capacity)
            (setf (svref phases index) :idle)))
      t)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-recycle-seeded-obligations-and-payloads-exactly-once
  (let ((seed #x1cf80d29))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dolist (capacity '(1 2 3 9))
        (dolist (shards '(1 4))
          (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti
                         :shards shards :capacity capacity))
                 (lists (make-array shards :initial-element nil))
                 (writers (make-array 11)) (phases (make-array 11 :initial-element :idle))
                 (messages (make-array 11 :initial-element nil)) (homes (make-array 11))
                 (accepted 0) (delivered 0))
            (dotimes (i 11)
              (setf (svref writers i) (ready-test-writer) (svref homes i) (mod i shards)))
            (dotimes (step 1000)
              (let ((index (mod (ash (next) -8) 11)))
                (case (mod (ash (next) -8) 4)
                  ((0 1)
                   (when (recycle-model-enqueue ready lists writers phases messages homes index
                                                (vector capacity shards step) capacity)
                     (incf accepted)))
                  (2 (when (recycle-model-process ready lists writers phases messages homes index
                                                  capacity)
                       (incf delivered)))
                  (3 (recycle-model-take ready lists writers phases
                                         (mod (ash (next) -8) shards))))))
            (loop repeat (1+ accepted)
                  for index = (or (position :owned phases)
                                  (recycle-model-take ready lists writers phases
                                                       (mod (next) shards)))
                  while index
                  do (is (recycle-model-process ready lists writers phases messages homes index
                                                capacity))
                     (incf delivered))
            (is (= accepted delivered))
            (is (every #'null lists)) (is (every #'null messages))
            (is (every (lambda (phase) (eq phase :idle)) phases))
            (ready-check-take ready 0 nil :empty (mod 1 shards))))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-all-consumers-reschedule-after-producer-refills-full
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (a (ready-test-writer)) (b (ready-test-writer))
         (c (ready-prepare-fixture-writer)) (d (ready-prepare-fixture-writer)))
    (dolist (writer (list a b))
      (handoff-check-enqueue writer :first 1 :schedule)
      (handoff-check-enqueue writer :second 2 :queued))
    (ready-check-publish ready 0 a 1) (ready-check-publish ready 0 b 2)
    (ready-check-take ready 0 a :writer 0) (ready-check-take ready 0 b :writer 0)
    (let ((lease-a (arcdocdb.execution:inizia-tratto-writer a))
          (lease-b (arcdocdb.execution:inizia-tratto-writer b)))
      (handoff-check-pop a lease-a (vector nil) 0 1 '(:first) :messages)
      (handoff-check-pop b lease-b (vector nil) 0 1 '(:first) :messages)
      (ready-check-publish ready 0 c 1) (ready-check-publish ready 0 d 2)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer a lease-a)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer b lease-b))))
    ;; Tutti i consumer hanno un obbligo; il retry del vecchio publish non drena.
    (let ((ring-before (ready-fi-snapshot (ready-test-partition ready 0)))
          (a-before (handoff-fi-snapshot a)) (b-before (handoff-fi-snapshot b)))
      (dolist (writer (list a b))
        (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
                 :ready-queue-full))
      (is (equalp ring-before (ready-fi-snapshot (ready-test-partition ready 0))))
      (is (equalp a-before (handoff-fi-snapshot a)))
      (is (equalp b-before (handoff-fi-snapshot b))))
    ;; Nessun dequeue aggiuntivo prima delle due rotazioni: C/D passano al caller.
    (recycle-fi-complete (recycle-check ready 0 a c :writer 2))
    (recycle-fi-complete (recycle-check ready 0 b d :writer 2))
    (dolist (writer (list a b))
      (ready-check-take ready 0 writer :writer 0)
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (handoff-check-pop writer lease (vector nil) 0 1 '(:second) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-busy-retains-obligation-and-both-ring-shapes
  (dolist (full '(nil t))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
           (old (and full (ready-prepare-fixture-writer)))
           (writer (ready-test-writer)) (partition (ready-test-partition ready 0)))
      (when old (ready-check-publish ready 0 old 1))
      (handoff-check-enqueue writer :one 1 :schedule)
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((ring-before (ready-fi-snapshot partition))
               (writer-before (handoff-fi-snapshot writer)))
           (signals resource-exhausted
             (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-busy)
           (is (equalp ring-before (ready-fi-snapshot partition)))
           (is (equalp writer-before (handoff-fi-snapshot writer))))))
      (handoff-check-enqueue writer :two 2 :queued)
      (recycle-check ready 0 writer old (if full :writer :published) 1)
      (when old (recycle-fi-complete old))
      (ready-check-take ready 0 writer :writer 0)
      (is (equal '(:one :two) (handoff-drain writer 2)))
      (ready-check-take ready 0 nil :empty 0))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-shard-writer-preflight-before-held-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writer (ready-prepare-fixture-writer)) (partition (ready-test-partition ready 1)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (let ((before (ready-fi-snapshot partition)))
         (dolist (bad (list -1 2 nil 1.0 (1+ most-positive-fixnum)))
           (signals invalid-argument
             (arcdocdb.execution:ricircola-writer-pronto ready bad writer) :ready-target))
         (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
           (signals invalid-argument
             (arcdocdb.execution:ricircola-writer-pronto ready 1 bad) :ready-writer))
         (is (equalp before (ready-fi-snapshot partition))))))
    (recycle-check ready 1 writer nil :published 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-private-ring-and-partition-shapes-pre-mutation
  ;; FI quiescente su ring sacrificati; mai oracolo del protocollo pubblico.
  (dolist (fault '(:capacity-zero :capacity-big :slots-length :head :tail :count :relation))
    (let* ((partition (ready-fi-bad-partition fault))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
           (writer (ready-prepare-fixture-writer)) (before (ready-fi-snapshot partition)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
      (is (equalp before (ready-fi-snapshot partition)))
      (recycle-fi-complete writer)))
  (dolist (partitions (list #() (make-array 65 :initial-element nil) (vector nil)))
    (let ((ready (arcdocdb.execution::%make-lista-writer-pronti partitions))
          (writer (ready-prepare-fixture-writer)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
      (recycle-fi-complete writer))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-malformed-full-head-and-free-tail-pre-mutation
  ;; FI: le celle del ring privato non rappresentano obblighi pubblici validi.
  (dolist (fault '(:full-nil :full-foreign :free-occupied))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
           (partition (ready-test-partition ready 0))
           (writer (ready-prepare-fixture-writer))
           (slots (arcdocdb.execution::partizione-pronta-slots partition)))
      (if (eq fault :free-occupied)
          (setf (svref slots 0) :occupied)
          (setf (arcdocdb.execution::partizione-pronta-count partition) 2
                (svref slots 0) (if (eq fault :full-nil) nil :foreign)
                (svref slots 1) (ready-test-writer)))
      (let ((before (ready-fi-snapshot partition)) (writer-before (handoff-fi-snapshot writer)))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
        (is (equalp before (ready-fi-snapshot partition)))
        (is (equalp writer-before (handoff-fi-snapshot writer))))
      (recycle-fi-complete writer)))
  ;; Precondizione del solo helper full, FI privata: un ring vuoto non si scambia.
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (partition (ready-test-partition ready 0)) (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (let ((before (ready-fi-snapshot partition)))
         (signals arcdocdb.conditions:invariant-violation
           (arcdocdb.execution::%scambia-pronto partition writer) :ready-recycle-full)
         (is (equalp before (ready-fi-snapshot partition))))))))

(defun recycle-check-unowned-helper (partition writer)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%ricircola-pronto partition writer) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%scambia-pronto partition writer) :ready-queue-guard))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-helper-rejects-missing-and-foreign-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (partition (ready-test-partition ready 0)) (writer (ready-prepare-fixture-writer))
         (before (ready-fi-snapshot partition)) (threads nil))
    (recycle-check-unowned-helper partition writer)
    (unwind-protect
         (ready-call-with-guards
          (list partition)
          (lambda ()
            (push (execution-thread
                   "recycle foreign guard"
                   (lambda () (recycle-check-unowned-helper partition writer) :ok)) threads)
            (execution-join (first threads))))
      (execution-stop-threads threads))
    (is (equalp before (ready-fi-snapshot partition)))
    (recycle-check ready 0 writer nil :published 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-004
(deftest test-REQ-CON-001-recycle-private-opaque-duplicate-is-outside-handoff-protocol
  ;; FI esclusivamente del helper: due riferimenti allo stesso writer violano
  ;; il protocollo handoff. Questo prova opacità del ring, non membership/dedup.
  (let ((partition (arcdocdb.execution::%make-partizione-pronta (vector nil) 1))
        (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (multiple-value-bind (actual status count)
           (arcdocdb.execution::%ricircola-pronto partition writer)
         (is (null actual)) (is (eq status :published)) (is (= count 1)))
       (multiple-value-bind (actual status count)
           (arcdocdb.execution::%ricircola-pronto partition writer)
         (is (eq actual writer)) (is (eq status :writer)) (is (= count 1)))
       (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
         (is (eq actual writer)) (is (eq status :writer)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-recycle-handoff-before-release-and-new-wave-without-cleanup
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3)))
    (dotimes (wave 4)
      (let ((first (vector wave :first)) (before (vector wave :before))
            (after (vector wave :after)) (blocker (ready-prepare-fixture-writer)))
        (handoff-check-enqueue writer first 1 :schedule)
        (recycle-check ready 0 writer nil :published 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list first) :messages)
          (handoff-check-pop writer lease (vector nil) 0 1 nil :empty)
          (handoff-check-enqueue writer before 1 :queued)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
        (recycle-check ready 0 blocker nil :published 1)
        (recycle-fi-complete (recycle-check ready 0 writer blocker :writer 1))
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list before) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        ;; Nessun cleanup del vecchio worker cancella il nuovo obbligo.
        (handoff-check-enqueue writer after 1 :schedule)
        (recycle-check ready 0 writer nil :published 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list after) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-take ready 0 nil :empty 0)))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-returned-obligation-survives-begin-busy
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (old (ready-prepare-fixture-writer)) (new (ready-prepare-fixture-writer))
         (queue (arcdocdb.execution::writer-programmabile-queue old)))
    (recycle-check ready 0 old nil :published 1)
    (let ((owned (recycle-check ready 0 new old :writer 1)))
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer owned)
                 :writer-queue-busy))
      ;; Il riferimento old resta al caller; new resta nel ring senza ripubblicare old.
      (recycle-fi-complete owned)
      (ready-check-complete-take ready 0 new :writer 0))
    (ready-check-take ready 0 nil :empty 0)))

(defun recycle-wave-pop (writer expected expected-end)
  (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
    (ready-read-message writer lease expected)
    (is (eq expected-end (arcdocdb.execution:termina-tratto-writer writer lease)))))

(defun recycle-wave-message (wave writer sequence)
  (let ((buffer (execution-buffer 256 (+ (* wave 13) (* writer 31) sequence))))
    (vector writer wave sequence buffer (reference-crc buffer 0 256))))

(defun recycle-wave-consumer (ready writers messages semaphores attempts returned drained index waves)
  (dotimes (wave waves)
    (execution-wait (svref (svref semaphores 0) index))
    (let* ((writer (svref writers index))
           (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (ready-read-message writer lease (svref (svref messages wave) (* index 2)))
      (sb-thread:signal-semaphore (svref (svref semaphores 1) index))
      (execution-wait (svref (svref semaphores 2) index))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease)))
      (let ((owned nil))
        (dotimes (attempt 2)
          (when (plusp attempt) (execution-wait (svref (svref semaphores 2) index)))
          (handler-case
              (multiple-value-bind (actual status count)
                  (arcdocdb.execution:ricircola-writer-pronto ready 0 writer)
                (is (eq status :writer)) (is (= count 2))
                (is (member actual (list (svref writers 2) (svref writers 3)) :test #'eq))
                (setf owned actual (svref attempts index) :writer))
            (resource-exhausted (condition)
              (is (eq (error-reason condition) :ready-queue-busy))
              (setf (svref attempts index) :busy)))
          (sb-thread:signal-semaphore (svref (svref semaphores 3) index))
          (when owned (return)))
        (is owned)
        (let ((old-index (position owned writers :test #'eq)))
          (setf (svref returned index) owned)
          (recycle-wave-pop owned (svref (svref messages wave) (+ 4 (- old-index 2))) :idle)))
      (sb-thread:signal-semaphore (svref (svref semaphores 4) index)))
    ;; I drain sono autorizzati separatamente: la competizione misurata è FULL recycle.
    (execution-wait (svref (svref semaphores 5) index))
    (multiple-value-bind (writer status next) (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (eq status :writer)) (is (zerop next))
      (let ((old-index (position writer writers :test #'eq)))
        (is (member old-index '(0 1)))
        (setf (svref drained index) writer)
        (recycle-wave-pop writer (svref (svref messages wave) (1+ (* old-index 2))) :idle)))
    (sb-thread:signal-semaphore (svref (svref semaphores 6) index)))
  :ok)

(defun recycle-wave-producer (ready writers messages go filled finish waves)
  (dotimes (wave waves)
    (execution-wait go)
    (dotimes (i 2)
      (let ((writer (svref writers (+ 2 i))))
        (handoff-check-enqueue writer (svref (svref messages wave) (+ 4 i)) 1 :schedule)
        (ready-check-publish ready 0 writer (1+ i))))
    (sb-thread:signal-semaphore filled))
  (execution-wait finish)
  :ok)

(defun recycle-wave-drive (ready writers messages semaphores attempts returned drained
                          producer go filled wave)
  (dotimes (i 2)
    (let ((writer (svref writers i)))
      (handoff-check-enqueue writer (svref (svref messages wave) (* i 2)) 1 :schedule)
      (handoff-check-enqueue writer (svref (svref messages wave) (1+ (* i 2))) 2 :queued)
      (ready-check-publish ready 0 writer (1+ i))))
  ;; Il main trasferisce due riferimenti distinti ai consumer, prima del refill.
  (dotimes (i 2) (ready-check-take ready 0 (svref writers i) :writer 0))
  (ready-pair-signal (svref semaphores 0)) (ready-pair-wait (svref semaphores 1))
  (sb-thread:signal-semaphore go) (execution-wait filled)
  (is (sb-thread:thread-alive-p producer))
  (ready-pair-signal (svref semaphores 2)) (ready-pair-wait (svref semaphores 3))
  (is (<= (count :busy attempts) 1))
  (dotimes (i 2)
    (when (eq (svref attempts i) :busy)
      (sb-thread:signal-semaphore (svref (svref semaphores 2) i))
      (execution-wait (svref (svref semaphores 3) i))))
  (ready-pair-wait (svref semaphores 4))
  (is (every (lambda (status) (eq status :writer)) attempts))
  (is (not (eq (svref returned 0) (svref returned 1))))
  (dotimes (i 2)
    (sb-thread:signal-semaphore (svref (svref semaphores 5) i))
    (execution-wait (svref (svref semaphores 6) i)))
  (is (not (eq (svref drained 0) (svref drained 1))))
  (ready-check-take ready 0 nil :empty 0))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-recycle-two-competing-consumers-and-live-producer-reused
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (writers (vector (ready-test-writer) (ready-test-writer)
                          (ready-test-writer) (ready-test-writer)))
         (messages (make-array waves)) (semaphores (make-array 7))
         (attempts (vector nil nil)) (returned (vector nil nil)) (drained (vector nil nil))
         (go (sb-thread:make-semaphore)) (filled (sb-thread:make-semaphore))
         (finish (sb-thread:make-semaphore)) (threads nil) (producer nil))
    (dotimes (i 7) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (wave waves)
      (setf (svref messages wave)
            (vector (recycle-wave-message wave 0 0) (recycle-wave-message wave 0 1)
                    (recycle-wave-message wave 1 0) (recycle-wave-message wave 1 1)
                    (recycle-wave-message wave 2 0) (recycle-wave-message wave 3 0))))
    (unwind-protect
         (progn
           (setf producer (execution-thread
                           "recycle live reused producer"
                           (lambda () (recycle-wave-producer ready writers messages
                                                             go filled finish waves))))
           (push producer threads)
           (dotimes (i 2)
             (let ((index i))
               (push (execution-thread
                      "recycle competing reused consumer"
                      (lambda () (recycle-wave-consumer ready writers messages semaphores
                                                       attempts returned drained index waves))) threads)))
           (dotimes (wave waves)
             (recycle-wave-drive ready writers messages semaphores attempts returned drained
                                 producer go filled wave))
           (sb-thread:signal-semaphore finish)
           (dolist (thread threads) (execution-join thread))
           (format t "  Recycle: 3 thread riusati, ~D ondate, ~D payload, ready FULL e busy bounded.~%"
                   waves (* 6 waves)))
      (dotimes (i 7) (ready-pair-signal (svref semaphores i)))
      (sb-thread:signal-semaphore go) (sb-thread:signal-semaphore finish)
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-recycle-other-shard-progresses-while-first-guard-is-held
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (old-a (ready-prepare-fixture-writer)) (old-b (ready-prepare-fixture-writer))
         (new-a (ready-prepare-fixture-writer)) (new-b (ready-prepare-fixture-writer))
         (home-a (ready-test-partition ready 0)) (threads nil))
    (ready-check-publish ready 0 old-a 1) (ready-check-publish ready 1 old-b 1)
    (unwind-protect
         (ready-call-with-guards
          (list home-a)
          (lambda ()
            (let ((before (ready-fi-snapshot home-a)) (writer-before (handoff-fi-snapshot new-a)))
              (push (execution-thread
                     "recycle independent shard"
                     (lambda ()
                       (signals resource-exhausted
                         (arcdocdb.execution:ricircola-writer-pronto ready 0 new-a)
                         :ready-queue-busy)
                       (recycle-fi-complete (recycle-check ready 1 new-b old-b :writer 1))
                       (ready-check-complete-take ready 1 new-b :writer 0)
                       :ok)) threads)
              (execution-join (first threads))
              (is (equalp before (ready-fi-snapshot home-a)))
              (is (equalp writer-before (handoff-fi-snapshot new-a))))))
      (execution-stop-threads threads))
    (recycle-fi-complete (recycle-check ready 0 new-a old-a :writer 1))
    (ready-check-complete-take ready 0 new-a :writer 1)
    (ready-check-take ready 0 nil :empty 1)))
