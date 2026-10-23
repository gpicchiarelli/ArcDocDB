(in-package #:arcdocdb.get.directory.tests)

(defun directory-worker-thread (worker thunk)
  "Condizioni trasportate al controller e ripropagate soltanto dopo il join."
  (sb-thread:make-thread
   (lambda ()
     (handler-case (list :ok (funcall thunk)) (error (condition) (list :error condition))))
   :name (format nil "directory GET reader ~D" worker)))
(defun directory-join-thread (thread &optional (timeout 5))
  (let ((result (sb-thread:join-thread thread :timeout timeout :default :directory-join-timeout)))
    (when (eq result :directory-join-timeout)
      (error 'directory-fixture-timeout :reason :join))
    (when (eq :error (first result)) (error (second result)))
    (unless (eq :ok (first result)) (error 'directory-fixture-error :reason :thread-result))
    (second result)))
(defun directory-stop-threads (threads)
  "Cleanup eccezionale prima della chiusura dei FD; un solo terminate/join per thread."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 2 :default :directory-aborted-or-joined)
    (when (sb-thread:thread-alive-p thread)
      (error 'directory-fixture-timeout :reason :cleanup)))
  nil)
(defun directory-wait-gate (semaphore phase &optional (timeout 5))
  (unless (sb-thread:wait-on-semaphore semaphore :timeout timeout)
    (error 'directory-fixture-timeout :reason phase))
  t)
(defun directory-worker-buffers (fixture worker)
  "Identità degli scratch; controller prima dei thread, nessuna lettura concorrente."
  (let* ((context (aref (directory-fixture-contexts fixture) worker))
         (reader (g::contesto-get-reader context)) (probe (g::contesto-get-probe context)))
    (list (g::contesto-get-bytes context) (g::contesto-get-proof context)
          (g::contesto-get-content context) (g::contesto-get-limit context)
          (arcdocdb.read::contesto-lettura-words reader) (p::contesto-indice-words probe)
          (aref (directory-fixture-outputs fixture) worker))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-CCH-002 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-CON-004-directory-four-readers-private-output-pins-zero
  (dolist (version '(1 2))
    (dolist (cache-p '(nil t))
      (let ((fixture (make-directory-fixture :count 4 :workers 4 :version version
                                            :value-bytes 256 :cache-p cache-p :observe-io-p t))
            (threads nil) (start (sb-thread:make-semaphore)) (ready (sb-thread:make-semaphore)))
        (unwind-protect
             (progn
               (directory-register-snapshot fixture)
               (let ((buffers (loop for worker below 4 append (directory-worker-buffers fixture worker))))
                 (is (= 28 (length buffers)))
                 (is (= 28 (length (remove-duplicates buffers :test #'eq)))))
               (is (= 4 (length (remove-duplicates (coerce (directory-fixture-contexts fixture) 'list) :test #'eq))))
               (when cache-p
                 (dotimes (ordinal 4)
                   (is (equal '(:segment :miss :inserted nil nil)
                              (nth-value 2 (directory-checked-read fixture :ordinal ordinal))))))
               (directory-clear-read-events fixture)
               (dotimes (worker 4)
                 (let ((id worker))
                   (push (directory-worker-thread
                          id
                          (lambda ()
                            ;; Tutte le attese della fixture precedono il primo ingresso EBR.
                            (sb-thread:signal-semaphore ready)
                            (directory-wait-gate start :start)
                            (dotimes (operation 16)
                              (let ((ordinal (mod (+ id operation) 4)))
                                (is (equal (if cache-p '(:cache :hit :not-attempted nil nil)
                                               '(:segment :disabled :not-attempted nil nil))
                                           (nth-value 2 (directory-checked-read fixture :worker id :ordinal ordinal))))))
                            :completed))
                         threads)))
               (dotimes (worker 4) (directory-wait-gate ready :ready))
               (sb-thread:signal-semaphore start 4)
               (dolist (thread threads) (is (eq :completed (directory-join-thread thread))))
               ;; Contesti e output osservati dal controller solo dopo TUTTI i join.
               (dotimes (worker 4)
                 (is (directory-check-clean fixture worker))
                 (is (directory-check-output fixture worker (mod (+ worker 15) 4))))
               (is (= (if cache-p 0 64) (length (directory-read-events fixture))))
               (is (= 1 (nth-value 0 (m:leggi-registro-snapshot (directory-fixture-snapshots fixture))))))
          (sb-thread:signal-semaphore start 4)
          ;; Se stop/join fallisce, non toccare FD o contesti di un worker ancora vivo.
          (directory-stop-threads threads)
          (close-directory-fixture fixture))))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-CON-004-directory-thread-timeouts-and-condition-transfer
  ;; Una gate mai segnalata genera una condizione tipizzata; nessun ciclo d'attesa indefinito.
  (let ((gate (sb-thread:make-semaphore)) (threads nil))
    (unwind-protect
         (progn
           (push (directory-worker-thread 0 (lambda () (directory-wait-gate gate :start 0.02))) threads)
           (is (handler-case (progn (directory-join-thread (first threads)) nil)
                 (directory-fixture-timeout (condition)
                   (eq :start (directory-fixture-error-reason condition))))))
      (sb-thread:signal-semaphore gate)
      (directory-stop-threads threads)))
  ;; Timeout del join distinto dal timeout della gate; cleanup porta il thread a quiescenza.
  (let ((gate (sb-thread:make-semaphore)) (ready (sb-thread:make-semaphore)) (threads nil))
    (unwind-protect
         (progn
           (push (directory-worker-thread
                  1 (lambda () (sb-thread:signal-semaphore ready) (directory-wait-gate gate :start) :completed))
                 threads)
           (directory-wait-gate ready :ready)
           (is (handler-case (progn (directory-join-thread (first threads) 0.02) nil)
                 (directory-fixture-timeout (condition)
                   (eq :join (directory-fixture-error-reason condition)))))
           (sb-thread:signal-semaphore gate)
           (is (eq :completed (directory-join-thread (first threads)))))
      (sb-thread:signal-semaphore gate)
      (directory-stop-threads threads))))
