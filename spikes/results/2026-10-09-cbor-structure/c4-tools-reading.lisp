(:schema-version 1
 :formats nil
 :kind :c4-tools-audit
 :status :ok
 :recorded-at "2026-10-09"
 :reviewer "/root/development_next"
 :mode :static-reading-and-safe-data-inspection
 :product-author-p t
 :independent-product-c1-reading nil
 :human-approval nil
 :worktree "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB"
 :scope (:coverage-driver :collector :collector-guard :preregistered-method)
 :source-fingerprints
 ((:path "tools/foundation-coverage.lisp" :algorithm :md5
   :value "201edfb6a2ea9b754260d441ae56b855")
  (:path "docs/implementazione/cbor-struttura-metodo.md" :algorithm :md5
   :value "64bc79fd8883760a22d14ee5b93141dd")
  (:path "/tmp/collect-cbor-structure-evidence.lisp" :algorithm :md5
   :value "3c285d0822adf20e96b4b5e15d1b3d87")
  (:path "/tmp/cbor-structure-collector-guard-test.lisp" :algorithm :md5
   :value "3da11da5aa727f01ba074fa61c5b7848")
  (:path "/tmp/cbor-structure-collector-guard-test-first.lisp" :algorithm :md5
   :value "f9d078e0210727621c94219c5ca99f2e"))
 :frozen-product-git-blobs
 (("src/codec/cbor-package.lisp" "411212b04f96be32516425aa2a7ac53aac5b921d")
  ("src/codec/cbor-space.lisp" "a8330e50a77b52a6b9044ebbb48f62bb4b3222a3")
  ("src/codec/cbor-scan-input.lisp" "57ffc48cc688a4de8ebec5cb14c1e69c4209704a")
  ("src/codec/cbor-scan-stack.lisp" "c574e87af5e195ddf3f596a4ae527e69c7a3c6a6")
  ("src/codec/cbor-scan-items.lisp" "70272936e323b3e0cb05173c9fb68cb2b614c355")
  ("src/codec/cbor-scan.lisp" "1f89112b43a39d98cf25dc6dfb34e412428ba843"))
 :checks
 ((:id :coverage-exact-terminal-suffix :status :ok
   :observation "Six exact source suffixes; static self-test rejects other codecs, tests, appended suffix and child path.")
  (:id :coverage-suite-selection :status :ok
   :observation "Structure scope runs structure suite; codec scope runs UTF8, header and structure.")
  (:id :coverage-whole-denominator :status :ok
   :observation "Full ASDF state is saved before filtered HTML; declarations and guards are included. Runtime counters pending.")
  (:id :safe-datum-read :status :ok
   :observation "Collector disables read evaluation and requires exactly one form followed by EOF.")
  (:id :original-byte-retention :status :ok
   :observation "Wrapper bytes, all states, coverage state/all HTML and all mutation logs retained; text channels have explicit origin.")
  (:id :absent-channel-domain :status :ok
   :observation "NIL and absent channels preserved explicitly; no invented empty strings.")
  (:id :schema-and-classification :status :ok
   :observation "Formats NIL, schema aliases, basename schema1 top entries and separate raw associations; no inferred mutation outcomes.")
  (:id :fresh-target :status :ok
   :observation "Collector and guard reject existing outputs; coverage caller must provide a new directory.")
  (:id :append-identity :status :ok
   :observation "Single captured prior bytes safely parsed, compared to metadata before write, history retained, stage reread before publication.")
  (:id :guard-toy-provenance :status :ok
   :observation "Root-run v2 11/11 safely read; first failure and rejected attempt preserved. No guard execution by reviewer.")
  (:id :method-contract :status :ok
   :observation "Exact item, separate budgets, tags/chunks node counting, map/array depth, strict chunk UTF8, generic syntax scope match frozen contract. Method separately declares a targeted last-stack-slot fixture added after static product reading; original corpus freeze is retained.")
  (:id :parallel-time-description :status :ok
   :observation "Closed documentation finding: wall-clock overlapping work intervals do not prove simultaneous execution on distinct cores."))
 :closed-findings
 ((:id :first-guard-old-scope-expectation
   :classification :failed-guard-fixture
   :first-result (:status :failed :passed 10 :failed 1)
   :correction "Only guard expectation changed from two old source names to the six exact files."
   :current-result (:status :ok :passed 11 :failed 0))
  (:id :method-wall-clock-description
   :correction "Method now states real-time work intervals and explicitly excludes inference of simultaneous distinct-core execution."))
 :self-test-evidence
 ((:role :first-failed-guard
   :code "/tmp/cbor-structure-collector-guard-test-first.lisp"
   :report "/tmp/cbor-structure-collector-self-test-first.lisp"
   :log "/tmp/cbor-structure-collector-self-test-first.log"
   :read-eval nil :eof-guard t :embedded-stdout-equals-log t
   :executed-by :root :status :failed :passed 10 :failed 1)
  (:role :rejected-repeat-target
   :report "/tmp/cbor-structure-collector-rejected-attempt.lisp"
   :read-eval nil :eof-guard t :status :failed :exit-code 1
   :origin :tool-result-transcription-not-original-byte-stream
   :original-tool-output-complete nil :original-tool-output-truncated t)
  (:role :corrected-guard
   :code "/tmp/cbor-structure-collector-guard-test.lisp"
   :report "/tmp/cbor-structure-collector-self-test-v2.lisp"
   :log "/tmp/cbor-structure-collector-self-test-v2.log"
   :read-eval nil :eof-guard t :embedded-stdout-equals-log t
   :executed-by :root :status :ok :passed 11 :failed 0))
 :pending (:coverage-self-test :product-campaigns :actual-evidence-catalog-integrity
           :root-benchmark-and-mutation-review)
 :limits
 (:no-product-or-build-execution-by-reviewer
  :no-collector-or-guard-execution-by-reviewer
  :benchmark-and-mutator-outside-this-review-scope
  :no-runtime-heap-or-timing-claim
  :no-independent-product-c1-reading
  :no-mcdc-or-runtime-qualification
  :no-human-approval))
