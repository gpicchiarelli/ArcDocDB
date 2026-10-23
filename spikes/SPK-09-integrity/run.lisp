;;;; Runner isolato di SPK-09. Nessuna dipendenza, compilazione sempre stretta.
;;; REQ: REQ-AFF-003
;;; REQ: REQ-SIM-002

(in-package #:cl-user)
(declaim (optimize (safety 3) (debug 1)))
(setf *read-eval* nil)

(defun spk09-warning-error (condizione)
  "Rende fatale ogni warning e style-warning, anche durante il caricamento."
  (error "Compilazione SPK-09 rifiutata: ~A" condizione))

(let* ((directory (make-pathname :name nil :type nil :defaults *load-truename*))
       (sorgente (merge-pathnames "core.lisp" directory))
       (destinazione (merge-pathnames "out/core.fasl" directory))
       (argomenti (cdr sb-ext:*posix-argv*)))
  (unless (or (null argomenti) (equal argomenti '("--check"))
              (equal argomenti '("--bench")))
    (error "Uso: sbcl --script run.lisp [--check | --bench]"))
  (ensure-directories-exist destinazione)
  (handler-bind ((warning #'spk09-warning-error)
                 (style-warning #'spk09-warning-error))
    (let ((*compile-verbose* nil) (*compile-print* nil)
          (*load-verbose* nil) (*load-print* nil))
      (multiple-value-bind (fasl avvisi fallimento)
          (compile-file sorgente :output-file destinazione)
        (when (or avvisi fallimento (null fasl))
          (error "Compilazione SPK-09 fallita: ~S ~S." avvisi fallimento))
        (load fasl))))
  ;; Il package è creato dal FASL: lookup di due nomi letterali, non dati esterni.
  (let* ((nome (if (equal argomenti '("--check")) "CHECK" "BENCHMARK"))
         (simbolo (find-symbol nome "ARCDOCDB.SPK09")))
    (unless (and simbolo (fboundp simbolo)) (error "API SPK-09 mancante: ~A" nome))
    (let ((*print-pretty* t) (*print-readably* t) (*print-base* 10)
          (*print-radix* nil) (*print-circle* nil) (*print-length* nil)
          (*print-level* nil) (*package* (find-package "CL-USER")))
      (write (funcall simbolo))
      (terpri))))
