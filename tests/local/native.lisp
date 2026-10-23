;;;; Fixture programmatiche FI: nessun filesystem, socket o processo reale al caricamento.
;;; REQ: REQ-IPC-001 REQ-IPC-002 REQ-IPC-003 REQ-AFF-004
(defpackage #:arcdocdb.local.native.tests
  (:use #:cl)
  (:local-nicknames (#:n #:arcdocdb.local))
  (:export #:run))
(in-package #:arcdocdb.local.native.tests)
(declaim (optimize (safety 3) (debug 3)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defmacro is (form)
  `(unless ,form (error "Oracolo native fallito: ~S" ',form)))
(defmacro rejects (type &body body)
  `(let ((seen nil))
     (handler-case (progn ,@body) (,type (condition) (setf seen condition)))
     (is seen) seen))

(defun bytes (size &optional (byte #xa5))
  (make-array size :element-type '(unsigned-byte 8) :initial-element byte))
(defun directory-node (inode uid mode)
  (n::%make-native-node 7 inode uid (logior #o40000 mode)))
(defun socket-node (inode &optional (mode #o600) (uid 42))
  (n::%make-native-node 7 inode uid (logior #o140000 mode)))

(defstruct fixture
  backend
  (calls nil)
  (closed nil)
  (faults (make-hash-table :test #'equal))
  hook
  (root (directory-node 10 0 #o755))
  (runtime (directory-node 11 42 #o700))
  node
  (root-fd 0)
  (runtime-fd 1)
  (socket-fd 2)
  (accept-fd -1)
  (accept-errno sb-posix:eagain)
  (connect-result 0)
  (connect-errno 0)
  (socket-error 0)
  (wait-ready t))

(defun fixture-call-count (fixture operation)
  (count operation (fixture-calls fixture) :key #'car))
(defun fixture-operation (fixture operation arguments)
  (case operation
    (:uid (values 42 0))
    (:socket (values (fixture-socket-fd fixture) 0))
    (:configure (values 0 0))
    (:root (values (fixture-root-fd fixture) 0))
    (:openat (is (equal (list (fixture-root-fd fixture) "svc") arguments))
             (values (fixture-runtime-fd fixture) 0))
    (:fstat (values (if (= (first arguments) (fixture-root-fd fixture))
                       (fixture-root fixture) (fixture-runtime fixture)) 0))
    (:lstat
     (cond ((string= (first arguments) "/") (values (fixture-root fixture) 0))
           ((string= (first arguments) "/svc") (values (fixture-runtime fixture) 0))
           ((fixture-node fixture) (values (fixture-node fixture) 0))
           (t (values -1 sb-posix:enoent))))
    (:entry
     (cond ((= (first arguments) (fixture-root-fd fixture)) (values (fixture-runtime fixture) 0))
           ((fixture-node fixture) (values (fixture-node fixture) 0))
           (t (values -1 sb-posix:enoent))))
    (:lock (values 0 0))
    (:bind (is (null (fixture-node fixture))) (setf (fixture-node fixture) (socket-node 12 #o777))
           (values 0 0))
    (:chmod (is (fixture-node fixture))
            (setf (fixture-node fixture) (socket-node (n::native-node-inode (fixture-node fixture))))
            (values 0 0))
    (:listen (is (= #o600 (logand #o7777 (n::native-node-mode (fixture-node fixture)))))
             (values 0 0))
    (:unlink (setf (fixture-node fixture) nil) (values 0 0))
    (:close (push (first arguments) (fixture-closed fixture)) (values 0 0))
    (:accept (values (fixture-accept-fd fixture) (fixture-accept-errno fixture)))
    (:connect (values (fixture-connect-result fixture) (fixture-connect-errno fixture)))
    (:socket-error (values (fixture-socket-error fixture) 0))
    (:wait-output (values (fixture-wait-ready fixture) 0))
    (otherwise (error "Operazione FI sconosciuta: ~S" operation))))

(defun make-scripted-fixture (&key recv send hook)
  (let ((fixture (make-fixture :hook hook)))
    (setf (fixture-backend fixture)
          (n::make-native-backend
           :recv (or recv (lambda (fd buffer start count)
                           (declare (ignore fd buffer start count)) (values -1 sb-posix:eagain)))
           :send (or send (lambda (fd buffer start count)
                           (declare (ignore fd buffer start count)) (values -1 sb-posix:epipe)))
           :control
           (lambda (operation arguments)
             (push (cons operation arguments) (fixture-calls fixture))
             (when (fixture-hook fixture) (funcall (fixture-hook fixture) fixture operation arguments))
             (let ((errno (or (gethash (cons operation arguments) (fixture-faults fixture))
                              (gethash operation (fixture-faults fixture)))))
               (if errno (values -1 errno) (fixture-operation fixture operation arguments))))))
    fixture))

(deftest test-REQ-IPC-002-native-span-guards-before-backend
  (let* ((calls 0) (buffer (bytes 8))
         (fixture (make-scripted-fixture
                   :recv (lambda (fd bytes start count)
                           (declare (ignore fd bytes start count)) (incf calls) (values 1 0))))
         (backend (fixture-backend fixture)))
    (dolist (spec (list (list -1 buffer 2 4) (list 2147483648 buffer 2 4)
                        (list 0 #(1 2) 0 1) (list 0 buffer -1 1)
                        (list 0 buffer 0 0) (list 0 buffer 2 7)
                        (list 0 buffer 9 1) (list 0 buffer 2 'bad)
                        (list 0 buffer 1/2 1) (list 0 buffer 0 (ash 1 100))))
      (rejects arcdocdb.conditions:invalid-argument
        (apply #'n::native-recv-span (append spec (list backend)))))
    (rejects arcdocdb.conditions:invalid-argument (n::native-send-span 0 buffer 2 4 :bad))
    (is (zerop calls))
    (is (every (lambda (byte) (= byte #xa5)) buffer))))

(deftest test-REQ-IPC-002-native-short-eintr-eagain-eof-and-fd-zero
  (let* ((buffer (bytes 10)) (script (list '(2 0) (list -1 sb-posix:eintr)
                                         (list -1 sb-posix:eagain) '(1 0) '(0 0)))
         (calls 0) (cursor 2)
         (fixture
           (make-scripted-fixture
            :recv (lambda (fd actual start count)
                    (is (= fd 0)) (is (eq buffer actual)) (is (= cursor start)) (is (= count 4))
                    (incf calls)
                    (destructuring-bind (n errno) (pop script)
                      (dotimes (i (max 0 n)) (setf (aref actual (+ start i)) (+ 11 start i)))
                      (values n errno))))))
    (dolist (expected (list '(2 0) (list -1 sb-posix:eintr) (list -1 sb-posix:eagain) '(1 0) '(0 0)))
      (multiple-value-bind (n errno)
          (n::native-recv-span 0 buffer cursor 4 (fixture-backend fixture))
        (is (equal (list n errno) expected))
        (when (plusp n) (incf cursor n))))
    (is (= calls 5)) (is (= cursor 5)) (is (null script))
    (is (equalp buffer (make-array 10 :element-type '(unsigned-byte 8)
                                   :initial-contents '(165 165 13 14 15 165 165 165 165 165))))))

(deftest test-REQ-AFF-004-native-impossible-result-and-callback-cause
  (dolist (result (list '(5 0) '(-2 0) '(-1 0) '(1 7) '(0 -1) '(nil 0) '(1 nil)))
    (let* ((calls 0)
           (fixture (make-scripted-fixture
                     :send (lambda (fd buffer start count)
                             (declare (ignore fd buffer start count)) (incf calls)
                             (values (first result) (second result))))))
      (rejects n::native-error (n::native-send-span 0 (bytes 8) 2 4 (fixture-backend fixture)))
      (is (= calls 1))))
  (let* ((primary (make-condition 'simple-error :format-control "FI callback"))
         (fixture (make-scripted-fixture
                   :recv (lambda (fd buffer start count)
                           (declare (ignore fd buffer start count)) (error primary)))))
    (let ((observed (rejects n::native-error
                      (n::native-recv-span 0 (bytes 8) 2 4 (fixture-backend fixture)))))
      (is (eq primary (n::native-error-primary observed))))))

(deftest test-REQ-IPC-002-native-send-zero-fatal-and-unchanged-buffer
  (dolist (result (list '(0 0) '(2 0) (list -1 sb-posix:epipe) (list -1 sb-posix:econnreset)))
    (let* ((buffer (bytes 8))
           (fixture (make-scripted-fixture
                     :send (lambda (fd actual start count)
                             (is (= fd 0)) (is (eq actual buffer)) (is (= start 2)) (is (= count 4))
                             (values (first result) (second result))))))
      (is (equal result (multiple-value-list
                         (n::native-send-span 0 buffer 2 4 (fixture-backend fixture)))))
      (is (every (lambda (byte) (= #xa5 byte)) buffer)))))

(deftest test-REQ-IPC-001-native-path-byte-preflight
  (dolist (path (list nil #p"/svc/sock" "" "relative.sock" "/" "/svc/" "/svc//a"
                      "/svc/./a" "/svc/../a" (concatenate 'string "/svc/" (string #\Null))
                      (concatenate 'string "/" (make-string 100 :initial-element #\a))
                      (concatenate 'string "/svc/" (make-string 48 :initial-element #\é))))
    (rejects arcdocdb.conditions:invalid-argument (n::native-path-preflight path)))
  (let ((path (concatenate 'string "/" (make-string 99 :initial-element #\a))))
    (multiple-value-bind (stable octets components leaf) (n::native-path-preflight path)
      (is (string= stable path)) (is (not (eq stable path))) (is (= (length octets) 100))
      (is (null components)) (is (= (length leaf) 99))))
  (multiple-value-bind (stable octets) (n::native-path-preflight "/svc/é.sock")
    (is (string= stable "/svc/é.sock")) (is (= (length octets) 12))))

(deftest test-REQ-IPC-003-native-anchor-precedes-socket-and-preserves-fd-zero
  (let* ((fixture (make-scripted-fixture))
         (anchor (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture))))
    (is (zerop (fixture-call-count fixture :socket)))
    (is (= 1 (fixture-call-count fixture :lock)))
    (is (equal '(7 11) (multiple-value-list (n::local-namespace-identity anchor))))
    (is (null (n::close-local-namespace anchor)))
    (is (equal '(0 1) (fixture-closed fixture)))
    (let ((count (fixture-call-count fixture :close)))
      (is (null (n::close-local-namespace anchor)))
      (is (= count (fixture-call-count fixture :close))))))

(deftest test-REQ-IPC-003-native-rejects-unsafe-directories-before-socket
  (dolist (bad (list (directory-node 11 42 #o770) (directory-node 11 43 #o700)
                    (directory-node 11 0 #o700) (n::%make-native-node 7 11 42 #o120700)
                    (directory-node 11 42 #o1700)))
    (let ((fixture (make-scripted-fixture)))
      (setf (fixture-runtime fixture) bad)
      (rejects n::native-error (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))
      (is (zerop (fixture-call-count fixture :socket)))
      (is (zerop (fixture-call-count fixture :bind)))
      (is (equal '(0 1) (fixture-closed fixture)))))
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-root fixture) (directory-node 10 0 #o777))
    (rejects n::native-error (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (equal '(0) (fixture-closed fixture)))
    (is (zerop (fixture-call-count fixture :openat)))))

(deftest test-REQ-IPC-003-native-occupied-node-and-access-error-preserved
  (dolist (node (list (socket-node 99) (n::%make-native-node 7 99 42 #o100600)
                     (n::%make-native-node 7 99 42 #o120777)))
    (let ((fixture (make-scripted-fixture)))
      (setf (fixture-node fixture) node)
      (rejects n::native-error (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))
      (is (eq node (fixture-node fixture)))
      (is (zerop (fixture-call-count fixture :unlink)))
      (is (zerop (fixture-call-count fixture :bind)))))
  (let ((fixture (make-scripted-fixture)))
    (setf (gethash (list :entry 1 "run.sock") (fixture-faults fixture)) sb-posix:eacces)
    (rejects n::native-error (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (zerop (fixture-call-count fixture :socket)))))

(deftest test-REQ-IPC-003-native-listener-borrows-anchor-chmod-before-listen
  (let* ((fixture (make-scripted-fixture)) (backend (fixture-backend fixture))
         (anchor (n::open-local-namespace "/svc/run.sock" :backend backend))
         (listener (n::open-local-listener "/svc/run.sock" :namespace anchor)))
    (is (= 2 (n::handle-socket listener)))
    (let ((operations (mapcar #'car (reverse (fixture-calls fixture)))))
      (is (< (position :bind operations) (position :chmod operations) (position :listen operations))))
    (is (null (n::close-local-listener listener)))
    (is (null (fixture-node fixture))) (is (equal '(2) (fixture-closed fixture)))
    (is (not (n::local-namespace-closed-p anchor)))
    (n::close-local-namespace anchor)
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-IPC-003-native-owned-anchor-close-and-replacement-diagnosis
  (let* ((fixture (make-scripted-fixture))
         (listener (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
         (replacement (socket-node 99)))
    (setf (fixture-node fixture) replacement)
    (let ((observed (rejects n::native-error (n::close-local-listener listener))))
      (is (typep (n::native-error-primary observed) 'n::native-error)))
    (is (eq replacement (fixture-node fixture)))
    (is (zerop (fixture-call-count fixture :unlink)))
    (is (equal '(0 1 2) (fixture-closed fixture)))
    (let ((calls (length (fixture-calls fixture))))
      (is (null (n::close-local-listener listener)))
      (is (= calls (length (fixture-calls fixture)))))))

(deftest test-REQ-IPC-003-native-cleanup-tries-all-preserves-primary-and-errnos
  (let* ((fixture (make-scripted-fixture))
         (listener (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
         (primary (make-condition 'arcdocdb.conditions:io-fault :reason :fi-primary :operation :put)))
    (setf (gethash :close (fixture-faults fixture)) sb-posix:eio
          (gethash :unlink (fixture-faults fixture)) sb-posix:eacces)
    (let ((failures (n::native-close-listener listener primary)))
      (is (eq primary (first failures))) (is (= 5 (length failures)))
      (is (equal (list sb-posix:eio sb-posix:eacces sb-posix:eio sb-posix:eio)
                 (mapcar #'arcdocdb.conditions:error-errno (rest failures)))))
    (is (= 3 (fixture-call-count fixture :close)))
    (is (= 1 (fixture-call-count fixture :unlink)))
    (is (n::native-listener-closed-p listener))))

(deftest test-REQ-IPC-003-native-namespace-replacement-after-bind-fails-closed
  (let ((fixture (make-scripted-fixture
                  :hook (lambda (fixture operation arguments)
                          (declare (ignore arguments))
                          (when (eq operation :bind)
                            (setf (fixture-runtime fixture) (directory-node 88 42 #o700)))))))
    (rejects n::native-error (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (zerop (fixture-call-count fixture :listen)))
    (is (zerop (fixture-call-count fixture :unlink)))
    (is (fixture-node fixture))
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-IPC-003-native-bind-failure-never-unlinks-other-node
  (let* ((replacement (socket-node 88))
         (fixture (make-scripted-fixture
                   :hook (lambda (fixture operation arguments)
                           (declare (ignore arguments))
                           (when (eq operation :bind) (setf (fixture-node fixture) replacement))))))
    (setf (gethash :bind (fixture-faults fixture)) sb-posix:eaddrinuse)
    (rejects n::native-error (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (eq replacement (fixture-node fixture)))
    (is (zerop (fixture-call-count fixture :unlink)))
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-IPC-001-native-gate-and-namespace-mismatch-before-effects
  (let ((fixture (make-scripted-fixture)))
    (rejects n::native-error
      (n::native-open-listener "/svc/run.sock" (constantly nil) :backend (fixture-backend fixture)))
    (is (null (fixture-calls fixture)))
    (let ((anchor (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture))))
      (rejects arcdocdb.conditions:invalid-argument
        (n::open-local-listener "/svc/other.sock" :namespace anchor))
      (is (zerop (fixture-call-count fixture :socket)))
      (n::close-local-namespace anchor))))

(deftest test-REQ-IPC-002-native-socket-configure-and-accept-fd-zero
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-socket-fd fixture) 0)
    (is (= 0 (n::native-socket-new :backend (fixture-backend fixture))))
    (is (= 1 (fixture-call-count fixture :configure)))
    (n::close-local-socket 0 :backend (fixture-backend fixture))
    (is (equal '(0) (fixture-closed fixture))))
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-accept-fd fixture) 0 (fixture-accept-errno fixture) 0)
    (is (equal '(0 0) (multiple-value-list (n::native-accept 9 :backend (fixture-backend fixture)))))
    (setf (gethash :configure (fixture-faults fixture)) sb-posix:eio)
    (rejects n::native-error (n::native-accept 9 :backend (fixture-backend fixture)))
    (is (equal '(0) (fixture-closed fixture))))
  (let* ((fixture (make-scripted-fixture))
         (listener (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture))))
    (is (null (n::accept-local-socket listener)))
    (is (= 1 (fixture-call-count fixture :accept)))
    (n::close-local-listener listener)))

(deftest test-REQ-IPC-002-native-connect-clock-and-pending-without-retry
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-connect-result fixture) -1 (fixture-connect-errno fixture) sb-posix:einprogress)
    (is (= 2 (n::connect-local-socket "/svc/run.sock" 100
                                     :clock (constantly 10) :backend (fixture-backend fixture))))
    (is (= 1 (fixture-call-count fixture :connect)))
    (is (= 1 (fixture-call-count fixture :wait-output)))
    (is (= 1 (fixture-call-count fixture :socket-error)))
    (is (null (fixture-closed fixture))))
  (dolist (ticks '((100) (10 9) (10 100) (10 10 100) (10 10 20 30 25)))
    (let ((fixture (make-scripted-fixture)) (times (copy-list ticks)))
      (setf (fixture-connect-result fixture) -1 (fixture-connect-errno fixture) sb-posix:einprogress)
      (rejects n::native-error
        (n::connect-local-socket "/svc/run.sock" 100 :backend (fixture-backend fixture)
                                :clock (lambda () (or (pop times) 100))))
      (is (<= (fixture-call-count fixture :connect) 1))
      (when (> (length ticks) 1) (is (equal '(2) (fixture-closed fixture)))))))

(deftest test-REQ-IPC-002-native-connect-so-error-close-and-cause
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-socket-error fixture) sb-posix:econnrefused
          (gethash :close (fixture-faults fixture)) sb-posix:eio)
    (let ((observed (rejects n::native-error
                      (n::connect-local-socket "/svc/run.sock" 100 :clock (constantly 10)
                                              :backend (fixture-backend fixture)))))
      (is (= sb-posix:econnrefused
             (arcdocdb.conditions:error-errno (n::native-error-primary observed))))
      (is (= sb-posix:eio
             (arcdocdb.conditions:error-errno (first (n::native-error-cleanup observed))))))
    (is (= 1 (fixture-call-count fixture :close)))))

(deftest test-REQ-AFF-004-native-backend-and-public-boundary-guards
  (dolist (slot '(:recv :send :control))
    (rejects arcdocdb.conditions:invalid-argument
      (apply #'n::make-native-backend (list slot nil))))
  (let* ((fixture (make-scripted-fixture)) (backend (fixture-backend fixture)))
    (rejects arcdocdb.conditions:invalid-argument (n::native-close -1 :backend backend))
    (rejects arcdocdb.conditions:invalid-argument (n::native-connect nil "/svc/run.sock" :backend backend))
    (rejects arcdocdb.conditions:invalid-argument (n::native-accept "0" :backend backend))
    (rejects arcdocdb.conditions:invalid-argument (n::native-socket-error -1 :backend backend))
    (rejects arcdocdb.conditions:invalid-argument (n::open-local-namespace "/svc/run.sock" :backend :bad))
    (rejects arcdocdb.conditions:invalid-argument (n::handle-socket nil))
    (rejects arcdocdb.conditions:invalid-argument (n::accept-local-socket nil))
    (rejects arcdocdb.conditions:invalid-argument (n::close-local-listener nil))
    (rejects arcdocdb.conditions:invalid-argument (n::close-local-namespace nil))
    (rejects arcdocdb.conditions:invalid-argument (n::local-namespace-identity nil))
    (rejects arcdocdb.conditions:invalid-argument
      (n::connect-local-socket "/svc/run.sock" -1 :backend backend))
    (is (null (fixture-calls fixture)))))

(deftest test-REQ-IPC-003-native-openat-nofollow-fstat-and-lock-faults
  (dolist (spec (list (list :openat sb-posix:eloop '(0))
                      (list (list :fstat 0) sb-posix:eio '(0))
                      (list :lock sb-posix:ewouldblock '(0 1))))
    (destructuring-bind (operation errno expected-closed) spec
      (let ((fixture (make-scripted-fixture)))
        (setf (gethash operation (fixture-faults fixture)) errno)
        (let ((observed (rejects n::native-error
                          (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))))
          (is (= errno (arcdocdb.conditions:error-errno (n::native-error-primary observed)))))
        (is (equal expected-closed (fixture-closed fixture)))
        (is (zerop (fixture-call-count fixture :socket)))
        (is (zerop (fixture-call-count fixture :unlink)))))))

(deftest test-REQ-IPC-003-native-chmod-listen-errors-clean-owned-node
  (dolist (operation '(:chmod :listen))
    (let ((fixture (make-scripted-fixture)))
      (setf (gethash operation (fixture-faults fixture)) sb-posix:eio)
      (let ((observed (rejects n::native-error
                        (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))))
        (is (= sb-posix:eio (arcdocdb.conditions:error-errno (n::native-error-primary observed)))))
      (is (null (fixture-node fixture)))
      (is (= 1 (fixture-call-count fixture :unlink)))
      (is (equal '(0 1 2) (fixture-closed fixture))))))

(deftest test-REQ-IPC-003-native-bind-without-identity-keeps-orphan
  (let ((fixture (make-scripted-fixture
                  :hook (lambda (fixture operation arguments)
                          (declare (ignore arguments))
                          (when (eq operation :bind)
                            (setf (gethash (list :entry 1 "run.sock") (fixture-faults fixture))
                                  sb-posix:eio))))))
    (rejects n::native-error (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (fixture-node fixture))
    (is (zerop (fixture-call-count fixture :unlink)))
    (is (zerop (fixture-call-count fixture :listen)))
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-IPC-003-native-listener-open-error-keeps-borrowed-anchor
  (let* ((fixture (make-scripted-fixture)) (backend (fixture-backend fixture))
         (anchor (n::open-local-namespace "/svc/run.sock" :backend backend)))
    (setf (gethash :listen (fixture-faults fixture)) sb-posix:eio)
    (rejects n::native-error (n::open-local-listener "/svc/run.sock" :namespace anchor))
    (is (equal '(2) (fixture-closed fixture)))
    (is (not (n::local-namespace-closed-p anchor)))
    (is (null (fixture-node fixture)))
    (is (equal '(7 11) (multiple-value-list (n::local-namespace-identity anchor))))
    (n::close-local-namespace anchor)
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-IPC-003-native-replacement-during-listen-preserved
  (let* ((replacement (socket-node 99))
         (fixture (make-scripted-fixture
                   :hook (lambda (fixture operation arguments)
                           (declare (ignore arguments))
                           (when (eq operation :listen) (setf (fixture-node fixture) replacement))))))
    (rejects n::native-error (n::open-local-listener "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (eq replacement (fixture-node fixture)))
    (is (zerop (fixture-call-count fixture :unlink)))
    (is (equal '(0 1 2) (fixture-closed fixture)))))

(deftest test-REQ-AFF-004-native-close-eintr-single-attempt-and-invalid-metadata
  (let ((fixture (make-scripted-fixture)))
    (setf (gethash :close (fixture-faults fixture)) sb-posix:eintr)
    (let ((condition (n::native-close 0 :backend (fixture-backend fixture))))
      (is (typep condition 'n::native-error))
      (is (= sb-posix:eintr (arcdocdb.conditions:error-errno condition))))
    (is (= 1 (fixture-call-count fixture :close))))
  (let ((fixture (make-scripted-fixture)))
    (setf (fixture-runtime fixture) nil)
    (rejects n::native-error (n::open-local-namespace "/svc/run.sock" :backend (fixture-backend fixture)))
    (is (equal '(0 1) (fixture-closed fixture))))
  (let* ((primary (make-condition 'simple-error :format-control "FI READY"))
         (fixture (make-scripted-fixture)))
    (let ((condition (rejects n::native-error
                       (n::native-open-listener "/svc/run.sock" (lambda () (error primary))
                                               :backend (fixture-backend fixture)))))
      (is (eq primary (n::native-error-primary condition))))
    (is (null (fixture-calls fixture)))))

(defun run ()
  "Esegue solo su invocazione esplicita del runner dopo freeze/review; nessuna esecuzione al load."
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~S~%" (list :kind :local-native-tests :status :passed :tests (length *tests*)
                         :native-syscalls-executed nil :fault-injection t))
  t)
