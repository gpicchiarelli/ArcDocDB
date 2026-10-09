(:schema-version 1 :kind :runtime-evidence-audit :scope :cbor-mutation-processes-integration
 :status :passed :source :parent-delivered-independent-audit-results
 :provenance
 ((:reviewer :decisions-mutations :role :read-only-campaign-and-baseline-audit
   :commands ("command-3.lisp" "command-4.lisp" "command-5.lisp"))
  (:reviewer :decisions-tests :role :read-only-minimal-self-cli-core-and-spike-audit
   :commands ("command-0.lisp" "command-1.lisp" "command-2.lisp"))
  (:parent :root :role :relay-and-six-command-record-reading))
 :campaigns
 (:status :ok :baseline-tests 392 :baseline-smoke-lines 2 :module-count 11
  :module-total 392 :baseline-completion-lines 1 :baseline-exit-code 0 :baseline-signal nil
  :mutants 27 :detected 27 :mutant-exit-code 1 :mutant-signals nil
  :runtime-unhandled-condition :present :completion-marker :absent
  :compilation-failure :absent :worker-errors 0
  :source-fingerprints 123 :before-after :equal :source-consistency :stable)
 :command-records
 (:count 6 :source-blobs 459 :before-after :equal :source-consistency :stable
  :ordinary-status :ok :ordinary-exit-code 0
  :negative-cli-status :failed :negative-cli-exit-code 1
  :negative-cli-diagnostic (:tool-file-name :cod-61))
 :minimal-standalone-fixture
 (:schema-version 1 :status :passed :stage :complete :worker-errors 2
  :signal-child (:exit-code 137 :signal 9 :result :worker-error :baseline-status :worker-error :detected nil)
  :completion-child (:exit-code 7 :signal nil :result :worker-error :baseline-status :worker-error :detected nil)
  :runner-and-log-presence :verified
  :injected-baseline-subreports 2 :subreport-status :passed :subreport-worker-errors 1
  :subreport-exit-code nil :subreport-signal nil :subreport-diagnostic :infrastructure-error)
 :core-and-spikes
 (:test-modules 11 :total-tests 392 :smoke :passed :global-status :complete :runs 10
  :spk-07-status :pass :other-spike-statuses :ok)
 :limits (:passive-original-record-reading-only :not-a-new-product-execution
          :audit-outcomes-relayed-by-parent :not-a-new-audit-by-collector
          :original-spk-07-pass-and-negative-cli-failed-preserved
          :not-c1-or-mcdc-or-complete-recovery-or-engine-qualification))
