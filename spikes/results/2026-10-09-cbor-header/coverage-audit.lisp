(:schema-version 1
 :kind :cbor-header-coverage-audit
 :recorded-at "2026-10-09 07:53:06 UTC"
 :workspace "/Users/gpicchiarelli/.codex/worktrees/cbor-header/ArcDocDB"
 :status :consistent-with-raw-report
 :readonly t
 :campaigns-run-by-reviewer nil
 :reader-read-eval nil
 :reader-eof-checked t
 :data-loaded-or-evaluated nil
 :statement-source
 (:counter-kind :sb-cover-expression-and-branch-outcome
  :index "spikes/out/cbor-coverage/cover-index.html"
  :saved-state "spikes/out/cbor-coverage/coverage-state.lisp"
  :saved-state-files 77
  :report-scope-files 2
  :scope ("src/codec/cbor-header.lisp" "src/codec/cbor-package.lisp")
  :scope-note "The saved state includes other ASDF source/test files. Counts here are only the two CBOR product files in the report index, not all 77 files."
  :source-attribution "Unobserved saved-state paths were partitioned by top-level source form and matched against both complete HTML reports and the frozen source. SB-COVER expression forms are not physical source-line counts."
  :header-html "spikes/out/cbor-coverage/9367fddeba1b4bcdc06fcacd4d6d6e9a.html"
  :package-html "spikes/out/cbor-coverage/eb9954b0ed3d3abd4c466cb5fc10d63f.html")
 :wrapper
 (:path "spikes/out/4000520588-command-87907-0/report.lisp"
  :status :ok :exit-code 0 :source-consistency :stable
  :source-blobs-before 363 :source-blobs-after 363
  :source-blob-lists-identical t
  :five-frozen-product-test-blobs-match-before-after-and-current t
  :runtime (:cbor-tests-passed 17
            :fuzz (:seed "8949A11F" :samples 4096 :accepted 3437 :rejected 659)
            :threads (:headers 2097152 :bytes 18874368
                      :sinks (2401919800705024 2231683637051392)
                      :overlap-ticks 128068 :ticks-per-second 1000000)))
 :coverage-self-test-wrapper
 (:path "spikes/out/4000520545-command-86639-0/report.lisp"
  :status :ok :exit-code 0 :source-consistency :stable
  :stdout "Copertura: self-test del ramo mancante superato.")
 :preliminary-check-wrapper
 (:path "spikes/out/4000520545-command-86637-0/report.lisp"
  :status :ok :exit-code 0 :source-consistency :stable
  :source-blobs-before 363 :source-blobs-after 363
  :source-blob-lists-identical t
  :five-frozen-product-test-blobs-match-before-and-after t)
 :source-files
 ((:path "src/codec/cbor-package.lisp" :git-blob "d5f72309f3eca0a719507d257a635e5dd680013a")
  (:path "src/codec/cbor-header.lisp" :git-blob "db635a50678f2712ec9516be335717ea254d4d09")
  (:path "tests/codec/cbor-support.lisp" :git-blob "172c4a335b2d504f785b2036532346a24ccf1378")
  (:path "tests/codec/cbor-header.lisp" :git-blob "a1541916590304adccc2092c226ef3be9c644168")
  (:path "tests/codec/cbor-threads.lisp" :git-blob "720d80c6dd5a962dc724835c1421635ba289b7ef"))
 :per-file
 ((:path "src/codec/cbor-header.lisp" :expressions-covered 222 :expressions-total 264
   :expressions-unobserved 42 :branch-outcomes-covered 32 :branch-outcomes-total 40
   :branch-outcomes-unobserved 8 :saved-state-paths 304 :saved-state-observed 254)
  (:path "src/codec/cbor-package.lisp" :expressions-covered 0 :expressions-total 1
   :expressions-unobserved 1 :branch-outcomes-covered 0 :branch-outcomes-total 0
   :branch-outcomes-unobserved 0 :saved-state-paths 1 :saved-state-observed 0))
 :totals
 (:expressions-covered 222 :expressions-total 265 :expressions-unobserved 43
  :branch-outcomes-covered 32 :branch-outcomes-total 40 :branch-outcomes-unobserved 8
  :saved-state-paths 305 :saved-state-observed 254 :saved-state-unobserved 51)
 :per-function
 ((:name "check-header-cbor-range" :top-level-form 3 :expressions-covered 30
   :expressions-total 30 :branch-outcomes-covered 8 :branch-outcomes-total 8)
  (:name "leggi-argomento-header-cbor" :top-level-form 5 :expressions-covered 64
   :expressions-total 76 :branch-outcomes-covered 7 :branch-outcomes-total 10)
  (:name "leggi-indefinito-header-cbor" :top-level-form 7 :expressions-covered 37
   :expressions-total 55 :branch-outcomes-covered 3 :branch-outcomes-total 6)
  (:name "leggi-header-cbor" :top-level-form 9 :expressions-covered 91
   :expressions-total 97 :branch-outcomes-covered 14 :branch-outcomes-total 16))
 :unobserved-partition
 (:declarative-forms 7 :internal-error-forms 36 :internal-error-sites 6
  :unobserved-branch-outcomes 8 :unclassified-forms 0 :unclassified-branch-outcomes 0
  :public-input-test-gap-observed nil)
 :declarative-inventory
 ((:path "src/codec/cbor-package.lisp" :line 3 :form :defpackage
   :top-level-form 0 :unobserved-expressions 1)
  (:path "src/codec/cbor-header.lisp" :lines (4 5 8 22 46 66)
   :forms (:in-package :optimize-declaim :ftype-declaim :ftype-declaim :ftype-declaim :ftype-declaim)
   :top-level-forms (0 1 2 4 6 8) :unobserved-expressions 6))
 :internal-error-inventory
 ((:reason :cbor-argument-range :line 30 :function "leggi-argomento-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 1
   :error-source-path (2 4 5)
   :explanation "Public preflight and lead consumption establish start<=end<=length before the private helper.")
  (:reason :cbor-argument-progress :line 42 :function "leggi-argomento-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 2
   :error-source-path (2 4 6 5)
   :explanation "Positive width and the complete-width fit guard establish start<next<=end.")
  (:reason :cbor-indefinite-range :line 56 :function "leggi-indefinito-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 2
   :error-source-path (2 4 7)
   :explanation "The private marker helper follows successful public preflight and a present lead.")
  (:reason :cbor-indefinite-context :line 58 :function "leggi-indefinito-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 1
   :error-source-path (2 5 7)
   :explanation "The only public call to the helper is in the AI=31 branch.")
  (:reason :cbor-major :line 63 :function "leggi-indefinito-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 0
   :error-source-path (1 5 6 7)
   :explanation "CASE clauses cover all values of the declared unsigned-byte3 major type. HTML marks the error unexecuted; no separate missing branch outcome is present for this site in the raw counters.")
  (:reason :cbor-header-progress :line 98 :function "leggi-header-cbor"
   :unobserved-expressions 6 :unobserved-branch-outcomes 2
   :error-source-path (2 4 3 5 3 4 9)
   :explanation "Immediate heads consume one byte; argument heads have already passed positive-width and fit checks." ))
 :benchmark-read-scope
 (:path "spikes/out/4000520577-command-87617-0/report.lisp"
  :wrapper-status :ok :exit-code 0 :source-consistency :stable
  :source-blobs-before 363 :source-blobs-after 363 :source-blob-lists-identical t
  :structured-stdout-read-with-read-eval-nil-and-eof t
  :cells 9 :samples 45 :iterations-per-sample 4096 :warmup-iterations 128
  :heap-bytes-per-sample 0
  :baseline-heap-bytes 0 :positive-control-heap-bytes 16777472
  :six-values-return-token-audit :root-verified
  :note "Root completed the benchmark audit. This review read the wrapper and structured stdout; no benchmark was rerun and no broader performance claim is added.")
 :limits
 (:denominator-unchanged t :approved-exclusions nil :mcdc-qualified nil
  :human-exception-approved nil :engine-release-gate-closed nil
  :note "All 265 expression forms and 40 branch outcomes remain in the denominator. Unobserved declarations and private guards are explanations, not approved exclusions."
  :scope "Local CBOR header grammar only; no full document/profile, payload, tag semantics, text, depth100, document budget, worker FAULTED controller or pool scaling claim."))
