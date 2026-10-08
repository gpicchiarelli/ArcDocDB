(:schema-version 1 :kind :evidence-catalog :date "2026-10-08"
 :path-base "spikes/results/2026-10-08/"
 :metadata-policy :read-from-artifact-without-inference
 :entries
 ((:kind :benchmark :formats (1) :variant :baseline
   :artifact "baseline-structured.lisp" :original "baseline.lisp")
  (:kind :benchmark :formats (1) :variant :crc-inline
   :artifact "crc-inline-structured.lisp" :original "crc-inline.lisp")
  (:kind :benchmark :formats (1) :variant :index-inline-100k
   :artifact "index-inline-100k-structured.lisp" :original "index-inline-100k.lisp")
  (:kind :benchmark :formats (1) :variant :index-inline-10m
   :artifact "index-inline-10m-structured.lisp" :original "index-inline-10m.lisp")
  (:kind :allocation-profile :formats (1) :variant :reader-speed2
   :artifact "profile-speed2.lisp")
  (:kind :allocation-profile :formats (1) :variant :reader-speed3-rejected
   :artifact "profile-speed3.lisp")
  (:kind :failed-attempt :formats (1) :variant :profile-compilation
   :artifact "profile-compile-failed.lisp" :process-artifact "profile-compile-failed-process.lisp")
  (:kind :check :formats (1) :variant :protocol-models
   :artifact "protocols-check.lisp")
  (:kind :module-check :formats (1 2) :variant :v2-codec
   :artifact "v2-codec-check.lisp")
  (:kind :module-check :formats (2) :variant :v2-index
   :artifact "v2-indice-check.lisp" :includes-failed-attempts t)
  (:kind :module-check :formats (2) :variant :v2-cbor-initial
   :artifact "v2-cbor-check.lisp")
  (:kind :module-check :formats (1 2) :variant :migration-model
   :artifact "v2-migrazione-check.lisp")
  (:kind :check :formats (1 2) :variant :v2-integration
   :artifact "v2-integration-check.lisp")
  (:kind :benchmark :formats (2) :variant :v2-initial-stack
   :artifact "v2-bench-initial.lisp")
  (:kind :module-check :formats (2) :variant :v2-cbor-lazy-stack
   :artifact "v2-cbor-allocation-check.lisp")
  (:kind :benchmark :formats (2) :variant :v2-lazy-stack
   :artifact "v2-bench-lazy-stack.lisp")
  (:kind :benchmark :formats (2) :variant :v2-lazy-stack-replica
   :artifact "v2-bench-lazy-stack-replica.lisp")
  (:kind :check :formats nil :variant :catalog-check
   :artifact "evidence-check.lisp")
  (:kind :derived-comparison :formats (2) :variant :cbor-allocations
   :artifact "v2-cbor-allocations.lisp")
  (:kind :command-verification :formats (1 2) :variant :full-verification
   :artifact "full-verification.lisp")
  (:kind :check :formats (1 2) :variant :full-spikes-check
   :artifact "full-spikes-check.lisp")
  (:kind :command-verification :formats nil :variant :publication-verification
   :artifact "publication-verification.lisp")
  (:kind :failed-attempt :formats nil :variant :catalog-schema-alias-detection
   :artifact "evidence-check-failed.lisp")
  (:kind :check :formats nil :variant :writer-pool-parking-read-restart
   :artifact "spk04-check.lisp")
  (:kind :benchmark :formats nil :variant :writer-pool-prequeued
   :artifact "spk04-bench.lisp")
  (:kind :command-verification :formats nil :variant :writer-pool-full-verification
   :artifact "spk04-full-check.lisp")
  (:kind :failed-attempt :formats nil :variant :writer-pool-macro-load
   :artifact "spk04-check-initial-failed.lisp"
   :process-artifact "spk04-check-initial-failed-process.lisp")
  (:kind :failed-attempt :formats nil :variant :writer-pool-parking-compilation
   :artifact "spk04-check-parking-failed.lisp"
   :process-artifact "spk04-check-parking-failed-process.lisp")
  (:kind :failed-attempt :formats nil :variant :checkpoint-link-verification
   :artifact "checkpoint-links-failed.lisp")
  (:kind :command-verification :formats (1 2) :variant :checkpoint-clean-checkout
   :artifact "checkpoint-verification.lisp")
  (:kind :command-verification :formats nil :variant :seqlock-observation-orders
   :artifact "spk07-memoria-check.lisp")
  (:kind :check :formats nil :variant :protocol-models-extended
   :artifact "spk07-integrated-check.lisp")
  (:kind :module-check :formats nil :variant :fragment-publication
   :artifact "spk07-pubblicazione-final.lisp")
  (:kind :failed-attempt :formats nil :variant :fragment-publication-runtime-arguments
   :artifact "spk07-pubblicazione-001-failed.lisp")
  (:kind :module-check :formats nil :variant :fragment-publication-counter-corrected-later
   :artifact "spk07-pubblicazione-002.lisp")
  (:kind :recorder-negative-control :formats nil :variant :publication-state-budget
   :artifact "spk07-pubblicazione-state-budget.lisp")
  (:kind :recorder-negative-control :formats nil :variant :publication-step-budget
   :artifact "spk07-pubblicazione-step-budget.lisp")
  (:kind :failed-attempt :formats nil :variant :snapshot-expiry-compilation
   :artifact "spk07-scadenza-001-failed.lisp")
  (:kind :module-check :formats nil :variant :snapshot-expiry-counter-corrected-later
   :artifact "spk07-scadenza-002.lisp")
  (:kind :module-check :formats nil :variant :snapshot-expiry
   :artifact "spk07-scadenza-003.lisp")
  (:kind :module-check :formats nil :variant :compaction-with-active-writer
   :artifact "spk07-compaction-campaign.lisp" :includes-failed-attempts t)
  (:kind :command-verification :formats nil :variant :protocols-trace-regeneration
   :artifact "spk07-final-trace-write.lisp")
  (:kind :command-verification :formats (1 2) :variant :protocols-clean-checkout-final
   :artifact "spk07-final-verification.lisp")
  (:kind :check :formats (1 2) :variant :full-spikes-with-protocol-extensions
   :artifact "spk07-final-spikes-check.lisp")
  (:kind :check :formats (2) :variant :segment-read-initial
   :artifact "spk05-check-initial.lisp")
  (:kind :benchmark :formats (2) :variant :segment-read-callback-initial
   :artifact "spk05-bench-initial.lisp")
  (:kind :check :formats (2) :variant :segment-read-native-inline-shared-sap
   :artifact "spk05-check-inline-shared-sap.lisp")
  (:kind :benchmark :formats (2) :variant :segment-read-native-inline-shared-sap
   :artifact "spk05-bench-inline-shared-sap.lisp")
  (:kind :check :formats (2) :variant :segment-read-native-inline-branch-sap
   :artifact "spk05-check.lisp")
  (:kind :benchmark :formats (2) :variant :segment-read-native-inline-branch-sap
   :artifact "spk05-bench.lisp")
  (:kind :command-verification :formats (1 2) :variant :segment-read-full-verification
   :artifact "spk05-full-check.lisp")
  (:kind :failed-attempt :formats (2) :variant :segment-read-controller-compilation
   :artifact "spk05-check-compilation-failed.lisp"
   :process-artifact "spk05-check-compilation-failed-process.lisp")
  (:kind :module-check :formats nil :variant :segment-read-io-first
   :artifact "spk05-io-first-check.lisp")
  (:kind :module-check :formats nil :variant :segment-read-io-short-and-errors
   :artifact "spk05-io-check.lisp")
  (:kind :failed-attempt :formats (2) :variant :segment-read-record-compilation
   :artifact "spk05-record-compilation-failed.lisp")
  (:kind :module-check :formats (2) :variant :segment-read-record-fixtures
   :artifact "spk05-record-check.lisp")
  (:kind :command-verification :formats (1 2) :variant :storage-segment-read-complete-verification
   :artifact "sviluppo-verifica.lisp")
  (:kind :failed-attempt :formats (2) :variant :compaction-copy-compilation
   :artifact "spk06-io-compilation-failed.lisp")
  (:kind :command-verification :formats (2) :variant :compaction-copy-compilation
   :artifact "spk06-io-compilation.lisp")
  (:kind :check :formats (2) :variant :compaction-controller-and-copy
   :artifact "spk06-check.lisp")
  (:kind :benchmark :formats (2) :variant :compaction-copy-interference
   :artifact "spk06-bench.lisp")
  (:kind :derived-comparison :formats (2) :variant :compaction-copy-interference
   :artifact "spk06-comparison.lisp")
  (:kind :command-verification :formats (1 2) :variant :compaction-and-recovery-full-verification
   :artifact "spk06-full-check.lisp")
  (:kind :recorder-negative-control :formats nil :variant :command-exit1
   :artifact "record-command-expected-failure.lisp" :expected-exit-code 1))
 :limits (:local-campaign :partial-product-coverage :no-reference-platform-claim))
