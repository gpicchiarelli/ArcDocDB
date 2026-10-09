(:SCHEMA-VERSION 1 :KIND :WAL-CSN-BENCHMARK :STATUS :OK :MODE
 #A((11) BASE-CHAR . "--self-test") :RECORDED-AT 4000529496 :FINISHED-AT
 4000529496 :OUTPUT-DIRECTORY
 #A((96) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/wal-csn-self-test-01/")
 :SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU
 #A((8) BASE-CHAR . "Apple M4") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
 #A((6) BASE-CHAR . "27.0.0") :SAFETY 3 :COUNTER-SCOPE :WHOLE-PROCESS
 :SERIAL-ZERO-HEAP-GATE T :PARALLEL-HEAP-GATE :OBSERVATIONAL
 :TIMER-UNITS-PER-SECOND 1000000 :MINIMUM-WINDOW-TICKS 20 :INITIAL-ITERATIONS
 20000 :MAXIMUM-ITERATIONS 320000 :MAXIMUM-ATTEMPTS 5 :WARMUP-ITERATIONS 1024
 :SERIAL-SAMPLES 5 :PARALLEL-REPLICAS 3 :WORKER-DEADLINE-SECONDS 30 :CAPACITY
 256 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "778ea8d0c4568e5c6ed83f178268ae39"))
  (:FILE "tools/wal-csn-bench.lisp" :MD5
   #A((32) BASE-CHAR . "4182110a2f14ad957ee2d4655d8c16af"))
  (:FILE "docs/implementazione/wal-csn-metodo.md" :MD5
   #A((32) BASE-CHAR . "595624c78bc929bebb1c8648a4fa6a3a"))
  (:FILE "src/codec/cbor-header.lisp" :MD5
   #A((32) BASE-CHAR . "6e8c6a49314c2f460aa6f8a1759200b6"))
  (:FILE "src/codec/cbor-package.lisp" :MD5
   #A((32) BASE-CHAR . "41ace98eff0e92e6e002cf7b204b84d1"))
  (:FILE "src/codec/package.lisp" :MD5
   #A((32) BASE-CHAR . "d885bd2a9860eb60aec1a775e5031d5e"))
  (:FILE "src/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "0f67dd5c51bf6a63bc292ab4e2a280c2"))
  (:FILE "src/csn/package.lisp" :MD5
   #A((32) BASE-CHAR . "1130012fc5613a5648d22ed8628be0e8"))
  (:FILE "src/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "a1cdb5661fc54beba5bf00e4765f3235"))
  (:FILE "src/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "bacb6820a020a23d11a36745fa1f3a6b"))
  (:FILE "src/execution/package.lisp" :MD5
   #A((32) BASE-CHAR . "8afc5ec2b0eddbc4ad13ea389b4e232b"))
  (:FILE "src/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "8202843bddb817da4279ac959ae3f3c4"))
  (:FILE "src/execution/ready-types.lisp" :MD5
   #A((32) BASE-CHAR . "a64d98c9ff429d6103d6e10ee1fd7980"))
  (:FILE "src/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "2c1892002f0599bb8273093031017520"))
  (:FILE "src/execution/writer.lisp" :MD5
   #A((32) BASE-CHAR . "73019644090e2971f2b54dc36e4491f5"))
  (:FILE "src/foundation/batch.lisp" :MD5
   #A((32) BASE-CHAR . "ca642ea47e4bff76f78f5b6d7287d6bd"))
  (:FILE "src/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "a06115175f450776762761dce25acdb8"))
  (:FILE "src/foundation/conditions.lisp" :MD5
   #A((32) BASE-CHAR . "0535060fb2eb883174e93863f61b4d0d"))
  (:FILE "src/foundation/crc32c.lisp" :MD5
   #A((32) BASE-CHAR . "4db58e2f48bf77d751f1b83bb9f84b5c"))
  (:FILE "src/foundation/package.lisp" :MD5
   #A((32) BASE-CHAR . "2e2730d535e6a973dbda618a633b943e"))
  (:FILE "src/foundation/record.lisp" :MD5
   #A((32) BASE-CHAR . "65ff9f2bb226ec818cec8f688ba7aa5c"))
  (:FILE "src/io/flush.lisp" :MD5
   #A((32) BASE-CHAR . "716866194d6b9f076e102e84187229c0"))
  (:FILE "src/io/lifecycle.lisp" :MD5
   #A((32) BASE-CHAR . "11c7103efbe733bbf0a13927f23c3d34"))
  (:FILE "src/io/native.lisp" :MD5
   #A((32) BASE-CHAR . "9500cfb800603de002d6d2b24f1bf056"))
  (:FILE "src/io/package.lisp" :MD5
   #A((32) BASE-CHAR . "c9380ad46a1d7acf41655aaed20db478"))
  (:FILE "src/io/transfer.lisp" :MD5
   #A((32) BASE-CHAR . "a5e7108e80664eb3b562fbd7e680801f"))
  (:FILE "src/io/types.lisp" :MD5
   #A((32) BASE-CHAR . "db8497f9cff35b1ee261f1f410f46ca6"))
  (:FILE "src/package.lisp" :MD5
   #A((32) BASE-CHAR . "becf5c78049c85f2c05cd1ef54454032"))
  (:FILE "src/recovery/decisions-build.lisp" :MD5
   #A((32) BASE-CHAR . "1a51ef4a488bb9fde2ff7d47bae01379"))
  (:FILE "src/recovery/decisions-package.lisp" :MD5
   #A((32) BASE-CHAR . "cbdc30f93109c474e1fc25066c9b9b13"))
  (:FILE "src/recovery/decisions-query.lisp" :MD5
   #A((32) BASE-CHAR . "f782d1137b8ce342b91c9999cfb7accc"))
  (:FILE "src/recovery/decisions-radix.lisp" :MD5
   #A((32) BASE-CHAR . "852149de4c289b8e067602780378d87a"))
  (:FILE "src/recovery/decisions-sort.lisp" :MD5
   #A((32) BASE-CHAR . "b33e57a643f2fca810846f6226366253"))
  (:FILE "src/recovery/decisions-types.lisp" :MD5
   #A((32) BASE-CHAR . "f4433fd19ebc7239dbc2628c39f3ecdb"))
  (:FILE "src/recovery/manifest-build.lisp" :MD5
   #A((32) BASE-CHAR . "bf65b1731eab6e0572461ef5cc60fc40"))
  (:FILE "src/recovery/manifest-decode.lisp" :MD5
   #A((32) BASE-CHAR . "67975249aaabd751757cdfb9222cc3c4"))
  (:FILE "src/recovery/manifest-fold.lisp" :MD5
   #A((32) BASE-CHAR . "e0d2498db1011e857b7b0daa1934f187"))
  (:FILE "src/recovery/manifest-package.lisp" :MD5
   #A((32) BASE-CHAR . "aa1768854b77767e4e2ddef296bfc93f"))
  (:FILE "src/recovery/manifest-query.lisp" :MD5
   #A((32) BASE-CHAR . "ebd7a54adea2213294a887e6d4db0927"))
  (:FILE "src/recovery/manifest-types.lisp" :MD5
   #A((32) BASE-CHAR . "7b1d4054415faca7e5fca59ad83b4d4a"))
  (:FILE "src/recovery/package.lisp" :MD5
   #A((32) BASE-CHAR . "1c1c8ad0cd15b1703a2fe19cbf3f13c2"))
  (:FILE "src/recovery/scan.lisp" :MD5
   #A((32) BASE-CHAR . "fcacd15460db25ea9cc4036065f9f096"))
  (:FILE "src/storage/compaction-scan.lisp" :MD5
   #A((32) BASE-CHAR . "1cda77a357ab2147035993b72d135a37"))
  (:FILE "src/storage/control-payload.lisp" :MD5
   #A((32) BASE-CHAR . "cb64f806b8d69eb42d865b4abfff0b27"))
  (:FILE "src/storage/formats.lisp" :MD5
   #A((32) BASE-CHAR . "061147be459d8d3b08c661bd3f91d152"))
  (:FILE "src/storage/log-header.lisp" :MD5
   #A((32) BASE-CHAR . "b53d27dcc9f4badf18b50519c50bc614"))
  (:FILE "src/storage/package.lisp" :MD5
   #A((32) BASE-CHAR . "f86bd104f20616a76b42c02227f72844"))
  (:FILE "src/storage/payload-record.lisp" :MD5
   #A((32) BASE-CHAR . "8c03f9c01dcb30f2d3970a5694968ecf"))
  (:FILE "src/storage/payload-write.lisp" :MD5
   #A((32) BASE-CHAR . "c4ece3c4fa8d9492d2a80df7c0a4f5a0"))
  (:FILE "src/storage/segment-header.lisp" :MD5
   #A((32) BASE-CHAR . "d6812fa59bf8fd1252fbf85a9bfa3896"))
  (:FILE "src/wal/builder.lisp" :MD5
   #A((32) BASE-CHAR . "c394d6bca1e43157edc6fbff34f061a6"))
  (:FILE "src/wal/csn.lisp" :MD5
   #A((32) BASE-CHAR . "923d4610e217cba1a202f2b6449dae8f"))
  (:FILE "src/wal/executor.lisp" :MD5
   #A((32) BASE-CHAR . "afc8179a1c6b87d8f6cb79c7a92cb57a"))
  (:FILE "src/wal/group.lisp" :MD5
   #A((32) BASE-CHAR . "7a0e7c99ab70b4720cbb091156560f5e"))
  (:FILE "src/wal/package.lisp" :MD5
   #A((32) BASE-CHAR . "4112bd94eed8a78cb5bb160191a775b9"))
  (:FILE "src/wal/types.lisp" :MD5
   #A((32) BASE-CHAR . "f799f27a8ac1a4c736c04796c1e543f9")))
 :SOURCE-FINGERPRINTS-AFTER
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "778ea8d0c4568e5c6ed83f178268ae39"))
  (:FILE "tools/wal-csn-bench.lisp" :MD5
   #A((32) BASE-CHAR . "4182110a2f14ad957ee2d4655d8c16af"))
  (:FILE "docs/implementazione/wal-csn-metodo.md" :MD5
   #A((32) BASE-CHAR . "595624c78bc929bebb1c8648a4fa6a3a"))
  (:FILE "src/codec/cbor-header.lisp" :MD5
   #A((32) BASE-CHAR . "6e8c6a49314c2f460aa6f8a1759200b6"))
  (:FILE "src/codec/cbor-package.lisp" :MD5
   #A((32) BASE-CHAR . "41ace98eff0e92e6e002cf7b204b84d1"))
  (:FILE "src/codec/package.lisp" :MD5
   #A((32) BASE-CHAR . "d885bd2a9860eb60aec1a775e5031d5e"))
  (:FILE "src/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "0f67dd5c51bf6a63bc292ab4e2a280c2"))
  (:FILE "src/csn/package.lisp" :MD5
   #A((32) BASE-CHAR . "1130012fc5613a5648d22ed8628be0e8"))
  (:FILE "src/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "a1cdb5661fc54beba5bf00e4765f3235"))
  (:FILE "src/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "bacb6820a020a23d11a36745fa1f3a6b"))
  (:FILE "src/execution/package.lisp" :MD5
   #A((32) BASE-CHAR . "8afc5ec2b0eddbc4ad13ea389b4e232b"))
  (:FILE "src/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "8202843bddb817da4279ac959ae3f3c4"))
  (:FILE "src/execution/ready-types.lisp" :MD5
   #A((32) BASE-CHAR . "a64d98c9ff429d6103d6e10ee1fd7980"))
  (:FILE "src/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "2c1892002f0599bb8273093031017520"))
  (:FILE "src/execution/writer.lisp" :MD5
   #A((32) BASE-CHAR . "73019644090e2971f2b54dc36e4491f5"))
  (:FILE "src/foundation/batch.lisp" :MD5
   #A((32) BASE-CHAR . "ca642ea47e4bff76f78f5b6d7287d6bd"))
  (:FILE "src/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "a06115175f450776762761dce25acdb8"))
  (:FILE "src/foundation/conditions.lisp" :MD5
   #A((32) BASE-CHAR . "0535060fb2eb883174e93863f61b4d0d"))
  (:FILE "src/foundation/crc32c.lisp" :MD5
   #A((32) BASE-CHAR . "4db58e2f48bf77d751f1b83bb9f84b5c"))
  (:FILE "src/foundation/package.lisp" :MD5
   #A((32) BASE-CHAR . "2e2730d535e6a973dbda618a633b943e"))
  (:FILE "src/foundation/record.lisp" :MD5
   #A((32) BASE-CHAR . "65ff9f2bb226ec818cec8f688ba7aa5c"))
  (:FILE "src/io/flush.lisp" :MD5
   #A((32) BASE-CHAR . "716866194d6b9f076e102e84187229c0"))
  (:FILE "src/io/lifecycle.lisp" :MD5
   #A((32) BASE-CHAR . "11c7103efbe733bbf0a13927f23c3d34"))
  (:FILE "src/io/native.lisp" :MD5
   #A((32) BASE-CHAR . "9500cfb800603de002d6d2b24f1bf056"))
  (:FILE "src/io/package.lisp" :MD5
   #A((32) BASE-CHAR . "c9380ad46a1d7acf41655aaed20db478"))
  (:FILE "src/io/transfer.lisp" :MD5
   #A((32) BASE-CHAR . "a5e7108e80664eb3b562fbd7e680801f"))
  (:FILE "src/io/types.lisp" :MD5
   #A((32) BASE-CHAR . "db8497f9cff35b1ee261f1f410f46ca6"))
  (:FILE "src/package.lisp" :MD5
   #A((32) BASE-CHAR . "becf5c78049c85f2c05cd1ef54454032"))
  (:FILE "src/recovery/decisions-build.lisp" :MD5
   #A((32) BASE-CHAR . "1a51ef4a488bb9fde2ff7d47bae01379"))
  (:FILE "src/recovery/decisions-package.lisp" :MD5
   #A((32) BASE-CHAR . "cbdc30f93109c474e1fc25066c9b9b13"))
  (:FILE "src/recovery/decisions-query.lisp" :MD5
   #A((32) BASE-CHAR . "f782d1137b8ce342b91c9999cfb7accc"))
  (:FILE "src/recovery/decisions-radix.lisp" :MD5
   #A((32) BASE-CHAR . "852149de4c289b8e067602780378d87a"))
  (:FILE "src/recovery/decisions-sort.lisp" :MD5
   #A((32) BASE-CHAR . "b33e57a643f2fca810846f6226366253"))
  (:FILE "src/recovery/decisions-types.lisp" :MD5
   #A((32) BASE-CHAR . "f4433fd19ebc7239dbc2628c39f3ecdb"))
  (:FILE "src/recovery/manifest-build.lisp" :MD5
   #A((32) BASE-CHAR . "bf65b1731eab6e0572461ef5cc60fc40"))
  (:FILE "src/recovery/manifest-decode.lisp" :MD5
   #A((32) BASE-CHAR . "67975249aaabd751757cdfb9222cc3c4"))
  (:FILE "src/recovery/manifest-fold.lisp" :MD5
   #A((32) BASE-CHAR . "e0d2498db1011e857b7b0daa1934f187"))
  (:FILE "src/recovery/manifest-package.lisp" :MD5
   #A((32) BASE-CHAR . "aa1768854b77767e4e2ddef296bfc93f"))
  (:FILE "src/recovery/manifest-query.lisp" :MD5
   #A((32) BASE-CHAR . "ebd7a54adea2213294a887e6d4db0927"))
  (:FILE "src/recovery/manifest-types.lisp" :MD5
   #A((32) BASE-CHAR . "7b1d4054415faca7e5fca59ad83b4d4a"))
  (:FILE "src/recovery/package.lisp" :MD5
   #A((32) BASE-CHAR . "1c1c8ad0cd15b1703a2fe19cbf3f13c2"))
  (:FILE "src/recovery/scan.lisp" :MD5
   #A((32) BASE-CHAR . "fcacd15460db25ea9cc4036065f9f096"))
  (:FILE "src/storage/compaction-scan.lisp" :MD5
   #A((32) BASE-CHAR . "1cda77a357ab2147035993b72d135a37"))
  (:FILE "src/storage/control-payload.lisp" :MD5
   #A((32) BASE-CHAR . "cb64f806b8d69eb42d865b4abfff0b27"))
  (:FILE "src/storage/formats.lisp" :MD5
   #A((32) BASE-CHAR . "061147be459d8d3b08c661bd3f91d152"))
  (:FILE "src/storage/log-header.lisp" :MD5
   #A((32) BASE-CHAR . "b53d27dcc9f4badf18b50519c50bc614"))
  (:FILE "src/storage/package.lisp" :MD5
   #A((32) BASE-CHAR . "f86bd104f20616a76b42c02227f72844"))
  (:FILE "src/storage/payload-record.lisp" :MD5
   #A((32) BASE-CHAR . "8c03f9c01dcb30f2d3970a5694968ecf"))
  (:FILE "src/storage/payload-write.lisp" :MD5
   #A((32) BASE-CHAR . "c4ece3c4fa8d9492d2a80df7c0a4f5a0"))
  (:FILE "src/storage/segment-header.lisp" :MD5
   #A((32) BASE-CHAR . "d6812fa59bf8fd1252fbf85a9bfa3896"))
  (:FILE "src/wal/builder.lisp" :MD5
   #A((32) BASE-CHAR . "c394d6bca1e43157edc6fbff34f061a6"))
  (:FILE "src/wal/csn.lisp" :MD5
   #A((32) BASE-CHAR . "923d4610e217cba1a202f2b6449dae8f"))
  (:FILE "src/wal/executor.lisp" :MD5
   #A((32) BASE-CHAR . "afc8179a1c6b87d8f6cb79c7a92cb57a"))
  (:FILE "src/wal/group.lisp" :MD5
   #A((32) BASE-CHAR . "7a0e7c99ab70b4720cbb091156560f5e"))
  (:FILE "src/wal/package.lisp" :MD5
   #A((32) BASE-CHAR . "4112bd94eed8a78cb5bb160191a775b9"))
  (:FILE "src/wal/types.lisp" :MD5
   #A((32) BASE-CHAR . "f799f27a8ac1a4c736c04796c1e543f9")))
 :SOURCE-CONSISTENCY :STABLE :SELF-TEST
 (:STATUS :OK :EMPTY-WINDOW
  (:SCHEMA-VERSION 1 :STATUS :OK :ITERATIONS 20000 :WARMUP-ITERATIONS 0
   :COMPLETED-ITERATIONS 20000 :HEAP-BYTES 0 :RAW-TICKS 151 :SECONDS 1.51d-4
   :START-TICKS 472177 :END-TICKS 472328 :TIME-QUALITY :VALID :SINK 199990000
   :EXPECTED-SINK 199990000 :BYTES-PER-CYCLE 0 :CYCLES-PER-SECOND
   1.324503311258278d8 :BYTES-PER-SECOND 0.0d0 :ALLOCATION-SCOPE
   :WHOLE-PROCESS-SERIAL :BUSY-FAILURES 0 :FULL-FAILURES 0 :RETRIES 0 :FINAL
   NIL :DIAGNOSTIC NIL)
  :ALLOCATION-CONTROL
  (:SCHEMA-VERSION 1 :STATUS :OK :ITERATIONS 16 :WARMUP-ITERATIONS 0
   :COMPLETED-ITERATIONS 16 :HEAP-BYTES 16777472 :RAW-TICKS 43 :SECONDS 4.3d-5
   :START-TICKS 482235 :END-TICKS 482278 :TIME-QUALITY :VALID :SINK 16777336
   :EXPECTED-SINK 16777336 :BYTES-PER-CYCLE 0 :CYCLES-PER-SECOND
   372093.0232558139d0 :BYTES-PER-SECOND 0.0d0 :ALLOCATION-SCOPE
   :WHOLE-PROCESS-SERIAL :BUSY-FAILURES 0 :FULL-FAILURES 0 :RETRIES 0 :FINAL
   NIL :DIAGNOSTIC NIL)
  :INVALID-TIME-REJECTED T :HEAP-REGRESSION-REJECTED T :MISSING-METRIC-REJECTED
  T :PERSISTED-METRIC-FIELDS
  (:STATUS :OK :PATH
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/wal-csn-self-test-01/self-test-metrics.lisp")
   :SHARED-HEAD-PRESERVED T :CYCLES-PER-SECOND 17.0d0 :BYTES-PER-SECOND
   19.0d0))
 :SERIAL NIL :PARALLEL NIL :PERSISTENCE-STATUS :VERIFIED :DIAGNOSTIC NIL
 :LIMITS
 (:SIMULATED-WRITE-AND-FLUSH :SIMULATED-EXTERNAL-INDEX-PUBLICATION
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
