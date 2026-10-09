(:FINISHED-AT-UNIVERSAL-TIME 4000512988 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((101) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512956-check-21876-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.567666d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57114913 :STORED-BYTES 879696
 :RESULTS
 ((:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512956-check-21876-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144187 :STORED-BYTES 410981 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144187 :UNCOMPRESSED-SHA256
    \"1218ca4d0403f338e3cba25057b24e35518dab0cf38c177086ba56416120fe1f\"
    :COMPRESSED-BYTES 410663 :COMPRESSED-SHA256
    \"a9cd23378ec48f3884e665a27a1e8f4d7b6d22930c56e3cdd8f4400fcdbb7f14\"))
  (:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512956-check-21876-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28970726 :STORED-BYTES 468715 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28970726 :UNCOMPRESSED-SHA256
    \"5a934da1d3fc6027e28730d3ea0b1aafa47cf97238f29c46e6bacd49d8b57455\"
    :COMPRESSED-BYTES 468397 :COMPRESSED-SHA256
    \"e2e3da4527958b9d26a37d37a74e5892c30f8e7eab9c1b0607587a8b2cfb1d55\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((92) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((101) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512956-check-21876-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "21876"))
 :STARTED-AT-UNIVERSAL-TIME 4000512986)
