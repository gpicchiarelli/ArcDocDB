;;;; REQ-MVC-003/004/005/007: snapshot reali sopra il registro CSN canonico.
;;;; Gli attesi sani sono interi/liste dell'harness; accessi privati solo nei casi FI dichiarati.
(in-package #:arcdocdb.mvcc.tests)

;;; REQ: REQ-MVC-004 REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-configuration-boundaries
  (dolist (configuration (list '(1 1 1) '(65536 20 5)
                               (list 1 +mvcc-maximum+ +mvcc-maximum+)))
    (let* ((csns (crea-registro-csn :capacity 1))
           (registry (apply #'crea-registro-snapshot csns configuration)))
      (mvcc-check-state registry 0 +mvcc-maximum+ 0)
      (is (snapshot-del-registro-p (crea-contesto-snapshot registry) registry)))))

;;; REQ: REQ-MVC-004 REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-configuration-typed-range-refusals
  (let ((csns (crea-registro-csn :capacity 1)))
    ;; Tutti gli argomenti restano INTEGER secondo il FTYPE pubblico; nessuna forma fuori contratto.
    (dolist (configuration (list '(-1 20 5) '(0 20 5) '(65537 20 5)
                                 '(1 -1 1) '(1 0 1) '(1 20 -1) '(1 20 0)
                                 '(1 5 6) (list 1 (1+ +mvcc-maximum+) 1)
                                 (list 1 +mvcc-maximum+ (1+ +mvcc-maximum+))))
      (signals invalid-argument
        (apply #'crea-registro-snapshot csns configuration) :snapshot-registry-configuration))
    (is (equal '(0 0) (mvcc-frontiers csns)))))

;;; REQ: REQ-MVC-005 REQ-MVC-007
(deftest test-REQ-MVC-005-snapshot-empty-archive-csn-zero
  (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 1)
    (is (equal '(0 0) (mvcc-frontiers csns)))
    (is (equal '(1 0 t) (multiple-value-list (registra-snapshot context 7))))
    (mvcc-check-pin-list registry '(0) 1)
    (is (= 0 (verifica-snapshot context 1 8)))
    (let ((buffer (mvcc-words)))
      (is (null (verifica-snapshot-in-buffer context 1 8 buffer 1)))
      (is (equalp (mvcc-words) (vector (aref buffer 0) #xfeed (aref buffer 2))))
      (is (= 0 (aref buffer 1))))
    (is (deve-trattenere-p registry 1))
    (termina-snapshot context 1)
    (mvcc-check-pin-list registry nil 1)))

;;; REQ: REQ-MVC-005 REQ-MVC-007
(deftest test-REQ-MVC-005-snapshot-canonical-out-of-order-activation
  (multiple-value-bind (csns registry context) (mvcc-fixture)
    (let ((first (mvcc-take-csn csns)) (second (mvcc-take-csn csns)))
      (is (= 1 (mvcc-token-csn first))) (is (= 2 (mvcc-token-csn second)))
      (mvcc-resolve-csn csns second)
      (is (equal '(2 0) (mvcc-frontiers csns)))
      (is (equal '(1 2 nil) (multiple-value-list (registra-snapshot context 0))))
      (mvcc-check-pin-list registry '(2) 1 0)
      (mvcc-buffer-refusal context 1 1 'invalid-argument :snapshot-not-ready)
      (is (null (attiva-snapshot context 1 1)))
      (mvcc-check-state registry 1 0 1)
      (mvcc-resolve-csn csns first)
      (is (equal '(2 2) (mvcc-frontiers csns)))
      (is (attiva-snapshot context 1 4))
      (is (= 2 (verifica-snapshot context 1 4)))
      (termina-snapshot context 1)
      (mvcc-check-pin-list registry nil 1))))

;;; REQ: REQ-MVC-005 REQ-MVC-007
(deftest test-REQ-MVC-005-snapshot-carry-u32-and-boxed-csn
  (dolist (base (list #xfffffffe #xffffffff (1- most-positive-fixnum)
                      #x8000000000000000 (- +mvcc-maximum+ 2)))
    (multiple-value-bind (csns registry context) (mvcc-fixture :base base)
      (let ((a (mvcc-take-csn csns)) (b (mvcc-take-csn csns)))
        (is (= (1+ base) (mvcc-token-csn a)))
        (is (= (+ base 2) (mvcc-token-csn b)))
        (mvcc-resolve-csn csns b)
        (is (equal (list (+ base 2) base) (mvcc-frontiers csns)))
        (is (equal (list 1 (+ base 2) nil)
                   (multiple-value-list (registra-snapshot context 0))))
        (is (null (attiva-snapshot context 1 1)))
        (mvcc-resolve-csn csns a)
        (is (attiva-snapshot context 1 2))
        (is (= (+ base 2) (verifica-snapshot context 1 3)))
        (let ((buffer (mvcc-words)))
          (verifica-snapshot-in-buffer context 1 3 buffer 2)
          (is (= (+ base 2) (aref buffer 2))))
        (termina-snapshot context 1)
        (mvcc-check-state registry 0 +mvcc-maximum+ 1)))))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-maximum-csn-is-not-absence
  (multiple-value-bind (csns registry context) (mvcc-fixture :base +mvcc-maximum+)
    (is (equal (list 1 +mvcc-maximum+ t)
               (multiple-value-list (registra-snapshot context 0))))
    (mvcc-check-pin-list registry (list +mvcc-maximum+) 1)
    (is (= +mvcc-maximum+ (verifica-snapshot context 1 1)))
    (is (null (deve-trattenere-p registry +mvcc-maximum+)))
    (signals resource-exhausted (prendi-csn csns) :csn-exhausted)
    (termina-snapshot context 1)
    (mvcc-check-pin-list registry nil 1)))

;;; REQ: REQ-MVC-005 REQ-MVC-007
(deftest test-REQ-MVC-007-snapshot-same-csn-distinct-generations
  (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 3 :base 17)
    (declare (ignore csns))
    (let ((contexts (list context (crea-contesto-snapshot registry)
                          (crea-contesto-snapshot registry))))
      (loop for snapshot in contexts for generation from 1
            do (is (equal (list generation 17 t)
                          (multiple-value-list (registra-snapshot snapshot 0)))))
      (mvcc-check-pin-list registry '(17 17 17) 3)
      (termina-snapshot (second contexts) 2)
      (mvcc-check-pin-list registry '(17 17) 3)
      (is (= 17 (verifica-snapshot (first contexts) 1 1)))
      (is (= 17 (verifica-snapshot (third contexts) 3 1)))
      (termina-snapshot (first contexts) 1)
      (termina-snapshot (third contexts) 3)
      (mvcc-check-pin-list registry nil 3))))

;;; REQ: REQ-MVC-003 REQ-MVC-007
(deftest test-REQ-MVC-003-snapshot-multipin-retention-boundaries
  (multiple-value-bind (csns registry a) (mvcc-fixture :base 10)
    (let ((b (crea-contesto-snapshot registry)))
      (is (equal '(1 10 t) (multiple-value-list (registra-snapshot a 0))))
      (mvcc-resolve-csn csns (mvcc-take-csn csns))
      (is (equal '(2 11 t) (multiple-value-list (registra-snapshot b 1))))
      (mvcc-check-pin-list registry '(10 11) 2)
      (is (null (deve-trattenere-p registry 10)))
      (is (deve-trattenere-p registry 11))
      (signals invalid-argument (deve-trattenere-p registry 0) :snapshot-commit-zero)
      (termina-snapshot a 1)
      (mvcc-check-pin-list registry '(11) 2)
      (is (null (deve-trattenere-p registry 11)))
      (is (deve-trattenere-p registry 12))
      (termina-snapshot b 2)
      (mvcc-check-pin-list registry nil 2)
      (is (null (deve-trattenere-p registry +mvcc-maximum+))))))

;;; REQ: REQ-MVC-003 REQ-MVC-005 REQ-MVC-007
(deftest test-REQ-MVC-007-snapshot-conservative-threshold-until-recalculation
  (multiple-value-bind (csns registry a) (mvcc-fixture)
    (let ((token (mvcc-take-csn csns)) (b (crea-contesto-snapshot registry)))
      (is (equal '(1 1 nil) (multiple-value-list (registra-snapshot a 0))))
      (mvcc-resolve-csn csns token)
      (is (attiva-snapshot a 1 1))
      (is (equal '(2 1 t) (multiple-value-list (registra-snapshot b 1))))
      (mvcc-check-pin-list registry '(1 1) 2 0)
      (is (deve-trattenere-p registry 1))
      (termina-snapshot a 1)
      (mvcc-check-pin-list registry '(1) 2)
      (is (null (deve-trattenere-p registry 1)))
      (termina-snapshot b 2))))

;;; REQ: REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-capacity-refuses-before-mutation
  (multiple-value-bind (csns registry a) (mvcc-fixture :capacity 2)
    (declare (ignore csns))
    (let ((b (crea-contesto-snapshot registry)) (c (crea-contesto-snapshot registry)))
      (registra-snapshot a 0) (registra-snapshot b 0)
      (mvcc-check-pin-list registry '(0 0) 2)
      (mvcc-refusal-preserves registry c (lambda () (registra-snapshot c 1))
                             'resource-exhausted :snapshot-capacity)
      (is (= 0 (verifica-snapshot a 1 1) (verifica-snapshot b 2 1)))
      (termina-snapshot a 1)
      (is (equal '(3 0 t) (multiple-value-list (registra-snapshot c 2))))
      (termina-snapshot b 2) (termina-snapshot c 3)
      (mvcc-check-pin-list registry nil 3))))

;;; REQ: REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-MVC-007-snapshot-pinned-context-refuses-before-mutation
  (dolist (capacity '(1 2))
    (multiple-value-bind (csns registry context) (mvcc-fixture :capacity capacity)
      (declare (ignore csns))
      (registra-snapshot context 0)
      (mvcc-refusal-preserves registry context (lambda () (registra-snapshot context 1))
                             'invalid-argument :snapshot-context-pinned)
      (mvcc-check-pin-list registry '(0) 1)
      (termina-snapshot context 1)
      (is (equal '(2 0 t) (multiple-value-list (registra-snapshot context 2))))
      (termina-snapshot context 2))))

;;; REQ: REQ-MVC-004 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-deadline-overflow-and-exact-u64-boundary
  (multiple-value-bind (csns registry context) (mvcc-fixture :lifetime 10 :wait 3)
    (declare (ignore csns))
    (mvcc-refusal-preserves registry context
                           (lambda () (registra-snapshot context (- +mvcc-maximum+ 9)))
                           'resource-exhausted :snapshot-deadline-overflow)
    (is (equal '(1 0 t)
               (multiple-value-list (registra-snapshot context (- +mvcc-maximum+ 10)))))
    (is (= 0 (verifica-snapshot context 1 (1- +mvcc-maximum+))))
    (mvcc-buffer-refusal context 1 +mvcc-maximum+ 'snapshot-too-old :snapshot-age-expired)
    (is (equal '(1 1) (multiple-value-list (scadi-snapshot registry +mvcc-maximum+ 1))))
    (mvcc-check-pin-list registry nil 1)))

;;; REQ: REQ-MVC-007 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-private-FI-generation-exhaustion
  (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 1)
    (declare (ignore csns))
    ;; Unicamente FI: avvicina il contatore non osservabile in tempi finiti, senza oracle privato.
    (setf (aref (arcdocdb.mvcc::registro-snapshot-words registry) 0) (1- +mvcc-maximum+))
    (is (equal (list +mvcc-maximum+ 0 t)
               (multiple-value-list (registra-snapshot context 0))))
    (is (= 0 (verifica-snapshot context +mvcc-maximum+ 1)))
    (termina-snapshot context +mvcc-maximum+)
    (mvcc-refusal-preserves registry context (lambda () (registra-snapshot context 2))
                           'resource-exhausted :snapshot-generation-exhausted)
    (mvcc-check-pin-list registry nil +mvcc-maximum+)))

;;; REQ: REQ-MVC-004
(deftest test-REQ-MVC-004-snapshot-active-reader-deadline-before-exact-after
  (dolist (now '(14 15 16))
    (multiple-value-bind (csns registry context) (mvcc-fixture :lifetime 5 :wait 3)
      (declare (ignore csns))
      (registra-snapshot context 10)
      (if (< now 15)
          (is (= 0 (verifica-snapshot context 1 now)))
          (mvcc-buffer-refusal context 1 now 'snapshot-too-old :snapshot-age-expired))
      ;; Un reader scaduto non rimuove il pin: il timer/controllore lo conserva fino al ritiro.
      (mvcc-check-pin-list registry '(0) 1)
      (termina-snapshot context 1)
      (mvcc-check-pin-list registry nil 1))))

;;; REQ: REQ-MVC-004
(deftest test-REQ-MVC-004-snapshot-active-activation-expiry-removes-pin
  (dolist (now '(14 15 16))
    (multiple-value-bind (csns registry context) (mvcc-fixture :lifetime 5 :wait 3)
      (declare (ignore csns))
      (registra-snapshot context 10)
      (if (< now 15)
          (progn (is (attiva-snapshot context 1 now)) (mvcc-check-pin-list registry '(0) 1))
          (progn
            (signals snapshot-too-old (attiva-snapshot context 1 now) :snapshot-age-expired)
            (mvcc-check-pin-list registry nil 1)
            (signals snapshot-too-old (attiva-snapshot context 1 now) :snapshot-ended)))
      (termina-snapshot context 1))))

;;; REQ: REQ-MVC-004 REQ-MVC-005
(deftest test-REQ-MVC-004-snapshot-wait-deadline-before-exact-after
  (dolist (now '(22 23 24))
    (dolist (resolved-p '(nil t))
      (multiple-value-bind (csns registry context) (mvcc-fixture :lifetime 10 :wait 3)
        (let ((token (mvcc-take-csn csns)))
          (is (equal '(1 1 nil) (multiple-value-list (registra-snapshot context 20))))
          (when resolved-p (mvcc-resolve-csn csns token))
          (if (< now 23)
              (progn
                (mvcc-buffer-refusal context 1 now 'invalid-argument :snapshot-not-ready)
                (if resolved-p (is (attiva-snapshot context 1 now))
                    (is (null (attiva-snapshot context 1 now)))))
              (progn
                ;; La deadline prevale anche se nel frattempo H ha raggiunto il CSN richiesto.
                (mvcc-buffer-refusal context 1 now 'resource-exhausted :snapshot-wait-timeout)
                (mvcc-check-state registry 1 0 1)
                (signals resource-exhausted (attiva-snapshot context 1 now) :snapshot-wait-timeout)
                (signals resource-exhausted (attiva-snapshot context 1 now) :snapshot-wait-timeout)
                (mvcc-check-pin-list registry nil 1)))
          (termina-snapshot context 1))))))

;;; REQ: REQ-MVC-004 REQ-MVC-005
(deftest test-REQ-MVC-004-snapshot-lifetime-includes-initial-wait
  (multiple-value-bind (csns registry context) (mvcc-fixture :lifetime 10 :wait 9)
    (let ((token (mvcc-take-csn csns)))
      (registra-snapshot context 10)
      (is (null (attiva-snapshot context 1 17)))
      (mvcc-resolve-csn csns token)
      (is (attiva-snapshot context 1 18))
      (is (= 1 (verifica-snapshot context 1 19)))
      (mvcc-buffer-refusal context 1 20 'snapshot-too-old :snapshot-age-expired)
      (termina-snapshot context 1)
      (mvcc-check-pin-list registry nil 1))))

;;; REQ: REQ-MVC-004 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-timer-budget-refusals-and-empty-sweep
  (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 3)
    (declare (ignore csns))
    (registra-snapshot context 0)
    (dolist (budget '(-1 0 4))
      (mvcc-refusal-preserves registry context (lambda () (scadi-snapshot registry 20 budget))
                             'invalid-argument :snapshot-sweep-budget))
    (is (equal '(3 1) (multiple-value-list (scadi-snapshot registry 20 3))))
    (mvcc-check-pin-list registry nil 1)
    (is (equal '(3 0) (multiple-value-list (scadi-snapshot registry 20 3))))
    (termina-snapshot context 1)))

;;; REQ: REQ-MVC-004 REQ-AFF-008
(deftest test-REQ-AFF-008-snapshot-timer-circular-fairness-and-mixed-deadlines
  (multiple-value-bind (csns registry first) (mvcc-fixture :capacity 4 :lifetime 5 :wait 5)
    (declare (ignore csns))
    (let ((contexts (cons first (loop repeat 3 collect (crea-contesto-snapshot registry))))
          (expired 0))
      (loop for context in contexts for now in '(0 3 6 9) do (registra-snapshot context now))
      ;; Un giro completo suddiviso: attesi indipendenti dall'ordine privato degli slot.
      (dolist (budget '(1 2 1))
        (multiple-value-bind (visits removed) (scadi-snapshot registry 10 budget)
          (is (= budget visits)) (is (<= 0 removed budget)) (incf expired removed)))
      (is (= 2 expired))
      (mvcc-check-pin-list registry '(0 0) 4)
      (mvcc-buffer-refusal (first contexts) 1 10 'snapshot-too-old :snapshot-ended)
      (mvcc-buffer-refusal (second contexts) 2 10 'snapshot-too-old :snapshot-ended)
      (is (= 0 (verifica-snapshot (third contexts) 3 10)))
      (is (= 0 (verifica-snapshot (fourth contexts) 4 10)))
      (is (equal '(4 1) (multiple-value-list (scadi-snapshot registry 11 4))))
      (is (equal '(4 0) (multiple-value-list (scadi-snapshot registry 13 4))))
      (mvcc-check-pin-list registry '(0) 4)
      (is (equal '(4 1) (multiple-value-list (scadi-snapshot registry 14 4))))
      (mvcc-check-pin-list registry nil 4)
      (loop for context in contexts for generation from 1 do (termina-snapshot context generation)))))

;;; REQ: REQ-MVC-004 REQ-MVC-005
(deftest test-REQ-MVC-004-snapshot-timer-distinguishes-wait-and-age
  (multiple-value-bind (csns registry active) (mvcc-fixture :capacity 2 :lifetime 10 :wait 3)
    (let ((waiting (crea-contesto-snapshot registry)))
      (registra-snapshot active 0)
      (let ((token (mvcc-take-csn csns)))
        (registra-snapshot waiting 0)
        (is (equal '(2 1) (multiple-value-list (scadi-snapshot registry 3 2))))
        (mvcc-check-pin-list registry '(0) 2)
        (is (= 0 (verifica-snapshot active 1 3)))
        (mvcc-resolve-csn csns token)
        (signals resource-exhausted (attiva-snapshot waiting 2 3) :snapshot-wait-timeout)
        (mvcc-buffer-refusal waiting 2 3 'snapshot-too-old :snapshot-ended)
        (is (equal '(2 1) (multiple-value-list (scadi-snapshot registry 10 2))))
        (mvcc-check-pin-list registry nil 2)
        (mvcc-buffer-refusal active 1 10 'snapshot-too-old :snapshot-ended)
        (termina-snapshot active 1) (termina-snapshot waiting 2)))))

;;; REQ: REQ-MVC-004 REQ-MVC-007
(deftest test-REQ-MVC-007-snapshot-termination-idempotent-active-and-waiting
  (dolist (pending-p '(nil t))
    (multiple-value-bind (csns registry context) (mvcc-fixture)
      (when pending-p (mvcc-take-csn csns))
      (registra-snapshot context 0)
      (is (null (termina-snapshot context 1)))
      (mvcc-check-pin-list registry nil 1)
      (is (null (termina-snapshot context 1)))
      (mvcc-check-pin-list registry nil 1)
      (signals snapshot-too-old (attiva-snapshot context 1 1) :snapshot-ended)
      (mvcc-buffer-refusal context 1 1 'snapshot-too-old :snapshot-ended))))

;;; REQ: REQ-MVC-004 REQ-MVC-007
(deftest test-REQ-MVC-007-snapshot-stale-generation-after-context-reuse
  (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 1)
    (declare (ignore csns))
    (registra-snapshot context 0) (termina-snapshot context 1)
    (is (equal '(2 0 t) (multiple-value-list (registra-snapshot context 1))))
    (mvcc-buffer-refusal context 1 2 'snapshot-too-old :snapshot-stale-identity)
    (mvcc-refusal-preserves registry context (lambda () (termina-snapshot context 1))
                           'snapshot-too-old :snapshot-stale-identity)
    (signals snapshot-too-old (attiva-snapshot context 1 2) :snapshot-stale-identity)
    (is (= 0 (verifica-snapshot context 2 2)))
    (mvcc-check-pin-list registry '(0) 2)
    (termina-snapshot context 2)))

;;; REQ: REQ-MVC-004 REQ-MVC-007
(deftest test-REQ-MVC-007-snapshot-stale-context-after-slot-reuse
  (multiple-value-bind (csns registry a) (mvcc-fixture :capacity 1)
    (declare (ignore csns))
    (let ((b (crea-contesto-snapshot registry)))
      (registra-snapshot a 0) (termina-snapshot a 1) (registra-snapshot b 1)
      (mvcc-buffer-refusal a 1 2 'snapshot-too-old :snapshot-stale-identity)
      (signals snapshot-too-old (termina-snapshot a 1) :snapshot-stale-identity)
      (signals snapshot-too-old (attiva-snapshot a 1 2) :snapshot-stale-identity)
      (is (= 0 (verifica-snapshot b 2 2)))
      (mvcc-check-pin-list registry '(0) 2)
      (termina-snapshot b 2))))

;;; REQ: REQ-MVC-004 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-005-snapshot-private-buffer-range-and-unbound-identity
  (multiple-value-bind (csns registry context) (mvcc-fixture :base #x8000000000000001)
    (declare (ignore csns))
    (is (snapshot-del-registro-p context registry))
    (mvcc-buffer-refusal context 0 0 'snapshot-too-old :snapshot-stale-identity)
    (mvcc-buffer-refusal context 1 0 'snapshot-too-old :snapshot-stale-identity)
    (signals snapshot-too-old (termina-snapshot context 0) :snapshot-stale-identity)
    (registra-snapshot context 0)
    (dolist (index '(-1 3))
      (mvcc-buffer-refusal context 1 1 'invalid-argument :snapshot-result-range index))
    (signals invalid-argument
      (verifica-snapshot-in-buffer context 1 1 (mvcc-words 0) 0) :snapshot-result-range)
    (let ((buffer (mvcc-words)))
      (verifica-snapshot-in-buffer context 1 1 buffer 1)
      (is (equalp buffer (vector #xfeed #x8000000000000001 #xfeed)))
      (setf (aref buffer 1) 0)
      (is (= #x8000000000000001 (verifica-snapshot context 1 1))))
    (termina-snapshot context 1)))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-AFF-004
(deftest test-REQ-AFF-004-snapshot-terminal-invalidation-preserves-pins
  (multiple-value-bind (csns registry context) (mvcc-fixture)
    (declare (ignore csns))
    (registra-snapshot context 0)
    (let ((before (rest (mvcc-private-image registry context))))
      (is (null (invalida-registro-snapshot registry)))
      (is (null (invalida-registro-snapshot registry)))
      (is (equalp before (rest (mvcc-private-image registry context)))))
    (mvcc-faulted-refusal registry context 1)))

;;; REQ: REQ-MVC-007 REQ-AFF-004
(deftest test-REQ-AFF-004-snapshot-private-FI-reader-csn-state-and-range
  (dolist (fault '(:csn :state :slot))
    (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 1)
      (declare (ignore csns))
      (registra-snapshot context 0)
      (ecase fault
        (:csn (setf (aref (arcdocdb.mvcc::contesto-snapshot-word context) 1) 1))
        (:state (setf (aref (arcdocdb.mvcc::registro-snapshot-states registry) 0) 6))
        (:slot (setf (arcdocdb.mvcc::contesto-snapshot-slot context) 1)))
      (mvcc-buffer-refusal context 1 1 'invariant-violation
                           (ecase fault (:csn :snapshot-csn-identity)
                                  (:state :snapshot-slot-state) (:slot :snapshot-slot-range)))
      (mvcc-faulted-refusal registry context 1))))

;;; REQ: REQ-MVC-007 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-snapshot-private-FI-counter-guards
  (dolist (fault '(:count :cursor :sweep :empty-threshold :missing-generation :free-state))
    (multiple-value-bind (csns registry context) (mvcc-fixture :capacity 2)
      (declare (ignore csns))
      (when (eq fault :missing-generation) (registra-snapshot context 0))
      (ecase fault
        (:count (setf (arcdocdb.mvcc::registro-snapshot-count registry) 3))
        (:cursor (setf (arcdocdb.mvcc::registro-snapshot-cursor registry) 2))
        (:sweep (setf (arcdocdb.mvcc::registro-snapshot-sweep-cursor registry) 2))
        (:empty-threshold (setf (aref (arcdocdb.mvcc::registro-snapshot-words registry) 1) 0))
        (:missing-generation (setf (aref (arcdocdb.mvcc::registro-snapshot-words registry) 0) 0))
        (:free-state (setf (aref (arcdocdb.mvcc::registro-snapshot-states registry) 0) 6)))
      (signals invariant-violation
        (registra-snapshot (crea-contesto-snapshot registry) 1)
        (if (eq fault :free-state) :snapshot-slot-state :snapshot-counters-inconsistent))
      (mvcc-faulted-refusal registry context 1))))

;;; REQ: REQ-MVC-003 REQ-MVC-007 REQ-AFF-004
(deftest test-REQ-AFF-004-snapshot-private-FI-recalculation-invariants
  (dolist (fault '(:generation :wait-deadline :count :threshold :state))
    (multiple-value-bind (csns registry a) (mvcc-fixture :capacity 2 :base 10)
      (declare (ignore csns))
      (let ((b (crea-contesto-snapshot registry)))
        (registra-snapshot a 0) (registra-snapshot b 0)
        ;; Corrompe il pin A; termina B attraverso l'API pubblica per obbligare il ricalcolo.
        (ecase fault
          (:generation (setf (aref (arcdocdb.mvcc::registro-snapshot-generations registry) 0) 3))
          (:wait-deadline (setf (aref (arcdocdb.mvcc::registro-snapshot-wait-deadlines registry) 0) 21))
          (:count (setf (arcdocdb.mvcc::registro-snapshot-count registry) 1))
          (:threshold (setf (aref (arcdocdb.mvcc::registro-snapshot-words registry) 1) 11))
          (:state (setf (aref (arcdocdb.mvcc::registro-snapshot-states registry) 0) 6)))
        (signals invariant-violation (termina-snapshot b 2)
          (ecase fault ((:generation :wait-deadline) :snapshot-slot-metadata)
                 (:count :snapshot-credit-accounting) (:threshold :snapshot-threshold-regression)
                 (:state :snapshot-slot-state)))
        (mvcc-faulted-refusal registry b 2)))))
