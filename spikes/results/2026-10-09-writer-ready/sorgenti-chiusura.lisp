(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :SOURCES
 ((:PATH "spikes/out/ready-close-evidence.lisp" :BYTES 692 :SHA256
   "d379b561504ad7e9918491da6084986395bb7d110c3c64d87404345f68250bc5" :GIT-BLOB
   "aa64f9ace6a975b476e1765e44a72c652cfcb6c1" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(let ((arguments (uiop:command-line-arguments)))
  (unless (= 2 (length arguments)) (error \"Record e nome richiesti.\"))
  (ready-copy-process (first arguments) (second arguments)))
(unless (probe-file \"spikes/results/2026-10-09-writer-ready/sorgenti-chiusura.lisp\")
  (ready-save-data (list :schema-version 1 :kind :verification-adapter-sources
                         :sources (list (ready-source-record \"spikes/out/ready-close-evidence.lisp\")))
                    \"spikes/results/2026-10-09-writer-ready/sorgenti-chiusura.lisp\"))
(load \"spikes/out/ready-refresh-catalog.lisp\")
(format t \"Processo conservato e catalogo aggiornato.~%\")
")))
