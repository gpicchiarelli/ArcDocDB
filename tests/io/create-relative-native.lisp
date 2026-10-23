;;;; C4: creazioni reali in namespace esclusivi 0700, byte e identità come oracoli.
;;; OWNER: registri bounded rename-native; parent distinto dai figli append/readonly.
(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-STO-003 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-NATIVE-append-flags-permissions-and-readonly-identity
  (ctr-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture))
            (path (rename-native-leaf fixture "payload.tmp"))
            (parent (rename-native-open fixture root :directory))
            (before (ctr-native-parent-observation parent))
            (writer (ctr-native-create fixture parent "payload.tmp" deadline :max-transfer 4 :max-file-bytes 4))
            (fd (arcdocdb.io::file-fd writer)) (data (bytes 7 0 255 19))
            (stat (sb-posix:fstat fd)) (flags (sb-posix:fcntl fd sb-posix:f-getfl)))
       (is (sb-posix:s-isreg (sb-posix:stat-mode stat)))
       ;; La fixture attesta mkdir0700 esatto e nessuno cambia umask: owner rw resta ammesso.
       ;; Mode0600 esatto rileva anche un quarto argomento alien perso su runner privilegiato.
       (is (= #o600 (logand #o7777 (sb-posix:stat-mode stat))))
       (is (zerop (sb-posix:stat-size stat)))
       (is (equal '(:open 0 0) (rename-native-state writer)))
       (is (= sb-posix:o-wronly (logand flags (logior sb-posix:o-wronly sb-posix:o-rdwr))))
       (is (not (zerop (logand flags sb-posix:o-append))))
       (is (logbitp 0 (sb-posix:fcntl fd sb-posix:f-getfd)))
       (is (= 2 (append-esatto writer data 0 2)))
       (is (zerop (sb-posix:lseek fd 0 sb-posix:seek-set)))
       (is (= 4 (append-esatto writer data 2 4)))
       (is (equal '(:open 4 0) (rename-native-state writer)))
       (multiple-value-bind (input eof)
           (orl-native-open fixture parent "payload.tmp" deadline :max-file-bytes 4)
         (is (= 4 eof)) (rename-native-check-bytes input data)
         (is (equal (rename-native-identity writer) (rename-native-identity input)))
         (is (equal (rename-native-identity input) (rename-native-path-identity path))))
       (is (equal before (ctr-native-parent-observation parent)))))))

;;; REQ: REQ-AFF-008 REQ-STO-003 REQ-AFF-001
(deftest test-REQ-AFF-008-IO-CREATE-RELATIVE-NATIVE-collisions-preserve-file-fifo-directory-and-symlink
  (ctr-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture)) (data (bytes 17 31 255))
            (file (rename-native-leaf fixture "file.tmp"))
            (writer (rename-native-create fixture file data))
            (fifo (rename-native-leaf fixture "fifo.tmp"))
            (directory (rename-native-subdirectory fixture "directory.tmp/"))
            (link (rename-native-leaf fixture "link.tmp"))
            (parent (rename-native-open fixture root :directory)))
       (sb-posix:mkfifo fifo #o600) (sb-posix:symlink "file.tmp" (namestring link))
       (let ((before (mapcar #'ctr-native-entry-observation (list file fifo directory link)))
             (writer-before (orl-native-observation writer))
             (parent-before (ctr-native-parent-observation parent)))
         (dolist (name '("file.tmp" "fifo.tmp" "directory.tmp" "link.tmp"))
           (let ((condition (ctr-condition 'io-fault :io-syscall
                              (lambda () (ctr-native-create fixture parent name deadline)))))
             (is (eq :create-relative (error-operation condition)))
             (is (= sb-posix:eexist (error-errno condition)))))
         (is (equal before (mapcar #'ctr-native-entry-observation (list file fifo directory link))))
         (is (string= "file.tmp" (sb-posix:readlink (namestring link))))
         (rename-native-check-path fixture file data)
         (is (equal writer-before (orl-native-observation writer)))
         (is (equal parent-before (ctr-native-parent-observation parent))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-NATIVE-parent-move-ignores-replacement-decoy
  (ctr-native-case
   (lambda (fixture deadline)
     (let* ((cwd (sb-posix:getcwd))
            (parent-path (rename-native-subdirectory fixture "parent/"))
            (owned (rename-native-subdirectory fixture "parent/owned/"))
            (moved (merge-pathnames "moved/" (rename-native-fixture-root fixture)))
            (moved-owned (merge-pathnames "owned/" moved))
            (parent (rename-native-open fixture owned :directory))
            (data (bytes 1 17 255)) (decoy (bytes 90 80 70 60)))
       (push moved (rename-native-fixture-directories fixture))
       (push moved-owned (rename-native-fixture-directories fixture))
       (sb-posix:rename (string-right-trim "/" (namestring parent-path))
                        (string-right-trim "/" (namestring moved)))
       (rename-native-subdirectory fixture "parent/") (rename-native-subdirectory fixture "parent/owned/")
       (rename-native-create fixture (rename-native-leaf fixture "payload.tmp" owned) decoy)
       (let* ((path (rename-native-leaf fixture "payload.tmp" moved-owned))
              (before (ctr-native-parent-observation parent))
              (writer (ctr-native-create fixture parent "payload.tmp" deadline)))
         (is (= 3 (append-esatto writer data 0 3)))
         (is (equal (rename-native-identity writer) (rename-native-path-identity path)))
         (multiple-value-bind (input eof) (orl-native-open fixture parent "payload.tmp" deadline)
           (is (= 3 eof)) (rename-native-check-bytes input data)
           (is (equal (rename-native-identity writer) (rename-native-identity input))))
         (rename-native-check-path fixture (merge-pathnames "payload.tmp" owned) decoy)
         (is (equal before (ctr-native-parent-observation parent))))
       (is (string= cwd (sb-posix:getcwd)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
(deftest test-REQ-AFF-001-IO-CREATE-RELATIVE-NATIVE-repeated-close-and-descriptor-reuse
  (ctr-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture))
            (parent (rename-native-open fixture root :directory))
            (before (ctr-native-parent-observation parent)) (previous nil) (reused nil))
       (dotimes (round 8)
         (let* ((name (format nil "round-~D.tmp" round))
                (path (rename-native-leaf fixture name))
                (writer (ctr-native-create fixture parent name deadline))
                (data (bytes (+ round 10) 0 255)))
           (when previous
             (when (= (arcdocdb.io::file-fd previous) (arcdocdb.io::file-fd writer)) (setf reused t))
             (chiudi previous))
           (is (not (minusp (sb-posix:fcntl (arcdocdb.io::file-fd writer) sb-posix:f-getfd))))
           (is (= 3 (append-esatto writer data 0 3)))
           (multiple-value-bind (input eof) (orl-native-open fixture parent name deadline)
             (is (= 3 eof)) (rename-native-check-bytes input data) (chiudi input))
           (is (equal (rename-native-identity writer) (rename-native-path-identity path)))
           (chiudi writer) (chiudi writer) (is (eq :closed (stato-file writer)))
           (setf previous writer)
           (is (equal before (ctr-native-parent-observation parent)))))
       (is reused)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-STO-003
(deftest test-REQ-AFF-004-IO-CREATE-RELATIVE-NATIVE-postcreate-validation-failure-keeps-orphan
  ;; Ibrido C4: syscall di creazione/close reali, guasto tipizzato della callback di validazione.
  (ctr-native-case
   (lambda (fixture deadline)
     (let* ((root (rename-native-fixture-root fixture))
            (path (rename-native-leaf fixture "orphan.tmp"))
            (primary (make-condition 'io-fault :reason :injected-postcreate :operation :file-metadata
                                              :errno sb-posix:eio :offset 13 :transferred 0))
            (created-fd nil) (close-count 0)
            (backend (make-backend
                      #'arcdocdb.io::native-open #'arcdocdb.io::native-read #'arcdocdb.io::native-write
                      #'arcdocdb.io::native-flush #'arcdocdb.io::native-directory-flush
                      (lambda (fd) (incf close-count) (arcdocdb.io::native-close fd))
                      :create-relative (lambda (fd name mode)
                                         (setf created-fd (arcdocdb.io::native-create-relative fd name mode)))
                      :file-metadata (lambda (fd) (is (= fd created-fd)) (error primary))
                      :entry-identity #'arcdocdb.io::native-entry-identity))
            (parent (rename-native-open fixture root :directory backend))
            (before (ctr-native-parent-observation parent)))
       (is (eq primary (ctr-condition 'io-fault :injected-postcreate
                         (lambda () (ctr-native-create fixture parent "orphan.tmp" deadline)))))
       (is (= close-count 1))
       (handler-case (progn (sb-posix:fcntl created-fd sb-posix:f-getfd)
                            (error "FD del child ancora aperto dopo il rifiuto."))
         (sb-posix:syscall-error (condition) (is (= sb-posix:ebadf (sb-posix:syscall-errno condition)))))
       (let ((stat (sb-posix:lstat (namestring path))))
         (is (sb-posix:s-isreg (sb-posix:stat-mode stat))) (is (zerop (sb-posix:stat-size stat))))
       (let ((native-parent (rename-native-open fixture root :directory)))
         (let ((condition (ctr-condition 'io-fault :io-syscall
                            (lambda () (ctr-native-create fixture native-parent "orphan.tmp" deadline)))))
           (is (= sb-posix:eexist (error-errno condition)))))
       (is (= close-count 1)) (is (equal before (ctr-native-parent-observation parent)))))))
