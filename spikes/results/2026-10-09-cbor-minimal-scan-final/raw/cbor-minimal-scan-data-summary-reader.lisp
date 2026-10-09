;;;; Solo estrazione del referto gia registrato e confronto bytes dello stato.
(require :asdf)
(load "tools/evidence-storage.lisp")
(let* ((path "spikes/out/cbor-minimal-scan-data-audit-attempt-3.lisp")
       (data (arcdocdb.evidence:read-evidence path))
       (bench (getf data :benchmark)) (mutations (getf data :mutations))
       (coverage (getf data :coverage))
       (original (getf coverage :original-state))
       (original-bytes (arcdocdb.evidence:file-bytes original))
       (original-sha (arcdocdb.evidence:file-sha256 original))
       (expanded (arcdocdb.evidence:call-with-evidence-bytes
                  (getf coverage :raw-state)
                  (lambda (plain) (list :bytes (arcdocdb.evidence:file-bytes plain)
                                        :sha256 (arcdocdb.evidence:file-sha256 plain)))))
       (equal-bytes (and (= original-bytes (getf expanded :bytes))
                         (string= original-sha (getf expanded :sha256))))
       (supplement (list :schema-version 1 :kind :coverage-bytewise-preservation-audit
                         :status (if equal-bytes :ok :failed)
                         :audit path :audit-sha256 (arcdocdb.evidence:file-sha256 path)
                         :source-reader "spikes/out/cbor-minimal-scan-data-summary-reader.lisp"
                         :original-state original :original-bytes original-bytes :original-sha256 original-sha
                         :descriptor (getf coverage :raw-state) :expanded expanded
                         :expanded-bytewise-equal-to-original equal-bytes
                         :read-eval nil :load-of-product-or-data nil
                         :limits '(:per-file-local-observation :no-atomic-snapshot))))
  (with-open-file (out "spikes/out/cbor-minimal-scan-data-bytewise-supplement.lisp"
                       :direction :output :if-exists :error :if-does-not-exist :create)
    (let ((*print-readably* t)) (write supplement :stream out :pretty t) (terpri out)))
  (format t "Audit ~S, ~D checks, ~D findings.~%" (getf data :status) (getf data :checks) (length (getf data :findings)))
  (format t "Benchmark ~D cells/~D samples, heaps~S; cold arities~S; baseline ~D positive ~D.~%"
          (getf bench :cells) (getf bench :samples) (getf bench :heap-values) (getf bench :cold-value-counts)
          (getf (getf bench :baseline) :heap-bytes) (getf (getf bench :positive-control) :heap-bytes))
  (format t "Mutation baseline markers ~D, completion line~S; detected ~D survived ~D invalid ~D worker~D.~%"
          (getf (getf mutations :baseline-log) :ok-marker-count) (getf (getf mutations :baseline-log) :completion-line)
          (getf mutations :detected) (getf mutations :survived) (getf mutations :invalid) (getf mutations :worker-errors))
  (dolist (entry (getf mutations :mapping))
    (let ((log (getf entry :log)))
      (format t "Mutant ~D ~A~%  rejection line ~D ~S~%  test ~S~%  last pass ~S~%  helper ~S~%"
              (getf entry :index) (getf entry :name) (getf log :first-rejection-line)
              (getf log :first-rejection) (getf log :first-test-frame)
              (getf log :last-passed-test) (getf log :helper-rejection-frame))))
  (format t "Coverage totals ~S, savedstate files ~D.~%" (getf coverage :totals) (getf coverage :saved-state-file-count))
  (dolist (entry (getf coverage :files))
    (let ((part (getf entry :partition)))
      (format t "~A expr~D/~D branch~D/~D.~%  partition ~S~%  error sites ~S~%  missing branches ~S~%  defaults ~S~%"
              (getf entry :path) (getf entry :expression-covered) (getf entry :expression-total)
              (getf entry :branch-covered) (getf entry :branch-total)
              (loop for key in '(:declarative-expressions :internal-error-expressions :unmarked-default-expressions
                                :unclassified-expressions :internal-guard-branch-outcomes :unclassified-branch-outcomes)
                    append (list key (getf part key)))
              (getf part :error-sites) (getf part :internal-guard-paths) (getf part :default-paths))))
  (format t "Expanded coverage state original byte equality ~S, ~D bytes.~%" equal-bytes original-bytes)
  (unless (and (eq :ok (getf data :status)) equal-bytes) (sb-ext:exit :code 1)))
