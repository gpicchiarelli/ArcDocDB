;;;; Begin pool: routing corrente e un solo begin composto, nessun lavoro implicito.
;;;; OWNER: porta, tabella, contesto e bridge sul creatore della fixture.
;;;; FI quiescenti: parole, limiti e sostituzioni temporanee sempre dichiarati.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-begin-check (dispatcher expected status reason)
  "Oracolo dei quattro valori pubblici; token positivo anche per CLOSING."
  (multiple-value-bind (link token actual refusal)
      (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher)
    (is (eq link expected)) (is (and (typep token 'fixnum) (plusp token)))
    (is (eq actual status)) (is (eq refusal reason)) token))

(defun pool-begin-claim (dispatcher context ready table writers &optional (ordinal 0))
  "Claim reale prima del nuovo ingresso; fixture attiva e ring a una partizione."
  (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers ordinal))))
  (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) ordinal)))
    (pool-dispatch-check dispatcher link :claimed 0 :unchanged)
    (is (eq :claimed (arcdocdb.execution:stato-worker-writer context))) link))

(defun pool-begin-without-work (thunk)
  "Sentinelle C4: nessun gate, ACK, claim, ricircolo, pop o chiusura nascosti."
  (labels ((protect (names)
             (if (null names) (funcall thunk)
                 (pool-claim-function-fi
                  (first names)
                  (lambda (&rest arguments) (declare (ignore arguments))
                    (error "Operazione implicita durante begin pool: ~S." (first names)))
                  (lambda () (protect (rest names)))))))
    (protect '(arcdocdb.scheduler:prendi-writer-pool
               arcdocdb.scheduler:applica-stato-worker-pool
               arcdocdb.execution:prendi-writer-worker
               arcdocdb.execution:ricircola-worker
               arcdocdb.execution.series:preleva-worker-serie
               arcdocdb.execution.series:termina-worker-serie))))

(defun pool-begin-refusal (dispatcher port table writers type reason)
  (pool-dispatch-refusal
   port table writers
   (lambda () (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher)) type reason))

(defun pool-begin-complete (link token item action)
  "Il caller applica e conferma il batch e termina esplicitamente il tratto."
  (is (null (arcdocdb.execution.series:conferma-worker-serie
             link token (pool-claim-bridge-pop link token item))))
  (is (eq action (arcdocdb.execution.series:termina-worker-serie link token))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-begin-real-active-forwards-four-values-without-pop
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (queue (arcdocdb.execution::writer-programmabile-queue (svref writers 0)))
           (original (fdefinition 'arcdocdb.execution.series:inizia-worker-serie))
           (calls 0) (token nil))
      (pool-begin-without-work
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution.series:inizia-worker-serie
          (lambda (selected) (is (eq link selected)) (incf calls) (funcall original selected))
          (lambda () (setf token (pool-begin-check dispatcher link :active nil))))))
      (is (= 1 calls))
      (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
      (is (eq :active (arcdocdb.execution.series:stato-worker-serie link)))
      (is (= 1 (arcdocdb.execution::coda-writer-count queue)))
      (is (zerop (arcdocdb.execution::coda-writer-extracted queue)))
      (is (plusp (arcdocdb.execution.series:lease-worker-serie link token)))
      (is (equal '(1 1 nil) (lifecycle-words port)))
      (signals resource-exhausted
        (arcdocdb.series:acquisisci-controllore-serie (svref controllers 0)) :serie-busy)
      (pool-begin-complete link token :a1 :idle)
      (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
      (is (null (arcdocdb.execution:writer-worker-writer context)))
      (let ((lease (arcdocdb.series:acquisisci-controllore-serie (svref controllers 0))))
        (arcdocdb.series:rilascia-controllore-serie (svref controllers 0) lease)))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-begin-full-recycle-starts-current-b-instead-of-previous-a
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable port))
    (pool-recycle-reschedule dispatcher context ready writers 0)
    (is (= 1 (arcdocdb.execution:pubblica-writer-pronto ready 0 (svref writers 1))))
    (let* ((links (arcdocdb.execution.series::tabella-worker-serie-links table))
           (left (svref links 0)) (right (svref links 1))
           (left-before (pool-dispatch-link-image left))
           (controller-before (pool-dispatch-series-image (svref controllers 0))))
      (pool-recycle-check dispatcher right :claimed 1)
      (let ((token (pool-begin-without-work
                    (lambda () (pool-begin-check dispatcher right :active nil)))))
        (is (not (eq left right)))
        (is (eq (svref writers 1) (arcdocdb.execution:writer-worker-writer context)))
        (is (equalp left-before (pool-dispatch-link-image left)))
        (is (equalp controller-before (pool-dispatch-series-image (svref controllers 0))))
        (let ((lease (arcdocdb.series:acquisisci-controllore-serie (svref controllers 0))))
          (arcdocdb.series:rilascia-controllore-serie (svref controllers 0) lease))
        (signals resource-exhausted
          (arcdocdb.series:acquisisci-controllore-serie (svref controllers 1)) :serie-busy)
        (pool-begin-complete right token :b1 :idle))
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-begin-complete left (pool-begin-check dispatcher left :active nil) :a2 :idle))))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-002-pool-begin-existing-claim-ignores-inactive-corrupt-and-retire-words
  (dolist (scenario '(:inactive :corrupt :retire))
    (with-pool-dispatch (dispatcher port context ready table writers controllers
                                   :active (not (eq scenario :inactive)) :left-items '(:a1))
      (declare (ignorable ready controllers))
      (is (null (arcdocdb.execution:adotta-writer-worker context (svref writers 0) 0)))
      ;; FI coordinator quiescente: comandi non validati da un obbligo gia CLAIMED.
      (case scenario
        (:corrupt (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4
                        (arcdocdb.scheduler::porta-worker-pool-ack port) 0))
        (:retire (setf (arcdocdb.scheduler::porta-worker-pool-request port) 2)))
      (let* ((words (lifecycle-words port))
             (link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0))
             (token (pool-begin-without-work
                     (lambda () (pool-begin-check dispatcher link :active nil)))))
        (is (equal words (lifecycle-words port)))
        (pool-begin-complete link token :a1 :idle)
        (is (equal words (lifecycle-words port))))
      (when (eq scenario :retire)
        (pool-dispatch-check dispatcher nil :inactive 0 :retired)
        (is (equal '(2 2 nil) (lifecycle-words port)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-begin-real-writer-busy-keeps-claimed-and-both-generations
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (let ((link (pool-begin-claim dispatcher context ready table writers)))
      (lifecycle-queue-busy
       (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
       (lambda ()
         (pool-begin-without-work
          (lambda () (pool-begin-refusal dispatcher port table writers
                                          'resource-exhausted :writer-queue-busy)))))
      (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
      (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
      (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
      (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-begin-real-serie-busy-returns-closing-with-explicit-close
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (controller (svref controllers 0))
           (held (arcdocdb.series:acquisisci-controllore-serie controller))
           (controller-before (pool-dispatch-series-image controller))
           (queue (arcdocdb.execution::writer-programmabile-queue (svref writers 0)))
           (original (fdefinition 'arcdocdb.series:acquisisci-controllore-serie))
           (calls 0))
      (unwind-protect
           (let ((token
                   (pool-begin-without-work
                    (lambda ()
                      (pool-claim-function-fi
                       'arcdocdb.series:acquisisci-controllore-serie
                       (lambda (selected) (incf calls) (funcall original selected))
                       (lambda () (pool-begin-check dispatcher link :closing :serie-busy)))))))
             (is (= 1 calls))
             (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
             (is (eq :closing (arcdocdb.execution.series:stato-worker-serie link)))
             (is (plusp (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link)))
             (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
             (is (= 1 (arcdocdb.execution::coda-writer-count queue)))
             (is (zerop (arcdocdb.execution::coda-writer-extracted queue)))
             (is (equalp controller-before (pool-dispatch-series-image controller)))
             (pool-begin-refusal dispatcher port table writers 'resource-exhausted :worker-state)
             (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
             (is (eq :reschedule (arcdocdb.execution:stato-worker-writer context)))
             (is (equalp controller-before (pool-dispatch-series-image controller))))
        (arcdocdb.series:rilascia-controllore-serie controller held))
      (pool-recycle-check dispatcher nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-serie-generation-limit-returns-token-and-explicit-close
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable port))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (controller (svref controllers 0))
           (saved (arcdocdb.series::controllore-serie-lease-generation controller))
           (queue (arcdocdb.execution::writer-programmabile-queue (svref writers 0))))
      (unwind-protect
           (progn
             ;; FI del limite, senza wrap o owner costruiti artificialmente.
             (setf (arcdocdb.series::controllore-serie-lease-generation controller)
                   most-positive-fixnum)
             (let* ((before (pool-dispatch-series-image controller))
                    (token (pool-begin-without-work
                            (lambda () (pool-begin-check dispatcher link :closing
                                                          :serie-lease-generation)))))
               (is (eq :closing (arcdocdb.execution.series:stato-worker-serie link)))
               (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
               (is (null (arcdocdb.series::controllore-serie-owner controller)))
               (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
               (is (= 1 (arcdocdb.execution::coda-writer-count queue)))
               (is (zerop (arcdocdb.execution::coda-writer-extracted queue)))
               (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
               (is (equalp before (pool-dispatch-series-image controller)))))
        (setf (arcdocdb.series::controllore-serie-lease-generation controller) saved))
      (pool-recycle-check dispatcher nil :published 1)
      (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
      (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-local-generation-limit-precedes-writer-and-serie-acquire
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (saved (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
      (unwind-protect
           (progn
             (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link)
                   most-positive-fixnum)
             (pool-begin-refusal dispatcher port table writers
                                 'resource-exhausted :worker-serie-generation))
        (setf (arcdocdb.execution.series::collegamento-worker-serie-generation link) saved))
      (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-binding-precedes-routing-and-any-acquisition
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (declare (ignorable controllers))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (other (arcdocdb.execution:crea-contesto-worker-writer ready))
           (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                       other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                       (arcdocdb.execution.series::tabella-worker-serie-links table)))
           (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
      (pool-claim-function-fi
       'arcdocdb.execution.series:collega-writer-worker-serie
       (lambda (routing) (declare (ignore routing)) (error "Routing dopo binding errato."))
       (lambda ()
         (pool-claim-function-fi
          'arcdocdb.execution.series:inizia-worker-serie
          (lambda (selected) (declare (ignore selected)) (error "Begin dopo binding errato."))
          (lambda () (pool-begin-refusal bad port table writers
                                          'invalid-argument :pool-dispatcher-binding)))))
      (is (eq :idle (arcdocdb.execution:stato-worker-writer other)))
      (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-begin-real-foreign-owner-precedes-binding-and-acquisitions
  (let ((worker (lifecycle-fixture-start t)) (dispatcher nil) (table nil) (writers nil)
        (left-file nil) (right-file nil))
    (unwind-protect
         (progn
           (lifecycle-call
            worker
            (lambda (owned)
              (multiple-value-bind (left resource) (pool-claim-series 87)
                (setf left-file resource)
                (multiple-value-bind (right resource) (pool-claim-series 88)
                  (setf right-file resource writers (vector (pool-claim-writer '(:a1) 0)
                                                           (pool-claim-writer '(:b1) 1))
                        table (arcdocdb.execution.series:crea-tabella-worker-serie
                               (lifecycle-fixture-context owned)
                               (arcdocdb.execution.series:crea-registro-worker-serie
                                writers (vector left right)))
                        dispatcher (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool
                                    (lifecycle-fixture-port owned) table))))
              (is (null (arcdocdb.execution:adotta-writer-worker
                         (lifecycle-fixture-context owned) (svref writers 0) 0))) :ok))
           (let* ((port (lifecycle-fixture-port worker))
                  (ready (pool-claim-ready (lifecycle-fixture-context worker)))
                  (other (arcdocdb.execution:crea-contesto-worker-writer ready))
                  (bad-table (arcdocdb.execution.series::%make-tabella-worker-serie
                              other (arcdocdb.execution.series::tabella-worker-serie-registry table)
                              (arcdocdb.execution.series::tabella-worker-serie-links table)))
                  (bad (arcdocdb.scheduler.dispatch::%make-dispatcher-writer-pool port bad-table)))
             ;; FI quiescente: owner viene prima di binding e parole invalide.
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 4)
             (pool-claim-function-fi
              'arcdocdb.execution.series:inizia-worker-serie
              (lambda (selected) (declare (ignore selected)) (error "Begin da owner straniero."))
              (lambda () (pool-begin-refusal bad port table writers
                                              'invalid-argument :pool-worker-owner)))
             (setf (arcdocdb.scheduler::porta-worker-pool-request port) 1))
           (lifecycle-call
            worker
            (lambda (owned)
              (declare (ignore owned))
              (let ((link (svref (arcdocdb.execution.series::tabella-worker-serie-links table) 0)))
                (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a1 :idle))
              :ok)))
      (when left-file
        (lifecycle-call worker (lambda (owned) (declare (ignore owned))
                                 (when right-file (arcdocdb.io:chiudi right-file))
                                 (arcdocdb.io:chiudi left-file) :ok)))
      (lifecycle-fixtures-stop (list worker)))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-pool-begin-six-wrong-phases-preserve-capacities-and-prior-fault
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable controllers))
    (flet ((refuse () (pool-begin-refusal dispatcher port table writers
                                           'resource-exhausted :worker-state)))
      (refuse)
      (let* ((link (pool-begin-claim dispatcher context ready table writers))
             (token (pool-begin-check dispatcher link :active nil)))
        (refuse)
        (let ((batch (pool-claim-bridge-pop link token :a1)))
          (refuse)
          (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch))))
        (lifecycle-queue-busy
         (arcdocdb.execution::writer-programmabile-queue (svref writers 0))
         (lambda ()
           (signals resource-exhausted
             (arcdocdb.execution.series:termina-worker-serie link token) :writer-queue-busy)
           (is (eq :finishing (arcdocdb.execution:stato-worker-writer context)))
           (refuse)))
        (is (eq :schedule (arcdocdb.execution.series:termina-worker-serie link token)))
        (refuse)
        (pool-recycle-check dispatcher nil :published 1)
        (arcdocdb.execution.tests::worker-check-claim context (svref writers 0) :claimed 0)
        (pool-begin-complete link (pool-begin-check dispatcher link :active nil) :a2 :idle))
      ;; FI diagnostica quiescente per la sesta fase, senza resettare un fault.
      (let ((original (make-condition 'invariant-violation :reason :worker-state)))
        (setf (arcdocdb.execution::contesto-worker-writer-state context) :faulted
              (arcdocdb.execution::contesto-worker-writer-fault context) original)
        (refuse)
        (is (eq original (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-routing-fault-precedes-begin-and-preserves-original-condition
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable ready))
    (let* ((unknown (pool-claim-writer '(:unknown) 2))
           (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown))
           (series-before (map 'list #'pool-dispatch-series-image controllers))
           (links-before (map 'list #'pool-dispatch-link-image
                              (arcdocdb.execution.series::tabella-worker-serie-links table))))
      (is (null (arcdocdb.execution:adotta-writer-worker context unknown 0)))
      (let ((condition
              (pool-claim-function-fi
               'arcdocdb.execution.series:inizia-worker-serie
               (lambda (selected) (declare (ignore selected)) (error "Begin dopo routing errato."))
               (lambda ()
                 (arcdocdb.execution.tests::worker-capture-condition
                  (lambda () (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher))
                  'invariant-violation :worker-serie-routing)))))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq unknown (arcdocdb.execution:writer-worker-writer context)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-pending context)))
        (is (equalp writer-before (arcdocdb.execution.tests::handoff-fi-snapshot unknown)))
        (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
        (is (equalp links-before (map 'list #'pool-dispatch-link-image
                                     (arcdocdb.execution.series::tabella-worker-serie-links table))))
        (is (equal '(1 1 nil) (lifecycle-words port)))
        (pool-begin-refusal dispatcher port table writers 'resource-exhausted :worker-state)
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-real-writer-not-ready-propagates-c1-fault-eq
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let ((link (pool-begin-claim dispatcher context ready table writers)))
      ;; FI tramite bypass pubblico: la fixture consuma il writer gia assegnato.
      (is (equal '(:a1) (arcdocdb.execution.tests::handoff-drain (svref writers 0) 1)))
      (let* ((series-before (map 'list #'pool-dispatch-series-image controllers))
             (writer-before (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0)))
             (condition
               (arcdocdb.execution.tests::worker-capture-condition
                (lambda () (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher))
                'resource-exhausted :writer-not-ready)))
        (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
        (is (eq :faulted (arcdocdb.execution.series:stato-worker-serie link)))
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
        (is (eq condition (arcdocdb.execution.series:errore-worker-serie link)))
        (is (eq (svref writers 0) (arcdocdb.execution:writer-worker-writer context)))
        (is (zerop (arcdocdb.execution::contesto-worker-writer-lease context)))
        (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
        (is (equalp writer-before
                    (arcdocdb.execution.tests::handoff-fi-snapshot (svref writers 0))))
        (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
        (pool-begin-refusal dispatcher port table writers 'resource-exhausted :worker-state)
        (is (eq condition (arcdocdb.execution:errore-worker-writer context)))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-unexpected-serie-acquire-keeps-c1-capacity-and-condition-eq
  (with-pool-dispatch (dispatcher port context ready table writers controllers :left-items '(:a1))
    (let* ((link (pool-begin-claim dispatcher context ready table writers))
           (writer (svref writers 0))
           (queue (arcdocdb.execution::writer-programmabile-queue writer))
           (series-before (map 'list #'pool-dispatch-series-image controllers))
           (original (make-condition 'arcdocdb.conditions:io-fault
                                     :reason :pool-begin-acquire :operation :series))
           (writer-lease nil) (calls 0))
      (unwind-protect
           (progn
             ;; FI di errore nel secondo acquire, dopo la vera lease writer.
             (let ((caught
                     (pool-claim-function-fi
                      'arcdocdb.series:acquisisci-controllore-serie
                      (lambda (selected) (declare (ignore selected))
                        (incf calls) (error original))
                      (lambda ()
                        (arcdocdb.execution.tests::worker-capture-condition
                         (lambda () (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher))
                         'arcdocdb.conditions:io-fault :pool-begin-acquire)))))
               (setf writer-lease
                     (arcdocdb.execution.series::collegamento-worker-serie-writer-lease link))
               (is (= 1 calls)) (is (eq original caught))
               (is (eq :faulted (arcdocdb.execution:stato-worker-writer context)))
               (is (eq :faulted (arcdocdb.execution.series:stato-worker-serie link)))
               (is (eq original (arcdocdb.execution:errore-worker-writer context)))
               (is (eq original (arcdocdb.execution.series:errore-worker-serie link)))
               (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
               (is (plusp writer-lease))
               (is (= writer-lease (arcdocdb.execution::contesto-worker-writer-lease context)))
               (is (plusp (arcdocdb.execution.series::collegamento-worker-serie-generation link)))
               (is (zerop (arcdocdb.execution.series::collegamento-worker-serie-series-lease link)))
               (is (eq :running (arcdocdb.execution::writer-programmabile-state writer)))
               (is (= 1 (arcdocdb.execution::coda-writer-count queue)))
               (is (zerop (arcdocdb.execution::coda-writer-extracted queue)))
               (is (equalp series-before (map 'list #'pool-dispatch-series-image controllers)))
               (is (equal '(1 1 nil) (lifecycle-words port)))
               (pool-begin-refusal dispatcher port table writers 'resource-exhausted :worker-state)
               (is (eq original (arcdocdb.execution:errore-worker-writer context)))))
        ;; Cleanup soltanto della lease reale della fixture; C1 e bridge restano FAULTED.
        (when writer-lease
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer writer-lease))))))))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-AFF-008-pool-begin-invalid-dispatcher-type-preserves-fixture
  (with-pool-dispatch (dispatcher port context ready table writers controllers)
    (declare (ignorable dispatcher context ready controllers))
    (let ((before (pool-dispatch-image port table writers)))
      (signals type-error
        (funcall (fdefinition 'arcdocdb.scheduler.dispatch:inizia-obbligo-pool) :invalid))
      (is (equalp before (pool-dispatch-image port table writers))))))
