;;;; arcdocdb.asd — definizione di sistema ASDF.
;;;;
;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.

(in-package #:asdf-user)

;; Il bootstrap non interroga l'OS e non richiede contrib opzionali.
(dolist (file '("src/io/cpu-package.lisp" "src/io/cpu-build.lisp"))
  (load (merge-pathnames file *load-truename*) :verbose nil :print nil))

(defsystem "arcdocdb"
  :description "Database server documentale general-purpose, append-only, in Common Lisp (SBCL)."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :version "0.0.0"
  :pathname "src/"
  :serial t
  :depends-on ("sb-posix" #+arcdocdb-crc32c-arm64 "sb-simd")
  :components ((:file "package")
               (:module "io-cpu" :pathname "io/" :serial t
                :components ((:file "cpu-package") (:file "cpu-build") (:file "cpu-features")))
               (:module "foundation"
                :serial t
                :components ((:file "package") (:file "conditions")
                             (:file "binary") (:file "crc32c")
                             (:file "crc32c-vops" :if-feature :arcdocdb-crc32c-arm64)
                             (:file "crc32c-native" :if-feature :arcdocdb-crc32c-arm64)
                             (:file "record") (:file "batch")))
               (:module "hash" :serial t
                :components ((:file "package") (:file "arithmetic") (:file "blocks") (:file "hash64")))
               (:module "codec" :serial t
                :components ((:file "package") (:file "utf8")
                             (:file "cbor-package") (:file "cbor-header")
                             (:file "cbor-float-minimal") (:file "cbor-minimal")
                             (:file "cbor-space") (:file "cbor-scan-input")
                             (:file "cbor-scan-stack") (:file "cbor-scan-items")
                             (:file "cbor-scan") (:file "cbor-scan-minimal")
                             (:file "cbor-write") (:file "cbor-string-write")
                             (:file "cbor-simple-write")
                             (:file "cbor-float-narrow") (:file "cbor-float-write")
                             (:file "cbor-array-input") (:file "cbor-array-write")
                             (:file "cbor-map-input") (:file "cbor-map-write")
                             (:file "cbor-tag-input") (:file "cbor-tag-write")
                             (:file "cbor-item-read") (:file "cbor-string-read")))
               (:module "fulltext" :serial t
                :components ((:file "format-package") (:file "format-constants")
                             (:file "format-input") (:file "format-write") (:file "format-read")
                             (:file "analysis-package") (:file "unicode-tables")
                             (:file "analysis-space") (:file "analysis-properties")
                             (:file "analysis-nfc") (:file "analysis-word-context")
                             (:file "analysis-word-rules") (:file "analysis-emit")
                             (:file "analysis") (:file "index-package") (:file "index-build")
                             (:file "index-sort") (:file "index-step") (:file "index-lookup")
                             (:file "codec-package") (:file "meta-read") (:file "meta-fields")
                             (:file "descriptor") (:file "codec-space") (:file "codec-input")
                             (:file "codec-run") (:file "codec-plan") (:file "codec-write-entries")
                             (:file "codec-write") (:file "codec-read-base") (:file "codec-read-lengths")
                             (:file "codec-read-term") (:file "codec-read-postings") (:file "codec-read-dict")
                             (:file "codec-view") (:file "codec-query")
                             (:file "document-package") (:file "document-config-input") (:file "document-config")
                             (:file "document-space") (:file "document-start") (:file "document-paths")
                             (:file "document-scan") (:file "document-analysis") (:file "document-bound")
                             (:file "document")))
               (:module "csn" :serial t
                :components ((:file "package") (:file "registry")))
               (:module "cache" :serial t
                :components ((:file "package") (:file "types") (:file "build") (:file "core")
                             (:file "read") (:file "clock") (:file "write")))
               (:module "execution" :serial t
                :components ((:file "package") (:file "queue") (:file "writer")
                             (:file "handoff") (:file "ready-types") (:file "ready")
                             (:file "ready-recycle")
                             (:file "worker-types") (:file "worker-boundary") (:file "worker-claim") (:file "worker-run")))
               (:module "fulltext-admission" :serial t
                :components ((:file "package") (:file "types") (:file "build")
                             (:file "guards") (:file "rows") (:file "row-update")
                             (:file "preflight") (:file "reserve")
                             (:file "copy") (:file "lifecycle") (:file "query")))
               (:module "scheduler" :serial t
                :components ((:file "package") (:file "types") (:file "build")
                             (:file "read") (:file "policy") (:file "update")
                             (:file "lifecycle-types") (:file "lifecycle-read")
                             (:file "lifecycle-build") (:file "lifecycle-worker")
                             (:file "lifecycle-update") (:file "pool-claim")))
               (:module "storage"
                :serial t
                :components ((:file "package") (:file "formats") (:file "segment-header")
                             (:file "log-header") (:file "compaction-scan")
                             (:file "control-payload") (:file "payload-record")
                             (:file "payload-write")))
               (:module "io" :serial t
                :components ((:file "package") (:file "types") (:file "identity-types")
                             (:file "native") (:file "native-namespace") (:file "native-publish")
                             (:file "native-directory")
                             (:file "native-open-relative")
                             (:file "native-create-relative")
                             (:file "lifecycle") (:file "identity") (:file "directory")
                             (:file "rename") (:file "namespace") (:file "publish") (:file "open-relative")
                             (:file "create-relative")
                             (:file "transfer") (:file "flush")
                             (:file "stabilize-preflight") (:file "stabilize") (:file "directory-lock")))
               (:module "wal" :serial t
                :components ((:file "package") (:file "types") (:file "builder")
                             (:file "frame") (:file "group") (:file "executor") (:file "csn")))
               (:module "fulltext-put" :serial t
                :components ((:file "package") (:file "types") (:file "build")
                             (:file "start") (:file "prepare") (:file "reserve")
                             (:file "append") (:file "binding") (:file "physical-header")
                             (:file "physical") (:file "row-reference")))
               (:module "series" :serial t
                :components ((:file "package") (:file "types") (:file "ownership")
                             (:file "events") (:file "io-events") (:file "publication")
                             (:file "query") (:file "retirement")
                             (:file "worker-package") (:file "worker-types")
                             (:file "worker-boundary") (:file "worker-run")
                             (:file "routing-types") (:file "routing-build") (:file "routing-select")))
               (:module "dispatch" :serial t
                :components ((:file "package") (:file "types") (:file "build") (:file "claim")
                             (:file "recycle") (:file "begin") (:file "step") (:file "start")))
               (:module "index" :serial t
                :components ((:file "package") (:file "types") (:file "core")
                             (:file "validation") (:file "read") (:file "write") (:file "relocate")
                             (:file "primary-package") (:file "primary-types") (:file "primary-core")
                             (:file "primary-build") (:file "primary-probe") (:file "primary-read")
                             (:file "primary-write") (:file "primary-relocate") (:file "primary-restore")
                             (:file "primary-arena") (:file "primary-directory")
                             (:file "rebuild-scan") (:file "rebuild-budget")
                             (:file "rebuild-copy") (:file "rebuild")
                             (:file "hash-seed") (:file "hash-digests")
                             (:file "mode-package") (:file "mode-types") (:file "mode-policy")
                             (:file "page-package") (:file "page-constants") (:file "page-types")
                             (:file "page-validation") (:file "page-bucket") (:file "page-body")
                             (:file "page-write") (:file "page-read")))
               (:module "mvcc" :serial t
                :components ((:file "package") (:file "types")
                             (:file "snapshots-types") (:file "snapshots-core") (:file "snapshots-csn")
                             (:file "snapshots-register") (:file "snapshots-lifecycle")
                             (:file "snapshots-read")))
               (:module "epochs" :serial t
                :components ((:file "package") (:file "types") (:file "core")
                             (:file "read") (:file "retire") (:file "reclaim")))
               (:module "read" :serial t
                :components ((:file "package") (:file "types") (:file "core")
                             (:file "task")))
               (:module "get" :serial t
                :components ((:file "package") (:file "types") (:file "build")
                             (:file "lifecycle") (:file "lookup") (:file "target") (:file "segment")))
               (:module "recovery"
                :serial t
                :components ((:file "package") (:file "scan")
                             (:file "decisions-package") (:file "decisions-types")
                             (:file "decisions-sort") (:file "decisions-radix") (:file "decisions-build")
                             (:file "decisions-query")
                             (:file "manifest-package") (:file "manifest-types")
                             (:file "manifest-decode") (:file "manifest-fold")
                             (:file "manifest-build") (:file "manifest-query") (:file "manifest-transition")
                             (:file "inventory-types") (:file "inventory-build")
                             (:file "inventory-query") (:file "inventory-id")
                             (:file "inventory-directory") (:file "inventory-directory-id")
                             (:file "inventory-sources-types") (:file "inventory-sources-query")
                             (:file "inventory-sources-build") (:file "inventory-sources")))
               (:module "get-resolver" :serial t
                :components ((:file "package") (:file "types") (:file "scan") (:file "sort")
                             (:file "rows") (:file "build") (:file "read")
                             (:file "active-types") (:file "active-directory")
                             (:file "active-scan") (:file "active-build") (:file "active-init")
                             (:file "active-preflight") (:file "active-read")))
               (:module "get-directory" :serial t
                :components ((:file "package") (:file "types") (:file "build") (:file "read")
                             (:file "sources-types") (:file "sources-read")))
               (:module "active" :serial t
                :components ((:file "package") (:file "types") (:file "preflight")
                             (:file "prepare") (:file "source")))
               (:module "control" :serial t
                :components ((:file "package") (:file "types") (:file "dependency")
                             (:file "build") (:file "preflight") (:file "transfer") (:file "prepare")
                             (:file "publication") (:file "publication-read")
                             (:file "recovery-types") (:file "recovery-read") (:file "recovery-publication")))
               (:module "recovery-active" :serial t
                :components ((:file "package") (:file "types") (:file "read") (:file "csn") (:file "frames")
                             (:file "resolve") (:file "build") (:file "query")
                             (:file "closure") (:file "publication")))
               (:module "recovery-archive" :serial t
                :components ((:file "package") (:file "types") (:file "read")
                             (:file "build") (:file "query") (:file "active")))
               (:module "recovery-checkpoint" :serial t
                :components ((:file "package") (:file "preflight") (:file "order")
                             (:file "sections") (:file "build")))
               (:module "recovery-closed" :serial t
                :components ((:file "package") (:file "types") (:file "read") (:file "verify")
                             (:file "resolve") (:file "csn") (:file "build") (:file "publication")
                             (:file "csn-serie")))
               (:module "recovery-series" :serial t
                :components ((:file "package") (:file "types") (:file "entry")
                             (:file "preflight") (:file "read") (:file "build")
                             (:file "stabilize-preflight") (:file "stabilize")
                             (:file "stabilize-set-preflight") (:file "stabilize-set")))
               (:module "recovery-archive-csn" :serial t
                :components ((:file "package") (:file "types") (:file "series") (:file "preflight")
                             (:file "build") (:file "query")))
               (:module "recovery-bootstrap" :serial t
                :components ((:file "package") (:file "shape") (:file "preflight") (:file "build")
                             (:file "stabilize-shape") (:file "stabilize-preflight") (:file "stabilize")))
               (:module "recovery-selection" :serial t
                :components ((:file "package") (:file "types") (:file "key")
                             (:file "frame") (:file "select") (:file "read")
                             (:file "index-preflight") (:file "index")))
               (:module "recovery-replay" :serial t
                :components ((:file "package") (:file "read") (:file "resolve") (:file "visit")))
               (:module "runtime" :serial t
                :components ((:file "package") (:file "types") (:file "preflight")
                             (:file "query") (:file "build") (:file "active")
                             (:file "closed-preflight") (:file "closed-transfer") (:file "closed")))
               (:module "engine" :serial t
                :components ((:file "package") (:file "types") (:file "lifecycle") (:file "files")
                             (:file "config") (:file "initialize") (:file "recovery") (:file "preflight") (:file "index")
                             (:file "adopt") (:file "startup") (:file "write") (:file "read"))))
  :in-order-to ((test-op (test-op "arcdocdb/tests"))))

(defsystem "arcdocdb/local"
  :description "Profilo M1 di produzione: sessione Unix locale, client e dispatcher."
  :license "BSD-2-Clause"
  :depends-on ("arcdocdb")
  :pathname "src/local/"
  :serial t
  :components ((:file "package") (:file "wire") (:file "native") (:file "state")
               (:file "dispatch") (:file "server") (:file "client") (:file "cli")))

(defsystem "arcdocdb/tests"
  :description "Test di ArcDocDB."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :depends-on ("arcdocdb/local")
  :pathname "tests/"
  :serial t
  :around-compile "ARCDOCDB.CI.TESTS::CALL-WITH-REGISTRATION-AUDIT"
  :components ((:file "ci-catalog" :around-compile nil)
               (:file "smoke")
               (:module "hash" :serial t
                :components ((:file "support") (:file "hash64") (:file "guards") (:file "threads")))
               (:module "foundation"
                :serial t
                :components ((:file "support") (:file "binary")
                             (:file "record") (:file "batch")))
               (:module "fulltext" :serial t
                :components ((:file "format-support") (:file "format")
                             (:file "format-guards") (:file "format-threads")
                             (:file "analysis-support") (:file "analysis-conformance") (:file "analysis")
                             (:file "index") (:file "allocation-threads")
                             (:file "codec-support") (:file "codec")
                             (:file "codec-corruption") (:file "codec-guards")
                             (:file "codec-differential")
                             (:file "document-support") (:file "document") (:file "document-guards")
                             (:file "document-differential")
                             (:file "admission-support") (:file "admission")
                             (:file "admission-guards") (:file "admission-resources")
                             (:file "admission-lifecycle") (:file "admission-rows-support")
                             (:file "admission-rows") (:file "admission-concurrency")
                             (:file "put-support") (:file "put") (:file "put-guards")
                             (:file "put-lifecycle") (:file "put-concurrency")
                             (:file "put-physical-support") (:file "put-physical")
                             (:file "put-physical-guards") (:file "put-physical-native")
                             (:file "put-rows")
                             (:static-file "minimum-v2.hex")))
               (:module "codec" :serial t
                :components ((:file "support") (:file "utf8") (:file "threads")
                             (:file "cbor-support") (:file "cbor-header") (:file "cbor-threads")
                             (:file "cbor-minimal-support") (:file "cbor-minimal")
                             (:file "cbor-minimal-threads") (:file "cbor-minimal-edges")
                             (:file "cbor-structure-support") (:file "cbor-structure")
                             (:file "cbor-structure-threads")
                             (:file "cbor-minimal-scan-support") (:file "cbor-minimal-scan")
                             (:file "cbor-minimal-scan-threads")
                             (:file "cbor-write-support") (:file "cbor-write")
                             (:file "cbor-write-threads") (:file "cbor-write-roundtrip")
                             (:file "cbor-string-write-support") (:file "cbor-string-write")
                             (:file "cbor-string-write-threads")
                             (:file "cbor-simple-write-support") (:file "cbor-simple-write")
                             (:file "cbor-simple-write-threads")
                             (:file "cbor-float-write-support") (:file "cbor-float-write")
                             (:file "cbor-float-write-threads")
                             (:file "cbor-array-write-support") (:file "cbor-array-write")
                             (:file "cbor-array-write-threads")
                             (:file "cbor-map-write-support") (:file "cbor-map-write")
                             (:file "cbor-map-write-threads")
                             (:file "cbor-tag-write-support") (:file "cbor-tag-write")
                             (:file "cbor-tag-write-threads")
                             (:file "cbor-item-read-support") (:file "cbor-item-read")
                             (:file "cbor-item-read-threads")
                             (:file "cbor-string-read-support") (:file "cbor-string-read")
                             (:file "cbor-string-read-threads")))
               (:module "csn" :serial t
                :components ((:file "support") (:file "registry") (:file "threads")))
               (:module "mvcc" :serial t
                :components ((:file "support") (:file "lifecycle") (:file "capture")))
               (:module "epochs" :serial t
                :components ((:file "support") (:file "lifecycle") (:file "threads")))
               (:module "read" :serial t
                :components ((:file "support") (:file "lifecycle") (:file "threads")))
               (:module "get" :serial t
                :components ((:file "support") (:file "lifecycle") (:file "segment")))
               (:module "get-performance" :serial t
                :components ((:file "support") (:file "paths") (:file "guards") (:file "threads")))
               (:module "cache" :serial t
                :components ((:file "support") (:file "guards") (:file "threads")))
               (:module "get-directory" :serial t
                :components ((:file "support") (:file "construction") (:file "read") (:file "threads")
                             (:file "series-support") (:file "series-read")
                             (:file "lifetime-support") (:file "lifetime")))
               (:module "get-resolver" :serial t
                :components ((:file "support") (:file "sort") (:file "construction") (:file "read")))
               (:module "get-active" :serial t
                :components ((:file "support") (:file "construction") (:file "preflight")
                             (:file "directory") (:file "read")))
               (:module "execution" :serial t
                :components ((:file "support") (:file "queue") (:file "threads")
                             (:file "handoff") (:file "ready") (:file "ready-recycle") (:file "worker")))
               (:module "scheduler" :serial t
                :components ((:file "support") (:file "controller") (:file "lifecycle")
                             (:file "pool-claim") (:file "dispatch") (:file "pool-recycle")
                             (:file "pool-begin") (:file "pool-step")
                             (:file "pool-chain-support") (:file "pool-chain") (:file "pool-start")))
               (:module "storage"
                :serial t
                :components ((:file "support") (:file "segment-header") (:file "log-header")
                             (:file "compaction-scan")
                             (:file "control-payload")))
               (:module "io" :serial t
                :components ((:file "support") (:file "transfer") (:file "native")
                             (:file "rename") (:file "rename-native") (:file "flush-failure")
                             (:file "transfer-failure") (:file "open-relative-support")
                             (:file "open-relative") (:file "open-relative-native")
                             (:file "create-relative-support") (:file "create-relative")
                             (:file "create-relative-native") (:file "directory-lock")))
               (:module "control" :serial t
                :components ((:file "support") (:file "publication") (:file "native")
                             (:file "recovery-read") (:file "recovery-publication") (:file "recovery-guards")))
               (:module "recovery"
                :serial t
                :components ((:file "support") (:file "scan") (:file "corruption")
                             (:file "decisions-support") (:file "decisions")
                             (:file "decisions-audit") (:file "decisions-radix") (:file "manifest-support")
                             (:file "manifest") (:file "manifest-audit") (:file "manifest-transition")
                             (:file "inventory-support") (:file "inventory")
                             (:file "inventory-id")
                             (:file "inventory-directory-support") (:file "inventory-directory")
                             (:file "inventory-directory-native") (:file "inventory-directory-id")
                             (:file "inventory-sources-support") (:file "inventory-sources")
                             (:file "inventory-sources-native")))
               (:module "recovery-active" :serial t
                :components ((:file "support") (:file "read") (:file "semantics") (:file "publication")))
               (:module "recovery-archive" :serial t
                :components ((:file "support") (:file "read") (:file "query")
                             (:file "active") (:file "native") (:file "guards")))

               (:module "recovery-active-checkpoint" :serial t
                :components ((:file "support") (:file "semantics") (:file "guards")
                             (:file "publication")))
               (:module "recovery-closed" :serial t
                :components ((:file "support") (:file "read") (:file "semantics")
                                  (:file "csn") (:file "publication") (:file "guards")))
               (:module "recovery-archive-csn" :serial t
                :components ((:file "support") (:file "set") (:file "plan") (:file "native")
                             (:file "guards")))
               (:module "runtime" :serial t
                :components ((:file "support") (:file "bootstrap") (:file "threads")
                             (:file "native") (:file "guards") (:file "adoption")))
               (:module "wal" :serial t
                :components ((:file "support") (:file "builder") (:file "group") (:file "fault")
                             (:file "native") (:file "csn") (:file "csn-threads")))
               (:module "series" :serial t
                :components ((:file "support") (:file "controller") (:file "boundaries") (:file "threads")
                             (:file "worker-bridge") (:file "worker-routing") (:file "log-binding")))
               (:module "index" :serial t
                :components ((:file "slot-support") (:file "slots") (:file "slot-threads")
                             (:file "primary-support") (:file "primary") (:file "primary-threads")
                             (:file "rebuild") (:file "hash-digests")
                             (:file "mode-support") (:file "mode-policy")
                             (:file "page-support") (:file "page-fixtures")
                             (:file "page-tests") (:file "page-corruption") (:file "page-chains")))
               (:module "vertical" :serial t
                :components ((:file "support") (:file "scenarios") (:file "resume") (:file "processes")))
               (:module "engine" :serial t
                :components ((:file "support") (:file "lifecycle") (:file "processes")))
               (:module "local" :serial t
                :components ((:file "wire") (:file "native") (:file "server") (:file "processes"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.ci.tests '#:run)))
