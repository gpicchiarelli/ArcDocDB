(:FINISHED-AT-UNIVERSAL-TIME 4000549218 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((100) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549187-check-92022-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.672567d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106070 :STORED-BYTES 878034
 :RESULTS
 ((:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549187-check-92022-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144049 :STORED-BYTES 410955 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144049 :UNCOMPRESSED-SHA256
    \"503dff7f054c0b010740b4d132f83a29d28d89d9140140c49eeceabd32aa822a\"
    :COMPRESSED-BYTES 410637 :COMPRESSED-SHA256
    \"944b7160ee3e35158854809347d46a4d57ddd40a3bb5c0a632021acfac6e153a\"))
  (:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549187-check-92022-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962021 :STORED-BYTES 467079 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962021 :UNCOMPRESSED-SHA256
    \"4d16fa4860a3dd4560605c9b426b1055d90070b78758d68386a1118a324ab581\"
    :COMPRESSED-BYTES 466761 :COMPRESSED-SHA256
    \"ded7bdca2e110ffc85ac5264b85f9e29cbb4c73a46aa9ee6eaeb8916bb7a4efa\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((91) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((100) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549187-check-92022-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "92022"))
 :STARTED-AT-UNIVERSAL-TIME 4000549216)
