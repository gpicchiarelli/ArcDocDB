;;;; Runner degli esperimenti SPK-08; ogni compilazione è rigorosa.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))

(defun dati-portabili (data)
  "Identificatori del modulo come stringhe; il report non richiede i suoi package."
  (typecase data
    (cons (cons (dati-portabili (car data)) (dati-portabili (cdr data))))
    (symbol (if (or (null data) (keywordp data) (eq (symbol-package data) (find-package :cl)))
                data
                (if (symbol-package data)
                    (format nil "~A::~A" (package-name (symbol-package data)) (symbol-name data))
                    (symbol-name data))))
    (t data)))

(defun compila-spk08 (base out name)
  (handler-bind ((warning (lambda (c) (error "Compilazione SPK-08: ~A" c))))
    (multiple-value-bind (fasl warnings failure)
        (compile-file (merge-pathnames (format nil "~A.lisp" name) base)
                      :output-file (merge-pathnames (format nil "~A.fasl" name) out)
                      :verbose nil :print nil)
      (when (or warnings failure (null fasl)) (error "Compilazione SPK-08 non valida: ~A" name))
      (load fasl :verbose nil :print nil))))

(let* ((args (uiop:command-line-arguments)) (mode (or (first args) "--check"))
       (simd-only (member mode '("--simd-check" "--simd-bench") :test #'string=))
       (benchmark (member mode '("--bench" "--simd-bench") :test #'string=))
       (base (uiop:pathname-directory-pathname *load-truename*))
       (out (merge-pathnames (format nil "out/process-~D-~D/" (get-universal-time)
                                    (sb-posix:getpid)) base)))
  (unless (and (<= (length args) 1)
               (member mode '("--check" "--bench" "--simd-check" "--simd-bench") :test #'string=))
    (error "Uso: run.lisp --check|--bench|--simd-check|--simd-bench"))
  (ensure-directories-exist out)
  (let ((scalar nil) (bitmap nil)
        (native (list :status :unsupported :module :simd :reason :contrib-or-architecture)))
    (unless simd-only
      (compila-spk08 base out "impronte")
      (setf scalar (uiop:symbol-call :arcdocdb.spk08.impronte (if benchmark :bench :check)))
      (unless (eq :ok (getf scalar :status)) (error "Esito scalar/SWAR non valido: ~S" scalar)))
    (when (and (or (member :arm64 *features*) (member :x86-64 *features*))
               (asdf:find-system :sb-simd nil))
      (require :sb-simd)
      (compila-spk08 base out "simd")
      (setf native (uiop:symbol-call :arcdocdb.spk08.simd (if benchmark :bench :check))))
    (unless (member (getf native :status) '(:ok :measured :unsupported))
      (error "Esito SIMD non valido: ~S" native))
    (unless simd-only
      (dolist (name '("bitmap" "core-bitmap")) (compila-spk08 base out name))
      (let ((checked (uiop:symbol-call :arcdocdb.spk08.bitmap.campagna :check)))
        (unless (eq (getf checked :status) :ok) (error "Esito bitmap non valido: ~S" checked))
        (setf bitmap (if benchmark
                         (list :check checked
                               :benchmark (uiop:symbol-call :arcdocdb.spk08.bitmap.campagna :benchmark))
                         checked))))
    (let ((*print-readably* t) (*print-pretty* t))
      (write (dati-portabili (if simd-only native
                 (list :spike :spk-08
                       :status (if (eq (getf native :status) :unsupported) :unsupported
                                   (if benchmark :measured :ok))
                       :variant :isolated-generated-code
                       :results (list :scalar-and-swar scalar :native-simd native :bitmap bitmap)
                       :limits '(:not-an-index-integration :no-production-promotion)))))
      (terpri))))
