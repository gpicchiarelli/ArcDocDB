(:FINISHED-AT-UNIVERSAL-TIME 4000520210 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((101) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520174-check-77665-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.876258d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57115914 :STORED-BYTES 879629
 :RESULTS
 ((:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520174-check-77665-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144187 :STORED-BYTES 410979 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144187 :UNCOMPRESSED-SHA256
    \"2303dbc14054586d36db9687df630d77bd150ea91e0a16ce1806050de3aeedb1\"
    :COMPRESSED-BYTES 410661 :COMPRESSED-SHA256
    \"67dbad920c9345b9227cbe4d1d2d41233b04bb7771c7d08623b1df44e20e7439\"))
  (:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520174-check-77665-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28971727 :STORED-BYTES 468650 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28971727 :UNCOMPRESSED-SHA256
    \"8ef06e4055853a80b6999e5825e5e731edfa8eb10f95107349f881d62e791c9b\"
    :COMPRESSED-BYTES 468332 :COMPRESSED-SHA256
    \"2c21e2fcb96f7441b77aef94bcd6101ba982ff2b5eaeefa4f24eac1b384ac882\")))
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
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520174-check-77665-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "77665"))
 :STARTED-AT-UNIVERSAL-TIME 4000520208)
