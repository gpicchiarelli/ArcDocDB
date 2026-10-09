(:schema-version 1 :kind :cbor-mutation-process-method :date "2026-10-09"
 :registered-before-execution t :scope :verification-tools-only
 :base-commit "aa5994a81102ccc8bf28a19c4ebc0a93a392c5c5"
 :tools ("tools/cbor-header-mutation.lisp" "tools/cbor-structure-mutation.lisp")
 :catalog-sizes (:header 9 :structure 10)
 :classification-priority (:os-signal :nonzero-after-exact-completion
                           :compilation-invalid :missing-marker-invalid
                           :completed-zero-survived :runtime-before-completion-detected)
 :planned-commands (("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-header-mutation.lisp" "--self-test")
                    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-structure-mutation.lisp" "--self-test")
                    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-header-mutation.lisp" "--run" "spikes/out/cbor-header-signals/")
                    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-structure-mutation.lisp" "--run" "spikes/out/cbor-structure-signals/")
                    ("make" "check-core")
                    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-header-mutation.lisp" "--invalid")
                    ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                     "tools/cbor-structure-mutation.lisp" "--invalid"))
 :negative-command-expectation (:failed :exit-code-nonzero :file-and-cod61-diagnostic)
 :real-fixtures (:smoke-then-self-sigkill :smoke-completion-then-exit-seven)
 :parallelism (:independent-worktree-and-output-directories :serial-within-catalog)
 :preservation (:raw-command-records :reports :generated-runners :raw-logs
                :fixtures-from-self-test-and-campaign :native-compressed-payloads)
 :limits (:no-product-change :no-benchmark-repeat :no-coverage-repeat
          :historical-evidence-unchanged :no-c1-or-mcdc-promotion))
