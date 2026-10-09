(:SCHEMA-VERSION 1 :KIND :WRITER-WORKER-FINAL-INTEGRATION-SUMMARY :STATUS
 :PASSED :INTEGRATION-HEAD "e07d77271758f3134b1977caf394fe38532b54ed"
 :HISTORICAL-INTEGRATED-HEAD "e2f7a75f3c7a45dffd91343b91d3a889fc3ee056"
 :WORKER-BASELINE "cf6091367853ec311fed7b05961a2812fd05a8f1" :CHECK-PATH
 #A((49) BASE-CHAR . "spikes/out/4000550386-command-90070-0/report.lisp")
 :CHECK-SHA256
 "575d62253b6387a4bb9572465aafbfe4e800d018a69b0cc62c9e5f4450955d28"
 :CHECK-COMMAND
 (#A((3) BASE-CHAR . "env")
  #A((148) BASE-CHAR
     . "XDG_CACHE_HOME=/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-cache")
  #A((35) BASE-CHAR . "SBCL=sbcl --dynamic-space-size 4096")
  #A((4) BASE-CHAR . "make") #A((10) BASE-CHAR . "check-core"))
 :SOURCE-CONSISTENCY :STABLE :TEST-SUM 415 :SUITE-COUNT 11 :TEST-MODULES
 ((:COUNT 28 :RAW-LINE "28 test delle fondazioni superati.")
  (:COUNT 17 :RAW-LINE "17 test UTF-8 superati.")
  (:COUNT 17 :RAW-LINE "17 test degli header CBOR superati.")
  (:COUNT 15 :RAW-LINE "15 test delle testate CBOR minime superati.")
  (:COUNT 24 :RAW-LINE "24 test della struttura CBOR superati.")
  (:COUNT 20 :RAW-LINE "20 test del registro CSN superati.")
  (:COUNT 89 :RAW-LINE "89 test delle code writer superati.")
  (:COUNT 44 :RAW-LINE "44 test dei metadati storage superati.")
  (:COUNT 18 :RAW-LINE "18 test I/O superati.")
  (:COUNT 95 :RAW-LINE "95 test recovery superati.")
  (:COUNT 48 :RAW-LINE "48 test WAL superati."))
 :SMOKE :PASSED :COMPILE :NO-WARNINGS :LINT-RAW "68 file, 0 violazioni"
 :LINT-NUMBERS (68 0) :LINKS-RAW "232 file, 2044 link controllati, 0 rotti"
 :LINKS-NUMBERS (232 2044 0) :TRACE-RAW
 "114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori" :TRACE-NUMBERS
 (114 65 13 52 0) :SPIKES-PATH
 #A((146) BASE-CHAR
    . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/report.lisp")
 :SPIKES-SHA256
 "a64a85cb6bdcb4d5af095fc2a0906861f33a423ca7998f101b2671e6e803b923" :SPIKES-RAW
 "10 spike completati; risultati: /private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/"
 :SPIKES
 ((:ID "SPK-01" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-02" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-03" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-04" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-05" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-06" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-07" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-08" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-09" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID "SPK-10" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE))
 :LIMITS
 (:READONLY-PROJECTION :ONE-FINAL-MAKE-CHECK-CORE :PRIVATE-XDG-CACHE
  :SBCL-DYNAMIC-SPACE-4096-MIB
  :NO-REPEAT-OF-WORKER-MUTATION-BENCHMARK-OR-COVERAGE))
