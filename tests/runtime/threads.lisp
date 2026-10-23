;;;; Bootstrap concorrente e legame CSN/snapshot della capsula canonica.
;;; OWNER: runner possiede fixture e worker; ogni cella risultati ha un solo writer.
;;; SHARED: piani congelati e runtime; risultati dopo join, effetti dopo handoff a semafori.
;;; Limiti: due piani, 2/4 worker, una partenza per worker, deadline comune di 10 s.
;;; Cleanup: soltanto i worker propri, al piu un join aggiuntivo di 1 s per worker.
;;; Partenza comune sulle API: nessuna finestra interna del CAS e forzata o dichiarata coperta.
;;; REQ: REQ-MVC-006 REQ-MVC-005 REQ-MVC-007 REQ-CON-004 REQ-AFF-008
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun runtime-REQ-MVC-006-identities (runtime)
  "Osserva i quattro legami pubblici, senza leggere la rappresentazione del runtime."
  (list (arcdocdb.runtime:csn-runtime-archivio runtime)
        (arcdocdb.runtime:ambito-runtime-archivio runtime)
        (arcdocdb.runtime:snapshot-runtime-archivio runtime)
        (arcdocdb.runtime:epoche-runtime-archivio runtime)))

(defun runtime-REQ-CON-004-start-race (fixture worker-count)
  "Due piani dello stesso Archivio gareggiano; ogni worker chiama una sola volta."
  (let* ((archive (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))
         (plans (vector (arcdocdb.recovery.archive.csn.tests::acr-plan fixture)
                        (arcdocdb.recovery.archive.csn.tests::acr-plan fixture)))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (results (make-array worker-count :initial-element nil))
         (observations (make-array worker-count :initial-element nil))
         (deadline (arcdocdb.csn.tests::csn-deadline 10)) (threads nil))
    (is (member worker-count '(2 4)))
    (is (not (eq (svref plans 0) (svref plans 1))))
    (is (null (arcdocdb.runtime:trova-runtime-archivio archive)))
    (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
    (unwind-protect
         (progn
           (dotimes (i worker-count)
             (let ((worker i))
               (push (arcdocdb.csn.tests::csn-worker
                      (format nil "REQ-MVC-006 runtime bootstrap ~D/~D" worker worker-count)
                      (lambda ()
                        (sb-thread:signal-semaphore ready)
                        (arcdocdb.csn.tests::csn-wait start deadline)
                        (setf (svref results worker)
                              (handler-case
                                  (arcdocdb.runtime:crea-runtime-archivio
                                   (svref plans (mod worker 2)) 20 5
                                   :csn-capacity 2 :snapshot-capacity 2
                                   :worker-capacity 4 :retirement-capacity 2)
                                (arcdocdb.conditions:invalid-argument (condition)
                                  (is (eq :archive-runtime-bound
                                          (arcdocdb.conditions:error-reason condition)))
                                  :archive-runtime-bound)))
                        (let ((runtime (arcdocdb.runtime:trova-runtime-archivio archive)))
                          (is runtime)
                          (setf (svref observations worker)
                                (runtime-REQ-MVC-006-identities runtime)))
                        :ok)) threads)))
           (dotimes (i worker-count) (arcdocdb.csn.tests::csn-wait ready deadline))
           (sb-thread:signal-semaphore start worker-count)
           (dolist (thread threads) (arcdocdb.csn.tests::csn-join thread deadline))
           (let* ((runtime (arcdocdb.runtime:trova-runtime-archivio archive))
                  (identities (runtime-REQ-MVC-006-identities runtime)))
             (is runtime)
             (is (= 1 (count runtime results :test #'eq)))
             (is (= (1- worker-count) (count :archive-runtime-bound results)))
             (dotimes (i worker-count) (is (equal identities (svref observations i))))
             (is (equal identities (runtime-REQ-MVC-006-identities runtime))))
           (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture))
      (sb-thread:signal-semaphore start worker-count)
      (arcdocdb.csn.tests::csn-stop-workers threads))))

;;; REQ: REQ-MVC-006 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-MVC-006-runtime-two-plans-one-canonical-publication
  (dolist (version '(1 2))
    (dolist (worker-count '(2 4))
      (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
       (lambda (fixture) (runtime-REQ-CON-004-start-race fixture worker-count))
       :version version))))

(defun runtime-REQ-MVC-005-worker (runtime worker tokens effects assigned release resolved deadline)
  "Un token per worker; la fixture pubblica il proprio effetto prima di risolverlo.
I retry sono solo dell'harness CSN esistente, limitati dalla deadline comune."
  (let* ((registry (arcdocdb.runtime:csn-runtime-archivio runtime))
         (token (multiple-value-list
                 (arcdocdb.csn.tests::csn-retry
                  (lambda () (arcdocdb.csn:prendi-csn registry)) deadline '(:csn-busy)))))
    (is (= 3 (length token)))
    (setf (svref tokens worker) token)
    (sb-thread:signal-semaphore assigned)
    (arcdocdb.csn.tests::csn-wait (svref release worker) deadline)
    ;; Non simula la durevolezza o un indice: osserva soltanto l'ordine del contratto CSN.
    (setf (svref effects worker) (arcdocdb.csn.tests::csn-token-number token))
    (arcdocdb.csn.tests::csn-retry
     (lambda () (apply #'arcdocdb.csn:risolvi-csn registry token)) deadline '(:csn-busy))
    (sb-thread:signal-semaphore resolved))
  :ok)

(defun runtime-REQ-MVC-007-read-check (snapshot generation reader now ready expected)
  "La verifica pubblica avviene nell'epoca reale del runtime, senza attese nella sezione."
  (is (arcdocdb.epochs:entra-epoca reader))
  (unwind-protect
       (if ready
           (is (= expected (arcdocdb.mvcc:verifica-snapshot snapshot generation now)))
           (signals arcdocdb.conditions:invalid-argument
             (arcdocdb.mvcc:verifica-snapshot snapshot generation now) :snapshot-not-ready))
    (arcdocdb.epochs:esci-epoca reader))
  (is (not (arcdocdb.epochs:epoca-attiva-p reader))))

(defun runtime-REQ-MVC-007-snapshot-gate (runtime tokens effects release resolved deadline base)
  "Risoluzione fuori ordine: lo snapshot aspetta il CSN minore, poi legge la frontiera comune."
  (let* ((registry (arcdocdb.runtime:csn-runtime-archivio runtime))
         (snapshots (arcdocdb.runtime:snapshot-runtime-archivio runtime))
         (snapshot (arcdocdb.mvcc:crea-contesto-snapshot snapshots))
         (reader (arcdocdb.epochs:contesto-epoca
                  (arcdocdb.runtime:epoche-runtime-archivio runtime) 0))
         (lower (position (1+ base) tokens :key #'arcdocdb.csn.tests::csn-token-number))
         (generation 0))
    (is (member lower '(0 1)))
    (is (equal (list (1+ base) (+ base 2))
               (sort (map 'list #'arcdocdb.csn.tests::csn-token-number tokens) #'<)))
    (is (not (= (first (svref tokens 0)) (first (svref tokens 1)))))
    (is (equal (list (+ base 2) base)
               (arcdocdb.mvcc.tests::mvcc-frontiers registry)))
    (unwind-protect
         (multiple-value-bind (identity captured ready) (arcdocdb.mvcc:registra-snapshot snapshot 10)
           (setf generation identity)
           (is (plusp generation))
           (is (= captured (+ base 2)))
           (is (not ready))
           (is (arcdocdb.mvcc:snapshot-del-registro-p snapshot snapshots))
           (runtime-REQ-MVC-007-read-check snapshot generation reader 11 nil (+ base 2))
           (sb-thread:signal-semaphore (svref release (- 1 lower)))
           (arcdocdb.csn.tests::csn-wait resolved deadline)
           (is (= (+ base 2) (svref effects (- 1 lower))))
           (is (null (svref effects lower)))
           (is (equal (list (+ base 2) base)
                      (arcdocdb.mvcc.tests::mvcc-frontiers registry)))
           (is (not (arcdocdb.mvcc:attiva-snapshot snapshot generation 12)))
           (runtime-REQ-MVC-007-read-check snapshot generation reader 12 nil (+ base 2))
           (sb-thread:signal-semaphore (svref release lower))
           (arcdocdb.csn.tests::csn-wait resolved deadline)
           (is (equal (list (1+ base) (+ base 2)) (sort (coerce effects 'list) #'<)))
           (is (equal (list (+ base 2) (+ base 2))
                      (arcdocdb.mvcc.tests::mvcc-frontiers registry)))
           (is (arcdocdb.mvcc:attiva-snapshot snapshot generation 13))
           (runtime-REQ-MVC-007-read-check snapshot generation reader 13 t (+ base 2)))
      (when (plusp generation) (arcdocdb.mvcc:termina-snapshot snapshot generation)))
    (is (zerop (nth-value 0 (arcdocdb.mvcc:leggi-registro-snapshot snapshots))))))

(defun runtime-REQ-MVC-005-shared-family (fixture base)
  "Due writer reali usano il registro della stessa capsula osservata da snapshot ed EBR."
  (let* ((archive (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))
         (plan (arcdocdb.recovery.archive.csn.tests::acr-plan fixture)))
    (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
    (let* ((runtime (arcdocdb.runtime:crea-runtime-archivio plan 20 5
                     :csn-capacity 2 :snapshot-capacity 1 :worker-capacity 2 :retirement-capacity 1))
           (identities (runtime-REQ-MVC-006-identities runtime))
           (tokens (make-array 2 :initial-element nil)) (effects (make-array 2 :initial-element nil))
           (assigned (sb-thread:make-semaphore)) (resolved (sb-thread:make-semaphore))
           (release (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))
           (deadline (arcdocdb.csn.tests::csn-deadline 10)) (threads nil))
      (is (eq runtime (arcdocdb.runtime:trova-runtime-archivio archive)))
      (is (equal (list base base)
                 (arcdocdb.mvcc.tests::mvcc-frontiers (first identities))))
      (unwind-protect
           (progn
             (dotimes (i 2)
               (let ((worker i))
                 (push (arcdocdb.csn.tests::csn-worker
                        (format nil "REQ-MVC-007 runtime CSN/snapshot ~D" worker)
                        (lambda ()
                          (runtime-REQ-MVC-005-worker
                           runtime worker tokens effects assigned release resolved deadline))) threads)))
             (dotimes (i 2) (arcdocdb.csn.tests::csn-wait assigned deadline))
             (runtime-REQ-MVC-007-snapshot-gate runtime tokens effects release resolved deadline base)
             (dolist (thread threads) (arcdocdb.csn.tests::csn-join thread deadline))
             (is (eq runtime (arcdocdb.runtime:trova-runtime-archivio archive)))
             (is (equal identities (runtime-REQ-MVC-006-identities runtime)))
             (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture))
        (dotimes (i 2) (sb-thread:signal-semaphore (svref release i)))
        (arcdocdb.csn.tests::csn-stop-workers threads)))))

;;; REQ: REQ-MVC-006 REQ-MVC-005 REQ-MVC-007 REQ-CMP-007 REQ-CON-004
(deftest test-REQ-MVC-007-runtime-shared-csn-out-of-order-resolution-and-snapshot
  (dolist (version '(1 2))
    (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
     (lambda (fixture) (runtime-REQ-MVC-005-shared-family fixture #xffffffff))
     :version version
     :series (list (arcdocdb.recovery.archive.csn.tests::acr-serie
                    1 :active (list (arcdocdb.recovery.closed.tests::cdr-batch
                                    #xffffffff
                                    (arcdocdb.recovery.closed.tests::cdr-record :put #xffffffff))))))))
