(:SCHEMA-VERSION 1 :KIND :C1-REVIEW :DATE "2026-10-09"
 :SCOPE (:INTEGRATION-MAIN-92D8B0E :ASDF :MUTATION-COPIER
         :MUTATION-PROCESS-TRANSPORT :MUTATION-CLASSIFICATION :MUTATION-REPORTS)
 :BRANCH-HEAD "6f9f62491a0e566ac76e742ba74aa870bf05cf25"
 :COMMON-BASE "4215fca415c15d64bd56b1aa17d5c09fe6083713"
 :INTEGRATED-MAIN "92d8b0ebf498800e4847bc4828560c6dac879c0e"
 :RUNTIME-VERIFICATION :PENDING-INTEGRATOR-RECORDED-RUNS
 :CONFLICT-RESOLUTIONS
 ((:PATH "CHANGELOG.md" :RESULT :BOTH-ADDITIONS-PRESERVED)
  (:PATH "docs/affidabilita/copertura-eccezioni.md"
   :RESULT :MANIFEST-AND-WRITER-HANDOFF-INVENTORIES-PRESERVED))
 :ASDF-AND-COPIER
 (:STATUS :NO-BLOCKING-FINDING
  :CODEC-PRODUCT ("package" "utf8")
  :CODEC-TESTS ("support" "utf8" "threads")
  :EXECUTION-HANDOFF-PRODUCT-AND-TEST-WIRED T
  :MANIFEST-SIX-SOURCES-AND-THREE-TESTS-WIRED T
  :UTF8-RUNNER-NAMESPACE "ARCDOCDB.UTF8.TESTS"
  :COPIER-CORRECTION (:ADDED-LINES 2
                      :SOURCE-GLOB "src/codec/*.lisp"
                      :TEST-GLOB "tests/codec/*.lisp")
  :ASDF-COPY-GUARD :READ-AS-DATA-WITH-READ-EVAL-NIL)
 :EXPECTED-TEST-COUNTS
 (:METHOD :STATIC-UNIQUE-TOP-LEVEL-DEFTEST-NAMES
  :RUNTIME-EXECUTED-BY-INDEPENDENT-REVIEWER NIL
  :REGISTRIES
  ((:NAMESPACE "ARCDOCDB.RECOVERY.TESTS" :COUNT 82
    :PER-FILE (("scan.lisp" 16) ("corruption.lisp" 3)
               ("decisions.lisp" 17) ("decisions-audit.lisp" 8)
               ("decisions-radix.lisp" 18) ("manifest.lisp" 10)
               ("manifest-audit.lisp" 10)))
   (:NAMESPACE "ARCDOCDB.EXECUTION.TESTS" :COUNT 34
    :PER-FILE (("queue.lisp" 13) ("threads.lisp" 4) ("handoff.lisp" 17)))
   (:NAMESPACE "ARCDOCDB.UTF8.TESTS" :COUNT 17
    :PER-FILE (("utf8.lisp" 16) ("threads.lisp" 1)))))
 :SOURCE-FILES
 ((:PATH "arcdocdb.asd" :GIT-BLOB "929f7202ee8e756cbc1863e2311dd2b56ec5a910")
  (:PATH "tools/foundation-mutation.lisp" :GIT-BLOB "9d6227de08b4ac8fda73c7050be42f22e36eb2b3")
  (:PATH "tools/utf8-mutation.lisp" :GIT-BLOB "27769759bb927e2055d711a6e723a69c468b0a0c")
  (:PATH "tools/writer-handoff-mutation.lisp" :GIT-BLOB "cafc0dbaedb6671672f994dfd86814d72f3307b8")
  (:PATH "tools/decisions-radix-mutation.lisp" :GIT-BLOB "1068f3f3ef7d46253c8ff83109791cd8d40a92e9")
  (:PATH "docs/implementazione/manifest-control-log.md" :GIT-BLOB "6b39b77b28e576610308a9d98e540df64e28555d")
  (:PATH "docs/implementazione/manifest-control-log-metodo.md" :GIT-BLOB "f755abc620aaad10470143418702e883baf2493a")
  (:PATH "docs/implementazione/manifest-control-log-decisioni.md" :GIT-BLOB "f779f81d41748e3e9b10596dc9af12b334d4dc23"))
 :MANIFEST-BYTE-COMPARISON
 (:REFERENCE "6f9f62491a0e566ac76e742ba74aa870bf05cf25"
  :METHOD :CURRENT-FILE-BYTES-COMPARED-TO-GIT-SHOW-BYTES
  :SOURCE-COUNT 6 :TEST-COUNT 3 :ALL-BYTE-IDENTICAL T
  :FILES
  ((:PATH "src/recovery/manifest-build.lisp" :BYTES 10251 :IDENTICAL T
    :GIT-BLOB "e74b806f5116db46f3a385821515c317b2dcb452")
   (:PATH "src/recovery/manifest-decode.lisp" :BYTES 6160 :IDENTICAL T
    :GIT-BLOB "ae5b8e4677fdd1dcee2f2a1baf293f49d9ce2972")
   (:PATH "src/recovery/manifest-fold.lisp" :BYTES 7068 :IDENTICAL T
    :GIT-BLOB "eaddc83c63dce2fde59227e0416917bbc766e325")
   (:PATH "src/recovery/manifest-package.lisp" :BYTES 1225 :IDENTICAL T
    :GIT-BLOB "38fd1ec3f4fcde2aeaaad1d24d7ae2b27bf86612")
   (:PATH "src/recovery/manifest-query.lisp" :BYTES 3582 :IDENTICAL T
    :GIT-BLOB "55e56d621129d1637eac1a787bad60dd0f0405b1")
   (:PATH "src/recovery/manifest-types.lisp" :BYTES 3345 :IDENTICAL T
    :GIT-BLOB "e062c804e68a8f62eddadd5c87db0e7af392744f")
   (:PATH "tests/recovery/manifest-audit.lisp" :BYTES 17670 :IDENTICAL T
    :GIT-BLOB "9dc9667bdae700ff8ff2afc93bb385c0617eda70")
   (:PATH "tests/recovery/manifest-support.lisp" :BYTES 9769 :IDENTICAL T
    :GIT-BLOB "7d3b1be9964aba5894215f29b7eda3d7a14a797f")
   (:PATH "tests/recovery/manifest.lisp" :BYTES 13799 :IDENTICAL T
    :GIT-BLOB "085e019e251106f6feecc7452e7b2d471a1a626f")))
 :C4-SOURCE-OBSERVATIONS
 ((:TOOL "tools/foundation-mutation.lisp"
   :TRANSPORT :LAUNCH-PROGRAM-AND-WAIT-PROCESS
   :PARALLEL-SIGNAL :WORKER-ERROR-BEFORE-CLASSIFICATION
   :SIGNAL-METADATA :NUMBER-IN-WORKER-DIAGNOSTIC
   :BASELINE-SIGNAL-SLOT NIL
   :COMPLETION-WITH-NONZERO-EXIT :WORKER-ERROR
   :WORKER-ERRORS-COUNTED T
   :MUTANT-COPY-SOURCE :VERIFIED-BASELINE
   :FIXTURES (:PARALLEL-LAUNCH-EXIT-AND-COLLECTION-FAILURES
              :ASDF-COPY-OMISSION-REJECTED))
  (:TOOL "tools/decisions-radix-mutation.lisp"
   :TRANSPORT :RESULT-EXIT-LOG-SIGNAL
   :SIGNAL-PRIORITY :WORKER-ERROR
   :COMPLETION-WITH-NONZERO-EXIT :WORKER-ERROR
   :METADATA (:SIGNAL :BASELINE-SIGNAL :WORKER-ERRORS)
   :SIGKILL-FIXTURE :CHILD-KILLS-OWN-PID-AFTER-FLUSHED-START-MARKER
   :FIXTURE-SERIALIZATION-CHECK T :RUNNER-LOG-REPORT-PRESERVED T)
  (:TOOL "tools/writer-handoff-mutation.lisp"
   :TRANSPORT :RESULT-EXIT-LOG-SIGNAL
   :SIGNAL-PRIORITY :WORKER-ERROR
   :COMPLETION-WITH-NONZERO-EXIT :WORKER-ERROR
   :METADATA (:SIGNAL :BASELINE-SIGNAL :WORKER-ERRORS)
   :SIGKILL-FIXTURE :CHILD-KILLS-OWN-PID-AFTER-FLUSHED-START-MARKER
   :FIXTURE-SERIALIZATION-CHECK T :RUNNER-LOG-REPORT-PRESERVED T)
  (:TOOL "tools/utf8-mutation.lisp"
   :TRANSPORT :TEXT-EXIT-LOG-SIGNAL
   :SIGNAL-PRIORITY :WORKER-ERROR
   :COMPLETION-WITH-NONZERO-EXIT :WORKER-ERROR-BEFORE-COMPILATION-DIAGNOSTIC
   :METADATA (:SIGNAL :BASELINE-NESTED-SIGNAL :WORKER-ERRORS :DIAGNOSTIC)
   :BASELINE-REQUIRES (:SMOKE :ZERO-EXIT :EXACT-BUILD-COMPLETION)
   :SIGKILL-FIXTURE :CHILD-KILLS-OWN-PID-AFTER-FLUSHED-SMOKE-MARKER
   :FIXTURE-SERIALIZATION-CHECK T :RUNNER-LOG-REPORT-PRESERVED T
   :FIXTURE-FAILURE-REPORT-PRESERVED T))
 :REVIEWS
 ((:REVIEWER "/root" :ROLE :INTEGRATOR
   :EVIDENCE-SOURCE :DIRECT-INTEGRATOR-TASK-MESSAGE
   :OBSERVATIONS ("L'integratore ha comunicato risoluzione dei due conflitti conservando entrambe le aggiunte, correzione del copier codec e congelamento delle fonti e dell'index."
                  "L'integratore ha avviato make check e tre self-test registrati; questa lettura non ne attesta l'esito."))
  (:REVIEWER "/root/project_access" :ROLE :INDEPENDENT-READ-ONLY-REVIEW
   :METHOD (:SOURCE-READING :DIFF-READING :BYTE-COMPARISON :STATIC-TEST-NAME-COUNT)
   :STATUS :NO-BLOCKING-FINDING
   :OBSERVATIONS ("Riletti ASDF, copier codec, risoluzioni editoriali e aggiornamento del contratto manifest per l'integrazione a main 92d8b0e."
                  "Riletti trasporto, classificazione, raccolta e metadati dei quattro tool con la distinzione della baseline legacy foundation."
                  "Le fixture SIGKILL di radix, handoff e UTF8 colpiscono soltanto il proprio child e preservano runner, log e report."
                  "Gli 82, 34 e 17 test sono conteggi statici di nomi univoci; nessun test eseguito dal recensore indipendente."
                  "I sei sorgenti e i tre test manifest coincidono byte per byte con 6f9f624.")))
 :LIMITS (:INTEGRATION-AND-TOOL-SOURCE-REVIEW-ONLY
          :NO-RUNTIME-RESULT-CLAIM :WORKER-WAIT-HAS-NO-TIMEOUT
          :FOUNDATION-BASELINE-SIGNAL-NOT-STRUCTURED
          :NO-COMPLETE-RECOVERY-QUALIFICATION :NO-MCDC-QUALIFICATION
          :READINGS-DO-NOT-REPLACE-RECORDED-RUNTIME-CHECKS))
