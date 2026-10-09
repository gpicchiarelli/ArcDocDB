(:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-SELF-TEST :STATUS :OK :CHECKS 24
 :CASES
 ((:CASE "positive" :EXPECTED-REASON NIL :OBSERVED-EXIT-CODE 0 :STATUS :OK
   :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/positive.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/positive.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :OK :ARCHIVE
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/positive/"
    :INDEXED-FILES 7 :ACTUAL-FILES 9 :INDEXED-BYTES 776 :PROCESSES
    ((:LABEL "plain" :RECORD-PATH "processes/plain/report.lisp" :COMMAND
      ("fixture" "plain") :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
     (:LABEL "gzip" :RECORD-PATH "processes/gzip/report.lisp" :COMMAND
      ("fixture" "gzip") :STATUS :ERROR :EXIT-CODE 1 :SOURCE-CONSISTENCY
      :CHANGED))
    :INDEX-SHA256
    "ba788fed2f66d2554f325d913149a419ff06e9e9d2637d67abf958a2713cc334"
    :CATALOGUE-SHA256
    "8b4a773dde65ea536bf322f1e7f546a3d119e41bc5615f9797e082c3509a7690"
    :ORIGINS-COMPARED NIL :CLOSED-INVENTORY T :READ-EVAL NIL :EOF-REQUIRED T
    :LIMITS
    (:PLAIN-BYTES 1048576 :GZIP-BYTES 8388608 :PROCESS-EXPANDED-BYTES 134217728
     :ENTRIES 100000 :DIRECTORY-DEPTH 128 :DIRECTORY-ENUMERATION-NOT-PREBOUNDED
     T :PER-FILE-LOCAL-OBSERVATION T :ATOMIC-PUBLICATION NIL
     :RESULT-OR-GATE-INFERENCE NIL :MCDC-CLAIM NIL)))
  (:CASE "corrupt" :EXPECTED-REASON :SHA256 :OBSERVED-EXIT-CODE 1 :STATUS :OK
   :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/corrupt.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/corrupt.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :SHA256 :PATH "raw/data.bin" :DIAGNOSTIC "SHA256 diverso dall'indice."))
  (:CASE "bytes" :EXPECTED-REASON :BYTES :OBSERVED-EXIT-CODE 1 :STATUS :OK
   :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/bytes.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/bytes.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :BYTES :PATH "raw/data.bin" :DIAGNOSTIC "Dimensione diversa dall'indice."))
  (:CASE "missing" :EXPECTED-REASON :MISSING-FILE :OBSERVED-EXIT-CODE 1 :STATUS
   :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/missing.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/missing.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :MISSING-FILE :PATH "raw/data.bin" :DIAGNOSTIC
    "Componente assente o non accessibile."))
  (:CASE "extra" :EXPECTED-REASON :INVENTORY :OBSERVED-EXIT-CODE 1 :STATUS :OK
   :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/extra.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/extra.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :INVENTORY :PATH ".unindexed" :DIAGNOSTIC
    "File effettivo non indicizzato."))
  (:CASE "absolute" :EXPECTED-REASON :RELATIVE-PATH :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/absolute.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/absolute.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :RELATIVE-PATH :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/positive/raw/data.bin"
    :DIAGNOSTIC "Componenti vuote, assolute o di escape vietate."))
  (:CASE "escape" :EXPECTED-REASON :RELATIVE-PATH :OBSERVED-EXIT-CODE 1 :STATUS
   :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/escape.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/escape.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :RELATIVE-PATH :PATH "../positive/raw/data.bin" :DIAGNOSTIC
    "Componenti vuote, assolute o di escape vietate."))
  (:CASE "duplicate" :EXPECTED-REASON :DUPLICATE-FILE :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/duplicate.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/duplicate.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :DUPLICATE-FILE :PATH "raw/data.bin" :DIAGNOSTIC
    "Path duplicato nell'indice."))
  (:CASE "symlink" :EXPECTED-REASON :NONREGULAR-PATH :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :NONREGULAR-PATH :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/symlink/raw/data.bin"
    :DIAGNOSTIC "Inventario con file speciale o symlink."))
  (:CASE "directory-symlink" :EXPECTED-REASON :NONREGULAR-PATH
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/directory-symlink.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/directory-symlink.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :NONREGULAR-PATH :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/directory-symlink/raw/"
    :DIAGNOSTIC "Inventario con file speciale o symlink."))
  (:CASE "process-command" :EXPECTED-REASON :PROCESS-METADATA
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-command.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-command.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :PROCESS-METADATA :PATH "processes/plain/report.lisp" :DIAGNOSTIC
    "Campo :COMMAND diverso dal record."))
  (:CASE "process-status" :EXPECTED-REASON :PROCESS-METADATA
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-status.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-status.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :PROCESS-METADATA :PATH "processes/plain/report.lisp" :DIAGNOSTIC
    "Campo :STATUS diverso dal record."))
  (:CASE "process-exit" :EXPECTED-REASON :PROCESS-METADATA :OBSERVED-EXIT-CODE
   1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-exit.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-exit.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :PROCESS-METADATA :PATH "processes/plain/report.lisp" :DIAGNOSTIC
    "Campo :EXIT-CODE diverso dal record."))
  (:CASE "process-source" :EXPECTED-REASON :PROCESS-METADATA
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-source.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-source.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :PROCESS-METADATA :PATH "processes/plain/report.lisp" :DIAGNOSTIC
    "Campo :SOURCE-CONSISTENCY diverso dal record."))
  (:CASE "process-duplicate" :EXPECTED-REASON :PROCESS-LABEL
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-duplicate.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/process-duplicate.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :PROCESS-LABEL :PATH "archive-index.lisp" :DIAGNOSTIC
    "Label mancante, invalido o duplicato."))
  (:CASE "catalogue-pending" :EXPECTED-REASON :CATALOGUE-SCHEMA
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-pending.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-pending.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :CATALOGUE-SCHEMA :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/catalogue-pending/catalogo.lisp"
    :DIAGNOSTIC
    "Catalogo schema1, kind evidence-catalog, pending NIL richiesto."))
  (:CASE "catalogue-entries" :EXPECTED-REASON :CATALOGUE-SCHEMA
   :OBSERVED-EXIT-CODE 1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-entries.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/catalogue-entries.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :CATALOGUE-SCHEMA :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/catalogue-entries/catalogo.lisp"
    :DIAGNOSTIC "Una entry richiesta."))
  (:CASE "index-schema" :EXPECTED-REASON :INDEX-SCHEMA :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-schema.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-schema.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :INDEX-SCHEMA :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-schema/archive-index.lisp"
    :DIAGNOSTIC "Indice schema1 original-command-archive richiesto."))
  (:CASE "plain-budget" :EXPECTED-REASON :FILE-BUDGET :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/plain-budget.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/plain-budget.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :FILE-BUDGET :PATH "unindexed.log" :DIAGNOSTIC
    "1048577 byte, limite 1048576."))
  (:CASE "gzip-budget" :EXPECTED-REASON :FILE-BUDGET :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :FILE-BUDGET :PATH "unindexed.gz" :DIAGNOSTIC
    "8388609 byte, limite 8388608."))
  (:CASE "index-read-eval" :EXPECTED-REASON :EVIDENCE-READ :OBSERVED-EXIT-CODE
   1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :EVIDENCE-READ :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-read-eval/archive-index.lisp"
    :DIAGNOSTIC
    "Evidenza non valida /Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-read-eval/archive-index.lisp: can't read #. while *READ-EVAL* is NIL

  Stream: #<SB-SYS:FD-STREAM for \"descriptor 6\" {8005966573}>"))
  (:CASE "index-trailing" :EXPECTED-REASON :EVIDENCE-READ :OBSERVED-EXIT-CODE 1
   :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-trailing.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-trailing.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :EVIDENCE-READ :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-trailing/archive-index.lisp"
    :DIAGNOSTIC
    "Evidenza non valida /Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-trailing/archive-index.lisp: Il file contiene più di una forma Lisp."))
  (:CASE "report-read-eval" :EXPECTED-REASON :EVIDENCE-READ :OBSERVED-EXIT-CODE
   1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-read-eval.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-read-eval.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :EVIDENCE-READ :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/report-read-eval/processes/plain/report.lisp"
    :DIAGNOSTIC
    "Evidenza non valida /Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/report-read-eval/processes/plain/report.lisp: can't read #. while *READ-EVAL* is NIL

  Stream: #<SB-SYS:FD-STREAM for \"descriptor 6\" {80059B6003}>"))
  (:CASE "report-trailing" :EXPECTED-REASON :EVIDENCE-READ :OBSERVED-EXIT-CODE
   1 :STATUS :OK :STDOUT
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-trailing.stdout.log"
   :STDERR
   "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/report-trailing.stderr.log"
   :REPORT
   (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
    :EVIDENCE-READ :PATH
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/report-trailing/processes/plain/report.lisp"
    :DIAGNOSTIC
    "Evidenza non valida /Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/report-trailing/processes/plain/report.lisp: Il file contiene più di una forma Lisp.")))
 :ROOT
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/"
 :ORIGINALS-OVERWRITTEN NIL :PRODUCT-CAMPAIGNS NIL :LIMITS
 (:LOCAL-FIXTURES :NO-GATE-OR-MCDC-CLAIM))
