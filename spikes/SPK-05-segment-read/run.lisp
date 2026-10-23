;;;; Runner SPK-05: solo una plist stdout, compilazione senza avvisi.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 2)))

(defun spk05-compila (base)
  "FASL in directory distinta per PID; sorgenti relativi allo script."
  (let ((out (merge-pathnames (format nil "out/~D/" (sb-posix:getpid)) base)))
    (dolist (nome '("io" "record" "core"))
      (let ((source (merge-pathnames (concatenate 'string nome ".lisp") base))
            (dest (merge-pathnames (concatenate 'string nome ".fasl") out)))
        (ensure-directories-exist dest)
        (handler-bind ((warning (lambda (c) (error "Compilazione SPK-05: ~A." c))))
          (multiple-value-bind (fasl avvisi fallimento)
              (compile-file source :output-file dest :verbose nil :print nil)
            (unless (and fasl (not avvisi) (not fallimento))
              (error "Compilazione SPK-05 fallita: ~A." source))
            (load fasl :verbose nil :print nil)))))))

(defun spk05-main ()
  "Valida CLI prima delle prove; ogni modo esegue check."
  (let ((args (uiop:command-line-arguments))
        (base (uiop:pathname-directory-pathname *load-truename*)))
    (unless (or (null args) (equal args '("--check")) (equal args '("--bench")))
      (error "Uso: run.lisp [--check|--bench]."))
    (spk05-compila base)
    (let ((check (uiop:symbol-call :arcdocdb.spk05 :check base)))
      (if (equal args '("--bench"))
          (list :status :ok :spike :spk-05 :check check
                :benchmark (uiop:symbol-call :arcdocdb.spk05 :benchmark base))
          check))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (progn (write (spk05-main)) (terpri) (finish-output))
    (error (c)
      (write (list :status :error :spike :spk-05 :message (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
