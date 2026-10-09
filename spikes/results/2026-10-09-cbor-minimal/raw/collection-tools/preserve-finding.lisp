(require :asdf)
(let* ((path "spikes/out/cbor-minimal-collection/collect.lisp")
       (before "'(\"lisp\" \"log\" \"gz\")") (after "'(\"lisp\" \"log\")")
       (source (uiop:read-file-string path :external-format :utf-8))
       (position (search before source))
       (target "spikes/out/cbor-minimal-collector-before-fix-reconstructed.lisp"))
  (unless (and position (not (search before source :start2 (1+ position))))
    (error "Bersaglio della ricostruzione assente o ambiguo."))
  (with-open-file (stream target :direction :output :if-exists :error :external-format :utf-8)
    (write-string (concatenate 'string (subseq source 0 position) after
                              (subseq source (+ position (length before)))) stream))
  (let ((blob (string-trim '(#\Newline #\Return)
                           (uiop:run-program (list "git" "hash-object" "--" target) :output :string))))
    (unless (string= blob "4ec1aa3c993f0236caa44bd0ef30867ac37c73b7")
      (error "Snapshot ricostruito diverso dal blob letto dal revisore: ~A." blob))
    (with-open-file (stream "spikes/out/cbor-minimal-finding-provenance.lisp"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t))
        (write (list :schema-version 1 :kind :static-finding-source-preservation
                     :status :matches-reviewer-original-blob
                     :source-policy :reconstructed-after-fix-not-original-file-capture
                     :derived-from path :reconstructed-path target :git-blob blob
                     :derivation (list :unique-replacement before after)
                     :finding :filtered-tree-descriptor-payload-omitted
                     :product-defect nil :campaign-executed-before-fix nil)
               :stream stream :pretty t)
        (terpri stream)))
    (format t "Sorgente del finding ricostruita, blob verificato: ~A.~%" blob)))
