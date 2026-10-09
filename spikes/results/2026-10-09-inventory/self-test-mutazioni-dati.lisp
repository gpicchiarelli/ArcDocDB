(:SCHEMA-VERSION 1 :KIND :SELFTEST-OUTPUT :ORIGINAL-COMMAND-RECORD
 "spikes/out/4000528555-command-77869-0/report.lisp" :ORIGINAL-REPORTS
 ((:NAME :COPIER :ORIGINAL-PATH
   "spikes/out/4000528556-mutation-copy-self-test-77907/report.lisp"
   :ORIGINAL-REPORT
   (:KIND :COPIER-SELF-TEST :STATUS :PASSED :SOURCE-FILES
    ("src/package.lisp" "src/foundation/package.lisp"
     "src/foundation/conditions.lisp" "src/foundation/binary.lisp"
     "src/foundation/crc32c.lisp" "src/foundation/record.lisp"
     "src/foundation/batch.lisp" "src/codec/package.lisp" "src/codec/utf8.lisp"
     "src/codec/cbor-package.lisp" "src/codec/cbor-header.lisp"
     "src/csn/package.lisp" "src/csn/registry.lisp"
     "src/execution/package.lisp" "src/execution/queue.lisp"
     "src/execution/writer.lisp" "src/execution/handoff.lisp"
     "src/execution/ready-types.lisp" "src/execution/ready.lisp"
     "src/storage/package.lisp" "src/storage/formats.lisp"
     "src/storage/segment-header.lisp" "src/storage/log-header.lisp"
     "src/storage/compaction-scan.lisp" "src/storage/control-payload.lisp"
     "src/storage/payload-record.lisp" "src/storage/payload-write.lisp"
     "src/io/package.lisp" "src/io/types.lisp" "src/io/native.lisp"
     "src/io/lifecycle.lisp" "src/io/transfer.lisp" "src/io/flush.lisp"
     "src/wal/package.lisp" "src/wal/types.lisp" "src/wal/builder.lisp"
     "src/wal/group.lisp" "src/wal/executor.lisp" "src/recovery/package.lisp"
     "src/recovery/scan.lisp" "src/recovery/decisions-package.lisp"
     "src/recovery/decisions-types.lisp" "src/recovery/decisions-sort.lisp"
     "src/recovery/decisions-radix.lisp" "src/recovery/decisions-build.lisp"
     "src/recovery/decisions-query.lisp" "src/recovery/manifest-package.lisp"
     "src/recovery/manifest-types.lisp" "src/recovery/manifest-decode.lisp"
     "src/recovery/manifest-fold.lisp" "src/recovery/manifest-build.lisp"
     "src/recovery/manifest-query.lisp" "src/recovery/inventory-types.lisp"
     "src/recovery/inventory-build.lisp" "src/recovery/inventory-query.lisp"
     "tests/smoke.lisp" "tests/foundation/support.lisp"
     "tests/foundation/binary.lisp" "tests/foundation/record.lisp"
     "tests/foundation/batch.lisp" "tests/codec/support.lisp"
     "tests/codec/utf8.lisp" "tests/codec/threads.lisp"
     "tests/codec/cbor-support.lisp" "tests/codec/cbor-header.lisp"
     "tests/codec/cbor-threads.lisp" "tests/csn/support.lisp"
     "tests/csn/registry.lisp" "tests/csn/threads.lisp"
     "tests/execution/support.lisp" "tests/execution/queue.lisp"
     "tests/execution/threads.lisp" "tests/execution/handoff.lisp"
     "tests/execution/ready.lisp" "tests/storage/support.lisp"
     "tests/storage/segment-header.lisp" "tests/storage/log-header.lisp"
     "tests/storage/compaction-scan.lisp" "tests/storage/control-payload.lisp"
     "tests/io/support.lisp" "tests/io/transfer.lisp" "tests/io/native.lisp"
     "tests/recovery/support.lisp" "tests/recovery/scan.lisp"
     "tests/recovery/corruption.lisp" "tests/recovery/decisions-support.lisp"
     "tests/recovery/decisions.lisp" "tests/recovery/decisions-audit.lisp"
     "tests/recovery/decisions-radix.lisp"
     "tests/recovery/manifest-support.lisp" "tests/recovery/manifest.lisp"
     "tests/recovery/manifest-audit.lisp"
     "tests/recovery/inventory-support.lisp" "tests/recovery/inventory.lisp"
     "tests/wal/support.lisp" "tests/wal/builder.lisp" "tests/wal/group.lisp"
     "tests/wal/fault.lisp" "tests/wal/native.lisp")
    :MISSING-SOURCE-REJECTED T))
  (:NAME :PARALLEL :ORIGINAL-PATH
   "spikes/out/4000528556-mutation-self-test-77907/report.lisp"
   :ORIGINAL-REPORT
   (:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
    ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
     (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
     (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
      :DIAGNOSTIC "Guasto avvio fixture." :LOG
      "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/2/test.log")
     (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE 0 :SIGNAL NIL
      :DIAGNOSTIC "Guasto raccolta fixture." :LOG
      "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/3/test.log")
     (:NAME "signaled" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9
      :DIAGNOSTIC "Worker terminato dal segnale 9." :LOG
      "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/4/test.log")))))
 :RAW-FILES
 ((:PATH "copier/report.lisp" :ORIGINAL-PATH
   #A((129) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-copy-self-test-77907/report.lisp")
   :BYTE-COUNT 3108 :GIT-BLOB "bce349f1aa6e211c26ff9364dc9c24da42bff6fa"
   :CONTENT "(:KIND :COPIER-SELF-TEST :STATUS :PASSED :SOURCE-FILES
 (\"src/package.lisp\" \"src/foundation/package.lisp\"
  \"src/foundation/conditions.lisp\" \"src/foundation/binary.lisp\"
  \"src/foundation/crc32c.lisp\" \"src/foundation/record.lisp\"
  \"src/foundation/batch.lisp\" \"src/codec/package.lisp\" \"src/codec/utf8.lisp\"
  \"src/codec/cbor-package.lisp\" \"src/codec/cbor-header.lisp\"
  \"src/csn/package.lisp\" \"src/csn/registry.lisp\" \"src/execution/package.lisp\"
  \"src/execution/queue.lisp\" \"src/execution/writer.lisp\"
  \"src/execution/handoff.lisp\" \"src/execution/ready-types.lisp\"
  \"src/execution/ready.lisp\" \"src/storage/package.lisp\"
  \"src/storage/formats.lisp\" \"src/storage/segment-header.lisp\"
  \"src/storage/log-header.lisp\" \"src/storage/compaction-scan.lisp\"
  \"src/storage/control-payload.lisp\" \"src/storage/payload-record.lisp\"
  \"src/storage/payload-write.lisp\" \"src/io/package.lisp\" \"src/io/types.lisp\"
  \"src/io/native.lisp\" \"src/io/lifecycle.lisp\" \"src/io/transfer.lisp\"
  \"src/io/flush.lisp\" \"src/wal/package.lisp\" \"src/wal/types.lisp\"
  \"src/wal/builder.lisp\" \"src/wal/group.lisp\" \"src/wal/executor.lisp\"
  \"src/recovery/package.lisp\" \"src/recovery/scan.lisp\"
  \"src/recovery/decisions-package.lisp\" \"src/recovery/decisions-types.lisp\"
  \"src/recovery/decisions-sort.lisp\" \"src/recovery/decisions-radix.lisp\"
  \"src/recovery/decisions-build.lisp\" \"src/recovery/decisions-query.lisp\"
  \"src/recovery/manifest-package.lisp\" \"src/recovery/manifest-types.lisp\"
  \"src/recovery/manifest-decode.lisp\" \"src/recovery/manifest-fold.lisp\"
  \"src/recovery/manifest-build.lisp\" \"src/recovery/manifest-query.lisp\"
  \"src/recovery/inventory-types.lisp\" \"src/recovery/inventory-build.lisp\"
  \"src/recovery/inventory-query.lisp\" \"tests/smoke.lisp\"
  \"tests/foundation/support.lisp\" \"tests/foundation/binary.lisp\"
  \"tests/foundation/record.lisp\" \"tests/foundation/batch.lisp\"
  \"tests/codec/support.lisp\" \"tests/codec/utf8.lisp\" \"tests/codec/threads.lisp\"
  \"tests/codec/cbor-support.lisp\" \"tests/codec/cbor-header.lisp\"
  \"tests/codec/cbor-threads.lisp\" \"tests/csn/support.lisp\"
  \"tests/csn/registry.lisp\" \"tests/csn/threads.lisp\"
  \"tests/execution/support.lisp\" \"tests/execution/queue.lisp\"
  \"tests/execution/threads.lisp\" \"tests/execution/handoff.lisp\"
  \"tests/execution/ready.lisp\" \"tests/storage/support.lisp\"
  \"tests/storage/segment-header.lisp\" \"tests/storage/log-header.lisp\"
  \"tests/storage/compaction-scan.lisp\" \"tests/storage/control-payload.lisp\"
  \"tests/io/support.lisp\" \"tests/io/transfer.lisp\" \"tests/io/native.lisp\"
  \"tests/recovery/support.lisp\" \"tests/recovery/scan.lisp\"
  \"tests/recovery/corruption.lisp\" \"tests/recovery/decisions-support.lisp\"
  \"tests/recovery/decisions.lisp\" \"tests/recovery/decisions-audit.lisp\"
  \"tests/recovery/decisions-radix.lisp\" \"tests/recovery/manifest-support.lisp\"
  \"tests/recovery/manifest.lisp\" \"tests/recovery/manifest-audit.lisp\"
  \"tests/recovery/inventory-support.lisp\" \"tests/recovery/inventory.lisp\"
  \"tests/wal/support.lisp\" \"tests/wal/builder.lisp\" \"tests/wal/group.lisp\"
  \"tests/wal/fault.lisp\" \"tests/wal/native.lisp\")
 :MISSING-SOURCE-REJECTED T)
")
  (:PATH "parallel/report.lisp" :ORIGINAL-PATH
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/report.lisp")
   :BYTE-COUNT 899 :GIT-BLOB "d9baa0e05aeb9b4c8fdbc00a552e8e8fb7a2546e"
   :CONTENT "(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME \"waiting\" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME \"failing\" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME \"launch-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
   :DIAGNOSTIC \"Guasto avvio fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/2/test.log\")
  (:NAME \"collect-error\" :RESULT :WORKER-ERROR :EXIT-CODE 0 :SIGNAL NIL
   :DIAGNOSTIC \"Guasto raccolta fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/3/test.log\")
  (:NAME \"signaled\" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9 :DIAGNOSTIC
   \"Worker terminato dal segnale 9.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/4/test.log\")))
")
  (:PATH "parallel/worker-fixture.lisp" :ORIGINAL-PATH
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/worker-fixture.lisp")
   :BYTE-COUNT 780 :GIT-BLOB "a8698802ac53ccb816de0347efdb50657ccb6ab5"
   :CONTENT "(REQUIRE :SB-POSIX)
(LET* ((ARGS (REST SB-EXT:*POSIX-ARGV*))
       (MODE (FIRST ARGS))
       (RELEASE (MERGE-PATHNAMES \"release\" (SECOND ARGS))))
  (COND
   ((STRING= MODE \"waiting\")
    (LOOP REPEAT 500
          UNTIL (PROBE-FILE RELEASE)
          DO (SLEEP 0.01))
    (SB-EXT:EXIT :CODE
                 (IF (PROBE-FILE RELEASE)
                     0
                     11)))
   ((STRING= MODE \"failing\")
    (WITH-OPEN-FILE (OUTPUT RELEASE :DIRECTION :OUTPUT :IF-EXISTS :ERROR)
      (WRITE-LINE \"rilasciato\" OUTPUT))
    (FORMAT T \"worker-fixture-failure~%\") (SB-EXT:EXIT :CODE 7))
   ((STRING= MODE \"signaled\")
    (FORMAT T \"inventory-test-start SIGNAL-FIXTURE~%\") (FINISH-OUTPUT)
    (SB-POSIX:KILL (SB-POSIX:GETPID) SB-POSIX:SIGKILL))
   (T (SB-EXT:EXIT :CODE 0))))")
  (:PATH "parallel/0/test.log" :ORIGINAL-PATH
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/0/test.log")
   :BYTE-COUNT 0 :GIT-BLOB "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT
   "")
  (:PATH "parallel/1/test.log" :ORIGINAL-PATH
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/1/test.log")
   :BYTE-COUNT 23 :GIT-BLOB "2af63261ff69d496cafb64fdb00f4cc91045cecc" :CONTENT
   "worker-fixture-failure
")
  (:PATH "parallel/3/test.log" :ORIGINAL-PATH
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/3/test.log")
   :BYTE-COUNT 0 :GIT-BLOB "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT
   "")
  (:PATH "parallel/4/test.log" :ORIGINAL-PATH
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000528556-mutation-self-test-77907/4/test.log")
   :BYTE-COUNT 36 :GIT-BLOB "bf2033e733a40617a5e304d5fcbc4d5953e88c21" :CONTENT
   "inventory-test-start SIGNAL-FIXTURE
"))
 :MISSING-FILES
 ((:PATH "copier/src/package.lisp" :REASON :INTENTIONAL-SELF-TEST-REMOVAL)
  (:PATH "parallel/2/test.log" :REASON :WORKER-LAUNCH-ERROR)))
