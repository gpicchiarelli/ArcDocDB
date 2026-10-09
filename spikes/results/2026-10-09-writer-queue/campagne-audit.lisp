(:schema 1
 :kind :writer-queue-data-audit
 :status :ok
 :recorded-at "2026-10-09 04:43:32 UTC"
 :reviewer "/root/storage_commit_review"
 :read-eval nil
 :report-loaded-or-evaluated nil
 :new-campaigns nil
 :repository-edited nil
 :original-review-rewritten nil
 :input-reports
 ("spikes/out/writer-queue-20261009-a-mutations/report.lisp"
  "spikes/out/4000509516-command-23971-0/report.lisp")
 :provenance
 (:review "/tmp/writer-queue-review-2.lisp"
  :review-phase :before-document-results
  :ten-fingerprint-comparison :review-versus-recorded-benchmark-wrapper
  :ten-recorded-wrapper-matches t
  :final-working-tree-comparison-of-all-ten nil
  :note "I dieci match riguardano la snapshot della lettura C1 e il wrapper osservato, prima dei risultati aggiunti a documentazione e CHANGELOG. Non attestano dieci match sulla working tree finale."
  :current-product-test-matches-review 6
  :current-product-test-hash-observation-at "2026-10-09 04:43:32 UTC"
  :documents-changed-after-review
  ((:file "docs/implementazione/code-writer.md"
    :review-and-recorded-wrapper-git-blob "1684e1484fe176c4623ce5d265aeca53c980cfde"
    :observed-current-git-blob "8b8350c21ce87e704e72b8e7b5a261ce49a0bbab"
    :matches-review nil)
   (:file "CHANGELOG.md"
    :recorded-wrapper-git-blob "de5370bb877d7ceccfe2898cf1d41374ff7e34b0"
    :observed-current-git-blob "d12cb4f95269d10c96157a0506d7fb16c349f950"
    :matches-recorded-wrapper nil)))
 :product-and-test-fingerprints
 ((:file "src/execution/package.lisp" :git-blob "06dbbbe0a53f33e1c5b3e77bf9922c2a0da7b46c")
   (:file "src/execution/queue.lisp" :git-blob "11f2674cabe9834937b3e162fe0697ca772cdd70")
   (:file "src/execution/writer.lisp" :git-blob "8e5102497f628796fa8faffa2085a165496af230")
   (:file "tests/execution/support.lisp" :git-blob "b8bac07926727a644f0246f6b57d600332288310")
   (:file "tests/execution/queue.lisp" :git-blob "546d4215f9f63007f632c522f0f8c1e75ac4bbeb")
   (:file "tests/execution/threads.lisp" :git-blob "4212f8cc4be686e923cdbec9ded24f42f1da74ba"))
 :mutation-audit
 (:status :ok
  :source-consistency :stable
  :fingerprints-before-after-equal t
  :fingerprint-count 70
  :baseline
  (:status :ok :exit-code 0 :compilable t
   :log "spikes/out/writer-queue-20261009-a-mutations/baseline/test.log"
   :exact-smoke "ok    package ARCDOCDB presente" :smoke-line 1
   :exact-build-end "build e test: nessun avviso, tutti i controlli superati"
   :build-end-line 183 :execution-test-count 17
   :open-drain-waves 3 :messages-per-wave 144
   :producers-per-wave 3 :consumers-per-wave 2 :workers-per-wave 5
   :worker-reuse t
   :cpu-buffer-bytes-processed 1048576
   :cpu-overlap-ticks 32936 :timer-units-per-second 1000000)
  :mutant-count 8 :detected-count 8
  :classification :runtime-failure-after-exact-smoke
  :compilation-failure-count 0
  :mutants
  ((:index 0 :name "writer-fifo-head" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/0/test.log" :smoke-line 1
    :first-failure-line 33 :test-backtrace-line 45
    :test "TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES"
    :failure :invariant-violation :reason :writer-queue-invariant
    :detail "Il secondo drain usa tail al posto di head e viola la relazione del ring.")
   (:index 1 :name "writer-tail-wrap" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/1/test.log" :smoke-line 1
    :first-failure-line 33 :test-backtrace-line 44
    :test "TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES"
    :failure :invariant-violation :reason :writer-queue-invariant
    :detail "Dopo il primo enqueue head=0, tail=2, count=1.")
   (:index 2 :name "writer-full-boundary" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/2/test.log" :smoke-line 1
    :first-failure-line 33 :test-backtrace-line 44
    :test "TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES"
    :failure :invariant-violation :reason :writer-queue-invariant
    :detail "Enqueue oltre il pieno: count=1025, capacity=1024.")
   (:index 3 :name "writer-guard-busy" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/3/test.log" :smoke-line 1
    :first-failure-line 36 :test-backtrace-line 53
    :test "TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE"
    :failure :assertion :expected-reason :writer-queue-busy
    :detail "Enqueue con guard gia occupata accetta il messaggio invece di rifiutarlo."
    :unhandled-events 2 :secondary-failure :fixture-guard-cleanup)
   (:index 4 :name "writer-thread-owner" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/4/test.log" :smoke-line 1
    :first-failure-line 45 :test-backtrace-line 64
    :test "TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE"
    :failure :assertion :expected-reason :writer-lease
    :detail "Prelievo da thread estraneo non segnala invalid-argument; errore del worker rilanciato dal join.")
   (:index 5 :name "writer-generation-lease" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/5/test.log" :smoke-line 1
    :first-failure-line 41 :test-backtrace-line 58
    :test "TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD"
    :failure :assertion :expected-reason :writer-lease
    :detail "Rilascio del vecchio gettone accettato dopo nuova acquisizione dello stesso thread."
    :unhandled-events 2 :secondary-failure :fresh-lease-cleanup-invalid-argument)
   (:index 6 :name "writer-cumulative-quantum" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/6/test.log" :smoke-line 1
    :first-failure-line 33 :test-backtrace-line 43
    :test "TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES"
    :failure :assertion :expected-count 0 :expected-status :yield :actual-count 64
    :detail "Secondo prelievo nella stessa lease consuma altri 64 messaggi dopo quota esaurita.")
   (:index 7 :name "writer-target-span" :result :detected :exit-code 1 :compilable t
    :log "spikes/out/writer-queue-20261009-a-mutations/7/test.log" :smoke-line 1
    :first-failure-line 34 :test-backtrace-line 44
    :test "TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL"
    :failure :assertion :expected-count 1 :actual-count 2
    :detail "Target start=1 end=2: restituisce due messaggi invece dell'unico nello span.")))
 :benchmark-audit
 (:status :ok :wrapper-exit-code 0 :wrapper-stderr-bytes 0
  :wrapper-source-consistency :stable :wrapper-fingerprints-before-after-equal t
  :wrapper-source-blob-count 320
  :benchmark-source-consistency :stable :benchmark-fingerprints-before-after-equal t
  :benchmark-fingerprint-count 39
  :sample-count 10 :replicas-per-cell 5
  :iterations-per-sample 4096 :warmup-per-sample 128
  :timer-units-per-second 1000000
  :independent-token-rule "6*n*(n+1)/2 + 3*n + 7"
  :independent-sink-rule "iterations*token + iterations*(iterations-1)/2"
  :sink-formula-verified t :seconds-and-cycles-rate-formulas-verified t
  :all-success-samples-heap-bytes-zero t
  :cells
  ((:capacity 1 :quantum 1 :messages-per-cycle 1 :calls-per-cycle 5
    :expected-return-token 16 :sink 8452096 :samples 5
    :raw-ticks (642 659 653 650 700) :heap-bytes (0 0 0 0 0))
   (:capacity 32 :quantum 32 :messages-per-cycle 32 :calls-per-cycle 36
    :expected-return-token 3271 :sink 21784576 :samples 5
    :raw-ticks (7513 7525 7569 7635 7808) :heap-bytes (0 0 0 0 0)))
  :counter-self-test
  (:status :ok
   :baseline (:iterations 4096 :warmup 128 :heap-bytes 0 :sink 8386560)
   :positive (:iterations 16 :warmup 0 :array-bytes-per-iteration 1048576
              :minimum-heap-bytes 16777216 :observed-heap-bytes 16777472
              :expected-return-token 1048576 :sink 16777336)))
 :limits
 (:targeted-mutants-only
  :serial-success-path-counter-observation-not-absolute-nonallocation-proof
  :cpu-overlap-is-private-buffer-work-not-engine-apply-or-pool-qualification
  :harness-error-cleanup-does-not-assert-thread-cessation-after-one-second-join
  :no-observed-residual-cleanup-risk-in-pass-with-all-joins-ok
  :no-new-tests-benchmarks-or-mutations
  :integrated-make-check-not-audited
  :no-ready-list-lost-wakeup-fairness-controller-durability-or-engine-gate-closed
  :no-deviation-approved))
