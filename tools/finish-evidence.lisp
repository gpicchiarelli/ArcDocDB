;;;; Compattazione fuori dalla finestra di misura, dopo l'ultima scrittura del run.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(defparameter *evidence-compactor*
  (namestring (merge-pathnames "compact-evidence.lisp" *load-truename*)))

(defun compact-finished-directory (directory)
  "Il chiamante possiede il run e ha terminato tutte le scritture ai suoi record."
  (let* ((argv (list (namestring sb-ext:*runtime-pathname*)
                     "--dynamic-space-size" "2048" "--noinform" "--no-userinit"
                     "--no-sysinit" "--script" *evidence-compactor*
                     "--root" (namestring directory) "--jobs" "4"
                     "--finished-owner-pid" (write-to-string (sb-posix:getpid))))
         (record (list :schema-version 1 :kind :evidence-finalization :command argv
                       :started-at-universal-time (get-universal-time)))
         (ok nil))
    (handler-case
        (multiple-value-bind (stdout stderr code)
            (uiop:run-program argv :output :string :error-output :string
                                   :ignore-error-status t)
          (setf ok (zerop code)
                (getf record :exit-code) code (getf record :stdout) stdout
                (getf record :stderr) stderr))
      (error (c) (setf (getf record :diagnostic) (princ-to-string c))))
    (setf (getf record :status) (if ok :ok :failed)
          (getf record :finished-at-universal-time) (get-universal-time))
    (with-open-file (stream (merge-pathnames "conservazione.lisp" directory)
                            :direction :output :if-exists :error
                            :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-readably* t)) (write record :stream stream :pretty t) (terpri stream)))
    (unless ok
      (format *error-output* "Compattazione fallita; originali e diagnostica conservati in ~A.~%"
              directory))
    ok))
