(:SCHEMA-VERSION 1 :KIND :SOURCE-SUPPORT :LANGUAGE :COMMON-LISP :ORIGINAL-PATH
 "/tmp/arcdocdb-snapshot-csn-preservation.lisp" :TEXT "(require :asdf)
(defun git-text (&rest args)
  (string-trim '(#\\Newline #\\Space #\\Return)
               (uiop:run-program (cons \"git\" args) :output :string :error-output :string)))
(let ((results nil))
  (dolist (name '(\"compilazione-iniziale.lisp\" \"lint-iniziale.lisp\" \"tracciabilita-iniziale.lisp\"
                  \"compilazione-finale.lisp\" \"lint-finale.lisp\" \"collegamenti.lisp\"
                  \"tracciabilita-finale.lisp\" \"cataloghi.lisp\"))
    (let* ((original (git-text \"rev-parse\" (concatenate 'string \"10d08ec:spikes/results/2026-10-09-csn/\" name)))
           (current (git-text \"hash-object\" (concatenate 'string \"spikes/results/2026-10-09-csn-origine/\" name))))
      (unless (string= original current) (error \"Report modificato: ~A\" name))
      (push (list :artifact name :original-git-blob original :current-git-blob current) results)))
  (dolist (name '(\"src/csn/package.lisp\" \"src/csn/registry.lisp\"))
    (let ((original (git-text \"rev-parse\" (concatenate 'string \"673987a:\" name)))
          (current (git-text \"hash-object\" name)))
      (unless (string= original current) (error \"Sorgente canonico modificato: ~A\" name))
      (push (list :source name :original-git-blob original :current-git-blob current) results)))
  (write (list :schema-version 1 :kind :source-preservation :status :ok
               :results (nreverse results) :limits '(:static-git-blob-comparison-only
                                                    :no-product-function-execution)) :pretty t)
  (terpri))
"
 :LIMITS (:STATIC-INSPECTION-ONLY :NO-PRODUCT-FUNCTION-EXECUTION))
