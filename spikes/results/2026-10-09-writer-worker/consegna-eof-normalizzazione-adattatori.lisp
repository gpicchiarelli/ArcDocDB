(:SCHEMA-VERSION 1 :KIND :FORMAT-ONLY-CONSERVATION-ADAPTERS :SOURCES
 ((:PATH #A((41) BASE-CHAR . "spikes/out/worker-final-format-proof.lisp") :BYTES 1687 :SHA256
   "371b28b8a40eea14175698d5d7805e844f5d70223bd890c7879c4abcd9389787" :GIT-BLOB
   "52baf1798fc5475cf06a40105d65a32213db0c2f" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(let* ((qualified-path \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-run.lisp\")
       (current-path \"src/execution/worker-run.lisp\")
       (before (uiop:read-file-string qualified-path :external-format :utf-8))
       (after (uiop:read-file-string current-path :external-format :utf-8)))
 (assert (and (= (length before) (1+ (length after)))
              (char= (char before (1- (length before))) #\\Newline)
              (char= (char after (1- (length after))) #\\Newline)
              (string= before after :end1 (length after))))
 (with-open-file (old qualified-path :element-type '(unsigned-byte 8))
  (with-open-file (new current-path :element-type '(unsigned-byte 8))
   (assert (= (file-length old) (1+ (file-length new))))
   (loop repeat (file-length new) do (assert (= (read-byte old) (read-byte new))))
   (assert (and (= (read-byte old) 10) (eq (read-byte old nil :eof) :eof)))))
 (worker-save-data
  (list :schema-version 1 :kind :qualified-source-formatting-proof :status :passed
        :qualified-record \"4000550386-command-90070-0\"
        :qualified-source (worker-source-record qualified-path)
        :final-source (worker-source-record current-path)
        :transformation :remove-one-terminal-line-feed :all-other-bytes-identical t
        :limits '(:no-lisp-form-or-line-location-change :no-test-rerun-for-eof-whitespace
                  :original-qualified-source-and-record-preserved))
  #p\"spikes/out/worker-final-format-proof-data.lisp\")
 (format t \"EOF FORMAT PROOF PASS: exact byte prefix retained; only one final LF removed.~%\"))
")
  (:PATH #A((44) BASE-CHAR . "spikes/out/worker-final-format-conserve.lisp") :BYTES 850 :SHA256
   "09cfa4f3d265fd25365ff9aba43ce18831d04c47a90295b31b0669ea3942e426" :GIT-BLOB
   "d04eb541c76d780a9ae69cfe841efe39288818ae" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(worker-copy-process \"4000551819-command-55460-0\" \"consegna-eof-normalizzazione-processo\")
(worker-copy-evidence \"spikes/out/worker-final-format-proof-data.lisp\"
 (merge-pathnames \"consegna-eof-normalizzazione-dati.lisp\" *worker-publication-directory*))
(worker-save-source-bundle '(\"spikes/out/worker-final-format-proof.lisp\"
                            \"spikes/out/worker-final-format-conserve.lisp\")
 (merge-pathnames \"consegna-eof-normalizzazione-adattatori.lisp\" *worker-publication-directory*)
 :format-only-conservation-adapters)
(worker-refresh-catalog \"e07d77271758f3134b1977caf394fe38532b54ed\"
 :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                    \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"))
(format t \"EOF FORMAT PROOF AND ORIGINAL SOURCE CONSERVED.~%\")
")))
