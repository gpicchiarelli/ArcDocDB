(require :asdf)
(let ((manifest
       (list :schema-version 1
             :processes '(("preliminary" "spikes/out/4000546808-command-75360-0/report.lisp")
                          ("coverage-self" "spikes/out/4000546850-command-77762-0/report.lisp")
                          ("mutation-self" "spikes/out/4000546850-command-77763-0/report.lisp")
                          ("benchmark" "spikes/out/4000546877-command-79443-0/report.lisp")
                          ("coverage" "spikes/out/4000546897-command-81110-0/report.lisp")
                          ("mutations" "spikes/out/4000546897-command-81113-0/report.lisp")
                          ("collection-guard-first" "spikes/out/4000547152-command-91683-0/report.lisp")
                          ("collection-guard" "spikes/out/4000547420-command-7798-0/report.lisp"))
             :trees '(("coverage" "spikes/out/cbor-minimal-coverage/" :all)
                      ("mutations" "spikes/out/cbor-minimal-mutations/" :lisp-and-log)
                      ("collection-tools" "spikes/out/cbor-minimal-collection/" :all))
             :files (append
                     (loop for path in (sort (directory "spikes/out/cbor-minimal-*.*")
                                             #'string< :key #'namestring)
                           when (and (pathname-name path) (pathname-type path))
                           collect (list (file-namestring path) (namestring path)))
                     (loop for path in '("/tmp/cbor-minimal-measurement-reader.lisp"
                                          "/tmp/cbor-minimal-measurement-reader-run.lisp"
                                          "/tmp/cbor-minimal-measurement-reader-v3.log"
                                          "/tmp/cbor-minimal-measurement-reader-first.lisp"
                                          "/tmp/cbor-minimal-measurement-reader-first.log"
                                          "/tmp/cbor-minimal-measurement-reader-v2.lisp"
                                          "/tmp/cbor-minimal-measurement-reader-v2.log"
                                          "/tmp/cbor-minimal-measurement-inspect.lisp"
                                          "/tmp/cbor-minimal-measurement-inspect.log"
                                          "/tmp/cbor-minimal-measurement-reader.log")
                           do (unless (probe-file path) (error "Input mancante: ~A" path))
                           collect (list (file-namestring path) path))))))
  (with-open-file (out "spikes/out/cbor-minimal-collection/manifest.lisp"
                       :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write manifest :stream out :pretty t) (terpri out)))
  (format t "Manifest: ~D processi, ~D tree, ~D file indipendenti.~%"
          (length (getf manifest :processes)) (length (getf manifest :trees))
          (length (getf manifest :files))))
