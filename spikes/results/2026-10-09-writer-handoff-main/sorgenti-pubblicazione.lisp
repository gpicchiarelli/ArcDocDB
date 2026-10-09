(:SCHEMA-VERSION 1 :KIND :PUBLICATION-HELPER-SOURCES :EXECUTION-METADATA
 :NOT-COLLECTED :SOURCES
 ((:PATH "spikes/out/handoff-final-import.lisp" :GIT-BLOB
   "1d90356006ae4fe3c9a757d59abcea5fc7dcc4e5" :TEXT "(require :asdf)
(defun save-data (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun source-record (path)
  (list :path path :git-blob
        (string-trim '(#\\Space #\\Newline) (uiop:run-program (list \"git\" \"hash-object\" \"--\" path) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(save-data (list :schema-version 1 :kind :c1-review-import :role :author
                 :base \"4215fca415c15d64bd56b1aa17d5c09fe6083713\"
                 :source :author-document-snapshot
                 :report (source-record \"docs/implementazione/writer-handoff-revisione.md\")
                 :limits '(:local-contract-only :no-coverage-exclusions :no-engine-qualification
                           :utf8-integration-verification-pending)
                 :final-integration-base \"7f8ca93499090b2a4f515015372046f16ac574cf\")
           \"spikes/results/2026-10-09-writer-handoff/lettura-autore.lisp\")
(save-data (list :schema-version 1 :kind :publication-helper-sources
                :sources (mapcar #'source-record
                  '(\"spikes/out/handoff-publish.lisp\" \"spikes/out/handoff-refresh-catalog.lisp\")))
           \"spikes/results/2026-10-09-writer-handoff/sorgenti-pubblicazione.lisp\")
")
  (:PATH "spikes/out/handoff-publish-main.lisp" :GIT-BLOB
   "06e160eb1919391e262510e7b49b6b288c7d16e0" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun save-new (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun copy-record (source target)
  (let ((record (arcdocdb.evidence:read-evidence source)))
    (unless (eql 1 (or (getf record :schema-version) (getf record :schema)))
      (error \"Schema mancante: ~A\" source))
    (uiop:copy-file source target)
    (let* ((*read-eval* nil) (raw (with-open-file (stream source) (read stream))))
      (when (eq :compressed-evidence (getf raw :kind))
        (let ((payload (getf raw :payload)))
          (uiop:copy-file (merge-pathnames payload (uiop:pathname-directory-pathname source))
                         (merge-pathnames payload (uiop:pathname-directory-pathname target))))))
    record))
(let ((out #p\"spikes/results/2026-10-09-writer-handoff-main/\"))
  (ensure-directories-exist out)
  (dolist (entry '((\"spikes/out/4000514045-command-42904-0/report.lisp\" \"wrapper-integrato.lisp\")
                   (\"spikes/out/4000514045-command-42904-0/conservazione.lisp\" \"wrapper-conservazione.lisp\")
                   (\"spikes/out/4000514046-command-42938-0/report.lisp\" \"check-integrato.lisp\")
                   (\"spikes/out/4000514046-command-42938-0/conservazione.lisp\" \"check-conservazione.lisp\")))
    (copy-record (first entry) (merge-pathnames (second entry) out)))
  (dolist (entry '((\"spikes/out/4000514107-check-43554-0/report.lisp\" \"spikes-integrati.lisp\")
                   (\"spikes/out/4000514107-check-43554-0/conservazione.lisp\" \"spikes-conservazione.lisp\")))
    (copy-record (first entry) (merge-pathnames (second entry) out)))
  (format t \"Wrapper, check e master dei dieci spike conservati in ~A~%\" out))
")
  (:PATH "spikes/out/handoff-final-bookkeeping.lisp" :GIT-BLOB
   "b98f0652669a015d7c11f9b7c39cc8356c9be824" :TEXT "(require :asdf)
(defun save-new (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun snapshot (path)
  (list :path path :git-blob
        (string-trim '(#\\Newline #\\Space) (uiop:run-program (list \"git\" \"hash-object\" \"--\" path) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(save-new (list :schema-version 1 :kind :c1-review-import :role :author
                :base \"7f8ca93499090b2a4f515015372046f16ac574cf\"
                :scope :integration-only :check-status :ok :source-consistency :stable :exit-code 0
                :check \"spikes/out/4000514046-command-42938-0/report.lisp\"
                :report (snapshot \"docs/implementazione/writer-handoff-revisione.md\")
                :sources (mapcar #'snapshot '(\"arcdocdb.asd\" \"src/execution/handoff.lisp\"
                                             \"src/execution/queue.lisp\" \"src/execution/package.lisp\"
                                             \"tests/execution/handoff.lisp\")))
          \"spikes/results/2026-10-09-writer-handoff-main/lettura-autore.lisp\")
(save-new (list :schema-version 1 :kind :publication-helper-sources
                :execution-metadata :not-collected
                :sources (mapcar #'snapshot '(\"spikes/out/handoff-final-import.lisp\"
                                             \"spikes/out/handoff-publish-main.lisp\"
                                             \"spikes/out/handoff-final-bookkeeping.lisp\")))
          \"spikes/results/2026-10-09-writer-handoff-main/sorgenti-pubblicazione.lisp\")
")))
