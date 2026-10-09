(:SCHEMA-VERSION 1 :KIND :SERIES-CONTROLLER-BENCHMARK :STATUS :OK :MODE
 #A((11) BASE-CHAR . "--self-test") :RECORDED-AT 4000549030 :FINISHED-AT
 4000549032 :OUTPUT-DIRECTORY
 #A((95) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/")
 :SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU
 #A((8) BASE-CHAR . "Apple M4") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
 #A((6) BASE-CHAR . "27.0.0") :SAFETY 3 :COUNTER-SCOPE :WHOLE-PROCESS
 :SERIAL-ZERO-HEAP-GATE T :PARALLEL-HEAP-GATE :OBSERVATIONAL
 :TIMER-UNITS-PER-SECOND 1000000 :MINIMUM-WINDOW-TICKS 20 :INITIAL-ITERATIONS
 20000 :MAXIMUM-ITERATIONS 320000 :MAXIMUM-ATTEMPTS 5 :WARMUP-ITERATIONS 1024
 :SERIAL-SAMPLES 5 :PARALLEL-REPLICAS 3 :WORKER-DEADLINE-SECONDS 30 :CAPACITY
 256 :EVENT-CAPACITY 64 :ENVIRONMENT
 (:ARGV
  (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
   #A((11) BASE-CHAR . "--self-test") #A((12) BASE-CHAR . "--output-dir")
   #A((31) BASE-CHAR . "spikes/out/series-self-test-02/"))
  :ARGV-SOURCE :SBCL-POSIX-ARGV :SCRIPT "tools/series-controller-bench.lisp"
  :CWD
  #A((64) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/")
  :HARDWARE
  (:MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
   17179869184 :LOGICAL-CPUS 10)
  :SBCL #A((5) BASE-CHAR . "2.6.9") :OS #A((6) BASE-CHAR . "Darwin")
  :OS-VERSION #A((6) BASE-CHAR . "27.0.0") :COMMIT
  "d45f4b146155af163d98307ddb18a9eefc2aab64" :WORKING-TREE ""
  :EXTERNAL-LOAD-STATUS :UNCONTROLLED)
 :BUILD
 (:STATUS :OK :PHASE :COMPLETE :API-STATUS :RESOLVED :FASL-MAPPING
  ((:SOURCE "tools/series-controller-bench.lisp" :FASL
    #A((134) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/tools/series-controller-bench.fasl"))
   (:SOURCE "src/codec/cbor-header.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-header.fasl"))
   (:SOURCE "src/codec/cbor-package.lisp" :FASL
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-package.fasl"))
   (:SOURCE "src/codec/cbor-scan-input.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-scan-input.fasl"))
   (:SOURCE "src/codec/cbor-scan-items.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-scan-items.fasl"))
   (:SOURCE "src/codec/cbor-scan-stack.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-scan-stack.fasl"))
   (:SOURCE "src/codec/cbor-scan.lisp" :FASL
    #A((124) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-scan.fasl"))
   (:SOURCE "src/codec/cbor-space.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/cbor-space.fasl"))
   (:SOURCE "src/codec/package.lisp" :FASL
    #A((122) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/package.fasl"))
   (:SOURCE "src/codec/utf8.lisp" :FASL
    #A((119) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/codec/utf8.fasl"))
   (:SOURCE "src/csn/package.lisp" :FASL
    #A((120) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/csn/package.fasl"))
   (:SOURCE "src/csn/registry.lisp" :FASL
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/csn/registry.fasl"))
   (:SOURCE "src/execution/handoff.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/handoff.fasl"))
   (:SOURCE "src/execution/package.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/package.fasl"))
   (:SOURCE "src/execution/queue.lisp" :FASL
    #A((124) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/queue.fasl"))
   (:SOURCE "src/execution/ready-recycle.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/ready-recycle.fasl"))
   (:SOURCE "src/execution/ready-types.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/ready-types.fasl"))
   (:SOURCE "src/execution/ready.lisp" :FASL
    #A((124) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/ready.fasl"))
   (:SOURCE "src/execution/writer.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/execution/writer.fasl"))
   (:SOURCE "src/foundation/batch.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/batch.fasl"))
   (:SOURCE "src/foundation/binary.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/binary.fasl"))
   (:SOURCE "src/foundation/conditions.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/conditions.fasl"))
   (:SOURCE "src/foundation/crc32c.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/crc32c.fasl"))
   (:SOURCE "src/foundation/package.lisp" :FASL
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/package.fasl"))
   (:SOURCE "src/foundation/record.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/foundation/record.fasl"))
   (:SOURCE "src/io/flush.lisp" :FASL
    #A((117) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/flush.fasl"))
   (:SOURCE "src/io/lifecycle.lisp" :FASL
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/lifecycle.fasl"))
   (:SOURCE "src/io/native.lisp" :FASL
    #A((118) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/native.fasl"))
   (:SOURCE "src/io/package.lisp" :FASL
    #A((119) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/package.fasl"))
   (:SOURCE "src/io/transfer.lisp" :FASL
    #A((120) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/transfer.fasl"))
   (:SOURCE "src/io/types.lisp" :FASL
    #A((117) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/io/types.fasl"))
   (:SOURCE "src/package.lisp" :FASL
    #A((116) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/package.fasl"))
   (:SOURCE "src/recovery/decisions-build.lisp" :FASL
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-build.fasl"))
   (:SOURCE "src/recovery/decisions-package.lisp" :FASL
    #A((135) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-package.fasl"))
   (:SOURCE "src/recovery/decisions-query.lisp" :FASL
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-query.fasl"))
   (:SOURCE "src/recovery/decisions-radix.lisp" :FASL
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-radix.fasl"))
   (:SOURCE "src/recovery/decisions-sort.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-sort.fasl"))
   (:SOURCE "src/recovery/decisions-types.lisp" :FASL
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/decisions-types.fasl"))
   (:SOURCE "src/recovery/manifest-build.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-build.fasl"))
   (:SOURCE "src/recovery/manifest-decode.lisp" :FASL
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-decode.fasl"))
   (:SOURCE "src/recovery/manifest-fold.lisp" :FASL
    #A((131) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-fold.fasl"))
   (:SOURCE "src/recovery/manifest-package.lisp" :FASL
    #A((134) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-package.fasl"))
   (:SOURCE "src/recovery/manifest-query.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-query.fasl"))
   (:SOURCE "src/recovery/manifest-types.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/manifest-types.fasl"))
   (:SOURCE "src/recovery/package.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/package.fasl"))
   (:SOURCE "src/recovery/scan.lisp" :FASL
    #A((122) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/recovery/scan.fasl"))
   (:SOURCE "src/series/events.lisp" :FASL
    #A((122) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/events.fasl"))
   (:SOURCE "src/series/io-events.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/io-events.fasl"))
   (:SOURCE "src/series/ownership.lisp" :FASL
    #A((125) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/ownership.fasl"))
   (:SOURCE "src/series/package.lisp" :FASL
    #A((123) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/package.fasl"))
   (:SOURCE "src/series/publication.lisp" :FASL
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/publication.fasl"))
   (:SOURCE "src/series/query.lisp" :FASL
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/query.fasl"))
   (:SOURCE "src/series/retirement.lisp" :FASL
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/retirement.fasl"))
   (:SOURCE "src/series/types.lisp" :FASL
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/series/types.fasl"))
   (:SOURCE "src/storage/compaction-scan.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/compaction-scan.fasl"))
   (:SOURCE "src/storage/control-payload.lisp" :FASL
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/control-payload.fasl"))
   (:SOURCE "src/storage/formats.lisp" :FASL
    #A((124) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/formats.fasl"))
   (:SOURCE "src/storage/log-header.lisp" :FASL
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/log-header.fasl"))
   (:SOURCE "src/storage/package.lisp" :FASL
    #A((124) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/package.fasl"))
   (:SOURCE "src/storage/payload-record.lisp" :FASL
    #A((131) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/payload-record.fasl"))
   (:SOURCE "src/storage/payload-write.lisp" :FASL
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/payload-write.fasl"))
   (:SOURCE "src/storage/segment-header.lisp" :FASL
    #A((131) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/storage/segment-header.fasl"))
   (:SOURCE "src/wal/builder.lisp" :FASL
    #A((120) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/builder.fasl"))
   (:SOURCE "src/wal/csn.lisp" :FASL
    #A((116) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/csn.fasl"))
   (:SOURCE "src/wal/executor.lisp" :FASL
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/executor.fasl"))
   (:SOURCE "src/wal/group.lisp" :FASL
    #A((118) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/group.fasl"))
   (:SOURCE "src/wal/package.lisp" :FASL
    #A((120) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/package.fasl"))
   (:SOURCE "src/wal/types.lisp" :FASL
    #A((118) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/src/wal/types.fasl")))
  :DRIVER-FASL
  #A((134) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/fasl/tools/series-controller-bench.fasl")
  :WARNINGS-POLICY :ALL-FATAL :ASD-BEFORE-TRANSLATIONS T :LOG "build.log")
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE "arcdocdb.asd" :SHA256
   "3863976de1b2b6ba63c8fafa42b1549f8e596d40a885992de41ffc5d2923da19")
  (:FILE "tools/series-controller-bench.lisp" :SHA256
   "20b21fe50fa3a3bc6123b6eac9602985a760a844e6d7b33322dab29b3d240d73")
  (:FILE "docs/implementazione/controller-serie-metodo.md" :SHA256
   "c442fe7441929d76ae85e3b435fa4d3d334f625659cf8eebbb7e612dd920f58d")
  (:FILE "src/codec/cbor-header.lisp" :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:FILE "src/codec/cbor-package.lisp" :SHA256
   "b162c3384587929fd29ff842af35b494cd96ede5036759409b6faec25330ca7f")
  (:FILE "src/codec/cbor-scan-input.lisp" :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:FILE "src/codec/cbor-scan-items.lisp" :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:FILE "src/codec/cbor-scan-stack.lisp" :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:FILE "src/codec/cbor-scan.lisp" :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:FILE "src/codec/cbor-space.lisp" :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:FILE "src/codec/package.lisp" :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:FILE "src/codec/utf8.lisp" :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:FILE "src/csn/package.lisp" :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:FILE "src/csn/registry.lisp" :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:FILE "src/execution/handoff.lisp" :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:FILE "src/execution/package.lisp" :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:FILE "src/execution/queue.lisp" :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:FILE "src/execution/ready-recycle.lisp" :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:FILE "src/execution/ready-types.lisp" :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:FILE "src/execution/ready.lisp" :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:FILE "src/execution/writer.lisp" :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:FILE "src/foundation/batch.lisp" :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:FILE "src/foundation/binary.lisp" :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:FILE "src/foundation/conditions.lisp" :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:FILE "src/foundation/crc32c.lisp" :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:FILE "src/foundation/package.lisp" :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:FILE "src/foundation/record.lisp" :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:FILE "src/io/flush.lisp" :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:FILE "src/io/lifecycle.lisp" :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:FILE "src/io/native.lisp" :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:FILE "src/io/package.lisp" :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:FILE "src/io/transfer.lisp" :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:FILE "src/io/types.lisp" :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:FILE "src/package.lisp" :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:FILE "src/recovery/decisions-build.lisp" :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:FILE "src/recovery/decisions-package.lisp" :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:FILE "src/recovery/decisions-query.lisp" :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:FILE "src/recovery/decisions-radix.lisp" :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:FILE "src/recovery/decisions-sort.lisp" :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:FILE "src/recovery/decisions-types.lisp" :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:FILE "src/recovery/manifest-build.lisp" :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:FILE "src/recovery/manifest-decode.lisp" :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:FILE "src/recovery/manifest-fold.lisp" :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:FILE "src/recovery/manifest-package.lisp" :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:FILE "src/recovery/manifest-query.lisp" :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:FILE "src/recovery/manifest-types.lisp" :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:FILE "src/recovery/package.lisp" :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:FILE "src/recovery/scan.lisp" :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:FILE "src/series/events.lisp" :SHA256
   "c4c551e27c6858fe521b7a8736a42539c639e2e78ab17599b39079511a8e77c7")
  (:FILE "src/series/io-events.lisp" :SHA256
   "5695cd60f16eec8b6c5da0b1c3c559dfd84a2e7e3a19b69643b00b2048385546")
  (:FILE "src/series/ownership.lisp" :SHA256
   "195e71c81a6993d5c021ba520918885f6c91629af7940688f723fe421fc388e4")
  (:FILE "src/series/package.lisp" :SHA256
   "7433162105df63d324141167e6dcf6bfee74611aa1cf7291cc6c92f41f3c7408")
  (:FILE "src/series/publication.lisp" :SHA256
   "288cb3fa41fad76a0e6919dfa0b2fce2beef15f5880129393bee35bc8795c762")
  (:FILE "src/series/query.lisp" :SHA256
   "21363e48cf5c76b771501e54d16b1a6b8627da003a0852db0aadcfbd45d55eb9")
  (:FILE "src/series/retirement.lisp" :SHA256
   "23f3ab39b4176917e86064dff0a11e389df47e0286778a870f718fdc6f3fa059")
  (:FILE "src/series/types.lisp" :SHA256
   "5b35f8f0b017476e14078ba073840e40f182438af41750dd1b3262d0a80c1ca9")
  (:FILE "src/storage/compaction-scan.lisp" :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:FILE "src/storage/control-payload.lisp" :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:FILE "src/storage/formats.lisp" :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:FILE "src/storage/log-header.lisp" :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:FILE "src/storage/package.lisp" :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:FILE "src/storage/payload-record.lisp" :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:FILE "src/storage/payload-write.lisp" :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:FILE "src/storage/segment-header.lisp" :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:FILE "src/wal/builder.lisp" :SHA256
   "186d481c39ed0a339a6c884ed3a8b6f82da6c17315d8649c8d749efee29682f0")
  (:FILE "src/wal/csn.lisp" :SHA256
   "2fc52ddc064a87c32c44d1a8a9756de65b75b25dd705fdf24be1da53ef5ab810")
  (:FILE "src/wal/executor.lisp" :SHA256
   "d5fce79d73f6d5115602fabb822ba36ab4ec376dfba5025c5bf1426f6ec438d8")
  (:FILE "src/wal/group.lisp" :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:FILE "src/wal/package.lisp" :SHA256
   "483c7fd8debf44765375cca8429dfc111bc4775a6db2eb5f0d7e6991f1e5ad89")
  (:FILE "src/wal/types.lisp" :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e"))
 :SOURCE-FINGERPRINTS-AFTER
 ((:FILE "arcdocdb.asd" :SHA256
   "3863976de1b2b6ba63c8fafa42b1549f8e596d40a885992de41ffc5d2923da19")
  (:FILE "tools/series-controller-bench.lisp" :SHA256
   "20b21fe50fa3a3bc6123b6eac9602985a760a844e6d7b33322dab29b3d240d73")
  (:FILE "docs/implementazione/controller-serie-metodo.md" :SHA256
   "c442fe7441929d76ae85e3b435fa4d3d334f625659cf8eebbb7e612dd920f58d")
  (:FILE "src/codec/cbor-header.lisp" :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:FILE "src/codec/cbor-package.lisp" :SHA256
   "b162c3384587929fd29ff842af35b494cd96ede5036759409b6faec25330ca7f")
  (:FILE "src/codec/cbor-scan-input.lisp" :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:FILE "src/codec/cbor-scan-items.lisp" :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:FILE "src/codec/cbor-scan-stack.lisp" :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:FILE "src/codec/cbor-scan.lisp" :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:FILE "src/codec/cbor-space.lisp" :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:FILE "src/codec/package.lisp" :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:FILE "src/codec/utf8.lisp" :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:FILE "src/csn/package.lisp" :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:FILE "src/csn/registry.lisp" :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:FILE "src/execution/handoff.lisp" :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:FILE "src/execution/package.lisp" :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:FILE "src/execution/queue.lisp" :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:FILE "src/execution/ready-recycle.lisp" :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:FILE "src/execution/ready-types.lisp" :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:FILE "src/execution/ready.lisp" :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:FILE "src/execution/writer.lisp" :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:FILE "src/foundation/batch.lisp" :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:FILE "src/foundation/binary.lisp" :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:FILE "src/foundation/conditions.lisp" :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:FILE "src/foundation/crc32c.lisp" :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:FILE "src/foundation/package.lisp" :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:FILE "src/foundation/record.lisp" :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:FILE "src/io/flush.lisp" :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:FILE "src/io/lifecycle.lisp" :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:FILE "src/io/native.lisp" :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:FILE "src/io/package.lisp" :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:FILE "src/io/transfer.lisp" :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:FILE "src/io/types.lisp" :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:FILE "src/package.lisp" :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:FILE "src/recovery/decisions-build.lisp" :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:FILE "src/recovery/decisions-package.lisp" :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:FILE "src/recovery/decisions-query.lisp" :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:FILE "src/recovery/decisions-radix.lisp" :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:FILE "src/recovery/decisions-sort.lisp" :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:FILE "src/recovery/decisions-types.lisp" :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:FILE "src/recovery/manifest-build.lisp" :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:FILE "src/recovery/manifest-decode.lisp" :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:FILE "src/recovery/manifest-fold.lisp" :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:FILE "src/recovery/manifest-package.lisp" :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:FILE "src/recovery/manifest-query.lisp" :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:FILE "src/recovery/manifest-types.lisp" :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:FILE "src/recovery/package.lisp" :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:FILE "src/recovery/scan.lisp" :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:FILE "src/series/events.lisp" :SHA256
   "c4c551e27c6858fe521b7a8736a42539c639e2e78ab17599b39079511a8e77c7")
  (:FILE "src/series/io-events.lisp" :SHA256
   "5695cd60f16eec8b6c5da0b1c3c559dfd84a2e7e3a19b69643b00b2048385546")
  (:FILE "src/series/ownership.lisp" :SHA256
   "195e71c81a6993d5c021ba520918885f6c91629af7940688f723fe421fc388e4")
  (:FILE "src/series/package.lisp" :SHA256
   "7433162105df63d324141167e6dcf6bfee74611aa1cf7291cc6c92f41f3c7408")
  (:FILE "src/series/publication.lisp" :SHA256
   "288cb3fa41fad76a0e6919dfa0b2fce2beef15f5880129393bee35bc8795c762")
  (:FILE "src/series/query.lisp" :SHA256
   "21363e48cf5c76b771501e54d16b1a6b8627da003a0852db0aadcfbd45d55eb9")
  (:FILE "src/series/retirement.lisp" :SHA256
   "23f3ab39b4176917e86064dff0a11e389df47e0286778a870f718fdc6f3fa059")
  (:FILE "src/series/types.lisp" :SHA256
   "5b35f8f0b017476e14078ba073840e40f182438af41750dd1b3262d0a80c1ca9")
  (:FILE "src/storage/compaction-scan.lisp" :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:FILE "src/storage/control-payload.lisp" :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:FILE "src/storage/formats.lisp" :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:FILE "src/storage/log-header.lisp" :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:FILE "src/storage/package.lisp" :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:FILE "src/storage/payload-record.lisp" :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:FILE "src/storage/payload-write.lisp" :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:FILE "src/storage/segment-header.lisp" :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:FILE "src/wal/builder.lisp" :SHA256
   "186d481c39ed0a339a6c884ed3a8b6f82da6c17315d8649c8d749efee29682f0")
  (:FILE "src/wal/csn.lisp" :SHA256
   "2fc52ddc064a87c32c44d1a8a9756de65b75b25dd705fdf24be1da53ef5ab810")
  (:FILE "src/wal/executor.lisp" :SHA256
   "d5fce79d73f6d5115602fabb822ba36ab4ec376dfba5025c5bf1426f6ec438d8")
  (:FILE "src/wal/group.lisp" :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:FILE "src/wal/package.lisp" :SHA256
   "483c7fd8debf44765375cca8429dfc111bc4775a6db2eb5f0d7e6991f1e5ad89")
  (:FILE "src/wal/types.lisp" :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e"))
 :SOURCE-CONSISTENCY :STABLE :SELF-TEST
 (:STATUS :OK :EMPTY-WINDOW
  (:SCHEMA-VERSION 1 :STATUS :OK :ITERATIONS 20000 :WARMUP-ITERATIONS 0
   :COMPLETED-ITERATIONS 20000 :HEAP-BYTES 0 :RAW-TICKS 86 :SECONDS 8.6d-5
   :START-TICKS 2831055 :END-TICKS 2831141 :HEAP-BEFORE 990272304 :HEAP-AFTER
   990272304 :TIME-QUALITY :VALID :SINK 199990000 :EXPECTED-SINK 199990000
   :BYTES-PER-CYCLE 0 :CYCLES-PER-SECOND 2.325581395348837d8 :BYTES-PER-SECOND
   0.0d0 :ALLOCATION-SCOPE :WHOLE-PROCESS-SERIAL :BUSY-FAILURES 0
   :FULL-FAILURES 0 :RETRIES 0 :FAILURE-TYPE NIL :FAILURE-REASON NIL
   :NORMALIZED-PENDING NIL :FINAL NIL :DIAGNOSTIC NIL :ADDITIONAL-DIAGNOSTICS
   NIL)
  :ALLOCATION-CONTROL
  (:SCHEMA-VERSION 1 :STATUS :OK :ITERATIONS 16 :WARMUP-ITERATIONS 0
   :COMPLETED-ITERATIONS 16 :HEAP-BYTES 16777472 :RAW-TICKS 44 :SECONDS 4.4d-5
   :START-TICKS 2842673 :END-TICKS 2842717 :HEAP-BEFORE 990272304 :HEAP-AFTER
   1007049776 :TIME-QUALITY :VALID :SINK 16777336 :EXPECTED-SINK 16777336
   :BYTES-PER-CYCLE 0 :CYCLES-PER-SECOND 363636.36363636365d0 :BYTES-PER-SECOND
   0.0d0 :ALLOCATION-SCOPE :WHOLE-PROCESS-SERIAL :BUSY-FAILURES 0
   :FULL-FAILURES 0 :RETRIES 0 :FAILURE-TYPE NIL :FAILURE-REASON NIL
   :NORMALIZED-PENDING NIL :FINAL NIL :DIAGNOSTIC NIL :ADDITIONAL-DIAGNOSTICS
   NIL)
  :INVALID-TIME-REJECTED T :NEGATIVE-TIME-REJECTED T :HEAP-REGRESSION-REJECTED
  T :MISSING-METRIC-REJECTED T :POSITIVE-RETAINED-OBJECTS 16
  :POSITIVE-RETAINED-BYTES 16777216 :PERSISTED-METRIC-FIELDS
  (:STATUS :OK :PATH
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/series-self-test-02/self-test-metrics.lisp")
   :SHARED-HEAD-PRESERVED T :CYCLES-PER-SECOND 17.0d0 :BYTES-PER-SECOND
   19.0d0))
 :SERIAL NIL :PARALLEL NIL :PERSISTENCE-STATUS :VERIFIED :DIAGNOSTIC NIL
 :ADDITIONAL-DIAGNOSTICS NIL :LIMITS
 (:SIMULATED-WRITE-AND-FLUSH :OPAQUE-IMMUTABLE-SYMBOL-ROOTS
  :SYNCHRONOUS-SAME-THREAD-IO-HANDOFF :LEASE-ACQUISITION-OUTSIDE-CLOCK
  :NO-NVME-OR-REAL-DURABILITY-CLAIM
  :NO-CLIENT-LATENCY-OR-DATABASE-THROUGHPUT-CLAIM
  :NO-SNAPSHOT-OR-RECOVERY-QUALIFICATION :EXTERNAL-LOAD-UNCONTROLLED
  :CAMPAIGNS-RUN-SEQUENTIALLY :ORACLE-IN-MEASURED-LOOP :NO-THROUGHPUT-THRESHOLD
  :SERIAL-SUCCESS-ZERO-HEAP-REQUIRED :PARALLEL-HEAP-OBSERVATIONAL
  :COUNTER-SCOPE-WHOLE-PROCESS
  :WORKER-HEAP-WINDOWS-OVERLAP-AND-ARE-NOT-SUMMABLE
  :PARALLEL-PROCESS-WINDOW-INCLUDES-START-AND-JOINS :NO-RETRY
  :UNEXPECTED-INTERRUPTION-AFTER-ASSIGNMENT-REQUIRES-FAIL-STOP
  :SENSOR-NOT-ABSOLUTE-NONALLOCATION-PROOF))
