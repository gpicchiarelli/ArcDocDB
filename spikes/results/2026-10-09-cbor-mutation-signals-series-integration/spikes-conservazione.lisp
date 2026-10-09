(:FINISHED-AT-UNIVERSAL-TIME 4000551069 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((105) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000551034-check-30152-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 2.196371d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106927 :STORED-BYTES 878630
 :RESULTS
 ((:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000551034-check-30152-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410957 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"67409a40d974926e3b37d0b23e0879d3da44805e7c67e2e8e8052c79cd700295\"
    :COMPRESSED-BYTES 410639 :COMPRESSED-SHA256
    \"f89a2e5abd9ce48a6e80ec94793dd9f52c4b816ef6520dc1507e870410f602fb\"))
  (:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000551034-check-30152-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962808 :STORED-BYTES 467673 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962808 :UNCOMPRESSED-SHA256
    \"4a3f6d88f118289563a6db6e17d7b2008e8c1a1176bf87219d4f5a9ca0940216\"
    :COMPRESSED-BYTES 467355 :COMPRESSED-SHA256
    \"cf396514bc3961422c200bea812ff34b869b1e6082b3693a5ebce88fb714f9aa\")))
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
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000551034-check-30152-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "30152"))
 :STARTED-AT-UNIVERSAL-TIME 4000551066)
