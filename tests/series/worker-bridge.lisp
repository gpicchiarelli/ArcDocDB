;;;; Bridge worker/Serie: FIFO e token attesi non leggono gli indici del prodotto.
;;;; OWNER: ogni collegamento appartiene al thread che crea il suo contesto worker.
;;;; SHARED: soltanto controller, registry e semafori dichiarati nei test concorrenti.
;;;; FI: accessor privati solo per immagini di rifiuto, limiti e cleanup della fixture.
;;;; Nessun thread, retry o callback della fixture viene aggiunto al prodotto.
(in-package #:arcdocdb.series.tests)

(defun bridge-make (f items &optional (quantum 1))
  "Fixture C4: cede la lease iniziale e adotta una sola volta l'obbligo writer."
  (when (series-fixture-lease f)
    (rilascia-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
    (setf (series-fixture-lease f) nil))
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (arcdocdb.execution.tests::worker-test-writer items quantum))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (arcdocdb.execution:adotta-writer-worker context writer 0)
    (values (arcdocdb.execution.series:crea-collegamento-worker-serie
             context writer (series-fixture-controller f))
            context writer ready)))

(defun bridge-state (link context phase worker-phase writer)
  "Verifica le fasi pubbliche senza usare lo stato privato come oracolo."
  (is (eq phase (arcdocdb.execution.series:stato-worker-serie link)))
  (is (eq worker-phase (arcdocdb.execution:stato-worker-writer context)))
  (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
  (unless (eq phase :faulted)
    (is (null (arcdocdb.execution.series:errore-worker-serie link)))
    (is (null (arcdocdb.execution:errore-worker-writer context)))))

(defun bridge-begin (link expected &optional (expected-reason (when (eq expected :closing) :serie-busy)))
  "Il token di tratto e positivo anche quando la seconda acquisizione rifiuta."
  (multiple-value-bind (token status reason) (arcdocdb.execution.series:inizia-worker-serie link)
    (is (and (typep token 'fixnum) (plusp token)))
    (is (eq expected status))
    (is (eq expected-reason reason))
    token))

(defun bridge-pop (link token target start end expected status)
  "Oracolo FIFO per EQ, comprese tutte le celle caller non scritte."
  (let ((before (copy-seq target)))
    (multiple-value-bind (count actual batch)
        (arcdocdb.execution.series:preleva-worker-serie link token target start end)
      (is (= count (length expected))) (is (eq actual status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      (if (eq status :messages)
          (is (and (typep batch 'fixnum) (plusp batch)))
          (is (zerop batch)))
      batch)))

(defun bridge-ack (link token batch)
  "Il caller ha applicato l'intero batch prima di confermare il debito."
  (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch))))

(defun bridge-end (link token action)
  "Verifica il trasferimento finale esplicito, senza ricircolo implicito."
  (is (eq action (arcdocdb.execution.series:termina-worker-serie link token))))

(defun bridge-refusal (objects thunk type reason)
  "Immagine completa prima/dopo un rifiuto ordinario: anche payload e identita."
  (let ((before (series-image objects)))
    (series-error thunk type reason)
    (is (series-image-equal before (series-image objects)))))

(defun bridge-closed-refusals (link token target)
  "CLOSING consente solo termine, senza reacquire o nuovi pop/ack."
  (signals resource-exhausted (arcdocdb.execution.series:inizia-worker-serie link)
           :worker-serie-state)
  (signals resource-exhausted (arcdocdb.execution.series:lease-worker-serie link token)
           :worker-serie-state)
  (signals resource-exhausted
    (arcdocdb.execution.series:preleva-worker-serie link token target 0 1)
    :worker-serie-state)
  (signals resource-exhausted
    (arcdocdb.execution.series:conferma-worker-serie link token 1) :worker-serie-state))

(defun bridge-check-fault (f link context writer token condition &optional (scope :archive))
  "Fault terminale conserva la condizione originale in entrambi i contesti."
  (bridge-state link context :faulted :faulted writer)
  (is (eq condition (arcdocdb.execution.series:errore-worker-serie link)))
  (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
  (if (eq scope :none) (series-healthy f) (series-faulted f scope))
  (let ((before (series-image (list f link))))
    (signals resource-exhausted (arcdocdb.execution.series:inizia-worker-serie link)
             :worker-serie-state)
    (signals resource-exhausted (arcdocdb.execution.series:lease-worker-serie link token)
             :worker-serie-state)
    (signals resource-exhausted
      (arcdocdb.execution.series:preleva-worker-serie link token nil 0 1)
      :worker-serie-state)
    (signals resource-exhausted
      (arcdocdb.execution.series:conferma-worker-serie link token nil) :worker-serie-state)
    (signals resource-exhausted
      (arcdocdb.execution.series:termina-worker-serie link token) :worker-serie-state)
    (is (series-image-equal before (series-image (list f link)))))
  (is (eq condition (arcdocdb.execution.series:errore-worker-serie link))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-001-worker-serie-double-lease-fifo-ack-and-idle
  (with-series (f)
    (let ((one (vector :one)) (two (vector :two)))
      (multiple-value-bind (link context writer ready) (bridge-make f (list one two) 2)
        (declare (ignore ready))
        (bridge-state link context :idle :claimed writer)
        (let* ((token (bridge-begin link :active))
               (lease (arcdocdb.execution.series:lease-worker-serie link token))
               (target (vector :left :x :y :right)))
          (bridge-state link context :active :running writer)
          (is (equal '(0 0 0) (multiple-value-list
                              (conta-commit-serie (series-fixture-controller f) lease))))
          (bridge-ack link token (bridge-pop link token target 1 3 (list one two) :messages))
          (bridge-pop link token target 1 3 nil :yield)
          (bridge-end link token :idle)
          (bridge-state link context :idle :idle nil)
          (signals invalid-argument
            (conta-commit-serie (series-fixture-controller f) lease) :serie-lease)
          (let ((later (acquisisci-controllore-serie (series-fixture-controller f))))
            (is (> later lease))
            (rilascia-controllore-serie (series-fixture-controller f) later)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-serie-quantum-rotation-monotone-tract-and-batch
  (with-series (f)
    (let ((items (list (vector 1) (vector 2) (vector 3))))
      (multiple-value-bind (link context writer ready) (bridge-make f items)
        (declare (ignore ready))
        (let ((previous-tract 0) (previous-batch 0) (previous-series 0))
          (loop for item in items for last = (eq item (third items))
                do (let* ((token (bridge-begin link :active))
                          (lease (arcdocdb.execution.series:lease-worker-serie link token))
                          (batch (bridge-pop link token (vector nil) 0 1 (list item) :messages)))
                     (is (> token previous-tract)) (is (> lease previous-series))
                     (is (> batch previous-batch))
                     (setf previous-tract token previous-series lease previous-batch batch)
                     (bridge-ack link token batch)
                     (bridge-end link token (if last :idle :schedule))
                     (bridge-state link context :idle (if last :idle :reschedule)
                                   (unless last writer))
                     (unless last
                       (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
                       (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)))))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-005-worker-serie-first-lease-busy-does-not-touch-serie
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:once))
      (declare (ignore ready))
      (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
        (arcdocdb.execution.tests::with-execution-guard (queue)
          (bridge-refusal (list f link)
                          (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
                          'resource-exhausted :writer-queue-busy)))
      (bridge-state link context :idle :claimed writer)
      (let ((token (bridge-begin link :active)))
        (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:once) :messages))
        (bridge-end link token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-005-worker-serie-second-lease-busy-closes-without-pop
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:once))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (held (acquisisci-controllore-serie controller)))
        (unwind-protect
             (let ((token (bridge-begin link :closing)) (target (vector :untouched)))
               (bridge-state link context :closing :running writer)
               (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
               (is (zerop (arcdocdb.execution::coda-writer-extracted
                           (arcdocdb.execution::writer-programmabile-queue writer))))
               (let ((before (series-image (list f link target))))
                 (bridge-closed-refusals link token target)
                 (is (series-image-equal before (series-image (list f link target)))))
               (bridge-end link token :schedule)
               (bridge-state link context :idle :reschedule writer)
               (is (equal '(0 0 0) (multiple-value-list (conta-commit-serie controller held)))))
          (rilascia-controllore-serie controller held)))
      (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
      (let ((token (bridge-begin link :active)))
        (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:once) :messages))
        (bridge-end link token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-serie-second-lease-busy-and-end-busy-keep-obligation
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:once))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (queue (arcdocdb.execution::writer-programmabile-queue writer))
             (held (acquisisci-controllore-serie controller))
             (token (bridge-begin link :closing)))
        (unwind-protect
             (progn
               (arcdocdb.execution.tests::with-execution-guard (queue)
                 (signals resource-exhausted
                   (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
                 (bridge-state link context :closing :finishing writer)
                 (let ((before (series-image (list f link))))
                   (bridge-closed-refusals link token (vector nil))
                   (signals resource-exhausted
                     (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
                   (is (series-image-equal before (series-image (list f link))))))
               (bridge-end link token :schedule)
               (bridge-state link context :idle :reschedule writer))
          (rilascia-controllore-serie controller held)))
      (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
      (let ((token (bridge-begin link :active)))
        (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:once) :messages))
        (bridge-end link token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-005-worker-serie-releases-serie-before-busy-writer-end
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:one :two) 2)
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (queue (arcdocdb.execution::writer-programmabile-queue writer))
             (token (bridge-begin link :active))
             (old (arcdocdb.execution.series:lease-worker-serie link token)))
        (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:one) :messages))
        (arcdocdb.execution.tests::with-execution-guard (queue)
          (signals resource-exhausted
            (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
          (bridge-state link context :closing :finishing writer)
          (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
          ;; La Serie e acquisibile mentre la guard writer impedisce ancora l'handoff.
          (let ((fresh (acquisisci-controllore-serie controller)))
            (unwind-protect
                 (progn
                   (is (> fresh old))
                   (signals invalid-argument (conta-commit-serie controller old) :serie-lease)
                   (let ((before (series-image (list f link))))
                     (bridge-closed-refusals link token (vector nil))
                     (signals resource-exhausted
                       (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
                     (is (series-image-equal before (series-image (list f link))))))
              (rilascia-controllore-serie controller fresh))))
        (bridge-end link token :schedule)
        (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
        (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
        (let ((next (bridge-begin link :active)))
          (bridge-ack link next (bridge-pop link next (vector nil) 0 1 '(:two) :messages))
          (bridge-end link next :idle))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-serie-batch-debt-and-stale-ack-retain-both-leases
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:one :two) 2)
      (declare (ignore ready))
      (let* ((token (bridge-begin link :active))
             (lease (arcdocdb.execution.series:lease-worker-serie link token))
             (batch (bridge-pop link token (vector nil) 0 1 '(:one) :messages)))
        (bridge-state link context :active :batch writer)
        (bridge-refusal (list f link)
                        (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                        'resource-exhausted :worker-state)
        (is (= lease (arcdocdb.execution.series:lease-worker-serie link token)))
        (dolist (bad (list nil 0 -1 1.0 :batch (1+ batch) (1+ most-positive-fixnum)))
          (bridge-refusal (list f link)
                          (lambda () (arcdocdb.execution.series:conferma-worker-serie link token bad))
                          'invalid-argument :worker-batch))
        (bridge-refusal (list f link)
                        (lambda () (arcdocdb.execution.series:preleva-worker-serie
                                     link token (vector nil) 0 1))
                        'resource-exhausted :worker-state)
        (bridge-ack link token batch)
        (let ((second (bridge-pop link token (vector nil) 0 1 '(:two) :messages)))
          (is (> second batch))
          (bridge-refusal (list f link)
                          (lambda () (arcdocdb.execution.series:conferma-worker-serie
                                       link token batch))
                          'invalid-argument :worker-batch)
          (bridge-ack link token second))
        (bridge-end link token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-serie-tract-token-refused-before-pop-ack-or-close
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:old :new))
      (declare (ignore ready))
      (let ((old (bridge-begin link :active)))
        (bridge-ack link old (bridge-pop link old (vector nil) 0 1 '(:old) :messages))
        (bridge-end link old :schedule)
        (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
        (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
        (let ((token (bridge-begin link :active)) (target (vector :untouched)))
          (is (> token old))
          (dolist (bad (list old 0 -1 nil 1.0 :tract (1+ token) (1+ most-positive-fixnum)))
            (dolist (operation
                      (list (lambda () (arcdocdb.execution.series:lease-worker-serie link bad))
                            (lambda () (arcdocdb.execution.series:preleva-worker-serie
                                         link bad target 0 1))
                            (lambda () (arcdocdb.execution.series:conferma-worker-serie link bad 1))
                            (lambda () (arcdocdb.execution.series:termina-worker-serie link bad))))
              (bridge-refusal (list f link target) operation 'invalid-argument :worker-serie-token)))
          (bridge-ack link token (bridge-pop link token target 0 1 '(:new) :messages))
          (bridge-end link token :idle))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-serie-target-span-and-alias-refusals-before-pop
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore context ready))
      (let ((token (bridge-begin link :active)) (target (vector :left :x :right)))
        (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
          (bridge-refusal (list f link target)
                          (lambda () (arcdocdb.execution.series:preleva-worker-serie
                                       link token target (first range) (second range)))
                          'invalid-argument :writer-target))
        (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                          (make-array 3 :adjustable t :initial-element :kept)
                          (arcdocdb.execution::coda-writer-slots
                           (arcdocdb.execution::writer-programmabile-queue writer))))
          (bridge-refusal (list f link target)
                          (lambda () (arcdocdb.execution.series:preleva-worker-serie
                                       link token bad 0 1))
                          'invalid-argument :writer-target))
        (bridge-ack link token (bridge-pop link token target 1 2 '(:kept) :messages))
        (bridge-end link token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-serie-static-binding-refuses-other-claimed-writer
  (with-series (f)
    (multiple-value-bind (right context writer ready) (bridge-make f '(:right))
      (declare (ignore ready))
      (let* ((other (arcdocdb.execution.tests::worker-test-writer '(:other)))
             (wrong (arcdocdb.execution.series:crea-collegamento-worker-serie
                     context other (series-fixture-controller f))))
        (bridge-refusal (list f right wrong)
                        (lambda () (arcdocdb.execution.series:inizia-worker-serie wrong))
                        'invalid-argument :worker-serie-binding)
        (bridge-state wrong context :idle :claimed writer)
        (let ((token (bridge-begin right :active)))
          (bridge-ack right token (bridge-pop right token (vector nil) 0 1 '(:right) :messages))
          (bridge-end right token :idle))
        (is (equal '(:other) (arcdocdb.execution.tests::handoff-drain other 1)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-local-generation-exhaustion-precedes-writer-begin
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      ;; FI quiescente: il budget e locale e la successiva acquisizione non lo azzera.
      (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link)
            most-positive-fixnum)
      (bridge-refusal (list f link)
                      (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
                      'resource-exhausted :worker-serie-generation)
      (bridge-state link context :idle :claimed writer)
      (let* ((fresh (arcdocdb.execution.series:crea-collegamento-worker-serie
                     context writer (series-fixture-controller f)))
             (token (bridge-begin fresh :active)))
        (bridge-ack fresh token (bridge-pop fresh token (vector nil) 0 1 '(:kept) :messages))
        (bridge-end fresh token :idle)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-controller-generation-limit-requires-explicit-close
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (saved (arcdocdb.series::controllore-serie-lease-generation controller)))
        (unwind-protect
             (progn
               (setf (arcdocdb.series::controllore-serie-lease-generation controller)
                     most-positive-fixnum)
               (let ((token (bridge-begin link :closing :serie-lease-generation)))
                 (bridge-state link context :closing :running writer)
                 (is (null (arcdocdb.series::controllore-serie-owner controller)))
                 (is (zerop (arcdocdb.execution::coda-writer-extracted
                             (arcdocdb.execution::writer-programmabile-queue writer))))
                 (bridge-end link token :schedule)
                 (bridge-state link context :idle :reschedule writer)))
          ;; Ripristino solo della FI; nessun reset o riuso di un contesto faulted.
          (setf (arcdocdb.series::controllore-serie-lease-generation controller) saved)))
      (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
      (let ((token (bridge-begin link :active)))
        (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:kept) :messages))
        (bridge-end link token :idle)))))

(defun bridge-foreign-probe (link context writer token)
  "Owner gate prima del handler: il thread straniero non puo osservare o avvelenare."
  (dolist (operation
            (list (lambda () (arcdocdb.execution.series:stato-worker-serie link))
                  (lambda () (arcdocdb.execution.series:errore-worker-serie link))
                  (lambda () (arcdocdb.execution.series:lease-worker-serie link token))
                  (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
                  (lambda () (arcdocdb.execution.series:preleva-worker-serie link token nil 0 1))
                  (lambda () (arcdocdb.execution.series:conferma-worker-serie link token nil))
                  (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                  (lambda () (arcdocdb.execution.series:crea-collegamento-worker-serie
                               context writer
                               (arcdocdb.execution.series::collegamento-worker-serie-controller link)))))
    (series-error operation 'invalid-argument :worker-owner)))

;;; REQ: REQ-CON-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CON-002-worker-serie-foreign-owner-in-idle-active-batch-and-closing
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:one :two) 2)
      (declare (ignore ready))
      (let ((go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore))
            (deadline (series-deadline 5)) (token 0) (threads nil))
        (unwind-protect
             (progn
               (push (series-worker
                      "bridge foreign owner"
                      (lambda ()
                        (dotimes (phase 4)
                          (series-wait go deadline)
                          (bridge-foreign-probe link context writer token)
                          (sb-thread:signal-semaphore done))
                        :ok)) threads)
               (labels ((probe ()
                          (let ((before (series-image (list f link))))
                            (sb-thread:signal-semaphore go)
                            (series-wait done deadline)
                            (is (series-image-equal before (series-image (list f link)))))))
                 (probe)
                 (setf token (bridge-begin link :active))
                 (probe)
                 (let ((batch (bridge-pop link token (vector nil) 0 1 '(:one) :messages)))
                   (probe) (bridge-ack link token batch))
                 (arcdocdb.execution.tests::with-execution-guard
                     ((arcdocdb.execution::writer-programmabile-queue writer))
                   (signals resource-exhausted
                     (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
                   (probe))
                 (bridge-end link token :schedule)
                 (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
                 (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
                 (setf token (bridge-begin link :active))
                 (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:two) :messages))
                 (bridge-end link token :idle))
               (series-join (first threads) deadline))
          (sb-thread:signal-semaphore go 4)
          (series-stop-workers threads))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-release-fault-retains-two-leases-and-original-condition
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (token (bridge-begin link :active))
             (series-lease (arcdocdb.execution.series:lease-worker-serie link token))
             (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
        ;; FI quiescente: rilascio con effetto locale incompleto e invariante Archive.
        (unwind-protect
             (progn
               (setf (arcdocdb.series::controllore-serie-effect-active controller) t)
               (let ((condition
                       (arcdocdb.execution.tests::worker-capture-condition
                        (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                        'invariant-violation :serie-effect)))
                 (bridge-check-fault f link context writer token condition)
                 (is (= series-lease
                        (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
                 (is (= writer-lease
                        (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
                 (is (eq sb-thread:*current-thread*
                         (arcdocdb.series::controllore-serie-owner controller)))
                 (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
                 (is (zerop (arcdocdb.execution::coda-writer-extracted
                             (arcdocdb.execution::writer-programmabile-queue writer))))))
          ;; Solo risorse della fixture: non ripara, resetta o riusa i contesti faulted.
          (setf (arcdocdb.series::controllore-serie-effect-active controller) nil)
          (rilascia-controllore-serie controller series-lease)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease))))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-error-between-releases-preserves-condition-and-writer
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (token (bridge-begin link :active))
             (lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
             (original (make-condition 'simple-error :format-control "FI between releases")))
        (unwind-protect
             (let ((caught
                     (series-call-with-function-fi
                      'arcdocdb.execution:termina-tratto-worker
                      (lambda (ignored) (declare (ignore ignored)) (error original))
                      (lambda ()
                        (arcdocdb.execution.tests::worker-capture-condition
                         (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                         'simple-error nil)))))
               (is (eq original caught))
               (bridge-check-fault f link context writer token original :none)
               (is (null (arcdocdb.series::controllore-serie-owner controller)))
               (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
               (is (= lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
               (is (eq :running (arcdocdb.execution::writer-programmabile-state writer))))
          ;; Libera soltanto la risorsa locale della fixture; non riusa il contesto faulted.
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-worker-serie-stale-controller-lease-never-poisons-new-owner
  (dolist (reacquire '(nil t))
    (with-series (f)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
        (declare (ignore ready))
        (let* ((controller (series-fixture-controller f))
               (token (bridge-begin link :active))
               (old (arcdocdb.execution.series:lease-worker-serie link token))
               (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
               (new nil))
          ;; FI di bypass pubblico: prima release mantiene generation, poi reacquire
          ;; cambia solo la generation rispetto al predicato owner/thread del bridge.
          (rilascia-controllore-serie controller old)
          (when reacquire (setf new (acquisisci-controllore-serie controller)))
          (unwind-protect
               (let* ((before (series-image (list controller)))
                      (condition
                        (arcdocdb.execution.tests::worker-capture-condition
                         (lambda () (arcdocdb.execution.series:lease-worker-serie link token))
                         'invalid-argument :serie-lease)))
                 (bridge-check-fault f link context writer token condition :none)
                 (is (series-image-equal before (series-image (list controller))))
                 (is (= old (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
                 (is (= writer-lease
                        (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
                 (when new
                   (is (> new old))
                   (is (equal '(0 0 0) (multiple-value-list (conta-commit-serie controller new))))))
            (when new (rilascia-controllore-serie controller new))
            ;; Cleanup separato della fixture: il contesto faulted resta terminale.
            (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease)))))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-worker-serie-owned-fault-three-independent-truth-pairs
  ;; A=lease>0, B=owner EQ current-thread, C=generation=lease.
  ;; False separati: gli altri due predicati restano veri, senza fault del bridge.
  ;; Il caso A falso usa generation0 soltanto nella FI quiescente; mai API owner.
  (dolist (scenario '(:all-true :lease-zero :owner-other :generation-stale))
    (with-series (f)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
        (declare (ignore context writer ready))
        (let* ((controller (series-fixture-controller f))
               (token (bridge-begin link :active))
               (lease (arcdocdb.execution.series:lease-worker-serie link token)))
          (unwind-protect
               (progn
                 (ecase scenario
                   (:all-true nil)
                   (:lease-zero
                    (setf (arcdocdb.execution.series::collegamento-worker-serie-series-lease link) 0
                          (arcdocdb.series::controllore-serie-lease-generation controller) 0))
                   (:owner-other (setf (arcdocdb.series::controllore-serie-owner controller) nil))
                   (:generation-stale
                    (setf (arcdocdb.series::controllore-serie-lease-generation controller) (1+ lease))))
                 (let ((before (series-image (list controller)
                                             :health-opaque (when (eq scenario :all-true)
                                                              (list controller)))))
                   (is (null (arcdocdb.execution.series::%fault-serie-posseduta link)))
                   (if (eq scenario :all-true) (series-faulted f :archive) (series-healthy f))
                   (is (series-image-equal
                        before (series-image (list controller)
                                             :health-opaque (when (eq scenario :all-true)
                                                              (list controller)))))))
            ;; Solo ripristino dei campi FI, prima di chiamare di nuovo le API lease.
            (setf (arcdocdb.execution.series::collegamento-worker-serie-series-lease link) lease
                  (arcdocdb.series::controllore-serie-lease-generation controller) lease
                  (arcdocdb.series::controllore-serie-owner controller) sb-thread:*current-thread*)
            (bridge-end link token :schedule)))))))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-boundary-once-values-and-exact-condition
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      (let ((evaluations 0)
            (expansion (macroexpand-1
                        '(arcdocdb.execution.series::%passo-worker-serie
                          ((bridge-boundary-link) (:worker-serie-state) (:worker-serie-token))
                          (values :a :b :c)))))
        (is (= 1 (arcdocdb.execution.tests::worker-tree-symbol-count
                  'bridge-boundary-link expansion)))
        (multiple-value-bind (a b c)
            (arcdocdb.execution.series::%passo-worker-serie
                ((progn (incf evaluations) link) (:worker-serie-state) (:worker-serie-token))
              (values :a :b :c))
          (is (eq a :a)) (is (eq b :b)) (is (eq c :c)))
        (is (= 1 evaluations))
        (dolist (condition (list (make-condition 'resource-exhausted :reason :worker-serie-state)
                                 (make-condition 'invalid-argument :reason :worker-serie-token)))
          (let ((before (series-image (list f link))))
            (is (eq condition
                    (arcdocdb.execution.tests::worker-capture-condition
                     (lambda ()
                       (arcdocdb.execution.series::%passo-worker-serie
                           (link (:worker-serie-state) (:worker-serie-token))
                         (error condition)))
                     (type-of condition) (error-reason condition))))
            (is (series-image-equal before (series-image (list f link))))))
        (let* ((token (bridge-begin link :active))
               (lease (arcdocdb.execution.series:lease-worker-serie link token))
               (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
               (original (make-condition 'simple-error :format-control "FI bridge boundary")))
          (unwind-protect
               (progn
                 (is (eq original
                         (arcdocdb.execution.tests::worker-capture-condition
                          (lambda ()
                            (arcdocdb.execution.series::%passo-worker-serie
                                (link (:worker-serie-state) (:worker-serie-token))
                              (error original)))
                          'simple-error nil)))
                 (bridge-check-fault f link context writer token original))
            (rilascia-controllore-serie (series-fixture-controller f) lease)
            (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease)))))))))

;;; REQ: REQ-CON-002 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-preserves-earlier-worker-fault-on-raw-begin
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:old))
      (declare (ignore ready))
      ;; FI di bypass pubblico: consuma l'obbligo prima del begin raw del worker.
      (is (equal '(:old) (arcdocdb.execution.tests::handoff-drain writer 1)))
      (let* ((original
               (arcdocdb.execution.tests::worker-capture-condition
                (lambda () (arcdocdb.execution:inizia-tratto-worker context))
                'resource-exhausted :writer-not-ready))
             (controller (series-fixture-controller f))
             (before (series-image (list controller))))
        (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))
        (let ((detected
                (arcdocdb.execution.tests::worker-capture-condition
                 (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
                 'invariant-violation :worker-state)))
          (bridge-state link context :faulted :faulted writer)
          (is (eq detected (arcdocdb.execution.series:errore-worker-serie link)))
          ;; La rilevazione successiva non sostituisce la causa originale nel worker.
          (is (eq original (arcdocdb.execution:errore-worker-writer context)))
          (is (not (eq detected original)))
          (series-healthy f)
          (is (series-image-equal before (series-image (list controller)))))
        (let ((snapshot (series-image (list f link))))
          (signals resource-exhausted
            (arcdocdb.execution.series:inizia-worker-serie link) :worker-serie-state)
          (is (series-image-equal snapshot (series-image (list f link)))))
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-acquire-boundary-unknown-reasons-never-remain-recoverable
  ;; Queste ragioni sono recuperabili in altri passi, ma non nel confine Serie.
  ;; FI prima dell'ownership: nessuna lease/controller scrittura viene fabbricata.
  (dolist (original (list (make-condition 'resource-exhausted :reason :writer-queue-busy)
                          (make-condition 'invalid-argument :reason :worker-serie-binding)
                          (make-condition 'io-fault :reason :fixture-acquire :operation :series)))
    (with-series (f)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
        (declare (ignore ready))
        (let* ((controller (series-fixture-controller f))
               (before (series-image (list controller)))
               (writer-lease nil))
          (unwind-protect
               (let ((caught
                       (series-call-with-function-fi
                        'arcdocdb.series:acquisisci-controllore-serie
                        (lambda (ignored) (declare (ignore ignored)) (error original))
                        (lambda ()
                          (arcdocdb.execution.tests::worker-capture-condition
                           (lambda () (arcdocdb.execution.series:inizia-worker-serie link))
                           (type-of original) (error-reason original))))))
                 (setf writer-lease
                       (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
                 (let ((token (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
                   (is (eq original caught))
                   (is (plusp token)) (is (plusp writer-lease))
                   (bridge-check-fault f link context writer token original :none)
                   (is (series-image-equal before (series-image (list controller))))
                   (is (null (arcdocdb.series::controllore-serie-owner controller)))
                   (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
                   (is (= writer-lease (arcdocdb.execution::contesto-worker-writer-lease context)))
                   (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
                   (is (zerop (arcdocdb.execution::coda-writer-extracted
                               (arcdocdb.execution::writer-programmabile-queue writer))))
                   (is (= 1 (arcdocdb.execution::coda-writer-count
                             (arcdocdb.execution::writer-programmabile-queue writer))))))
            ;; Solo lease della fixture: il bridge e il worker restano faulted.
            (when writer-lease
              (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease))))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-release-boundary-unknown-reasons-retain-both-leases
  ;; FI prima della release: ragioni recuperabili altrove non giustificano retry
  ;; della chiusura composta dopo un errore inatteso nel confine della Serie.
  (dolist (original (list (make-condition 'resource-exhausted :reason :writer-queue-busy)
                          (make-condition 'invalid-argument :reason :worker-serie-token)
                          (make-condition 'io-fault :reason :fixture-release :operation :series)))
    (with-series (f)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
        (declare (ignore ready))
        (let* ((controller (series-fixture-controller f))
               (token (bridge-begin link :active))
               (series-lease (arcdocdb.execution.series:lease-worker-serie link token))
               (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
               (before (series-image (list controller) :health-opaque (list controller))))
          (unwind-protect
               (let ((caught
                       (series-call-with-function-fi
                        'arcdocdb.series:rilascia-controllore-serie
                        (lambda (ignored lease) (declare (ignore ignored lease)) (error original))
                        (lambda ()
                          (arcdocdb.execution.tests::worker-capture-condition
                           (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                           (type-of original) (error-reason original))))))
                 (is (eq original caught))
                 (bridge-check-fault f link context writer token original)
                 (is (series-image-equal
                      before (series-image (list controller) :health-opaque (list controller))))
                 (is (= series-lease
                        (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
                 (is (= writer-lease
                        (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
                 (is (= writer-lease (arcdocdb.execution::contesto-worker-writer-lease context)))
                 (is (eq sb-thread:*current-thread*
                         (arcdocdb.series::controllore-serie-owner controller)))
                 (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
                 (is (= 1 (arcdocdb.execution::coda-writer-count
                           (arcdocdb.execution::writer-programmabile-queue writer))))
                 (is (zerop (arcdocdb.execution::coda-writer-extracted
                             (arcdocdb.execution::writer-programmabile-queue writer)))))
            ;; Release raw solo dopo il ripristino della funzione FI; nessun riuso.
            (rilascia-controllore-serie controller series-lease)
            (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease)))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-lower-worker-fault-cannot-match-benign-outer-token-reason
  (with-series (f)
    (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
      (declare (ignore ready))
      (let* ((controller (series-fixture-controller f))
             (token (bridge-begin link :active))
             (series-lease (arcdocdb.execution.series:lease-worker-serie link token))
             (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
             (target (vector :untouched))
             (original (make-condition 'invalid-argument :reason :worker-serie-token))
             (before (series-image (list controller) :health-opaque (list controller))))
        (unwind-protect
             (let ((caught
                     (series-call-with-function-fi
                      'arcdocdb.execution:preleva-lavori-writer
                      (lambda (ignored lease buffer start end)
                        (declare (ignore ignored lease buffer start end)) (error original))
                      (lambda ()
                        (arcdocdb.execution.tests::worker-capture-condition
                         (lambda () (arcdocdb.execution.series:preleva-worker-serie
                                      link token target 0 1))
                         'invalid-argument :worker-serie-token)))))
               (is (eq original caught))
               ;; La causa nasce sotto worker: la stessa ragione e attesa solo al gate esterno.
               (bridge-check-fault f link context writer token original)
               (is (series-image-equal
                    before (series-image (list controller) :health-opaque (list controller))))
               (is (equalp #(:untouched) target))
               (is (= series-lease
                      (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
               (is (= writer-lease
                      (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
               (is (= writer-lease (arcdocdb.execution::contesto-worker-writer-lease context)))
               (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
               (is (= 1 (arcdocdb.execution::coda-writer-count
                         (arcdocdb.execution::writer-programmabile-queue writer))))
               (is (zerop (arcdocdb.execution::coda-writer-extracted
                           (arcdocdb.execution::writer-programmabile-queue writer))))
               (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
               (is (zerop (arcdocdb.execution::contesto-worker-writer-batch-generation context))))
          (rilascia-controllore-serie controller series-lease)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease))))))))

;;; REQ: REQ-CON-002 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-serie-zero-active-generation-faults-only-owned-controller
  (dolist (phase '(:active :closing))
    (with-series (f)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:kept))
        (declare (ignore ready))
        (let* ((controller (series-fixture-controller f))
               (held (when (eq phase :closing) (acquisisci-controllore-serie controller)))
               (token (bridge-begin link phase))
               (series-lease (when (eq phase :active)
                               (arcdocdb.execution.series:lease-worker-serie link token)))
               (writer-lease (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
          (unwind-protect
               (progn
                 ;; FI: generation zero non puo essere un tratto avviato dal prodotto.
                 (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link) 0)
                 (let* ((before (series-image (list controller)
                                             :health-opaque (when series-lease (list controller))))
                        (condition
                          (arcdocdb.execution.tests::worker-capture-condition
                           (lambda () (arcdocdb.execution.series:termina-worker-serie link token))
                           'invariant-violation :worker-serie-generation)))
                   (bridge-check-fault f link context writer token condition
                                       (if series-lease :archive :none))
                   (is (series-image-equal
                        before (series-image (list controller)
                                             :health-opaque (when series-lease (list controller)))))
                   (is (= writer-lease
                          (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
                   (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))))
            (rilascia-controllore-serie controller (or held series-lease))
            (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease)))))))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-001
(deftest test-REQ-WAL-006-worker-serie-faulted-controller-still-drains-finished-io
  (with-series (f)
    (let* ((lot (series-seal f))
           (adopted (multiple-value-list (series-adopt f lot)))
           (event (first adopted)) (generation (second adopted))
           (group (series-group f lot)))
      (series-begin f event generation)
      (arcdocdb.wal:esegui-gruppo group)
      (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
      (series-faulted f :serie)
      (multiple-value-bind (link context writer ready) (bridge-make f '(:fine-io))
        (declare (ignore context writer ready))
        (let* ((token (bridge-begin link :active))
               (lease (arcdocdb.execution.series:lease-worker-serie link token)))
          (setf (series-fixture-lease f) lease)
          (unwind-protect
               (let ((batch (bridge-pop link token (vector nil) 0 1 '(:fine-io) :messages)))
                 ;; Esecuzione terminata sincrona della fixture, non solo stato WRITTEN.
                 (series-complete f event generation)
                 (series-annul f event generation 1)
                 (series-faulted f :serie)
                 (series-counts f 1 0 0)
                 (bridge-ack link token batch)
                 (bridge-end link token :idle))
            (setf (series-fixture-lease f) nil)))))))

(defun bridge-contender (f item acquired release deadline result index)
  "Una sola acquisizione, senza retry: la seconda Serie lease e busy oppure esclusiva."
  (multiple-value-bind (link context writer ready) (bridge-make f (list item))
    (declare (ignore ready))
    (multiple-value-bind (token status reason) (arcdocdb.execution.series:inizia-worker-serie link)
      (is (plusp token)) (setf (svref result index) status)
      (is (eq reason (when (eq status :closing) :serie-busy)))
      (sb-thread:signal-semaphore acquired)
      (series-wait release deadline)
      (case status
        (:active
         (let ((lease (arcdocdb.execution.series:lease-worker-serie link token)))
           (is (equal '(0 0 0) (multiple-value-list
                               (conta-commit-serie (series-fixture-controller f) lease)))))
         (bridge-ack link token (bridge-pop link token (vector nil) 0 1 (list item) :messages))
         (bridge-end link token :idle))
        (:closing
         (bridge-end link token :schedule)
         (bridge-state link context :idle :reschedule writer))
        (otherwise (error "Esito bridge concorrente inatteso: ~S" status)))
      :ok)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-worker-serie-two-writers-one-controller-have-one-active-lease
  (with-series (f)
    (rilascia-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
    (setf (series-fixture-lease f) nil)
    (let ((first-ready (sb-thread:make-semaphore)) (second-ready (sb-thread:make-semaphore))
          (release (sb-thread:make-semaphore)) (result (vector nil nil))
          (deadline (series-deadline 5)) (threads nil))
      (unwind-protect
           (progn
             (push (series-worker
                    "bridge same Serie first"
                    (lambda () (bridge-contender f (vector :one) first-ready release deadline result 0)))
                   threads)
             (series-wait first-ready deadline)
             (is (eq :active (svref result 0)))
             (push (series-worker
                    "bridge same Serie second"
                    (lambda () (bridge-contender f (vector :two) second-ready release deadline result 1)))
                   threads)
             (series-wait second-ready deadline)
             (is (eq :closing (svref result 1)))
             (sb-thread:signal-semaphore release 2)
             (dolist (thread threads) (series-join thread deadline))
             (setf (series-fixture-lease f) (acquisisci-controllore-serie (series-fixture-controller f)))
             (series-counts f 0 0 0)
             (series-healthy f))
        (sb-thread:signal-semaphore release 2)
        (series-stop-workers threads)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-worker-serie-independent-controllers-active-concurrently
  (with-series (left :file-id 31)
    (with-series (right :file-id 32)
      (dolist (f (list left right))
        (rilascia-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
        (setf (series-fixture-lease f) nil))
      (let ((acquired (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
            (result (vector nil nil)) (deadline (series-deadline 5)) (threads nil))
        (unwind-protect
             (progn
               (loop for f in (list left right) for index from 0
                     do (let ((fixture f) (slot index) (item (vector index)))
                          (push (series-worker
                                 (format nil "bridge distinct Serie ~D" slot)
                                 (lambda () (bridge-contender fixture item acquired release
                                                             deadline result slot))) threads)))
               ;; Entrambi i worker devono arrivare prima che qualunque lease sia rilasciata.
               (dotimes (worker 2) (series-wait acquired deadline))
               (is (equalp #(:active :active) result))
               (sb-thread:signal-semaphore release 2)
               (dolist (thread threads) (series-join thread deadline))
               (dolist (f (list left right))
                 (setf (series-fixture-lease f)
                       (acquisisci-controllore-serie (series-fixture-controller f)))
                 (series-counts f 0 0 0) (series-healthy f))
               (is (not (eq (leggi-radice-serie (series-fixture-controller left))
                            (leggi-radice-serie (series-fixture-controller right))))))
          (sb-thread:signal-semaphore release 2)
          (series-stop-workers threads))))))
