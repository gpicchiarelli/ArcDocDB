;;;; Reads an existing command report; no product or collector execution.
(load "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/tools/evidence-storage.lisp")
(let* ((base "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/")
       (relative "spikes/out/4000548089-command-42461-0/report.lisp")
       (data (arcdocdb.evidence:read-evidence (concatenate 'string base relative)))
       (lines (with-input-from-string (stream (getf data :stdout))
                (loop for line = (read-line stream nil nil) while line collect line)))
       (end (position "build e test: nessun avviso, tutti i controlli superati" lines :test #'equal))
       (markers (loop for line in lines for number from 0
                      when (and (>= (length line) 3) (string= line "ok" :end1 2)
                                (find (char line 2) '(#\Space #\Tab)))
                        collect (list :line (1+ number) :text line)))
       (build (remove-if-not (lambda (entry) (and end (<= (getf entry :line) end))) markers))
       (after (set-difference markers build :test #'equal)))
  (let ((report (list :schema-version 1 :kind :read-only-build-marker-audit :source relative
                      :status (getf data :status) :exit-code (getf data :exit-code)
                      :source-consistency (getf data :source-consistency)
                      :build-summary-line (and end (1+ end)) :total-ok-markers (length markers)
                      :build-ok-markers (length build) :post-build-ok-markers (length after)
                      :first-build-markers (subseq build 0 (min 4 (length build)))
                      :last-build-markers (last build 4) :post-build-markers after
                      :section-markers
                      (loop for line in lines for number from 1
                            when (or (search "tools/build.lisp" line) (search "tools/lint.lisp" line)
                                     (search "build e test:" line)) collect (list :line number :text line)))))
    (with-open-file (out (concatenate 'string base "spikes/out/cbor-minimal-final-audit-build-extract.lisp")
                         :direction :output :if-exists :error)
      (let ((*print-pretty* t)) (write report :stream out) (terpri out)))
    (let ((*print-pretty* t)) (write report) (terpri))))
