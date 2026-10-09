(:schema 1
 :kind :utility-attempt-failure
 :subject :cbor-structure-coverage-audit-data-writing
 :recorded-at "2026-10-09 10:15:17 UTC"
 :statement-source :reviewer-transcription-of-truncated-tool-result
 :attempt-status :failed
 :invocation "sbcl --noinform --disable-debugger --script /tmp/cbor-structure-coverage-audit-builder.lisp"
 :exit-code :not-captured
 :original-full-output-captured nil
 :tool-result-truncated t
 :reported-original-token-count 2553
 :reported-total-output-lines 64
 :tool-output-budget-tokens 2000
 :log "/tmp/cbor-structure-coverage-audit-builder-first-transcription.txt"
 :log-provenance :selected-visible-excerpts-nonoriginal-transcription
 :omitted-text-reconstructed nil
 :first-code "/tmp/cbor-structure-coverage-audit-builder-first-reconstructed.lisp"
 :first-code-provenance :reconstructed-by-reversing-eight-recorded-quote-corrections
 :first-code-preserved-original-byte-claim nil
 :observed-errors (:compiler-illegal-function-call :undefined-keyword-functions
                   :runtime-undefined-function-scan-stack)
 :cause :eight-literal-data-lists-without-quote
 :correction :quote-eight-literal-data-lists
 :final-code "/tmp/cbor-structure-coverage-audit-builder.lisp"
 :final-attempt-status :successful-data-write-and-safe-readback
 :final-audit "/tmp/cbor-structure-coverage-audit.lisp"
 :input-policy (:read-eval nil :single-form-and-eof-checked t :load-or-eval-of-reports nil)
 :scope (:temporary-data-writing-only t :product-executed nil :campaign-rerun nil
         :repository-edited nil :source-or-frozen-test-edited nil)
 :failure-attributed-to-product nil)
