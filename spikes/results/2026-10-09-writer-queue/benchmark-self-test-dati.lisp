(:SCHEMA-VERSION 1 :KIND :RAW-PROCESS-DATUM :FORMATS NIL :PROCESS-ARTIFACT
 "benchmark-self-test.lisp" :PARSE-RESULT
 (:STATUS :SINGLE-DATUM :DATA
  (:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
   ((:FILE "arcdocdb.asd" :MD5
     #A((32) BASE-CHAR . "a8dba6b9e089a4dbcd65f4674b8aaeac"))
    (:FILE "tools/writer-queue-bench.lisp" :MD5
     #A((32) BASE-CHAR . "2184a75051108100e94e0d8e76021360"))
    (:FILE "src/execution/package.lisp" :MD5
     #A((32) BASE-CHAR . "bb55573bdd5468f9e3de53935f377642"))
    (:FILE "src/execution/queue.lisp" :MD5
     #A((32) BASE-CHAR . "8dcb8eb489352cd45caf7af85f4e93b9"))
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
     #A((32) BASE-CHAR . "b95f4808a955f174f0dc8260b8ba89e8"))
    (:FILE "src/foundation/record.lisp" :MD5
     #A((32) BASE-CHAR . "d1a05da76eb360dba2941ce32549ba51"))
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
     #A((32) BASE-CHAR . "81a0a94e9ac1972df40ea2003c2a84f0"))
    (:FILE "src/recovery/decisions-package.lisp" :MD5
     #A((32) BASE-CHAR . "cbdc30f93109c474e1fc25066c9b9b13"))
    (:FILE "src/recovery/decisions-query.lisp" :MD5
     #A((32) BASE-CHAR . "f782d1137b8ce342b91c9999cfb7accc"))
    (:FILE "src/recovery/decisions-radix.lisp" :MD5
     #A((32) BASE-CHAR . "fa08530e3ddfb808f2ac2c5edb66b91b"))
    (:FILE "src/recovery/decisions-sort.lisp" :MD5
     #A((32) BASE-CHAR . "b33e57a643f2fca810846f6226366253"))
    (:FILE "src/recovery/decisions-types.lisp" :MD5
     #A((32) BASE-CHAR . "f4433fd19ebc7239dbc2628c39f3ecdb"))
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
     #A((32) BASE-CHAR . "304194318389c07a28cbb4477121eb4f"))
    (:FILE "src/wal/executor.lisp" :MD5
     #A((32) BASE-CHAR . "afc8179a1c6b87d8f6cb79c7a92cb57a"))
    (:FILE "src/wal/group.lisp" :MD5
     #A((32) BASE-CHAR . "2fa3e6255117d6194473557b5e5cc633"))
    (:FILE "src/wal/package.lisp" :MD5
     #A((32) BASE-CHAR . "f37f17f017b3c54e08ae499e37becf7e"))
    (:FILE "src/wal/types.lisp" :MD5
     #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5")))
   :SELF-TEST
   (:STATUS :OK :BASELINE
    (:ITERATIONS 4096 :WARMUP-ITERATIONS 128 :HEAP-BYTES 0 :RAW-TICKS 23
     :SECONDS 2.3d-5 :SINK 8386560 :EXPECTED-SINK 8386560
     :EXPECTED-RETURN-TOKEN 0 :CYCLES-PER-SECOND 1.7808695652173913d8)
    :POSITIVE-CONTROL
    (:ITERATIONS 16 :WARMUP-ITERATIONS 0 :HEAP-BYTES 16777472 :RAW-TICKS 52
     :SECONDS 5.2d-5 :SINK 16777336 :EXPECTED-SINK 16777336
     :EXPECTED-RETURN-TOKEN 1048576 :CYCLES-PER-SECOND 307692.3076923077d0))
   :SCHEMA-VERSION 1 :KIND :WRITER-QUEUE-BENCHMARK :STATUS :OK
   :SOURCE-FINGERPRINTS-BEFORE
   ((:FILE "arcdocdb.asd" :MD5
     #A((32) BASE-CHAR . "a8dba6b9e089a4dbcd65f4674b8aaeac"))
    (:FILE "tools/writer-queue-bench.lisp" :MD5
     #A((32) BASE-CHAR . "2184a75051108100e94e0d8e76021360"))
    (:FILE "src/execution/package.lisp" :MD5
     #A((32) BASE-CHAR . "bb55573bdd5468f9e3de53935f377642"))
    (:FILE "src/execution/queue.lisp" :MD5
     #A((32) BASE-CHAR . "8dcb8eb489352cd45caf7af85f4e93b9"))
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
     #A((32) BASE-CHAR . "b95f4808a955f174f0dc8260b8ba89e8"))
    (:FILE "src/foundation/record.lisp" :MD5
     #A((32) BASE-CHAR . "d1a05da76eb360dba2941ce32549ba51"))
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
     #A((32) BASE-CHAR . "81a0a94e9ac1972df40ea2003c2a84f0"))
    (:FILE "src/recovery/decisions-package.lisp" :MD5
     #A((32) BASE-CHAR . "cbdc30f93109c474e1fc25066c9b9b13"))
    (:FILE "src/recovery/decisions-query.lisp" :MD5
     #A((32) BASE-CHAR . "f782d1137b8ce342b91c9999cfb7accc"))
    (:FILE "src/recovery/decisions-radix.lisp" :MD5
     #A((32) BASE-CHAR . "fa08530e3ddfb808f2ac2c5edb66b91b"))
    (:FILE "src/recovery/decisions-sort.lisp" :MD5
     #A((32) BASE-CHAR . "b33e57a643f2fca810846f6226366253"))
    (:FILE "src/recovery/decisions-types.lisp" :MD5
     #A((32) BASE-CHAR . "f4433fd19ebc7239dbc2628c39f3ecdb"))
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
     #A((32) BASE-CHAR . "304194318389c07a28cbb4477121eb4f"))
    (:FILE "src/wal/executor.lisp" :MD5
     #A((32) BASE-CHAR . "afc8179a1c6b87d8f6cb79c7a92cb57a"))
    (:FILE "src/wal/group.lisp" :MD5
     #A((32) BASE-CHAR . "2fa3e6255117d6194473557b5e5cc633"))
    (:FILE "src/wal/package.lisp" :MD5
     #A((32) BASE-CHAR . "f37f17f017b3c54e08ae499e37becf7e"))
    (:FILE "src/wal/types.lisp" :MD5
     #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5")))
   :RECORDED-AT 4000509506 :SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE
   #A((5) BASE-CHAR . "ARM64") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
   #A((6) BASE-CHAR . "27.0.0") :WORKERS 1 :SAFETY 3 :TIMER-UNITS-PER-SECOND
   1000000 :LIMITS
   (:SUCCESS-PATH-ONLY :SERIAL-QUEUE-CYCLES :PREALLOCATED-INPUTS
    :COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF :EXTERNAL-LOAD-UNCONTROLLED
    :NO-POOL-OR-DEVICE-THROUGHPUT :NO-SCALING-OR-LATENCY-THRESHOLD)))
 :RAW-STDOUT "(:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"a8dba6b9e089a4dbcd65f4674b8aaeac\"))
  (:FILE \"tools/writer-queue-bench.lisp\" :MD5
   #A((32) BASE-CHAR . \"2184a75051108100e94e0d8e76021360\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"bb55573bdd5468f9e3de53935f377642\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8dcb8eb489352cd45caf7af85f4e93b9\"))
  (:FILE \"src/execution/writer.lisp\" :MD5
   #A((32) BASE-CHAR . \"73019644090e2971f2b54dc36e4491f5\"))
  (:FILE \"src/foundation/batch.lisp\" :MD5
   #A((32) BASE-CHAR . \"ca642ea47e4bff76f78f5b6d7287d6bd\"))
  (:FILE \"src/foundation/binary.lisp\" :MD5
   #A((32) BASE-CHAR . \"a06115175f450776762761dce25acdb8\"))
  (:FILE \"src/foundation/conditions.lisp\" :MD5
   #A((32) BASE-CHAR . \"0535060fb2eb883174e93863f61b4d0d\"))
  (:FILE \"src/foundation/crc32c.lisp\" :MD5
   #A((32) BASE-CHAR . \"4db58e2f48bf77d751f1b83bb9f84b5c\"))
  (:FILE \"src/foundation/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"b95f4808a955f174f0dc8260b8ba89e8\"))
  (:FILE \"src/foundation/record.lisp\" :MD5
   #A((32) BASE-CHAR . \"d1a05da76eb360dba2941ce32549ba51\"))
  (:FILE \"src/io/flush.lisp\" :MD5
   #A((32) BASE-CHAR . \"716866194d6b9f076e102e84187229c0\"))
  (:FILE \"src/io/lifecycle.lisp\" :MD5
   #A((32) BASE-CHAR . \"11c7103efbe733bbf0a13927f23c3d34\"))
  (:FILE \"src/io/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"9500cfb800603de002d6d2b24f1bf056\"))
  (:FILE \"src/io/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"c9380ad46a1d7acf41655aaed20db478\"))
  (:FILE \"src/io/transfer.lisp\" :MD5
   #A((32) BASE-CHAR . \"a5e7108e80664eb3b562fbd7e680801f\"))
  (:FILE \"src/io/types.lisp\" :MD5
   #A((32) BASE-CHAR . \"db8497f9cff35b1ee261f1f410f46ca6\"))
  (:FILE \"src/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"becf5c78049c85f2c05cd1ef54454032\"))
  (:FILE \"src/recovery/decisions-build.lisp\" :MD5
   #A((32) BASE-CHAR . \"81a0a94e9ac1972df40ea2003c2a84f0\"))
  (:FILE \"src/recovery/decisions-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"cbdc30f93109c474e1fc25066c9b9b13\"))
  (:FILE \"src/recovery/decisions-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"f782d1137b8ce342b91c9999cfb7accc\"))
  (:FILE \"src/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"fa08530e3ddfb808f2ac2c5edb66b91b\"))
  (:FILE \"src/recovery/decisions-sort.lisp\" :MD5
   #A((32) BASE-CHAR . \"b33e57a643f2fca810846f6226366253\"))
  (:FILE \"src/recovery/decisions-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"f4433fd19ebc7239dbc2628c39f3ecdb\"))
  (:FILE \"src/recovery/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"1c1c8ad0cd15b1703a2fe19cbf3f13c2\"))
  (:FILE \"src/recovery/scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"fcacd15460db25ea9cc4036065f9f096\"))
  (:FILE \"src/storage/compaction-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"1cda77a357ab2147035993b72d135a37\"))
  (:FILE \"src/storage/control-payload.lisp\" :MD5
   #A((32) BASE-CHAR . \"cb64f806b8d69eb42d865b4abfff0b27\"))
  (:FILE \"src/storage/formats.lisp\" :MD5
   #A((32) BASE-CHAR . \"061147be459d8d3b08c661bd3f91d152\"))
  (:FILE \"src/storage/log-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"b53d27dcc9f4badf18b50519c50bc614\"))
  (:FILE \"src/storage/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"f86bd104f20616a76b42c02227f72844\"))
  (:FILE \"src/storage/payload-record.lisp\" :MD5
   #A((32) BASE-CHAR . \"8c03f9c01dcb30f2d3970a5694968ecf\"))
  (:FILE \"src/storage/payload-write.lisp\" :MD5
   #A((32) BASE-CHAR . \"c4ece3c4fa8d9492d2a80df7c0a4f5a0\"))
  (:FILE \"src/storage/segment-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"d6812fa59bf8fd1252fbf85a9bfa3896\"))
  (:FILE \"src/wal/builder.lisp\" :MD5
   #A((32) BASE-CHAR . \"304194318389c07a28cbb4477121eb4f\"))
  (:FILE \"src/wal/executor.lisp\" :MD5
   #A((32) BASE-CHAR . \"afc8179a1c6b87d8f6cb79c7a92cb57a\"))
  (:FILE \"src/wal/group.lisp\" :MD5
   #A((32) BASE-CHAR . \"2fa3e6255117d6194473557b5e5cc633\"))
  (:FILE \"src/wal/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"f37f17f017b3c54e08ae499e37becf7e\"))
  (:FILE \"src/wal/types.lisp\" :MD5
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\")))
 :SELF-TEST
 (:STATUS :OK :BASELINE
  (:ITERATIONS 4096 :WARMUP-ITERATIONS 128 :HEAP-BYTES 0 :RAW-TICKS 23 :SECONDS
   2.3d-5 :SINK 8386560 :EXPECTED-SINK 8386560 :EXPECTED-RETURN-TOKEN 0
   :CYCLES-PER-SECOND 1.7808695652173913d8)
  :POSITIVE-CONTROL
  (:ITERATIONS 16 :WARMUP-ITERATIONS 0 :HEAP-BYTES 16777472 :RAW-TICKS 52
   :SECONDS 5.2d-5 :SINK 16777336 :EXPECTED-SINK 16777336
   :EXPECTED-RETURN-TOKEN 1048576 :CYCLES-PER-SECOND 307692.3076923077d0))
 :SCHEMA-VERSION 1 :KIND :WRITER-QUEUE-BENCHMARK :STATUS :OK
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"a8dba6b9e089a4dbcd65f4674b8aaeac\"))
  (:FILE \"tools/writer-queue-bench.lisp\" :MD5
   #A((32) BASE-CHAR . \"2184a75051108100e94e0d8e76021360\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"bb55573bdd5468f9e3de53935f377642\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8dcb8eb489352cd45caf7af85f4e93b9\"))
  (:FILE \"src/execution/writer.lisp\" :MD5
   #A((32) BASE-CHAR . \"73019644090e2971f2b54dc36e4491f5\"))
  (:FILE \"src/foundation/batch.lisp\" :MD5
   #A((32) BASE-CHAR . \"ca642ea47e4bff76f78f5b6d7287d6bd\"))
  (:FILE \"src/foundation/binary.lisp\" :MD5
   #A((32) BASE-CHAR . \"a06115175f450776762761dce25acdb8\"))
  (:FILE \"src/foundation/conditions.lisp\" :MD5
   #A((32) BASE-CHAR . \"0535060fb2eb883174e93863f61b4d0d\"))
  (:FILE \"src/foundation/crc32c.lisp\" :MD5
   #A((32) BASE-CHAR . \"4db58e2f48bf77d751f1b83bb9f84b5c\"))
  (:FILE \"src/foundation/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"b95f4808a955f174f0dc8260b8ba89e8\"))
  (:FILE \"src/foundation/record.lisp\" :MD5
   #A((32) BASE-CHAR . \"d1a05da76eb360dba2941ce32549ba51\"))
  (:FILE \"src/io/flush.lisp\" :MD5
   #A((32) BASE-CHAR . \"716866194d6b9f076e102e84187229c0\"))
  (:FILE \"src/io/lifecycle.lisp\" :MD5
   #A((32) BASE-CHAR . \"11c7103efbe733bbf0a13927f23c3d34\"))
  (:FILE \"src/io/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"9500cfb800603de002d6d2b24f1bf056\"))
  (:FILE \"src/io/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"c9380ad46a1d7acf41655aaed20db478\"))
  (:FILE \"src/io/transfer.lisp\" :MD5
   #A((32) BASE-CHAR . \"a5e7108e80664eb3b562fbd7e680801f\"))
  (:FILE \"src/io/types.lisp\" :MD5
   #A((32) BASE-CHAR . \"db8497f9cff35b1ee261f1f410f46ca6\"))
  (:FILE \"src/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"becf5c78049c85f2c05cd1ef54454032\"))
  (:FILE \"src/recovery/decisions-build.lisp\" :MD5
   #A((32) BASE-CHAR . \"81a0a94e9ac1972df40ea2003c2a84f0\"))
  (:FILE \"src/recovery/decisions-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"cbdc30f93109c474e1fc25066c9b9b13\"))
  (:FILE \"src/recovery/decisions-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"f782d1137b8ce342b91c9999cfb7accc\"))
  (:FILE \"src/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"fa08530e3ddfb808f2ac2c5edb66b91b\"))
  (:FILE \"src/recovery/decisions-sort.lisp\" :MD5
   #A((32) BASE-CHAR . \"b33e57a643f2fca810846f6226366253\"))
  (:FILE \"src/recovery/decisions-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"f4433fd19ebc7239dbc2628c39f3ecdb\"))
  (:FILE \"src/recovery/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"1c1c8ad0cd15b1703a2fe19cbf3f13c2\"))
  (:FILE \"src/recovery/scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"fcacd15460db25ea9cc4036065f9f096\"))
  (:FILE \"src/storage/compaction-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"1cda77a357ab2147035993b72d135a37\"))
  (:FILE \"src/storage/control-payload.lisp\" :MD5
   #A((32) BASE-CHAR . \"cb64f806b8d69eb42d865b4abfff0b27\"))
  (:FILE \"src/storage/formats.lisp\" :MD5
   #A((32) BASE-CHAR . \"061147be459d8d3b08c661bd3f91d152\"))
  (:FILE \"src/storage/log-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"b53d27dcc9f4badf18b50519c50bc614\"))
  (:FILE \"src/storage/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"f86bd104f20616a76b42c02227f72844\"))
  (:FILE \"src/storage/payload-record.lisp\" :MD5
   #A((32) BASE-CHAR . \"8c03f9c01dcb30f2d3970a5694968ecf\"))
  (:FILE \"src/storage/payload-write.lisp\" :MD5
   #A((32) BASE-CHAR . \"c4ece3c4fa8d9492d2a80df7c0a4f5a0\"))
  (:FILE \"src/storage/segment-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"d6812fa59bf8fd1252fbf85a9bfa3896\"))
  (:FILE \"src/wal/builder.lisp\" :MD5
   #A((32) BASE-CHAR . \"304194318389c07a28cbb4477121eb4f\"))
  (:FILE \"src/wal/executor.lisp\" :MD5
   #A((32) BASE-CHAR . \"afc8179a1c6b87d8f6cb79c7a92cb57a\"))
  (:FILE \"src/wal/group.lisp\" :MD5
   #A((32) BASE-CHAR . \"2fa3e6255117d6194473557b5e5cc633\"))
  (:FILE \"src/wal/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"f37f17f017b3c54e08ae499e37becf7e\"))
  (:FILE \"src/wal/types.lisp\" :MD5
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\")))
 :RECORDED-AT 4000509506 :SBCL #A((5) BASE-CHAR . \"2.6.9\") :MACHINE
 #A((5) BASE-CHAR . \"ARM64\") :OS #A((6) BASE-CHAR . \"Darwin\") :OS-VERSION
 #A((6) BASE-CHAR . \"27.0.0\") :WORKERS 1 :SAFETY 3 :TIMER-UNITS-PER-SECOND
 1000000 :LIMITS
 (:SUCCESS-PATH-ONLY :SERIAL-QUEUE-CYCLES :PREALLOCATED-INPUTS
  :COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF :EXTERNAL-LOAD-UNCONTROLLED
  :NO-POOL-OR-DEVICE-THROUGHPUT :NO-SCALING-OR-LATENCY-THRESHOLD))
")
