;;;; Harness Fase 0. Ogni esperimento gira in un processo nuovo, in serie.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-AFF-012
(require :asdf)
(require :sb-posix)
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
    ("SPK-04" . "spikes/SPK-04-writer-pool/run.lisp")
    ("SPK-07" . "spikes/SPK-07-protocols/run.lisp")
    ("SPK-09" . "spikes/SPK-09-integrity/run.lisp")
    ("SPK-10" . "spikes/SPK-10-v2-limits/run.lisp")))

(defun command-output (command)
  "Esegue un comando senza shell e restituisce il suo output senza spazi esterni."
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program command :output :string :error-output :string)))

(defun source-blobs (paths)
  "Identifica i file presenti; non inventa hash per un file assente."
  (loop for path in paths
        collect (list :path path :git-blob
                      (if (probe-file path)
                          (command-output (list "git" "hash-object" path)) :absent))))

(defun spike-sources (entry mode)
  "Dichiara i sorgenti caricati dal singolo processo, incluse le dipendenze locali."
  (append (list "tools/run-spikes.lisp" (cdr entry)
                (namestring (merge-pathnames "core.lisp" (cdr entry))))
          (when (string= (car entry) "SPK-04")
            '("spikes/SPK-04-writer-pool/pool.lisp" "spikes/SPK-04-writer-pool/parcheggi.lisp"))
          (when (string= (car entry) "SPK-07")
            '("spikes/SPK-07-protocols/pubblicazione.lisp"
              "spikes/SPK-07-protocols/scadenza.lisp"
              "spikes/SPK-07-protocols/compaction.lisp"
              "spikes/SPK-07-protocols/memoria.lisp"
              "spikes/SPK-07-protocols/suite.lisp"))
          (when (string= (car entry) "SPK-10")
            '("spikes/SPK-10-v2-limits/codec.lisp" "spikes/SPK-10-v2-limits/indice.lisp"
              "spikes/SPK-10-v2-limits/cbor.lisp" "spikes/SPK-10-v2-limits/migrazione.lisp"
              "spikes/SPK-09-integrity/core.lisp"))
          (when (and (string= (car entry) "SPK-01") (string= mode "--profile"))
            '("spikes/SPK-01-primary-index/profile.lisp"))))

(defun environment-report ()
  "Registra ambiente, revisione e modifiche locali; non deduce il carico della macchina."
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :cpu #+darwin (command-output '("sysctl" "-n" "machdep.cpu.brand_string"))
             #-darwin (machine-version)
        :memory-bytes #+darwin (parse-integer (command-output '("sysctl" "-n" "hw.memsize")))
                      #-darwin :not-collected
        :logical-cpus #+darwin (parse-integer (command-output '("sysctl" "-n" "hw.logicalcpu")))
                      #-darwin :not-collected
        :external-load-status :uncontrolled
        :load-average #+darwin (command-output '("sysctl" "-n" "vm.loadavg"))
                      #-darwin :not-collected
        :commit (command-output '("git" "rev-parse" "HEAD"))
        :working-tree (command-output '("git" "status" "--porcelain"))
        :source-blobs
        (loop for path in (append '("tools/run-spikes.lisp"
                                    "spikes/SPK-04-writer-pool/pool.lisp"
                                    "spikes/SPK-04-writer-pool/parcheggi.lisp"
                                    "spikes/SPK-07-protocols/pubblicazione.lisp"
                                    "spikes/SPK-07-protocols/scadenza.lisp"
                                    "spikes/SPK-07-protocols/compaction.lisp"
                                    "spikes/SPK-07-protocols/memoria.lisp"
                                    "spikes/SPK-07-protocols/suite.lisp"
                                    "spikes/SPK-01-primary-index/profile.lisp"
                                    "spikes/SPK-10-v2-limits/codec.lisp"
                                    "spikes/SPK-10-v2-limits/indice.lisp"
                                    "spikes/SPK-10-v2-limits/cbor.lisp"
                                    "spikes/SPK-10-v2-limits/migrazione.lisp")
                            (loop for entry in *spike-runners*
                                  append (list (cdr entry)
                                               (namestring (merge-pathnames "core.lisp"
                                                                            (cdr entry))))))
              collect (list :path path :git-blob
                            (if (probe-file path)
                                (command-output (list "git" "hash-object" path))
                                :absent)))
        :dynamic-space-mib 4096 :date-universal-time (get-universal-time)))

(defun new-report-directory (mode)
  "Crea il direttorio con mkdir esclusivo; nessun report esistente è sovrascritto."
  (ensure-directories-exist "spikes/out/")
  (loop for attempt below 1000
        for path = (merge-pathnames
                     (format nil "spikes/out/~D-~A-~D-~D/" (get-universal-time)
                             (subseq mode 2) (sb-posix:getpid) attempt)
                     (truename "./"))
        do (handler-case
               (progn (sb-posix:mkdir path #o700) (return-from new-report-directory path))
             (sb-posix:syscall-error (condition)
               (unless (= (sb-posix:syscall-errno condition) sb-posix:eexist)
                 (error condition)))))
  (fail-harness "Esauriti i tentativi di creazione del direttorio del report."))

(defun validate-output (stdout id mode &optional failed-process-p)
  "Accetta una sola plist di esito, letta senza read-eval; non accetta testo extra."
  (let ((*read-eval* nil) (eof (gensym "EOF")))
    (with-input-from-string (stream stdout)
      (let* ((result (read stream nil eof))
             (payload (and (listp result)
                           (or (getf result :benchmark) result)))
             (status (and (listp payload) (getf payload :status))))
        (unless (and (listp result) (not (eq result eof))
                     (eq (read stream nil eof) eof)
                     (or (member status '(:ok :pass :measured :unsupported :budget-exhausted))
                         (and failed-process-p (eq status :error))))
          (fail-harness "~A ~A: output strutturato non valido o esito fallito." id mode))
        (when (member status '(:unsupported :budget-exhausted))
          (format *error-output* "~&~A: campagna limitata, esito ~S.~%" id status))
        (values result status)))))

(defun save-report (report path)
  "Conserva il record anche prima della validazione o di un errore del processo."
  (with-open-file (stream path :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream))))

(defun run-spike (entry mode out child-options)
  "Esegue un processo isolato e conserva anche stdout/stderr quando il processo fallisce."
  (let* ((id (car entry))
         (start-time (get-universal-time))
         (start-ticks (get-internal-real-time))
         (sources (spike-sources entry mode))
         (before (source-blobs sources))
         (command (append (list (namestring sb-ext:*runtime-pathname*)
                        "--dynamic-space-size" "4096" "--noinform" "--no-userinit"
                        "--no-sysinit"
                        "--script" (cdr entry) mode) child-options)))
    (format *error-output* "~&~A ~A~%" id mode)
    (multiple-value-bind (stdout stderr status)
        (uiop:run-program command :output :string :error-output :string
                          :ignore-error-status t)
      (let* ((path (merge-pathnames (format nil "~A.lisp" id) out))
             (report (list :schema-version 1 :id id :command command :exit-code status
                           :started-at-universal-time start-time
                           :finished-at-universal-time (get-universal-time)
                           :wall-seconds (/ (- (get-internal-real-time) start-ticks)
                                            (coerce internal-time-units-per-second 'double-float))
                           :status (if (zerop status) :output-unvalidated :failed)
                           :source-blobs-before before
                           :source-blobs-after (source-blobs sources)
                           :source-consistency :unvalidated
                           :result nil :stdout stdout :stderr stderr)))
        (setf (getf report :source-consistency)
              (if (equal before (getf report :source-blobs-after)) :stable :changed))
        (save-report report path)
        (unless (zerop status)
          (handler-case
              (setf (getf report :result) (validate-output stdout id mode t))
            (error (condition) (setf (getf report :diagnostic) (princ-to-string condition))))
          (save-report report path)
          (fail-harness "~A fallito (exit ~D):~%~A~%~A" id status stdout stderr))
        (unless (eq (getf report :source-consistency) :stable)
          (setf (getf report :status) :source-changed)
          (save-report report path)
          (fail-harness "Sorgenti di ~A modificati durante il run: risultato non attribuibile." id))
        (handler-case
            (multiple-value-bind (result outcome) (validate-output stdout id mode)
              (setf (getf report :result) result (getf report :status) outcome)
              (save-report report path))
          (error (condition)
            (setf (getf report :status) :invalid-output
                  (getf report :diagnostic) (princ-to-string condition))
            (save-report report path)
            (error condition)))
        report))))

(defun main ()
  "Valida la selezione e lancia la campagna in serie, senza sovrapporre gli esperimenti."
  (let* ((args (uiop:command-line-arguments))
         (mode (or (first args) "--check"))
         (separator (position "--" args :test #'string=))
         (selected (if separator (subseq args 1 separator) (rest args)))
         (child-options (when separator (subseq args (1+ separator)))))
    (unless (member mode '("--check" "--bench" "--profile") :test #'string=)
      (fail-harness "Uso: --check|--bench ID... [-- opzioni] oppure --profile SPK-01"))
    (dolist (id selected)
      (unless (assoc id *spike-runners* :test #'string=)
        (fail-harness "Spike sconosciuto: ~A" id)))
    (when (and separator (or (not (string= mode "--bench"))
                            (/= 1 (length selected))))
      (fail-harness "Le opzioni dopo -- richiedono --bench e un solo spike selezionato."))
    (when (and (string= mode "--profile")
               (not (equal selected '("SPK-01"))))
      (fail-harness "Il profilo di allocazione richiede --profile SPK-01."))
    (let ((out (new-report-directory mode)))
      (let ((report (list :schema-version 1 :environment (environment-report)
                          :mode mode :status :running :runs nil
                          :run-artifacts (loop for entry in *spike-runners*
                            when (or (null selected) (member (car entry) selected :test #'string=))
                            collect (namestring (merge-pathnames
                                                 (format nil "~A.lisp" (car entry)) out))))))
        (save-report report (merge-pathnames "report.lisp" out))
        (handler-case
            (dolist (entry *spike-runners*)
              (when (or (null selected) (member (car entry) selected :test #'string=))
                (setf (getf report :runs)
                      (append (getf report :runs) (list (run-spike entry mode out child-options))))
                (save-report report (merge-pathnames "report.lisp" out))))
          (error (condition)
            (setf (getf report :status) :failed
                  (getf report :diagnostic) (princ-to-string condition))
            (save-report report (merge-pathnames "report.lisp" out))
            (error condition)))
        (setf (getf report :status) :complete)
        (save-report report (merge-pathnames "report.lisp" out))
        (format t "~&~D spike completati; risultati: ~A~%" (length (getf report :runs)) out)))))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
