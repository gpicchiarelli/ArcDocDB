(:SCHEMA-VERSION 1 :KIND :ORIGINAL-COMMAND-ARCHIVE :METADATA-POLICY
 :READ-WITHOUT-RESULT-INFERENCE :PROCESSES
 ((:LABEL "preliminary" :RECORD-PATH "processes/preliminary/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((4) BASE-CHAR . "test")
    #A((4) BASE-CHAR . "lint") #A((11) BASE-CHAR . "trace-write")
    #A((5) BASE-CHAR . "trace")))
  (:LABEL "coverage-self" :RECORD-PATH "processes/coverage-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((30) BASE-CHAR . "tools/foundation-coverage.lisp")
    #A((11) BASE-CHAR . "--self-test")
    #A((38) BASE-CHAR . "spikes/out/cbor-minimal-coverage-self/")))
  (:LABEL "mutation-self" :RECORD-PATH "processes/mutation-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((11) BASE-CHAR . "--self-test")))
  (:LABEL "benchmark" :RECORD-PATH "processes/benchmark/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((29) BASE-CHAR . "tools/cbor-minimal-bench.lisp")
    #A((7) BASE-CHAR . "--bench")))
  (:LABEL "coverage" :RECORD-PATH "processes/coverage/report.lisp" :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((30) BASE-CHAR . "tools/foundation-coverage.lisp")
    #A((8) BASE-CHAR . "--report")
    #A((33) BASE-CHAR . "spikes/out/cbor-minimal-coverage/")
    #A((12) BASE-CHAR . "cbor-minimal")))
  (:LABEL "mutations" :RECORD-PATH "processes/mutations/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((34) BASE-CHAR . "spikes/out/cbor-minimal-mutations/")))
  (:LABEL "collection-guard-first" :RECORD-PATH
   "processes/collection-guard-first/report.lisp" :STATUS :FAILED :EXIT-CODE 1
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((45) BASE-CHAR . "spikes/out/cbor-minimal-collection/guard.lisp")
    #A((11) BASE-CHAR . "--self-test")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-collection/guard-run-01/")))
  (:LABEL "collection-guard" :RECORD-PATH
   "processes/collection-guard/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((45) BASE-CHAR . "spikes/out/cbor-minimal-collection/guard.lisp")
    #A((11) BASE-CHAR . "--self-test")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-collection/guard-run-02/"))))
 :FILES
 ((:PATH "collection-manifest.lisp" :SOURCE
   #A((110) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/manifest.lisp")
   :BYTES 5290 :SHA256
   "fefb48f8cb96dce604e3ce7b60c3f9bd57b264e6721d311f15d02c52c36e5abc")
  (:PATH "collection-source.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "processes/benchmark/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546877-command-79443-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "c29c328161c7614ceeb4aeb1beeb23957ea1d8f50f9749c094f0713467505a48")
  (:PATH "processes/benchmark/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546877-command-79443-0/report.lisp")
   :BYTES 119677 :SHA256
   "4e360510b7bc4c4740f53c091150d473667eb2f587a1e3ecae7dd73dfe065d65")
  (:PATH "processes/collection-guard-first/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547152-command-91683-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "18fe9a112e7d8977f5b2821a3d05208aaae6f0e1498673fc62d778a663c2ac78")
  (:PATH "processes/collection-guard-first/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547152-command-91683-0/report.lisp")
   :BYTES 96460 :SHA256
   "2d2b1c62a5e231429a6198a922761c54b9006bec5239935af997dfcd3852eeee")
  (:PATH "processes/collection-guard/conservazione.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547420-command-7798-0/conservazione.lisp")
   :BYTES 1142 :SHA256
   "ace0eff92a381acbe5ca8b9587a631f805e3c456989871b32c4b8141d86494bd")
  (:PATH "processes/collection-guard/report.lisp" :SOURCE
   #A((110) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000547420-command-7798-0/report.lisp")
   :BYTES 108382 :SHA256
   "0b89cb33a8538f0c6f526a6fd26b8c3a3ee8ab24d4a3d64365468cf23d87c3ea")
  (:PATH "processes/coverage-self/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546850-command-77762-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "957d0ed1debe17a4f8ac463f3510720a2f1b24ef097e2fc65c98338b502c6343")
  (:PATH "processes/coverage-self/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546850-command-77762-0/report.lisp")
   :BYTES 94426 :SHA256
   "1e006fbe642db39f84fcb7eb2ec91003bf3dd9e1ac0cd0fb5396a4071e41f646")
  (:PATH "processes/coverage/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546897-command-81110-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "2b3b1b85fad708ccc41c3c04e59184ba47562979fadede82591ba637816b9dad")
  (:PATH "processes/coverage/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546897-command-81110-0/report.lisp")
   :BYTES 95949 :SHA256
   "16183016c5d50b5ba3ca7f1f75fe0cc168fb08630df42f7597fbab8f2242bf66")
  (:PATH "processes/mutation-self/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546850-command-77763-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "2958ebe416ef5223e858025735ae2952a9df743119d1d1d35a1b64eb7e646a1e")
  (:PATH "processes/mutation-self/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546850-command-77763-0/report.lisp")
   :BYTES 121761 :SHA256
   "96d6270ddac230fad621097ed8fa28e84bd77650b342f3a12e23e6b7bdceba44")
  (:PATH "processes/mutations/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546897-command-81113-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "233c8d96eb7e3a0d3ba2ebb092873a8979f81aceacf943804fd7b84e42c4a824")
  (:PATH "processes/mutations/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546897-command-81113-0/report.lisp")
   :BYTES 124434 :SHA256
   "d8bda3b4eda61abe95e5208032da94332fa546b49ca4d6fd5fa0a4b4d20f8b9f")
  (:PATH "processes/preliminary/conservazione.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546808-command-75360-0/conservazione.lisp")
   :BYTES 1147 :SHA256
   "ecef31f628e0c99f5a1b23dcfc8e6ba1975d71c2b9c96cf2c55092349682dda7")
  (:PATH "processes/preliminary/report.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000546808-command-75360-0/report.lisp")
   :BYTES 194437 :SHA256
   "5a0cadba198daca82fa4351c2e07533ebb1d1b9c0cff9c4a664f0d545c010390")
  (:PATH "raw/cbor-minimal-collector-before-fix-reconstructed.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collector-before-fix-reconstructed.lisp")
   :BYTES 9652 :SHA256
   "dbfe80bc4ef909c0124617a40b056c243e1e2e793e07b4d2aad4cccb602c9811")
  (:PATH "raw/cbor-minimal-coverage-audit.lisp" :SOURCE
   #A((105) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-audit.lisp")
   :BYTES 7637 :SHA256
   "fbf96e998e47b0760f6a8020dfe9e88515c1f7213cfd2e204e3672de50530e37")
  (:PATH "raw/cbor-minimal-coverage-extract.lisp" :SOURCE
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-extract.lisp")
   :BYTES 3521 :SHA256
   "9a957df3dee86486c8f8e232953af4cb0577a67aed68754143c5071190d4725a")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-1.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-1.lisp")
   :BYTES 4666 :SHA256
   "f626b586d079c945f789206e0c71b4991b204a346aa08d67a2834bce2414a9e9")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-1.stderr.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-1.stdout.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-1.stdout.log")
   :BYTES 1643 :SHA256
   "94767298146daa342fb587f743fd484635e1b739a7ce9e3b21409835267f6617")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-2.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-2.lisp")
   :BYTES 16967 :SHA256
   "bd53cd38e89f196934c6e1a389c294ed8993fc261385b87e8d5195cb9964aa20")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-2.stderr.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-2.stdout.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-2.stdout.log")
   :BYTES 1725 :SHA256
   "b0fb332fdfa89d9b097b51411da2826b5f5a034d657262087ac0992cae0f99f1")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-3.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-3.lisp")
   :BYTES 18054 :SHA256
   "4dfff00959c43c1fc600f7d56f6a173021ee7997c9e259f607afe55e0e976529")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-3.stderr.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-3.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-coverage-reader-attempt-3.stdout.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader-attempt-3.stdout.log")
   :BYTES 1725 :SHA256
   "b0fb332fdfa89d9b097b51411da2826b5f5a034d657262087ac0992cae0f99f1")
  (:PATH "raw/cbor-minimal-coverage-reader.lisp" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage-reader.lisp")
   :BYTES 18054 :SHA256
   "4dfff00959c43c1fc600f7d56f6a173021ee7997c9e259f607afe55e0e976529")
  (:PATH "raw/cbor-minimal-finding-provenance.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-finding-provenance.lisp")
   :BYTES 569 :SHA256
   "90553bc3b632881fe1a6e9af01a1ad5f4dd84358167907902b062df8ec979bb9")
  (:PATH "raw/cbor-minimal-independent-review.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-independent-review.lisp")
   :BYTES 4848 :SHA256
   "12a0bbcf259b209b8b7efd05c7a0b90492098040eab122e195940a5ea148ffeb")
  (:PATH "raw/cbor-minimal-measurement-audit.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-measurement-audit.lisp")
   :BYTES 59817 :SHA256
   "d92b322a637e55c19f510312ff23dcb6709df7247cfc7b2479a006345a361db6")
  (:PATH "raw/cbor-minimal-measurement-inspect.lisp" :SOURCE
   #A((50) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-inspect.lisp")
   :BYTES 1434 :SHA256
   "ab30adbf1b2c67bef29c2e23a55fc22651b41534e946d3b5156814e68f1a5a86")
  (:PATH "raw/cbor-minimal-measurement-inspect.log" :SOURCE
   #A((49) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-inspect.log")
   :BYTES 15074 :SHA256
   "f2a54a0706b26d6961d8bcaf6c42fb2a3c0ed34d7f335e225067c74651ec8e0b")
  (:PATH "raw/cbor-minimal-measurement-reader-first.lisp" :SOURCE
   #A((55) BASE-CHAR
      . "/private/tmp/cbor-minimal-measurement-reader-first.lisp")
   :BYTES 20500 :SHA256
   "4f408c3051b905c847c7d5926533e12b566d99dfac247da2a60e1acfc17cb736")
  (:PATH "raw/cbor-minimal-measurement-reader-first.log" :SOURCE
   #A((54) BASE-CHAR
      . "/private/tmp/cbor-minimal-measurement-reader-first.log")
   :BYTES 1366 :SHA256
   "78df7be60cfe28c324729015a8ad1cea9afd754c4edd486ad0159747cb791c9f")
  (:PATH "raw/cbor-minimal-measurement-reader-run.lisp" :SOURCE
   #A((53) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader-run.lisp")
   :BYTES 192 :SHA256
   "a24e81921db1d9ed83dd4639f6995af99f5c1b23ed9a5d458977b5cb1a15763e")
  (:PATH "raw/cbor-minimal-measurement-reader-v2.lisp" :SOURCE
   #A((52) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader-v2.lisp")
   :BYTES 21383 :SHA256
   "8f4a14791a3c0dbf4b5faae3f62815b5b659886c6344dfa6d63ae3c83f5fc051")
  (:PATH "raw/cbor-minimal-measurement-reader-v2.log" :SOURCE
   #A((51) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader-v2.log")
   :BYTES 28083 :SHA256
   "9fc4853e4532b6c2009bb1ff717adfe7ce1dc07a4711fa6cfb23d1915b1d7fc4")
  (:PATH "raw/cbor-minimal-measurement-reader-v3.log" :SOURCE
   #A((51) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader-v3.log")
   :BYTES 70 :SHA256
   "0e60ff5ea4a669963b22ef3126d87536b62f1d77fb62114673ccda5c54c58d1d")
  (:PATH "raw/cbor-minimal-measurement-reader.lisp" :SOURCE
   #A((49) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader.lisp")
   :BYTES 22292 :SHA256
   "d9b5d9385969e95958f38dd00f080821869bba3473be311216927c681425f817")
  (:PATH "raw/cbor-minimal-measurement-reader.log" :SOURCE
   #A((48) BASE-CHAR . "/private/tmp/cbor-minimal-measurement-reader.log")
   :BYTES 1366 :SHA256
   "78df7be60cfe28c324729015a8ad1cea9afd754c4edd486ad0159747cb791c9f")
  (:PATH "raw/cbor-minimal-root-review.lisp" :SOURCE
   #A((102) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-root-review.lisp")
   :BYTES 1503 :SHA256
   "95c87767c9a8d853b87b6e00a7211e55175d3ebaa91e5351a3916290857d23c7")
  (:PATH "raw/cbor-minimal-tools-review.lisp" :SOURCE
   #A((103) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-tools-review.lisp")
   :BYTES 3188 :SHA256
   "b39cc710eb465b12b948fe42ecdd1a27684cef7f172d38076c9742182fb5cc1e")
  (:PATH "raw/collection-tools/collect.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "raw/collection-tools/guard-run-01-harness-attribution.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01-harness-attribution.lisp")
   :BYTES 1280 :SHA256
   "c2a35b7a23981c49cecc2c2e5bef15aeebedf66d3bf6425bf4e6f3f719db3439")
  (:PATH "raw/collection-tools/guard-run-01/archive-corrupt/archive-index.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/archive-index.lisp")
   :BYTES 4901 :SHA256
   "ddd8a8efa74618b63c6460b72b598c70cf8ce3db7af54a6954d172f9bedc48c4")
  (:PATH "raw/collection-tools/guard-run-01/archive-corrupt/catalogo.lisp"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/catalogo.lisp")
   :BYTES 407 :SHA256
   "7b191fb1badf7316c7ed400828f313ebc997b766c7f3dda6f6bd8c6bc58000a6")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/collection-manifest.lisp"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "e9ff8f19dd34cfe42d0d1bf71b496a08e4a6197ce71e86942014d2927541d165")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/collection-source.lisp"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/compressed/original.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/compressed/raw.log"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/compressed/report.lisp"
   :SOURCE
   #A((158) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((161) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/plain/extra.txt"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/plain/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/processes/plain/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-01/archive-corrupt/raw/extra.bin"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/raw/gzip-tree/raw.log"
   :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-corrupt/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-corrupt/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "0f72cecbbb4e2a4262b19be49f417a306cfa07a894332e56c1fd695b7fc17fea")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/compressed/original.lisp"
   :SOURCE
   #A((162) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/compressed/raw.log"
   :SOURCE
   #A((156) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/compressed/report.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((163) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/plain/extra.txt"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/plain/raw.log"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/processes/plain/report.lisp"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-01/archive-duplicate/raw/extra.bin"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/raw/gzip-tree/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-duplicate/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((156) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-duplicate/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-01/archive-missing/archive-index.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/archive-index.lisp")
   :BYTES 4901 :SHA256
   "ddd8a8efa74618b63c6460b72b598c70cf8ce3db7af54a6954d172f9bedc48c4")
  (:PATH "raw/collection-tools/guard-run-01/archive-missing/catalogo.lisp"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/catalogo.lisp")
   :BYTES 407 :SHA256
   "7b191fb1badf7316c7ed400828f313ebc997b766c7f3dda6f6bd8c6bc58000a6")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/collection-manifest.lisp"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "e9ff8f19dd34cfe42d0d1bf71b496a08e4a6197ce71e86942014d2927541d165")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/collection-source.lisp"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/compressed/original.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/compressed/raw.log"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/compressed/report.lisp"
   :SOURCE
   #A((158) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/compressed/report.lisp.gz.missing"
   :SOURCE
   #A((169) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/compressed/report.lisp.gz.missing")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/plain/extra.txt"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/plain/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/processes/plain/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-01/archive-missing/raw/extra.bin"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/raw/gzip-tree/raw.log"
   :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-missing/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-missing/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/archive-index.lisp"
   :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/archive-index.lisp")
   :BYTES 4901 :SHA256
   "ddd8a8efa74618b63c6460b72b598c70cf8ce3db7af54a6954d172f9bedc48c4")
  (:PATH "raw/collection-tools/guard-run-01/archive-positive/catalogo.lisp"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/catalogo.lisp")
   :BYTES 407 :SHA256
   "7b191fb1badf7316c7ed400828f313ebc997b766c7f3dda6f6bd8c6bc58000a6")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/collection-manifest.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "e9ff8f19dd34cfe42d0d1bf71b496a08e4a6197ce71e86942014d2927541d165")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/collection-source.lisp"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/compressed/original.lisp"
   :SOURCE
   #A((161) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/compressed/raw.log"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/compressed/report.lisp"
   :SOURCE
   #A((159) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((162) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/plain/extra.txt"
   :SOURCE
   #A((152) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/plain/raw.log"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/processes/plain/report.lisp"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-01/archive-positive/raw/extra.bin"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/raw/gzip-tree/raw.log"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((152) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-01/archive-positive/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/archive-positive/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-01/duplicate-manifest.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/duplicate-manifest.lisp")
   :BYTES 971 :SHA256
   "a33cc9796c7f34017bfce935a555287599b58c2cfda07d6b5662889941907246")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/compressed/original.lisp"
   :SOURCE
   #A((143) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/compressed/raw.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/compressed/report.lisp"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/compressed/report.lisp.gz"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/extra.bin" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/plain/extra.txt" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/plain/raw.log" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/plain/report.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/tree/excluded.txt" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/tree/excluded.txt")
   :BYTES 30 :SHA256
   "31f60e65170ce00c01830f8a1dd381f038def3172731267a615eb1279f5e5ce4")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/tree/original.lisp"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/tree/raw.log" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/tree/report.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH "raw/collection-tools/guard-run-01/fixtures/tree/report.lisp.gz"
   :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/fixtures/tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-01/logs/audit-positive.stderr.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/audit-positive.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/audit-positive.stdout.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/audit-positive.stdout.log")
   :BYTES 58 :SHA256
   "4b218b480bdf89b8abc314d4599b7bd66d673a9e358b1fe367d1fdb6bf16ef3b")
  (:PATH "raw/collection-tools/guard-run-01/logs/collect-positive.stderr.log"
   :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/collect-positive.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/collect-positive.stdout.log"
   :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/collect-positive.stdout.log")
   :BYTES 52 :SHA256
   "bf1f77d6c72e040498075234b8ddb091ffd2a39e3c6336c82c327c2a88d9c803")
  (:PATH "raw/collection-tools/guard-run-01/logs/corrupted-raw.stderr.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/corrupted-raw.stderr.log")
   :BYTES 6058 :SHA256
   "817e6c616236c06b436a4a15fa2486bcec14939a0d2e446b6b512edb589f74c7")
  (:PATH "raw/collection-tools/guard-run-01/logs/corrupted-raw.stdout.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/corrupted-raw.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/duplicate-path.stderr.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/duplicate-path.stderr.log")
   :BYTES 6876 :SHA256
   "7c95c6a261fd378a4757390995b374abc5e653d35b576ef85ce27280299b8290")
  (:PATH "raw/collection-tools/guard-run-01/logs/duplicate-path.stdout.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/duplicate-path.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/existing-target.stderr.log"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/existing-target.stderr.log")
   :BYTES 6385 :SHA256
   "268654ebc6c7158d11f5c325d6d31a101c8a37c5cf238da64e05d34a97b7c0e5")
  (:PATH "raw/collection-tools/guard-run-01/logs/existing-target.stdout.log"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/existing-target.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/gzip-process.stderr.log"
   :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/gzip-process.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/gzip-tree.stderr.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/gzip-tree.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/missing-raw.stderr.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/missing-raw.stderr.log")
   :BYTES 7512 :SHA256
   "f5bcf959ac33bda4f7938cb5601d9fb2384f2d1209d2eb321dcf5d254e9821e2")
  (:PATH "raw/collection-tools/guard-run-01/logs/missing-raw.stdout.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/missing-raw.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/reader-eval.stderr.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/reader-eval.stderr.log")
   :BYTES 8318 :SHA256
   "0db0cf6b8ddf5df177a2549b56dfc9e991b8dfc34c8f5e5a0b959101b338ef18")
  (:PATH "raw/collection-tools/guard-run-01/logs/reader-eval.stdout.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/reader-eval.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/logs/trailing-form.stderr.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/trailing-form.stderr.log")
   :BYTES 6592 :SHA256
   "114721890ad439e37898636a72ae7c34bb40f9f590803e2ead29596f3a0b4da8")
  (:PATH "raw/collection-tools/guard-run-01/logs/trailing-form.stdout.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/logs/trailing-form.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-01/manifest.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/manifest.lisp")
   :BYTES 793 :SHA256
   "e9ff8f19dd34cfe42d0d1bf71b496a08e4a6197ce71e86942014d2927541d165")
  (:PATH "raw/collection-tools/guard-run-01/reader-eval-manifest.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/reader-eval-manifest.lisp")
   :BYTES 4254 :SHA256
   "f90656c367a2d1a1659b1a9c44cb188a3ba328363bbe59f907a39b5cdf1564bf")
  (:PATH "raw/collection-tools/guard-run-01/report.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/report.lisp")
   :BYTES 1968 :SHA256
   "c81adc1c093e9001c5002ee48c090c90671d584a716cec16920d5646bd37f53c")
  (:PATH "raw/collection-tools/guard-run-01/trailing-manifest.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-01/trailing-manifest.lisp")
   :BYTES 821 :SHA256
   "b09e730d7ec1418e295222feaf7edeea0597c894ad58cba7b3a6cc77e89abde4")
  (:PATH "raw/collection-tools/guard-run-02/archive-corrupt/archive-index.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/archive-index.lisp")
   :BYTES 4901 :SHA256
   "4fc6e411d2b5602c96b1227bbf2cd1e2ad1f4396393ec11ca4068d6e4c0f5cb4")
  (:PATH "raw/collection-tools/guard-run-02/archive-corrupt/catalogo.lisp"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/catalogo.lisp")
   :BYTES 407 :SHA256
   "0e764c5441bbd09b7efaff0f743bbb570d46b525cdedff15436e3511ae342ec3")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/collection-manifest.lisp"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "4e6688a4854d8c5cda540048595d9099c37f82280239eaa3b911fa7d8120271f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/collection-source.lisp"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/compressed/original.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/compressed/raw.log"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/compressed/report.lisp"
   :SOURCE
   #A((158) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((161) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/plain/extra.txt"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/plain/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/processes/plain/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-02/archive-corrupt/raw/extra.bin"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/raw/gzip-tree/raw.log"
   :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-corrupt/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "0f72cecbbb4e2a4262b19be49f417a306cfa07a894332e56c1fd695b7fc17fea")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/compressed/original.lisp"
   :SOURCE
   #A((162) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/compressed/raw.log"
   :SOURCE
   #A((156) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/compressed/report.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((163) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/plain/extra.txt"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/plain/raw.log"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/processes/plain/report.lisp"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-02/archive-duplicate/raw/extra.bin"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/raw/gzip-tree/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-duplicate/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((156) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-02/archive-missing/archive-index.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/archive-index.lisp")
   :BYTES 4901 :SHA256
   "4fc6e411d2b5602c96b1227bbf2cd1e2ad1f4396393ec11ca4068d6e4c0f5cb4")
  (:PATH "raw/collection-tools/guard-run-02/archive-missing/catalogo.lisp"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/catalogo.lisp")
   :BYTES 407 :SHA256
   "0e764c5441bbd09b7efaff0f743bbb570d46b525cdedff15436e3511ae342ec3")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/collection-manifest.lisp"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "4e6688a4854d8c5cda540048595d9099c37f82280239eaa3b911fa7d8120271f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/collection-source.lisp"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/compressed/original.lisp"
   :SOURCE
   #A((160) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/compressed/raw.log"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/compressed/report.lisp"
   :SOURCE
   #A((158) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/compressed/report.lisp.gz.missing"
   :SOURCE
   #A((169) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/compressed/report.lisp.gz.missing")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/plain/extra.txt"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/plain/raw.log"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/processes/plain/report.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-02/archive-missing/raw/extra.bin"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/raw/gzip-tree/raw.log"
   :SOURCE
   #A((147) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-missing/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/archive-index.lisp"
   :SOURCE
   #A((145) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/archive-index.lisp")
   :BYTES 4901 :SHA256
   "4fc6e411d2b5602c96b1227bbf2cd1e2ad1f4396393ec11ca4068d6e4c0f5cb4")
  (:PATH "raw/collection-tools/guard-run-02/archive-positive/catalogo.lisp"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/catalogo.lisp")
   :BYTES 407 :SHA256
   "0e764c5441bbd09b7efaff0f743bbb570d46b525cdedff15436e3511ae342ec3")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/collection-manifest.lisp"
   :SOURCE
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/collection-manifest.lisp")
   :BYTES 793 :SHA256
   "4e6688a4854d8c5cda540048595d9099c37f82280239eaa3b911fa7d8120271f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/collection-source.lisp"
   :SOURCE
   #A((149) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/collection-source.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/compressed/original.lisp"
   :SOURCE
   #A((161) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/compressed/raw.log"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/compressed/report.lisp"
   :SOURCE
   #A((159) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/compressed/report.lisp.gz"
   :SOURCE
   #A((162) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/plain/extra.txt"
   :SOURCE
   #A((152) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/plain/raw.log"
   :SOURCE
   #A((150) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/processes/plain/report.lisp"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/processes/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-02/archive-positive/raw/extra.bin"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/raw/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/raw/gzip-tree/original.lisp"
   :SOURCE
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/raw/gzip-tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/raw/gzip-tree/raw.log"
   :SOURCE
   #A((148) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/raw/gzip-tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/raw/gzip-tree/report.lisp"
   :SOURCE
   #A((152) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/raw/gzip-tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH
   "raw/collection-tools/guard-run-02/archive-positive/raw/gzip-tree/report.lisp.gz"
   :SOURCE
   #A((155) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/raw/gzip-tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-02/duplicate-manifest.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/duplicate-manifest.lisp")
   :BYTES 971 :SHA256
   "8fbd095d875aba2be06a4cc6e7b903fc1f6b33ee7778289b06c259055a41bece")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/compressed/original.lisp"
   :SOURCE
   #A((143) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/compressed/raw.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/compressed/report.lisp"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/compressed/report.lisp.gz"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/extra.bin" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/plain/extra.txt" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/plain/raw.log" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/plain/report.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/tree/excluded.txt" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/excluded.txt")
   :BYTES 30 :SHA256
   "31f60e65170ce00c01830f8a1dd381f038def3172731267a615eb1279f5e5ce4")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/tree/original.lisp"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/tree/raw.log" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/tree/report.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH "raw/collection-tools/guard-run-02/fixtures/tree/report.lisp.gz"
   :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d")
  (:PATH "raw/collection-tools/guard-run-02/logs/audit-positive.stderr.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/audit-positive.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/audit-positive.stdout.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/audit-positive.stdout.log")
   :BYTES 58 :SHA256
   "4b218b480bdf89b8abc314d4599b7bd66d673a9e358b1fe367d1fdb6bf16ef3b")
  (:PATH "raw/collection-tools/guard-run-02/logs/collect-positive.stderr.log"
   :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/collect-positive.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/collect-positive.stdout.log"
   :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/collect-positive.stdout.log")
   :BYTES 52 :SHA256
   "bf1f77d6c72e040498075234b8ddb091ffd2a39e3c6336c82c327c2a88d9c803")
  (:PATH "raw/collection-tools/guard-run-02/logs/corrupted-raw.stderr.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/corrupted-raw.stderr.log")
   :BYTES 6058 :SHA256
   "394c3446087ecdf7df638f3ede46f2a46a8a0d46d7438f2f98d8f54804454468")
  (:PATH "raw/collection-tools/guard-run-02/logs/corrupted-raw.stdout.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/corrupted-raw.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/duplicate-path.stderr.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/duplicate-path.stderr.log")
   :BYTES 6876 :SHA256
   "8a51edc67fee575d237f917e9ad6e507f0c63c9f3b927b6f4a1c57eef2625d88")
  (:PATH "raw/collection-tools/guard-run-02/logs/duplicate-path.stdout.log"
   :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/duplicate-path.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/existing-target.stderr.log"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/existing-target.stderr.log")
   :BYTES 6385 :SHA256
   "33649b8383b2e18c8a49fe78ed9f2e5f472e321d3b45c17e61d26d8076dc1368")
  (:PATH "raw/collection-tools/guard-run-02/logs/existing-target.stdout.log"
   :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/existing-target.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/gzip-process.stderr.log"
   :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/gzip-process.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/gzip-tree.stderr.log" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/gzip-tree.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/missing-raw.stderr.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/missing-raw.stderr.log")
   :BYTES 7512 :SHA256
   "c4656d5a13de5fcd3b6e9859491275ba9dbbe239304fe63bd2a42c9d8338e123")
  (:PATH "raw/collection-tools/guard-run-02/logs/missing-raw.stdout.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/missing-raw.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/reader-eval.stderr.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/reader-eval.stderr.log")
   :BYTES 8318 :SHA256
   "8e41d8657056fecea75b6710a2e1c0c53dfdf764fe4c5b092f6c456f4058d702")
  (:PATH "raw/collection-tools/guard-run-02/logs/reader-eval.stdout.log"
   :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/reader-eval.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/logs/trailing-form.stderr.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/trailing-form.stderr.log")
   :BYTES 6592 :SHA256
   "422c4b5bf58abbc1542afe3f3b4581add387dbafefb2096857c5a80ecf4531f3")
  (:PATH "raw/collection-tools/guard-run-02/logs/trailing-form.stdout.log"
   :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/trailing-form.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/collection-tools/guard-run-02/manifest.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/manifest.lisp")
   :BYTES 793 :SHA256
   "4e6688a4854d8c5cda540048595d9099c37f82280239eaa3b911fa7d8120271f")
  (:PATH "raw/collection-tools/guard-run-02/reader-eval-manifest.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/reader-eval-manifest.lisp")
   :BYTES 4254 :SHA256
   "8db2e52152d0218ba158a15192a595bb9f6dc663e7ae0a4968eb2750e598fda4")
  (:PATH "raw/collection-tools/guard-run-02/report.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/report.lisp")
   :BYTES 13371 :SHA256
   "4a1283a0cac558562fdb42ac228bf0bb615ef36a9a139c9ba137a6045be58df9")
  (:PATH "raw/collection-tools/guard-run-02/trailing-manifest.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/trailing-manifest.lisp")
   :BYTES 821 :SHA256
   "f0e01b129993c0db7d2df08a7db4f3df0b58447c106377684209d2ce0fc9cdbd")
  (:PATH "raw/collection-tools/guard-v1-report-plist.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-v1-report-plist.lisp")
   :BYTES 22168 :SHA256
   "d092bdcd4cc1b9aeeb63a050af5c45ad4944ade79879d0fcc533fd62046ef729")
  (:PATH "raw/collection-tools/guard.lisp" :SOURCE
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard.lisp")
   :BYTES 22280 :SHA256
   "d12bcd9cae36a02068be3519ecc53ad5007e3159305effa7d258fce58a487494")
  (:PATH "raw/collection-tools/manifest.lisp" :SOURCE
   #A((110) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/manifest.lisp")
   :BYTES 5290 :SHA256
   "fefb48f8cb96dce604e3ce7b60c3f9bd57b264e6721d311f15d02c52c36e5abc")
  (:PATH "raw/collection-tools/preserve-finding.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/preserve-finding.lisp")
   :BYTES 1929 :SHA256
   "f23293f221718e6c2e51fdb9a6ac5e6187b789f7153db3653975bd089666242e")
  (:PATH "raw/collection-tools/root-review.lisp" :SOURCE
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/root-review.lisp")
   :BYTES 2176 :SHA256
   "be6dd6eff7e5a4847d02127c5d3661bfc69afe9c9906385601499056dd673f43")
  (:PATH "raw/collection-tools/write-manifest.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/write-manifest.lisp")
   :BYTES 2916 :SHA256
   "498f3fb16cea72bd36b70191b8f2a06cedcd1ec8879183fcd166683664d5a8e8")
  (:PATH "raw/coverage/4aa7a033acb28fa71977ad7f38fd6e95.html" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage/4aa7a033acb28fa71977ad7f38fd6e95.html")
   :BYTES 23321 :SHA256
   "7c6a521772debcc08875bd202d1fa051513e02d1ad79fb604e0187368442eb03")
  (:PATH "raw/coverage/b5f35c3f3adc77420ac318a47cebed2c.html" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage/b5f35c3f3adc77420ac318a47cebed2c.html")
   :BYTES 25895 :SHA256
   "85edf120bc3585793236436811dc2933a9f63654351a6b0bd4299d7939996e16")
  (:PATH "raw/coverage/cover-index.html" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage/cover-index.html")
   :BYTES 1951 :SHA256
   "10a63ac31a474e272e8c79e2ebc79e084633ce86edb8532c2b924e96be3383ac")
  (:PATH "raw/coverage/coverage-state.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-coverage/coverage-state.lisp")
   :BYTES 843318 :SHA256
   "732d2a2783c132ef0174b15c9a6a37e2a21ff771ff8819343c0f34c4dc98648f")
  (:PATH "raw/mutations/0/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db")
  (:PATH "raw/mutations/0/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/0/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "0ca186cfdc54bef959924544412cc32a4b3f6600936326778022b9cf6deb6c85")
  (:PATH "raw/mutations/0/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/0/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/0/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/0/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/0/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/0/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/0/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/0/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/0/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/0/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/0/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/0/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/0/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/0/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/0/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/0/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/0/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/0/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/0/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/0/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/0/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/0/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/0/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/0/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/0/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/0/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/0/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/0/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/0/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/0/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/0/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/0/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/0/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/0/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/0/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/0/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/0/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/0/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/0/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/0/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/0/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/0/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/0/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/0/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/0/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/0/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/0/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/0/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/0/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/0/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/0/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/0/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/0/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/0/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/0/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/0/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/0/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/0/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/0/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/test.log")
   :BYTES 14338 :SHA256
   "cab06a970030ea053b17ff06c6b21ecf7cdb7bc980d8e91fe94db8967a992510")
  (:PATH "raw/mutations/0/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/0/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/0/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/0/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/0/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/0/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/0/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/0/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/0/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/0/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/0/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/0/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/0/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/0/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/0/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/0/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/0/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/0/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/0/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/0/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/0/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/0/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/0/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/0/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/0/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/0/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/0/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/0/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/0/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/0/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/0/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/0/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/0/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/0/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/0/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/0/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/0/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/0/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/0/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/0/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/0/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/0/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/0/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/0/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/0/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/0/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/0/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/0/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/0/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/0/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/0/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/0/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/0/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/0/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/0/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/0/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/0/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "a2a95b47792bb697dca7a470437e671d3662a672848ae1d5899c24b49f302f99")
  (:PATH "raw/mutations/1/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db")
  (:PATH "raw/mutations/1/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/1/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "4ff0856da669433dc48f2230d489051dbec19cf34bf73d3506833f5e59622bd2")
  (:PATH "raw/mutations/1/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/1/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/1/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/1/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/1/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/1/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/1/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/1/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/1/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/1/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/1/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/1/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/1/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/1/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/1/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/1/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/1/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/1/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/1/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/1/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/1/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/1/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/1/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/1/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/1/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/1/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/1/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/1/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/1/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/1/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/1/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/1/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/1/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/1/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/1/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/1/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/1/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/1/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/1/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/1/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/1/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/1/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/1/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/1/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/1/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/1/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/1/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/1/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/1/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/1/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/1/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/1/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/1/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/1/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/1/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/1/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/1/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/1/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/1/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/test.log")
   :BYTES 14342 :SHA256
   "9b4efc6d8db00549684add54cb3c58ee30e2eee8dc999992520454847dc4c4ee")
  (:PATH "raw/mutations/1/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/1/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/1/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/1/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/1/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/1/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/1/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/1/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/1/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/1/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/1/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/1/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/1/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/1/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/1/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/1/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/1/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/1/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/1/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/1/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/1/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/1/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/1/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/1/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/1/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/1/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/1/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/1/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/1/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/1/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/1/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/1/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/1/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/1/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/1/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/1/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/1/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/1/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/1/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/1/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/1/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/1/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/1/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/1/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/1/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/1/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/1/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/1/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/1/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/1/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/1/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/1/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/1/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/1/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/1/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/1/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/1/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "bdc2e95bd6a9293c7bddf03c9fd565b1296fb163f1234beea027451ac3ab3d98")
  (:PATH "raw/mutations/2/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db")
  (:PATH "raw/mutations/2/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/2/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "80818a629ab6359fe03b2e01a4bea93881f80379cc971dc68afb56434526b834")
  (:PATH "raw/mutations/2/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/2/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/2/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/2/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/2/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/2/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/2/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/2/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/2/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/2/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/2/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/2/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/2/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/2/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/2/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/2/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/2/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/2/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/2/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/2/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/2/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/2/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/2/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/2/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/2/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/2/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/2/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/2/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/2/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/2/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/2/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/2/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/2/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/2/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/2/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/2/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/2/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/2/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/2/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/2/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/2/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/2/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/2/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/2/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/2/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/2/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/2/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/2/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/2/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/2/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/2/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/2/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/2/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/2/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/2/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/2/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/2/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/2/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/2/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/test.log")
   :BYTES 14336 :SHA256
   "f6180df2a38dcc1225a4d6acbba386c6400e4faaaf17d6acbe01df35f3026be7")
  (:PATH "raw/mutations/2/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/2/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/2/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/2/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/2/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/2/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/2/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/2/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/2/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/2/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/2/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/2/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/2/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/2/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/2/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/2/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/2/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/2/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/2/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/2/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/2/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/2/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/2/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/2/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/2/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/2/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/2/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/2/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/2/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/2/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/2/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/2/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/2/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/2/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/2/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/2/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/2/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/2/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/2/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/2/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/2/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/2/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/2/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/2/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/2/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/2/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/2/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/2/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/2/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/2/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/2/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/2/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/2/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/2/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/2/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/2/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/2/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "3b8fe04e8da993f37ef7afa7e998839eaf8568cc3d745893a42375adc913953b")
  (:PATH "raw/mutations/3/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db")
  (:PATH "raw/mutations/3/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/3/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-minimal.lisp")
   :BYTES 3591 :SHA256
   "6ef78bcd3c3384c1cc3cf96d76e9dba770b77d8ef727b5fd7aefe60ee441f5b8")
  (:PATH "raw/mutations/3/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/3/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/3/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/3/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/3/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/3/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/3/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/3/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/3/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/3/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/3/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/3/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/3/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/3/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/3/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/3/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/3/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/3/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/3/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/3/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/3/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/3/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/3/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/3/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/3/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/3/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/3/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/3/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/3/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/3/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/3/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/3/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/3/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/3/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/3/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/3/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/3/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/3/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/3/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/3/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/3/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/3/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/3/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/3/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/3/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/3/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/3/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/3/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/3/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/3/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/3/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/3/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/3/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/3/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/3/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/3/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/3/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/3/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/3/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/test.log")
   :BYTES 14222 :SHA256
   "fa4717dca6e0515c7e4aa03a2c9b6bc4837ef5f158d3146021d2209d070cabce")
  (:PATH "raw/mutations/3/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/3/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/3/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/3/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/3/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/3/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/3/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/3/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/3/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/3/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/3/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/3/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/3/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/3/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/3/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/3/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/3/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/3/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/3/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/3/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/3/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/3/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/3/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/3/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/3/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/3/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/3/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/3/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/3/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/3/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/3/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/3/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/3/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/3/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/3/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/3/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/3/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/3/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/3/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/3/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/3/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/3/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/3/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/3/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/3/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/3/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/3/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/3/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/3/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/3/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/3/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/3/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/3/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/3/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/3/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/3/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "bd792f0c903833555109d6e946096b10c713a7997d67d1ff10090759ec273523")
  (:PATH "raw/mutations/4/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "a677621050d50eb533bc1d37961c1879666d18af3b54cdb6158279e26e01b0dd")
  (:PATH "raw/mutations/4/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/4/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449")
  (:PATH "raw/mutations/4/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/4/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/4/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/4/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/4/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/4/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/4/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/4/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/4/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/4/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/4/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/4/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/4/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/4/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/4/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/4/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/4/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/4/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/4/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/4/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/4/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/4/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/4/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/4/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/4/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/4/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/4/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/4/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/4/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/4/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/4/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/4/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/4/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/4/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/4/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/4/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/4/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/4/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/4/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/4/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/4/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/4/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/4/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/4/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/4/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/4/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/4/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/4/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/4/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/4/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/4/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/4/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/4/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/4/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/4/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/4/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/4/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/4/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/4/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/test.log")
   :BYTES 14264 :SHA256
   "3b5d52e745bbaf6452e34cc29cc15866d6d284b356d5fc0f927dde543878c54e")
  (:PATH "raw/mutations/4/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/4/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/4/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/4/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/4/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/4/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/4/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/4/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/4/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/4/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/4/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/4/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/4/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/4/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/4/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/4/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/4/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/4/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/4/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/4/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/4/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/4/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/4/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/4/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/4/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/4/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/4/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/4/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/4/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/4/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/4/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/4/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/4/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/4/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/4/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/4/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/4/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/4/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/4/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/4/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/4/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/4/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/4/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/4/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/4/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/4/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/4/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/4/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/4/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/4/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/4/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/4/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/4/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/4/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/4/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/4/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/4/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "31bc1b63a04de84559b48c2360c6806f1c9d20a11ce228dbc66e67e82437210a")
  (:PATH "raw/mutations/5/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "1921aebd2c70a562720b6946ec084342fc0a28494d4337e44d0d551ae4b2ac11")
  (:PATH "raw/mutations/5/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/5/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449")
  (:PATH "raw/mutations/5/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/5/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/5/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/5/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/5/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/5/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/5/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/5/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/5/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/5/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/5/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/5/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/5/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/5/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/5/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/5/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/5/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/5/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/5/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/5/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/5/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/5/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/5/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/5/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/5/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/5/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/5/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/5/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/5/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/5/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/5/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/5/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/5/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/5/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/5/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/5/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/5/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/5/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/5/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/5/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/5/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/5/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/5/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/5/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/5/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/5/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/5/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/5/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/5/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/5/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/5/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/5/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/5/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/5/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/5/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/5/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/5/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/5/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/5/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/test.log")
   :BYTES 14266 :SHA256
   "ef7e1df5f89098ec3c7854d663ea0a0603a5d2d94f4536d6297dd8da06e0143c")
  (:PATH "raw/mutations/5/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/5/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/5/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/5/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/5/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/5/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/5/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/5/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/5/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/5/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/5/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/5/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/5/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/5/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/5/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/5/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/5/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/5/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/5/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/5/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/5/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/5/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/5/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/5/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/5/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/5/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/5/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/5/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/5/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/5/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/5/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/5/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/5/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/5/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/5/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/5/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/5/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/5/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/5/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/5/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/5/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/5/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/5/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/5/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/5/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/5/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/5/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/5/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/5/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/5/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/5/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/5/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/5/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/5/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/5/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/5/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/5/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "d0f43508c2dcc5bd51b838efc44eac08024919f17bede9f25a22b60dd2dc6e9e")
  (:PATH "raw/mutations/6/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "b620edc2c8eb51330a9a065a4ad4f365d60626492a85c56cd5266b0593056e48")
  (:PATH "raw/mutations/6/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/6/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449")
  (:PATH "raw/mutations/6/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/6/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/6/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/6/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/6/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/6/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/6/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/6/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/6/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/6/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/6/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/6/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/6/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/6/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/6/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/6/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/6/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/6/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/6/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/6/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/6/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/6/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/6/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/6/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/6/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/6/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/6/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/6/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/6/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/6/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/6/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/6/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/6/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/6/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/6/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/6/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/6/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/6/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/6/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/6/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/6/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/6/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/6/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/6/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/6/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/6/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/6/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/6/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/6/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/6/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/6/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/6/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/6/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/6/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/6/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/6/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/6/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/6/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/6/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/test.log")
   :BYTES 14263 :SHA256
   "d689db88fa88c185ad44fffe2fa02eda3b5cbdfc6e4a088973d32fcaad72f436")
  (:PATH "raw/mutations/6/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/6/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/6/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/6/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/6/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/6/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/6/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/6/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/6/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/6/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/6/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/6/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/6/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/6/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/6/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/6/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/6/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/6/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/6/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/6/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/6/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/6/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/6/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/6/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/6/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/6/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/6/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/6/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/6/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/6/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/6/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/6/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/6/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/6/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/6/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/6/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/6/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/6/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/6/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/6/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/6/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/6/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/6/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/6/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/6/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/6/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/6/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/6/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/6/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/6/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/6/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/6/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/6/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/6/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/6/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/6/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/6/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "18af95704a639667363b5f8911bd49587b522b65b2fa7c6f5f12079ba30ba926")
  (:PATH "raw/mutations/7/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "7a60d3c8ad7e4c20312546693bd20f6dcdb70bdd7c6dc7061b2d45e02a90cfd3")
  (:PATH "raw/mutations/7/src/codec/cbor-header.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/7/src/codec/cbor-minimal.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449")
  (:PATH "raw/mutations/7/src/codec/cbor-package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/7/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/7/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/7/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/7/src/codec/cbor-scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/7/src/codec/cbor-space.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/7/src/codec/package.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/7/src/codec/utf8.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/7/src/csn/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/7/src/csn/registry.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/7/src/execution/handoff.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/7/src/execution/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/7/src/execution/queue.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/7/src/execution/ready-recycle.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/7/src/execution/ready-types.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/7/src/execution/ready.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/7/src/execution/writer.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/7/src/foundation/batch.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/7/src/foundation/binary.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/7/src/foundation/conditions.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/7/src/foundation/crc32c.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/7/src/foundation/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/7/src/foundation/record.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/7/src/io/flush.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/7/src/io/lifecycle.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/7/src/io/native.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/7/src/io/package.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/7/src/io/transfer.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/7/src/io/types.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/7/src/package.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/7/src/recovery/decisions-build.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/7/src/recovery/decisions-package.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/7/src/recovery/decisions-query.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/7/src/recovery/decisions-radix.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/7/src/recovery/decisions-sort.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/7/src/recovery/decisions-types.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/7/src/recovery/manifest-build.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/7/src/recovery/manifest-decode.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/7/src/recovery/manifest-fold.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/7/src/recovery/manifest-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/7/src/recovery/manifest-query.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/7/src/recovery/manifest-types.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/7/src/recovery/package.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/7/src/recovery/scan.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/7/src/storage/compaction-scan.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/7/src/storage/control-payload.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/7/src/storage/formats.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/7/src/storage/log-header.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/7/src/storage/package.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/7/src/storage/payload-record.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/7/src/storage/payload-write.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/7/src/storage/segment-header.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/7/src/wal/builder.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/7/src/wal/csn.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/7/src/wal/executor.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/7/src/wal/group.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/7/src/wal/package.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/7/src/wal/types.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/7/test.log" :SOURCE
   #A((106) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/test.log")
   :BYTES 14642 :SHA256
   "fb1eb379b86496ea04ab3b26a36acda0536bacbd92a5fe471535c708a9a5a746")
  (:PATH "raw/mutations/7/tests/codec/cbor-header.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/7/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/7/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/7/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/7/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/7/tests/codec/cbor-structure-support.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/7/tests/codec/cbor-structure-threads.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/7/tests/codec/cbor-structure.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/7/tests/codec/cbor-support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/7/tests/codec/cbor-threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/7/tests/codec/support.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/7/tests/codec/threads.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/7/tests/codec/utf8.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/7/tests/csn/registry.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/7/tests/csn/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/7/tests/csn/threads.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/7/tests/execution/handoff.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/7/tests/execution/queue.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/7/tests/execution/ready-recycle.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/7/tests/execution/ready.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/7/tests/execution/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/7/tests/execution/threads.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/7/tests/foundation/batch.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/7/tests/foundation/binary.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/7/tests/foundation/record.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/7/tests/foundation/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/7/tests/io/native.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/7/tests/io/support.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/7/tests/io/transfer.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/7/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/7/tests/lint-fixtures/good.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/7/tests/recovery/corruption.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/7/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/7/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/7/tests/recovery/decisions-support.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/7/tests/recovery/decisions.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/7/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/7/tests/recovery/manifest-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/7/tests/recovery/manifest.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/7/tests/recovery/scan.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/7/tests/recovery/support.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/7/tests/smoke.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/7/tests/storage/compaction-scan.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/7/tests/storage/control-payload.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/7/tests/storage/log-header.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/7/tests/storage/segment-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/7/tests/storage/support.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/7/tests/wal/builder.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/7/tests/wal/csn-threads.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/7/tests/wal/csn.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/7/tests/wal/fault.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/7/tests/wal/group.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/7/tests/wal/native.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/7/tests/wal/support.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/7/tools/build.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/7/tools/cbor-minimal-isolated-build.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/7/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 444 :SHA256
   "7befcf27f3dbcef3ede93a7db1c3300312592f499d7ee3d4a304bbc8786ca511")
  (:PATH "raw/mutations/baseline/src/codec/cbor-float-minimal.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-float-minimal.lisp")
   :BYTES 3911 :SHA256
   "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db")
  (:PATH "raw/mutations/baseline/src/codec/cbor-header.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-header.lisp")
   :BYTES 5769 :SHA256
   "a67318d1811033309b4e329aa0912a48a859d7927e74c7fde8d3b7f23d269beb")
  (:PATH "raw/mutations/baseline/src/codec/cbor-minimal.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-minimal.lisp")
   :BYTES 3592 :SHA256
   "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449")
  (:PATH "raw/mutations/baseline/src/codec/cbor-package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-package.lisp")
   :BYTES 478 :SHA256
   "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b")
  (:PATH "raw/mutations/baseline/src/codec/cbor-scan-input.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-scan-input.lisp")
   :BYTES 2121 :SHA256
   "abd04a9edb5302d2afba92c919a0d730fe4080fc684ed22a2d8f003492623ed4")
  (:PATH "raw/mutations/baseline/src/codec/cbor-scan-items.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-scan-items.lisp")
   :BYTES 7209 :SHA256
   "7cfd60997c1508559992454259b28556c880e3b373d35e66075e4411d13fbd39")
  (:PATH "raw/mutations/baseline/src/codec/cbor-scan-stack.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-scan-stack.lisp")
   :BYTES 5645 :SHA256
   "32ac1fc9375616bbeef2e17c2e4caea04d8d209536c37b9cf9a6cd0ccbfacbbb")
  (:PATH "raw/mutations/baseline/src/codec/cbor-scan.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-scan.lisp")
   :BYTES 4898 :SHA256
   "a016b8e407bb6d9c53b394686df3a292f46e1a7ef05d36f5aea7311cfcd42059")
  (:PATH "raw/mutations/baseline/src/codec/cbor-space.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/cbor-space.lisp")
   :BYTES 3381 :SHA256
   "fcddc3685ac95e2ea0f754c10fdff10cd733cdf08b44b8e202af68b2d6819590")
  (:PATH "raw/mutations/baseline/src/codec/package.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/package.lisp")
   :BYTES 393 :SHA256
   "7971492e08a41885a4553ea906dce058076047317d894e6d90eaa0eee00bb768")
  (:PATH "raw/mutations/baseline/src/codec/utf8.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/codec/utf8.lisp")
   :BYTES 6197 :SHA256
   "d0b0f4d43fed5bb0a602d40f33e2fa5eeeb66e6f0ca4f1cb6ff6af641af11b4e")
  (:PATH "raw/mutations/baseline/src/csn/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/csn/package.lisp")
   :BYTES 441 :SHA256
   "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0")
  (:PATH "raw/mutations/baseline/src/csn/registry.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/csn/registry.lisp")
   :BYTES 12139 :SHA256
   "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a")
  (:PATH "raw/mutations/baseline/src/execution/handoff.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/handoff.lisp")
   :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:PATH "raw/mutations/baseline/src/execution/package.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/package.lisp")
   :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb")
  (:PATH "raw/mutations/baseline/src/execution/queue.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/queue.lisp")
   :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:PATH "raw/mutations/baseline/src/execution/ready-recycle.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/ready-recycle.lisp")
   :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b")
  (:PATH "raw/mutations/baseline/src/execution/ready-types.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/ready-types.lisp")
   :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:PATH "raw/mutations/baseline/src/execution/ready.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/ready.lisp")
   :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:PATH "raw/mutations/baseline/src/execution/writer.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/execution/writer.lisp")
   :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:PATH "raw/mutations/baseline/src/foundation/batch.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/batch.lisp")
   :BYTES 5228 :SHA256
   "318cdb151268a96cad596b21e2ba7bb8073193a94b98ea8a372e7a4677766af3")
  (:PATH "raw/mutations/baseline/src/foundation/binary.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/binary.lisp")
   :BYTES 3295 :SHA256
   "880aebbf3b7d762d5ce3c5f629c9d0297328650b94dc41deeeacbaa55a2154ea")
  (:PATH "raw/mutations/baseline/src/foundation/conditions.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/conditions.lisp")
   :BYTES 2050 :SHA256
   "a15bd1d4c96f18b10bf9d2d6937896adc8b4038cf4fa352a96cd9a1085d652a8")
  (:PATH "raw/mutations/baseline/src/foundation/crc32c.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/crc32c.lisp")
   :BYTES 3332 :SHA256
   "fa170d3c52f14d8261a81247df84b92dd131774f04f3912ff14d5645e65d8a1b")
  (:PATH "raw/mutations/baseline/src/foundation/package.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/package.lisp")
   :BYTES 1471 :SHA256
   "539778b426b4170334efd56944efd412368383e4099ab2e24ae1a0f78e7857eb")
  (:PATH "raw/mutations/baseline/src/foundation/record.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/foundation/record.lisp")
   :BYTES 16369 :SHA256
   "1afe1ab9951ac1f35ff4e0439e0e65e2f5bf551b2cb4ac241893654de75ae8e2")
  (:PATH "raw/mutations/baseline/src/io/flush.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/flush.lisp")
   :BYTES 1569 :SHA256
   "0ff9522660c824265368a62dbf7df2a5f5ad59f4ef759217107e1e49d8ed6325")
  (:PATH "raw/mutations/baseline/src/io/lifecycle.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/lifecycle.lisp")
   :BYTES 4536 :SHA256
   "baa1f763fe0f394a14d381b753dcb1be1e90eb03eaff5d6469465b5d4eca015f")
  (:PATH "raw/mutations/baseline/src/io/native.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/native.lisp")
   :BYTES 5026 :SHA256
   "b8cf3ce1ff7b4fa9def8a602ab768c0e9a321f8d6cdce6e5b2b7ded2fe3d97dd")
  (:PATH "raw/mutations/baseline/src/io/package.lisp" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/package.lisp")
   :BYTES 592 :SHA256
   "118eba04ab2aa87a2d86e0b0269dbeacaa485457acebbc12c57317ae465a89c0")
  (:PATH "raw/mutations/baseline/src/io/transfer.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/transfer.lisp")
   :BYTES 5051 :SHA256
   "3748328cf85e1c007900a63bdd0f159f38a8d7cd3577c92c56fc68692b9b7bcf")
  (:PATH "raw/mutations/baseline/src/io/types.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/io/types.lisp")
   :BYTES 4143 :SHA256
   "50c7eeea91af232fca7103ce5a25535958d73836f01cb45a20c7120b88b1336b")
  (:PATH "raw/mutations/baseline/src/package.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/package.lisp")
   :BYTES 425 :SHA256
   "40c02ae97dc8efe074428022ca22b0d29c855f4acc2ea36c8ce19c85797ea0c8")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-build.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-build.lisp")
   :BYTES 11857 :SHA256
   "be292ec655087a229a1630179876da9e302a6121985ec3141a5e35226885a115")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-package.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-package.lisp")
   :BYTES 818 :SHA256
   "a58dcefca404c567bcb339c24e2ad38767a49964d34dc2c3c6696c932902de39")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-query.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-query.lisp")
   :BYTES 4525 :SHA256
   "08196938136a920e5e1cc84838726f721d1f43b59f1f677fac10871574171e24")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-radix.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-radix.lisp")
   :BYTES 11061 :SHA256
   "564becba75721f15317b260b9a949eba716e682a9062c4e009d5463040c21e54")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-sort.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-sort.lisp")
   :BYTES 7654 :SHA256
   "cfb4d0c6e02bb0253cff992b4ab0f9664c18b9054ee334d541e69931ff0876a2")
  (:PATH "raw/mutations/baseline/src/recovery/decisions-types.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/decisions-types.lisp")
   :BYTES 2056 :SHA256
   "77cfcb54f46cc735310546f0f89fd0dfd16297cf74f8b0942ee7e451ae59873c")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-build.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-build.lisp")
   :BYTES 10251 :SHA256
   "1e6f306f14685607c3e5adb3ddefd3cbbef915d3185882b1f8ea18aa6b0f9471")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-decode.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-decode.lisp")
   :BYTES 6160 :SHA256
   "04ee77e3b294a41f5b93fab01c99b907a39d6ab229f770484b00af64f3505779")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-fold.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-fold.lisp")
   :BYTES 7068 :SHA256
   "60ed35eefdeafe2d1bdb40b6306969b6b00801e641e2a14a61a5492d45486730")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-package.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-package.lisp")
   :BYTES 1225 :SHA256
   "43d288ae82f8ac3ce1f5249512afbc75bd4f0c163d00bfb921f093c859cb15a1")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-query.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-query.lisp")
   :BYTES 3582 :SHA256
   "d033f9dea7c94f92dd52dc45fa84b5dc852ac99ab254503c1a51d78eadb8ad6b")
  (:PATH "raw/mutations/baseline/src/recovery/manifest-types.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/manifest-types.lisp")
   :BYTES 3345 :SHA256
   "4d6a51841dde7f5cd88834cb94538e3d6b060b660d210c7d418b1d7a940b7a10")
  (:PATH "raw/mutations/baseline/src/recovery/package.lisp" :SOURCE
   #A((130) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/package.lisp")
   :BYTES 927 :SHA256
   "a7593b4df8d126fb3953c75628230392822a156dd74e7f5e38d5131bce2d62c9")
  (:PATH "raw/mutations/baseline/src/recovery/scan.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/recovery/scan.lisp")
   :BYTES 12829 :SHA256
   "cdcc030eb24d1bcc8ededafbfb1fe8bc3e107af0dd4a1d4b8f202f049904e218")
  (:PATH "raw/mutations/baseline/src/storage/compaction-scan.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/compaction-scan.lisp")
   :BYTES 5510 :SHA256
   "63b4e2bd18045a3aead8833509f6984d9d1f99b458ee790e61194b5a20ee329d")
  (:PATH "raw/mutations/baseline/src/storage/control-payload.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/control-payload.lisp")
   :BYTES 6273 :SHA256
   "106b5eefb612ea6180a50ee7c7db682930dc481fc7cedb5b94f32a34ab2e9491")
  (:PATH "raw/mutations/baseline/src/storage/formats.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/formats.lisp")
   :BYTES 3841 :SHA256
   "7b926250bf3ace00ed955d5ea9c27b66ab44fa21e3b4b78f87f1fce9dae1494f")
  (:PATH "raw/mutations/baseline/src/storage/log-header.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/log-header.lisp")
   :BYTES 3947 :SHA256
   "817ba58a321911b766db3f7c75ada3d557249258641cc973811863a43695be81")
  (:PATH "raw/mutations/baseline/src/storage/package.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/package.lisp")
   :BYTES 1079 :SHA256
   "28b5e2c1558e4055cf792638a49161b09b101a9e70cd7182b9638dcc6a10a01e")
  (:PATH "raw/mutations/baseline/src/storage/payload-record.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/payload-record.lisp")
   :BYTES 3641 :SHA256
   "ea76337e95dd48a65d412efdcf403f5c4b1588759aa33152caed4ebdb0c649a7")
  (:PATH "raw/mutations/baseline/src/storage/payload-write.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/payload-write.lisp")
   :BYTES 5239 :SHA256
   "15b8638ce03d098181dfa2a85ec48db687c917fb0f1aa9ea799d20ce5ff8dfbc")
  (:PATH "raw/mutations/baseline/src/storage/segment-header.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/storage/segment-header.lisp")
   :BYTES 5517 :SHA256
   "f0b78ed097b1f92ee3201288b0e4924066c3f38a06c1681cf0c531c9fd982011")
  (:PATH "raw/mutations/baseline/src/wal/builder.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/builder.lisp")
   :BYTES 7552 :SHA256
   "37825cf0df9b3e7ae3b08baa7bd4316e9c9bed9e82f8b8daa5e8e31d14f4f2e3")
  (:PATH "raw/mutations/baseline/src/wal/csn.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/csn.lisp")
   :BYTES 7765 :SHA256
   "055e2d06119da29a8895c55683cbec1f6a3d16ab91ff6f97419e8ec56500b43f")
  (:PATH "raw/mutations/baseline/src/wal/executor.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/executor.lisp")
   :BYTES 5619 :SHA256
   "7ad745b601ac4faa43323159a9c18bc4e3164c933ee99edb821ad5ea40fa56b7")
  (:PATH "raw/mutations/baseline/src/wal/group.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/group.lisp")
   :BYTES 6305 :SHA256
   "7401cefa0a094aa1765ded7ab209d924a84c6a3d579bbceadc38ab0c0582bd4b")
  (:PATH "raw/mutations/baseline/src/wal/package.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/package.lisp")
   :BYTES 1607 :SHA256
   "890ccdaf1abef8d07858c573474b63089d0f43fd9dd56e1fdaa0eac8878fe2a7")
  (:PATH "raw/mutations/baseline/src/wal/types.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/src/wal/types.lisp")
   :BYTES 5420 :SHA256
   "c4ae64ea2a63f8eeccf026cc130cdb668f3e4b256f30804db59230e9a023e18e")
  (:PATH "raw/mutations/baseline/test.log" :SOURCE
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/test.log")
   :BYTES 26179 :SHA256
   "cd734f6f0e85f08dff8245ea1829696d62a4740be37d22f08b94d1a9cd5920db")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-header.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-header.lisp")
   :BYTES 10773 :SHA256
   "6ac998e6ef3f426e1caaf3332088ca3bbc7915369cd80262c8f675a4a960d815")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-minimal-edges.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-minimal-edges.lisp")
   :BYTES 1613 :SHA256
   "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-minimal-support.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-minimal-support.lisp")
   :BYTES 8620 :SHA256
   "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-minimal-threads.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-minimal-threads.lisp")
   :BYTES 3799 :SHA256
   "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-minimal.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-minimal.lisp")
   :BYTES 12604 :SHA256
   "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-structure-support.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-structure-support.lisp")
   :BYTES 11757 :SHA256
   "1e592931aaa7a67f748dde85ef0cc2e0eaf2bb32b3444ff25b89f24b4e764edb")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-structure-threads.lisp"
   :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-structure-threads.lisp")
   :BYTES 4305 :SHA256
   "28f05d84e92eb1a9c30b2d90ab9edd7157823e9440416cb04567a71d94e9c645")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-structure.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-structure.lisp")
   :BYTES 22968 :SHA256
   "795d7c2edac33b6cde7c8c472e2e1933a0187e2baaa68be64c26f16a13bf5110")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-support.lisp")
   :BYTES 6072 :SHA256
   "41e013305941cb627928ad3440a923413a250c47558514a74c9e233f24d6126a")
  (:PATH "raw/mutations/baseline/tests/codec/cbor-threads.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/cbor-threads.lisp")
   :BYTES 3683 :SHA256
   "3eb0102046f7d64ed449e6ebcfd019a7cb92cc7334239afd8802b044b5e9ab14")
  (:PATH "raw/mutations/baseline/tests/codec/support.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/support.lisp")
   :BYTES 5807 :SHA256
   "32f653ba22788d8a08ad5bb38d1c418916432594d58ec04fbc9bb81206736b96")
  (:PATH "raw/mutations/baseline/tests/codec/threads.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/threads.lisp")
   :BYTES 3111 :SHA256
   "d693a74fc7276c958d083532fde8aab86e604b28da6ff67334a39dc348fcd337")
  (:PATH "raw/mutations/baseline/tests/codec/utf8.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/codec/utf8.lisp")
   :BYTES 12892 :SHA256
   "7692bbbe1831824c177985152fd48178a9d7daa85e4add0817361e51d4dc6100")
  (:PATH "raw/mutations/baseline/tests/csn/registry.lisp" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/csn/registry.lisp")
   :BYTES 19411 :SHA256
   "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950")
  (:PATH "raw/mutations/baseline/tests/csn/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/csn/support.lisp")
   :BYTES 11407 :SHA256
   "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db")
  (:PATH "raw/mutations/baseline/tests/csn/threads.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/csn/threads.lisp")
   :BYTES 10525 :SHA256
   "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2")
  (:PATH "raw/mutations/baseline/tests/execution/handoff.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/handoff.lisp")
   :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e")
  (:PATH "raw/mutations/baseline/tests/execution/queue.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/queue.lisp")
   :BYTES 12894 :SHA256
   "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722")
  (:PATH "raw/mutations/baseline/tests/execution/ready-recycle.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/ready-recycle.lisp")
   :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae")
  (:PATH "raw/mutations/baseline/tests/execution/ready.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/ready.lisp")
   :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:PATH "raw/mutations/baseline/tests/execution/support.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/support.lisp")
   :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43")
  (:PATH "raw/mutations/baseline/tests/execution/threads.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/execution/threads.lisp")
   :BYTES 14622 :SHA256
   "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359")
  (:PATH "raw/mutations/baseline/tests/foundation/batch.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/foundation/batch.lisp")
   :BYTES 5185 :SHA256
   "fc5242806f7eae35760f1e1a16566c5266fd74608b217fd069dc269e6ccdc183")
  (:PATH "raw/mutations/baseline/tests/foundation/binary.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/foundation/binary.lisp")
   :BYTES 3721 :SHA256
   "c8e60ebfe830b6b8d166fed267d451bf1aa21604d9e661fb5c231759d038f4fe")
  (:PATH "raw/mutations/baseline/tests/foundation/record.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/foundation/record.lisp")
   :BYTES 14950 :SHA256
   "d47e0aaf280f4e27ebd7518b50e876fa61266c4d9aad17ced8d0f46bd0a9d3e8")
  (:PATH "raw/mutations/baseline/tests/foundation/support.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/foundation/support.lisp")
   :BYTES 2464 :SHA256
   "2a9dc4ca5195872f0612e2a656dbe1b02bff2b162460279f40d6c004e9cb959b")
  (:PATH "raw/mutations/baseline/tests/io/native.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/io/native.lisp")
   :BYTES 6207 :SHA256
   "9a9b4607ffd9fe2f57d0131ed516d8f045f85397c7082e7aa0883b08c7a37dc0")
  (:PATH "raw/mutations/baseline/tests/io/support.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/io/support.lisp")
   :BYTES 2951 :SHA256
   "283ab16cdb01d5d81b5f78c2f2aa2676913f07a682a9f8c573e67c956f2d6a50")
  (:PATH "raw/mutations/baseline/tests/io/transfer.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/io/transfer.lisp")
   :BYTES 11847 :SHA256
   "827e879fdd05d196059258ec78af754234012e2b217518d6391f35fb631d71fd")
  (:PATH "raw/mutations/baseline/tests/lint-fixtures/bad.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/lint-fixtures/bad.lisp")
   :BYTES 1587 :SHA256
   "ac8912ce6cc1101f2ebc305a50c0565879547b527d7ca0aeac900ee06bf26652")
  (:PATH "raw/mutations/baseline/tests/lint-fixtures/good.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/lint-fixtures/good.lisp")
   :BYTES 671 :SHA256
   "05ce84f8fd12d9af48252601bcc92d6d60335b53f39b01a9fe2697c4bdaa8cee")
  (:PATH "raw/mutations/baseline/tests/recovery/corruption.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/corruption.lisp")
   :BYTES 7106 :SHA256
   "ab0fca8f28b57b99d69c2cb5e087135713a296aea9328ad234da88fbaf65355c")
  (:PATH "raw/mutations/baseline/tests/recovery/decisions-audit.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/decisions-audit.lisp")
   :BYTES 14971 :SHA256
   "35479ab2de43fd0a2bf65025c7ebd1c53d791e728316d0d00da96a08600fd6f0")
  (:PATH "raw/mutations/baseline/tests/recovery/decisions-radix.lisp" :SOURCE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/decisions-radix.lisp")
   :BYTES 27851 :SHA256
   "75296b2de5620afd4f67117445197cb227adb4b9f65203e299ef6a4ee79518c0")
  (:PATH "raw/mutations/baseline/tests/recovery/decisions-support.lisp" :SOURCE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/decisions-support.lisp")
   :BYTES 6797 :SHA256
   "a0c71abdf2b6685e24c0144485f66261283028f0377bb14a210c2b0a3ca2abb4")
  (:PATH "raw/mutations/baseline/tests/recovery/decisions.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/decisions.lisp")
   :BYTES 19149 :SHA256
   "37b5bded30afbed2a0968e85f179db08f74c44b117127e448db7b1b4a7ac036e")
  (:PATH "raw/mutations/baseline/tests/recovery/manifest-audit.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/manifest-audit.lisp")
   :BYTES 17670 :SHA256
   "f4db042a50275b840f0d4e5c78e4454c36fccff80e72f4ffc786c4f5007f83d6")
  (:PATH "raw/mutations/baseline/tests/recovery/manifest-support.lisp" :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/manifest-support.lisp")
   :BYTES 9769 :SHA256
   "d5fcc1a53715c6b07600536b78143d99d3f1edb10ccae8e06f7cb4917c30b830")
  (:PATH "raw/mutations/baseline/tests/recovery/manifest.lisp" :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/manifest.lisp")
   :BYTES 13799 :SHA256
   "28f1311cdd468fd076fee2053f9949aa98febcae28cc108fabe106a0f2054edd")
  (:PATH "raw/mutations/baseline/tests/recovery/scan.lisp" :SOURCE
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/scan.lisp")
   :BYTES 16966 :SHA256
   "c0ed9d49f266fc77e1b72a51a6283c5c49084427808d0cb402ab40a9176d4d6b")
  (:PATH "raw/mutations/baseline/tests/recovery/support.lisp" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/recovery/support.lisp")
   :BYTES 5957 :SHA256
   "7083ff693d5e184526dce131d14b3fd58b5226e90c4f12d7b86768ec8b086204")
  (:PATH "raw/mutations/baseline/tests/smoke.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/smoke.lisp")
   :BYTES 735 :SHA256
   "9e880b35987d70fafac2ba70d940dcac0bfc3cbd3971b2f36dd54bc849c7f9c8")
  (:PATH "raw/mutations/baseline/tests/storage/compaction-scan.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/storage/compaction-scan.lisp")
   :BYTES 16196 :SHA256
   "2a001ba21b72b7eec9f3c871ceca098a0d6d13d068d5a099fbbc6dd15772c4f5")
  (:PATH "raw/mutations/baseline/tests/storage/control-payload.lisp" :SOURCE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/storage/control-payload.lisp")
   :BYTES 12651 :SHA256
   "b7698a5f27ed54290b18fcd61b9e334a1685cf3640f1e3e46e54dd8e38acaeae")
  (:PATH "raw/mutations/baseline/tests/storage/log-header.lisp" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/storage/log-header.lisp")
   :BYTES 11969 :SHA256
   "cf2ffcfebf549b93fc47c42f9f3816d52074264abf83dce285c01378a7f45b1e")
  (:PATH "raw/mutations/baseline/tests/storage/segment-header.lisp" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/storage/segment-header.lisp")
   :BYTES 4149 :SHA256
   "dd94d76f20db349ba0f4337ac34400a034a86f4ede523fed5551d261091c83df")
  (:PATH "raw/mutations/baseline/tests/storage/support.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/storage/support.lisp")
   :BYTES 4029 :SHA256
   "dfb74f2108cbd909cb867eda09d4a22164aaf4eaf0534a06ae2a732bd20b2625")
  (:PATH "raw/mutations/baseline/tests/wal/builder.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/builder.lisp")
   :BYTES 4000 :SHA256
   "903fb769d104d75871f7fa1db0ecd8ad5c54ef29c212441ce5d527dab467b1e6")
  (:PATH "raw/mutations/baseline/tests/wal/csn-threads.lisp" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/csn-threads.lisp")
   :BYTES 12114 :SHA256
   "f41096f116253e588524746ecce74c444227937b854706889d9fdd8ec6a3445c")
  (:PATH "raw/mutations/baseline/tests/wal/csn.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/csn.lisp")
   :BYTES 34661 :SHA256
   "b508b26e6bad4aa105b0d500aa810a00b9db54726e1b440975894d6225bc5e3a")
  (:PATH "raw/mutations/baseline/tests/wal/fault.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/fault.lisp")
   :BYTES 7614 :SHA256
   "0574c51ccfe04a24c71c3b03341b04f24c8fb271d902b365c4fa82175015a875")
  (:PATH "raw/mutations/baseline/tests/wal/group.lisp" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/group.lisp")
   :BYTES 5524 :SHA256
   "edbdab57cfa0c0d5bdd31342fea6461e2691c887a66f2ca3113f605aed3ea40e")
  (:PATH "raw/mutations/baseline/tests/wal/native.lisp" :SOURCE
   #A((126) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/native.lisp")
   :BYTES 2567 :SHA256
   "3d54ef02df2f251943694a7bbb1141b7dc1a0079cebda7eed66211e6cd7fc2f7")
  (:PATH "raw/mutations/baseline/tests/wal/support.lisp" :SOURCE
   #A((127) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tests/wal/support.lisp")
   :BYTES 1951 :SHA256
   "90a47539e5e2898c0a08059207f30bb5551e7ca8fc166f8f6ce7b95afa757295")
  (:PATH "raw/mutations/baseline/tools/build.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tools/build.lisp")
   :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832")
  (:PATH "raw/mutations/baseline/tools/cbor-minimal-isolated-build.lisp"
   :SOURCE
   #A((143) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/baseline/tools/cbor-minimal-isolated-build.lisp")
   :BYTES 458 :SHA256
   "51c869dc731ccbc4ca4b06ea07b2ff24c10754b598a321f459b994c9cf1185df")
  (:PATH "raw/mutations/report.lisp" :SOURCE
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/report.lisp")
   :BYTES 29005 :SHA256
   "dfbe684d18f945afbb9af609cdda34c03021f9ad0789774c06aa2ccbac522d8d"))
 :LIMITS
 (:SHA256-BYTE-COPY-CHECK :RAW-ORIGINALS-PRESERVED
  :FASL-EXCLUDED-FROM-PUBLISHED-MUTATION-TREES
  :NO-REQUIREMENT-OR-RELEASE-PROMOTION))
