;;;; CLI C4 con compilazione stretta; i client caricano FASL gia costruiti dal padre.
;;; REQ: REQ-VAL-001 REQ-IPC-001 REQ-IPC-002 REQ-IPC-003
(require :asdf)
(require :sb-posix)
(require :sb-bsd-sockets)
(declaim (optimize (safety 3) (debug 3)))

(defun spk11-codec-inputs (base)
  "Manifest locale dei soli sorgenti codec realmente caricati, letto senza read-eval."
  (with-open-file (stream (merge-pathnames "codec-inputs.lisp" base))
    (let ((*read-eval* nil)) (getf (read stream) :sources))))

(defun spk11-load (source target client)
  "Compila in una directory esclusiva, poi carica lo stesso FASL usato dai figli."
  (unless client
    (handler-bind ((warning (lambda (condition) (error "SPK-11 compilazione: ~A" condition))))
      (multiple-value-bind (fasl warnings failure)
          (compile-file source :output-file target :verbose nil :print nil)
        (unless (and fasl (not warnings) (not failure)) (error "SPK-11 compile: ~A" source)))))
  (load target :verbose nil :print nil))

(defun spk11-main ()
  "Carica il codec canonico e compila solo lo spike; argv estranei vengono rifiutati."
  (let* ((base (uiop:pathname-directory-pathname *load-truename*))
         (root (truename (merge-pathnames "../../" base)))
         (args (uiop:command-line-arguments))
         (client (and (= (length args) 4) (string= (first args) "--client")))
         (build (if client (uiop:ensure-directory-pathname (fourth args))
                    (progn (ensure-directories-exist (merge-pathnames "out/" base))
                           (uiop:ensure-directory-pathname
                            (sb-posix:mkdtemp (namestring (merge-pathnames "out/build-XXXXXX" base))))))))
    (unless (or client (null args) (equal args '("--check")) (equal args '("--bench")))
      (error "Uso SPK-11: --check|--bench oppure --client PATH MODE FASLDIR"))
    (loop for source in (spk11-codec-inputs base) for n from 0 do
      (spk11-load (merge-pathnames source root) (merge-pathnames (format nil "codec-~D.fasl" n) build) client))
    (dolist (name '("core" "native-io" "io-state" "io-checks" "session-wire" "session-model"
                   "session-checks" "transport" "io-transport" "session-transport" "scenarios"))
      (spk11-load (merge-pathnames (format nil "~A.lisp" name) base)
                  (merge-pathnames (format nil "~A.fasl" name) build) client))
    (cond (client (uiop:symbol-call :arcdocdb.spk11 :client (second args) (third args)))
          ((equal args '("--bench")) (list :status :unsupported :reason :no-benchmark-defined))
          (t (uiop:symbol-call :arcdocdb.spk11 :check base build)))))

(handler-case
    (let ((*print-readably* t) (*print-pretty* t)) (write (spk11-main)) (terpri) (finish-output))
  (error (condition)
    (write (list :status :error :spike :spk-11 :diagnostic (princ-to-string condition)) :pretty t)
    (terpri) (finish-output) (sb-ext:exit :code 1)))
