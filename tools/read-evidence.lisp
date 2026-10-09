;;;; Lettura esplicita delle prove, inclusi i descriptor gzip.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(require :asdf)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(let ((args (uiop:command-line-arguments)))
  (unless (= 1 (length args))
    (error "Uso: sbcl --script tools/read-evidence.lisp percorso.lisp"))
  (let ((*print-readably* t))
    (write (arcdocdb.evidence:read-evidence (first args)) :pretty t)
    (terpri)))
