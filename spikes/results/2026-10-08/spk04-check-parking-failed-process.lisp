(:SCHEMA-VERSION 1 :ID "SPK-04" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-04-writer-pool/run.lisp"
  #A((7) BASE-CHAR . "--check"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000477086 :FINISHED-AT-UNIVERSAL-TIME
 4000477087 :WALL-SECONDS 0.915313d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
  (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
   "77056cc1f695574ed0f4d34795b99aaea736f378")
  (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
   "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
  (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
   "1211d8aeabb40bedec914c2b0e45556061b1376b")
  (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
   "2050948e1856ce9814195156e7be1a4516dffa52"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
  (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
   "77056cc1f695574ed0f4d34795b99aaea736f378")
  (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
   "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
  (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
   "1211d8aeabb40bedec914c2b0e45556061b1376b")
  (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
   "2050948e1856ce9814195156e7be1a4516dffa52"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK-04 :MESSAGE
  #A((110) BASE-CHAR
     . "Compilazione SPK-04 fallita: /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-04-writer-pool/parcheggi.lisp."))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK-04 :MESSAGE
 #A((110) BASE-CHAR
    . \"Compilazione SPK-04 fallita: /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-04-writer-pool/parcheggi.lisp.\"))
"
 :STDERR "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 464, Column: 60, File-Position: 22832
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-04-writer-pool/parcheggi.lisp\" {800ECE69C3}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
")
