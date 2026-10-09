(:schema-version 1 :kind :checker-memory-method
 :registration :before-new-recorded-memory-check
 :observed-ci (:run-id 37956507620 :head "bffbdd017efca5a3020c1a314bb6c8c0078a9818"
              :tested-merge "d3b3d9f1f56f93593b4649fcadcb14cb059b218f"
              :linux-command "ci-linux-command.lisp" :status :failed :exit-code 2
              :source-consistency :stable :product-tests 436 :smoke :passed
              :failure :heap-exhausted :dynamic-space-bytes 1073741824
              :allocated-bytes 953125488 :requested-allocation-bytes 55866624
              :historical-record "spikes/results/2026-10-09-writer-handoff/spikes-integrati.lisp"
              :historical-expanded-bytes 28962971)
 :configuration (:file "Makefile" :git-blob "718394b890d58b69e660fc401c3ff3fa31c5793d"
                 :variable "EVIDENCE_DYNAMIC_SPACE_SIZE" :default-mib 2048
                 :scope :evidence-recipe-only)
 :static-readings (:root :decisions-mutations) :outcome :no-static-blocker
 :planned-command ("make" "evidence" "trace" "links")
 :expected-not-observed (:status :ok :exit-code 0 :source-consistency :stable)
 :final-ci :exact-pushed-head-required
 :limits (:checker-reader-product-and-file-limits-unchanged
          :original-ci-failure-preserved :no-default-heap-difference-asserted
          :not-c1-or-mcdc-or-engine-qualification))
