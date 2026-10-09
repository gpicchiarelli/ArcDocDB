(:schema-version 1 :kind :integration-method :date "2026-10-09"
 :scope :cbor-mutation-processes-with-minimal-profile
 :integration-head "9ce0e6e287d518e9f3f4c091805cc5aff4e2cf62"
 :new-main-short-ref "e07d772"
 :registration :before-new-recorded-executions
 :runtime-evidence :not-collected
 :expected-results-not-observations
 (:total-tests 392 :smoke :passed :spikes 10
  :mutants ((:minimal 8) (:header 9) (:structure 10))
  :successful-command-exit-code 0 :negative-cli-exit-code 1
  :source-consistency :stable :campaign-worker-errors 0)
 :unchanged-prior-tools
 ((:file "tools/cbor-header-mutation.lisp"
   :git-blob "a47d36577af8e249c045096a5f7270cd628f0df8")
  (:file "tools/cbor-structure-mutation.lisp"
   :git-blob "e43405f5a6825f420364f112de951013d36b85ca"))
 :minimal-tool-freeze :after-c4-fix-and-independent-review-before-execution
 :prior-observed-evidence
 (:catalog "spikes/results/2026-10-09-cbor-mutation-signals/catalogo.lisp"
  :total-tests 377 :smoke :passed :preservation :original-bytes-and-statuses)
 :planned
 ((:command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
             "tools/cbor-minimal-mutation.lisp" "--self-test")
   :expected-status :ok)
  (:command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
             "tools/cbor-minimal-mutation.lisp" "--invalid")
   :expected-status :failed :expected-exit-code 1
   :required-diagnostic (:tool-file-name :cod-61))
  (:command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
             "tools/cbor-header-mutation.lisp" "--run"
             "spikes/out/cbor-header-signals-integrated/")
   :expected-mutants 9)
  (:command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
             "tools/cbor-structure-mutation.lisp" "--run"
             "spikes/out/cbor-structure-signals-integrated/")
   :expected-mutants 10)
  (:command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
             "tools/cbor-minimal-mutation.lisp" "--run"
             "spikes/out/cbor-minimal-signals-integrated/")
   :expected-mutants 8)
  (:command ("make" "check-core") :expected-tests 392 :expected-spikes 10)
  (:command ("make" "evidence" "trace" "links") :after-flat-publication t))
 :recording
 (:all-commands-via "tools/record-command.lisp"
  :actual-argv-environment-output-exit-and-source-hashes :required
  :no-source-or-index-mutation-during-recorded-execution
  :fresh-owned-campaign-directories :required
  :parallel-campaigns-in-independent-copies :permitted)
 :required-observations
 (:baseline-smoke-and-exact-build-completion :required
  :baseline-zero-exit-and-no-signal :required
  :all-three-run-commands-invoke-self-test :required
  :real-signal-child (:signal 9 :classification :worker-error :detected nil)
  :real-completion-child (:exit-code 7 :signal nil :classification :worker-error :detected nil)
  :child-target :own-pid-only
  :save-fixture-results-before-assertions :required
  :baseline-and-mutant-exit-signal-counters :required
  :preserve-fixture-campaign-report-log-and-generated-runner :required
  :negative-cli-status :failed)
 :publication
 (:catalog-artifact-names :leaf-only
  :command-records "command-N.lisp"
  :command-conservations "command-N-conservazione.lisp"
  :spike-records "SPK-NN.lisp"
  :global-spike-record "spikes-report.lisp"
  :global-spike-payload "report.lisp.gz"
  :spike-conservation "spikes-conservazione.lisp"
  :final-command "verifica-finale.lisp"
  :final-command-conservation "verifica-finale-conservazione.lisp"
  :native-bytes-and-payload-names :unchanged
  :raw-wrapper-content-byte-count-and-git-blob :verified
  :all-schema-one-leaf-records :catalogued
  :failed-or-preliminary-evidence :preserved-with-original-status)
 :limits
 (:tools-only-c4-correction :codec-product-tests-and-formats-not-changed-by-c4
  :minimal-profile-product-arrives-from-main
  :prior-377-test-photograph-unchanged
  :no-coverage-or-benchmark-repeat :no-worker-timeout
  :not-c1-or-mcdc-or-complete-recovery-or-engine-qualification
  :expected-counts-do-not-attest-runtime-success))
