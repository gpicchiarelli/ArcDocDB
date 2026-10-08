;;;; Verifica dei cataloghi e dei record conservati, letti soltanto come dati.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(declaim (optimize (safety 3) (debug 3)))

(define-condition invalid-evidence (error)
  ((path :initarg :path :reader evidence-path))
  (:report (lambda (c stream) (format stream "Evidenza non valida: ~A." (evidence-path c)))))

(defun leggi-dati (path)
  "Una sola plist; read-eval disabilitato, nessun load del record."
  (let ((*read-eval* nil) (eof (gensym "EOF")))
    (with-open-file (stream path)
      (let ((data (read stream nil eof)))
        (unless (and (listp data) data (evenp (length data))
                     (loop for key in data by #'cddr always (keywordp key))
                     (eq (read stream nil eof) eof))
          (error 'invalid-evidence :path path))
        data))))

(defun artefatto (nome base)
  "Il catalogo può riferire solo nomi di file nella propria directory datata."
  (unless (and (stringp nome) (plusp (length nome))
               (not (find #\/ nome)) (not (find #\\ nome))
               (not (member nome '("." "..") :test #'string=)))
    (error 'invalid-evidence :path nome))
  (merge-pathnames nome base))

(uiop:with-current-directory
    ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (let ((cataloghi 0) (record 0))
    (dolist (path (directory "spikes/results/*/catalogo.lisp"))
      (let* ((data (leggi-dati path)) (base (uiop:pathname-directory-pathname path)))
        (unless (and (eql 1 (getf data :schema-version))
                     (eq :evidence-catalog (getf data :kind)) (getf data :entries))
          (error 'invalid-evidence :path path))
        (incf cataloghi)
        (dolist (entry (getf data :entries))
          (unless (getf entry :artifact) (error 'invalid-evidence :path path))
          (dolist (key '(:artifact :original :process-artifact))
            (when (getf entry key)
              (let* ((target (artefatto (getf entry key) base)) (r (leggi-dati target)))
                (when (and (eq key :artifact)
                           (not (eql 1 (or (getf r :schema-version) (getf r :schema)))))
                  (error 'invalid-evidence :path target))
                (incf record)))))))
    (unless (plusp cataloghi) (error 'invalid-evidence :path "Nessun catalogo."))
    (write (list :status :ok :catalogs cataloghi :artifact-references record
                 :limits '(:structure-and-presence-only :no-result-reinterpretation)))
    (terpri)))
