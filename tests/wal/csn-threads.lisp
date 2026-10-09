(in-package #:arcdocdb.wal.tests)

;;; REQ: REQ-AFF-008 REQ-AFF-001 REQ-WAL-005
(deftest test-REQ-AFF-008-wal-csn-file-budget-and-availability-before-assignment
  (dolist (case '(:closed :faulted :transfer-budget :file-budget :written-offset :planned-budget))
    (let* ((file (fixture-file :max-transfer (if (eq case :transfer-budget) 81 512)
                              :max-file-bytes (case case (:file-budget 81) (:planned-budget 100) (otherwise 512))))
           (log (crea-log-io file :segment 31)) (lot (wal-csn-open))
           (registry (arcdocdb.csn:crea-registro-csn))
           (start (if (eq case :planned-budget) 40 0)))
      (unwind-protect
           (progn
             (case case
               (:closed (arcdocdb.io:chiudi file))
               (:faulted (setf (arcdocdb.io::file-state file) :faulted))
               (:written-offset (setf (arcdocdb.io::file-written file) 1))
               (otherwise nil))
             (let ((before (wal-csn-image lot registry log)))
               (case case
                 ((:closed :faulted)
                  (signals io-fault (arcdocdb.wal:sigilla-lotto-con-csn lot registry log start 0)
                           :io-unavailable))
                 (:written-offset
                  (signals invalid-argument (arcdocdb.wal:sigilla-lotto-con-csn lot registry log start 0)
                           :lotto-written-offset))
                 (otherwise
                  (signals resource-exhausted (arcdocdb.wal:sigilla-lotto-con-csn lot registry log start 0)
                           :io-group-budget)))
               (is (equalp before (wal-csn-image lot registry log)))
               (is (eq :libero (arcdocdb.wal:stato-csn-lotto lot)))
               (wal-csn-frontiers registry 0 0)))
        (unless (eq (arcdocdb.io:stato-file file) :closed) (arcdocdb.io:chiudi file))))))

;;; REQ: REQ-AFF-004 REQ-MVC-008 REQ-WAL-005
(deftest test-REQ-AFF-004-wal-csn-invalid-record-offset-retains-obligation
  (let* ((file (fixture-file)) (log (crea-log-io file :segment 31))
         (registry (arcdocdb.csn:crea-registro-csn :capacity 1))
         (lot (crea-lotto :segment 31 :capacity 128 :max-records 1)))
    (unwind-protect
         (progn
           (aggiungi-record lot 1 (bytes 1) (bytes #xa0))
           (setf (arcdocdb.wal::lotto-count lot) 2)
           (signals invariant-violation (arcdocdb.wal::ristampa-record-parole lot 0 1)
                    :lotto-record-count)
           (setf (arcdocdb.wal::lotto-count lot) 1)
           ;; FI sul solo stato interno: un offset non contiene l'header completo.
           (setf (aref (arcdocdb.wal::lotto-offsets lot) 0) 26)
           (signals invariant-violation
                    (arcdocdb.wal:sigilla-lotto-con-csn lot registry log 0 0)
                    :lotto-record-offset)
           (is (eq :open (stato-lotto lot)))
           (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
           (multiple-value-bind (slot high low) (arcdocdb.wal:leggi-csn-lotto lot)
             (is (= high 0)) (is (= low 1))
             (signals invalid-argument (aggiungi-record lot 1 (bytes 2) (bytes #xa0)) :lotto-csn-bound)
             (signals invalid-argument (sigilla-lotto lot 2 0 0) :lotto-csn-bound)
             (signals invalid-argument (riusa-lotto lot) :lotto-state)
             (multiple-value-bind (lh ll hh hl) (arcdocdb.csn:leggi-frontiere-csn registry)
               (is (equal '(0 1 0 0) (list lh ll hh hl))))
             ;; La fixture applica la transizione del controller dopo il fail-stop;
             ;; nessun I/O è stato ammesso, quindi non esistono consumatori da ritirare.
             (setf (arcdocdb.wal::log-io-state log) :faulted)
             (arcdocdb.wal:annulla-csn-lotto lot registry slot high low)
             (is (eq :risolto (arcdocdb.wal:stato-csn-lotto lot)))
             (multiple-value-bind (lh ll hh hl) (arcdocdb.csn:leggi-frontiere-csn registry)
               (is (equal '(0 1 0 1) (list lh ll hh hl))))))
      (arcdocdb.io:chiudi file))))

;;; REQ: REQ-MVC-008 REQ-WAL-005 REQ-WAL-006 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-MVC-008-four-series-shared-csn-wal-lifecycle
  (let* ((workers 4) (per-worker 500) (capacity 3) (total (* workers per-worker))
         (base #x80000000fffffffd)
         (registry (arcdocdb.csn:crea-registro-csn :capacity capacity
                     :initial-high #x80000000 :initial-low #xfffffffd))
         (tokens (make-array workers)) (effects (make-array total :initial-element nil))
         (busy (make-array workers :initial-element 0)) (full (make-array workers :initial-element 0))
         (start (sb-thread:make-semaphore)) (assigned (sb-thread:make-semaphore))
         (saturated (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (deadline (arcdocdb.csn.tests::csn-deadline 20)) (threads nil))
    (dotimes (worker workers)
      (setf (svref tokens worker) (make-array per-worker :initial-element nil)))
    (labels ((retry (thunk reasons refused)
               (arcdocdb.csn.tests::csn-retry thunk deadline reasons refused))
             (work (worker)
               (let* ((file (fixture-file)) (log (crea-log-io file :segment (1+ worker)))
                      (lot (crea-lotto :segment (1+ worker) :capacity 128 :max-records 1))
                      (group (crea-gruppo log :max-lots 1)) (key (bytes 1)) (value (bytes #xa0))
                      (notified nil) (previous base))
                 (unwind-protect
                      (progn
                        (arcdocdb.csn.tests::csn-wait start deadline)
                        (dotimes (iteration per-worker)
                          (aggiungi-record lot 1 key value)
                          (retry
                           (lambda ()
                             (arcdocdb.wal:sigilla-lotto-con-csn lot registry log
                               (arcdocdb.io:posizione-scritta file)
                               (arcdocdb.io:posizione-durevole file)))
                           '(:csn-busy :csn-full)
                           (lambda (reason)
                             (is (eq :open (stato-lotto lot)))
                             (is (eq :libero (arcdocdb.wal:stato-csn-lotto lot)))
                             (is (= 26 (lunghezza-lotto lot)))
                             (if (eq reason :csn-busy) (incf (svref busy worker))
                                 (progn
                                   (incf (svref full worker))
                                   (unless notified
                                     (setf notified t)
                                     (sb-thread:signal-semaphore saturated))))))
                          (multiple-value-bind (slot high low) (arcdocdb.wal:leggi-csn-lotto lot)
                            (let* ((number (+ (ash high 32) low)) (rank (1- (- number base))))
                              (is (< previous number (+ base total 1)))
                              (setf previous number (svref (svref tokens worker) iteration) number)
                              (when (zerop iteration)
                                (sb-thread:signal-semaphore assigned)
                                (arcdocdb.csn.tests::csn-wait release deadline))
                              (aggiungi-lotto group lot) (chiudi-gruppo group) (esegui-gruppo group)
                              ;; Effetto della fixture già pubblicato prima della risoluzione;
                              ;; ogni CSN unico deve avere una sola cella, nessun indice del motore.
                              (is (null (svref effects rank)))
                              (setf (svref effects rank) :published)
                              (retry
                               (lambda () (arcdocdb.wal:risolvi-lotto-pubblicato
                                           lot registry slot high low :group))
                               '(:csn-busy)
                               (lambda (reason)
                                 (is (eq reason :csn-busy))
                                 (incf (svref busy worker))
                                 (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))))
                              (riusa-gruppo group) (riusa-lotto lot)
                              (is (eq :libero (arcdocdb.wal:stato-csn-lotto lot))))))
                        (is (= (* per-worker 82) (arcdocdb.io:posizione-scritta file)
                               (arcdocdb.io:posizione-durevole file)))
                        :ok)
                   (arcdocdb.io:chiudi file)))))
      (unwind-protect
           (progn
             (dotimes (worker workers)
               (let ((number worker))
                 (push (arcdocdb.csn.tests::csn-worker
                        (format nil "WAL CSN Serie ~D" number) (lambda () (work number))) threads)))
             (sb-thread:signal-semaphore start workers)
             (dotimes (i capacity) (arcdocdb.csn.tests::csn-wait assigned deadline))
             (arcdocdb.csn.tests::csn-wait saturated deadline)
             (multiple-value-bind (lh ll hh hl)
                 (retry (lambda () (arcdocdb.csn:leggi-frontiere-csn registry)) '(:csn-busy) nil)
               (is (= (+ base capacity) (+ (ash lh 32) ll)))
               (is (= base (+ (ash hh 32) hl))))
             (sb-thread:signal-semaphore release workers)
             (dolist (thread threads) (arcdocdb.csn.tests::csn-join thread deadline))
             (let ((seen (make-array total :initial-element 0)))
               (dotimes (worker workers)
                 (dotimes (iteration per-worker)
                   (incf (svref seen (1- (- (svref (svref tokens worker) iteration) base))))))
               (is (every (lambda (count) (= count 1)) seen)))
             (is (every (lambda (effect) (eq effect :published)) effects))
             (is (plusp (reduce #'+ full)))
             (multiple-value-bind (lh ll hh hl) (arcdocdb.csn:leggi-frontiere-csn registry)
               (is (= (+ base total) (+ (ash lh 32) ll) (+ (ash hh 32) hl))))
             (format t "  WAL/CSN: ~D Serie x ~D cicli, ~D busy, ~D full, H convergente.~%"
                     workers per-worker (reduce #'+ busy) (reduce #'+ full)))
        (sb-thread:signal-semaphore start workers)
        (sb-thread:signal-semaphore release workers)
        (arcdocdb.csn.tests::csn-stop-workers threads)))))
