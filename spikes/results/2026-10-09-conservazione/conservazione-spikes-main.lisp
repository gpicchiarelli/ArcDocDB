(:FINISHED-AT-UNIVERSAL-TIME 4000512062 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((96) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000512027-check-586-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.88321d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106421 :STORED-BYTES 878179
 :RESULTS
 ((:PATH
   #A((107) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000512027-check-586-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410946 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"ada2427f178419c15f542a5de8dbf07e652326777122d9a8913fabee23ee81e2\"
    :COMPRESSED-BYTES 410628 :COMPRESSED-SHA256
    \"ff04cc7544935f59cda70b78e95cda40cc3b270210fe7245a896555e548d7756\"))
  (:PATH
   #A((107) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000512027-check-586-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962302 :STORED-BYTES 467233 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962302 :UNCOMPRESSED-SHA256
    \"cc02f9230b49146449fcc21283b85c26110cc094041ec6c928cbbd4baffe0b4a\"
    :COMPRESSED-BYTES 466915 :COMPRESSED-SHA256
    \"4815c537b446d4f40924e1bf559cd59e1c7ebb21f440d89ec7183ef73efe4fe8\")))
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
  #A((96) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/prove-compatte/ArcDocDB/spikes/out/4000512027-check-586-0/")
  "--jobs" "4" "--finished-owner-pid" #A((3) BASE-CHAR . "586"))
 :STARTED-AT-UNIVERSAL-TIME 4000512060)
