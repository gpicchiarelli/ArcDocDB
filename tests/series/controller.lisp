;;;; Prove sequenziali; nessun test parte durante la modifica dei sorgenti.
(in-package #:arcdocdb.series.tests)

(defun series-bootstrap-preserved-image (f roots &key fault)
  "Oracolo: congela ring, eventi, owner, lease, offset, parole CSN, WAL e file.
Esclude solo ROOT/PLANNED-ROOT; nelle FI esclude anche la transizione di salute."
  (let* ((controller (series-fixture-controller f))
         (image (series-image (list controller (series-fixture-registry f)
                                    (series-fixture-log f) (series-fixture-file f)
                                    (series-fixture-calls f))
                              :opaque roots :health-opaque (when fault (list controller)))))
    (setf (fourth (first image))
          (remove-if (lambda (entry)
                       (member (symbol-name (first entry)) '("ROOT" "PLANNED-ROOT")
                               :test #'string=))
                     (fourth (first image))))
    image))

(defun series-bootstrap-before-effect (thunk)
  "FI seriale: ogni rifiuto atteso deve precedere anche la chiamata a BEGIN."
  (let ((original (symbol-function 'arcdocdb.series::%begin-effect)) (calls 0))
    (series-call-with-function-fi
     'arcdocdb.series::%begin-effect
     (lambda (controller) (incf calls) (funcall original controller)) thunk)
    (is (zerop calls))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-WAL-006-series-bootstrap-capacity-offset-csn-and-effect-boundaries
  (dolist (capacity '(1 64 1024))
    (dolist (offset (list 0 most-positive-fixnum))
      (with-series (f :root nil :capacity capacity :next-offset offset
                     :base #x80000000fffffffd)
        (let* ((c (series-fixture-controller f)) (root (series-root 71 (series-root 29 nil)))
               (begin (symbol-function 'arcdocdb.series::%begin-effect))
               (end (symbol-function 'arcdocdb.series::%end-effect))
               (begins 0) (ends 0))
          ;; Parole sentinella: rileva anche un azzeramento accidentale.
          (series-fi-set c "LAST-HIGH" #x80000000)
          (series-fi-set c "LAST-LOW" #xfffffffd)
          ;; Un ring vergine valido puo avere i tre cursori coincidenti non zero.
          (dolist (cursor '("HEAD" "TAIL" "PUBLISH-HEAD"))
            (series-fi-set c cursor (1- capacity)))
          (let ((before (series-bootstrap-preserved-image f (list root)))
                (root-before (series-image (list root))))
            (series-call-with-function-fi
             'arcdocdb.series::%begin-effect
             (lambda (controller)
               (incf begins)
               (is (eq c controller))
               (is (null (arcdocdb.series::controllore-serie-root c)))
               (is (null (arcdocdb.series::controllore-serie-planned-root c)))
               (is (not (arcdocdb.series::controllore-serie-effect-active c)))
               (funcall begin controller))
             (lambda ()
               (series-call-with-function-fi
                'arcdocdb.series::%end-effect
                (lambda (controller complete)
                  (incf ends)
                  (is (eq c controller)) (is (eq t complete))
                  (is (arcdocdb.series::controllore-serie-effect-active c))
                  (is (eq root (arcdocdb.series::controllore-serie-root c)))
                  (is (eq root (arcdocdb.series::controllore-serie-planned-root c)))
                  (funcall end controller complete))
                (lambda ()
                  (is (equal (list root)
                             (multiple-value-list
                              (arcdocdb.series:inizializza-radice-serie
                               c (series-fixture-lease f) root))))))))
            (is (= 1 begins ends))
            (is (eq root (leggi-radice-serie c)))
            (is (series-image-equal root-before (series-image (list root))))
            (is (series-image-equal before (series-bootstrap-preserved-image f (list root))))
            (series-counts f 0 0 0)
            (series-frontiers (series-fixture-registry f) #x80000000fffffffd nil)
            (is (equalp #(1 0 0 0) (series-fixture-calls f)))
            (series-healthy f)))))))

;;; REQ: REQ-WAL-006 REQ-CON-002
(deftest test-REQ-WAL-006-series-bootstrap-accepts-opaque-non-nil-values
  ;; Nessuna forma interna della radice e richiesta dall'API.
  (dolist (root (list :opaque 37 #\R (gensym "SERIES-OPAQUE") (series-root 0 nil)))
    (with-series (f :root nil)
      (let ((before (series-bootstrap-preserved-image f (list root))))
        (is (eql root (arcdocdb.series:inizializza-radice-serie
                       (series-fixture-controller f) (series-fixture-lease f) root)))
        (is (eql root (leggi-radice-serie (series-fixture-controller f))))
        (is (eql root (arcdocdb.series::controllore-serie-planned-root
                       (series-fixture-controller f))))
        (is (series-image-equal before (series-bootstrap-preserved-image f (list root))))))))

;;; REQ: REQ-AFF-004 REQ-CON-001 REQ-WAL-006
(deftest test-REQ-AFF-004-series-bootstrap-nil-stale-and-repeated-before-effect
  (with-series (f :root nil)
    (let* ((c (series-fixture-controller f)) (old (series-fixture-lease f))
           (root (series-root 71 nil)))
      (series-bootstrap-before-effect
       (lambda ()
         (series-refusal f (lambda () (arcdocdb.series:inizializza-radice-serie c old nil))
                         'invalid-argument :reason :serie-initial-root)
         (dolist (bad (list 0 -1 nil :bad (1+ old) (1+ most-positive-fixnum)))
           (series-refusal f (lambda () (arcdocdb.series:inizializza-radice-serie c bad root))
                           'invalid-argument :reason :serie-lease))))
      (rilascia-controllore-serie c old)
      (setf (series-fixture-lease f) nil)
      (series-bootstrap-before-effect
       (lambda ()
         (series-refusal f (lambda () (arcdocdb.series:inizializza-radice-serie c old root))
                         'invalid-argument :reason :serie-lease)))
      (setf (series-fixture-lease f) (acquisisci-controllore-serie c))
      (series-bootstrap-before-effect
       (lambda ()
         (series-refusal f (lambda () (arcdocdb.series:inizializza-radice-serie c old root))
                         'invalid-argument :reason :serie-lease)))
      (is (eq root (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root)))
      (let ((copy (series-root 71 nil)))
        (is (equalp root copy)) (is (not (eq root copy)))
        (series-bootstrap-before-effect
         (lambda ()
           (dolist (candidate (list root copy (series-root 99 nil)))
             (series-refusal
              f (lambda () (arcdocdb.series:inizializza-radice-serie
                            c (series-fixture-lease f) candidate))
              'invalid-argument :reason :serie-started)))))
      (is (eq root (leggi-radice-serie c)))
      (series-healthy f))))

;;; REQ: REQ-AFF-004 REQ-WAL-006 REQ-AFF-008
(deftest test-REQ-AFF-004-series-bootstrap-virgin-guards-and-existing-reader-root
  ;; Ogni guardia falsa separatamente, con ring valido.
  (dolist (guard '("ROOT" "PLANNED-ROOT" "EVENT-GENERATION"))
    (with-series (f :root nil)
      (let ((c (series-fixture-controller f)) (root (series-root 71 nil)))
        (series-fi-set c guard (if (string= guard "EVENT-GENERATION") 1 (series-root 29 nil)))
        (series-bootstrap-before-effect
         (lambda ()
           (series-refusal
            f (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root))
            'invalid-argument :reason :serie-started)))
        (series-healthy f))))
  (with-series (f :root nil)
    (let ((c (series-fixture-controller f)) (lot (series-seal f)))
      (series-adopt f lot :root nil)
      ;; FI isola COUNT>0: la guardia EVENT-GENERATION non deve nasconderla.
      (unwind-protect
           (progn
             (series-fi-set c "EVENT-GENERATION" 0)
             (series-bootstrap-before-effect
              (lambda ()
                (series-refusal
                 f (lambda () (arcdocdb.series:inizializza-radice-serie
                               c (series-fixture-lease f) (series-root 71 nil)))
                 'invalid-argument :reason :serie-started :lots (list lot))))
             (series-counts f 1 1 0))
        (series-fi-set c "EVENT-GENERATION" 1))))
  (with-series (f)
    (let* ((c (series-fixture-controller f)) (existing (leggi-radice-serie c)))
      (is existing)
      (series-bootstrap-before-effect
       (lambda ()
         (dolist (candidate (list existing (series-root 71 nil)))
           (series-refusal
            f (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) candidate))
            'invalid-argument :reason :serie-started))))
      (is (eq existing (leggi-radice-serie c)))
      (series-healthy f))))

;;; REQ: REQ-WAL-006 REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-WAL-006-series-bootstrap-refuses-used-empty-ring-with-nil-root
  (with-series (f :root nil :capacity 1)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot :root nil)
        (is (null root))
        (let ((group (series-group f lot)))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation) (series-publish f event generation 1)
          (arcdocdb.wal:riusa-gruppo group) (series-retire f event generation)
          (series-counts f 0 0 0)
          (is (null (leggi-radice-serie (series-fixture-controller f))))
          (is (null (arcdocdb.series::controllore-serie-planned-root (series-fixture-controller f))))
          (is (= 1 (arcdocdb.series::controllore-serie-event-generation (series-fixture-controller f))))
          (series-bootstrap-before-effect
           (lambda ()
             (series-refusal
              f (lambda () (arcdocdb.series:inizializza-radice-serie
                            (series-fixture-controller f) (series-fixture-lease f) (series-root 71 nil)))
              'invalid-argument :reason :serie-started :lots (list lot) :groups (list group))))
          (series-frontiers (series-fixture-registry f) 1 nil)
          (series-healthy f))))))

;;; REQ: REQ-WAL-006 REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-WAL-006-series-bootstrap-first-commit-requires-initial-root-identity
  (dolist (level '(:async :group :strong))
    (with-series (f :root nil :capacity 1)
      (let* ((c (series-fixture-controller f)) (initial (series-root 71 nil))
             (copy (series-root 71 nil)) (next (series-root 72 initial)))
        (is (eq initial (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) initial)))
        (setf (series-fixture-planned f) initial)
        (let ((lot (series-seal f)))
          (is (equalp initial copy)) (is (not (eq initial copy)))
          (dolist (wrong (list nil copy))
            (series-refusal
             f (lambda () (registra-commit-serie c (series-fixture-lease f) lot wrong next level))
             'invalid-argument :reason :serie-root-order :lots (list lot)))
          (multiple-value-bind (event generation actual) (series-adopt f lot :root next :level level)
            (is (= 1 generation)) (is (eq next actual))
            (is (eq initial (arcdocdb.series::commit-serie-expected-root event)))
            (is (eq initial (leggi-radice-serie c)))
            (let ((group (series-group f lot)))
              (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
              (series-complete f event generation) (series-publish f event generation 1)
              (is (eq next (leggi-radice-serie c)))
              (is (eq initial (series-root-parent next)))
              (arcdocdb.wal:riusa-gruppo group) (series-retire f event generation)
              (series-counts f 0 0 0)
              (series-frontiers (series-fixture-registry f) 1 nil))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-WAL-006
(deftest test-REQ-AFF-001-series-bootstrap-health-and-ring-precede-effect
  (dolist (scope '(:serie :archive))
    (with-series (f :root nil)
      (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f) scope)
      (series-bootstrap-before-effect
       (lambda ()
         (series-refusal
          f (lambda () (arcdocdb.series:inizializza-radice-serie
                        (series-fixture-controller f) (series-fixture-lease f) (series-root 71 nil)))
          'io-fault :reason :serie-faulted)))
      (series-faulted f scope)))
  (with-series (f :root nil)
    (arcdocdb.wal:marca-log-faulted (series-fixture-log f))
    (let* ((c (series-fixture-controller f))
           (before (series-image (list f) :health-opaque (list c))))
      (series-bootstrap-before-effect
       (lambda ()
         (series-error (lambda () (arcdocdb.series:inizializza-radice-serie
                                  c (series-fixture-lease f) (series-root 71 nil)))
                       'io-fault :log-faulted)))
      (series-faulted f :serie)
      (is (series-image-equal before (series-image (list f) :health-opaque (list c))))))
  (dolist (name '("HEAD" "TAIL" "PUBLISH-HEAD" "COUNT" "UNRESOLVED" "ACTIVE-IO"))
    (with-series (f :root nil :capacity 1)
      (let ((c (series-fixture-controller f)))
        (unwind-protect
             (progn
               (series-fi-set c name (if (string= name "COUNT") 2 1))
               (series-bootstrap-before-effect
                (lambda ()
                  (series-archive-refusal
                   f (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f)
                                                                         (series-root 71 nil)))
                   (if (member name '("HEAD" "TAIL" "PUBLISH-HEAD") :test #'string=)
                       :serie-ring :serie-count))))
               (is (null (arcdocdb.series::controllore-serie-root c)))
               (is (null (arcdocdb.series::controllore-serie-planned-root c))))
          (series-fi-set c name 0))))))

;;; REQ: REQ-AFF-001 REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-AFF-001-series-bootstrap-acquired-effect-exit-preserves-cause-and-roots
  ;; D08: il vero BEGIN ha gia acquisito l'effetto quando la FI esce.
  (dolist (exit '(invalid-argument resource-exhausted io-fault simple-error :nonlocal))
    (with-series (f :root nil)
      (let* ((c (series-fixture-controller f)) (root (series-root 71 nil))
             (before (series-image (list f root) :health-opaque (list c)))
             (begin (symbol-function 'arcdocdb.series::%begin-effect))
             (end (symbol-function 'arcdocdb.series::%end-effect))
             (condition (unless (eq exit :nonlocal)
                          (if (eq exit 'simple-error)
                              (make-condition 'simple-error :format-control "FI bootstrap acquisito")
                              (make-condition exit :reason :bootstrap-injected))))
             (tag (gensym "SERIES-ACQUIRED-EXIT")) (marker (gensym "SERIES-ACQUIRED-MARKER"))
             (begins 0) (ends 0))
        (labels ((invoke ()
                   (series-call-with-function-fi
                    'arcdocdb.series::%begin-effect
                    (lambda (controller)
                      (incf begins)
                      (funcall begin controller)
                      (is (arcdocdb.series::controllore-serie-effect-active controller))
                      (if (eq exit :nonlocal) (throw tag marker) (error condition)))
                    (lambda ()
                      (series-call-with-function-fi
                       'arcdocdb.series::%end-effect
                       (lambda (controller complete)
                         (incf ends)
                         (is (null complete))
                         (is (arcdocdb.series::controllore-serie-effect-active controller))
                         (funcall end controller complete))
                       (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root)))))))
          (if (eq exit :nonlocal)
              (is (eq marker (catch tag (invoke))))
              (is (eq condition (handler-case (progn (invoke) nil) (error (actual) actual))))))
        (is (= 1 begins ends))
        (series-faulted f :archive)
        (is (not (arcdocdb.series::controllore-serie-effect-active c)))
        (is (null (arcdocdb.series::controllore-serie-root c)))
        (is (null (arcdocdb.series::controllore-serie-planned-root c)))
        (is (series-image-equal before (series-image (list f root) :health-opaque (list c))))
        (series-counts f 0 0 0)
        (series-frontiers (series-fixture-registry f) 0 nil)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-CON-002
(deftest test-REQ-AFF-001-series-bootstrap-preexisting-effect-keeps-outer-ownership
  (with-series (f :root nil)
    (let ((c (series-fixture-controller f)) (root (series-root 71 nil)))
      (unwind-protect
           (progn
             (series-fi-set c "EFFECT-ACTIVE" t)
             (series-bootstrap-before-effect
              (lambda ()
                (series-archive-refusal
                 f (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root))
                 :serie-effect)))
             (series-faulted f :archive)
             (is (arcdocdb.series::controllore-serie-effect-active c))
             (is (null (arcdocdb.series::controllore-serie-root c)))
             (is (null (arcdocdb.series::controllore-serie-planned-root c))))
        ;; Riparazione della sola FI per permettere il rilascio della fixture.
        (series-fi-set c "EFFECT-ACTIVE" nil)))))

;;; REQ: REQ-AFF-001 REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-AFF-001-series-bootstrap-cas-corruption-keeps-first-condition-and-faults-archive
  (with-series (f :root nil)
    (let* ((c (series-fixture-controller f)) (root (series-root 71 nil))
           (intruder (series-root 99 nil)) (roots (list root intruder))
           (before (series-bootstrap-preserved-image f roots :fault t))
           (begin (symbol-function 'arcdocdb.series::%begin-effect))
           (end (symbol-function 'arcdocdb.series::%end-effect))
           (first-condition nil) (caught nil) (begins 0) (ends 0))
      (series-call-with-function-fi
       'arcdocdb.series::%begin-effect
       (lambda (controller)
         (incf begins)
         (funcall begin controller)
         (is (arcdocdb.series::controllore-serie-effect-active controller))
         ;; BEGIN ritorna normalmente: l'uscita avviene nel corpo protetto, al CAS.
         (series-fi-set controller "ROOT" intruder)
         nil)
       (lambda ()
         (series-call-with-function-fi
          'arcdocdb.series::%end-effect
          (lambda (controller complete)
            (incf ends)
            (is (null complete))
            (is (arcdocdb.series::controllore-serie-effect-active controller))
            (is (eq intruder (arcdocdb.series::controllore-serie-root controller)))
            ;; Prova anche PLANNED=ROOT prima del CAS che fallisce.
            (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
            (funcall end controller complete))
          (lambda ()
            (setf caught
                  (handler-case
                      (handler-bind ((error (lambda (condition)
                                              (unless first-condition (setf first-condition condition)))))
                        (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root)
                        nil)
                    (invariant-violation (condition) condition)))))))
      (is (typep caught 'invariant-violation))
      (is (eq :serie-root-cas (error-reason caught)))
      (is (eq first-condition caught)) (is (= 1 begins ends))
      (series-faulted f :archive)
      (is (not (arcdocdb.series::controllore-serie-effect-active c)))
      (is (eq intruder (arcdocdb.series::controllore-serie-root c)))
      (is (eq root (arcdocdb.series::controllore-serie-planned-root c)))
      (is (series-image-equal before (series-bootstrap-preserved-image f roots :fault t)))
      (series-counts f 0 0 0)
      (series-frontiers (series-fixture-registry f) 0 nil)
      (series-bootstrap-before-effect
       (lambda ()
         (series-refusal f (lambda () (leggi-radice-serie c)) 'io-fault :reason :serie-faulted)
         (series-refusal
          f (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root))
          'io-fault :reason :serie-faulted))))))

;;; REQ: REQ-AFF-001 REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-AFF-001-series-bootstrap-incomplete-end-preserves-error-and-nonlocal-exit
  (dolist (exit '(:error :nonlocal))
    (with-series (f :root nil)
      (let* ((c (series-fixture-controller f)) (root (series-root 71 nil))
             (before (series-bootstrap-preserved-image f (list root) :fault t))
             (end (symbol-function 'arcdocdb.series::%end-effect))
             (condition (make-condition 'invalid-argument :reason :bootstrap-injected))
             (tag (gensym "SERIES-BOOTSTRAP-EXIT")) (marker (gensym "SERIES-BOOTSTRAP-MARKER"))
             (ends 0))
        (labels ((invoke ()
                   (series-call-with-function-fi
                    'arcdocdb.series::%end-effect
                    (lambda (controller complete)
                      (incf ends)
                      (is (eq c controller)) (is (eq t complete))
                      (is (arcdocdb.series::controllore-serie-effect-active c))
                      (is (eq root (arcdocdb.series::controllore-serie-root c)))
                      (is (eq root (arcdocdb.series::controllore-serie-planned-root c)))
                      ;; FI esplicita: il completamento viene ritirato nel cleanup.
                      (funcall end controller nil)
                      (ecase exit
                        (:error (error condition))
                        (:nonlocal (throw tag marker))))
                    (lambda () (arcdocdb.series:inizializza-radice-serie c (series-fixture-lease f) root)))))
          (ecase exit
            (:error
             (is (eq condition (handler-case (progn (invoke) nil)
                                 (invalid-argument (actual) actual)))))
            (:nonlocal (is (eq marker (catch tag (invoke)))))))
        (is (= 1 ends))
        (series-faulted f :archive)
        (is (not (arcdocdb.series::controllore-serie-effect-active c)))
        (is (eq root (arcdocdb.series::controllore-serie-root c)))
        (is (eq root (arcdocdb.series::controllore-serie-planned-root c)))
        (is (series-image-equal before (series-bootstrap-preserved-image f (list root) :fault t)))
        (series-counts f 0 0 0)
        (series-frontiers (series-fixture-registry f) 0 nil)))))

;;; REQ: REQ-AFF-008 REQ-WAL-005
(deftest test-REQ-AFF-008-series-default-and-capacity-boundaries
  (is (equal (macroexpand-1 '(deftest sample-series-test :ok))
             '(progn (defun sample-series-test () :ok) (pushnew 'sample-series-test *tests*))))
  (is (equal (macroexpand-1 '(with-series (sample :capacity 1) :ok))
             '(call-with-series-fixture (lambda (sample) :ok) :capacity 1)))
  (dolist (capacity '(1 64 1024))
    (with-series (f :capacity capacity :root nil)
      (series-healthy f)
      (series-counts f 0 0 0)
      (is (null (leggi-radice-serie (series-fixture-controller f))))))
  (with-series (f :use-default-capacity t :csn-capacity 65 :root nil)
    (dotimes (i 64) (series-adopt f (series-seal f) :root (series-root i nil)))
    (series-counts f 64 64 0)
    (let ((extra (series-seal f)))
      (series-refusal f
                      (lambda () (registra-commit-serie
                                  (series-fixture-controller f) (series-fixture-lease f) extra
                                  (series-fixture-planned f) nil :async))
                      'resource-exhausted :reason :serie-full :lots (list extra)))
    (is (equalp #(1 0 0 0) (series-fixture-calls f)))))

;;; REQ: REQ-AFF-008 REQ-AFF-004
(deftest test-REQ-AFF-008-series-invalid-configuration-preserves-wal
  (with-series (f)
    (dolist (capacity '(0 -1 1025 nil :bad 1/2))
      (series-refusal f
                      (lambda () (crea-controllore-serie
                                  (series-fixture-registry f) (series-fixture-log f)
                                  :capacity capacity)) 'invalid-argument :reason :serie-budget))
    (dolist (offset (list -1 (1+ most-positive-fixnum) nil :bad 1/2))
      (series-refusal f
                      (lambda () (crea-controllore-serie
                                  (series-fixture-registry f) (series-fixture-log f)
                                  :next-offset offset)) 'invalid-argument :reason :serie-budget))
    (series-healthy f)))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-CON-001-series-lease-busy-stale-and-single-release
  (with-series (f)
    (let ((c (series-fixture-controller f)) (old (series-fixture-lease f)))
      (is (and (typep old 'fixnum) (plusp old)))
      (series-refusal f (lambda () (acquisisci-controllore-serie c))
                      'resource-exhausted :reason :serie-busy)
      (dolist (bad (list 0 -1 (1+ old) nil :bad (1+ most-positive-fixnum)))
        (series-refusal f (lambda () (conta-commit-serie c bad))
                        'invalid-argument :reason :serie-lease)
        (series-refusal f (lambda () (rilascia-controllore-serie c bad))
                        'invalid-argument :reason :serie-lease))
      (is (null (rilascia-controllore-serie c old)))
      (setf (series-fixture-lease f) nil)
      (series-refusal f (lambda () (rilascia-controllore-serie c old))
                      'invalid-argument :reason :serie-lease)
      (setf (series-fixture-lease f) (acquisisci-controllore-serie c))
      (is (> (series-fixture-lease f) old))
      (series-refusal f (lambda () (conta-commit-serie c old))
                      'invalid-argument :reason :serie-lease)
      (series-counts f 0 0 0))))

;;; REQ: REQ-WAL-005 REQ-MVC-008
(deftest test-REQ-WAL-005-series-adopts-sealed-before-io-and-captures-token
  (with-series (f :root nil)
    (let* ((lot (series-seal f))
           ;; Il backlink del log non amplia il dominio WAL/CSN al controller mutato.
           (before (series-image (list lot (series-fixture-registry f) (series-fixture-file f))
                                 :opaque (list (series-fixture-controller f))))
           (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lot)))
           (root (series-root 17 nil)))
      (multiple-value-bind (event generation actual-root) (series-adopt f lot :root root)
        (is (eq root actual-root))
        (is (null (leggi-radice-serie (series-fixture-controller f))))
        (is (equal token (multiple-value-list
                         (leggi-csn-commit-serie (series-fixture-controller f) event generation))))
        (is (series-image-equal
             before (series-image (list lot (series-fixture-registry f) (series-fixture-file f))
                                  :opaque (list (series-fixture-controller f)))))
        (is (eq (series-fixture-controller f)
                (arcdocdb.series:trova-controllore-serie (series-fixture-log f))))
        (series-counts f 1 1 0)
        (is (equalp #(1 0 0 0) (series-fixture-calls f)))
        (series-frontiers (series-fixture-registry f) 1 '(1))))))

;;; REQ: REQ-WAL-005 REQ-AFF-004
(deftest test-REQ-WAL-005-series-refuses-open-unbound-and-post-dispatch-lots
  (dolist (state '(:open :unbound :written))
    (with-series (f)
      (let ((lot (series-open-lot f)))
        (case state
          (:open nil)
          (:unbound (arcdocdb.wal:sigilla-lotto lot 1 0 0))
          (:written
           (series-seal f :lot lot)
           (arcdocdb.wal:scrivi-gruppo (series-group f lot)))
          (otherwise (error "Scenario di test inatteso.")))
        (series-refusal f
                        (lambda () (registra-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f)
                                    lot (series-fixture-planned f) nil :async))
                        'invalid-argument
                        :reason (if (eq state :unbound) :lotto-csn-free :serie-lotto-state)
                        :lots (list lot))
        (series-counts f 0 0 0)))))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-AFF-004-series-registry-and-log-binding-before-adoption
  (with-series (a)
    (with-series (b)
      (let ((lot (series-seal a)))
        (series-refusal (list a b)
                        (lambda () (registra-commit-serie
                                    (series-fixture-controller b) (series-fixture-lease b) lot
                                    (series-fixture-planned b) nil :group))
                        'invalid-argument :reason :lotto-csn-stale :lots (list lot))))
    (with-series (b :registry (series-fixture-registry a))
      (let ((lot (series-seal a)))
        ;; File-id uguale e registro uguale: conta l'identita del log, non i numeri.
        (series-refusal (list a b)
                        (lambda () (registra-commit-serie
                                    (series-fixture-controller b) (series-fixture-lease b) lot
                                    (series-fixture-planned b) nil :group))
                        'invalid-argument :reason :lotto-csn-log :lots (list lot))))))

;;; REQ: REQ-WAL-005 REQ-AFF-004
(deftest test-REQ-WAL-005-series-offset-gap-and-duplicate-preserve-obligation
  (with-series (f)
    (let ((gap (series-seal f :offset 1)))
      (series-refusal f
                      (lambda () (registra-commit-serie
                                  (series-fixture-controller f) (series-fixture-lease f) gap
                                  (series-fixture-planned f) nil :group))
                      'invalid-argument :reason :serie-offset :lots (list gap)))
    (let ((lot (series-seal f)))
      (series-adopt f lot)
      (series-refusal f
                      (lambda () (registra-commit-serie
                                  (series-fixture-controller f) (series-fixture-lease f) lot
                                  (series-fixture-planned f) nil :group))
                      'invalid-argument :reason :serie-offset :lots (list lot))
      (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
      (series-counts f 1 1 0))))

;;; REQ: REQ-MVC-008 REQ-WAL-005
(deftest test-REQ-MVC-008-series-csn-strict-order-even-at-contiguous-offsets
  (dolist (relation '(:equal :older))
    (with-series (f)
      (let* ((first (series-seal f))
             (second (series-seal f :offset (arcdocdb.wal:lunghezza-lotto first))))
        ;; Chiusure reali; l'ordine d'adozione e volutamente inverso. FI solo sugli offset.
        (setf (arcdocdb.wal::lotto-start second) 0)
        (series-adopt f second)
        (let ((candidate (if (eq relation :equal) second first)))
          (setf (arcdocdb.wal::lotto-start candidate) (series-fixture-next f))
          (series-refusal f
                          (lambda () (registra-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      candidate (series-fixture-planned f) nil :group))
                          'invalid-argument :reason :serie-csn-order :lots (list first second))
          (series-counts f 1 1 0))))))

;;; REQ: REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-WAL-006-series-planned-root-eq-and-nil-are-distinct-preconditions
  (with-series (f :root nil)
    (let ((a (series-seal f)) (root (series-root 1 nil)))
      (multiple-value-bind (ea ga ra) (series-adopt f a :root root)
        (is (eq root ra))
        (let ((b (series-seal f)) (copy (series-root 1 nil)))
          (is (equalp root copy)) (is (not (eq root copy)))
          (dolist (wrong (list nil copy))
            (series-refusal f
                            (lambda () (registra-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        b wrong nil :group))
                            'invalid-argument :reason :serie-root-order :lots (list b)))
          (multiple-value-bind (eb gb rb) (series-adopt f b :root nil)
            (is (null rb))
            (series-counts f 2 2 0)
            (is (null (leggi-radice-serie (series-fixture-controller f))))
            (let ((group (series-group f a b)))
              (series-begin f ea ga) (series-begin f eb gb)
              (arcdocdb.wal:esegui-gruppo group)
              (series-complete f ea ga) (series-complete f eb gb)
              (series-publish f ea ga 1)
              (is (eq root (leggi-radice-serie (series-fixture-controller f))))
              (series-publish f eb gb 2)
              (is (null (leggi-radice-serie (series-fixture-controller f)))))))))))

;;; REQ: REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-AFF-008-series-full-keeps-sealed-token-for-later-adoption
  (with-series (f :capacity 1 :csn-capacity 2)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a)
        (let* ((b (series-seal f)) (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto b)))
               (group (series-group f a)))
          (series-refusal f
                          (lambda () (registra-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      b ra (series-root 2 ra) :group))
                          'resource-exhausted :reason :serie-full
                          :lots (list b) :groups (list group))
          (is (eq :sealed (arcdocdb.wal:stato-lotto b)))
          (is (eq :pendente (arcdocdb.wal:stato-csn-lotto b)))
          (series-begin f ea ga) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f ea ga) (series-publish f ea ga 1)
          (arcdocdb.wal:riusa-gruppo group) (series-retire f ea ga)
          (multiple-value-bind (eb gb rb) (series-adopt f b)
            (declare (ignore rb))
            (is (eq ea eb)) (is (> gb ga))
            (is (equal token (multiple-value-list
                             (leggi-csn-commit-serie (series-fixture-controller f) eb gb))))
            (series-counts f 1 1 0)
            (series-frontiers (series-fixture-registry f) 2 '(2))))))))

;;; REQ: REQ-WAL-006 REQ-MVC-008
(deftest test-REQ-WAL-006-series-publication-fifo-unresolved-and-returned-h
  (with-series (f)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a)
        (let ((b (series-seal f)))
          (multiple-value-bind (eb gb rb) (series-adopt f b)
            (let ((group (series-group f a b)))
              (series-begin f ea ga) (series-begin f eb gb)
              (arcdocdb.wal:esegui-gruppo group)
              (series-complete f ea ga) (series-complete f eb gb)
              (series-refusal f
                              (lambda () (pubblica-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          eb gb)) 'invalid-argument :reason :serie-publish-order
                              :groups (list group))
              (series-publish f ea ga 1)
              (is (eq ra (leggi-radice-serie (series-fixture-controller f))))
              (series-counts f 2 1 0)
              (series-publish f eb gb 2)
              (is (eq rb (leggi-radice-serie (series-fixture-controller f))))
              (series-counts f 2 0 0)
              (series-frontiers (series-fixture-registry f) 2 nil))))))))

;;; REQ: REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-WAL-006-series-group-strong-coverage-before-root-cas
  (dolist (level '(:group :strong))
    (with-series (f)
      (let ((lot (series-seal f)) (initial (series-fixture-planned f)))
        (multiple-value-bind (event generation root) (series-adopt f lot :level level)
          (let ((group (series-group f lot)))
            (series-refusal f
                            (lambda () (pubblica-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :serie-io-not-started
                            :groups (list group))
            (series-begin f event generation)
            (series-refusal f
                            (lambda () (pubblica-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :lotto-not-covered
                            :groups (list group))
            (arcdocdb.wal:scrivi-gruppo group)
            (series-refusal f
                            (lambda () (pubblica-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :lotto-not-covered
                            :groups (list group))
            (is (eq initial (leggi-radice-serie (series-fixture-controller f))))
            (arcdocdb.wal:sincronizza-gruppo group) (series-complete f event generation)
            (series-publish f event generation 1)
            (is (eq root (leggi-radice-serie (series-fixture-controller f))))))))))

;;; REQ: REQ-WAL-006 REQ-WAL-002
(deftest test-REQ-WAL-006-series-async-separate-publication-and-retirement-cursors
  (with-series (f :capacity 2)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a :level :async)
        (let ((b (series-seal f)))
          (multiple-value-bind (eb gb rb) (series-adopt f b :level :async)
            (let ((group (series-group f a b)))
              (series-begin f ea ga) (series-begin f eb gb)
              (arcdocdb.wal:scrivi-gruppo group)
              (series-publish f ea ga 1)
              (is (eq ra (leggi-radice-serie (series-fixture-controller f))))
              (series-publish f eb gb 2)
              (is (eq rb (leggi-radice-serie (series-fixture-controller f))))
              (series-counts f 2 0 2)
              (is (eq :written (arcdocdb.wal:stato-lotto a)))
              (is (eq :written (arcdocdb.wal:stato-lotto b)))
              (series-refusal f
                              (lambda () (riusa-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          ea ga)) 'invalid-argument :reason :serie-io-in-flight
                              :groups (list group))
              (arcdocdb.wal:sincronizza-gruppo group)
              (series-complete f ea ga) (series-complete f eb gb)
              (arcdocdb.wal:riusa-gruppo group)
              (series-retire f ea ga) (series-retire f eb gb)
              (series-counts f 0 0 0)
              (is (equalp #(1 2 1 0) (series-fixture-calls f))))))))))

;;; REQ: REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-AFF-004-series-io-begin-once-and-written-is-not-completion
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (declare (ignore root))
        (let ((group (series-group f lot)))
          (series-refusal f
                          (lambda () (completa-io-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :serie-io-state
                          :groups (list group))
          (series-begin f event generation)
          (series-refusal f
                          (lambda () (inizia-io-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :serie-io-state
                          :groups (list group))
          (arcdocdb.wal:scrivi-gruppo group)
          (series-refusal f
                          (lambda () (completa-io-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :serie-io-in-flight
                          :groups (list group))
          (series-counts f 1 1 1)
          (arcdocdb.wal:sincronizza-gruppo group) (series-complete f event generation)
          (series-refusal f
                          (lambda () (completa-io-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :serie-io-state
                          :groups (list group))
          (series-counts f 1 1 0))))))

;;; REQ: REQ-WAL-005 REQ-AFF-004
(deftest test-REQ-WAL-005-series-retirement-fifo-resolved-durable-unowned
  (with-series (f)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a)
        (declare (ignore ra))
        (let ((b (series-seal f)))
          (multiple-value-bind (eb gb rb) (series-adopt f b)
            (declare (ignore rb))
            (let ((group (series-group f a b)))
              (series-begin f ea ga) (series-begin f eb gb)
              (arcdocdb.wal:esegui-gruppo group)
              (series-complete f ea ga) (series-complete f eb gb)
              (series-refusal f
                              (lambda () (riusa-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          ea ga)) 'invalid-argument :reason :serie-event-state
                              :groups (list group))
              (series-publish f ea ga 1) (series-publish f eb gb 2)
              (series-refusal f
                              (lambda () (riusa-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          ea ga)) 'invalid-argument :reason :lotto-owned
                              :groups (list group))
              (arcdocdb.wal:riusa-gruppo group)
              (series-refusal f
                              (lambda () (riusa-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          eb gb)) 'invalid-argument :reason :serie-retire-order)
              (series-retire f ea ga) (series-retire f eb gb)
              (is (eq :open (arcdocdb.wal:stato-lotto a)))
              (is (eq :open (arcdocdb.wal:stato-lotto b)))
              (series-counts f 0 0 0))))))))

;;; REQ: REQ-AFF-004 REQ-WAL-005
(deftest test-REQ-AFF-004-series-free-and-stale-preallocated-event-after-wrap
  (with-series (f :capacity 1)
    (let ((lot (series-seal f)))
      (multiple-value-bind (old-event old-generation root) (series-adopt f lot)
        (declare (ignore root))
        (let ((group (series-group f lot)))
          (series-begin f old-event old-generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f old-event old-generation) (series-publish f old-event old-generation 1)
          (arcdocdb.wal:riusa-gruppo group) (series-retire f old-event old-generation)
          (is (eq :libero (stato-commit-serie (series-fixture-controller f) old-event old-generation)))
          (series-refusal f
                          (lambda () (leggi-csn-commit-serie
                                      (series-fixture-controller f) old-event old-generation))
                          'invalid-argument :reason :serie-event-state)
          (arcdocdb.wal:aggiungi-record lot 1 (bytes 2) (bytes #xa0))
          (series-seal f :lot lot)
          (multiple-value-bind (event generation new-root) (series-adopt f lot)
            (declare (ignore new-root))
            (is (eq old-event event)) (is (> generation old-generation))
            (dolist (operation (list #'stato-commit-serie #'leggi-csn-commit-serie))
              (series-refusal f
                              (lambda () (funcall operation (series-fixture-controller f)
                                                  old-event old-generation))
                              'invalid-argument :reason :serie-event))
            (dolist (operation (list #'inizia-io-commit-serie #'completa-io-commit-serie
                                     #'ritira-io-commit-serie
                                     #'pubblica-commit-serie #'riusa-commit-serie
                                     #'annulla-commit-serie))
              (series-refusal f
                              (lambda () (funcall operation (series-fixture-controller f)
                                                  (series-fixture-lease f) old-event old-generation))
                              'invalid-argument :reason :serie-event))
            (series-counts f 1 1 0)))))))

;;; REQ: REQ-AFF-004 REQ-CON-001
(deftest test-REQ-AFF-004-series-foreign-event-same-generation-and-csn
  (with-series (a)
    (with-series (b)
      (multiple-value-bind (ea ga ra) (series-adopt a (series-seal a))
        (declare (ignore ra))
        (multiple-value-bind (eb gb rb) (series-adopt b (series-seal b))
          (declare (ignore rb))
          (is (= ga gb)) (is (not (eq ea eb)))
          (is (equal (multiple-value-list (leggi-csn-commit-serie (series-fixture-controller a) ea ga))
                     (multiple-value-list (leggi-csn-commit-serie (series-fixture-controller b) eb gb))))
          (dolist (operation (list #'stato-commit-serie #'leggi-csn-commit-serie))
            (series-refusal (list a b)
                            (lambda () (funcall operation (series-fixture-controller b) ea ga))
                            'invalid-argument :reason :serie-event))
          (dolist (operation (list #'inizia-io-commit-serie #'completa-io-commit-serie
                                   #'ritira-io-commit-serie
                                   #'pubblica-commit-serie #'riusa-commit-serie #'annulla-commit-serie))
            (series-refusal (list a b)
                            (lambda () (funcall operation (series-fixture-controller b)
                                                (series-fixture-lease b) ea ga))
                            'invalid-argument :reason :serie-event)))))))

;;; REQ: REQ-AFF-004 REQ-WAL-006
(deftest test-REQ-AFF-004-series-false-event-and-invalid-generation-before-mutation
  (with-series (f)
    (multiple-value-bind (event generation root) (series-adopt f (series-seal f))
      (declare (ignore root))
      (dolist (fake (list nil :fake (list event generation)))
        (series-refusal f
                        (lambda () (stato-commit-serie (series-fixture-controller f) fake generation))
                        'invalid-argument :reason :serie-event)
        (series-refusal f
                        (lambda () (inizia-io-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f)
                                    fake generation)) 'invalid-argument :reason :serie-event))
      (dolist (bad (list 0 -1 (1+ generation) nil :fake (1+ most-positive-fixnum)))
        (series-refusal f
                        (lambda () (pubblica-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f)
                                    event bad)) 'invalid-argument :reason :serie-event))
      ;; FI: una copia interna conserva controller/numero ma non l'identita dello slot.
      (let ((clone (copy-structure event))
            (before (series-image (list event (series-fixture-registry f)
                                        (series-fixture-log f))
                                  :opaque (list (series-fixture-controller f)))))
        (series-error
         (lambda () (stato-commit-serie (series-fixture-controller f) clone generation))
         'invariant-violation :serie-event-slot)
        (series-faulted f :archive)
        (is (series-image-equal
             before (series-image (list event (series-fixture-registry f)
                                       (series-fixture-log f))
                                 :opaque (list (series-fixture-controller f)))))))))

;;; REQ: REQ-MVC-008 REQ-WAL-006
(deftest test-REQ-MVC-008-series-busy-after-cas-keeps-root-once-and-captured-token
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (let ((group (series-group f lot))
              (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lot))))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation)
          ;; Rientranza: forza :csn-busy in modo deterministico, senza attesa.
          (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex (series-fixture-registry f)))
            (series-pending
             (lambda () (pubblica-commit-serie
                         (series-fixture-controller f) (series-fixture-lease f) event generation)))
            (is (eq root (leggi-radice-serie (series-fixture-controller f))))
            (is (eq :pubblicato (stato-commit-serie (series-fixture-controller f) event generation)))
            (is (equal token (multiple-value-list
                             (leggi-csn-commit-serie (series-fixture-controller f) event generation))))
            (let ((before (series-fixture-image (list f) nil (list group))))
              (dotimes (i 3)
                (series-pending
                 (lambda () (pubblica-commit-serie
                             (series-fixture-controller f) (series-fixture-lease f) event generation))))
              (is (series-image-equal before (series-fixture-image (list f) nil (list group))))))
          ;; Un secondo CAS expected->new fallirebbe: expected e new sono distinti.
          (series-publish f event generation 1)
          (is (eq root (leggi-radice-serie (series-fixture-controller f))))
          (series-frontiers (series-fixture-registry f) 1 nil))))))

;;; REQ: REQ-MVC-008 REQ-WAL-006
(deftest test-REQ-MVC-008-series-high-csn-carry-and-delayed-global-horizon
  (dolist (base '(#xfffffffe #x7ffffffffffffffe #xfffffffffffffffc))
    (with-series (a :base base)
      (with-series (b :registry (series-fixture-registry a) :base base)
        (let ((la (series-seal a)) (lb (series-seal b)))
          (multiple-value-bind (ea ga ra) (series-adopt a la)
            (multiple-value-bind (eb gb rb) (series-adopt b lb)
              (let ((ag (series-group a la)) (bg (series-group b lb)))
                (series-begin a ea ga) (series-begin b eb gb)
                (arcdocdb.wal:esegui-gruppo ag) (arcdocdb.wal:esegui-gruppo bg)
                (series-complete a ea ga) (series-complete b eb gb)
                (let ((ta (multiple-value-list (leggi-csn-commit-serie (series-fixture-controller a) ea ga)))
                      (tb (multiple-value-list (leggi-csn-commit-serie (series-fixture-controller b) eb gb))))
                  (is (= (1+ base) (series-number (second ta) (third ta))))
                  (is (= (+ base 2) (series-number (second tb) (third tb)))))
                (series-publish b eb gb base)
                (is (eq rb (leggi-radice-serie (series-fixture-controller b))))
                (series-frontiers (series-fixture-registry a) (+ base 2) (list (1+ base)))
                (series-publish a ea ga (+ base 2))
                (is (eq ra (leggi-radice-serie (series-fixture-controller a))))
                (series-frontiers (series-fixture-registry a) (+ base 2) nil)))))))))

;;; REQ: REQ-AFF-001 REQ-WAL-006
(deftest test-REQ-AFF-001-series-known-write-and-flush-fault-drain-and-annul
  (dolist (operation '(:write :flush))
    (let ((failure (arcdocdb.io.tests::raises-errno sb-posix:eio)))
      (with-series (f :writer (when (eq operation :write) failure)
                     :flush (when (eq operation :flush) failure))
        (let ((lot (series-seal f)))
          (multiple-value-bind (event generation root) (series-adopt f lot)
            (declare (ignore root))
            (let ((group (series-group f lot)))
              (series-begin f event generation)
              (signals io-fault (arcdocdb.wal:esegui-gruppo group))
              (is (eq :faulted (arcdocdb.wal:stato-lotto lot)))
              (when (eq operation :write)
                (is (null (fault-controllore-serie
                           (series-fixture-controller f) (series-fixture-lease f))))
                (series-faulted f :serie))
              (series-complete f event generation)
              (series-faulted f :serie)
              (series-counts f 1 1 0)
              (series-annul f event generation 1)
              (is (eq :risolto (arcdocdb.wal:stato-csn-lotto lot)))
              (series-refusal f
                              (lambda () (riusa-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          event generation)) 'io-fault :reason :serie-faulted
                              :groups (list group))
              (is (eq :faulted (arcdocdb.wal:stato-lotto lot)))
              (series-counts f 1 0 0))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-series-terminal-fault-and-scope-only-upgrades
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (declare (ignore root))
        (series-refusal f
                        (lambda () (fault-controllore-serie
                                    (series-fixture-controller f) (series-fixture-lease f) :bad))
                        'invalid-argument :reason :serie-fault-scope)
        (is (null (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))))
        (series-faulted f :serie)
        (series-refusal f (lambda () (leggi-radice-serie (series-fixture-controller f)))
                        'io-fault :reason :serie-faulted)
        (series-refusal f
                        (lambda () (inizia-io-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f)
                                    event generation)) 'io-fault :reason :serie-faulted)
        (series-refusal f
                        (lambda () (pubblica-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f)
                                    event generation)) 'io-fault :reason :serie-faulted)
        (is (null (fault-controllore-serie
                   (series-fixture-controller f) (series-fixture-lease f) :archive)))
        (series-faulted f :archive)
        (is (null (fault-controllore-serie
                   (series-fixture-controller f) (series-fixture-lease f) :serie)))
        (series-faulted f :archive)
        (let ((next (series-open-lot f)))
          (series-refusal f
                          (lambda () (registra-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      next (series-fixture-planned f) nil :group))
                          'io-fault :reason :serie-faulted :lots (list next)))
        (series-counts f 1 1 0)))))

;;; REQ: REQ-AFF-001 REQ-MVC-008
(deftest test-REQ-AFF-001-series-annul-requires-local-fault-and-global-quiescence
  (with-series (f)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a)
        (declare (ignore ra))
        (let ((b (series-seal f)))
          (multiple-value-bind (eb gb rb) (series-adopt f b)
            (declare (ignore rb))
            (let ((group (series-group f a b)))
              (series-refusal f
                              (lambda () (annulla-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          ea ga)) 'invalid-argument :reason :serie-fault-scope
                              :groups (list group))
              (series-begin f ea ga) (series-begin f eb gb)
              (arcdocdb.wal:esegui-gruppo group)
              (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
              (series-complete f ea ga)
              ;; A e concluso ma B appartiene ancora al compito: rifiuto sull'intera Serie.
              (series-refusal f
                              (lambda () (annulla-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          ea ga)) 'invalid-argument :reason :serie-io-active
                              :groups (list group))
              (is (eq :open (arcdocdb.wal:stato-log (series-fixture-log f))))
              (series-counts f 2 2 1)
              (series-complete f eb gb)
              (series-annul f ea ga 1) (series-annul f eb gb 2)
              (is (eq :faulted (arcdocdb.wal:stato-log (series-fixture-log f))))
              (series-frontiers (series-fixture-registry f) 2 nil))))))))

;;; REQ: REQ-MVC-008 REQ-AFF-001
(deftest test-REQ-MVC-008-series-annul-fifo-busy-preserves-captured-obligation
  (with-series (f)
    (let ((a (series-seal f)))
      (multiple-value-bind (ea ga ra) (series-adopt f a)
        (declare (ignore ra))
        (let ((b (series-seal f)))
          (multiple-value-bind (eb gb rb) (series-adopt f b)
            (declare (ignore rb))
            (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
            (series-refusal f
                            (lambda () (annulla-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        eb gb)) 'invalid-argument :reason :serie-publish-order)
            (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex (series-fixture-registry f)))
              (series-pending
               (lambda () (annulla-commit-serie
                           (series-fixture-controller f) (series-fixture-lease f) ea ga)))
              (is (eq :preparato (stato-commit-serie (series-fixture-controller f) ea ga)))
              (is (eq :pendente (arcdocdb.wal:stato-csn-lotto a)))
              (is (eq :faulted (arcdocdb.wal:stato-log (series-fixture-log f))))
              (let ((before (series-fixture-image (list f) nil nil)))
                (series-pending
                 (lambda () (annulla-commit-serie
                             (series-fixture-controller f) (series-fixture-lease f) ea ga)))
                (is (series-image-equal before (series-fixture-image (list f) nil nil)))))
            (series-counts f 2 2 0)
            (series-annul f ea ga 1) (series-annul f eb gb 2)
            (series-counts f 2 0 0)
            (series-refusal f
                            (lambda () (annulla-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        ea ga)) 'invalid-argument :reason :serie-publish-order)
            (is (eq :sealed (arcdocdb.wal:stato-lotto a)))
            (series-refusal f
                            (lambda () (riusa-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        ea ga)) 'io-fault :reason :serie-faulted)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-series-archive-fault-refuses-automatic-annul
  (with-series (f)
    (multiple-value-bind (event generation root) (series-adopt f (series-seal f))
      (declare (ignore root))
      (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f) :archive)
      (series-refusal f
                      (lambda () (annulla-commit-serie
                                  (series-fixture-controller f) (series-fixture-lease f)
                                  event generation)) 'invalid-argument :reason :serie-fault-scope)
      (is (eq :open (arcdocdb.wal:stato-log (series-fixture-log f))))
      (series-counts f 1 1 0)
      (series-frontiers (series-fixture-registry f) 1 '(1)))))

;;; REQ: REQ-AFF-004 REQ-MVC-008
(deftest test-REQ-AFF-004-series-captured-token-never-reconstructed-from-mutated-lot
  (with-series (f)
    (let ((lot (series-seal f)) (initial (series-fixture-planned f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (declare (ignore root))
        (let ((group (series-group f lot))
              (token (multiple-value-list (leggi-csn-commit-serie
                                          (series-fixture-controller f) event generation))))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation)
          (incf (arcdocdb.wal::lotto-csn-low lot))
          (let ((before (series-image (list lot (series-fixture-registry f) group event)
                                      :opaque (list (series-fixture-controller f)))))
            (series-error
             (lambda () (pubblica-commit-serie
                         (series-fixture-controller f) (series-fixture-lease f) event generation))
             'invalid-argument :lotto-csn-stale)
            (series-faulted f :archive)
            (is (eq initial (arcdocdb.series::controllore-serie-root
                             (series-fixture-controller f))))
            (is (series-image-equal
                 before (series-image (list lot (series-fixture-registry f) group event)
                                      :opaque (list (series-fixture-controller f))))))
          (is (equal token (multiple-value-list
                           (leggi-csn-commit-serie (series-fixture-controller f) event generation))))
          (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f) :serie)
          (series-faulted f :archive)
          (series-frontiers (series-fixture-registry f) 1 '(1)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-series-registry-invariant-after-root-cas-faults-archive
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (let ((group (series-group f lot)))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation)
          ;; La copertura WAL resta valida; il guasto appare al resolver dopo il CAS.
          (setf (arcdocdb.csn::registro-csn-used (series-fixture-registry f)) 0)
          ;; Root e salute cambiano come verificato sotto; WAL, CSN e gruppo restano intatti.
          (let ((before (series-image (list lot (series-fixture-registry f) group)
                                      :opaque (list (series-fixture-controller f)))))
            (series-error
             (lambda () (pubblica-commit-serie
                         (series-fixture-controller f) (series-fixture-lease f) event generation))
             'invariant-violation)
            (series-faulted f :archive)
            (is (series-image-equal
                 before (series-image (list lot (series-fixture-registry f) group)
                                      :opaque (list (series-fixture-controller f)))))
            (is (eq (series-fixture-controller f)
                    (arcdocdb.series:trova-controllore-serie (series-fixture-log f)))))
          (is (eq root (slot-value (series-fixture-controller f)
                                  (sb-mop:slot-definition-name
                                   (series-private-slot (series-fixture-controller f) "ROOT")))))
          (series-refusal f
                          (lambda () (annulla-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument
                          :reason :serie-fault-scope))))))

;;; REQ: REQ-AFF-001 REQ-WAL-006
(deftest test-REQ-AFF-001-series-unexpected-root-cas-and-nonlocal-exit-fault-archive
  (dolist (fault '(:root :cas :nonlocal :wrong-busy :late-invalid))
    (with-series (f)
      (let ((lot (series-seal f)))
        (multiple-value-bind (event generation root) (series-adopt f lot)
          (let ((group (series-group f lot)))
            (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
            (series-complete f event generation)
            (ecase fault
              (:root
               (series-fi-set (series-fixture-controller f) "ROOT" (series-root 999 nil))
               (series-error
                (lambda () (pubblica-commit-serie
                            (series-fixture-controller f) (series-fixture-lease f) event generation))
                'invariant-violation :serie-root-invariant))
              (:cas
               ;; FI tra preflight e CAS: conserva la fase incerta :pubblicando.
               (let ((original (symbol-function 'arcdocdb.series::%publish-root)))
                 (series-call-with-function-fi
                  'arcdocdb.series::%publish-root
                  (lambda (controller commit)
                    (series-fi-set controller "ROOT" (series-root 999 nil))
                    (funcall original controller commit))
                  (lambda ()
                    (series-error
                     (lambda () (pubblica-commit-serie
                                 (series-fixture-controller f) (series-fixture-lease f)
                                 event generation)) 'invariant-violation :serie-root-cas))))
               (is (eq :pubblicando (arcdocdb.series::commit-serie-phase event)))
               (series-refusal f
                               (lambda () (stato-commit-serie
                                           (series-fixture-controller f) event generation))
                               'invariant-violation :reason :serie-event-uncertain
                               :groups (list group)))
              (:nonlocal
               (let ((tag (gensym "SERIES-EXIT")))
                 (is (eq :injected
                         (catch tag
                           (series-call-with-function-fi
                            'arcdocdb.wal:risolvi-lotto-pubblicato
                            (lambda (&rest args) (declare (ignore args)) (throw tag :injected))
                            (lambda () (pubblica-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)))))))
               (is (eq root (slot-value (series-fixture-controller f)
                                       (sb-mop:slot-definition-name
                                        (series-private-slot (series-fixture-controller f) "ROOT"))))))
              ((:wrong-busy :late-invalid)
               (let ((type (if (eq fault :wrong-busy) 'resource-exhausted 'invalid-argument))
                     (reason (if (eq fault :wrong-busy) :csn-full :injected-after-cas)))
                 (series-call-with-function-fi
                  'arcdocdb.wal:risolvi-lotto-pubblicato
                  (lambda (&rest args) (declare (ignore args)) (error type :reason reason))
                  (lambda ()
                    (series-error
                     (lambda () (pubblica-commit-serie
                                 (series-fixture-controller f) (series-fixture-lease f)
                                 event generation)) type reason))))
               (is (eq root (slot-value (series-fixture-controller f)
                                       (sb-mop:slot-definition-name
                                        (series-private-slot (series-fixture-controller f) "ROOT")))))))
            (series-faulted f :archive)
            (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
            (series-frontiers (series-fixture-registry f) 1 '(1))
            (series-refusal f
                            (lambda () (annulla-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument
                            :reason :serie-fault-scope)))))))

;;; REQ: REQ-AFF-008 REQ-CON-001
(deftest test-REQ-AFF-008-series-lease-and-event-generations-exhaust-without-wrap
  (with-series (f)
    (let ((c (series-fixture-controller f)) (old (series-fixture-lease f)))
      (rilascia-controllore-serie c old)
      (setf (series-fixture-lease f) nil)
      (series-fi-set c "LEASE-GENERATION" (1- most-positive-fixnum))
      (let ((last-lease (acquisisci-controllore-serie c)))
        (is (= most-positive-fixnum last-lease))
        (rilascia-controllore-serie c last-lease))
      (series-refusal f (lambda () (acquisisci-controllore-serie c))
                      'resource-exhausted :reason :serie-lease-generation)))
  (with-series (f)
    (let ((lot (series-seal f)))
      (series-fi-set (series-fixture-controller f) "EVENT-GENERATION" (1- most-positive-fixnum))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (declare (ignore event root))
        (is (= most-positive-fixnum generation)))
      (setf lot (series-seal f))
      (series-refusal f
                      (lambda () (registra-commit-serie
                                  (series-fixture-controller f) (series-fixture-lease f) lot
                                  (series-fixture-planned f) nil :group))
                      'resource-exhausted :reason :serie-event-generation :lots (list lot))
      (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
      (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
      (series-frontiers (series-fixture-registry f) 2 '(1 2)))))

;;; REQ: REQ-WAL-006 REQ-AFF-004
(deftest test-REQ-WAL-006-series-invalid-level-and-publication-replay-preserve-state
  (with-series (f)
    (let ((lot (series-seal f)))
      (dolist (level '(nil :bad :sync 7))
        (series-refusal f
                        (lambda () (registra-commit-serie
                                    (series-fixture-controller f) (series-fixture-lease f) lot
                                    (series-fixture-planned f) nil level))
                        'invalid-argument :reason :serie-level :lots (list lot)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (let ((group (series-group f lot)))
          (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
          (series-complete f event generation) (series-publish f event generation 1)
          (series-refusal f
                          (lambda () (pubblica-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :serie-publish-order
                          :groups (list group))
          (is (eq root (leggi-radice-serie (series-fixture-controller f))))
          (series-frontiers (series-fixture-registry f) 1 nil))))))

;;; REQ: REQ-WAL-006 REQ-MVC-008 REQ-CON-002 REQ-AFF-001
(deftest test-REQ-WAL-006-series-rejected-dispatch-withdraws-without-io-and-h-converges
  (dolist (group-state '(:building :ready))
    (let ((base #xffffffff))
      (with-series (f :base base :capacity 2 :csn-capacity 2)
        (let ((a (series-seal f)) (initial (series-fixture-planned f)))
          (multiple-value-bind (ea ga ra) (series-adopt f a)
            (declare (ignore ra))
            (let ((b (series-seal f)))
              (multiple-value-bind (eb gb rb) (series-adopt f b)
                (declare (ignore rb))
                (let ((group (arcdocdb.wal:crea-gruppo (series-fixture-log f) :max-lots 2))
                      (a-bytes (copy-seq (arcdocdb.wal::lotto-buffer a)))
                      (b-bytes (copy-seq (arcdocdb.wal::lotto-buffer b)))
                      (ta (multiple-value-list (leggi-csn-commit-serie
                                               (series-fixture-controller f) ea ga)))
                      (tb (multiple-value-list (leggi-csn-commit-serie
                                               (series-fixture-controller f) eb gb))))
                  (arcdocdb.wal:aggiungi-lotto group a)
                  (arcdocdb.wal:aggiungi-lotto group b)
                  (when (eq group-state :ready) (arcdocdb.wal:chiudi-gruppo group))
                  (series-begin f ea ga) (series-begin f eb gb)
                  ;; Lo scheduler della fixture non ha mai accettato il compito.
                  (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
                  (arcdocdb.wal:annulla-gruppo group)
                  (series-withdraw-io f ea ga)
                  (series-counts f 2 2 1)
                  (series-refusal f
                                  (lambda () (annulla-commit-serie
                                              (series-fixture-controller f) (series-fixture-lease f)
                                              ea ga)) 'invalid-argument :reason :serie-io-active
                                  :groups (list group))
                  (is (eq :open (arcdocdb.wal:stato-log (series-fixture-log f))))
                  (series-withdraw-io f eb gb)
                  (series-counts f 2 2 0)
                  (is (eq :preparato (stato-commit-serie (series-fixture-controller f) ea ga)))
                  (is (eq :preparato (stato-commit-serie (series-fixture-controller f) eb gb)))
                  (is (eq :pendente (arcdocdb.wal:stato-csn-lotto a)))
                  (is (eq :pendente (arcdocdb.wal:stato-csn-lotto b)))
                  (is (equal ta (multiple-value-list
                                (leggi-csn-commit-serie (series-fixture-controller f) ea ga))))
                  (is (equal tb (multiple-value-list
                                (leggi-csn-commit-serie (series-fixture-controller f) eb gb))))
                  (series-frontiers (series-fixture-registry f) (+ base 2)
                                    (list (1+ base) (+ base 2)))
                  (series-annul f ea ga (1+ base))
                  (series-annul f eb gb (+ base 2))
                  (series-frontiers (series-fixture-registry f) (+ base 2) nil)
                  (series-counts f 2 0 0)
                  (is (eq initial (arcdocdb.series::controllore-serie-root
                                   (series-fixture-controller f))))
                  (is (eq :sealed (arcdocdb.wal:stato-lotto a)))
                  (is (eq :sealed (arcdocdb.wal:stato-lotto b)))
                  (is (equalp a-bytes (arcdocdb.wal::lotto-buffer a)))
                  (is (equalp b-bytes (arcdocdb.wal::lotto-buffer b)))
                  (is (equalp #(1 0 0 0) (series-fixture-calls f)))
                  (is (zerop (arcdocdb.io:posizione-scritta (series-fixture-file f))))
                  (is (zerop (arcdocdb.io:posizione-durevole (series-fixture-file f)))))))))))))

;;; REQ: REQ-WAL-006 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-series-withdraw-refuses-healthy-owned-written-stale-and-double
  (dolist (group-state '(:building :ready))
    (with-series (f)
      (let ((lot (series-seal f)))
        (multiple-value-bind (event generation root) (series-adopt f lot)
          (declare (ignore root))
          (let ((group (arcdocdb.wal:crea-gruppo (series-fixture-log f) :max-lots 1)))
            (arcdocdb.wal:aggiungi-lotto group lot)
            (when (eq group-state :ready) (arcdocdb.wal:chiudi-gruppo group))
            (series-begin f event generation)
            (series-refusal f
                            (lambda () (ritira-io-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :serie-not-faulted
                            :groups (list group))
            (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
            (series-refusal f
                            (lambda () (ritira-io-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :lotto-owned
                            :groups (list group))
            (arcdocdb.wal:annulla-gruppo group)
            (dolist (bad (list 0 -1 nil (1+ generation)))
              (series-refusal f
                              (lambda () (ritira-io-commit-serie
                                          (series-fixture-controller f) (series-fixture-lease f)
                                          event bad)) 'invalid-argument :reason :serie-event
                              :groups (list group)))
            (series-counts f 1 1 1)
            (series-withdraw-io f event generation)
            (series-counts f 1 1 0)
            (series-refusal f
                            (lambda () (ritira-io-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :serie-io-state
                            :groups (list group))
            (series-refusal f
                            (lambda () (completa-io-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :serie-io-state
                            :groups (list group))
            (series-annul f event generation 1)
            (is (equalp #(1 0 0 0) (series-fixture-calls f))))))))
  (with-series (f)
    (let ((lot (series-seal f)))
      (multiple-value-bind (event generation root) (series-adopt f lot)
        (declare (ignore root))
        (let ((group (series-group f lot)))
          (series-begin f event generation) (arcdocdb.wal:scrivi-gruppo group)
          (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
          (series-refusal f
                          (lambda () (ritira-io-commit-serie
                                      (series-fixture-controller f) (series-fixture-lease f)
                                      event generation)) 'invalid-argument :reason :lotto-state
                          :groups (list group))
          (series-counts f 1 1 1)
          (arcdocdb.wal:sincronizza-gruppo group)
          (series-complete f event generation)
          (series-annul f event generation 1)
          (series-counts f 1 0 0)
          (is (equalp #(1 1 1 0) (series-fixture-calls f))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001 REQ-WAL-005
(deftest test-REQ-AFF-004-series-wal-preflight-invariants-fault-before-adoption-or-release
  ;; %CAPTURE-TOKEN: associazione incompleta di un lotto sealed prima dell'adozione.
  (with-series (f)
    (let ((lot (series-seal f)))
      (setf (arcdocdb.wal::lotto-csn-log lot) nil)
      (series-archive-refusal
       f (lambda () (registra-commit-serie
                     (series-fixture-controller f) (series-fixture-lease f) lot
                     (series-fixture-planned f) (series-root 1 (series-fixture-planned f)) :group))
       :lotto-csn-token :lots (list lot))
      (series-counts f 0 0 0)
      (series-frontiers (series-fixture-registry f) 1 '(1))
      (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
      (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
      (is (equalp #(1 0 0 0) (series-fixture-calls f)))))
  ;; %CHECK-LOTTO-RELEASE: due preflight reali; nessun mutamento dell'evento prima del fault.
  (dolist (kind '(:riuso :ritiro))
    (with-series (f)
      (let ((lot (series-seal f)))
        (multiple-value-bind (event generation root) (series-adopt f lot)
          (declare (ignore root))
          (let ((group (series-group f lot)))
            (series-begin f event generation)
            (ecase kind
              (:riuso
               (arcdocdb.wal:esegui-gruppo group) (series-complete f event generation)
               (series-publish f event generation 1) (arcdocdb.wal:riusa-gruppo group))
              (:ritiro
               (fault-controllore-serie (series-fixture-controller f) (series-fixture-lease f))
               (arcdocdb.wal:annulla-gruppo group)))
            (setf (arcdocdb.wal::lotto-used lot) (1+ (length (arcdocdb.wal::lotto-buffer lot))))
            (series-archive-refusal
             f (lambda () (funcall (if (eq kind :riuso) #'riusa-commit-serie #'ritira-io-commit-serie)
                                  (series-fixture-controller f) (series-fixture-lease f)
                                  event generation))
             :lotto-length :groups (list group))
            (ecase kind
              (:riuso
               (series-counts f 1 0 0)
               (is (eq :risolto (stato-commit-serie (series-fixture-controller f) event generation)))
               (is (eq :durable (arcdocdb.wal:stato-lotto lot)))
               (series-frontiers (series-fixture-registry f) 1 nil))
              (:ritiro
               (series-counts f 1 1 1)
               (is (eq :preparato (stato-commit-serie (series-fixture-controller f) event generation)))
               (is (eq :sealed (arcdocdb.wal:stato-lotto lot)))
               (series-frontiers (series-fixture-registry f) 1 '(1))
               (is (equalp #(1 0 0 0) (series-fixture-calls f)))))))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001 REQ-WAL-006
(deftest test-REQ-AFF-004-series-uncertain-getter-faults-archive-before-and-after-cas
  (dolist (window '(:before-cas :after-cas))
    (with-series (f)
      (let ((lot (series-seal f)))
        (multiple-value-bind (event generation root) (series-adopt f lot)
          (let ((group (series-group f lot)))
            (series-begin f event generation) (arcdocdb.wal:esegui-gruppo group)
            (series-complete f event generation)
            ;; FI di una finestra interrotta: phase non prova se il CAS sia gia avvenuto.
            (series-fi-set event "PHASE" :pubblicando)
            (when (eq window :after-cas)
              (series-fi-set (series-fixture-controller f) "ROOT" root))
            (series-archive-refusal
             f (lambda () (stato-commit-serie (series-fixture-controller f) event generation))
             :serie-event-uncertain :groups (list group))
            (is (eq :pubblicando (arcdocdb.series::commit-serie-phase event)))
            (series-counts f 1 1 0)
            (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lot)))
            (series-frontiers (series-fixture-registry f) 1 '(1))
            (series-refusal f
                            (lambda () (leggi-radice-serie (series-fixture-controller f)))
                            'io-fault :reason :serie-faulted :groups (list group))
            (series-refusal f
                            (lambda () (annulla-commit-serie
                                        (series-fixture-controller f) (series-fixture-lease f)
                                        event generation)) 'invalid-argument :reason :serie-fault-scope
                            :groups (list group))
            (is (equalp #(1 1 1 0) (series-fixture-calls f)))))))))
