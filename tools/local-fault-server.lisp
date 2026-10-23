;;;; C4: iniezione al confine pubblico del servizio; startup/recovery restano nel prodotto.
(require :asdf)
(require :sb-posix)
(handler-case
    (progn
      (asdf:load-asd (merge-pathnames "../arcdocdb.asd" *load-truename*))
      (let ((*standard-output* *error-output*)) (asdf:load-system "arcdocdb/local"))
      (let ((args (uiop:command-line-arguments)))
        (unless (<= 4 (length args) 7) (error "Argomenti FI non validi."))
        (multiple-value-bind (create version)
            (uiop:symbol-call :arcdocdb.local :server-cli-options (nthcdr 4 args))
          (uiop:symbol-call :arcdocdb.local :serve-local (first args)
            (uiop:symbol-call :arcdocdb.local :local-unhex (third args) 16 16)
            (uiop:symbol-call :arcdocdb.local :local-unhex (fourth args) 16 16)
            (second args) :create create :version version
            :observer (lambda (engine phase)
                        (declare (ignore engine))
                        (when (eq phase :after-commit)
                          (error (make-condition
                                  (find-symbol "IO-FAULT" "ARCDOCDB.CONDITIONS")
                                  :reason :local-after-commit :operation :test))) nil)
            :ready (lambda ()
                     (format t "~S~%" (list :kind :local-server :state :ready :pid (sb-posix:getpid)))
                     (finish-output) nil)))))
  (error (condition)
    (format *error-output* "~&LOCAL-FAULT-SERVER-FAIL ~A: ~A~%" (type-of condition) condition)
    (sb-ext:exit :code 1)))
