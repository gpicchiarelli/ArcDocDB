(:schema 1
 :kind :code-review
 :subject :cbor-structure
 :recorded-at "2026-10-09 10:02:49 UTC"
 :formats nil
 :reader :storage-commit-review
 :statement-source :direct-static-reading
 :worktree "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB"
 :source-scope (:product-files 6 :test-files 3 :mutable-working-tree-claim nil)
 :test-independence
 (:original-snapshot-freeze-before-new-product-read t
  :entire-current-test-file-freeze-before-new-product-read nil
  :original-main-test-copy "/tmp/cbor-structure-tests-original-before-read.lisp"
  :original-main-test-git-blob "d2f1ee8e57c0d587c7c1a7274ed171c16fb4fb53"
  :original-main-test-sha256 "28df4a97183169e2fa46651290df17e05261baf9703706102482e45263301997"
  :original-review-copy "/tmp/cbor-structure-independent-review-before-supplement.lisp"
  :original-review-sha256 "d40e42884269ad5e161666fcd05e336ec435a14f18f41d66b222f5dd1f373e85"
  :original-copies-bytewise-verified-before-edit t
  :supplement (:authorized-by :coordinator
               :written-after-product-read t :expected-source :frozen-contract
               :scope :two-fixtures-in-existing-depth-test
               :contents (:100-single-child-arrays :indefinite-text-or-bytes :empty-chunk :break)
               :expected (:nodes 102 :peak-depth 100 :last-frame-slot 101)
               :no-new-nominal-test t)
  :new-product-or-spike-used-for-expected nil
  :support-author :native-subagent-cbor-policy
  :support-author-product-read-before-freeze nil
  :support-reviewed-by :storage-commit-review
  :expected-sources (:frozen-contract :manual-rfc-vectors :arithmetic-ast-construction
                     :cold-recursive-model :frozen-independent-header-oracle
                     :manual-utf8-grammar)
  :sbcl-utf8-role :acceptance-confirmation-only
  :oracle-limits (:span-bytes 64 :recursive-calls 64)
  :lexical-parenthesis-check :pass
  :reviewer-compiled-or-executed-product nil)
 :product-fingerprints
 ((:path "src/codec/cbor-package.lisp" :git-blob "411212b04f96be32516425aa2a7ac53aac5b921d")
  (:path "src/codec/cbor-space.lisp" :git-blob "a8330e50a77b52a6b9044ebbb48f62bb4b3222a3")
  (:path "src/codec/cbor-scan-input.lisp" :git-blob "57ffc48cc688a4de8ebec5cb14c1e69c4209704a")
  (:path "src/codec/cbor-scan-stack.lisp" :git-blob "c574e87af5e195ddf3f596a4ae527e69c7a3c6a6")
  (:path "src/codec/cbor-scan-items.lisp" :git-blob "70272936e323b3e0cb05173c9fb68cb2b614c355")
  (:path "src/codec/cbor-scan.lisp" :git-blob "1f89112b43a39d98cf25dc6dfb34e412428ba843"))
 :test-fingerprints
 ((:path "tests/codec/cbor-structure-support.lisp" :git-blob "e9cc8a08917903cab7b7f5617225884b7d89e6c4")
  (:path "tests/codec/cbor-structure.lisp" :git-blob "7e9b7a518bc3a260d721e85d62ff986553bb06de")
  (:path "tests/codec/cbor-structure-threads.lisp" :git-blob "3624e1dde5f5a484a117f4c783d4e6b88027cc89"))
 :nominal-tests 24
 :planned-corpus
 (:manual-vector-types (:definite :indefinite :float-raw :nonminimal :unknown-tag
                       :duplicate-map-key :unordered-map-key)
  :ast-cases 256 :ast-seed #x7394b21d :trailing-mutations 256
  :lead-spans 512 :lead-second-bytes (0 255)
  :fuzz-cases 4096 :fuzz-seed #x49cba017 :fuzz-span-range (1 64)
  :truncation-boundaries :all-offsets-of-two-mixed-fixtures
  :large-document-bytes 16777216 :over-byte-budget-bytes 16777217
  :container-depth-boundaries (100 101) :tag-chain-nodes 1025)
 :planned-parallel-fixture
 (:workers 2 :private-buffer-and-workspace t :scans 48
  :nodes 2359344 :bytes 5505168 :expected-sinks (4718784 3145920)
  :returned-value-count 3 :input-immutability :whole-buffer
  :clock :get-internal-real-time :interval :after-start-barrier-through-computation
  :positive-work-interval-overlap-required t
  :cpu-time-or-distinct-core-claim nil :scaling-claim nil
  :semaphore-timeout-seconds 15 :join-timeout-seconds 20
  :cleanup-join-timeout-seconds 1 :cleanup-termination-asserted t)
 :checks
 ((:point 1 :status :static-consistent
   :evidence "LIM001/002 AFF004/008; ADR0048 bytes/depth; ADR0014 profile remains future.")
  (:point 2 :status :fixtures-written-runtime-pending
   :evidence "Progress, arity, map phase, depth, nodes, immutable input, reset/reuse; internal defenses not claimed executed.")
  (:point 3 :status :static-consistent-runtime-pending
   :evidence "Typed reasons/offsets and order; invariant-violation propagates without Series FAULTED controller.")
  (:point 4 :status :static-bounded
   :evidence "Span outer steps; 102 drain steps; 100 containers; no product recursion or waits.")
  (:point 5 :status :measurement-pending
   :evidence "No explicit success constructors; scratch factory/errors cold; zero heap not yet attested.")
  (:point 6 :status :static-consistent
   :evidence "Exactly three values after exact root and count/state/cursor postconditions; no decoded content exits.")
  (:point 7 :status :inventory-written-coverage-pending
   :compound-decisions 20 :per-file (2 4 5 6 3)
   :evidence "All new and/or decisions listed; guards/defaults remain in denominator; no MC/DC or exceptions.")
  (:point 8 :status :static-consistent
   :evidence "Immutable caller buffer; exclusive scratch; no retained input references; EQ kinds alias refused before reset.")
  (:point 9 :status :integration-static-check-complete-check-pending
   :evidence "ASDF product/test order checked; trace and make-check not executed by reviewer.")
  (:point 10 :status :static-consistent-automatic-checks-pending
   :evidence "FTYPEs, typed slots, safety3, contracts, active invariants and explicit case defaults; no approved deviation.")
  (:point 11 :status :static-isolated-runtime-pending
   :evidence "No per-operation shared write/wait/lock across Series; private two-worker fixture only, wall-time interval overlap.")
  (:point 12 :status :not-applicable
   :evidence "No durable writes, deletes, I/O or atomic publication in pure scanner."))
 :functional-findings nil
 :pending (:strict-build :lint :trace :links :runtime :coverage :heap :mutations :full-check)
 :limits (:no-human-approval :no-engine-release-gate :no-full-cbor-semantic-validity
          :no-deterministic-profile :no-tag-semantics :no-writer-admission
          :no-series-faulted-controller :no-core-simultaneity-or-scaling-claim
          :no-coverage-exclusion :no-mcdc))
