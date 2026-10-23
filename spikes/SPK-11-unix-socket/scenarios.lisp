;;;; Supervisione C4: ogni figlio raccolto, niente nuovo thread per connessione nel prodotto.
;;; REQ: REQ-VAL-001 REQ-IPC-001 REQ-IPC-002 REQ-IPC-003
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defun check-collision (path)
  "Bind fallito contro un nome esistente, con identita esatta preservata."
  (let ((before (node-identity path)) (socket (new-socket)))
    (unwind-protect
         (progn
           (demand before :collision-fixture)
           (expect-rejection :occupied (lambda () (bind-unoccupied socket path)))
           (demand (equal before (node-identity path)) :collision-replaced))
      (close-socket socket))))

(defun await-child (process until)
  "Supervisione limitata; al timeout SIGKILL e wait raccolgono sempre il figlio."
  (loop repeat 1500 while (sb-ext:process-alive-p process) do
    (when (>= (get-internal-real-time) until)
      (sb-ext:process-kill process sb-posix:sigkill)
      (sb-ext:process-wait process)
      (error 'rejection :reason :child-deadline))
    (sleep 0.01))
  (when (sb-ext:process-alive-p process)
    (sb-ext:process-kill process sb-posix:sigkill)
    (sb-ext:process-wait process)
    (error 'rejection :reason :child-bound))
  (sb-ext:process-wait process)
  (sb-ext:process-exit-code process))

(defun server-exchange (socket mode)
  "Oracoli sul contenuto e sul rifiuto; nessuna simulazione di commit o query."
  (let ((until (deadline)))
    (cond
      ((string= mode "native-server") (server-native-session socket until))
      ((string= mode "native-client") (server-session-exchange socket "session" until))
      ((string= mode "native-truncated") (server-native-truncated socket until))
      ((member mode '("session" "session-invalid-hello" "session-pre-hello"
                      "session-oversize-hello" "session-id-reuse") :test #'string=)
       (server-session-exchange socket mode until))
      ((member mode '("fragmented" "coalesced") :test #'string=)
       (let ((input (receive-count socket 2 (if (string= mode "fragmented") 1 64) until)))
         (same-frames input (list (ping 1) (ping 2)))
         (dolist (body input) (check-codec body))
         (send-bytes socket (concatenate '(simple-array (unsigned-byte 8) (*))
                                         (frame (ping 2 3)) (frame (ping 1 3))) 1 until)))
      ((string= mode "maximum")
       (let* ((actual (first (receive-count socket 1 65536 until)))
              (expected (maximum-body)) (key-start (1+ +document-limit+)))
         (same-frames (list actual) (list expected))
         (check-codec actual 1 key-start)
         (check-codec actual key-start (length actual))
         (send-bytes socket (frame (ping 1 3)) 10 until)))
      ((member mode '("zero" "oversize") :test #'string=)
       (expect-rejection :length (lambda () (receive-frames socket 0 4 until))))
      ((string= mode "truncated")
       (expect-rejection :truncated (lambda () (receive-frames socket 1 64 until))))
      (t (error 'rejection :reason :server-mode)))))

(defun run-exchange (base build directory mode)
  "Listener posseduto prima del figlio; registra argv, PID e stdout/stderr originali."
  (let* ((path (concatenate 'string directory "/ipc.sock")) (listener (new-socket))
         (identity nil) (peer nil) (process nil)
         (out (merge-pathnames (format nil "~A.stdout" mode) (pathname (concatenate 'string directory "/"))))
         (err (merge-pathnames (format nil "~A.stderr" mode) out))
         (args (list "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     (namestring (merge-pathnames "run.lisp" base)) "--client" path mode (namestring build)))
         (result nil) (failure nil) (observation nil))
    (unwind-protect
         (handler-case
             (progn
               (bind-unoccupied listener path)
               (sb-posix:chmod path #o600)
               (setf identity (node-identity path))
               (demand (= #o600 (logand #o777 (third identity))) :socket-mode)
               (sb-bsd-sockets:socket-listen listener 8)
               (check-collision path)
               (setf process (sb-ext:run-program (namestring sb-ext:*runtime-pathname*) args
                                               :input nil :output out :error err :wait nil))
               (wait-socket listener :input (deadline))
               (setf peer (sb-bsd-sockets:socket-accept listener))
               (demand peer :accept-interrupted)
               (setf (sb-bsd-sockets:non-blocking-mode peer) t)
               (setf observation (server-exchange peer mode))
               (close-socket peer)
               (demand (zerop (await-child process (deadline 15))) :child-exit)
               (setf result (list :status :ok :mode mode :server-pid (sb-posix:getpid)
                                  :client-pid (sb-ext:process-pid process) :argv args
                                  :exit-code (sb-ext:process-exit-code process) :observation observation
                                  :stdout (uiop:read-file-string out) :stderr (uiop:read-file-string err)))
               (demand (/= (getf result :server-pid) (getf result :client-pid)) :same-process))
           (error (condition) (setf failure condition)))
      (close-socket peer) (close-socket listener)
      (when process
        (when (sb-ext:process-alive-p process) (sb-ext:process-kill process sb-posix:sigkill))
        (sb-ext:process-wait process) (sb-ext:process-close process))
      (when identity (unlink-owned path identity)))
    (write (or result (list :status :failed :mode mode :argv args
                           :stdout (if (probe-file out) (uiop:read-file-string out) :absent)
                           :stderr (if (probe-file err) (uiop:read-file-string err) :absent)))
           :stream *error-output* :pretty t)
    (terpri *error-output*)
    (when failure
      (format *error-output* "~&SPK-11 ~A: ~A~%stdout: ~A~%stderr: ~A~%" mode failure
              (if (probe-file out) (uiop:read-file-string out) "assente")
              (if (probe-file err) (uiop:read-file-string err) "assente"))
      (error failure))
    result))

(defun native-symlink-probe (directory)
  "Diagnostica OS: bind grezzo su link pendente, confinato a target della directory privata."
  (let* ((path (concatenate 'string directory "/native-link"))
         (target (concatenate 'string directory "/native-target"))
         (socket (new-socket)))
    (unwind-protect
         (progn
           (sb-posix:symlink "native-target" path)
           (let ((outcome (handler-case (progn (sb-bsd-sockets:socket-bind socket path) :bound)
                            (sb-bsd-sockets:socket-error (condition) (princ-to-string condition)))))
             (list :bind-result outcome :link (node-identity path) :target (node-identity target))))
      (close-socket socket))))

(defun check-names (directory)
  "Orfano, file, link e sostituzione preservati; rimozione esplicita solo dei propri fixture."
  (let* ((path (concatenate 'string directory "/name.sock")) (socket (new-socket))
         (identity nil))
    (unwind-protect
         (progn
           (sb-bsd-sockets:socket-bind socket path)
           (setf identity (node-identity path))
           (close-socket socket)
           (check-collision path)
           (demand (unlink-owned path identity) :orphan-cleanup)
           (with-open-file (stream path :direction :output :if-exists :error) (write-string "preserva" stream))
           (check-collision path)
           (demand (null (unlink-owned path identity)) :replacement-deleted)
           (demand (string= "preserva" (uiop:read-file-string path)) :replacement-content)
           (sb-posix:unlink path)
           (sb-posix:symlink "missing-target" path)
           (check-collision path)
           (demand (string= "missing-target" (sb-posix:readlink path)) :symlink-target)
           (demand (null (node-identity (concatenate 'string directory "/missing-target"))) :symlink-followed)
           (sb-posix:unlink path)
           (list :status :ok :occupied-nodes '(:listener :orphan :file :symlink)
                 :replacement-preserved t))
      (close-socket socket))))

(defun check (base build)
  "Campagna locale finita; cleanup della sola directory esclusiva dopo join/chiusura."
  (let* ((directory (sb-posix:mkdtemp "/tmp/arcdocdb-spk11-XXXXXX"))
         (root (uiop:ensure-directory-pathname directory)))
    (unwind-protect
         (progn
           (demand (= #o700 (logand #o777 (sb-posix:stat-mode (sb-posix:stat directory)))) :directory-mode)
           (list :status :ok :spike :spk-11 :framing (check-framing) :session (check-session)
                 :native-io (check-native-io directory)
                 :processes (loop for mode in '("fragmented" "coalesced" "maximum" "zero" "oversize" "truncated"
                                               "session" "session-invalid-hello" "session-pre-hello"
                                               "session-oversize-hello" "session-id-reuse"
                                               "native-server" "native-client" "native-truncated")
                                  collect (run-exchange base build directory mode))
                 :namespace (check-names directory)
                 :native-symlink-bind (native-symlink-probe directory)
                 :limits '(:transport-and-control-model :no-engine-admission :no-durability
                           :no-distinct-uid :no-performance-measurement)))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :error))))
