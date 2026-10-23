;;;; Proposte ID: oracolo a ricerca finita, frontiere u64 e decisioni RID-D/G.
;;; OWNER: fixture e piani appartengono alla prova; worker con manifest privati.
(in-package #:arcdocdb.recovery.tests)

(defun recovery-id-check (manifest specs expected &rest options)
  "Interroga solo l'API pubblica; conserva identità degli input e numero dei valori."
  (let* ((files (inventory-files specs)) (before (copy-seq files))
         (result (multiple-value-list
                   (apply #'arcdocdb.recovery.manifest:scegli-id-segmento-recovery
                          manifest files options))))
    (is (= 3 (length result))) (is (= expected (first result)))
    (is (= (1+ expected) (second result))) (is (every #'eq before files))
    (third result)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-recovery-id-finite-model
  ;; 1.024 inventari × tre ordini × v1/v2: ricerca del primo candidato ammissibile.
  (dolist (version '(1 2))
    (multiple-value-bind (manifest buffer) (inventory-manifest 3 '(0) '(1) :version version)
      (let ((before (copy-seq buffer)))
        (dotimes (number 1024)
          (let* ((specs (inventory-small-files number))
                 (expected (loop for candidate from 4 to 8
                                 when (every (lambda (file) (< (first file) candidate)) specs)
                                   return candidate))
                 (oracle (inventory-oracle 3 '(0) '(1) specs)))
            (dolist (ordered (inventory-input-orders specs))
              (inventory-assert-plan (recovery-id-check manifest ordered expected) oracle))))
        (is (equalp before buffer))
        (is (equal '(t 4) (multiple-value-list
                           (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-recovery-id-high-water-and-orphans
  (dolist (version '(1 2))
    (let ((manifest (inventory-fixture-manifest
                     (list (manifest-spec :completo t :next-id 100 :open 7
                                          :chiusi '((1 64 nil)) :rimossi '(2 99)))
                     :version version)))
      (dolist (case '((((7 :final) (1 :final)) 100 :ready)
                      (((7 :final)) 100 :degraded)
                      (() 100 :faulted)
                      (((7 :final) (1 :final) (120 :temporary) (119 :final)) 121 :ready)
                      (((7 :final) (1 :final) (120 :temporary) (120 :final)) 121 :ready)
                      (((7 :final) (1 :final) (99 :temporary)) 100 :ready)))
        (destructuring-bind (specs expected health) case
          (let ((plan (recovery-id-check manifest specs expected)))
            (inventory-assert-plan plan (inventory-oracle 7 '(1) '(2 99) specs))
            (is (eq health (arcdocdb.recovery.manifest:stato-riconciliazione plan)))))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-REC-001-recovery-id-u64-frontiers
  (let ((maximum #xffffffffffffffff))
    (dolist (version '(1 2))
      (let ((manifest (inventory-manifest 7 nil nil :version version)))
        (dolist (id (list (ash 1 63) (- maximum 2)))
          (recovery-id-check manifest (list '(7 :final) (list id :temporary)) (1+ id)))
        (dolist (id (list (1- maximum) maximum))
          (signals resource-exhausted
                   (arcdocdb.recovery.manifest:scegli-id-segmento-recovery
                     manifest (inventory-files (list '(7 :final) (list id :final))))
                   :recovery-segment-id-exhausted))
        (recovery-id-check manifest '((0 :temporary) (7 :final)) 8))
      (let ((manifest (inventory-fixture-manifest
                       (list (manifest-spec :completo t :next-id (1- maximum) :open 7))
                       :version version)))
        (recovery-id-check manifest '((7 :final)) (1- maximum)))
      (dolist (specs (list (list (manifest-spec :completo t :next-id maximum :open 7))
                          (list (inventory-snapshot 7 nil nil)
                                (manifest-spec :open maximum :chiusi '((7 64 nil))))))
        (multiple-value-bind (manifest buffer) (inventory-fixture-manifest specs :version version)
          (let ((before (copy-seq buffer))
                (minimum (multiple-value-list
                           (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
            (signals resource-exhausted
                     (arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest #())
                     :recovery-segment-id-exhausted)
            (is (equalp before buffer))
            (is (equal minimum (multiple-value-list
                                (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-008-recovery-id-original-errors-and-budgets
  (let* ((manifest (inventory-manifest 7 '(1 2) '(3)))
         (specs '((7 :final) (1 :temporary) (2 :final) (3 :final) (9 :temporary)))
         (files (inventory-files specs)) (before (copy-seq files)))
    (recovery-id-check manifest specs 10 :max-files 5 :max-segmenti 3)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:scegli-id-segmento-recovery
               manifest files :max-files 4 :max-segmenti 3) :inventory-file-budget)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:scegli-id-segmento-recovery
               manifest files :max-files 5 :max-segmenti 2) :inventory-segment-budget)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:scegli-id-segmento-recovery
               manifest (vector nil) :max-files 0) :inventory-file-budget)
    (signals resource-exhausted
             (arcdocdb.recovery.manifest:scegli-id-segmento-recovery
               manifest #() :max-files 0 :max-segmenti 0) :inventory-segment-budget)
    (let* ((duplicate (inventory-files '((7 :final) (7 :final))))
           (condition (signals invalid-argument
                        (arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest duplicate)
                        :inventory-duplicate)))
      (is (= 1 (error-offset condition))))
    (let ((condition (signals invalid-argument
                       (arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest (vector nil))
                       :inventory-entry)))
      (is (= 0 (error-offset condition))))
    (dolist (key '(:max-files :max-segmenti))
      (dolist (value (list -1 (1+ most-positive-fixnum)))
        (signals invalid-argument
                 (apply #'arcdocdb.recovery.manifest:scegli-id-segmento-recovery
                        manifest #() (list key value)) :inventory-budget))
      (signals type-error (inventory-indirect-call
                           'arcdocdb.recovery.manifest:scegli-id-segmento-recovery
                           manifest #() key :invalid)))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest nil))
    (signals type-error (inventory-indirect-call
                         'arcdocdb.recovery.manifest:scegli-id-segmento-recovery nil #()))
    (is (every #'eq before files))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-018-recovery-id-independent-decisions
  ;; RID-D01: TTT, FTT, TFT, TTF; RID-D02: uguale/discordante.
  (is (null (arcdocdb.recovery.manifest::verifica-id-segmento-recovery 10 9 10 11)))
  (dolist (arguments '((0 9 10 11) (10 8 9 10) (10 10 10 11)))
    (signals arcdocdb.conditions:invariant-violation
             (apply #'arcdocdb.recovery.manifest::verifica-id-segmento-recovery arguments)
             :recovery-segment-id-frontier))
  (signals arcdocdb.conditions:invariant-violation
           (arcdocdb.recovery.manifest::verifica-id-segmento-recovery 10 9 10 12)
           :recovery-segment-id-successor))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-AFF-018-recovery-id-empty-plan-injection
  ;; Serializzata dal runner: nessun worker è attivo durante la sostituzione privata.
  (let* ((manifest (inventory-manifest 7 nil nil))
         (symbol 'arcdocdb.recovery.manifest:pianifica-riconciliazione)
         (original (symbol-function symbol)))
    (unwind-protect
         (progn
           (setf (symbol-function symbol)
                 (lambda (manifest files &key max-files max-segmenti)
                   (declare (ignore manifest files max-files max-segmenti))
                   (arcdocdb.recovery.manifest::%make-reconciliation-plan #() :ready)))
           (signals arcdocdb.conditions:invariant-violation
                    (arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest #())
                    :recovery-segment-id-empty-plan))
      (setf (symbol-function symbol) original))
    (recovery-id-check manifest '((7 :final)) 8)))

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-recovery-id-owned-plan-no-reservation
  (multiple-value-bind (manifest buffer) (inventory-manifest 7 '(0) '(2))
    (let* ((specs '((7 :final) (0 :temporary) (2 :final) (9 :temporary)))
           (files (inventory-files specs)) (oracle (inventory-oracle 7 '(0) '(2) specs)))
      (multiple-value-bind (id next plan)
          (arcdocdb.recovery.manifest:scegli-id-segmento-recovery manifest files)
        (is (= id 10)) (is (= next 11))
        (let ((repeat (recovery-id-check manifest specs 10)))
          (is (not (eq plan repeat))))
        (fill files nil) (fill buffer #xaa)
        (inventory-assert-plan plan oracle)
        (inventory-assert-plan (recovery-id-check manifest specs 10) oracle)))))

(defun recovery-id-private-worker (number gate)
  "Quattro Serie senza scritture condivise: attesa e ripetizioni limitate."
  (is (sb-thread:wait-on-semaphore gate :timeout 10))
  (let* ((active (+ 7 (* number 10))) (orphan (+ active 8))
         (manifest (inventory-manifest active nil nil))
         (specs (list (list active :final) (list orphan :temporary)))
         (oracle (inventory-oracle active nil nil specs)))
    (dotimes (iteration 16)
      (inventory-assert-plan (recovery-id-check manifest specs (1+ orphan)) oracle)))
  t)

;;; REQ: REQ-REC-001 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-recovery-id-four-private-series
  (let ((gate (sb-thread:make-semaphore :count 0)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (number 4)
             (let ((serie number))
               (push (sb-thread:make-thread
                      (lambda ()
                        (handler-case (recovery-id-private-worker serie gate)
                          (error (condition) condition)))
                      :name (format nil "recovery-id-serie-~D" serie)) threads)))
           (sb-thread:signal-semaphore gate 4)
           (dolist (thread threads)
             (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
               (when (typep result 'error) (error result))
               (is (eq t result)))))
      (inventory-stop-workers threads))))
