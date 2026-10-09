;;;; Raccolta conclusiva; archivi delle campagne originali restano immutati.
(require :asdf)
(let ((files nil))
  (dolist (path (uiop:directory-files "spikes/out/"))
    (let ((name (file-namestring path)))
      (when (and (uiop:string-prefix-p "cbor-minimal" name)
                 (not (search "coverage-state-original" name)))
        (push (list name (namestring (truename path))) files))))
  (setf files (nreverse files))
  (with-open-file (out "spikes/out/scan-final-collection-manifest.lisp" :direction :output :if-exists :error)
    (write (list :schema-version 1
                 :processes '(("collection" "spikes/out/4000552649-command-74116-0/report.lisp")
      ("manifest-v2" "spikes/out/4000552734-command-77489-0/report.lisp")
      ("initial-publication-audit" "spikes/out/4000552733-command-77433-0/report.lisp")
      ("full-check" "spikes/out/4000552850-command-80037-0/report.lisp")
      ("data-audit-first" "spikes/out/4000552876-command-80674-0/report.lisp")
      ("data-audit-second" "spikes/out/4000552959-command-83078-0/report.lisp")
      ("data-audit" "spikes/out/4000553029-command-85919-0/report.lisp")
      ("coverage-byte-audit" "spikes/out/4000553094-command-89492-0/report.lisp"))
                 :trees '(("full-spikes" "spikes/out/4000552955-check-82980-0/" :all))
                 :files files
                 :limits '(:first-index-immutable :full-negative-fixtures-and-fasl-local
                           :original-failed-helper-attempts-preserved :no-gate-promotion))
           :stream out :pretty t)
    (terpri out))
  (format t "Raccolta finale: ~D file scelti e otto processi.~%" (length files)))

