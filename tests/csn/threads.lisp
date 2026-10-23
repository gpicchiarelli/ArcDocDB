(in-package #:arcdocdb.csn.tests)

;;; REQ: REQ-MVC-008 REQ-CON-004 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-004-csn-held-worker-guard-busy-and-independent-registry
  (multiple-value-bind (registry model) (csn-fixture :capacity 2)
    (multiple-value-bind (other other-model) (csn-fixture :capacity 1 :base #x100000000)
      (let* ((token (csn-take registry model)) (before (csn-check-model registry model))
             (private-before (csn-private-image registry)) (evaluations 0) (executions 0))
        (call-with-csn-held-guard
         registry
         (lambda ()
           ;; Le tre API e il macro devono terminare mentre l'altro worker
           ;; possiede ancora il mutex; il main non lo rilascia prima del join.
           (dotimes (attempt 3)
             (signals resource-exhausted (prendi-csn registry) :csn-busy)
             (signals resource-exhausted (apply #'risolvi-csn registry token) :csn-busy)
             (signals resource-exhausted (leggi-frontiere-csn registry) :csn-busy)
             (signals resource-exhausted
               (arcdocdb.csn::%with-csn-guard ((progn (incf evaluations) registry))
                 (incf executions) (values :unexpected :body)) :csn-busy))
           (is (= evaluations 3)) (is (zerop executions))
           ;; La guardia e per Archivio: un registro indipendente avanza subito.
           (let ((other-token (csn-take other other-model)))
             (csn-resolve other other-model other-token))))
        (is (equal before (csn-check-model registry model)))
        (is (equalp private-before (csn-private-image registry)))
        (is (equal '(1 1 1 1) (csn-check-model other other-model)))
        (csn-resolve registry model token)
        (csn-drain registry model)))))

;;; REQ: REQ-MVC-005 REQ-MVC-008 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-MVC-008-csn-four-real-workers-one-thousand-assignments-each
  (let* ((worker-count 4) (per-worker 1000) (total (* worker-count per-worker))
         (capacity 3) (base #x80000001fffffffd)
         (registry (crea-registro-csn :capacity capacity :initial-high #x80000001
                                     :initial-low #xfffffffd))
         (tokens (make-array worker-count)) (effects (make-array total :initial-element nil))
         (busy (make-array worker-count :initial-element 0))
         (full (make-array worker-count :initial-element 0))
         (starts (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
         (assigned (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
         (saturated (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
         (release (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
         (finished (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
         (deadline (csn-deadline 20)) (threads nil))
    (dotimes (worker worker-count)
      (setf (svref tokens worker) (make-array per-worker :initial-element nil)))
    (labels ((work (worker)
               (let ((previous-csn base) (previous-last base) (previous-horizon base))
                 (dotimes (iteration per-worker)
                   (when (< iteration 2) (csn-wait (svref starts iteration) deadline))
                   (let* ((notified-full nil)
                          (token
                            (multiple-value-list
                             (csn-retry
                              (lambda () (prendi-csn registry)) deadline '(:csn-busy :csn-full)
                              (lambda (reason)
                                (ecase reason
                                  (:csn-busy (incf (svref busy worker)))
                                  (:csn-full
                                   (incf (svref full worker))
                                   (when (and (< iteration 2) (not notified-full))
                                     (setf notified-full t)
                                     (sb-thread:signal-semaphore (svref saturated iteration)))))))))
                          (number (progn
                                    (is (= 3 (length token)))
                                    (is (and (typep (first token) 'fixnum)
                                             (<= 0 (first token) (1- capacity))))
                                    (is (every (lambda (word) (typep word '(unsigned-byte 32)))
                                               (rest token)))
                                    (csn-token-number token)))
                          (frontiers
                            (multiple-value-list
                             (csn-retry (lambda () (leggi-frontiere-csn registry)) deadline
                                        '(:csn-busy) (lambda (reason)
                                                      (declare (ignore reason))
                                                      (incf (svref busy worker)))))))
                     (is (< previous-csn number (1+ (+ base total))))
                     (is (= 4 (length frontiers)))
                     (is (every (lambda (word) (typep word '(unsigned-byte 32))) frontiers))
                     (setf (svref (svref tokens worker) iteration) token
                           previous-csn number)
                     (let ((last (csn-number (first frontiers) (second frontiers)))
                           (horizon (csn-number (third frontiers) (fourth frontiers))))
                       (is (>= last number previous-last))
                       ;; Il token proprio e ancora pendente: H non lo oltrepassa,
                       ;; nemmeno se altri worker hanno pubblicato commit posteriori.
                       (is (<= previous-horizon horizon))
                       (is (< horizon number))
                       (setf previous-last last previous-horizon horizon))
                     (when (< iteration 2)
                       (sb-thread:signal-semaphore (svref assigned iteration))
                       (csn-wait (svref release iteration) deadline))
                     ;; Effetti della fixture pubblicati/annullati prima di risolvere.
                     ;; Ogni cella ha un solo writer, dato il CSN unico assegnato.
                     (setf (svref effects (1- (- number base)))
                           (if (evenp iteration) :published :annulled))
                     (let ((result
                             (multiple-value-list
                              (csn-retry
                               (lambda () (apply #'risolvi-csn registry token)) deadline
                               '(:csn-busy) (lambda (reason)
                                             (declare (ignore reason))
                                             (incf (svref busy worker)))))))
                       (is (= 2 (length result)))
                       (is (every (lambda (word) (typep word '(unsigned-byte 32))) result))
                       (let ((horizon (csn-number (first result) (second result))))
                         (is (<= previous-horizon horizon (+ base total)))
                         (setf previous-horizon horizon)))
                     (when (< iteration 2)
                       (sb-thread:signal-semaphore (svref finished iteration))))))
               :ok))
      (unwind-protect
           (progn
             (dotimes (i worker-count)
               (let ((worker i))
                 (push (csn-worker (format nil "CSN worker ~D" worker)
                                   (lambda () (work worker))) threads)))
             ;; Due onde obbligano ogni slot a essere riusato dai worker reali.
             ;; I tre assegnatari tengono il token, il quarto incontra FULL.
             (dotimes (wave 2)
               (sb-thread:signal-semaphore (svref starts wave) worker-count)
               (dotimes (i capacity) (csn-wait (svref assigned wave) deadline))
               (csn-wait (svref saturated wave) deadline)
               (let ((frontiers
                       (multiple-value-list
                        (csn-retry (lambda () (leggi-frontiere-csn registry)) deadline '(:csn-busy)))))
                 (is (= 4 (length frontiers)))
                 (is (= (+ base (* wave worker-count) capacity)
                        (csn-number (first frontiers) (second frontiers))))
                 (is (= (+ base (* wave worker-count))
                        (csn-number (third frontiers) (fourth frontiers)))))
               (sb-thread:signal-semaphore (svref release wave) worker-count)
               (dotimes (i worker-count) (csn-wait (svref finished wave) deadline)))
             (dolist (thread threads) (csn-join thread deadline))
             (let ((seen (make-array total :initial-element 0))
                   (slot-uses (make-array capacity :initial-element 0)))
               (dotimes (worker worker-count)
                 (let ((previous base))
                   (dotimes (iteration per-worker)
                     (let* ((token (svref (svref tokens worker) iteration))
                            (number (csn-token-number token)) (rank (1- (- number base))))
                       (is (< previous number (1+ (+ base total))))
                       (setf previous number)
                       (incf (svref seen rank)) (incf (svref slot-uses (first token)))))))
               ;; Contiguita e unicita provano anche che BUSY/FULL non consumano CSN.
               (is (every (lambda (count) (= count 1)) seen))
               (is (every (lambda (count) (>= count 2)) slot-uses))
               (is (= total (reduce #'+ slot-uses)))
               (is (every (lambda (effect) (member effect '(:published :annulled))) effects))
               (is (plusp (reduce #'+ full)))
               (let ((frontiers (csn-frontiers registry)))
                 (is (= (+ base total) (csn-number (first frontiers) (second frontiers))
                        (csn-number (third frontiers) (fourth frontiers)))))
               (dotimes (worker worker-count)
                 (csn-reject-token registry (svref (svref tokens worker) (1- per-worker))))
               (format t "  CSN: ~D worker x ~D assegnazioni, ~D busy, ~D full, slot ~S, H convergente.~%"
                       worker-count per-worker (reduce #'+ busy) (reduce #'+ full) slot-uses)))
        ;; Sblocca tutte le fixture prima di terminare/joinare i worker rimasti.
        (dotimes (wave 2)
          (sb-thread:signal-semaphore (svref starts wave) worker-count)
          (sb-thread:signal-semaphore (svref release wave) worker-count))
        (csn-stop-workers threads)))))
