;;;; arcdocdb.asd — definizione di sistema ASDF.
;;;;
;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.

(in-package #:asdf-user)

(defsystem "arcdocdb"
  :description "Database server documentale general-purpose, append-only, in Common Lisp (SBCL)."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :version "0.0.0"
  :pathname "src/"
  :serial t
  :depends-on ("sb-posix")
  :components ((:file "package")
               (:module "foundation"
                :serial t
                :components ((:file "package") (:file "conditions")
                             (:file "binary") (:file "crc32c")
                             (:file "record") (:file "batch")))
               (:module "codec" :serial t
                :components ((:file "package") (:file "utf8")
                             (:file "cbor-package") (:file "cbor-header")
                             (:file "cbor-float-minimal") (:file "cbor-minimal")
                             (:file "cbor-space") (:file "cbor-scan-input")
                             (:file "cbor-scan-stack") (:file "cbor-scan-items")
                             (:file "cbor-scan")))
               (:module "csn" :serial t
                :components ((:file "package") (:file "registry")))
               (:module "execution" :serial t
                :components ((:file "package") (:file "queue") (:file "writer")
                             (:file "handoff") (:file "ready-types") (:file "ready")
                             (:file "ready-recycle")))
               (:module "storage"
                :serial t
                :components ((:file "package") (:file "formats") (:file "segment-header")
                             (:file "log-header") (:file "compaction-scan")
                             (:file "control-payload") (:file "payload-record")
                             (:file "payload-write")))
               (:module "io" :serial t
                :components ((:file "package") (:file "types") (:file "native")
                             (:file "lifecycle") (:file "transfer") (:file "flush")))
               (:module "wal" :serial t
                :components ((:file "package") (:file "types") (:file "builder")
                             (:file "group") (:file "executor") (:file "csn")))
               (:module "series" :serial t
                :components ((:file "package") (:file "types") (:file "ownership")
                             (:file "events") (:file "io-events") (:file "publication")
                             (:file "query") (:file "retirement")))
               (:module "index" :serial t
                :components ((:file "package") (:file "types") (:file "core")
                             (:file "validation") (:file "read") (:file "write") (:file "relocate")
                             (:file "primary-package") (:file "primary-types") (:file "primary-core")
                             (:file "primary-build") (:file "primary-probe") (:file "primary-read")
                             (:file "primary-write") (:file "primary-relocate")
                             (:file "primary-arena") (:file "primary-directory")))
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
               (:module "recovery"
                :serial t
                :components ((:file "package") (:file "scan")
                             (:file "decisions-package") (:file "decisions-types")
                             (:file "decisions-sort") (:file "decisions-radix") (:file "decisions-build")
                             (:file "decisions-query")
                             (:file "manifest-package") (:file "manifest-types")
                             (:file "manifest-decode") (:file "manifest-fold")
                             (:file "manifest-build") (:file "manifest-query")
                             (:file "inventory-types") (:file "inventory-build")
                             (:file "inventory-query"))))
  :in-order-to ((test-op (test-op "arcdocdb/tests"))))

(defsystem "arcdocdb/tests"
  :description "Test di ArcDocDB."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :depends-on ("arcdocdb")
  :pathname "tests/"
  :serial t
  :components ((:file "smoke")
               (:module "foundation"
                :serial t
                :components ((:file "support") (:file "binary")
                             (:file "record") (:file "batch")))
               (:module "codec" :serial t
                :components ((:file "support") (:file "utf8") (:file "threads")
                             (:file "cbor-support") (:file "cbor-header") (:file "cbor-threads")
                             (:file "cbor-minimal-support") (:file "cbor-minimal")
                             (:file "cbor-minimal-threads") (:file "cbor-minimal-edges")
                             (:file "cbor-structure-support") (:file "cbor-structure")
                             (:file "cbor-structure-threads")))
               (:module "csn" :serial t
                :components ((:file "support") (:file "registry") (:file "threads")))
               (:module "execution" :serial t
                :components ((:file "support") (:file "queue") (:file "threads")
                             (:file "handoff") (:file "ready") (:file "ready-recycle")))
               (:module "storage"
                :serial t
                :components ((:file "support") (:file "segment-header") (:file "log-header")
                             (:file "compaction-scan")
                             (:file "control-payload")))
               (:module "io" :serial t
                :components ((:file "support") (:file "transfer") (:file "native")))
               (:module "recovery"
                :serial t
                :components ((:file "support") (:file "scan") (:file "corruption")
                             (:file "decisions-support") (:file "decisions")
                             (:file "decisions-audit") (:file "decisions-radix") (:file "manifest-support")
                             (:file "manifest") (:file "manifest-audit")
                             (:file "inventory-support") (:file "inventory")))
               (:module "wal" :serial t
                :components ((:file "support") (:file "builder") (:file "group") (:file "fault")
                             (:file "native") (:file "csn") (:file "csn-threads")))
               (:module "series" :serial t
                :components ((:file "support") (:file "controller") (:file "boundaries") (:file "threads"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.minimal.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.series.tests '#:run)))
