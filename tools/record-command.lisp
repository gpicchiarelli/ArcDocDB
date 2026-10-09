;;;; Registro C4 di un comando di verifica: argv, ambiente, sorgenti e output.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "finish-evidence.lisp" *load-truename*))
(declaim (optimize (safety 3) (debug 3)))

(define-condition recording-error (error)
  ((messaggio :initarg :messaggio :reader messaggio))
  (:report (lambda (c stream) (write-string (messaggio c) stream))))

(defun comando-output (argv)
  "Comando senza shell; nessuna valutazione degli argomenti."
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program argv :output :string :error-output :string)))

(defun sorgenti ()
  "Include sorgenti e documenti, anche non committed; esclude artefatti di prove."
  (let* ((paths (loop for path in (uiop:split-string
                                 (uiop:run-program '("git" "ls-files" "-z" "--cached" "--others"
                                                     "--exclude-standard") :output :string)
                                 :separator '(#\Null))
                      when (and (plusp (length path))
                                (not (uiop:string-prefix-p "spikes/results/" path))) collect path))
         (presenti (remove-if-not #'probe-file paths))
         ;; Un solo processo Git per lo snapshot, mantenendo l'ordine argv/output.
         (hashes (when presenti (uiop:split-string
                                 (comando-output (append '("git" "hash-object" "--") presenti))
                                 :separator '(#\Newline))))
         (tabella (make-hash-table :test 'equal)))
    (unless (= (length presenti) (length hashes))
      (error 'recording-error :messaggio "Hash dei sorgenti incompleti."))
    (loop for path in presenti for hash in hashes do (setf (gethash path tabella) hash))
    (loop for path in paths collect (list :path path :git-blob (gethash path tabella :absent)))))

(defun ambiente ()
  "Metadata osservati; il carico esterno non è controllato."
  (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
        :os (software-type) :os-version (software-version) :machine (machine-type)
        :cpu #+darwin (comando-output '("sysctl" "-n" "machdep.cpu.brand_string"))
             #-darwin (machine-version)
        :memory-bytes #+darwin (parse-integer (comando-output '("sysctl" "-n" "hw.memsize")))
                      #-darwin :not-collected
        :logical-cpus #+darwin (parse-integer (comando-output '("sysctl" "-n" "hw.logicalcpu")))
                      #-darwin :not-collected
        :external-load-status :uncontrolled
        :load-average #+darwin (comando-output '("sysctl" "-n" "vm.loadavg"))
                      #-darwin :not-collected
        :commit (comando-output '("git" "rev-parse" "HEAD"))
        :working-tree (comando-output '("git" "status" "--porcelain"))
        :cwd (namestring (truename "./"))
        :date-universal-time (get-universal-time)))

(defun nuovo-direttorio ()
  "mkdir esclusivo, numero limitato di tentativi; non sovrascrive prove."
  (ensure-directories-exist "spikes/out/")
  (loop for attempt below 1000
        for path = (merge-pathnames
                    (format nil "spikes/out/~D-command-~D-~D/" (get-universal-time)
                            (sb-posix:getpid) attempt) (truename "./"))
        do (handler-case
               (progn (sb-posix:mkdir path #o700) (return-from nuovo-direttorio path))
             (sb-posix:syscall-error (c)
               (unless (= (sb-posix:syscall-errno c) sb-posix:eexist) (error c)))))
  (error 'recording-error :messaggio "Impossibile creare il direttorio del registro."))

(defun salva (record path)
  "Lo stato iniziale e quello finale sono salvati nello stesso record esclusivo."
  (with-open-file (stream path :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write record :stream stream :pretty t) (terpri stream))))

(defun main ()
  "Uso: -- argv...; nessuna shell, interpretazione Lisp o inferenza di risultati."
  (let* ((args (uiop:command-line-arguments)) (argv (rest args)))
    (unless (and (equal (first args) "--") argv)
      (error 'recording-error :messaggio "Uso: sbcl --script tools/record-command.lisp -- make check"))
    (let* ((out (nuovo-direttorio)) (path (merge-pathnames "report.lisp" out))
           (before (sorgenti)) (ticks (get-internal-real-time))
           (record (list :schema-version 1 :kind :command-verification :environment (ambiente)
                         :command argv :status :running :started-at-universal-time (get-universal-time)
                         :source-blobs-before before :stdout nil :stderr nil :exit-code nil
                         :limits '(:command-output-is-raw :wall-time-includes-entire-command
                                   :no-automatic-requirement-promotion))))
      (salva record path)
      (handler-case
          (multiple-value-bind (stdout stderr code)
              (uiop:run-program argv :output :string :error-output :string :ignore-error-status t)
            (setf (getf record :stdout) stdout (getf record :stderr) stderr
                  (getf record :exit-code) code (getf record :status) (if (zerop code) :ok :failed)))
        (error (c) (setf (getf record :status) :failed (getf record :diagnostic) (princ-to-string c))))
      ;; Salva l'esito prima di raccogliere altri metadata, che possono fallire.
      (setf (getf record :finished-at-universal-time) (get-universal-time)
            (getf record :wall-seconds) (/ (- (get-internal-real-time) ticks)
                                          (coerce internal-time-units-per-second 'double-float)))
      (salva record path)
      (handler-case
          (let ((after (sorgenti)))
            (setf (getf record :source-blobs-after) after
                  (getf record :source-consistency) (if (equal before after) :stable :changed))
            (when (and (eq :ok (getf record :status)) (not (equal before after)))
              (setf (getf record :status) :source-changed)))
        (error (c) (setf (getf record :status) :failed (getf record :diagnostic) (princ-to-string c))))
      (salva record path)
      (unless (compact-finished-directory out)
        (sb-ext:exit :code 1))
      (format t "~&~S: ~{~A~^ ~}; record: ~A~%" (getf record :status) argv path)
      (unless (eq (getf record :status) :ok) (sb-ext:exit :code 1)))))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
