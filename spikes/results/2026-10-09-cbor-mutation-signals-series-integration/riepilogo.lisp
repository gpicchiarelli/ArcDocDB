(:schema-version 1 :kind :series-integration-verification-summary :status :ok
 :integration-head "0fce70f19c44aa36b748ab3beb1cf397643541d4"
 :comparison-main "1cb968d62829b610791ea8a819a6f1aeee6bf68f"
 :core-command "core-command.lisp" :core-status :ok :core-exit-code 0
 :source-consistency :stable :source-blobs-before-after :equal
 :test-modules (28 17 17 15 24 20 66 44 18 95 48 44) :total-tests 436 :smoke :passed
 :spikes 10 :global-spike-status :complete :spk-07-status :pass :other-spikes-status :ok
 :core-before-memory-configuration t
 :prior-cbor-photograph (:main "e07d772" :total-tests 392 :mutants 27 :unchanged t)
 :linux-ci (:run-id 37956507620 :command "ci-linux-command.lisp" :status :failed
            :exit-code 2 :failure :heap-exhausted :product-tests 436 :smoke :passed)
 :native-preservation "native-copy-audit.lisp" :native-files-before-final-check 18
 :final-recorded-verification (:artifact "verifica-finale.lisp" :status :ok :exit-code 0 :source-consistency :stable :source-blobs-before-after :equal :checker-heap-mib 2048) :exact-head-ci (:status :pending-at-publication :required-before-merge t :pull-request "https://github.com/gpicchiarelli/ArcDocDB/pull/5")
 :limits (:original-runtime-statuses-preserved :no-new-cbor-campaign
          :not-c1-or-mcdc-or-engine-qualification))
