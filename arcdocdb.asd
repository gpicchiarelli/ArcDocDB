;;;; arcdocdb.asd — definizione di sistema ASDF.
;;;;
;;;; Fase 0 (definizione architetturale): il sistema contiene solo il package radice.
;;;; La suddivisione in package per modulo (M01…M18, vedi docs/16-moduli.md) si introduce
;;;; con la prima milestone di implementazione.

(defsystem "arcdocdb"
  :description "Database server documentale general-purpose, append-only, in Common Lisp (SBCL)."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :version "0.0.0"
  :pathname "src/"
  :serial t
  :components ((:file "package"))
  :in-order-to ((test-op (test-op "arcdocdb/tests"))))

(defsystem "arcdocdb/tests"
  :description "Test di ArcDocDB."
  :author "Giacomo Picchiarelli"
  :license "BSD-2-Clause"
  :depends-on ("arcdocdb")
  :pathname "tests/"
  :serial t
  :components ((:file "smoke"))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)))
