;;;; Parent C4: deadline, SIGKILL verificato e output dei figli conservato nello stdout.
(in-package #:arcdocdb.vertical.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; Nessun valore globale: ogni RUN possiede il proprio binding e la propria lista.
(defvar *vertical-run-events*)
(defvar *vertical-scenario-id*)

(defun call-with-vertical-events (function)
  ;; Il catalogo CI chiama anche i singoli casi, senza passare da RUN.
  (if (boundp '*vertical-run-events*)
      (funcall function)
      (let ((*vertical-run-events* nil)) (funcall function))))

(defun vertical-event-count (kind)
  (count kind *vertical-run-events* :key (lambda (event) (getf event :event))))

(defun child (root version stage mode expected-status expected-code)
  (let* ((name (format nil "~A-~A" mode stage))
         (stdout (merge-pathnames (format nil "~A.stdout" name) root))
         (stderr (merge-pathnames (format nil "~A.stderr" name) root))
         (id (1+ (vertical-event-count :process)))
         (arguments (list "--noinform" "--no-userinit" "--no-sysinit" "--script"
                          (namestring (asdf:system-relative-pathname "arcdocdb" "tools/vertical-crash.lisp"))
                          mode (namestring root) (write-to-string version) (string-downcase stage)))
         (process nil) (status :not-started) (code nil)
         (text nil) (errors nil) (failure nil) (passed nil))
    (labels ((attempt (function)
               ;; Il primo errore resta la causa; nessun errore di cleanup salta i log.
               (handler-case (funcall function)
                 (serious-condition (condition)
                   (unless failure (setf failure condition))
                   nil))))
      (unwind-protect
           (attempt
            (lambda ()
              (setf process (sb-ext:run-program (first sb-ext:*posix-argv*) arguments
                                              :search t :wait nil :output stdout :error stderr))
              (sb-ext:with-timeout 60 (sb-ext:process-wait process))))
        (when process
          (attempt (lambda ()
                     (when (member (sb-ext:process-status process) '(:running :stopped))
                       (sb-ext:process-kill process sb-posix:sigkill))))
          (attempt (lambda ()
                     (sb-ext:with-timeout 5 (sb-ext:process-wait process))))
          (attempt (lambda ()
                     (setf status (sb-ext:process-status process)
                           code (sb-ext:process-exit-code process)))))
        ;; Un solo punto di lettura/emissione, anche dopo timeout o avvio fallito.
        (setf text (attempt (lambda () (uiop:read-file-string stdout)))
              errors (attempt (lambda () (uiop:read-file-string stderr))))
        (attempt (lambda ()
                   (format t "~&CHILD v~D ~A status=~S code=~S~%" version name status code)))
        (when text (attempt (lambda () (write-string text))))
        (when errors (attempt (lambda () (write-string errors))))
        (attempt (lambda () (finish-output)))
        (when process (attempt (lambda () (sb-ext:process-close process)))))
      (unless failure
        (attempt
         (lambda ()
           (when (string= mode "verify-wrong")
             (is (search "VERTICAL-ORACLE-MISMATCH" errors)))
           (when (string= mode "resume-wrong-csn")
             (is (search "VERTICAL-CSN-MISMATCH" errors))
             (is (search "REJECTED-CSN-BEFORE-APPEND" text)))
           (when (member mode '("recover-resumed" "verify-resumed") :test #'string=)
             (is (search "REVERIFIED" text)))
           (when (member mode '("write" "resume") :test #'string=)
             (is (search (format nil "CRASH-READY ~S"
                                 (cond ((string= mode "resume") :resumed)
                                       ((eq stage :prepared) :checkpoint-prepared)
                                       (t stage))) text)))
           (is (eq expected-status status))
           (is (= expected-code code))
           (setf passed t))))
      (push (list :event :process :id id :scenario *vertical-scenario-id*
                  :version version :stage stage :mode mode :status status :code code
                  :result (if passed :pass :fail))
            *vertical-run-events*)
      (when failure (error failure))
      t)))

(defun call-with-vertical-scenario (version stage kind negative function)
  (let ((*vertical-scenario-id* (1+ (vertical-event-count :scenario)))
        (root (arcdocdb.get.active.tests::active-fresh-root))
        (passed nil))
    (unwind-protect
         (progn
           (funcall function root)
           ;; I log sono già stati emessi e flushati da ogni CHILD.
           (uiop:delete-directory-tree root :validate t)
           (push (list :event :scenario :id *vertical-scenario-id* :kind kind
                       :version version :stage stage :negative (not (null negative)) :result :pass)
                 *vertical-run-events*)
           (setf passed t))
      (unless passed
        ;; Anche un errore di lettura/emissione lascia disponibili gli originali.
        (format *error-output* "~&VERTICAL-ROOT-RETAINED ~A~%" root)
        (finish-output *error-output*)))))

(defun scenario (version stage &optional negative)
  (call-with-vertical-scenario
   version stage :native negative
   (lambda (root)
     (child root version stage "write" :signaled sb-posix:sigkill)
     (child root version stage "recover" :exited 0)
     (child root version stage "verify" :exited 0)
     (when negative (child root version stage "verify-wrong" :exited 1)))))

;;; REQ: REQ-REC-001 REQ-WAL-006 REQ-IDX-001 REQ-STO-003 REQ-AFF-001 REQ-AFF-018
(defun test-REQ-REC-001-vertical-native-SIGKILL-reopen-v1-v2 ()
  (call-with-vertical-events
   (lambda ()
     (dolist (version '(1 2))
       (dolist (stage '(:committed :tail :prepared :rotated))
         (scenario version stage)
         (format t "~&VERTICAL v~D ~S PASS~%" version stage))))))

;;; REQ: REQ-VAL-001 REQ-AFF-012
(defun test-REQ-VAL-001-vertical-oracle-rejects-wrong-value ()
  (call-with-vertical-events (lambda () (scenario 2 :committed t))))

(defun resumed-scenario (version stage &optional negative)
  (call-with-vertical-scenario
   version stage :resumed negative
   (lambda (root)
     (child root version stage "write" :signaled sb-posix:sigkill)
     (child root version stage "recover" :exited 0)
     (if negative
         (child root version stage "resume-wrong-csn" :exited 1)
         (progn
           (child root version stage "resume" :signaled sb-posix:sigkill)
           (child root version stage "recover-resumed" :exited 0)
           (child root version stage "verify-resumed" :exited 0))))))

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-WAL-006 REQ-AFF-009 REQ-AFF-018
(defun test-REQ-REC-001-vertical-resume-writes-second-SIGKILL-v1-v2 ()
  (call-with-vertical-events
   (lambda ()
     (dolist (version '(1 2))
       (dolist (stage '(:committed :tail :prepared :rotated))
         (resumed-scenario version stage)
         (format t "~&VERTICAL-RESUME v~D ~S PASS~%" version stage))))))

;;; REQ: REQ-VAL-001 REQ-MVC-005 REQ-AFF-012
(defun test-REQ-VAL-001-vertical-oracle-rejects-reused-CSN ()
  (call-with-vertical-events (lambda () (resumed-scenario 2 :rotated t))))

(defun vertical-summary ()
  (let* ((events (reverse *vertical-run-events*))
         (scenarios (remove-if-not (lambda (event) (eq :scenario (getf event :event))) events))
         (processes (remove-if-not (lambda (event) (eq :process (getf event :event))) events))
         (negative-scenarios (count-if (lambda (event) (getf event :negative)) scenarios))
         (crashes (remove-if-not (lambda (event)
                                   (and (eq :signaled (getf event :status))
                                        (eql sb-posix:sigkill (getf event :code))))
                                 processes))
         (negatives (remove-if-not (lambda (event)
                                     (and (eq :exited (getf event :status))
                                          (eql 1 (getf event :code))
                                          (member (getf event :mode)
                                                  '("verify-wrong" "resume-wrong-csn")
                                                  :test #'string=)))
                                   processes)))
    ;; Conteggi degli eventi terminali verificati, non incrementi pianificati.
    (is (every (lambda (event) (eq :pass (getf event :result))) events))
    (is (= 18 (length scenarios)))
    (is (= 16 (- (length scenarios) negative-scenarios)))
    (is (= 2 negative-scenarios))
    (is (= 71 (length processes)))
    (is (= 26 (length crashes)))
    (is (= 2 (length negatives)))
    (list :vertical-summary :schema-version 1 :result :pass
          :counts (list :scenarios (length scenarios)
                        :positive-scenarios (- (length scenarios) negative-scenarios)
                        :processes (length processes) :crashes (length crashes)
                        :negatives (length negatives))
          :scenarios scenarios :processes processes
          :crashes (mapcar (lambda (event) (getf event :id)) crashes)
          :negatives (mapcar (lambda (event) (getf event :id)) negatives))))

(defun run ()
  (let ((*vertical-run-events* nil))
    (test-REQ-REC-001-vertical-native-SIGKILL-reopen-v1-v2)
    (format t "ok    test-REQ-REC-001-vertical-native-SIGKILL-reopen-v1-v2~%")
    (test-REQ-VAL-001-vertical-oracle-rejects-wrong-value)
    (format t "ok    test-REQ-VAL-001-vertical-oracle-rejects-wrong-value~%")
    (test-REQ-REC-001-vertical-resume-writes-second-SIGKILL-v1-v2)
    (format t "ok    test-REQ-REC-001-vertical-resume-writes-second-SIGKILL-v1-v2~%")
    (test-REQ-VAL-001-vertical-oracle-rejects-reused-CSN)
    (format t "ok    test-REQ-VAL-001-vertical-oracle-rejects-reused-CSN~%")
    (let ((summary (vertical-summary)))
      ;; Una sola forma leggibile, ordine di esecuzione, senza PID/path/tempi.
      (with-standard-io-syntax
        (write summary :stream *standard-output* :readably t :pretty nil)
        (terpri)
        (finish-output)))
    t))
