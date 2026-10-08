;;;; Runner distinto per l'estensione bitmap; non carica i moduli impronte/SIMD.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 2)))

(defun compila-bitmap (base out nome)
  "Compila e carica con tutti gli avvisi fatali; FASL locale al processo."
  (handler-bind ((warning (lambda (c) (error "SPK-08 bitmap: ~A." c))))
    (multiple-value-bind (fasl avvisi fallimento)
        (compile-file (merge-pathnames (format nil "~A.lisp" nome) base)
                      :output-file (merge-pathnames (format nil "~A.fasl" nome) out)
                      :verbose nil :print nil)
      (unless (and fasl (not avvisi) (not fallimento))
        (error "SPK-08 bitmap: compilazione fallita: ~A." nome))
      (load fasl :verbose nil :print nil))))

(defun esegui-bitmap ()
  "Valida CLI, poi esegue il CHECK prima di ogni misura."
  (let* ((args (uiop:command-line-arguments))
         (base (uiop:pathname-directory-pathname *load-truename*))
         (out (merge-pathnames (format nil "out/bitmap-~D-~D/" (get-universal-time)
                                       (sb-posix:getpid)) base)))
    (unless (or (null args) (equal args '("--check")) (equal args '("--bench")))
      (error "Uso: run-bitmap.lisp [--check|--bench]."))
    (ensure-directories-exist out)
    (dolist (nome '("bitmap" "core-bitmap")) (compila-bitmap base out nome))
    (let ((check (uiop:symbol-call :arcdocdb.spk08.bitmap.campagna :check)))
      (if (equal args '("--bench"))
          (list :status :ok :check check
                :benchmark (uiop:symbol-call :arcdocdb.spk08.bitmap.campagna :benchmark))
          check))))

(let ((*read-eval* nil) (*print-readably* t) (*print-pretty* t))
  (handler-case (progn (write (esegui-bitmap)) (terpri) (finish-output))
    (error (c)
      (write (list :status :error :module :spk08-bitmap :diagnostic (princ-to-string c)))
      (terpri) (finish-output) (sb-ext:exit :code 1))))
