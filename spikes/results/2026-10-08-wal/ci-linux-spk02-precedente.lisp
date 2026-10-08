(:SCHEMA-VERSION 1 :ID "SPK-02" :COMMAND
 (#A((13) BASE-CHAR . "/usr/bin/sbcl") "--dynamic-space-size" "4096"
  "--noinform" "--no-userinit" "--no-sysinit" "--script"
  "spikes/SPK-02-gc/run.lisp" "--check")
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000485356 :FINISHED-AT-UNIVERSAL-TIME
 4000485356 :WALL-SECONDS 0.128022d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
   "9fbe499100da40c2f7a14072af67c35c734949c5")
  (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
   "01f6760c75fa6e96a480fca41b1426941a9f703d"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
   "9fbe499100da40c2f7a14072af67c35c734949c5")
  (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
   "01f6760c75fa6e96a480fca41b1426941a9f703d"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK02 :MESSAGE
  #A((90) BASE-CHAR
     . "SPK02 compilazione fallita: /home/runner/work/ArcDocDB/ArcDocDB/spikes/SPK-02-gc/core.lisp"))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK02 :MESSAGE
 #A((90) BASE-CHAR
    . \"SPK02 compilazione fallita: /home/runner/work/ArcDocDB/ArcDocDB/spikes/SPK-02-gc/core.lisp\"))
"
 :STDERR "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     Symbol \"*GC-REAL-TIME*\" not found in the SB-EXT package.
;   
;       Line: 303, Column: 68, File-Position: 13963
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /home/runner/work/ArcDocDB/ArcDocDB/spikes/SPK-02-gc/core.lisp\" {10017B8563}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
")
