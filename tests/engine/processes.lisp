;;;; Oracoli C4: solo API del motore nei figli, nessun checkpoint/replay/CSN costruito dal test.
(in-package #:arcdocdb.engine.tests)

(defun crash (phase)
  (format t "~&ENGINE-CRASH-READY ~S~%" phase) (finish-output)
  (sb-posix:kill (sb-posix:getpid) sb-posix:sigkill)
  (error "SIGKILL non eseguito."))

(defun child-main (arguments)
  (destructuring-bind (mode path format stage) arguments
    (let* ((root (uiop:ensure-directory-pathname path)) (version (parse-integer format))
           (phase (cond ((member stage '("plain" "tail") :test #'string=) nil)
                        ((string= stage "checkpoint-prepared") :checkpoint-prepared)
                        ((string= stage "checkpoint-published") :checkpoint-published)
                        (t (error "Stage sconosciuto."))))
           (originals (images root t)))
      (with-engine (engine (open-engine root :create (string= mode "write") :version version
                            :observer (lambda (engine step)
                                        (when (and (string= mode "recovery-crash") (eq phase step))
                                          (is (not (eq :ready (e:stato-motore engine)))) (crash step)) nil)))
        (cond ((string= mode "write")
               (initial-workload engine) (check-initial engine)
               (when (string= stage "tail")
                 ;; FI: solo 13 byte di una cornice senza SEAL, dopo cinque conferme strong.
                 (let ((buffer (bytes 128)) (append (arcdocdb.engine::motore-append engine)))
                   (arcdocdb.record:scrivi-record buffer 0 1 6 (key 1) (value 9) :version version)
                   (let ((end (+ 13 (arcdocdb.io:posizione-scritta append))))
                     (is (= end (arcdocdb.io:append-esatto append buffer 0 13)
                            (arcdocdb.io:durable-flush append))))))
               (crash :written))
              ((string= mode "resume")
               (check-initial engine) (check-segment-images root originals)
               (resumed-workload engine) (check-resumed engine) (crash :resumed))
              ((string= mode "verify") (check-resumed engine) (check-segment-images root originals))
              ((string= mode "verify-wrong") (check-frontier engine 8))
              (t (error "Mode inatteso o crash non avvenuto."))))
      (format t "~&ENGINE-VERIFIED v~D ~A~%" version mode))))

(defun child (root version mode stage signal code)
  (let* ((storage (merge-pathnames "storage/" root))
         (name (format nil "~A-~A" mode stage))
         (stdout (merge-pathnames (concatenate 'string name ".stdout") root))
         (stderr (merge-pathnames (concatenate 'string name ".stderr") root))
         (prepared (ensure-directories-exist (merge-pathnames ".parent" storage)))
         (process (sb-ext:run-program (namestring sb-ext:*runtime-pathname*)
                    (list "--noinform" "--no-userinit" "--no-sysinit" "--script"
                          (namestring (asdf:system-relative-pathname "arcdocdb" "tools/engine-crash.lisp"))
                          mode (namestring storage) (write-to-string version) stage)
                    :wait nil :output stdout :error stderr))
         (failure nil))
    (declare (ignore prepared))
    (unwind-protect
         (handler-case
             (progn
               (sb-ext:with-timeout 60 (sb-ext:process-wait process))
               (is (eq (sb-ext:process-status process) signal))
               (is (eql (sb-ext:process-exit-code process) code)))
           (error (condition) (setf failure condition)))
      (when (member (sb-ext:process-status process) '(:running :stopped))
        (sb-ext:process-kill process sb-posix:sigkill) (sb-ext:process-wait process))
      (let ((text (uiop:read-file-string stdout)) (errors (uiop:read-file-string stderr)))
        (write-string text) (write-string errors)
        (format t "~&~S~%" (list :kind :engine-child :mode mode :format version :stage stage
                                  :status (sb-ext:process-status process) :code (sb-ext:process-exit-code process)))
        (when (and (not failure) (eq signal :signaled)) (is (search "ENGINE-CRASH-READY" text)))
        (when (and (not failure) (string= mode "verify")) (is (search "ENGINE-VERIFIED" text)))
        (when (and (not failure) (string= mode "verify-wrong")) (is (search "ENGINE-ORACLE-MISMATCH" errors)))
        (finish-output))
      (sb-ext:process-close process))
    (when failure (error failure))))

;;; REQ: REQ-REC-001 REQ-WAL-006 REQ-MVC-006 REQ-AFF-018 REQ-IDX-001
(deftest test-REQ-REC-001-production-two-SIGKILL-restart-without-harness-v1-v2
  (dolist (version '(1 2))
    (dolist (stage '("plain" "tail" "checkpoint-prepared" "checkpoint-published"))
      (with-root (root)
        (child root version "write" stage :signaled sb-posix:sigkill)
        (unless (member stage '("plain" "tail") :test #'string=)
          (child root version "recovery-crash" stage :signaled sb-posix:sigkill))
        (child root version "resume" stage :signaled sb-posix:sigkill)
        (child root version "verify" stage :exited 0)))))

;;; REQ: REQ-VAL-001 REQ-AFF-012 REQ-MVC-006
(deftest test-REQ-VAL-001-production-independent-oracle-rejects-wrong-frontier
  (with-root (root)
    (child root 2 "write" "plain" :signaled sb-posix:sigkill)
    (child root 2 "resume" "plain" :signaled sb-posix:sigkill)
    (child root 2 "verify-wrong" "plain" :exited 1)))
