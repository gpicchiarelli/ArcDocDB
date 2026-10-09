(require :asdf)
(let* ((files '("src/codec/cbor-package.lisp" "src/codec/cbor-float-minimal.lisp"
                "src/codec/cbor-minimal.lisp" "tests/codec/cbor-minimal-support.lisp"
                "tests/codec/cbor-minimal.lisp" "tests/codec/cbor-minimal-threads.lisp"
                "tools/cbor-minimal-bench.lisp" "tools/cbor-minimal-mutation.lisp"))
       (blobs (uiop:split-string
               (string-trim '(#\Newline #\Return)
                            (uiop:run-program (append '("git" "hash-object" "--") files)
                                              :output :string)) :separator '(#\Newline)))
       (record (list :schema-version 1 :kind :cbor-minimal-static-reading
                     :reader-role :contract-asdf-and-campaign-coordinator
                     :kernel-author :other-agent :driver-author :other-agent
                     :status :no-open-static-findings
                     :recorded-at (get-universal-time)
                     :source-blobs (loop for file in files for blob in blobs
                                         collect (list :path file :git-blob blob))
                     :c1-checklist-document "docs/implementazione/cbor-minimo-lettura.md"
                     :c4-checklist-document "docs/implementazione/cbor-minimo-driver-review.md"
                     :compound-decisions 10
                     :float32-exponent-ranges '(:normal (113 142) :subnormal (103 112))
                     :float64-exponent-ranges '(:normal (897 1150) :subnormal (874 896))
                     :syntax-error-priority :before-nonminimal
                     :runtime-tests :pending :heap-measurements :pending
                     :limits '(:static-reading-only :no-mcdc-or-release-approval))))
  (unless (= (length files) (length blobs)) (error "Snapshot incomplet des sources."))
  (with-open-file (stream "spikes/out/cbor-minimal-root-review.lisp" :direction :output
                          :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write record :stream stream :pretty t) (terpri stream)))
  (format t "Lecture statique: ~D fichiers, 10 décisions, aucun constat ouvert.~%" (length files)))
