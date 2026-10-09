(:SCHEMA-VERSION 1 :KIND :RAW-PROCESS-DATUM :FORMATS NIL :PROCESS-ARTIFACT
 "benchmark-self-test.lisp" :PARSE-RESULT
 (:STATUS :SINGLE-DATUM :DATA
  (:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
   ((:FILE "arcdocdb.asd" :MD5
     #A((32) BASE-CHAR . "db4d6e4218061402b881c18b00d76a27"))
    (:FILE "tools/cbor-structure-bench.lisp" :MD5
     #A((32) BASE-CHAR . "9a9ac87eb9ac94d5c83a895d055b61b3"))
    (:FILE "src/codec/cbor-header.lisp" :MD5
     #A((32) BASE-CHAR . "6e8c6a49314c2f460aa6f8a1759200b6"))
    (:FILE "src/codec/cbor-package.lisp" :MD5
     #A((32) BASE-CHAR . "6b37c29bae90ce222efdcbe58707ebda"))
    (:FILE "src/codec/cbor-scan-input.lisp" :MD5
     #A((32) BASE-CHAR . "f6488e987889432b375254021825dbe5"))
    (:FILE "src/codec/cbor-scan-items.lisp" :MD5
     #A((32) BASE-CHAR . "706c0baa4158bf272c4b0df17c1439d2"))
    (:FILE "src/codec/cbor-scan-stack.lisp" :MD5
     #A((32) BASE-CHAR . "cf1999ddb10f879aeefbeea853742d57"))
    (:FILE "src/codec/cbor-scan.lisp" :MD5
     #A((32) BASE-CHAR . "61fbb5e7e118f209ac8809a392245106"))
    (:FILE "src/codec/cbor-space.lisp" :MD5
     #A((32) BASE-CHAR . "c33cdcc45f45218aa3e8bf26ce0ee575"))
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
    (:ITERATIONS 32 :WARMUP-ITERATIONS 128 :HEAP-BYTES 0 :RAW-TICKS 1 :SECONDS
     1.0d-6 :SINK 496 :EXPECTED-SINK 496 :EXPECTED-RETURN-TOKEN 0
     :CALLS-PER-SECOND 3.2d7)
    :POSITIVE-CONTROL
    (:ITERATIONS 16 :WARMUP-ITERATIONS 0 :HEAP-BYTES 16777472 :RAW-TICKS 28
     :SECONDS 2.8d-5 :SINK 16777336 :EXPECTED-SINK 16777336
     :EXPECTED-RETURN-TOKEN 1048576 :CALLS-PER-SECOND 571428.5714285715d0))
   :SCHEMA-VERSION 1 :KIND :CBOR-STRUCTURE-BENCHMARK :STATUS :OK
   :SOURCE-FINGERPRINTS-BEFORE
   ((:FILE "arcdocdb.asd" :MD5
     #A((32) BASE-CHAR . "db4d6e4218061402b881c18b00d76a27"))
    (:FILE "tools/cbor-structure-bench.lisp" :MD5
     #A((32) BASE-CHAR . "9a9ac87eb9ac94d5c83a895d055b61b3"))
    (:FILE "src/codec/cbor-header.lisp" :MD5
     #A((32) BASE-CHAR . "6e8c6a49314c2f460aa6f8a1759200b6"))
    (:FILE "src/codec/cbor-package.lisp" :MD5
     #A((32) BASE-CHAR . "6b37c29bae90ce222efdcbe58707ebda"))
    (:FILE "src/codec/cbor-scan-input.lisp" :MD5
     #A((32) BASE-CHAR . "f6488e987889432b375254021825dbe5"))
    (:FILE "src/codec/cbor-scan-items.lisp" :MD5
     #A((32) BASE-CHAR . "706c0baa4158bf272c4b0df17c1439d2"))
    (:FILE "src/codec/cbor-scan-stack.lisp" :MD5
     #A((32) BASE-CHAR . "cf1999ddb10f879aeefbeea853742d57"))
    (:FILE "src/codec/cbor-scan.lisp" :MD5
     #A((32) BASE-CHAR . "61fbb5e7e118f209ac8809a392245106"))
    (:FILE "src/codec/cbor-space.lisp" :MD5
     #A((32) BASE-CHAR . "c33cdcc45f45218aa3e8bf26ce0ee575"))
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
     #A((32) BASE-CHAR . "304194318389c07a28cbb4477121eb4f"))
    (:FILE "src/wal/executor.lisp" :MD5
     #A((32) BASE-CHAR . "afc8179a1c6b87d8f6cb79c7a92cb57a"))
    (:FILE "src/wal/group.lisp" :MD5
     #A((32) BASE-CHAR . "2fa3e6255117d6194473557b5e5cc633"))
    (:FILE "src/wal/package.lisp" :MD5
     #A((32) BASE-CHAR . "f37f17f017b3c54e08ae499e37becf7e"))
    (:FILE "src/wal/types.lisp" :MD5
     #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5")))
   :RECORDED-AT 4000529100 :SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE
   #A((5) BASE-CHAR . "ARM64") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
   #A((6) BASE-CHAR . "27.0.0") :WORKERS 1 :SAFETY 3 :TIMER-UNITS-PER-SECOND
   1000000 :LIMITS
   (:SUCCESS-PATH-ONLY :SERIAL :PREALLOCATED-INPUTS-AND-SCRATCH
    :STRUCTURAL-VALIDATION-ONLY :NO-MATERIALIZED-DOCUMENT-OR-FLOAT
    :COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF :EXTERNAL-LOAD-UNCONTROLLED
    :NO-POOL-OR-DEVICE-THROUGHPUT :NO-SCALING-OR-LATENCY-THRESHOLD)))
 :RAW-STDOUT "(:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"db4d6e4218061402b881c18b00d76a27\"))
  (:FILE \"tools/cbor-structure-bench.lisp\" :MD5
   #A((32) BASE-CHAR . \"9a9ac87eb9ac94d5c83a895d055b61b3\"))
  (:FILE \"src/codec/cbor-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"6e8c6a49314c2f460aa6f8a1759200b6\"))
  (:FILE \"src/codec/cbor-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"6b37c29bae90ce222efdcbe58707ebda\"))
  (:FILE \"src/codec/cbor-scan-input.lisp\" :MD5
   #A((32) BASE-CHAR . \"f6488e987889432b375254021825dbe5\"))
  (:FILE \"src/codec/cbor-scan-items.lisp\" :MD5
   #A((32) BASE-CHAR . \"706c0baa4158bf272c4b0df17c1439d2\"))
  (:FILE \"src/codec/cbor-scan-stack.lisp\" :MD5
   #A((32) BASE-CHAR . \"cf1999ddb10f879aeefbeea853742d57\"))
  (:FILE \"src/codec/cbor-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"61fbb5e7e118f209ac8809a392245106\"))
  (:FILE \"src/codec/cbor-space.lisp\" :MD5
   #A((32) BASE-CHAR . \"c33cdcc45f45218aa3e8bf26ce0ee575\"))
  (:FILE \"src/codec/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"d885bd2a9860eb60aec1a775e5031d5e\"))
  (:FILE \"src/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"0f67dd5c51bf6a63bc292ab4e2a280c2\"))
  (:FILE \"src/csn/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"1130012fc5613a5648d22ed8628be0e8\"))
  (:FILE \"src/csn/registry.lisp\" :MD5
   #A((32) BASE-CHAR . \"a1cdb5661fc54beba5bf00e4765f3235\"))
  (:FILE \"src/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb6820a020a23d11a36745fa1f3a6b\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"8afc5ec2b0eddbc4ad13ea389b4e232b\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8202843bddb817da4279ac959ae3f3c4\"))
  (:FILE \"src/execution/ready-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"a64d98c9ff429d6103d6e10ee1fd7980\"))
  (:FILE \"src/execution/ready.lisp\" :MD5
   #A((32) BASE-CHAR . \"2c1892002f0599bb8273093031017520\"))
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
   #A((32) BASE-CHAR . \"1a51ef4a488bb9fde2ff7d47bae01379\"))
  (:FILE \"src/recovery/decisions-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"cbdc30f93109c474e1fc25066c9b9b13\"))
  (:FILE \"src/recovery/decisions-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"f782d1137b8ce342b91c9999cfb7accc\"))
  (:FILE \"src/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"852149de4c289b8e067602780378d87a\"))
  (:FILE \"src/recovery/decisions-sort.lisp\" :MD5
   #A((32) BASE-CHAR . \"b33e57a643f2fca810846f6226366253\"))
  (:FILE \"src/recovery/decisions-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"f4433fd19ebc7239dbc2628c39f3ecdb\"))
  (:FILE \"src/recovery/manifest-build.lisp\" :MD5
   #A((32) BASE-CHAR . \"bf65b1731eab6e0572461ef5cc60fc40\"))
  (:FILE \"src/recovery/manifest-decode.lisp\" :MD5
   #A((32) BASE-CHAR . \"67975249aaabd751757cdfb9222cc3c4\"))
  (:FILE \"src/recovery/manifest-fold.lisp\" :MD5
   #A((32) BASE-CHAR . \"e0d2498db1011e857b7b0daa1934f187\"))
  (:FILE \"src/recovery/manifest-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"aa1768854b77767e4e2ddef296bfc93f\"))
  (:FILE \"src/recovery/manifest-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"ebd7a54adea2213294a887e6d4db0927\"))
  (:FILE \"src/recovery/manifest-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"7b1d4054415faca7e5fca59ad83b4d4a\"))
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
  (:ITERATIONS 32 :WARMUP-ITERATIONS 128 :HEAP-BYTES 0 :RAW-TICKS 1 :SECONDS
   1.0d-6 :SINK 496 :EXPECTED-SINK 496 :EXPECTED-RETURN-TOKEN 0
   :CALLS-PER-SECOND 3.2d7)
  :POSITIVE-CONTROL
  (:ITERATIONS 16 :WARMUP-ITERATIONS 0 :HEAP-BYTES 16777472 :RAW-TICKS 28
   :SECONDS 2.8d-5 :SINK 16777336 :EXPECTED-SINK 16777336
   :EXPECTED-RETURN-TOKEN 1048576 :CALLS-PER-SECOND 571428.5714285715d0))
 :SCHEMA-VERSION 1 :KIND :CBOR-STRUCTURE-BENCHMARK :STATUS :OK
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"db4d6e4218061402b881c18b00d76a27\"))
  (:FILE \"tools/cbor-structure-bench.lisp\" :MD5
   #A((32) BASE-CHAR . \"9a9ac87eb9ac94d5c83a895d055b61b3\"))
  (:FILE \"src/codec/cbor-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"6e8c6a49314c2f460aa6f8a1759200b6\"))
  (:FILE \"src/codec/cbor-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"6b37c29bae90ce222efdcbe58707ebda\"))
  (:FILE \"src/codec/cbor-scan-input.lisp\" :MD5
   #A((32) BASE-CHAR . \"f6488e987889432b375254021825dbe5\"))
  (:FILE \"src/codec/cbor-scan-items.lisp\" :MD5
   #A((32) BASE-CHAR . \"706c0baa4158bf272c4b0df17c1439d2\"))
  (:FILE \"src/codec/cbor-scan-stack.lisp\" :MD5
   #A((32) BASE-CHAR . \"cf1999ddb10f879aeefbeea853742d57\"))
  (:FILE \"src/codec/cbor-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"61fbb5e7e118f209ac8809a392245106\"))
  (:FILE \"src/codec/cbor-space.lisp\" :MD5
   #A((32) BASE-CHAR . \"c33cdcc45f45218aa3e8bf26ce0ee575\"))
  (:FILE \"src/codec/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"d885bd2a9860eb60aec1a775e5031d5e\"))
  (:FILE \"src/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"0f67dd5c51bf6a63bc292ab4e2a280c2\"))
  (:FILE \"src/csn/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"1130012fc5613a5648d22ed8628be0e8\"))
  (:FILE \"src/csn/registry.lisp\" :MD5
   #A((32) BASE-CHAR . \"a1cdb5661fc54beba5bf00e4765f3235\"))
  (:FILE \"src/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb6820a020a23d11a36745fa1f3a6b\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"8afc5ec2b0eddbc4ad13ea389b4e232b\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8202843bddb817da4279ac959ae3f3c4\"))
  (:FILE \"src/execution/ready-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"a64d98c9ff429d6103d6e10ee1fd7980\"))
  (:FILE \"src/execution/ready.lisp\" :MD5
   #A((32) BASE-CHAR . \"2c1892002f0599bb8273093031017520\"))
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
   #A((32) BASE-CHAR . \"1a51ef4a488bb9fde2ff7d47bae01379\"))
  (:FILE \"src/recovery/decisions-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"cbdc30f93109c474e1fc25066c9b9b13\"))
  (:FILE \"src/recovery/decisions-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"f782d1137b8ce342b91c9999cfb7accc\"))
  (:FILE \"src/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"852149de4c289b8e067602780378d87a\"))
  (:FILE \"src/recovery/decisions-sort.lisp\" :MD5
   #A((32) BASE-CHAR . \"b33e57a643f2fca810846f6226366253\"))
  (:FILE \"src/recovery/decisions-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"f4433fd19ebc7239dbc2628c39f3ecdb\"))
  (:FILE \"src/recovery/manifest-build.lisp\" :MD5
   #A((32) BASE-CHAR . \"bf65b1731eab6e0572461ef5cc60fc40\"))
  (:FILE \"src/recovery/manifest-decode.lisp\" :MD5
   #A((32) BASE-CHAR . \"67975249aaabd751757cdfb9222cc3c4\"))
  (:FILE \"src/recovery/manifest-fold.lisp\" :MD5
   #A((32) BASE-CHAR . \"e0d2498db1011e857b7b0daa1934f187\"))
  (:FILE \"src/recovery/manifest-package.lisp\" :MD5
   #A((32) BASE-CHAR . \"aa1768854b77767e4e2ddef296bfc93f\"))
  (:FILE \"src/recovery/manifest-query.lisp\" :MD5
   #A((32) BASE-CHAR . \"ebd7a54adea2213294a887e6d4db0927\"))
  (:FILE \"src/recovery/manifest-types.lisp\" :MD5
   #A((32) BASE-CHAR . \"7b1d4054415faca7e5fca59ad83b4d4a\"))
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
 :RECORDED-AT 4000529100 :SBCL #A((5) BASE-CHAR . \"2.6.9\") :MACHINE
 #A((5) BASE-CHAR . \"ARM64\") :OS #A((6) BASE-CHAR . \"Darwin\") :OS-VERSION
 #A((6) BASE-CHAR . \"27.0.0\") :WORKERS 1 :SAFETY 3 :TIMER-UNITS-PER-SECOND
 1000000 :LIMITS
 (:SUCCESS-PATH-ONLY :SERIAL :PREALLOCATED-INPUTS-AND-SCRATCH
  :STRUCTURAL-VALIDATION-ONLY :NO-MATERIALIZED-DOCUMENT-OR-FLOAT
  :COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF :EXTERNAL-LOAD-UNCONTROLLED
  :NO-POOL-OR-DEVICE-THROUGHPUT :NO-SCALING-OR-LATENCY-THRESHOLD))
")
