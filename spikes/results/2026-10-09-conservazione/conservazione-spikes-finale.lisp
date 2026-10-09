(:FINISHED-AT-UNIVERSAL-TIME 4000510327 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((98) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000510295-check-48997-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.734447d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57109514 :STORED-BYTES 878811
 :RESULTS
 ((:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000510295-check-48997-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410943 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"5e7ff6e8a2699575a01d8fde82687c61aa2ec94d4ca98d4c4bf8f85ee5eb624c\"
    :COMPRESSED-BYTES 410625 :COMPRESSED-SHA256
    \"b9102072efecbcfd0c6a5d5deab8b8fdf5f0fa8785d2a47751536031290ed9cf\"))
  (:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000510295-check-48997-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28965395 :STORED-BYTES 467868 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28965395 :UNCOMPRESSED-SHA256
    \"6d9b6d77a9c322a754893aefa5b0d9a3f669e536481b8c6f18582799f5d8cc68\"
    :COMPRESSED-BYTES 467550 :COMPRESSED-SHA256
    \"ea822e5e50149476904d04f40a015343edd9567822f705736f102f61024d4ba6\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((89) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((98) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000510295-check-48997-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "48997"))
 :STARTED-AT-UNIVERSAL-TIME 4000510325)
