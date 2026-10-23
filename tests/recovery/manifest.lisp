;;;; Ricostruzione del manifest: storie logiche, oracolo indipendente e sole API pubbliche.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-AFF-017 REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-AFF-017-manifest-histories-v1-v2-and-batch-layouts
  (let* ((specs (manifest-basic-history)) (expected (manifest-oracle specs)))
    (dolist (version '(1 2))
      (dolist (batches (list (list specs) (mapcar #'list specs)
                            (list nil (subseq specs 0 2) nil (subseq specs 2 5)
                                  (subseq specs 5) nil)))
        (multiple-value-bind (buffer start end) (manifest-log-fixture batches :version version)
          (let ((before (copy-seq buffer)))
            (loop repeat 2 do
              (multiple-value-bind (manifest prefix status)
                  (manifest-fixture-read buffer start end :version version)
                (is (= end prefix)) (is (eq :complete status))
                (assert-manifest-model manifest expected)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-FOR-003 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-FOR-003-manifest-snapshot-sizes-and-permuted-sections
  (dolist (count '(0 1 2 3 4 5 7 8 9 15 16 17))
    (let* ((closed (loop for i below count collect
                    (list (1+ (* i 2)) (if (evenp i) 64 #xffffffff)
                          (loop for j below (mod i 5) collect
                            (list (+ (* i 32) j) (if (evenp j) 0 #xffffffffffffffff))))))
           (spec (manifest-spec :completo t :next-id 100 :open 50
                                 :chiusi closed :rimossi '(51 52 53)))
           (expected (manifest-oracle (list spec))))
      (dolist (version '(1 2))
        (dolist (seed '(1 42 193))
          (let ((permuted (copy-tree spec)))
            (setf (getf permuted :chiusi)
                  (loop for entry in (permute-decisions closed seed) collect
                    (list (first entry) (second entry) (permute-decisions (third entry) seed)))
                  (getf permuted :rimossi) (permute-decisions (getf spec :rimossi) seed))
            (multiple-value-bind (buffer start end)
                (manifest-log-fixture (list (list permuted)) :version version)
              (multiple-value-bind (manifest prefix status)
                  (manifest-fixture-read buffer start end :version version)
                (is (= end prefix)) (is (eq :complete status))
                (assert-manifest-model manifest expected '(0 2 49 54 1024))))))))))

;;; REQ: REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-AFF-018-manifest-idempotent-closures-removals-and-outcomes
  (let* ((a '(1 64 ((0 0) (7 17) (0 0))))
         (permuted '(1 64 ((7 17) (0 0) (7 17))))
         (specs (list (manifest-spec :completo t :next-id 100 :open 10
                                    :chiusi (list a permuted '(2 512 nil)) :rimossi '(3 3))
                      (manifest-spec :chiusi (list permuted a) :rimossi '(2 3 2 3)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (mapcar #'list specs)
                                                                  :version version)
        (multiple-value-bind (manifest prefix status)
            (manifest-fixture-read buffer start end :version version)
          (is (= end prefix)) (is (eq :complete status))
          (assert-manifest-model manifest (manifest-oracle specs))
          (is (equal '(t 0) (multiple-value-list
                             (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 1 0))))
          (is (equal '(nil 0) (multiple-value-list
                               (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 0)))))))))

;;; REQ: REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-FOR-003-manifest-conflicting-outcome-and-closed-proof
  (let ((initial (manifest-spec :completo t :next-id 100 :open 10
                                :chiusi '((1 64 ((0 0) (7 17)))))))
    (dolist (version '(1 2))
      (dolist (case (list (list (manifest-spec :chiusi '((2 64 ((0 0) (0 1)))))
                                :manifest-outcome-conflict)
                         (list (manifest-spec :chiusi '((1 65 ((0 0) (7 17)))))
                               :manifest-closed-conflict)
                         (list (manifest-spec :chiusi '((1 64 ((0 1) (7 17)))))
                               :manifest-closed-conflict)
                         (list (manifest-spec :chiusi '((1 64 ((0 0)))))
                               :manifest-closed-conflict)
                         (list (manifest-spec :chiusi '((1 64 ((0 0) (8 17)))))
                               :manifest-closed-conflict)
                         (list (manifest-spec :chiusi '((2 64 nil) (2 65 nil)))
                               :manifest-closed-conflict)))
        (multiple-value-bind (buffer start end layouts)
            (manifest-log-fixture (list (list initial) (list (first case))) :version version)
          (let* ((before (copy-seq buffer))
                 (condition (signals corruption-detected
                              (manifest-fixture-read buffer start end :version version)
                              (second case))))
            (is (= (+ 64 (getf (second layouts) :start)) (error-offset condition)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-AFF-018 REQ-FOR-003
(deftest test-REQ-AFF-018-manifest-section-overlap-is-invalid
  (let ((initial (manifest-spec :completo t :next-id 100 :open 10
                                :chiusi '((1 64 nil)) :rimossi '(3))))
    (dolist (version '(1 2))
      (dolist (bad (list (manifest-spec :open 11 :chiusi '((10 64 nil) (11 64 nil)))
                        (manifest-spec :chiusi '((1 64 nil)) :rimossi '(1))
                        (manifest-spec :open 11 :chiusi '((10 64 nil)) :rimossi '(11))
                        (manifest-spec :completo t :next-id 100 :open 10
                                       :chiusi '((10 64 nil)))
                        (manifest-spec :completo t :next-id 100 :open 10 :rimossi '(10))
                        (manifest-spec :completo t :next-id 100 :open 10
                                       :chiusi '((1 64 nil)) :rimossi '(1))))
        (let ((batches (if (getf bad :completo) (list (list bad))
                          (list (list initial bad)))))
          (multiple-value-bind (buffer start end layouts)
              (manifest-log-fixture batches :version version)
            (let ((condition (signals corruption-detected
                               (manifest-fixture-read buffer start end :version version)
                               :manifest-section-conflict)))
              (is (= (+ 64 (if (getf bad :completo) start
                              (second (getf (first layouts) :records))))
                     (error-offset condition))))))))))

;;; REQ: REQ-AFF-018 REQ-AFF-017
(deftest test-REQ-AFF-018-manifest-invalid-transitions-never-reactivate
  (let ((initial (manifest-spec :completo t :next-id 100 :open 10
                                :chiusi '((1 64 nil)) :rimossi '(3))))
    (dolist (version '(1 2))
      (dolist (case (list (list (manifest-spec :open 11) :manifest-active-rotation)
                         (list (manifest-spec :chiusi '((10 64 nil))) :manifest-active-rotation)
                         (list (manifest-spec :open 1 :chiusi '((10 64 nil))) :manifest-reopen)
                         (list (manifest-spec :open 3 :chiusi '((10 64 nil))) :manifest-reopen)
                         (list (manifest-spec :chiusi '((3 64 nil))) :manifest-reopen)
                         (list (manifest-spec :rimossi '(10)) :manifest-remove-active)
                         (list (manifest-spec :rimossi '(2)) :manifest-remove-unknown)))
        (multiple-value-bind (buffer start end layouts)
            (manifest-log-fixture (list (list initial (first case))) :version version)
          (let* ((before (copy-seq buffer))
                 (condition (signals corruption-detected
                              (manifest-fixture-read buffer start end :version version)
                              (second case))))
            (is (= (+ 64 (second (getf (first layouts) :records))) (error-offset condition)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-AFF-017 REQ-FOR-003
(deftest test-REQ-FOR-003-manifest-snapshot-required-and-valid
  (dolist (version '(1 2))
    (dolist (batches (list nil '(nil nil) (list (list (manifest-spec :open 1)))))
      (multiple-value-bind (buffer start end) (manifest-log-fixture batches :version version)
        (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                 :manifest-missing-snapshot)))
    (dolist (case (list (list (manifest-spec :completo t :next-id 1) :manifest-active-id)
                       (list (manifest-spec :completo t :next-id 0 :open 1) :manifest-next-id)
                       (list (manifest-spec :completo t :next-id 1 :open 1) :manifest-next-id)
                       (list (manifest-spec :completo t :next-id 10 :open 1
                                           :chiusi '((10 64 nil))) :manifest-next-id)
                       (list (manifest-spec :completo t :next-id 10 :open 1 :rimossi '(10))
                             :manifest-next-id)))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (list (list (first case)))
                                                                  :version version)
        (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                 (second case))))
    (let ((initial (manifest-spec :completo t :next-id 2 :open 1)))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (list (list initial initial))
                                                                  :version version)
        (signals corruption-detected (manifest-fixture-read buffer start end :version version)
                 :manifest-repeated-snapshot)))))

;;; REQ: REQ-AFF-017 REQ-AFF-009 REQ-FOR-003
(deftest test-REQ-AFF-017-manifest-every-cut-keeps-whole-sealed-prefix
  (dolist (version '(1 2))
    (let* ((specs (manifest-basic-history)) (batches (mapcar #'list specs)))
      (multiple-value-bind (buffer start end layouts) (manifest-log-fixture batches :version version)
        (let ((before (copy-seq buffer)))
          (loop for cut from start to end do
            (let ((complete (count-if (lambda (layout) (<= (getf layout :end) cut)) layouts)))
              (if (zerop complete)
                  (signals corruption-detected
                           (manifest-fixture-read buffer start cut :version version)
                           :manifest-missing-snapshot)
                  (let ((expected-prefix (getf (nth (1- complete) layouts) :end)))
                    (multiple-value-bind (manifest prefix status)
                        (manifest-fixture-read buffer start cut :version version)
                      (is (= expected-prefix prefix))
                      (is (eq (if (= prefix cut) :complete :tail) status))
                      (assert-manifest-model manifest
                        (manifest-oracle (subseq specs 0 complete))))))))
          (is (equalp before buffer)))))))

;;; REQ: REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-manifest-owns-closure-and-outcome-copies
  (let* ((specs (manifest-basic-history)) (expected (manifest-oracle specs)))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end) (manifest-log-fixture (list specs) :version version)
        (let ((before (copy-seq buffer)))
          (multiple-value-bind (manifest prefix status)
              (manifest-fixture-read buffer start end :version version)
            (is (= end prefix)) (is (eq :complete status))
            (is (equalp before buffer))
            (fill buffer #xff)
            (loop repeat 3 do (assert-manifest-model manifest expected))))))))

;;; REQ: REQ-AFF-018 REQ-FOR-003 REQ-LIM-001
(deftest test-REQ-FOR-003-manifest-u64-boundaries-and-id-exhaustion
  (let* ((maximum #xffffffffffffffff)
         (initial (manifest-spec :completo t :next-id maximum :open 1
                                 :chiusi (list (list 2 #xffffffff
                                                   (list (list 0 0) (list maximum maximum))))))
         (next (manifest-spec :chiusi (list (list maximum 64 nil))))
         (later (manifest-spec :open 3 :chiusi '((1 64 nil))))
         (open-maximum (manifest-spec :open maximum :chiusi '((1 64 nil))))
         (close-maximum (manifest-spec :open 3 :chiusi (list (list maximum 64 nil)))))
    (dolist (version '(1 2))
      (dolist (specs (list (list initial) (list initial next) (list initial next later)
                          (list initial open-maximum)
                          (list initial open-maximum close-maximum)
                          (list initial open-maximum close-maximum
                                (manifest-spec :rimossi (list maximum)))))
        (multiple-value-bind (buffer start end) (manifest-log-fixture (mapcar #'list specs)
                                                                    :version version)
          (multiple-value-bind (manifest prefix status)
              (manifest-fixture-read buffer start end :version version)
            (is (= end prefix)) (is (eq :complete status))
            (assert-manifest-model manifest (manifest-oracle specs) '(0 1024 1025))
            (is (equal '(t 0) (multiple-value-list
                               (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 0))))
            (is (equal (list t maximum) (multiple-value-list
                                         (arcdocdb.recovery.manifest:trova-esito-chiusura
                                           manifest 2 maximum))))))))))
