(:schema-version 1 :kind :imported-agent-probe :role :independent
 :scope :read-only-evidence-inspection :metadata-source :tool-history-only
 :absent-metadata :not-inferred :campaigns-executed nil
 :probes (
  (:purpose "HTML e lettura rapporti senza preload ASDF; HTML riuscito, lettore fallito" :command-text "python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
class Rows(HTMLParser):
    def __init__(self):
        super().__init__(); self.rows=[]; self.row=None; self.cell=None
    def handle_starttag(self, tag, attrs):
        if tag=='tr': self.row=[]
        if tag=='td' and self.row is not None: self.cell=''
    def handle_data(self, data):
        if self.cell is not None: self.cell+=data
    def handle_endtag(self, tag):
        if tag=='td' and self.cell is not None:
            self.row.append(self.cell.strip()); self.cell=None
        if tag=='tr' and self.row is not None:
            self.rows.append(self.row); self.row=None
p=Rows(); p.feed(Path('spikes/out/ready-coverage/cover-index.html').read_text())
for row in p.rows:
    if len(row)==7 and row[0].endswith('.lisp'):
        print(row[0], 'expressions', row[1]+'/'+row[2], 'branches', row[4]+'/'+row[5])
PY
sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(let ((*read-eval* nil))
 (let ((report (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations/report.lisp\")))
   (format t \"MUTATION-KEYS ~S~%\" (loop for (k v) on report by #'cddr collect k))
   (format t \"MUTATION-SUMMARY ~S~%\" (loop for k in '(:status :stage :baseline :source-consistency :planned-mutants :detected :survived :compile-failed :before-tests :diagnostic :limits :mutants) append (list k (getf report k)))))
 (let* ((report (arcdocdb.evidence:read-evidence \"spikes/out/4000520747-command-93257-0/report.lisp\"))
        (output (getf report :stdout)))
   (format t \"COMMAND-KEYS ~S~%\" (loop for (k v) on report by #'cddr collect k))
   (format t \"COMMAND-METADATA ~S~%\" (loop for k in '(:command :command-argv :process-argv :cwd :status :source-consistency :exit-code) append (list k (getf report k))))
   (format t \"BUILD-COUNTS ~S~%\" (loop for line in (uiop:split-string output :separator '(#\\Newline))
                                      when (or (search \" test \" line) (search \"avvis\" line)) collect line))))
LISP" :combined-tool-output "handoff.lisp expressions 173/190 branches 16/16
package.lisp expressions 0/1 branches 0/0
queue.lisp expressions 142/184 branches 24/34
ready-types.lisp expressions 170/187 branches 30/30
ready.lisp expressions 173/194 branches 20/22
writer.lisp expressions 190/218 branches 36/44
Unhandled SB-C::INPUT-ERROR-IN-LOAD in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                                 {80052B0003}>:
  READ error during LOAD:

    Package UIOP does not exist.

      Line: 10, Column: 69, File-Position: 929

      Stream: #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}>

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80052B0003}>
0: (SB-DEBUG::DEBUGGER-DISABLED-HOOK #<SB-C::INPUT-ERROR-IN-LOAD {80079339E3}> #<unused argument> :QUIT T)
1: (SB-DEBUG::RUN-HOOK *INVOKE-DEBUGGER-HOOK* #<SB-C::INPUT-ERROR-IN-LOAD {80079339E3}>)
2: (INVOKE-DEBUGGER #<SB-C::INPUT-ERROR-IN-LOAD {80079339E3}>)
3: (ERROR #<SB-C::INPUT-ERROR-IN-LOAD {80079339E3}>)
4: (SB-C:COMPILER-ERROR SB-C::INPUT-ERROR-IN-LOAD :CONDITION #<SB-INT:SIMPLE-READER-PACKAGE-ERROR \"Package ~A does not exist.\" {8007933983}> :STREAM #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}>)
5: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {105610F1B}> #<SB-C::SOURCE-INFO {80052607B3}> SB-C::INPUT-ERROR-IN-LOAD)
6: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
7: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}> NIL)
8: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {1056109EB}> #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}> NIL #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}>)
9: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}> NIL)
10: (LOAD #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
11: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {80052505B3}>)
12: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
13: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
14: (SB-IMPL::PROCESS-SCRIPT \"/dev/stdin\")
15: (SB-IMPL::TOPLEVEL-INIT)
16: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
17: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
18: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
" :tool-exit-code 1 :tool-wall-seconds 0.047238542 :tool-chunk-id "e9e54f")
  (:purpose "Lettura rapporti con preload ASDF; selezione compilation-failures precisata successivamente" :command-text "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let ((*read-eval* nil))
 (let ((report (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations/report.lisp\")))
   (format t \"MUTATION-KEYS ~S~%\" (loop for (k v) on report by #'cddr collect k))
   (format t \"MUTATION-SUMMARY ~S~%\" (loop for k in '(:status :stage :baseline :source-consistency :planned-mutants :detected :survived :compile-failed :before-tests :diagnostic :limits :mutants) append (list k (getf report k)))))
 (let* ((report (arcdocdb.evidence:read-evidence \"spikes/out/4000520747-command-93257-0/report.lisp\"))
        (output (getf report :stdout)))
   (format t \"COMMAND-KEYS ~S~%\" (loop for (k v) on report by #'cddr collect k))
   (format t \"COMMAND-METADATA ~S~%\" (loop for k in '(:command :command-argv :process-argv :cwd :status :source-consistency :exit-code) append (list k (getf report k))))
   (format t \"BUILD-COUNTS ~S~%\" (loop for line in (uiop:split-string output :separator '(#\\Newline))
                                      when (or (search \" test \" line) (search \"avvis\" line)) collect line))))
LISP" :combined-tool-output "MUTATION-KEYS (:SCHEMA-VERSION :KIND :STATUS :STAGE :PROCESS-ARGV
               :TOOL-ARGUMENTS :RECORDED-AT :SBCL :SOURCE-FINGERPRINTS-BEFORE
               :SOURCE-FINGERPRINTS-AFTER :SOURCE-CONSISTENCY :TARGETS
               :PLANNED-MUTANTS :BASELINE :BASELINE-RESULT :BASELINE-EXIT-CODE
               :BASELINE-LOG :MUTANTS :CURRENT-ORDINAL :CURRENT-MUTANT
               :CURRENT-LOG :DIAGNOSTIC :DETECTED :SURVIVED
               :COMPILATION-FAILURES :BEFORE-TESTS :LIMITS)
MUTATION-SUMMARY (:STATUS :OK :STAGE :COMPLETE :BASELINE :PASSED
                  :SOURCE-CONSISTENCY :STABLE :PLANNED-MUTANTS 12 :DETECTED 12
                  :SURVIVED 0 :COMPILE-FAILED NIL :BEFORE-TESTS 0 :DIAGNOSTIC
                  NIL :LIMITS
                  (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE
                   :STRICT-COMPILATION :TEST-EVENTS-AT-LINE-START
                   :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
                   :NO-POOL-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION)
                  :MUTANTS
                  ((:NAME \"ready-fifo-head-from-tail\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/0/test.log\")
                   (:NAME \"ready-tail-wrap-two\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/1/test.log\")
                   (:NAME \"ready-head-wrap-two\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/2/test.log\")
                   (:NAME \"ready-full-boundary\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/3/test.log\")
                   (:NAME \"ready-pop-count-unchanged\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/4/test.log\")
                   (:NAME \"ready-pop-keeps-reference\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/5/test.log\")
                   (:NAME \"ready-release-keeps-guard\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/6/test.log\")
                   (:NAME \"ready-scan-forgets-busy\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/7/test.log\")
                   (:NAME \"ready-scan-stops-on-busy\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/8/test.log\")
                   (:NAME \"ready-scan-misses-last-shard\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/9/test.log\")
                   (:NAME \"ready-success-cursor-stays\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/10/test.log\")
                   (:NAME \"ready-unsuccessful-cursor-stays\" :SOURCE-FILE
                    \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                    :LOG
                    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations/11/test.log\")))
COMMAND-KEYS (:SOURCE-CONSISTENCY :SOURCE-BLOBS-AFTER :WALL-SECONDS
              :FINISHED-AT-UNIVERSAL-TIME :SCHEMA-VERSION :KIND :ENVIRONMENT
              :COMMAND :STATUS :STARTED-AT-UNIVERSAL-TIME :SOURCE-BLOBS-BEFORE
              :STDOUT :STDERR :EXIT-CODE :LIMITS)
COMMAND-METADATA (:COMMAND
                  (\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                   \"--script\" \"spikes/out/ready-build-test.lisp\")
                  :COMMAND-ARGV NIL :PROCESS-ARGV NIL :CWD NIL :STATUS :OK
                  :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0)
BUILD-COUNTS (\"26 test delle fondazioni superati.\" \"17 test UTF-8 superati.\"
              \"51 test delle code writer superati.\"
              \"44 test dei metadati storage superati.\" \"18 test I/O superati.\"
              \"62 test recovery superati.\" \"19 test WAL superati.\"
              \"build e test: nessun avviso, tutti i controlli superati\")
" :tool-exit-code 0 :tool-wall-seconds 0.195860417 :tool-chunk-id "1db4a8")
  (:purpose "Lettura log con percorso baseline errato; shell exit 0 perché segue SBCL riuscito" :command-text "python3 - <<'PY'
from pathlib import Path
for p in [Path('spikes/out/ready-mutations/baseline.log'), *[Path('spikes/out/ready-mutations')/str(i)/'test.log' for i in range(12)]]:
    lines=p.read_text().splitlines()
    ok=[s for s in lines if s.startswith('ok    TEST-REQ-')]
    failed=[s for s in lines if s.lower().startswith(('fail ', 'error ', 'échec '))]
    if not failed:
        failed=[s for s in lines if 'TEST-REQ-' in s and not s.startswith('ok    ')]
    diagnostics=[s for s in lines if any(t in s.lower() for t in ['compilation failure', 'compile-file-error', 'warning:', 'style-warning'])]
    print(p.as_posix(), 'ok-events',len(ok),'first-failure',failed[:1],'compiler-diagnostics',diagnostics[:2])
PY
sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(let ((report (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations/report.lisp\")))
  (format t \"FINAL-MUTATION-COUNTS ~S~%\" (loop for k in '(:baseline-result :baseline-exit-code :compilation-failures :before-tests :detected :survived) append (list k (getf report k)))))
LISP" :combined-tool-output "Traceback (most recent call last):
  File \"<stdin>\", line 3, in <module>
  File \"/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/pathlib/__init__.py\", line 787, in read_text
    with self.open(mode='r', encoding=encoding, errors=errors, newline=newline) as f:
         ~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File \"/opt/homebrew/Cellar/python@3.14/3.14.7/Frameworks/Python.framework/Versions/3.14/lib/python3.14/pathlib/__init__.py\", line 771, in open
    return io.open(self, mode, buffering, encoding, errors, newline)
           ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
FileNotFoundError: [Errno 2] No such file or directory: 'spikes/out/ready-mutations/baseline.log'
FINAL-MUTATION-COUNTS (:BASELINE-RESULT :SURVIVED :BASELINE-EXIT-CODE 0
                       :COMPILATION-FAILURES 0 :BEFORE-TESTS 0 :DETECTED 12
                       :SURVIVED 0)
" :tool-exit-code 0 :tool-wall-seconds 0.082263042 :tool-chunk-id "8ba89d")
  (:purpose "Lettura log con percorso corretto; campo first-failure comprendeva erroneamente eventi start, sostituito dal probe seguente" :command-text "python3 - <<'PY'
from pathlib import Path
for p in [Path('spikes/out/ready-mutations/baseline/test.log'), *[Path('spikes/out/ready-mutations')/str(i)/'test.log' for i in range(12)]]:
    lines=p.read_text().splitlines()
    ok=[s for s in lines if s.startswith('ok    TEST-REQ-')]
    failed=[s for s in lines if s.lower().startswith(('fail ', 'error ', 'échec '))]
    if not failed:
        failed=[s for s in lines if 'TEST-REQ-' in s and not s.startswith('ok    ')]
    diagnostics=[s for s in lines if any(t in s.lower() for t in ['compilation failure', 'compile-file-error', 'warning:', 'style-warning'])]
    print(p.as_posix(), 'ok-events',len(ok),'first-failure',failed[:1],'compiler-diagnostics',diagnostics[:2])
PY" :combined-tool-output "spikes/out/ready-mutations/baseline/test.log ok-events 51 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/0/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/1/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/2/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/3/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/4/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/5/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/6/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/7/test.log ok-events 41 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/8/test.log ok-events 41 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/9/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/10/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
spikes/out/ready-mutations/11/test.log ok-events 34 first-failure ['execution-test-start TEST-REQ-AFF-008-WRITER-CONFIGURATION'] compiler-diagnostics []
" :tool-exit-code 0 :tool-wall-seconds 0.000008792 :tool-chunk-id "890958")
  (:purpose "Lettura finale dei log tramite ultimo evento start, completion e Unhandled; lettura benchmark riuscita" :command-text "python3 - <<'PY'
from pathlib import Path
for p in [Path('spikes/out/ready-mutations/baseline/test.log'), *[Path('spikes/out/ready-mutations')/str(i)/'test.log' for i in range(12)]]:
    lines=p.read_text().splitlines()
    events=[s for s in lines if s.startswith('execution-test-start ')]
    completed=[s for s in lines if s.startswith('execution-tests-complete ')]
    exceptions=[s for s in lines if s.startswith('Unhandled ')]
    print(p.as_posix(), 'started',len(events),'last-test',events[-1:] ,'complete',completed,'exception',exceptions[:1])
PY
sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(let ((*read-eval* nil))
 (let ((r (arcdocdb.evidence:read-evidence \"spikes/out/ready-allocations/report.lisp\")))
   (format t \"BENCH-METADATA ~S~%\" (loop for k in '(:status :stage :source-consistency :workers :iterations :warmup :replicas :diagnostic :limits :self-test) append (list k (getf r k))))
   (dolist (c (getf r :campaigns))
     (format t \"BENCH-SCENARIO ~S~%\" (loop for k in '(:scenario :shards :capacity-per-shard :ready-published-per-cycle :calls-per-cycle :expected-token :status :stage :diagnostic :samples) append (list k (getf c k))))))
 (let ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000520933-command-3549-0/report.lisp\")))
   (format t \"BENCH-COMMAND ~S~%\" (loop for k in '(:status :source-consistency :exit-code :command :stderr) append (list k (getf r k))))))
LISP" :combined-tool-output "spikes/out/ready-mutations/baseline/test.log started 51 last-test ['execution-test-start TEST-REQ-CON-002-READY-COMPETING-CONSUMERS-TAKE-ONE-REFERENCE-PER-WAVE'] complete ['execution-tests-complete 51'] exception []
spikes/out/ready-mutations/0/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/1/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/2/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/3/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/4/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/5/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/6/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/7/test.log started 42 last-test ['execution-test-start TEST-REQ-CON-004-READY-SKIPS-BUSY-HOME-AND-PRESERVES-LOCAL-RING'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/8/test.log started 42 last-test ['execution-test-start TEST-REQ-CON-004-READY-SKIPS-BUSY-HOME-AND-PRESERVES-LOCAL-RING'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/9/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/10/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
spikes/out/ready-mutations/11/test.log started 35 last-test ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] exception ['Unhandled SIMPLE-ERROR in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING']
BENCH-METADATA (:STATUS :OK :STAGE :COMPLETE :SOURCE-CONSISTENCY :STABLE
                :WORKERS 1 :ITERATIONS 4096 :WARMUP 128 :REPLICAS 5 :DIAGNOSTIC
                NIL :LIMITS
                (:SUCCESS-PATH-ONLY :SERIAL-COMPOSED-HANDOFF-AND-READY-CYCLES
                 :PREALLOCATED-INPUTS :COUNTER-NOT-ABSOLUTE-NONALLOCATION-PROOF
                 :EXTERNAL-LOAD-UNCONTROLLED :CLOCK-ZERO-IS-BELOW-RESOLUTION
                 :NO-THROUGHPUT-P99-SCALING-OR-TIME-THRESHOLD
                 :NO-POOL-DEVICE-DURABILITY-OR-RELEASE-QUALIFICATION)
                :SELF-TEST
                (:STATUS :OK :BASELINE
                 (:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 37 :SECONDS 3.7d-5 :TIME-QUALITY :MEASURED :SINK
                  8386560 :EXPECTED-SINK 8386560 :EXPECTED-RETURN-TOKEN 0
                  :DIAGNOSTIC NIL)
                 :POSITIVE-CONTROL
                 (:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 16
                  :WARMUP-ITERATIONS 0 :COMPLETED-ITERATIONS 16 :HEAP-BYTES
                  16777472 :RAW-TICKS 36 :SECONDS 3.6d-5 :TIME-QUALITY
                  :MEASURED :SINK 16777336 :EXPECTED-SINK 16777336
                  :EXPECTED-RETURN-TOKEN 1048576 :DIAGNOSTIC NIL)
                 :WRONG-SINK :REJECTED :ZERO-CLOCK :BELOW-RESOLUTION
                 :PARTIAL-REPORT :PRESERVED :EXISTING-DESTINATION :PRESERVED
                 :COMPOSED-API-PROBES
                 ((:SHARDS 1 :CAPACITY-PER-SHARD 3 :PROBE
                   (:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4
                    :WARMUP-ITERATIONS 0 :COMPLETED-ITERATIONS 4 :HEAP-BYTES 0
                    :RAW-TICKS 10 :SECONDS 1.0d-5 :TIME-QUALITY :MEASURED :SINK
                    846 :EXPECTED-SINK 846 :EXPECTED-RETURN-TOKEN 210
                    :DIAGNOSTIC NIL))
                  (:SHARDS 4 :CAPACITY-PER-SHARD 3 :PROBE
                   (:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4
                    :WARMUP-ITERATIONS 0 :COMPLETED-ITERATIONS 4 :HEAP-BYTES 0
                    :RAW-TICKS 24 :SECONDS 2.4d-5 :TIME-QUALITY :MEASURED :SINK
                    4314 :EXPECTED-SINK 4314 :EXPECTED-RETURN-TOKEN 1077
                    :DIAGNOSTIC NIL)))))
BENCH-SCENARIO (:SCENARIO :ONE-SHARD :SHARDS 1 :CAPACITY-PER-SHARD 3
                :READY-PUBLISHED-PER-CYCLE 2 :CALLS-PER-CYCLE 13
                :EXPECTED-TOKEN 210 :STATUS :OK :STAGE :COMPLETE :DIAGNOSTIC
                NIL :SAMPLES
                ((:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 3595 :SECONDS 0.003595d0 :TIME-QUALITY :MEASURED
                  :SINK 9246720 :EXPECTED-SINK 9246720 :EXPECTED-RETURN-TOKEN
                  210 :DIAGNOSTIC NIL)
                 (:REPLICA 1 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 3551 :SECONDS 0.003551d0 :TIME-QUALITY :MEASURED
                  :SINK 9246720 :EXPECTED-SINK 9246720 :EXPECTED-RETURN-TOKEN
                  210 :DIAGNOSTIC NIL)
                 (:REPLICA 2 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 3578 :SECONDS 0.003578d0 :TIME-QUALITY :MEASURED
                  :SINK 9246720 :EXPECTED-SINK 9246720 :EXPECTED-RETURN-TOKEN
                  210 :DIAGNOSTIC NIL)
                 (:REPLICA 3 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 3584 :SECONDS 0.003584d0 :TIME-QUALITY :MEASURED
                  :SINK 9246720 :EXPECTED-SINK 9246720 :EXPECTED-RETURN-TOKEN
                  210 :DIAGNOSTIC NIL)
                 (:REPLICA 4 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 3618 :SECONDS 0.003618d0 :TIME-QUALITY :MEASURED
                  :SINK 9246720 :EXPECTED-SINK 9246720 :EXPECTED-RETURN-TOKEN
                  210 :DIAGNOSTIC NIL)))
BENCH-SCENARIO (:SCENARIO :FOUR-SHARDS :SHARDS 4 :CAPACITY-PER-SHARD 3
                :READY-PUBLISHED-PER-CYCLE 8 :CALLS-PER-CYCLE 49
                :EXPECTED-TOKEN 1077 :STATUS :OK :STAGE :COMPLETE :DIAGNOSTIC
                NIL :SAMPLES
                ((:REPLICA 0 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 13623 :SECONDS 0.013623d0 :TIME-QUALITY
                  :MEASURED :SINK 12797952 :EXPECTED-SINK 12797952
                  :EXPECTED-RETURN-TOKEN 1077 :DIAGNOSTIC NIL)
                 (:REPLICA 1 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 13710 :SECONDS 0.01371d0 :TIME-QUALITY :MEASURED
                  :SINK 12797952 :EXPECTED-SINK 12797952 :EXPECTED-RETURN-TOKEN
                  1077 :DIAGNOSTIC NIL)
                 (:REPLICA 2 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 13647 :SECONDS 0.013647d0 :TIME-QUALITY
                  :MEASURED :SINK 12797952 :EXPECTED-SINK 12797952
                  :EXPECTED-RETURN-TOKEN 1077 :DIAGNOSTIC NIL)
                 (:REPLICA 3 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 13748 :SECONDS 0.013748d0 :TIME-QUALITY
                  :MEASURED :SINK 12797952 :EXPECTED-SINK 12797952
                  :EXPECTED-RETURN-TOKEN 1077 :DIAGNOSTIC NIL)
                 (:REPLICA 4 :STATUS :OK :STAGE :COMPLETE :ITERATIONS 4096
                  :WARMUP-ITERATIONS 128 :COMPLETED-ITERATIONS 4096 :HEAP-BYTES
                  0 :RAW-TICKS 13632 :SECONDS 0.013632d0 :TIME-QUALITY
                  :MEASURED :SINK 12797952 :EXPECTED-SINK 12797952
                  :EXPECTED-RETURN-TOKEN 1077 :DIAGNOSTIC NIL)))
BENCH-COMMAND (:STATUS :OK :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :COMMAND
               (\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                \"--disable-debugger\" \"--script\" \"tools/writer-ready-bench.lisp\"
                \"--bench\" \"spikes/out/ready-allocations/\")
               :STDERR \"\")
" :tool-exit-code 0 :tool-wall-seconds 0.052914209 :tool-chunk-id "d9b52c")
 ))

