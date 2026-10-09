(:SCHEMA-VERSION 1 :KIND :C4-EVIDENCE-AUDIT :FORMATS NIL :STATUS :OK
 :RECORDED-AT 4000521039 :REVIEWER "/root/development_next" :MODE
 :READONLY-DATA-INTEGRITY :PRODUCT-AUTHOR-P T :HUMAN-APPROVAL NIL :SCOPE
 "CBOR header: catalogo iniziale18entry/52file e struttura append22entry"
 :CATALOG-SNAPSHOT
 (:PATH
  #A((127) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/results/2026-10-09-cbor-header/catalogo-prima-full-check.lisp")
  :MD5 #A((32) BASE-CHAR . "f8443024942dbf1ed11caf68837dce2d") :ENTRIES 18
  :ASSOCIATED-RAW-FILES 33 :COUNTED-FILES 52
  :INITIAL-CATALOG-READ-BEFORE-APPEND T
  :HISTORICAL-SNAPSHOT-USED-AFTER-ROOT-APPEND T)
 :CHECKS
 ((:NAME :CATALOG-INVENTORY :STATUS :OK :DETAIL
   (:ENTRIES 18 :ASSOCIATED-RAW-FILES 33 :TOTAL-FILES 52 :ALL-LISTED T
    :SAFE-DATA-EOF T))
  (:NAME :WRAPPERS :STATUS :OK :DETAIL
   (:COUNT 7 :BYTEWISE-ORIGINALS T :ALL-OK-EXIT-ZERO-STABLE T
    :SNAPSHOT-BEFORE-AFTER-EQUAL T))
  (:NAME :PROCESS-CHANNELS :STATUS :OK :DETAIL
   (:COUNT 14 :UTF8-ENCODING-OF-WRAPPER-EMBEDDED-STRINGS-EXACT T))
  (:NAME :COVERAGE-INTEGRITY :STATUS :OK :DETAIL
   (:STATE 1 :HTML 3 :BYTEWISE-ORIGINALS T :EMBEDDED-TEXT-EXACT T
    :RAW-STATE-READ-EVAL-NIL-EOF T))
  (:NAME :MUTATION-INTEGRITY :STATUS :OK :DETAIL
   (:REPORT 1 :LOGS 10 :BYTEWISE-ORIGINALS T :EMBEDDED-TEXT-EXACT T
    :LOGS-NOT-EVALUATED T))
  (:NAME :BENCHMARK :STATUS :OK :DETAIL
   (:CELLS 9 :SAMPLES 45 :CALLS-PER-SAMPLE 4096 :WARMUP 128 :HEAP-BYTES-EACH 0
    :SINKS-EXACT T :SIX-VALUE-CONSTANTS-EXACT T :TIMER-UNITS-PER-SECOND 1000000
    :TICKS-MIN 251 :TICKS-MAX 340 :ZERO-TICK-SAMPLES 0
    :SECONDS-AND-RATE-CONSISTENT T :ENVIRONMENT
    (:SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE #A((5) BASE-CHAR . "ARM64") :OS
     #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
     :WORKERS 1 :SAFETY 3)))
  (:NAME :BENCHMARK-SENSOR :STATUS :OK :DETAIL
   (:BASELINE-HEAP 0 :POSITIVE-CONTROL-HEAP 16777472
    :POSITIVE-CONTROL-REQUIRED-MINIMUM 16777216 :BASELINE-SINK 8386560
    :POSITIVE-SINK 16777336))
  (:NAME :SEPARATE-BENCHMARK-SELF-TEST-SENSOR :STATUS :OK :DETAIL
   (:BASELINE-HEAP 0 :POSITIVE-CONTROL-HEAP 16777472
    :POSITIVE-CONTROL-REQUIRED-MINIMUM 16777216 :BASELINE-SINK 8386560
    :POSITIVE-SINK 16777336))
  (:NAME :MUTATION-CLASSIFICATION :STATUS :OK :DETAIL
   (:BASELINE-OK T :MUTANTS 9 :DETECTED 9 :INVALID 0 :SURVIVED 0
    :ALL-REAL-EXACT-SMOKE-LINES T :COMPILATION-FAILURE-PATTERNS-ABSENT T
    :SOURCE-FINGERPRINTS-STABLE T))
  (:NAME :COLLECTOR-ATTEMPTS :STATUS :OK :DETAIL
   (:FIRST-APPARENT-PASS 10 :FIRST-CLASSIFICATION :INVALID
    :FIRST-CODE-AND-REPORT-AND-LOG-PRESERVED-BYTEWISE T :ACCEPTED-VERSION 2
    :ACCEPTED-GUARDS 11 :ACCEPTED-FAILED 0 :ACCEPTED-LOG-MATCHES T))
  (:NAME :APPEND-STRUCTURE :STATUS :OK :DETAIL
   (:ENTRIES 22 :PREVIOUS-ENTRIES-PRESERVED 18
    :SCHEMA-ONE-AND-EOF-ON-FOUR-ADDITIONS T :CATALOG-MD5
    #A((32) BASE-CHAR . "321fbe9857d2eb2a1b59de868b9d7397")
    :FULL-CHECK-MASTER-PAYLOAD-VERIFICATION
    :PERFORMED-BY-ROOT-NOT-REPEATED-IN-THIS-AUDIT))
  (:NAME :MUTATION-RUNTIME-PERTINENCE :STATUS :OK :DETAIL
   (:STATUS :OK :BASELINE-CBOR-GROUPS 17 :BASELINE-BUILD-END-LINE-PRESENT T
    :ALL-MUTANTS-FAIL-IN-CBOR-TESTS T :NO-UNRELATED-TEST-FAILURES-REPORTED T
    :MAPPING-SOURCE
    "/root/storage_commit_review via helper cbor_policy, readonly10logs"
    :FAILURES
    ((:NAME "reserved-28" :INDEX 0 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :TYPE-ERROR :DETAIL
      "WIDTH=16; caso lead28 attende cbor-reserved offset3")
     (:NAME "physical-span" :INDEX 1 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-ONE-BYTE-SPANS" :OBSERVED
      :ASSERTION-TYPEP-OBSERVED :DETAIL
      "lead24 [7,8) attende cbor-truncated offset8; condizione effettiva non stampata")
     (:NAME "endianness-low" :INDEX 2 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :ASSERTION-EQUAL :EXPECTED-VALUES (0 25 0 42258 6 :ARGUMENT))
     (:NAME "split-u32" :INDEX 3 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :ASSERTION-EQUAL :EXPECTED-VALUES (0 26 0 2769433686 8 :ARGUMENT))
     (:NAME "high-low-swapped" :INDEX 4 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :ASSERTION-EQUAL :EXPECTED-VALUES (0 24 0 165 5 :ARGUMENT))
     (:NAME "simple-31" :INDEX 5 :TEST
      "TEST-REQ-AFF-004-CBOR-EXTENDED-SIMPLE-VALUES" :OBSERVED
      :ASSERTION-NOT-RETURNED :DETAIL
      "F8 31 [5,7) attende cbor-simple offset6")
     (:NAME "indefinite-major6" :INDEX 6 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :ASSERTION-TYPEP-OBSERVED :DETAIL
      "lead223 attende cbor-indefinite offset3; condizione effettiva non stampata")
     (:NAME "direct-argument" :INDEX 7 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :ASSERTION-EQUAL :EXPECTED-VALUES (0 0 0 0 4 :ARGUMENT))
     (:NAME "next-index" :INDEX 8 :TEST
      "TEST-REQ-AFF-004-CBOR-ALL-256-COMPLETE-LEADING-BYTES" :OBSERVED
      :INVARIANT-VIOLATION :REASON :CBOR-ARGUMENT-PROGRESS :OFFSET 4 :LEAD
      24)))))
 :BYTEWISE-SOURCE-PAIRS
 ((:ARTIFACT "preliminary.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520545-command-86637-0/report.lisp")
   :BYTES 138664)
  (:ARTIFACT "mutation-self-test.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520545-command-86638-0/report.lisp")
   :BYTES 95635)
  (:ARTIFACT "coverage-self-test.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520545-command-86639-0/report.lisp")
   :BYTES 76306)
  (:ARTIFACT "benchmark-self-test.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520563-command-87238-0/report.lisp")
   :BYTES 86584)
  (:ARTIFACT "benchmark.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520577-command-87617-0/report.lisp")
   :BYTES 98258)
  (:ARTIFACT "mutations.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520588-command-87906-0/report.lisp")
   :BYTES 98308)
  (:ARTIFACT "coverage.lisp" :SOURCE
   #A((108) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/4000520588-command-87907-0/report.lisp")
   :BYTES 77822)
  (:ARTIFACT "coverage-raw-raw/coverage-state.lisp" :SOURCE
   #A((103) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-coverage/coverage-state.lisp")
   :BYTES 497466)
  (:ARTIFACT "coverage-raw-raw/9367fddeba1b4bcdc06fcacd4d6d6e9a.html" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-coverage/9367fddeba1b4bcdc06fcacd4d6d6e9a.html")
   :BYTES 34709)
  (:ARTIFACT "coverage-raw-raw/cover-index.html" :SOURCE
   #A((100) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-coverage/cover-index.html")
   :BYTES 1931)
  (:ARTIFACT "coverage-raw-raw/eb9954b0ed3d3abd4c466cb5fc10d63f.html" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-coverage/eb9954b0ed3d3abd4c466cb5fc10d63f.html")
   :BYTES 4004)
  (:ARTIFACT "mutations-raw-report-originale.lisp" :SOURCE
   #A((96) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/report.lisp")
   :BYTES 21274)
  (:ARTIFACT "mutations-raw-logs/0/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/0/test.log")
   :BYTES 12211)
  (:ARTIFACT "mutations-raw-logs/1/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/1/test.log")
   :BYTES 12395)
  (:ARTIFACT "mutations-raw-logs/2/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/2/test.log")
   :BYTES 12492)
  (:ARTIFACT "mutations-raw-logs/3/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/3/test.log")
   :BYTES 12497)
  (:ARTIFACT "mutations-raw-logs/4/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/4/test.log")
   :BYTES 12490)
  (:ARTIFACT "mutations-raw-logs/5/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/5/test.log")
   :BYTES 12433)
  (:ARTIFACT "mutations-raw-logs/6/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/6/test.log")
   :BYTES 12451)
  (:ARTIFACT "mutations-raw-logs/7/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/7/test.log")
   :BYTES 12485)
  (:ARTIFACT "mutations-raw-logs/8/test.log" :SOURCE
   #A((95) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/8/test.log")
   :BYTES 12673)
  (:ARTIFACT "mutations-raw-logs/baseline/test.log" :SOURCE
   #A((102) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB/spikes/out/cbor-mutations/baseline/test.log")
   :BYTES 15117)
  (:ARTIFACT "collector-first-attempt.lisp" :SOURCE
   #A((49) BASE-CHAR . "/private/tmp/cbor-header-collector-self-test.lisp")
   :BYTES 1667)
  (:ARTIFACT "collector-self-test.lisp" :SOURCE
   #A((52) BASE-CHAR . "/private/tmp/cbor-header-collector-self-test-v2.lisp")
   :BYTES 1880)
  (:ARTIFACT "collector-attempt-audit.lisp" :SOURCE
   #A((53) BASE-CHAR . "/private/tmp/cbor-header-collector-attempt-audit.lisp")
   :BYTES 921)
  (:ARTIFACT "collector-code.txt" :SOURCE
   #A((46) BASE-CHAR . "/private/tmp/collect-cbor-header-evidence.lisp") :BYTES
   21724)
  (:ARTIFACT "collector-first-code.txt" :SOURCE
   #A((60) BASE-CHAR
      . "/private/tmp/collect-cbor-header-evidence-first-attempt.lisp")
   :BYTES 21723)
  (:ARTIFACT "collector-self-test-code.txt" :SOURCE
   #A((50) BASE-CHAR . "/private/tmp/cbor-header-collector-guard-test.lisp")
   :BYTES 15037)
  (:ARTIFACT "collector-first-attempt.log" :SOURCE
   #A((48) BASE-CHAR . "/private/tmp/cbor-header-collector-self-test.log")
   :BYTES 855)
  (:ARTIFACT "collector-self-test.log" :SOURCE
   #A((51) BASE-CHAR . "/private/tmp/cbor-header-collector-self-test-v2.log")
   :BYTES 1018))
 :INVENTORY
 ((:ARTIFACT "catalogo-prima-full-check.lisp" :BYTES 10932 :MD5
   #A((32) BASE-CHAR . "f8443024942dbf1ed11caf68837dce2d"))
  (:ARTIFACT "preliminary.lisp" :BYTES 138664 :MD5
   #A((32) BASE-CHAR . "42a1865faef7897e6e8e368db4e5eac3"))
  (:ARTIFACT "mutation-self-test.lisp" :BYTES 95635 :MD5
   #A((32) BASE-CHAR . "4ab9162cd4e0b14804245ac8ad6313ec"))
  (:ARTIFACT "coverage-self-test.lisp" :BYTES 76306 :MD5
   #A((32) BASE-CHAR . "fae4f4ac59d1b263d70e60f39ec31406"))
  (:ARTIFACT "benchmark-self-test.lisp" :BYTES 86584 :MD5
   #A((32) BASE-CHAR . "c0dae3b6afed622beb18a0ee968d6bd6"))
  (:ARTIFACT "benchmark-self-test-raw.lisp" :BYTES 20965 :MD5
   #A((32) BASE-CHAR . "301c6703bdd41e709b0c0c6981581f11"))
  (:ARTIFACT "benchmark.lisp" :BYTES 98258 :MD5
   #A((32) BASE-CHAR . "65cb32d9c195dcd2439e0022964bb611"))
  (:ARTIFACT "benchmark-raw.lisp" :BYTES 44725 :MD5
   #A((32) BASE-CHAR . "f049f518e8608eddf6ab8803866cc3cd"))
  (:ARTIFACT "mutations.lisp" :BYTES 98308 :MD5
   #A((32) BASE-CHAR . "23c65c11956247790a401acaadfc59a8"))
  (:ARTIFACT "coverage.lisp" :BYTES 77822 :MD5
   #A((32) BASE-CHAR . "701db2610d4f0a7ff9c4a7d3ac92667d"))
  (:ARTIFACT "coverage-raw.lisp" :BYTES 621051 :MD5
   #A((32) BASE-CHAR . "4ae1882750ad295198e0691521fe7cb4"))
  (:ARTIFACT "mutations-raw-report-originale.lisp" :BYTES 21274 :MD5
   #A((32) BASE-CHAR . "b8486f18033c0a2a0b4530cdbbadbcd5"))
  (:ARTIFACT "mutations-raw.lisp" :BYTES 274814 :MD5
   #A((32) BASE-CHAR . "4aed56b1f0cac6d13c0266f30b8a1f9e"))
  (:ARTIFACT "c1-root.lisp" :BYTES 80072 :MD5
   #A((32) BASE-CHAR . "8276bb0ec249935718f9ebb9b830731b"))
  (:ARTIFACT "c1-independent.lisp" :BYTES 84862 :MD5
   #A((32) BASE-CHAR . "d8d7ede28aab7d50905d1debfc43c1dd"))
  (:ARTIFACT "c4-tools.lisp" :BYTES 82790 :MD5
   #A((32) BASE-CHAR . "de623f5a57c72077dca8701cf2c2817c"))
  (:ARTIFACT "collector-first-attempt.lisp" :BYTES 1667 :MD5
   #A((32) BASE-CHAR . "875b1b286031feaf29801ebfce5bdcd2"))
  (:ARTIFACT "collector-self-test.lisp" :BYTES 1880 :MD5
   #A((32) BASE-CHAR . "44c7382d5eaa01afa989b985b5ef9984"))
  (:ARTIFACT "collector-attempt-audit.lisp" :BYTES 921 :MD5
   #A((32) BASE-CHAR . "b6db889bffafa85423e01696b945694d"))
  (:ARTIFACT "preliminary.stdout.log" :BYTES 42358 :MD5
   #A((32) BASE-CHAR . "df02c43c05fdacff529e88a9543d1a6f"))
  (:ARTIFACT "preliminary.stderr.log" :BYTES 20001 :MD5
   #A((32) BASE-CHAR . "7ddcc95b15deb253e1a5d36d104f1f0a"))
  (:ARTIFACT "mutation-self-test.stdout.log" :BYTES 18703 :MD5
   #A((32) BASE-CHAR . "bfc85e764855f84425d334bad64fd22d"))
  (:ARTIFACT "mutation-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "coverage-self-test.stdout.log" :BYTES 49 :MD5
   #A((32) BASE-CHAR . "ae30fae71d0b653fb9dbde6ad2f670c4"))
  (:ARTIFACT "coverage-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "benchmark-self-test.stdout.log" :BYTES 10025 :MD5
   #A((32) BASE-CHAR . "7092fc5339a64b808af2d66e1f5e1381"))
  (:ARTIFACT "benchmark-self-test.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "benchmark.stdout.log" :BYTES 21704 :MD5
   #A((32) BASE-CHAR . "2f0c7c66ba7b6e362ba3b4145525f383"))
  (:ARTIFACT "benchmark.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "mutations.stdout.log" :BYTES 21274 :MD5
   #A((32) BASE-CHAR . "b8486f18033c0a2a0b4530cdbbadbcd5"))
  (:ARTIFACT "mutations.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "coverage.stdout.log" :BYTES 1547 :MD5
   #A((32) BASE-CHAR . "5d2aa717e284f693efcff9223209564b"))
  (:ARTIFACT "coverage.stderr.log" :BYTES 0 :MD5
   #A((32) BASE-CHAR . "d41d8cd98f00b204e9800998ecf8427e"))
  (:ARTIFACT "coverage-raw-raw/coverage-state.lisp" :BYTES 497466 :MD5
   #A((32) BASE-CHAR . "53c220e216159d9581edd7612b801d52"))
  (:ARTIFACT "coverage-raw-raw/9367fddeba1b4bcdc06fcacd4d6d6e9a.html" :BYTES
   34709 :MD5 #A((32) BASE-CHAR . "42ed94a0c6a7e0e04ed2dffb417b32e0"))
  (:ARTIFACT "coverage-raw-raw/cover-index.html" :BYTES 1931 :MD5
   #A((32) BASE-CHAR . "85edbed660b94dd726f5cb22fcb6f694"))
  (:ARTIFACT "coverage-raw-raw/eb9954b0ed3d3abd4c466cb5fc10d63f.html" :BYTES
   4004 :MD5 #A((32) BASE-CHAR . "310dc7eb8ddf501884896ec4aaba2bcb"))
  (:ARTIFACT "mutations-raw-logs/0/test.log" :BYTES 12211 :MD5
   #A((32) BASE-CHAR . "598cf0de62cf93ff214a48ae92b70c57"))
  (:ARTIFACT "mutations-raw-logs/1/test.log" :BYTES 12395 :MD5
   #A((32) BASE-CHAR . "e83d30407801b841028b5ad931abfefe"))
  (:ARTIFACT "mutations-raw-logs/2/test.log" :BYTES 12492 :MD5
   #A((32) BASE-CHAR . "39bda215e932115ca73557632d810cce"))
  (:ARTIFACT "mutations-raw-logs/3/test.log" :BYTES 12497 :MD5
   #A((32) BASE-CHAR . "b48b2064b85dc160b89a221ffe90284f"))
  (:ARTIFACT "mutations-raw-logs/4/test.log" :BYTES 12490 :MD5
   #A((32) BASE-CHAR . "1eeaba64b0a8f90ee4a547804d3deca7"))
  (:ARTIFACT "mutations-raw-logs/5/test.log" :BYTES 12433 :MD5
   #A((32) BASE-CHAR . "ef70e25a6fdccf1bc739c9fd40381c8a"))
  (:ARTIFACT "mutations-raw-logs/6/test.log" :BYTES 12451 :MD5
   #A((32) BASE-CHAR . "a1de7c19674c830104d9a5e18723b6d7"))
  (:ARTIFACT "mutations-raw-logs/7/test.log" :BYTES 12485 :MD5
   #A((32) BASE-CHAR . "b58098b903751564b037f1797843fe48"))
  (:ARTIFACT "mutations-raw-logs/8/test.log" :BYTES 12673 :MD5
   #A((32) BASE-CHAR . "72cd5d44698316e4574bfa740a74c0cf"))
  (:ARTIFACT "mutations-raw-logs/baseline/test.log" :BYTES 15117 :MD5
   #A((32) BASE-CHAR . "078ffe18c3c883adfbd1099aab2c2642"))
  (:ARTIFACT "collector-code.txt" :BYTES 21724 :MD5
   #A((32) BASE-CHAR . "f39c4c1172d91570c745e69f2fbac48c"))
  (:ARTIFACT "collector-first-code.txt" :BYTES 21723 :MD5
   #A((32) BASE-CHAR . "0443097ab9ca271c97fb08b62bf7f30d"))
  (:ARTIFACT "collector-self-test-code.txt" :BYTES 15037 :MD5
   #A((32) BASE-CHAR . "d00b5cfe42f1c82b7752ce07417f3da4"))
  (:ARTIFACT "collector-first-attempt.log" :BYTES 855 :MD5
   #A((32) BASE-CHAR . "953697660eb2f31ac9a8b47f51090875"))
  (:ARTIFACT "collector-self-test.log" :BYTES 1018 :MD5
   #A((32) BASE-CHAR . "0125c6304b1754fe234f9c3061b50429")))
 :PROVENANCE
 (:AUDIT-READER "/tmp/cbor-header-evidence-reader.lisp" :AUDIT-READER-MD5
  #A((32) BASE-CHAR . "aa1f34e2c558de4f20751c1d94e8562a") :DATA-READ-EVAL NIL
  :SINGLE-DATUM-EOF-GUARD T :NO-PRODUCT-LOAD-OR-EVAL T
  :NO-NEW-BUILD-TESTS-OR-BENCHMARK T :PROCESS-CHANNEL-SOURCE
  :WRAPPER-EMBEDDED-STRING-ENCODED-UTF8 :MUTATION-FAILURE-MAP
  :READER-HELPER-STATEMENT :FIRST-COLLECTOR-DIAGNOSTIC
  :ROOT-TRANSCRIPTION-NOT-CAPTURED-STDERR)
 :LIMITS
 (:LOCAL-AGENT-AUDIT-NOT-HUMAN-APPROVAL :AUTHOR-AUDIT-NOT-INDEPENDENT-C1
  :HEAP-COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF
  :BENCHMARK-SERIAL-SUCCESS-PATH-ONLY :EXTERNAL-LOAD-UNCONTROLLED
  :COVERAGE-INTEGRITY-ONLY-NOT-NEW-COVERAGE-COUNT-AUDIT
  :MUTATION-ACTUAL-CONDITION-NOT-PRINTED-IN-TWO-LOGS
  :FULL-CHECK-COMPRESSED-MASTER-CHECKED-BY-ROOT-NOT-REPEATED
  :CATALOG-FINAL-APPEND-AND-LINKS-PENDING :NO-ENGINE-OR-RELEASE-QUALIFICATION))
