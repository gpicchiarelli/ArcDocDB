;;;; Conservazione gzip senza perdita; file indipendenti compattati in parallelo.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(declaim (optimize (safety 3) (debug 3)))

(defun compact-one (path)
  "Pubblica il descriptor solo dopo la verifica dei byte originali e compatti."
  (let* ((source (namestring path))
         (payload (concatenate 'string source ".gz"))
         (lock (concatenate 'string source ".compact-lock"))
         (temporary (concatenate 'string source ".compact-descriptor"))
         (owned-lock nil) (owned-payload nil) (owned-temporary nil) (published nil))
    (unwind-protect
         (progn
           (with-open-file (stream lock :direction :output :if-exists :error
                                       :if-does-not-exist :create)
             (setf owned-lock t)
             (write (list :pid (sb-posix:getpid)) :stream stream))
           (let ((bytes (arcdocdb.evidence:file-bytes path))
                 (hash (arcdocdb.evidence:file-sha256 path)))
             ;; Creazione esclusiva: nessun payload o descriptor preesistente viene perso.
             (with-open-file (stream payload :element-type '(unsigned-byte 8)
                                            :direction :output :if-exists :error
                                            :if-does-not-exist :create)
               (setf owned-payload t)
               (uiop:run-program (list "gzip" "-n" "-9" "-c" "--" source)
                                 :output stream :error-output :string))
             (let* ((descriptor
                      (list :schema-version 1 :kind :compressed-evidence :codec :gzip
                            :payload (file-namestring payload)
                            :uncompressed-bytes bytes :uncompressed-sha256 hash
                            :compressed-bytes (arcdocdb.evidence:file-bytes payload)
                            :compressed-sha256 (arcdocdb.evidence:file-sha256 payload))))
               (with-open-file (stream temporary :direction :output :if-exists :error
                                                 :if-does-not-exist :create
                                                 :external-format :utf-8)
                 (setf owned-temporary t)
                 (let ((*print-readably* t))
                   (write descriptor :stream stream :pretty t) (terpri stream)))
               (arcdocdb.evidence:call-with-evidence-bytes
                temporary
                (lambda (expanded)
                  (unless (and (= bytes (arcdocdb.evidence:file-bytes expanded))
                               (string= hash (arcdocdb.evidence:file-sha256 expanded)))
                    (error "I byte ricostruiti non coincidono: ~A." source))))
               (unless (and (= bytes (arcdocdb.evidence:file-bytes path))
                            (string= hash (arcdocdb.evidence:file-sha256 path)))
                 (error "Il registro è cambiato durante la compattazione: ~A." source))
               ;; rename nella medesima directory: i lettori vedono originale o descriptor completo.
               (sb-posix:rename temporary source)
               (setf published t)
               (list :path source :status :ok :original-bytes bytes
                     :stored-bytes (+ (arcdocdb.evidence:file-bytes path)
                                      (getf descriptor :compressed-bytes))
                     :descriptor descriptor))))
      (when (and owned-temporary (probe-file temporary)) (delete-file temporary))
      (when (and owned-payload (not published) (probe-file payload)) (delete-file payload))
      (when (and owned-lock (probe-file lock)) (delete-file lock)))))

(defun active-run-p (path)
  "Non tocca directory del registratore il cui PID esiste ancora."
  (let* ((directory (car (last (pathname-directory path))))
         (parts (and (stringp directory) (uiop:split-string directory :separator '(#\-)))))
    (when (and (= (length parts) 4)
               (member (second parts) '("command" "check" "bench" "profile") :test #'string=))
      (let ((pid (ignore-errors (parse-integer (third parts)))))
        (when (and pid (plusp pid))
          (handler-case (progn (sb-posix:kill pid 0) t)
            (sb-posix:syscall-error (c)
              ;; In dubbio non compatta; ESRCH è l'unico caso di PID assente.
              (/= (sb-posix:syscall-errno c) sb-posix:esrch))))))))

(defun candidates (root minimum-age &optional finished-owner)
  "Solo file .lisp grandi; il limite di età protegge le campagne recenti."
  (let ((paths nil) (now (get-universal-time)))
    (labels ((walk (directory)
               (dolist (path (uiop:directory-files directory))
                 (when (and (equal (pathname-type path) "lisp")
                            (> (arcdocdb.evidence:file-bytes path) (* 1024 1024))
                            (>= (- now (file-write-date path)) minimum-age)
                            (or (and finished-owner
                                     (eql finished-owner
                                          (ignore-errors
                                            (parse-integer
                                             (third (uiop:split-string
                                                     (car (last (pathname-directory path)))
                                                     :separator '(#\-)))))))
                                (not (active-run-p path))))
                   (push path paths)))
               (dolist (directory (uiop:subdirectories directory)) (walk directory))))
      (walk root))
    (sort paths #'string< :key #'namestring)))

(defun compact-many (paths jobs)
  "Coda corta protetta; gzip e verifica di ogni file restano indipendenti."
  (let* ((queue (copy-list paths)) (mutex (sb-thread:make-mutex :name "evidence queue"))
         (results nil) (threads nil))
    (labels ((worker ()
               (loop for path = (sb-thread:with-mutex (mutex) (pop queue))
                     while path
                     for result = (handler-case (compact-one path)
                                    (error (c) (list :path (namestring path) :status :failed
                                                     :diagnostic (princ-to-string c))))
                     do (sb-thread:with-mutex (mutex) (push result results)))))
      (unwind-protect
           (progn
             (dotimes (i (min jobs (length paths)))
               (push (sb-thread:make-thread #'worker :name "evidence compressor") threads))
             (dolist (thread threads) (sb-thread:join-thread thread)))
        ;; Se la creazione di un worker fallisce, gli altri terminano prima di restituire.
        (dolist (thread threads)
          (when (sb-thread:thread-alive-p thread) (sb-thread:join-thread thread)))))
    (sort results #'string< :key (lambda (r) (getf r :path)))))

(defun main ()
  (let ((root "spikes/results/") (jobs 4) (minimum-age 0) (finished-owner nil)
        (args (uiop:command-line-arguments)))
    (loop while args for option = (pop args) for value = (pop args)
          do (unless value (error "Valore mancante per ~A." option))
             (cond ((string= option "--root") (setf root value))
                   ((string= option "--jobs") (setf jobs (parse-integer value)))
                   ((string= option "--minimum-age-seconds")
                    (setf minimum-age (parse-integer value)))
                   ((string= option "--finished-owner-pid")
                    (setf finished-owner (parse-integer value)))
                   (t (error "Opzione sconosciuta: ~A." option))))
    (unless (and (typep jobs '(integer 1 8)) (typep minimum-age '(integer 0))
                 (or (null finished-owner)
                     (and (typep finished-owner '(integer 1))
                          (eql finished-owner (sb-posix:getppid)))))
      (error "Workers: 1..8; età minima: secondi non negativi."))
    (let* ((root (uiop:ensure-directory-pathname (truename root)))
           (paths (candidates root minimum-age finished-owner))
           (ticks (get-internal-real-time))
           (results (compact-many paths jobs))
           (ok (every (lambda (r) (eq (getf r :status) :ok)) results)))
      (let ((*print-readably* t))
        (write (list :schema-version 1 :kind :evidence-compaction
                     :status (if ok :ok :failed) :root (namestring root) :jobs jobs
                     :minimum-age-seconds minimum-age :files (length results)
                     :wall-seconds (/ (- (get-internal-real-time) ticks)
                                      (coerce internal-time-units-per-second 'double-float))
                     :clock-units-per-second internal-time-units-per-second
                     :original-bytes (loop for r in results sum (getf r :original-bytes 0))
                     :stored-bytes (loop for r in results sum (getf r :stored-bytes 0))
                     :results results
                     :limits '(:lossless-byte-verification :no-git-history-rewrite
                               :requires-immutable-input-files :no-power-loss-durability-claim))
               :pretty t)
        (terpri))
      (unless ok (sb-ext:exit :code 1)))))

(main)
