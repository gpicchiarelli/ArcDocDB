(:FINISHED-AT-UNIVERSAL-TIME 4000552988 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((101) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.762623d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106838 :STORED-BYTES 878421
 :RESULTS
 ((:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410944 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"2ad1ab51d9684e9f00b1f60bdebf4f3e05bd12fefb6a286d177519bfc58ce100\"
    :COMPRESSED-BYTES 410626 :COMPRESSED-SHA256
    \"f8527b27d1f21748a9d6ad278b6dc6578eca3f1deba83a10a17aa2b8807b6940\"))
  (:PATH
   #A((112) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962719 :STORED-BYTES 467477 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962719 :UNCOMPRESSED-SHA256
    \"69966b472b8643a76ae6b8658a7f70f3f95e1b63806d5cc7ffcf7667e1aa162a\"
    :COMPRESSED-BYTES 467159 :COMPRESSED-SHA256
    \"d65d7a467ae8cc2ccfabfc6ee7fc038e9f3b391afbbb1c52cb6b5d9ee0ec864d\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((92) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((101) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "82980"))
 :STARTED-AT-UNIVERSAL-TIME 4000552986)
