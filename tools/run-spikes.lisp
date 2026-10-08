;;;; Harness Fase 0. Ogni esperimento gira in un processo nuovo, in serie.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-AFF-012
(require :asdf)
(declaim (optimize (safety 3) (debug 3)))

(define-condition spike-harness-error (error)
  ((message :initarg :message :reader harness-message))
  (:report (lambda (condition stream) (write-string (harness-message condition) stream))))

(defun fail-harness (control &rest arguments)
  "Segnala un errore del confine CLI conservando il contesto utile alla diagnosi."
  (error 'spike-harness-error :message (apply #'format nil control arguments)))

(defparameter *spike-runners*
  '(("SPK-01" . "spikes/SPK-01-primary-index/run.lisp")
    ("SPK-02" . "spikes/SPK-02-gc/run.lisp")
    ("SPK-03" . "spikes/SPK-03-group-commit/run.lisp")
    ("SPK-07" . "spikes/SPK-07-protocols/run.lisp")
    ("SPK-09" . "spikes/SPK-09-integrity/run.lisp")))

(defun command-output (command)
  "Esegue un comando senza shell e restituisce il suo output senza spazi esterni."
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program command :output :string :error-output :string)))

(defun environment-report ()
  "Registra ambiente, revisione e modifiche locali; non deduce il carico della macchina."
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :cpu #+darwin (command-output '("sysctl" "-n" "machdep.cpu.brand_string"))
             #-darwin (machine-version)
        :memory-bytes #+darwin (parse-integer (command-output '("sysctl" "-n" "hw.memsize")))
                      #-darwin :not-collected
        :commit (command-output '("git" "rev-parse" "HEAD"))
        :working-tree (command-output '("git" "status" "--porcelain"))
        :source-blobs
        (loop for path in (cons "tools/run-spikes.lisp"
                            (loop for entry in *spike-runners*
                                  append (list (cdr entry)
                                               (namestring (merge-pathnames "core.lisp"
                                                                            (cdr entry))))))
              collect (list :path path :git-blob
                            (command-output (list "git" "hash-object" path))))
        :dynamic-space-mib 4096 :date-universal-time (get-universal-time)))

(defun validate-output (stdout id mode)
  "Accetta una sola plist di esito, letta senza read-eval; non accetta testo extra."
  (let ((*read-eval* nil) (eof (gensym "EOF")))
    (with-input-from-string (stream stdout)
      (let* ((result (read stream nil eof))
             (payload (and (listp result)
                           (or (getf result :benchmark) result)))
             (status (and (listp payload) (getf payload :status))))
        (unless (and (listp result) (not (eq result eof))
                     (eq (read stream nil eof) eof)
                     (member status '(:ok :pass :measured :unsupported :budget-exhausted)))
          (fail-harness "~A ~A: output strutturato non valido o esito fallito." id mode))
        (when (member status '(:unsupported :budget-exhausted))
          (format *error-output* "~&~A: campagna limitata, esito ~S.~%" id status))
        status))))

(defun run-spike (entry mode out)
  "Esegue un processo isolato e conserva anche stdout/stderr quando il processo fallisce."
  (let* ((id (car entry))
         (command (list (namestring sb-ext:*runtime-pathname*)
                        "--dynamic-space-size" "4096" "--noinform" "--no-userinit"
                        "--no-sysinit"
                        "--script" (cdr entry) mode)))
    (format *error-output* "~&~A ~A~%" id mode)
    (multiple-value-bind (stdout stderr status)
        (uiop:run-program command :output :string :error-output :string
                          :ignore-error-status t)
      (let ((report (list :id id :command command :exit-code status
                          :stdout stdout :stderr stderr)))
        (with-open-file (stream (merge-pathnames (format nil "~A.lisp" id) out)
                                :direction :output :if-exists :supersede)
          (write report :stream stream :pretty t) (terpri stream))
        (unless (zerop status)
          (fail-harness "~A fallito (exit ~D):~%~A~%~A" id status stdout stderr))
        (validate-output stdout id mode)
        report))))

(defun main ()
  "Valida la selezione e lancia la campagna in serie, senza sovrapporre gli esperimenti."
  (let* ((args (uiop:command-line-arguments))
         (mode (or (first args) "--check"))
         (selected (rest args)))
    (unless (member mode '("--check" "--bench") :test #'string=)
      (fail-harness "Uso: --check|--bench [SPK-01 SPK-02 SPK-03 SPK-07 SPK-09]"))
    (dolist (id selected)
      (unless (assoc id *spike-runners* :test #'string=)
        (fail-harness "Spike sconosciuto: ~A" id)))
    (let ((out (merge-pathnames (format nil "spikes/out/~D-~A/"
                                       (get-universal-time) (subseq mode 2))
                                (truename "./"))))
      (ensure-directories-exist (merge-pathnames "report.lisp" out))
      (let ((report (list :environment (environment-report)
                          :mode mode
                          :runs (loop for entry in *spike-runners*
                                      when (or (null selected)
                                               (member (car entry) selected :test #'string=))
                                      collect (run-spike entry mode out)))))
        (with-open-file (stream (merge-pathnames "report.lisp" out)
                                :direction :output :if-exists :supersede)
          (write report :stream stream :pretty t) (terpri stream))
        (format t "~&~D spike completati; risultati: ~A~%" (length (getf report :runs)) out)))))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
