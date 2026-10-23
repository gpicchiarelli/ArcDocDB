;;;; Binding canonico del controller al singolo oggetto LOG-IO, senza I/O.
;;;; OWNER: ogni test possiede log virtuali nuovi, registri e cleanup dei propri worker.
;;;; SHARED: fonte e root immutabili; solo binding CAS e celle risultato a writer unico.
;;;; Race: 2/4 factory, una chiamata ciascuna, osservatore e deadline comune di 10 s.
;;;; Non forza la finestra CAS e non distingue il rifiuto anticipato dal CAS perdente.
;;;; Nessuna sostituzione di FDEFINITION; FI seriali dello slot sempre ripristinate.
(in-package #:arcdocdb.series.tests)
(declaim (optimize (safety 3) (debug 3)))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-008
(defun series-binding-fresh-log (thunk &key (kind :segment) (version 2))
  "Log virtuale ancora privo di controller; nessuna vecchia fixture gia bound.
Le tre celle contano open/I-O inatteso/close; solo open e cleanup sono ammessi."
  (let ((calls (vector 0 0 0)))
    (labels ((unexpected-io (&rest arguments)
               (declare (ignore arguments))
               (incf (svref calls 1))
               (error "REQ-AFF-001: I/O inatteso nel binding Serie."))
             (open-file (name mode)
               (is (string= name "series-log-binding-private.tmp"))
               (is (eq mode :append))
               (incf (svref calls 0))
               7)
             (close-file (fd)
               (is (= fd 7))
               (incf (svref calls 2))
               0))
      (let* ((backend (arcdocdb.io:make-backend
                       #'open-file #'unexpected-io #'unexpected-io
                       #'unexpected-io #'unexpected-io #'close-file))
             (file (arcdocdb.io:crea-temporaneo
                    "series-log-binding-private.tmp" :backend backend)))
        (unwind-protect
             (let ((log (arcdocdb.wal:crea-log-io
                         file kind (if (eq kind :segment) 31 0) :version version)))
               (funcall thunk log file calls)
               (is (equalp calls #(1 0 0)))
               (is (eq :open (arcdocdb.io:stato-file file)))
               (is (zerop (arcdocdb.io:posizione-scritta file)))
               (is (zerop (arcdocdb.io:posizione-durevole file))))
          (arcdocdb.io:chiudi file))
        (is (equalp calls #(1 0 1)))))))

;;; REQ: REQ-CON-002 REQ-AFF-008 REQ-WAL-006
(defun series-binding-initial-controller (controller registry log root offset capacity)
  "Controlla il candidato pubblicato interamente inizializzato, senza lease o CSN."
  (is (eq registry (arcdocdb.series::controllore-serie-registry controller)))
  (is (eq log (arcdocdb.series::controllore-serie-log controller)))
  (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
  (is (eq root (leggi-radice-serie controller)))
  (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
  (is (= offset (arcdocdb.series::controllore-serie-next-offset controller)))
  (is (eq :healthy (stato-controllore-serie controller)))
  (is (null (arcdocdb.series::controllore-serie-owner controller)))
  (is (not (arcdocdb.series::controllore-serie-effect-active controller)))
  (is (zerop (arcdocdb.series::controllore-serie-lease-generation controller)))
  (is (zerop (arcdocdb.series::controllore-serie-event-generation controller)))
  (is (zerop (arcdocdb.series::controllore-serie-head controller)))
  (is (zerop (arcdocdb.series::controllore-serie-tail controller)))
  (is (zerop (arcdocdb.series::controllore-serie-publish-head controller)))
  (is (zerop (arcdocdb.series::controllore-serie-count controller)))
  (is (zerop (arcdocdb.series::controllore-serie-unresolved controller)))
  (is (zerop (arcdocdb.series::controllore-serie-active-io controller)))
  (is (zerop (arcdocdb.series::controllore-serie-last-high controller)))
  (is (zerop (arcdocdb.series::controllore-serie-last-low controller)))
  (let ((slots (arcdocdb.series::controllore-serie-slots controller)))
    (is (= capacity (length slots)))
    (dotimes (i capacity)
      (let ((event (svref slots i)))
        (is (eq controller (arcdocdb.series::commit-serie-controller event)))
        (is (= i (arcdocdb.series::commit-serie-position event)))
        (is (eq :libero (arcdocdb.series::commit-serie-phase event)))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-CON-002-series-log-binding-fresh-getter-and-default-factory
  (series-binding-fresh-log
   (lambda (log file calls)
     (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 2 :initial-low 17))
            (before (series-image (list registry file calls))))
       (dotimes (i 8)
         (is (null (arcdocdb.series:trova-controllore-serie log))))
       (let ((controller (crea-controllore-serie registry log)))
         (series-binding-initial-controller controller registry log nil 0 64)
         (dotimes (i 8)
           (is (eq controller (arcdocdb.series:trova-controllore-serie log)))))
       (is (series-image-equal before (series-image (list registry file calls))))))))

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-WAL-006
(deftest test-REQ-AFF-008-series-log-binding-preserves-capacity-general-root-and-offset
  (dolist (capacity '(1 64 1024))
    (dolist (offset (list 0 most-positive-fixnum))
      (dolist (root (list nil :opaque-root (series-root 71 nil)))
        (series-binding-fresh-log
         (lambda (log file calls)
           (let* ((registry (arcdocdb.csn:crea-registro-csn
                            :capacity 1 :initial-high #x80000000 :initial-low #xfffffffd))
                  (before (series-image (list registry file calls root)))
                  (controller (crea-controllore-serie
                               registry log :capacity capacity :root root :next-offset offset)))
             (series-binding-initial-controller controller registry log root offset capacity)
             (is (series-image-equal
                  before (series-image (list registry file calls root)))))))))))

;;; REQ: REQ-CON-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CON-002-series-log-binding-duplicate-factory-even-other-registry
  (series-binding-fresh-log
   (lambda (log file calls)
     (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 2))
            (other (arcdocdb.csn:crea-registro-csn :capacity 2))
            (root (series-root 19 nil))
            (controller (crea-controllore-serie
                         registry log :capacity 2 :root root :next-offset 137)))
       (is (not (eq registry other)))
       (dolist (candidate (list registry other))
         (let ((before (series-image (list controller registry other log file calls root))))
           (signals invalid-argument
             (crea-controllore-serie candidate log :capacity 1 :root :other :next-offset 0)
             :serie-log-bound)
           (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
           (is (series-image-equal
                before (series-image (list controller registry other log file calls root))))))
       (let ((lease (acquisisci-controllore-serie controller)))
         (unwind-protect
              (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
           (rilascia-controllore-serie controller lease)))
       (signals invalid-argument (crea-controllore-serie other log) :serie-log-bound)
       (is (eq controller (arcdocdb.series:trova-controllore-serie log)))))))

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-008-series-log-binding-invalid-config-precedes-binding
  ;; Osserva precedenza, sorgenti intatte e assenza di binding sul log vergine.
  ;; Non misura le allocazioni e non sostituisce i costruttori di prodotto.
  (dolist (bound '(nil t))
    (series-binding-fresh-log
     (lambda (log file calls)
       (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 1))
              (controller (when bound (crea-controllore-serie registry log :capacity 1)))
              (before (series-image (list registry log file calls))))
         (dolist (options
                  (append (loop for value in (list 0 -1 1025 (1+ most-positive-fixnum) nil :bad 1/2)
                                collect (list :capacity value))
                          (loop for value in (list -1 (1+ most-positive-fixnum) nil :bad 1/2)
                                collect (list :next-offset value))))
           (signals invalid-argument
             (apply #'crea-controllore-serie registry log options) :serie-budget)
           (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
           (is (series-image-equal before (series-image (list registry log file calls)))))
         (unless bound
           (let ((created (crea-controllore-serie registry log :capacity 1)))
             (is (eq created (arcdocdb.series:trova-controllore-serie log))))))))))

;;; REQ: REQ-CON-002 REQ-WAL-005 REQ-AFF-004
(deftest test-REQ-CON-002-series-log-binding-rejects-nonsegment-before-binding
  (dolist (kind '(:control :multiserie))
    (series-binding-fresh-log
     (lambda (log file calls)
       (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 1))
              (before (series-image (list registry log file calls))))
         (is (null (arcdocdb.series:trova-controllore-serie log)))
         (signals invalid-argument
           (crea-controllore-serie registry log :capacity 1) :log-segment-kind)
         (is (null (arcdocdb.series:trova-controllore-serie log)))
         (is (series-image-equal before (series-image (list registry log file calls))))))
     :kind kind)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001
(deftest test-REQ-CON-002-series-log-binding-new-canonical-log-independent
  (series-binding-fresh-log
   (lambda (log file calls)
     (declare (ignore file calls))
     (series-binding-fresh-log
      (lambda (other-log other-file other-calls)
        (declare (ignore other-file other-calls))
        (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 1))
               (first (crea-controllore-serie registry log :capacity 1)))
          ;; Stesso file-id/formato e registro: l'autorita e il singolo oggetto log.
          (is (not (eq log other-log)))
          (is (null (arcdocdb.series:trova-controllore-serie other-log)))
          (let ((second (crea-controllore-serie registry other-log :capacity 1)))
            (is (not (eq first second)))
            (is (eq first (arcdocdb.series:trova-controllore-serie log)))
            (is (eq second (arcdocdb.series:trova-controllore-serie other-log))))))))))

;;; REQ: REQ-AFF-009 REQ-CON-002 REQ-AFF-004
(defun series-binding-REQ-AFF-009-foreign-slot-fi (log controller foreign)
  "FI seriale dichiarata: slot foreign, condizione tipizzata e ripristino EQ."
  (let ((before (series-image (list log controller))))
    (unwind-protect
         (progn
           (setf (arcdocdb.wal::log-io-controller log) foreign)
           (signals invariant-violation
             (arcdocdb.series:trova-controllore-serie log) :serie-log-binding))
      (setf (arcdocdb.wal::log-io-controller log) controller))
    (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
    (is (series-image-equal before (series-image (list log controller))))))

;;; REQ: REQ-AFF-009 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-009-series-log-binding-foreign-slot-fi-restored
  (series-binding-fresh-log
   (lambda (log file calls)
     (declare (ignore file calls))
     (series-binding-fresh-log
      (lambda (other-log other-file other-calls)
        (declare (ignore other-file other-calls))
        (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 1))
               (controller (crea-controllore-serie registry log :capacity 1))
               (foreign-controller (crea-controllore-serie registry other-log :capacity 1)))
          (dolist (foreign (list :foreign 17 #() (cons :foreign nil) foreign-controller))
            (series-binding-REQ-AFF-009-foreign-slot-fi log controller foreign)
            (is (eq foreign-controller
                    (arcdocdb.series:trova-controllore-serie other-log))))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-008
(defun series-binding-REQ-CON-004-race (log file calls worker-count distinct-registries)
  "Unica pubblicazione osservabile, osservatore getter e sorgenti intatte dopo join.
Nessuna pretesa di forzare un perdente precisamente dentro il CAS."
  (is (member worker-count '(2 4)))
  (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 2 :initial-low 23))
         (registries (make-array worker-count :initial-element registry))
         (root (series-root 71 nil))
         (results (make-array worker-count :initial-element nil))
         (observations (make-array worker-count :initial-element nil))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (published (sb-thread:make-semaphore)) (observed nil)
         (deadline (arcdocdb.csn.tests::csn-deadline 10)) (threads nil))
    (when distinct-registries
      (dotimes (i worker-count)
        (setf (svref registries i)
              (arcdocdb.csn:crea-registro-csn :capacity 2 :initial-low 23))))
    (is (null (arcdocdb.series:trova-controllore-serie log)))
    (let ((before (series-image (list registries file calls root))))
      (unwind-protect
           (progn
             (push (arcdocdb.csn.tests::csn-worker
                    "REQ-CON-004 Serie binding getter observer"
                    (lambda ()
                      (sb-thread:signal-semaphore ready)
                      (arcdocdb.csn.tests::csn-wait start deadline)
                      (arcdocdb.csn.tests::csn-wait published deadline)
                      (setf observed (arcdocdb.series:trova-controllore-serie log))
                      (is observed)
                      :ok)) threads)
             (dotimes (i worker-count)
               (let ((worker i))
                 (push (arcdocdb.csn.tests::csn-worker
                        (format nil "REQ-CON-002 Serie log binding ~D/~D" worker worker-count)
                        (lambda ()
                          (sb-thread:signal-semaphore ready)
                          (arcdocdb.csn.tests::csn-wait start deadline)
                          (let ((result
                                  (handler-case
                                      (crea-controllore-serie
                                       (svref registries worker) log
                                       :capacity 2 :root root :next-offset 137)
                                    (invalid-argument (condition)
                                      (is (eq :serie-log-bound (error-reason condition)))
                                      :serie-log-bound))))
                            (setf (svref results worker) result)
                            (when (typep result 'arcdocdb.series:controllore-serie)
                              (sb-thread:signal-semaphore published))
                            (setf (svref observations worker)
                                  (arcdocdb.series:trova-controllore-serie log)))
                          :ok)) threads)))
             (dotimes (i (1+ worker-count))
               (arcdocdb.csn.tests::csn-wait ready deadline))
             (sb-thread:signal-semaphore start (1+ worker-count))
             (dolist (thread threads) (arcdocdb.csn.tests::csn-join thread deadline))
             (let* ((controller (arcdocdb.series:trova-controllore-serie log))
                    (position (position controller results :test #'eq)))
               (is controller)
               (is position)
               (is (= 1 (count controller results :test #'eq)))
               (is (= (1- worker-count) (count :serie-log-bound results)))
               (is (eq observed controller))
               (dotimes (i worker-count)
                 (is (eq controller (svref observations i))))
               (series-binding-initial-controller
                controller (svref registries position) log root 137 2))
             (is (series-image-equal before (series-image (list registries file calls root)))))
        (sb-thread:signal-semaphore start (1+ worker-count))
        (sb-thread:signal-semaphore published)
        (arcdocdb.csn.tests::csn-stop-workers threads)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-CON-004-series-log-binding-two-four-workers-one-publication-and-observer
  (dolist (version '(1 2))
    (dolist (workers '(2 4))
      (dolist (distinct-registries '(nil t))
        (series-binding-fresh-log
         (lambda (log file calls)
           (series-binding-REQ-CON-004-race log file calls workers distinct-registries))
         :version version)))))
