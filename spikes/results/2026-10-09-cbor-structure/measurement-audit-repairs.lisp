(:schema-version 1 :kind :cbor-structure-measurement-audit-reader-repairs :status :ok
 :formats nil :product-or-campaign-reruns nil :repository-edits nil
 :first-attempt
 (:status :failed :phase :trusted-audit-reader-load
  :diagnostic "Simbolo UIOP:READ-FILE-BYTE-VECTOR non disponibile; nessun dato prodotto eseguito."
  :reader-source "/tmp/cbor-structure-measurement-audit-reader-v1-unavailable-uiop.lisp"
  :log "/tmp/cbor-structure-measurement-audit-reader-v1.log"
  :log-provenance :tool-returned-output-transcribed-verbatim
  :raw-log-file-created-at-attempt nil :report-created-at-attempt nil)
 :second-attempt
 (:status :failed :phase :current-wrapper-global-comparison
  :diagnostic "Confronto globale current includeva documentazione modificata legittimamente dopo campagne."
  :report "/tmp/cbor-structure-measurement-audit-v1-global-current-assumption.lisp"
  :log "/tmp/cbor-structure-measurement-audit-reader-v2-failed.log"
  :log-provenance :tool-returned-output-transcribed-verbatim
  :raw-log-file-created-at-attempt nil)
 :final-attempt
 (:status :ok :report "/tmp/cbor-structure-measurement-audit.lisp"
  :reader-source "/tmp/cbor-structure-measurement-audit-reader.lisp"
  :scope-current (:src :tests :tools :asdf)
  :wrapper-before-after-global-stability-checked t
  :post-campaign-nonfocus-changes-listed t
  :repair :explicit-byte-vector-reader-and-separate-current-document-scope))
