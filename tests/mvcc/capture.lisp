;;;; Iniezioni seriali sulle catture; le funzioni originali sono sempre ripristinate.
(in-package #:arcdocdb.mvcc.tests)

(define-condition capture-fixture-timeout (error) ()
  (:report (lambda (condition stream)
             (declare (ignore condition)) (write-string "Deadline della fixture snapshot." stream))))

(defun capture-call-with-function (symbol replacement thunk)
  "FI dell'harness seriale: nessun consumer concorrente usa l'adapter sostituito."
  (let ((original (symbol-function symbol)))
    (unwind-protect
         (progn (setf (symbol-function symbol) replacement) (funcall thunk original))
      (setf (symbol-function symbol) original))))

(defun capture-same-condition (expected thunk)
  (let ((observed nil))
    (handler-case (funcall thunk) (error (condition) (setf observed condition)))
    (is (eq expected observed))))

(defun capture-faulted (registry)
  (mvcc-error-reason (lambda () (arcdocdb.mvcc:soglia-snapshot registry))
                     'arcdocdb.conditions:invariant-violation :snapshot-registry-faulted)
  (is (null (sb-thread:mutex-owner (arcdocdb.mvcc::registro-snapshot-mutex registry)))))

(defun capture-deadline ()
  (+ (get-internal-real-time) (* 5 internal-time-units-per-second)))

(defun capture-left (deadline)
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error 'capture-fixture-timeout))
    (/ remaining (float internal-time-units-per-second 1d0))))

(defun capture-wait (semaphore deadline)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout (capture-left deadline))
    (error 'capture-fixture-timeout)))

(defun capture-worker (name thunk)
  (sb-thread:make-thread
   (lambda () (handler-case (progn (funcall thunk) :ok) (error (condition) condition))) :name name))

(defun capture-join (thread deadline)
  (let ((result (sb-thread:join-thread thread :timeout (capture-left deadline) :default :capture-timeout)))
    (when (eq result :capture-timeout) (error 'capture-fixture-timeout))
    (when (typep result 'error) (error result))
    (is (eq result :ok))))

(defun capture-stop (threads)
  "Solo i worker della fixture, join limitato anche durante cleanup."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :capture-terminated)
    (when (sb-thread:thread-alive-p thread) (error 'capture-fixture-timeout))))

(defun capture-with-held-mutex (mutex thunk)
  "Il probe deve finire prima che il parent rilasci il mutex dell'altro worker."
  (let ((held (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
        (deadline (capture-deadline)) (threads nil))
    (unwind-protect
         (progn
           (push (capture-worker "snapshot guard holder"
                                 (lambda () (sb-thread:with-mutex (mutex)
                                              (sb-thread:signal-semaphore held)
                                              (capture-wait release deadline)))) threads)
           (capture-wait held deadline)
           (push (capture-worker "snapshot nonblocking probe" thunk) threads)
           (capture-join (first threads) deadline)
           (sb-thread:signal-semaphore release)
           (capture-join (second threads) deadline))
      (sb-thread:signal-semaphore release)
      (capture-stop threads))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-announcement-before-capture
  (multiple-value-bind (csns registry context) (mvcc-fixture)
    (declare (ignore csns))
    (let ((calls 0))
      (capture-call-with-function
       'arcdocdb.mvcc::frontiere-snapshot
       (lambda (target)
         (is (eq target registry))
         (incf calls)
         (if (= calls 1) (values 4 8)
             (progn
               ;; Writer senza mutex: deve vedere l'annuncio prima della seconda cattura.
               (is (= 4 (arcdocdb.mvcc:soglia-snapshot registry)))
               (is (arcdocdb.mvcc:deve-trattenere-p registry 5))
               (values 6 8))))
       (lambda (original)
         (declare (ignore original))
         (is (equal '(1 8 nil) (multiple-value-list (arcdocdb.mvcc:registra-snapshot context 0))))))
      (is (= calls 2))
      (mvcc-check-state registry 1 4 1)
      (arcdocdb.mvcc:termina-snapshot context 1))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-horizon-regression
  (multiple-value-bind (csns registry context) (mvcc-fixture)
    (declare (ignore csns))
    (let ((calls 0))
      (capture-call-with-function
       'arcdocdb.mvcc::frontiere-snapshot
       (lambda (target) (declare (ignore target)) (incf calls) (values (if (= calls 1) 4 3) 8))
       (lambda (original)
         (declare (ignore original))
         (mvcc-error-reason (lambda () (arcdocdb.mvcc:registra-snapshot context 0))
                            'arcdocdb.conditions:invariant-violation :snapshot-csn-frontier-regression)))
      (is (= calls 2))
      (is (zerop (arcdocdb.mvcc::registro-snapshot-count registry)))
      (capture-faulted registry))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-captured-csn-below-horizon
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 4)
    (declare (ignore csns))
    (capture-call-with-function
     'arcdocdb.mvcc::tenta-cattura-snapshot
     (lambda (target) (declare (ignore target)) (values t 6 5))
     (lambda (original)
       (declare (ignore original))
       (mvcc-error-reason (lambda () (arcdocdb.mvcc:registra-snapshot context 0))
                          'arcdocdb.conditions:invariant-violation :snapshot-csn-frontier-regression)))
    (is (zerop (arcdocdb.mvcc::registro-snapshot-count registry)))
    (capture-faulted registry)))

(defun capture-busy-rollback (with-pin)
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 5)
    (when with-pin
      (is (equal '(1 5 t) (multiple-value-list (arcdocdb.mvcc:registra-snapshot context 0))))
      (setf context (arcdocdb.mvcc:crea-contesto-snapshot registry)))
    (let ((before (mvcc-private-image registry context)) (state (mvcc-public-state registry))
          (calls 0) (observed nil)
          (busy (make-condition 'arcdocdb.conditions:resource-exhausted :reason :csn-busy)))
      (capture-call-with-function
       'arcdocdb.csn:leggi-frontiere-csn
       (lambda (target)
         (is (eq target csns)) (incf calls)
         (if (= calls 1) (values 0 8 0 6)
             (progn
               (setf observed (arcdocdb.mvcc:soglia-snapshot registry))
               (is (arcdocdb.mvcc:deve-trattenere-p registry 9))
               (error busy))))
       (lambda (original)
         (declare (ignore original))
         (mvcc-error-reason (lambda () (arcdocdb.mvcc:registra-snapshot context 1))
                            'arcdocdb.conditions:resource-exhausted :csn-busy)))
      (is (= calls 2))
      (is (= observed (if with-pin 5 6)))
      (is (equal state (mvcc-public-state registry)))
      (is (equalp before (mvcc-private-image registry context)))
      (is (eq :open (arcdocdb.mvcc::registro-snapshot-health registry)))
      (is (null (sb-thread:mutex-owner (arcdocdb.mvcc::registro-snapshot-mutex registry))))
      (is (equal (list (if with-pin 2 1) 5 t)
                 (multiple-value-list (arcdocdb.mvcc:registra-snapshot context 2)))))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-008 REQ-CON-004
(deftest test-REQ-MVC-007-snapshot-busy-rollback-without-pin (capture-busy-rollback nil))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-AFF-008 REQ-CON-004
(deftest test-REQ-MVC-007-snapshot-busy-rollback-with-pin (capture-busy-rollback t))

;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-other-resource-fail-stop
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 4)
    (let ((condition (make-condition 'arcdocdb.conditions:resource-exhausted :reason :csn-full))
          (calls 0))
      (capture-call-with-function
       'arcdocdb.csn:leggi-frontiere-csn
       (lambda (target)
         (is (eq target csns)) (incf calls)
         (if (= calls 1) (values 0 4 0 4) (error condition)))
       (lambda (original)
         (declare (ignore original))
         (capture-same-condition condition (lambda () (arcdocdb.mvcc:registra-snapshot context 0)))))
      (is (= calls 2))
      (is (zerop (arcdocdb.mvcc::registro-snapshot-count registry)))
      (capture-faulted registry))))

;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-canonical-condition-identity
  (dolist (stage '(:first :second))
    (multiple-value-bind (csns registry context) (mvcc-fixture :base 4)
      (let ((condition (make-condition 'arcdocdb.conditions:invariant-violation :reason :snapshot-fi-csn))
            (calls 0))
        (capture-call-with-function
         'arcdocdb.csn:leggi-frontiere-csn
         (lambda (target)
           (is (eq target csns)) (incf calls)
           (if (or (eq stage :first) (= calls 2)) (error condition) (values 0 4 0 4)))
         (lambda (original)
           (declare (ignore original))
           (capture-same-condition condition (lambda () (arcdocdb.mvcc:registra-snapshot context 0)))))
        (is (= calls (if (eq stage :first) 1 2)))
        (is (zerop (arcdocdb.mvcc::registro-snapshot-count registry)))
        (capture-faulted registry)))))

;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-throw-after-announcement
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 4)
    (declare (ignore csns))
    (is (eq :escaped
            (catch 'capture-stop
              (capture-call-with-function
               'arcdocdb.mvcc::tenta-cattura-snapshot
               (lambda (target) (declare (ignore target)) (throw 'capture-stop :escaped))
               (lambda (original) (declare (ignore original)) (arcdocdb.mvcc:registra-snapshot context 0))))))
    (is (zerop (arcdocdb.mvcc::registro-snapshot-count registry)))
    (is (= 4 (aref (arcdocdb.mvcc::registro-snapshot-words registry) 1)))
    (capture-faulted registry)))

(defun capture-publish-fault (stage)
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 7)
    (declare (ignore csns))
    (let* ((symbol (if (eq stage :during) 'arcdocdb.mvcc::verifica-contatori-snapshot
                       'arcdocdb.mvcc::pubblica-registrazione-snapshot))
           (original (symbol-function symbol)))
      (capture-call-with-function
       symbol
       (if (eq stage :during)
           (lambda (target)
             (when (plusp (arcdocdb.mvcc::registro-snapshot-count target))
               (arcdocdb.mvcc:invalida-registro-snapshot target))
             (funcall original target))
           (lambda (&rest args)
             (when (eq stage :before) (arcdocdb.mvcc:invalida-registro-snapshot registry))
             (multiple-value-prog1 (apply original args)
               (when (eq stage :after) (arcdocdb.mvcc:invalida-registro-snapshot registry)))))
       (lambda (saved)
         (declare (ignore saved))
         (mvcc-error-reason (lambda () (arcdocdb.mvcc:registra-snapshot context 0))
                            'arcdocdb.conditions:invariant-violation :snapshot-registry-faulted)))
      ;; Un pin già pubblicato resta conservato: nessun rollback dopo l'esposizione.
      (is (= (if (eq stage :before) 0 1) (arcdocdb.mvcc::registro-snapshot-count registry)))
      (is (= (if (eq stage :before) 0 1) (aref (arcdocdb.mvcc::contesto-snapshot-word context) 0)))
      (capture-faulted registry))))

;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-fault-before-publish (capture-publish-fault :before))
;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-fault-during-publish (capture-publish-fault :during))
;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-fault-after-publish (capture-publish-fault :after))

;;; REQ: REQ-MVC-007 REQ-MVC-003 REQ-MVC-004 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-ready-equality-and-published-identity
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 7)
    (declare (ignore csns))
    (is (equal '(1 7 t) (multiple-value-list (arcdocdb.mvcc:registra-snapshot context 0))))
    (is (= 7 (arcdocdb.mvcc:verifica-snapshot context 1 1)))
    (is (not (arcdocdb.mvcc:deve-trattenere-p registry 7)))
    (is (arcdocdb.mvcc:deve-trattenere-p registry 8))
    (arcdocdb.mvcc:termina-snapshot context 1)))

(defun capture-management-busy (registry context generation)
  (dolist (thunk (list (lambda () (arcdocdb.mvcc:registra-snapshot context 1))
                      (lambda () (arcdocdb.mvcc:attiva-snapshot context generation 1))
                      (lambda () (arcdocdb.mvcc:termina-snapshot context generation))
                      (lambda () (arcdocdb.mvcc:scadi-snapshot registry 1 1))
                      (lambda () (arcdocdb.mvcc:leggi-registro-snapshot registry))))
    (mvcc-error-reason thunk 'arcdocdb.conditions:resource-exhausted :snapshot-busy)))

(defun capture-reader-check (registry context)
  (let ((result (mvcc-words 1)))
    (is (= 7 (arcdocdb.mvcc:verifica-snapshot context 1 1)))
    (is (null (arcdocdb.mvcc:verifica-snapshot-in-buffer context 1 1 result 0)))
    (is (= 7 (aref result 0) (arcdocdb.mvcc:soglia-snapshot registry)))
    (is (arcdocdb.mvcc:snapshot-del-registro-p context registry))
    (is (arcdocdb.mvcc:deve-trattenere-p registry 8))))

;;; REQ: REQ-MVC-007 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-snapshot-held-mutex-reader-and-other-archive
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 7)
    (declare (ignore csns))
    (arcdocdb.mvcc:registra-snapshot context 0)
    (let ((before (mvcc-private-image registry)))
      (capture-with-held-mutex
       (arcdocdb.mvcc::registro-snapshot-mutex registry)
       (lambda ()
         (capture-management-busy registry context 1)
         (capture-reader-check registry context)
         (multiple-value-bind (other-csns other other-context) (mvcc-fixture :base 12)
           (declare (ignore other-csns))
           (is (equal '(1 12 t) (multiple-value-list (arcdocdb.mvcc:registra-snapshot other-context 0))))
           (mvcc-check-state other 1 12 1))))
      (is (equalp before (mvcc-private-image registry))))
    (arcdocdb.mvcc:termina-snapshot context 1)))

;;; REQ: REQ-MVC-007 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-snapshot-recursive-guard-and-nil-body
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 7)
    (arcdocdb.mvcc:registra-snapshot context 0)
    (let ((before (mvcc-private-image registry)))
      (sb-thread:with-mutex ((arcdocdb.mvcc::registro-snapshot-mutex registry))
        (capture-management-busy registry context 1)
        (capture-reader-check registry context))
      (is (equalp before (mvcc-private-image registry))))
    (arcdocdb.mvcc:termina-snapshot context 1)
    ;; Corpi legittimamente NIL: attivazione ancora waiting e terminazione idempotente.
    (let ((token (mvcc-take-csn csns)))
      (is (equal '(2 8 nil) (multiple-value-list (arcdocdb.mvcc:registra-snapshot context 2))))
      (is (null (arcdocdb.mvcc:attiva-snapshot context 2 3)))
      (is (null (arcdocdb.mvcc:termina-snapshot context 2)))
      (is (null (arcdocdb.mvcc:termina-snapshot context 2)))
      (mvcc-resolve-csn csns token))
    (is (null (sb-thread:mutex-owner (arcdocdb.mvcc::registro-snapshot-mutex registry))))
    (is (eq :open (arcdocdb.mvcc::registro-snapshot-health registry)))))

;;; REQ: REQ-MVC-007 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-snapshot-reader-with-csn-mutex-held
  (multiple-value-bind (csns registry context) (mvcc-fixture :base 7)
    (arcdocdb.mvcc:registra-snapshot context 0)
    (let ((fresh (arcdocdb.mvcc:crea-contesto-snapshot registry)) (before (mvcc-private-image registry)))
      (capture-with-held-mutex
       (arcdocdb.csn::registro-csn-mutex csns)
       (lambda ()
         (capture-reader-check registry context)
         (mvcc-error-reason (lambda () (arcdocdb.mvcc:registra-snapshot fresh 1))
                            'arcdocdb.conditions:resource-exhausted :csn-busy)))
      (is (equalp before (mvcc-private-image registry))))
    (arcdocdb.mvcc:termina-snapshot context 1)))
