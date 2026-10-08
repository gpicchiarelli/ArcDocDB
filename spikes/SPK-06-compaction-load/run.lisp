;;;; Runner SPK-06: dipendenze pubbliche SPK-05, compilazione senza avvisi.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 2)))

(defun spk06-compila-file (source output)
  "Compila e carica un sorgente locale; warning e style-warning sono fatali."
  (ensure-directories-exist output)
  (handler-bind ((warning (lambda (c) (error "Compilazione SPK-06: ~A." c))))
    (multiple-value-bind (fasl avvisi fallimento)
        (compile-file source :output-file output :verbose nil :print nil)
      (unless (and fasl (not avvisi) (not fallimento))
        (error "Compilazione SPK-06 fallita: ~A." source))
      (load fasl :verbose nil :print nil))))

(defun spk06-compila (base)
  "FASL distinti per PID; nessun file dello spike riusato viene modificato."
  (let ((out (merge-pathnames (format nil "out/~D/" (sb-posix:getpid)) base)))
    (dolist (nome '("io" "record"))
      (spk06-compila-file
       (merge-pathnames (format nil "../SPK-05-segment-read/~A.lisp" nome) base)
       (merge-pathnames (format nil "spk05-~A.fasl" nome) out)))
    (dolist (nome '("controllore" "interferenza" "core"))
      (spk06-compila-file (merge-pathnames (format nil "~A.lisp" nome) base)
                          (merge-pathnames (format nil "~A.fasl" nome) out)))))

(defun spk06-main ()
  "Valida CLI prima dell'I/O; tutti i modi eseguono check."
  (let ((args (uiop:command-line-arguments))
        (base (uiop:pathname-directory-pathname *load-truename*)))
    (unless (or (null args) (equal args '("--check")) (equal args '("--bench")))
      (error "Uso: run.lisp [--check|--bench]."))
    (spk06-compila base)
    (let ((check (uiop:symbol-call :arcdocdb.spk06 :check base)))
      (if (equal args '("--bench"))
          (list :status :ok :spike :spk-06 :check check
                :benchmark (uiop:symbol-call :arcdocdb.spk06 :benchmark base))
          check))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (progn (write (spk06-main)) (terpri) (finish-output))
    (error (c)
      (write (list :status :error :spike :spk-06 :message (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
