(:schema-version 1 :kind :cbor-structure-c1-review :status :no-open-static-defects
 :statement-source "root: prima lettura indipendente del kernel, coordinatore del contratto e ASDF"
 :recorded-at "2026-10-09 09:56 UTC" :product-author nil :oracle-author nil
 :campaigns-run-by-reviewer-before-reading nil :human-approval nil
 :source-files (
  (:path "src/codec/cbor-package.lisp" :git-blob "411212b04f96be32516425aa2a7ac53aac5b921d")
  (:path "src/codec/cbor-space.lisp" :git-blob "a8330e50a77b52a6b9044ebbb48f62bb4b3222a3")
  (:path "src/codec/cbor-scan-input.lisp" :git-blob "57ffc48cc688a4de8ebec5cb14c1e69c4209704a")
  (:path "src/codec/cbor-scan-stack.lisp" :git-blob "c574e87af5e195ddf3f596a4ae527e69c7a3c6a6")
  (:path "src/codec/cbor-scan-items.lisp" :git-blob "70272936e323b3e0cb05173c9fb68cb2b614c355")
  (:path "src/codec/cbor-scan.lisp" :git-blob "1f89112b43a39d98cf25dc6dfb34e412428ba843")
  (:path "tests/codec/cbor-structure-support.lisp" :git-blob "e9cc8a08917903cab7b7f5617225884b7d89e6c4")
  (:path "tests/codec/cbor-structure.lisp" :git-blob "d2f1ee8e57c0d587c7c1a7274ed171c16fb4fb53")
  (:path "tests/codec/cbor-structure-threads.lisp" :git-blob "3624e1dde5f5a484a117f4c783d4e6b88027cc89"))
 :review-document "docs/implementazione/cbor-struttura-lettura.md"
 :checks (:preflight-before-reset :alias-rejection :single-child-charge-after-tags
          :map-parity :chunk-local-utf8 :container-only-depth :fixed-102-frame-stack
          :high-low-no-u64-assembly :span-progress-bound :exact-root-postconditions
          :exclusive-workspace-no-buffer-retention :two-independent-worker-inputs
          :ftype-safety3-typed-errors :twelve-c1-points)
 :limits (:static-reading-only :runtime-campaigns-pending :not-semantic-or-deterministic-profile
          :not-engine-release-qualification :not-human-approval))
