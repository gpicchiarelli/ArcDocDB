(:schema 1
 :kind :tool-review
 :subject :cbor-minimal-coverage-and-collection
 :recorded-at "2026-10-09 14:51:25 UTC"
 :formats nil
 :reader :storage-commit-review
 :reader-role :product-author-reviewing-c4-tools
 :statement-source :direct-static-reading
 :worktree "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB"
 :source-fingerprints
 ((:path "tools/foundation-coverage.lisp" :git-blob "554b840090373179043aa39dd6491cd35433552a")
  (:path "spikes/out/cbor-minimal-collection/collect.lisp" :git-blob "12670016a52b29eaedca72bb746343f840824b53")
  (:path "tools/evidence-storage.lisp" :git-blob "fa2b5d36dca0837e2ed5e49b282887b2e110b2b7" :scope :targeted-dependency-reading))
 :reviewer-executed (:product nil :tests nil :compile nil :coverage nil :collector nil :guard nil)
 :new-product-test-corpus-read nil
 :coverage
 (:scope "cbor-minimal"
  :exact-files ("src/codec/cbor-float-minimal.lisp" "src/codec/cbor-minimal.lisp")
  :self-test-positive-file-count 2
  :self-test-negative-cases (:unchanged-header :utf8 :tests-directory :fake-suffix :child-suffix)
  :test-dispatch :arcdocdb-cbor-minimal-tests-run
  :codec-dispatch-includes-new-suite t
  :private-cache-mapping-checked t :warning-promoted-to-error t
  :raw-state-saved-before-filtered-html t :denominator-exclusions nil
  :self-test-runtime :pending :coverage-runtime :pending
  :caller-must-provide-fresh-exclusive-directory t)
 :collection
 (:read-eval nil :single-form-and-eof t :load-or-eval-of-report-data nil
  :trusted-local-tool-loaded "tools/evidence-storage.lisp"
  :byte-and-sha256-before-source-after-and-target-check t
  :process-decoded-record-compared-after-copy t
  :existing-target-refused t :record-data-rewritten nil
  :metadata-policy :read-without-result-inference
  :filtered-tree-extensions ("lisp" "log" "gz")
  :fasl-subtrees-excluded t
  :descriptor-and-current-gz-relative-path-preserved :static
  :append-audits-previous-archive t :append-rewrites-derived-index t
  :atomic-index-publication-or-index-history-claim nil
  :manifest-label-policy :trusted-local-coordinator-input)
 :findings
 ((:id :filtered-tree-descriptor-payload-omitted
   :source-before "4ec1aa3c993f0236caa44bd0ef30867ac37c73b7"
   :path "spikes/out/cbor-minimal-collection/collect.lisp" :lines (43 44 45)
   :cause :lisp-and-log-filter-excluded-gz-payload
   :effect :descriptor-copied-without-payload-while-file-hash-audit-can-pass
   :fixed-by :coordinator-before-collector-run
   :fix :include-gz-with-original-relative-path
   :source-after "12670016a52b29eaedca72bb746343f840824b53"
   :status :static-fix-reviewed-runtime-guard-pending
   :required-guard-cases (:compressed-process-report :compressed-report-in-filtered-tree)
   :product-defect nil))
 :open-current-payload-filter-findings nil
 :pending (:collector-guard :coverage-self-test :product-campaigns :final-bytewise-dataset-audit)
 :limits (:no-independent-c1-product-reading :no-human-approval :no-mcdc
          :no-engine-or-requirement-promotion :benchmark-and-mutator-not-reviewed
          :no-adversarial-manifest-label-boundary :no-atomic-index-publication
          :no-automatic-copy-of-non-gz-descriptor-payload-in-filtered-tree))
