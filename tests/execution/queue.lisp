(in-package #:arcdocdb.execution.tests)

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-writer-configuration
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-coda-writer :capacity bad :quantum 3) :writer-configuration)
    (signals invalid-argument
      (arcdocdb.execution:crea-coda-writer :capacity 3 :quantum bad) :writer-configuration)))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-writer-defaults-and-configuration-boundaries
  (let ((queue (arcdocdb.execution:crea-coda-writer))
        (target (make-array 1024 :initial-element :untouched)))
    (dotimes (i 1024) (is (= (1+ i) (arcdocdb.execution:accoda-messaggio queue i))))
    (signals resource-exhausted (arcdocdb.execution:accoda-messaggio queue :extra)
             :writer-queue-full)
    (with-execution-lease (lease queue)
      (execution-check-pop queue lease target 0 1024 (loop for i below 64 collect i) :messages)
      (execution-check-pop queue lease target 0 1024 nil :yield))
    (is (equal (loop for i from 64 below 1024 collect i) (execution-drain queue 1024))))
  ;; I due massimi sono leciti anche quando capacity e quantum differiscono.
  (dolist (limits '((1 65536) (65536 1)))
    (let ((queue (arcdocdb.execution:crea-coda-writer
                  :capacity (first limits) :quantum (second limits))))
      (is (= 1 (arcdocdb.execution:accoda-messaggio queue :one)))
      (is (equal '(:one) (execution-drain queue 1))))))

;;; REQ: REQ-CON-001 REQ-CON-002
(deftest test-REQ-CON-001-writer-fifo-ring-wrap-and-nil
  (dolist (capacity '(1 2 3 7))
    (let ((queue (arcdocdb.execution:crea-coda-writer :capacity capacity :quantum 65536))
          (model nil) (serial 0) (target (make-array 3 :initial-element :untouched)))
      (dotimes (round 31)
        (loop repeat (- capacity (length model))
              for item = (if (zerop (mod serial 4)) nil (list serial))
              do (incf serial)
                 (setf model (append model (list item)))
                 (is (= (length model) (arcdocdb.execution:accoda-messaggio queue item))))
        (with-execution-lease (lease queue)
          (execution-check-pop queue lease target 1 2 (list (first model)) :messages))
        (setf model (rest model)))
      (is (equal model (execution-drain queue capacity))))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-writer-full-refusal-retains-payload
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 1))
         (a (vector :a)) (b (vector :b)) (rejected (vector :unaccepted))
         (before (copy-seq rejected)) (target (vector :untouched)))
    (is (= 1 (arcdocdb.execution:accoda-messaggio queue a)))
    (is (= 2 (arcdocdb.execution:accoda-messaggio queue b)))
    (signals resource-exhausted (arcdocdb.execution:accoda-messaggio queue rejected)
             :writer-queue-full)
    (is (equalp before rejected))
    (with-execution-lease (lease queue)
      (execution-check-pop queue lease target 0 1 (list a) :messages))
    (is (= 2 (arcdocdb.execution:accoda-messaggio queue rejected)))
    (is (equal (list b rejected) (execution-drain queue 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-writer-guard-busy-does-not-mutate
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 1))
         (item (vector :queued)) (refused (vector :caller-owned))
         (target (vector :left :right)) (before (copy-seq target)))
    (arcdocdb.execution:accoda-messaggio queue item)
    (with-execution-lease (lease queue)
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:accoda-messaggio queue refused)
                 :writer-queue-busy)
        (signals resource-exhausted
          (arcdocdb.execution:preleva-messaggi queue lease target 0 2) :writer-queue-busy)
        (is (equalp before target)) (is (equalp refused #(:caller-owned))))
      ;; Il tentativo rifiutato non ha consumato il quantum.
      (execution-check-pop queue lease target 0 2 (list item) :messages)
      (execution-check-pop queue lease target 0 2 nil :yield))
    (is (null (execution-drain queue 2)))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-CON-001-writer-target-subrange-and-empty
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 3 :quantum 8))
         (a (vector :a)) (b (vector :b)) (target (vector :l :x :y :r)))
    (arcdocdb.execution:accoda-messaggio queue a)
    (arcdocdb.execution:accoda-messaggio queue b)
    (with-execution-lease (lease queue)
      (execution-check-pop queue lease target 1 3 (list a b) :messages)
      (execution-check-pop queue lease target 1 3 nil :empty))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-writer-invalid-target-preflight
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 2))
         (item (vector :kept)) (target (vector :a :b :c)) (before (copy-seq target)))
    (arcdocdb.execution:accoda-messaggio queue item)
    (with-execution-lease (lease queue)
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-messaggi queue lease target (first range) (second range))
          :writer-target)
        (is (equalp before target)))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :caller)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-messaggi queue lease bad 0 1) :writer-target))
      (execution-check-pop queue lease target 1 3 (list item) :messages))))

;;; REQ: REQ-AFF-004 REQ-CON-001
(deftest test-REQ-AFF-004-writer-private-ring-alias-refused
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 3 :quantum 3))
         (a (vector :a)) (b (vector :b))
         (slots (arcdocdb.execution::coda-writer-slots queue)))
    ;; Solo accessor privato per FI alias, non oracolo dell'ordine o del contenuto.
    (arcdocdb.execution:accoda-messaggio queue a)
    (arcdocdb.execution:accoda-messaggio queue b)
    (let ((before (copy-seq slots)))
      (with-execution-lease (lease queue)
        (signals invalid-argument
          (arcdocdb.execution:preleva-messaggi queue lease slots 0 2) :writer-target)
        (is (equalp before slots))))
    (is (equal (list a b) (execution-drain queue 3)))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-CON-001-writer-lease-lifecycle
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 2))
         (target (vector :untouched)) (lease (arcdocdb.execution:acquisisci-writer queue)))
    (unwind-protect
         (progn
           (is (and (typep lease 'fixnum) (plusp lease)))
           (signals resource-exhausted (arcdocdb.execution:acquisisci-writer queue) :writer-busy)
           (dolist (bad (list 0 -1 nil :wrong (1+ most-positive-fixnum)))
             (signals invalid-argument
               (arcdocdb.execution:preleva-messaggi queue bad target 0 1) :writer-lease)
             (signals invalid-argument (arcdocdb.execution:rilascia-writer queue bad) :writer-lease))
           (is (equalp target #(:untouched)))
           (execution-check-pop queue lease target 0 1 nil :empty))
      (is (null (arcdocdb.execution:rilascia-writer queue lease))))
    (signals invalid-argument (arcdocdb.execution:rilascia-writer queue lease) :writer-lease)
    (signals invalid-argument
      (arcdocdb.execution:preleva-messaggi queue lease target 0 1) :writer-lease)))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-CON-001-writer-stale-lease-same-thread
  (let* ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 1))
         (old (arcdocdb.execution:acquisisci-writer queue)) (target (vector :untouched)))
    (arcdocdb.execution:rilascia-writer queue old)
    (arcdocdb.execution:accoda-messaggio queue :kept)
    (with-execution-lease (fresh queue)
      (is (> fresh old))
      (signals invalid-argument (arcdocdb.execution:rilascia-writer queue old) :writer-lease)
      (signals invalid-argument
        (arcdocdb.execution:preleva-messaggi queue old target 0 1) :writer-lease)
      (is (equalp target #(:untouched)))
      (signals resource-exhausted (arcdocdb.execution:acquisisci-writer queue) :writer-busy)
      (execution-check-pop queue fresh target 0 1 '(:kept) :messages))))

;;; REQ: REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-writer-quantum-is-cumulative-per-lease
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity 7 :quantum 3))
        (target (make-array 8 :initial-element :untouched)))
    (dotimes (i 7) (arcdocdb.execution:accoda-messaggio queue i))
    (with-execution-lease (lease queue)
      (execution-check-pop queue lease target 1 3 '(0 1) :messages)
      (execution-check-pop queue lease target 1 7 '(2) :messages)
      ;; Yield deve precedere perfino il tentativo della guardia della coda.
      (with-execution-guard (queue)
        (execution-check-pop queue lease target 1 7 nil :yield)))
    (with-execution-lease (lease queue)
      (execution-check-pop queue lease target 1 7 '(3 4 5) :messages)
      (execution-check-pop queue lease target 1 7 nil :yield))
    (is (equal '(6) (execution-drain queue 7))))
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity 1 :quantum 3))
        (target (vector :untouched)))
    (with-execution-lease (lease queue)
      (dotimes (i 3)
        (arcdocdb.execution:accoda-messaggio queue i)
        (execution-check-pop queue lease target 0 1 (list i) :messages))
      (arcdocdb.execution:accoda-messaggio queue :next-slice)
      (execution-check-pop queue lease target 0 1 nil :yield))
    (is (equal '(:next-slice) (execution-drain queue 1)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-writer-generation-does-not-wrap
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity 1 :quantum 1)))
    ;; Stato legale preparato su coda privata: nessun worker e nessun proprietario.
    ;; Non simula trilioni di acquisizioni né cambia un contatore vivo.
    (setf (arcdocdb.execution::coda-writer-generation queue) (1- most-positive-fixnum))
    (let ((last (arcdocdb.execution:acquisisci-writer queue)))
      (is (= last most-positive-fixnum))
      (arcdocdb.execution:rilascia-writer queue last))
    (dotimes (attempt 2)
      (signals resource-exhausted (arcdocdb.execution:acquisisci-writer queue) :writer-generation))
    (is (= most-positive-fixnum (arcdocdb.execution::coda-writer-generation queue)))
    (is (= 1 (arcdocdb.execution:accoda-messaggio queue :producer-still-independent)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-001-writer-seeded-list-oracle
  (let ((seed #x52c0317a))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((capacity (1+ (mod (next) 9))) (quantum (1+ (mod (next) 12)))
               (queue (arcdocdb.execution:crea-coda-writer :capacity capacity :quantum quantum))
               (model nil) (remaining quantum) (serial 0)
               (lease (arcdocdb.execution:acquisisci-writer queue)))
          (unwind-protect
               (dotimes (step 1200)
                 (case (mod (next) 4)
                   ((0 1)
                    (let ((item (if (zerop (mod serial 7)) nil (vector scenario serial))))
                      (incf serial)
                      (if (= (length model) capacity)
                          (signals resource-exhausted
                            (arcdocdb.execution:accoda-messaggio queue item) :writer-queue-full)
                          (progn (setf model (append model (list item)))
                                 (is (= (length model)
                                        (arcdocdb.execution:accoda-messaggio queue item)))))))
                   (2
                    (let* ((start (1+ (mod (next) 3))) (span (1+ (mod (next) 7)))
                           (target (make-array (+ start span 2) :initial-element :untouched))
                           (n (min remaining span (length model)))
                           (status (cond ((zerop remaining) :yield) ((zerop n) :empty)
                                         (t :messages))))
                      (execution-check-pop queue lease target start (+ start span)
                                           (subseq model 0 n) status)
                      (setf model (nthcdr n model)) (decf remaining n)))
                   (3
                    (arcdocdb.execution:rilascia-writer queue lease)
                    (let ((fresh (arcdocdb.execution:acquisisci-writer queue)))
                      (is (> fresh lease)) (setf lease fresh remaining quantum)))))
            (arcdocdb.execution:rilascia-writer queue lease))
          (is (equal model (execution-drain queue capacity))))))))
