(:schema-version 1 :formats nil :kind :cbor-minimal-independent-c1-review
 :status :no-open-static-product-defects :classification :c1
 :recorded-at "2026-10-09 14:57:26 UTC"
 :statement-source "development_next: seconda lettura statica dopo freeze del corpus blind"
 :reviewer "/root/development_next" :mode :static-reading
 :new-product-author-p nil :prior-header-and-structure-author-p t
 :test-oracle-author-p t :human-approval nil
 :worktree "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB"
 :source-files
 ((:path "src/codec/cbor-package.lisp" :git-blob "0d014e499f0862f13674bd934070c166c286f256" :md5 "ca3e8cd7b4bfc17811114f7e1dadebe3")
  (:path "src/codec/cbor-float-minimal.lisp" :git-blob "ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f" :md5 "bc7a7b176e8cdd361b7c4306a1a4de4b")
  (:path "src/codec/cbor-minimal.lisp" :git-blob "761302dad1073c841397f6c88d595b114af8d9ef" :md5 "ecd8fe950344059c629927b38fb6e4aa"))
 :requirements ("REQ-LIM-002" "REQ-AFF-004" "REQ-AFF-008")
 :invariants ("INV-A4" "INV-A8" "INV-P6")
 :adrs ("ADR-0014" "ADR-0048" "ADR-0033" "ADR-0034")
 :checks
 ((:number 1 :status :static-coherent :finding "Requisiti e contratto locale coerenti; LIM-002 parziale, profilo completo separato.")
  (:number 2 :status :invariants-and-tests-present :finding "Campi, larghezze, allineamento, progresso; guardie interne incluse, runtime pendente.")
  (:number 3 :status :typed-and-ordered :finding "Sintassi prima di nonminimal al lead; invarianti tipizzati; nessun owner Serie o transizione FAULTED.")
  (:number 4 :status :bounded :finding "Nove byte nella base, lavoro costante nel filtro; nessun nuovo ciclo, ricorsione o attesa.")
  (:number 5 :status :measurement-pending :finding "Nessun costruttore o u64/float materializzato; shift fino32 immediato su64bit; sensore/heap da acquisire.")
  (:number 6 :status :local-output-checked :finding "Esattamente sei valori dopo sintassi e minimo; nessun payload decodificato o semantica tag.")
  (:number 7 :status :inventory-present :finding "Dieci decisioni D01-D10 corrispondono; D03/D06 supplemento dichiarato, nessuna attestazione MC/DC.")
  (:number 8 :status :caller-owned-read-only :finding "Solo buffer immutabile e locali, nessun scratch o globale mutabile.")
  (:number 9 :status :integration-present-check-pending :finding "Export e ordine ASDF presenti; build, trace e make check dello snapshot pendenti.")
  (:number 10 :status :no-static-deviation-found :finding "Sei funzioni FTYPE/docstring/safety3/due guardie, dimensioni e complessita limitate; lint/build pendenti.")
  (:number 11 :status :no-per-operation-sharing :finding "Nessun lock/attesa/scrittura tra Serie; prova due worker pendente, tempo reale non prova core o scaling.")
  (:number 12 :status :not-applicable :finding "Nessun cambiamento durevole, delete o pubblicazione."))
 :decisions (:count 10 :ids (:d01 :d02 :d03 :d04 :d05 :d06 :d07 :d08 :d09 :d10)
             :table "docs/implementazione/cbor-minimo-decisioni.md" :source-correspondence t
             :raw-coverage-pending t :mcdc-claimed nil)
 :blind-corpus
 (:frozen-before-new-product-reading t :test-count 14
  :files ((:path "tests/codec/cbor-minimal-support.lisp" :git-blob "774e6cd0bec4a9d2242ad4dede878ffa2afca90c" :md5 "4d7ec43e187859da277b8fb5f66f8e73")
          (:path "tests/codec/cbor-minimal.lisp" :git-blob "b863ace9a22e8b7508b7c9d8f91465ebfbcd4e98" :md5 "2311a15f8d4af90bf341e91e0e64342b")
          (:path "tests/codec/cbor-minimal-threads.lisp" :git-blob "e613ea025c2a886cdae7fd5e119cf80593c6b72e" :md5 "9a6a26ae45747211bb795bc323b13770"))
  :half-patterns 65536 :exact-expansions 131072 :truncated-prefixes 152
  :fuzz (:seed #x4d494e43 :lcg-multiplier 1664525 :lcg-increment 1013904223 :modulus 4294967296
         :binary32-words 4096 :binary64-words 4096 :spans 4096 :span-bytes (0 9))
  :threads (:workers 2 :private-buffers t :units 1024 :repetitions 256 :wait-seconds 15 :join-seconds 20))
 :supplement
 (:added-after-new-product-reading t :coordinator-authorized t :original-three-blobs-unchanged t
  :path "tests/codec/cbor-minimal-edges.lisp" :git-blob "c6f891dff335a37689ddbfabccf793d2e9f2f143"
  :md5 "392d402b44d04a9ce1c95fef4c4e8bf9" :test-count 1 :public-calls 26
  :test "TEST-REQ-AFF-004-CBOR-MINIMAL-PUBLIC-SUBNORMAL-ALIGNMENT-PAIRS"
  :scope (:d03-shift32-33-52-high-low-pairs :d06-high-only-subnormal)
  :oracle :general-integer-and-rational-ieee :new-product-helpers-used nil)
 :tests-total 15
 :pending (:strict-build :lint :trace :full-check :raw-coverage :mutation-campaign :heap-measurement :thread-runtime)
 :limits (:static-review-not-runtime-result :not-complete-document-profile :not-semantic-tag-validation
          :no-mcdc-claim :no-runtime-or-release-qualification :no-human-approval
          :no-product-execution-by-reviewer :supplement-not-part-of-original-blind-corpus))
