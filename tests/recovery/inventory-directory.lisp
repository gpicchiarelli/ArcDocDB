;;;; Prove C4 dell'enumerazione attestata e dell'adattatore verso il planner ADR0040.
;;; OWNER: backend e nomi privati; nessun effetto durevole o override globale.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-adr-table-v1-v2
  (let ((specs '((7 :final) (0 :final) (2 :temporary) (3 :final) (4 :temporary)
                 (9 :temporary) (10 :final))))
    (dolist (version '(1 2))
      (let ((manifest (inventory-manifest 7 '(0 2) '(3 4) :version version)))
        (idr-run (idr-names specs "control.log" "multiserie.log" ".hidden")
          (lambda (state directory)
            (idr-check state directory manifest 7 '(0 2) '(3 4) specs)
            (is (= 1 (idr-enumerations state)))
            (is (= (length specs) (count :identity (idr-state-events state) :key #'first)))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-full-u64-and-more-than-eight-files
  (let* ((maximum #xffffffffffffffff)
         (closed (list 0 1 2 3 4 5 6 8 9 #x100000000 #x8000000000000000 maximum))
         (edits (list (manifest-spec :completo t :next-id maximum :open 7
                                     :chiusi (mapcar (lambda (id) (list id 64 nil)) (butlast closed)))
                      (manifest-spec :chiusi (list (list maximum 64 nil)))))
         (specs (cons '(7 :temporary) (mapcar (lambda (id) (list id :final)) (reverse closed)))))
    (dolist (version '(1 2))
      (let ((manifest (inventory-fixture-manifest edits :version version)))
        (idr-run (idr-names specs)
          (lambda (state directory)
            (let ((plan (idr-check state directory manifest 7 closed nil specs)))
              (is (= 13 (length (inventory-plan-rows plan))))
              (is (= maximum (first (car (last (inventory-plan-rows plan)))))))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-018
(deftest test-REQ-REC-002-inventory-directory-absent-and-conflicting-live-names
  (dolist (version '(1 2))
    (let ((manifest (inventory-manifest 7 '(1) '(3) :version version)))
      (dolist (specs '(() ((7 :final)) ((1 :final)) ((7 :final) (7 :temporary) (1 :final))
                       ((7 :final) (1 :final) (1 :temporary))
                       ((7 :final) (1 :final) (3 :final) (3 :temporary))))
        (idr-run (idr-names specs)
          (lambda (state directory) (idr-check state directory manifest 7 '(1) '(3) specs)))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-inventory-directory-three-io-budgets-exact-one-under
  (idr-run (vector (copy-seq "ab") (copy-seq "cde"))
    (lambda (state directory)
      (is (equalp '(#("ab" "cde") t)
                  (multiple-value-list (arcdocdb.io:elenca-directory directory
                                        :max-names 2 :max-total-name-bytes 5 :max-name-bytes 3))))
      (dolist (spec '((:max-names 1 :io-directory-names)
                      (:max-total-name-bytes 4 :io-directory-total-name-bytes)
                      (:max-name-bytes 2 :io-directory-name-bytes)))
        (signals resource-exhausted
          (apply #'arcdocdb.io:elenca-directory directory (list (first spec) (second spec)))
          (third spec)))
      (is (= 4 (idr-enumerations state)))
      (is (equal '(:open 0 0) (idr-observation directory))))))

;;; REQ: REQ-AFF-008 REQ-REC-001 REQ-AFF-018
(deftest test-REQ-AFF-008-inventory-directory-ignored-names-count-before-filtering
  (let ((manifest (inventory-manifest 7 nil nil)))
    (idr-run (idr-names '((7 :final)) "abc")
      (lambda (state directory)
        (idr-check state directory manifest 7 nil nil '((7 :final))
                   :max-files 1 :max-segmenti 1 :max-names 2 :max-total-name-bytes 23 :max-name-bytes 20)
        (signals resource-exhausted (idr-plan manifest directory :max-names 1) :io-directory-names)
        (signals resource-exhausted (idr-plan manifest directory :max-total-name-bytes 22)
                 :io-directory-total-name-bytes)
        (signals resource-exhausted (idr-plan manifest directory :max-name-bytes 19)
                 :io-directory-name-bytes)
        (signals resource-exhausted (idr-plan manifest directory :max-files 0) :inventory-file-budget)
        (signals resource-exhausted (idr-plan manifest directory :max-segmenti 0) :inventory-segment-budget)))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-inventory-directory-invalid-budgets-before-enumeration
  (idr-run #()
    (lambda (state directory)
      (dolist (spec '((:max-names -1) (:max-total-name-bytes -1) (:max-name-bytes 0)
                      (:max-name-bytes 256) (:max-names :invalid) (:max-name-bytes 3/2)))
        (signals invalid-argument (apply #'arcdocdb.io:elenca-directory directory spec)
                 :io-directory-budget))
      (let ((manifest (inventory-manifest 7 nil nil)))
        (dolist (key '(:max-files :max-segmenti))
          (signals invalid-argument (idr-plan manifest directory key -1) :inventory-budget)))
      (is (zerop (idr-enumerations state))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-inventory-directory-rejects-incomplete-and-invalid-backend-names
  (dolist (complete '(nil :eof))
    (idr-run #() (lambda (state directory)
                   (setf (idr-state-complete state) complete)
                   (signals arcdocdb.conditions:invariant-violation
                     (arcdocdb.io:elenca-directory directory) :io-directory-result))))
  (idr-run '("valid") (lambda (state directory)
                        (declare (ignore state))
                        (signals arcdocdb.conditions:invariant-violation
                          (arcdocdb.io:elenca-directory directory) :io-directory-result)))
  (dolist (name (list nil 7 "" "." ".." "a/b" (string #\Null) (string (code-char 256))))
    (idr-run (vector name)
      (lambda (state directory)
        (declare (ignore state))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.io:elenca-directory directory) :io-directory-name)))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-inventory-directory-capability-and-callback-preflight
  (idr-run #() (lambda (state directory)
                 (signals unsupported-format (arcdocdb.io:elenca-directory directory)
                          :io-directory-unavailable)
                 (is (zerop (idr-enumerations state)))) :enumeration-p nil)
  (idr-run #() (lambda (state directory)
                 (signals unsupported-format (idr-plan (inventory-manifest 7 nil nil) directory)
                          :io-entry-identity-unavailable)
                 (is (zerop (idr-enumerations state)))) :identity-p nil)
  (idr-run #() (lambda (state directory)
                 (signals invalid-argument (arcdocdb.io:elenca-directory directory) :io-mode)
                 (is (zerop (idr-enumerations state)))) :mode :input)
  (idr-run #() (lambda (state directory)
                 (arcdocdb.io:chiudi directory)
                 (signals arcdocdb.conditions:io-fault (arcdocdb.io:elenca-directory directory)
                          :io-unavailable)
                 (is (zerop (idr-enumerations state))))))

;;; REQ: REQ-AFF-017 REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-017-inventory-directory-owned-latin1-names-and-plan-survive-reuse
  (let* ((name (concatenate 'string "note-" (string (code-char 255))))
         (specs '((7 :temporary) (0 :final)))
         (names (idr-names specs name)))
    (multiple-value-bind (manifest buffer) (inventory-manifest 7 '(0) nil)
      (idr-run names
        (lambda (state directory)
          (multiple-value-bind (first complete) (arcdocdb.io:elenca-directory directory)
            (is (eq complete t)) (is (not (eq names first)))
            (is (equalp names first))
            (is (= 255 (char-code (char (aref first 2) 5))))
            (dotimes (i (length names)) (is (not (eq (aref names i) (aref first i)))))
            (let* ((copied (map 'simple-vector #'copy-seq first))
                   (plan (idr-check state directory manifest 7 '(0) nil specs))
                   (expected (inventory-oracle 7 '(0) nil specs)))
              (fill buffer 255)
              (dotimes (i (length names)) (fill (aref names i) #\x))
              (fill names nil)
              (inventory-assert-plan plan expected)
              (is (equalp copied first)))))))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-malformed-segmentlike-names-rejected
  (let ((manifest (inventory-manifest 7 nil nil)))
    (dolist (name '("7.seg" "00000000000000007.seg" "000000000000000G.seg"
                    "000000000000000A.seg" "0000000000000007.SEG"
                    "0000000000000007.seg.TMP" ".seg" "-000000000000007.seg.tmp"))
      (idr-run (vector (copy-seq name))
        (lambda (state directory)
          (signals corruption-detected (idr-plan manifest directory) :inventory-segment-name)
          (is (not (find :identity (idr-state-events state) :key #'first))))))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-inventory-directory-physical-alias-and-duplicate-name
  (let ((manifest (inventory-manifest 7 '(1) nil)))
    (idr-run (idr-names '((7 :final) (1 :final)))
      (lambda (state directory)
        (setf (idr-state-identity-hook state)
              (lambda (current name) (declare (ignore current name)) (values 8 13)))
        (signals corruption-detected (idr-plan manifest directory) :inventory-physical-alias)
        (is (equal '(:open 0 0) (idr-observation directory)))))
    (idr-run (idr-names '((7 :final) (7 :final)))
      (lambda (state directory)
        (declare (ignore state))
        (signals invalid-argument (idr-plan manifest directory) :inventory-duplicate)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-001-inventory-directory-original-fault-and-callback-close
  (idr-run #()
    (lambda (state directory)
      (let ((original (make-condition 'arcdocdb.conditions:io-fault
                                     :reason :injected-directory-failure :operation :directory-entries)))
        (setf (idr-state-enum-hook state) (lambda (current) (declare (ignore current)) (error original)))
        (is (eq original (signals arcdocdb.conditions:io-fault
                           (arcdocdb.io:elenca-directory directory) :injected-directory-failure)))
        (is (eq original (signals arcdocdb.conditions:io-fault
                           (idr-plan (inventory-manifest 7 nil nil) directory)
                           :injected-directory-failure)))
        (is (equal '(:open 0 0) (idr-observation directory))))))
  (idr-run #()
    (lambda (state directory)
      (setf (idr-state-enum-hook state)
            (lambda (current) (arcdocdb.io:chiudi (idr-state-directory current))))
      (signals arcdocdb.conditions:io-fault
        (idr-plan (inventory-manifest 7 nil nil) directory) :io-unavailable)
      (is (eq :closed (arcdocdb.io:stato-file directory)))))
  (idr-run (idr-names '((7 :final)))
    (lambda (state directory)
      (setf (idr-state-identity-hook state)
            (lambda (current name)
              (declare (ignore name))
              (arcdocdb.io:chiudi (idr-state-directory current))
              (values 5 1)))
      (signals arcdocdb.conditions:io-fault
        (idr-plan (inventory-manifest 7 nil nil) directory) :io-unavailable)
      (is (eq :closed (arcdocdb.io:stato-file directory))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-inventory-directory-native-outcome-data-policy-only
  ;; Unità pura su esiti scalari: non inietta né attesta guasti di syscall native.
  (is (null (arcdocdb.io::native-directory-outcome nil nil nil nil)))
  (dolist (reason '(:io-directory-names :io-directory-total-name-bytes :io-directory-name-bytes))
    (signals resource-exhausted (arcdocdb.io::native-directory-outcome reason nil nil nil) reason)
    (let ((condition (signals arcdocdb.conditions:io-fault
                       (arcdocdb.io::native-directory-outcome reason nil sb-posix:eintr t) reason)))
      (is (eq :directory-entries (arcdocdb.conditions:error-operation condition)))
      (is (null (arcdocdb.conditions:error-errno condition)))
      (is (= sb-posix:eintr (arcdocdb.conditions:error-cleanup-errno condition)))))
  (dolist (cleanup '(nil t))
    (let* ((secondary (when cleanup sb-posix:eintr))
           (condition (signals arcdocdb.conditions:io-fault
                        (arcdocdb.io::native-directory-outcome :io-syscall sb-posix:eio secondary cleanup)
                        :io-syscall)))
      (is (= sb-posix:eio (arcdocdb.conditions:error-errno condition)))
      (is (eql secondary (arcdocdb.conditions:error-cleanup-errno condition)))))
  (dolist (errno (list nil sb-posix:eio))
    (let ((condition (signals arcdocdb.conditions:io-fault
                       (arcdocdb.io::native-directory-outcome nil nil errno t) :io-directory-close)))
      (is (eql errno (arcdocdb.conditions:error-errno condition)))
      (is (null (arcdocdb.conditions:error-cleanup-errno condition))))))
