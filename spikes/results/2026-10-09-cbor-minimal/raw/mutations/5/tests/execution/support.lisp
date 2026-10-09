;;;; Oracoli della coda writer; nessuna dipendenza dalla rappresentazione del ring.
(defpackage #:arcdocdb.execution.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals #:reference-crc)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.execution.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test delle code writer superati.~%" (length *tests*))
  t)

(defmacro with-execution-lease ((lease queue) &body body)
  (let ((q (gensym "QUEUE")))
    `(let* ((,q ,queue)
            (,lease (arcdocdb.execution:acquisisci-writer ,q)))
       (unwind-protect (progn ,@body)
         (arcdocdb.execution:rilascia-writer ,q ,lease)))))

(defmacro with-execution-guard ((queue) &body body)
  "FI dichiarata: prende e restituisce la guardia con gli stessi CAS del contratto."
  (let ((q (gensym "QUEUE")) (owner (gensym "OWNER")))
    `(let ((,q ,queue) (,owner sb-thread:*current-thread*))
       (is (null (sb-ext:compare-and-swap
                  (arcdocdb.execution::coda-writer-guard ,q) nil ,owner)))
       (unwind-protect (progn ,@body)
         (is (eq ,owner (sb-ext:compare-and-swap
                          (arcdocdb.execution::coda-writer-guard ,q) ,owner nil)))))))

(defun execution-check-pop (queue lease target start end expected status)
  "Lista attesa indipendente; nessuna lettura di head/count/slot del prodotto."
  (let ((before (copy-seq target)))
    (multiple-value-bind (count actual-status)
        (arcdocdb.execution:preleva-messaggi queue lease target start end)
      (is (= count (length expected)))
      (is (eq actual-status status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      count)))

(defun execution-drain (queue maximum)
  "Drain bornato per gli oracoli sequenziali: rinnova il quantum fra i tratti."
  (let ((target (make-array (max 1 maximum) :initial-element :untouched)) (items nil))
    (loop repeat (1+ maximum)
          do (with-execution-lease (lease queue)
               (multiple-value-bind (count status)
                   (arcdocdb.execution:preleva-messaggi queue lease target 0 (length target))
                 (is (<= 0 count (length target)))
                 (case status
                   (:messages
                    (is (plusp count))
                    (dotimes (i count) (push (svref target i) items)))
                   (:empty (is (zerop count)) (return-from execution-drain (nreverse items)))
                   (otherwise (error "Statuto inatteso nel primo prelievo: ~S" status)))))
          finally (error "Il drain dell'oracolo ha superato il limite."))))

(defun execution-wait (semaphore &optional (seconds 15))
  (unless (sb-thread:wait-on-semaphore semaphore :timeout seconds)
    (error "Attesa della fixture oltre il limite."))
  t)

(defun execution-thread (name thunk)
  "Gli errori restano risultati del worker e vengono rilanciati dal join."
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

(defun execution-join (thread &optional (seconds 20))
  (let ((result (sb-thread:join-thread thread :timeout seconds :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq result :ok))
    result))

(defun execution-stop-threads (threads)
  "Cleanup solo della fixture, anche dopo timeout o asserzioni del thread principale."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread)
      (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated))
  nil)

(defun execution-buffer (size seed)
  (let ((buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf (aref buffer i) (logand #xff (+ (* i 29) seed))))))

(defun execution-deadline (&optional (seconds 15))
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun execution-before-deadline (deadline)
  (when (>= (get-internal-real-time) deadline)
    (error "Budget temporale della fixture esaurito.")))
