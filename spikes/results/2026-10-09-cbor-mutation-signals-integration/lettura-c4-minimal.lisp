(:schema-version 1 :kind :c4-review :scope :cbor-minimal-mutation-tool
 :source :parent-agent-messages :parent :root
 :readings ((:reviewer :root :role :first-static-reading)
            (:reviewer :decisions-mutations :role :independent-second-static-reading))
 :tool (:file "tools/cbor-minimal-mutation.lisp"
        :git-blob "a9a94354a24bd3dc6bfe3a1511adbeb1d52c88d6")
 :related-unchanged-tools
 ((:file "tools/cbor-header-mutation.lisp" :git-blob "a47d36577af8e249c045096a5f7270cd628f0df8")
  (:file "tools/cbor-structure-mutation.lisp" :git-blob "e43405f5a6825f420364f112de951013d36b85ca"))
 :reported-outcome :no-static-blocker :reported-findings nil
 :catalog-and-cli (:minimal-mutants 8 :helper-prefix :unchanged)
 :runtime-evidence-source :separate-command-and-fixture-records
 :limits (:parent-delivered-static-review-outcome :not-a-new-reading-by-collector
          :not-c1-or-mcdc-or-engine-qualification))
