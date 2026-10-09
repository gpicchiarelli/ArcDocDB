(:SCHEMA-VERSION 1 :KIND :RAW-MUTATION-OUTPUT :FORMATS (1 2) :PROCESS-ARTIFACT
 "mutazioni.lisp" :SOURCE-PATH
 #A((81) BASE-CHAR
    . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/report.lisp")
 :STATUS :OK :SOURCE-CONSISTENCY :STABLE :RAW-REPORT
 (:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
  ((:FILE "arcdocdb.asd" :MD5
    #A((32) BASE-CHAR . "6a3d9189b7f122239934fd951c3e7593"))
   (:FILE "tools/build.lisp" :MD5
    #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
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
    #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5"))
   (:FILE "tests/foundation/batch.lisp" :MD5
    #A((32) BASE-CHAR . "29fc6a9711ea9265840e8cde4971f74e"))
   (:FILE "tests/foundation/binary.lisp" :MD5
    #A((32) BASE-CHAR . "07c4c9ac2177f22e5b7fb25f9867a133"))
   (:FILE "tests/foundation/record.lisp" :MD5
    #A((32) BASE-CHAR . "1300a75bcab1801ad064c401cd81123f"))
   (:FILE "tests/foundation/support.lisp" :MD5
    #A((32) BASE-CHAR . "758adad069aec2f9dbe0635797314ff6"))
   (:FILE "tests/io/native.lisp" :MD5
    #A((32) BASE-CHAR . "1e6fd9ab36eb4e307207d371ed947757"))
   (:FILE "tests/io/support.lisp" :MD5
    #A((32) BASE-CHAR . "a26526e87fe46794b8bbab1fdd46d68c"))
   (:FILE "tests/io/transfer.lisp" :MD5
    #A((32) BASE-CHAR . "ab2fb36682dd8b8bc757e586ceb3be62"))
   (:FILE "tests/lint-fixtures/bad.lisp" :MD5
    #A((32) BASE-CHAR . "30f1396c941dd9b8a41ca15698b5a347"))
   (:FILE "tests/lint-fixtures/good.lisp" :MD5
    #A((32) BASE-CHAR . "f85250c3a057c851db6745b9eba27da1"))
   (:FILE "tests/recovery/corruption.lisp" :MD5
    #A((32) BASE-CHAR . "a369b8176d4e877ab546d17e983b94ed"))
   (:FILE "tests/recovery/decisions-audit.lisp" :MD5
    #A((32) BASE-CHAR . "33b98cf215d1ddb469d02cc6c0032bfe"))
   (:FILE "tests/recovery/decisions-support.lisp" :MD5
    #A((32) BASE-CHAR . "80348d0ce2adbc8a4d37db49df291b1d"))
   (:FILE "tests/recovery/decisions.lisp" :MD5
    #A((32) BASE-CHAR . "5add0e087181bad8ce330af23fc26686"))
   (:FILE "tests/recovery/scan.lisp" :MD5
    #A((32) BASE-CHAR . "aa7af12d270673b62542d32ec60b361a"))
   (:FILE "tests/recovery/support.lisp" :MD5
    #A((32) BASE-CHAR . "769bac1994a5e3d74bd56b510970bf9b"))
   (:FILE "tests/smoke.lisp" :MD5
    #A((32) BASE-CHAR . "afb2e2bc7ff7249ebb2e1ccf0f87aaf3"))
   (:FILE "tests/storage/compaction-scan.lisp" :MD5
    #A((32) BASE-CHAR . "cb4acb5a73eb973f53ef337113880d32"))
   (:FILE "tests/storage/control-payload.lisp" :MD5
    #A((32) BASE-CHAR . "25f3c822273c898d2263ceb3db538cab"))
   (:FILE "tests/storage/log-header.lisp" :MD5
    #A((32) BASE-CHAR . "eecb2fe94e710a918254e5ad453a0daa"))
   (:FILE "tests/storage/segment-header.lisp" :MD5
    #A((32) BASE-CHAR . "ab2c52fb6b79702d50dcef6d12ca8906"))
   (:FILE "tests/storage/support.lisp" :MD5
    #A((32) BASE-CHAR . "82a4dbb4767c17f9851143a637af3b83"))
   (:FILE "tests/wal/builder.lisp" :MD5
    #A((32) BASE-CHAR . "0d01e4e18c0a559873fce584a0ac91cd"))
   (:FILE "tests/wal/fault.lisp" :MD5
    #A((32) BASE-CHAR . "00367366b82918614d84f517f4bb395e"))
   (:FILE "tests/wal/group.lisp" :MD5
    #A((32) BASE-CHAR . "0ee2462103a749b58488561aeacaac07"))
   (:FILE "tests/wal/native.lisp" :MD5
    #A((32) BASE-CHAR . "0643b96c5ee339f9826b19150d065ddf"))
   (:FILE "tests/wal/support.lisp" :MD5
    #A((32) BASE-CHAR . "15952f6b761acea4519abf701bb2346c"))
   (:FILE "tools/compaction-mutation.lisp" :MD5
    #A((32) BASE-CHAR . "11a8af81275b8ec38fa33328e9abbba2")))
  :MUTANTS
  ((:NAME "compaction-origin" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
    :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/test.log"))
   (:NAME "compaction-tombstone-kind" :DETECTED T :EXIT-CODE 1 :RESULT
    :DETECTED :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/test.log"))
   (:NAME "compaction-prepared-bit" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
    :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/test.log"))
   (:NAME "compaction-physical-tail" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
    :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/test.log"))
   (:NAME "compaction-byte-budget" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
    :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/test.log"))
   (:NAME "compaction-record-budget" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
    :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/test.log"))
   (:NAME "compaction-header-version" :DETECTED T :EXIT-CODE 1 :RESULT
    :DETECTED :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/test.log"))
   (:NAME "compaction-put-tombstone-count" :DETECTED T :EXIT-CODE 1 :RESULT
    :DETECTED :DIAGNOSTIC NIL :LOG
    #A((80) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/test.log")))
  :BASELINE
  (:STATUS :OK :EXIT-CODE 0 :LOG
   #A((87) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/baseline/test.log")
   :DIAGNOSTIC NIL)
  :SELF-TEST
  (:STATUS :OK :SUBSTITUTION :FIRST-ONLY :CLASSIFICATION
   :AFTER-EXACT-SMOKE-LINE :BACKTRACE-MARKER :INVALID :INVALID-TARGETS
   (:MISSING :AMBIGUOUS) :COMPILATION-FAILURE :INVALID :APPLICABLE-MUTANTS 8)
  :SCHEMA-VERSION 1 :KIND :COMPACTION-MUTATIONS :STATUS :OK :RECORDED-AT
  4000507329 :SBCL #A((5) BASE-CHAR . "2.6.9") :SOURCE-FINGERPRINTS-BEFORE
  ((:FILE "arcdocdb.asd" :MD5
    #A((32) BASE-CHAR . "6a3d9189b7f122239934fd951c3e7593"))
   (:FILE "tools/build.lisp" :MD5
    #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
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
    #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5"))
   (:FILE "tests/foundation/batch.lisp" :MD5
    #A((32) BASE-CHAR . "29fc6a9711ea9265840e8cde4971f74e"))
   (:FILE "tests/foundation/binary.lisp" :MD5
    #A((32) BASE-CHAR . "07c4c9ac2177f22e5b7fb25f9867a133"))
   (:FILE "tests/foundation/record.lisp" :MD5
    #A((32) BASE-CHAR . "1300a75bcab1801ad064c401cd81123f"))
   (:FILE "tests/foundation/support.lisp" :MD5
    #A((32) BASE-CHAR . "758adad069aec2f9dbe0635797314ff6"))
   (:FILE "tests/io/native.lisp" :MD5
    #A((32) BASE-CHAR . "1e6fd9ab36eb4e307207d371ed947757"))
   (:FILE "tests/io/support.lisp" :MD5
    #A((32) BASE-CHAR . "a26526e87fe46794b8bbab1fdd46d68c"))
   (:FILE "tests/io/transfer.lisp" :MD5
    #A((32) BASE-CHAR . "ab2fb36682dd8b8bc757e586ceb3be62"))
   (:FILE "tests/lint-fixtures/bad.lisp" :MD5
    #A((32) BASE-CHAR . "30f1396c941dd9b8a41ca15698b5a347"))
   (:FILE "tests/lint-fixtures/good.lisp" :MD5
    #A((32) BASE-CHAR . "f85250c3a057c851db6745b9eba27da1"))
   (:FILE "tests/recovery/corruption.lisp" :MD5
    #A((32) BASE-CHAR . "a369b8176d4e877ab546d17e983b94ed"))
   (:FILE "tests/recovery/decisions-audit.lisp" :MD5
    #A((32) BASE-CHAR . "33b98cf215d1ddb469d02cc6c0032bfe"))
   (:FILE "tests/recovery/decisions-support.lisp" :MD5
    #A((32) BASE-CHAR . "80348d0ce2adbc8a4d37db49df291b1d"))
   (:FILE "tests/recovery/decisions.lisp" :MD5
    #A((32) BASE-CHAR . "5add0e087181bad8ce330af23fc26686"))
   (:FILE "tests/recovery/scan.lisp" :MD5
    #A((32) BASE-CHAR . "aa7af12d270673b62542d32ec60b361a"))
   (:FILE "tests/recovery/support.lisp" :MD5
    #A((32) BASE-CHAR . "769bac1994a5e3d74bd56b510970bf9b"))
   (:FILE "tests/smoke.lisp" :MD5
    #A((32) BASE-CHAR . "afb2e2bc7ff7249ebb2e1ccf0f87aaf3"))
   (:FILE "tests/storage/compaction-scan.lisp" :MD5
    #A((32) BASE-CHAR . "cb4acb5a73eb973f53ef337113880d32"))
   (:FILE "tests/storage/control-payload.lisp" :MD5
    #A((32) BASE-CHAR . "25f3c822273c898d2263ceb3db538cab"))
   (:FILE "tests/storage/log-header.lisp" :MD5
    #A((32) BASE-CHAR . "eecb2fe94e710a918254e5ad453a0daa"))
   (:FILE "tests/storage/segment-header.lisp" :MD5
    #A((32) BASE-CHAR . "ab2c52fb6b79702d50dcef6d12ca8906"))
   (:FILE "tests/storage/support.lisp" :MD5
    #A((32) BASE-CHAR . "82a4dbb4767c17f9851143a637af3b83"))
   (:FILE "tests/wal/builder.lisp" :MD5
    #A((32) BASE-CHAR . "0d01e4e18c0a559873fce584a0ac91cd"))
   (:FILE "tests/wal/fault.lisp" :MD5
    #A((32) BASE-CHAR . "00367366b82918614d84f517f4bb395e"))
   (:FILE "tests/wal/group.lisp" :MD5
    #A((32) BASE-CHAR . "0ee2462103a749b58488561aeacaac07"))
   (:FILE "tests/wal/native.lisp" :MD5
    #A((32) BASE-CHAR . "0643b96c5ee339f9826b19150d065ddf"))
   (:FILE "tests/wal/support.lisp" :MD5
    #A((32) BASE-CHAR . "15952f6b761acea4519abf701bb2346c"))
   (:FILE "tools/compaction-mutation.lisp" :MD5
    #A((32) BASE-CHAR . "11a8af81275b8ec38fa33328e9abbba2")))
  :LIMITS
  (:TARGETED-MUTANTS-ONLY :IN-MEMORY-COMPACTED-SEGMENT-TESTS
   :COMPILE-FAILURE-NOT-DETECTION :NO-DURABILITY-OR-ENGINE-QUALIFICATION))
 :RAW-REPORT-TEXT "(:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"6a3d9189b7f122239934fd951c3e7593\"))
  (:FILE \"tools/build.lisp\" :MD5
   #A((32) BASE-CHAR . \"a0367c24405a56a2ffe84a9282004db0\"))
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
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\"))
  (:FILE \"tests/foundation/batch.lisp\" :MD5
   #A((32) BASE-CHAR . \"29fc6a9711ea9265840e8cde4971f74e\"))
  (:FILE \"tests/foundation/binary.lisp\" :MD5
   #A((32) BASE-CHAR . \"07c4c9ac2177f22e5b7fb25f9867a133\"))
  (:FILE \"tests/foundation/record.lisp\" :MD5
   #A((32) BASE-CHAR . \"1300a75bcab1801ad064c401cd81123f\"))
  (:FILE \"tests/foundation/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"758adad069aec2f9dbe0635797314ff6\"))
  (:FILE \"tests/io/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"1e6fd9ab36eb4e307207d371ed947757\"))
  (:FILE \"tests/io/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"a26526e87fe46794b8bbab1fdd46d68c\"))
  (:FILE \"tests/io/transfer.lisp\" :MD5
   #A((32) BASE-CHAR . \"ab2fb36682dd8b8bc757e586ceb3be62\"))
  (:FILE \"tests/lint-fixtures/bad.lisp\" :MD5
   #A((32) BASE-CHAR . \"30f1396c941dd9b8a41ca15698b5a347\"))
  (:FILE \"tests/lint-fixtures/good.lisp\" :MD5
   #A((32) BASE-CHAR . \"f85250c3a057c851db6745b9eba27da1\"))
  (:FILE \"tests/recovery/corruption.lisp\" :MD5
   #A((32) BASE-CHAR . \"a369b8176d4e877ab546d17e983b94ed\"))
  (:FILE \"tests/recovery/decisions-audit.lisp\" :MD5
   #A((32) BASE-CHAR . \"33b98cf215d1ddb469d02cc6c0032bfe\"))
  (:FILE \"tests/recovery/decisions-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"80348d0ce2adbc8a4d37db49df291b1d\"))
  (:FILE \"tests/recovery/decisions.lisp\" :MD5
   #A((32) BASE-CHAR . \"5add0e087181bad8ce330af23fc26686\"))
  (:FILE \"tests/recovery/scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"aa7af12d270673b62542d32ec60b361a\"))
  (:FILE \"tests/recovery/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"769bac1994a5e3d74bd56b510970bf9b\"))
  (:FILE \"tests/smoke.lisp\" :MD5
   #A((32) BASE-CHAR . \"afb2e2bc7ff7249ebb2e1ccf0f87aaf3\"))
  (:FILE \"tests/storage/compaction-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"cb4acb5a73eb973f53ef337113880d32\"))
  (:FILE \"tests/storage/control-payload.lisp\" :MD5
   #A((32) BASE-CHAR . \"25f3c822273c898d2263ceb3db538cab\"))
  (:FILE \"tests/storage/log-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"eecb2fe94e710a918254e5ad453a0daa\"))
  (:FILE \"tests/storage/segment-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"ab2c52fb6b79702d50dcef6d12ca8906\"))
  (:FILE \"tests/storage/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"82a4dbb4767c17f9851143a637af3b83\"))
  (:FILE \"tests/wal/builder.lisp\" :MD5
   #A((32) BASE-CHAR . \"0d01e4e18c0a559873fce584a0ac91cd\"))
  (:FILE \"tests/wal/fault.lisp\" :MD5
   #A((32) BASE-CHAR . \"00367366b82918614d84f517f4bb395e\"))
  (:FILE \"tests/wal/group.lisp\" :MD5
   #A((32) BASE-CHAR . \"0ee2462103a749b58488561aeacaac07\"))
  (:FILE \"tests/wal/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"0643b96c5ee339f9826b19150d065ddf\"))
  (:FILE \"tests/wal/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"15952f6b761acea4519abf701bb2346c\"))
  (:FILE \"tools/compaction-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"11a8af81275b8ec38fa33328e9abbba2\")))
 :MUTANTS
 ((:NAME \"compaction-origin\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/test.log\"))
  (:NAME \"compaction-tombstone-kind\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/test.log\"))
  (:NAME \"compaction-prepared-bit\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/test.log\"))
  (:NAME \"compaction-physical-tail\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/test.log\"))
  (:NAME \"compaction-byte-budget\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/test.log\"))
  (:NAME \"compaction-record-budget\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/test.log\"))
  (:NAME \"compaction-header-version\" :DETECTED T :EXIT-CODE 1 :RESULT :DETECTED
   :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/test.log\"))
  (:NAME \"compaction-put-tombstone-count\" :DETECTED T :EXIT-CODE 1 :RESULT
   :DETECTED :DIAGNOSTIC NIL :LOG
   #A((80) BASE-CHAR
      . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/test.log\")))
 :BASELINE
 (:STATUS :OK :EXIT-CODE 0 :LOG
  #A((87) BASE-CHAR
     . \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/baseline/test.log\")
  :DIAGNOSTIC NIL)
 :SELF-TEST
 (:STATUS :OK :SUBSTITUTION :FIRST-ONLY :CLASSIFICATION :AFTER-EXACT-SMOKE-LINE
  :BACKTRACE-MARKER :INVALID :INVALID-TARGETS (:MISSING :AMBIGUOUS)
  :COMPILATION-FAILURE :INVALID :APPLICABLE-MUTANTS 8)
 :SCHEMA-VERSION 1 :KIND :COMPACTION-MUTATIONS :STATUS :OK :RECORDED-AT
 4000507329 :SBCL #A((5) BASE-CHAR . \"2.6.9\") :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"6a3d9189b7f122239934fd951c3e7593\"))
  (:FILE \"tools/build.lisp\" :MD5
   #A((32) BASE-CHAR . \"a0367c24405a56a2ffe84a9282004db0\"))
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
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\"))
  (:FILE \"tests/foundation/batch.lisp\" :MD5
   #A((32) BASE-CHAR . \"29fc6a9711ea9265840e8cde4971f74e\"))
  (:FILE \"tests/foundation/binary.lisp\" :MD5
   #A((32) BASE-CHAR . \"07c4c9ac2177f22e5b7fb25f9867a133\"))
  (:FILE \"tests/foundation/record.lisp\" :MD5
   #A((32) BASE-CHAR . \"1300a75bcab1801ad064c401cd81123f\"))
  (:FILE \"tests/foundation/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"758adad069aec2f9dbe0635797314ff6\"))
  (:FILE \"tests/io/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"1e6fd9ab36eb4e307207d371ed947757\"))
  (:FILE \"tests/io/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"a26526e87fe46794b8bbab1fdd46d68c\"))
  (:FILE \"tests/io/transfer.lisp\" :MD5
   #A((32) BASE-CHAR . \"ab2fb36682dd8b8bc757e586ceb3be62\"))
  (:FILE \"tests/lint-fixtures/bad.lisp\" :MD5
   #A((32) BASE-CHAR . \"30f1396c941dd9b8a41ca15698b5a347\"))
  (:FILE \"tests/lint-fixtures/good.lisp\" :MD5
   #A((32) BASE-CHAR . \"f85250c3a057c851db6745b9eba27da1\"))
  (:FILE \"tests/recovery/corruption.lisp\" :MD5
   #A((32) BASE-CHAR . \"a369b8176d4e877ab546d17e983b94ed\"))
  (:FILE \"tests/recovery/decisions-audit.lisp\" :MD5
   #A((32) BASE-CHAR . \"33b98cf215d1ddb469d02cc6c0032bfe\"))
  (:FILE \"tests/recovery/decisions-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"80348d0ce2adbc8a4d37db49df291b1d\"))
  (:FILE \"tests/recovery/decisions.lisp\" :MD5
   #A((32) BASE-CHAR . \"5add0e087181bad8ce330af23fc26686\"))
  (:FILE \"tests/recovery/scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"aa7af12d270673b62542d32ec60b361a\"))
  (:FILE \"tests/recovery/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"769bac1994a5e3d74bd56b510970bf9b\"))
  (:FILE \"tests/smoke.lisp\" :MD5
   #A((32) BASE-CHAR . \"afb2e2bc7ff7249ebb2e1ccf0f87aaf3\"))
  (:FILE \"tests/storage/compaction-scan.lisp\" :MD5
   #A((32) BASE-CHAR . \"cb4acb5a73eb973f53ef337113880d32\"))
  (:FILE \"tests/storage/control-payload.lisp\" :MD5
   #A((32) BASE-CHAR . \"25f3c822273c898d2263ceb3db538cab\"))
  (:FILE \"tests/storage/log-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"eecb2fe94e710a918254e5ad453a0daa\"))
  (:FILE \"tests/storage/segment-header.lisp\" :MD5
   #A((32) BASE-CHAR . \"ab2c52fb6b79702d50dcef6d12ca8906\"))
  (:FILE \"tests/storage/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"82a4dbb4767c17f9851143a637af3b83\"))
  (:FILE \"tests/wal/builder.lisp\" :MD5
   #A((32) BASE-CHAR . \"0d01e4e18c0a559873fce584a0ac91cd\"))
  (:FILE \"tests/wal/fault.lisp\" :MD5
   #A((32) BASE-CHAR . \"00367366b82918614d84f517f4bb395e\"))
  (:FILE \"tests/wal/group.lisp\" :MD5
   #A((32) BASE-CHAR . \"0ee2462103a749b58488561aeacaac07\"))
  (:FILE \"tests/wal/native.lisp\" :MD5
   #A((32) BASE-CHAR . \"0643b96c5ee339f9826b19150d065ddf\"))
  (:FILE \"tests/wal/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"15952f6b761acea4519abf701bb2346c\"))
  (:FILE \"tools/compaction-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"11a8af81275b8ec38fa33328e9abbba2\")))
 :LIMITS
 (:TARGETED-MUTANTS-ONLY :IN-MEMORY-COMPACTED-SEGMENT-TESTS
  :COMPILE-FAILURE-NOT-DETECTION :NO-DURABILITY-OR-ENGINE-QUALIFICATION))
"
 :LOGS
 ((:NAME "baseline" :SOURCE-PATH
   #A((87) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/baseline/test.log")
   :LOCAL-FILE "mutazione-baseline.log" :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
ok    TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE
ok    TEST-REQ-FOR-003-COMPACTION-EVERY-CONTENT-TRUNCATION
ok    TEST-REQ-FOR-001-COMPACTION-EVERY-BIT-CORRUPTION
ok    TEST-REQ-FOR-002-COMPACTION-AUTHORITATIVE-IDENTITIES
ok    TEST-REQ-FOR-002-COMPACTION-HEADER-FIELDS-AND-VERSION
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-WRITER-ORIGIN
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-PREPARED-RECORDS
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-CONTROL-RECORDS
ok    TEST-REQ-FOR-003-COMPACTION-CRC-VALID-INVALID-TYPE-AND-FLAGS
ok    TEST-REQ-FOR-003-COMPACTION-CRC-VALID-INCONSISTENT-LENGTHS
ok    TEST-REQ-FOR-001-COMPACTION-IGNORES-PHYSICAL-TAIL
ok    TEST-REQ-AFF-008-COMPACTION-EXACT-AND-EXHAUSTED-BUDGETS
ok    TEST-REQ-AFF-008-COMPACTION-INVALID-ARGUMENTS
ok    TEST-REQ-FOR-003-EDIT-ENCODING-LAYOUT
ok    TEST-REQ-FOR-003-EDIT-TRUNCATION-COUNTS-AND-LENGTHS
ok    TEST-REQ-AFF-008-EDIT-BUDGET-BOUNDARIES
ok    TEST-REQ-TXM-001-DECISION-ENCODING-LAYOUT
ok    TEST-REQ-TXM-001-DECISION-TRUNCATION-AND-BUDGETS
ok    TEST-REQ-FOR-003-CONTROL-RECORD-BOTH-VERSIONS
ok    TEST-REQ-FOR-003-CONTROL-RECORD-INTEGRITY-BEFORE-COUNTS
ok    TEST-REQ-AFF-008-ENCODER-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-008-EDIT-CUMULATIVE-BUDGET-AND-CORRUPT-HUGE-COUNTS
ok    TEST-REQ-AFF-008-ENCODER-OVERFLOW-AND-UNUSED-SECTIONS
ok    TEST-REQ-FOR-003-DECISION-RECORD-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-AFF-008-BYTE-BUDGET-BEFORE-CRC-SCAN
ok    TEST-REQ-AFF-008-INTERNAL-RANGE-GUARDS
44 test dei metadati storage superati.
ok    TEST-REQ-AFF-001-SHORT-APPEND-AND-GROUP-FLUSH
ok    TEST-REQ-STO-003-SHORT-PREAD-POSITIONAL-NO-STATE-WRITE
ok    TEST-REQ-AFF-001-WRITE-ERRORS-NEVER-RETRY
ok    TEST-REQ-AFF-001-FLUSH-ERROR-PRESERVES-DURABLE-FRONTIER
ok    TEST-REQ-AFF-002-READ-ERRORS-NO-RETRY-NO-SHARED-MUTATION
ok    TEST-REQ-AFF-008-INVALID-PROGRESS-AND-EOF
ok    TEST-REQ-AFF-008-PREFLIGHT-BUDGET-AND-ZERO-LENGTH
ok    TEST-REQ-AFF-001-CLOSE-ONCE-EVEN-EINTR
ok    TEST-REQ-AFF-001-DIRECTORY-FLUSH-DISPATCH-AND-INVALID-RETURN
ok    TEST-REQ-STO-003-OPEN-PREFLIGHT-AND-ERRORS
ok    TEST-REQ-AFF-001-DIRECTORY-FAILURE-AND-EMPTY-FILE-FLUSH
ok    TEST-REQ-AFF-001-INVALID-CLOSE-RESULT-AND-CLOSED-READER
ok    TEST-REQ-AFF-004-INVALID-PRIVATE-DESCRIPTOR-BEFORE-SYSCALL
ok    TEST-REQ-STO-003-NATIVE-APPEND-FLUSH-AND-CHECKED-RECORD
ok    TEST-REQ-STO-003-NATIVE-NO-FOLLOW-FILE-KINDS-AND-CLOEXEC
ok    TEST-REQ-STO-003-CONCURRENT-PREAD-DISTINCT-BUFFERS
ok    TEST-REQ-FOR-003-NATIVE-TWO-SEALED-BATCHES-ONE-FLUSH
ok    TEST-REQ-AFF-004-NATIVE-ERRNO-AND-CLEANUP-PROVENANCE
18 test I/O superati.
ok    TEST-REQ-FOR-003-VALID-LOG-ORACLE-AND-DETERMINISM
ok    TEST-REQ-FOR-003-EMPTY-LOG-AND-EMPTY-BATCHES
ok    TEST-REQ-AFF-009-EVERY-LOG-TRUNCATION
ok    TEST-REQ-AFF-009-FRONTIER-BOUNDARY-AND-FAILED-BATCH-START
ok    TEST-REQ-AFF-009-DAMAGED-WITNESS-BATCH-REMAINS-EVIDENCE
ok    TEST-REQ-AFF-009-INVALID-WITNESSES-ARE-IGNORED
ok    TEST-REQ-AFF-009-CORRUPT-LENGTH-CANNOT-HIDE-WITNESS
ok    TEST-REQ-AFF-009-BROKEN-HEADER-DOES-NOT-END-SEARCH
ok    TEST-REQ-AFF-009-WITNESS-AT-EVERY-ALIGNMENT
ok    TEST-REQ-AFF-009-NESTED-SEAL-AT-LAST-SEARCH-POSITION
ok    TEST-REQ-AFF-008-LOG-AND-BATCH-BUDGETS
ok    TEST-REQ-AFF-008-BATCH-BUDGET-CANNOT-CLASSIFY-UNCHECKED-TAIL
ok    TEST-REQ-AFF-008-SEARCH-BUDGET-COUNTS-POSITIONS
ok    TEST-REQ-AFF-008-EOF-IS-EXPLICIT-AND-COMPLETE
ok    TEST-REQ-AFF-008-INVALID-CONFIGURATION-IS-NEVER-TAIL
ok    TEST-REQ-AFF-009-U64-OFFSETS-AND-OVERFLOW
13504 mutazioni bit prima del testimone durevole verificate.
ok    TEST-REQ-AFF-009-EVERY-BIT-BEFORE-DURABLE-WITNESS
6752 mutazioni bit nel lotto finale senza testimone verificate.
ok    TEST-REQ-AFF-017-EVERY-BIT-IN-FINAL-UNWITNESSED-BATCH
ok    TEST-REQ-AFF-009-OVERLAPPING-SEAL-AFTER-NONCOVERING-FRONTIER
ok    TEST-REQ-TXM-005-DECISION-TABLE-ORDERED-UNORDERED-ORACLE
ok    TEST-REQ-TXM-005-SEEDED-HISTORIES-AND-PERMUTED-DUPLICATES
ok    TEST-REQ-TXM-001-ZERO-MAXIMUM-U64-AND-SHARED-CSN
ok    TEST-REQ-TXM-005-TABLE-OWNS-PARTICIPANT-COPIES
ok    TEST-REQ-TXM-001-PARTICIPANT-EXACT-BYTES-AND-QUERY-RANGES
ok    TEST-REQ-TXM-005-CONFLICTING-CSN-SET-OR-COUNT
ok    TEST-REQ-TXM-005-DUPLICATE-PARTICIPANTS-WITHIN-RECORD
ok    TEST-REQ-TXM-005-EVERY-CUT-KEEPS-ONLY-SEALED-DECISIONS
ok    TEST-REQ-TXM-005-PRESUMED-ABORT-AFTER-COMPLETE-TAIL-SEARCH
ok    TEST-REQ-TXM-005-SCANS-LATER-CORRUPTION-BEFORE-PAYLOAD-OR-BUDGET
ok    TEST-REQ-FOR-003-SEALED-INVALID-DECISION-PAYLOAD-IS-NOT-TAIL
ok    TEST-REQ-AFF-008-EMPTY-DECISIONS-ZERO-AND-LARGE-BUDGETS
ok    TEST-REQ-AFF-008-PHYSICAL-DUPLICATE-RECORD-BUDGETS
ok    TEST-REQ-AFF-008-INVALID-DECISION-BUDGETS-EVEN-EMPTY
ok    TEST-REQ-AFF-008-DECISION-SCANNER-BUDGETS-PROPAGATE
ok    TEST-REQ-AFF-008-DECISION-EOF-AND-VERSION-ERRORS
ok    TEST-REQ-TXM-005-HIGH-FILE-OFFSET-AND-CONFLICT-PROVENANCE
ok    TEST-REQ-TXM-005-FIRST-PHYSICAL-DECISION-CONFLICT-ACROSS-TXID-GROUPS
ok    TEST-REQ-TXM-001-PARTICIPANT-EVERY-BYTE-AND-EVERY-BIT
ok    TEST-REQ-FOR-003-SEALED-TRAILING-DECISION-PAYLOAD
ok    TEST-REQ-FOR-003-SHORT-DECISION-FRAME-REQUIRES-COVERING-WITNESS
ok    TEST-REQ-TXM-005-UNSEALED-SEMANTIC-ERRORS-AND-COVERING-WITNESS
ok    TEST-REQ-AFF-008-DECISION-BUDGET-OFFSETS-BEFORE-COALESCENCE
ok    TEST-REQ-TXM-005-PUBLIC-DEFAULT-BUDGETS-AND-EXPLICIT-VERSION
ok    TEST-REQ-TXM-001-MAXIMUM-U16-PARTICIPANT-COUNT
44 test recovery superati.
ok    TEST-REQ-WAL-005-CODEC-V1-V2-AND-HIGH-U64
ok    TEST-REQ-WAL-005-PRESERVE-PREPARED-OUTCOME-DECISION-TXID
ok    TEST-REQ-WAL-005-EMPTY-AND-SEAL-EXACT-CAPACITY
ok    TEST-REQ-AFF-008-BUILDER-PREFLIGHT-AND-SEALED-IMMUTABILITY
ok    TEST-REQ-WAL-002-TWO-LOTS-ONE-FLUSH-AND-REUSE
ok    TEST-REQ-AFF-008-GROUP-BUDGET-IDENTITY-AND-ORDER
ok    TEST-REQ-AFF-008-FILE-BUDGET-BEFORE-ANY-WRITE
ok    TEST-REQ-WAL-005-OFFSET-AND-DURABLE-WITNESS-BEFORE-WRITE
ok    TEST-REQ-WAL-003-CONTROL-LOG-NEVER-ASYNC
ok    TEST-REQ-AFF-008-CANCEL-UNSENT-GROUP-RELEASES-CAPACITY
ok    TEST-REQ-AFF-001-WRITE-FAILURE-STOPS-LOG-AND-ALL-BATCHES
ok    TEST-REQ-AFF-001-FLUSH-FAILURE-NEVER-ADVANCES-DURABILITY
ok    TEST-REQ-WAL-005-CRASH-AT-EVERY-WRITTEN-BYTE-V1-V2
ok    TEST-REQ-AFF-001-PRIVATE-OWNERSHIP-VIOLATION-STOPS-BEFORE-FLUSH
ok    TEST-REQ-WAL-002-SECOND-GROUP-REJECTED-UNTIL-FLUSH
ok    TEST-REQ-WAL-002-CONCURRENT-GROUPS-AT-MOST-ONE-WRITE
ok    TEST-REQ-WAL-002-CONCURRENT-FLUSH-AT-MOST-ONE-SYSCALL
ok    TEST-REQ-WAL-002-NATIVE-GROUP-AND-DURABLE-WITNESS-V1-V2
ok    TEST-REQ-AFF-009-SUBSEQUENT-BATCH-WITNESS-DETECTS-OLD-CORRUPTION
19 test WAL superati.
build e test: nessun avviso, tutti i controlli superati
")
  (:NAME "compaction-origin" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-0.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\":
Unhandled ARCDOCDB.CONDITIONS:INVALID-ARGUMENT in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                            {8005800453}>:
  ArcDocDB: COMPACTION-ORIGIN all'offset 0

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005800453}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8005327E93}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8005327E93}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8005327E93}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVALID-ARGUMENT :REASON :COMPACTION-ORIGIN :OFFSET 0)
4: (ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 :MAX-BYTES 67108864 :MAX-RECORDS 65536)
5: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (64 1 0 0 0))
6: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS)
7: (ARCDOCDB.STORAGE.TESTS:RUN)
8: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
9: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
10: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
11: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
12: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
13: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
14: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
15: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
16: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
17: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
18: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
19: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
20: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
21: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
22: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
23: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
24: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
25: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
26: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
27: (\"top level form\") [toplevel]
28: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
29: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
30: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
31: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
32: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
33: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
34: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
35: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
36: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107DB1B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
37: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
38: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\" {80052C0723}> NIL)
39: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107DB163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\" {80052C0723}>)
40: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/build.lisp\" {80052C0723}> NIL)
41: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
42: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
43: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
44: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
45: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
46: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107DB0F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
47: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
48: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
49: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107DB09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}>)
50: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
51: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
52: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/0/tools/compaction-isolated-build.lisp\" {80052C0043}>)
53: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
54: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
55: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
56: (SB-IMPL::TOPLEVEL-INIT)
57: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
58: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
59: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-tombstone-kind" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-1.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\":
Unhandled ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {80057F0803}>:
  ArcDocDB: COMPACTION-RECORD-KIND all'offset 90

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80057F0803}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005345803}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005345803}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005345803}>)
3: (ERROR ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED :REASON :COMPACTION-RECORD-KIND :OFFSET 90)
4: (ARCDOCDB.STORAGE.FORMAT::VERIFICA-RECORD-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 90 170 1)
5: (ARCDOCDB.STORAGE.FORMAT::SCANSIONA-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 170 1 65536)
6: (ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 170 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 :MAX-BYTES 67108864 :MAX-RECORDS 65536)
7: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 170 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (170 1 4 2 2))
8: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS)
9: (ARCDOCDB.STORAGE.TESTS:RUN)
10: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
11: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
12: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
13: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
14: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
15: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
16: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
17: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
18: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
21: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
22: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
23: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
24: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
25: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
26: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
27: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
28: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
29: (\"top level form\") [toplevel]
30: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
31: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
32: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
33: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
34: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
35: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
36: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
37: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
38: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109B91B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
39: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
40: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\" {80052C0723}> NIL)
41: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {109B9163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\" {80052C0723}>)
42: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/build.lisp\" {80052C0723}> NIL)
43: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
44: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
45: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
46: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
47: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
48: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109B90F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
49: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
50: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
51: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {109B909EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}>)
52: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
53: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
54: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/1/tools/compaction-isolated-build.lisp\" {80052C0043}>)
55: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
56: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
57: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
58: (SB-IMPL::TOPLEVEL-INIT)
59: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
60: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
61: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-prepared-bit" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-2.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
ok    TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE
ok    TEST-REQ-FOR-003-COMPACTION-EVERY-CONTENT-TRUNCATION
ok    TEST-REQ-FOR-001-COMPACTION-EVERY-BIT-CORRUPTION
ok    TEST-REQ-FOR-002-COMPACTION-AUTHORITATIVE-IDENTITIES
ok    TEST-REQ-FOR-002-COMPACTION-HEADER-FIELDS-AND-VERSION
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-WRITER-ORIGIN
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\":
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005800453}>:
  Asserzione fallita: ARCDOCDB.STORAGE.TESTS::CAUGHT

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005800453}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800546B3C3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800546B3C3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800546B3C3}>)
3: (ERROR \"Asserzione fallita: ~S\" ARCDOCDB.STORAGE.TESTS::CAUGHT)
4: (ARCDOCDB.STORAGE.TESTS::COMPACTION-EXPECT-ERROR #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 116 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED :COMPACTION-PREPARED)
5: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-CMP-009-COMPACTION-REJECTS-PREPARED-RECORDS)
6: (ARCDOCDB.STORAGE.TESTS:RUN)
7: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
8: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
9: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
10: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
11: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
12: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
13: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
14: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
15: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
16: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
17: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
18: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
21: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
22: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
23: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
24: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
25: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
26: (\"top level form\") [toplevel]
27: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
28: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
29: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
30: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
31: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
32: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
33: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
34: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
35: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105331B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
36: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
37: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\" {80052C0723}> NIL)
38: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {10533163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\" {80052C0723}>)
39: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/build.lisp\" {80052C0723}> NIL)
40: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
41: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
42: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
43: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
44: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
45: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105330F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
46: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
47: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
48: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1053309EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}>)
49: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
50: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
51: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/2/tools/compaction-isolated-build.lisp\" {80052C0043}>)
52: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
53: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
54: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
55: (SB-IMPL::TOPLEVEL-INIT)
56: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
57: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
58: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-physical-tail" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-3.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
ok    TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\":
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005800483}>:
  ArcDocDB: COMPACTION-RESULT all'offset 144

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005800483}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80053C03B3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80053C03B3}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80053C03B3}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :COMPACTION-RESULT :OFFSET 144)
4: (ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 :MAX-BYTES 67108864 :MAX-RECORDS 65536)
5: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (64 1 0 0 0))
6: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-FOR-003-COMPACTION-EVERY-CONTENT-TRUNCATION)
7: (ARCDOCDB.STORAGE.TESTS:RUN)
8: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
9: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
10: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
11: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
12: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
13: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
14: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
15: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
16: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
17: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
18: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
19: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
20: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
21: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
22: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
23: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
24: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
25: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
26: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
27: (\"top level form\") [toplevel]
28: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
29: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
30: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
31: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
32: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
33: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
34: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
35: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
36: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1097D1B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
37: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
38: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\" {80052C0723}> NIL)
39: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1097D163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\" {80052C0723}>)
40: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/build.lisp\" {80052C0723}> NIL)
41: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
42: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
43: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
44: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
45: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
46: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1097D0F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
47: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
48: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
49: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1097D09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}>)
50: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
51: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
52: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/3/tools/compaction-isolated-build.lisp\" {80052C0043}>)
53: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
54: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
55: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
56: (SB-IMPL::TOPLEVEL-INIT)
57: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
58: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
59: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-byte-budget" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-4.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\":
Unhandled ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                              {8005810453}>:
  ArcDocDB: COMPACTION-BYTE-BUDGET all'offset 0

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005810453}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED {8005327F03}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED {8005327F03}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED {8005327F03}>)
3: (ERROR ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED :REASON :COMPACTION-BYTE-BUDGET :OFFSET 0)
4: (ARCDOCDB.STORAGE.FORMAT::CHECK-COMPACTION-ARGUMENTS #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 64 0)
5: (ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 :MAX-BYTES 64 :MAX-RECORDS 0)
6: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 64 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (64 1 0 0 0) :MAX-BYTES 64 :MAX-RECORDS 0)
7: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS)
8: (ARCDOCDB.STORAGE.TESTS:RUN)
9: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
10: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
11: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
12: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
13: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
14: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
15: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
16: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
17: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
18: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
19: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
20: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
21: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
22: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
23: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
24: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
25: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
26: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
27: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
28: (\"top level form\") [toplevel]
29: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
30: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
31: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
32: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
33: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
34: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
35: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
36: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
37: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1091A1B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
38: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
39: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\" {80052C0723}> NIL)
40: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1091A163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\" {80052C0723}>)
41: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/build.lisp\" {80052C0723}> NIL)
42: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
43: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
44: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
45: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
46: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
47: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1091A0F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
48: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
49: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
50: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1091A09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}>)
51: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
52: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
53: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/4/tools/compaction-isolated-build.lisp\" {80052C0043}>)
54: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
55: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
56: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
57: (SB-IMPL::TOPLEVEL-INIT)
58: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
59: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
60: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-record-budget" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-5.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
ok    TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE
ok    TEST-REQ-FOR-003-COMPACTION-EVERY-CONTENT-TRUNCATION
ok    TEST-REQ-FOR-001-COMPACTION-EVERY-BIT-CORRUPTION
ok    TEST-REQ-FOR-002-COMPACTION-AUTHORITATIVE-IDENTITIES
ok    TEST-REQ-FOR-002-COMPACTION-HEADER-FIELDS-AND-VERSION
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-WRITER-ORIGIN
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-PREPARED-RECORDS
ok    TEST-REQ-CMP-009-COMPACTION-REJECTS-CONTROL-RECORDS
ok    TEST-REQ-FOR-003-COMPACTION-CRC-VALID-INVALID-TYPE-AND-FLAGS
ok    TEST-REQ-FOR-003-COMPACTION-CRC-VALID-INCONSISTENT-LENGTHS
ok    TEST-REQ-FOR-001-COMPACTION-IGNORES-PHYSICAL-TAIL
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\":
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80057F04E3}>:
  Asserzione fallita: ARCDOCDB.STORAGE.TESTS::CAUGHT

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80057F04E3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80054711C3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80054711C3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80054711C3}>)
3: (ERROR \"Asserzione fallita: ~S\" ARCDOCDB.STORAGE.TESTS::CAUGHT)
4: (ARCDOCDB.STORAGE.TESTS::COMPACTION-EXPECT-ERROR #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 115 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED :COMPACTION-RECORD-BUDGET :MAX-BYTES 115 :MAX-RECORDS 1)
5: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-AFF-008-COMPACTION-EXACT-AND-EXHAUSTED-BUDGETS)
6: (ARCDOCDB.STORAGE.TESTS:RUN)
7: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
8: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
9: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
10: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
11: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
12: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
13: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
14: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
15: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
16: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
17: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
18: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
21: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
22: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
23: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
24: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
25: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
26: (\"top level form\") [toplevel]
27: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
28: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
29: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
30: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
31: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
32: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
33: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
34: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
35: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107311B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
36: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
37: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\" {80052C0723}> NIL)
38: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {10731163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\" {80052C0723}>)
39: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/build.lisp\" {80052C0723}> NIL)
40: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
41: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
42: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
43: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
44: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
45: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107310F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
46: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
47: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
48: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1073109EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}>)
49: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
50: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
51: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/5/tools/compaction-isolated-build.lisp\" {80052C0043}>)
52: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
53: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
54: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
55: (SB-IMPL::TOPLEVEL-INIT)
56: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
57: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
58: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-header-version" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-6.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\":
Unhandled ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {80058236C3}>:
  ArcDocDB: V1-RESERVED all'offset 64

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80058236C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005329253}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005329253}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED {8005329253}>)
3: (ERROR ARCDOCDB.CONDITIONS:CORRUPTION-DETECTED :REASON :V1-RESERVED :OFFSET 64)
4: (ARCDOCDB.RECORD::CHECKED-HEADER #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 64 345 1 16777216)
5: (ARCDOCDB.RECORD:VERIFICA-CORNICE #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 64 345 :VERSION 1 :DOCUMENT-LIMIT 16777216)
6: (ARCDOCDB.STORAGE.FORMAT::VERIFICA-RECORD-COMPATTATO #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 64 345 1)
7: (ARCDOCDB.STORAGE.FORMAT::SCANSIONA-COMPATTATO #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 64 345 1 65536)
8: (ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 345 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 :MAX-BYTES 67108864 :MAX-RECORDS 65536)
9: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 2 0 2 0 ...) 345 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (345 2 1 1 0))
10: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE)
11: (ARCDOCDB.STORAGE.TESTS:RUN)
12: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
13: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
14: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
15: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
16: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
17: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
18: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
19: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
20: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
21: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
22: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
23: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
24: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
25: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
26: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
27: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
28: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
29: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
30: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
31: (\"top level form\") [toplevel]
32: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
33: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
34: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
35: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
36: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
37: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
38: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
39: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
40: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105481B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
41: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
42: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\" {80052C0723}> NIL)
43: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {10548163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\" {80052C0723}>)
44: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/build.lisp\" {80052C0723}> NIL)
45: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
46: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
47: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
48: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
49: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
50: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105480F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
51: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
52: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
53: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1054809EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}>)
54: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
55: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
56: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/6/tools/compaction-isolated-build.lisp\" {80052C0043}>)
57: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
58: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
59: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
60: (SB-IMPL::TOPLEVEL-INIT)
61: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
62: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
63: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
")
  (:NAME "compaction-put-tombstone-count" :SOURCE-PATH
   #A((80) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/test.log")
   :LOCAL-FILE #A((15) BASE-CHAR . "mutazione-7.log") :CONTENT
   "ok    package ARCDOCDB presente
ok    ARCDOCDB:*VERSION* è una stringa
ok    TEST-REQ-AFF-004-TYPED-ERRORS-RENDERING
ok    TEST-REQ-FOR-003-OUT-OF-LINE-READERS
ok    TEST-REQ-FOR-003-LITTLE-ENDIAN
ok    TEST-REQ-FOR-003-RANGES
ok    TEST-REQ-FOR-003-CRC-KNOWN-VECTORS
ok    TEST-REQ-FOR-003-CRC-DIFFERENTIAL-INCREMENTAL
ok    TEST-REQ-FOR-003-INDEPENDENT-ENCODING-ORACLE
ok    TEST-REQ-LIM-001-ROUNDTRIP-VERSIONS
ok    TEST-REQ-LIM-003-KEY-BOUNDARIES
ok    TEST-REQ-LIM-001-DOCUMENT-BOUNDARIES
ok    TEST-REQ-FOR-003-EVERY-BYTE-CORRUPTION
ok    TEST-REQ-FOR-003-EVERY-TRUNCATION
ok    TEST-REQ-FOR-003-VALID-CRC-INVALID-FIELDS
ok    TEST-REQ-LIM-001-PREFLIGHT-NO-PARTIAL-WRITE
ok    TEST-REQ-AFF-002-INDEX-IDENTITY
ok    TEST-REQ-FOR-004-PREPARED-OUTCOME
ok    TEST-REQ-FOR-003-CONTROL-RECORD-SHAPES
ok    TEST-REQ-LIM-001-SEMANTIC-BOUNDARIES
ok    TEST-REQ-FOR-004-OUTCOME-PROVENANCE-FIELDS
ok    TEST-REQ-FOR-004-U64-BOTH-WORDS
ok    TEST-REQ-FOR-003-SEALED-BATCHES
ok    TEST-REQ-FOR-003-BATCH-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-003-BATCH-SEAL-SEMANTIC-CORRUPTION
ok    TEST-REQ-FOR-003-BATCH-STAMP-AND-TYPE
ok    TEST-REQ-LIM-003-BATCH-BUDGETS
ok    TEST-REQ-FOR-004-BATCH-TXID-INDEPENDENT-OF-SEAL-CSN
26 test delle fondazioni superati.
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-001-SEGMENT-HEADER-ALL-TRUNCATIONS-AND-BIT-FLIPS
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-CRC-VALID-INVALID-FIELDS
ok    TEST-REQ-AFF-002-SEGMENT-HEADER-IDENTITY
ok    TEST-REQ-FOR-002-SEGMENT-HEADER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-INDEPENDENT-ORACLE
ok    TEST-REQ-FOR-002-LOG-HEADER-DEFAULT-VERSION-IS-TWO
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-TRUNCATIONS
ok    TEST-REQ-FOR-001-LOG-HEADER-ALL-BIT-FLIPS
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-RESERVED-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-EVERY-IDENTITY-BYTE
ok    TEST-REQ-FOR-002-LOG-HEADER-CRC-VALID-WRONG-MAGIC
ok    TEST-REQ-FOR-002-LOG-HEADER-UNKNOWN-VERSION-WITH-VALID-CRC
ok    TEST-REQ-FOR-001-LOG-HEADER-CRC-BEFORE-UNKNOWN-VERSION
ok    TEST-REQ-FOR-002-LOG-HEADER-ENCODER-PREFLIGHT-PRESERVES-BUFFER
ok    TEST-REQ-FOR-002-LOG-HEADER-READER-PREFLIGHT
ok    TEST-REQ-FOR-002-COMPACTION-EMPTY-HEADERS
ok    TEST-REQ-CMP-009-COMPACTION-RESOLVED-RECORDS-AND-COUNTS
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\":
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005800453}>:
  Asserzione fallita: (EQUAL ARCDOCDB.STORAGE.TESTS::EXPECTED
                             (MULTIPLE-VALUE-LIST
                              (APPLY
                               #'ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO
                               ARCDOCDB.STORAGE.TESTS::BUFFER
                               ARCDOCDB.STORAGE.TESTS::VALID
                               ARCDOCDB.STORAGE.TESTS::SERIE
                               ARCDOCDB.STORAGE.TESTS::SEGMENT-ID
                               ARCDOCDB.STORAGE.TESTS::OPTIONS)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005800453}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8005328C73}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8005328C73}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8005328C73}>)
3: (ERROR \"Asserzione fallita: ~S\" (EQUAL ARCDOCDB.STORAGE.TESTS::EXPECTED (MULTIPLE-VALUE-LIST (APPLY (FUNCTION ARCDOCDB.STORAGE.FORMAT:VERIFICA-SEGMENTO-COMPATTATO) ARCDOCDB.STORAGE.TESTS::BUFFER ARCDOCDB.STORAGE.TESTS::VALID ARCDOCDB.STORAGE.TESTS::SERIE ARCDOCDB.STORAGE.TESTS::SEGMENT-ID ARCDOCDB.STORAGE.TESTS::OPTIONS))))
4: (ARCDOCDB.STORAGE.TESTS::COMPACTION-ASSERT-RESULT #(65 82 67 68 83 69 71 49 1 0 2 0 ...) 344 #(128 255 0 165 4 5 6 7 8 9 10 11 ...) 18364758544493064720 (344 1 1 1 0))
5: (ARCDOCDB.STORAGE.TESTS::TEST-REQ-FOR-002-COMPACTION-VERSION-FROM-FILE)
6: (ARCDOCDB.STORAGE.TESTS:RUN)
7: ((:METHOD ASDF/ACTION:PERFORM (ASDF/LISP-ACTION:TEST-OP (EQL #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">))) #<unused argument> #<unused argument>) [fast-method]
8: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">)
9: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
10: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb/tests\">) [fast-method]
11: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
12: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
13: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80052C0E83}>) [fast-method]
14: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
15: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
16: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
17: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
18: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
21: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0CEB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
22: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
23: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80052C0C1B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
24: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
25: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
26: (\"top level form\") [toplevel]
27: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
28: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL T T)
29: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052C0973}> 3 NIL)
30: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
31: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
32: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
33: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
34: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
35: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105201B6B}> #<SB-C::SOURCE-INFO {80052C0973}> SB-C::INPUT-ERROR-IN-LOAD)
36: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\" {80052C0723}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
37: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\" {80052C0723}> NIL)
38: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {10520163B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\" {80052C0723}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\" {80052C0723}>)
39: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/build.lisp\" {80052C0723}> NIL)
40: (LOAD \"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
41: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LOAD \"tools/build.lisp\") #<NULL-LEXENV>)
42: (EVAL-TLF (LOAD \"tools/build.lisp\") 2 NIL)
43: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") 2)
44: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LOAD \"tools/build.lisp\") :CURRENT-INDEX 2)
45: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105200F1B}> #<SB-C::SOURCE-INFO {80052C0423}> SB-C::INPUT-ERROR-IN-LOAD)
46: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
47: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
48: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1052009EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}>)
49: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}> NIL)
50: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
51: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/compaction-mutants/7/tools/compaction-isolated-build.lisp\" {80052C0043}>)
52: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
53: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
54: (SB-IMPL::PROCESS-SCRIPT \"tools/compaction-isolated-build.lisp\")
55: (SB-IMPL::TOPLEVEL-INIT)
56: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
57: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
58: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
"))
 :LIMITS
 (:TARGETED-MUTANTS-ONLY :IN-MEMORY-COMPACTED-SEGMENT-TESTS
  :COMPILE-FAILURE-NOT-DETECTION :NO-DURABILITY-OR-ENGINE-QUALIFICATION))
