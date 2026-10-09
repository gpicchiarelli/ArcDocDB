(in-package #:arcdocdb.csn.tests)

;;; REQ: REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-008-csn-default-capacity-and-valid-boundaries
  (let* ((values (multiple-value-list (crea-registro-csn)))
         (registry (first values)) (model (%make-csn-model 256 0 0)))
    (is (= 1 (length values)))
    (is (typep registry 'registro-csn))
    (is (equal '(0 0 0 0) (csn-check-model registry model)))
    (dotimes (i 256) (is (csn-take registry model)))
    (is (null (csn-take registry model)))
    (csn-drain registry model))
  ;; Le capacita estreme sono reali; non richiede miliardi di passi a K massimo.
  (dolist (capacity '(1 2 3 65536))
    (multiple-value-bind (registry model) (csn-fixture :capacity capacity)
      (dotimes (i (min capacity 3)) (is (csn-take registry model)))
      (csn-drain registry model))))

;;; REQ: REQ-MVC-008 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-csn-invalid-configuration-each-field
  (dolist (bad '(0 -1 65537 nil t :capacity 2.0 3/2 18446744073709551616))
    (signals invalid-argument (crea-registro-csn :capacity bad) :csn-config))
  (dolist (bad '(-1 4294967296 nil t :word 1.0 1/2 18446744073709551616))
    (signals invalid-argument (crea-registro-csn :initial-high bad :initial-low 7) :csn-config)
    (signals invalid-argument (crea-registro-csn :initial-high 7 :initial-low bad) :csn-config)))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(deftest test-REQ-MVC-008-csn-recovery-base-and-first-successor
  (dolist (base '(0 1 4294967295 4294967296 4294967297
                 9223372036854775807 18446744069414584320))
    (multiple-value-bind (registry model) (csn-fixture :capacity 2 :base base)
      (multiple-value-bind (high low) (csn-words base)
        (is (equal (list high low high low) (csn-check-model registry model))))
      (let ((token (csn-take registry model)))
        (is (= (1+ base) (csn-token-number token)))
        (is (= base (csn-model-horizon model)))
        (csn-resolve registry model token)
        (is (= (1+ base) (csn-model-horizon model)))))))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-008-csn-full-refusal-credit-and-every-slot-reused
  (dolist (capacity '(1 2 3 7))
    (multiple-value-bind (registry model) (csn-fixture :capacity capacity)
      (let ((uses (make-array capacity :initial-element 0)))
        (dotimes (round 4)
          (let ((tokens nil))
            (dotimes (i capacity)
              (let ((token (csn-take registry model)))
                (incf (svref uses (first token)))
                (push token tokens)))
            (dotimes (attempt 3) (is (null (csn-take registry model))))
            (dolist (token (if (evenp round) tokens (reverse tokens)))
              (csn-resolve registry model token))
            (is (= (* (1+ round) capacity) (csn-model-horizon model)))))
        (is (every (lambda (count) (= count 4)) uses))
        (is (= (* 4 capacity) (csn-model-last model)))))))

;;; REQ: REQ-MVC-005 REQ-MVC-008
(deftest test-REQ-MVC-008-csn-reverse-completion-and-interior-gap
  (multiple-value-bind (registry model) (csn-fixture :capacity 6 :base 17)
    (let ((tokens (loop repeat 6 collect (csn-take registry model))))
      (dolist (token (reverse (rest tokens)))
        (is (equal '(0 17) (csn-resolve registry model token))))
      (is (equal '(0 23) (csn-resolve registry model (first tokens)))))
    (let ((a (csn-take registry model)) (b (csn-take registry model))
          (c (csn-take registry model)))
      ;; Un gap intermedio e conservato anche quando il primo e il terzo finiscono.
      (is (equal '(0 24) (csn-resolve registry model a)))
      (is (equal '(0 24) (csn-resolve registry model c)))
      (is (equal '(0 26) (csn-resolve registry model b))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(deftest test-REQ-MVC-008-csn-ADR0046-modulo-ring-counterexample
  (dolist (last '(5 65))
    (multiple-value-bind (registry model) (csn-fixture :capacity 2)
      (let ((oldest (csn-take registry model)))
        ;; Witness storico: 1 rimane in volo, 2/3/4/5 finiscono, poi finisce 1.
        ;; Il secondo scenario supera di molto anche quella distanza.
        (loop for number from 2 to last
              do (let ((later (csn-take registry model)))
                   (is (/= (first oldest) (first later)))
                   (is (= number (csn-token-number later)))
                   (is (equal '(0 0) (csn-resolve registry model later)))
                   (is (= 1 (length (csn-model-live model))))))
        (is (equal (list 0 last) (csn-resolve registry model oldest)))
        (is (equal (list 0 last 0 last) (csn-frontiers registry)))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(deftest test-REQ-MVC-008-csn-carry-u32-and-horizon-borrow
  (multiple-value-bind (registry model) (csn-fixture :capacity 3 :base #xfffffffe)
    (let ((before-carry (csn-take registry model))
          (carry (csn-take registry model)) (after-carry (csn-take registry model)))
      (is (equal '(0 4294967295) (rest before-carry)))
      (is (equal '(1 0) (rest carry)))
      (is (equal '(1 1) (rest after-carry)))
      (is (equal '(0 4294967294) (csn-resolve registry model after-carry)))
      ;; Minimo residuo 1:0: la sottrazione deve prendere il prestito dalla high.
      (is (equal '(0 4294967295) (csn-resolve registry model before-carry)))
      (let ((new (csn-take registry model)))
        (is (/= (first carry) (first new)))
        (is (equal '(1 2) (rest new)))
        (is (equal '(0 4294967295) (csn-resolve registry model new))))
      (is (equal '(1 2) (csn-resolve registry model carry))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(deftest test-REQ-MVC-008-csn-crosses-SBCL-fixnum-boundary
  (is (< most-positive-fixnum +csn-test-maximum+))
  (multiple-value-bind (registry model)
      (csn-fixture :capacity 3 :base (1- most-positive-fixnum))
    (let ((a (csn-take registry model)) (b (csn-take registry model))
          (c (csn-take registry model)))
      (is (= most-positive-fixnum (csn-token-number a)))
      (is (= (1+ most-positive-fixnum) (csn-token-number b)))
      (is (= (+ 2 most-positive-fixnum) (csn-token-number c)))
      (csn-resolve registry model c)
      (csn-resolve registry model a)
      (is (= most-positive-fixnum (csn-model-horizon model)))
      (csn-resolve registry model b)
      (is (= (+ 2 most-positive-fixnum) (csn-model-horizon model))))))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-AFF-008-csn-last-u64-and-exhaustion-does-not-wrap
  (multiple-value-bind (registry model)
      (csn-fixture :capacity 2 :base (- +csn-test-maximum+ 2))
    (let ((penultimate (csn-take registry model)) (last (csn-take registry model)))
      (is (equal '(4294967295 4294967294) (rest penultimate)))
      (is (equal '(4294967295 4294967295) (rest last)))
      (csn-resolve registry model penultimate)
      ;; Un credito libero non permette il wrap, e il token ultimo resta valido.
      (dotimes (attempt 3) (is (null (csn-take registry model))))
      (csn-resolve registry model last)
      (dotimes (attempt 3) (is (null (csn-take registry model))))))
  (multiple-value-bind (registry model) (csn-fixture :capacity 1 :base +csn-test-maximum+)
    (dotimes (attempt 3) (is (null (csn-take registry model))))))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-csn-invalid-token-shapes-and-zero
  (multiple-value-bind (registry model) (csn-fixture :capacity 3 :base #x900000011)
    (let ((token (csn-take registry model)))
      (dolist (bad '(-1 3 65536 nil t :slot 0.0 1/2 18446744073709551616))
        (csn-reject-token registry (list bad (second token) (third token))))
      (dolist (bad '(-1 4294967296 nil t :word 1.0 1/2 18446744073709551616))
        (csn-reject-token registry (list (first token) bad (third token)))
        (csn-reject-token registry (list (first token) (second token) bad)))
      (csn-reject-token registry (list (first token) 0 0))
      (csn-check-model registry model)
      (dotimes (i 2) (is (csn-take registry model)))
      (is (null (csn-take registry model)))
      (csn-drain registry model)))
  (let ((empty (crea-registro-csn :capacity 1)))
    (csn-reject-token empty '(0 0 0))
    (csn-reject-token empty '(0 0 1))))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-csn-exact-slot-high-low-and-registry-binding
  (multiple-value-bind (registry model) (csn-fixture :capacity 2 :base #x12345678fffffff0)
    (let ((a (csn-take registry model)) (b (csn-take registry model)))
      (csn-reject-token registry (list (first a) (1+ (second a)) (third a)))
      (csn-reject-token registry (list (first a) (second a) (1+ (third a))))
      (csn-reject-token registry (list (first b) (second a) (third a)))
      (multiple-value-bind (foreign foreign-model)
          (csn-fixture :capacity 2 :base #x1234567900000010)
        (csn-reject-token registry (csn-take foreign foreign-model))
        (csn-drain foreign foreign-model))
      (is (null (csn-take registry model)))
      (csn-resolve registry model a)
      (csn-resolve registry model b)))
  ;; Nessun cookie di Archivio nel token: stessi numeri possono appartenere a
  ;; registri diversi. Il chiamante conserva ogni token insieme al suo registro.
  (multiple-value-bind (a ma) (csn-fixture :capacity 1 :base 41)
    (multiple-value-bind (b mb) (csn-fixture :capacity 1 :base 41)
      (let ((ta (csn-take a ma)) (tb (csn-take b mb)))
        (is (not (eq a b))) (is (equal ta tb))
        (csn-resolve a ma ta)
        (csn-check-model b mb)
        (csn-resolve b mb tb)))))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-csn-double-resolution-and-stale-reused-slot
  (multiple-value-bind (registry model) (csn-fixture :capacity 1 :base #xfffffffd)
    (let ((retired nil))
      (dotimes (round 9)
        (let ((fresh (csn-take registry model)))
          (is (zerop (first fresh)))
          (dolist (old retired) (csn-reject-token registry old))
          (is (null (csn-take registry model)))
          (csn-resolve registry model fresh)
          (csn-reject-token registry fresh)
          (push fresh retired))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-008-csn-exhaustive-capacity-2-3-through-six-commits
  (dolist (capacity '(2 3))
    (multiple-value-bind (prefixes complete) (csn-explore capacity 6)
      (is (> prefixes complete 1)))))

;;; REQ: REQ-MVC-008 REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-008-csn-deterministic-ten-thousand-actions
  (let ((seed #x46c5a71b) (taken 0) (resolved 0) (full 0) (reads 0) (stale 0))
    (flet ((next ()
             (setf seed (mod (+ (* seed 1664525) 1013904223) +csn-word-base+))
             ;; Non usa i bit bassi periodici del generatore per scegliere le azioni.
             (ldb (byte 16 16) seed)))
      (multiple-value-bind (registry model) (csn-fixture :capacity 7 :base #x80000001fffffff0)
        (let ((retired nil))
          (dotimes (step 10000)
            (case (mod (next) 10)
              ((0 1 2 3 4)
               (if (csn-take registry model) (incf taken) (incf full)))
              ((5 6 7)
               (let ((live (csn-model-live model)))
                 (if live
                     (let ((token (nth (mod (next) (length live)) live)))
                       (csn-resolve registry model token)
                       (push token retired) (incf resolved))
                     (progn (is (csn-take registry model)) (incf taken)))))
              (8 (csn-check-model registry model) (incf reads))
              (9
               (csn-reject-token registry
                                 (if retired (nth (mod (next) (length retired)) retired)
                                     '(0 0 0)))
               (incf stale))))
          (csn-drain registry model)
          (is (= taken (- (csn-model-last model) #x80000001fffffff0)))
          (is (>= taken resolved))
          (is (> resolved 100))
          (is (every #'plusp (list full reads stale)))
          (format t "  CSN seed #x46C5A71B: ~D presi, ~D risolti, ~D pieni, ~D letture, ~D stale.~%"
                  taken resolved full reads stale))))))

;;; REQ: REQ-MVC-008 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-csn-private-FI-shape-before-public-mutation
  (flet ((reject-apis (registry)
           (csn-invariant-refusal registry (lambda () (prendi-csn registry)) :csn-registry)
           (csn-invariant-refusal registry (lambda () (leggi-frontiere-csn registry)) :csn-registry)
           (csn-invariant-refusal registry (lambda () (risolvi-csn registry 0 0 1)) :csn-registry)))
    (dolist (lengths '((1 2) (2 1)))
      ;; I vettori read-only non sono rimpiazzabili tramite setter: oggetto FI
      ;; privato costruito con una sola lunghezza incoerente per volta.
      (reject-apis
       (arcdocdb.csn::%make-registro-csn
        2 (make-array (first lengths) :element-type '(unsigned-byte 32) :initial-element 0)
        (make-array (second lengths) :element-type '(unsigned-byte 32) :initial-element 0)
        (sb-thread:make-mutex :name "CSN malformed fixture") 0 0 0 0)))
    (dolist (field '(:used :cursor))
      (let ((registry (crea-registro-csn :capacity 2)))
        (arcdocdb.csn::%with-csn-guard (registry)
          (ecase field
            (:used (setf (arcdocdb.csn::registro-csn-used registry) 3))
            (:cursor (setf (arcdocdb.csn::registro-csn-cursor registry) 2))))
        (reject-apis registry)))))

;;; REQ: REQ-MVC-005 REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-csn-private-FI-frontiers-before-public-mutation
  (dolist (horizon '((2 0) (1 6) (0 5) (1 4)))
    ;; Base 1:5; H maggiore per high/low, poi H inferiore con registro vuoto
    ;; e ciascuna delle due parole diversa separatamente.
    (let ((registry (crea-registro-csn :capacity 2 :initial-high 1 :initial-low 5)))
      (arcdocdb.csn::%with-csn-guard (registry)
        (setf (arcdocdb.csn::registro-csn-horizon-high registry) (first horizon)
              (arcdocdb.csn::registro-csn-horizon-low registry) (second horizon)))
      (csn-invariant-refusal registry (lambda () (prendi-csn registry)) :csn-frontier)
      (csn-invariant-refusal registry (lambda () (leggi-frontiere-csn registry)) :csn-frontier)
      (csn-invariant-refusal registry (lambda () (risolvi-csn registry 0 0 1)) :csn-frontier))))

;;; REQ: REQ-MVC-005 REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-csn-private-FI-live-count-token-and-residual-scan
  ;; Conteggio che promette credito quando tutti gli slot sono occupati:
  ;; low sola, high sola, entrambe non zero vengono tutte trattate come occupate.
  (dolist (base '(0 4294967294 4294967296))
    (multiple-value-bind (registry model) (csn-fixture :capacity 2 :base base)
      (csn-take registry model) (csn-take registry model)
      (arcdocdb.csn::%with-csn-guard (registry)
        (setf (arcdocdb.csn::registro-csn-used registry) 1))
      (csn-invariant-refusal registry (lambda () (prendi-csn registry)) :csn-registry)))
  ;; Un count residuo troppo alto o troppo basso deve fallire prima di liberare
  ;; lo slot risolto, anche quando il token e le frontiere sono validi.
  (dolist (used '(1 3))
    (multiple-value-bind (registry model) (csn-fixture :capacity 3)
      (let ((token (csn-take registry model)))
        (csn-take registry model)
        (arcdocdb.csn::%with-csn-guard (registry)
          (setf (arcdocdb.csn::registro-csn-used registry) used))
        (csn-invariant-refusal registry
                               (lambda () (apply #'risolvi-csn registry token)) :csn-registry))))
  (dolist (fault '(:at-horizon :after-last :zero-used))
    (multiple-value-bind (registry model) (csn-fixture :capacity 2)
      (let ((token (csn-take registry model)))
        (csn-take registry model)
        (arcdocdb.csn::%with-csn-guard (registry)
          (ecase fault
            (:at-horizon (setf (arcdocdb.csn::registro-csn-horizon-low registry) 1))
            (:after-last (setf (arcdocdb.csn::registro-csn-last-low registry) 0))
            (:zero-used
             (setf (arcdocdb.csn::registro-csn-used registry) 0
                   (arcdocdb.csn::registro-csn-horizon-low registry) 2))))
        ;; used=0 richiede H=ultimo nel wrapper, quindi forza anche H>=token.
        (csn-invariant-refusal registry
                               (lambda () (apply #'risolvi-csn registry token)) :csn-frontier))))
  (dolist (remaining '(1 4))
    (multiple-value-bind (registry model) (csn-fixture :capacity 3)
      (let ((a (csn-take registry model)) (b (csn-take registry model))
            (c (csn-take registry model)))
        (csn-resolve registry model a)
        ;; C resta valido; B e corrotto a H oppure oltre ultimo. Il controllo
        ;; dei residui deve precedere qualsiasi scrittura allo slot di C.
        (arcdocdb.csn::%with-csn-guard (registry)
          (setf (aref (arcdocdb.csn::registro-csn-lows registry) (first b)) remaining))
        (csn-invariant-refusal registry
                               (lambda () (apply #'risolvi-csn registry c)) :csn-frontier))))
  ;; Confronto stretto: tutte le relazioni high e low, incluse low invertite
  ;; rispetto a high. Il risultato atteso e un confronto di interi indipendente.
  (dolist (a '((0 0) (0 4294967295) (1 0) (1 1) (4294967295 0) (4294967295 4294967295)))
    (dolist (b '((0 0) (0 4294967295) (1 0) (1 1) (4294967295 0) (4294967295 4294967295)))
      (is (eql (< (apply #'csn-number a) (apply #'csn-number b))
               (funcall (symbol-function 'arcdocdb.csn::%csn-before-p)
                        (first a) (second a) (first b) (second b)))))))

;;; REQ: REQ-MVC-008 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CON-004-csn-guard-macro-single-evaluation-values-and-cleanup
  (multiple-value-bind (registry model) (csn-fixture :capacity 2)
    (let ((evaluations 0) (executions 0))
      (is (equal '(nil 4294967295 17)
                 (multiple-value-list
                  (arcdocdb.csn::%with-csn-guard ((progn (incf evaluations) registry))
                    (incf executions) (values nil #xffffffff 17)))))
      (is (= 1 evaluations executions))
      (is (null (multiple-value-list (arcdocdb.csn::%with-csn-guard (registry) (values)))))
      (is (equal '(nil) (multiple-value-list
                        (arcdocdb.csn::%with-csn-guard (registry) nil))))
      (signals simple-error
        (arcdocdb.csn::%with-csn-guard (registry) (error "CSN body fault fixture")))
      (is (null (sb-thread:mutex-owner (arcdocdb.csn::registro-csn-mutex registry))))
      (is (eq :escaped
              (block escaped
                (arcdocdb.csn::%with-csn-guard (registry) (return-from escaped :escaped)))))
      (csn-check-model registry model)
      (csn-invariant-refusal registry
                             (lambda () (arcdocdb.csn::%check-registro-csn registry)) :csn-guard)
      (let ((token (csn-take registry model)))
        (arcdocdb.csn::%with-csn-guard (registry)
          (is (null (arcdocdb.csn::%check-registro-csn registry)))
          (signals resource-exhausted (prendi-csn registry) :csn-busy)
          (signals resource-exhausted (apply #'risolvi-csn registry token) :csn-busy)
          (signals resource-exhausted (leggi-frontiere-csn registry) :csn-busy)
          (signals resource-exhausted
            (arcdocdb.csn::%with-csn-guard ((progn (incf evaluations) registry))
              (incf executions)) :csn-busy))
        (is (= 2 evaluations)) (is (= 1 executions))
        (csn-resolve registry model token)))))
