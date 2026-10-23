;;;; Il budget protegge anche file pubblicati ma ancora fuori catalogo.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(require :sb-posix)
(let* ((root (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
       (fixture (merge-pathnames (format nil "spikes/results/.budget-test-~D/"
                                        (sb-posix:getpid)) root))
       (cases nil) (owned nil))
  (unwind-protect
       (progn
         (sb-posix:mkdir fixture #o700)
         (setf owned t)
         (dolist (case '(("fuori-catalogo.lisp" 1048577) ("fuori-catalogo.gz" 8388609)))
           (let ((path (merge-pathnames (first case) fixture)))
             (with-open-file (stream path :direction :output :if-exists :error
                                          :element-type '(unsigned-byte 8))
               ;; File sparso: conta la dimensione logica, senza allocare un buffer gigante.
               (file-position stream (1- (second case))) (write-byte 0 stream))
             (multiple-value-bind (stdout stderr code)
                 (uiop:run-program
                  (list (namestring sb-ext:*runtime-pathname*) "--noinform" "--no-userinit"
                        "--no-sysinit" "--script"
                        (namestring (merge-pathnames "tools/check-evidence.lisp" root)))
                  :output :string :error-output :string :ignore-error-status t)
               (unless (and (not (zerop code)) (search (first case) stderr)
                            (search "limite" stderr))
                 (error "Il controllo non ha rifiutato il file grande previsto: ~A." path))
               (push (list :fixture (first case) :bytes (second case) :status :ok
                           :observed-exit-code code :stdout stdout :stderr stderr) cases))
             (delete-file path)))
         (write (list :schema-version 1 :kind :evidence-publication-tests :status :ok
                      :checks (length cases) :cases (nreverse cases)) :pretty t)
         (terpri))
    (when owned (uiop:delete-directory-tree fixture :validate t :if-does-not-exist :ignore))))
