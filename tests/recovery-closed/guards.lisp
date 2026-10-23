;;;; FI seriali di ritorni interni impossibili; nessuna evidenza di corruzione fisica.
;;; OWNER: runner dopo il join delle prove native; nessun worker o nuova capacità.
;;; SHARED: sostituzioni FDEFINITION limitate all'estensione dinamica e sempre ripristinate.
;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.closed.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun cdrg-with-function (name replacement thunk)
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn (setf (fdefinition name) replacement) (funcall thunk))
      (setf (fdefinition name) original))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-io-header-body-returns
  (dolist (version '(1 2))
    (dolist (target '(0 64))
      (let ((original (fdefinition 'io:leggi-esatto)))
        (cdr-with-fixture (cdrr-log version 1)
          (lambda (f)
            (cdrg-with-function 'io:leggi-esatto
              (lambda (input scratch start end offset)
                (if (= offset target) start (funcall original input scratch start end offset)))
              (lambda ()
                (cdr-expect 'invariant-violation
                  (if (zerop target) :closed-recovery-header-read :closed-recovery-read)
                  (lambda () (cdr-call f)))))
            (cdrr-events f (if (zerop target) nil '((:read 502 0 64 0))))
            (cdr-noeffects f)
            (cdr-clear f) (cdrr-success f version 1 2 2))
          :version version)))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-header-each-conjunct
  (dolist (variant '(:next :created))
    (let ((original (fdefinition 'arcdocdb.storage.format:verifica-header-segmento)))
      (cdr-with-fixture (cdr-log nil)
        (lambda (f)
          (cdrg-with-function 'arcdocdb.storage.format:verifica-header-segmento
            (lambda (&rest args)
              (multiple-value-bind (next version origin created) (apply original args)
                (values (if (eq variant :next) 63 next) version origin
                        (if (eq variant :created) next created))))
            (lambda () (cdr-expect 'invariant-violation :closed-recovery-header (lambda () (cdr-call f)))))
          (cdrr-events f '((:read 502 0 64 0))) (cdr-noeffects f)
          (cdr-clear f) (cdrr-success f 2 1 0 0))))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-manifest-impossible-prefix
  (dolist (prefix '(63 #x100000000))
    (let ((original (fdefinition 'arcdocdb.recovery.manifest:trova-segmento)))
      (cdr-with-fixture (cdr-log nil)
        (lambda (f)
          (cdrg-with-function 'arcdocdb.recovery.manifest:trova-segmento
            (lambda (manifest id)
              (multiple-value-bind (state actual count) (funcall original manifest id)
                (is (= actual 64)) (values state prefix count)))
            (lambda () (cdr-expect 'corruption-detected :closed-recovery-prefix (lambda () (cdr-call f)))))
          (cdrr-events f nil) (cdr-noeffects f))))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-batch-progress-and-frontiers
  (dolist (variant '(:progress :end :durable))
    (let ((original (fdefinition 'arcdocdb.record:verifica-lotto)))
      (cdr-with-fixture (cdr-log (list (cdr-batch 1 (cdr-record :put 1))))
        (lambda (f)
          (cdrg-with-function 'arcdocdb.record:verifica-lotto
            (lambda (buffer start end id &rest keys)
              (multiple-value-bind (next stamp durable count) (apply original buffer start end id keys)
                (values (case variant (:progress start) (:end (1+ end)) (otherwise next))
                        stamp
                        (if (eq variant :durable) (1+ start) durable) count)))
            (lambda () (cdr-expect 'invariant-violation :closed-recovery-batch (lambda () (cdr-call f)) 64)))
          (cdr-noeffects f)
          (cdr-clear f) (cdrr-success f 2 1 1 1))))))

(deftest test-REQ-AFF-008-CLOSED-GUARDS-batches-and-record-budgets
  (cdr-with-fixture (cdr-log (list (cdr-batch 1 (cdr-record :put 1)) (cdr-batch 2 (cdr-record :put 2))))
    (lambda (f)
      (cdr-expect 'invalid-argument :closed-recovery-batches
        (lambda () (cr::verifica-lotti-closed (cdr-fixture-source f) (cdr-fixture-prefix f) 2 2 0 2 2 4096)))
      (cdr-expect 'resource-exhausted :closed-recovery-record-budget
        (lambda () (cdr-call f :max-records 0)) 64)
      (cdr-clear f)
      (cdr-expect 'resource-exhausted :closed-recovery-batch-budget
        (lambda () (cdr-call f :max-batches 1)))
      (cdr-noeffects f)
      (cdr-clear f) (cdrr-success f 2 1 2 2))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-compaction-each-conjunct
  (dolist (variant '(:end :version :partition :budget))
    (let ((original (fdefinition 'arcdocdb.storage.format:verifica-segmento-compattato)))
      (cdr-with-fixture (cdr-log nil :origin 2 :records (list (cdr-record :put 1)))
        (lambda (f)
          (cdrg-with-function 'arcdocdb.storage.format:verifica-segmento-compattato
            (lambda (&rest args)
              (multiple-value-bind (next version count puts tombstones) (apply original args)
                (values (if (eq variant :end) (1- next) next)
                        (if (eq variant :version) 1 version)
                        (if (member variant '(:partition :budget)) (1+ count) count)
                        (if (eq variant :budget) (1+ puts) puts) tombstones)))
            (lambda ()
              (cdr-expect 'invariant-violation :closed-recovery-compaction (lambda () (cdr-call f :max-records 1)))))
          (cdr-noeffects f)
          (cdr-clear f) (cdrr-success f 2 2 0 1))))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-local-state-and-edit-value
  (cdr-with-fixture (cdr-log nil)
    (lambda (f)
      (let ((manifest (c:manifest-control-recuperato (cdr-fixture-control f))))
        (cdr-expect 'invariant-violation :closed-recovery-resolution-state
          (lambda () (cr::risolvi-prepared-closed (arcdocdb.recovery.active::%make-workspace-active) manifest 9)))
        (cdr-expect 'invariant-violation :closed-recovery-csn-state
          (lambda () (cr::massimo-csn-chiusura manifest 9 nil 0)))
        (let* ((entry (gethash 2 (arcdocdb.recovery.manifest::%manifest-closed manifest)))
               (table (arcdocdb.recovery.manifest::%closed-outcomes entry)))
          (dolist (invalid '(-1 #x10000000000000000))
            (unwind-protect
                 (progn
                   (setf (gethash 0 table) invalid)
                   (cdr-expect 'invariant-violation :closed-recovery-csn-value
                     (lambda () (cr::massimo-csn-chiusura manifest 2 nil 0))))
              (remhash 0 table)))))
      (cdrr-events f nil) (cdr-noeffects f)
      (cdrr-success f 2 1 0 0))))

(deftest test-REQ-AFF-009-CLOSED-GUARDS-compaction-csn-count-kind-consumption
  (cdr-with-fixture (cdr-log nil :origin 2 :records (list (cdr-record :put 1)))
    (lambda (f)
      (let ((buffer (cdr-fixture-source f)) (prefix (cdr-fixture-prefix f))
            (original (fdefinition 'arcdocdb.recovery.active::cornice-active-verificata)))
        (cdr-expect 'invariant-violation :closed-recovery-csn-count
          (lambda () (cr::massimo-csn-compattato buffer prefix 2 2)))
        (dolist (variant '(:kind :prepared :consumption))
          (cdrg-with-function 'arcdocdb.recovery.active::cornice-active-verificata
            (lambda (&rest args)
              (multiple-value-bind (next kind flags value) (apply original args)
                (values (if (eq variant :consumption) (1- next) next)
                        (if (eq variant :kind) arcdocdb.record:+outcome+ kind)
                        (if (eq variant :prepared) arcdocdb.record:+prepared+ flags) value)))
            (lambda ()
              (cdr-expect 'invariant-violation
                (if (eq variant :consumption) :closed-recovery-csn-consumption :closed-recovery-csn-kind)
                (lambda () (cr::massimo-csn-compattato buffer prefix 2 1))
                (if (eq variant :consumption) (1- prefix) 64))))))
      (cdrr-events f nil) (cdr-noeffects f)
      (cdrr-success f 2 2 0 1))))

(defun cdrg-arguments (f)
  (list (cdr-fixture-control f) (cdr-fixture-input f) 2 64 2 1 0 0 0 0 0 0 nil 0))

(deftest test-REQ-AFF-008-CLOSED-GUARDS-private-result-types-and-set-prefix
  (cdr-with-fixture (cdr-log nil)
    (lambda (f)
      (let ((args (cdrg-arguments f)))
        (dolist (bad '((0 nil) (1 nil) (2 -1) (2 #x10000000000000000) (3 -1) (4 3) (5 0)
                       (6 -1) (7 -1) (8 -1) (9 -1) (10 -1) (11 -1) (12 1) (13 -1)))
          (let ((invalid (copy-list args)))
            (setf (nth (first bad) invalid) (second bad))
            (cdr-expect 'type-error nil (lambda () (apply #'cdr-invoke 'cr::%make-closed-recuperato invalid)))))
        (dolist (bad '((2 9) (3 65)))
          (let ((invalid (copy-list args)))
            (setf (nth (first bad) invalid) (second bad))
            (cdr-expect 'invalid-argument :closed-recovery-set-prefix
              (lambda () (cr:verifica-closed-completi (cdr-fixture-control f)
                           (vector (apply #'cdr-invoke 'cr::%make-closed-recuperato invalid))))))))
      (cdrr-events f nil) (cdr-noeffects f)
      (cdrr-success f 2 1 0 0))))
