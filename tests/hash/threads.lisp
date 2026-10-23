(in-package #:arcdocdb.hash64.tests)

(defun hash-wait (semaphore label &optional (count 1))
  (unless (sb-thread:wait-on-semaphore semaphore :n count :timeout 5)
    (error "XXH64: attesa ~A oltre 5 secondi." label)))

(defun hash-cleanup-workers (threads joined)
  "Solo worker della fixture: termine degli eventuali superstiti e join limitato."
  (dolist (thread threads)
    (unless (member thread joined :test #'eq)
      (when (sb-thread:thread-alive-p thread)
        (handler-case (sb-thread:terminate-thread thread)
          (error (condition)
            ;; Il worker potrebbe essere terminato fra ALIVE-P e TERMINATE.
            (when (sb-thread:thread-alive-p thread) (error condition)))))
      (multiple-value-bind (result status)
          (sb-thread:join-thread thread :timeout 2 :default :cleanup)
        (declare (ignore result))
        (is (not (eq status :timeout)))))
    (is (not (sb-thread:thread-alive-p thread))))
  nil)

(defun hash-worker (id entry buffer start sizes seeds expected
                    ready start-gate entered work-gate)
  "Input, attesi e sink privati; i semafori sono le sole comunicazioni in corsa."
  (handler-case
      (progn
        (sb-thread:signal-semaphore ready)
        (hash-wait start-gate "start del worker")
        ;; Un risultato pubblico prima della seconda barriera: ciascuno dei quattro
        ;; thread ha davvero eseguito il kernel mentre gli altri sono ancora vivi.
        (hash-check-values
         (multiple-value-list (funcall entry buffer start start 0 0))
         (first (first expected)))
        (sb-thread:signal-semaphore entered)
        (hash-wait work-gate "fase di lavoro del worker")
        (let ((calls 1) (sink 0))
          (dotimes (round 2)
            (loop for size in sizes for digests in expected
                  do (loop for (high low) in seeds for digest in digests
                           do (let ((actual (multiple-value-list
                                             (funcall entry buffer start (+ start size) high low))))
                                (hash-check-values actual digest)
                                (setf sink (mod (+ (* sink 33) (first actual) (second actual))
                                                4294967296))
                                (incf calls)))))
          (list :ok id calls sink)))
    (error (condition) condition)))

;;; REQ: REQ-IDX-001 REQ-CON-005 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-four-real-workers-with-private-input-and-bounded-cleanup
  ;; 1220 chiamate totali, due passate finite. Nessuna misura prestazionale,
  ;; nessun requisito fragile di overlap dei tick, nessun oracle nei worker.
  (let* ((workers 4) (entry (hash-entry-point))
         (sizes '(0 1 3 4 7 8 15 16 23 24 31 32 33 63 64 65 257 1024 65535))
         (buffers (make-array workers)) (copies (make-array workers))
         (starts (vector 0 7 15 31)) (seeds (make-array workers))
         (expected (make-array workers)) (expected-sinks (make-array workers))
         (ready (sb-thread:make-semaphore)) (start-gate (sb-thread:make-semaphore))
         (entered (sb-thread:make-semaphore)) (work-gate (sb-thread:make-semaphore))
         (threads nil) (joined nil) (results nil))
    (dotimes (id workers)
      (let* ((contents (hash-corpus-bytes 65535 (+ #x64830000 id)))
             ;; Copie della lista di semi: ogni worker possiede anche i suoi attesi.
             (private-seeds (copy-tree *hash-seeds*)))
        (multiple-value-bind (buffer start end)
            (hash-fixture contents :prefix (svref starts id) :guard (+ #xa0 id))
          (declare (ignore end))
          (setf (svref buffers id) buffer (svref copies id) (copy-seq buffer)
                (svref seeds id) private-seeds
                (svref expected id)
                (loop for size in sizes
                      collect (loop for (high low) in private-seeds
                                    collect (hash-reference buffer start (+ start size) high low))))
          (let ((sink 0))
            (dotimes (round 2)
              (dolist (digests (svref expected id))
                (dolist (digest digests)
                  (setf sink (mod (+ (* sink 33) (first digest) (second digest)) 4294967296)))))
            (setf (svref expected-sinks id) sink)))))
    (dotimes (id workers)
      (dotimes (other id)
        (is (not (eq (svref buffers id) (svref buffers other))))
        (is (not (eq (svref seeds id) (svref seeds other))))))
    (unwind-protect
         (progn
           (dotimes (i workers)
             (let ((id i))
               (push (sb-thread:make-thread
                      (lambda ()
                        (hash-worker id entry (svref buffers id) (svref starts id)
                                     sizes (svref seeds id) (svref expected id)
                                     ready start-gate entered work-gate))
                      :name (format nil "XXH64 private worker ~D" id))
                     threads)))
           (is (= workers (length threads)))
           (hash-wait ready "ready dei quattro worker" workers)
           (is (every #'sb-thread:thread-alive-p threads))
           (sb-thread:signal-semaphore start-gate workers)
           (hash-wait entered "primo hash dei quattro worker" workers)
           (is (every #'sb-thread:thread-alive-p threads))
           (sb-thread:signal-semaphore work-gate workers)
           (dolist (thread threads)
             (multiple-value-bind (result status)
                 (sb-thread:join-thread thread :timeout 5 :default :join-timeout)
               (when (null status) (push thread joined))
               (is (null status))
               (when (typep result 'error) (error result))
               (push result results)))
           (is (= workers (length results)))
           (let ((seen nil) (calls 0))
             (dolist (result results)
               (destructuring-bind (status id count sink) result
                 (is (eq status :ok))
                 (is (and (typep id '(integer 0 3)) (not (member id seen))))
                 (push id seen)
                 (is (= count 305))
                 (is (= sink (svref expected-sinks id)))
                 (incf calls count)))
             (is (= calls 1220))
             (format t "  XXH64 thread: quattro worker privati, 1220 risultati, ready/join limitati.~%")))
      ;; Anche creation failure, timeout o errore del kernel liberano ogni gate.
      (sb-thread:signal-semaphore start-gate workers)
      (sb-thread:signal-semaphore work-gate workers)
      (hash-cleanup-workers threads joined)
      (dotimes (id workers)
        (is (equalp (svref buffers id) (svref copies id)))))))
