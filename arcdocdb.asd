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
  :components ((:file "package")
               (:module "foundation"
                :serial t
                :components ((:file "package") (:file "conditions")
                             (:file "binary") (:file "crc32c")
                             (:file "record") (:file "batch"))))
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
                             (:file "record") (:file "batch"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)))
