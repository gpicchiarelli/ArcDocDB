;;;; Verifica dei cataloghi e dei record conservati, letti soltanto come dati.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(declaim (optimize (safety 3) (debug 3)))

(define-condition invalid-evidence (error)
  ((path :initarg :path :reader evidence-path))
  (:report (lambda (c stream) (format stream "Evidenza non valida: ~A." (evidence-path c)))))

(defun leggi-dati (path)
  "Una sola plist; read-eval disabilitato, nessun load del record."
  (arcdocdb.evidence:read-evidence path))

(defun verifica-dimensioni (base)
  "Rifiuta nuovi registri enormi, anche se non ancora inclusi in un catalogo."
  (let ((count 0) (bytes 0))
    (labels ((walk (directory)
               (dolist (path (uiop:directory-files directory))
                 (let* ((size (arcdocdb.evidence:file-bytes path))
                        (compressed (equal (pathname-type path) "gz"))
                        (limit (if compressed (* 8 1024 1024) (* 1024 1024))))
                   (when (> size limit)
                     (error "Artefatto ~A: ~D byte, limite ~D. Eseguire make compact-evidence."
                            path size limit))
                   (incf count) (incf bytes size)))
               (dolist (subdirectory (uiop:subdirectories directory)) (walk subdirectory))))
      (walk base))
    (values count bytes)))

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
    (multiple-value-bind (files bytes) (verifica-dimensioni #P"spikes/results/")
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
                 :stored-files files :stored-bytes bytes
                 :limits '(:structure-presence-size-and-compressed-integrity
                           :no-result-reinterpretation)))
    (terpri))))
