;;;; FI sequenziali D02/D03 e truth-pairs D06; caricamento dopo support.lisp.
;;;; OWNER: il test conserva la lease; ogni corruzione e ripristinata nel cleanup.
;;;; D04: gia coperto da lease-busy-stale-and-single-release e dal test foreign-thread.
(in-package #:arcdocdb.series.tests)

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-AFF-001
(deftest test-REQ-AFF-008-series-ring-invalid-capacity-before-indexing
  ;; La factory esclude questi vettori e SLOTS e readonly: FI via costruttore.
  ;; A falso: con 1025 slot tutti i cursori sono validi; con zero sono
  ;; necessariamente fuori range, ma il corto circuito precede le loro letture.
  (dolist (capacity '(0 1025))
    (with-series (f)
      (let* ((original (series-fixture-controller f))
             (root (leggi-radice-serie original))
             (lot (series-seal f))
             (malformed
               (arcdocdb.series::%make-controllore-serie
                (series-fixture-registry f) (series-fixture-log f)
                (make-array capacity :initial-element nil) root root 0)))
        (unwind-protect
             (progn
               (setf (series-fixture-controller f) malformed)
               (series-archive-refusal
                f (lambda () (acquisisci-controllore-serie malformed))
                :serie-ring :lots (list lot))
               (is (null (arcdocdb.series::controllore-serie-owner malformed)))
               (is (zerop (arcdocdb.series::controllore-serie-lease-generation malformed)))
               (is (eq root (arcdocdb.series::controllore-serie-root malformed)))
               (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
               (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot))))
          ;; Non si modifica SLOTS readonly: la fixture riottiene il controller
          ;; valido prima che il suo cleanup rilasci e ricontrolli la lease.
          (setf (series-fixture-controller f) original))
        (series-healthy f)
        (series-counts f 0 0 0)))))

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-AFF-001 REQ-WAL-006
(deftest test-REQ-CON-002-series-ring-cursors-fail-separately
  ;; D02: B, C, D falsi separati; ogni altro cursore resta nel range.
  (dolist (name '("HEAD" "TAIL" "PUBLISH-HEAD"))
    (with-series (f :capacity 2)
      (let* ((controller (series-fixture-controller f))
             (root (leggi-radice-serie controller))
             (lot (series-seal f)))
        (series-adopt f lot)
        (series-counts f 1 1 0)
        (let* ((slot (sb-mop:slot-definition-name (series-private-slot controller name)))
               (saved (slot-value controller slot)))
          (unwind-protect
               (progn
                 (series-fi-set controller name 2)
                 ;; Snapshot dopo FI: cambia soltanto STATE, inclusi nel grafo
                 ;; evento, token, registro, lotto, byte e radici pianificate.
                 (series-archive-refusal
                  f (lambda () (conta-commit-serie controller (series-fixture-lease f)))
                  :serie-ring :lots (list lot))
                 (is (eq root (arcdocdb.series::controllore-serie-root controller)))
                 (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
                 (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot))))
            (series-fi-set controller name saved)))
        ;; La salute resta terminale; il ring riparato permette il rilascio.
        (series-faulted f :archive)
        (series-counts f 1 1 0)))))

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-AFF-001 REQ-MVC-008
(deftest test-REQ-CON-002-series-ring-counts-fail-separately
  ;; D03: count>capacity, unresolved>count, active-io>count; solo un falso.
  (dolist (scenario '(("COUNT" 3) ("UNRESOLVED" 2) ("ACTIVE-IO" 2)))
    (destructuring-bind (name value) scenario
      (with-series (f :capacity 2)
        (let* ((controller (series-fixture-controller f))
               (root (leggi-radice-serie controller))
               (lot (series-seal f)))
          (multiple-value-bind (event generation planned-root) (series-adopt f lot)
            (declare (ignore planned-root))
            ;; Nessun dispatch: l'obbligo active e soltanto registrato nel test.
            (series-begin f event generation)
            (series-counts f 1 1 1)
            (let* ((slot (sb-mop:slot-definition-name (series-private-slot controller name)))
                   (saved (slot-value controller slot)))
              (unwind-protect
                   (progn
                     (series-fi-set controller name value)
                     (series-archive-refusal
                      f (lambda () (conta-commit-serie controller (series-fixture-lease f)))
                      :serie-count :lots (list lot))
                     (is (eq root (arcdocdb.series::controllore-serie-root controller)))
                     (is (eq :preparato (stato-commit-serie controller event generation)))
                     (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
                     (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot))))
                (series-fi-set controller name saved)))
            (series-faulted f :archive)
            (series-counts f 1 1 1)))))))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-MVC-008-series-csn-after-explicit-truth-pairs
  ;; D06 A: B falso e low minore in entrambi; cambia solo high>previous-high.
  (is (arcdocdb.series::%csn-after-p 2 0 1 1))
  (is (not (arcdocdb.series::%csn-after-p 0 0 1 1)))
  ;; D06 B: A falso, low maggiore; uguaglianza high contro high inferiore.
  (is (arcdocdb.series::%csn-after-p 1 #xffffffff 1 0))
  (is (not (arcdocdb.series::%csn-after-p 0 #xffffffff 1 0)))
  ;; D06 C: A falso e B vero; low maggiore contro uguaglianza totale.
  (is (arcdocdb.series::%csn-after-p 1 2 1 1))
  (is (not (arcdocdb.series::%csn-after-p 1 1 1 1))))
