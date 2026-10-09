(:SCHEMA-VERSION 1 :KIND :IMPORTED-MUTATION-OUTPUT :SCOPE :DECISIONS :COMMANDS
 (("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
   "tools/foundation-mutation.lisp" "--self-test")
  ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
   "tools/foundation-mutation.lisp" "--run"
   "spikes/out/decisions-mutants-20261009-integration/" "decisions"))
 :RAW-SELF-TEST-OUTPUT "Mutazioni: self-test superato.
"
 :RAW-CAMPAIGN-OUTPUT "(:SCOPE :DECISIONS :BASELINE :PASSED :MUTANTS
 ((:NAME \"decision-count-boundary\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/0/test.log\")
  (:NAME \"decision-cumulative-participants\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/1/test.log\")
  (:NAME \"decision-duplicate-participant\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/2/test.log\")
  (:NAME \"decision-csn-conflict\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/3/test.log\")
  (:NAME \"decision-last-id-byte\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/4/test.log\")
  (:NAME \"decision-missing-found\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/5/test.log\")
  (:NAME \"decision-set-conflict\" :RESULT :DETECTED :EXIT-CODE 1 :LOG
   \"/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/6/test.log\"))
 :DETECTED 7 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0)
"
 :ORIGINAL-REPORT
 (:SCOPE :DECISIONS :BASELINE :PASSED :MUTANTS
  ((:NAME "decision-count-boundary" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/0/test.log")
   (:NAME "decision-cumulative-participants" :RESULT :DETECTED :EXIT-CODE 1
    :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/1/test.log")
   (:NAME "decision-duplicate-participant" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/2/test.log")
   (:NAME "decision-csn-conflict" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/3/test.log")
   (:NAME "decision-last-id-byte" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/4/test.log")
   (:NAME "decision-missing-found" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/5/test.log")
   (:NAME "decision-set-conflict" :RESULT :DETECTED :EXIT-CODE 1 :LOG
    "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/decisions-mutants-20261009-integration/6/test.log"))
  :DETECTED 7 :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0)
 :MISSING-METADATA
 (:ENVIRONMENT :SOURCE-BLOBS-BEFORE :SOURCE-BLOBS-AFTER :TIMING)
 :REASON-FOR-RECORDED-REPEAT :MISSING-COMMAND-PROVENANCE :LIMITS
 (:METADATA-NOT-RECONSTRUCTED :NOT-THE-FINAL-COMMAND-EVIDENCE))
