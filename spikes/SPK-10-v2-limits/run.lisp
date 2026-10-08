;;;; Runner indipendente dalla cwd, compilazione stretta in processi isolati.
;;; REQ: REQ-VAL-001 REQ-AFF-003 REQ-LIM-001 REQ-LIM-002 REQ-LIM-003
(require :asdf)
(declaim (optimize (safety 3) (debug 3)))

(defun spk10-compila (source output)
  "Compila senza warning/style-warning e carica soltanto il FASL ottenuto."
  (ensure-directories-exist output)
  (handler-bind ((warning (lambda (c) (error "Compilazione v2: ~A" c))))
    (multiple-value-bind (fasl warnings failure)
        (compile-file source :output-file output :verbose nil :print nil)
      (when (or warnings failure (null fasl)) (error "Compilazione v2 fallita: ~A" source))
      (load fasl :verbose nil :print nil))))

(let* ((base (uiop:pathname-directory-pathname *load-truename*))
       (args (uiop:command-line-arguments))
       (mode (or (first args) "--check")))
  (unless (and (<= (length args) 1) (member mode '("--check" "--bench") :test #'string=))
    (error "Uso SPK-10: --check|--bench"))
  (spk10-compila (merge-pathnames "../SPK-09-integrity/core.lisp" base)
                (merge-pathnames "out/crc.fasl" base))
  (dolist (name '("codec" "indice" "cbor" "migrazione" "core"))
    (spk10-compila (merge-pathnames (format nil "~A.lisp" name) base)
                  (merge-pathnames (format nil "out/~A.fasl" name) base)))
  (let* ((package (find-package "ARCDOCDB.SPK10"))
         (api (if (string= mode "--check") "CHECK" "BENCHMARK"))
         (result (funcall (symbol-function (find-symbol api package)))))
    (let ((*print-readably* t) (*print-pretty* t)) (write result) (terpri))))
