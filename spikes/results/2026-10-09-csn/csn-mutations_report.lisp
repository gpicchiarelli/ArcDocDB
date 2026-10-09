(:SOURCE-CONSISTENCY :STABLE :SOURCE-FINGERPRINTS-AFTER
 ((:FILE "src/foundation/package.lisp" :MD5
   #A((32) BASE-CHAR . "b95f4808a955f174f0dc8260b8ba89e8"))
  (:FILE "src/foundation/conditions.lisp" :MD5
   #A((32) BASE-CHAR . "0535060fb2eb883174e93863f61b4d0d"))
  (:FILE "src/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "a06115175f450776762761dce25acdb8"))
  (:FILE "src/csn/package.lisp" :MD5
   #A((32) BASE-CHAR . "1130012fc5613a5648d22ed8628be0e8"))
  (:FILE "src/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "a1cdb5661fc54beba5bf00e4765f3235"))
  (:FILE "tools/csn-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "299a866691b1adfac25d6b5466f22fa7")))
 :DIRECTORY
 #A((88) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/")
 :SOURCE-FINGERPRINTS-BEFORE
 ((:FILE "src/foundation/package.lisp" :MD5
   #A((32) BASE-CHAR . "b95f4808a955f174f0dc8260b8ba89e8"))
  (:FILE "src/foundation/conditions.lisp" :MD5
   #A((32) BASE-CHAR . "0535060fb2eb883174e93863f61b4d0d"))
  (:FILE "src/foundation/binary.lisp" :MD5
   #A((32) BASE-CHAR . "a06115175f450776762761dce25acdb8"))
  (:FILE "src/csn/package.lisp" :MD5
   #A((32) BASE-CHAR . "1130012fc5613a5648d22ed8628be0e8"))
  (:FILE "src/csn/registry.lisp" :MD5
   #A((32) BASE-CHAR . "a1cdb5661fc54beba5bf00e4765f3235"))
  (:FILE "tools/csn-mutation.lisp" :MD5
   #A((32) BASE-CHAR . "299a866691b1adfac25d6b5466f22fa7")))
 :SCHEMA-VERSION 1 :KIND :CSN-MUTATIONS :STATUS :OK :RECORDED-AT 4000521007
 :SBCL #A((5) BASE-CHAR . "2.6.9") :COPIED-PRODUCT-FILE-COUNT 5
 :CHILD-DEADLINE-SECONDS 30 :TARGETS
 ((:NAME "drop-inflight-register" :FILE "src/csn/registry.lisp" :TEST
   "inflight-registration" :BEFORE
   "(setf (aref (registro-csn-highs registry) slot) high
                   (aref (registro-csn-lows registry) slot) low"
   :AFTER "(setf (aref (registro-csn-highs registry) slot) 0
                   (aref (registro-csn-lows registry) slot) 0")
  (:NAME "horizon-latest-unconditionally" :FILE "src/csn/registry.lisp" :TEST
   "oldest-pinned-recycle" :BEFORE "(when (plusp count)
      (if (zerop low) (setf high (1- high) low #xffffffff) (decf low)))
    (values high low)))"
   :AFTER "(when (plusp count)
      (if (zerop low) (setf high (1- high) low #xffffffff) (decf low)))
    (values (registro-csn-last-high registry) (registro-csn-last-low registry))))")
  (:NAME "omit-high-carry" :FILE "src/csn/registry.lisp" :TEST "high-carry"
   :BEFORE "(if (= low #xffffffff) (setf low 0 high (1+ high)) (incf low))"
   :AFTER "(if (= low #xffffffff) (setf low 0) (incf low))")
  (:NAME "accept-stale-token" :FILE "src/csn/registry.lisp" :TEST
   "stale-slot-identity" :BEFORE
   "(unless (and (= (aref (registro-csn-highs registry) slot) high)
               (= (aref (registro-csn-lows registry) slot) low))
    (error 'invalid-argument :reason :csn-token))"
   :AFTER "(progn ; MUTANT: omesso il controllo di identità slot/CSN.
    nil)"))
 :SELF-TEST
 (:STATUS :OK :UNIQUE-TARGETS 4 :MISSING-AND-AMBIGUOUS-REJECTED T
  :READER-EVALUATION-DISABLED T :QUOTED-MARKERS-REJECTED T :COMPILE-FAILURE
  :INVALID :WRONG-TEST-FAILURE :INVALID :KILL :NAMED-RUNTIME-PROBE)
 :BASELINE
 (:DIAGNOSTIC NIL :EXECUTION
  (:EXIT-CODE 0 :TIMED-OUT NIL :ARGV
   ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
    "--script" "isolated-build.lisp")
   :STDOUT-LOG
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/baseline/stdout.log")
   :STDERR-LOG
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/baseline/stderr.log")
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :CSN-MUTATION-PROBE :STATUS :OK :PHASE :COMPLETE
    :FAILED-TEST NIL :PASSED-TESTS
    ("inflight-registration" "oldest-pinned-recycle" "high-carry"
     "stale-slot-identity")
    :DIAGNOSTIC NIL))
  :NAME "baseline" :EXPECTED-TEST NIL :STATUS :OK :RESULT :BASELINE-PASSED
  :DIRECTORY
  #A((97) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/baseline/"))
 :MUTANTS
 ((:DIAGNOSTIC NIL :EXECUTION
   (:EXIT-CODE 1 :TIMED-OUT NIL :ARGV
    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
     "--script" "isolated-build.lisp" "inflight-registration")
    :STDOUT-LOG
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/drop-inflight-register/stdout.log")
    :STDERR-LOG
    #A((121) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/drop-inflight-register/stderr.log")
    :REPORT
    (:SCHEMA-VERSION 1 :KIND :CSN-MUTATION-PROBE :STATUS :FAILED :PHASE :TESTS
     :FAILED-TEST "inflight-registration" :PASSED-TESTS NIL :DIAGNOSTIC
     #A((19) BASE-CHAR . "ArcDocDB: CSN-TOKEN")))
   :NAME "drop-inflight-register" :EXPECTED-TEST "inflight-registration"
   :STATUS :OK :RESULT :DETECTED :DIRECTORY
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/drop-inflight-register/"))
  (:DIAGNOSTIC NIL :EXECUTION
   (:EXIT-CODE 1 :TIMED-OUT NIL :ARGV
    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
     "--script" "isolated-build.lisp" "oldest-pinned-recycle")
    :STDOUT-LOG
    #A((129) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/horizon-latest-unconditionally/stdout.log")
    :STDERR-LOG
    #A((129) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/horizon-latest-unconditionally/stderr.log")
    :REPORT
    (:SCHEMA-VERSION 1 :KIND :CSN-MUTATION-PROBE :STATUS :FAILED :PHASE :TESTS
     :FAILED-TEST "oldest-pinned-recycle" :PASSED-TESTS NIL :DIAGNOSTIC
     #A((26) BASE-CHAR . "Coppia 0/2 diversa da 0/0.")))
   :NAME "horizon-latest-unconditionally" :EXPECTED-TEST
   "oldest-pinned-recycle" :STATUS :OK :RESULT :DETECTED :DIRECTORY
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/horizon-latest-unconditionally/"))
  (:DIAGNOSTIC NIL :EXECUTION
   (:EXIT-CODE 1 :TIMED-OUT NIL :ARGV
    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
     "--script" "isolated-build.lisp" "high-carry")
    :STDOUT-LOG
    #A((114) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/omit-high-carry/stdout.log")
    :STDERR-LOG
    #A((114) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/omit-high-carry/stderr.log")
    :REPORT
    (:SCHEMA-VERSION 1 :KIND :CSN-MUTATION-PROBE :STATUS :FAILED :PHASE :TESTS
     :FAILED-TEST "high-carry" :PASSED-TESTS NIL :DIAGNOSTIC
     #A((22) BASE-CHAR . "ArcDocDB: CSN-FRONTIER")))
   :NAME "omit-high-carry" :EXPECTED-TEST "high-carry" :STATUS :OK :RESULT
   :DETECTED :DIRECTORY
   #A((104) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/omit-high-carry/"))
  (:DIAGNOSTIC NIL :EXECUTION
   (:EXIT-CODE 1 :TIMED-OUT NIL :ARGV
    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
     "--script" "isolated-build.lisp" "stale-slot-identity")
    :STDOUT-LOG
    #A((117) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/accept-stale-token/stdout.log")
    :STDERR-LOG
    #A((117) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/accept-stale-token/stderr.log")
    :REPORT
    (:SCHEMA-VERSION 1 :KIND :CSN-MUTATION-PROBE :STATUS :FAILED :PHASE :TESTS
     :FAILED-TEST "stale-slot-identity" :PASSED-TESTS NIL :DIAGNOSTIC
     #A((43) BASE-CHAR . "Token stale accettato oppure reason errata.")))
   :NAME "accept-stale-token" :EXPECTED-TEST "stale-slot-identity" :STATUS :OK
   :RESULT :DETECTED :DIRECTORY
   #A((107) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB/spikes/out/csn-mutations/accept-stale-token/")))
 :LIMITS
 (:FOUR-TARGETED-MUTANTS :STANDALONE-PROBES-NOT-INTEGRATED-TEST-SUITE
  :FRESH-PROCESS-PER-COPY :EXPLICIT-LOCAL-FASL-NO-GLOBAL-CACHE
  :COMPILATION-FAILURE-IS-INVALID :KILL-REQUIRES-EXPECTED-TEST-NAME
  :TEMPORARY-COPIES-RETAINED-FOR-AUDIT :NO-PERSISTENCE-QUALIFICATION))
