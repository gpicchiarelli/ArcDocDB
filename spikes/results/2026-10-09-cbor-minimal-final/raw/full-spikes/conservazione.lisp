(:FINISHED-AT-UNIVERSAL-TIME 4000548207 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((98) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.882631d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106459 :STORED-BYTES 878306
 :RESULTS
 ((:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144283 :STORED-BYTES 410993 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144283 :UNCOMPRESSED-SHA256
    \"da21cd5ec10cad447328566868fcb8f2ec06e3465ecd493ae8e2ba47801574ba\"
    :COMPRESSED-BYTES 410675 :COMPRESSED-SHA256
    \"6d4c492345f9cf1cad669733b4502a21fdf96c2f14eaa0707400ea9103fe1e0a\"))
  (:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962176 :STORED-BYTES 467313 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962176 :UNCOMPRESSED-SHA256
    \"524b33def82e735f103122468a923806aabb00ae5456512d4908c05d5a0d5e2b\"
    :COMPRESSED-BYTES 466995 :COMPRESSED-SHA256
    \"06a5008ad4e0bbf65ec57bca01e5c64e878d258d6511771283c9e5bbdbc33a11\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((89) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((98) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/4000548174-check-45397-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "45397"))
 :STARTED-AT-UNIVERSAL-TIME 4000548204)
