;;;; Independent reader: never load or call the collector or product.
(defparameter *pa-base* "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/")
(defparameter *pa-root* (concatenate 'string *pa-base* "spikes/results/2026-10-09-cbor-minimal/"))
(defparameter *pa-prefix* (concatenate 'string *pa-base* "spikes/out/cbor-minimal-publication-audit"))
(defvar *pa-check-count* 0)
(defvar *pa-findings* nil)
(defvar *pa-inventory-sequence* 0)
(defun pa-path (relative) (concatenate 'string *pa-base* relative))
;; Only the invariant plain/descriptor dependency, never collector or product.
(load (pa-path "tools/evidence-storage.lisp"))
(defun pa-read-one (path)
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)))
    (with-open-file (stream path)
      (let* ((eof (gensym "EOF")) (data (read stream nil eof)))
        (when (eq data eof) (error "Empty input: ~A" path))
        (unless (eq (read stream nil eof) eof) (error "Trailing form: ~A" path))
        data))))
(defun pa-save (path data)
  (with-open-file (stream path :direction :output :if-exists :error)
    (let ((*print-pretty* t)) (write data :stream stream) (terpri stream)))
  (pa-read-one path))
(defun pa-check (condition kind &rest facts)
  (incf *pa-check-count*)
  (unless condition (push (list* :kind kind facts) *pa-findings*)))
(defun pa-stamp ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D UTC"
            year month day hour minute second)))
(defun pa-directory (path)
  (namestring (make-pathname :name nil :type nil :version nil :defaults path)))
(defun pa-find-file (path entries)
  (find path entries :key (lambda (entry) (getf entry :path)) :test #'equal))
(defun pa-inventory (root &optional (mode "all"))
  (let* ((sequence (incf *pa-inventory-sequence*))
         (output (format nil "~A-inventory-~D.lisp" *pa-prefix* sequence))
         (error-log (format nil "~A-inventory-~D.stderr.log" *pa-prefix* sequence))
         (process (sb-ext:run-program
                   "python3" (list (concatenate 'string *pa-prefix* "-inventory.py") root mode)
                   :search t :wait t :input nil :output output :error error-log
                   :if-output-exists :error :if-error-exists :error)))
    (unwind-protect
         (unless (and (eq (sb-ext:process-status process) :exited)
                      (eql (sb-ext:process-exit-code process) 0))
           (error "Inventory helper failed: ~A" error-log))
      (sb-ext:process-close process))
    (getf (pa-read-one output) :files)))
(defun pa-required-file (path files)
  (pa-check (pa-find-file path files) :required-artifact :path path))
(defun pa-full-audit ()
  (let* ((index-path (concatenate 'string *pa-root* "archive-index.lisp"))
         (index-before (arcdocdb.evidence:file-sha256 index-path))
         (index (pa-read-one index-path))
         (catalogue (pa-read-one (concatenate 'string *pa-root* "catalogo.lisp")))
         (manifest (pa-read-one (concatenate 'string *pa-root* "collection-manifest.lisp")))
         (indexed (getf index :files))
         (actual (pa-inventory *pa-root*))
         (processes (getf index :processes))
         (metadata nil) (expected nil) (group-counts nil))
    (pa-check (and (eql 1 (getf index :schema-version))
                   (eq :original-command-archive (getf index :kind))) :index-schema)
    (pa-check (= (length indexed) (length (remove-duplicates indexed :key (lambda (entry) (getf entry :path)) :test #'equal)))
              :duplicate-indexed-path)
    (pa-check (= (length processes) (length (remove-duplicates processes :key (lambda (entry) (getf entry :label)) :test #'equal)))
              :duplicate-process-label)
    (dolist (entry indexed)
      (let* ((path (getf entry :path)) (observed (pa-find-file path actual)))
        (pa-check observed :indexed-file-absent :path path)
        (when observed
          (pa-check (= (getf entry :bytes) (getf observed :bytes)) :indexed-byte-count :path path)
          (pa-check (equal (getf entry :sha256) (getf observed :sha256)) :indexed-sha256 :path path))))
    (let ((extras (remove-if (lambda (entry) (or (pa-find-file (getf entry :path) indexed)
                                                 (member (getf entry :path) '("archive-index.lisp" "catalogo.lisp") :test #'equal))) actual)))
      (pa-check (null extras) :unindexed-archive-files :paths (mapcar (lambda (entry) (getf entry :path)) extras)))
    (pa-check (search "archive-index.lisp" (prin1-to-string catalogue)) :catalogue-index-reference)
    (dolist (mandatory '("preliminary" "coverage-self" "mutation-self" "benchmark" "coverage" "mutations"
                         "collection-guard-first" "collection-guard"))
      (pa-check (find mandatory processes :key (lambda (entry) (getf entry :label)) :test #'equal)
                :mandatory-process :label mandatory))
    (dolist (process processes)
      (let* ((label (getf process :label))
             (relative (getf process :record-path))
             (record-entry (pa-find-file relative indexed))
             (source-path (getf record-entry :source))
             (declared (assoc label (getf manifest :processes) :test #'equal))
             (record (arcdocdb.evidence:read-evidence (concatenate 'string *pa-root* relative)))
             (source (arcdocdb.evidence:read-evidence source-path)))
        (when declared
          (pa-check (equal source-path (namestring (merge-pathnames (second declared) *pa-base*)))
                    :mandatory-process-source :label label))
        (dolist (key '(:command :status :exit-code :source-consistency))
          (pa-check (equal (getf process key) (getf record key)) :process-metadata :label label :field key))
        (pa-check (equal source record) :decoded-source-copy :label label)
        (push (loop for key in '(:label :record-path :status :exit-code :source-consistency :command)
                    append (list key (getf process key))) metadata)
        (let ((inventory (pa-inventory (pa-directory source-path))))
          (push (list :kind :process :label label :files (length inventory)) group-counts)
          (dolist (entry inventory)
            (push (list :path (concatenate 'string "processes/" label "/" (getf entry :path))
                        :bytes (getf entry :bytes) :sha256 (getf entry :sha256)) expected)))))
    (dolist (tree (getf manifest :trees))
      (let* ((label (first tree))
             (directory (namestring (merge-pathnames (second tree) *pa-base*)))
             (inventory (pa-inventory directory (if (eq (third tree) :lisp-and-log) "filtered" "all"))))
        (push (list :kind :tree :label label :files (length inventory) :mode (third tree)) group-counts)
        (dolist (entry inventory)
          (push (list :path (concatenate 'string "raw/" label "/" (getf entry :path))
                      :bytes (getf entry :bytes) :sha256 (getf entry :sha256)) expected))))
    (dolist (declared (getf manifest :files))
      (let ((source (second declared)))
        (push (list :path (concatenate 'string "raw/" (first declared))
                    :bytes (arcdocdb.evidence:file-bytes source)
                    :sha256 (arcdocdb.evidence:file-sha256 source)) expected)))
    (dolist (pair '(("collection-manifest.lisp" . "spikes/out/cbor-minimal-collection/manifest.lisp")
                    ("collection-source.lisp" . "spikes/out/cbor-minimal-collection/collect.lisp")))
      (push (list :path (car pair) :bytes (arcdocdb.evidence:file-bytes (pa-path (cdr pair)))
                  :sha256 (arcdocdb.evidence:file-sha256 (pa-path (cdr pair)))) expected))
    (dolist (entry expected)
      (let ((published (pa-find-file (getf entry :path) indexed)))
        (pa-check published :expected-copy-omitted :path (getf entry :path))
        (when published
          (pa-check (and (= (getf entry :bytes) (getf published :bytes))
                         (equal (getf entry :sha256) (getf published :sha256)))
                    :expected-copy-fingerprint :path (getf entry :path)))))
    (pa-check (null (set-difference (mapcar (lambda (entry) (getf entry :path)) indexed)
                                   (mapcar (lambda (entry) (getf entry :path)) expected) :test #'equal))
              :index-outside-declared-scope)
    (dolist (file '("raw/coverage/cover-index.html" "raw/coverage/coverage-state.lisp"
                    "raw/coverage/b5f35c3f3adc77420ac318a47cebed2c.html"
                    "raw/coverage/4aa7a033acb28fa71977ad7f38fd6e95.html"
                    "raw/mutations/baseline/test.log"
                    "raw/collection-tools/guard-run-01/report.lisp"
                    "raw/collection-tools/guard-run-02/report.lisp"
                    "raw/cbor-minimal-measurement-reader-first.lisp"
                    "raw/cbor-minimal-measurement-reader-first.log"
                    "raw/cbor-minimal-measurement-reader-v2.lisp"
                    "raw/cbor-minimal-measurement-reader-v2.log"))
      (pa-required-file file indexed))
    (loop for mutant below 8 do
      (pa-required-file (format nil "raw/mutations/~D/test.log" mutant) indexed)
      (dolist (source '("src/codec/cbor-float-minimal.lisp" "src/codec/cbor-minimal.lisp"))
        (pa-required-file (format nil "raw/mutations/~D/~A" mutant source) indexed)))
    (loop for attempt from 1 to 3 do
      (dolist (suffix '("lisp" "stdout.log" "stderr.log"))
        (pa-required-file (format nil "raw/cbor-minimal-coverage-reader-attempt-~D.~A" attempt suffix) indexed)))
    (let ((second-inventory (pa-inventory *pa-root*)))
      (pa-check (equal actual second-inventory) :archive-mutated-during-audit))
    (pa-check (equal index-before (arcdocdb.evidence:file-sha256 index-path)) :index-mutated-during-audit)
    (let ((audit
            (list :schema-version 1 :kind :independent-publication-audit :subject :cbor-minimal
                  :recorded-at (pa-stamp) :status (if *pa-findings* :failed :ok)
                  :statement-source :direct-recorded-data-and-independent-file-inventory
                  :reader :storage-commit-review :reader-role :product-author-independent-of-collector
                  :archive "spikes/results/2026-10-09-cbor-minimal/"
                  :archive-index-sha256 index-before :snapshot-scope :index-at-audit-time-before-publication-of-this-audit
                  :checks *pa-check-count* :findings (nreverse *pa-findings*)
                  :indexed-files (length indexed) :expected-files (length expected)
                  :actual-files (length actual) :unindexed-derived-files '("archive-index.lisp" "catalogo.lisp")
                  :total-indexed-bytes (reduce #'+ indexed :key (lambda (entry) (getf entry :bytes)) :initial-value 0)
                  :process-count (length processes) :process-metadata (nreverse metadata)
                  :group-counts (nreverse group-counts)
                  :index-file-checks :all-indexed-bytes-and-sha256
                  :omission-checks :mandatory-artifacts-and-independent-expansion-of-declared-source-directories
                  :read-policy '(:read-eval nil :eof-required t :report-reader :read-evidence
                                 :collector-loaded-or-called nil :product-or-test-campaigns nil)
                  :tools '(:lisp-reader "spikes/out/cbor-minimal-publication-audit-reader.lisp"
                           :python-inventory "spikes/out/cbor-minimal-publication-audit-inventory.py"
                           :invariant-dependency "tools/evidence-storage.lisp")
                  :limits '(:local-snapshot-not-atomic-publication :no-release-or-requirement-promotion
                            :fasl-directories-excluded-from-published-trees
                            :future-appends-change-index-and-require-distinct-audit))))
      (pa-save (concatenate 'string *pa-prefix* ".lisp") audit)
      (format t "Independent publication audit ~S: ~D checks, ~D indexed files, ~D processes, ~D findings.~%"
              (getf audit :status) *pa-check-count* (length indexed) (length processes) (length (getf audit :findings)))
      (when *pa-findings* (format t "Findings: ~S~%" (getf audit :findings)))
      (sb-ext:exit :code (if *pa-findings* 1 0)))))
(pa-full-audit)
