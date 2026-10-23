;;;; Routing ordinal: oracoli FIFO e identita indipendenti dagli indici del prodotto.
;;;; OWNER: contesto, tabella e links del singolo thread; registry solo dopo costruzione.
;;;; SHARED: registry immutabile, ready e controller nelle prove con handoff esplicito.
;;;; FI: accessor privati soltanto per preimage, corruzione dichiarata e cleanup.
(in-package #:arcdocdb.series.tests)

(defun routing-writer (items index &optional (quantum 1))
  "Fixture C4: un solo obbligo SCHEDULE per writer, nessun routing implicito."
  (let ((writer (arcdocdb.execution:crea-writer-programmabile
                 :capacity (max 4 (length items)) :quantum quantum :routing-index index)))
    (loop for item in items for count from 1
          do (arcdocdb.execution.tests::handoff-check-enqueue
              writer item count (if (= count 1) :schedule :queued)))
    writer))

(defun routing-release (f)
  "Cede la lease iniziale della fixture prima di qualunque begin del bridge."
  (rilascia-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
  (setf (series-fixture-lease f) nil))

(defun routing-make (writers controllers &optional ready)
  "Prealloca sul thread corrente; restituisce oggetti necessari agli oracoli."
  (let* ((queue (or ready (arcdocdb.execution:crea-lista-writer-pronti
                           :shards 1 :capacity 1)))
         (context (arcdocdb.execution:crea-contesto-worker-writer queue))
         (registry (arcdocdb.execution.series:crea-registro-worker-serie
                    writers controllers)))
    (values (arcdocdb.execution.series:crea-tabella-worker-serie context registry)
            context registry queue)))

(defun routing-lookup (table context writer)
  "Ogni lookup ripetuto conserva l'intero grafo e restituisce lo stesso link."
  (let* ((before (series-image (list table)))
         (link (arcdocdb.execution.series:collega-writer-worker-serie table)))
    (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
    (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
    (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
    (is (series-image-equal before (series-image (list table))))
    (is (eq link (arcdocdb.execution.series:collega-writer-worker-serie table)))
    (is (series-image-equal before (series-image (list table))))
    link))

(defun routing-phase-refusal (table objects)
  "Il lookup fuori CLAIMED rifiuta senza cambiare fasi, riferimenti o payload."
  (bridge-refusal objects
                  (lambda () (arcdocdb.execution.series:collega-writer-worker-serie table))
                  'resource-exhausted :worker-state))

(defun routing-fault (table context writer controllers &optional (reason :worker-serie-routing))
  "Guasto di binding prima di acquire: causa EQ, obbligo conservato, Serie intatte."
  (let* ((before (series-image controllers))
         (writer-before (series-image (list writer)))
         (condition (arcdocdb.execution.tests::worker-capture-condition
                     (lambda () (arcdocdb.execution.series:collega-writer-worker-serie table))
                     'invariant-violation reason)))
    (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
    (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
    (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
    (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
    (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
    (is (series-image-equal before (series-image controllers)))
    (is (series-image-equal writer-before (series-image (list writer))))
    ;; La tabella puo contenere una shape FI enorme; l'immagine del worker resta
    ;; bounded dal contesto, mentre i vettori FI sono verificati iterativamente.
    (routing-phase-refusal table (list context writer))
    (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
    condition))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-writer-ordinal-and-legacy-default
  (let ((legacy (arcdocdb.execution:crea-writer-programmabile))
        (first (routing-writer nil 0)) (last (routing-writer nil 65535)))
    (is (null (arcdocdb.execution:indice-routing-writer legacy)))
    (is (= 0 (arcdocdb.execution:indice-routing-writer first)))
    (is (= 65535 (arcdocdb.execution:indice-routing-writer last)))
    (dolist (invalid '(-1 65536 1/2 0.0 :zero #()))
      (signals invalid-argument
        (arcdocdb.execution:crea-writer-programmabile :routing-index invalid)
        :writer-configuration))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-registry-maximum-shape-reaches-entry-validation
  ;; Nessun controller/writer falso viene costruito: al budget massimo passa
  ;; la validazione shape, quindi il primo NIL e rifiutato come entry.
  (let ((writers (make-array 65536 :initial-element nil))
        (controllers (make-array 65536 :initial-element nil)))
    (signals invalid-argument
      (arcdocdb.execution.series:crea-registro-worker-serie writers controllers)
      :worker-serie-routing-binding)
    (is (every #'null writers)) (is (every #'null controllers))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-registry-rejects-shape-and-budget-without-effects
  (with-series (f)
    (let* ((writer (routing-writer '(:kept) 0))
           (controller (series-fixture-controller f))
           (valid-writers (vector writer)) (valid-controllers (vector controller))
           (adjustable (make-array 1 :initial-element writer :adjustable t))
           (displaced (make-array 1 :displaced-to valid-writers)))
      (dolist (pair (list (list nil valid-controllers) (list valid-writers nil)
                          (list (list writer) valid-controllers)
                          (list valid-writers (list controller))
                          (list "x" valid-controllers) (list adjustable valid-controllers)
                          (list displaced valid-controllers)
                          (list #() #())
                          (list valid-writers (vector controller controller))))
        (bridge-refusal (list f writer (first pair) (second pair))
                        (lambda () (arcdocdb.execution.series:crea-registro-worker-serie
                                     (first pair) (second pair)))
                        'invalid-argument :worker-serie-routing-configuration)))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-registry-oversize-refusal-has-iterative-preimage
  ;; Copie e confronto per cella, senza costruire liste profonde 65537 livelli.
  (with-series (f)
    (let* ((writer (routing-writer '(:kept) 0))
           (writers (make-array 65537 :initial-element writer))
           (controllers (make-array 65537 :initial-element (series-fixture-controller f)))
           (writer-copy (copy-seq writers)) (controller-copy (copy-seq controllers)))
      (bridge-refusal (list f writer)
                      (lambda () (arcdocdb.execution.series:crea-registro-worker-serie writers controllers))
                      'invalid-argument :worker-serie-routing-configuration)
      (is (= 65537 (length writers))) (is (= 65537 (length controllers)))
      (dotimes (i 65537)
        (is (eq (svref writer-copy i) (svref writers i)))
        (is (eq (svref controller-copy i) (svref controllers i)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-routing-corrupt-private-shape-rejects-before-lease
  ;; FI quiescente via costruttori privati, senza mutare gli slot read-only validi.
  ;; Registry/table malformati non sono mai pubblicati ad altri worker.
  (dolist (scenario '(:registry-empty :registry-oversize :controllers-short :links-short :links-long))
    (with-series (f)
      (routing-release f)
      (let ((writer (routing-writer '(:kept) 0)))
        (multiple-value-bind (table context registry ready)
            (routing-make (vector writer) (vector (series-fixture-controller f)))
          (declare (ignore ready))
          (let* ((large (when (eq scenario :registry-oversize)
                          (make-array 65537 :initial-element nil)))
                 (bad-registry
                   (case scenario
                     (:registry-empty (arcdocdb.execution.series::%make-registro-worker-serie #() #()))
                     (:registry-oversize (arcdocdb.execution.series::%make-registro-worker-serie large large))
                     (:controllers-short
                      (arcdocdb.execution.series::%make-registro-worker-serie (vector writer) #()))
                     (otherwise registry)))
                 (bad-links
                   (case scenario
                     (:links-short #())
                     (:links-long (vector (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0) nil))
                     (otherwise (arcdocdb.execution.series::tabella-worker-serie-links table))))
                 (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                             context bad-registry bad-links)))
            (when (member scenario '(:registry-empty :registry-oversize :controllers-short))
              (bridge-refusal (list context writer f)
                              (lambda () (arcdocdb.execution.series:crea-tabella-worker-serie context bad-registry))
                              'invariant-violation :worker-serie-routing)
              (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
              (is (null (arcdocdb.execution:errore-worker-writer context))))
            (arcdocdb.execution:adotta-writer-worker context writer 0)
            (routing-fault bad-table context writer (list (series-fixture-controller f)))
            (when large
              (is (= 65537 (length large)))
              (dotimes (i 65537) (is (null (svref large i)))))
            (series-healthy f)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-routing-selects-faulted-serie-for-explicit-drain
  (dolist (scope '(:serie :archive))
    (with-series (f)
      (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f) scope)
      (routing-release f)
      (let ((writer (routing-writer '(:drain) 0)))
        (multiple-value-bind (table context registry ready)
            (routing-make (vector writer) (vector (series-fixture-controller f)))
          (declare (ignore registry ready))
          (arcdocdb.execution:adotta-writer-worker context writer 0)
          (let* ((controller (series-fixture-controller f))
                 (before (series-image (list controller)))
                 (link (routing-lookup table context writer)))
            (is (series-image-equal before (series-image (list controller))))
            (series-faulted f scope)
            (let ((token (bridge-begin link :active)))
              (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:drain) :messages))
              (bridge-end link token :idle))
            (series-faulted f scope)
            (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
            (is (null (arcdocdb.execution:errore-worker-writer context)))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-registry-entry-types-and-exact-ordinals
  (with-series (left :file-id 31)
    (with-series (right :file-id 32)
      (let* ((zero (routing-writer '(:zero) 0)) (one (routing-writer '(:one) 1))
             (legacy (arcdocdb.execution:crea-writer-programmabile))
             (c0 (series-fixture-controller left)) (c1 (series-fixture-controller right)))
        (dolist (pair (list (list (vector nil) (vector c0))
                            (list (vector :writer) (vector c0))
                            (list (vector zero) (vector nil))
                            (list (vector zero) (vector :controller))
                            (list (vector legacy) (vector c0))
                            (list (vector one) (vector c0))
                            (list (vector one zero) (vector c0 c1))
                            (list (vector zero zero) (vector c0 c1))))
          (bridge-refusal (list left right legacy zero one (first pair) (second pair))
                          (lambda () (arcdocdb.execution.series:crea-registro-worker-serie
                                       (first pair) (second pair)))
                          'invalid-argument :worker-serie-routing-binding))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-routing-registry-refuses-controller-alias-before-any-lease
  (with-series (f)
    (let ((writers (vector (routing-writer '(:zero) 0) (routing-writer '(:one) 1)))
          (controllers (vector (series-fixture-controller f) (series-fixture-controller f))))
      (bridge-refusal (list f writers controllers)
                      (lambda () (arcdocdb.execution.series:crea-registro-worker-serie
                                   writers controllers))
                      'invalid-argument :worker-serie-routing-binding))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-routing-registry-copies-input-vectors-and-preserves-identities
  (with-series (left :file-id 31)
    (with-series (right :file-id 32)
      (routing-release left) (routing-release right)
      (let* ((w0 (routing-writer '(:zero) 0)) (w1 (routing-writer '(:one) 1))
             (c0 (series-fixture-controller left)) (c1 (series-fixture-controller right))
             (writers (vector w0 w1)) (controllers (vector c0 c1))
             (input-before (series-image (list writers controllers))))
        (multiple-value-bind (table context registry ready) (routing-make writers controllers)
          (declare (ignore ready))
          (is (series-image-equal input-before (series-image (list writers controllers))))
          (is (not (eq writers (arcdocdb.execution.series::registro-worker-serie-writers registry))))
          (is (not (eq controllers (arcdocdb.execution.series::registro-worker-serie-controllers registry))))
          (setf (svref writers 0) nil (svref writers 1) :changed
                (svref controllers 0) c1 (svref controllers 1) c0)
          (arcdocdb.execution:adotta-writer-worker context w0 0)
          (let* ((link (routing-lookup table context w0)) (token (bridge-begin link :active)))
            (is (eq c0 (arcdocdb.execution.series::collegamento-worker-serie-controller link)))
            (bridge-ack link token (bridge-pop link token (vector :left nil :right) 1 2 '(:zero) :messages))
            (bridge-end link token :idle))
          (arcdocdb.execution:adotta-writer-worker context w1 0)
          (let* ((link (routing-lookup table context w1)) (token (bridge-begin link :active)))
            (is (eq c1 (arcdocdb.execution.series::collegamento-worker-serie-controller link)))
            (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:one) :messages))
            (bridge-end link token :idle)))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-table-construction-requires-idle-owner
  (with-series (f)
    (let ((writer (routing-writer '(:one) 0)))
      (multiple-value-bind (table context registry ready)
          (routing-make (vector writer) (vector (series-fixture-controller f)))
        (declare (ignore ready))
        (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
        (routing-phase-refusal table (list table f))
        (arcdocdb.execution:adotta-writer-worker context writer 0)
        (bridge-refusal (list table f)
                        (lambda () (arcdocdb.execution.series:crea-tabella-worker-serie context registry))
                        'resource-exhausted :worker-state)
        (is (eq writer (arcdocdb.execution:writer-worker-writer context)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-ready-full-recycle-switches-series-and-preserves-fifo
  (with-series (left :file-id 31)
    (with-series (right :file-id 32)
      (routing-release left) (routing-release right)
      (let* ((a (vector :a)) (b (vector :b)) (x (vector :x)) (y (vector :y))
             (w0 (routing-writer (list a b) 0)) (w1 (routing-writer (list x y) 1)))
        (multiple-value-bind (table context registry ready)
            (routing-make (vector w0 w1) (vector (series-fixture-controller left)
                                               (series-fixture-controller right)))
          (declare (ignore registry))
          (arcdocdb.execution.tests::ready-check-publish ready 0 w0 1)
          (arcdocdb.execution.tests::worker-check-claim context w0 :claimed 0)
          (arcdocdb.execution.tests::ready-check-publish ready 0 w1 1)
          (let ((first nil) (second nil))
            (loop for writer in (list w0 w1 w0 w1) for item in (list a x b y)
                  for action in '(:schedule :schedule :idle :idle)
                  for step from 0
                  do (let* ((link (routing-lookup table context writer))
                            (token (bridge-begin link :active)))
                       (if (evenp step)
                           (if first (is (eq first link)) (setf first link))
                           (if second (is (eq second link)) (setf second link)))
                       (bridge-ack link token (bridge-pop link token (vector :left nil :right)
                                                         1 2 (list item) :messages))
                       (bridge-end link token action)
                       (case step
                         (0 (arcdocdb.execution.tests::worker-check-recycle context w1 :claimed 1))
                         (1 (arcdocdb.execution.tests::worker-check-recycle context w0 :claimed 1))
                         (2 (arcdocdb.execution.tests::worker-check-claim context w1 :claimed 0))))
                  finally (is (not (eq first second))))
            (arcdocdb.execution.tests::worker-check-claim context nil :empty 0)))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-routing-unknown-unrouted-and-out-of-range-retain-obligation
  (dolist (scenario '(:legacy :different-identity :out-of-range))
    (with-series (f)
      (routing-release f)
      (let* ((registered (routing-writer '(:registered) 0))
             (claimed (ecase scenario
                        (:legacy (arcdocdb.execution.tests::worker-test-writer '(:legacy)))
                        (:different-identity (routing-writer '(:other) 0))
                        (:out-of-range (routing-writer '(:range) 1)))))
        (multiple-value-bind (table context registry ready)
            (routing-make (vector registered) (vector (series-fixture-controller f)))
          (declare (ignore registry ready))
          (arcdocdb.execution:adotta-writer-worker context claimed 0)
          (routing-fault table context claimed (list (series-fixture-controller f)))
          (series-healthy f))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-routing-corrupt-link-is-detected-before-lease-or-pop
  (dolist (scenario '(:nil :wrong-writer :wrong-context :wrong-controller :active
                     :fault :writer-lease :series-lease))
    (with-series (left :file-id 31)
      (with-series (right :file-id 32)
        (routing-release left) (routing-release right)
        (let ((writer (routing-writer '(:kept) 0)))
          (multiple-value-bind (table context registry ready)
              (routing-make (vector writer) (vector (series-fixture-controller left)))
            (declare (ignore registry))
            (arcdocdb.execution:adotta-writer-worker context writer 0)
            (let* ((links (arcdocdb.execution.series::tabella-worker-serie-links table))
                   (link (svref links 0)))
              (ecase scenario
                (:nil (setf (svref links 0) nil))
                (:wrong-writer
                 (setf (svref links 0) (arcdocdb.execution.series:crea-collegamento-worker-serie
                                        context (routing-writer '(:wrong) 0)
                                        (series-fixture-controller left))))
                (:wrong-context
                 (setf (svref links 0) (arcdocdb.execution.series:crea-collegamento-worker-serie
                                        (arcdocdb.execution:crea-contesto-worker-writer ready)
                                        writer (series-fixture-controller left))))
                (:wrong-controller
                 (setf (svref links 0) (arcdocdb.execution.series:crea-collegamento-worker-serie
                                        context writer (series-fixture-controller right))))
                (:active (setf (arcdocdb.execution.series::collegamento-worker-serie-state link) :active))
                (:fault (setf (arcdocdb.execution.series::collegamento-worker-serie-fault link)
                              (make-condition 'simple-error :format-control "FI routing link")))
                (:writer-lease
                 (setf (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link) 1))
                (:series-lease
                 (setf (arcdocdb.execution.series::collegamento-worker-serie-series-lease link) 1)))
              (routing-fault table context writer
                             (list (series-fixture-controller left) (series-fixture-controller right))
                             (case scenario
                               (:fault :worker-serie-state)
                               ((:writer-lease :series-lease) :worker-serie-lease)
                               (otherwise :worker-serie-routing)))
              (series-healthy left) (series-healthy right))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-lookup-rejects-running-batch-and-reschedule
  (with-series (f)
    (routing-release f)
    (let ((one (vector :one)) (two (vector :two)))
      (multiple-value-bind (table context registry ready)
          (routing-make (vector (routing-writer (list one two) 0))
                        (vector (series-fixture-controller f)))
        (declare (ignore registry ready))
        (let ((writer (svref (arcdocdb.execution.series::registro-worker-serie-writers
                              (arcdocdb.execution.series::tabella-worker-serie-registry table)) 0)))
          (arcdocdb.execution:adotta-writer-worker context writer 0)
          (let* ((link (routing-lookup table context writer)) (token (bridge-begin link :active))
                 (target (vector nil)))
            (routing-phase-refusal table (list table f target))
            (let ((batch (bridge-pop link token target 0 1 (list one) :messages)))
              (routing-phase-refusal table (list table f target))
              (bridge-ack link token batch))
            (bridge-end link token :schedule)
            (routing-phase-refusal table (list table f target))
            (arcdocdb.execution.tests::worker-check-recycle context nil :published 1)
            (routing-phase-refusal table (list table f target))
            (arcdocdb.execution.tests::worker-check-claim context writer :claimed 0)
            (is (eq link (routing-lookup table context writer)))
            (let ((next (bridge-begin link :active)))
              (bridge-ack link next (bridge-pop link next target 0 1 (list two) :messages))
              (bridge-end link next :idle))))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-routing-lookup-rejects-finishing-without-changing-debt
  (with-series (f)
    (routing-release f)
    (let ((writer (routing-writer '(:one) 0)))
      (multiple-value-bind (table context registry ready)
          (routing-make (vector writer) (vector (series-fixture-controller f)))
        (declare (ignore registry ready))
        (arcdocdb.execution:adotta-writer-worker context writer 0)
        (let* ((link (routing-lookup table context writer)) (token (bridge-begin link :active))
               (queue (arcdocdb.execution::writer-programmabile-queue writer)))
          (bridge-ack link token (bridge-pop link token (vector nil) 0 1 '(:one) :messages))
          (arcdocdb.execution.tests::with-execution-guard (queue)
            (signals resource-exhausted
              (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
            (is (eq :finishing (arcdocdb.execution:stato-worker-writer context)))
            (routing-phase-refusal table (list table f)))
          (bridge-end link token :idle))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-routing-foreign-owner-factory-and-lookup-preserve-all-fields
  (with-series (f)
    (let ((writer (routing-writer '(:one) 0)))
      (multiple-value-bind (table context registry ready)
          (routing-make (vector writer) (vector (series-fixture-controller f)))
        (declare (ignore ready))
        (arcdocdb.execution:adotta-writer-worker context writer 0)
        (let ((deadline (series-deadline 5)) (threads nil))
          (unwind-protect
               (progn
                 (push (series-worker
                        "routing foreign owner"
                        (lambda ()
                          (bridge-refusal (list table f)
                                          (lambda () (arcdocdb.execution.series:crea-tabella-worker-serie
                                                       context registry))
                                          'invalid-argument :worker-owner)
                          (bridge-refusal (list table f)
                                          (lambda () (arcdocdb.execution.series:collega-writer-worker-serie table))
                                          'invalid-argument :worker-owner)
                          :ok)) threads)
                 (series-join (first threads) deadline)
                 (routing-lookup table context writer))
            (series-stop-workers threads)))))))

(defun routing-parallel-worker (registry ready acquired release deadline results slot expected)
  "Un contesto e tabella per thread; lease tenuta fino all'arrivo di entrambi."
  (let* ((context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (table (arcdocdb.execution.series:crea-tabella-worker-serie context registry)))
    (multiple-value-bind (writer status cursor) (arcdocdb.execution:prendi-writer-worker context)
      (is (eq :claimed status)) (is (zerop cursor))
      (let* ((index (arcdocdb.execution:indice-routing-writer writer))
             (link (routing-lookup table context writer)) (token (bridge-begin link :active)))
        (is (member index '(0 1)))
        (setf (svref results slot) (list :active index link table))
        (sb-thread:signal-semaphore acquired)
        (series-wait release deadline)
        (bridge-ack link token (bridge-pop link token (vector :left nil :right)
                                          1 2 (list (svref expected index)) :messages))
        (bridge-end link token :idle)
        :ok))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-routing-shared-registry-ready-two-series-active-in-parallel
  (with-series (left :file-id 31)
    (with-series (right :file-id 32)
      (routing-release left) (routing-release right)
      (let* ((items (vector (vector :left-item) (vector :right-item)))
             (writers (vector (routing-writer (list (svref items 0)) 0)
                              (routing-writer (list (svref items 1)) 1)))
             (registry (arcdocdb.execution.series:crea-registro-worker-serie
                        writers (vector (series-fixture-controller left)
                                        (series-fixture-controller right))))
             (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
             (acquired (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
             (results (vector nil nil)) (deadline (series-deadline 5)) (threads nil))
        (dotimes (i 2) (arcdocdb.execution.tests::ready-check-publish ready 0 (svref writers i) (1+ i)))
        (unwind-protect
             (progn
               ;; Il secondo claim parte dopo il primo: nessun retry implicito su ready busy.
               (push (series-worker "routing shared registry first"
                                    (lambda () (routing-parallel-worker registry ready acquired release
                                                                       deadline results 0 items))) threads)
               (series-wait acquired deadline)
               (push (series-worker "routing shared registry second"
                                    (lambda () (routing-parallel-worker registry ready acquired release
                                                                       deadline results 1 items))) threads)
               (series-wait acquired deadline)
               (is (eq :active (first (svref results 0))))
               (is (eq :active (first (svref results 1))))
               (is (= 0 (second (svref results 0)))) (is (= 1 (second (svref results 1))))
               (is (not (eq (third (svref results 0)) (third (svref results 1)))))
               (is (not (eq (fourth (svref results 0)) (fourth (svref results 1)))))
               (sb-thread:signal-semaphore release 2)
               (dolist (thread threads) (series-join thread deadline))
               (dolist (f (list left right))
                 (setf (series-fixture-lease f) (acquisisci-controllore-serie (series-fixture-controller f)))
                 (series-counts f 0 0 0) (series-healthy f)))
          (sb-thread:signal-semaphore release 2)
          (series-stop-workers threads))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-routing-lookup-reason-cannot-bypass-terminal-boundary
  ;; FI quiescente: lookup solo CLAIMED, nessuna lease posseduta; restore sempre.
  ;; :WORKER-STATE e ordinario soltanto nel gate di fase, non nel lookup interno.
  (dolist (helper '(arcdocdb.execution.series::%routing-ordinal
                    arcdocdb.execution.series::%routing-link))
    (with-series (f)
      (routing-release f)
      (let ((writer (routing-writer '(:kept) 0)))
        (multiple-value-bind (table context registry ready)
            (routing-make (vector writer) (vector (series-fixture-controller f)))
          (declare (ignore registry ready))
          (arcdocdb.execution:adotta-writer-worker context writer 0)
          (let* ((original (make-condition 'resource-exhausted :reason :worker-state))
                 (saved (fdefinition helper))
                 (before (series-image (list f writer)))
                 (home (arcdocdb.execution::contesto-worker-writer-home context)))
            (unwind-protect
                 (progn
                   (setf (fdefinition helper)
                         (lambda (&rest arguments) (declare (ignore arguments)) (error original)))
                   (is (eq original
                           (arcdocdb.execution.tests::worker-capture-condition
                            (lambda () (arcdocdb.execution.series:collega-writer-worker-serie table))
                            'resource-exhausted :worker-state)))
                   (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
                   (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
                   (is (= home (arcdocdb.execution::contesto-worker-writer-home context)))
                   (is (eq original (arcdocdb.execution:errore-worker-writer context)))
                   (is (series-image-equal before (series-image (list f writer))))
                   (routing-phase-refusal table (list table f writer))
                   (is (eq original (arcdocdb.execution:errore-worker-writer context))))
              (setf (fdefinition helper) saved))))))))
