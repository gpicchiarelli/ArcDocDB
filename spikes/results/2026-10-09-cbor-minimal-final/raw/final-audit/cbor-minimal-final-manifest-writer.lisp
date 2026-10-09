(require :asdf)
(let ((manifest
       (list :schema-version 1
             :processes '(("collection" "spikes/out/4000547797-command-24349-0/report.lisp")
                          ("full-check" "spikes/out/4000548089-command-42461-0/report.lisp"))
             :trees '(("full-spikes" "spikes/out/4000548174-check-45397-0/" :all))
             :files (loop for path in (sort (directory "spikes/out/cbor-minimal-publication*.*")
                                           #'string< :key #'namestring)
                          when (and (pathname-name path) (pathname-type path))
                          collect (list (file-namestring path) (namestring path))))))
  (with-open-file (out "spikes/out/cbor-minimal-final-manifest.lisp"
                       :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write manifest :stream out :pretty t) (terpri out)))
  (format t "Manifest finale: ~D processi, ~D file di audit.~%"
          (length (getf manifest :processes)) (length (getf manifest :files))))
