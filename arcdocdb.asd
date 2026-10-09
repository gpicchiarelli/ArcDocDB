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
               (:module "execution" :serial t
                :components ((:file "package") (:file "queue") (:file "writer")))
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
                             (:file "group") (:file "executor")))
               (:module "mvcc" :serial t
                :components ((:file "package") (:file "types") (:file "horizon")
                             (:file "snapshots-types") (:file "snapshots-core")
                             (:file "snapshots-register") (:file "snapshots-lifecycle")
                             (:file "snapshots-read")))
               (:module "recovery"
                :serial t
                :components ((:file "package") (:file "scan")
                             (:file "decisions-package") (:file "decisions-types")
                             (:file "decisions-sort") (:file "decisions-radix") (:file "decisions-build")
                             (:file "decisions-query"))))
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
               (:module "execution" :serial t
                :components ((:file "support") (:file "queue") (:file "threads")))
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
                             (:file "decisions-audit") (:file "decisions-radix")))
               (:module "wal" :serial t
                :components ((:file "support") (:file "builder") (:file "group") (:file "fault")
                             (:file "native"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
