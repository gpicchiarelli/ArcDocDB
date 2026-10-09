(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :STATUS :PASSED :STAGE
 :COMPLETE :PROCESS-ARGV ("sbcl" "--self-test") :TOOL-ARGUMENTS ("--self-test")
 :RECORDED-AT 4000521810 :SBCL #A((5) BASE-CHAR . "2.6.9")
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "a892e51155dd4495c06f46495f18be06"))
  (:FILE "tools/build.lisp" :MD5
   #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
  (:FILE "src/codec/package.lisp" :MD5
   #A((32) BASE-CHAR . "d885bd2a9860eb60aec1a775e5031d5e"))
  (:FILE "src/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "0f67dd5c51bf6a63bc292ab4e2a280c2"))
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
   #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5"))
  (:FILE "tests/codec/support.lisp" :MD5
   #A((32) BASE-CHAR . "32534fd42dd8124b50b45deefe143eaf"))
  (:FILE "tests/codec/threads.lisp" :MD5
   #A((32) BASE-CHAR . "a71504598cda8e99cd50e229ddd5275b"))
  (:FILE "tests/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "767ead15603be8dce90f340dbb200d8f"))
  (:FILE "tests/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "f87fdc0f7bd194329c6349026a2f35bb"))
  (:FILE "tests/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "940ebb450bc871f8c2dd7dc9977bb158"))
  (:FILE "tests/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "f6756125a9150b6312dad3e2705b74d3"))
  (:FILE "tests/execution/support.lisp" :MD5
   #A((32) BASE-CHAR . "bacb1a135c0d73cded57ba21986c8496"))
  (:FILE "tests/execution/threads.lisp" :MD5
   #A((32) BASE-CHAR . "32b6a6578f526b7d4bcc3a1665a8c6e6"))
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
  (:FILE "tests/recovery/decisions-radix.lisp" :MD5
   #A((32) BASE-CHAR . "58eec0feac01e643c76ad19ef5c07df5"))
  (:FILE "tests/recovery/decisions-support.lisp" :MD5
   #A((32) BASE-CHAR . "80348d0ce2adbc8a4d37db49df291b1d"))
  (:FILE "tests/recovery/decisions.lisp" :MD5
   #A((32) BASE-CHAR . "5add0e087181bad8ce330af23fc26686"))
  (:FILE "tests/recovery/manifest-audit.lisp" :MD5
   #A((32) BASE-CHAR . "3ca73a199708e2571da3a27e6dc00c76"))
  (:FILE "tests/recovery/manifest-support.lisp" :MD5
   #A((32) BASE-CHAR . "3286e0dfb66496aafe8b6fbbdd92ab43"))
  (:FILE "tests/recovery/manifest.lisp" :MD5
   #A((32) BASE-CHAR . "b6bdcc4d20f7db14c0dc00d5258cbf8c"))
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
  (:FILE "tools/writer-ready-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "b42b93da5531cee14e285c1ee8e8627e")))
 :SOURCE-FINGERPRINTS-AFTER
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "a892e51155dd4495c06f46495f18be06"))
  (:FILE "tools/build.lisp" :MD5
   #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
  (:FILE "src/codec/package.lisp" :MD5
   #A((32) BASE-CHAR . "d885bd2a9860eb60aec1a775e5031d5e"))
  (:FILE "src/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "0f67dd5c51bf6a63bc292ab4e2a280c2"))
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
   #A((32) BASE-CHAR . "b7be1fd52803a3cf9eb88436d381c5e5"))
  (:FILE "tests/codec/support.lisp" :MD5
   #A((32) BASE-CHAR . "32534fd42dd8124b50b45deefe143eaf"))
  (:FILE "tests/codec/threads.lisp" :MD5
   #A((32) BASE-CHAR . "a71504598cda8e99cd50e229ddd5275b"))
  (:FILE "tests/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "767ead15603be8dce90f340dbb200d8f"))
  (:FILE "tests/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "f87fdc0f7bd194329c6349026a2f35bb"))
  (:FILE "tests/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "940ebb450bc871f8c2dd7dc9977bb158"))
  (:FILE "tests/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "f6756125a9150b6312dad3e2705b74d3"))
  (:FILE "tests/execution/support.lisp" :MD5
   #A((32) BASE-CHAR . "bacb1a135c0d73cded57ba21986c8496"))
  (:FILE "tests/execution/threads.lisp" :MD5
   #A((32) BASE-CHAR . "32b6a6578f526b7d4bcc3a1665a8c6e6"))
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
  (:FILE "tests/recovery/decisions-radix.lisp" :MD5
   #A((32) BASE-CHAR . "58eec0feac01e643c76ad19ef5c07df5"))
  (:FILE "tests/recovery/decisions-support.lisp" :MD5
   #A((32) BASE-CHAR . "80348d0ce2adbc8a4d37db49df291b1d"))
  (:FILE "tests/recovery/decisions.lisp" :MD5
   #A((32) BASE-CHAR . "5add0e087181bad8ce330af23fc26686"))
  (:FILE "tests/recovery/manifest-audit.lisp" :MD5
   #A((32) BASE-CHAR . "3ca73a199708e2571da3a27e6dc00c76"))
  (:FILE "tests/recovery/manifest-support.lisp" :MD5
   #A((32) BASE-CHAR . "3286e0dfb66496aafe8b6fbbdd92ab43"))
  (:FILE "tests/recovery/manifest.lisp" :MD5
   #A((32) BASE-CHAR . "b6bdcc4d20f7db14c0dc00d5258cbf8c"))
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
  (:FILE "tools/writer-ready-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "b42b93da5531cee14e285c1ee8e8627e")))
 :SOURCE-CONSISTENCY :STABLE :TARGETS (("signal-fixture" "fixture" NIL))
 :PLANNED-MUTANTS 1 :BASELINE :PENDING :BASELINE-RESULT NIL :BASELINE-EXIT-CODE
 NIL :BASELINE-SIGNAL NIL :BASELINE-LOG
 #A((156) BASE-CHAR
    . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/4000521810-ready-signal-self-test-41080/baseline/test.log")
 :MUTANTS
 ((:NAME "signal-fixture" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9 :LOG
   #A((147) BASE-CHAR
      . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/4000521810-ready-signal-self-test-41080/test.log")))
 :CURRENT-ORDINAL NIL :CURRENT-MUTANT NIL :CURRENT-LOG NIL :DIAGNOSTIC NIL
 :DETECTED 0 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0 :WORKER-ERRORS
 1 :LIMITS
 (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE :STRICT-COMPILATION
  :TEST-EVENTS-AT-LINE-START :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
  :NO-POOL-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))
