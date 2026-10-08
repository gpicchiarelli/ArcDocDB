(:SCHEMA-VERSION 1 :KIND :IMPORTED-COMMAND-VERIFICATION :STATUS :FAILED
 :COMMAND ("make" "test" "lint") :EXIT-CODE 2 :SOURCE-BLOBS :NOT-RECORDED
 :ENVIRONMENT :NOT-RECORDED :ORIGINAL-PATH
 "/tmp/arcdocdb-storage-tests-001-failed.log" :STDOUT-AND-STDERR
 "sbcl --noinform --no-userinit --non-interactive --load tools/build.lisp
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/package.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/package-tmpGHU3ALSV.fasl
; compilation finished in 0:00:00.005
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/package.lisp\" (written 08 OCT 2026 10:03:10 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/package-tmpAAURSO1.fasl
; compilation finished in 0:00:00.003
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/conditions.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/conditions-tmp5GEXGEG5.fasl
; compilation finished in 0:00:00.007
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/binary.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/binary-tmpAR3FSGEY.fasl
; compilation finished in 0:00:00.030
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/crc32c.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/crc32c-tmpJAIDFZTC.fasl
; compilation finished in 0:00:00.032
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/record.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/record-tmp8V3J6PE9.fasl
; compilation finished in 0:00:00.203
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/batch.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/foundation/batch-tmp9V47YWQF.fasl
; compilation finished in 0:00:00.054
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/package.lisp\" (written 08 OCT 2026 10:03:10 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/package-tmp9BN22RMA.fasl
; compilation finished in 0:00:00.001
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/formats.lisp\" (written 08 OCT 2026 10:04:48 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/formats-tmp1CXFJSK9.fasl
; compilation finished in 0:00:00.008
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/segment-header.lisp\" (written 08 OCT 2026 10:04:48 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/segment-header-tmpX4BRKI0R.fasl
; compilation finished in 0:00:00.052
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/control-payload.lisp\" (written 08 OCT 2026 10:04:48 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/control-payload-tmpQ371UGST.fasl
; compilation finished in 0:00:00.060
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/payload-record.lisp\" (written 08 OCT 2026 10:04:48 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/payload-record-tmp2OWI3Q7U.fasl
; compilation finished in 0:00:00.042
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/payload-write.lisp\" (written 08 OCT 2026 10:06:25 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/src/storage/payload-write-tmp9KKTJMYV.fasl
; compilation finished in 0:00:00.101
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/smoke.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/smoke-tmpJU0JWO19.fasl
; compilation finished in 0:00:00.008
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/support.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/support-tmpZX2WN8N4.fasl
; compilation finished in 0:00:00.055
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/binary.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/binary-tmpOU81XRV0.fasl
; compilation finished in 0:00:00.036
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/record.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/record-tmpY2ML9CFA.fasl
; compilation finished in 0:00:00.135
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/batch.lisp\" (written 08 OCT 2026 09:57:21 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/foundation/batch-tmpX2JYJDQE.fasl
; compilation finished in 0:00:00.052
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/support.lisp\" (written 08 OCT 2026 10:10:15 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/support-tmpOPCILR65.fasl
; compilation finished in 0:00:00.074
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/segment-header.lisp\" (written 08 OCT 2026 10:10:15 PM):

; wrote /Users/gpicchiarelli/.cache/common-lisp/sbcl-2.6.9-macosx-arm64/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/segment-header-tmpRV9F8A9A.fasl
; compilation finished in 0:00:00.034
; compiling file \"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/control-payload.lisp\" (written 08 OCT 2026 10:10:15 PM):
; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 82, Column: 107, File-Position: 4893
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tests/storage/control-payload.lisp\" {8007452103}>

; compilation aborted after 0:00:00.042
While evaluating the form starting at line 23, column 0
  of #P\"/Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\":
Unhandled UIOP/LISP-BUILD:COMPILE-FILE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                          {80086B03B3}>:
  COMPILE-FILE-ERROR while
  compiling #<CL-SOURCE-FILE \"arcdocdb/tests\" \"storage\" \"control-payload\">

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80086B03B3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {8007E712F3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {8007E712F3}>)
2: (INVOKE-DEBUGGER #<UIOP/LISP-BUILD:COMPILE-FILE-ERROR {8007E712F3}>)
3: (ERROR UIOP/LISP-BUILD:COMPILE-FILE-ERROR :CONTEXT-FORMAT \"~/asdf-action::format-action/\" :CONTEXT-ARGUMENTS ((#<ASDF/LISP-ACTION:COMPILE-OP > . #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"storage\" \"control-payload\">)))
4: (UIOP/LISP-BUILD:CHECK-LISP-COMPILE-RESULTS NIL T T \"~/asdf-action::format-action/\" ((#<ASDF/LISP-ACTION:COMPILE-OP > . #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"storage\" \"control-payload\">)))
5: ((SB-PCL::EMF ASDF/ACTION:PERFORM) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:COMPILE-OP > #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"storage\" \"control-payload\">)
6: ((LAMBDA NIL :IN ASDF/ACTION:CALL-WHILE-VISITING-ACTION))
7: ((:METHOD ASDF/ACTION:PERFORM-WITH-RESTARTS :AROUND (T T)) #<ASDF/LISP-ACTION:COMPILE-OP > #<ASDF/LISP-ACTION:CL-SOURCE-FILE \"arcdocdb/tests\" \"storage\" \"control-payload\">) [fast-method]
8: ((:METHOD ASDF/PLAN:PERFORM-PLAN (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80090001F3}>) [fast-method]
9: ((FLET SB-C::WITH-IT :IN SB-C::%WITH-COMPILATION-UNIT))
10: ((:METHOD ASDF/PLAN:PERFORM-PLAN :AROUND (T)) #<ASDF/PLAN:SEQUENTIAL-PLAN {80090001F3}>) [fast-method]
11: ((:METHOD ASDF/OPERATE:OPERATE (ASDF/OPERATION:OPERATION ASDF/COMPONENT:COMPONENT)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\"> :PLAN-CLASS NIL :PLAN-OPTIONS NIL) [fast-method]
12: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">)
13: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
14: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) #<ASDF/LISP-ACTION:TEST-OP > #<ASDF/SYSTEM:SYSTEM \"arcdocdb\">) [fast-method]
15: ((SB-PCL::EMF ASDF/OPERATE:OPERATE) #<unused argument> #<unused argument> ASDF/LISP-ACTION:TEST-OP \"arcdocdb\")
16: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
17: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
18: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {80090000AB}> :OVERRIDE T :KEY NIL :OVERRIDE-CACHE T :OVERRIDE-FORCING NIL)
19: ((LAMBDA NIL :IN ASDF/OPERATE:OPERATE))
20: (ASDF/SESSION:CALL-WITH-ASDF-SESSION #<FUNCTION (LAMBDA NIL :IN ASDF/OPERATE:OPERATE) {800900001B}> :OVERRIDE NIL :KEY NIL :OVERRIDE-CACHE NIL :OVERRIDE-FORCING NIL)
21: ((:METHOD ASDF/OPERATE:OPERATE :AROUND (T T)) ASDF/LISP-ACTION:TEST-OP \"arcdocdb\") [fast-method]
22: (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")
23: (\"top level form\") [toplevel]
24: ((FLET \"G\" :IN SB-C::%COMPILE-IN-LEXENV))
25: (SB-C::%COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> NIL #<SB-C::SOURCE-INFO {80086805A3}> 3 NIL T T)
26: (SB-C:EVAL-WITH-COMPILE-IN-LEXENV (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV> #<SB-C::SOURCE-INFO {80086805A3}> 3 NIL)
27: (SB-IMPL::%SIMPLE-EVAL (LET ((SB-KERNEL:*HANDLER-CLUSTERS* (CONS (LOAD-TIME-VALUE # T) . #1=(SB-KERNEL:*HANDLER-CLUSTERS*)))) (DECLARE (DYNAMIC-EXTENT . #1#)) (FUNCTION TREAT-AS-ERROR) (FUNCTION TREAT-AS-ERROR) (PROGN (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\"))) #<NULL-LEXENV>)
28: (SB-INT:SIMPLE-EVAL-IN-LEXENV (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) #<NULL-LEXENV>)
29: (EVAL-TLF (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3 NIL)
30: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) 3)
31: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (HANDLER-BIND ((WARNING (FUNCTION TREAT-AS-ERROR)) (STYLE-WARNING (FUNCTION TREAT-AS-ERROR))) (ASDF/FIND-SYSTEM:LOAD-ASD (MERGE-PATHNAMES \"arcdocdb.asd\" (TRUENAME \"./\"))) (ASDF/OPERATE:LOAD-SYSTEM \"arcdocdb\" :FORCE T) (ASDF/OPERATE:TEST-SYSTEM \"arcdocdb\")) :CURRENT-INDEX 3)
32: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {1098A0D7B}> #<SB-C::SOURCE-INFO {80086805A3}> SB-C::INPUT-ERROR-IN-LOAD)
33: (SB-INT:LOAD-AS-SOURCE #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\" {8008680353}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
34: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\" {8008680353}> NIL)
35: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1098A084B}> #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\" {8008680353}> NIL #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\" {8008680353}>)
36: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/fondazioni-record-v2/ArcDocDB/tools/build.lisp\" {8008680353}> NIL)
37: (LOAD #P\"tools/build.lisp\" :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
38: (SB-IMPL::PROCESS-EVAL/LOAD-OPTIONS ((:LOAD . \"tools/build.lisp\") (:QUIT)))
39: (SB-IMPL::TOPLEVEL-INIT)
40: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
41: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
42: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
; 
; compilation unit aborted
;   caught 2 fatal ERROR conditions
;   caught 1 ERROR condition
make: *** [test] Error 1
"
 :LIMITS (:IMPORTED-AFTER-EXECUTION :SOURCE-STATE-NOT-RECONSTRUCTED))
