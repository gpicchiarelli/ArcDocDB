(:FINAL-RECORDED-VERIFICATION
 (:ARTIFACT "verifica-finale.lisp" :CONSERVATION-ARTIFACT
  "verifica-finale-conservazione.lisp" :STATUS :OK :EXIT-CODE 0
  :SOURCE-CONSISTENCY :STABLE :COMMAND
  (#A((4) BASE-CHAR . "make") #A((8) BASE-CHAR . "evidence")
   #A((5) BASE-CHAR . "trace") #A((5) BASE-CHAR . "links"))
  :SCOPE :EVIDENCE-TRACE-LINKS)
 :UNRECORDED-LEAF-METADATA-CHECK
 (:ARTIFACT "verifica-leaf-preliminare.lisp" :STATUS :OK :EXIT-CODE 0
  :RECORDING :UNRECORDED-LOCAL-METADATA-CHECK :CHECKED-CATALOG-ENTRIES 44
  :NEW-FINAL-RECORDED-VERIFICATION :PENDING-ROOT)
 :LEAF-PUBLICATION-CORRECTION
 (:DIAGNOSTIC "correzione-leaf.lisp" :HISTORICAL-METADATA
  ("catalogo-annidato.lisp.txt" "riepilogo-annidato.lisp.txt")
  :RAW-NATIVE-BYTES :UNCHANGED :RAW-WRAPPER-BYTES :UNCHANGED
  :NEW-FINAL-RECORDED-VERIFICATION :PENDING-ROOT)
 :PRELIMINARY-FINAL-CHECK
 (:ARTIFACT "verifica-finale-preliminare.lisp" :CONSERVATION-ARTIFACT
  "verifica-finale-preliminare-conservazione.lisp" :COMMAND
  (#A((4) BASE-CHAR . "make") #A((8) BASE-CHAR . "evidence")
   #A((5) BASE-CHAR . "trace") #A((5) BASE-CHAR . "links"))
  :STATUS :FAILED :EXIT-CODE 2 :SOURCE-CONSISTENCY :STABLE :CAUSE
  :NESTED-CATALOG-ARTIFACT-NAMES :RESULT-PROMOTION NIL)
 :SCHEMA-VERSION 1 :KIND :CBOR-PROCESS-VERIFICATION-SUMMARY :DATE "2026-10-09"
 :STATUS :OK :SCOPE :VERIFICATION-TOOLS-ONLY :OBSERVED-COMMANDS
 ((:ARTIFACT #A((14) BASE-CHAR . "command-0.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((31) BASE-CHAR . "tools/cbor-header-mutation.lisp")
    #A((11) BASE-CHAR . "--self-test"))
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL NIL)
  (:ARTIFACT #A((14) BASE-CHAR . "command-1.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((34) BASE-CHAR . "tools/cbor-structure-mutation.lisp")
    #A((11) BASE-CHAR . "--self-test"))
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL NIL)
  (:ARTIFACT #A((14) BASE-CHAR . "command-2.lisp") :COMMAND
   (#A((4) BASE-CHAR . "make") #A((10) BASE-CHAR . "check-core")) :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL NIL)
  (:ARTIFACT #A((14) BASE-CHAR . "command-3.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((31) BASE-CHAR . "tools/cbor-header-mutation.lisp")
    #A((9) BASE-CHAR . "--invalid"))
   :STATUS :FAILED :EXIT-CODE 1 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL
   T)
  (:ARTIFACT #A((14) BASE-CHAR . "command-4.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((34) BASE-CHAR . "tools/cbor-structure-mutation.lisp")
    #A((9) BASE-CHAR . "--invalid"))
   :STATUS :FAILED :EXIT-CODE 1 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL
   T)
  (:ARTIFACT #A((14) BASE-CHAR . "command-5.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((31) BASE-CHAR . "tools/cbor-header-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((31) BASE-CHAR . "spikes/out/cbor-header-signals/"))
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL NIL)
  (:ARTIFACT #A((14) BASE-CHAR . "command-6.lisp") :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((34) BASE-CHAR . "tools/cbor-structure-mutation.lisp")
    #A((5) BASE-CHAR . "--run")
    #A((34) BASE-CHAR . "spikes/out/cbor-structure-signals/"))
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :NEGATIVE-CONTROL NIL))
 :TEST-MODULES (28 17 17 24 20 66 44 18 95 48) :TOTAL-TESTS 377 :SMOKE :PASSED
 :SPIKES 10 :HEADER-MUTANTS 9 :STRUCTURE-MUTANTS 10 :CAMPAIGN-WORKER-ERRORS 0
 :FIXTURE-EXECUTIONS 4 :FIXTURE-OBSERVATIONS
 ((:EXIT-CODE 137 :SIGNAL 9 :RESULT :WORKER-ERROR)
  (:EXIT-CODE 7 :SIGNAL NIL :RESULT :WORKER-ERROR))
 :STRUCTURE-INJECTED-BASELINE-ERRORS (:COPY :TRANSPORT) :LIMITS
 (:RAW-REPORTS-ARE-AUTHORITATIVE :NEGATIVE-STATUSES-PRESERVED
  :NO-PRODUCT-CHANGE :NO-COVERAGE-REPEAT :NO-MCDC-OR-ENGINE-QUALIFICATION))
