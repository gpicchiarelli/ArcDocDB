(:SCHEMA-VERSION 1 :KIND :C1-REVIEW :DATE "2026-10-09"
 :SCOPE (:ASDF-INTEGRATION :MUTATION-COPIER :DEDICATED-TEST-SELECTION :RADIX-WORKER-CLASSIFICATION)
 :BRANCH-BASE "c309bd2abbb0caac211c34b6f6111c3c370e0185"
 :INTEGRATED-MAIN "4215fca415c15d64bd56b1aa17d5c09fe6083713"
 :UNCHANGED-MANIFEST-SOURCE-AND-TESTS T
 :SOURCE-FILES ((:PATH "arcdocdb.asd" :GIT-BLOB "b2a14c3d620cff8304f9e6152c0f14183a01884e")
(:PATH "tools/foundation-mutation.lisp" :GIT-BLOB "bb3b77d002fda52ea8d982beaa913f583db540a6")
(:PATH "tools/decisions-radix-mutation.lisp" :GIT-BLOB "1068f3f3ef7d46253c8ff83109791cd8d40a92e9")
(:PATH "docs/implementazione/manifest-control-log.md" :GIT-BLOB "49dd9019c21930bef3287e773033e8c5d499d63a")
(:PATH "src/recovery/manifest-build.lisp" :GIT-BLOB "e74b806f5116db46f3a385821515c317b2dcb452")
(:PATH "src/recovery/manifest-decode.lisp" :GIT-BLOB "ae5b8e4677fdd1dcee2f2a1baf293f49d9ce2972")
(:PATH "src/recovery/manifest-fold.lisp" :GIT-BLOB "eaddc83c63dce2fde59227e0416917bbc766e325")
(:PATH "src/recovery/manifest-package.lisp" :GIT-BLOB "38fd1ec3f4fcde2aeaaad1d24d7ae2b27bf86612")
(:PATH "src/recovery/manifest-query.lisp" :GIT-BLOB "55e56d621129d1637eac1a787bad60dd0f0405b1")
(:PATH "src/recovery/manifest-types.lisp" :GIT-BLOB "e062c804e68a8f62eddadd5c87db0e7af392744f")
(:PATH "tests/recovery/manifest-audit.lisp" :GIT-BLOB "9dc9667bdae700ff8ff2afc93bb385c0617eda70")
(:PATH "tests/recovery/manifest-support.lisp" :GIT-BLOB "7d3b1be9964aba5894215f29b7eda3d7a14a797f")
(:PATH "tests/recovery/manifest.lisp" :GIT-BLOB "085e019e251106f6feecc7452e7b2d471a1a626f"))
 :REVIEWS
 ((:REVIEWER "/root" :ROLE :INTEGRATOR :METHOD :SOURCE-AND-DIFF-READING
   :STATUS :NO-BLOCKING-FINDING
   :OBSERVATIONS ("ASDF preserves execution, radix and manifest ordering and test runners."
                  "The isolated copier is checked against ASDF declarations read as data."
                  "DECISION selects 43 tests; manifest still selects 20 tests."
                  "Compiler failures, worker completion failures and OS signals remain distinct from mutation detections."))
  (:REVIEWER "/root/project_access" :ROLE :INDEPENDENT-READ-ONLY-REVIEW
   :STATUS :NO-BLOCKING-FINDING
   :OBSERVATIONS ("Execution is in its own package; radix preserves DECISION API and contracts."
                  "SIGKILL fixture uses the same process transport, kills only its child and checks report serialization."
                  "Compressed SPK-07 and global report match original bytes and declared Git blobs.")))
 :LIMITS (:INTEGRATION-REVIEW-ONLY :NO-ENGINE-RECOVERY-QUALIFICATION
          :WORKER-WAIT-HAS-NO-TIMEOUT :CANCELLATION-CLEANUP-NOT-EXERCISED
          :TWO-REVIEW-READINGS-DO-NOT-REPLACE-RUNTIME-CHECKS))
