(:SCHEMA-VERSION 1 :KIND :CBOR-PROCESS-VERIFICATION-SUMMARY :STATUS :OK :SCOPE
 :TOOLS-ONLY-INTEGRATION :OBSERVED-COMMANDS
 ((:ARTIFACT #A((14) BASE-CHAR . "command-0.lisp") :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((11) BASE-CHAR . "--self-test")))
  (:ARTIFACT #A((14) BASE-CHAR . "command-1.lisp") :STATUS :FAILED :EXIT-CODE 1
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((9) BASE-CHAR . "--invalid")))
  (:ARTIFACT #A((14) BASE-CHAR . "command-2.lisp") :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((10) BASE-CHAR . "check-core")))
  (:ARTIFACT #A((14) BASE-CHAR . "command-3.lisp") :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((31) BASE-CHAR . "tools/cbor-header-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((42) BASE-CHAR . "spikes/out/cbor-header-signals-integrated/")))
  (:ARTIFACT #A((14) BASE-CHAR . "command-4.lisp") :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((34) BASE-CHAR . "tools/cbor-structure-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((45) BASE-CHAR . "spikes/out/cbor-structure-signals-integrated/")))
  (:ARTIFACT #A((14) BASE-CHAR . "command-5.lisp") :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/cbor-minimal-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((43) BASE-CHAR . "spikes/out/cbor-minimal-signals-integrated/"))))
 :TEST-MODULES (28 17 17 15 24 20 66 44 18 95 48) :TOTAL-TESTS 392 :SMOKE
 :PASSED :CAMPAIGNS
 ((:ARTIFACT #A((21) BASE-CHAR . "header-mutazioni.lisp") :MUTANTS 9 :DETECTED
   9 :BASELINE :OK :WORKER-ERRORS 0 :SOURCE-CONSISTENCY :STABLE)
  (:ARTIFACT #A((24) BASE-CHAR . "structure-mutazioni.lisp") :MUTANTS 10
   :DETECTED 10 :BASELINE :OK :WORKER-ERRORS 0 :SOURCE-CONSISTENCY :STABLE)
  (:ARTIFACT #A((22) BASE-CHAR . "minimal-mutazioni.lisp") :MUTANTS 8 :DETECTED
   8 :BASELINE :OK :WORKER-ERRORS 0 :SOURCE-CONSISTENCY :STABLE))
 :FIXTURE-EXECUTIONS 4 :FIXTURE-CHILDREN 8 :REAL-CHILD-CLASSES
 ((:EXIT-CODE 137 :SIGNAL 9 :RESULT :WORKER-ERROR)
  (:EXIT-CODE 7 :SIGNAL NIL :RESULT :WORKER-ERROR))
 :SPIKES
 ((:ARTIFACT #A((11) BASE-CHAR . "SPK-01.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-02.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-03.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-04.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-05.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-06.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-07.lisp") :STATUS :PASS)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-08.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-09.lisp") :STATUS :OK)
  (:ARTIFACT #A((11) BASE-CHAR . "SPK-10.lisp") :STATUS :OK))
 :GLOBAL-SPIKE-STATUS :COMPLETE :FINAL-RECORDED-VERIFICATION
 (:ARTIFACT "verifica-finale.lisp" :CONSERVATION-ARTIFACT
  "verifica-finale-conservazione.lisp" :STATUS :OK :EXIT-CODE 0
  :SOURCE-CONSISTENCY :STABLE :VERIFIED-READER
  :ARCDOCDB-EVIDENCE-READ-EVIDENCE)
 :PRIOR-377-TEST-PHOTOGRAPH :UNCHANGED :RUNTIME-COUNT-AUDIT
 "audit-runtime-indipendente.lisp" :LIMITS
 (:RAW-RECORDS-AUTHORITATIVE :NEGATIVE-CLI-STAYS-FAILED
  :NOT-C1-OR-MCDC-OR-COMPLETE-RECOVERY-OR-ENGINE-QUALIFICATION
  :NO-WORKER-TIMEOUT))
