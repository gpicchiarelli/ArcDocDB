(in-package #:arcdocdb.get.performance.tests)

(defun performance-worker-thread (worker thunk)
  "Ogni errore viaggia al controller come dato e viene ripropagato dopo join."
  (sb-thread:make-thread
   (lambda ()
     (handler-case (list :ok (funcall thunk)) (error (condition) (list :error condition))))
   :name (format nil "GET performance shared reader ~D" worker)))

(defun performance-join-thread (thread)
  (let ((result (sb-thread:join-thread thread :timeout 5 :default :performance-join-timeout)))
    (when (eq result :performance-join-timeout)
      (error 'performance-fixture-timeout :phase :join))
    (when (eq (first result) :error) (error (second result)))
    (is (eq :ok (first result)))
    (second result)))

(defun performance-stop-threads (threads)
  "Cleanup eccezionale prima di chiudere il FD; nessun file chiuso sotto un reader vivo."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    ;; DEFAULT copre anche l'uscita abortita; controllare la quiescenza effettiva.
    (sb-thread:join-thread thread :timeout 2 :default :performance-joined-or-aborted)
    (when (sb-thread:thread-alive-p thread)
      (error 'performance-fixture-timeout :phase :cleanup))))

(defun performance-worker-buffers (fixture worker)
  "Audit statico delle identità degli scratch prima dei thread, nessun oracolo di valore privato."
  (let* ((context (aref (get-performance-fixture-contexts fixture) worker))
         (reader (g::contesto-get-reader context))
         (probe (g::contesto-get-probe context)))
    (list (g::contesto-get-bytes context) (g::contesto-get-proof context)
          (g::contesto-get-content context) (g::contesto-get-limit context)
          (arcdocdb.read::contesto-lettura-words reader) (p::contesto-indice-words probe)
          (aref (get-performance-fixture-outputs fixture) worker))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-CCH-002 REQ-AFF-002
(deftest test-REQ-CON-004-performance-shared-readers4
  (dolist (version '(1 2))
    (dolist (cache-p '(nil t))
      (let ((fixture (make-get-performance-fixture
                      :version version :value-bytes 4096 :workers 4 :cache-p cache-p
                      :csn (if cache-p +performance-max-csn+ 7) :snapshot-p t :observe-io-p nil))
            (threads nil) (start (sb-thread:make-semaphore)))
        (unwind-protect
             (let ((buffers (loop for worker below 4 append (performance-worker-buffers fixture worker)))
                   (ready (sb-thread:make-semaphore)))
               (when cache-p (performance-warm-cache fixture))
               (is (= 28 (length buffers)))
               (is (= 28 (length (remove-duplicates buffers :test #'eq))))
               (is (= 4 (length (remove-duplicates
                                (coerce (get-performance-fixture-contexts fixture) 'list) :test #'eq))))
               (dotimes (worker 4)
                 (let ((id worker))
                   (push (performance-worker-thread
                          id
                          (lambda ()
                            ;; La sola attesa della fixture è PRIMA dell'EBR.
                            (sb-thread:signal-semaphore ready)
                            (unless (sb-thread:wait-on-semaphore start :timeout 5)
                              (error 'performance-fixture-timeout :phase :start))
                            (dotimes (operation 16)
                              (performance-checked-get fixture :worker id
                                                      :path (if cache-p :cache-record :file)))
                            :completed))
                         threads)))
               (dotimes (worker 4)
                 (unless (sb-thread:wait-on-semaphore ready :timeout 5)
                   (error 'performance-fixture-timeout :phase :ready)))
               (sb-thread:signal-semaphore start 4)
               (dolist (thread threads) (is (eq :completed (performance-join-thread thread))))
               ;; Ogni osservazione del controller sui contesti è dopo TUTTI i join.
               (dotimes (worker 4)
                 (performance-check-unpinned fixture worker)
                 (performance-check-response fixture (aref (get-performance-fixture-outputs fixture) worker)))
               (is (= 1 (nth-value 0 (m:leggi-registro-snapshot
                                      (get-performance-fixture-snapshots fixture))))))
          (sb-thread:signal-semaphore start 4)
          ;; Se stop/join fallisce, lasciare il FD e i contesti al runner isolato:
          ;; il cleanup non deve toccare le risorse di un worker ancora vivo.
          (performance-stop-threads threads)
          (close-get-performance-fixture fixture))))))
