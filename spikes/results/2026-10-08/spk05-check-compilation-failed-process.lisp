(:SCHEMA-VERSION 1 :ID "SPK-05" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-05-segment-read/run.lisp"
  #A((7) BASE-CHAR . "--check"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000478621 :FINISHED-AT-UNIVERSAL-TIME
 4000478622 :WALL-SECONDS 0.716466d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "b4df3c7ba8d13e24794e3dbc6ac794eab4e5a6a1")
  (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
   "c67a3ae8e672f96d9105deb935fb621b07d67afb")
  (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp") :GIT-BLOB
   "86959aeff6d931c451705622fed06686d47cf67e")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "8c7bf2cab38fa7027dea6faed3257bef50b0ccbf")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "16e4eba7d9aecb42abfe4721fcedf7138241a009"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "b4df3c7ba8d13e24794e3dbc6ac794eab4e5a6a1")
  (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
   "c67a3ae8e672f96d9105deb935fb621b07d67afb")
  (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp") :GIT-BLOB
   "86959aeff6d931c451705622fed06686d47cf67e")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "8c7bf2cab38fa7027dea6faed3257bef50b0ccbf")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "16e4eba7d9aecb42abfe4721fcedf7138241a009"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK-05 :MESSAGE
  #A((106) BASE-CHAR
     . "Compilazione SPK-05 fallita: /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-05-segment-read/core.lisp."))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK-05 :MESSAGE
 #A((106) BASE-CHAR
    . \"Compilazione SPK-05 fallita: /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-05-segment-read/core.lisp.\"))
"
 :STDERR "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 332, Column: 94, File-Position: 18884
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-05-segment-read/core.lisp\" {800D1B4673}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
")
