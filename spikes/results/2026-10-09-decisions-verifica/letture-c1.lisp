(:DECISION-PREDICATE-DOCUMENT
 "docs/implementazione/decisioni-multiserie-decisioni.md"
 :COVERAGE-INVENTORY-DOCUMENT "docs/affidabilita/copertura-eccezioni.md"
 :FINAL-TEST-COUNT 25 :TEST-SOURCE-BLOBS
 ((:PATH "tests/recovery/decisions-support.lisp" :GIT-BLOB
   "f67450a9d681512a4b66efe1af1bfc82180e0058")
  (:PATH "tests/recovery/decisions.lisp" :GIT-BLOB
   "28d04d8738f077bf21ac22393a4014b518a6a0f2")
  (:PATH "tests/recovery/decisions-audit.lisp" :GIT-BLOB
   "1b79a76515d8b8c2e67c46700cd6968b40047d62"))
 :SCHEMA-VERSION 1 :KIND :AGENT-REVIEW :SCOPE
 ("src/recovery/decisions-package.lisp" "src/recovery/decisions-types.lisp"
  "src/recovery/decisions-sort.lisp" "src/recovery/decisions-build.lisp"
  "src/recovery/decisions-query.lisp")
 :SOURCE-BLOBS
 ((:PATH "src/recovery/decisions-package.lisp" :GIT-BLOB
   "878fd1afdcbf035a232166ef87066af4420e1aae")
  (:PATH "src/recovery/decisions-types.lisp" :GIT-BLOB
   "0dbb2b3bdfbf5447a5904ce0fa6e4a97337a6827")
  (:PATH "src/recovery/decisions-sort.lisp" :GIT-BLOB
   "b133ea00a3b8063e9e934a1b41f10cad024471ae")
  (:PATH "src/recovery/decisions-build.lisp" :GIT-BLOB
   "2ff69622cb63d36a900698d2f81f071c7a0dbce9")
  (:PATH "src/recovery/decisions-query.lisp" :GIT-BLOB
   "a6ce94b8be3c8c84043abfd6441599f9780b2c11"))
 :READINGS
 ((:REVIEWER "/root/segment_header_code" :ROLE :AUTHOR :RESULT
   :NO-FUNCTIONAL-FINDINGS :CHECKS
   (:REQUIREMENTS-AND-ADRS :FTYPES-AND-TYPES :BOUNDED-LOOPS
    :PREALLOCATION-BUDGETS :EXACT-CONSUMPTION :OWNED-COPIES :ALL-OR-ERROR
    :NO-IO-OR-SHARED-STATE))
  (:REVIEWER "/root/scan_audit" :ROLE :INDEPENDENT :RESULT :NO-PRODUCT-FINDINGS
   :CHECKS
   (:COMPLETE-SCAN-BEFORE-RESULT :DUPLICATE-SETS :PHYSICAL-FIRST-CONFLICT
    :SOURCE-OWNERSHIP :BOUNDED-SORT-AND-SEARCH :RAW-COVERAGE)
   :TOOL-FINDING :BACKTRACE-MARKER-COULD-MIMIC-TEST-START :TOOL-FINDING-STATUS
   :CORRECTED)
  (:REVIEWER "/root/review_changes" :ROLE :INDEPENDENT-TEST-REVIEW :RESULT
   :NO-BLOCKING-FINDINGS :CHECKS
   (:INDEPENDENT-FIXTURES :PRESENCE-VERSUS-CSN-ZERO
    :PRESUMED-ABORT-AFTER-SUCCESS :SCANNER-WITNESS-RULES
    :MUTANT-TEST-MAPPING)))
 :LIMITS (:AGENT-READINGS :NO-HUMAN-APPROVAL :NO-RELEASE-QUALIFICATION))
