(:schema-version 1 :kind :audit-utility-attempts
 :reader "spikes/out/cbor-minimal-scan-data-reader.lisp"
 :source-blob-before-runtime "2c4303b16d415171bb52efbc555cba1789d9a21d"
 :attempts
 ((:kind :source-syntax-read :attempt 1 :exit-code 1
   :original-source "spikes/out/cbor-minimal-scan-data-reader-attempt-1.lisp"
   :stdout "spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-1.stdout.log"
   :stderr "spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-1.stderr.log"
   :cause :syntax-reader-setup-omitted-sb-md5-require
   :correction :preload-sb-md5-in-syntax-reader
   :helper-source-changed nil :product-loaded nil :data-audit-executed nil)
  (:kind :source-syntax-read :attempt 2 :exit-code 0
   :original-source "spikes/out/cbor-minimal-scan-data-reader-attempt-1.lisp"
   :stdout "spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-2.stdout.log"
   :stderr "spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-2.stderr.log"
   :read-eval nil :helper-source-evaluated nil :product-loaded nil))
 :runtime-attempts
 ((:attempt 1 :status :failed :exit-code 1 :checks 239 :findings 1
   :original-source "spikes/out/cbor-minimal-scan-data-reader-attempt-1.lisp"
   :source-blob "2c4303b16d415171bb52efbc555cba1789d9a21d"
   :record "spikes/out/4000552876-command-80674-0/report.lisp"
   :audit "spikes/out/cbor-minimal-scan-data-audit-attempt-1.lisp"
   :stdout "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-1.stdout.log"
   :stderr "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-1.stderr.log"
   :cause :mutation-stdout-has-selftest-text-before-single-plist
   :correction :check-expected-text-prelude-before-safe-plist-read
   :product-campaign-rerun nil)
  (:attempt 2 :status :failed :exit-code 1 :checks 1895 :actual-plist-findings 2
   :original-source "spikes/out/cbor-minimal-scan-data-reader-attempt-2.lisp"
   :source-blob "81050a81d05e17bf241546f6c18b4ccaac0c4241"
   :record "spikes/out/4000552959-command-83078-0/report.lisp"
   :audit "spikes/out/cbor-minimal-scan-data-audit-attempt-2.lisp"
   :stdout "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-2.stdout.log"
   :stderr "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-2.stderr.log"
   :cause :html-parser-assumed-explicit-tr-closing-tag
   :correction :next-tr-also-terminates-unclosed-html-row
   :summary-print-finding-count 1
   :summary-count-cause :nreverse-left-original-list-variable-at-final-cons
   :summary-count-correction :assign-nreverse-result-before-report-and-print
   :product-campaign-rerun nil)
  (:attempt 3 :status :ok :exit-code 0 :checks 1895 :findings 0
   :original-source "spikes/out/cbor-minimal-scan-data-reader-attempt-3.lisp"
   :source-blob "c7e4a329c22f084c8681258eac63824f582a6ba3"
   :record "spikes/out/4000553029-command-85919-0/report.lisp"
   :audit "spikes/out/cbor-minimal-scan-data-audit-attempt-3.lisp"
   :stdout "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-3.stdout.log"
   :stderr "spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-3.stderr.log"
   :product-campaign-rerun nil))
 :bytewise-supplement
 (:status :ok :exit-code 0 :original-bytes 1113055
  :code "spikes/out/cbor-minimal-scan-data-summary-reader.lisp"
  :record "spikes/out/4000553094-command-89492-0/report.lisp"
  :audit "spikes/out/cbor-minimal-scan-data-bytewise-supplement.lisp"
  :stdout "spikes/out/cbor-minimal-scan-data-summary.stdout.log"
  :stderr "spikes/out/cbor-minimal-scan-data-summary.stderr.log"
  :expanded-sha-and-bytes-equal-original t :product-campaign-rerun nil)
 :limits (:original-stdout-and-stderr-preserved t :source-syntax-not-runtime-check t
          :utility-setup-error-not-product-failure t))
