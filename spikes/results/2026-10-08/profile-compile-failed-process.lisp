(:SCHEMA-VERSION 1 :ID "SPK-01" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-01-primary-index/run.lisp"
  #A((9) BASE-CHAR . "--profile"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000474442 :FINISHED-AT-UNIVERSAL-TIME
 4000474443 :WALL-SECONDS 0.400794d0 :STATUS :FAILED :RESULT NIL :STDOUT
 "(:SPIKE :SPK-01 :STATUS :ERROR :CONDITION \"Compilazione profilo fallita.\")
"
 :STDERR "; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 45, Column: 59, File-Position: 2109
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/profile.lisp\" {800CE161E3}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
")
