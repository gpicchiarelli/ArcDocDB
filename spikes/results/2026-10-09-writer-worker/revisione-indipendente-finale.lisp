(:schema-version 1
 :kind :independent-c1-reading
 :component :writer-worker
 :reading :final
 :result :no-open-functional-finding
 :scope :local-context-composed-with-handoff-ready-and-recycle
 :base "cf6091367853ec311fed7b05961a2812fd05a8f1"
 :verification "arcdocdb-worker-verify-hzghjzb6"
 :source-hashes
 ((:path "src/execution/worker-types.lisp"
   :sha256 "62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317")
  (:path "src/execution/worker-boundary.lisp"
   :sha256 "4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a")
  (:path "src/execution/worker-claim.lisp"
   :sha256 "62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e")
  (:path "src/execution/worker-run.lisp"
   :sha256 "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847")
  (:path "tests/execution/worker.lisp"
   :sha256 "ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06")
  (:path "tools/writer-worker-bench.lisp"
   :sha256 "aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1")
  (:path "tools/writer-worker-mutation.lisp"
   :sha256 "5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c"))
 :initial-reports ("spikes/out/worker-c1-initial.lisp" "spikes/out/worker-c1-initial-closed.lisp")
 :closed-findings
 ((:id :permanent-fault-retry :status :closed
   :evidence "Local faulted records original condition and blocks all mutating APIs, including cede/adopt. New-wave regression keeps stale context terminal while fresh context consumes new obligation.")
  (:id :batch-debt-upper-bound :status :closed
   :evidence "Pending positive<=extracted; delegated lease checks extracted<=quantum. Dedicated FI checker fixture, debt blocked until current ack.")
  (:id :private-index-classification :status :closed
   :evidence "Private cursor/home bounds invariant before delegated ready-target; public adopt FI poisons context without transferring caller obligation.")
  (:id :private-index-docstring :status :closed
   :evidence "Final worker-types changes only explanatory docstring from preliminary closed reading."))
 :checklist
 ((:point 1 :status :reviewed
   :text "REQ-CON-001/002/004/005 and REQ-AFF-008; ADR-0005 and ADR-0045 §§6/8 coherent with bounded local writer context. No whole-pool qualification.")
  (:point 2 :status :reviewed-with-evidence
   :text "Owner, phase, lease, unique obligation, batch debt, stale ack and permanent fault covered by 23 new fixtures, seeded 8000-step list oracle and complete 89-test execution baseline. Three initial source findings closed. Oracle is not exhaustive pool exploration.")
  (:point 3 :status :reviewed-with-evidence
   :text "Only explicit type/reason per API recoverable. Owner and fault gate before handler preserve original diagnostic. Unexpected/permanent/runtime errors record same condition and terminal phase, no reset or rollback. Typed synthetic boundary fixtures and concrete not-ready/new-wave regression read; Series controller still absent.")
  (:point 4 :status :reviewed
   :text "No new explicit loop, recursion, retry or wait. MEMBER lists bounded to three resources/two arguments; delegated scan <=64 shards/128 CAS and bounded copy. Test threads have timeouts.")
  (:point 5 :status :reviewed-measured-local-success-path
   :text "Twenty complete composed samples, five per four configurations, each4096cycles withheap0. Positive16777472bytes detected; wrong sink rejected; warmup/GC outside measured window. Constructor/errors excluded, no universal heap proof.")
  (:point 6 :status :reviewed
   :text "Complete ftype/typed slots; target/span/alias validated before local overflow/pop, count/status/token checked. Monotone context/token pairs, no cross-context uniqueness. Ack is caller assertion; diagnostic getters do not transfer obligations or authorize replay.")
  (:point 7 :status :reviewed-partial-raw-coverage
   :text "All new scalar/case/macro controls inventoried. Macro expansion once-evaluation/multiple-values/error-identity fixture read. Native=HTML=export across11files, including every missing path. Source enumerator maps all new missing forms through original macro wrapper without executing product. 233expressions/31outcomes remain uncovered; no exclusions or MC/DC inference, no complete C1 gate.")
  (:point 8 :status :reviewed-with-evidence
   :text "Read-only owner/ready, local nonreentrant fields; ring access delegated. Cede/adopt only without active lease/debt. Reused4threads/6waves/36CRCpayloads with live producers and independent-shard progress, plus two competing owner contexts/8waves/one winner.")
  (:point 9 :status :reviewed-frozen-scoped-check
   :text "Frozen check OK/STABLE/exit0:387tests plus smoke,63lintfiles/zero,trace114REQ65INV13FI52ADR,221docs2007links/zero,10spikes.89execution baseline,strictC4FASLselftests,12/12mutants. Later e2f7a75 integration check is distinct/pending; unchanged execution bytes do not relabel frozen records.")
  (:point 10 :status :reviewed-with-local-boundary-limit
   :text "Safety3, typed functions/slots, pre/post and short bodies. Error handler only at worker boundary with recorded condition and defined transition COD21; no application callback. COD24 Series FAULTED/controller and full C1 coverage not qualified.")
  (:point 11 :status :reviewed-with-parallel-functional-evidence
   :text "Ready per tranche, no new shared per-message global write, wait or product thread. Real reused-thread fixtures demonstrate functional independent progress. Allocation benchmark is serial; no speedup/fairness/P99/scaling claim.")
  (:point 12 :status :reviewed-no-durable-change
   :text "No durable mutation/removal. End latches finishing, busy retains lease/ref and blocks replay. After end only local fields change, no writer cleanup can cancel new wave. Full exchange delegated atomic ring operation; internal faults fail-stop without promised rollback."))
 :coverage
 (:process "4000547204-command-93188-0"
  :export-process "4000547249-command-95826-0"
  :independent-process "4000547296-command-98426-0"
  :source-mapping-process "4000547596-command-16195-0"
  :files 11 :expressions-hit 1427 :expressions-total 1660
  :branches-hit 199 :branches-total 230
  :new-expressions-hit 498 :new-expressions-total 600
  :new-branches-hit 65 :new-branches-total 76
  :missing-expressions 233 :missing-branches 31
  :exclusions nil :mcdc-inferred nil :complete-c1-gate nil
  :raw "spikes/out/worker-review-coverage-data.lisp"
  :source-mapping "spikes/out/worker-review-forms-data.lisp")
 :mutations
 (:process "4000547268-command-97067-0" :baseline-tests 89 :logs-read 13
  :detected 12 :planned 12 :all-mutant-exit-codes 1 :all-mutant-signals nil
  :survived 0 :compilation-failures 0 :before-tests 0 :worker-errors 0)
 :benchmark
 (:process "4000547268-command-97066-0" :samples-read 20 :iterations 4096
  :all-sample-heap-bytes 0 :positive-control-heap-bytes 16777472
  :independent-derivation
  (:full "189+115C+3C(C+1)/2+5Σpayload+7(C+1)next"
   :room "227+14next" :total-payloads "1..M; M=K(C+1)"
   :cursor-sum "K(K-1)/2" :empty "29+7*(1 mod K)"
   :calls "1+K(27+7C)" :batches "K(C+4)"
   :sink "4096*token+4096*4095/2")
  :configurations
  ((:shards 1 :capacity 1 :token 578 :sink 10754048 :calls 35 :batches 5)
   (:shards 1 :capacity 3 :token 858 :sink 11900928 :calls 49 :batches 7)
   (:shards 4 :capacity 1 :token 2520 :sink 18708480 :calls 137 :batches 20)
   (:shards 4 :capacity 3 :token 4084 :sink 25114624 :calls 193 :batches 28)))
 :strict-c4 ("4000547221-command-94073-0" "4000547221-command-94074-0")
 :signal-fixture
 (:id "4000547222-worker-signal-self-test-94121" :signal 9 :exit-code 137
  :worker-errors 1 :detected 0 :baseline :fixture-only)
 :check
 (:process "4000547204-command-93189-0" :status :ok :source-consistency :stable
  :exit-code 0 :wall-seconds 112.229559d0 :tests 387 :smoke t
  :module-counts (28 17 17 24 20 89 44 18 82 48)
  :lint-files 63 :lint-violations 0 :trace (114 65 13 52)
  :documents 221 :links 2007 :broken-links 0
  :spike-master "4000547284-check-97964-0" :spike-runs 10 :spike-artifacts 10)
 :independent-results-probes
 ((:id "4000547689-command-21967-0" :status :ok :source-consistency :stable :exit-code 0)
  (:id "4000547809-command-24892-0" :status :failed :source-consistency :stable :exit-code 1
   :reason "Summary adapter applied GETF to tagged non-plist entry; adapter/record preserved, no product failure.")
  (:id "4000547879-command-29495-0" :status :ok :source-consistency :stable :exit-code 0))
 :raw-results "spikes/out/worker-review-results-data.lisp"
 :compact-results "spikes/out/worker-review-summary-data.lisp"
 :raw-results-logical-sha256 "5dcefe371a865a428edc71b2cecf7faaad5f140ecd89c401de43ffb698dc247a"
 :later-integration
 (:base "e2f7a75" :unchanged-worker-execution-bytes t
  :full-check-status :pending :frozen-scoped-records-relabeled nil)
 :material-limits
 (:all-missing-coverage-retained :no-approved-exclusions :no-mcdc-inference
  :no-whole-pool-or-series-controller :caller-unique-obligations-and-private-buffers
  :caller-attested-ack :no-rollback-after-internal-fault
  :no-wake-park-shutdown-admission-fairness-or-scaling-qualification
  :no-durable-wal-application-qualification))
