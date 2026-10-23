;;;; Due worker con ready/routing condivisi: lease distinte e migrazione dopo ritiro.
;;;; Le attese artificiali con lease/debito sono esclusivamente controlli C4.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-chain-independent (held-phase)
  (multiple-value-bind (left left-file) (pool-claim-series 91)
    (multiple-value-bind (right right-file) (pool-claim-series 92)
      (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
             (a (pool-chain-writer 2 0)) (b (pool-chain-writer 32 1))
             (registry (arcdocdb.execution.series:crea-registro-worker-serie
                        (vector a b) (vector left right)))
             (coordinator sb-thread:*current-thread*)
             (held (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
             (threads nil) (fast nil))
        (unwind-protect
             (progn
               (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 a)))
               (is (= 2 (arcdocdb.execution:pubblica-writer-pronto ready 0 b)))
               (push
                (pool-thread
                 "pool-chain-held"
                 (lambda ()
                   (multiple-value-bind (context port dispatcher)
                       (pool-chain-local ready registry coordinator)
                     (declare (ignore port))
                     (let* ((link (pool-chain-take dispatcher context a :claim 0))
                            (token (pool-chain-begin dispatcher link))
                            (batch (when (eq held-phase :batch)
                                     (pool-claim-bridge-pop link token 0))))
                       (is (eq held-phase (arcdocdb.execution:stato-worker-writer context)))
                       (sb-thread:signal-semaphore held)
                       (pool-wait release)
                       ;; B è già joined: nessuna release di A poteva abilitarlo.
                       (unless batch (setf batch (pool-claim-bridge-pop link token 0)))
                       (pool-chain-ack-end context link token batch :schedule))
                     (pool-chain-published dispatcher 1)
                     (pool-chain-finish dispatcher context
                                        (pool-chain-take dispatcher context a :claim 0) 1 :idle)
                     (pool-chain-empty dispatcher context 0)
                     :ok))) threads)
               (pool-wait held)
               (setf fast
                     (pool-thread
                      "pool-chain-progress"
                      (lambda ()
                        (multiple-value-bind (context port dispatcher)
                            (pool-chain-local ready registry coordinator)
                          (declare (ignore port))
                          (dotimes (index 32)
                            (pool-chain-finish
                             dispatcher context (pool-chain-take dispatcher context b :claim 0)
                             index (if (= index 31) :idle :schedule))
                            (unless (= index 31) (pool-chain-published dispatcher 1)))
                          (pool-chain-empty dispatcher context 0)
                          :ok))))
               (push fast threads)
               (pool-join fast)
               (sb-thread:signal-semaphore release)
               (pool-join (second threads))
               (format t "  pool-chain: A ~S, B 32 quantum conclusi prima della release A.~%"
                       held-phase))
          (sb-thread:signal-semaphore release)
          (pool-stop-threads threads)
          (arcdocdb.io:chiudi right-file) (arcdocdb.io:chiudi left-file))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-chain-other-series-completes-before-held-lease-and-batch-release
  (dolist (phase '(:running :batch)) (pool-chain-independent phase)))

(defun pool-chain-retiring-worker (ready routing writers coordinator ports started staged resume home full)
  (multiple-value-bind (context port dispatcher)
      (pool-chain-local ready routing coordinator home)
    (setf (svref ports 1) port)
    (sb-thread:signal-semaphore started)
    (pool-wait resume)
    (let ((link (pool-chain-take dispatcher context (svref writers 0)
                                 :claim (mod (1+ home) 3))))
      (pool-chain-finish dispatcher context link :a1 :schedule))
    (sb-thread:signal-semaphore staged)
    (pool-wait resume)
    (if full
        (pool-chain-finish
         dispatcher context
         (pool-chain-take dispatcher context (svref writers 1) :recycle 1) :b1 :idle)
        (pool-chain-published dispatcher 2))
    (pool-step-check dispatcher nil :inactive :claim (mod (1+ home) 3) :retired)
    (pool-step-check dispatcher nil :inactive :claim (mod (1+ home) 3) :unchanged)
    (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
    (is (null (arcdocdb.execution:errore-worker-writer context)))
    :ok))

(defun pool-chain-retirement (capacity home)
  (multiple-value-bind (left left-file) (pool-claim-series 93)
    (multiple-value-bind (right right-file) (pool-claim-series 94)
      (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity capacity))
             (a (pool-claim-writer '(:a1 :a2) 0)) (b (pool-claim-writer '(:b1) 1))
             (routing (arcdocdb.execution.series:crea-registro-worker-serie
                       (vector a b) (vector left right)))
             (coordinator sb-thread:*current-thread*) (ports (vector nil nil))
             (started (sb-thread:make-semaphore)) (staged (sb-thread:make-semaphore))
             (resume (sb-thread:make-semaphore)) (take-over (sb-thread:make-semaphore))
             (threads nil) (retiring nil) (remaining nil))
        (unwind-protect
             (progn
               (setf remaining
                     (pool-thread
                      "pool-chain-take-over"
                      (lambda ()
                        (multiple-value-bind (context port dispatcher)
                            (pool-chain-local ready routing coordinator home)
                          (setf (svref ports 0) port)
                          (sb-thread:signal-semaphore started)
                          (pool-wait take-over)
                          (when (= capacity 2)
                            (pool-chain-finish
                             dispatcher context
                             (pool-chain-take dispatcher context b :claim (mod (1+ home) 3))
                             :b1 :idle))
                          (pool-chain-finish
                           dispatcher context
                           (pool-chain-take dispatcher context a :claim (mod (1+ home) 3))
                           :a2 :idle)
                          (pool-chain-empty dispatcher context (mod (+ home 2) 3))
                          :ok))))
               (push remaining threads)
               (setf retiring
                     (pool-thread
                      "pool-chain-retire"
                      (lambda () (pool-chain-retiring-worker
                                  ready routing (vector a b) coordinator ports started staged resume home
                                  (= capacity 1)))))
               (push retiring threads)
               (pool-wait started 2)
               (let* ((controller (crea-controllore-pool 1 :initial 2 :dwell 500))
                      (registry (arcdocdb.scheduler:crea-registro-pool controller ports)))
                 (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready home a)))
                 (sb-thread:signal-semaphore resume)
                 (pool-wait staged)
                 (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready home b)))
                 (lifecycle-start-retirement controller registry)
                 (sb-thread:signal-semaphore resume)
                 (pool-join retiring)
                 (is (equal '(1 1 nil) (lifecycle-registry-state registry)))
                 (sb-thread:signal-semaphore take-over)
                 (pool-join remaining)
                 (is (equal '(1 1 nil) (lifecycle-registry-state registry)))
                 (format t "  pool-chain: capacity ~D, home ~D, ~A, ritiro e handoff conclusi.~%"
                         capacity home (if (= capacity 1) :full :room))))
          (sb-thread:signal-semaphore resume 2)
          (sb-thread:signal-semaphore take-over)
          (pool-stop-threads threads)
          (arcdocdb.io:chiudi right-file) (arcdocdb.io:chiudi left-file))))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-THR-001-pool-chain-full-room-retirement-and-cross-worker-ready-handoff
  (dolist (capacity '(1 2))
    (dolist (home '(0 2)) (pool-chain-retirement capacity home))))
