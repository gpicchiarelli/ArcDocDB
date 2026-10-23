(in-package #:arcdocdb.read.tests)

(defun read-test-thread (name thunk)
  "Condizioni conservate come dato; il join del controller le ripropaga."
  (sb-thread:make-thread
   (lambda () (handler-case (list :ok (funcall thunk)) (error (condition) (list :error condition))))
   :name name))

(defun read-test-join (thread)
  (let ((result (sb-thread:join-thread thread :timeout 5 :default :read-test-timeout)))
    (when (eq result :read-test-timeout) (error 'fixture-timeout :phase :join))
    (when (eq :error (first result)) (error (second result)))
    (is (eq :ok (first result)))
    (second result)))

(defun read-test-stop-threads (threads)
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (when (eq :read-test-cleanup-timeout
              (sb-thread:join-thread thread :timeout 1 :default :read-test-cleanup-timeout))
      (error 'fixture-timeout :phase :cleanup))))

;;; REQ: REQ-CON-004 REQ-CMP-005 REQ-CMP-007 REQ-MVC-005
(deftest test-REQ-CON-004-read-two-worker-migration
  (with-read-fixture (csns snapshots snapshot epochs reader context) (:base 23)
    (let* ((second-reader (contesto-epoca epochs 1))
           (second-context (crea-contesto-lettura second-reader snapshots))
           (second-start (sb-thread:make-semaphore))
           (first-buffer (read-words)) (second-buffer (read-words))
           (threads nil) (first-thread nil) (second-thread nil))
      (registra-snapshot snapshot 10)
      (unwind-protect
           (progn
             (setf second-thread
                   (read-test-thread
                    "reader migrated worker"
                    (lambda ()
                      ;; Attesa prima dell'epoca; nessun semaforo o callback nel lookup.
                      (unless (sb-thread:wait-on-semaphore second-start :timeout 5)
                        (error 'fixture-timeout :phase :start))
                      (unwind-protect
                           (progn
                             (is (avvia-lettura second-context snapshot 1 13))
                             (is (copia-limite-lettura second-context second-buffer 1))
                             (is (= 23 (aref second-buffer 1)))
                             (concludi-lettura second-context 14))
                        (abbandona-lettura second-context))
                      :completed)))
             (push second-thread threads)
             (setf first-thread
                   (read-test-thread
                    "reader original worker"
                    (lambda ()
                      (unwind-protect
                           (progn
                             (is (avvia-lettura context snapshot 1 11))
                             (is (copia-limite-lettura context first-buffer 1))
                             (is (= 23 (aref first-buffer 1)))
                             ;; Nessuna location/epoca viene passata al nuovo worker.
                             (abbandona-lettura context))
                        (abbandona-lettura context))
                      :abandoned)))
             (push first-thread threads)
             (is (eq :abandoned (read-test-join first-thread)))
             ;; Il controller osserva il primo contesto soltanto dopo il join.
             (read-check-idle context reader)
             ;; Il secondo ingresso vede un'epoca realmente avanzata fra i due compiti.
             (multiple-value-bind (ticket generation) (prenota-ritiro epochs (vector :retired))
               (pubblica-ritiro ticket generation)
               (aggiorna-soglia-reclaim epochs)
               (is (acquisisci-reclaim ticket generation))
               (completa-reclaim ticket generation))
             (sb-thread:signal-semaphore second-start)
             (is (eq :completed (read-test-join second-thread)))
             (read-check-idle second-context second-reader)
             (is (= 23 (verifica-snapshot snapshot 1 15)))
             (is (= 1 (nth-value 0 (leggi-registro-snapshot snapshots)))))
        (sb-thread:signal-semaphore second-start)
        (read-test-stop-threads threads)
        (termina-snapshot snapshot 1)))))
