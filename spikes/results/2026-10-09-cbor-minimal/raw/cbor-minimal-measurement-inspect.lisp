;;;; Lettura diagnostica dei dati, mai del prodotto o dei driver eseguibili.
(load "tools/evidence-storage.lisp")
(defun safe-string-data (text)
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)) (*read-base* 10))
    (with-input-from-string (input text)
      (let ((datum (read input nil :eof)))
        (assert (not (eq :eof datum)))
        (assert (eq :eof (read input nil :eof)))
        datum))))
(let* ((wrapper (arcdocdb.evidence:read-evidence
                 "spikes/out/4000546877-command-79443-0/report.lisp"))
       (bench (safe-string-data (getf wrapper :stdout)))
       (mutation (arcdocdb.evidence:read-evidence
                  "spikes/out/cbor-minimal-mutations/report.lisp")))
  (format t "WRAPPER keys ~S~%BENCH keys ~S~%MUTATION keys ~S~%"
          (loop for key in wrapper by #'cddr collect key)
          (loop for key in bench by #'cddr collect key)
          (loop for key in mutation by #'cddr collect key))
  (format t "ENV ~S~%SELFTEST ~S~%"
          (loop for key in '(:sbcl :machine :os :os-version :workers :safety :timer-units-per-second)
                append (list key (getf bench key)))
          (getf bench :self-test))
  (dolist (cell (getf bench :campaigns)) (write cell :pretty t) (terpri))
  (format t "MUT SUMMARY ~S~%"
          (loop for key in '(:status :baseline :mutants :mutation-scope-size :results :self-test)
                append (list key (getf mutation key)))))
