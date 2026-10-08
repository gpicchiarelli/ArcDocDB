(:schema-version 1 :kind :c1-review :date "2026-10-08"
 :scope "src/recovery/" :review-kind :independent-agent-readings
 :source-blobs ((:path "src/recovery/package.lisp" :git-blob "b97b5c9bca6955e5dc45d9d4257089ab7132f3fb") (:path "src/recovery/scan.lisp" :git-blob "7ad6b7541397611f1ecbda7dffdda98c4453dbf1"))
 :reviews
 ((:reviewer "/root/segment_header_code" :reading :first
   :checks (:explicit-contracts :bounded-loops :typed-errors :no-buffer-mutation
            :no-replay :strict-compilation :lint) :outcome :no-blocking-defect)
  (:reviewer "/root/scan_audit" :reading :second
   :checks (:batch-start-prefix :strict-durable-frontier :bytewise-search
            :error-propagation :physical-eof :finite-budgets :c1-checklist
            :independent-bitwise-oracles :coverage-review)
   :outcome :no-blocking-defect
   :follow-up :public-batch-byte-budget-type-regression))
 :limits (:memory-scanner-only :not-engine-recovery :not-human-approval
          :not-mcdc :not-release-gate-qualification))
