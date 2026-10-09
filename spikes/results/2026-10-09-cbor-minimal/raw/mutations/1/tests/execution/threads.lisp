(in-package #:arcdocdb.execution.tests)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-CON-001-writer-foreign-thread-cannot-use-lease
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 2)) (threads nil))
    (unwind-protect
         (with-execution-lease (lease queue)
           (push (execution-thread
                  "execution foreign owner"
                  (lambda ()
                    (let ((target (vector :untouched)))
                      (signals resource-exhausted (arcdocdb.execution:acquisisci-writer queue)
                               :writer-busy)
                      (signals invalid-argument
                        (arcdocdb.execution:preleva-messaggi queue lease target 0 1) :writer-lease)
                      (signals invalid-argument
                        (arcdocdb.execution:rilascia-writer queue lease) :writer-lease)
                      (is (equalp target #(:untouched)))
                      ;; Il producer non deve acquisire il gettone del writer.
                      (is (= 1 (arcdocdb.execution:accoda-messaggio queue :from-producer)))
                      :ok))) threads)
           (execution-join (first threads))
           (execution-check-pop queue lease (vector :untouched) 0 1 '(:from-producer) :messages))
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-CON-001-writer-cas-has-one-owner
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity 1 :quantum 1))
        (start (sb-thread:make-semaphore)) (outcome (sb-thread:make-semaphore))
        (release (sb-thread:make-semaphore)) (results (vector nil nil)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (i 2)
             (let ((index i))
               (push (execution-thread
                      "execution competing owner"
                      (lambda ()
                        (execution-wait start)
                        (let ((lease (handler-case (arcdocdb.execution:acquisisci-writer queue)
                                       (resource-exhausted (condition)
                                         (is (eq :writer-busy (error-reason condition))) nil))))
                          (if lease
                              (unwind-protect
                                   (progn (setf (svref results index) :owner)
                                          (sb-thread:signal-semaphore outcome)
                                          (execution-wait release))
                                (arcdocdb.execution:rilascia-writer queue lease))
                              (progn (setf (svref results index) :busy)
                                     (sb-thread:signal-semaphore outcome))))
                        :ok)) threads)))
           (sb-thread:signal-semaphore start 2)
           (dotimes (i 2) (execution-wait outcome))
           (is (= 1 (count :owner results))) (is (= 1 (count :busy results)))
           (sb-thread:signal-semaphore release)
           (dolist (thread threads) (execution-join thread))
           (with-execution-lease (lease queue) (is (plusp lease))))
      (sb-thread:signal-semaphore release)
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-002 REQ-CON-003 REQ-CON-005
(deftest test-REQ-CON-003-independent-series-progress-and-cpu-overlap
  (let* ((a (arcdocdb.execution:crea-coda-writer :capacity 1 :quantum 1))
         (b (arcdocdb.execution:crea-coda-writer :capacity 2 :quantum 1))
         (buffers (vector (execution-buffer 8192 17) (execution-buffer 8192 53)))
         (copies (map 'vector #'copy-seq buffers))
         (expected (map 'vector (lambda (buffer) (reference-crc buffer 0 (length buffer))) buffers))
         (a-ready (sb-thread:make-semaphore)) (b-progress (sb-thread:make-semaphore))
         (cpu-ready (sb-thread:make-semaphore)) (cpu-go (sb-thread:make-semaphore))
         (starts (vector 0 0)) (ends (vector 0 0)) (sinks (vector 0 0))
         (repetitions 64) (threads nil))
    (arcdocdb.execution:accoda-messaggio a (svref buffers 0))
    (arcdocdb.execution:accoda-messaggio b :progress)
    (arcdocdb.execution:accoda-messaggio b (svref buffers 1))
    (flet ((cpu-work (index)
             (sb-thread:signal-semaphore cpu-ready)
             (execution-wait cpu-go)
             ;; L'intervallo misurato contiene soltanto calcolo, dopo i semafori.
             (setf (svref starts index) (get-internal-real-time))
             (let ((buffer (svref buffers index)) (sink 0))
               (dotimes (i repetitions)
                 (setf sink (logand #xffffffff
                                    (+ sink (reference-crc buffer 0 (length buffer))))))
               (setf (svref sinks index) sink))
             (setf (svref ends index) (get-internal-real-time))
             :ok))
      (unwind-protect
           (progn
             (push (execution-thread
                    "execution serie A"
                    (lambda ()
                      (execution-wait a-ready)
                      (with-execution-lease (lease a)
                        (execution-check-pop a lease (vector nil) 0 1 (list (svref buffers 0)) :messages))
                      (cpu-work 0))) threads)
             (with-execution-lease (lease a)
               (with-execution-guard (a)
                 (push (execution-thread
                        "execution serie B"
                        (lambda ()
                          (with-execution-lease (other b)
                            (execution-check-pop b other (vector nil) 0 1 '(:progress) :messages))
                          (sb-thread:signal-semaphore b-progress)
                          (with-execution-lease (other b)
                            (execution-check-pop b other (vector nil) 0 1
                                                 (list (svref buffers 1)) :messages))
                          (cpu-work 1))) threads)
                 ;; B avanza mentre A conserva sia la guardia sia il gettone.
                 (execution-wait b-progress)))
             (sb-thread:signal-semaphore a-ready)
             (dotimes (i 2) (execution-wait cpu-ready))
             (sb-thread:signal-semaphore cpu-go 2)
             (dolist (thread threads) (execution-join thread))
             (dotimes (i 2)
               (is (> (svref ends i) (svref starts i)))
               (is (= (svref sinks i) (logand #xffffffff (* repetitions (svref expected i)))))
               (is (equalp (svref buffers i) (svref copies i))))
             (let ((overlap (- (min (svref ends 0) (svref ends 1))
                               (max (svref starts 0) (svref starts 1)))))
               (is (plusp overlap))
               (format t "  CPU due Serie: ~D byte, overlap ~D tick, unita ~D tick/s.~%"
                       (* 2 repetitions 8192) overlap internal-time-units-per-second)))
        (sb-thread:signal-semaphore a-ready)
        (sb-thread:signal-semaphore cpu-go 2)
        (execution-stop-threads threads)))))

(defun execution-concurrent-wave (wave)
  "Cinque worker riusati per tutti i messaggi, producer ancora aperti durante il drain."
  (let* ((producer-count 3) (consumer-count 2) (per-producer 48)
         (total (* producer-count per-producer))
         (queue (arcdocdb.execution:crea-coda-writer :capacity 7 :quantum 3))
         (messages (make-array producer-count)) (accepted (make-array producer-count :initial-element 0))
         (producer-ends (make-array producer-count :initial-element 0))
         (seen (make-array total :initial-element 0))
         (last-sequence (make-array producer-count :initial-element -1))
         (observed 0) (first-read 0) (record-lock (sb-thread:make-mutex))
         (start (sb-thread:make-semaphore)) (first-accepted (sb-thread:make-semaphore))
         (first-consumed (sb-thread:make-semaphore)) (continue (sb-thread:make-semaphore))
         (threads nil))
    ;; Identita, corpi ed esiti attesi sono preparati prima di creare i worker.
    (dotimes (producer producer-count)
      (let ((items (make-array per-producer)))
        (dotimes (sequence per-producer)
          (let ((buffer (execution-buffer 512 (+ (* producer 67) sequence (* wave 11)))))
            (setf (svref items sequence)
                  (vector producer sequence buffer (reference-crc buffer 0 (length buffer))))))
        (setf (svref messages producer) items)))
    (labels
        ((producer-work (producer)
           (execution-wait start)
           (let ((deadline (execution-deadline)))
             (dotimes (sequence per-producer)
               (let ((item (svref (svref messages producer) sequence)) (published nil))
                 (loop repeat 100000
                       do (execution-before-deadline deadline)
                          (let ((count (handler-case (arcdocdb.execution:accoda-messaggio queue item)
                                         (resource-exhausted (condition)
                                           (is (member (error-reason condition)
                                                       '(:writer-queue-busy :writer-queue-full))) nil))))
                            (when count
                              (is (<= 1 count 7)) (incf (svref accepted producer))
                              (setf published t) (return)))
                          (sb-thread:thread-yield))
                 (is published))
               (when (zerop sequence)
                 (sb-thread:signal-semaphore first-accepted)
                 (execution-wait continue)))
             (setf (svref producer-ends producer) (get-internal-real-time)))
           :ok)
         (consumer-work ()
           (execution-wait start)
           (let ((deadline (execution-deadline)) (target (make-array 5 :initial-element :untouched)))
             (loop repeat 600000
                   do (execution-before-deadline deadline)
                      (when (sb-thread:with-mutex (record-lock) (= observed total))
                        (return-from consumer-work :ok))
                      (let ((lease (handler-case (arcdocdb.execution:acquisisci-writer queue)
                                     (resource-exhausted (condition)
                                       (is (eq :writer-busy (error-reason condition))) nil))))
                        (when lease
                          (unwind-protect
                               (handler-case
                                   (multiple-value-bind (count status)
                                       (arcdocdb.execution:preleva-messaggi queue lease target 0 5)
                                     (is (<= 0 count 3))
                                     (is (eq status (if (plusp count) :messages :empty)))
                                     (dotimes (i count)
                                       (let* ((item (svref target i)) (producer (svref item 0))
                                              (sequence (svref item 1)) (buffer (svref item 2))
                                              (identity (+ (* producer per-producer) sequence)))
                                         (is (eq item (svref (svref messages producer) sequence)))
                                         ;; Calcolo reale fuori dalla guardia della coda; il gettone
                                         ;; conserva l'ordine di estrazione fra i due consumer.
                                         (is (= (svref item 3) (reference-crc buffer 0 (length buffer))))
                                         (sb-thread:with-mutex (record-lock)
                                           (is (= sequence (1+ (svref last-sequence producer))))
                                           (setf (svref last-sequence producer) sequence)
                                           (incf (svref seen identity)) (is (= 1 (svref seen identity)))
                                           (incf observed)
                                           (when (zerop first-read)
                                             (setf first-read (get-internal-real-time))))
                                         (when (zerop sequence)
                                           (sb-thread:signal-semaphore first-consumed)))))
                                 (resource-exhausted (condition)
                                   (is (eq :writer-queue-busy (error-reason condition)))))
                            (arcdocdb.execution:rilascia-writer queue lease))))
                      (sb-thread:thread-yield)
                   finally (error "Budget di retry consumer esaurito.")))))
      (unwind-protect
           (progn
             (dotimes (producer producer-count)
               (let ((index producer))
                 (push (execution-thread "execution producer" (lambda () (producer-work index))) threads)))
             (dotimes (consumer consumer-count)
               (push (execution-thread "execution consumer" #'consumer-work) threads))
             (is (= (+ producer-count consumer-count) (length threads)))
             (sb-thread:signal-semaphore start (+ producer-count consumer-count))
             (dotimes (producer producer-count) (execution-wait first-accepted))
             (dotimes (producer producer-count) (execution-wait first-consumed))
             (is (every (lambda (count) (= count 1)) accepted))
             (is (every #'zerop producer-ends))
             (sb-thread:with-mutex (record-lock) (is (= producer-count observed)))
             ;; Nessuna coda chiusa e pre-riempita: i tre producer devono ora
             ;; pubblicare ancora 47 messaggi ciascuno, sugli stessi worker.
             (sb-thread:signal-semaphore continue producer-count)
             (dolist (thread threads) (execution-join thread))
             (is (= total observed)) (is (every (lambda (count) (= count per-producer)) accepted))
             (is (every (lambda (count) (= count 1)) seen))
             (is (every (lambda (sequence) (= sequence (1- per-producer))) last-sequence))
             (is (every (lambda (end) (< first-read end)) producer-ends))
             (is (null (execution-drain queue 7)))
             (format t "  wave ~D: ~D messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.~%"
                     wave total)
             t)
        (sb-thread:signal-semaphore start (+ producer-count consumer-count))
        (sb-thread:signal-semaphore continue producer-count)
        (execution-stop-threads threads)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-001-writer-real-producers-consumers-and-worker-reuse
  (dotimes (wave 3) (is (execution-concurrent-wave wave))))
