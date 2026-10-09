(:SCHEMA-VERSION 1 :KIND :PUBLICATION-CLOSURE-ADAPTER :SOURCES
 ((:PATH #A((40) BASE-CHAR . "spikes/out/worker-publication-close.lisp") :BYTES 1107 :SHA256
   "afd3a4ac4f82e86a14cf6cdbfeff491be022e9476687a7de3a4cd71c3459f9a5" :GIT-BLOB
   "0535806326f69893831602de9107efe80b6a7476" :TEXT "(load \"spikes/out/worker-publish.lisp\")
(worker-copy-process \"4000549781-command-39344-0\" \"pubblicazione-ripresa-heap-fallita-processo\")
(worker-save-source-bundle '(\"spikes/out/worker-publication-close.lisp\")
 (worker-publication-target \"pubblicazione-chiusura-adattatori.lisp\") :publication-closure-adapter)
(dolist (part '(\"report\" \"conservazione\"))
 (worker-copy-evidence-resume
  (format nil \"spikes/out/4000548134-check-44515-0/~A.lisp\" part)
  (merge-pathnames (format nil \"spikes-finali~A.lisp\" (if (string= part \"report\") \"\" \"-conservazione\"))
                  *worker-integration-publication-directory*)))
(worker-refresh-catalog \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
 :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\")
 :directory *worker-integration-publication-directory*)
(sb-ext:gc :full t)
(worker-run-review-process-evidence)
(sb-ext:gc :full t)
(worker-refresh-catalog \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
 :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"))
(format t \"PUBLICATION CLOSURE OK: original bytes preserved, three flat catalogs ready.~%\")
")))
