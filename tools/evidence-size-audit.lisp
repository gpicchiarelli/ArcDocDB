;;;; Dimensioni logiche osservate; non confonde byte dei file con spazio allocato.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(defun audit-root (root)
  (let ((files 0) (bytes 0) (large nil))
    (labels ((walk (directory)
               (dolist (path (uiop:directory-files directory))
                 (let ((size (arcdocdb.evidence:file-bytes path)))
                   (incf files) (incf bytes size)
                   (when (> size (* 1024 1024))
                     (push (list :path (namestring path) :bytes size) large))))
               (dolist (subdirectory (uiop:subdirectories directory)) (walk subdirectory))))
      (walk (uiop:ensure-directory-pathname (truename root))))
    (list :path root :files files :bytes bytes
          :large-files (sort large #'> :key (lambda (r) (getf r :bytes))))))
(let ((args (uiop:command-line-arguments)))
  (unless args (error "Uso: evidence-size-audit.lisp directory..."))
  (let ((*print-readably* t))
    (write (list :schema-version 1 :kind :evidence-size-audit :status :ok
                 :roots (mapcar #'audit-root args)
                 :git-count-objects
                 (uiop:run-program '("git" "count-objects" "-vH") :output :string)
                 :limits '(:logical-file-bytes :no-disk-block-accounting
                           :point-in-time-observation))
           :pretty t)
    (terpri)))
