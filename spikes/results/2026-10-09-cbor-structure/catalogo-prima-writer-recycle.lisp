(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :PATH-BASE
 "spikes/results/2026-10-09-cbor-structure/" :FORMATS NIL :METADATA-POLICY
 :READ-FROM-ARTIFACT-WITHOUT-INFERENCE :ENTRIES
 ((:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "preliminary.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529070 :FINISHED-AT
   4000529075 :WALL-SECONDS 6.454682d0)
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "coverage-self-test.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529070 :FINISHED-AT
   4000529070 :WALL-SECONDS 0.814107d0)
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "mutation-self-test.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529070 :FINISHED-AT
   4000529070 :WALL-SECONDS 0.877623d0)
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "benchmark-self-test.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529099 :FINISHED-AT
   4000529100 :WALL-SECONDS 0.814973d0)
  (:KIND :RAW-PROCESS-DATUM :FORMATS NIL :ARTIFACT
   "benchmark-self-test-raw.lisp" :PROCESS-ARTIFACT "benchmark-self-test.lisp")
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "benchmark.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529114 :FINISHED-AT
   4000529115 :WALL-SECONDS 1.713632d0)
  (:KIND :RAW-PROCESS-DATUM :FORMATS NIL :ARTIFACT "benchmark-raw.lisp"
   :PROCESS-ARTIFACT "benchmark.lisp")
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "coverage.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529136 :FINISHED-AT
   4000529140 :WALL-SECONDS 4.24921d0)
  (:KIND :VERIFICATION :FORMATS NIL :ARTIFACT "mutations.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529136 :FINISHED-AT
   4000529178 :WALL-SECONDS 42.646272d0)
  (:KIND :RAW-COVERAGE :FORMATS NIL :ARTIFACT "coverage-raw.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :RAW-COVERAGE :PROCESS-ARTIFACT
   "coverage.lisp" :HTML-COUNT 7)
  (:KIND :RAW-MUTATION-REPORT :FORMATS NIL :ARTIFACT
   "mutations-raw-report-originale.lisp" :PROCESS-ARTIFACT "mutations.lisp")
  (:KIND :RAW-MUTATION-OUTPUT :FORMATS NIL :ARTIFACT "mutations-raw.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :RAW-MUTATION-OUTPUT
   :PROCESS-ARTIFACT "mutations.lisp" :STATUS :OK :SOURCE-CONSISTENCY :STABLE
   :LOG-COUNT 11)
  (:KIND :C1-REVIEW :FORMATS NIL :ARTIFACT "c1-root-reading.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-C1-REVIEW :STATUS :NO-OPEN-STATIC-DEFECTS
   :STATEMENT-SOURCE
   "root: prima lettura indipendente del kernel, coordinatore del contratto e ASDF"
   :SOURCE-PATH
   #A((44) BASE-CHAR . "/private/tmp/cbor-structure-root-review.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :SUPPLEMENT-REVIEW :FORMATS NIL :ARTIFACT "c1-root-supplement.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-SUPPLEMENT-REVIEW :STATUS
   :NO-OPEN-STATIC-DEFECTS :STATEMENT-SOURCE
   "root: verifica statica della fixture aggiunta dopo lettura, derivata dal contratto"
   :SOURCE-PATH
   #A((55) BASE-CHAR
      . "/private/tmp/cbor-structure-root-supplement-review.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :ORIGINAL-C1-REVIEW :FORMATS NIL :ARTIFACT
   "c1-independent-original.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA :ARTIFACT-KIND :CODE-REVIEW :STATUS NIL
   :STATEMENT-SOURCE :DIRECT-STATIC-READING :SOURCE-PATH
   #A((69) BASE-CHAR
      . "/private/tmp/cbor-structure-independent-review-before-supplement.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :C1-REVIEW :FORMATS NIL :ARTIFACT "c1-independent-reading.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA :ARTIFACT-KIND
   :CODE-REVIEW :STATUS NIL :STATEMENT-SOURCE :DIRECT-STATIC-READING
   :SOURCE-PATH
   #A((51) BASE-CHAR . "/private/tmp/cbor-structure-independent-review.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :C4-REVIEW :FORMATS NIL :ARTIFACT "c4-driver-reading.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-C4-DRIVER-REVIEW :STATUS
   :NO-OPEN-STATIC-DEFECTS :STATEMENT-SOURCE
   "root: lettura statica indipendente dei driver benchmark e mutation"
   :SOURCE-PATH
   #A((46) BASE-CHAR . "/private/tmp/cbor-structure-driver-review.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :C4-REVIEW :FORMATS NIL :ARTIFACT "c4-tools-reading.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :C4-TOOLS-AUDIT :STATUS :OK :STATEMENT-SOURCE NIL
   :SOURCE-PATH
   #A((44) BASE-CHAR . "/private/tmp/cbor-structure-tools-audit.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :FAILED-COLLECTOR-GUARD :FORMATS NIL :ARTIFACT
   "collector-guard-first.lisp" :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY
   :SCHEMA-VERSION :ARTIFACT-KIND :CBOR-STRUCTURE-COLLECTOR-SELF-TEST :STATUS
   :FAILED :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((58) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-self-test-first.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :REJECTED-COLLECTOR-GUARD :FORMATS NIL :ARTIFACT
   "collector-guard-rejected-target.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION :ARTIFACT-KIND
   :COLLECTOR-REJECTED-ATTEMPT :STATUS :FAILED :STATEMENT-SOURCE
   "root: risultato exec_command della seconda invocazione del guard"
   :SOURCE-PATH
   #A((59) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-rejected-attempt.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :COLLECTOR-GUARD :FORMATS NIL :ARTIFACT "collector-guard.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-COLLECTOR-SELF-TEST :STATUS :OK
   :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((55) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-self-test-v2.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :PRIOR-CATALOG :FORMATS NIL :ARTIFACT "catalogo-prima-full-check.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :EVIDENCE-CATALOG)
  (:KIND :FULL-VERIFICATION :FORMATS NIL :ARTIFACT "full-check.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND :COMMAND-VERIFICATION :STATUS :OK
   :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :STARTED-AT 4000529416 :FINISHED-AT
   4000529520 :WALL-SECONDS 104.763966d0)
  (:KIND :FULL-CHECK-AUDIT :FORMATS NIL :ARTIFACT "full-check-audit.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-FULL-CHECK-AUDIT :STATUS :OK
   :STATEMENT-SOURCE
   "root: lettura protetta del wrapper make check e master compresso validato"
   :SOURCE-PATH
   #A((49) BASE-CHAR . "/private/tmp/cbor-structure-full-check-audit.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :SPIKES-MASTER :FORMATS NIL :ARTIFACT "spikes-check.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :COMPRESSED-EVIDENCE :STATUS NIL :STATEMENT-SOURCE NIL
   :SOURCE-PATH
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529486-check-86824-0/report.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :RAW-COVERAGE-AUDIT :FORMATS NIL :ARTIFACT "coverage-audit.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA :ARTIFACT-KIND
   :COVERAGE-AUDIT :STATUS NIL :STATEMENT-SOURCE
   :DIRECT-READ-OF-RECORDED-DATA-HTML-AND-FROZEN-SOURCE :SOURCE-PATH
   #A((47) BASE-CHAR . "/private/tmp/cbor-structure-coverage-audit.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :MEASUREMENT-AUDIT :FORMATS NIL :ARTIFACT "measurement-audit.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-MEASUREMENT-AUDIT :STATUS :OK
   :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((50) BASE-CHAR . "/private/tmp/cbor-structure-measurement-audit.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :AUDIT-READER-REPAIRS :FORMATS NIL :ARTIFACT
   "measurement-audit-repairs.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION :ARTIFACT-KIND
   :CBOR-STRUCTURE-MEASUREMENT-AUDIT-READER-REPAIRS :STATUS :OK
   :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((58) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-repairs.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :FAILED-AUDIT-READER :FORMATS NIL :ARTIFACT
   "measurement-audit-first.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION :ARTIFACT-KIND
   :CBOR-STRUCTURE-MEASUREMENT-AUDIT :STATUS :FAILED :STATEMENT-SOURCE NIL
   :SOURCE-PATH
   #A((79) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-v1-global-current-assumption.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :FAILED-AUDIT-BUILDER :FORMATS NIL :ARTIFACT
   "coverage-audit-builder-first.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA :ARTIFACT-KIND :UTILITY-ATTEMPT-FAILURE :STATUS
   NIL :STATEMENT-SOURCE :REVIEWER-TRANSCRIPTION-OF-TRUNCATED-TOOL-RESULT
   :SOURCE-PATH
   #A((68) BASE-CHAR
      . "/private/tmp/cbor-structure-coverage-audit-builder-first-failed.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :AUDIT-READER-OUTPUT-NOTE :FORMATS NIL :ARTIFACT
   "evidence-reader-addendum.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION :ARTIFACT-KIND
   :AUDIT-READER-OUTPUT-ADDENDUM :STATUS :DOCUMENTED-OUTPUT-DEFECT
   :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((64) BASE-CHAR
      . "/private/tmp/cbor-structure-evidence-reader-output-addendum.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :INITIAL-EVIDENCE-AUDIT :FORMATS NIL :ARTIFACT "evidence-audit.lisp"
   :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-SCHEMA-KEY :SCHEMA-VERSION
   :ARTIFACT-KIND :CBOR-STRUCTURE-INITIAL-EVIDENCE-AUDIT :STATUS :OK
   :STATEMENT-SOURCE NIL :SOURCE-PATH
   #A((47) BASE-CHAR . "/private/tmp/cbor-structure-evidence-audit.lisp")
   :SOURCE-ARTIFACTS NIL)
  (:KIND :PRIOR-CATALOG :FORMATS NIL :ARTIFACT
   "catalogo-prima-verifica-finale.lisp" :ARTIFACT-SCHEMA-VERSION 1
   :ARTIFACT-KIND :EVIDENCE-CATALOG)
  (:KIND :FINAL-ARTIFACT-VERIFICATION :FORMATS NIL :ARTIFACT
   "final-verification.lisp" :ARTIFACT-SCHEMA-VERSION 1 :ARTIFACT-KIND
   :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0
   :STARTED-AT 4000529988 :FINISHED-AT 4000530035 :WALL-SECONDS 47.463186d0))
 :ASSOCIATED-RAW-FILES
 ((:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((22) BASE-CHAR . "preliminary.stdout.log") :PROCESS-ARTIFACT
   "preliminary.lisp" :CHANNEL :STDOUT :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 58218)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((22) BASE-CHAR . "preliminary.stderr.log") :PROCESS-ARTIFACT
   "preliminary.lisp" :CHANNEL :STDERR :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 29564)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "coverage-self-test.stdout.log") :PROCESS-ARTIFACT
   "coverage-self-test.lisp" :CHANNEL :STDOUT :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 49)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "coverage-self-test.stderr.log") :PROCESS-ARTIFACT
   "coverage-self-test.lisp" :CHANNEL :STDERR :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 0)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "mutation-self-test.stdout.log") :PROCESS-ARTIFACT
   "mutation-self-test.lisp" :CHANNEL :STDOUT :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 24638)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "mutation-self-test.stderr.log") :PROCESS-ARTIFACT
   "mutation-self-test.lisp" :CHANNEL :STDERR :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 0)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((30) BASE-CHAR . "benchmark-self-test.stdout.log") :PROCESS-ARTIFACT
   "benchmark-self-test.lisp" :CHANNEL :STDOUT :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 13223)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((30) BASE-CHAR . "benchmark-self-test.stderr.log") :PROCESS-ARTIFACT
   "benchmark-self-test.lisp" :CHANNEL :STDERR :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 0)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((20) BASE-CHAR . "benchmark.stdout.log") :PROCESS-ARTIFACT
   "benchmark.lisp" :CHANNEL :STDOUT :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 20962)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((20) BASE-CHAR . "benchmark.stderr.log") :PROCESS-ARTIFACT
   "benchmark.lisp" :CHANNEL :STDERR :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 0)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((19) BASE-CHAR . "coverage.stdout.log") :PROCESS-ARTIFACT "coverage.lisp"
   :CHANNEL :STDOUT :SOURCE-KIND :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8
   :CHARACTERS 2112)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((19) BASE-CHAR . "coverage.stderr.log") :PROCESS-ARTIFACT "coverage.lisp"
   :CHANNEL :STDERR :SOURCE-KIND :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8
   :CHARACTERS 0)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((20) BASE-CHAR . "mutations.stdout.log") :PROCESS-ARTIFACT
   "mutations.lisp" :CHANNEL :STDOUT :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 27703)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((20) BASE-CHAR . "mutations.stderr.log") :PROCESS-ARTIFACT
   "mutations.lisp" :CHANNEL :STDERR :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 0)
  (:KIND :RAW-COVERAGE-STATE :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/coverage-state.lisp" :PROCESS-ARTIFACT "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/29072952df369aae8fc3dc7a771fe097.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/7094973643691432160466524c47eaf0.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/7188e5bcde7bfb748a562937d6e9579a.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/9c78c917675d99a10c140b7febb42ee3.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/cover-index.html" :PROCESS-ARTIFACT "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/d5dfe24b8e7ce80699dc58a809f5f2f7.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-COVERAGE-HTML :FORMATS NIL :ARTIFACT
   "coverage-raw-raw/dd182fef492f215bec89dca5da795603.html" :PROCESS-ARTIFACT
   "coverage.lisp")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/0/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "node-budget-boundary")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/1/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "depth-budget-boundary")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/2/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "header-physical-end")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/3/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "payload-physical-end")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/4/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "trailing-direction")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/5/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "map-break-parity")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/6/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "tag-child-consumption")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/7/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "chunk-major")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/8/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "utf8-major")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/9/test.log" :PROCESS-ARTIFACT "mutations.lisp" :NAME
   "map-child-arity")
  (:KIND :RAW-MUTATION-LOG :FORMATS NIL :ARTIFACT
   "mutations-raw-logs/baseline/test.log" :PROCESS-ARTIFACT "mutations.lisp"
   :NAME "baseline")
  (:KIND :COLLECTOR-CODE :FORMATS NIL :ARTIFACT "collector-code.txt"
   :SOURCE-PATH
   #A((49) BASE-CHAR . "/private/tmp/collect-cbor-structure-evidence.lisp"))
  (:KIND :COLLECTOR-GUARD-CODE :FORMATS NIL :ARTIFACT
   "collector-guard-code.txt" :SOURCE-PATH
   #A((53) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-guard-test.lisp"))
  (:KIND :FAILED-GUARD-CODE :FORMATS NIL :ARTIFACT
   "collector-guard-first-code.txt" :SOURCE-PATH
   #A((59) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-guard-test-first.lisp"))
  (:KIND :RAW-FAILED-GUARD-OUTPUT :FORMATS NIL :ARTIFACT
   "collector-guard-first.log" :SOURCE-PATH
   #A((57) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-self-test-first.log"))
  (:KIND :RAW-GUARD-OUTPUT :FORMATS NIL :ARTIFACT "collector-guard.log"
   :SOURCE-PATH
   #A((54) BASE-CHAR
      . "/private/tmp/cbor-structure-collector-self-test-v2.log"))
  (:KIND :ORIGINAL-FROZEN-TEST-CODE :FORMATS NIL :ARTIFACT
   "tests-original-before-read.txt" :SOURCE-PATH
   #A((59) BASE-CHAR
      . "/private/tmp/cbor-structure-tests-original-before-read.lisp"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "audit-library-code.txt"
   :SOURCE-PATH
   #A((42) BASE-CHAR . "/private/tmp/cbor-structure-audit-lib.lisp"))
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((21) BASE-CHAR . "full-check.stdout.log") :PROCESS-ARTIFACT
   "full-check.lisp" :CHANNEL :STDOUT :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 75184)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((21) BASE-CHAR . "full-check.stderr.log") :PROCESS-ARTIFACT
   "full-check.lisp" :CHANNEL :STDERR :SOURCE-KIND :WRAPPER-EMBEDDED-STRING
   :ENCODING :UTF-8 :CHARACTERS 29714)
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "evidence-audit-reader-code.txt"
   :SOURCE-PATH
   #A((48) BASE-CHAR . "/private/tmp/cbor-structure-evidence-reader.lisp"))
  (:KIND :FAILED-AUDIT-CODE :FORMATS NIL :ARTIFACT
   "evidence-audit-reader-first-code.txt" :SOURCE-PATH
   #A((54) BASE-CHAR
      . "/private/tmp/cbor-structure-evidence-reader-first.lisp"))
  (:KIND :FAILED-AUDIT-OUTPUT :FORMATS NIL :ARTIFACT
   "evidence-audit-reader-first.log" :SOURCE-PATH
   #A((47) BASE-CHAR . "/private/tmp/cbor-structure-evidence-reader.log"))
  (:KIND :AUDIT-OUTPUT :FORMATS NIL :ARTIFACT "evidence-audit-reader.log"
   :SOURCE-PATH
   #A((50) BASE-CHAR . "/private/tmp/cbor-structure-evidence-reader-v2.log"))
  (:KIND :COLLECTION-CONFIG :FORMATS NIL :ARTIFACT
   "initial-collection-config.txt" :SOURCE-PATH
   #A((48) BASE-CHAR . "/private/tmp/cbor-structure-collect-initial.lisp"))
  (:KIND :COMPRESSED-SPIKES-MASTER :FORMATS NIL :ARTIFACT "report.lisp.gz"
   :SOURCE-PATH
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-structure/ArcDocDB/spikes/out/4000529486-check-86824-0/report.lisp.gz"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "full-check-audit-code.txt"
   :SOURCE-PATH
   #A((47) BASE-CHAR . "/private/tmp/cbor-structure-full-audit-run.lisp"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "coverage-audit-reader-code.txt"
   :SOURCE-PATH
   #A((48) BASE-CHAR . "/private/tmp/cbor-structure-coverage-reader.lisp"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "coverage-audit-builder-code.txt"
   :SOURCE-PATH
   #A((55) BASE-CHAR
      . "/private/tmp/cbor-structure-coverage-audit-builder.lisp"))
  (:KIND :RECONSTRUCTED-FAILED-AUDIT-CODE :FORMATS NIL :ARTIFACT
   "coverage-audit-builder-first-reconstructed.txt" :SOURCE-PATH
   #A((75) BASE-CHAR
      . "/private/tmp/cbor-structure-coverage-audit-builder-first-reconstructed.lisp"))
  (:KIND :SELECTED-TOOL-RESULT-TRANSCRIPTION :FORMATS NIL :ARTIFACT
   "coverage-audit-builder-first-transcription.txt" :SOURCE-PATH
   #A((74) BASE-CHAR
      . "/private/tmp/cbor-structure-coverage-audit-builder-first-transcription.txt"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT "measurement-audit-reader-code.txt"
   :SOURCE-PATH
   #A((57) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-reader.lisp"))
  (:KIND :FAILED-AUDIT-CODE :FORMATS NIL :ARTIFACT
   "measurement-audit-reader-first-code.txt" :SOURCE-PATH
   #A((77) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-reader-v1-unavailable-uiop.lisp"))
  (:KIND :AUDIT-CODE :FORMATS NIL :ARTIFACT
   "measurement-audit-read-check-code.txt" :SOURCE-PATH
   #A((61) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-read-check.lisp"))
  (:KIND :TOOL-RESULT-TRANSCRIPTION :FORMATS NIL :ARTIFACT
   "measurement-audit-reader-first-transcription.log" :SOURCE-PATH
   #A((59) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-reader-v1.log"))
  (:KIND :TOOL-RESULT-TRANSCRIPTION :FORMATS NIL :ARTIFACT
   "measurement-audit-reader-second-transcription.log" :SOURCE-PATH
   #A((66) BASE-CHAR
      . "/private/tmp/cbor-structure-measurement-audit-reader-v2-failed.log"))
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "final-verification.stdout.log") :PROCESS-ARTIFACT
   "final-verification.lisp" :CHANNEL :STDOUT :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 344)
  (:KIND :RAW-PROCESS-OUTPUT :FORMATS NIL :ARTIFACT
   #A((29) BASE-CHAR . "final-verification.stderr.log") :PROCESS-ARTIFACT
   "final-verification.lisp" :CHANNEL :STDERR :SOURCE-KIND
   :WRAPPER-EMBEDDED-STRING :ENCODING :UTF-8 :CHARACTERS 0))
 :PENDING NIL :LIMITS
 (:RUNTIME-ONLY :LOCAL-AGENT-READINGS-NOT-HUMAN-APPROVAL
  :NO-ENGINE-OR-RELEASE-QUALIFICATION))
