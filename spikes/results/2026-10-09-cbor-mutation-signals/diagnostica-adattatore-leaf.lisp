(:schema-version 1 :kind :publication-diagnostic :scope :local-metadata-adapter
 :status :failed :exit-code 1 :source :local-tool-call-transcript
 :command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
           "/tmp/cbor-leaf-publication-adapter.lisp")
 :cause :rename-file-relative-target-resolved-against-source-directory
 :observed-diagnostic "RENAME-FILE attempted commands/0/spikes/results/2026-10-09-cbor-mutation-signals/command-0.lisp; No such file or directory."
 :moves-completed 0 :native-bytes :unchanged
 :already-preserved ("catalogo-annidato.lisp.txt" "riepilogo-annidato.lisp.txt")
 :preliminary-source "adattatore-leaf-preliminare-source.lisp.txt"
 :correction :absolute-truename-base
 :limits (:local-adapter-failure :no-product-or-test-run :no-result-promotion
          :original-tool-call-output-not-reconstructed))
