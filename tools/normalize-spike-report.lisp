;;;; Importa i report precedenti al campo RESULT, senza eseguire i dati.
;;; REQ: REQ-VAL-001 REQ-BEN-001
(require :asdf)
(declaim (optimize (safety 3) (debug 3)))

(define-condition invalid-spike-report (error)
  ((motivo :initarg :motivo :reader motivo))
  (:report (lambda (c s) (write-string (motivo c) s))))

(defun leggi-record (stream)
  "Richiede una sola plist senza read-eval, conservando il report originale."
  (let ((*read-eval* nil) (eof (gensym "EOF")))
    (let ((record (read stream nil eof)))
      (unless (and (listp record) (not (eq record eof)) (eq (read stream nil eof) eof))
        (error 'invalid-spike-report :motivo "Il file non contiene una sola plist."))
      record)))

(let ((args (uiop:command-line-arguments)))
  (unless (= 2 (length args))
    (error 'invalid-spike-report :motivo "Uso: normalize-spike-report.lisp input output"))
  (let* ((input (first args)) (output (second args))
         (old (with-open-file (s input) (leggi-record s)))
         (runs (copy-tree (getf old :runs))))
    (dolist (r runs)
      (setf (getf r :result)
            (with-input-from-string (s (getf r :stdout)) (leggi-record s)))
      (let* ((payload (or (getf (getf r :result) :benchmark) (getf r :result)))
             (status (getf payload :status)))
        (unless status
          (error 'invalid-spike-report :motivo "Esito del processo mancante."))
        (setf (getf r :status) status)))
    (ensure-directories-exist output)
    (with-open-file (s output :direction :output :if-exists :error)
      (let ((*print-readably* t))
        (write (list :schema-version 1 :kind :legacy-import :source-report input
                     :environment (getf old :environment) :mode (getf old :mode)
                     :metadata-policy :preserved-without-inferred-fields
                     :status :imported :runs runs)
               :stream s :pretty t)
        (terpri s)))))
