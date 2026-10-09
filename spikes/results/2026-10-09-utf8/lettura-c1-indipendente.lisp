(:schema-version 1
 :kind :code-review
 :recorded-at "2026-10-09 05:40:12 UTC"
 :workspace "/Users/gpicchiarelli/.codex/worktrees/utf8-validation/ArcDocDB"
 :status :no-functional-defect-found
 :readonly-product t
 :campaigns-run-by-reviewer nil
 :report-reader-read-eval nil
 :source-files
 ((:path "src/codec/package.lisp" :git-blob "807939c0fbc5d149bc7c8c1e29c7864ef7be991d")
  (:path "src/codec/utf8.lisp" :git-blob "26726c45555ae8490e0dff31f61f70735183acc7")
  (:path "tests/codec/support.lisp" :git-blob "6b8226ae1b41dc9e47e45986e18287a10a8d54e7")
  (:path "tests/codec/utf8.lisp" :git-blob "59e3ffc9cee96d97ef20d132e3e531aef2f9ddf7")
  (:path "tests/codec/threads.lisp" :git-blob "dc9ea34945c3a8c52d5c62062951674d27becd5a"))
 :integration-read
 ("arcdocdb.asd" "docs/implementazione/utf8.md"
  "docs/implementazione/utf8-metodo.md" "docs/implementazione/utf8-decisioni.md"
  "docs/affidabilita/standard-di-codifica.md" "docs/adr/0048-limiti-documentali-e-formato-v2.md")
 :test-independence
 (:test-frozen-before-source-read t :source-not-read-before-freeze t
  :freeze-hashes-sent-before-source-read t :edits-after-freeze nil
  :nominal-tests 17 :static-lexical-balance :pass
  :reference "RFC 3629 manual grammar and installed SBCL strict decoder without replacement"
  :reference-scope :acceptance-and-scalar-count
  :diagnostic-reference :manual-reason-offset-and-priority
  :reference-priority-limitation "SBCL can check continuation bytes before truncation; its diagnostic priority is not the product oracle."
  :single-byte-inputs 256 :two-byte-inputs 65536
  :two-byte-expected (:accepted 18304 :rejected 47232 :scalar-total 34688)
  :fuzz (:seed "3629A11F" :algorithm :lcg-32
         :multiplier 1664525 :increment 1013904223 :samples 4096 :lengths (3 8)
         :offsets (1 7) :expected-from-product nil)
  :scalar-stream (:seed "3629" :scalars 521 :manual-arithmetic-encoder t)
  :thread-test (:workers 2 :private-buffer-bytes 655360 :calls-per-worker 64
                :expected-sink-per-worker 16777216 :bytes 83886080
                :wait-timeout-seconds 15 :join-timeout-seconds 20
                :cleanup-join-timeout-seconds 1 :cleanup-checks-cessation t
                :barriers-before-measured-interval t :sleep-in-measured-interval nil))
 :checks
 ((:point 1 :name :requirements-and-adr :status :static-ok
   :evidence "REQ-LIM-001/002 and REQ-AFF-004/008; ADR-0048. This is a pure UTF-8 support kernel, not complete CBOR validation.")
  (:point 2 :name :invariants-and-tests :status :public-contract-static-ok
   :evidence "Manual boundaries, all one/two-byte inputs, counts, immutable input and offsets; cursor progress/count/result guards remain active."
   :limit "Private invariant failures cannot be caused through a conforming public call; mutation and coverage evidence are separate.")
  (:point 3 :name :typed-errors :status :static-ok
   :evidence "Range then budget then byte-budget; legal lead then full width, continuation left-to-right, scalar restriction. All errors use arcdocdb-error subtypes and no normal count escapes on failure."
   :limit "Invariant-violation is classified but this kernel has no Serie controller or FAULTED transition.")
  (:point 4 :name :bounded-work :status :static-ok
   :evidence "Public loop repeats at most span <= 16777216; continuation loop at most three steps. No recursion, locks or waits. Width checked before cursor addition; count <= span and all successful arithmetic remains index.")
  (:point 5 :name :hot-path-allocation :status :measurement-pending
   :evidence "Success source uses local index/u8 values and reads existing arrays, with no object constructor."
   :limit "Source inspection alone does not prove zero heap; registered heap benchmark and positive sensor remain to audit.")
  (:point 6 :name :verified-output :status :static-ok
   :evidence "Only one scalar count after complete span and result/count postconditions; no string, scalar value, partial count or document structure returned.")
  (:point 7 :name :compound-decisions :status :inventory-static-ok
   :evidence "All three product AND decisions are present in utf8-decisioni.md: range, budget and progress. No product OR; scalar and lead bounds covered manually."
   :limit "No MC/DC qualification or denominator exclusion approved by this review.")
  (:point 8 :name :ownership :status :static-ok
   :evidence "Caller owns and keeps buffer immutable; OWNER/SHARED comments declare read-only input and local cursor/count. No mutable global state.")
  (:point 9 :name :integration-and-checks :status :local-checks-direct-read
   :evidence "ASDF loads foundation before codec, registers all three test files and calls arcdocdb.utf8.tests:run. Initial strict build/test, lint, lint self-test, trace and links wrapper is OK/exit0/stable."
   :limit "Full make check and release gate are not claimed here.")
  (:point 10 :name :coding-rules :status :no-static-violation-found
   :evidence "safety3/speed2, complete FTYPE, public T arguments checked at runtime, short functions with contracts, no broad error handler in product, no reader/eval/FFI."
   :limit "No deviation or human C1 approval supplied by this automated review.")
  (:point 11 :name :series-independence :status :static-ok
   :evidence "No per-operation shared write, lock, global queue or wait. Two private-buffer worker computation intervals overlap in the directly read recorded test."
   :limit "This is validator CPU overlap only, not pool/apply throughput, scaling or a complete engine parallelism claim.")
  (:point 12 :name :durable-atomicity :status :not-applicable
   :evidence "Kernel changes no durable state, performs no I/O and deletes no object/file."))
 :directly-read-evidence
 (:path "spikes/out/4000512960-command-22018-0/report.lisp"
  :reader :read-with-read-eval-nil :report-loaded-or-evaluated nil
  :status :ok :exit-code 0 :source-consistency :stable
  :source-blobs-before 341 :source-blobs-after 341 :full-lists-identical t
  :five-product-test-blobs-match-review-before-and-after t
  :five-product-test-blobs-match-current-at-review t
  :utf8-individual-ok-rows 17 :utf8-tests-passed 17
  :module-tests 203
  :fuzz (:seed "3629A11F" :samples 4096 :accepted 234 :rejected 3862)
  :threads (:bytes 83886080 :sink-per-worker 16777216
            :overlap-ticks 265891 :ticks-per-second 1000000)
  :stderr "37 compiler notes; no caught WARNING or caught STYLE-WARNING markers. UTF-8 LOOP arithmetic note is not an allocation measurement."
  :lint (:files 39 :violations 0)
  :trace (:requirements 114 :invariants 65 :fi-scenarios 13 :adrs 52 :errors 0)
  :links (:files 174 :checked 1805 :broken 0))
 :pending-or-not-audited
 (:heap :pending :mutations :pending :full-make-check :pending
  :coverage (:parent-reported :pass :direct-read-by-this-reviewer nil
             :wrapper "spikes/out/4000512999-command-23965-0/report.lisp")
  :benchmark-driver (:parent-reported-initial-failure :format-trailing-tilde
                     :parent-reported-correction t :direct-read-by-this-reviewer nil))
 :limits
 ("Pure UTF-8 grammar/count only: no CBOR structure, chunk handling, depth, schema, normalization or replacement."
  "Caller immutability is a precondition; concurrent mutation of one input buffer is outside the contract."
  "Internal guards signal invariant-violation; the future owner must perform Serie FAULTED fail-stop."
  "No approved C1 coverage exception, MC/DC qualification, human approval or engine release gate."
  "Reviewer ran no compilation, test, benchmark, fuzz, mutation or coverage campaign; only static inspection and safe recorded-data reading."))
