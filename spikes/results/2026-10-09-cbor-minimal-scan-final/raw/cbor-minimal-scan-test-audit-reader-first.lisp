;;;; C4: sola lettura del record originale e del corpus congelato, nessun prodotto.
(require :asdf)
(load (merge-pathnames "../../tools/evidence-storage.lisp" *load-truename*))

(defparameter *audit-root*
  (truename (merge-pathnames "../../" *load-truename*)))
(defparameter *audit-helper* *load-truename*)
(defparameter *audit-checks* nil)
(defparameter *audit-frozen*
  '(("src/codec/cbor-package.lisp" "9c9edc4775c24188cd38e4620da77b8bad349344")
    ("src/codec/cbor-scan.lisp" "e3d7d77407046338d23e26eb0b8a2e8fdc3d699d")
    ("src/codec/cbor-scan-minimal.lisp" "f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6")
    ("tests/codec/cbor-minimal-scan-support.lisp" "c2af64af4e5f8b5f669819fd56a00f416b3aaf0d")
    ("tests/codec/cbor-minimal-scan.lisp" "1742189ff6845197ba76996c09c1097d59216fcb")
    ("tests/codec/cbor-minimal-scan-threads.lisp" "56318b1632a7a0ae11f2987cdf0d4bec68e465cb")))

(defun audit-check (name value observed)
  (unless value (error "Audit ~S non soddisfatto: ~S" name observed))
  (push (list :check name :status :ok :observed observed) *audit-checks*)
  observed)

(defun audit-required (data key)
  (let* ((missing (gensym)) (value (getf data key missing)))
    (when (eq value missing) (error "Campo assente ~S." key))
    value))

(defun audit-lines (text)
  (mapcar (lambda (line) (string-right-trim '(#\Return) line))
          (uiop:split-string text :separator '(#\Newline))))

(defun audit-prefix-p (prefix line)
  (and (<= (length prefix) (length line))
       (string= prefix line :end2 (length prefix))))

(defun audit-unique-line (prefix lines)
  (let ((found (remove-if-not (lambda (line) (audit-prefix-p prefix line)) lines)))
    (audit-check (list :unique-line prefix) (= 1 (length found)) found)
    (first found)))

(defun audit-numbers (line)
  (loop for token in (uiop:split-string line :separator " ,/;:")
        when (and (plusp (length token)) (every #'digit-char-p token))
          collect (parse-integer token)))

(defun audit-test-names ()
  (loop for relative in '("tests/codec/cbor-minimal-scan.lisp"
                          "tests/codec/cbor-minimal-scan-threads.lisp")
        append
        (with-open-file (stream (merge-pathnames relative *audit-root*))
          (loop for line = (read-line stream nil nil) while line
                when (audit-prefix-p "(deftest " line)
                  collect (let ((end (or (position #\Space line :start 9)
                                         (position #\) line :start 9) (length line))))
                            (string-upcase (subseq line 9 end)))))))

(defun audit-source-snapshots (record)
  (let ((before (audit-required record :source-blobs-before))
        (after (audit-required record :source-blobs-after)))
    (audit-check :complete-source-snapshot-stable (equal before after) (length before))
    (loop for (relative frozen) in *audit-frozen*
          for prior = (find relative before :key (lambda (entry) (getf entry :path)) :test #'equal)
          for later = (find relative after :key (lambda (entry) (getf entry :path)) :test #'equal)
          for current = (string-trim '(#\Space #\Newline #\Return)
                                     (uiop:run-program
                                      (list "git" "-C" (namestring *audit-root*) "hash-object" relative)
                                      :output :string :error-output :string))
          collect
          (progn
            (audit-check (list :frozen-blob relative)
                         (and prior later (equal frozen (getf prior :git-blob))
                              (equal frozen (getf later :git-blob)) (equal frozen current))
                         (list :before (getf prior :git-blob) :after (getf later :git-blob) :current current))
            (list :path relative :git-blob frozen)))))

(defun audit-runtime ()
  (let* ((relative "spikes/out/4000552268-command-64251-0/report.lisp")
         (path (merge-pathnames relative *audit-root*))
         (original-sha (arcdocdb.evidence:file-sha256 path))
         (record (arcdocdb.evidence:read-evidence path :max-expanded-bytes 1048576))
         (stdout (audit-required record :stdout)) (stderr (audit-required record :stderr))
         (lines (audit-lines stdout)) (error-lines (audit-lines stderr)))
    (audit-check :wrapper-schema (= 1 (audit-required record :schema-version)) 1)
    (audit-check :wrapper-kind (eq :command-verification (audit-required record :kind)) (getf record :kind))
    (audit-check :wrapper-status (eq :ok (audit-required record :status)) (getf record :status))
    (audit-check :wrapper-exit (eql 0 (audit-required record :exit-code)) (getf record :exit-code))
    (audit-check :wrapper-source (eq :stable (audit-required record :source-consistency)) (getf record :source-consistency))
    (audit-check :wrapper-command (equal '("make" "test" "lint" "trace") (getf record :command)) (getf record :command))
    (audit-check :raw-channels (and (stringp stdout) (stringp stderr)) (list (length stdout) (length stderr)))
    (let* ((fingerprints (audit-source-snapshots record))
           (nominals (audit-test-names))
           (passes (remove-if-not (lambda (line) (audit-prefix-p "ok    " line)) lines))
           (minimal-passes (remove-if-not
                            (lambda (line) (search "-CBOR-MINIMAL-SCAN-" line)) passes))
           (summaries (remove-if-not
                       (lambda (line) (and (plusp (length line)) (digit-char-p (char line 0))
                                          (search " test " line) (search "superati." line))) lines))
           (summary-counts (mapcar (lambda (line) (parse-integer line :junk-allowed t)) summaries))
           (lead-line (audit-unique-line "  CBOR struttura minima: 768 casi lead, " lines))
           (fuzz-line (audit-unique-line "  CBOR struttura minima: 512 AST e fuzz4096 seed53434d31, " lines))
           (worker-line (audit-unique-line "  CBOR minimal scan: 2 worker, " lines))
           (lead (audit-numbers lead-line)) (fuzz (audit-numbers fuzz-line))
           (workers (audit-numbers worker-line))
           (warnings (remove-if-not
                      (lambda (line) (let ((upper (string-upcase line)))
                                      (or (search "WARNING" upper) (search "UNHANDLED" upper)
                                          (search "; CAUGHT ERROR" upper))))
                      (append lines error-lines)))
           (completion "build e test: nessun avviso, tutti i controlli superati"))
      (audit-check :frozen-nominal-count (= 22 (length nominals)) nominals)
      (audit-check :exact-nominal-runtime-order
                   (equal minimal-passes (mapcar (lambda (name) (concatenate 'string "ok    " name)) nominals))
                   minimal-passes)
      (dolist (name nominals)
        (audit-check (list :nominal-pass name)
                     (= 1 (count (concatenate 'string "ok    " name) passes :test #'equal)) name))
      (audit-check :minimum-suite-summary
                   (= 1 (count "22 test della struttura CBOR minima superati." lines :test #'equal)) 22)
      (audit-check :build-pass-lines (= 460 (length passes)) (length passes))
      (audit-check :nominal-total (= 458 (reduce #'+ summary-counts)) summary-counts)
      (dolist (smoke '("ok    package ARCDOCDB presente" "ok    ARCDOCDB:*VERSION* è una stringa"))
        (audit-check (list :smoke smoke) (= 1 (count smoke lines :test #'equal)) smoke))
      (audit-check :completion-once (= 1 (count completion lines :test #'equal)) completion)
      (audit-check :completion-after-minimum-summary
                   (< (position "22 test della struttura CBOR minima superati." lines :test #'equal)
                      (position completion lines :test #'equal)) t)
      (audit-check :no-warning-or-unhandled-diagnostic (null warnings) warnings)
      (audit-check :lead-counts (and (equal '(768 84 684) lead) (= 768 (+ (second lead) (third lead)))) lead)
      (audit-check :asts-and-fuzz (and (equal '(512 41 4055) fuzz) (= 4096 (+ (second fuzz) (third fuzz)))) fuzz)
      (let* ((children 32768) (repetitions 24) (prefix 3) (header 3)
             (first-nodes (1+ children)) (second-nodes (+ 1 (* 2 children)))
             (first-end (+ prefix header (* children 5)))
             (second-end (+ prefix header (* children 10)))
             (first-sink (* repetitions (+ first-nodes 1 first-end)))
             (second-sink (* repetitions (+ second-nodes 1 second-end))))
        (audit-check :private-worker-counts
                     (and (equal (subseq workers 0 4) (list 2 (* 2 repetitions) first-sink second-sink))
                          (= 6 (length workers)) (= (sixth workers) 1000000)
                          (plusp (fifth workers)))
                     workers)
        (audit-check :record-preserved (string-equal original-sha (arcdocdb.evidence:file-sha256 path)) original-sha)
        (list :schema-version 1 :kind :cbor-minimal-scan-test-audit :formats nil :status :ok
              :recorded-at-universal-time (get-universal-time) :reviewer "/root/development_next"
              :original-record relative :original-record-sha256 original-sha
              :original-record-bytes (arcdocdb.evidence:file-bytes path)
              :reader "arcdocdb.evidence:read-evidence" :read-eval nil :eof-required t
              :helper (enough-namestring *audit-helper* *audit-root*)
              :helper-sha256 (arcdocdb.evidence:file-sha256 *audit-helper*)
              :command (getf record :command) :wrapper-status (getf record :status)
              :exit-code (getf record :exit-code) :source-consistency (getf record :source-consistency)
              :source-snapshot-size (length (getf record :source-blobs-before))
              :six-frozen-blobs fingerprints :environment (getf record :environment)
              :wall-seconds (getf record :wall-seconds)
              :build '(:nominal-tests 458 :smoke-checks 2 :pass-lines 460)
              :minimal-nominal-tests 22 :minimal-test-names nominals
              :leading-bytes (list :cases 768 :accepted (second lead) :rejected (third lead) :raw-line lead-line)
              :generated-asts 512
              :fuzz (list :cases 4096 :seed #x53434d31 :accepted (second fuzz) :rejected (third fuzz) :raw-line fuzz-line)
              :parallel (list :workers 2 :scans 48 :repetitions-per-worker repetitions
                              :nodes-per-scan (list first-nodes second-nodes) :end-per-scan (list first-end second-end)
                              :sink-per-worker (list first-sink second-sink)
                              :overlap-ticks (fifth workers) :ticks-per-second (sixth workers)
                              :overlap-seconds (/ (fifth workers) (sixth workers))
                              :raw-line worker-line :private-buffer-and-workspace-assertions :nominal-pass
                              :distinct-core-claim nil :scaling-claim nil)
              :diagnostic-warnings warnings :completion-marker completion
              :checks (nreverse *audit-checks*)
              :limits '(:original-record-and-frozen-corpus-only :reviewer-authored-tests
                        :no-oracle-adjustment :no-product-load-or-compilation :no-rerun
                        :counts-observed-not-oracle-recomputed :nominal-pass-not-coverage-or-mcdc
                        :no-success-heap-or-performance-inference :external-load-uncontrolled)))))))

(let ((report (audit-runtime)))
  (with-open-file (stream (merge-pathnames "spikes/out/cbor-minimal-scan-test-audit.lisp" *audit-root*)
                          :direction :output :if-exists :error)
    (let ((*print-readably* t) (*print-circle* t) (*print-pretty* t))
      (write report :stream stream) (terpri stream)))
  (format t "Audit dati completato: ~D controlli, 22 nominali, 460 pass totali.~%"
          (length (getf report :checks))))
