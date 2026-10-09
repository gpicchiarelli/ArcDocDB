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
(defparameter *cm-audit-partitions*
  '((:path "src/codec/cbor-float-minimal.lisp"
     :git-blob "ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f"
     :html "b5f35c3f3adc77420ac318a47cebed2c.html"
     :expression-covered 151 :expression-total 184 :branch-covered 31 :branch-total 40
     :declaration-top-forms (0 1 2 4 6) :declaration-lines (4 5 8 30 50)
     :declarative-expressions 5 :internal-error-expressions 28 :internal-guard-branch-outcomes 9
     :error-sites
     ((:line 16 :guard-line 15 :source-path (3 4 3 2) :reason :cbor-float32-fields :expressions 4 :branches 2)
      (:line 26 :guard-line 25 :source-path (3 4 4 2 2) :reason :cbor-float32-alignment :expressions 4 :branches 1)
      (:line 37 :guard-line 36 :source-path (5 4 2) :reason :cbor-float64-significand :expressions 4 :branches 1)
      (:line 39 :guard-line 38 :source-path (5 5 2) :reason :cbor-float64-shift :expressions 4 :branches 1)
      (:line 46 :guard-line 45 :source-path (5 6 2 2) :reason :cbor-float64-alignment :expressions 4 :branches 1)
      (:line 58 :guard-line 57 :source-path (7 4 3 2) :reason :cbor-float64-fields :expressions 4 :branches 2)
      (:line 68 :guard-line 67 :source-path (7 4 4 2 2) :reason :cbor-float64-alignment :expressions 4 :branches 1)))
    (:path "src/codec/cbor-minimal.lisp"
     :git-blob "761302dad1073c841397f6c88d595b114af8d9ef"
     :html "4aa7a033acb28fa71977ad7f38fd6e95.html"
     :expression-covered 107 :expression-total 148 :branch-covered 21 :branch-total 28
     :declaration-top-forms (0 1 2 4 6) :declaration-lines (4 5 8 27 44)
     :declarative-expressions 5 :internal-error-expressions 36 :internal-guard-branch-outcomes 7
     :error-sites
     ((:line 15 :guard-line 14 :source-path (3 4 2) :reason :cbor-minimal-ai :expressions 4 :branches 1)
      (:line 17 :guard-line 16 :source-path (3 5 2) :reason :cbor-minimal-words :expressions 4 :branches 1)
      (:line 24 :guard-line 24 :source-path (3 6 3 6 1) :reason :cbor-minimal-ai :expressions 4 :branches 0)
      (:line 34 :guard-line 33 :source-path (5 4 2) :reason :cbor-minimal-ai :expressions 4 :branches 1)
      (:line 36 :guard-line 35 :source-path (5 5 2) :reason :cbor-minimal-words :expressions 4 :branches 1)
      (:line 41 :guard-line 41 :source-path (5 6 5 1) :reason :cbor-minimal-ai :expressions 4 :branches 0)
      (:line 57 :guard-line 56 :source-path (7 4 3 2) :reason :cbor-minimal-progress :expressions 6 :branches 2)
      (:line 59 :guard-line 58 :source-path (7 4 4 2) :reason :cbor-minimal-form :expressions 6 :branches 1)))))
(defun cm-audit-read-source (path)
  (let ((*read-eval* nil))
    (with-open-file (stream path)
      (loop for form = (read stream nil :eof) until (eq form :eof) collect form))))
(defun cm-audit-source-node (forms path)
  (let ((node forms))
    (dolist (position path node)
      (unless (and (listp node) (integerp position) (<= 0 position) (< position (length node)))
        (error "Source path cannot be attributed: ~S" path))
      (setf node (nth position node)))))
(defun cm-audit-prefix-p (prefix path)
  (and (<= (length prefix) (length path))
       (equal prefix (subseq path 0 (length prefix)))))
(defun cm-audit-read-text (path)
  (with-open-file (stream path)
    (let ((text (make-string (file-length stream))))
      (subseq text 0 (read-sequence text stream)))))
(defun cm-audit-recorded-at ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC"
            year month day hour minute second)))
(defun cm-audit-build (raw)
  (let* ((wrapper (getf raw :wrapper))
         (files (getf raw :selected))
         (index (cm-audit-read-text
                 (cm-audit-path "spikes/out/cbor-minimal-coverage/cover-index.html")))
         (partitions nil))
    (unless (and (eq (getf wrapper :status) :ok) (eql (getf wrapper :exit-code) 0)
                 (eq (getf wrapper :source-consistency) :stable)
                 (getf wrapper :before-after-equal))
      (error "Recorded coverage wrapper is not OK/stable."))
    (dolist (file files)
      (let* ((path (getf file :path))
             (part (copy-tree (find path *cm-audit-partitions*
                                   :key (lambda (entry) (getf entry :path)) :test #'equal)))
             (forms (cm-audit-read-source (cm-audit-path path)))
             (expr (mapcar #'reverse (getf file :missing-expressions)))
             (branches (mapcar (lambda (entry) (reverse (rest entry)))
                               (getf file :missing-branches)))
             (decl (getf part :declaration-top-forms))
             (sites (getf part :error-sites))
             (blob (find path (getf wrapper :selected-blobs)
                         :key (lambda (entry) (getf entry :path)) :test #'equal)))
        (unless (and (equal (getf blob :before) (getf part :git-blob))
                     (equal (getf blob :after) (getf part :git-blob)))
          (error "Recorded fingerprint differs: ~A" path))
        (dolist (key '(:expression-covered :expression-total :branch-covered :branch-total))
          (unless (= (getf file key) (getf part key)) (error "Unexpected raw count: ~A ~S" path key)))
        (unless (search (format nil "<td>~D</td><td>~D</td>"
                                (getf file :expression-covered) (getf file :expression-total)) index)
          (error "Index expression count differs: ~A" path))
        (unless (search (format nil "<td>~D</td><td>~D</td>"
                                (getf file :branch-covered) (getf file :branch-total)) index)
          (error "Index branch count differs: ~A" path))
        (unless (search (getf part :html) index) (error "Index lacks source HTML: ~A" path))
        (cm-audit-read-text (cm-audit-path
                            (concatenate 'string "spikes/out/cbor-minimal-coverage/" (getf part :html))))
        (dolist (top decl)
          (unless (member (list top) expr :test #'equal) (error "Expected declaration path missing."))
          (unless (member (symbol-name (first (nth top forms))) '("IN-PACKAGE" "DECLAIM") :test #'equal)
            (error "Declaration attribution differs.")))
        (dolist (site sites)
          (let* ((root (getf site :source-path))
                 (node (cm-audit-source-node forms root))
                 (parent (butlast root))
                 (site-expr (remove-if-not (lambda (entry) (cm-audit-prefix-p root entry)) expr))
                 (site-branch (remove-if-not (lambda (entry) (cm-audit-prefix-p parent entry)) branches)))
            (unless (and (eq (first node) 'error)
                         (equal (symbol-name (second (second node))) "INVARIANT-VIOLATION")
                         (eq (getf (cddr node) :reason) (getf site :reason)))
              (error "Internal-error source attribution differs: ~A ~S" path root))
            (unless (and (= (length site-expr) (getf site :expressions))
                         (= (length site-branch) (getf site :branches)))
              (error "Error-site partition differs: ~A line ~D" path (getf site :line)))
            (setf (getf site :missing-expression-paths) site-expr
                  (getf site :missing-branch-paths) site-branch)
            (setf expr (set-difference expr site-expr :test #'equal)
                  branches (set-difference branches site-branch :test #'equal))))
        (setf expr (remove-if (lambda (entry) (and (= (length entry) 1) (member (first entry) decl))) expr))
        (unless (and (null expr) (null branches)) (error "Unclassified raw paths remain: ~A" path))
        (unless (and (= (- (getf file :expression-total) (getf file :expression-covered))
                       (+ (getf part :declarative-expressions) (getf part :internal-error-expressions)))
                     (= (- (getf file :branch-total) (getf file :branch-covered))
                        (getf part :internal-guard-branch-outcomes)))
          (error "Partition does not retain full denominator: ~A" path))
        (setf (getf part :expression-fraction) (/ (getf file :expression-covered) (getf file :expression-total))
              (getf part :branch-fraction) (/ (getf file :branch-covered) (getf file :branch-total))
              (getf part :unmarked-default-expressions) 0
              (getf part :unclassified-source-attribution-expressions) 0
              (getf part :unclassified-source-attribution-branches) 0)
        (push part partitions)))
    (let ((audit
            (list :schema 1 :kind :coverage-audit :subject :cbor-minimal
                  :recorded-at (cm-audit-recorded-at) :reader :storage-commit-review
                  :reader-role :product-author-reading-recorded-coverage-data
                  :statement-source :direct-read-of-recorded-state-complete-html-and-frozen-source
                  :worktree (string-right-trim "/" *cm-audit-base*)
                  :read-policy '(:read-eval nil :single-form-and-eof-checked t
                                 :source-read-only t :load-or-eval-of-reports nil
                                 :product-tests-or-campaigns-run-by-reader nil)
                  :reader-code "spikes/out/cbor-minimal-coverage-reader.lisp"
                  :extraction "spikes/out/cbor-minimal-coverage-extract.lisp"
                  :wrapper (loop for key in '(:path :status :exit-code :source-consistency
                                             :before-after-equal :blob-count :selected-blobs)
                                 append (list key (getf wrapper key)))
                  :fingerprint-scope :two-new-product-sources
                  :raw-state "spikes/out/cbor-minimal-coverage/coverage-state.lisp"
                  :raw-index "spikes/out/cbor-minimal-coverage/cover-index.html"
                  :saved-state-file-count (getf raw :saved-state-file-count)
                  :reported-source-files 2 :html-files-including-index 3
                  :source-path-convention :sbcl-reversed-numeric-path-with-branch-prefix
                  :counts-and-original-missing-paths files
                  :partition-by-file (nreverse partitions)
                  :totals '(:expression-covered 258 :expression-total 332 :expression-fraction 129/166
                            :branch-covered 52 :branch-total 68 :branch-fraction 13/17
                            :missing-expressions 74 :missing-branch-outcomes 16)
                  :missing-partition '(:declarative-expressions 10 :internal-error-expressions 64
                                       :internal-error-sites 15 :internal-guard-branch-outcomes 16
                                       :unmarked-default-expressions 0
                                       :unclassified-source-attribution-expressions 0
                                       :unclassified-source-attribution-branches 0)
                  :classification-limits '(:association-not-unreachability-proof t
                                           :runtime-cause-of-unmarked-declarations :unclassified
                                           :public-gap-assessment :not-inferred-from-source-attribution
                                           :no-claim-complete-public-behavior t
                                           :denominators-retained-in-full t :guard-exclusions nil
                                           :exceptions-approved nil :mcdc-claim nil
                                           :independent-c1-review-claim nil)
                  :audit-utility-attempts '(:attempt-1 :ok :attempt-1-exit-code 0
                                            :attempt-1-original-code "spikes/out/cbor-minimal-coverage-reader-attempt-1.lisp"
                                            :attempt-1-stdout "spikes/out/cbor-minimal-coverage-reader-attempt-1.stdout.log"
                                            :attempt-1-stderr "spikes/out/cbor-minimal-coverage-reader-attempt-1.stderr.log"
                                            :attempt-2 :ok :attempt-2-exit-code 0
                                            :attempt-2-original-code "spikes/out/cbor-minimal-coverage-reader-attempt-2.lisp"
                                            :attempt-2-stdout "spikes/out/cbor-minimal-coverage-reader-attempt-2.stdout.log"
                                            :attempt-2-stderr "spikes/out/cbor-minimal-coverage-reader-attempt-2.stderr.log"
                                            :final-run-original-code "spikes/out/cbor-minimal-coverage-reader-attempt-3.lisp"
                                            :final-run-stdout "spikes/out/cbor-minimal-coverage-reader-attempt-3.stdout.log"
                                            :final-run-stderr "spikes/out/cbor-minimal-coverage-reader-attempt-3.stderr.log")
                  :not-attested '(:full-engine-gate :human-approval :full-profile-validation
                                  :cross-platform-heap-or-throughput :mcdc))))
      (with-open-file (out (cm-audit-path "spikes/out/cbor-minimal-coverage-audit.lisp")
                           :direction :output :if-exists :supersede)
        (let ((*print-pretty* t)) (write audit :stream out) (terpri out)))
      (cm-audit-read-one (cm-audit-path "spikes/out/cbor-minimal-coverage-audit.lisp"))
      (format t "Audit written and safely reread; full raw denominator, two exact source mappings.~%"))))
(cm-audit-build (cm-audit-extract))
