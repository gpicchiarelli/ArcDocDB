(:schema-version 1 :kind :collector-attempt-audit :formats NIL
 :status :ok :statement-source "root: lettura del risultato tool, prima raccolta dati"
 :first-attempt (:classification :invalid :reported-guard-status :ok :guards 10
   :exit-code 0 :diagnostic-source :tool-return-transcribed
   :diagnostic "caught ERROR: illegal function call in COLLECT-COVERAGE, unquoted :scope list"
   :unexercised-function :collect-coverage :record "/tmp/cbor-header-collector-self-test.lisp"
   :code "/tmp/collect-cbor-header-evidence-first-attempt.lisp")
 :repair (:scope-list-quoted T :load-warnings-fatal T :coverage-guard-added T)
 :accepted-attempt (:guards 11 :record "/tmp/cbor-header-collector-self-test-v2.lisp"
                    :status :ok :compiler-diagnostic-observed NIL)
 :limits (:first-guard-pass-not-accepted :diagnostic-is-transcription-not-byte-captured-stderr
          :collector-only :no-product-campaign))
