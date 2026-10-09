(:schema-version 1 :kind :cbor-structure-c4-driver-review :status :no-open-static-defects
 :statement-source "root: lettura statica indipendente dei driver benchmark e mutation"
 :recorded-at "2026-10-09 09:58 UTC" :product-author nil :driver-author nil :campaigns-run-before-reading nil
 :sources ((:path "tools/cbor-structure-bench.lisp" :git-blob "a0a676c0107dee9429f27d3fdcdc78bb3d7f2957")
           (:path "tools/cbor-structure-mutation.lisp" :git-blob "dd6e9fb1f3655b78eb64285bee0de35474e12eba"))
 :checks (:six-independent-fixtures :all-three-values-in-sink :five-times32-warmup128
          :gc-and-setup-outside-measurement :positive-heap-control :strict-markers :baseline-complete
          :compiler-failure-invalid :zero-exit-incomplete-invalid :exclusive-copies :ten-unique-anchors)
 :review-document "docs/implementazione/cbor-struttura-driver-review.md"
 :limits (:static-only :runtime-campaigns-pending :not-exhaustive-mutation-proof :not-human-approval))
