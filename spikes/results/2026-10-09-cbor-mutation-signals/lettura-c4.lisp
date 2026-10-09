(:schema-version 1 :kind :c4-reading :date "2026-10-09"
 :status :static-review-complete :runtime-results :pending
 :source-blobs ((:path "tools/cbor-header-mutation.lisp" :git-blob "a47d36577af8e249c045096a5f7270cd628f0df8")
                (:path "tools/cbor-structure-mutation.lisp" :git-blob "e43405f5a6825f420364f112de951013d36b85ca"))
 :readers ((:name :root :scope :both-tools :role :coordinator)
           (:name :decisions-tests :scope :header :role :structure-tool-author)
           (:name :decisions-mutations :scope :structure :role :header-tool-author)
           (:name :project-access :scope :both-tools :role :independent-reader))
 :observations (:four-value-transport :signal-before-marker-classification
                :nonzero-after-completion-worker-error :completed-zero-survival
                :baseline-and-mutant-infrastructure-boundaries :distinct-worker-counter
                :exact-lf-and-crlf-markers :quoted-markers-rejected
                :real-child-fixtures-through-campaign-transport :raw-report-roundtrip
                :progress-recording :cod61-nonzero-exit :catalog-and-cli-preserved)
 :pre-execution-finding
 (:scope :structure :category :plist-head-propagation
  :read-blob "26529f5fc15559cc447f2efaa5be911f03d6f0f8"
  :reported-by :decisions-mutations :status :corrected-before-execution
  :correction :consume-record-baseline-result-return-at-all-three-call-sites)
 :second-pre-execution-finding
 (:scope :structure :category :failed-fixture-observation-retention
  :read-blob "7cd69e83b6e5eb6f303add54f7166ae315629800"
  :reported-by :decisions-mutations :status :corrected-before-execution
  :correction :save-observed-entry-before-fixture-assertion
  :related-change :schema-one-on-infrastructure-fixture-reports)
 :limits (:static-reading :runtime-confirmation-separate :automated-local-review
          :not-human-approval :not-c1-or-mcdc :not-engine-qualification))
