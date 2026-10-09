(:schema-version 1 :formats nil :kind :audit-reader-output-addendum
 :recorded-at "2026-10-09" :reviewer "/root/development_next"
 :scope :audit-helper-only :status :documented-output-defect
 :audit "/tmp/cbor-structure-evidence-audit.lisp"
 :audit-md5 "fdc2421b1611dd158eae7ba2b5d5ad97"
 :reader "/tmp/cbor-structure-evidence-reader.lisp"
 :reader-md5 "37d12845de5d82d94ccbae1251dd6988"
 :log "/tmp/cbor-structure-evidence-reader-v2.log"
 :log-md5 "5a44bdf662e3ecbcd3bf59ed0d027800"
 :observation "The final console line prints byte-comparisons1. The generated audit safely reads as one schema1 datum and contains 43 bytewise-comparison records and 15 checks."
 :cause "NREVERSE transfers the complete reversed list into the report but leaves the global variable pointing to its final cons; the later console LENGTH therefore sees one record."
 :evidence-integrity-checks-affected nil
 :audit-or-code-rewritten nil :product-execution nil :rerun nil
 :limits (:console-count-not-authoritative :original-code-log-and-audit-retained))
