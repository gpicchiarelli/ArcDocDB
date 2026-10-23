;;;; Verifica C4 dei cataloghi; dati soltanto, processi isolati e riduzione ordinata.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(declaim (optimize (safety 3) (debug 3)))

(defpackage #:arcdocdb.evidence.check
  (:use #:cl) (:export #:verifica-evidenze))
(in-package #:arcdocdb.evidence.check)

(defparameter *checker-source* *load-truename*)
(defvar *worker-command-hook* nil)
(defvar *process-scan-serial* 0)
(defvar *process-scan-command* '("ps" "-axo" "pid="))

(define-condition invalid-evidence (error)
  ((path :initarg :path :reader evidence-path)
   (detail :initarg :detail :initform nil :reader evidence-detail))
  (:report (lambda (c stream)
             (format stream "Evidenza non valida: ~A.~@[ ~A~]"
                     (evidence-path c) (evidence-detail c)))))

(define-condition invalid-process-snapshot (simple-error) ())

(defun snapshot-invalido (control &rest arguments)
  (error 'invalid-process-snapshot :format-control control :format-arguments arguments))

(defun leggi-dati (path)
  "Una sola plist; read-eval disabilitato, nessun load del record."
  (arcdocdb.evidence:read-evidence path))

(defun verifica-dimensioni (base)
  "Rifiuta registri enormi anche se non catalogati, prima di avviare worker."
  (let ((count 0) (bytes 0))
    (labels ((walk (directory)
               (dolist (path (uiop:directory-files directory))
                 (let* ((size (arcdocdb.evidence:file-bytes path))
                        (compressed (equal (pathname-type path) "gz"))
                        (limit (if compressed (* 8 1024 1024) (* 1024 1024))))
                   (when (> size limit)
                     (error "Artefatto ~A: ~D byte, limite ~D. Eseguire make compact-evidence."
                            path size limit))
                   (incf count) (incf bytes size)))
               (dolist (subdirectory (uiop:subdirectories directory)) (walk subdirectory))))
      (walk base))
    (values count bytes)))

(defun artefatto (nome base)
  "Il catalogo può riferire solo nomi di file nella propria directory datata."
  (unless (and (stringp nome) (plusp (length nome))
               (not (find #\/ nome)) (not (find #\\ nome))
               (not (member nome '("." "..") :test #'string=)))
    (error 'invalid-evidence :path nome))
  (merge-pathnames nome base))

(defun verifica-catalogo (path)
  "Stesso ordine storico: catalogo, entry, artifact/original/process-artifact."
  (let* ((data (leggi-dati path)) (base (uiop:pathname-directory-pathname path)) (record 0))
    (unless (and (eql 1 (getf data :schema-version))
                 (eq :evidence-catalog (getf data :kind)) (getf data :entries))
      (error 'invalid-evidence :path path))
    (dolist (entry (getf data :entries))
      (unless (getf entry :artifact) (error 'invalid-evidence :path path))
      (dolist (key '(:artifact :original :process-artifact))
        (when (getf entry key)
          (let* ((target (artefatto (getf entry key) base)) (r (leggi-dati target)))
            (when (and (eq key :artifact)
                       (not (eql 1 (or (getf r :schema-version) (getf r :schema)))))
              (error 'invalid-evidence :path target))
            (incf record)))))
    record))

(defun nuova-root-worker ()
  "Log e temporanei esclusivi, conservati anche in caso di fallimento."
  (let ((parent (merge-pathnames "../spikes/out/"
                                (uiop:pathname-directory-pathname *checker-source*))))
    (ensure-directories-exist parent)
    (uiop:ensure-directory-pathname
     (sb-posix:mkdtemp (namestring (merge-pathnames "evidence-check-XXXXXX" parent))))))

(defun avvia-worker (path index logs seconds heap)
  (let* ((directory (merge-pathnames (format nil "~D/" index) logs))
         (stdout (merge-pathnames "stdout.lisp" directory))
         (stderr (merge-pathnames "stderr.log" directory))
         (argv (list (namestring sb-ext:*runtime-pathname*) "--dynamic-space-size" (write-to-string heap)
                     "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     (namestring *checker-source*) "--catalog" (namestring path)
                     "--temporary-directory" (namestring directory))))
    (ensure-directories-exist stdout)
    (when *worker-command-hook* (setf argv (funcall *worker-command-hook* path argv)))
    (let ((process (uiop:launch-program argv :output stdout :error-output stderr
                                       :if-output-exists :error :if-error-output-exists :error
                                       :force-shell nil)))
      (list :index index :path path :process process :stdout stdout :stderr stderr :directory directory
            :deadline (+ (get-internal-real-time) (* seconds internal-time-units-per-second))))))

(defun inizializza-sessione-worker (temporary)
  "Sessione privata: RUN-PROGRAM può separare il gruppo delle utility, non la sessione."
  (when (= (sb-posix:getpgrp) (sb-posix:getpid))
    (sb-posix:setpgid 0 (sb-posix:getpgid (sb-posix:getppid))))
  (sb-posix:setsid)
  (unless (= (sb-posix:getsid 0) (sb-posix:getpid))
    (error "Il worker non possiede una sessione privata."))
  (let ((pending (merge-pathnames "session.pid.pending" temporary))
        (marker (merge-pathnames "session.pid" temporary)))
    (with-open-file (out pending :direction :output :if-exists :error)
      (format out "~D~%" (sb-posix:getpid)))
    (sb-posix:rename pending marker)))

(defun sessione-worker-p (worker pid)
  (let ((marker (merge-pathnames "session.pid" (getf worker :directory))))
    (when (probe-file marker)
      (with-open-file (stream marker)
        (unless (<= (file-length stream) 32) (error "Marker sessione non valido: ~A." marker))
        (let ((text (string-trim '(#\Space #\Newline #\Return) (read-line stream nil ""))))
          (unless (and (plusp (length text)) (every #'digit-char-p text)
                       (= pid (parse-integer text)) (null (read-line stream nil nil)))
            (error "Marker sessione non valido: ~A." marker))))
      t)))

(defun acquisisci-pid (logs)
  "Snapshot PS concluso con exit zero; stdout, stderr e stato restano conservati."
  (let* ((serial (incf *process-scan-serial*))
         (stdout (merge-pathnames (format nil "scan-~D.stdout.log" serial) logs))
         (stderr (merge-pathnames (format nil "scan-~D.stderr.log" serial) logs))
         (metadata (merge-pathnames (format nil "scan-~D.lisp" serial) logs))
         (process nil))
    (unwind-protect
         (progn
           (setf process (uiop:launch-program *process-scan-command* :output stdout :error-output stderr
                                            :if-output-exists :error :if-error-output-exists :error))
           (multiple-value-bind (exit signal) (uiop:wait-process process)
             (with-open-file (out metadata :direction :output :if-exists :error)
               (write (list :schema-version 1 :kind :process-snapshot :command *process-scan-command*
                            :exit-code exit :signal signal :stdout (namestring stdout) :stderr (namestring stderr))
                      :stream out))
             (unless (and (eql 0 exit) (null signal)
                          (zerop (arcdocdb.evidence:file-bytes stderr)))
               (snapshot-invalido "Enumera PID: ps exit ~S signal ~S. Log: ~A e ~A." exit signal stdout stderr)))
           (with-open-file (input stdout)
             (let ((pids (loop for line = (read-line input nil nil) while line
                               collect (handler-case (parse-integer line)
                                         (parse-error ()
                                           (snapshot-invalido "Enumera PID: riga non numerica. Log: ~A." stdout))))))
               (unless (and (every (lambda (pid) (plusp pid)) pids)
                            (member (sb-posix:getpid) pids))
                 (snapshot-invalido "Enumera PID: snapshot incompleto. Log: ~A." stdout))
               pids)))
      (when process
        (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t))
        (sb-ext:with-timeout 1 (uiop:wait-process process))
        (uiop:close-streams process)))))

(defun processi-sessione (session logs)
  "Tre tentativi bounded; uno snapshot incompleto non prova mai l'assenza di membri."
  (let ((pids nil) (failures nil) (complete nil))
    (dotimes (attempt 3)
      (handler-case
          (progn (setf pids (acquisisci-pid logs) complete t) (return))
        (invalid-process-snapshot (c) (push (princ-to-string c) failures))))
    (unless complete (error "Enumera PID: nessuno snapshot completo: ~{~A~^; ~}." (nreverse failures)))
    (loop for pid in pids
          when (handler-case (= session (sb-posix:getsid pid))
                 (sb-posix:syscall-error (c)
                   (unless (member (sb-posix:syscall-errno c) (list sb-posix:esrch sb-posix:eperm)) (error c))
                   nil))
            collect pid)))

(defun uccidi-pid (pid)
  (handler-case (sb-posix:kill pid sb-posix:sigkill)
    (sb-posix:syscall-error (c)
      (unless (= (sb-posix:syscall-errno c) sb-posix:esrch) (error c)))))

(defun termina-worker (worker)
  "Termina la sessione posseduta anche con leader morto; raccolta entro cinque secondi."
  (let* ((process (getf worker :process)) (pid (uiop:process-info-pid process)))
    (unwind-protect
         (sb-ext:with-timeout 5
           ;; Ferma e raccoglie il leader prima di consultare il marker: non può
           ;; pubblicarlo e avviare una utility dopo la nostra osservazione.
           (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t))
           (uiop:wait-process process)
           (if (sessione-worker-p worker pid)
               (loop for members = (processi-sessione pid (getf worker :directory)) while members
                     do (dolist (member (remove pid members)) (uccidi-pid member))
                        (when (member pid members) (uccidi-pid pid))
                        (sleep 0.01))
               nil))
      (uiop:close-streams process))))

(defun leggi-protocollo-worker (path)
  "Protocollo plain di 64 KiB: niente descriptor, valutazione, coda o chiavi duplicate."
  (with-open-file (stream path :external-format :utf-8)
    (when (> (file-length stream) 65536)
      (error "Output worker oltre 65536 byte: ~A." path))
    (let* ((*read-eval* nil) (*readtable* (copy-readtable nil)) (eof (gensym "EOF"))
           (unused (set-macro-character
                    #\# (lambda (input char)
                          (declare (ignore input char))
                          (error "Dispatch reader vietato nel protocollo worker."))
                    nil *readtable*))
           (data (read stream nil eof)) (length (and (listp data) (list-length data))))
      (declare (ignore unused))
      (unless (and length (= length 10) (eq eof (read stream nil eof))
                   (loop for (key value) on data by #'cddr
                         always (and (keywordp key)
                                     (member key '(:schema-version :kind :catalog :status
                                                   :artifact-references :diagnostic))))
                   (= 5 (length (remove-duplicates
                                 (loop for (key value) on data by #'cddr collect key)))))
        (error "Protocollo worker plain non valido: ~A." path))
      data)))

(defun risultato-worker (worker)
  "Accetta solo un risultato dati coerente con catalogo ed exit del processo."
  (let* ((path (getf worker :path)) (process (getf worker :process))
         (exit (uiop:wait-process process)))
    (let ((data (leggi-protocollo-worker (getf worker :stdout))))
    (unless (and (eql 1 (getf data :schema-version))
                 (eq :evidence-catalog-check (getf data :kind))
                 (equal (namestring path) (getf data :catalog))
                 (or (and (eql 0 exit) (eq :ok (getf data :status))
                          (typep (getf data :artifact-references) '(integer 0)))
                     (and (eql 1 exit) (eq :failed (getf data :status))
                          (stringp (getf data :diagnostic)))))
      (error 'invalid-evidence :path path :detail "Protocollo worker o codice di uscita non valido."))
      data)))

(defun fallimento-worker (worker detail)
  (list :status :failed :catalog (namestring (getf worker :path))
        :diagnostic (format nil "~A Log: ~A e ~A."
                            detail (getf worker :stdout) (getf worker :stderr))))

(defun chiudi-workers (workers logs)
  "Prova ogni cleanup anche dopo un timeout; nessuna condizione grave è assorbita."
  (let ((errors nil))
    (dolist (worker workers)
      (handler-case (termina-worker worker)
        (serious-condition (c) (push (princ-to-string c) errors))))
    (when errors (error "Cleanup worker fallito: ~{~A~^; ~}. Log: ~A." (nreverse errors) logs))))

(defun verifica-parallela (paths jobs seconds heap)
  "Finestra di processi limitata; nessuna stampa concorrente, riduzione per indice."
  (let* ((logs (nuova-root-worker)) (results (make-array (length paths) :initial-element nil))
         (cursor 0) (active nil) (count (length paths)))
    (unwind-protect
         (loop while (or (< cursor count) active)
               do (loop while (and (< cursor count) (< (length active) jobs))
                        do (handler-case
                               (push (avvia-worker (aref paths cursor) cursor logs seconds heap) active)
                             (error (c)
                               (setf (aref results cursor)
                                     (list :status :failed :diagnostic (princ-to-string c)))))
                           (incf cursor))
                  (dolist (worker (copy-list active))
                    (let* ((process (getf worker :process))
                           (alive (uiop:process-alive-p process))
                           (timeout (and alive (>= (get-internal-real-time) (getf worker :deadline)))))
                      (when (or (not alive) timeout)
                        ;; Un cleanup fallito deve lasciare il worker in ACTIVE:
                        ;; l'unwind esterno riprova e non dichiara mai successo.
                        (when timeout (termina-worker worker))
                        (setf (aref results (getf worker :index))
                              (handler-case
                                  (if timeout
                                      (fallimento-worker worker "Timeout worker.")
                                      (risultato-worker worker))
                                (error (c) (fallimento-worker worker (princ-to-string c)))))
                        (unless timeout (termina-worker worker))
                        (setf active (delete worker active :test #'eq)))))
                  (when active (sleep 0.01)))
      (chiudi-workers active logs))
    (loop for result across results for path across paths
          unless (eq :ok (getf result :status))
            do (error 'invalid-evidence :path path :detail (getf result :diagnostic)))
    (values (loop for result across results sum (getf result :artifact-references)) logs)))

(defun verifica-evidenze (root &key (jobs 4) (worker-seconds 300) (worker-heap-mib 2048))
  "Controlla prima tutte le dimensioni, poi i cataloghi nell'ordine DIRECTORY.
JOBS=1 usa il percorso seriale; JOBS=2..4 assegna un heap distinto a ogni catalogo.
La directory di input deve restare immutata per tutta la verifica."
  (unless (and (typep jobs '(integer 1 4)) (typep worker-seconds '(integer 1 86400))
               (typep worker-heap-mib '(integer 128 65536)))
    (error 'invalid-evidence :path root :detail "Budget worker non valido."))
  (let ((base (uiop:ensure-directory-pathname (truename root))))
    (multiple-value-bind (files bytes) (verifica-dimensioni base)
      (let ((paths (coerce (directory (merge-pathnames "*/catalogo.lisp" base)) 'vector)))
      (when (zerop (length paths)) (error 'invalid-evidence :path "Nessun catalogo."))
      (multiple-value-bind (record logs)
          (if (= jobs 1) (values (loop for path across paths sum (verifica-catalogo path)) nil)
              (verifica-parallela paths jobs worker-seconds worker-heap-mib))
        (list :status :ok :catalogs (length paths) :artifact-references record
              :stored-files files :stored-bytes bytes :worker-logs (and logs (namestring logs))
              :limits '(:structure-presence-size-and-compressed-integrity
                        :no-result-reinterpretation)))))))

(defun catalog-worker (path temporary)
  "Le utility storage appartengono alla sessione privata terminabile dal parent."
  (inizializza-sessione-worker temporary)
  (setf (uiop:getenv "TMPDIR") temporary)
  (let ((result (handler-case
                    (list :status :ok :artifact-references (verifica-catalogo path))
                  (error (c) (list :status :failed :diagnostic (princ-to-string c))))))
    (write (append (list :schema-version 1 :kind :evidence-catalog-check :catalog path) result))
    (terpri)
    (unless (eq :ok (getf result :status)) (sb-ext:exit :code 1))))

(defun intero-cli (text)
  (unless (and text (plusp (length text)) (every #'digit-char-p text))
    (error "Argomento numerico non valido: ~S." text))
  (parse-integer text))

(defun main ()
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond
          ((equal (first args) "--catalog")
           (unless (and (= 4 (length args)) (equal (third args) "--temporary-directory"))
             (error "Argomenti worker non validi."))
           (catalog-worker (second args) (fourth args)))
          ((equal (first args) "--self-test")
           (unless (<= (length args) 2) (error "Uso: --self-test [directory]."))
           (load (merge-pathnames "check-evidence-parallel-tests.lisp" *checker-source*))
           (funcall (symbol-function (find-symbol "SELF-TEST" "ARCDOCDB.EVIDENCE.CHECK")) (second args)))
          (t
           (let ((root (merge-pathnames "../spikes/results/"
                                       (uiop:pathname-directory-pathname *checker-source*)))
                 (jobs 4) (seconds 300) (heap 2048))
             (loop while args for key = (pop args) for value = (pop args)
                   do (unless value (error "Valore mancante per ~A." key))
                      (cond ((equal key "--root") (setf root value))
                            ((equal key "--jobs") (setf jobs (intero-cli value)))
                            ((equal key "--worker-seconds") (setf seconds (intero-cli value)))
                            ((equal key "--worker-heap-mib") (setf heap (intero-cli value)))
                            (t (error "Opzione non valida: ~A." key))))
             (write (verifica-evidenze root :jobs jobs :worker-seconds seconds :worker-heap-mib heap))
             (terpri)))))
    (serious-condition (c)
      (format *error-output* "~&Verifica evidenze (~A): ~A~%" *checker-source* c)
      (sb-ext:exit :code 1))))

(unless (member :arcdocdb-evidence-check-library *features*) (main))
