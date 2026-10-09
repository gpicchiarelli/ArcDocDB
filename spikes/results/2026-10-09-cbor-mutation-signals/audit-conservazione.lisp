(:schema-version 1 :kind :evidence-retention-audit :date "2026-10-09"
 :scope :cbor-mutation-processes :status :ok
 :method (:read-eval-nil :verified-evidence-reader
          :utf8-content-reencoding :original-byte-comparison
          :byte-count-comparison :git-blob-comparison
          :native-descriptor-and-gzip-payload-comparison
          :historical-status-counter-and-source-consistency-reading)
 :comparisons
 (:raw-files 72 :original-reports 10 :native-files 28
  :raw-content-byte-identity :passed :raw-byte-counts :passed
  :raw-git-blobs :passed :original-report-plists :passed
  :native-stored-byte-identity :passed :gzip-expanded-byte-identity :passed
  :required-report-log-and-runner-presence :passed)
 :wrappers
 ((:path "fixture-0.lisp" :raw-files 5 :raw-bytes 1796 :original-reports 1
   :git-blob "7a86cdcc72e8c2af29d8824a284f95a807459136")
  (:path "fixture-1.lisp" :raw-files 9 :raw-bytes 3400 :original-reports 3
   :git-blob "328523cb1177e58a9545c32c20471dc7999130c2")
  (:path "fixture-2.lisp" :raw-files 5 :raw-bytes 1796 :original-reports 1
   :git-blob "3477551bd488913f3c01adb4b17bf454681b32c9")
  (:path "fixture-3.lisp" :raw-files 9 :raw-bytes 3400 :original-reports 3
   :git-blob "1a362a5309ba8dc0be837bd3d71a37cb1bd4044d")
  (:path "header-mutazioni.lisp" :raw-files 21 :raw-bytes 174207
   :original-reports 1 :git-blob "4c6b3aaa76be7b37341b00ce2257058f88f4f9c6")
  (:path "struttura-mutazioni.lisp" :raw-files 23 :raw-bytes 211425
   :original-reports 1 :git-blob "2a4359b11e2683b58b6211729f0cabe8b7d01f11"))
 :fixture-observations
 (:root-reports 4 :root-statuses (:passed :passed :passed :passed)
  :root-worker-error-counts (2 2 2 2)
  :signal-fixtures 4 :signal 9 :signal-exit-code 137
  :signal-diagnostic :process-signal
  :completion-fixtures 4 :completion-exit-code 7 :completion-signal nil
  :completion-diagnostic :after-build-completion
  :all-eight-child-results :worker-error :all-eight-child-detected nil
  :structure-infrastructure-subreports 4
  :injected-boundaries (:copy :transport :copy :transport)
  :subreport-statuses (:passed :passed :passed :passed)
  :subreport-worker-error-counts (1 1 1 1)
  :baseline-result :worker-error :baseline-status :worker-error
  :baseline-exit-code nil :baseline-signal nil
  :baseline-diagnostic :infrastructure-error
  :root-and-subreport-originals-with-logs-and-child-runners :preserved)
 :campaign-observations
 ((:path "header-mutazioni.lisp" :status :ok :source-consistency :stable
   :source-fingerprints-before-after :equal
   :baseline-status :ok :baseline-exit-code 0 :baseline-signal nil
   :baseline-test-count 377 :baseline-smoke-lines 2
   :baseline-completion-marker "build e test: nessun avviso, tutti i controlli superati"
   :mutants 9 :detected 9 :mutant-exit-codes (1 1 1 1 1 1 1 1 1)
   :mutant-signals (nil nil nil nil nil nil nil nil nil)
   :worker-errors 0 :baseline-and-nine-mutant-logs-and-runners :preserved)
  (:path "struttura-mutazioni.lisp" :status :ok :source-consistency :stable
   :source-fingerprints-before-after :equal
   :baseline-status :ok :baseline-exit-code 0 :baseline-signal nil
   :baseline-test-count 377 :baseline-smoke-lines 2
   :baseline-completion-marker "build e test: nessun avviso, tutti i controlli superati"
   :mutants 10 :detected 10 :mutant-exit-codes (1 1 1 1 1 1 1 1 1 1)
   :mutant-signals (nil nil nil nil nil nil nil nil nil nil)
   :worker-errors 0 :baseline-and-ten-mutant-logs-and-runners :preserved))
 :command-observations
 (:records 7 :conservations 7 :both-native-files-per-command :byte-identical
  :statuses (:ok :ok :ok :failed :failed :ok :ok)
  :exit-codes (0 0 0 1 1 0 0)
  :source-consistencies (:stable :stable :stable :stable :stable :stable :stable)
  :all-source-blobs-before-after :equal
  :negative-cli-indexes (3 4) :negative-cli-cod61-and-tool-file-name :present
  :conservation-statuses (:ok :ok :ok :ok :ok :ok :ok)
  :conservation-exit-codes (0 0 0 0 0 0 0))
 :native-spike-observations
 (:spike-records 10 :global-records 1 :conservations 1
  :stored-files :byte-identical :source-blobs-before-after :equal
  :spike-statuses (:ok :ok :ok :ok :ok :ok :pass :ok :ok :ok)
  :spike-exit-codes (0 0 0 0 0 0 0 0 0 0)
  :spike-source-consistencies
  (:stable :stable :stable :stable :stable :stable :stable :stable :stable :stable)
  :global-status :complete :global-runs 10 :global-run-artifacts 10
  :conservation-status :ok :conservation-exit-code 0)
 :native-gzip-observations
 ((:path "spikes/0/SPK-07.lisp" :payload "SPK-07.lisp.gz"
   :descriptor-and-payload-native-bytes :identical :verified-reader :passed
   :compressed-bytes 410619 :expanded-bytes 28144119
   :expanded-sha256 "6a1310ae8dbe35e3c69874b175d3588150bd4ce2b72d0f93ab11f58c02d89b1c"
   :expanded-git-blob "e04720821a11f4e76b8d9f4b7da2f61ccc3f5226")
  (:path "spikes/0/report.lisp" :payload "report.lisp.gz"
   :descriptor-and-payload-native-bytes :identical :verified-reader :passed
   :compressed-bytes 467404 :expanded-bytes 28962809
   :expanded-sha256 "d0dd7515eacae7c7f895a8c284fa0855d722afcd7730efe7e2f8a78b0c5ab6cc"
   :expanded-git-blob "c069ae732f45879561e329e78cc196d0f35bc491"))
 :frozen-tool-blobs
 ((:path "tools/cbor-header-mutation.lisp"
   :git-blob "a47d36577af8e249c045096a5f7270cd628f0df8")
  (:path "tools/cbor-structure-mutation.lisp"
   :git-blob "e43405f5a6825f420364f112de951013d36b85ca"))
 :findings nil
 :local-inspection-diagnostics
 (:scope :audit-reader-only :original-outputs :tool-call-transcript
  :events
  ((:exit-code 1 :diagnostic :sbcl-runtime-option-order :corrected t)
   (:exit-code 1 :diagnostic :audit-script-unclosed-form :corrected t)
   (:exit-code 1 :diagnostic :overstrict-audit-assertion
    :detail "SPK-07 conserva :PASS; l'asserzione locale richiedeva soltanto :OK."
    :resolution :original-pass-status-preserved)
   (:exit-code 1 :diagnostic :audit-script-extra-closing-parenthesis
    :detail "Le letture stampate erano complete; forma finale eccedente."
    :resolution :final-short-reader-completed-exit-zero))
  :no-product-or-test-execution t)
 :limits (:retention-audit-only :no-gate-promotion :original-statuses-preserved
          :no-new-product-or-test-run :no-product-tool-or-doc-changes
          :not-c1-or-mcdc :not-engine-qualification
          :historical-static-review-status-not-rewritten))
