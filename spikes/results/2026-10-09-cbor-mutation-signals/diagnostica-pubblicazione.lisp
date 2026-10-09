(:schema-version 1 :kind :publication-diagnostic :scope :evidence-summary
 :source :local-tool-command-result :status :failed :exit-code 1
 :command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script" "/tmp/publish-cbor-mutation-signals.lisp")
 :cause :root-report-selector-assumed-relative-path
 :raw-output "Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                    {80086A04B3}>:
  No root report header-mutazioni.lisp

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80086A04B3}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SIMPLE-ERROR \"No root report ~A\" {8006D0CA03}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SIMPLE-ERROR \"No root report ~A\" {8006D0CA03}>)
2: (INVOKE-DEBUGGER #<SIMPLE-ERROR \"No root report ~A\" {8006D0CA03}>)
3: (ERROR \"No root report ~A\" \"header-mutazioni.lisp\")
4: (ROOT-REPORT \"header-mutazioni.lisp\")
5: (MAIN)
6: (SB-INT:SIMPLE-EVAL-IN-LEXENV (MAIN) #<NULL-LEXENV>)
7: (EVAL-TLF (MAIN) 7 NIL)
8: ((LABELS SB-FASL::EVAL-FORM :IN SB-INT:LOAD-AS-SOURCE) (MAIN) 7)
9: ((LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) (MAIN) :CURRENT-INDEX 7)
10: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107B50F1B}> #<SB-C::SOURCE-INFO {8008680423}> SB-C::INPUT-ERROR-IN-LOAD)
11: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
12: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}> NIL)
13: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107B509EB}> #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}> NIL #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}>)
14: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}> NIL)
15: (LOAD #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
16: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /tmp/publish-cbor-mutation-signals.lisp\" {8008680043}>)
17: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
18: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
19: (SB-IMPL::PROCESS-SCRIPT \"/tmp/publish-cbor-mutation-signals.lisp\")
20: (SB-IMPL::TOPLEVEL-INIT)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
23: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
"
 :correction :select-unique-report-by-file-name
 :limits (:publication-helper-failure :no-product-or-test-execution
          :raw-campaign-reports-unchanged :no-result-promotion))
