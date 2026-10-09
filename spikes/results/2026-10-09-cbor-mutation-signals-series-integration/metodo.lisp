(:schema-version 1 :kind :integration-method :date "2026-10-09"
 :scope :cbor-mutation-processes-with-series-controller-wal
 :new-main-short-ref "1cb968d" :prior-integration-short-ref "bffbdd0"
 :registration :before-new-recorded-executions
 :runtime-evidence :not-collected
 :expected-results-not-observations
 (:successful-command-status :ok :successful-command-exit-code 0
  :source-consistency :stable :test-count :observe-from-new-core-run)
 :required-impact-comparison
 (:three-cbor-mutation-tools-and-target-codecs :unchanged
  :reviewer :independent-agent :role :read-only-source-comparison
  :series-product-review :outside-this-scope)
 :planned
 ((:command ("make" "check-core") :after-integration-and-source-freeze t)
  (:command ("make" "evidence" "trace" "links") :after-flat-publication t)
  (:check :github-ci :revision :exact-pushed-integration-head))
 :recording
 (:local-commands-via "tools/record-command.lisp"
  :actual-argv-environment-output-exit-and-source-hashes :required
  :no-source-document-or-index-mutation-during-recorded-execution)
 :required-observations
 (:core-module-test-counts-and-smoke :from-original-output
  :ten-spike-original-statuses-and-global-report :from-original-records
  :successful-command-exit-zero-and-source-consistency-stable :required
  :github-ci-exact-head :required-before-publication-complete)
 :prior-observed-evidence
 (:catalog "spikes/results/2026-10-09-cbor-mutation-signals-integration/catalogo.lisp"
  :comparison-main-short-ref "e07d772" :total-tests 392 :smoke :passed
  :mutants (:header 9 :structure 10 :minimal 8)
  :preservation :original-bytes-and-statuses
  :new-cbor-campaign-executions :not-planned)
 :publication
 (:catalog-artifact-names :leaf-only
  :core-command "core-command.lisp"
  :core-conservation "core-command-conservazione.lisp"
  :spike-records "SPK-NN.lisp"
  :global-spike-record "spikes-report.lisp"
  :global-spike-payload "report.lisp.gz"
  :spike-conservation "spikes-conservazione.lisp"
  :final-command "verifica-finale.lisp"
  :final-command-conservation "verifica-finale-conservazione.lisp"
  :method-summary-impact-review-and-native-byte-audit :required
  :native-bytes-and-payload-names :unchanged
  :failed-or-preliminary-evidence :preserved-with-original-status)
 :limits
 (:bounded-integration-build-and-evidence-check
  :no-new-mutation-campaign-or-fixture-execution
  :no-coverage-or-benchmark-repeat :no-other-tool-fix
  :prior-377-and-392-test-photographs-unchanged
  :not-c1-or-mcdc-or-complete-recovery-or-engine-qualification
  :expected-success-does-not-attest-runtime-success))
