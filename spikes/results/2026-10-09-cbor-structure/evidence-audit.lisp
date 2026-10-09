(:SCHEMA-VERSION 1 :FORMATS NIL :KIND :CBOR-STRUCTURE-INITIAL-EVIDENCE-AUDIT
 :STATUS :OK :RECORDED-AT 4000529791 :REVIEWER "/root/development_next" :MODE
 :READ-ONLY-SAFE-DATA-AND-BYTEWISE-COMPARISON :DATASET-STAGE :INITIAL
 :PATH-BASE "spikes/results/2026-10-09-cbor-structure/" :CATALOG-MD5
 #A((32) BASE-CHAR . "0161dc7d7bf36ca33beb96ef4467a44f") :CONFIG-SOURCE
 "/tmp/cbor-structure-collect-initial.lisp" :HELPER-SOURCE
 "/tmp/cbor-structure-evidence-reader.lisp" :HELPER-MD5
 #A((32) BASE-CHAR . "37d12845de5d82d94ccbae1251dd6988") :CONFIG-MD5
 #A((32) BASE-CHAR . "b1facae987bee01522030231f6e00a4a") :COUNTED-FILES
 (:ENTRIES 21 :ASSOCIATED-RAW 40 :CATALOG 1 :TOTAL 62 :TOTAL-BYTES 3509846
  :WRAPPERS 7 :CHANNELS 14 :COVERAGE-STATE 1 :COVERAGE-HTML 7 :MUTATION-REPORT
  1 :MUTATION-LOGS 11 :IMPORTED-DATA 9)
 :READER
 (:READ-EVAL NIL :SINGLE-FORM-EOF T :SAFE-READ-COUNT 61
  :NO-EVIDENCE-LOAD-OR-EVAL T :LOGS-ARE-STRINGS-NOT-FORMS T)
 :READER-ATTEMPTS
 ((:STATUS :FAILED :EXIT-CODE 1 :SCOPE :AUDIT-HELPER-ONLY :CODE
   "/tmp/cbor-structure-evidence-reader-first.lisp" :LOG
   "/tmp/cbor-structure-evidence-reader.log" :REASON
   :INCORRECT-FAILED-FIELD-DOMAIN-ASSUMPTION :ACTUAL-DOMAIN
   :LIST-OF-FAILURE-RECORDS :FINAL-AUDIT-WRITTEN NIL)
  (:STATUS :OK :EXIT-CODE 0 :SCOPE :AUDIT-HELPER-ONLY :CODE
   "/tmp/cbor-structure-evidence-reader.lisp" :LOG
   "/tmp/cbor-structure-evidence-reader-v2.log"))
 :CHECKS
 ((:CHECK :CATALOG-SCHEMA :STATUS :OK :DETAIL NIL)
  (:CHECK :INITIAL-INVENTORY :STATUS :OK :DETAIL (21 40 1 62))
  (:CHECK :UNIQUE-ARTIFACTS :STATUS :OK :DETAIL NIL)
  (:CHECK :COMPLETE-FILE-INVENTORY :STATUS :OK :DETAIL NIL)
  (:CHECK :TOP-DATA-SCHEMA-READ-EVAL-NIL-AND-EOF :STATUS :OK :DETAIL
   :ALL-21-PLUS-CATALOG)
  (:CHECK :SEVEN-WRAPPERS-AND-FOURTEEN-UTF8-CHANNELS :STATUS :OK :DETAIL NIL)
  (:CHECK :SIX-FILE-COVERAGE-SCOPE :STATUS :OK :DETAIL NIL)
  (:CHECK :COVERAGE-STATE-AND-SEVEN-HTML-BYTEWISE-AND-STRING :STATUS :OK
   :DETAIL NIL)
  (:CHECK :MUTATION-REPORT-AND-BASELINE-PLUS-TEN-LOG-STRINGS :STATUS :OK
   :DETAIL NIL)
  (:CHECK :REVIEWS-AND-COLLECTOR-ATTEMPTS-ORIGINAL-BYTE-IDENTITY :STATUS :OK
   :DETAIL NIL)
  (:CHECK :ORIGINAL-TESTS-BEFORE-READING-PRESERVED-AS-BYTES :STATUS :OK :DETAIL
   NIL)
  (:CHECK :FIRST-FAILED-AND-CORRECTED-GUARD-BOTH-PRESERVED :STATUS :OK :DETAIL
   NIL)
  (:CHECK :PENDING-INITIAL-NOT-FINAL :STATUS :OK :DETAIL NIL)
  (:CHECK :CATALOG-UNCHANGED-DURING-AUDIT :STATUS :OK :DETAIL NIL)
  (:CHECK :DATASET-UNCHANGED-DURING-AUDIT :STATUS :OK :DETAIL NIL))
 :BYTEWISE-COMPARISONS
 ((:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529069-command-81914-0/report.lisp")
   :COPY "preliminary.lisp" :BYTES 174946 :MD5
   #A((32) BASE-CHAR . "538a6e6ad120290c017fd88455d4eee0"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529069-command-81913-0/report.lisp")
   :COPY "coverage-self-test.lisp" :BYTES 87123 :MD5
   #A((32) BASE-CHAR . "77f644d813463c1bbb977e4738a7afef"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529069-command-81915-0/report.lisp")
   :COPY "mutation-self-test.lisp" :BYTES 112588 :MD5
   #A((32) BASE-CHAR . "00508edd91c7b98f490e59b22439bca9"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529099-command-82288-0/report.lisp")
   :COPY "benchmark-self-test.lisp" :BYTES 100712 :MD5
   #A((32) BASE-CHAR . "ca83be88111e2b83365960444a8ab0c1"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529113-command-82449-0/report.lisp")
   :COPY "benchmark.lisp" :BYTES 108446 :MD5
   #A((32) BASE-CHAR . "abad0306fb4a9ef946e7b1e40cc9ccf7"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529135-command-82764-0/report.lisp")
   :COPY "coverage.lisp" :BYTES 89216 :MD5
   #A((32) BASE-CHAR . "637e671c9a8b17b33012a9cd6b6c02f1"))
  (:ROLE :WRAPPER :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529135-command-82763-0/report.lisp")
   :COPY "mutations.lisp" :BYTES 115771 :MD5
   #A((32) BASE-CHAR . "b970c6f865bdeed4dd876eca94efde65"))
  (:ROLE :COVERAGE-STATE :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/coverage-state.lisp")
   :COPY "coverage-raw-raw/coverage-state.lisp" :BYTES 703391 :MD5
   #A((32) BASE-CHAR . "276d5b6669c122e1fe5c6573676e406a"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/29072952df369aae8fc3dc7a771fe097.html")
   :COPY "coverage-raw-raw/29072952df369aae8fc3dc7a771fe097.html" :BYTES 35904
   :MD5 #A((32) BASE-CHAR . "9e348042d48a6156bde6fccb5ba095b1"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/7094973643691432160466524c47eaf0.html")
   :COPY "coverage-raw-raw/7094973643691432160466524c47eaf0.html" :BYTES 28646
   :MD5 #A((32) BASE-CHAR . "130252bc1faa4c9b266832bc5f6b2100"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/7188e5bcde7bfb748a562937d6e9579a.html")
   :COPY "coverage-raw-raw/7188e5bcde7bfb748a562937d6e9579a.html" :BYTES 45732
   :MD5 #A((32) BASE-CHAR . "7ad81ed677f61d7e824677b36e8b11a7"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/9c78c917675d99a10c140b7febb42ee3.html")
   :COPY "coverage-raw-raw/9c78c917675d99a10c140b7febb42ee3.html" :BYTES 21395
   :MD5 #A((32) BASE-CHAR . "e4c22df92579a49fffa502a75ab26a18"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/cover-index.html")
   :COPY "coverage-raw-raw/cover-index.html" :BYTES 2700 :MD5
   #A((32) BASE-CHAR . "9936cce14310dc1a7024c4fa2fc6a468"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/d5dfe24b8e7ce80699dc58a809f5f2f7.html")
   :COPY "coverage-raw-raw/d5dfe24b8e7ce80699dc58a809f5f2f7.html" :BYTES 4342
   :MD5 #A((32) BASE-CHAR . "ecde4036dffcbcfe9af8d1d377f99488"))
  (:ROLE :COVERAGE-HTML :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-coverage/dd182fef492f215bec89dca5da795603.html")
   :COPY "coverage-raw-raw/dd182fef492f215bec89dca5da795603.html" :BYTES 13991
   :MD5 #A((32) BASE-CHAR . "df05ff5e5e2fe65194563f503454ad3e"))
  (:ROLE :MUTATION-REPORT :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/report.lisp")
   :COPY "mutations-raw-report-originale.lisp" :BYTES 27703 :MD5
   #A((32) BASE-CHAR . "3c005425402b0063c64ef7a143a7b630"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/0/test.log")
   :COPY "mutations-raw-logs/0/test.log" :BYTES 14907 :MD5
   #A((32) BASE-CHAR . "3c8f8a4359d7e1e897cde77d49a1d3d7"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/1/test.log")
   :COPY "mutations-raw-logs/1/test.log" :BYTES 15232 :MD5
   #A((32) BASE-CHAR . "aca57b849a564a4eee236284344c6581"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/2/test.log")
   :COPY "mutations-raw-logs/2/test.log" :BYTES 14487 :MD5
   #A((32) BASE-CHAR . "b89da5bf1bc3b4421d7d8bcbb7e945a6"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/3/test.log")
   :COPY "mutations-raw-logs/3/test.log" :BYTES 14487 :MD5
   #A((32) BASE-CHAR . "854faf7c7a75d8a03bc69a6abe556baf"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/4/test.log")
   :COPY "mutations-raw-logs/4/test.log" :BYTES 14384 :MD5
   #A((32) BASE-CHAR . "3de5121b8a73d587f04359fa5d5f7cfa"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/5/test.log")
   :COPY "mutations-raw-logs/5/test.log" :BYTES 15068 :MD5
   #A((32) BASE-CHAR . "b081fb359c371b6ef89a3189b31a72fd"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/6/test.log")
   :COPY "mutations-raw-logs/6/test.log" :BYTES 14703 :MD5
   #A((32) BASE-CHAR . "e1bd6c18d5410aa4c7005f15e4970703"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/7/test.log")
   :COPY "mutations-raw-logs/7/test.log" :BYTES 15067 :MD5
   #A((32) BASE-CHAR . "72d8037a927496ef856a28e83ee7c8eb"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/8/test.log")
   :COPY "mutations-raw-logs/8/test.log" :BYTES 15764 :MD5
   #A((32) BASE-CHAR . "9f0fb2596b52e3ea129750c0d63cf1bb"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/9/test.log")
   :COPY "mutations-raw-logs/9/test.log" :BYTES 14703 :MD5
   #A((32) BASE-CHAR . "d4ed4fb6d9a220420349d6b7aa55a065"))
  (:ROLE :MUTATION-LOG :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/cbor-structure-mutations/baseline/test.log")
   :COPY "mutations-raw-logs/baseline/test.log" :BYTES 21438 :MD5
   #A((32) BASE-CHAR . "14346fc1e9ca8b5fac2dc1981318773c"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((36) BASE-CHAR . "/tmp/cbor-structure-root-review.lisp") :COPY
   "c1-root-reading.lisp" :BYTES 1834 :MD5
   #A((32) BASE-CHAR . "6d9057c798c5028647724efc46be89c2"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((47) BASE-CHAR . "/tmp/cbor-structure-root-supplement-review.lisp") :COPY
   "c1-root-supplement.lisp" :BYTES 803 :MD5
   #A((32) BASE-CHAR . "5baf31d94c3fa40ed5b76491fc10ee34"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((61) BASE-CHAR
      . "/tmp/cbor-structure-independent-review-before-supplement.lisp")
   :COPY "c1-independent-original.lisp" :BYTES 5332 :MD5
   #A((32) BASE-CHAR . "6a21ca9d00ced63377cbb944e8270362"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((43) BASE-CHAR . "/tmp/cbor-structure-independent-review.lisp") :COPY
   "c1-independent-reading.lisp" :BYTES 6289 :MD5
   #A((32) BASE-CHAR . "ac5bc52099e4e0ed80508978472a75f8"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((38) BASE-CHAR . "/tmp/cbor-structure-driver-review.lisp") :COPY
   "c4-driver-reading.lisp" :BYTES 973 :MD5
   #A((32) BASE-CHAR . "36bf5aa382b38252f600662ca929339f"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((36) BASE-CHAR . "/tmp/cbor-structure-tools-audit.lisp") :COPY
   "c4-tools-reading.lisp" :BYTES 5539 :MD5
   #A((32) BASE-CHAR . "2ca564bf03578537646960b4f9dd5bae"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((50) BASE-CHAR . "/tmp/cbor-structure-collector-self-test-first.lisp")
   :COPY "collector-guard-first.lisp" :BYTES 2030 :MD5
   #A((32) BASE-CHAR . "8d612b10e2ef9461bd74e202176f900e"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((51) BASE-CHAR . "/tmp/cbor-structure-collector-rejected-attempt.lisp")
   :COPY "collector-guard-rejected-target.lisp" :BYTES 618 :MD5
   #A((32) BASE-CHAR . "5d570d65c6312b4608110b9e3d09ee2d"))
  (:ROLE :IMPORTED-DATUM :SOURCE
   #A((47) BASE-CHAR . "/tmp/cbor-structure-collector-self-test-v2.lisp") :COPY
   "collector-guard.lisp" :BYTES 1913 :MD5
   #A((32) BASE-CHAR . "9f112992b46267763a1da20d46634383"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((41) BASE-CHAR . "/tmp/collect-cbor-structure-evidence.lisp") :COPY
   "collector-code.txt" :BYTES 21858 :MD5
   #A((32) BASE-CHAR . "3c285d0822adf20e96b4b5e15d1b3d87"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((45) BASE-CHAR . "/tmp/cbor-structure-collector-guard-test.lisp") :COPY
   "collector-guard-code.txt" :BYTES 15189 :MD5
   #A((32) BASE-CHAR . "3da11da5aa727f01ba074fa61c5b7848"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((51) BASE-CHAR . "/tmp/cbor-structure-collector-guard-test-first.lisp")
   :COPY "collector-guard-first-code.txt" :BYTES 15067 :MD5
   #A((32) BASE-CHAR . "f9d078e0210727621c94219c5ca99f2e"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((49) BASE-CHAR . "/tmp/cbor-structure-collector-self-test-first.log")
   :COPY "collector-guard-first.log" :BYTES 1075 :MD5
   #A((32) BASE-CHAR . "3568b13496778941fac6e1b63c5b4c91"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((46) BASE-CHAR . "/tmp/cbor-structure-collector-self-test-v2.log") :COPY
   "collector-guard.log" :BYTES 1036 :MD5
   #A((32) BASE-CHAR . "297cd70f3bd35124b250e1794705b054"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((51) BASE-CHAR . "/tmp/cbor-structure-tests-original-before-read.lisp")
   :COPY "tests-original-before-read.txt" :BYTES 22677 :MD5
   #A((32) BASE-CHAR . "81d9bb2d019289cf34434721616e431c"))
  (:ROLE :ASSOCIATED-SOURCE :SOURCE
   #A((34) BASE-CHAR . "/tmp/cbor-structure-audit-lib.lisp") :COPY
   "audit-library-code.txt" :BYTES 1119 :MD5
   #A((32) BASE-CHAR . "69eb2e6bf50ce9f97101fad9fb71abfa")))
 :FILE-MANIFEST
 ((:PATH "audit-library-code.txt" :BYTES 1119 :MD5
   #A((32) BASE-CHAR . "69eb2e6bf50ce9f97101fad9fb71abfa"))
  (:PATH "benchmark-raw.lisp" :BYTES 43406 :MD5
   #A((32) BASE-CHAR . "7209ffb09861f0717daf741706d78118"))
  (:PATH "benchmark-self-test-raw.lisp" :BYTES 27603 :MD5
   #A((32) BASE-CHAR . "8b4a137f916a7ce33908e9d3d145acff"))
  (:PATH "benchmark-self-test.lisp" :BYTES 100712 :MD5
   #A((32) BASE-CHAR . "ca83be88111e2b83365960444a8ab0c1"))
  (:PATH "benchmark-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "benchmark-self-test.stdout.log" :BYTES 13223 :MD5
   #A((32) BASE-CHAR . "19d9c31585fcebe6a3b9d36c1739484e"))
  (:PATH "benchmark.lisp" :BYTES 108446 :MD5
   #A((32) BASE-CHAR . "abad0306fb4a9ef946e7b1e40cc9ccf7"))
  (:PATH "benchmark.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "benchmark.stdout.log" :BYTES 20962 :MD5
   #A((32) BASE-CHAR . "1f8e30e283eeb522cb96cceb5f9a69b6"))
  (:PATH "c1-independent-original.lisp" :BYTES 5332 :MD5
   #A((32) BASE-CHAR . "6a21ca9d00ced63377cbb944e8270362"))
  (:PATH "c1-independent-reading.lisp" :BYTES 6289 :MD5
   #A((32) BASE-CHAR . "ac5bc52099e4e0ed80508978472a75f8"))
  (:PATH "c1-root-reading.lisp" :BYTES 1834 :MD5
   #A((32) BASE-CHAR . "6d9057c798c5028647724efc46be89c2"))
  (:PATH "c1-root-supplement.lisp" :BYTES 803 :MD5
   #A((32) BASE-CHAR . "5baf31d94c3fa40ed5b76491fc10ee34"))
  (:PATH "c4-driver-reading.lisp" :BYTES 973 :MD5
   #A((32) BASE-CHAR . "36bf5aa382b38252f600662ca929339f"))
  (:PATH "c4-tools-reading.lisp" :BYTES 5539 :MD5
   #A((32) BASE-CHAR . "2ca564bf03578537646960b4f9dd5bae"))
  (:PATH "catalogo.lisp" :BYTES 13968 :MD5
   #A((32) BASE-CHAR . "0161dc7d7bf36ca33beb96ef4467a44f"))
  (:PATH "collector-code.txt" :BYTES 21858 :MD5
   #A((32) BASE-CHAR . "3c285d0822adf20e96b4b5e15d1b3d87"))
  (:PATH "collector-guard-code.txt" :BYTES 15189 :MD5
   #A((32) BASE-CHAR . "3da11da5aa727f01ba074fa61c5b7848"))
  (:PATH "collector-guard-first-code.txt" :BYTES 15067 :MD5
   #A((32) BASE-CHAR . "f9d078e0210727621c94219c5ca99f2e"))
  (:PATH "collector-guard-first.lisp" :BYTES 2030 :MD5
   #A((32) BASE-CHAR . "8d612b10e2ef9461bd74e202176f900e"))
  (:PATH "collector-guard-first.log" :BYTES 1075 :MD5
   #A((32) BASE-CHAR . "3568b13496778941fac6e1b63c5b4c91"))
  (:PATH "collector-guard-rejected-target.lisp" :BYTES 618 :MD5
   #A((32) BASE-CHAR . "5d570d65c6312b4608110b9e3d09ee2d"))
  (:PATH "collector-guard.lisp" :BYTES 1913 :MD5
   #A((32) BASE-CHAR . "9f112992b46267763a1da20d46634383"))
  (:PATH "collector-guard.log" :BYTES 1036 :MD5
   #A((32) BASE-CHAR . "297cd70f3bd35124b250e1794705b054"))
  (:PATH "coverage-raw-raw/29072952df369aae8fc3dc7a771fe097.html" :BYTES 35904
   :MD5 #A((32) BASE-CHAR . "9e348042d48a6156bde6fccb5ba095b1"))
  (:PATH "coverage-raw-raw/7094973643691432160466524c47eaf0.html" :BYTES 28646
   :MD5 #A((32) BASE-CHAR . "130252bc1faa4c9b266832bc5f6b2100"))
  (:PATH "coverage-raw-raw/7188e5bcde7bfb748a562937d6e9579a.html" :BYTES 45732
   :MD5 #A((32) BASE-CHAR . "7ad81ed677f61d7e824677b36e8b11a7"))
  (:PATH "coverage-raw-raw/9c78c917675d99a10c140b7febb42ee3.html" :BYTES 21395
   :MD5 #A((32) BASE-CHAR . "e4c22df92579a49fffa502a75ab26a18"))
  (:PATH "coverage-raw-raw/cover-index.html" :BYTES 2700 :MD5
   #A((32) BASE-CHAR . "9936cce14310dc1a7024c4fa2fc6a468"))
  (:PATH "coverage-raw-raw/coverage-state.lisp" :BYTES 703391 :MD5
   #A((32) BASE-CHAR . "276d5b6669c122e1fe5c6573676e406a"))
  (:PATH "coverage-raw-raw/d5dfe24b8e7ce80699dc58a809f5f2f7.html" :BYTES 4342
   :MD5 #A((32) BASE-CHAR . "ecde4036dffcbcfe9af8d1d377f99488"))
  (:PATH "coverage-raw-raw/dd182fef492f215bec89dca5da795603.html" :BYTES 13991
   :MD5 #A((32) BASE-CHAR . "df05ff5e5e2fe65194563f503454ad3e"))
  (:PATH "coverage-raw.lisp" :BYTES 952936 :MD5
   #A((32) BASE-CHAR . "61e53f85e833c7f2143c6f57d2dede8c"))
  (:PATH "coverage-self-test.lisp" :BYTES 87123 :MD5
   #A((32) BASE-CHAR . "77f644d813463c1bbb977e4738a7afef"))
  (:PATH "coverage-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "coverage-self-test.stdout.log" :BYTES 49 :MD5
   #A((32) BASE-CHAR . "ae30fae71d0b653fb9dbde6ad2f670c4"))
  (:PATH "coverage.lisp" :BYTES 89216 :MD5
   #A((32) BASE-CHAR . "637e671c9a8b17b33012a9cd6b6c02f1"))
  (:PATH "coverage.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "coverage.stdout.log" :BYTES 2112 :MD5
   #A((32) BASE-CHAR . "3d78ebc2fa871500ad79776c6bf58919"))
  (:PATH "mutation-self-test.lisp" :BYTES 112588 :MD5
   #A((32) BASE-CHAR . "00508edd91c7b98f490e59b22439bca9"))
  (:PATH "mutation-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "mutation-self-test.stdout.log" :BYTES 24638 :MD5
   #A((32) BASE-CHAR . "eed238ea6ea555fedbd16e2a49bcfb3e"))
  (:PATH "mutations-raw-logs/0/test.log" :BYTES 14907 :MD5
   #A((32) BASE-CHAR . "3c8f8a4359d7e1e897cde77d49a1d3d7"))
  (:PATH "mutations-raw-logs/1/test.log" :BYTES 15232 :MD5
   #A((32) BASE-CHAR . "aca57b849a564a4eee236284344c6581"))
  (:PATH "mutations-raw-logs/2/test.log" :BYTES 14487 :MD5
   #A((32) BASE-CHAR . "b89da5bf1bc3b4421d7d8bcbb7e945a6"))
  (:PATH "mutations-raw-logs/3/test.log" :BYTES 14487 :MD5
   #A((32) BASE-CHAR . "854faf7c7a75d8a03bc69a6abe556baf"))
  (:PATH "mutations-raw-logs/4/test.log" :BYTES 14384 :MD5
   #A((32) BASE-CHAR . "3de5121b8a73d587f04359fa5d5f7cfa"))
  (:PATH "mutations-raw-logs/5/test.log" :BYTES 15068 :MD5
   #A((32) BASE-CHAR . "b081fb359c371b6ef89a3189b31a72fd"))
  (:PATH "mutations-raw-logs/6/test.log" :BYTES 14703 :MD5
   #A((32) BASE-CHAR . "e1bd6c18d5410aa4c7005f15e4970703"))
  (:PATH "mutations-raw-logs/7/test.log" :BYTES 15067 :MD5
   #A((32) BASE-CHAR . "72d8037a927496ef856a28e83ee7c8eb"))
  (:PATH "mutations-raw-logs/8/test.log" :BYTES 15764 :MD5
   #A((32) BASE-CHAR . "9f0fb2596b52e3ea129750c0d63cf1bb"))
  (:PATH "mutations-raw-logs/9/test.log" :BYTES 14703 :MD5
   #A((32) BASE-CHAR . "d4ed4fb6d9a220420349d6b7aa55a065"))
  (:PATH "mutations-raw-logs/baseline/test.log" :BYTES 21438 :MD5
   #A((32) BASE-CHAR . "14346fc1e9ca8b5fac2dc1981318773c"))
  (:PATH "mutations-raw-report-originale.lisp" :BYTES 27703 :MD5
   #A((32) BASE-CHAR . "3c005425402b0063c64ef7a143a7b630"))
  (:PATH "mutations-raw.lisp" :BYTES 349265 :MD5
   #A((32) BASE-CHAR . "ea443d6c91e87a758aecee1f69061ee5"))
  (:PATH "mutations.lisp" :BYTES 115771 :MD5
   #A((32) BASE-CHAR . "b970c6f865bdeed4dd876eca94efde65"))
  (:PATH "mutations.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:PATH "mutations.stdout.log" :BYTES 27703 :MD5
   #A((32) BASE-CHAR . "3c005425402b0063c64ef7a143a7b630"))
  (:PATH "preliminary.lisp" :BYTES 174946 :MD5
   #A((32) BASE-CHAR . "538a6e6ad120290c017fd88455d4eee0"))
  (:PATH "preliminary.stderr.log" :BYTES 29564 :MD5
   #A((32) BASE-CHAR . "3ba45c3b08c5956861e72a34a03f6920"))
  (:PATH "preliminary.stdout.log" :BYTES 58219 :MD5
   #A((32) BASE-CHAR . "ca9213f9aca723ccf452322da1deff79"))
  (:PATH "tests-original-before-read.txt" :BYTES 22677 :MD5
   #A((32) BASE-CHAR . "81d9bb2d019289cf34434721616e431c")))
 :BENCHMARK
 (:RAW-STDOUT-SAFELY-PARSED T :PARSED-DATUM-IDENTICAL T :SCHEMA-VERSION 1
  :STATUS :OK :NUMERICAL-AUDIT :SEPARATE-REVIEW)
 :PENDING
 (:RAW-COVERAGE-AUDIT :MEASUREMENT-AUDIT :FULL-CHECK :FINAL-CATALOG-AUDIT)
 :LIMITS
 (:INITIAL-DATASET-NOT-FINAL-GATE :NO-NEW-PRODUCT-EXECUTION-OR-BUILD
  :NO-NEW-MEASUREMENT :NO-REPOSITORY-EDIT :NO-HUMAN-APPROVAL
  :MUTATION-CAUSE-AND-MEASUREMENT-INTERPRETATION-SEPARATE-REVIEWS
  :BEFORE-READ-TEST-CODE-IDENTITY-NOT-EXECUTION
  :NO-RECONSTRUCTED-MISSING-TOOL-STREAM
  :NO-HISTORICAL-NON-OVERWRITE-CLAIM-BEYOND-PRESERVED-BYTE-IDENTICAL-ATTEMPTS))
