;;;; C4: preflight, FD validi conosciuti e provenienza del cleanup readonly.
;;; OWNER: un backend privato per caso, nessuna sostituzione di funzioni di prodotto.
(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-owned-input-eof-and-exact-identities
  (dolist (descriptor '(0 73))
    (orl-run
     (lambda (fixture parent)
       (setf (orl-fixture-child-fd fixture) descriptor
             (orl-fixture-metadata fixture) (list (- (ash 1 63)) #xffffffffffffffff 4)
             (orl-fixture-entry fixture) (list (- (ash 1 63)) #xffffffffffffffff))
       (multiple-value-bind (file eof) (orl-open fixture :max-transfer 4 :max-file-bytes 4)
         (is (= eof 4)) (is (eq :input (arcdocdb.io:mode-file file)))
         (is (= descriptor (arcdocdb.io::file-fd file)))
         (is (eq (arcdocdb.io::file-backend parent) (arcdocdb.io::file-backend file)))
         (let ((buffer (make-array 8 :element-type '(unsigned-byte 8) :initial-element 204)))
           (is (= 6 (leggi-esatto file buffer 2 6 0)))
           (is (equalp (bytes 204 204 7 0 255 19 204 204) buffer)))
         (is (equal '(:open 0 0) (rename-native-state file)))
         (orl-check-parent parent)
         (is (equal '(:entry :metadata :relative) (mapcar #'first (orl-fixture-events fixture)))))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-zero-and-index-eof-boundaries
  (dolist (eof (list 0 most-positive-fixnum))
    (orl-run
     (lambda (fixture parent)
       (setf (orl-fixture-metadata fixture) (list 5 9 eof))
       (multiple-value-bind (file observed)
           (orl-open fixture :max-transfer arcdocdb.io::+max-transfer+ :max-file-bytes eof)
         (is (= eof observed))
         (is (= eof (arcdocdb.io::file-max-file-bytes file)))
         (is (equal '(:open 0 0) (rename-native-state file)))
         (orl-check-parent parent))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-all-callbacks-required-no-legacy-fallback
  (dolist (missing '(:relative :metadata :entry))
    (orl-run (lambda (fixture parent)
               (signals arcdocdb.conditions:unsupported-format (orl-open fixture)
                        :io-open-relative-unavailable)
               (is (null (orl-fixture-events fixture))) (orl-check-parent parent))
             :missing missing)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-invalid-budgets-before-callback
  (orl-run
   (lambda (fixture parent)
     (dolist (spec (list '(:max-transfer 0) '(:max-transfer -1) '(:max-transfer :bad)
                         (list :max-transfer (1+ arcdocdb.io::+max-transfer+))
                         '(:max-file-bytes -1) '(:max-file-bytes 1/2)
                         (list :max-file-bytes (1+ arcdocdb.io::+max-file-offset+))))
       (signals invalid-argument (apply #'orl-open fixture spec) :io-budget))
     (is (null (orl-fixture-events fixture))) (orl-check-parent parent))))

;;; REQ: REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-ascii-name-bounds-and-private-copy
  (orl-run
   (lambda (fixture parent)
     (dolist (name (append (rename-native-invalid-names) (list nil 7 "a\\b" (string #\Newline))))
       (signals invalid-argument (orl-call parent name) :io-leaf-name))
     (is (null (orl-fixture-events fixture)))
     (dolist (size '(1 255))
       (multiple-value-bind (file eof) (orl-call parent (make-string size :initial-element #\a))
         (push file (orl-fixture-files fixture)) (is (= eof 4)) (chiudi file)))
     (let ((name (make-array 20 :element-type 'character :adjustable t :fill-pointer 11
                              :initial-element #\x)))
       (replace name "payload.seg")
       (setf (orl-fixture-open-hook fixture)
             (lambda (current fd private mode)
               (declare (ignore current fd mode))
               (is (not (eq private name))) (fill name #\z) (is (string= private "payload.seg"))))
       (multiple-value-bind (file eof) (orl-call parent name)
         (push file (orl-fixture-files fixture)) (is (= eof 4)))
       (let ((entry (find :entry (orl-fixture-events fixture) :key #'first)))
         (is (string= "payload.seg" (third entry)))))
     (orl-check-parent parent))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-parent-mode-and-lifecycle-preflight
  (dolist (mode '(:input :append))
    (orl-run (lambda (fixture parent)
               (signals invalid-argument (orl-open fixture) :io-mode)
               (is (null (orl-fixture-events fixture))) (orl-check-parent parent)) :mode mode))
  (dolist (state '(:closed :faulted))
    (orl-run
     (lambda (fixture parent)
       (if (eq state :closed) (chiudi parent) (setf (arcdocdb.io::file-state parent) :faulted))
       (let ((before (copy-tree (orl-fixture-events fixture))))
         (signals io-fault (orl-open fixture) :io-unavailable)
         (is (equal before (orl-fixture-events fixture))))
       (orl-check-parent parent state)))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-invalid-child-fd-and-parent-alias-not-closed
  (dolist (descriptor '(nil -1 2147483648 :invalid 41))
    (orl-run
     (lambda (fixture parent)
       (setf (orl-fixture-child-fd fixture) descriptor)
       (signals invariant-violation (orl-open fixture)
                (if (eql descriptor 41) :io-open-relative-parent :io-open-relative-result))
       (is (zerop (orl-count fixture :close)))
       (is (zerop (orl-count fixture :metadata))) (orl-check-parent parent)))))

;;; REQ: REQ-AFF-008 REQ-AFF-001 REQ-FOR-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-metadata-shape-and-size-budget
  (dolist (metadata (list '(nil 9 4) '(5 :bad 4) '(5 9 -1) '(5 9 1/2)
                          (list (ash 1 64) 9 4) (list 5 (- (1+ (ash 1 63))) 4)))
    (orl-run (lambda (fixture parent)
               (setf (orl-fixture-metadata fixture) metadata)
               (signals invariant-violation (orl-open fixture) :io-file-metadata-result)
               (is (= 1 (orl-closes fixture 73))) (orl-check-parent parent))))
  (dolist (eof (list 5 (ash 1 32) #xffffffffffffffff))
    (orl-run (lambda (fixture parent)
               (setf (orl-fixture-metadata fixture) (list 5 9 eof))
               (signals resource-exhausted (orl-open fixture :max-file-bytes 4) :io-file-size)
               (is (= 1 (orl-closes fixture 73))) (orl-check-parent parent)))))

;;; REQ: REQ-FOR-001 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-FOR-001-IO-OPEN-RELATIVE-entry-identity-mismatch-and-invalid-result
  (dolist (entry '((6 9) (5 10) (nil 9)))
    (orl-run
     (lambda (fixture parent)
       (setf (orl-fixture-entry fixture) entry)
       (if (null (first entry))
           (signals invariant-violation (orl-open fixture) :io-entry-identity-result)
           (signals invalid-argument (orl-open fixture) :io-open-relative-identity))
       (is (= 1 (orl-closes fixture 73))) (orl-check-parent parent)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-parent-closed-in-each-callback
  (dolist (stage '(:relative :metadata :entry))
    (orl-run
     (lambda (fixture parent)
       (orl-set-hook fixture stage
         (lambda (&rest args) (declare (ignore args)) (chiudi parent)))
       (signals io-fault (orl-open fixture) :io-unavailable)
       (is (= 1 (orl-closes fixture 73))) (is (= 1 (orl-closes fixture 41)))
       (when (eq stage :relative) (is (zerop (orl-count fixture :metadata))))
       (when (eq stage :metadata) (is (zerop (orl-count fixture :entry))))
       (orl-check-parent parent :closed)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-callback-conditions-and-syscall-provenance
  (dolist (stage '(:relative :metadata :entry))
    (dolist (type '(io-fault resource-exhausted))
      (orl-run
       (lambda (fixture parent)
         (declare (ignore parent))
         (let ((original (if (eq type 'io-fault)
                             (make-condition 'io-fault :reason :injected-relative :offset 17
                                             :operation :read :errno sb-posix:eio :transferred 3)
                             (make-condition 'resource-exhausted :reason :injected-relative :offset 17))))
           (orl-throw-primary fixture stage original)))))
    (orl-run
     (lambda (fixture parent)
       (orl-set-hook fixture stage (raises-errno sb-posix:eintr))
       (let ((condition (orl-condition 'io-fault :io-syscall (lambda () (orl-open fixture)))))
         (is (= sb-posix:eintr (error-errno condition)))
         (is (eq (ecase stage (:relative :open-relative) (:metadata :file-metadata)
                                    (:entry :entry-identity)) (error-operation condition))))
       (is (= (if (eq stage :relative) 0 1) (orl-closes fixture 73)))
       (orl-check-parent parent)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-IO-OPEN-RELATIVE-cleanup-failure-keeps-primary-fields-no-retry
  (dolist (cleanup '(:syscall :io-fault :nonzero))
   (dolist (io-p '(nil t))
    (orl-run
     (lambda (fixture parent)
       (let ((original (if io-p
                           (make-condition 'io-fault :reason :injected-primary :offset 29
                                           :operation :read :errno sb-posix:enospc :transferred 7)
                           (make-condition 'resource-exhausted :reason :injected-primary :offset 29))))
         (orl-set-hook fixture :metadata
           (lambda (&rest args) (declare (ignore args)) (error original)))
         (setf (orl-fixture-close-hook fixture)
               (lambda (current fd) (declare (ignore current))
                 (if (= fd 73)
                     (ecase cleanup
                       (:syscall (error 'sb-posix:syscall-error :errno sb-posix:eintr :name 'close))
                       (:io-fault (error 'io-fault :reason :injected-close :operation :close
                                                  :errno sb-posix:eio))
                       (:nonzero -1)) 0)))
         (let ((condition (orl-condition 'io-fault :injected-primary (lambda () (orl-open fixture)))))
           (is (= 29 (arcdocdb.conditions:error-offset condition)))
           (is (eql (ecase cleanup (:syscall sb-posix:eintr) (:io-fault sb-posix:eio) (:nonzero nil))
                    (arcdocdb.conditions:error-cleanup-errno condition)))
           (is (eq (if io-p :read :open-relative) (error-operation condition)))
           (is (eql (when io-p sb-posix:enospc) (error-errno condition)))
           (is (= (if io-p 7 0) (error-transferred condition))))
         (is (= 1 (orl-closes fixture 73))) (orl-check-parent parent)))))))

;;; REQ: REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-IO-OPEN-RELATIVE-nonlocal-exit-cleans-child-before-caller
  (dolist (cleanup-fails '(nil t))
    (orl-run
     (lambda (fixture parent)
       (let ((marker (list :open-relative-escape)) (closed-before-caller nil))
         (orl-set-hook fixture :metadata
           (lambda (&rest args) (declare (ignore args)) (throw 'orl-escape marker)))
         (when cleanup-fails
           (setf (orl-fixture-close-hook fixture)
                 (lambda (current fd) (declare (ignore current))
                   (if (= fd 73) (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'close) 0))))
         (is (eq marker
                 (catch 'orl-escape
                   (unwind-protect (orl-open fixture)
                     (setf closed-before-caller (= 1 (orl-closes fixture 73)))))))
         (is closed-before-caller) (is (= 1 (orl-closes fixture 73)))
         (orl-check-parent parent))))))
