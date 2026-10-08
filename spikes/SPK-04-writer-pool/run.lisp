;;;; Runner SPK-04: stdout contiene una sola plist, incluso un fallimento.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 2)))

(defun spk04-compila (base)
  "Compila soltanto i tre moduli locali, senza avvisi e con output distinto per processo."
  (let ((out (merge-pathnames (format nil "out/~D/" (sb-posix:getpid)) base)))
    (dolist (nome '("pool" "parcheggi" "core"))
      (let ((source (merge-pathnames (concatenate 'string nome ".lisp") base))
            (output (merge-pathnames (concatenate 'string nome ".fasl") out)))
        (ensure-directories-exist output)
        (handler-bind ((warning (lambda (c) (error "Compilazione SPK-04: ~A." c))))
          (multiple-value-bind (fasl avvisi fallimento)
              (compile-file source :output-file output :verbose nil :print nil)
            (unless (and fasl (not avvisi) (not fallimento))
              (error "Compilazione SPK-04 fallita: ~A." source))
            (load fasl :verbose nil :print nil)))))))

(defun spk04-main ()
  "Valida il modo, controlla i moduli e separa le misure di prestazione."
  (let ((args (uiop:command-line-arguments)))
    (unless (or (null args) (equal args '("--check")) (equal args '("--bench")))
      (error "Uso: run.lisp [--check|--bench]."))
    (spk04-compila (uiop:pathname-directory-pathname *load-truename*))
    (let ((verifica (uiop:symbol-call :arcdocdb.spk04 :check)))
      (if (equal args '("--bench"))
          (list :status :ok :spike :spk-04 :check verifica
                :benchmark (uiop:symbol-call :arcdocdb.spk04 :benchmark))
          verifica))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case
      (progn (write (spk04-main)) (terpri) (finish-output))
    (error (c)
      (write (list :status :error :spike :spk-04 :message (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
