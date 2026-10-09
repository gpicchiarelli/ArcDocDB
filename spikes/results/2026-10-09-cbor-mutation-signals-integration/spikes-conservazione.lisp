(:FINISHED-AT-UNIVERSAL-TIME 4000549813 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((105) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000549782-check-39441-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.890736d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106871 :STORED-BYTES 878590
 :RESULTS
 ((:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000549782-check-39441-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410935 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"55c0321a79098274c4f2e35caa173e4262b8e65bfaa31bcc699674f5c5d44d64\"
    :COMPRESSED-BYTES 410617 :COMPRESSED-SHA256
    \"55198f51ad259e731d143f397f817c30d1f4a8a92bff7d0e89354ce1a5fa93f3\"))
  (:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000549782-check-39441-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962752 :STORED-BYTES 467655 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962752 :UNCOMPRESSED-SHA256
    \"cf83296b110224e2c1187c294979cd2b938bcd79daaba416bc249732cf1fc647\"
    :COMPRESSED-BYTES 467337 :COMPRESSED-SHA256
    \"22ef0b876a008df3a606c62f8dc884601e717742b59a4d816794d2781bc8a9fd\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((96) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((105) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000549782-check-39441-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "39441"))
 :STARTED-AT-UNIVERSAL-TIME 4000549811)
