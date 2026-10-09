(:SCHEMA-VERSION 1 :KIND :MUTATION-OUTPUT :SCOPE :WRITER-HANDOFF
 :DEDICATED-TESTS 34 :PROCESS-ARTIFACT "mutazioni-handoff.lisp"
 :ORIGINAL-DIRECTORY "spikes/out/manifest-main92-handoff/" :ORIGINAL-REPORT
 (:SCHEMA-VERSION 1 :KIND :WRITER-HANDOFF-MUTATIONS :STATUS :OK :STAGE
  :COMPLETE :RECORDED-AT 4000520346 :SBCL "2.6.9" :SOURCE-FINGERPRINTS-BEFORE
  ((:FILE "arcdocdb.asd" :MD5 "9a57dfcc33a93f0c03cb5d0fab73763a")
   (:FILE "tools/build.lisp" :MD5 "a0367c24405a56a2ffe84a9282004db0")
   (:FILE "src/codec/package.lisp" :MD5 "d885bd2a9860eb60aec1a775e5031d5e")
   (:FILE "src/codec/utf8.lisp" :MD5 "0f67dd5c51bf6a63bc292ab4e2a280c2")
   (:FILE "src/execution/handoff.lisp" :MD5 "bacb6820a020a23d11a36745fa1f3a6b")
   (:FILE "src/execution/package.lisp" :MD5 "89dbbee45c2bdc1c5ed8e6a2c9635691")
   (:FILE "src/execution/queue.lisp" :MD5 "8202843bddb817da4279ac959ae3f3c4")
   (:FILE "src/execution/writer.lisp" :MD5 "73019644090e2971f2b54dc36e4491f5")
   (:FILE "src/foundation/batch.lisp" :MD5 "ca642ea47e4bff76f78f5b6d7287d6bd")
   (:FILE "src/foundation/binary.lisp" :MD5 "a06115175f450776762761dce25acdb8")
   (:FILE "src/foundation/conditions.lisp" :MD5
    "0535060fb2eb883174e93863f61b4d0d")
   (:FILE "src/foundation/crc32c.lisp" :MD5 "4db58e2f48bf77d751f1b83bb9f84b5c")
   (:FILE "src/foundation/package.lisp" :MD5
    "b95f4808a955f174f0dc8260b8ba89e8")
   (:FILE "src/foundation/record.lisp" :MD5 "d1a05da76eb360dba2941ce32549ba51")
   (:FILE "src/io/flush.lisp" :MD5 "716866194d6b9f076e102e84187229c0")
   (:FILE "src/io/lifecycle.lisp" :MD5 "11c7103efbe733bbf0a13927f23c3d34")
   (:FILE "src/io/native.lisp" :MD5 "9500cfb800603de002d6d2b24f1bf056")
   (:FILE "src/io/package.lisp" :MD5 "c9380ad46a1d7acf41655aaed20db478")
   (:FILE "src/io/transfer.lisp" :MD5 "a5e7108e80664eb3b562fbd7e680801f")
   (:FILE "src/io/types.lisp" :MD5 "db8497f9cff35b1ee261f1f410f46ca6")
   (:FILE "src/package.lisp" :MD5 "becf5c78049c85f2c05cd1ef54454032")
   (:FILE "src/recovery/decisions-build.lisp" :MD5
    "1a51ef4a488bb9fde2ff7d47bae01379")
   (:FILE "src/recovery/decisions-package.lisp" :MD5
    "cbdc30f93109c474e1fc25066c9b9b13")
   (:FILE "src/recovery/decisions-query.lisp" :MD5
    "f782d1137b8ce342b91c9999cfb7accc")
   (:FILE "src/recovery/decisions-radix.lisp" :MD5
    "852149de4c289b8e067602780378d87a")
   (:FILE "src/recovery/decisions-sort.lisp" :MD5
    "b33e57a643f2fca810846f6226366253")
   (:FILE "src/recovery/decisions-types.lisp" :MD5
    "f4433fd19ebc7239dbc2628c39f3ecdb")
   (:FILE "src/recovery/manifest-build.lisp" :MD5
    "bf65b1731eab6e0572461ef5cc60fc40")
   (:FILE "src/recovery/manifest-decode.lisp" :MD5
    "67975249aaabd751757cdfb9222cc3c4")
   (:FILE "src/recovery/manifest-fold.lisp" :MD5
    "e0d2498db1011e857b7b0daa1934f187")
   (:FILE "src/recovery/manifest-package.lisp" :MD5
    "aa1768854b77767e4e2ddef296bfc93f")
   (:FILE "src/recovery/manifest-query.lisp" :MD5
    "ebd7a54adea2213294a887e6d4db0927")
   (:FILE "src/recovery/manifest-types.lisp" :MD5
    "7b1d4054415faca7e5fca59ad83b4d4a")
   (:FILE "src/recovery/package.lisp" :MD5 "1c1c8ad0cd15b1703a2fe19cbf3f13c2")
   (:FILE "src/recovery/scan.lisp" :MD5 "fcacd15460db25ea9cc4036065f9f096")
   (:FILE "src/storage/compaction-scan.lisp" :MD5
    "1cda77a357ab2147035993b72d135a37")
   (:FILE "src/storage/control-payload.lisp" :MD5
    "cb64f806b8d69eb42d865b4abfff0b27")
   (:FILE "src/storage/formats.lisp" :MD5 "061147be459d8d3b08c661bd3f91d152")
   (:FILE "src/storage/log-header.lisp" :MD5
    "b53d27dcc9f4badf18b50519c50bc614")
   (:FILE "src/storage/package.lisp" :MD5 "f86bd104f20616a76b42c02227f72844")
   (:FILE "src/storage/payload-record.lisp" :MD5
    "8c03f9c01dcb30f2d3970a5694968ecf")
   (:FILE "src/storage/payload-write.lisp" :MD5
    "c4ece3c4fa8d9492d2a80df7c0a4f5a0")
   (:FILE "src/storage/segment-header.lisp" :MD5
    "d6812fa59bf8fd1252fbf85a9bfa3896")
   (:FILE "src/wal/builder.lisp" :MD5 "304194318389c07a28cbb4477121eb4f")
   (:FILE "src/wal/executor.lisp" :MD5 "afc8179a1c6b87d8f6cb79c7a92cb57a")
   (:FILE "src/wal/group.lisp" :MD5 "2fa3e6255117d6194473557b5e5cc633")
   (:FILE "src/wal/package.lisp" :MD5 "f37f17f017b3c54e08ae499e37becf7e")
   (:FILE "src/wal/types.lisp" :MD5 "b7be1fd52803a3cf9eb88436d381c5e5")
   (:FILE "tests/codec/support.lisp" :MD5 "32534fd42dd8124b50b45deefe143eaf")
   (:FILE "tests/codec/threads.lisp" :MD5 "a71504598cda8e99cd50e229ddd5275b")
   (:FILE "tests/codec/utf8.lisp" :MD5 "767ead15603be8dce90f340dbb200d8f")
   (:FILE "tests/execution/handoff.lisp" :MD5
    "f87fdc0f7bd194329c6349026a2f35bb")
   (:FILE "tests/execution/queue.lisp" :MD5 "940ebb450bc871f8c2dd7dc9977bb158")
   (:FILE "tests/execution/support.lisp" :MD5
    "bacb1a135c0d73cded57ba21986c8496")
   (:FILE "tests/execution/threads.lisp" :MD5
    "32b6a6578f526b7d4bcc3a1665a8c6e6")
   (:FILE "tests/foundation/batch.lisp" :MD5
    "29fc6a9711ea9265840e8cde4971f74e")
   (:FILE "tests/foundation/binary.lisp" :MD5
    "07c4c9ac2177f22e5b7fb25f9867a133")
   (:FILE "tests/foundation/record.lisp" :MD5
    "1300a75bcab1801ad064c401cd81123f")
   (:FILE "tests/foundation/support.lisp" :MD5
    "758adad069aec2f9dbe0635797314ff6")
   (:FILE "tests/io/native.lisp" :MD5 "1e6fd9ab36eb4e307207d371ed947757")
   (:FILE "tests/io/support.lisp" :MD5 "a26526e87fe46794b8bbab1fdd46d68c")
   (:FILE "tests/io/transfer.lisp" :MD5 "ab2fb36682dd8b8bc757e586ceb3be62")
   (:FILE "tests/lint-fixtures/bad.lisp" :MD5
    "30f1396c941dd9b8a41ca15698b5a347")
   (:FILE "tests/lint-fixtures/good.lisp" :MD5
    "f85250c3a057c851db6745b9eba27da1")
   (:FILE "tests/recovery/corruption.lisp" :MD5
    "a369b8176d4e877ab546d17e983b94ed")
   (:FILE "tests/recovery/decisions-audit.lisp" :MD5
    "33b98cf215d1ddb469d02cc6c0032bfe")
   (:FILE "tests/recovery/decisions-radix.lisp" :MD5
    "58eec0feac01e643c76ad19ef5c07df5")
   (:FILE "tests/recovery/decisions-support.lisp" :MD5
    "80348d0ce2adbc8a4d37db49df291b1d")
   (:FILE "tests/recovery/decisions.lisp" :MD5
    "5add0e087181bad8ce330af23fc26686")
   (:FILE "tests/recovery/manifest-audit.lisp" :MD5
    "3ca73a199708e2571da3a27e6dc00c76")
   (:FILE "tests/recovery/manifest-support.lisp" :MD5
    "3286e0dfb66496aafe8b6fbbdd92ab43")
   (:FILE "tests/recovery/manifest.lisp" :MD5
    "b6bdcc4d20f7db14c0dc00d5258cbf8c")
   (:FILE "tests/recovery/scan.lisp" :MD5 "aa7af12d270673b62542d32ec60b361a")
   (:FILE "tests/recovery/support.lisp" :MD5
    "769bac1994a5e3d74bd56b510970bf9b")
   (:FILE "tests/smoke.lisp" :MD5 "afb2e2bc7ff7249ebb2e1ccf0f87aaf3")
   (:FILE "tests/storage/compaction-scan.lisp" :MD5
    "cb4acb5a73eb973f53ef337113880d32")
   (:FILE "tests/storage/control-payload.lisp" :MD5
    "25f3c822273c898d2263ceb3db538cab")
   (:FILE "tests/storage/log-header.lisp" :MD5
    "eecb2fe94e710a918254e5ad453a0daa")
   (:FILE "tests/storage/segment-header.lisp" :MD5
    "ab2c52fb6b79702d50dcef6d12ca8906")
   (:FILE "tests/storage/support.lisp" :MD5 "82a4dbb4767c17f9851143a637af3b83")
   (:FILE "tests/wal/builder.lisp" :MD5 "0d01e4e18c0a559873fce584a0ac91cd")
   (:FILE "tests/wal/fault.lisp" :MD5 "00367366b82918614d84f517f4bb395e")
   (:FILE "tests/wal/group.lisp" :MD5 "0ee2462103a749b58488561aeacaac07")
   (:FILE "tests/wal/native.lisp" :MD5 "0643b96c5ee339f9826b19150d065ddf")
   (:FILE "tests/wal/support.lisp" :MD5 "15952f6b761acea4519abf701bb2346c")
   (:FILE "tools/writer-handoff-mutation.lisp" :MD5
    "8e85b90362b70e72986ea74083fbb1f1")
   (:FILE "tools/writer-queue-mutation.lisp" :MD5
    "367c71c799e673d9c7e264508d503833"))
  :SOURCE-FINGERPRINTS-AFTER
  ((:FILE "arcdocdb.asd" :MD5 "9a57dfcc33a93f0c03cb5d0fab73763a")
   (:FILE "tools/build.lisp" :MD5 "a0367c24405a56a2ffe84a9282004db0")
   (:FILE "src/codec/package.lisp" :MD5 "d885bd2a9860eb60aec1a775e5031d5e")
   (:FILE "src/codec/utf8.lisp" :MD5 "0f67dd5c51bf6a63bc292ab4e2a280c2")
   (:FILE "src/execution/handoff.lisp" :MD5 "bacb6820a020a23d11a36745fa1f3a6b")
   (:FILE "src/execution/package.lisp" :MD5 "89dbbee45c2bdc1c5ed8e6a2c9635691")
   (:FILE "src/execution/queue.lisp" :MD5 "8202843bddb817da4279ac959ae3f3c4")
   (:FILE "src/execution/writer.lisp" :MD5 "73019644090e2971f2b54dc36e4491f5")
   (:FILE "src/foundation/batch.lisp" :MD5 "ca642ea47e4bff76f78f5b6d7287d6bd")
   (:FILE "src/foundation/binary.lisp" :MD5 "a06115175f450776762761dce25acdb8")
   (:FILE "src/foundation/conditions.lisp" :MD5
    "0535060fb2eb883174e93863f61b4d0d")
   (:FILE "src/foundation/crc32c.lisp" :MD5 "4db58e2f48bf77d751f1b83bb9f84b5c")
   (:FILE "src/foundation/package.lisp" :MD5
    "b95f4808a955f174f0dc8260b8ba89e8")
   (:FILE "src/foundation/record.lisp" :MD5 "d1a05da76eb360dba2941ce32549ba51")
   (:FILE "src/io/flush.lisp" :MD5 "716866194d6b9f076e102e84187229c0")
   (:FILE "src/io/lifecycle.lisp" :MD5 "11c7103efbe733bbf0a13927f23c3d34")
   (:FILE "src/io/native.lisp" :MD5 "9500cfb800603de002d6d2b24f1bf056")
   (:FILE "src/io/package.lisp" :MD5 "c9380ad46a1d7acf41655aaed20db478")
   (:FILE "src/io/transfer.lisp" :MD5 "a5e7108e80664eb3b562fbd7e680801f")
   (:FILE "src/io/types.lisp" :MD5 "db8497f9cff35b1ee261f1f410f46ca6")
   (:FILE "src/package.lisp" :MD5 "becf5c78049c85f2c05cd1ef54454032")
   (:FILE "src/recovery/decisions-build.lisp" :MD5
    "1a51ef4a488bb9fde2ff7d47bae01379")
   (:FILE "src/recovery/decisions-package.lisp" :MD5
    "cbdc30f93109c474e1fc25066c9b9b13")
   (:FILE "src/recovery/decisions-query.lisp" :MD5
    "f782d1137b8ce342b91c9999cfb7accc")
   (:FILE "src/recovery/decisions-radix.lisp" :MD5
    "852149de4c289b8e067602780378d87a")
   (:FILE "src/recovery/decisions-sort.lisp" :MD5
    "b33e57a643f2fca810846f6226366253")
   (:FILE "src/recovery/decisions-types.lisp" :MD5
    "f4433fd19ebc7239dbc2628c39f3ecdb")
   (:FILE "src/recovery/manifest-build.lisp" :MD5
    "bf65b1731eab6e0572461ef5cc60fc40")
   (:FILE "src/recovery/manifest-decode.lisp" :MD5
    "67975249aaabd751757cdfb9222cc3c4")
   (:FILE "src/recovery/manifest-fold.lisp" :MD5
    "e0d2498db1011e857b7b0daa1934f187")
   (:FILE "src/recovery/manifest-package.lisp" :MD5
    "aa1768854b77767e4e2ddef296bfc93f")
   (:FILE "src/recovery/manifest-query.lisp" :MD5
    "ebd7a54adea2213294a887e6d4db0927")
   (:FILE "src/recovery/manifest-types.lisp" :MD5
    "7b1d4054415faca7e5fca59ad83b4d4a")
   (:FILE "src/recovery/package.lisp" :MD5 "1c1c8ad0cd15b1703a2fe19cbf3f13c2")
   (:FILE "src/recovery/scan.lisp" :MD5 "fcacd15460db25ea9cc4036065f9f096")
   (:FILE "src/storage/compaction-scan.lisp" :MD5
    "1cda77a357ab2147035993b72d135a37")
   (:FILE "src/storage/control-payload.lisp" :MD5
    "cb64f806b8d69eb42d865b4abfff0b27")
   (:FILE "src/storage/formats.lisp" :MD5 "061147be459d8d3b08c661bd3f91d152")
   (:FILE "src/storage/log-header.lisp" :MD5
    "b53d27dcc9f4badf18b50519c50bc614")
   (:FILE "src/storage/package.lisp" :MD5 "f86bd104f20616a76b42c02227f72844")
   (:FILE "src/storage/payload-record.lisp" :MD5
    "8c03f9c01dcb30f2d3970a5694968ecf")
   (:FILE "src/storage/payload-write.lisp" :MD5
    "c4ece3c4fa8d9492d2a80df7c0a4f5a0")
   (:FILE "src/storage/segment-header.lisp" :MD5
    "d6812fa59bf8fd1252fbf85a9bfa3896")
   (:FILE "src/wal/builder.lisp" :MD5 "304194318389c07a28cbb4477121eb4f")
   (:FILE "src/wal/executor.lisp" :MD5 "afc8179a1c6b87d8f6cb79c7a92cb57a")
   (:FILE "src/wal/group.lisp" :MD5 "2fa3e6255117d6194473557b5e5cc633")
   (:FILE "src/wal/package.lisp" :MD5 "f37f17f017b3c54e08ae499e37becf7e")
   (:FILE "src/wal/types.lisp" :MD5 "b7be1fd52803a3cf9eb88436d381c5e5")
   (:FILE "tests/codec/support.lisp" :MD5 "32534fd42dd8124b50b45deefe143eaf")
   (:FILE "tests/codec/threads.lisp" :MD5 "a71504598cda8e99cd50e229ddd5275b")
   (:FILE "tests/codec/utf8.lisp" :MD5 "767ead15603be8dce90f340dbb200d8f")
   (:FILE "tests/execution/handoff.lisp" :MD5
    "f87fdc0f7bd194329c6349026a2f35bb")
   (:FILE "tests/execution/queue.lisp" :MD5 "940ebb450bc871f8c2dd7dc9977bb158")
   (:FILE "tests/execution/support.lisp" :MD5
    "bacb1a135c0d73cded57ba21986c8496")
   (:FILE "tests/execution/threads.lisp" :MD5
    "32b6a6578f526b7d4bcc3a1665a8c6e6")
   (:FILE "tests/foundation/batch.lisp" :MD5
    "29fc6a9711ea9265840e8cde4971f74e")
   (:FILE "tests/foundation/binary.lisp" :MD5
    "07c4c9ac2177f22e5b7fb25f9867a133")
   (:FILE "tests/foundation/record.lisp" :MD5
    "1300a75bcab1801ad064c401cd81123f")
   (:FILE "tests/foundation/support.lisp" :MD5
    "758adad069aec2f9dbe0635797314ff6")
   (:FILE "tests/io/native.lisp" :MD5 "1e6fd9ab36eb4e307207d371ed947757")
   (:FILE "tests/io/support.lisp" :MD5 "a26526e87fe46794b8bbab1fdd46d68c")
   (:FILE "tests/io/transfer.lisp" :MD5 "ab2fb36682dd8b8bc757e586ceb3be62")
   (:FILE "tests/lint-fixtures/bad.lisp" :MD5
    "30f1396c941dd9b8a41ca15698b5a347")
   (:FILE "tests/lint-fixtures/good.lisp" :MD5
    "f85250c3a057c851db6745b9eba27da1")
   (:FILE "tests/recovery/corruption.lisp" :MD5
    "a369b8176d4e877ab546d17e983b94ed")
   (:FILE "tests/recovery/decisions-audit.lisp" :MD5
    "33b98cf215d1ddb469d02cc6c0032bfe")
   (:FILE "tests/recovery/decisions-radix.lisp" :MD5
    "58eec0feac01e643c76ad19ef5c07df5")
   (:FILE "tests/recovery/decisions-support.lisp" :MD5
    "80348d0ce2adbc8a4d37db49df291b1d")
   (:FILE "tests/recovery/decisions.lisp" :MD5
    "5add0e087181bad8ce330af23fc26686")
   (:FILE "tests/recovery/manifest-audit.lisp" :MD5
    "3ca73a199708e2571da3a27e6dc00c76")
   (:FILE "tests/recovery/manifest-support.lisp" :MD5
    "3286e0dfb66496aafe8b6fbbdd92ab43")
   (:FILE "tests/recovery/manifest.lisp" :MD5
    "b6bdcc4d20f7db14c0dc00d5258cbf8c")
   (:FILE "tests/recovery/scan.lisp" :MD5 "aa7af12d270673b62542d32ec60b361a")
   (:FILE "tests/recovery/support.lisp" :MD5
    "769bac1994a5e3d74bd56b510970bf9b")
   (:FILE "tests/smoke.lisp" :MD5 "afb2e2bc7ff7249ebb2e1ccf0f87aaf3")
   (:FILE "tests/storage/compaction-scan.lisp" :MD5
    "cb4acb5a73eb973f53ef337113880d32")
   (:FILE "tests/storage/control-payload.lisp" :MD5
    "25f3c822273c898d2263ceb3db538cab")
   (:FILE "tests/storage/log-header.lisp" :MD5
    "eecb2fe94e710a918254e5ad453a0daa")
   (:FILE "tests/storage/segment-header.lisp" :MD5
    "ab2c52fb6b79702d50dcef6d12ca8906")
   (:FILE "tests/storage/support.lisp" :MD5 "82a4dbb4767c17f9851143a637af3b83")
   (:FILE "tests/wal/builder.lisp" :MD5 "0d01e4e18c0a559873fce584a0ac91cd")
   (:FILE "tests/wal/fault.lisp" :MD5 "00367366b82918614d84f517f4bb395e")
   (:FILE "tests/wal/group.lisp" :MD5 "0ee2462103a749b58488561aeacaac07")
   (:FILE "tests/wal/native.lisp" :MD5 "0643b96c5ee339f9826b19150d065ddf")
   (:FILE "tests/wal/support.lisp" :MD5 "15952f6b761acea4519abf701bb2346c")
   (:FILE "tools/writer-handoff-mutation.lisp" :MD5
    "8e85b90362b70e72986ea74083fbb1f1")
   (:FILE "tools/writer-queue-mutation.lisp" :MD5
    "367c71c799e673d9c7e264508d503833"))
  :SOURCE-CONSISTENCY :STABLE :TARGETS
  (("handoff-idle-stays-idle" "src/execution/handoff.lisp"
    (("(when schedule (setf (writer-programmabile-state writer) :ready))"
      "(when schedule (setf (writer-programmabile-state writer) :idle))")))
   ("handoff-duplicate-schedule" "src/execution/handoff.lisp"
    (("(values count (if schedule :schedule :queued))"
      "(values count (if schedule :schedule :schedule))")))
   ("handoff-running-enqueue-ready" "src/execution/handoff.lisp"
    (("(when schedule (setf (writer-programmabile-state writer) :ready))"
      "(when (or schedule (eq (writer-programmabile-state writer) :running))
               (setf (writer-programmabile-state writer) :ready))")))
   ("handoff-start-idle" "src/execution/handoff.lisp"
    (("(unless (eq (writer-programmabile-state writer) :ready)"
      "(when (eq (writer-programmabile-state writer) :running)")))
   ("handoff-start-stays-ready" "src/execution/handoff.lisp"
    (("(setf (writer-programmabile-state writer) :running)"
      "(setf (writer-programmabile-state writer) :ready)")))
   ("handoff-backlog-goes-idle" "src/execution/handoff.lisp"
    (("(if pending :ready :idle)" "(if pending :idle :idle)")))
   ("handoff-backlog-loses-schedule" "src/execution/handoff.lisp"
    (("(if pending :schedule :idle)" "(if pending :idle :idle)")))
   ("handoff-empty-goes-ready" "src/execution/handoff.lisp"
    (("(if pending :ready :idle)" "(if pending :ready :ready)")))
   ("writer-fifo-head" "src/execution/writer.lisp"
    (("(cursor (coda-writer-head queue))"
      "(cursor (coda-writer-tail queue))")))
   ("writer-tail-wrap" "src/execution/queue.lisp"
    (("(coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))"
      "(coda-writer-tail queue) (mod (+ tail 2) (coda-writer-capacity queue))")))
   ("writer-full-boundary" "src/execution/queue.lisp"
    (("(= (coda-writer-count queue) (coda-writer-capacity queue))"
      "(> (coda-writer-count queue) (coda-writer-capacity queue))")))
   ("writer-guard-busy" "src/execution/queue.lisp"
    (("(unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))"
      "(sb-ext:compare-and-swap (coda-writer-guard queue) nil thread)")))
   ("writer-thread-owner" "src/execution/writer.lisp"
    (("(eq (coda-writer-owner queue) sb-thread:*current-thread*)"
      "(coda-writer-owner queue)")))
   ("writer-generation-lease" "src/execution/writer.lisp"
    (("(= lease (coda-writer-generation queue))"
      "(<= lease (coda-writer-generation queue))")))
   ("writer-cumulative-quantum" "src/execution/writer.lisp"
    (("(let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))"
      "(let ((remaining (progn (setf (coda-writer-extracted queue) 0)
                            (- (coda-writer-quantum queue) (coda-writer-extracted queue)))))")))
   ("writer-target-span" "src/execution/writer.lisp"
    (("(taken (min count (- limit first) remaining))"
      "(taken (min count (max (- limit first) (- (length destination) first)) remaining))"))))
  :PLANNED-MUTANTS 16 :BASELINE :PASSED :BASELINE-RESULT :SURVIVED
  :BASELINE-EXIT-CODE 0 :BASELINE-SIGNAL NIL :BASELINE-LOG
  "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/baseline/test.log"
  :MUTANTS
  ((:NAME "handoff-idle-stays-idle" :SOURCE-FILE "src/execution/handoff.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/test.log")
   (:NAME "handoff-duplicate-schedule" :SOURCE-FILE
    "src/execution/handoff.lisp" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/test.log")
   (:NAME "handoff-running-enqueue-ready" :SOURCE-FILE
    "src/execution/handoff.lisp" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/test.log")
   (:NAME "handoff-start-idle" :SOURCE-FILE "src/execution/handoff.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/test.log")
   (:NAME "handoff-start-stays-ready" :SOURCE-FILE "src/execution/handoff.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/test.log")
   (:NAME "handoff-backlog-goes-idle" :SOURCE-FILE "src/execution/handoff.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/test.log")
   (:NAME "handoff-backlog-loses-schedule" :SOURCE-FILE
    "src/execution/handoff.lisp" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL
    :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/test.log")
   (:NAME "handoff-empty-goes-ready" :SOURCE-FILE "src/execution/handoff.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/test.log")
   (:NAME "writer-fifo-head" :SOURCE-FILE "src/execution/writer.lisp" :RESULT
    :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/test.log")
   (:NAME "writer-tail-wrap" :SOURCE-FILE "src/execution/queue.lisp" :RESULT
    :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/test.log")
   (:NAME "writer-full-boundary" :SOURCE-FILE "src/execution/queue.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/test.log")
   (:NAME "writer-guard-busy" :SOURCE-FILE "src/execution/queue.lisp" :RESULT
    :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/test.log")
   (:NAME "writer-thread-owner" :SOURCE-FILE "src/execution/writer.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/test.log")
   (:NAME "writer-generation-lease" :SOURCE-FILE "src/execution/writer.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/test.log")
   (:NAME "writer-cumulative-quantum" :SOURCE-FILE "src/execution/writer.lisp"
    :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/test.log")
   (:NAME "writer-target-span" :SOURCE-FILE "src/execution/writer.lisp" :RESULT
    :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/test.log"))
  :CURRENT-ORDINAL NIL :CURRENT-MUTANT NIL :CURRENT-LOG NIL :DIAGNOSTIC NIL
  :DETECTED 16 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0
  :WORKER-ERRORS 0 :LIMITS
  (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE :STRICT-COMPILATION
   :TEST-EVENTS-AT-LINE-START :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
   :NO-POOL-READY-LIST-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))
 :RAW-FILES
 ((:PATH "report.lisp" :BYTE-COUNT 26262 :GIT-BLOB
   "c46de81417ab7d7e963c0e2cb78b1209388ba642" :CONTENT
   "(:SCHEMA-VERSION 1 :KIND :WRITER-HANDOFF-MUTATIONS :STATUS :OK :STAGE :COMPLETE
 :RECORDED-AT 4000520346 :SBCL #A((5) BASE-CHAR . \"2.6.9\")
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"9a57dfcc33a93f0c03cb5d0fab73763a\"))
  (:FILE \"tools/build.lisp\" :MD5
   #A((32) BASE-CHAR . \"a0367c24405a56a2ffe84a9282004db0\"))
  (:FILE \"src/codec/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"d885bd2a9860eb60aec1a775e5031d5e\"))
  (:FILE \"src/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"0f67dd5c51bf6a63bc292ab4e2a280c2\"))
  (:FILE \"src/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb6820a020a23d11a36745fa1f3a6b\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"89dbbee45c2bdc1c5ed8e6a2c9635691\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8202843bddb817da4279ac959ae3f3c4\"))
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
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\"))
  (:FILE \"tests/codec/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"32534fd42dd8124b50b45deefe143eaf\"))
  (:FILE \"tests/codec/threads.lisp\" :MD5
   #A((32) BASE-CHAR . \"a71504598cda8e99cd50e229ddd5275b\"))
  (:FILE \"tests/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"767ead15603be8dce90f340dbb200d8f\"))
  (:FILE \"tests/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"f87fdc0f7bd194329c6349026a2f35bb\"))
  (:FILE \"tests/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"940ebb450bc871f8c2dd7dc9977bb158\"))
  (:FILE \"tests/execution/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb1a135c0d73cded57ba21986c8496\"))
  (:FILE \"tests/execution/threads.lisp\" :MD5
   #A((32) BASE-CHAR . \"32b6a6578f526b7d4bcc3a1665a8c6e6\"))
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
  (:FILE \"tests/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"58eec0feac01e643c76ad19ef5c07df5\"))
  (:FILE \"tests/recovery/decisions-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"80348d0ce2adbc8a4d37db49df291b1d\"))
  (:FILE \"tests/recovery/decisions.lisp\" :MD5
   #A((32) BASE-CHAR . \"5add0e087181bad8ce330af23fc26686\"))
  (:FILE \"tests/recovery/manifest-audit.lisp\" :MD5
   #A((32) BASE-CHAR . \"3ca73a199708e2571da3a27e6dc00c76\"))
  (:FILE \"tests/recovery/manifest-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"3286e0dfb66496aafe8b6fbbdd92ab43\"))
  (:FILE \"tests/recovery/manifest.lisp\" :MD5
   #A((32) BASE-CHAR . \"b6bdcc4d20f7db14c0dc00d5258cbf8c\"))
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
  (:FILE \"tools/writer-handoff-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"8e85b90362b70e72986ea74083fbb1f1\"))
  (:FILE \"tools/writer-queue-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"367c71c799e673d9c7e264508d503833\")))
 :SOURCE-FINGERPRINTS-AFTER
 ((:FILE \"arcdocdb.asd\" :MD5
   #A((32) BASE-CHAR . \"9a57dfcc33a93f0c03cb5d0fab73763a\"))
  (:FILE \"tools/build.lisp\" :MD5
   #A((32) BASE-CHAR . \"a0367c24405a56a2ffe84a9282004db0\"))
  (:FILE \"src/codec/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"d885bd2a9860eb60aec1a775e5031d5e\"))
  (:FILE \"src/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"0f67dd5c51bf6a63bc292ab4e2a280c2\"))
  (:FILE \"src/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb6820a020a23d11a36745fa1f3a6b\"))
  (:FILE \"src/execution/package.lisp\" :MD5
   #A((32) BASE-CHAR . \"89dbbee45c2bdc1c5ed8e6a2c9635691\"))
  (:FILE \"src/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"8202843bddb817da4279ac959ae3f3c4\"))
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
   #A((32) BASE-CHAR . \"b7be1fd52803a3cf9eb88436d381c5e5\"))
  (:FILE \"tests/codec/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"32534fd42dd8124b50b45deefe143eaf\"))
  (:FILE \"tests/codec/threads.lisp\" :MD5
   #A((32) BASE-CHAR . \"a71504598cda8e99cd50e229ddd5275b\"))
  (:FILE \"tests/codec/utf8.lisp\" :MD5
   #A((32) BASE-CHAR . \"767ead15603be8dce90f340dbb200d8f\"))
  (:FILE \"tests/execution/handoff.lisp\" :MD5
   #A((32) BASE-CHAR . \"f87fdc0f7bd194329c6349026a2f35bb\"))
  (:FILE \"tests/execution/queue.lisp\" :MD5
   #A((32) BASE-CHAR . \"940ebb450bc871f8c2dd7dc9977bb158\"))
  (:FILE \"tests/execution/support.lisp\" :MD5
   #A((32) BASE-CHAR . \"bacb1a135c0d73cded57ba21986c8496\"))
  (:FILE \"tests/execution/threads.lisp\" :MD5
   #A((32) BASE-CHAR . \"32b6a6578f526b7d4bcc3a1665a8c6e6\"))
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
  (:FILE \"tests/recovery/decisions-radix.lisp\" :MD5
   #A((32) BASE-CHAR . \"58eec0feac01e643c76ad19ef5c07df5\"))
  (:FILE \"tests/recovery/decisions-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"80348d0ce2adbc8a4d37db49df291b1d\"))
  (:FILE \"tests/recovery/decisions.lisp\" :MD5
   #A((32) BASE-CHAR . \"5add0e087181bad8ce330af23fc26686\"))
  (:FILE \"tests/recovery/manifest-audit.lisp\" :MD5
   #A((32) BASE-CHAR . \"3ca73a199708e2571da3a27e6dc00c76\"))
  (:FILE \"tests/recovery/manifest-support.lisp\" :MD5
   #A((32) BASE-CHAR . \"3286e0dfb66496aafe8b6fbbdd92ab43\"))
  (:FILE \"tests/recovery/manifest.lisp\" :MD5
   #A((32) BASE-CHAR . \"b6bdcc4d20f7db14c0dc00d5258cbf8c\"))
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
  (:FILE \"tools/writer-handoff-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"8e85b90362b70e72986ea74083fbb1f1\"))
  (:FILE \"tools/writer-queue-mutation.lisp\" :MD5
   #A((32) BASE-CHAR . \"367c71c799e673d9c7e264508d503833\")))
 :SOURCE-CONSISTENCY :STABLE :TARGETS
 ((\"handoff-idle-stays-idle\" \"src/execution/handoff.lisp\"
   ((\"(when schedule (setf (writer-programmabile-state writer) :ready))\"
     \"(when schedule (setf (writer-programmabile-state writer) :idle))\")))
  (\"handoff-duplicate-schedule\" \"src/execution/handoff.lisp\"
   ((\"(values count (if schedule :schedule :queued))\"
     \"(values count (if schedule :schedule :schedule))\")))
  (\"handoff-running-enqueue-ready\" \"src/execution/handoff.lisp\"
   ((\"(when schedule (setf (writer-programmabile-state writer) :ready))\"
     \"(when (or schedule (eq (writer-programmabile-state writer) :running))
               (setf (writer-programmabile-state writer) :ready))\")))
  (\"handoff-start-idle\" \"src/execution/handoff.lisp\"
   ((\"(unless (eq (writer-programmabile-state writer) :ready)\"
     \"(when (eq (writer-programmabile-state writer) :running)\")))
  (\"handoff-start-stays-ready\" \"src/execution/handoff.lisp\"
   ((\"(setf (writer-programmabile-state writer) :running)\"
     \"(setf (writer-programmabile-state writer) :ready)\")))
  (\"handoff-backlog-goes-idle\" \"src/execution/handoff.lisp\"
   ((\"(if pending :ready :idle)\" \"(if pending :idle :idle)\")))
  (\"handoff-backlog-loses-schedule\" \"src/execution/handoff.lisp\"
   ((\"(if pending :schedule :idle)\" \"(if pending :idle :idle)\")))
  (\"handoff-empty-goes-ready\" \"src/execution/handoff.lisp\"
   ((\"(if pending :ready :idle)\" \"(if pending :ready :ready)\")))
  (\"writer-fifo-head\" \"src/execution/writer.lisp\"
   ((\"(cursor (coda-writer-head queue))\" \"(cursor (coda-writer-tail queue))\")))
  (\"writer-tail-wrap\" \"src/execution/queue.lisp\"
   ((\"(coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))\"
     \"(coda-writer-tail queue) (mod (+ tail 2) (coda-writer-capacity queue))\")))
  (\"writer-full-boundary\" \"src/execution/queue.lisp\"
   ((\"(= (coda-writer-count queue) (coda-writer-capacity queue))\"
     \"(> (coda-writer-count queue) (coda-writer-capacity queue))\")))
  (\"writer-guard-busy\" \"src/execution/queue.lisp\"
   ((\"(unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))\"
     \"(sb-ext:compare-and-swap (coda-writer-guard queue) nil thread)\")))
  (\"writer-thread-owner\" \"src/execution/writer.lisp\"
   ((\"(eq (coda-writer-owner queue) sb-thread:*current-thread*)\"
     \"(coda-writer-owner queue)\")))
  (\"writer-generation-lease\" \"src/execution/writer.lisp\"
   ((\"(= lease (coda-writer-generation queue))\"
     \"(<= lease (coda-writer-generation queue))\")))
  (\"writer-cumulative-quantum\" \"src/execution/writer.lisp\"
   ((\"(let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))\"
     \"(let ((remaining (progn (setf (coda-writer-extracted queue) 0)
                            (- (coda-writer-quantum queue) (coda-writer-extracted queue)))))\")))
  (\"writer-target-span\" \"src/execution/writer.lisp\"
   ((\"(taken (min count (- limit first) remaining))\"
     \"(taken (min count (max (- limit first) (- (length destination) first)) remaining))\"))))
 :PLANNED-MUTANTS 16 :BASELINE :PASSED :BASELINE-RESULT :SURVIVED
 :BASELINE-EXIT-CODE 0 :BASELINE-SIGNAL NIL :BASELINE-LOG
 #A((117) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/baseline/test.log\")
 :MUTANTS
 ((:NAME \"handoff-idle-stays-idle\" :SOURCE-FILE \"src/execution/handoff.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/test.log\"))
  (:NAME \"handoff-duplicate-schedule\" :SOURCE-FILE \"src/execution/handoff.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/test.log\"))
  (:NAME \"handoff-running-enqueue-ready\" :SOURCE-FILE
   \"src/execution/handoff.lisp\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/test.log\"))
  (:NAME \"handoff-start-idle\" :SOURCE-FILE \"src/execution/handoff.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/test.log\"))
  (:NAME \"handoff-start-stays-ready\" :SOURCE-FILE \"src/execution/handoff.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/test.log\"))
  (:NAME \"handoff-backlog-goes-idle\" :SOURCE-FILE \"src/execution/handoff.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/test.log\"))
  (:NAME \"handoff-backlog-loses-schedule\" :SOURCE-FILE
   \"src/execution/handoff.lisp\" :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/test.log\"))
  (:NAME \"handoff-empty-goes-ready\" :SOURCE-FILE \"src/execution/handoff.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/test.log\"))
  (:NAME \"writer-fifo-head\" :SOURCE-FILE \"src/execution/writer.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/test.log\"))
  (:NAME \"writer-tail-wrap\" :SOURCE-FILE \"src/execution/queue.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/test.log\"))
  (:NAME \"writer-full-boundary\" :SOURCE-FILE \"src/execution/queue.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/test.log\"))
  (:NAME \"writer-guard-busy\" :SOURCE-FILE \"src/execution/queue.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/test.log\"))
  (:NAME \"writer-thread-owner\" :SOURCE-FILE \"src/execution/writer.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/test.log\"))
  (:NAME \"writer-generation-lease\" :SOURCE-FILE \"src/execution/writer.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/test.log\"))
  (:NAME \"writer-cumulative-quantum\" :SOURCE-FILE \"src/execution/writer.lisp\"
   :RESULT :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/test.log\"))
  (:NAME \"writer-target-span\" :SOURCE-FILE \"src/execution/writer.lisp\" :RESULT
   :DETECTED :EXIT-CODE 1 :SIGNAL NIL :LOG
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/test.log\")))
 :CURRENT-ORDINAL NIL :CURRENT-MUTANT NIL :CURRENT-LOG NIL :DIAGNOSTIC NIL
 :DETECTED 16 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0
 :WORKER-ERRORS 0 :LIMITS
 (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE :STRICT-COMPILATION
  :TEST-EVENTS-AT-LINE-START :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
  :NO-POOL-READY-LIST-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))
")
  (:PATH "baseline/test.log" :BYTE-COUNT 5199 :GIT-BLOB
   "80edf482fe40df3b1f0bae818f6324a5f01f99a5" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 34010 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
ok    TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
execution-test-start TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN
ok    TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN
execution-test-start TEST-REQ-CON-005-HANDOFF-ENQUEUE-BEFORE-AND-AFTER-EMPTY-RELEASE
ok    TEST-REQ-CON-005-HANDOFF-ENQUEUE-BEFORE-AND-AFTER-EMPTY-RELEASE
execution-test-start TEST-REQ-CON-004-HANDOFF-CUMULATIVE-QUANTUM-AND-SUCCESSIVE-SLICES
ok    TEST-REQ-CON-004-HANDOFF-CUMULATIVE-QUANTUM-AND-SUCCESSIVE-SLICES
execution-test-start TEST-REQ-AFF-008-HANDOFF-FULL-READY-AND-RUNNING-RETAIN-STATE
ok    TEST-REQ-AFF-008-HANDOFF-FULL-READY-AND-RUNNING-RETAIN-STATE
execution-test-start TEST-REQ-CON-004-HANDOFF-BUSY-IDLE-AND-READY-PRESERVE-STATE
ok    TEST-REQ-CON-004-HANDOFF-BUSY-IDLE-AND-READY-PRESERVE-STATE
execution-test-start TEST-REQ-CON-005-HANDOFF-BUSY-RELEASE-RETAINS-LEASE-FOR-RETRY
ok    TEST-REQ-CON-005-HANDOFF-BUSY-RELEASE-RETAINS-LEASE-FOR-RETRY
execution-test-start TEST-REQ-CON-005-HANDOFF-EARLY-RELEASE-CONSERVES-ENTIRE-BACKLOG
ok    TEST-REQ-CON-005-HANDOFF-EARLY-RELEASE-CONSERVES-ENTIRE-BACKLOG
execution-test-start TEST-REQ-AFF-004-HANDOFF-LEASE-VALIDATION-AND-STALE-GENERATION
ok    TEST-REQ-AFF-004-HANDOFF-LEASE-VALIDATION-AND-STALE-GENERATION
execution-test-start TEST-REQ-AFF-004-HANDOFF-TARGET-PREFLIGHT-AND-PRIVATE-ALIAS
ok    TEST-REQ-AFF-004-HANDOFF-TARGET-PREFLIGHT-AND-PRIVATE-ALIAS
execution-test-start TEST-REQ-AFF-008-HANDOFF-GENERATION-EXHAUSTION-PRESERVES-READY
ok    TEST-REQ-AFF-008-HANDOFF-GENERATION-EXHAUSTION-PRESERVES-READY
execution-test-start TEST-REQ-AFF-004-HANDOFF-REJECTS-INCONSISTENT-SCHEDULING-STATES
ok    TEST-REQ-AFF-004-HANDOFF-REJECTS-INCONSISTENT-SCHEDULING-STATES
execution-test-start TEST-REQ-AFF-004-HANDOFF-HELPERS-REQUIRE-CURRENT-THREAD-GUARD
ok    TEST-REQ-AFF-004-HANDOFF-HELPERS-REQUIRE-CURRENT-THREAD-GUARD
execution-test-start TEST-REQ-CON-001-HANDOFF-SEEDED-LIST-AND-SCHEDULING-ORACLE
ok    TEST-REQ-CON-001-HANDOFF-SEEDED-LIST-AND-SCHEDULING-ORACLE
execution-test-start TEST-REQ-CON-001-HANDOFF-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-HANDOFF-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-002-HANDOFF-TRANSFERS-SUCCESSIVE-SLICES-BETWEEN-REUSED-THREADS
ok    TEST-REQ-CON-002-HANDOFF-TRANSFERS-SUCCESSIVE-SLICES-BETWEEN-REUSED-THREADS
execution-test-start TEST-REQ-CON-003-HANDOFF-REUSES-FOUR-WORKERS-ACROSS-INDEPENDENT-SERIES-WAVES
  Handoff: 4 thread riusati, 6 ondate, 36 messaggi, 2 Serie indipendenti.
ok    TEST-REQ-CON-003-HANDOFF-REUSES-FOUR-WORKERS-ACROSS-INDEPENDENT-SERIES-WAVES
execution-tests-complete 34
")
  (:PATH "0/test.log" :BYTE-COUNT 10968 :GIT-BLOB
   "b8e792d75a444abaf884865c1405138424f1202e" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 34050 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900393}>:
  ArcDocDB: WRITER-SCHEDULING

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800773AA63}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800773AA63}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800773AA63}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-SCHEDULING)
4: (ARCDOCDB.EXECUTION::%CHECK-PROGRAMMABILE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) :STATE :IDLE))
5: (ARCDOCDB.EXECUTION:ACCODA-LAVORO-WRITER #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) :STATE :IDLE) NIL)
6: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-CHECK-ENQUEUE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) :STATE :IDLE) NIL 1 :SCHEDULE)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106EF0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106EF09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/0/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "1/test.log" :BYTE-COUNT 10383 :GIT-BLOB
   "79d8daaf1cba5cb25652a19d5c5bab78f01a8fcb" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 33829 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80059003C3}>:
  Asserzione fallita: (EQ ARCDOCDB.EXECUTION.TESTS::STATUS
                          ARCDOCDB.EXECUTION.TESTS::EXPECTED-STATUS)

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059003C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006ED8B23}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006ED8B23}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006ED8B23}>)
3: (ERROR \"Asserzione fallita: ~S\" (EQ ARCDOCDB.EXECUTION.TESTS::STATUS ARCDOCDB.EXECUTION.TESTS::EXPECTED-STATUS))
4: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-CHECK-ENQUEUE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(0 1 NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 2 :COUNT 2 :GUARD NIL :OWNER NIL :GENERATION 0 :EXTRACTED 0) :STATE :READY) 1 2 :QUEUED)
5: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
12: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105250F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1052509EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/1/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "2/test.log" :BYTE-COUNT 11619 :GIT-BLOB
   "62b31dc7b35538911477cb9263f3864c359ee1e3" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 34024 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
ok    TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
execution-test-start TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN
ok    TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN
execution-test-start TEST-REQ-CON-005-HANDOFF-ENQUEUE-BEFORE-AND-AFTER-EMPTY-RELEASE
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {80059009E3}>:
  ArcDocDB: WRITER-SCHEDULING

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059009E3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80079DCF43}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80079DCF43}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {80079DCF43}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-SCHEDULING)
4: (ARCDOCDB.EXECUTION::%CHECK-WRITER-INATTIVO #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL :BEFORE-RELEASE) :CAPACITY 2 :QUANTUM 3 :HEAD 1 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059009E3}> :OWNER #1# :GENERATION 1 :EXTRACTED 1))
5: (ARCDOCDB.EXECUTION::%CHECK-PROGRAMMABILE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL :BEFORE-RELEASE) :CAPACITY 2 :QUANTUM 3 :HEAD 1 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059009E3}> :OWNER #1# :GENERATION 1 :EXTRACTED 1) :STATE :READY))
6: (ARCDOCDB.EXECUTION:ACCODA-LAVORO-WRITER #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL :BEFORE-RELEASE) :CAPACITY 2 :QUANTUM 3 :HEAD 1 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059009E3}> :OWNER #1# :GENERATION 1 :EXTRACTED 1) :STATE :READY) :BEFORE-RELEASE)
7: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-CHECK-ENQUEUE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL :BEFORE-RELEASE) :CAPACITY 2 :QUANTUM 3 :HEAD 1 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059009E3}> :OWNER #1# :GENERATION 1 :EXTRACTED 1) :STATE :READY) :BEFORE-RELEASE 1 :QUEUED)
8: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-005-HANDOFF-ENQUEUE-BEFORE-AND-AFTER-EMPTY-RELEASE)
9: (\"top level form\") [toplevel]
10: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
11: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
12: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
13: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
15: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107230F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1072309EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
23: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
24: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/2/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
27: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
28: (SB-IMPL::TOPLEVEL-INIT)
29: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
30: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
31: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "3/test.log" :BYTE-COUNT 10641 :GIT-BLOB
   "ac0aa7ffefe1fbb013ed0bd85768fecbb83ea823" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 32950 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
ok    TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
execution-test-start TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900403}>:
  Asserzione fallita: (HANDLER-CASE
                       (PROGN
                        (ARCDOCDB.EXECUTION:INIZIA-TRATTO-WRITER
                         ARCDOCDB.EXECUTION.TESTS::WRITER)
                        NIL)
                       (ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED (CONDITION)
                        (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON CONDITION)
                            :WRITER-NOT-READY)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006DF8A83}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006DF8A83}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006DF8A83}>)
3: (ERROR \"Asserzione fallita: ~S\" (HANDLER-CASE (PROGN (ARCDOCDB.EXECUTION:INIZIA-TRATTO-WRITER ARCDOCDB.EXECUTION.TESTS::WRITER) NIL) (ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED #1=(CONDITION) (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON . #1#) :WRITER-NOT-READY))))
4: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-005-HANDOFF-SINGLE-OBLIGATION-AND-DUPLICATE-BEGIN)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1059C0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1059C09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/3/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "4/test.log" :BYTE-COUNT 11215 :GIT-BLOB
   "4e3471a6a6b6db5ef01fbcbb6dbb76dc35d289a8" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 34034 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900333}>:
  ArcDocDB: WRITER-SCHEDULING

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900333}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006F68B03}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006F68B03}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006F68B03}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-SCHEDULING)
4: (ARCDOCDB.EXECUTION::%CHECK-WRITER-INATTIVO #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900333}> :OWNER #1# :GENERATION 1 :EXTRACTED 0))
5: (ARCDOCDB.EXECUTION::%CHECK-PROGRAMMABILE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900333}> :OWNER #1# :GENERATION 1 :EXTRACTED 0) :STATE :READY))
6: (ARCDOCDB.EXECUTION:INIZIA-TRATTO-WRITER #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900333}> :OWNER #1# :GENERATION 1 :EXTRACTED 0) :STATE :READY))
7: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-DRAIN #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 1 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900333}> :OWNER #1# :GENERATION 1 :EXTRACTED 0) :STATE :READY) 1)
8: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
9: (\"top level form\") [toplevel]
10: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
11: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
12: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
13: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
15: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
16: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
17: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
18: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {108EA0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
19: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
20: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
21: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {108EA09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
23: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
24: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/4/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
27: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
28: (SB-IMPL::TOPLEVEL-INIT)
29: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
30: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
31: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "5/test.log" :BYTE-COUNT 11101 :GIT-BLOB
   "a47ade1bb41bfc52fb37b2ded68168cb0ae19ffb" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 33921 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900593}>:
  ArcDocDB: WRITER-SCHEDULING

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900593}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800742AB63}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800742AB63}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800742AB63}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-SCHEDULING)
4: (ARCDOCDB.EXECUTION::%CHECK-PROGRAMMABILE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 960 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900593}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :IDLE))
5: (ARCDOCDB.EXECUTION:TERMINA-TRATTO-WRITER #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 960 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900593}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :IDLE) 1)
6: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-DRAIN #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 960 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900593}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :IDLE) 1024)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105680F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1056809EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/5/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "6/test.log" :BYTE-COUNT 10475 :GIT-BLOB
   "bdc398e13d5fcd10ec4979f7927bd72dd698015c" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 34017 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80059003C3}>:
  Asserzione fallita: (EQUAL
                       (LOOP ARCDOCDB.EXECUTION.TESTS::FOR ARCDOCDB.EXECUTION.TESTS::I ARCDOCDB.EXECUTION.TESTS::BELOW 1024
                             ARCDOCDB.EXECUTION.TESTS::COLLECT ARCDOCDB.EXECUTION.TESTS::I)
                       (ARCDOCDB.EXECUTION.TESTS::HANDOFF-DRAIN
                        ARCDOCDB.EXECUTION.TESTS::WRITER 1024))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059003C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006E589A3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006E589A3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006E589A3}>)
3: (ERROR \"Asserzione fallita: ~S\" (EQUAL (LOOP ARCDOCDB.EXECUTION.TESTS::FOR ARCDOCDB.EXECUTION.TESTS::I ARCDOCDB.EXECUTION.TESTS::BELOW 1024 ARCDOCDB.EXECUTION.TESTS::COLLECT ARCDOCDB.EXECUTION.TESTS::I) (ARCDOCDB.EXECUTION.TESTS::HANDOFF-DRAIN ARCDOCDB.EXECUTION.TESTS::WRITER 1024)))
4: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1057C0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1057C09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/6/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "7/test.log" :BYTE-COUNT 10948 :GIT-BLOB
   "0831dbbc338d01c8f63267007f33ea7a46ad265a" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
ok    TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
execution-test-start TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
ok    TEST-REQ-CON-001-WRITER-CAS-HAS-ONE-OWNER
execution-test-start TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
  CPU due Serie: 1048576 byte, overlap 33855 tick, unita 1000000 tick/s.
ok    TEST-REQ-CON-003-INDEPENDENT-SERIES-PROGRESS-AND-CPU-OVERLAP
execution-test-start TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
  wave 0: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 1: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
  wave 2: 144 messaggi, 3 producer, 2 consumer, 5 worker riusati, drain aperto.
ok    TEST-REQ-CON-001-WRITER-REAL-PRODUCERS-CONSUMERS-AND-WORKER-REUSE
execution-test-start TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900A73}>:
  ArcDocDB: WRITER-SCHEDULING

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900A73}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007968B03}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007968B03}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8007968B03}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-SCHEDULING)
4: (ARCDOCDB.EXECUTION::%CHECK-PROGRAMMABILE #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 0 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900A73}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :READY))
5: (ARCDOCDB.EXECUTION:TERMINA-TRATTO-WRITER #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 0 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900A73}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :READY) 1)
6: (ARCDOCDB.EXECUTION.TESTS::HANDOFF-DRAIN #S(ARCDOCDB.EXECUTION:WRITER-PROGRAMMABILE :QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL) :CAPACITY 1 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 0 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900A73}> :OWNER NIL :GENERATION 1 :EXTRACTED 0) :STATE :READY) 1)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-HANDOFF-CONFIGURATION-AND-LIMITS)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1096D0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1096D09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/7/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "8/test.log" :BYTE-COUNT 8613 :GIT-BLOB
   "3cfa363d05fce4c5552e34ebd2f86cbd300deb6b" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900403}>:
  ArcDocDB: WRITER-QUEUE-INVARIANT

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006778073}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006778073}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006778073}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-QUEUE-INVARIANT)
4: (ARCDOCDB.EXECUTION::%CHECK-QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 896 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER #1# :GENERATION 2 :EXTRACTED 64))
5: (ARCDOCDB.EXECUTION:PRELEVA-MESSAGGI #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 896 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER #1# :GENERATION 2 :EXTRACTED 64) 2 #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) 0 1024)
6: (ARCDOCDB.EXECUTION.TESTS::EXECUTION-DRAIN #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 64 :TAIL 0 :COUNT 896 :GUARD #1=#<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER #1# :GENERATION 2 :EXTRACTED 64) 1024)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107BD0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107BD09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/8/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "9/test.log" :BYTE-COUNT 8519 :GIT-BLOB
   "e7b1b875bfd83e7666afeb61f38d8e8a019823bc" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900403}>:
  ArcDocDB: WRITER-QUEUE-INVARIANT

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006782013}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006782013}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {8006782013}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-QUEUE-INVARIANT)
4: (ARCDOCDB.EXECUTION::%CHECK-QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(0 NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 2 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER NIL :GENERATION 0 :EXTRACTED 0))
5: (ARCDOCDB.EXECUTION::%ACCODA-SOTTO-GUARD #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(0 NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 2 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) 0)
6: (ARCDOCDB.EXECUTION:ACCODA-MESSAGGIO #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(0 NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 2 :COUNT 1 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) 0)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109D90F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {109D909EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/9/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "10/test.log" :BYTE-COUNT 8500 :GIT-BLOB
   "dcffe3896d74447331e8549e4def742cbef1279e" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                               {8005900303}>:
  ArcDocDB: WRITER-QUEUE-INVARIANT

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800675D093}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800675D093}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION {800675D093}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION :REASON :WRITER-QUEUE-INVARIANT)
4: (ARCDOCDB.EXECUTION::%CHECK-QUEUE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(:EXTRA 1 2 3 4 5 6 7 8 9 10 11 ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 1 :COUNT 1025 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}> :OWNER NIL :GENERATION 0 :EXTRACTED 0))
5: (ARCDOCDB.EXECUTION::%ACCODA-SOTTO-GUARD #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(:EXTRA 1 2 3 4 5 6 7 8 9 10 11 ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 1 :COUNT 1025 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) :EXTRA)
6: (ARCDOCDB.EXECUTION:ACCODA-MESSAGGIO #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(:EXTRA 1 2 3 4 5 6 7 8 9 10 11 ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 0 :TAIL 1 :COUNT 1025 :GUARD #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}> :OWNER NIL :GENERATION 0 :EXTRACTED 0) :EXTRA)
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {108F30F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {108F309EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/10/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "11/test.log" :BYTE-COUNT 16295 :GIT-BLOB
   "9f00ed565f0744ce2a9bc051847a2a7ae4a9ee07" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900303}>:
  Asserzione fallita: (HANDLER-CASE
                       (PROGN
                        (ARCDOCDB.EXECUTION:ACCODA-MESSAGGIO
                         ARCDOCDB.EXECUTION.TESTS::QUEUE
                         ARCDOCDB.EXECUTION.TESTS::REFUSED)
                        NIL)
                       (ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED (CONDITION)
                        (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON CONDITION)
                            :WRITER-QUEUE-BUSY)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006795ED3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006795ED3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006795ED3}>)
3: (ERROR \"Asserzione fallita: ~S\" (HANDLER-CASE (PROGN (ARCDOCDB.EXECUTION:ACCODA-MESSAGGIO ARCDOCDB.EXECUTION.TESTS::QUEUE ARCDOCDB.EXECUTION.TESTS::REFUSED) NIL) (ARCDOCDB.CONDITIONS:RESOURCE-EXHAUSTED #1=(CONDITION) (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON . #1#) :WRITER-QUEUE-BUSY))))
4: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107980F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1079809EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900303}>:
  Asserzione fallita: (EQ #:OWNER5
                          (COMPARE-AND-SWAP
                           (ARCDOCDB.EXECUTION::CODA-WRITER-GUARD #:QUEUE4)
                           #:OWNER5 NIL))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900303}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800687FEA3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800687FEA3}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {800687FEA3}>)
3: (ERROR \"Asserzione fallita: ~S\" (EQ #1=#:OWNER5 (COMPARE-AND-SWAP (ARCDOCDB.EXECUTION::CODA-WRITER-GUARD #:QUEUE4) #1# NIL)))
4: ((FLET \"CLEANUP-FUN-9\" :IN ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE)) [cleanup]
5: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
12: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107980F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1079809EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/11/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "12/test.log" :BYTE-COUNT 9740 :GIT-BLOB
   "3ec8d6a3cd537efdca6c157f80ff6b5c789815cb" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
ok    TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
execution-test-start TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
ok    TEST-REQ-AFF-008-WRITER-QUANTUM-IS-CUMULATIVE-PER-LEASE
execution-test-start TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
ok    TEST-REQ-AFF-008-WRITER-GENERATION-DOES-NOT-WRAP
execution-test-start TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
ok    TEST-REQ-CON-001-WRITER-SEEDED-LIST-ORACLE
execution-test-start TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900403}>:
  Asserzione fallita: (HANDLER-CASE
                       (PROGN
                        (ARCDOCDB.EXECUTION:PRELEVA-MESSAGGI
                         ARCDOCDB.EXECUTION.TESTS::QUEUE
                         ARCDOCDB.EXECUTION.TESTS::LEASE
                         ARCDOCDB.EXECUTION.TESTS::TARGET 0 1)
                        NIL)
                       (ARCDOCDB.CONDITIONS:INVALID-ARGUMENT (CONDITION)
                        (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON CONDITION)
                            :WRITER-LEASE)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900403}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006990033}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006990033}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006990033}>)
3: (ERROR #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006990033}>)
4: (ARCDOCDB.EXECUTION.TESTS::EXECUTION-JOIN #<SB-THREAD:THREAD tid=6915 \"execution foreign owner\" FINISHED values: #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006990033}> {80069772C3}> 20)
5: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-001-WRITER-FOREIGN-THREAD-CANNOT-USE-LEASE)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
12: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109550F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1095509EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/12/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "13/test.log" :BYTE-COUNT 17078 :GIT-BLOB
   "07fcdd5fb0b3b1f8496cea1001447115c389a271" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
ok    TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
execution-test-start TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
ok    TEST-REQ-AFF-008-WRITER-FULL-REFUSAL-RETAINS-PAYLOAD
execution-test-start TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
ok    TEST-REQ-CON-004-WRITER-GUARD-BUSY-DOES-NOT-MUTATE
execution-test-start TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
ok    TEST-REQ-CON-001-WRITER-TARGET-SUBRANGE-AND-EMPTY
execution-test-start TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
ok    TEST-REQ-AFF-004-WRITER-INVALID-TARGET-PREFLIGHT
execution-test-start TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
ok    TEST-REQ-AFF-004-WRITER-PRIVATE-RING-ALIAS-REFUSED
execution-test-start TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
ok    TEST-REQ-CON-001-WRITER-LEASE-LIFECYCLE
execution-test-start TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900393}>:
  Asserzione fallita: (HANDLER-CASE
                       (PROGN
                        (ARCDOCDB.EXECUTION:RILASCIA-WRITER
                         ARCDOCDB.EXECUTION.TESTS::QUEUE
                         ARCDOCDB.EXECUTION.TESTS::OLD)
                        NIL)
                       (ARCDOCDB.CONDITIONS:INVALID-ARGUMENT (CONDITION)
                        (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON CONDITION)
                            :WRITER-LEASE)))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F18A03}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F18A03}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F18A03}>)
3: (ERROR \"Asserzione fallita: ~S\" (HANDLER-CASE (PROGN (ARCDOCDB.EXECUTION:RILASCIA-WRITER ARCDOCDB.EXECUTION.TESTS::QUEUE ARCDOCDB.EXECUTION.TESTS::OLD) NIL) (ARCDOCDB.CONDITIONS:INVALID-ARGUMENT #1=(CONDITION) (EQ (ARCDOCDB.CONDITIONS:ERROR-REASON . #1#) :WRITER-LEASE))))
4: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD)
5: (\"top level form\") [toplevel]
6: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
7: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
8: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
9: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
10: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
12: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
13: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
14: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106DC0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
15: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
16: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
17: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106DC09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
18: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
19: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
20: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
23: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
24: (SB-IMPL::TOPLEVEL-INIT)
25: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
26: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
27: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
Unhandled ARCDOCDB.CONDITIONS:INVALID-ARGUMENT in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                            {8005900393}>:
  ArcDocDB: WRITER-LEASE

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900393}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8007022513}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8007022513}>)
2: (INVOKE-DEBUGGER #<ARCDOCDB.CONDITIONS:INVALID-ARGUMENT {8007022513}>)
3: (ERROR ARCDOCDB.CONDITIONS:INVALID-ARGUMENT :REASON :WRITER-LEASE)
4: (ARCDOCDB.EXECUTION::%CHECK-LEASE #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(:KEPT NIL) :CAPACITY 2 :QUANTUM 1 :HEAD 0 :TAIL 1 :COUNT 1 :GUARD NIL :OWNER NIL :GENERATION 2 :EXTRACTED 0) 2)
5: (ARCDOCDB.EXECUTION:RILASCIA-WRITER #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(:KEPT NIL) :CAPACITY 2 :QUANTUM 1 :HEAD 0 :TAIL 1 :COUNT 1 :GUARD NIL :OWNER NIL :GENERATION 2 :EXTRACTED 0) 2)
6: ((FLET \"CLEANUP-FUN-1\" :IN ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD)) [cleanup]
7: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-001-WRITER-STALE-LEASE-SAME-THREAD)
8: (\"top level form\") [toplevel]
9: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
10: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
11: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
12: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
13: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
14: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
15: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
16: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
17: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {106DC0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
18: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
19: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {106DC09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
21: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
22: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
23: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/13/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
24: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
25: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
26: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
27: (SB-IMPL::TOPLEVEL-INIT)
28: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
29: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
30: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "14/test.log" :BYTE-COUNT 7995 :GIT-BLOB
   "6e88310921ddbf23d4f525afa6649209d20d982d" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {8005900363}>:
  Asserzione fallita: (= COUNT (LENGTH ARCDOCDB.EXECUTION.TESTS::EXPECTED))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900363}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80067B4023}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80067B4023}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {80067B4023}>)
3: (ERROR \"Asserzione fallita: ~S\" (= COUNT (LENGTH ARCDOCDB.EXECUTION.TESTS::EXPECTED)))
4: (ARCDOCDB.EXECUTION.TESTS::EXECUTION-CHECK-POP #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL NIL ...) :CAPACITY 1024 :QUANTUM 64 :HEAD 128 :TAIL 0 :COUNT 896 :GUARD NIL :OWNER #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {8005900363}> :GENERATION 1 :EXTRACTED 64) 1 #(64 65 66 67 68 69 70 71 72 73 74 75 ...) 0 1024 NIL :YIELD)
5: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
12: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109CE0F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {109CE09EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/14/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")
  (:PATH "15/test.log" :BYTE-COUNT 8048 :GIT-BLOB
   "4079220af9adcfe2b23e41a446394a25896e3a33" :CONTENT
   "execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION
ok    TEST-REQ-AFF-008-WRITER-CONFIGURATION
execution-test-start TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
ok    TEST-REQ-AFF-008-WRITER-DEFAULTS-AND-CONFIGURATION-BOUNDARIES
execution-test-start TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL
Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80059003C3}>:
  Asserzione fallita: (= COUNT (LENGTH ARCDOCDB.EXECUTION.TESTS::EXPECTED))

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059003C3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F3A983}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F3A983}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"Asserzione fallita: ~S\" {8006F3A983}>)
3: (ERROR \"Asserzione fallita: ~S\" (= COUNT (LENGTH ARCDOCDB.EXECUTION.TESTS::EXPECTED)))
4: (ARCDOCDB.EXECUTION.TESTS::EXECUTION-CHECK-POP #S(ARCDOCDB.EXECUTION:CODA-WRITER :SLOTS #(NIL NIL) :CAPACITY 2 :QUANTUM 65536 :HEAD 0 :TAIL 0 :COUNT 0 :GUARD NIL :OWNER #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80059003C3}> :GENERATION 1 :EXTRACTED 2) 1 #(:UNTOUCHED NIL (1)) 1 2 (NIL) :MESSAGES)
5: (ARCDOCDB.EXECUTION.TESTS::TEST-REQ-CON-001-WRITER-FIFO-RING-WRAP-AND-NIL)
6: (\"top level form\") [toplevel]
7: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
8: (SB-C::%COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL T T)
9: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80052B0423}> 4 NIL)
10: (SB-IMPL::%SIMPLE-EVAL (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
11: (SB-INT:SIMPLE-EVAL-IN-LEXENV (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) #<NULL-LEXENV>)
12: (EVAL-TLF (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4 NIL)
13: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) 4)
14: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (LET* ((PACKAGE (OR (FIND-PACKAGE \"ARCDOCDB.EXECUTION.TESTS\") (ERROR \"Harness execution non caricato.\"))) (REGISTRY (OR (FIND-SYMBOL \"*TESTS*\" PACKAGE) (ERROR \"Registro execution assente.\"))) (TESTS (REVERSE (SYMBOL-VALUE REGISTRY)))) (UNLESS (AND TESTS (EVERY (FUNCTION FBOUNDP) TESTS)) (ERROR \"Test execution non caricati dal sistema ASDF.\")) (DOLIST (TEST TESTS) (FORMAT T \"~&execution-test-start ~A~%\" TEST) (FINISH-OUTPUT) (FUNCALL TEST) (FORMAT T \"ok    ~A~%\" TEST)) (FORMAT T \"~&execution-tests-complete ~D~%\" (LENGTH TESTS))) :CURRENT-INDEX 4)
15: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {109350F1B}> #<SB-C::SOURCE-INFO {80052B0423}> SB-C::INPUT-ERROR-IN-LOAD)
16: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
17: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
18: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1093509EB}> #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
19: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> NIL)
20: (LOAD #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
21: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/manifest-main92-handoff/15/tools/writer-handoff-isolated-build.lisp\" {80052B0043}>)
22: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
23: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
24: (SB-IMPL::PROCESS-SCRIPT \"tools/writer-handoff-isolated-build.lisp\")
25: (SB-IMPL::TOPLEVEL-INIT)
26: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
27: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
28: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
")))
