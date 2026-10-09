;;;; Recorded-data reader only. No product, test or coverage execution.
(defun cm-audit-read-one (path)
  (let ((*read-eval* nil))
    (with-open-file (stream path)
      (let ((data (read stream nil :eof)))
        (when (eq data :eof) (error "Empty audit input: ~A" path))
        (unless (eq (read stream nil :eof) :eof)
          (error "More than one form in audit input: ~A" path))
        data))))
(defparameter *cm-audit-base*
  "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/")
(defparameter *cm-audit-sources*
  '("src/codec/cbor-float-minimal.lisp" "src/codec/cbor-minimal.lisp"))
(defparameter *cm-audit-wrapper*
  "spikes/out/4000546897-command-81110-0/report.lisp")
(defun cm-audit-path (path) (concatenate 'string *cm-audit-base* path))
(defun cm-audit-blob (file entries)
  (getf (find file entries :key (lambda (entry) (getf entry :path))
             :test #'equal) :git-blob))
(defun cm-audit-extract ()
  (let* ((wrapper (cm-audit-read-one (cm-audit-path *cm-audit-wrapper*)))
         (before (getf wrapper :source-blobs-before))
         (after (getf wrapper :source-blobs-after))
         (state (cm-audit-read-one
                 (cm-audit-path "spikes/out/cbor-minimal-coverage/coverage-state.lisp")))
         (selected
           (loop for file in *cm-audit-sources*
                 for entry = (find (cm-audit-path file) state :key #'first :test #'equal)
                 collect
                 (progn
                   (unless entry (error "Source absent from saved state: ~A" file))
                   (let ((paths (second entry)) (bits (cddr entry)))
                     (unless (= (length paths) (length bits))
                       (error "Paths and bits have different lengths: ~A" file))
                     (list :path file
                           :expression-covered
                           (loop for path across paths for bit across bits
                                 count (and (numberp (first path)) (= bit 1)))
                           :expression-total
                           (loop for path across paths count (numberp (first path)))
                           :branch-covered
                           (loop for path across paths for bit across bits
                                 count (and (keywordp (first path)) (= bit 1)))
                           :branch-total
                           (loop for path across paths count (keywordp (first path)))
                           :missing-expressions
                           (loop for path across paths for bit across bits
                                 when (and (numberp (first path)) (= bit 0)) collect path)
                           :missing-branches
                           (loop for path across paths for bit across bits
                                 when (and (keywordp (first path)) (= bit 0)) collect path)))))))
    (let ((data
            (list :wrapper
                  (list :path *cm-audit-wrapper* :status (getf wrapper :status)
                        :exit-code (getf wrapper :exit-code)
                        :source-consistency (getf wrapper :source-consistency)
                        :before-after-equal (equal before after)
                        :blob-count (length before)
                        :selected-blobs
                        (loop for file in *cm-audit-sources* collect
                          (list :path file :before (cm-audit-blob file before)
                                :after (cm-audit-blob file after)))
                        :stdout (getf wrapper :stdout) :stderr (getf wrapper :stderr))
                  :saved-state-file-count (length state) :selected selected)))
      (with-open-file (out (cm-audit-path "spikes/out/cbor-minimal-coverage-extract.lisp")
                           :direction :output :if-exists :supersede)
        (let ((*print-pretty* t)) (write data :stream out) (terpri out)))
      (cm-audit-read-one (cm-audit-path "spikes/out/cbor-minimal-coverage-extract.lisp"))
      (format t "Wrapper ~S, exit ~S, source ~S; before/after equal ~S; ~D blobs.~%"
              (getf wrapper :status) (getf wrapper :exit-code)
              (getf wrapper :source-consistency) (equal before after) (length before))
      (dolist (file selected)
        (format t "~A expressions ~D/~D; branches ~D/~D.~%Missing expressions: ~S~%Missing branches: ~S~%"
                (getf file :path) (getf file :expression-covered)
                (getf file :expression-total) (getf file :branch-covered)
                (getf file :branch-total) (getf file :missing-expressions)
                (getf file :missing-branches)))
      data)))
(cm-audit-extract)
