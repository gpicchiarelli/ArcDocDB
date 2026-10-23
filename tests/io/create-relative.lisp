;;;; C4: preflight, ownership e provenienza degli errori della creazione relativa.
;;; OWNER: un backend privato per caso; nessuna funzione di prodotto sostituita.
(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-owned-append-fd-zero-and-exact-identities
  (dolist (descriptor '(0 73))
    (ctr-run
     (lambda (fixture parent)
       (setf (ctr-fixture-child-fd fixture) descriptor
             (ctr-fixture-metadata fixture) (list (- (ash 1 63)) #xffffffffffffffff 0)
             (ctr-fixture-entry fixture) (list (- (ash 1 63)) #xffffffffffffffff))
       (let ((file (ctr-create fixture :max-transfer 4 :max-file-bytes 4)))
         (is (eq :append (arcdocdb.io:mode-file file)))
         (is (= descriptor (arcdocdb.io::file-fd file)))
         (is (eq (arcdocdb.io::file-backend parent) (arcdocdb.io::file-backend file)))
         (is (equal '(:open 0 0) (rename-native-state file)))
         (is (equal '(:entry :metadata :create) (mapcar #'first (ctr-fixture-events fixture))))
         (signals invalid-argument (leggi-esatto file (zeros 1) 0 1 0) :io-mode)
         (is (= 4 (append-esatto file (bytes 7 0 255 19) 0 4)))
         (is (equal '(:open 4 0) (rename-native-state file)))
         (ctr-check-parent parent))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-positive-budget-bounds-before-callback
  (ctr-run
   (lambda (fixture parent)
     (dolist (spec (list '(:max-transfer 0) '(:max-transfer -1) '(:max-transfer :bad)
                         (list :max-transfer (1+ arcdocdb.io::+max-transfer+))
                         '(:max-file-bytes 0) '(:max-file-bytes -1) '(:max-file-bytes 1/2)
                         '(:max-file-bytes :bad)
                         (list :max-file-bytes (1+ arcdocdb.io::+max-file-offset+))))
       (signals invalid-argument (apply #'ctr-create fixture spec) :io-budget))
     (is (null (ctr-fixture-events fixture)))
     (dolist (bounds (list '(1 1) (list arcdocdb.io::+max-transfer+ most-positive-fixnum)))
       (let ((file (ctr-create fixture :max-transfer (first bounds) :max-file-bytes (second bounds))))
         (is (= (first bounds) (arcdocdb.io::file-max-transfer file)))
         (is (= (second bounds) (arcdocdb.io::file-max-file-bytes file)))
         (chiudi file)))
     (ctr-check-parent parent))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-all-callbacks-required-no-legacy-fallback
  (dolist (missing '(:create :metadata :entry))
    (ctr-run (lambda (fixture parent)
               (signals arcdocdb.conditions:unsupported-format (ctr-create fixture)
                        :io-create-relative-unavailable)
               (is (null (ctr-fixture-events fixture))) (ctr-check-parent parent)) :missing missing)))

;;; REQ: REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-tmp-leaf-bounds-and-private-copy
  (ctr-run
   (lambda (fixture parent)
     (dolist (name (append (rename-native-invalid-names)
                          (list nil 7 "a\\b.tmp" (string #\Newline))))
       (signals invalid-argument (ctr-call parent name) :io-leaf-name))
     (dolist (name '("plain" "x.TMP" "tmp"))
       (signals invalid-argument (ctr-call parent name) :io-temporary-name))
     (is (null (ctr-fixture-events fixture)))
     (dolist (name (list ".tmp" (concatenate 'string (make-string 251 :initial-element #\a) ".tmp")))
       (let ((file (ctr-call parent name)))
         (push file (ctr-fixture-files fixture)) (chiudi file)))
     (let ((name (make-array 20 :element-type 'character :adjustable t :fill-pointer 11
                              :initial-element #\x)))
       (replace name "payload.tmp")
       (setf (ctr-fixture-create-hook fixture)
             (lambda (current fd private mode)
               (declare (ignore current fd mode))
               (is (not (eq private name))) (fill name #\z) (is (string= private "payload.tmp"))))
       (let ((file (ctr-call parent name))) (push file (ctr-fixture-files fixture)))
       (is (string= "payload.tmp" (third (find :entry (ctr-fixture-events fixture) :key #'first)))))
     (ctr-check-parent parent))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-parent-mode-and-lifecycle-preflight
  (dolist (mode '(:input :append))
    (ctr-run (lambda (fixture parent)
               (signals invalid-argument (ctr-create fixture) :io-mode)
               (is (null (ctr-fixture-events fixture))) (ctr-check-parent parent)) :mode mode))
  (dolist (state '(:closed :faulted))
    (ctr-run
     (lambda (fixture parent)
       (if (eq state :closed) (chiudi parent) (setf (arcdocdb.io::file-state parent) :faulted))
       (let ((before (copy-tree (ctr-fixture-events fixture))))
         (signals io-fault (ctr-create fixture) :io-unavailable)
         (is (equal before (ctr-fixture-events fixture))))
       (ctr-check-parent parent state)))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-invalid-child-fd-and-parent-alias-not-closed
  (dolist (descriptor '(nil -1 2147483648 :invalid 41))
    (ctr-run
     (lambda (fixture parent)
       (setf (ctr-fixture-child-fd fixture) descriptor)
       (signals invariant-violation (ctr-create fixture)
                (if (eql descriptor 41) :io-create-relative-parent :io-create-relative-result))
       (is (zerop (ctr-count fixture :close)))
       (is (zerop (ctr-count fixture :metadata))) (ctr-check-parent parent)))))

;;; REQ: REQ-AFF-008 REQ-AFF-001 REQ-FOR-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-metadata-shape-empty-and-size-budget
  (dolist (metadata (list '(nil 9 0) '(5 :bad 0) '(5 9 -1) '(5 9 1/2)
                          (list (ash 1 64) 9 0) (list 5 (- (1+ (ash 1 63))) 0)))
    (ctr-run (lambda (fixture parent)
               (setf (ctr-fixture-metadata fixture) metadata)
               (signals invariant-violation (ctr-create fixture) :io-file-metadata-result)
               (is (= 1 (ctr-closes fixture 73))) (ctr-check-parent parent))))
  (ctr-run (lambda (fixture parent)
             (setf (ctr-fixture-metadata fixture) '(5 9 1))
             (signals invariant-violation (ctr-create fixture :max-file-bytes 1)
                      :io-create-relative-nonempty)
             (is (= 1 (ctr-closes fixture 73))) (is (zerop (ctr-count fixture :entry)))
             (ctr-check-parent parent)))
  (dolist (size (list 5 (ash 1 32) #xffffffffffffffff))
    (ctr-run (lambda (fixture parent)
               (setf (ctr-fixture-metadata fixture) (list 5 9 size))
               (signals resource-exhausted (ctr-create fixture :max-file-bytes 4) :io-file-size)
               (is (= 1 (ctr-closes fixture 73))) (ctr-check-parent parent)))))

;;; REQ: REQ-FOR-001 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-FOR-001-IO-CREATE-RELATIVE-entry-identity-mismatch-and-invalid-result
  (dolist (entry '((6 9) (5 10) (nil 9)))
    (ctr-run
     (lambda (fixture parent)
       (setf (ctr-fixture-entry fixture) entry)
       (if (null (first entry))
           (signals invariant-violation (ctr-create fixture) :io-entry-identity-result)
           (signals invalid-argument (ctr-create fixture) :io-create-relative-identity))
       (is (= 1 (ctr-closes fixture 73))) (ctr-check-parent parent)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-parent-closed-in-each-callback
  (dolist (stage '(:create :metadata :entry))
    (ctr-run
     (lambda (fixture parent)
       (ctr-set-hook fixture stage (lambda (&rest args) (declare (ignore args)) (chiudi parent)))
       (signals io-fault (ctr-create fixture) :io-unavailable)
       (is (= 1 (ctr-closes fixture 73))) (is (= 1 (ctr-closes fixture 41)))
       (when (eq stage :create) (is (zerop (ctr-count fixture :metadata))))
       (when (eq stage :metadata) (is (zerop (ctr-count fixture :entry))))
       (ctr-check-parent parent :closed)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-callback-conditions-preserve-primary
  (dolist (stage '(:create :metadata :entry))
    (dolist (type '(io-fault resource-exhausted))
      (ctr-run
       (lambda (fixture parent)
         (let ((original (if (eq type 'io-fault)
                             (make-condition 'io-fault :reason :injected-create :offset 17
                                             :operation :write :errno sb-posix:eio :transferred 3)
                             (make-condition 'resource-exhausted :reason :injected-create :offset 17))))
           (ctr-set-hook fixture stage (lambda (&rest args) (declare (ignore args)) (error original)))
           (is (eq original (ctr-condition type :injected-create (lambda () (ctr-create fixture)))))
           (is (= (if (eq stage :create) 0 1) (ctr-closes fixture 73)))
           (ctr-check-parent parent)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-syscall-provenance-at-each-stage
  (dolist (stage '(:create :metadata :entry))
    (ctr-run
     (lambda (fixture parent)
       (ctr-set-hook fixture stage (raises-errno sb-posix:eintr))
       (let ((condition (ctr-condition 'io-fault :io-syscall (lambda () (ctr-create fixture)))))
         (is (= sb-posix:eintr (error-errno condition)))
         (is (eq (ecase stage (:create :create-relative) (:metadata :file-metadata)
                                    (:entry :entry-identity)) (error-operation condition))))
       (is (= (if (eq stage :create) 0 1) (ctr-closes fixture 73))) (ctr-check-parent parent)))))

;;; REQ: REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-IO-CREATE-RELATIVE-cleanup-failure-keeps-primary-fields-no-retry
  (dolist (cleanup '(:syscall :io-fault :nonzero))
    (dolist (io-p '(nil t))
      (ctr-run
       (lambda (fixture parent)
         (let ((original (if io-p
                             (make-condition 'io-fault :reason :injected-primary :offset 29
                                             :operation :write :errno sb-posix:enospc :transferred 7)
                             (make-condition 'resource-exhausted :reason :injected-primary :offset 29))))
           (ctr-set-hook fixture :metadata (lambda (&rest args) (declare (ignore args)) (error original)))
           (setf (ctr-fixture-close-hook fixture)
                 (lambda (current fd) (declare (ignore current))
                   (if (= fd 73)
                       (ecase cleanup
                         (:syscall (error 'sb-posix:syscall-error :errno sb-posix:eintr :name 'close))
                         (:io-fault (error 'io-fault :reason :injected-close :operation :close
                                                    :errno sb-posix:eio))
                         (:nonzero -1)) 0)))
           (let ((condition (ctr-condition 'io-fault :injected-primary (lambda () (ctr-create fixture)))))
             (is (= 29 (arcdocdb.conditions:error-offset condition)))
             (is (eql (ecase cleanup (:syscall sb-posix:eintr) (:io-fault sb-posix:eio) (:nonzero nil))
                      (arcdocdb.conditions:error-cleanup-errno condition)))
             (is (eq (if io-p :write :create-relative) (error-operation condition)))
             (is (eql (when io-p sb-posix:enospc) (error-errno condition)))
             (is (= (if io-p 7 0) (error-transferred condition))))
           (is (= 1 (ctr-closes fixture 73))) (ctr-check-parent parent)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-IO-CREATE-RELATIVE-nonlocal-exit-cleans-child-before-caller
  (dolist (cleanup-fails '(nil t))
    (ctr-run
     (lambda (fixture parent)
       (let ((marker (list :create-relative-escape)) (closed-before-caller nil))
         (ctr-set-hook fixture :metadata
           (lambda (&rest args) (declare (ignore args)) (throw 'ctr-escape marker)))
         (when cleanup-fails
           (setf (ctr-fixture-close-hook fixture)
                 (lambda (current fd) (declare (ignore current))
                   (if (= fd 73) (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'close) 0))))
         (is (eq marker
                 (catch 'ctr-escape
                   (unwind-protect (ctr-create fixture)
                     (setf closed-before-caller (= 1 (ctr-closes fixture 73)))))))
         (is closed-before-caller) (is (= 1 (ctr-closes fixture 73))) (ctr-check-parent parent))))))
