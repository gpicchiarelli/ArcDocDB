(:schema-version 1 :kind :inspection-diagnostic :scope :evidence-metadata
 :source :local-tool-call-transcript :status :reader-package-error
 :observed-exit-code 0 :tool-transcript-excerpt "Package UIOP does not exist."
 :cause :asdf-not-required-before-uiop-symbol-read
 :correction (:require-asdf-first :disable-debugger :read-only-inspection-repeated)
 :corrected-inspection-exit-code 0
 :limits (:excerpt-not-byte-artifact :no-product-or-test-execution
          :reader-failure-is-not-verification-success))
