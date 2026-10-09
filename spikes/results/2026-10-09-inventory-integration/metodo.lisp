(:schema-version 1 :kind :integration-method :date "2026-10-09"
 :scope :inventory-with-wal-csn-cbor-structure-and-writer-recycle
 :prior-inventory "ef98f494871e21522e7fd609a75c5f93077b4a32"
 :main-integrated "cf6091367853ec311fed7b05961a2812fd05a8f1"
 :integration-head "aa5994a81102ccc8bf28a19c4ebc0a93a392c5c5"
 :registration :before-recorded-execution
 :planned ((:command ("make" "check-core"))
           (:command ("sbcl" "--script" "tools/foundation-mutation.lisp" "--self-test"))
           (:command ("sbcl" "--script" "tools/foundation-mutation.lisp" "--run"
                      "spikes/out/inventory-integrated-mutations/" "inventory" "--jobs" "4")))
 :limits (:inventory-sources-and-tests-unchanged :no-benchmark-repetition
          :no-inventory-coverage-repetition :prior-denominators-and-gates-preserved
          :command-records-include-actual-argv-environment-and-source-hashes))
