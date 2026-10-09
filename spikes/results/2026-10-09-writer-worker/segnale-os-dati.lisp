(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :STATUS :PASSED :STAGE
 :COMPLETE :PROCESS-ARGV
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--self-test")
 :TOOL-ARGUMENTS ("--self-test") :RECORDED-AT 4000547222 :SBCL
 #A((5) BASE-CHAR . "2.6.9") :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "8b059b3e979fa134cebba5bcb3119e50"))
  (:FILE "tools/build.lisp" :MD5
   #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
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
   #A((32) BASE-CHAR . "c57180df548721dc69049451a15b55d5"))
  (:FILE "src/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "8202843bddb817da4279ac959ae3f3c4"))
  (:FILE "src/execution/ready-recycle.lisp" :MD5
   #A((32) BASE-CHAR . "38d26f8c749dd946dfc4b9c57103a892"))
  (:FILE "src/execution/ready-types.lisp" :MD5
   #A((32) BASE-CHAR . "a64d98c9ff429d6103d6e10ee1fd7980"))
  (:FILE "src/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "2c1892002f0599bb8273093031017520"))
  (:FILE "src/execution/worker-boundary.lisp" :MD5
   #A((32) BASE-CHAR . "c24065d6c8d80d1be53994a0041743df"))
  (:FILE "src/execution/worker-claim.lisp" :MD5
   #A((32) BASE-CHAR . "babd0a78b4185af24ae1fef870c0fabb"))
  (:FILE "src/execution/worker-run.lisp" :MD5
   #A((32) BASE-CHAR . "6823b446cebcff986645e4c992070d8f"))
  (:FILE "src/execution/worker-types.lisp" :MD5
   #A((32) BASE-CHAR . "0679ee07c46f69db330706303c70d8d2"))
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
   #A((32) BASE-CHAR . "f799f27a8ac1a4c736c04796c1e543f9"))
  (:FILE "tests/codec/cbor-header.lisp" :MD5
   #A((32) BASE-CHAR . "208ee0d03652de67ad453bdd34d10b62"))
  (:FILE "tests/codec/cbor-structure-support.lisp" :MD5
   #A((32) BASE-CHAR . "220d386d29b1fa192e06ceebe4ec245c"))
  (:FILE "tests/codec/cbor-structure-threads.lisp" :MD5
   #A((32) BASE-CHAR . "f38848c55b050dae335b0a37657c1f5c"))
  (:FILE "tests/codec/cbor-structure.lisp" :MD5
   #A((32) BASE-CHAR . "06e6f060aea55a18d06047e5ebabd18e"))
  (:FILE "tests/codec/cbor-support.lisp" :MD5
   #A((32) BASE-CHAR . "e5da97609a2ba58bb35fea24b7518d2b"))
  (:FILE "tests/codec/cbor-threads.lisp" :MD5
   #A((32) BASE-CHAR . "4d7d61509b2ce749fb2331ceeaeeca76"))
  (:FILE "tests/codec/support.lisp" :MD5
   #A((32) BASE-CHAR . "32534fd42dd8124b50b45deefe143eaf"))
  (:FILE "tests/codec/threads.lisp" :MD5
   #A((32) BASE-CHAR . "a71504598cda8e99cd50e229ddd5275b"))
  (:FILE "tests/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "767ead15603be8dce90f340dbb200d8f"))
  (:FILE "tests/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "1d9133c5fd33cb60ff160f468db330f4"))
  (:FILE "tests/csn/support.lisp" :MD5
   #A((32) BASE-CHAR . "e5c151cda2e10e4f9cae46a4326699eb"))
  (:FILE "tests/csn/threads.lisp" :MD5
   #A((32) BASE-CHAR . "087108576603e6cd5b9af14b50475746"))
  (:FILE "tests/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "f87fdc0f7bd194329c6349026a2f35bb"))
  (:FILE "tests/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "940ebb450bc871f8c2dd7dc9977bb158"))
  (:FILE "tests/execution/ready-recycle.lisp" :MD5
   #A((32) BASE-CHAR . "4ccdc0512b3c81837726076d7c795930"))
  (:FILE "tests/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "f6756125a9150b6312dad3e2705b74d3"))
  (:FILE "tests/execution/support.lisp" :MD5
   #A((32) BASE-CHAR . "bacb1a135c0d73cded57ba21986c8496"))
  (:FILE "tests/execution/threads.lisp" :MD5
   #A((32) BASE-CHAR . "32b6a6578f526b7d4bcc3a1665a8c6e6"))
  (:FILE "tests/execution/worker.lisp" :MD5
   #A((32) BASE-CHAR . "bbaa592327d730fdae78cb881350efe0"))
  (:FILE "tests/foundation/batch.lisp" :MD5
   #A((32) BASE-CHAR . "29fc6a9711ea9265840e8cde4971f74e"))
  (:FILE "tests/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "07c4c9ac2177f22e5b7fb25f9867a133"))
  (:FILE "tests/foundation/record.lisp" :MD5
   #A((32) BASE-CHAR . "7a84ca3aa74ab158c6b7d66886cf8b23"))
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
  (:FILE "tests/wal/csn-threads.lisp" :MD5
   #A((32) BASE-CHAR . "ecb2cbf4f7ace32cdaff329476070d60"))
  (:FILE "tests/wal/csn.lisp" :MD5
   #A((32) BASE-CHAR . "3e2dbc3319b611db090e27493a10fc2c"))
  (:FILE "tests/wal/fault.lisp" :MD5
   #A((32) BASE-CHAR . "00367366b82918614d84f517f4bb395e"))
  (:FILE "tests/wal/group.lisp" :MD5
   #A((32) BASE-CHAR . "0ee2462103a749b58488561aeacaac07"))
  (:FILE "tests/wal/native.lisp" :MD5
   #A((32) BASE-CHAR . "0643b96c5ee339f9826b19150d065ddf"))
  (:FILE "tests/wal/support.lisp" :MD5
   #A((32) BASE-CHAR . "15952f6b761acea4519abf701bb2346c"))
  (:FILE "tools/writer-worker-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "593041388d9cf69357902e5dbf5479c6")))
 :SOURCE-FINGERPRINTS-AFTER
 ((:FILE "arcdocdb.asd" :MD5
   #A((32) BASE-CHAR . "8b059b3e979fa134cebba5bcb3119e50"))
  (:FILE "tools/build.lisp" :MD5
   #A((32) BASE-CHAR . "a0367c24405a56a2ffe84a9282004db0"))
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
   #A((32) BASE-CHAR . "c57180df548721dc69049451a15b55d5"))
  (:FILE "src/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "8202843bddb817da4279ac959ae3f3c4"))
  (:FILE "src/execution/ready-recycle.lisp" :MD5
   #A((32) BASE-CHAR . "38d26f8c749dd946dfc4b9c57103a892"))
  (:FILE "src/execution/ready-types.lisp" :MD5
   #A((32) BASE-CHAR . "a64d98c9ff429d6103d6e10ee1fd7980"))
  (:FILE "src/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "2c1892002f0599bb8273093031017520"))
  (:FILE "src/execution/worker-boundary.lisp" :MD5
   #A((32) BASE-CHAR . "c24065d6c8d80d1be53994a0041743df"))
  (:FILE "src/execution/worker-claim.lisp" :MD5
   #A((32) BASE-CHAR . "babd0a78b4185af24ae1fef870c0fabb"))
  (:FILE "src/execution/worker-run.lisp" :MD5
   #A((32) BASE-CHAR . "6823b446cebcff986645e4c992070d8f"))
  (:FILE "src/execution/worker-types.lisp" :MD5
   #A((32) BASE-CHAR . "0679ee07c46f69db330706303c70d8d2"))
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
   #A((32) BASE-CHAR . "f799f27a8ac1a4c736c04796c1e543f9"))
  (:FILE "tests/codec/cbor-header.lisp" :MD5
   #A((32) BASE-CHAR . "208ee0d03652de67ad453bdd34d10b62"))
  (:FILE "tests/codec/cbor-structure-support.lisp" :MD5
   #A((32) BASE-CHAR . "220d386d29b1fa192e06ceebe4ec245c"))
  (:FILE "tests/codec/cbor-structure-threads.lisp" :MD5
   #A((32) BASE-CHAR . "f38848c55b050dae335b0a37657c1f5c"))
  (:FILE "tests/codec/cbor-structure.lisp" :MD5
   #A((32) BASE-CHAR . "06e6f060aea55a18d06047e5ebabd18e"))
  (:FILE "tests/codec/cbor-support.lisp" :MD5
   #A((32) BASE-CHAR . "e5da97609a2ba58bb35fea24b7518d2b"))
  (:FILE "tests/codec/cbor-threads.lisp" :MD5
   #A((32) BASE-CHAR . "4d7d61509b2ce749fb2331ceeaeeca76"))
  (:FILE "tests/codec/support.lisp" :MD5
   #A((32) BASE-CHAR . "32534fd42dd8124b50b45deefe143eaf"))
  (:FILE "tests/codec/threads.lisp" :MD5
   #A((32) BASE-CHAR . "a71504598cda8e99cd50e229ddd5275b"))
  (:FILE "tests/codec/utf8.lisp" :MD5
   #A((32) BASE-CHAR . "767ead15603be8dce90f340dbb200d8f"))
  (:FILE "tests/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "1d9133c5fd33cb60ff160f468db330f4"))
  (:FILE "tests/csn/support.lisp" :MD5
   #A((32) BASE-CHAR . "e5c151cda2e10e4f9cae46a4326699eb"))
  (:FILE "tests/csn/threads.lisp" :MD5
   #A((32) BASE-CHAR . "087108576603e6cd5b9af14b50475746"))
  (:FILE "tests/execution/handoff.lisp" :MD5
   #A((32) BASE-CHAR . "f87fdc0f7bd194329c6349026a2f35bb"))
  (:FILE "tests/execution/queue.lisp" :MD5
   #A((32) BASE-CHAR . "940ebb450bc871f8c2dd7dc9977bb158"))
  (:FILE "tests/execution/ready-recycle.lisp" :MD5
   #A((32) BASE-CHAR . "4ccdc0512b3c81837726076d7c795930"))
  (:FILE "tests/execution/ready.lisp" :MD5
   #A((32) BASE-CHAR . "f6756125a9150b6312dad3e2705b74d3"))
  (:FILE "tests/execution/support.lisp" :MD5
   #A((32) BASE-CHAR . "bacb1a135c0d73cded57ba21986c8496"))
  (:FILE "tests/execution/threads.lisp" :MD5
   #A((32) BASE-CHAR . "32b6a6578f526b7d4bcc3a1665a8c6e6"))
  (:FILE "tests/execution/worker.lisp" :MD5
   #A((32) BASE-CHAR . "bbaa592327d730fdae78cb881350efe0"))
  (:FILE "tests/foundation/batch.lisp" :MD5
   #A((32) BASE-CHAR . "29fc6a9711ea9265840e8cde4971f74e"))
  (:FILE "tests/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "07c4c9ac2177f22e5b7fb25f9867a133"))
  (:FILE "tests/foundation/record.lisp" :MD5
   #A((32) BASE-CHAR . "7a84ca3aa74ab158c6b7d66886cf8b23"))
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
  (:FILE "tests/wal/csn-threads.lisp" :MD5
   #A((32) BASE-CHAR . "ecb2cbf4f7ace32cdaff329476070d60"))
  (:FILE "tests/wal/csn.lisp" :MD5
   #A((32) BASE-CHAR . "3e2dbc3319b611db090e27493a10fc2c"))
  (:FILE "tests/wal/fault.lisp" :MD5
   #A((32) BASE-CHAR . "00367366b82918614d84f517f4bb395e"))
  (:FILE "tests/wal/group.lisp" :MD5
   #A((32) BASE-CHAR . "0ee2462103a749b58488561aeacaac07"))
  (:FILE "tests/wal/native.lisp" :MD5
   #A((32) BASE-CHAR . "0643b96c5ee339f9826b19150d065ddf"))
  (:FILE "tests/wal/support.lisp" :MD5
   #A((32) BASE-CHAR . "15952f6b761acea4519abf701bb2346c"))
  (:FILE "tools/writer-worker-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "593041388d9cf69357902e5dbf5479c6")))
 :SOURCE-CONSISTENCY :STABLE :TARGETS (("signal-fixture" "fixture" NIL))
 :PLANNED-MUTANTS 1 :BASELINE :PENDING :BASELINE-RESULT NIL :BASELINE-EXIT-CODE
 NIL :BASELINE-SIGNAL NIL :BASELINE-LOG
 #A((158) BASE-CHAR
    . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547222-worker-signal-self-test-94121/baseline/test.log")
 :MUTANTS
 ((:NAME "signal-fixture" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9 :LOG
   #A((149) BASE-CHAR
      . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547222-worker-signal-self-test-94121/test.log")))
 :CURRENT-ORDINAL NIL :CURRENT-MUTANT NIL :CURRENT-LOG NIL :DIAGNOSTIC NIL
 :DETECTED 0 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0 :WORKER-ERRORS
 1 :LIMITS
 (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE :STRICT-COMPILATION
  :TEST-EVENTS-AT-LINE-START :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
  :NO-POOL-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))
