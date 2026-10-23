;;;; C4: IO reale su namespace 0700, soli nomi registrati, nessun worker o benchmark.
;;; OWNER: fixture rename-native già caricata; FD parent distinti dai figli readonly.
(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-STO-003 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-NATIVE-read-eof-flags-and-preserved-writer
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture))
            (data (bytes 0 13 255 19 81))
            (path (rename-native-leaf fixture "payload.tmp"))
            (writer (rename-native-create fixture path data))
            (parent (rename-native-open fixture root :directory))
            (before (list (orl-native-observation writer) (orl-native-observation parent))))
       (multiple-value-bind (file eof)
           (orl-native-open fixture parent "payload.tmp" deadline :max-transfer 5 :max-file-bytes 5)
         (is (= 5 eof)) (is (equal (rename-native-identity writer) (rename-native-identity file)))
         (is (logbitp 0 (sb-posix:fcntl (arcdocdb.io::file-fd file) sb-posix:f-getfd)))
         (is (= sb-posix:o-rdonly
                (logand (sb-posix:fcntl (arcdocdb.io::file-fd file) sb-posix:f-getfl)
                        (logior sb-posix:o-wronly sb-posix:o-rdwr))))
         (rename-native-check-bytes file data)
         (signals invalid-argument (append-esatto file (bytes 9) 0 1) :io-mode)
         (is (equal before (list (orl-native-observation writer) (orl-native-observation parent))))
         (rename-native-check-bytes file data))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-NATIVE-empty-file-zero-budget
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((path (rename-native-leaf fixture "empty.tmp"))
            (writer (rename-native-open fixture path :append))
            (parent (rename-native-open fixture (rename-native-fixture-root fixture) :directory)))
       (multiple-value-bind (file eof)
           (orl-native-open fixture parent "empty.tmp" deadline :max-file-bytes 0 :max-transfer 1)
         (is (zerop eof)) (is (zerop (leggi-esatto file (zeros 0) 0 0 0)))
         (rename-native-check-bytes file (zeros 0))
         (is (equal (rename-native-identity writer) (rename-native-identity file))))))))

;;; REQ: REQ-AFF-008 REQ-FOR-001 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-NATIVE-sparse-u64-eof-exact-and-one-under
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((path (rename-native-leaf fixture "sparse.tmp"))
            (writer (rename-native-open fixture path :append)) (size (1+ (ash 1 32)))
            (parent (rename-native-open fixture (rename-native-fixture-root fixture) :directory)))
       ;; C4: file sparse, nessun array o scrittura di vari GiB.
       (sb-posix:ftruncate (arcdocdb.io::file-fd writer) size)
       (let ((before (list (orl-native-observation writer) (orl-native-observation parent))))
         (signals resource-exhausted (orl-native-open fixture parent "sparse.tmp" deadline) :io-file-size)
         (signals resource-exhausted
           (orl-native-open fixture parent "sparse.tmp" deadline :max-file-bytes (1- size)) :io-file-size)
         (multiple-value-bind (file eof)
             (orl-native-open fixture parent "sparse.tmp" deadline :max-file-bytes size :max-transfer 1)
           (is (= size eof))
           (let ((last (bytes 255)))
             (is (= 1 (leggi-esatto file last 0 1 (1- size)))) (is (zerop (aref last 0)))))
         (is (equal before (list (orl-native-observation writer) (orl-native-observation parent)))))))))

;;; REQ: REQ-AFF-008 REQ-AFF-001 REQ-STO-003
(deftest test-REQ-AFF-008-IO-OPEN-RELATIVE-NATIVE-no-follow-file-kinds-and-missing
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture)) (data (bytes 17 31 255))
            (source (rename-native-leaf fixture "source.tmp"))
            (writer (rename-native-create fixture source data))
            (link (rename-native-leaf fixture "link")) (fifo (rename-native-leaf fixture "fifo"))
            (parent (rename-native-open fixture root :directory)))
       (rename-native-subdirectory fixture "subdir/")
       (sb-posix:symlink (namestring source) (namestring link)) (sb-posix:mkfifo fifo #o600)
       (let ((before (list (orl-native-observation writer) (orl-native-observation parent))))
         (dolist (name '("fifo" "subdir"))
           (signals io-fault (orl-native-open fixture parent name deadline) :io-file-kind))
         (dolist (name '("link" "missing"))
           (let ((condition (orl-condition 'io-fault :io-syscall
                                          (lambda () (orl-native-open fixture parent name deadline)))))
             (is (eq :open-relative (error-operation condition)))
             (is (= (if (string= name "missing") sb-posix:enoent sb-posix:eloop) (error-errno condition)))))
         (is (equal before (list (orl-native-observation writer) (orl-native-observation parent))))
         (multiple-value-bind (file eof) (orl-native-open fixture parent "source.tmp" deadline)
           (is (= 3 eof)) (rename-native-check-bytes file data)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-NATIVE-parent-move-ignores-replacement-decoy
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((cwd (sb-posix:getcwd))
            (parent-path (rename-native-subdirectory fixture "parent/"))
            (owned (rename-native-subdirectory fixture "parent/owned/"))
            (moved (merge-pathnames "moved/" (rename-native-fixture-root fixture)))
            (moved-owned (merge-pathnames "owned/" moved))
            (parent (rename-native-open fixture owned :directory))
            (old (bytes 1 17 255)) (decoy (bytes 90 80 70 60))
            (writer (rename-native-create fixture (rename-native-leaf fixture "payload.tmp" owned) old)))
       (push moved (rename-native-fixture-directories fixture))
       (push moved-owned (rename-native-fixture-directories fixture))
       (rename-native-leaf fixture "payload.tmp" moved-owned)
       (sb-posix:rename (string-right-trim "/" (namestring parent-path))
                        (string-right-trim "/" (namestring moved)))
       (rename-native-subdirectory fixture "parent/") (rename-native-subdirectory fixture "parent/owned/")
       (rename-native-create fixture (rename-native-leaf fixture "payload.tmp" owned) decoy)
       (let ((before (list (orl-native-observation writer) (orl-native-observation parent))))
         (multiple-value-bind (file eof) (orl-native-open fixture parent "payload.tmp" deadline)
           (is (= 3 eof)) (rename-native-check-bytes file old)
           (is (equal (rename-native-identity writer) (rename-native-identity file))))
         (rename-native-check-path fixture (merge-pathnames "payload.tmp" owned) decoy)
         (is (equal before (list (orl-native-observation writer) (orl-native-observation parent)))))
       (is (string= cwd (sb-posix:getcwd)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
(deftest test-REQ-AFF-001-IO-OPEN-RELATIVE-NATIVE-repeat-close-owns-only-child
  (orl-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture)) (data (bytes 0 255 31 47))
            (writer (rename-native-create fixture (rename-native-leaf fixture "payload.tmp") data))
            (parent (rename-native-open fixture root :directory)) (previous nil)
            (before (list (orl-native-observation writer) (orl-native-observation parent))))
       (loop repeat 8 do
         (multiple-value-bind (file eof) (orl-native-open fixture parent "payload.tmp" deadline)
           (is (= 4 eof)) (is (not (eq previous file)))
           (when previous (chiudi previous))
           (rename-native-check-bytes file data)
           (chiudi file) (is (eq :closed (stato-file file)))
           (setf previous file)
           (is (equal before (list (orl-native-observation writer) (orl-native-observation parent))))))
       (is (eq :open (stato-file parent)))))))
