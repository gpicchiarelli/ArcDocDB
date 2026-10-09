(:schema-version 1
 :formats nil
 :kind :coverage-audit
 :status :local-agent-reading
 :recorded-at 4000513251
 :reviewer "/root/development_next"
 :mode :readonly-raw-state-and-html
 :human-approval nil
 :campaigns-run nil
 :evidence-read-eval nil
 :evidence-eof-guard t
 :raw-directory "/Users/gpicchiarelli/.codex/worktrees/utf8-validation/ArcDocDB/spikes/out/utf8-20261009-a-coverage/"
 :coverage-wrapper
 (:file "spikes/out/4000512999-command-23965-0/report.lisp"
  :schema-version 1 :status :ok :exit-code 0 :source-consistency :stable)
 :self-test-wrapper
 (:file "spikes/out/4000512998-command-23932-0/report.lisp"
  :schema-version 1 :status :ok :exit-code 0 :source-consistency :stable)
 :source-fingerprints
 ((:file "src/codec/package.lisp" :md5 "d885bd2a9860eb60aec1a775e5031d5e")
  (:file "src/codec/utf8.lisp" :md5 "0f67dd5c51bf6a63bc292ab4e2a280c2"))
 :raw-files
 ((:file "cover-index.html" :md5 "c6649ef18eb061aafd1dbbd1d97bfed7")
  (:file "coverage-state.lisp" :md5 "8cbe24084dfc7410b5598adc4324cf83")
  (:file "883d324a5a48a0a827cb90b144235348.html" :md5 "16b6aa0479e823550c5fd160b5db62ba")
  (:file "b75c3c29fddd8b2888a8026623a24a6d.html" :md5 "380eb67979102778361e23d7904ef7c5"))
 :decision-table
 (:file "docs/implementazione/utf8-decisioni.md" :md5 "c929472679be3c0930855eb1da7ae426")
 :totals
 (:expressions-covered 231 :expressions-total 301 :expressions-unmarked 70
  :branches-covered 49 :branches-total 60 :branches-unmarked 11
  :excluded-expressions 0 :excluded-branches 0)
 :files
 ((:file "src/codec/package.lisp" :expressions-covered 0 :expressions-total 1
   :branches-covered 0 :branches-total 0
   :unmarked-expressions ((0)) :unmarked-branches nil)
  (:file "src/codec/utf8.lisp" :expressions-covered 231 :expressions-total 300
   :branches-covered 49 :branches-total 60
   :unmarked-expressions
   ((0) (1) (2) (3) (5) (2 4 6) (1 2 4 6) (2 2 4 6) (3 2 4 6)
    (4 2 4 6) (5 2 4 6) (2 5 6) (1 2 5 6) (2 2 5 6) (3 2 5 6)
    (4 2 5 6) (5 2 5 6) (7) (2 4 8) (1 2 4 8) (2 2 4 8)
    (3 2 4 8) (4 2 4 8) (5 2 4 8) (2 5 8) (1 2 5 8)
    (2 2 5 8) (3 2 5 8) (4 2 5 8) (5 2 5 8) (9)
    (2 4 10) (1 2 4 10) (2 2 4 10) (3 2 4 10) (4 2 4 10)
    (5 2 4 10) (2 5 10) (1 2 5 10) (2 2 5 10) (3 2 5 10)
    (4 2 5 10) (5 2 5 10) (2 4 6 10) (1 2 4 6 10)
    (2 2 4 6 10) (3 2 4 6 10) (4 2 4 6 10) (5 2 4 6 10)
    (11) (2 7 3 3 4 12) (1 2 7 3 3 4 12) (2 2 7 3 3 4 12)
    (3 2 7 3 3 4 12) (4 2 7 3 3 4 12) (5 2 7 3 3 4 12)
    (2 4 3 4 12) (1 2 4 3 4 12) (2 2 4 3 4 12)
    (3 2 4 3 4 12) (4 2 4 3 4 12) (5 2 4 3 4 12)
    (2 5 3 4 12) (1 2 5 3 4 12) (2 2 5 3 4 12)
    (3 2 5 3 4 12) (4 2 5 3 4 12) (5 2 5 3 4 12) (4 2 12))
   :unmarked-branches
   ((:else 1 4 6) (:else 1 5 6) (:else 1 4 8) (:else 1 5 8)
    (:else 1 4 10) (:else 1 5 10) (:else 1 1 4 6 10)
    (:else 1 4 6 10) (:else 1 7 3 3 4 12)
    (:else 1 4 3 4 12) (:else 1 5 3 4 12))))
 :unmarked-inventory
 (:declarative
  (:expressions 9 :branches 0
   :observation "Defpackage1; UTF8 in-package, optimize, constant e cinque FTYPE8. Tutti inclusi nel denominatore."
   :utf8-lines (4 5 8 11 28 49 66 92))
  :parameter-default
  (:expressions 1 :branches 0 :line 94 :raw-path (4 2 12)
   :observation "Nodo sintattico (max-bytes +max-utf8-bytes+) non marcato. Il comportamento default e esercitato: utf8-accept usa APPLY con options NIL e il test16MiB omette la keyword. Questo non cambia il numeratore grezzo."
   :test-evidence "tests/codec/support.lisp:50; tests/codec/utf8.lisp:20-27 e213-220, letti solo dopo freeze.")
  :defensive-errors
  (:expressions 60 :branches 11 :error-calls 10
   :groups
   ((:function "verifica-suite-utf8" :error-lines (35 37)
     :expressions 12 :branches 2 :guards "cursor<end; end<=length")
    (:function "verifica-scalare-utf8" :error-lines (55 57)
     :expressions 12 :branches 2 :guards "lead di3/4byte; second gia continuazione")
    (:function "verifica-carattere-utf8" :error-lines (73 75 88)
     :expressions 18 :branches 4 :guards "cursor<end; end<=length; AND di progresso con due rami non marcati")
    (:function "verifica-utf8" :error-lines (110 112 114)
     :expressions 18 :branches 3 :guards "count<=byteconsumati; fine esatta; count<=span"))))
 :decision-table-comparison
 (:range-and :both-outcomes-marked
  :budget-and :both-outcomes-marked
  :progress-and :two-defensive-outcomes-unmarked
  :other-operational-or-public-input-branch-unmarked nil
  :observation "Range/budget e rifiuti di lead, width, continuation e scalar risultano marcati. Il progresso AND resta solo sul ramo coerente del contratto interno. La tabella lo dichiara esplicitamente, senza escluderlo o proclamare MC/DC completa.")
 :checks
 (:raw-state-equals-index-and-html t
  :html-source-equals-current-source t
  :source-line-counts (:package 8 :utf8 115)
  :whole-denominator-retained t)
 :coverage-process-observations
 (:codec-tests 17 :stderr-empty t
  :two-byte-inputs 65536 :two-byte-valid 18304 :two-byte-rejected 47232
  :fuzz-inputs 4096 :fuzz-valid 234 :fuzz-rejected 3862
  :parallel-workers 2 :parallel-bytes 83886080 :sink-per-worker 16777216
  :instrumented-overlap-ticks 1606013 :timer-units-per-second 1000000
  :observation "Solo valori letti dal wrapper della copertura; overlap strumentato non e tempo del primo build ne benchmark o scaling.")
 :limits
 (:source-author-audit :no-human-approval :no-new-product-execution
  :no-campaign-rerun :no-exclusion :no-waiver :no-complete-mcdc-claim
  :defensive-error-edges-unexercised :future-faulted-controller-not-tested
  :md5-for-consistency-not-authenticity :not-a-full-cbor-or-engine-gate))
