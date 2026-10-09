(:schema-version 1 :kind :integration-impact-review :reviewer :decisions-mutations
 :delivery :parent-agent-message :comparison ("e07d772" "1cb968d")
 :unchanged (:three-cbor-mutation-tools :src-codec :tests-codec :build-tool :ci-workflow)
 :copier (:observed-files 136 :required-series-wal-files 16 :covered 16 :missing nil)
 :required-verification (:recorded-check-core :final-metadata-gate :exact-head-ci)
 :cbor-campaigns (:new-executions :not-required :historical-base "e07d772" :mutants 27)
 :memory-configuration (:file "Makefile" :git-blob "718394b890d58b69e660fc401c3ff3fa31c5793d"
                        :readings (:root :decisions-mutations) :outcome :no-static-blocker
                        :scope :evidence-recipe-only)
 :limits (:read-only-static-comparison :not-new-series-product-review
          :historical-cbor-evidence-not-promoted-to-new-base))
