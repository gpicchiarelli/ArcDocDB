;;;; Thread reali con handoff a semafori e scadenze: nessuna attesa senza limite.
(in-package #:arcdocdb.series.tests)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-CON-001-series-foreign-thread-lease-and-release-reacquire-transfer
  (with-series (f)
    (let* ((c (series-fixture-controller f)) (old (series-fixture-lease f))
           (deadline (series-deadline 5)) (threads nil))
      (unwind-protect
           (progn
             (push (series-worker
                    "Serie foreign lease probe"
                    (lambda ()
                      (series-refusal f (lambda () (conta-commit-serie c old))
                                      'invalid-argument :reason :serie-lease)
                      (series-refusal f (lambda () (rilascia-controllore-serie c old))
                                      'invalid-argument :reason :serie-lease)
                      (series-refusal f (lambda () (acquisisci-controllore-serie c))
                                      'resource-exhausted :reason :serie-busy)
                      :ok)) threads)
             ;; Il probe deve finire mentre il proprietario conserva ancora il lease.
             (series-join (first threads) deadline)
             (rilascia-controllore-serie c old)
             (setf (series-fixture-lease f) nil)
             (push (series-worker
                    "Serie lease transferred"
                    (lambda ()
                      (let ((lease (acquisisci-controllore-serie c)))
                        (unwind-protect
                             (progn
                               (is (> lease old))
                               (series-refusal f (lambda () (conta-commit-serie c old))
                                               'invalid-argument :reason :serie-lease)
                               (is (equal '(0 0 0) (multiple-value-list (conta-commit-serie c lease)))))
                          (rilascia-controllore-serie c lease)))
                      :ok)) threads)
             (series-join (first threads) deadline)
             (setf (series-fixture-lease f) (acquisisci-controllore-serie c))
             (is (> (series-fixture-lease f) old)))
        (series-stop-workers threads)))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-series-cas-eight-contenders-one-owner
  (with-series (f)
    (let* ((workers 8) (c (series-fixture-controller f)) (old (series-fixture-lease f))
           (start (sb-thread:make-semaphore)) (arrived (sb-thread:make-semaphore))
           (release (sb-thread:make-semaphore)) (results (make-array workers :initial-element nil))
           (deadline (series-deadline 5)) (threads nil))
      (rilascia-controllore-serie c old)
      (setf (series-fixture-lease f) nil)
      (unwind-protect
           (progn
             (dotimes (worker workers)
               (let ((id worker))
                 (push (series-worker
                        (format nil "Serie CAS contender ~D" id)
                        (lambda ()
                          (series-wait start deadline)
                          (handler-case
                              (let ((lease (acquisisci-controllore-serie c)))
                                (unwind-protect
                                     (progn
                                       (setf (svref results id) lease)
                                       (sb-thread:signal-semaphore arrived)
                                       (series-wait release deadline)
                                       (is (equal '(0 0 0)
                                                  (multiple-value-list (conta-commit-serie c lease)))))
                                  (rilascia-controllore-serie c lease)))
                            (resource-exhausted (condition)
                              (is (eq :serie-busy (error-reason condition)))
                              (setf (svref results id) :busy)
                              (sb-thread:signal-semaphore arrived)))
                          :ok)) threads)))
             (sb-thread:signal-semaphore start workers)
             (dotimes (worker workers) (series-wait arrived deadline))
             (is (= 1 (count-if #'integerp results)))
             (is (= 7 (count :busy results)))
             (is (= (1+ old) (find-if #'integerp results)))
             (sb-thread:signal-semaphore release)
             (dolist (thread threads) (series-join thread deadline))
             (setf (series-fixture-lease f) (acquisisci-controllore-serie c))
             (series-counts f 0 0 0))
        (sb-thread:signal-semaphore start workers)
        (sb-thread:signal-semaphore release workers)
        (series-stop-workers threads)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-CON-004-series-four-controllers-shared-bounded-csn
  (let* ((workers 4) (rounds 64) (capacity 3) (total (* workers rounds))
         (base #x80000000fffffffd)
         (registry (arcdocdb.csn:crea-registro-csn
                    :capacity capacity :initial-high #x80000000 :initial-low #xfffffffd))
         (start (sb-thread:make-semaphore)) (assigned (sb-thread:make-semaphore))
         (saturated (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (fast-done (sb-thread:make-semaphore)) (slow-release (sb-thread:make-semaphore))
         (effects (make-array total :initial-element nil))
         (histories (make-array workers :initial-element nil))
         (busy (make-array workers :initial-element 0))
         (full (make-array workers :initial-element 0))
         (deadline (series-deadline 20)) (threads nil))
    (labels ((work (id)
               (with-series (f :registry registry :base base :capacity 2 :file-id (1+ id))
                 (let ((notified nil) (slow nil) (previous base) (horizon base)
                       (history nil) (last-root (series-fixture-planned f)))
                   (series-wait start deadline)
                   (dotimes (round rounds)
                     (let* ((lot (series-open-lot f :id (1+ id)))
                            (before (series-image (list lot)
                                                  :opaque (list registry (series-fixture-log f)))))
                       (series-retry
                        (lambda () (series-seal f :lot lot)) deadline '(:csn-busy :csn-full)
                        (lambda (reason)
                          (is (eq :open (arcdocdb.wal:stato-lotto lot)))
                          (is (eq :libero (arcdocdb.wal:stato-csn-lotto lot)))
                          (is (= 26 (arcdocdb.wal:lunghezza-lotto lot)))
                          (is (series-image-equal
                               before (series-image (list lot)
                                                    :opaque (list registry (series-fixture-log f)))))
                          (is (equalp (bytes (1+ id) #xa0)
                                      (subseq (arcdocdb.wal::lotto-buffer lot) 24 26)))
                          (ecase reason
                            (:csn-busy (incf (svref busy id)))
                            (:csn-full
                             (incf (svref full id))
                             (unless notified
                               (setf notified t)
                               (sb-thread:signal-semaphore saturated))))))
                       (let* ((token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lot)))
                              (number (series-number (second token) (third token)))
                              (position (- number base 1))
                              (root (series-root (+ (* id rounds) round 1) last-root)))
                         (is (< previous number)) (setf previous number)
                         (is (<= 0 position (1- total)))
                         (is (null (svref effects position)))
                         (setf (svref effects position) (list id round root))
                         (push number history)
                         (multiple-value-bind (event generation actual) (series-adopt f lot :root root)
                           (is (eq root actual))
                           (when (zerop round)
                             (setf slow (= number (1+ base)))
                             (sb-thread:signal-semaphore assigned)
                             (series-wait release deadline)
                             ;; Il primo CSN resta pendente mentre le altre tre Serie progrediscono.
                             (when slow (series-wait slow-release deadline)))
                           (let ((group (series-group f lot)))
                             (series-counts f 1 1 0)
                             (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
                             (series-complete f event generation)
                             (let* ((result (series-publish-retry f event generation deadline))
                                    (observed (series-number (second result) (third result))))
                               (is (<= horizon observed (+ base total)))
                               (unless slow (is (= base observed)))
                               (setf horizon observed))
                             (is (eq root (leggi-radice-serie (series-fixture-controller f))))
                             (is (eq :risolto (arcdocdb.wal:stato-csn-lotto lot)))
                             (arcdocdb.wal:riusa-gruppo group) (series-retire f event generation)
                             (series-counts f 0 0 0)
                             (setf last-root root)))))
                     (sb-thread:thread-yield))
                   (is (= rounds (length history)))
                   (setf (svref histories id) (nreverse history))
                   (is (equalp (vector 1 rounds rounds 0) (series-fixture-calls f)))
                   ;; Oracolo delle radici: catena immutable distinta e ordine del writer.
                   (let ((cursor last-root))
                     (loop for round downfrom (1- rounds) to 0
                           do (is (= (+ (* id rounds) round 1) (series-root-id cursor)))
                              (setf cursor (series-root-parent cursor)))
                     (is (= 0 (series-root-id cursor))))
                   (unless slow (sb-thread:signal-semaphore fast-done))
                   :ok))))
      (unwind-protect
           (progn
             (dotimes (worker workers)
               (let ((id worker))
                 (push (series-worker (format nil "Serie bounded CSN ~D" id)
                                      (lambda () (work id))) threads)))
             (sb-thread:signal-semaphore start workers)
             (dotimes (slot capacity) (series-wait assigned deadline))
             (series-wait saturated deadline)
             (series-retry
              (lambda () (series-frontiers registry (+ base capacity)
                                          (loop for i from 1 to capacity collect (+ base i))))
              deadline '(:csn-busy))
             (is (plusp (reduce #'+ full)))
             (sb-thread:signal-semaphore release workers)
             (dotimes (worker (1- workers)) (series-wait fast-done deadline))
             (series-frontiers registry (+ base 1 (* (1- workers) rounds)) (list (1+ base)))
             (sb-thread:signal-semaphore slow-release)
             (dolist (thread threads) (series-join thread deadline))
             (is (every #'identity effects))
             (is (= total (length (remove-duplicates
                                  (loop for numbers across histories append numbers)))))
             (series-frontiers registry (+ base total) nil)
             (format t "  Serie: ~D controller x ~D lotti, K=~D, ~D busy, ~D full, H convergente.~%"
                     workers rounds capacity (reduce #'+ busy) (reduce #'+ full)))
        (sb-thread:signal-semaphore start workers)
        (sb-thread:signal-semaphore release workers)
        (sb-thread:signal-semaphore slow-release workers)
        (series-stop-workers threads)))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-MVC-005
(deftest test-REQ-CON-002-series-immutable-root-parallel-reader-after-handoff
  (with-series (f :capacity 1)
    (let* ((rounds 40) (roots (make-array rounds :initial-element nil))
           (published (sb-thread:make-semaphore)) (observed (sb-thread:make-semaphore))
           (deadline (series-deadline 10)) (threads nil)
           (initial (series-fixture-planned f)))
      (unwind-protect
           (progn
             (push (series-worker
                    "Serie immutable root reader"
                    (lambda ()
                      (dotimes (i rounds)
                        (series-wait published deadline)
                        (let ((root (leggi-radice-serie (series-fixture-controller f))))
                          (is (eq (svref roots i) root))
                          (is (= (1+ i) (series-root-id root)))
                          (is (eq (if (zerop i) initial (svref roots (1- i)))
                                  (series-root-parent root))))
                        (sb-thread:signal-semaphore observed))
                      :ok)) threads)
             (dotimes (i rounds)
               (let ((lot (series-seal f))
                     (root (series-root (1+ i) (series-fixture-planned f))))
                 (multiple-value-bind (event generation actual) (series-adopt f lot :root root)
                   (is (eq root actual))
                   (let ((group (series-group f lot)))
                     (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
                     (series-complete f event generation) (series-publish f event generation (1+ i))
                     (setf (svref roots i) root)
                     (sb-thread:signal-semaphore published)
                     (series-wait observed deadline)
                     (arcdocdb.wal:riusa-gruppo group) (series-retire f event generation)))))
             (series-join (first threads) deadline)
             (series-frontiers (series-fixture-registry f) rounds nil))
        (sb-thread:signal-semaphore published rounds)
        (series-stop-workers threads)))))

;;; REQ: REQ-WAL-006 REQ-AFF-001 REQ-CON-002
(deftest test-REQ-WAL-006-series-io-finish-joined-before-drain-and-annul
  (let ((entered (sb-thread:make-semaphore)) (finish (sb-thread:make-semaphore))
        (deadline (series-deadline 5)) (threads nil))
    (with-series (f :flush (lambda (fd)
                            (declare (ignore fd))
                            (sb-thread:signal-semaphore entered)
                            (series-wait finish deadline)
                            0))
      (let ((lot (series-seal f)))
        (multiple-value-bind (event generation root) (series-adopt f lot)
          (declare (ignore root))
          (let ((group (series-group f lot)))
            (unwind-protect
                 (progn
                   (series-begin f event generation)
                   (push (series-worker
                          "Serie I/O completion handoff"
                          (lambda () (arcdocdb.wal:esegui-gruppo group) :ok)) threads)
                   (series-wait entered deadline)
                   (is (eq :written (arcdocdb.wal:stato-lotto lot)))
                   ;; Il worker e vivo e fermo nel flush: lo snapshot e sincronizzato.
                   (series-refusal f
                                   (lambda () (completa-io-commit-serie
                                               (series-fixture-controller f) (series-fixture-lease f)
                                               event generation))
                                   'invalid-argument :reason :serie-io-in-flight
                                   :groups (list group))
                   (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
                   (series-refusal f
                                   (lambda () (annulla-commit-serie
                                               (series-fixture-controller f) (series-fixture-lease f)
                                               event generation))
                                   'invalid-argument :reason :serie-io-active
                                   :groups (list group))
                   (is (eq :open (arcdocdb.wal:stato-log (series-fixture-log f))))
                   (sb-thread:signal-semaphore finish)
                   (series-join (first threads) deadline)
                   ;; JOIN e il solo handoff di FINE compito; durable da solo non lo prova.
                   (series-complete f event generation)
                   (let ((calls (copy-seq (series-fixture-calls f))))
                     (series-annul f event generation 1)
                     (is (equalp calls (series-fixture-calls f))))
                   (series-faulted f :serie)
                   (series-counts f 1 0 0))
              (sb-thread:signal-semaphore finish)
              (series-stop-workers threads))))))))

;;; REQ: REQ-MVC-008 REQ-CON-004 REQ-WAL-006
(deftest test-REQ-CON-004-series-held-csn-guard-publish-never-waits
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (let ((group (series-group f lot)) (held (sb-thread:make-semaphore))
              (release (sb-thread:make-semaphore)) (deadline (series-deadline 5)) (threads nil))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation)
          (let ((c (series-fixture-controller f)))
            (rilascia-controllore-serie c (series-fixture-lease f))
            (setf (series-fixture-lease f) nil)
            (unwind-protect
                 (progn
                   (push (series-worker
                          "Serie CSN guard holder"
                          (lambda ()
                            (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex
                                                  (series-fixture-registry f)))
                              (sb-thread:signal-semaphore held)
                              (series-wait release deadline))
                            :ok)) threads)
                   (series-wait held deadline)
                   (push (series-worker
                          "Serie nonblocking publisher"
                          (lambda ()
                            (let ((lease (acquisisci-controllore-serie c)))
                              (unwind-protect
                                   (progn
                                     (series-pending
                                      (lambda () (pubblica-commit-serie c lease event generation)))
                                     (is (eq root (leggi-radice-serie c)))
                                     (is (eq :pubblicato (stato-commit-serie c event generation))))
                                (rilascia-controllore-serie c lease)))
                            :ok)) threads)
                   ;; JOIN prima di rilasciare il mutex: rileva un mutante bloccante.
                   (series-join (first threads) deadline)
                   (sb-thread:signal-semaphore release)
                   (series-join (second threads) deadline)
                   (setf (series-fixture-lease f) (acquisisci-controllore-serie c))
                   (let ((calls (copy-seq (series-fixture-calls f))))
                     (series-publish f event generation 1)
                     (is (equalp calls (series-fixture-calls f)))))
              (sb-thread:signal-semaphore release)
              (series-stop-workers threads))))))))
