(:SCHEMA-VERSION 1 :KIND :INDEPENDENT-PUBLICATION-AUDIT :SUBJECT :CBOR-MINIMAL
 :RECORDED-AT "2026-10-09 15:22:05 UTC" :STATUS :OK :STATEMENT-SOURCE
 :DIRECT-RECORDED-DATA-AND-INDEPENDENT-FILE-INVENTORY :READER
 :STORAGE-COMMIT-REVIEW :READER-ROLE :PRODUCT-AUTHOR-INDEPENDENT-OF-COLLECTOR
 :ARCHIVE "spikes/results/2026-10-09-cbor-minimal/" :ARCHIVE-INDEX-SHA256
 "1c6509a834ee556d8d1efee82fbd44c621208cebe61d7154f2f38594a5755c6c"
 :SNAPSHOT-SCOPE :INDEX-AT-AUDIT-TIME-BEFORE-PUBLICATION-OF-THIS-AUDIT :CHECKS
 6673 :FINDINGS NIL :INDEXED-FILES 1313 :EXPECTED-FILES 1313 :ACTUAL-FILES 1315
 :UNINDEXED-DERIVED-FILES ("archive-index.lisp" "catalogo.lisp")
 :TOTAL-INDEXED-BYTES 10648301 :PROCESS-COUNT 8 :PROCESS-METADATA
 ((:LABEL "preliminary" :RECORD-PATH "processes/preliminary/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("make" "test" "lint" "trace-write" "trace"))
  (:LABEL "coverage-self" :RECORD-PATH "processes/coverage-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/foundation-coverage.lisp" "--self-test"
    "spikes/out/cbor-minimal-coverage-self/"))
  (:LABEL "mutation-self" :RECORD-PATH "processes/mutation-self/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/cbor-minimal-mutation.lisp" "--self-test"))
  (:LABEL "benchmark" :RECORD-PATH "processes/benchmark/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/cbor-minimal-bench.lisp" "--bench"))
  (:LABEL "coverage" :RECORD-PATH "processes/coverage/report.lisp" :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/foundation-coverage.lisp" "--report"
    "spikes/out/cbor-minimal-coverage/" "cbor-minimal"))
  (:LABEL "mutations" :RECORD-PATH "processes/mutations/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
    "tools/cbor-minimal-mutation.lisp" "--run"
    "spikes/out/cbor-minimal-mutations/"))
  (:LABEL "collection-guard-first" :RECORD-PATH
   "processes/collection-guard-first/report.lisp" :STATUS :FAILED :EXIT-CODE 1
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
    "--script" "spikes/out/cbor-minimal-collection/guard.lisp" "--self-test"
    "spikes/out/cbor-minimal-collection/guard-run-01/"))
  (:LABEL "collection-guard" :RECORD-PATH
   "processes/collection-guard/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
    "--script" "spikes/out/cbor-minimal-collection/guard.lisp" "--self-test"
    "spikes/out/cbor-minimal-collection/guard-run-02/")))
 :GROUP-COUNTS
 ((:KIND :PROCESS :LABEL "preliminary" :FILES 2)
  (:KIND :PROCESS :LABEL "coverage-self" :FILES 2)
  (:KIND :PROCESS :LABEL "mutation-self" :FILES 2)
  (:KIND :PROCESS :LABEL "benchmark" :FILES 2)
  (:KIND :PROCESS :LABEL "coverage" :FILES 2)
  (:KIND :PROCESS :LABEL "mutations" :FILES 2)
  (:KIND :PROCESS :LABEL "collection-guard-first" :FILES 2)
  (:KIND :PROCESS :LABEL "collection-guard" :FILES 2)
  (:KIND :TREE :LABEL "coverage" :FILES 4 :MODE :ALL)
  (:KIND :TREE :LABEL "mutations" :FILES 1063 :MODE :LISP-AND-LOG)
  (:KIND :TREE :LABEL "collection-tools" :FILES 200 :MODE :ALL))
 :INDEX-FILE-CHECKS :ALL-INDEXED-BYTES-AND-SHA256 :OMISSION-CHECKS
 :MANDATORY-ARTIFACTS-AND-INDEPENDENT-EXPANSION-OF-DECLARED-SOURCE-DIRECTORIES
 :READ-POLICY
 (:READ-EVAL NIL :EOF-REQUIRED T :REPORT-READER :READ-EVIDENCE
  :COLLECTOR-LOADED-OR-CALLED NIL :PRODUCT-OR-TEST-CAMPAIGNS NIL)
 :TOOLS
 (:LISP-READER "spikes/out/cbor-minimal-publication-audit-reader.lisp"
  :PYTHON-INVENTORY "spikes/out/cbor-minimal-publication-audit-inventory.py"
  :INVARIANT-DEPENDENCY "tools/evidence-storage.lisp")
 :LIMITS
 (:LOCAL-SNAPSHOT-NOT-ATOMIC-PUBLICATION :NO-RELEASE-OR-REQUIREMENT-PROMOTION
  :FASL-DIRECTORIES-EXCLUDED-FROM-PUBLISHED-TREES
  :FUTURE-APPENDS-CHANGE-INDEX-AND-REQUIRE-DISTINCT-AUDIT))
