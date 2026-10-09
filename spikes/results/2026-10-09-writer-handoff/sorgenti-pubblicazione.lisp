(:SCHEMA-VERSION 1 :KIND :PUBLICATION-HELPER-SOURCES :SOURCES
 ((:PATH "spikes/out/handoff-publish.lisp" :GIT-BLOB
   "d49732d7c3b8a3b6ef4b91c838f4fde0586cd717" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun save-data (data path)
  (with-open-file (output path :direction :output :if-exists :supersede :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream output :pretty t) (terpri output))))
(defun source-record (path)
  (list :path (namestring path) :git-blob
        (string-trim '(#\\Newline #\\Space) (uiop:run-program (list \"git\" \"hash-object\" \"--\" (namestring path)) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(let ((destination #p\"spikes/results/2026-10-09-writer-handoff/\"))
  (ensure-directories-exist destination)
  (dolist (entry '((\"spikes/out/4000512533-command-11322-0/report.lisp\" \"build-iniziale.lisp\")
                   (\"spikes/out/4000512681-command-15990-0/report.lisp\" \"strict-contrib-fallito.lisp\")
                   (\"spikes/out/4000512719-command-17482-0/report.lisp\" \"strict-argv-fallito.lisp\")
                   (\"spikes/out/4000512777-command-18876-0/report.lisp\" \"strumenti-selftest.lisp\")
                   (\"spikes/out/4000512719-command-17483-0/report.lisp\" \"copertura-processo.lisp\")
                   (\"spikes/out/4000512829-command-19467-0/report.lisp\" \"export-copertura-fallito.lisp\")
                   (\"spikes/out/4000512922-command-21276-0/report.lisp\" \"export-copertura-processo.lisp\")
                   (\"spikes/out/handoff-coverage-export.lisp\" \"copertura-grezza.lisp\")
                   (\"spikes/out/4000512859-command-20096-0/report.lisp\" \"mutazioni-processo.lisp\")
                   (\"spikes/out/handoff-mutations/report.lisp\" \"mutazioni-dati.lisp\")
                   (\"spikes/out/4000512906-command-20972-0/report.lisp\" \"allocazioni-processo.lisp\")
                   (\"spikes/out/handoff-allocations/report.lisp\" \"allocazioni-dati.lisp\")))
    (uiop:copy-file (first entry) (merge-pathnames (second entry) destination)))
  (let ((mutation (arcdocdb.evidence:read-evidence \"spikes/out/handoff-mutations/report.lisp\")))
    (save-data (list :schema-version 1 :kind :raw-mutation-logs
                     :logs (mapcar #'source-record
                                   (cons (getf mutation :baseline-log)
                                         (mapcar (lambda (entry) (getf entry :log)) (getf mutation :mutants)))))
               (merge-pathnames \"mutazioni-log.lisp\" destination)))
  (save-data (list :schema-version 1 :kind :verification-adapter-sources
                   :sources (mapcar #'source-record
                                    '(\"spikes/out/handoff-strict-tools-initial.lisp\"
                                      \"spikes/out/handoff-strict-tools-args-initial.lisp\"
                                      \"spikes/out/handoff-strict-tools.lisp\"
                                      \"spikes/out/handoff-export-coverage-initial.lisp\"
                                      \"spikes/out/handoff-export-coverage.lisp\"
                                      \"docs/implementazione/writer-handoff-metodo.md\")))
             (merge-pathnames \"sorgenti-adattatori.lisp\" destination))
  (when (probe-file \"spikes/out/handoff-agent-probes.lisp\")
    (uiop:copy-file \"spikes/out/handoff-agent-probes.lisp\" (merge-pathnames \"probe-agente.lisp\" destination)))
  (save-data (list :schema-version 1 :kind :evidence-catalog :component :writer-handoff
                   :targeted-base \"85a4e0502242a20bbc4e91a04a5afd792ab26dd6\"
                   :integration-base \"4215fca\"
                   :entries (loop for file in (sort (directory (merge-pathnames \"*.lisp\" destination)) #'string< :key #'namestring)
                                  unless (string= (file-namestring file) \"catalogo.lisp\")
                                  collect (list :artifact (file-namestring file))))
             (merge-pathnames \"catalogo.lisp\" destination))
  (format t \"Evidenze pubblicate: ~A~%\" destination))
")
  (:PATH "spikes/out/handoff-refresh-catalog.lisp" :GIT-BLOB
   "e2a0c5119efea27b8ad834bae0bd24aa08450c43" :TEXT "(require :asdf)
(let* ((directory #p\"spikes/results/2026-10-09-writer-handoff/\")
       (data (list :schema-version 1 :kind :evidence-catalog :component :writer-handoff
                   :targeted-base \"85a4e0502242a20bbc4e91a04a5afd792ab26dd6\"
                   :integration-base \"4215fca\"
                   :entries (loop for file in (sort (directory (merge-pathnames \"*.lisp\" directory)) #'string< :key #'namestring)
                                  unless (string= (file-namestring file) \"catalogo.lisp\")
                                  collect (list :artifact (file-namestring file))))))
  (with-open-file (output (merge-pathnames \"catalogo.lisp\" directory) :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write data :stream output :pretty t) (terpri output))))
")))
