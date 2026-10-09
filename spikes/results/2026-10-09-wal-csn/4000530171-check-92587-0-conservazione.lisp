(:FINISHED-AT-UNIVERSAL-TIME 4000530205 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((100) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530171-check-92587-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.794317d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106051 :STORED-BYTES 877888
 :RESULTS
 ((:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530171-check-92587-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410953 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"d923d50e43ac68b055e6ff0f894c0c4c848bda7be98897065983e7afbfdac310\"
    :COMPRESSED-BYTES 410635 :COMPRESSED-SHA256
    \"550a234431df5f8484aa2200184e250d47d2443cc3ffe81c5b12025815ae5841\"))
  (:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530171-check-92587-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962000 :STORED-BYTES 466935 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962000 :UNCOMPRESSED-SHA256
    \"4f59d211e66f088ac778d0a719383eae088b501372013f46f7c765e6c37b98a3\"
    :COMPRESSED-BYTES 466617 :COMPRESSED-SHA256
    \"cd772742074a7fee70c97ef142f89fd4e7cbfcfc0f35f53b8af905d570c47e2f\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((91) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((100) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530171-check-92587-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "92587"))
 :STARTED-AT-UNIVERSAL-TIME 4000530203)
