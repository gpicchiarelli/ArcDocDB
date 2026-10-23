;;;; Launcher C4 indipendente dalla cwd. Stdout contiene una sola plist.
;;; REQ: REQ-VAL-001 REQ-IDX-001 REQ-IDX-007 REQ-BEN-001
(in-package #:cl-user)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(defun spk01-opzioni (args)
  "Separa le due matrici; rifiuta opzioni estranee prima di eseguire prove."
  (let ((mode :bench) (variant :baseline) (raw nil) (options nil) (seen nil))
    (when (and args (member (first args) '("--check" "--bench" "--profile") :test #'string=))
      (setf mode (cdr (assoc (pop args) '(("--check" . :check) ("--bench" . :bench)
                                       ("--profile" . :profile)) :test #'string=))))
    (when (and (not (eq mode :bench)) args)
      (error "Check/profile non accettano opzioni benchmark."))
    (loop while args do
      (let ((name (pop args)) (value (pop args)))
        (unless value (error "Valore assente per ~S." name))
        (when (member name seen :test #'string=) (error "Opzione duplicata: ~A" name))
        (push name seen)
        (if (string= name "--variant")
            (setf variant (or (cdr (assoc value '(("baseline" . :baseline) ("buffer" . :buffer))
                                         :test #'string=))
                             (error "Variante SPK-01 sconosciuta: ~S." value)))
            (push (cons name value) raw))))
    (dolist (pair (reverse raw))
      (let* ((name (car pair)) (value (cdr pair))
             (key (cdr (assoc name
                              (if (eq variant :buffer)
                                  '(("--documents" . :documents) ("--capacity" . :capacity)
                                    ("--operations" . :operations) ("--replicas" . :replicas)
                                    ("--warmup" . :warmup)
                                    ("--time-limit-seconds" . :time-limit-seconds)
                                    ("--memory-mib" . :memory-mib))
                                  '(("--documents" . :documents) ("--seconds" . :seconds)
                                    ("--capacity" . :capacity) ("--words" . :words)
                                    ("--readers" . :readers) ("--memory-mib" . :memory-mib)))
                              :test #'string=))))
        (unless (and key (plusp (length value)) (every #'digit-char-p value))
          (error "Opzione SPK-01 non valida per ~S: ~S ~S" variant name value))
        (setf options (append options (list key (parse-integer value :junk-allowed nil))))))
    (values mode variant options)))

(defun spk01-compila (base name)
  "Compila e carica un modulo; ogni avviso interrompe il processo."
  (let ((source (merge-pathnames (format nil "~A.lisp" name) base))
        (fasl (merge-pathnames (format nil "out/~A.fasl" name) base)))
    (ensure-directories-exist fasl)
    (handler-bind ((warning (lambda (c) (error "Compilazione SPK-01: ~A" c))))
      (multiple-value-bind (output warnings failure)
          (compile-file source :output-file fasl :verbose nil :print nil)
        (when (or warnings failure (null output)) (error "Compilazione SPK-01 fallita: ~A." name))
        (load output :verbose nil :print nil)))))

(defun spk01-funzione (package name)
  "Risolve l'API dopo la compilazione, senza valutare dati del report."
  (let* ((pkg (or (find-package package) (error "Package ~A assente." package)))
         (symbol (or (find-symbol name pkg) (error "~A assente in ~A." name package))))
    (symbol-function symbol)))

(defun spk01-main ()
  (multiple-value-bind (mode variant options) (spk01-opzioni (rest sb-ext:*posix-argv*))
    (let ((base (make-pathname :name nil :type nil :defaults *load-truename*)))
      (dolist (name '("core" "lettura-buffer" "check-lettura-buffer"))
        (spk01-compila base name))
      (let* ((verification (funcall (spk01-funzione "ARCDOCDB.SPK01" "CHECK")))
             (buffer-check (funcall (spk01-funzione "ARCDOCDB.SPK01.CHECK-LETTURA-BUFFER" "CHECK"))))
        (unless (eq :ok (getf buffer-check :status)) (error "Verifica lettura buffer incompleta."))
        (case mode
          (:check (append verification (list :buffer-check buffer-check)))
          (:profile
           (spk01-compila base "profile")
           (append (funcall (spk01-funzione "ARCDOCDB.SPK01" "PROFILE"))
                   (list :buffer-check buffer-check)))
          (:bench
           (list :spike :spk-01 :check verification :buffer-check buffer-check :variant variant
                 :benchmark
                 (if (eq variant :buffer)
                     (progn (spk01-compila base "bench-lettura-buffer")
                            (apply (spk01-funzione "ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER" "BENCH") options))
                     (apply (spk01-funzione "ARCDOCDB.SPK01" "BENCHMARK") options)))))))))

(let ((*read-eval* nil) (*print-readably* t) (*print-escape* t) (*print-pretty* t))
  (handler-case (progn (write (spk01-main)) (terpri) (finish-output))
    (error (c)
      (write (list :spike :spk-01 :status :error :condition (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
