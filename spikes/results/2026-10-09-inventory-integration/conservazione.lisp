(:FINISHED-AT-UNIVERSAL-TIME 4000545919 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((102) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545886-check-51151-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.649627d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106329 :STORED-BYTES 877900
 :RESULTS
 ((:PATH
   #A((113) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545886-check-51151-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410956 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"cf66fe1c5192360f6b28fd520db28fc174dac304deef03846e6aa9693daeb25c\"
    :COMPRESSED-BYTES 410638 :COMPRESSED-SHA256
    \"049fd2ccd4ff6b8f9ca75bc509b69287f6f1185fa5602beb2aaf0466fd02158d\"))
  (:PATH
   #A((113) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545886-check-51151-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962210 :STORED-BYTES 466944 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962210 :UNCOMPRESSED-SHA256
    \"585cf770e980f43c69782ca85fe2439e516ec9d5e63e43e7888e8c7720aba9e6\"
    :COMPRESSED-BYTES 466626 :COMPRESSED-SHA256
    \"48ee63d56b90779add8bb52498f82d56e719ca8c1d205c892ba4f0fdd06bba91\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((93) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((102) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545886-check-51151-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "51151"))
 :STARTED-AT-UNIVERSAL-TIME 4000545917)
