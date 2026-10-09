(:schema-version 1
 :kind :coverage-audit
 :status :local-agent-reading
 :recorded-at 4000509783
 :recorded-at-utc "2026-10-09 04:43:03 UTC"
 :reviewer "/root/development_next"
 :mode :read-only-evidence-audit
 :evidence-directory "spikes/out/writer-queue-20261009-a-coverage/"
 :evidence-files ("cover-index.html" "141e364c61efef2da8bf7f827a1fefa3.html" "dff2c92b20b16dea3693dfefae283a9f.html" "ef492e5df3b5ef763970d20c96c87f73.html" "coverage-state.lisp")
 :coverage-state-md5 "497624b359daac89d2c7162f64f2d12b"
 :decision-table (:file "docs/implementazione/code-writer-decisioni.md" :md5 "c139e9b76bef9bc36fc34a26197fec7c" :read-after-original-first-c1-reading t)
 :data-reading (:raw-evidence-read-as-text t :path-and-bit-vectors-parsed-as-data t :read-load-or-eval-on-evidence nil :requires-read-eval-nil-and-eof-guard-for-future-common-lisp-reader t)
 :totals (:covered-expressions 321 :all-expressions 391 :covered-branches 58 :all-branches 76 :uncovered-expressions 70 :uncovered-branches 18)
 :full-denominator-retained t
 :files (
   (:file "src/execution/package.lisp"
    :covered-expressions 0 :all-expressions 1
    :covered-branches 0 :all-branches 0
    :classifications (
       (:category :declarative-unmarked :uncovered-expressions 1 :uncovered-branches 0 :source-lines (3 4 5 6 7 8 9) :finding "DEFPACKAGE: una forma raw non marcata, nessun ramo."))
    :uncovered-expression-paths (
       (:raw-index 0 :source-path (0) :top-level-form 0))
    :uncovered-branch-paths (
))
   (:file "src/execution/queue.lisp"
    :covered-expressions 131 :all-expressions 172
    :covered-branches 22 :all-branches 32
    :classifications (
       (:category :declarative-or-generated-unmarked :uncovered-expressions 21 :uncovered-branches 2 :source-lines (4 5 8 9 14 15 16 17 18 19 20 23 38 50 61 62 74) :finding "In-package/optimize, due costanti, dieci forme di slot, cinque ftype, due defaultargs factory. I due rami appartengono al tipo OR della guard nel DEFSTRUCT e nessuno e marcato.")
       (:category :defensive-ring-bounds :uncovered-expressions 4 :uncovered-branches 4 :source-lines (29 30 31 32) :finding "False nei bounds del ring/AND complessivo; corpo ERROR con quattro espressioni raw non marcate.")
       (:category :defensive-ring-relation :uncovered-expressions 4 :uncovered-branches 1 :source-lines (33 34) :finding "Relazione tail=(head+count) mod capacity mai falsa.")
       (:category :defensive-guard-acquisition-postcondition :uncovered-expressions 4 :uncovered-branches 1 :source-lines (45 46) :finding "Guard diversa dal thread dopo CAS riuscito mai osservata.")
       (:category :defensive-guard-release-owner :uncovered-expressions 4 :uncovered-branches 1 :source-lines (54 55) :finding "Proprietario guard inatteso prima del CAS mai osservato.")
       (:category :defensive-guard-release-cas :uncovered-expressions 4 :uncovered-branches 1 :source-lines (56 57) :finding "Valore precedente del CAS release inatteso mai osservato."))
    :uncovered-expression-paths (
       (:raw-index 0 :source-path (0) :top-level-form 0)
       (:raw-index 1 :source-path (1) :top-level-form 1)
       (:raw-index 2 :source-path (2) :top-level-form 2)
       (:raw-index 3 :source-path (3) :top-level-form 3)
       (:raw-index 5 :source-path (3 4) :top-level-form 4)
       (:raw-index 6 :source-path (4 4) :top-level-form 4)
       (:raw-index 7 :source-path (5 4) :top-level-form 4)
       (:raw-index 8 :source-path (6 4) :top-level-form 4)
       (:raw-index 9 :source-path (7 4) :top-level-form 4)
       (:raw-index 10 :source-path (8 4) :top-level-form 4)
       (:raw-index 11 :source-path (9 4) :top-level-form 4)
       (:raw-index 12 :source-path (10 4) :top-level-form 4)
       (:raw-index 13 :source-path (11 4) :top-level-form 4)
       (:raw-index 14 :source-path (12 4) :top-level-form 4)
       (:raw-index 17 :source-path (5) :top-level-form 5)
       (:raw-index 47 :source-path (2 2 4 6) :top-level-form 6)
       (:raw-index 48 :source-path (1 2 2 4 6) :top-level-form 6)
       (:raw-index 49 :source-path (2 2 2 4 6) :top-level-form 6)
       (:raw-index 50 :source-path (3 2 2 4 6) :top-level-form 6)
       (:raw-index 60 :source-path (2 3 4 6) :top-level-form 6)
       (:raw-index 61 :source-path (1 2 3 4 6) :top-level-form 6)
       (:raw-index 62 :source-path (2 2 3 4 6) :top-level-form 6)
       (:raw-index 63 :source-path (3 2 3 4 6) :top-level-form 6)
       (:raw-index 69 :source-path (7) :top-level-form 7)
       (:raw-index 89 :source-path (2 3 4 8) :top-level-form 8)
       (:raw-index 90 :source-path (1 2 3 4 8) :top-level-form 8)
       (:raw-index 91 :source-path (2 2 3 4 8) :top-level-form 8)
       (:raw-index 92 :source-path (3 2 3 4 8) :top-level-form 8)
       (:raw-index 95 :source-path (9) :top-level-form 9)
       (:raw-index 103 :source-path (2 4 10) :top-level-form 10)
       (:raw-index 104 :source-path (1 2 4 10) :top-level-form 10)
       (:raw-index 105 :source-path (2 2 4 10) :top-level-form 10)
       (:raw-index 106 :source-path (3 2 4 10) :top-level-form 10)
       (:raw-index 113 :source-path (2 5 10) :top-level-form 10)
       (:raw-index 114 :source-path (1 2 5 10) :top-level-form 10)
       (:raw-index 115 :source-path (2 2 5 10) :top-level-form 10)
       (:raw-index 116 :source-path (3 2 5 10) :top-level-form 10)
       (:raw-index 118 :source-path (11) :top-level-form 11)
       (:raw-index 165 :source-path (1 2 12) :top-level-form 12)
       (:raw-index 166 :source-path (2 2 12) :top-level-form 12)
       (:raw-index 167 :source-path (13) :top-level-form 13))
    :uncovered-branch-paths (
       (:raw-index 15 :source-path (:THEN 3 9 4) :top-level-form 4)
       (:raw-index 16 :source-path (:ELSE 3 9 4) :top-level-form 4)
       (:raw-index 39 :source-path (:ELSE 3 1 2 4 6) :top-level-form 6)
       (:raw-index 40 :source-path (:ELSE 2 1 2 4 6) :top-level-form 6)
       (:raw-index 41 :source-path (:ELSE 1 1 2 4 6) :top-level-form 6)
       (:raw-index 46 :source-path (:ELSE 1 2 4 6) :top-level-form 6)
       (:raw-index 59 :source-path (:ELSE 1 3 4 6) :top-level-form 6)
       (:raw-index 88 :source-path (:ELSE 1 3 4 8) :top-level-form 8)
       (:raw-index 102 :source-path (:ELSE 1 4 10) :top-level-form 10)
       (:raw-index 112 :source-path (:ELSE 1 5 10) :top-level-form 10)))
   (:file "src/execution/writer.lisp"
    :covered-expressions 190 :all-expressions 218
    :covered-branches 36 :all-branches 44
    :classifications (
       (:category :declarative-unmarked :uncovered-expressions 8 :uncovered-branches 0 :source-lines (4 5 8 22 33 54 55 66 67 103) :finding "In-package/optimize e sei ftype; non vengono esclusi dal denominatore.")
       (:category :defensive-lease-quota :uncovered-expressions 4 :uncovered-branches 2 :source-lines (16 17 18) :finding "Quantum fuori 1..65536 o extracted sopra quantum: falsi dei controlli interni non osservati. Quota operativa normale/esatta/esaurita e stata invece marcata.")
       (:category :defensive-owner-release-precondition :uncovered-expressions 4 :uncovered-branches 1 :source-lines (26 27) :finding "Owner non uguale al thread del cleanup mai osservato.")
       (:category :defensive-owner-release-cas :uncovered-expressions 4 :uncovered-branches 1 :source-lines (28 29) :finding "CAS release con valore precedente inatteso mai osservato.")
       (:category :defensive-acquisition-owner-and-extracted :uncovered-expressions 4 :uncovered-branches 2 :source-lines (43 44 45) :finding "Owner diverso dal thread dopo CAS o extracted non zero prima della nuova lease: falsi non osservati.")
       (:category :defensive-extraction-quota-postcondition :uncovered-expressions 4 :uncovered-branches 2 :source-lines (96 97 98) :finding "Taken sopra remaining o extracted sopra quantum dopo drain: falsi non osservati."))
    :uncovered-expression-paths (
       (:raw-index 0 :source-path (0) :top-level-form 0)
       (:raw-index 1 :source-path (1) :top-level-form 1)
       (:raw-index 2 :source-path (2) :top-level-form 2)
       (:raw-index 39 :source-path (2 5 3) :top-level-form 3)
       (:raw-index 40 :source-path (1 2 5 3) :top-level-form 3)
       (:raw-index 41 :source-path (2 2 5 3) :top-level-form 3)
       (:raw-index 42 :source-path (3 2 5 3) :top-level-form 3)
       (:raw-index 44 :source-path (4) :top-level-form 4)
       (:raw-index 52 :source-path (2 4 5) :top-level-form 5)
       (:raw-index 53 :source-path (1 2 4 5) :top-level-form 5)
       (:raw-index 54 :source-path (2 2 4 5) :top-level-form 5)
       (:raw-index 55 :source-path (3 2 4 5) :top-level-form 5)
       (:raw-index 62 :source-path (2 5 5) :top-level-form 5)
       (:raw-index 63 :source-path (1 2 5 5) :top-level-form 5)
       (:raw-index 64 :source-path (2 2 5 5) :top-level-form 5)
       (:raw-index 65 :source-path (3 2 5 5) :top-level-form 5)
       (:raw-index 67 :source-path (6) :top-level-form 6)
       (:raw-index 98 :source-path (2 1 1 3 4 7) :top-level-form 7)
       (:raw-index 99 :source-path (1 2 1 1 3 4 7) :top-level-form 7)
       (:raw-index 100 :source-path (2 2 1 1 3 4 7) :top-level-form 7)
       (:raw-index 101 :source-path (3 2 1 1 3 4 7) :top-level-form 7)
       (:raw-index 117 :source-path (8) :top-level-form 8)
       (:raw-index 165 :source-path (10) :top-level-form 10)
       (:raw-index 223 :source-path (2 6 2 1 2 4 3 5 11) :top-level-form 11)
       (:raw-index 224 :source-path (1 2 6 2 1 2 4 3 5 11) :top-level-form 11)
       (:raw-index 225 :source-path (2 2 6 2 1 2 4 3 5 11) :top-level-form 11)
       (:raw-index 226 :source-path (3 2 6 2 1 2 4 3 5 11) :top-level-form 11)
       (:raw-index 252 :source-path (12) :top-level-form 12))
    :uncovered-branch-paths (
       (:raw-index 36 :source-path (:ELSE 1 1 5 3) :top-level-form 3)
       (:raw-index 38 :source-path (:ELSE 1 5 3) :top-level-form 3)
       (:raw-index 51 :source-path (:ELSE 1 4 5) :top-level-form 5)
       (:raw-index 61 :source-path (:ELSE 1 5 5) :top-level-form 5)
       (:raw-index 95 :source-path (:ELSE 1 1 1 1 3 4 7) :top-level-form 7)
       (:raw-index 97 :source-path (:ELSE 1 1 1 3 4 7) :top-level-form 7)
       (:raw-index 220 :source-path (:ELSE 1 1 6 2 1 2 4 3 5 11) :top-level-form 11)
       (:raw-index 222 :source-path (:ELSE 1 6 2 1 2 4 3 5 11) :top-level-form 11))))
 :operational-input-branches-uncovered-in-this-instrumentation nil
 :unmarked-default-arguments (:file "src/execution/queue.lisp" :line 62 :defaults (1024 64) :independent-test "test-REQ-AFF-008-writer-defaults-and-configuration-boundaries" :test-source "tests/execution/queue.lisp" :test-line 12 :finding "Il test chiama la factory senza keyword, verifica pieno a 1024 e primo tratto di 64. I due defaultargs restano non marcati raw; nessuna correzione del denominatore.")
 :decision-table-audit (:functional-decisions-enumerated t :defensive-false-paths-open t :type-or-and-generated-default-scaffolding-described-by-this-audit t :complete-mc-dc nil :waiver nil)
 :limits (:raw-states-not-exclusion-proof :defensive-false-paths-still-uncovered :quota-checks-retained-in-denominator :no-complete-condition-coverage :no-human-approval :no-new-test-benchmark-or-product-execution :no-repository-edits)
 :related-first-reading "/tmp/writer-queue-review-1.lisp")
