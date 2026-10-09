(:SCHEMA-VERSION 1 :KIND :IMPORTED-AGENT-PROBE :ROLE :INDEPENDENT :SCOPE
 :HARDENED-WRITER-READY-EVIDENCE-AND-MAIN-INTEGRATION :METADATA-SOURCE
 :TOOL-HISTORY-ONLY :ABSENT-METADATA :NOT-INFERRED :CAMPAIGNS-EXECUTED NIL
 :ORIGINAL-MASTER-PRESERVED T :PROBES
 ((:PURPOSE "Lettura dei record strict, SIGKILL e prima conservazione"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(dolist (path '(\"spikes/out/4000521809-command-41045-0/report.lisp\"
                \"spikes/out/4000521810-ready-signal-self-test-41080/report.lisp\"
                \"spikes/out/4000521888-command-44171-0/report.lisp\"))
  (let ((r (arcdocdb.evidence:read-evidence path)))
    (format t \"~%REPORT ~A~%~S~%\" path
            (loop for k in '(:schema-version :kind :status :stage :source-consistency :exit-code :command :baseline :detected :worker-errors :mutants :stdout :stderr :limits)
                  for value = (getf r k)
                  when value append (list k value)))))
LISP"
   :COMBINED-TOOL-OUTPUT "
REPORT spikes/out/4000521809-command-41045-0/report.lisp
(:SCHEMA-VERSION 1 :KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
 :STABLE :EXIT-CODE 0 :COMMAND
 (\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\" \"--disable-debugger\"
  \"--script\" \"spikes/out/writer-ready-mutation-final-self-test.lisp\"
  \"tools/writer-ready-mutation.lisp\")
 :STDOUT
 \"Writer ready: PASSED, baseline PENDING, rilevati 0/1; /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/4000521810-ready-signal-self-test-41080/report.lisp
Writer ready: self-test segnale OS superato; /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/4000521810-ready-signal-self-test-41080/report.lisp
Writer ready: self-test superato, nessuna campagna eseguita.
Tool ready tools/writer-ready-mutation.lisp: COMPILE-FILE completo e --self-test FASL superati.
\"
 :STDERR \"\" :LIMITS
 (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
  :NO-AUTOMATIC-REQUIREMENT-PROMOTION))

REPORT spikes/out/4000521810-ready-signal-self-test-41080/report.lisp
(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :STATUS :PASSED :STAGE
 :COMPLETE :SOURCE-CONSISTENCY :STABLE :BASELINE :PENDING :DETECTED 0
 :WORKER-ERRORS 1 :MUTANTS
 ((:NAME \"signal-fixture\" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9 :LOG
   \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/4000521810-ready-signal-self-test-41080/test.log\"))
 :LIMITS
 (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE :STRICT-COMPILATION
  :TEST-EVENTS-AT-LINE-START :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
  :NO-POOL-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))

REPORT spikes/out/4000521888-command-44171-0/report.lisp
(:SCHEMA-VERSION 1 :KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
 :STABLE :EXIT-CODE 0 :COMMAND
 (\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\" \"--script\"
  \"spikes/out/ready-publish-first-review.lisp\")
 :STDOUT \"Prima revisione e processo di pubblicazione conservati.
\"
 :STDERR \"\" :LIMITS
 (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
  :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 0.018758126 :TOOL-CHUNK-ID "928138"
   :TOOL-ORIGINAL-TOKEN-COUNT 551 :TOOL-OUTPUT-TRUNCATED NIL)
  (:PURPOSE "Lettura dei record finali check/mutazioni/probe e dati mutazioni"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(dolist (path '(\"spikes/out/4000521907-command-44843-0/report.lisp\"
                \"spikes/out/4000521918-command-45102-0/report.lisp\"
                \"spikes/out/4000522063-command-47453-0/report.lisp\"))
  (let* ((r (arcdocdb.evidence:read-evidence path)) (out (getf r :stdout)) (err (getf r :stderr)))
    (format t \"~%REPORT ~A ~S~%\" path
            (loop for k in '(:schema-version :kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
    (format t \"STDOUT-LENGTH ~D STDERR-LENGTH ~D~%\" (length out) (length err))
    (dolist (line (uiop:split-string out :separator '(#\\Newline)))
      (when (and (< (length line) 190)
                 (or (search \" test \" line) (search \"avvis\" line)
                     (search \"violaz\" line) (search \"Traccia\" line)
                     (search \"file\" line) (search \"link\" line)
                     (search \"SPK-\" line) (search \"report\" line) (search \"Report\" line)))
        (format t \"~A~%\" line)))
    (format t \"STDERR-SAMPLE ~A~%\" (subseq err 0 (min 1600 (length err))))))
(let ((r (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations-final/report.lisp\")))
  (format t \"FINAL-MUTATION ~S~%\" (loop for k in '(:status :stage :source-consistency :baseline :baseline-result :baseline-exit-code :baseline-signal :detected :survived :compilation-failures :before-tests :worker-errors :mutants :limits) append (list k (getf r k)))))
LISP"
   :COMBINED-TOOL-OUTPUT "
REPORT spikes/out/4000521907-command-44843-0/report.lisp (:SCHEMA-VERSION 1
                                                          :KIND
                                                          :COMMAND-VERIFICATION
                                                          :STATUS :OK
                                                          :SOURCE-CONSISTENCY
                                                          :STABLE :EXIT-CODE 0
                                                          :WALL-SECONDS
                                                          96.821713d0 :COMMAND
                                                          (\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\"
                                                           \"check-core\")
                                                          :LIMITS
                                                          (:COMMAND-OUTPUT-IS-RAW
                                                           :WALL-TIME-INCLUDES-ENTIRE-COMMAND
                                                           :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
STDOUT-LENGTH 68851 STDERR-LENGTH 25523
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/conditions.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/binary.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/crc32c.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/record.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/foundation/batch.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/codec/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/codec/utf8.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/package.lisp\" (written 09 OCT 2026 10:00:31 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/queue.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/writer.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/handoff.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/ready-types.lisp\" (written 09 OCT 2026 10:00:31 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/execution/ready.lisp\" (written 09 OCT 2026 10:00:31 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/formats.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/segment-header.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/log-header.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/compaction-scan.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/control-payload.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/payload-record.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/storage/payload-write.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/types.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/native.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/lifecycle.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/transfer.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/io/flush.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/wal/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/wal/types.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/wal/builder.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/wal/group.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/wal/executor.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/scan.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-package.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-types.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-sort.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-radix.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-build.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/decisions-query.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-package.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-types.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-decode.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-fold.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-build.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/recovery/manifest-query.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/smoke.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/foundation/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/foundation/binary.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/foundation/record.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/foundation/batch.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/codec/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/codec/utf8.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/codec/threads.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/execution/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/execution/queue.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/execution/threads.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/execution/handoff.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/execution/ready.lisp\" (written 09 OCT 2026 10:00:31 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/storage/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/storage/segment-header.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/storage/log-header.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/storage/compaction-scan.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/storage/control-payload.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/io/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/io/transfer.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/io/native.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/scan.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/corruption.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/decisions-support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/decisions.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/decisions-audit.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/decisions-radix.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/manifest-support.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/manifest.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/recovery/manifest-audit.lisp\" (written 09 OCT 2026 10:00:41 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/wal/support.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/wal/builder.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/wal/group.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/wal/fault.lisp\" (written 09 OCT 2026 09:32:07 AM):
; compiling file \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tests/wal/native.lisp\" (written 09 OCT 2026 09:32:07 AM):
26 test delle fondazioni superati.
17 test UTF-8 superati.
51 test delle code writer superati.
44 test dei metadati storage superati.
18 test I/O superati.
82 test recovery superati.
19 test WAL superati.
build e test: nessun avviso, tutti i controlli superati
48 file, 0 violazioni
ok    good.lisp: nessuna violazione
sbcl --script tools/check-links.lisp .
187 file, 1880 link controllati, 0 rotti
    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tools/normalize-spike-report.lisp\"
    ((:STATUS :PASS :RESULT (:STATUS :PASS :N 1) :ID \"SPK-fixture\" :STDOUT
    \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/tools/normalize-spike-report.lisp\"
    ((:STATUS :PASS :RESULT (:STATUS :PASS :N 1) :ID \"SPK-fixture\" :STDOUT
STDERR-SAMPLE 
; file: /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/src/codec/utf8.lisp
; in: DEFUN VERIFICA-UTF8
;     (LOOP ARCDOCDB.UTF8::REPEAT ARCDOCDB.UTF8::SPAN
;           DO (WHEN (= ARCDOCDB.UTF8::CURSOR ARCDOCDB.UTF8::LIMIT)
;                (RETURN)) (SETF ARCDOCDB.UTF8::CURSOR
;                                  (ARCDOCDB.UTF8::VERIFICA-CARATTERE-UTF8
;                                   ARCDOCDB.UTF8::BYTES ARCDOCDB.UTF8::CURSOR
;                                   ARCDOCDB.UTF8::LIMIT)) (INCF COUNT) (UNLESS
;                                                                           (<=
;                                                                            COUNT
;                                                                            (-
;                                                                             ARCDOCDB.UTF8::CURSOR
;                                                                             ARCDOCDB.UTF8::BEGIN))
;                                                                         (ERROR
;                                                                          'ARCDOCDB.CONDITIONS:INVARIANT-VIOLATION
;                                                                          :REASON
;                                                                          :UTF8-COUNT
;                                                                          :OFFSET
;                                                                          ARCDOCDB.UTF8::CURSOR)))
; --> LET TAGBODY IF DECF SETQ THE SB-IMPL::XSUBTRAC

REPORT spikes/out/4000521918-command-45102-0/report.lisp (:SCHEMA-VERSION 1
                                                          :KIND
                                                          :COMMAND-VERIFICATION
                                                          :STATUS :OK
                                                          :SOURCE-CONSISTENCY
                                                          :STABLE :EXIT-CODE 0
                                                          :WALL-SECONDS
                                                          37.429325d0 :COMMAND
                                                          (\"sbcl\" \"--noinform\"
                                                           \"--no-userinit\"
                                                           \"--no-sysinit\"
                                                           \"--disable-debugger\"
                                                           \"--script\"
                                                           \"tools/writer-ready-mutation.lisp\"
                                                           \"--run\"
                                                           \"spikes/out/ready-mutations-final/\")
                                                          :LIMITS
                                                          (:COMMAND-OUTPUT-IS-RAW
                                                           :WALL-TIME-INCLUDES-ENTIRE-COMMAND
                                                           :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
STDOUT-LENGTH 184 STDERR-LENGTH 0
Writer ready: OK, baseline PASSED, rilevati 12/12; /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/report.lisp
STDERR-SAMPLE 

REPORT spikes/out/4000522063-command-47453-0/report.lisp (:SCHEMA-VERSION 1
                                                          :KIND
                                                          :COMMAND-VERIFICATION
                                                          :STATUS :OK
                                                          :SOURCE-CONSISTENCY
                                                          :STABLE :EXIT-CODE 0
                                                          :WALL-SECONDS
                                                          0.467326d0 :COMMAND
                                                          (\"sbcl\" \"--noinform\"
                                                           \"--no-userinit\"
                                                           \"--no-sysinit\"
                                                           \"--disable-debugger\"
                                                           \"--script\"
                                                           \"spikes/out/ready-mutation-final-summary.lisp\")
                                                          :LIMITS
                                                          (:COMMAND-OUTPUT-IS-RAW
                                                           :WALL-TIME-INCLUDES-ENTIRE-COMMAND
                                                           :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
STDOUT-LENGTH 100 STDERR-LENGTH 0
STDERR-SAMPLE 
FINAL-MUTATION (:STATUS :OK :STAGE :COMPLETE :SOURCE-CONSISTENCY :STABLE
                :BASELINE :PASSED :BASELINE-RESULT :SURVIVED
                :BASELINE-EXIT-CODE 0 :BASELINE-SIGNAL NIL :DETECTED 12
                :SURVIVED 0 :COMPILATION-FAILURES 0 :BEFORE-TESTS 0
                :WORKER-ERRORS 0 :MUTANTS
                ((:NAME \"ready-fifo-head-from-tail\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/0/test.log\")
                 (:NAME \"ready-tail-wrap-two\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/1/test.log\")
                 (:NAME \"ready-head-wrap-two\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/2/test.log\")
                 (:NAME \"ready-full-boundary\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/3/test.log\")
                 (:NAME \"ready-pop-count-unchanged\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/4/test.log\")
                 (:NAME \"ready-pop-keeps-reference\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/5/test.log\")
                 (:NAME \"ready-release-keeps-guard\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/6/test.log\")
                 (:NAME \"ready-scan-forgets-busy\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/7/test.log\")
                 (:NAME \"ready-scan-stops-on-busy\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/8/test.log\")
                 (:NAME \"ready-scan-misses-last-shard\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/9/test.log\")
                 (:NAME \"ready-success-cursor-stays\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/10/test.log\")
                 (:NAME \"ready-unsuccessful-cursor-stays\" :SOURCE-FILE
                  \"src/execution/ready.lisp\" :RESULT :DETECTED :EXIT-CODE 1
                  :SIGNAL NIL :LOG
                  \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-ready-verify-_dtdm24z/spikes/out/ready-mutations-final/11/test.log\"))
                :LIMITS
                (:TARGETED-MUTANTS-ONLY :COMPLETE-EXECUTION-SUITE
                 :STRICT-COMPILATION :TEST-EVENTS-AT-LINE-START
                 :PARTIAL-CAMPAIGN-PRESERVED :EXCLUSIVE-DIRECTORY
                 :NO-POOL-DEVICE-DURABILITY-OR-PERFORMANCE-QUALIFICATION))
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 0.2220828 :TOOL-CHUNK-ID "37af62"
   :TOOL-ORIGINAL-TOKEN-COUNT 6413 :TOOL-OUTPUT-TRUNCATED NIL)
  (:PURPOSE
   "Lettura master e log; selezione iniziale results invece di runs, precisata successivamente"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000521968-check-46180-0/report.lisp\")))
  (format t \"MASTER-KEYS ~S~%\" (loop for (k v) on r by #'cddr collect k))
  (format t \"MASTER-SUMMARY ~S~%\" (loop for k in '(:schema-version :kind :mode :status :source-consistency :environment :limits :diagnostic) append (list k (getf r k))))
  (dolist (entry (getf r :results))
    (format t \"SPIKE ~S~%\" (loop for k in '(:id :status :exit-code :signal :duration-seconds :source-consistency :result) append (list k (getf entry k))))))
(let* ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000521907-command-44843-0/report.lisp\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \"INTEGRATED-COUNTS ~S~%\"
          (loop for line in (uiop:split-string out :separator '(#\\Newline))
                when (or (search \" test \" line) (search \"violazioni\" line)
                         (search \"requisiti\" line) (search \"REQ:\" line)
                         (search \"invarianti\" line) (search \"riferimenti\" line)
                         (search \"1880\" line) (search \"114\" line)) collect line))
  (format t \"COMPILER-WARNING-LINES ~S~%\"
          (loop for line in (uiop:split-string err :separator '(#\\Newline))
                when (or (search \"; caught WARNING:\" line)
                         (search \"; caught STYLE-WARNING:\" line)) collect line)))
LISP
python3 - <<'PY'
from pathlib import Path
for p in [Path('spikes/out/ready-mutations-final/baseline/test.log'), *[Path('spikes/out/ready-mutations-final')/str(i)/'test.log' for i in range(12)]]:
    lines=p.read_text().splitlines()
    starts=[s for s in lines if s.startswith('execution-test-start ')]
    oks=[s for s in lines if s.startswith('ok    TEST-REQ-')]
    complete=[s for s in lines if s.startswith('execution-tests-complete ')]
    diagnostics=[s for s in lines if any(x in s.lower() for x in ['compilation aborted','compile-file-error','compile-file-warned','non ammesso (cod-01)'])]
    print(p.as_posix(), 'start',len(starts),'ok',len(oks),'last',starts[-1:],'complete',complete,'compiler-failure',diagnostics[:1])
PY"
   :COMBINED-TOOL-OUTPUT
   "MASTER-KEYS (:SCHEMA-VERSION :ENVIRONMENT :MODE :STATUS :RUNS :RUN-ARTIFACTS)
MASTER-SUMMARY (:SCHEMA-VERSION 1 :KIND NIL :MODE \"--check\" :STATUS :COMPLETE
                :SOURCE-CONSISTENCY NIL :ENVIRONMENT
                (:LISP \"SBCL\" :VERSION \"2.6.9\" :OS \"Darwin\" :OS-VERSION
                 \"27.0.0\" :MACHINE \"ARM64\" :CPU \"Apple M4\" :MEMORY-BYTES
                 17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS
                 :UNCONTROLLED :LOAD-AVERAGE \"{ 5.50 4.85 4.22 }\" :COMMIT
                 \"fd96fb3145f593f31552de26a8fd93478b69fc8f\" :WORKING-TREE
                 \"M arcdocdb.asd
 M docs/affidabilita/copertura-eccezioni.md
 M docs/implementazione/README.md
 M docs/implementazione/writer-handoff.md
 M src/execution/package.lisp
?? docs/implementazione/writer-ready-decisioni.md
?? docs/implementazione/writer-ready-metodo.md
?? docs/implementazione/writer-ready-revisione.md
?? docs/implementazione/writer-ready-risultati.md
?? docs/implementazione/writer-ready.md
?? spikes/results/2026-10-09-writer-ready/
?? src/execution/ready-types.lisp
?? src/execution/ready.lisp
?? tests/execution/ready.lisp
?? tools/writer-ready-bench.lisp
?? tools/writer-ready-mutation.lisp\"
                 :SOURCE-BLOBS
                 ((:PATH \"spikes/SPK-01-primary-index/profile.lisp\" :GIT-BLOB
                   \"a71fde100e32072b6e7b010228683b640ea4ff9a\")
                  (:PATH \"tools/finish-evidence.lisp\" :GIT-BLOB
                   \"c8ebe7bbe4c99a3c712033d0f58e97610914f87f\")
                  (:PATH \"tools/compact-evidence.lisp\" :GIT-BLOB
                   \"72a1c32b1efcb7fd89ff798a669a558ceffb0aa0\")
                  (:PATH \"tools/evidence-storage.lisp\" :GIT-BLOB
                   \"fa2b5d36dca0837e2ed5e49b282887b2e110b2b7\")
                  (:PATH \"spikes/SPK-01-primary-index/run.lisp\" :GIT-BLOB
                   \"b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e\")
                  (:PATH \"spikes/SPK-01-primary-index/core.lisp\" :GIT-BLOB
                   \"c019f6ad53e173a0d336a4dbfaf903e274a66f08\")
                  (:PATH \"spikes/SPK-01-primary-index/lettura-buffer.lisp\"
                   :GIT-BLOB \"34b3574a554ca4e03a34f04b3fc66022abb7893b\")
                  (:PATH
                   \"spikes/SPK-01-primary-index/check-lettura-buffer.lisp\"
                   :GIT-BLOB \"fd32c5260ffb7c6e96cf1a420765eb01effe70bc\")
                  (:PATH \"spikes/SPK-02-gc/run.lisp\" :GIT-BLOB
                   \"9fbe499100da40c2f7a14072af67c35c734949c5\")
                  (:PATH \"spikes/SPK-02-gc/core.lisp\" :GIT-BLOB
                   \"01f6760c75fa6e96a480fca41b1426941a9f703d\")
                  (:PATH \"spikes/SPK-03-group-commit/run.lisp\" :GIT-BLOB
                   \"c0b093e87028dd587c43d3cd52e59492270fdc38\")
                  (:PATH \"spikes/SPK-03-group-commit/core.lisp\" :GIT-BLOB
                   \"d3c58f2866e299ba27b0fa820c20317438774410\")
                  (:PATH \"spikes/SPK-04-writer-pool/run.lisp\" :GIT-BLOB
                   \"77056cc1f695574ed0f4d34795b99aaea736f378\")
                  (:PATH \"spikes/SPK-04-writer-pool/core.lisp\" :GIT-BLOB
                   \"557b32e6378290c46c7d9b128fc8e59a0e7e0a44\")
                  (:PATH \"spikes/SPK-04-writer-pool/pool.lisp\" :GIT-BLOB
                   \"cbec51aad2b64fb8c5be026891eff859ba371c18\")
                  (:PATH \"spikes/SPK-04-writer-pool/parcheggi.lisp\" :GIT-BLOB
                   \"c0fee7b738395fcaf3359f297282cd266ce6dfad\")
                  (:PATH \"spikes/SPK-05-segment-read/run.lisp\" :GIT-BLOB
                   \"c67a3ae8e672f96d9105deb935fb621b07d67afb\")
                  (:PATH \"spikes/SPK-05-segment-read/core.lisp\" :GIT-BLOB
                   \"15fad418184ce9969c337b181317b855ede9f5ce\")
                  (:PATH \"spikes/SPK-06-compaction-load/run.lisp\" :GIT-BLOB
                   \"b2863cbac49d0988b850bdeeae1713108a21bfca\")
                  (:PATH \"spikes/SPK-06-compaction-load/core.lisp\" :GIT-BLOB
                   \"375cb97e1490e0252c04fd1a3076a17342cefd68\")
                  (:PATH \"spikes/SPK-06-compaction-load/controllore.lisp\"
                   :GIT-BLOB \"4602972e2400d31d4d3b771f60703c68e23f0804\")
                  (:PATH \"spikes/SPK-06-compaction-load/interferenza.lisp\"
                   :GIT-BLOB \"9ad30ce92bdb643aeb5163e96508bf677996a4ef\")
                  (:PATH \"spikes/SPK-05-segment-read/io.lisp\" :GIT-BLOB
                   \"ba470bce3cae0ce14888dbec6e26c5656e9bbd1a\")
                  (:PATH \"spikes/SPK-05-segment-read/record.lisp\" :GIT-BLOB
                   \"baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe\")
                  (:PATH \"spikes/SPK-07-protocols/run.lisp\" :GIT-BLOB
                   \"648bd776767e4be914a2470069afced14bc1c1e5\")
                  (:PATH \"spikes/SPK-07-protocols/core.lisp\" :GIT-BLOB
                   \"489e2732cf5bfed4cd11251bb686a5d4f4e10b3e\")
                  (:PATH \"spikes/SPK-07-protocols/pubblicazione.lisp\" :GIT-BLOB
                   \"d317849b3f95394a7f604b82fb131495b5b3770c\")
                  (:PATH \"spikes/SPK-07-protocols/scadenza.lisp\" :GIT-BLOB
                   \"05a5e93591e2d6e96c2c7548e90888424cbb1f9f\")
                  (:PATH \"spikes/SPK-07-protocols/compaction.lisp\" :GIT-BLOB
                   \"93483f72f3bfe43f0e2afa93b022892114a824e1\")
                  (:PATH \"spikes/SPK-07-protocols/memoria.lisp\" :GIT-BLOB
                   \"96b6cf64d481643cdba7857f339a7cb7c029b765\")
                  (:PATH \"spikes/SPK-07-protocols/suite.lisp\" :GIT-BLOB
                   \"a813fbeb55cd03980b2215c99fc3170d6afa4d92\")
                  (:PATH \"spikes/SPK-07-protocols/seqlock-readers.lisp\"
                   :GIT-BLOB \"b2e704bbe7e699b9df68173319f64d2ae8abc5fc\")
                  (:PATH \"spikes/SPK-07-protocols/byte-crash.lisp\" :GIT-BLOB
                   \"66a6c3b458d808fc214f7c3bd96e09d239312c67\")
                  (:PATH \"src/package.lisp\" :GIT-BLOB
                   \"3d0181717e3f334580bab9a6a507e2dfe57261ff\")
                  (:PATH \"src/foundation/package.lisp\" :GIT-BLOB
                   \"0658b083f1e777aa0ada67a63535d36946921eac\")
                  (:PATH \"src/foundation/conditions.lisp\" :GIT-BLOB
                   \"dd5b46acca9106fb07e92e22ec4fbaca0cafa30a\")
                  (:PATH \"src/foundation/binary.lisp\" :GIT-BLOB
                   \"2d514f6fe2e81eecb29fa53de611fa5e28696904\")
                  (:PATH \"src/foundation/crc32c.lisp\" :GIT-BLOB
                   \"f9c691d28620427099d1d89a89a1ff5d04cbe257\")
                  (:PATH \"src/foundation/record.lisp\" :GIT-BLOB
                   \"8df53d416747131d9ed9921abb4ef356d9ce5696\")
                  (:PATH \"src/foundation/batch.lisp\" :GIT-BLOB
                   \"2cbd40c539b13dd80070eedf4af82bd1b26f4b28\")
                  (:PATH \"spikes/SPK-08-generated-code/run.lisp\" :GIT-BLOB
                   \"a1fdf6705a10fcca3926f40e26051fe7b6df5bf0\")
                  (:PATH \"spikes/SPK-08-generated-code/impronte.lisp\" :GIT-BLOB
                   \"d187e3d95f0e85a0a8ae84843a67a326e803cd2c\")
                  (:PATH \"spikes/SPK-08-generated-code/simd.lisp\" :GIT-BLOB
                   \"dbd551322880f1e0ddac6436c8af8f0dd85ddb9f\")
                  (:PATH \"spikes/SPK-08-generated-code/bitmap.lisp\" :GIT-BLOB
                   \"cbeff7e2a58f268291b01cb6a1f124533063d5d6\")
                  (:PATH \"spikes/SPK-08-generated-code/core-bitmap.lisp\"
                   :GIT-BLOB \"a4be2005a702a77a631f35568778673c503c60b5\")
                  (:PATH \"spikes/SPK-09-integrity/run.lisp\" :GIT-BLOB
                   \"c95660a4df5f2e6f6eb93e1078c2c36df6dabc85\")
                  (:PATH \"tools/run-spikes.lisp\" :GIT-BLOB
                   \"9421994e3c9883b423f6f17311d1b26c094ee991\")
                  (:PATH \"spikes/SPK-10-v2-limits/run.lisp\" :GIT-BLOB
                   \"6aa63afeac91c3b75174b76daba61e354bb7fe4d\")
                  (:PATH \"spikes/SPK-10-v2-limits/core.lisp\" :GIT-BLOB
                   \"c5b7cfd27c663734b7d5fae481dde939418566b5\")
                  (:PATH \"spikes/SPK-10-v2-limits/codec.lisp\" :GIT-BLOB
                   \"567c84546d29e1b8ddc5cd9e1a31b4e93519c75d\")
                  (:PATH \"spikes/SPK-10-v2-limits/indice.lisp\" :GIT-BLOB
                   \"bc978eb16aa7f0d69e3deac2df86057a650f8551\")
                  (:PATH \"spikes/SPK-10-v2-limits/cbor.lisp\" :GIT-BLOB
                   \"d6a5c93e34a0444d64b206df875a25b380545631\")
                  (:PATH \"spikes/SPK-10-v2-limits/migrazione.lisp\" :GIT-BLOB
                   \"cab850dc32ff9908b487b24edf3e1df2cc90008c\")
                  (:PATH \"spikes/SPK-09-integrity/core.lisp\" :GIT-BLOB
                   \"80cdac4c0e52703618e1f274413b2ecbe00e6b14\"))
                 :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000521973)
                :LIMITS NIL :DIAGNOSTIC NIL)
INTEGRATED-COUNTS (\"26 test delle fondazioni superati.\"
                   \"17 test UTF-8 superati.\"
                   \"51 test delle code writer superati.\"
                   \"44 test dei metadati storage superati.\"
                   \"18 test I/O superati.\" \"82 test recovery superati.\"
                   \"19 test WAL superati.\" \"48 file, 0 violazioni\"
                   \"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\"
                   \"187 file, 1880 link controllati, 0 rotti\")
COMPILER-WARNING-LINES NIL
spikes/out/ready-mutations-final/baseline/test.log start 51 ok 51 last ['execution-test-start TEST-REQ-CON-002-READY-COMPETING-CONSUMERS-TAKE-ONE-REFERENCE-PER-WAVE'] complete ['execution-tests-complete 51'] compiler-failure []
spikes/out/ready-mutations-final/0/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/1/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/2/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/3/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/4/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/5/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/6/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/7/test.log start 42 ok 41 last ['execution-test-start TEST-REQ-CON-004-READY-SKIPS-BUSY-HOME-AND-PRESERVES-LOCAL-RING'] complete [] compiler-failure []
spikes/out/ready-mutations-final/8/test.log start 42 ok 41 last ['execution-test-start TEST-REQ-CON-004-READY-SKIPS-BUSY-HOME-AND-PRESERVES-LOCAL-RING'] complete [] compiler-failure []
spikes/out/ready-mutations-final/9/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/10/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
spikes/out/ready-mutations-final/11/test.log start 35 ok 34 last ['execution-test-start TEST-REQ-AFF-008-READY-CONFIGURATION-AND-LIMITS'] complete [] compiler-failure []
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 1.3440906 :TOOL-CHUNK-ID "53f217"
   :TOOL-ORIGINAL-TOKEN-COUNT 2880 :TOOL-OUTPUT-TRUNCATED NIL)
  (:PURPOSE
   "Lettura struttura runs; stampa del risultato completo troncata dal tool, superseduta dalla selezione dei soli metadati; master originale integro"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \"spikes/out/4000521968-check-46180-0/report.lisp\"))
       (environment (getf r :environment)))
  (format t \"ENVIRONMENT ~S~%\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf environment k))))
  (format t \"RUN-COUNT ~D ARTIFACT-COUNT ~D~%\" (length (getf r :runs)) (length (getf r :run-artifacts)))
  (dolist (run (getf r :runs))
    (format t \"RUN-KEYS ~S~%\" (loop for (k v) on run by #'cddr collect k))
    (format t \"RUN-SUMMARY ~S~%\" (loop for k in '(:id :status :exit-code :signal :result :output :stdout)
                                       for value = (getf run k)
                                       when value append (list k (if (and (stringp value) (> (length value) 140))
                                                                      (concatenate 'string (subseq value 0 140) \" [...] \") value))))))
LISP"
   :COMBINED-TOOL-OUTPUT
   "Warning: truncated output (original token count: 4446730)
... 16738341 bytes omitted ...

ENVIRONMENT (:LISP \"SBCL\" :VERSION \"2.6.9\" :OS \"Darwin\" :OS-VERSION \"27.0.0\"
             :MACHINE \"ARM64\" :CPU \"Apple M4\" :MEMORY-BYTES 17179869184
             :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
             \"{ 5.50 4.85 4.22 }\" :COMMIT
             \"fd96fb3145f593f31552de26a8fd93478b69fc8f\" :DYNAMIC-SPACE-MIB 4096
             :DATE-UNIVERSAL-TIME 4000521973)
RUN-COUNT 10 ARTIFACT-COUNT 10
RUN-KEYS (:SCHEMA-VERSION :ID :COMMAND :EXIT-CODE :STARTED-AT-UNIVERSAL-TIME
          :FINISHED-AT-UNIVERSAL-TIME :WALL-SECONDS :STATUS
          :SOURCE-BLOBS-BEFORE :SOURCE-BLOBS-AFTER :SOURCE-CONSISTENCY :RESULT
          :STDOUT :STDERR)
RUN-SUMMARY (:ID \"SPK-01\" :STATUS :OK :EXIT-CODE 0 :RESULT
             (:SPIKE :SPK-01 :STATUS :OK :LAYOUT :ADR-0043-V1
              :VERIFIES-FORMAT-V2 NIL :SEED 424242 :GOLDEN :OK :DIFFERENTIAL
              ((:WORDS 4 :OPERATIONS 3000 :SEED 424242 :STATUS :OK)
               (:WORDS 5 :OPERATIONS 3000 :SEED 424242 :STATUS :OK))
              :COLLISIONS :OK :RECLAIM :OK :RETIRED-ROOT
              (:STATUS :OK :ROOT-ACQUIRED-CSN 1 :UNVALIDATED-RETIRED-HIT-CSN 2
               :REVALIDATED-HIT-CSN 3 :DISCARDED-ATTEMPTS 1
               :RETIRED-MISS-REVALIDATED T :FALSIFIED-CLAIM
               :LINEARIZATION-AT-ROOT-ACQUISITION
               :GENERAL-LINEARIZABILITY-COUNTEREXAMPLE NIL)
              :SEQLOCK :OK :LIMITS :OK :WORKER-ERRORS-AND-CLEANUP :OK
              :CONCURRENCY
              ((:WORDS 4 :STATUS :OK :WORKERS
                (:WRITER-COMPLETED
                 (:READER 0 :OPERATIONS 1200 :RETRIES 53 :FALLBACK 0)
                 (:READER 1 :OPERATIONS 1200 :RETRIES 44 :FALLBACK 0)))
               (:WORDS 5 :STATUS :OK :WORKERS
                (:WRITER-COMPLETED
                 (:READER 0 :OPERATIONS 1200 :RETRIES 67 :FALLBACK 0)
                 (:READER 1 :OPERATIONS 1200 :RETRIES 69 :FALLBACK 0))))
              :BUFFER-CHECK
              (:SCHEMA-VERSION 1 :STATUS :OK :SPIKE :SPK-01 :PHASE 0 :LAYOUT
               :V1 :LAYOUTS (:WORDS4 :WORDS5-EXTRA-END) :VERIFIES-FORMAT-V2
               :FALSE :SAFETY 3 :BENCH-EXECUTED :FALSE :KERNEL
               \"ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI\" :BASELINE
               \"ARCDOCDB.SPK01:LEGGI\" :MODEL
               :INDEPENDENT-MAP-WITH-JOURNAL-REPLAY :PRINCIPAL-CASES 54
               :NEGATIVE-CONTROLS 79 :NEGATIVE-COUNTS
               (:INGRESS 46 :WRITER 16 :BUDGET 1 :MUTANTS 16) :READ-COMPARISONS
               2032 :CAMPAIGNS
               ((:WORDS 4 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
                 :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512
                 :INITIAL-READS 64 :FINAL-READS 384 :READ-COMPARISONS 960
                 :HISTORY-EVENTS 576 :FINAL-LIVE 64 :FINAL-STATE 2846191538
                 :SPLITS 6 :REBUILDS 18)
                (:WORDS 5 :SEED 424242 :STEPS 1024 :BLOCKS 128 :INITIAL-PUTS 64
                 :CAMPAIGN-PUTS 384 :CAMPAIGN-DELETES 128 :CAMPAIGN-READS 512
                 :INITIAL-READS 64 :FINAL-READS 384 :READ-COMPARISONS 960
                 :HISTORY-EVENTS 576 :FINAL-LIVE 64 :FINAL-STATE 2846191538
                 :SPLITS 6 :REBUILDS 18))
               :BOUNDARIES
               ((:WORDS 4 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED
                 :MAX64 18446744073709551615 :LENGTH-MAX 16777215
                 :DELETE-ABSENT :COVERED)
                (:WORDS 5 :RECORDS 6 :ZERO-KEY :COVERED :ALL-FF-KEY :COVERED
                 :MAX64 18446744073709551615 :LENGTH-MAX 16777215
                 :DELETE-ABSENT :COVERED))
               :REBUILDS
               ((:WORDS 4 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1)
                (:WORDS 5 :TOMBSTONE-REBUILDS 1 :SEQUENCE-REBUILDS 1))
               :COLLISIONS
               ((:WORDS 4 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS
                 (15 0 1 2 3 4) :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870
                 :CANDIDATE-CALLBACKS :VERIFIED)
                (:WORDS 5 :FINGERPRINT 53 :PROBE-START 15 :OCCUPIED-SLOTS
                 (15 0 1 2 3 4) :KEYS-FOUND 7 :SEARCH-CANDIDATES 11870
                 :CANDIDATE-CALLBACKS :VERIFIED))
               :WITNESSES
               ((:WORDS 4 :CASES
                 ((:CASE :ROOT-HIT :WORDS 4 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 2
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ROOT-MISS :WORDS 4 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-UPDATE :WORDS 4 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 2
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-DELETE :WORDS 4 :STATUS :MISS :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-ODD :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ROOT-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-CHURN :WORDS 4 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ERROR-FRAGMENT :WORDS 4 :STATUS :ORIGINAL-ERROR
                   :RETRIES :NOT-RETURNED :FRAGMENT-CALLBACKS 1
                   :FIELDS-CALLBACKS 0 :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ERROR-FIELDS :WORDS 4 :STATUS :ORIGINAL-ERROR
                   :RETRIES :NOT-RETURNED :FRAGMENT-CALLBACKS 1
                   :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED)))
                (:WORDS 5 :CASES
                 ((:CASE :ROOT-HIT :WORDS 5 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 2
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ROOT-MISS :WORDS 5 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-UPDATE :WORDS 5 :STATUS :HIT :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 2
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-DELETE :WORDS 5 :STATUS :MISS :RETRIES 1
                   :FRAGMENT-CALLBACKS 2 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-ODD :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 1
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ROOT-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :FIELDS-CHURN :WORDS 5 :STATUS :RETRY-LIMIT :RETRIES 8
                   :FRAGMENT-CALLBACKS 8 :FIELDS-CALLBACKS 8
                   :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ERROR-FRAGMENT :WORDS 5 :STATUS :ORIGINAL-ERROR
                   :RETRIES :NOT-RETURNED :FRAGMENT-CALLBACKS 1
                   :FIELDS-CALLBACKS 0 :BUFFER-PUBLICATION :VALIDATED)
                  (:CASE :ERROR-FIELDS :WORDS 5 :STATUS :ORIGINAL-ERROR
                   :RETRIES :NOT-RETURNED :FRAGMENT-CALLBACKS 1
                   :FIELDS-CALLBACKS 1 :BUFFER-PUBLICATION :VALIDATED))))
               :RETRY-BUDGETS
               ((:WORDS 4 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT)
                (:WORDS 5 :ATTEMPTS (1 2 3 4 5 6 7 8) :STATUS :RETRY-LIMIT))
               :INVALID-INPUTS
               ((:WORDS 4 :CASES 23 :REJECTIONS
                 …258152 tokens truncated…D-REBUILDS 1)
                  (:STATUS :OK :RETIRED-HIT-RETRIES 1 :RETIRED-MISS-RETRIES 1
                   :CONTINUOUS-ROOT-ATTEMPTS 8 :GENERATION-WRAP-REJECTED T)
                  (:STATUS :OK :SEED 424242 :OPERATIONS 600 :ORACLE-COMPARISONS
                   664 :WRITE-REQUESTS 186 :DELETE-REQUESTS 208 :READ-REQUESTS
                   206 :KEY-LENGTHS (1 255 256 65535) :STATISTICS
                   (:CAPACITY 128 :DOCUMENTS 20 :CTRL-BYTES 128 :SLOT-WORDS 640
                    :BYTES-PER-SLOT 41 :ARENA-USED 593911 :ARENA-CAPACITY
                    1048576 :LIVE-KEY-BYTES 461049 :TOMBSTONES 9
                    :ROOT-GENERATION 4 :PAYLOAD-BYTES 1053832
                    :PEAK-PAYLOAD-BYTES 2102408 :PEAK-TRANSIENT-BYTES 3216519
                    :INSERTIONS 106 :UPDATES 80 :DELETIONS 86 :REBUILDS 4
                    :ARENA-GROWTHS 10 :COPIED-KEY-BYTES 8052124
                    :MAX-COPIED-KEY-BYTES 1119215 :MAX-SOURCE-SLOTS-VISITED 128
                    :MAX-SOURCE-SLOTS-COPIED 30
                    :MAX-DIRECTORY-REFERENCES-COPIED 1 :MAX-PREPARATION-SECONDS
                    0.020894d0 :LIMITS
                    (:KEY-BYTES 65535 :DOCUMENT-BYTES 16777216 :ARENA-BYTES
                     8388608 :COPY-BYTES 16777216 :TRANSIENT-BYTES 134217728
                     :MAINTENANCE-SECONDS 0.5d0 :READER-ATTEMPTS 8 :LOAD-FACTOR
                     7/8)
                    :TIME-BUDGET :COOPERATIVE-WALL :MEMORY-ACCOUNTING
                    :ARRAY-PAYLOAD :PENDING
                    (:SPLIT :EXTENDIBLE-DIRECTORY :RETAINED-VERSIONS
                     :WRITER-FALLBACK :MEMORY-MODEL-ARM64-X86-64
                     :RETIRED-ROOTS-RSS-BUDGET))))
                 :PENDING
                 (:SPLIT :EXTENDIBLE-DIRECTORY :RETAINED-VERSIONS
                  :WRITER-FALLBACK :MEMORY-MODEL-ARM64-X86-64
                  :PRODUCTION-COMMIT :V2-GATE)))
               (:MODULE \"ARCDOCDB.SPK10.CBOR\" :RESULT
                (:SPIKE :SPK-10 :MODULE :CBOR :STATUS :OK :SCOPE :PARTIAL
                 :SAFETY 3 :CASES 629 :FIXTURES (:VALID 21 :REJECTED 47)
                 :DEPTH-CASES 12 :BUDGET-CASES 19 :SIZE
                 (:CASES 3 :ENCODED-BYTES 16777216 :PAYLOAD-BYTES 16777211
                  :OVERSIZE-BYTES 16777217 :LIVE-FIXTURE-BYTES 33554433)
                 :MUTATIONS
                 (:SEEDS (1 48 8949 20261008) :CASES 512 :VALID 128 :REJECTED
                  384 :ORACLE :KNOWN-TRANSFORMATIONS)
                 :STACK-ALLOCATION-CHECKS
                 (:CASES 15 :VERIFICATION :OBJECT-COUNTS :RESULTS
                  ((:CASE (:REQ-AFF-008 :SCALARE) :OUTCOME :OK :FRAMES-CREATED
                    0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
                   (:CASE (:REQ-AFF-008 :BINARIO) :OUTCOME :OK :FRAMES-CREATED
                    0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
                   (:CASE (:REQ-AFF-008 :ARRAY-VUOTO) :OUTCOME :OK
                    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES
                    1 :DEPTH 1)
                   (:CASE (:REQ-AFF-008 :MAPPA-VUOTA) :OUTCOME :OK
                    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES
                    1 :DEPTH 1)
                   (:CASE (:REQ-AFF-008 :POCO-PROFONDO) :OUTCOME :OK
                    :FRAMES-CREATED 1 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 4 :DEPTH 1)
                   (:CASE (:REQ-AFF-008 :FIGLIO-VUOTO) :OUTCOME :OK
                    :FRAMES-CREATED 1 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 2 :DEPTH 2)
                   (:CASE (:REQ-AFF-008 :RIUSO-MAPPA-ARRAY-MAPPA) :OUTCOME :OK
                    :FRAMES-CREATED 2 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 9 :DEPTH 2)
                   (:CASE (:REQ-AFF-008 :SCALARE-LIMITE-ZERO) :OUTCOME :OK
                    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 0 :NODES 1
                    :DEPTH 0)
                   (:CASE (:REQ-AFF-008 :VUOTO-LIMITE-ZERO) :OUTCOME
                    :DEPTH-LIMIT :FRAMES-CREATED 0 :STACK-CAPACITY 0
                    :STACK-LIMIT 0 :NODES 1 :DEPTH 0)
                   (:CASE (:REQ-AFF-008 :TRONCATO-PRIMA-PILA) :OUTCOME
                    :TRUNCATED :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT
                    100 :NODES 1 :DEPTH 1)
                   (:CASE (:REQ-AFF-008 :BUDGET-PRIMA-PILA) :OUTCOME
                    :NODE-BUDGET :FRAMES-CREATED 0 :STACK-CAPACITY 0
                    :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
                   (:CASE (:REQ-AFF-008 :PROFONDITA-RIDOTTA) :OUTCOME
                    :DEPTH-LIMIT :FRAMES-CREATED 1 :STACK-CAPACITY 1
                    :STACK-LIMIT 1 :NODES 2 :DEPTH 1)
                   (:CASE :REQ-LIM-002-PILA-100-VUOTO :OUTCOME :OK
                    :FRAMES-CREATED 99 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 100 :DEPTH 100)
                   (:CASE :REQ-LIM-002-PILA-100-NONVUOTO :OUTCOME :OK
                    :FRAMES-CREATED 100 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 101 :DEPTH 100)
                   (:CASE :REQ-LIM-002-PILA-101 :OUTCOME :DEPTH-LIMIT
                    :FRAMES-CREATED 100 :STACK-CAPACITY 100 :STACK-LIMIT 100
                    :NODES 101 :DEPTH 100)))
                 :LIMITS
                 (:DOCUMENT-BYTES 16777216 :CONTAINER-DEPTH 100 :NODES 16777216
                  :INPUT-BYTES 16777216 :STACK-FRAMES 100)
                 :UNSUPPORTED (:TAGS :FLOATING-POINT :OTHER-SIMPLE-VALUES)
                 :ELAPSED-SECONDS 0.005669d0))
               (:MODULE \"ARCDOCDB.SPK10.MIGRAZIONE\" :RESULT
                (:STATUS :OK :FILEHEADERS
                 (:ACCETTATI 8 :RIFIUTATI 2393 :BIT-FLIP 2048 :TRONCAMENTI 256
                  :RISERVATI-CRC-VALIDO 68 :ORIGINI-INVALIDE 12
                  :VERSIONI-IGNOTE 4 :BOUNDS-INVALIDI 4
                  :MAGIC-ALTERNATIVO-RIFIUTATO 1
                  :PARSER-INVOCATI-SU-HEADER-INVALIDI 0)
                 :MODELLO
                 (:SCENARI 4 :STATI-PIN 2 :PREFISSI 52 :CRASH 208
                  :INTERRUZIONI-RECOVERY 4160 :RERUN 208 :MASSIMO-PASSI 22
                  :MASSIMO-COPIE 4 :FALSE-VERIFICHE-RILEVATE-DA-ORACLE 2
                  :VERIFICHE-NEGATIVE 4)
                 :ANOMALIE
                 (:CASI 4 :TMP-NOMINATO-RINOMINATO 1 :ERRORI-INTEGRITA 2
                  :DEFINITIVI-SCONOSCIUTI-CONSERVATI 1)
                 :BUDGET (:SATURAZIONI 13 :PIN-TRATTENUTO 1 :PIN-RILASCIATO 1)
                 :MUTANTI-RILEVATI 3 :MUTANTI-ATTESI
                 ((:MUTANTE :UNLINK-BEFORE-EDIT :RILEVATO T :FASE :PREPARE.TMP
                   :ORACLE :UNLINK-BEFORE-EDIT)
                  (:MUTANTE :SKIP-VERIFICATION :RILEVATO T :FASE :PUBLISH.EDIT
                   :ORACLE :SKIP-VERIFICATION)
                  (:MUTANTE :RECLAIM-PINNED :RILEVATO T :FASE :RECLAIM :ORACLE
                   :RECLAIM-PINNED))
                 :LIMITI
                 (:FILEHEADER-BYTE 64 :CRC-BYTE 56 :SORGENTI 1 :OUTPUT 1
                  :PIN-MASSIMO 1 :PASSI-PER-ESECUZIONE 32 :COPIE 4
                  :COPIE-PER-TENTATIVO 2 :FASI 10 :PASSI-RECOVERY 4
                  :PREFISSI-PER-SCENARIO 11 :SCENARI 4 :ALTERNATIVE-CRASH 4)
                 :CONVERSIONE-BYTE NIL :CRASH-REALI-VERIFICATI NIL)))
              :INTEGRATION
              (:STATUS :OK :POSITIVE-CASES 16 :ASSERTIONS 113 :NEGATIVE-CASES 1
               :DOCUMENT-BYTES (4 102 16777216) :DEPTHS (2 100 1) :KEY-LENGTHS
               (1 255 256 65535) :MAXIMUM-RECORD-BYTES 16842775 :LIMITS
               (:ORDINARY-PUT-ONLY :TEST-ONLY-VALUE-COPY
                :NO-STORAGE-OR-DURABLE-COMMIT :HINT-SECTION-CRC-NOT-INTEGRATED
                :V1-MAX-DOCUMENT-NOT-REPRESENTABLE))
              :PRODUCTION-GATE-COMPLETE NIL)
             :STDOUT \"(:SPIKE :SPK-10 :STATUS :OK :FORMAT-VERSION 2 :MODULES
 ((:MODULE \\\"ARCDOCDB.SPK10.CODEC\\\" :RESULT
   (:STATUS :OK :CASES 416 :COUNTS
    (:CR [...] \")
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 1.9016052 :TOOL-CHUNK-ID "735790"
   :TOOL-ORIGINAL-TOKEN-COUNT 4446730 :TOOL-OUTPUT-TRUNCATED T)
  (:PURPOSE
   "Lettura finale dei dieci statuti/exit/stabilità/risultati normalizzati e metadati master, output completo breve"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(load \"tools/evidence-storage.lisp\")
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \"spikes/out/4000521968-check-46180-0/report.lisp\")))
  (format t \"MASTER :status ~S :mode ~S :runs ~D :artifacts ~D~%\" (getf r :status) (getf r :mode) (length (getf r :runs)) (length (getf r :run-artifacts)))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result))
           (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \"SPIKE ~S~%\" (list :id (getf run :id) :status (getf run :status)
                                :exit-code (getf run :exit-code)
                                :source-consistency (getf run :source-consistency)
                                :result-type (if (stringp raw-result) :serialized-text :plist)
                                :result-status (getf result :status)
                                :wall-seconds (getf run :wall-seconds)))))
  (let ((e (getf r :environment)))
    (format t \"ENV ~S~%\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP"
   :COMBINED-TOOL-OUTPUT
   "MASTER :status :COMPLETE :mode \"--check\" :runs 10 :artifacts 10
SPIKE (:ID \"SPK-01\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 1.119369d0)
SPIKE (:ID \"SPK-02\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 0.507179d0)
SPIKE (:ID \"SPK-03\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 0.531252d0)
SPIKE (:ID \"SPK-04\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 0.890796d0)
SPIKE (:ID \"SPK-05\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 0.817557d0)
SPIKE (:ID \"SPK-06\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 1.230933d0)
SPIKE (:ID \"SPK-07\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :PASS :WALL-SECONDS 8.48353d0)
SPIKE (:ID \"SPK-08\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 2.014306d0)
SPIKE (:ID \"SPK-09\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 0.733293d0)
SPIKE (:ID \"SPK-10\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-TYPE :PLIST :RESULT-STATUS :OK :WALL-SECONDS 2.784008d0)
ENV (:LISP \"SBCL\" :VERSION \"2.6.9\" :OS \"Darwin\" :OS-VERSION \"27.0.0\" :MACHINE
     \"ARM64\" :CPU \"Apple M4\" :MEMORY-BYTES 17179869184 :LOGICAL-CPUS 10
     :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE \"{ 5.50 4.85 4.22 }\"
     :COMMIT \"fd96fb3145f593f31552de26a8fd93478b69fc8f\" :DYNAMIC-SPACE-MIB 4096
     :DATE-UNIVERSAL-TIME 4000521973)
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 1.0759815 :TOOL-CHUNK-ID "8986dc"
   :TOOL-ORIGINAL-TOKEN-COUNT 466 :TOOL-OUTPUT-TRUNCATED NIL)
  (:PURPOSE
   "Lettura indipendente integrazione ASDF/README e hash sulla base 201562"
   :COMMAND-TEXT "git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md"
   :COMBINED-TOOL-OUTPUT "201562dffd8c48e5d2047f73ef905f64b447e663
3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \"cbor-package\") (:file \"cbor-header\")))
26:                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")))
45:                             (:file \"manifest-package\") (:file \"manifest-types\")
46:                             (:file \"manifest-decode\") (:file \"manifest-fold\")
47:                             (:file \"manifest-build\") (:file \"manifest-query\"))))
64:                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")))
67:                             (:file \"handoff\") (:file \"ready\")))
79:                             (:file \"decisions-audit\") (:file \"decisions-radix\") (:file \"manifest-support\")
80:                             (:file \"manifest\") (:file \"manifest-audit\")))
88:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
17:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
22:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 9.541e-6 :TOOL-CHUNK-ID "d464dd"
   :TOOL-ORIGINAL-TOKEN-COUNT 473)
  (:PURPOSE
   "Lettura indipendente check integrato 201562 e soli metadati dei dieci run"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000522514-command-56618-0/report.lisp\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \"FINAL-CHECK ~S~%\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \"COUNTS ~S~%\" (loop for line in (uiop:split-string out :separator '(#\\Newline))
                                   when (or (search \" test \" line) (search \"violazioni\" line)
                                            (search \"requisiti\" line) (search \" link controllati\" line)
                                            (search \"nessun avviso\" line)) collect line))
  (format t \"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\Newline))
                when (or (search \"; caught WARNING:\" line) (search \"; caught STYLE-WARNING:\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \"spikes/out/4000522582-check-59441-0/report.lisp\")))
  (format t \"FINAL-MASTER ~S~%\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \"SPIKE ~S~%\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \"FINAL-ENV ~S~%\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP"
   :COMBINED-TOOL-OUTPUT
   "FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 102.063356d0 :COMMAND
             (\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\"
              \"check-core\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\"26 test delle fondazioni superati.\" \"17 test UTF-8 superati.\"
        \"17 test degli header CBOR superati.\"
        \"51 test delle code writer superati.\"
        \"44 test dei metadati storage superati.\" \"18 test I/O superati.\"
        \"82 test recovery superati.\" \"19 test WAL superati.\"
        \"build e test: nessun avviso, tutti i controlli superati\"
        \"50 file, 0 violazioni\"
        \"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\"
        \"193 file, 1899 link controllati, 0 rotti\")
STDERR-LENGTH 25842 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \"--check\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \"SPK-01\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-02\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-03\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-04\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-05\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-06\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-07\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \"SPK-08\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-09\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-10\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \"SBCL\" :VERSION \"2.6.9\" :OS \"Darwin\" :OS-VERSION \"27.0.0\"
           :MACHINE \"ARM64\" :CPU \"Apple M4\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \"{ 3.89 3.37 3.63 }\" :COMMIT
           \"201562dffd8c48e5d2047f73ef905f64b447e663\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522586)
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 1.2876817 :TOOL-CHUNK-ID "edd4d3"
   :TOOL-ORIGINAL-TOKEN-COUNT 604)
  (:PURPOSE
   "Lettura struttura degli import per conservazione dei campi e del report originale"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(dolist (p '(\"spikes/out/ready-independent-review.lisp\" \"spikes/out/ready-main-independent-review.lisp\" \"spikes/out/ready-main-review-probes.lisp\"))
 (let ((r (arcdocdb.evidence:read-evidence p)))
 (format t \"~A KEYS ~S~%\" p (loop for (k v) on r by #'cddr collect k))
 (when (getf r :source-hashes) (format t \"HASHES ~S~%\" (getf r :source-hashes)))
 (when (getf r :probes) (format t \"PROBES ~D FIRST-KEYS ~S~%\" (length (getf r :probes)) (loop for (k v) on (first (getf r :probes)) by #'cddr collect k)))))
LISP"
   :COMBINED-TOOL-OUTPUT
   "spikes/out/ready-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :BASE-COMMIT :SCOPE :STATUS
                                               :OPEN-FINDINGS :SOURCE-HASHES
                                               :INVENTORY :EVIDENCE-REFERENCES
                                               :RAW-COVERAGE :PROBES
                                               :REPORT-ORIGINAL
                                               :CLOSURE-APPENDIX :LIMITS)
HASHES ((:FILE \"arcdocdb.asd\" :SHA256
         \"53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3\")
        (:FILE \"src/execution/package.lisp\" :SHA256
         \"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\")
        (:FILE \"src/execution/queue.lisp\" :SHA256
         \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\")
        (:FILE \"src/execution/writer.lisp\" :SHA256
         \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\")
        (:FILE \"src/execution/handoff.lisp\" :SHA256
         \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\")
        (:FILE \"src/execution/ready-types.lisp\" :SHA256
         \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\")
        (:FILE \"src/execution/ready.lisp\" :SHA256
         \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\")
        (:FILE \"tests/execution/ready.lisp\" :SHA256
         \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\")
        (:FILE \"tools/writer-ready-bench.lisp\" :SHA256
         \"9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4\")
        (:FILE \"tools/writer-ready-mutation.lisp\" :SHA256
         \"e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829\"))
PROBES 4 FIRST-KEYS NIL
spikes/out/ready-main-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                                    :SCOPE :STATUS :BASE-COMMIT
                                                    :ORIGINAL-REVIEW
                                                    :DELTA-HASHES
                                                    :EVIDENCE-REFERENCES
                                                    :HARDENED-TOOL-READING
                                                    :CLOSURE-APPENDIX
                                                    :LATEST-CHECK-PENDING-BASE
                                                    :LIMITS)
spikes/out/ready-main-review-probes.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :SCOPE :METADATA-SOURCE
                                               :ABSENT-METADATA
                                               :CAMPAIGNS-EXECUTED
                                               :ORIGINAL-MASTER-PRESERVED
                                               :PROBES)
PROBES 5 FIRST-KEYS (:PURPOSE :COMMAND-TEXT :COMBINED-TOOL-OUTPUT
                     :TOOL-EXIT-CODE :TOOL-WALL-SECONDS :TOOL-CHUNK-ID
                     :TOOL-ORIGINAL-TOKEN-COUNT :TOOL-OUTPUT-TRUNCATED)
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 0.1969435 :TOOL-CHUNK-ID "9668e8"
   :TOOL-ORIGINAL-TOKEN-COUNT 773)
  (:PURPOSE
   "Lettura indipendente integrazione ASDF/README e hash sulla base 33aa224"
   :COMMAND-TEXT "git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md"
   :COMBINED-TOOL-OUTPUT "33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691
6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \"cbor-package\") (:file \"cbor-header\")))
28:                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")))
47:                             (:file \"manifest-package\") (:file \"manifest-types\")
48:                             (:file \"manifest-decode\") (:file \"manifest-fold\")
49:                             (:file \"manifest-build\") (:file \"manifest-query\"))))
66:                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")))
71:                             (:file \"handoff\") (:file \"ready\")))
83:                             (:file \"decisions-audit\") (:file \"decisions-radix\") (:file \"manifest-support\")
84:                             (:file \"manifest\") (:file \"manifest-audit\")))
92:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
18:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
23:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 8.334e-6 :TOOL-CHUNK-ID "033e54"
   :TOOL-ORIGINAL-TOKEN-COUNT 473)
  (:PURPOSE
   "Lettura indipendente check integrato 33aa224 e soli metadati dei dieci run"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000522904-command-41347-0/report.lisp\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \"FINAL-CHECK ~S~%\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \"COUNTS ~S~%\" (loop for line in (uiop:split-string out :separator '(#\\Newline))
                                   when (or (search \" test \" line) (search \"violazioni\" line)
                                            (search \"requisiti\" line) (search \" link controllati\" line)
                                            (search \"nessun avviso\" line)) collect line))
  (format t \"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\Newline))
                when (or (search \"; caught WARNING:\" line) (search \"; caught STYLE-WARNING:\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \"spikes/out/4000522979-check-41982-0/report.lisp\")))
  (format t \"FINAL-MASTER ~S~%\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \"SPIKE ~S~%\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \"FINAL-ENV ~S~%\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP"
   :COMBINED-TOOL-OUTPUT
   "FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 109.725672d0 :COMMAND
             (\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\"
              \"check-core\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\"26 test delle fondazioni superati.\" \"17 test UTF-8 superati.\"
        \"17 test degli header CBOR superati.\"
        \"20 test del registro CSN superati.\"
        \"51 test delle code writer superati.\"
        \"44 test dei metadati storage superati.\" \"18 test I/O superati.\"
        \"82 test recovery superati.\" \"19 test WAL superati.\"
        \"build e test: nessun avviso, tutti i controlli superati\"
        \"52 file, 0 violazioni\"
        \"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\"
        \"198 file, 1918 link controllati, 0 rotti\")
STDERR-LENGTH 27215 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \"--check\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \"SPK-01\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-02\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-03\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-04\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-05\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-06\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-07\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \"SPK-08\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-09\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \"SPK-10\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \"SBCL\" :VERSION \"2.6.9\" :OS \"Darwin\" :OS-VERSION \"27.0.0\"
           :MACHINE \"ARM64\" :CPU \"Apple M4\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \"{ 2.10 2.88 3.34 }\" :COMMIT
           \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522983)
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 1.2599766 :TOOL-CHUNK-ID "441dfb"
   :TOOL-ORIGINAL-TOKEN-COUNT 615)
  (:PURPOSE
   "Tentativo di serializzazione dell'import fallito prima di ogni scrittura: SETF FIND non valido nel helper di audit; corretto nel tentativo seguente. Non è un warning del prodotto."
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((original (arcdocdb.evidence:read-evidence \"spikes/out/ready-independent-review.lisp\"))
       (review (arcdocdb.evidence:read-evidence \"spikes/out/ready-main-independent-review.lisp\"))
       (probes (arcdocdb.evidence:read-evidence \"spikes/out/ready-main-review-probes.lisp\"))
       (hashes (copy-tree (getf original :source-hashes))))
  (setf (getf (find \"arcdocdb.asd\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=) :sha256) \"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\")
  (setf (getf (find \"tools/writer-ready-mutation.lisp\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=) :sha256) \"06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb\")
  (setf (getf review :report-original) (getf original :report-original)
        (getf review :initial-integration-base) (getf review :base-commit)
        (getf review :fd96-delta-hashes) (getf review :delta-hashes)
        (getf review :base-commit) \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\"
        (getf review :status) :final-locally-verified-no-engine-qualification
        (getf review :open-findings) nil
        (getf review :source-hashes) hashes
        (getf review :raw-coverage) (getf original :raw-coverage)
        (getf review :inventory) '(:path \"docs/implementazione/writer-ready-decisioni.md\" :sha256 \"cc432094d4c5916c22401c38189a5a690b557ef6bd5394313d93af2e8a95183a\")
        (getf review :closure-appendices) (list (list :base-commit \"201562dffd8c48e5d2047f73ef905f64b447e663\" :report \"Appendice locale storica, base 201562dffd8c48e5d2047f73ef905f64b447e663. Il report originale e la chiusura fd96 restano verbatim.
ASDF SHA-256 3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde; registrazioni execution/ready conservate, sorgenti ready/test/bench/runner invariati. Non è una lettura C1 dei sorgenti CBOR.
Check 4000522514-command-56618-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 102.063356 s; 274 test degli otto moduli (26+17 UTF-8+17 CBOR+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 50 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 193 file/1899 link/0 rotti. Stderr note del compilatore/progresso spike, nessun warning/style-warning reale.
Master 4000522582-check-59441-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 3.89 3.37 3.63 }, commit 201562dffd8c48e5d2047f73ef905f64b447e663, date-universal-time 4000522586.
Nessun finding ready aperto. I check precedenti e le campagne mirate mantengono la propria provenienza; nessuna qualifica di pool, prestazioni o motore integrato.\") (list :base-commit \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\" :report \"Appendice locale definitiva, base 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691. Il report originale 92d8 e le appendici fd96/201562 restano verbatim.
ASDF SHA-256 6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc; registrazioni ready conservate. Ready-types, ready, test e strumenti ready sono byte-identici alle letture precedenti. Non è una lettura C1 dei sorgenti CSN.
Check 4000522904-command-41347-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 109.725672 s; 294 test dei nove moduli (26+17 UTF-8+17 CBOR+20 CSN+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 52 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 198 file/1918 link/0 rotti. Stderr 27215 byte, senza righe di warning/style-warning reali.
Master 4000522979-check-41982-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 2.10 2.88 3.34 }, commit 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691, date-universal-time 4000522983.
La verifica locale dei dodici punti è chiusa senza finding ready aperti. I due rilievi testuali iniziali e il rilievo C4 del runner sono chiusi. Native/HTML restano 848/974 espressioni e 126/146 esiti, con lacune nuove e legacy conservate; nessuna esclusione approvata o MC/DC dedotta. Mutazioni finali 12/12 detected senza altri esiti e allocazioni seriali 10/10 heap zero mantengono le basi originali e non qualificano pool, wakeup, shutdown, FAULTED, throughput/P99, scalabilità o motore integrato. Nessuna campagna eseguita dal revisore.\"))
        (getf review :limits) '(:original-report-not-rewritten :historical-pending-statements-retained-as-history :coverage-gaps-retained :no-mcdc-exclusions-approved :no-manifest-cbor-or-csn-source-c1-review :no-pool-or-performance-qualification :no-engine-qualification :no-campaign-executed-by-reviewer))
  (remf review :delta-hashes)
  (remf review :latest-check-pending-base)
  (setf (getf review :evidence-references) (append (getf review :evidence-references) '(\"spikes/out/4000521907-command-44843-0/report.lisp\" \"spikes/out/4000521968-check-46180-0/report.lisp\" \"spikes/out/4000521918-command-45102-0/report.lisp\" \"spikes/out/ready-mutations-final/report.lisp\" \"spikes/out/4000522063-command-47453-0/report.lisp\" \"spikes/out/4000522514-command-56618-0/report.lisp\" \"spikes/out/4000522582-check-59441-0/report.lisp\" \"spikes/out/4000522904-command-41347-0/report.lisp\" \"spikes/out/4000522979-check-41982-0/report.lisp\")))
  (setf (getf probes :probes) (append (getf probes :probes) '( (:purpose \"Lettura indipendente integrazione ASDF/README e hash sulla base 201562\" :command-text \"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\" :combined-tool-output \"201562dffd8c48e5d2047f73ef905f64b447e663
3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")))
26:                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")))
45:                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")
46:                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")
47:                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\"))))
64:                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")))
67:                             (:file \\\"handoff\\\") (:file \\\"ready\\\")))
79:                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")
80:                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")))
88:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
17:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
22:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\" :tool-exit-code 0 :tool-wall-seconds 0.000009541 :tool-chunk-id \"d464dd\" :tool-original-token-count 473)
(:purpose \"Lettura indipendente check integrato 201562 e soli metadati dei dieci run\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522514-command-56618-0/report.lisp\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\"FINAL-CHECK ~S~%\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\"COUNTS ~S~%\\\" (loop for line in (uiop:split-string out :separator '(#\\\\Newline))
                                   when (or (search \\\" test \\\" line) (search \\\"violazioni\\\" line)
                                            (search \\\"requisiti\\\" line) (search \\\" link controllati\\\" line)
                                            (search \\\"nessun avviso\\\" line)) collect line))
  (format t \\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\Newline))
                when (or (search \\\"; caught WARNING:\\\" line) (search \\\"; caught STYLE-WARNING:\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522582-check-59441-0/report.lisp\\\")))
  (format t \\\"FINAL-MASTER ~S~%\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\"SPIKE ~S~%\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\"FINAL-ENV ~S~%\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\" :combined-tool-output \"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 102.063356d0 :COMMAND
             (\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\"
              \\\"check-core\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\"26 test delle fondazioni superati.\\\" \\\"17 test UTF-8 superati.\\\"
        \\\"17 test degli header CBOR superati.\\\"
        \\\"51 test delle code writer superati.\\\"
        \\\"44 test dei metadati storage superati.\\\" \\\"18 test I/O superati.\\\"
        \\\"82 test recovery superati.\\\" \\\"19 test WAL superati.\\\"
        \\\"build e test: nessun avviso, tutti i controlli superati\\\"
        \\\"50 file, 0 violazioni\\\"
        \\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\"
        \\\"193 file, 1899 link controllati, 0 rotti\\\")
STDERR-LENGTH 25842 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\"--check\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\"SPK-01\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-02\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-03\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-04\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-05\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-06\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-07\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\"SPK-08\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-09\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-10\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\"SBCL\\\" :VERSION \\\"2.6.9\\\" :OS \\\"Darwin\\\" :OS-VERSION \\\"27.0.0\\\"
           :MACHINE \\\"ARM64\\\" :CPU \\\"Apple M4\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\"{ 3.89 3.37 3.63 }\\\" :COMMIT
           \\\"201562dffd8c48e5d2047f73ef905f64b447e663\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522586)
\" :tool-exit-code 0 :tool-wall-seconds 1.2876816660000001 :tool-chunk-id \"edd4d3\" :tool-original-token-count 604)
(:purpose \"Lettura struttura degli import per conservazione dei campi e del report originale\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(dolist (p '(\\\"spikes/out/ready-independent-review.lisp\\\" \\\"spikes/out/ready-main-independent-review.lisp\\\" \\\"spikes/out/ready-main-review-probes.lisp\\\"))
 (let ((r (arcdocdb.evidence:read-evidence p)))
 (format t \\\"~A KEYS ~S~%\\\" p (loop for (k v) on r by #'cddr collect k))
 (when (getf r :source-hashes) (format t \\\"HASHES ~S~%\\\" (getf r :source-hashes)))
 (when (getf r :probes) (format t \\\"PROBES ~D FIRST-KEYS ~S~%\\\" (length (getf r :probes)) (loop for (k v) on (first (getf r :probes)) by #'cddr collect k)))))
LISP\" :combined-tool-output \"spikes/out/ready-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :BASE-COMMIT :SCOPE :STATUS
                                               :OPEN-FINDINGS :SOURCE-HASHES
                                               :INVENTORY :EVIDENCE-REFERENCES
                                               :RAW-COVERAGE :PROBES
                                               :REPORT-ORIGINAL
                                               :CLOSURE-APPENDIX :LIMITS)
HASHES ((:FILE \\\"arcdocdb.asd\\\" :SHA256
         \\\"53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3\\\")
        (:FILE \\\"src/execution/package.lisp\\\" :SHA256
         \\\"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\\\")
        (:FILE \\\"src/execution/queue.lisp\\\" :SHA256
         \\\"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\\\")
        (:FILE \\\"src/execution/writer.lisp\\\" :SHA256
         \\\"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\\\")
        (:FILE \\\"src/execution/handoff.lisp\\\" :SHA256
         \\\"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\\\")
        (:FILE \\\"src/execution/ready-types.lisp\\\" :SHA256
         \\\"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\\\")
        (:FILE \\\"src/execution/ready.lisp\\\" :SHA256
         \\\"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\\\")
        (:FILE \\\"tests/execution/ready.lisp\\\" :SHA256
         \\\"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\\\")
        (:FILE \\\"tools/writer-ready-bench.lisp\\\" :SHA256
         \\\"9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4\\\")
        (:FILE \\\"tools/writer-ready-mutation.lisp\\\" :SHA256
         \\\"e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829\\\"))
PROBES 4 FIRST-KEYS NIL
spikes/out/ready-main-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                                    :SCOPE :STATUS :BASE-COMMIT
                                                    :ORIGINAL-REVIEW
                                                    :DELTA-HASHES
                                                    :EVIDENCE-REFERENCES
                                                    :HARDENED-TOOL-READING
                                                    :CLOSURE-APPENDIX
                                                    :LATEST-CHECK-PENDING-BASE
                                                    :LIMITS)
spikes/out/ready-main-review-probes.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :SCOPE :METADATA-SOURCE
                                               :ABSENT-METADATA
                                               :CAMPAIGNS-EXECUTED
                                               :ORIGINAL-MASTER-PRESERVED
                                               :PROBES)
PROBES 5 FIRST-KEYS (:PURPOSE :COMMAND-TEXT :COMBINED-TOOL-OUTPUT
                     :TOOL-EXIT-CODE :TOOL-WALL-SECONDS :TOOL-CHUNK-ID
                     :TOOL-ORIGINAL-TOKEN-COUNT :TOOL-OUTPUT-TRUNCATED)
\" :tool-exit-code 0 :tool-wall-seconds 0.1969435 :tool-chunk-id \"9668e8\" :tool-original-token-count 773)
(:purpose \"Lettura indipendente integrazione ASDF/README e hash sulla base 33aa224\" :command-text \"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\" :combined-tool-output \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691
6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")))
28:                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")))
47:                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")
48:                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")
49:                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\"))))
66:                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")))
71:                             (:file \\\"handoff\\\") (:file \\\"ready\\\")))
83:                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")
84:                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")))
92:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
18:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
23:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\" :tool-exit-code 0 :tool-wall-seconds 0.000008334 :tool-chunk-id \"033e54\" :tool-original-token-count 473)
(:purpose \"Lettura indipendente check integrato 33aa224 e soli metadati dei dieci run\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522904-command-41347-0/report.lisp\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\"FINAL-CHECK ~S~%\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\"COUNTS ~S~%\\\" (loop for line in (uiop:split-string out :separator '(#\\\\Newline))
                                   when (or (search \\\" test \\\" line) (search \\\"violazioni\\\" line)
                                            (search \\\"requisiti\\\" line) (search \\\" link controllati\\\" line)
                                            (search \\\"nessun avviso\\\" line)) collect line))
  (format t \\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\Newline))
                when (or (search \\\"; caught WARNING:\\\" line) (search \\\"; caught STYLE-WARNING:\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522979-check-41982-0/report.lisp\\\")))
  (format t \\\"FINAL-MASTER ~S~%\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\"SPIKE ~S~%\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\"FINAL-ENV ~S~%\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\" :combined-tool-output \"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 109.725672d0 :COMMAND
             (\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\"
              \\\"check-core\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\"26 test delle fondazioni superati.\\\" \\\"17 test UTF-8 superati.\\\"
        \\\"17 test degli header CBOR superati.\\\"
        \\\"20 test del registro CSN superati.\\\"
        \\\"51 test delle code writer superati.\\\"
        \\\"44 test dei metadati storage superati.\\\" \\\"18 test I/O superati.\\\"
        \\\"82 test recovery superati.\\\" \\\"19 test WAL superati.\\\"
        \\\"build e test: nessun avviso, tutti i controlli superati\\\"
        \\\"52 file, 0 violazioni\\\"
        \\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\"
        \\\"198 file, 1918 link controllati, 0 rotti\\\")
STDERR-LENGTH 27215 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\"--check\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\"SPK-01\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-02\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-03\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-04\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-05\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-06\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-07\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\"SPK-08\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-09\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-10\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\"SBCL\\\" :VERSION \\\"2.6.9\\\" :OS \\\"Darwin\\\" :OS-VERSION \\\"27.0.0\\\"
           :MACHINE \\\"ARM64\\\" :CPU \\\"Apple M4\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\"{ 2.10 2.88 3.34 }\\\" :COMMIT
           \\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522983)
\" :tool-exit-code 0 :tool-wall-seconds 1.259976584 :tool-chunk-id \"441dfb\" :tool-original-token-count 615) )))
  (dolist (pair (list (cons \"spikes/out/ready-main-independent-review.lisp\" review) (cons \"spikes/out/ready-main-review-probes.lisp\" probes)))
    (with-open-file (out (car pair) :direction :output :if-exists :supersede :if-does-not-exist :create)
      (with-standard-io-syntax (let ((*print-pretty* t) (*print-circle* nil)) (write (cdr pair) :stream out) (terpri out)))))
  (format t \"CLOSURE-WRITTEN ~S PROBES ~D~%\" (getf review :status) (length (getf probes :probes))))

LISP"
   :COMBINED-TOOL-OUTPUT "Warning: truncated output (original token count: 4838)
Total output lines: 60


; file: /dev/stdin
; in:
;      LET* ((ORIGINAL
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \"spikes/out/ready-independent-review.lisp\"))
;        (REVIEW
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \"spikes/out/ready-main-independent-review.lisp\"))
;        (PROBES
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \"spikes/out/ready-main-review-probes.lisp\"))
;        (HASHES (COPY-TREE (GETF ORIGINAL :SOURCE-HASHES))))
;     (GETF
;      (FIND \"arcdocdb.asd\" HASHES :KEY (LAMBDA (ENTRY) (GETF ENTRY :FILE)) :TEST
;            #'STRING=)
;      :SHA256)
; --> LET FUNCALL 
; ==>
;   1
; 
; caught WARNING:
;   The function (SETF FIND) is undefined, and its name is reserved by ANSI CL so
;   that even if it were defined later, the code doing so would not be portable.
; 
; compilation unit finished
;   Undefined function:
;     (SETF FIND)
;   caught 1 WARNING condition
Unhandled UNDEFINED-FUNCTION in thread #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING
                                          {80086B04B3}>:
  The function (COMMON-LISP:SETF COMMON-LISP:FIND) is undefined.

Backtrace for: #<SB-THREAD:THREAD tid=259 \"main thread\" RUNNING {80086B04B3}>:
0: (\"undefined function\" (:FILE \"arcdocdb.asd\" :SHA256 \"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\") \"arcdocdb.asd\" ((:FILE \"arcdocdb.asd\" :SHA256 \"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\") (:FILE \"src/execution/package.lisp\" :SHA256 \"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\") (:FILE \"src/execution/queue.lisp\" :SHA256 \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\") (:FILE \"src/execution/writer.lisp\" :SHA256 \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\") (:FILE \"src/execution/handoff.lisp\" :SHA256 \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\") (:FILE \"src/execution/ready-types.lisp\" :SHA256 \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\") (:FILE \"src/e…3838 tokens truncated… \"spikes/out/4000522904-command-41347-0/report.lisp\" \"spikes/out/4000522979-check-41982-0/report.lisp\")))) (SETF (GETF PROBES :PROBES) (APPEND (GETF PROBES :PROBES) (QUOTE (# # # # #)))) (DOLIST (PAIR (LIST (CONS \"spikes/out/ready-main-independent-review.lisp\" REVIEW) (CONS \"spikes/out/ready-main-review-probes.lisp\" PROBES))) (WITH-OPEN-FILE (OUT (CAR PAIR) :DIRECTION :OUTPUT :IF-EXISTS :SUPERSEDE :IF-DOES-NOT-EXIST :CREATE) (WITH-STANDARD-IO-SYNTAX (LET # # #)))) (FORMAT T \"CLOSURE-WRITTEN ~S PROBES ~D~%\" (GETF REVIEW :STATUS) (LENGTH (GETF PROBES :PROBES)))) :CURRENT-INDEX 2)
10: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107A40F1B}> #<SB-C::SOURCE-INFO {8008690423}> SB-C::INPUT-ERROR-IN-LOAD)
11: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}> :VERBOSE NIL :PRINT NIL :CONTEXT \"loading\")
12: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}> NIL)
13: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107A409EB}> #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}> NIL #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}>)
14: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}> NIL)
15: (LOAD #<SB-SYS:FD-STREAM for \"file /dev/stdin\" {8008690043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
16: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT))
17: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
18: ((FLET \"WITHOUT-INTERRUPTS-BODY-\" :IN SB-IMPL::PROCESS-SCRIPT))
19: (SB-IMPL::PROCESS-SCRIPT \"/dev/stdin\")
20: (SB-IMPL::TOPLEVEL-INIT)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
22: ((FLET \"WITHOUT-INTERRUPTS-BODY-3\" :IN SB-IMPL::START-LISP))
23: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
"
   :TOOL-EXIT-CODE 1 :TOOL-WALL-SECONDS 0.19899675 :TOOL-CHUNK-ID "c1e30e"
   :TOOL-ORIGINAL-TOKEN-COUNT 4838 :TOOL-OUTPUT-TRUNCATED T)
  (:PURPOSE
   "Serializzazione corretta dell'import dopo il fallimento SETF FIND: entry locale, nessun warning; scrittura dei soli due file ignored"
   :COMMAND-TEXT "sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((original (arcdocdb.evidence:read-evidence \"spikes/out/ready-independent-review.lisp\"))
       (review (arcdocdb.evidence:read-evidence \"spikes/out/ready-main-independent-review.lisp\"))
       (probes (arcdocdb.evidence:read-evidence \"spikes/out/ready-main-review-probes.lisp\"))
       (hashes (copy-tree (getf original :source-hashes))))
  (let ((entry (find \"arcdocdb.asd\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=))) (setf (getf entry :sha256) \"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\"))
  (let ((entry (find \"tools/writer-ready-mutation.lisp\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=))) (setf (getf entry :sha256) \"06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb\"))
  (setf (getf review :report-original) (getf original :report-original)
        (getf review :initial-integration-base) (getf review :base-commit)
        (getf review :fd96-delta-hashes) (getf review :delta-hashes)
        (getf review :base-commit) \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\"
        (getf review :status) :final-locally-verified-no-engine-qualification
        (getf review :open-findings) nil
        (getf review :source-hashes) hashes
        (getf review :raw-coverage) (getf original :raw-coverage)
        (getf review :inventory) '(:path \"docs/implementazione/writer-ready-decisioni.md\" :sha256 \"cc432094d4c5916c22401c38189a5a690b557ef6bd5394313d93af2e8a95183a\")
        (getf review :closure-appendices) (list (list :base-commit \"201562dffd8c48e5d2047f73ef905f64b447e663\" :report \"Appendice locale storica, base 201562dffd8c48e5d2047f73ef905f64b447e663. Il report originale e la chiusura fd96 restano verbatim.
ASDF SHA-256 3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde; registrazioni execution/ready conservate, sorgenti ready/test/bench/runner invariati. Non è una lettura C1 dei sorgenti CBOR.
Check 4000522514-command-56618-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 102.063356 s; 274 test degli otto moduli (26+17 UTF-8+17 CBOR+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 50 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 193 file/1899 link/0 rotti. Stderr note del compilatore/progresso spike, nessun warning/style-warning reale.
Master 4000522582-check-59441-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 3.89 3.37 3.63 }, commit 201562dffd8c48e5d2047f73ef905f64b447e663, date-universal-time 4000522586.
Nessun finding ready aperto. I check precedenti e le campagne mirate mantengono la propria provenienza; nessuna qualifica di pool, prestazioni o motore integrato.\") (list :base-commit \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\" :report \"Appendice locale definitiva, base 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691. Il report originale 92d8 e le appendici fd96/201562 restano verbatim.
ASDF SHA-256 6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc; registrazioni ready conservate. Ready-types, ready, test e strumenti ready sono byte-identici alle letture precedenti. Non è una lettura C1 dei sorgenti CSN.
Check 4000522904-command-41347-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 109.725672 s; 294 test dei nove moduli (26+17 UTF-8+17 CBOR+20 CSN+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 52 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 198 file/1918 link/0 rotti. Stderr 27215 byte, senza righe di warning/style-warning reali.
Master 4000522979-check-41982-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 2.10 2.88 3.34 }, commit 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691, date-universal-time 4000522983.
La verifica locale dei dodici punti è chiusa senza finding ready aperti. I due rilievi testuali iniziali e il rilievo C4 del runner sono chiusi. Native/HTML restano 848/974 espressioni e 126/146 esiti, con lacune nuove e legacy conservate; nessuna esclusione approvata o MC/DC dedotta. Mutazioni finali 12/12 detected senza altri esiti e allocazioni seriali 10/10 heap zero mantengono le basi originali e non qualificano pool, wakeup, shutdown, FAULTED, throughput/P99, scalabilità o motore integrato. Nessuna campagna eseguita dal revisore.\"))
        (getf review :limits) '(:original-report-not-rewritten :historical-pending-statements-retained-as-history :coverage-gaps-retained :no-mcdc-exclusions-approved :no-manifest-cbor-or-csn-source-c1-review :no-pool-or-performance-qualification :no-engine-qualification :no-campaign-executed-by-reviewer))
  (remf review :delta-hashes)
  (remf review :latest-check-pending-base)
  (setf (getf review :evidence-references) (append (getf review :evidence-references) '(\"spikes/out/4000521907-command-44843-0/report.lisp\" \"spikes/out/4000521968-check-46180-0/report.lisp\" \"spikes/out/4000521918-command-45102-0/report.lisp\" \"spikes/out/ready-mutations-final/report.lisp\" \"spikes/out/4000522063-command-47453-0/report.lisp\" \"spikes/out/4000522514-command-56618-0/report.lisp\" \"spikes/out/4000522582-check-59441-0/report.lisp\" \"spikes/out/4000522904-command-41347-0/report.lisp\" \"spikes/out/4000522979-check-41982-0/report.lisp\")))
  (setf (getf probes :probes) (append (getf probes :probes) '( (:purpose \"Lettura indipendente integrazione ASDF/README e hash sulla base 201562\" :command-text \"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\" :combined-tool-output \"201562dffd8c48e5d2047f73ef905f64b447e663
3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")))
26:                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")))
45:                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")
46:                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")
47:                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\"))))
64:                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")))
67:                             (:file \\\"handoff\\\") (:file \\\"ready\\\")))
79:                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")
80:                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")))
88:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
17:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
22:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\" :tool-exit-code 0 :tool-wall-seconds 0.000009541 :tool-chunk-id \"d464dd\" :tool-original-token-count 473)
(:purpose \"Lettura indipendente check integrato 201562 e soli metadati dei dieci run\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522514-command-56618-0/report.lisp\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\"FINAL-CHECK ~S~%\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\"COUNTS ~S~%\\\" (loop for line in (uiop:split-string out :separator '(#\\\\Newline))
                                   when (or (search \\\" test \\\" line) (search \\\"violazioni\\\" line)
                                            (search \\\"requisiti\\\" line) (search \\\" link controllati\\\" line)
                                            (search \\\"nessun avviso\\\" line)) collect line))
  (format t \\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\Newline))
                when (or (search \\\"; caught WARNING:\\\" line) (search \\\"; caught STYLE-WARNING:\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522582-check-59441-0/report.lisp\\\")))
  (format t \\\"FINAL-MASTER ~S~%\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\"SPIKE ~S~%\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\"FINAL-ENV ~S~%\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\" :combined-tool-output \"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 102.063356d0 :COMMAND
             (\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\"
              \\\"check-core\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\"26 test delle fondazioni superati.\\\" \\\"17 test UTF-8 superati.\\\"
        \\\"17 test degli header CBOR superati.\\\"
        \\\"51 test delle code writer superati.\\\"
        \\\"44 test dei metadati storage superati.\\\" \\\"18 test I/O superati.\\\"
        \\\"82 test recovery superati.\\\" \\\"19 test WAL superati.\\\"
        \\\"build e test: nessun avviso, tutti i controlli superati\\\"
        \\\"50 file, 0 violazioni\\\"
        \\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\"
        \\\"193 file, 1899 link controllati, 0 rotti\\\")
STDERR-LENGTH 25842 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\"--check\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\"SPK-01\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-02\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-03\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-04\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-05\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-06\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-07\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\"SPK-08\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-09\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-10\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\"SBCL\\\" :VERSION \\\"2.6.9\\\" :OS \\\"Darwin\\\" :OS-VERSION \\\"27.0.0\\\"
           :MACHINE \\\"ARM64\\\" :CPU \\\"Apple M4\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\"{ 3.89 3.37 3.63 }\\\" :COMMIT
           \\\"201562dffd8c48e5d2047f73ef905f64b447e663\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522586)
\" :tool-exit-code 0 :tool-wall-seconds 1.2876816660000001 :tool-chunk-id \"edd4d3\" :tool-original-token-count 604)
(:purpose \"Lettura struttura degli import per conservazione dei campi e del report originale\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(dolist (p '(\\\"spikes/out/ready-independent-review.lisp\\\" \\\"spikes/out/ready-main-independent-review.lisp\\\" \\\"spikes/out/ready-main-review-probes.lisp\\\"))
 (let ((r (arcdocdb.evidence:read-evidence p)))
 (format t \\\"~A KEYS ~S~%\\\" p (loop for (k v) on r by #'cddr collect k))
 (when (getf r :source-hashes) (format t \\\"HASHES ~S~%\\\" (getf r :source-hashes)))
 (when (getf r :probes) (format t \\\"PROBES ~D FIRST-KEYS ~S~%\\\" (length (getf r :probes)) (loop for (k v) on (first (getf r :probes)) by #'cddr collect k)))))
LISP\" :combined-tool-output \"spikes/out/ready-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :BASE-COMMIT :SCOPE :STATUS
                                               :OPEN-FINDINGS :SOURCE-HASHES
                                               :INVENTORY :EVIDENCE-REFERENCES
                                               :RAW-COVERAGE :PROBES
                                               :REPORT-ORIGINAL
                                               :CLOSURE-APPENDIX :LIMITS)
HASHES ((:FILE \\\"arcdocdb.asd\\\" :SHA256
         \\\"53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3\\\")
        (:FILE \\\"src/execution/package.lisp\\\" :SHA256
         \\\"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\\\")
        (:FILE \\\"src/execution/queue.lisp\\\" :SHA256
         \\\"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\\\")
        (:FILE \\\"src/execution/writer.lisp\\\" :SHA256
         \\\"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\\\")
        (:FILE \\\"src/execution/handoff.lisp\\\" :SHA256
         \\\"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\\\")
        (:FILE \\\"src/execution/ready-types.lisp\\\" :SHA256
         \\\"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\\\")
        (:FILE \\\"src/execution/ready.lisp\\\" :SHA256
         \\\"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\\\")
        (:FILE \\\"tests/execution/ready.lisp\\\" :SHA256
         \\\"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\\\")
        (:FILE \\\"tools/writer-ready-bench.lisp\\\" :SHA256
         \\\"9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4\\\")
        (:FILE \\\"tools/writer-ready-mutation.lisp\\\" :SHA256
         \\\"e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829\\\"))
PROBES 4 FIRST-KEYS NIL
spikes/out/ready-main-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                                    :SCOPE :STATUS :BASE-COMMIT
                                                    :ORIGINAL-REVIEW
                                                    :DELTA-HASHES
                                                    :EVIDENCE-REFERENCES
                                                    :HARDENED-TOOL-READING
                                                    :CLOSURE-APPENDIX
                                                    :LATEST-CHECK-PENDING-BASE
                                                    :LIMITS)
spikes/out/ready-main-review-probes.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :SCOPE :METADATA-SOURCE
                                               :ABSENT-METADATA
                                               :CAMPAIGNS-EXECUTED
                                               :ORIGINAL-MASTER-PRESERVED
                                               :PROBES)
PROBES 5 FIRST-KEYS (:PURPOSE :COMMAND-TEXT :COMBINED-TOOL-OUTPUT
                     :TOOL-EXIT-CODE :TOOL-WALL-SECONDS :TOOL-CHUNK-ID
                     :TOOL-ORIGINAL-TOKEN-COUNT :TOOL-OUTPUT-TRUNCATED)
\" :tool-exit-code 0 :tool-wall-seconds 0.1969435 :tool-chunk-id \"9668e8\" :tool-original-token-count 773)
(:purpose \"Lettura indipendente integrazione ASDF/README e hash sulla base 33aa224\" :command-text \"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\" :combined-tool-output \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691
6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")))
28:                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")))
47:                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")
48:                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")
49:                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\"))))
66:                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")))
71:                             (:file \\\"handoff\\\") (:file \\\"ready\\\")))
83:                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")
84:                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")))
92:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
18:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
23:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\" :tool-exit-code 0 :tool-wall-seconds 0.000008334 :tool-chunk-id \"033e54\" :tool-original-token-count 473)
(:purpose \"Lettura indipendente check integrato 33aa224 e soli metadati dei dieci run\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522904-command-41347-0/report.lisp\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\"FINAL-CHECK ~S~%\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\"COUNTS ~S~%\\\" (loop for line in (uiop:split-string out :separator '(#\\\\Newline))
                                   when (or (search \\\" test \\\" line) (search \\\"violazioni\\\" line)
                                            (search \\\"requisiti\\\" line) (search \\\" link controllati\\\" line)
                                            (search \\\"nessun avviso\\\" line)) collect line))
  (format t \\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\Newline))
                when (or (search \\\"; caught WARNING:\\\" line) (search \\\"; caught STYLE-WARNING:\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\"spikes/out/4000522979-check-41982-0/report.lisp\\\")))
  (format t \\\"FINAL-MASTER ~S~%\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\"SPIKE ~S~%\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\"FINAL-ENV ~S~%\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\" :combined-tool-output \"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 109.725672d0 :COMMAND
             (\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\"
              \\\"check-core\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\"26 test delle fondazioni superati.\\\" \\\"17 test UTF-8 superati.\\\"
        \\\"17 test degli header CBOR superati.\\\"
        \\\"20 test del registro CSN superati.\\\"
        \\\"51 test delle code writer superati.\\\"
        \\\"44 test dei metadati storage superati.\\\" \\\"18 test I/O superati.\\\"
        \\\"82 test recovery superati.\\\" \\\"19 test WAL superati.\\\"
        \\\"build e test: nessun avviso, tutti i controlli superati\\\"
        \\\"52 file, 0 violazioni\\\"
        \\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\"
        \\\"198 file, 1918 link controllati, 0 rotti\\\")
STDERR-LENGTH 27215 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\"--check\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\"SPK-01\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-02\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-03\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-04\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-05\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-06\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-07\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\"SPK-08\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-09\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\"SPK-10\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\"SBCL\\\" :VERSION \\\"2.6.9\\\" :OS \\\"Darwin\\\" :OS-VERSION \\\"27.0.0\\\"
           :MACHINE \\\"ARM64\\\" :CPU \\\"Apple M4\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\"{ 2.10 2.88 3.34 }\\\" :COMMIT
           \\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522983)
\" :tool-exit-code 0 :tool-wall-seconds 1.259976584 :tool-chunk-id \"441dfb\" :tool-original-token-count 615)
(:purpose \"Tentativo di serializzazione dell'import fallito prima di ogni scrittura: SETF FIND non valido nel helper di audit; corretto nel tentativo seguente. Non è un warning del prodotto.\" :command-text \"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\"tools/evidence-storage.lisp\\\")
(let* ((original (arcdocdb.evidence:read-evidence \\\"spikes/out/ready-independent-review.lisp\\\"))
       (review (arcdocdb.evidence:read-evidence \\\"spikes/out/ready-main-independent-review.lisp\\\"))
       (probes (arcdocdb.evidence:read-evidence \\\"spikes/out/ready-main-review-probes.lisp\\\"))
       (hashes (copy-tree (getf original :source-hashes))))
  (setf (getf (find \\\"arcdocdb.asd\\\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=) :sha256) \\\"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\\\")
  (setf (getf (find \\\"tools/writer-ready-mutation.lisp\\\" hashes :key (lambda (entry) (getf entry :file)) :test #'string=) :sha256) \\\"06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb\\\")
  (setf (getf review :report-original) (getf original :report-original)
        (getf review :initial-integration-base) (getf review :base-commit)
        (getf review :fd96-delta-hashes) (getf review :delta-hashes)
        (getf review :base-commit) \\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\\\"
        (getf review :status) :final-locally-verified-no-engine-qualification
        (getf review :open-findings) nil
        (getf review :source-hashes) hashes
        (getf review :raw-coverage) (getf original :raw-coverage)
        (getf review :inventory) '(:path \\\"docs/implementazione/writer-ready-decisioni.md\\\" :sha256 \\\"cc432094d4c5916c22401c38189a5a690b557ef6bd5394313d93af2e8a95183a\\\")
        (getf review :closure-appendices) (list (list :base-commit \\\"201562dffd8c48e5d2047f73ef905f64b447e663\\\" :report \\\"Appendice locale storica, base 201562dffd8c48e5d2047f73ef905f64b447e663. Il report originale e la chiusura fd96 restano verbatim.
ASDF SHA-256 3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde; registrazioni execution/ready conservate, sorgenti ready/test/bench/runner invariati. Non è una lettura C1 dei sorgenti CBOR.
Check 4000522514-command-56618-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 102.063356 s; 274 test degli otto moduli (26+17 UTF-8+17 CBOR+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 50 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 193 file/1899 link/0 rotti. Stderr note del compilatore/progresso spike, nessun warning/style-warning reale.
Master 4000522582-check-59441-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 3.89 3.37 3.63 }, commit 201562dffd8c48e5d2047f73ef905f64b447e663, date-universal-time 4000522586.
Nessun finding ready aperto. I check precedenti e le campagne mirate mantengono la propria provenienza; nessuna qualifica di pool, prestazioni o motore integrato.\\\") (list :base-commit \\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\\\" :report \\\"Appendice locale definitiva, base 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691. Il report originale 92d8 e le appendici fd96/201562 restano verbatim.
ASDF SHA-256 6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc; registrazioni ready conservate. Ready-types, ready, test e strumenti ready sono byte-identici alle letture precedenti. Non è una lettura C1 dei sorgenti CSN.
Check 4000522904-command-41347-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 109.725672 s; 294 test dei nove moduli (26+17 UTF-8+17 CBOR+20 CSN+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 52 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 198 file/1918 link/0 rotti. Stderr 27215 byte, senza righe di warning/style-warning reali.
Master 4000522979-check-41982-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 2.10 2.88 3.34 }, commit 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691, date-universal-time 4000522983.
La verifica locale dei dodici punti è chiusa senza finding ready aperti. I due rilievi testuali iniziali e il rilievo C4 del runner sono chiusi. Native/HTML restano 848/974 espressioni e 126/146 esiti, con lacune nuove e legacy conservate; nessuna esclusione approvata o MC/DC dedotta. Mutazioni finali 12/12 detected senza altri esiti e allocazioni seriali 10/10 heap zero mantengono le basi originali e non qualificano pool, wakeup, shutdown, FAULTED, throughput/P99, scalabilità o motore integrato. Nessuna campagna eseguita dal revisore.\\\"))
        (getf review :limits) '(:original-report-not-rewritten :historical-pending-statements-retained-as-history :coverage-gaps-retained :no-mcdc-exclusions-approved :no-manifest-cbor-or-csn-source-c1-review :no-pool-or-performance-qualification :no-engine-qualification :no-campaign-executed-by-reviewer))
  (remf review :delta-hashes)
  (remf review :latest-check-pending-base)
  (setf (getf review :evidence-references) (append (getf review :evidence-references) '(\\\"spikes/out/4000521907-command-44843-0/report.lisp\\\" \\\"spikes/out/4000521968-check-46180-0/report.lisp\\\" \\\"spikes/out/4000521918-command-45102-0/report.lisp\\\" \\\"spikes/out/ready-mutations-final/report.lisp\\\" \\\"spikes/out/4000522063-command-47453-0/report.lisp\\\" \\\"spikes/out/4000522514-command-56618-0/report.lisp\\\" \\\"spikes/out/4000522582-check-59441-0/report.lisp\\\" \\\"spikes/out/4000522904-command-41347-0/report.lisp\\\" \\\"spikes/out/4000522979-check-41982-0/report.lisp\\\")))
  (setf (getf probes :probes) (append (getf probes :probes) '( (:purpose \\\"Lettura indipendente integrazione ASDF/README e hash sulla base 201562\\\" :command-text \\\"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\\\" :combined-tool-output \\\"201562dffd8c48e5d2047f73ef905f64b447e663
3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\\\\\"cbor-package\\\\\\\") (:file \\\\\\\"cbor-header\\\\\\\")))
26:                             (:file \\\\\\\"handoff\\\\\\\") (:file \\\\\\\"ready-types\\\\\\\") (:file \\\\\\\"ready\\\\\\\")))
45:                             (:file \\\\\\\"manifest-package\\\\\\\") (:file \\\\\\\"manifest-types\\\\\\\")
46:                             (:file \\\\\\\"manifest-decode\\\\\\\") (:file \\\\\\\"manifest-fold\\\\\\\")
47:                             (:file \\\\\\\"manifest-build\\\\\\\") (:file \\\\\\\"manifest-query\\\\\\\"))))
64:                             (:file \\\\\\\"cbor-support\\\\\\\") (:file \\\\\\\"cbor-header\\\\\\\") (:file \\\\\\\"cbor-threads\\\\\\\")))
67:                             (:file \\\\\\\"handoff\\\\\\\") (:file \\\\\\\"ready\\\\\\\")))
79:                             (:file \\\\\\\"decisions-audit\\\\\\\") (:file \\\\\\\"decisions-radix\\\\\\\") (:file \\\\\\\"manifest-support\\\\\\\")
80:                             (:file \\\\\\\"manifest\\\\\\\") (:file \\\\\\\"manifest-audit\\\\\\\")))
88:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
17:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
22:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\\\" :tool-exit-code 0 :tool-wall-seconds 0.000009541 :tool-chunk-id \\\"d464dd\\\" :tool-original-token-count 473)
(:purpose \\\"Lettura indipendente check integrato 201562 e soli metadati dei dieci run\\\" :command-text \\\"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\\\\\"tools/evidence-storage.lisp\\\\\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\\\\\"spikes/out/4000522514-command-56618-0/report.lisp\\\\\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\\\\\"FINAL-CHECK ~S~%\\\\\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\\\\\"COUNTS ~S~%\\\\\\\" (loop for line in (uiop:split-string out :separator '(#\\\\\\\\Newline))
                                   when (or (search \\\\\\\" test \\\\\\\" line) (search \\\\\\\"violazioni\\\\\\\" line)
                                            (search \\\\\\\"requisiti\\\\\\\" line) (search \\\\\\\" link controllati\\\\\\\" line)
                                            (search \\\\\\\"nessun avviso\\\\\\\" line)) collect line))
  (format t \\\\\\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\\\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\\\\\Newline))
                when (or (search \\\\\\\"; caught WARNING:\\\\\\\" line) (search \\\\\\\"; caught STYLE-WARNING:\\\\\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\\\\\"spikes/out/4000522582-check-59441-0/report.lisp\\\\\\\")))
  (format t \\\\\\\"FINAL-MASTER ~S~%\\\\\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\\\\\"SPIKE ~S~%\\\\\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\\\\\"FINAL-ENV ~S~%\\\\\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\\\" :combined-tool-output \\\"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 102.063356d0 :COMMAND
             (\\\\\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\\\\\"
              \\\\\\\"check-core\\\\\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\\\\\"26 test delle fondazioni superati.\\\\\\\" \\\\\\\"17 test UTF-8 superati.\\\\\\\"
        \\\\\\\"17 test degli header CBOR superati.\\\\\\\"
        \\\\\\\"51 test delle code writer superati.\\\\\\\"
        \\\\\\\"44 test dei metadati storage superati.\\\\\\\" \\\\\\\"18 test I/O superati.\\\\\\\"
        \\\\\\\"82 test recovery superati.\\\\\\\" \\\\\\\"19 test WAL superati.\\\\\\\"
        \\\\\\\"build e test: nessun avviso, tutti i controlli superati\\\\\\\"
        \\\\\\\"50 file, 0 violazioni\\\\\\\"
        \\\\\\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\\\\\"
        \\\\\\\"193 file, 1899 link controllati, 0 rotti\\\\\\\")
STDERR-LENGTH 25842 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\\\\\"--check\\\\\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\\\\\"SPK-01\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-02\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-03\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-04\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-05\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-06\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-07\\\\\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\\\\\"SPK-08\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-09\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-10\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\\\\\"SBCL\\\\\\\" :VERSION \\\\\\\"2.6.9\\\\\\\" :OS \\\\\\\"Darwin\\\\\\\" :OS-VERSION \\\\\\\"27.0.0\\\\\\\"
           :MACHINE \\\\\\\"ARM64\\\\\\\" :CPU \\\\\\\"Apple M4\\\\\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\\\\\"{ 3.89 3.37 3.63 }\\\\\\\" :COMMIT
           \\\\\\\"201562dffd8c48e5d2047f73ef905f64b447e663\\\\\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522586)
\\\" :tool-exit-code 0 :tool-wall-seconds 1.2876816660000001 :tool-chunk-id \\\"edd4d3\\\" :tool-original-token-count 604)
(:purpose \\\"Lettura struttura degli import per conservazione dei campi e del report originale\\\" :command-text \\\"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\\\\\"tools/evidence-storage.lisp\\\\\\\")
(dolist (p '(\\\\\\\"spikes/out/ready-independent-review.lisp\\\\\\\" \\\\\\\"spikes/out/ready-main-independent-review.lisp\\\\\\\" \\\\\\\"spikes/out/ready-main-review-probes.lisp\\\\\\\"))
 (let ((r (arcdocdb.evidence:read-evidence p)))
 (format t \\\\\\\"~A KEYS ~S~%\\\\\\\" p (loop for (k v) on r by #'cddr collect k))
 (when (getf r :source-hashes) (format t \\\\\\\"HASHES ~S~%\\\\\\\" (getf r :source-hashes)))
 (when (getf r :probes) (format t \\\\\\\"PROBES ~D FIRST-KEYS ~S~%\\\\\\\" (length (getf r :probes)) (loop for (k v) on (first (getf r :probes)) by #'cddr collect k)))))
LISP\\\" :combined-tool-output \\\"spikes/out/ready-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :BASE-COMMIT :SCOPE :STATUS
                                               :OPEN-FINDINGS :SOURCE-HASHES
                                               :INVENTORY :EVIDENCE-REFERENCES
                                               :RAW-COVERAGE :PROBES
                                               :REPORT-ORIGINAL
                                               :CLOSURE-APPENDIX :LIMITS)
HASHES ((:FILE \\\\\\\"arcdocdb.asd\\\\\\\" :SHA256
         \\\\\\\"53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3\\\\\\\")
        (:FILE \\\\\\\"src/execution/package.lisp\\\\\\\" :SHA256
         \\\\\\\"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\\\\\\\")
        (:FILE \\\\\\\"src/execution/queue.lisp\\\\\\\" :SHA256
         \\\\\\\"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\\\\\\\")
        (:FILE \\\\\\\"src/execution/writer.lisp\\\\\\\" :SHA256
         \\\\\\\"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\\\\\\\")
        (:FILE \\\\\\\"src/execution/handoff.lisp\\\\\\\" :SHA256
         \\\\\\\"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\\\\\\\")
        (:FILE \\\\\\\"src/execution/ready-types.lisp\\\\\\\" :SHA256
         \\\\\\\"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\\\\\\\")
        (:FILE \\\\\\\"src/execution/ready.lisp\\\\\\\" :SHA256
         \\\\\\\"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\\\\\\\")
        (:FILE \\\\\\\"tests/execution/ready.lisp\\\\\\\" :SHA256
         \\\\\\\"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\\\\\\\")
        (:FILE \\\\\\\"tools/writer-ready-bench.lisp\\\\\\\" :SHA256
         \\\\\\\"9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4\\\\\\\")
        (:FILE \\\\\\\"tools/writer-ready-mutation.lisp\\\\\\\" :SHA256
         \\\\\\\"e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829\\\\\\\"))
PROBES 4 FIRST-KEYS NIL
spikes/out/ready-main-independent-review.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                                    :SCOPE :STATUS :BASE-COMMIT
                                                    :ORIGINAL-REVIEW
                                                    :DELTA-HASHES
                                                    :EVIDENCE-REFERENCES
                                                    :HARDENED-TOOL-READING
                                                    :CLOSURE-APPENDIX
                                                    :LATEST-CHECK-PENDING-BASE
                                                    :LIMITS)
spikes/out/ready-main-review-probes.lisp KEYS (:SCHEMA-VERSION :KIND :ROLE
                                               :SCOPE :METADATA-SOURCE
                                               :ABSENT-METADATA
                                               :CAMPAIGNS-EXECUTED
                                               :ORIGINAL-MASTER-PRESERVED
                                               :PROBES)
PROBES 5 FIRST-KEYS (:PURPOSE :COMMAND-TEXT :COMBINED-TOOL-OUTPUT
                     :TOOL-EXIT-CODE :TOOL-WALL-SECONDS :TOOL-CHUNK-ID
                     :TOOL-ORIGINAL-TOKEN-COUNT :TOOL-OUTPUT-TRUNCATED)
\\\" :tool-exit-code 0 :tool-wall-seconds 0.1969435 :tool-chunk-id \\\"9668e8\\\" :tool-original-token-count 773)
(:purpose \\\"Lettura indipendente integrazione ASDF/README e hash sulla base 33aa224\\\" :command-text \\\"git rev-parse HEAD
shasum -a 256 arcdocdb.asd src/execution/ready-types.lisp src/execution/ready.lisp tests/execution/ready.lisp tools/writer-ready-bench.lisp tools/writer-ready-mutation.lisp
rg -n 'ready|cbor|manifest' arcdocdb.asd
rg -n 'Lista dei writer pronti|CBOR|Manifest' docs/implementazione/README.md\\\" :combined-tool-output \\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691
6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc  arcdocdb.asd
0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f  src/execution/ready-types.lisp
a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327  src/execution/ready.lisp
4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e  tests/execution/ready.lisp
9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4  tools/writer-ready-bench.lisp
06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb  tools/writer-ready-mutation.lisp
23:                             (:file \\\\\\\"cbor-package\\\\\\\") (:file \\\\\\\"cbor-header\\\\\\\")))
28:                             (:file \\\\\\\"handoff\\\\\\\") (:file \\\\\\\"ready-types\\\\\\\") (:file \\\\\\\"ready\\\\\\\")))
47:                             (:file \\\\\\\"manifest-package\\\\\\\") (:file \\\\\\\"manifest-types\\\\\\\")
48:                             (:file \\\\\\\"manifest-decode\\\\\\\") (:file \\\\\\\"manifest-fold\\\\\\\")
49:                             (:file \\\\\\\"manifest-build\\\\\\\") (:file \\\\\\\"manifest-query\\\\\\\"))))
66:                             (:file \\\\\\\"cbor-support\\\\\\\") (:file \\\\\\\"cbor-header\\\\\\\") (:file \\\\\\\"cbor-threads\\\\\\\")))
71:                             (:file \\\\\\\"handoff\\\\\\\") (:file \\\\\\\"ready\\\\\\\")))
83:                             (:file \\\\\\\"decisions-audit\\\\\\\") (:file \\\\\\\"decisions-radix\\\\\\\") (:file \\\\\\\"manifest-support\\\\\\\")
84:                             (:file \\\\\\\"manifest\\\\\\\") (:file \\\\\\\"manifest-audit\\\\\\\")))
92:             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
11:| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
18:| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
23:| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
\\\" :tool-exit-code 0 :tool-wall-seconds 0.000008334 :tool-chunk-id \\\"033e54\\\" :tool-original-token-count 473)
(:purpose \\\"Lettura indipendente check integrato 33aa224 e soli metadati dei dieci run\\\" :command-text \\\"sbcl --noinform --script /dev/stdin <<'LISP'
(require :asdf)
(load \\\\\\\"tools/evidence-storage.lisp\\\\\\\")
(let* ((r (arcdocdb.evidence:read-evidence \\\\\\\"spikes/out/4000522904-command-41347-0/report.lisp\\\\\\\"))
       (out (getf r :stdout)) (err (getf r :stderr)))
  (format t \\\\\\\"FINAL-CHECK ~S~%\\\\\\\" (loop for k in '(:kind :status :source-consistency :exit-code :wall-seconds :command :limits) append (list k (getf r k))))
  (format t \\\\\\\"COUNTS ~S~%\\\\\\\" (loop for line in (uiop:split-string out :separator '(#\\\\\\\\Newline))
                                   when (or (search \\\\\\\" test \\\\\\\" line) (search \\\\\\\"violazioni\\\\\\\" line)
                                            (search \\\\\\\"requisiti\\\\\\\" line) (search \\\\\\\" link controllati\\\\\\\" line)
                                            (search \\\\\\\"nessun avviso\\\\\\\" line)) collect line))
  (format t \\\\\\\"STDERR-LENGTH ~D COMPILER-WARNING-LINES ~S~%\\\\\\\" (length err)
          (loop for line in (uiop:split-string err :separator '(#\\\\\\\\Newline))
                when (or (search \\\\\\\"; caught WARNING:\\\\\\\" line) (search \\\\\\\"; caught STYLE-WARNING:\\\\\\\" line)) collect line)))
(let* ((*read-eval* nil) (r (arcdocdb.evidence:read-evidence \\\\\\\"spikes/out/4000522979-check-41982-0/report.lisp\\\\\\\")))
  (format t \\\\\\\"FINAL-MASTER ~S~%\\\\\\\" (list :status (getf r :status) :mode (getf r :mode) :runs (length (getf r :runs)) :artifacts (length (getf r :run-artifacts))))
  (dolist (run (getf r :runs))
    (let* ((raw-result (getf run :result)) (result (if (stringp raw-result) (read-from-string raw-result) raw-result)))
      (format t \\\\\\\"SPIKE ~S~%\\\\\\\" (list :id (getf run :id) :status (getf run :status)
                                 :exit-code (getf run :exit-code) :source-consistency (getf run :source-consistency)
                                 :result-status (getf result :status)))))
  (let ((e (getf r :environment)))
    (format t \\\\\\\"FINAL-ENV ~S~%\\\\\\\" (loop for k in '(:lisp :version :os :os-version :machine :cpu :memory-bytes :logical-cpus :external-load-status :load-average :commit :dynamic-space-mib :date-universal-time) append (list k (getf e k))))))
LISP\\\" :combined-tool-output \\\"FINAL-CHECK (:KIND :COMMAND-VERIFICATION :STATUS :OK :SOURCE-CONSISTENCY
             :STABLE :EXIT-CODE 0 :WALL-SECONDS 109.725672d0 :COMMAND
             (\\\\\\\"/Applications/Xcode.app/Contents/Developer/usr/bin/make\\\\\\\"
              \\\\\\\"check-core\\\\\\\")
             :LIMITS
             (:COMMAND-OUTPUT-IS-RAW :WALL-TIME-INCLUDES-ENTIRE-COMMAND
              :NO-AUTOMATIC-REQUIREMENT-PROMOTION))
COUNTS (\\\\\\\"26 test delle fondazioni superati.\\\\\\\" \\\\\\\"17 test UTF-8 superati.\\\\\\\"
        \\\\\\\"17 test degli header CBOR superati.\\\\\\\"
        \\\\\\\"20 test del registro CSN superati.\\\\\\\"
        \\\\\\\"51 test delle code writer superati.\\\\\\\"
        \\\\\\\"44 test dei metadati storage superati.\\\\\\\" \\\\\\\"18 test I/O superati.\\\\\\\"
        \\\\\\\"82 test recovery superati.\\\\\\\" \\\\\\\"19 test WAL superati.\\\\\\\"
        \\\\\\\"build e test: nessun avviso, tutti i controlli superati\\\\\\\"
        \\\\\\\"52 file, 0 violazioni\\\\\\\"
        \\\\\\\"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\\\\\\\"
        \\\\\\\"198 file, 1918 link controllati, 0 rotti\\\\\\\")
STDERR-LENGTH 27215 COMPILER-WARNING-LINES NIL
FINAL-MASTER (:STATUS :COMPLETE :MODE \\\\\\\"--check\\\\\\\" :RUNS 10 :ARTIFACTS 10)
SPIKE (:ID \\\\\\\"SPK-01\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-02\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-03\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-04\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-05\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-06\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-07\\\\\\\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :PASS)
SPIKE (:ID \\\\\\\"SPK-08\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-09\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
SPIKE (:ID \\\\\\\"SPK-10\\\\\\\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE
       :RESULT-STATUS :OK)
FINAL-ENV (:LISP \\\\\\\"SBCL\\\\\\\" :VERSION \\\\\\\"2.6.9\\\\\\\" :OS \\\\\\\"Darwin\\\\\\\" :OS-VERSION \\\\\\\"27.0.0\\\\\\\"
           :MACHINE \\\\\\\"ARM64\\\\\\\" :CPU \\\\\\\"Apple M4\\\\\\\" :MEMORY-BYTES 17179869184
           :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED :LOAD-AVERAGE
           \\\\\\\"{ 2.10 2.88 3.34 }\\\\\\\" :COMMIT
           \\\\\\\"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\\\\\\\" :DYNAMIC-SPACE-MIB 4096
           :DATE-UNIVERSAL-TIME 4000522983)
\\\" :tool-exit-code 0 :tool-wall-seconds 1.259976584 :tool-chunk-id \\\"441dfb\\\" :tool-original-token-count 615) )))
  (dolist (pair (list (cons \\\"spikes/out/ready-main-independent-review.lisp\\\" review) (cons \\\"spikes/out/ready-main-review-probes.lisp\\\" probes)))
    (with-open-file (out (car pair) :direction :output :if-exists :supersede :if-does-not-exist :create)
      (with-standard-io-syntax (let ((*print-pretty* t) (*print-circle* nil)) (write (cdr pair) :stream out) (terpri out)))))
  (format t \\\"CLOSURE-WRITTEN ~S PROBES ~D~%\\\" (getf review :status) (length (getf probes :probes))))

LISP\" :combined-tool-output \"Warning: truncated output (original token count: 4838)
Total output lines: 60


; file: /dev/stdin
; in:
;      LET* ((ORIGINAL
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \\\"spikes/out/ready-independent-review.lisp\\\"))
;        (REVIEW
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \\\"spikes/out/ready-main-independent-review.lisp\\\"))
;        (PROBES
;         (ARCDOCDB.EVIDENCE:READ-EVIDENCE
;          \\\"spikes/out/ready-main-review-probes.lisp\\\"))
;        (HASHES (COPY-TREE (GETF ORIGINAL :SOURCE-HASHES))))
;     (GETF
;      (FIND \\\"arcdocdb.asd\\\" HASHES :KEY (LAMBDA (ENTRY) (GETF ENTRY :FILE)) :TEST
;            #'STRING=)
;      :SHA256)
; --> LET FUNCALL 
; ==>
;   1
; 
; caught WARNING:
;   The function (SETF FIND) is undefined, and its name is reserved by ANSI CL so
;   that even if it were defined later, the code doing so would not be portable.
; 
; compilation unit finished
;   Undefined function:
;     (SETF FIND)
;   caught 1 WARNING condition
Unhandled UNDEFINED-FUNCTION in thread #<SB-THREAD:THREAD tid=259 \\\"main thread\\\" RUNNING
                                          {80086B04B3}>:
  The function (COMMON-LISP:SETF COMMON-LISP:FIND) is undefined.

Backtrace for: #<SB-THREAD:THREAD tid=259 \\\"main thread\\\" RUNNING {80086B04B3}>:
0: (\\\"undefined function\\\" (:FILE \\\"arcdocdb.asd\\\" :SHA256 \\\"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\\\") \\\"arcdocdb.asd\\\" ((:FILE \\\"arcdocdb.asd\\\" :SHA256 \\\"6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc\\\") (:FILE \\\"src/execution/package.lisp\\\" :SHA256 \\\"97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8\\\") (:FILE \\\"src/execution/queue.lisp\\\" :SHA256 \\\"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\\\") (:FILE \\\"src/execution/writer.lisp\\\" :SHA256 \\\"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\\\") (:FILE \\\"src/execution/handoff.lisp\\\" :SHA256 \\\"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\\\") (:FILE \\\"src/execution/ready-types.lisp\\\" :SHA256 \\\"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\\\") (:FILE \\\"src/e…3838 tokens truncated… \\\"spikes/out/4000522904-command-41347-0/report.lisp\\\" \\\"spikes/out/4000522979-check-41982-0/report.lisp\\\")))) (SETF (GETF PROBES :PROBES) (APPEND (GETF PROBES :PROBES) (QUOTE (# # # # #)))) (DOLIST (PAIR (LIST (CONS \\\"spikes/out/ready-main-independent-review.lisp\\\" REVIEW) (CONS \\\"spikes/out/ready-main-review-probes.lisp\\\" PROBES))) (WITH-OPEN-FILE (OUT (CAR PAIR) :DIRECTION :OUTPUT :IF-EXISTS :SUPERSEDE :IF-DOES-NOT-EXIST :CREATE) (WITH-STANDARD-IO-SYNTAX (LET # # #)))) (FORMAT T \\\"CLOSURE-WRITTEN ~S PROBES ~D~%\\\" (GETF REVIEW :STATUS) (LENGTH (GETF PROBES :PROBES)))) :CURRENT-INDEX 2)
10: (SB-C::%DO-FORMS-FROM-INFO #<FUNCTION (LAMBDA (SB-KERNEL:FORM &KEY :CURRENT-INDEX &ALLOW-OTHER-KEYS) :IN SB-INT:LOAD-AS-SOURCE) {107A40F1B}> #<SB-C::SOURCE-INFO {8008690423}> SB-C::INPUT-ERROR-IN-LOAD)
11: (SB-INT:LOAD-AS-SOURCE #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}> :VERBOSE NIL :PRINT NIL :CONTEXT \\\"loading\\\")
12: ((LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}> NIL)
13: (SB-FASL::CALL-WITH-LOAD-BINDINGS #<FUNCTION (LABELS SB-FASL::LOAD-STREAM-1 :IN LOAD) {107A409EB}> #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}> NIL #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}>)
14: ((LABELS SB-FASL::LOAD-STREAM :IN LOAD) #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}> NIL)
15: (LOAD #<SB-SYS:FD-STREAM for \\\"file /dev/stdin\\\" {8008690043}> :VERBOSE NIL :PRINT NIL :IF-DOES-NOT-EXIST :ERROR :EXTERNAL-FORMAT :DEFAULT)
16: ((FLET SB-IMPL::LOAD-SCRIPT :IN SB-IMPL::PROCESS-SCRIPT))
17: ((FLET SB-UNIX::BODY :IN SB-IMPL::PROCESS-SCRIPT))
18: ((FLET \\\"WITHOUT-INTERRUPTS-BODY-\\\" :IN SB-IMPL::PROCESS-SCRIPT))
19: (SB-IMPL::PROCESS-SCRIPT \\\"/dev/stdin\\\")
20: (SB-IMPL::TOPLEVEL-INIT)
21: ((FLET SB-UNIX::BODY :IN SB-IMPL::START-LISP))
22: ((FLET \\\"WITHOUT-INTERRUPTS-BODY-3\\\" :IN SB-IMPL::START-LISP))
23: (SB-IMPL::%START-LISP)

unhandled condition in --disable-debugger mode, quitting
\" :tool-exit-code 1 :tool-wall-seconds 0.19899675 :tool-chunk-id \"c1e30e\" :tool-original-token-count 4838 :tool-output-truncated t) )))
  (dolist (pair (list (cons \"spikes/out/ready-main-independent-review.lisp\" review) (cons \"spikes/out/ready-main-review-probes.lisp\" probes)))
    (with-open-file (out (car pair) :direction :output :if-exists :supersede :if-does-not-exist :create)
      (with-standard-io-syntax (let ((*print-pretty* t) (*print-circle* nil)) (write (cdr pair) :stream out) (terpri out)))))
  (format t \"CLOSURE-WRITTEN ~S PROBES ~D~%\" (getf review :status) (length (getf probes :probes))))

LISP"
   :COMBINED-TOOL-OUTPUT
   "CLOSURE-WRITTEN :FINAL-LOCALLY-VERIFIED-NO-ENGINE-QUALIFICATION PROBES 11
"
   :TOOL-EXIT-CODE 0 :TOOL-WALL-SECONDS 0.16168872 :TOOL-CHUNK-ID "a48151"
   :TOOL-ORIGINAL-TOKEN-COUNT 19)))
