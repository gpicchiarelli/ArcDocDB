;;;; Audit di dati registrati. Non carica prodotto, test, benchmark o mutatore.
;;;; INV-X3: solo Common Lisp; evidence-storage e SB-MD5 sono dipendenze fidate.
(require :asdf)
(require :sb-md5)
(load "tools/evidence-storage.lisp")
(defpackage #:arcdocdb.minimal-scan.data-audit (:use #:cl))
(in-package #:arcdocdb.minimal-scan.data-audit)
(declaim (optimize (safety 3) (debug 3)))
(defparameter *checks* 0)
(defparameter *findings* nil)
(defparameter *observations* nil)
(defparameter *sources* '("src/codec/cbor-scan.lisp" "src/codec/cbor-scan-minimal.lisp"))
(defparameter *cells*
  '((:u64-maximum 9 (1 0 11)) (:arrays-100 100 (100 100 102))
    (:tags-64 65 (65 0 67)) (:text-nul-unicode 8 (1 0 10))
    (:bytes-16 17 (1 0 19)) (:mixed 17 (8 2 19))
    (:floats-array 18 (4 1 20)) (:array-64 66 (65 1 68))))
(defparameter *targets*
  '(("src/codec/cbor-scan-minimal.lisp" "scan-minimal-wrapper-bypass"
     "(verifica-struttura-cbor-interna buffer start end space max-bytes max-nodes max-depth t)"
     "(verifica-struttura-cbor-interna buffer start end space max-bytes max-nodes max-depth nil)")
    ("src/codec/cbor-scan.lisp" "scan-minimal-root-only"
     "(passo-struttura-cbor bytes scratch limit node-limit depth-limit minimal)"
     "(passo-struttura-cbor bytes scratch limit node-limit depth-limit (and minimal (zerop (spazio-cbor-nodes scratch))))")
    ("src/codec/cbor-scan.lisp" "scan-minimal-disabled-after-tag"
     "(if minimal (leggi-header-cbor-minimo buffer lead end)"
     "(if (and minimal (not (spazio-cbor-pending-tag space))) (leggi-header-cbor-minimo buffer lead end)")
    ("src/codec/cbor-scan.lisp" "scan-reset-only-unused-space"
     "(azzera-spazio-cbor scratch begin)"
     "(when (zerop (spazio-cbor-nodes scratch)) (azzera-spazio-cbor scratch begin))")
    ("src/codec/cbor-scan.lisp" "scan-node-budget-plus-one"
     "(conta-nodo-cbor space max-nodes lead)"
     "(conta-nodo-cbor space (min +cbor-scan-max-bytes+ (1+ max-nodes)) lead)")
    ("src/codec/cbor-scan.lisp" "scan-depth-budget-plus-one"
     "(tratta-item-cbor buffer space major high low next end form max-depth lead)"
     "(tratta-item-cbor buffer space major high low next end form (min +cbor-scan-max-depth+ (1+ max-depth)) lead)")
    ("src/codec/cbor-scan.lisp" "scan-reported-nodes-minus-one"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) end)"
     "(values (max 0 (1- (spazio-cbor-nodes space))) (spazio-cbor-peak-depth space) end)")
    ("src/codec/cbor-scan.lisp" "scan-reported-end-minus-one"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) end)"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) (max 0 (1- end)))")))

(defun check (predicate label &optional details)
  (incf *checks*)
  (unless predicate (push (list :check label :details details) *findings*))
  predicate)

(defun read-one (stream label)
  (let ((*read-eval* nil) (*package* (find-package :cl-user)) (eof (gensym "EOF")))
    (let ((value (read stream nil eof)))
      (when (eq value eof) (error "Input vuoto: ~A" label))
      (unless (eq (read stream nil eof) eof) (error "Forme aggiuntive: ~A" label))
      value)))

(defun read-data (path)
  (arcdocdb.evidence:call-with-evidence-bytes
   path (lambda (plain) (with-open-file (stream plain :external-format :utf-8)
                         (read-one stream path)))))

(defun text-data (path)
  (arcdocdb.evidence:call-with-evidence-bytes
   path (lambda (plain) (uiop:read-file-string plain :external-format :utf-8))))

(defun observe (path)
  (let ((entry (list :path (namestring (pathname path))
                     :bytes (arcdocdb.evidence:file-bytes path)
                     :sha256 (arcdocdb.evidence:file-sha256 path))))
    (push entry *observations*) entry))

(defun md5 (path)
  (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))

(defun blob (path entries)
  (getf (find path entries :key (lambda (entry) (getf entry :path)) :test #'equal) :git-blob))

(defun git-blob (path)
  (string-trim '(#\Space #\Newline #\Return)
               (uiop:run-program (list "git" "hash-object" "--" path) :output :string)))

(defun wrapper (path)
  (observe path)
  (let* ((data (arcdocdb.evidence:read-evidence path))
         (before (getf data :source-blobs-before)) (after (getf data :source-blobs-after)))
    (check (and (eql 1 (getf data :schema-version))
                (eq :command-verification (getf data :kind))) :wrapper-schema path)
    (check (and (eq :ok (getf data :status)) (eql 0 (getf data :exit-code))
                (eq :stable (getf data :source-consistency)) (equal before after))
           :wrapper-success-and-stability path)
    (dolist (source *sources*)
      (check (and (blob source before) (equal (blob source before) (git-blob source)))
             :wrapper-current-product-fingerprint (list path source)))
    (values data (list :path path :command (getf data :command) :status (getf data :status)
                       :exit-code (getf data :exit-code) :source-consistency (getf data :source-consistency)
                       :before-after-equal (equal before after) :blob-count (length before)
                       :selected-blobs (loop for source in *sources* collect
                                        (list :path source :git-blob (blob source before)))))))

(defun parse-stdout (data label)
  (with-input-from-string (stream (getf data :stdout)) (read-one stream label)))

(defun parse-mutation-stdout (data label)
  "Il driver conserva una riga testuale del self-test, poi una sola plist finale."
  (let* ((text (getf data :stdout)) (newline (position #\Newline text)))
    (unless (and newline (uiop:string-prefix-p "CBOR minimo: self-test worker superato; " text))
      (error "Preambolo mutazioni inatteso: ~A" label))
    (with-input-from-string (stream (subseq text (1+ newline))) (read-one stream label))))

(defun roughly-equal (x y)
  (and (realp x) (realp y) (<= (abs (- x y)) (* 1d-10 (max 1d0 (abs x) (abs y))))))

(defun sink (iterations token)
  (logand most-positive-fixnum (+ (* iterations token) (ash (* iterations (1- iterations)) -1))))

(defun audit-sample (sample token iterations warmup units heap label)
  (check (and (eql iterations (getf sample :iterations))
              (eql warmup (getf sample :warmup-iterations))
              (eql token (getf sample :expected-return-token))) :sample-parameters label)
  (check (and (eql (sink iterations token) (getf sample :sink))
              (eql (sink iterations token) (getf sample :expected-sink))) :sample-sink label)
  (check (eql heap (getf sample :heap-bytes)) :sample-heap label)
  (let ((ticks (getf sample :raw-ticks)) (seconds (getf sample :seconds))
        (rate (getf sample :calls-per-second)))
    (check (and (integerp ticks) (not (minusp ticks))
                (roughly-equal seconds (/ ticks (coerce units 'double-float)))) :sample-clock label)
    (check (if (and (realp seconds) (plusp seconds))
               (roughly-equal rate (/ iterations seconds)) (null rate)) :sample-rate label)))

(defun audit-benchmark (path)
  (multiple-value-bind (record summary) (wrapper path)
    (let* ((data (parse-stdout record path)) (cells (getf data :campaigns))
           (self (getf data :self-test)) (units (getf data :timer-units-per-second)))
      (check (and (eql 1 (getf data :schema-version))
                  (eq :cbor-minimal-scan-benchmark (getf data :kind))
                  (eq :ok (getf data :status))) :benchmark-schema-and-status)
      (check (and (eq :stable (getf data :source-consistency))
                  (equal (getf data :source-fingerprints-before) (getf data :source-fingerprints-after)))
             :benchmark-source-stability)
      (check (and (eql 1 (getf data :workers)) (eql 3 (getf data :safety))
                  (integerp units) (plusp units) (eq :ok (getf self :status))) :benchmark-context)
      (check (= 8 (length cells)) :benchmark-eight-cells)
      (audit-sample (getf self :baseline) 0 4096 128 units 0 :baseline)
      (audit-sample (getf self :positive-control) 1048576 16 0 units 16777472 :positive-control)
      (loop for cell in cells for expected in *cells* do
        (destructuring-bind (name size values) expected
          (let ((token (+ (first values) (* 65536 (second values)) (* 16777216 (third values)))))
            (check (and (eq name (getf cell :name)) (eql size (getf cell :unit-bytes))
                        (equal values (getf cell :expected-values)) (equal values (getf cell :cold-values))
                        (eql 3 (getf cell :cold-value-count)) (eql token (getf cell :expected-token))
                        (eql 2 (getf cell :start)) (eql (+ 2 size) (getf cell :end))
                        (eq t (getf cell :private-preallocated-space)) (eq t (getf cell :input-unchanged)))
                   :benchmark-cold-three-values name)
            (check (= 5 (length (getf cell :samples))) :benchmark-five-replicas name)
            (loop for sample in (getf cell :samples) for replica from 0 do
              (audit-sample sample token 4096 128 units 0 (list name replica))))))
      (list :wrapper summary :cells (length cells)
            :samples (reduce #'+ cells :key (lambda (cell) (length (getf cell :samples))))
            :cold-value-counts (mapcar (lambda (cell) (getf cell :cold-value-count)) cells)
            :heap-values (remove-duplicates (loop for cell in cells append
                              (mapcar (lambda (sample) (getf sample :heap-bytes)) (getf cell :samples))))
            :fixture-values-and-tokens (loop for cell in cells collect
                (list :name (getf cell :name) :values (getf cell :cold-values) :token (getf cell :expected-token)))
            :baseline (getf self :baseline) :positive-control (getf self :positive-control)
            :limits '(:serial-success-path-only :no-counter-independent-nonallocation-proof
                      :no-new-product-execution :cold-values-arity-not-hot-arity-proof)))))

(defun lines (text) (uiop:split-string text :separator '(#\Newline)))
(defun exact-line (text value)
  (find value (lines text) :test #'string= :key (lambda (line) (string-right-trim '(#\Return) line))))
(defun compile-error-p (text)
  (some (lambda (needle) (search needle text :test #'char-equal))
        '("compilation aborted" "COMPILE-FILE-ERROR" "COMPILE-FILE-WARNED")))

(defun log-evidence (path baseline exit signal)
  (observe path)
  (let* ((text (text-data path)) (rows (lines text))
         (smoke (position "ok    ARCDOCDB:*VERSION* è una stringa" rows :test #'string=))
         (completion (position "build e test: nessun avviso, tutti i controlli superati" rows :test #'string=))
         (reject (position-if (lambda (line) (uiop:string-prefix-p "Unhandled " line)) rows))
         (test-frame (when reject (find-if (lambda (line) (search "::TEST-REQ-" line)) (nthcdr reject rows))))
         (last-pass (when reject (car (last (remove-if-not
                         (lambda (line) (uiop:string-prefix-p "ok    TEST-" line)) (subseq rows 0 reject)))))))
    (check (and smoke (not signal) (integerp exit) (not (compile-error-p text))
                (if baseline (and (zerop exit) completion (null reject))
                    (and (not (zerop exit)) (null completion) reject (< smoke reject))))
           :runtime-log-classification path)
    (list :path path :smoke-line (when smoke (1+ smoke)) :completion-line (when completion (1+ completion))
          :exit-code exit :signal signal :compile-failure (compile-error-p text)
          :first-rejection-line (when reject (1+ reject))
          :first-rejection (when reject (subseq rows reject (min (length rows) (+ reject 6))))
          :first-test-frame test-frame :last-passed-test last-pass
          :helper-rejection-frame (when reject (find-if
                    (lambda (line) (or (search "::CS-REJECT " line) (search "::CMS-REJECT " line)
                                      (search "::CS-ACCEPT " line) (search "::CMS-ACCEPT " line)))
                    (nthcdr reject rows)))
          :test-name-attribution (if (or baseline test-frame) :direct-log :not-present-in-first-backtrace)
          :ok-marker-count (count-if (lambda (line) (uiop:string-prefix-p "ok    " line)) rows))))

(defun replacement (text old new)
  (let ((at (search old text)))
    (unless (and at (not (search old text :start2 (1+ at)))) (error "Target non unico."))
    (concatenate 'string (subseq text 0 at) new (subseq text (+ at (length old))))))

(defun audit-private-copy (root index fingerprints target)
  (let* ((directory (merge-pathnames (format nil "~A/" index) root))
         (changed nil) (count 0))
    (dolist (entry fingerprints)
      (let ((relative (getf entry :file)))
        (unless (equal relative "tools/cbor-minimal-mutation.lisp")
          (let ((copy (merge-pathnames relative directory)))
            (incf count)
            (check (probe-file copy) :copied-file-exists (list index relative))
            (when (probe-file copy)
              (unless (equal (md5 copy) (getf entry :md5)) (push relative changed)))))))
    (check (equal changed (when target (list (first target)))) :exactly-one-mutated-file (list index changed))
    (when target
      (check (string= (text-data (merge-pathnames (first target) directory))
                       (replacement (text-data (merge-pathnames (first target) (merge-pathnames "baseline/" root)))
                                    (third target) (fourth target))) :exact-target-replacement index))
    (let* ((runner (merge-pathnames "tools/cbor-minimal-isolated-build.lisp" directory))
           (cache (merge-pathnames "fasl/" directory)) (text (text-data runner)))
      (check (and (probe-file cache) (search (namestring directory) text)
                  (search (namestring cache) text) (search ":IGNORE-INHERITED-CONFIGURATION" text :test #'char-equal)
                  (search "tools/build.lisp" text)) :isolated-cache-and-runner index)
      (list :directory (namestring directory) :cache (namestring cache) :copied-files count
            :changed-files changed :mutation-exact (not (null target)) :test-files-read-as-opaque-md5 t))))

(defun audit-mutations (wrapper-path root-name)
  (multiple-value-bind (record summary) (wrapper wrapper-path)
    (let* ((root (uiop:ensure-directory-pathname (truename root-name)))
           (report-path (merge-pathnames "report.lisp" root)) (report (read-data report-path))
           (stdout (parse-mutation-stdout record wrapper-path)) (baseline (getf report :baseline))
           (fingerprints (getf report :source-fingerprints-before)) (results (getf report :mutants))
           (targets (getf report :targets)) (maps nil))
      (observe report-path)
      (check (equal report stdout) :mutation-final-report-equals-stdout)
      (check (and (eql 1 (getf report :schema-version))
                  (eq :cbor-minimal-scan-mutations (getf report :kind))
                  (eq :scan (getf report :campaign-group)) (eq :ok (getf report :status))
                  (eq :stable (getf report :source-consistency))
                  (equal fingerprints (getf report :source-fingerprints-after))) :mutation-status-and-stability)
      (check (and (= 8 (length results)) (= 8 (length targets))
                  (eql 0 (getf report :worker-errors))) :mutation-eight-results-zero-worker)
      (check (and (eq :ok (getf baseline :status)) (eq :ok (getf baseline :result))) :mutation-baseline-status)
      (let ((baseline-log (log-evidence (merge-pathnames "baseline/test.log" root) t
                                       (getf baseline :exit-code) (getf baseline :signal)))
            (baseline-copy (audit-private-copy root "baseline" fingerprints nil)))
        (loop for result in results for expected in *targets* for target in targets for index from 0 do
          (check (and (string= (second expected) (getf result :name))
                      (string= (first expected) (getf result :source-file))
                      (eq t (getf result :detected)) (eq :detected (getf result :result))
                      (null (getf result :diagnostic))) :mutation-detected-target index)
          (check (and (equal (getf target :source-file) (first expected))
                      (equal (getf target :name) (second expected))
                      (equal (getf target :before) (third expected))
                      (equal (getf target :after) (fourth expected))) :mutation-target-catalog index)
          (let ((log (merge-pathnames (format nil "~D/test.log" index) root)))
            (check (equal (namestring log) (getf result :log)) :mutation-recorded-log-path index)
            (push (list :index index :name (second expected) :source-file (first expected)
                        :result (getf result :result)
                        :log (log-evidence log nil (getf result :exit-code) (getf result :signal))
                        :private-copy (audit-private-copy root index fingerprints expected)) maps)))
        (list :wrapper summary :report (namestring report-path) :baseline-log baseline-log
              :baseline-copy baseline-copy :detected (count :detected results :key (lambda (entry) (getf entry :result)))
              :survived (count :survived results :key (lambda (entry) (getf entry :result)))
              :invalid (count :invalid results :key (lambda (entry) (getf entry :result)))
              :worker-errors (getf report :worker-errors) :mapping (nreverse maps)
              :limits '(:targeted-eight-mutants-only :inline-test-frames-may-be-absent
                        :copied-tests-hashed-not-read-as-oracle :no-new-product-execution))))))

(defun strip-tags (text)
  (with-output-to-string (output)
    (let ((inside nil))
      (loop for char across text do
        (cond ((char= char #\<) (setf inside t)) ((char= char #\>) (setf inside nil))
              ((not inside) (write-char char output)))))))

(defun html-cells (row)
  (loop with cursor = 0 for at = (search "<td" row :start2 cursor) while at
        for begin = (position #\> row :start at) for end = (search "</td>" row :start2 begin)
        do (unless end (error "TD HTML non chiuso."))
        collect (string-trim '(#\Space #\Newline #\Return) (strip-tags (subseq row (1+ begin) end)))
        do (setf cursor (+ end 5))))

(defun html-rows (text)
  (loop with cursor = 0 for at = (search "<tr" text :start2 cursor) while at
        for next = (search "<tr" text :start2 (+ at 3))
        for close = (search "</tr>" text :start2 at)
        for end = (if (and next (or (null close) (< next close))) next
                      (when close (+ close 5)))
        do (unless end (error "TR HTML senza fine o successiva riga."))
        collect (subseq text at end) do (setf cursor end)))

(defun source-forms (path)
  (let ((*read-eval* nil) (*package* (find-package :cl-user)) (eof (gensym "EOF")))
    (with-open-file (stream path :external-format :utf-8)
      (loop for form = (read stream nil eof) until (eq form eof) collect form))))

(defun named (node name) (and (symbolp node) (string= (symbol-name node) name)))
(defun prefix (prefix path)
  (and (<= (length prefix) (length path)) (equal prefix (subseq path 0 (length prefix)))))

(defun error-sites (forms text)
  (let ((result nil))
    (labels ((visit (node path)
               (when (consp node)
                 (when (and (named (first node) "ERROR") (consp (second node))
                            (named (second (second node)) "INVARIANT-VIOLATION"))
                   (let* ((reason (getf (cddr node) :reason))
                          (at (search (string-downcase (symbol-name reason)) text :test #'char-equal)))
                     (push (list :reason reason :source-path path :guard-path (butlast path)
                                 :line (when at (1+ (count #\Newline text :end at)))) result)))
                 (loop for child in node for i from 0 do (visit child (append path (list i)))))))
      (loop for form in forms for i from 0 do (visit form (list i))))
    (nreverse result)))

(defun default-sites (forms)
  (loop for form in forms for top from 0 when (named (first form) "DEFUN") append
    (loop with keyword-section = nil for argument in (third form) for i from 0
          when (named argument "&KEY") do (setf keyword-section t)
          when (and keyword-section (consp argument)) collect (list top 2 i))))

(defun partition (forms text expressions branches)
  (let* ((sites (error-sites forms text)) (defaults (default-sites forms))
         (declarations (loop for form in forms for i from 0
                       when (or (named (first form) "IN-PACKAGE") (named (first form) "DECLAIM")) collect i))
         (decl nil) (errors nil) (default nil) (unknown nil) (guards nil) (unknown-branches nil))
    (dolist (raw expressions)
      (let* ((path (reverse raw)) (site (find-if (lambda (entry) (prefix (getf entry :source-path) path)) sites)))
        (cond ((and (= 1 (length path)) (member (first path) declarations)) (push raw decl))
              (site (push (list :raw-path raw :reason (getf site :reason)) errors))
              ((some (lambda (entry) (prefix entry path)) defaults) (push raw default))
              (t (push raw unknown)))))
    (dolist (raw branches)
      (let* ((path (reverse (rest raw)))
             (candidates (remove-if-not (lambda (site) (prefix (getf site :guard-path) path)) sites))
             (site (first (sort (copy-list candidates) #'> :key (lambda (entry) (length (getf entry :guard-path)))))))
        (if site (push (list :raw-path raw :reason (getf site :reason)) guards) (push raw unknown-branches))))
    (list :declarative-expressions (length decl) :internal-error-expressions (length errors)
          :unmarked-default-expressions (length default) :unclassified-expressions (length unknown)
          :internal-guard-branch-outcomes (length guards) :unclassified-branch-outcomes (length unknown-branches)
          :declaration-paths (nreverse decl) :internal-error-paths (nreverse errors)
          :default-paths (nreverse default) :unclassified-expression-paths (nreverse unknown)
          :internal-guard-paths (nreverse guards) :unclassified-branch-paths (nreverse unknown-branches)
          :error-sites sites :default-source-paths defaults)))

(defun audit-coverage (wrapper-path root-name original-state)
  (multiple-value-bind (record summary) (wrapper wrapper-path)
    (declare (ignore record))
    (let* ((root (uiop:ensure-directory-pathname (truename root-name)))
           (state-path (merge-pathnames "coverage-state.lisp" root))
           (state (read-data state-path)) (original (read-data original-state))
           (index-path (merge-pathnames "cover-index.html" root)) (index (text-data index-path))
           (source-rows (remove-if-not (lambda (row) (search "<a href='" row)) (html-rows index)))
           (files nil))
      (observe state-path) (observe original-state) (observe index-path)
      (check (equalp state original) :coverage-descriptor-equals-original-state)
      (check (= 2 (length source-rows)) :coverage-two-exact-html-source-rows)
      (dolist (source *sources*)
        (let* ((absolute (namestring (truename source)))
               (entry (find absolute state :key #'first :test #'string=))
               (leaf (file-namestring source))
               (row (find-if (lambda (row) (member leaf (html-cells row) :test #'string=)) source-rows))
               (forms (source-forms source)) (text (text-data source)))
          (check (and entry row) :coverage-source-present source)
          (unless (and entry row) (error "Source absent savedstate/HTML: ~A" source))
          (let* ((paths (second entry)) (bits (cddr entry)) (cells (html-cells row))
                 (expr (loop for path across paths for bit across bits when (and (numberp (first path)) (= bit 0)) collect path))
                 (branches (loop for path across paths for bit across bits when (and (keywordp (first path)) (= bit 0)) collect path))
                 (ec (loop for path across paths for bit across bits count (and (numberp (first path)) (= bit 1))))
                 (et (loop for path across paths count (numberp (first path))))
                 (bc (loop for path across paths for bit across bits count (and (keywordp (first path)) (= bit 1))))
                 (bt (loop for path across paths count (keywordp (first path))))
                 (href-at (+ (search "<a href='" row) 9)) (href-end (position #\' row :start href-at))
                 (html-path (merge-pathnames (subseq row href-at href-end) root)) (html (text-data html-path))
                 (source-counts (loop for html-row in (html-rows html) for entries = (html-cells html-row)
                                     when (member (first entries) '("expression" "branch") :test #'string=) collect entries))
                 (part (partition forms text expr branches)))
            (observe html-path)
            (check (= (length paths) (length bits)) :coverage-path-bit-length source)
            (check (and (= ec (parse-integer (second cells))) (= et (parse-integer (third cells)))
                        (= bc (parse-integer (fifth cells))) (= bt (parse-integer (sixth cells)))) :coverage-index-raw-counts source)
            (check (and (search absolute html) (= 2 (length source-counts))
                        (= ec (parse-integer (second (first source-counts))))
                        (= et (parse-integer (third (first source-counts))))
                        (= bc (parse-integer (second (second source-counts))))
                        (= bt (parse-integer (third (second source-counts))))) :coverage-source-html-counts source)
            (check (= (- et ec) (+ (getf part :declarative-expressions) (getf part :internal-error-expressions)
                                   (getf part :unmarked-default-expressions) (getf part :unclassified-expressions))) :coverage-full-expression-denominator source)
            (check (= (- bt bc) (+ (getf part :internal-guard-branch-outcomes) (getf part :unclassified-branch-outcomes))) :coverage-full-branch-denominator source)
            (push (list :path source :git-blob (git-blob source) :html (namestring html-path)
                        :expression-covered ec :expression-total et :expression-fraction (/ ec et)
                        :branch-covered bc :branch-total bt :branch-fraction (when (plusp bt) (/ bc bt))
                        :missing-expression-paths expr :missing-branch-paths branches :partition part) files))))
      (setf files (nreverse files))
      (let ((ec (reduce #'+ files :key (lambda (file) (getf file :expression-covered))))
            (et (reduce #'+ files :key (lambda (file) (getf file :expression-total))))
            (bc (reduce #'+ files :key (lambda (file) (getf file :branch-covered))))
            (bt (reduce #'+ files :key (lambda (file) (getf file :branch-total)))))
        (list :wrapper summary :raw-state (namestring state-path) :original-state original-state
              :index (namestring index-path) :saved-state-file-count (length state)
              :source-file-count 2 :html-file-count-including-index 3 :files files
              :totals (list :expression-covered ec :expression-total et :expression-fraction (/ ec et)
                            :branch-covered bc :branch-total bt :branch-fraction (/ bc bt)
                            :missing-expressions (- et ec) :missing-branch-outcomes (- bt bc))
              :statement-source :complete-savedstate-html-and-frozen-source-read-as-data
              :limits '(:all-denominators-retained :no-guard-exclusions :no-approved-exceptions
                        :no-mcdc-claim :source-association-not-unreachability-proof
                        :declaration-and-default-runtime-cause-unclassified
                        :no-public-behavior-completeness-inferred :no-new-product-execution))))))

(defun main ()
  (let* ((args (uiop:command-line-arguments)) (output (first args))
         (audit (list :schema-version 1 :kind :cbor-minimal-scan-recorded-data-audit
                      :recorded-at (get-universal-time) :status :running
                      :reader-role :product-author-independent-recorded-data-check
                      :read-policy '(:read-eval nil :eof-checked t :product-loaded nil :tests-read nil
                                     :new-product-campaigns nil :verification-language :common-lisp))))
    (unless (= 7 (length args)) (error "Usage: OUTPUT BENCH-WRAPPER MUTATION-WRAPPER MUTATION-DIR COVERAGE-WRAPPER COVERAGE-DIR ORIGINAL-STATE"))
    (when (probe-file output) (error "Audit destinazione gia presente: ~A" output))
    (handler-case
        (setf (getf audit :benchmark) (audit-benchmark (second args))
              (getf audit :mutations) (audit-mutations (third args) (fourth args))
              (getf audit :coverage) (audit-coverage (fifth args) (sixth args) (seventh args)))
      (error (condition) (push (list :check :reader-error :details (princ-to-string condition)) *findings*)))
    (setf (getf audit :input-observations-before) (nreverse *observations*)
          (getf audit :input-observations-after)
          (loop for entry in (getf audit :input-observations-before) collect
            (list :path (getf entry :path) :bytes (arcdocdb.evidence:file-bytes (getf entry :path))
                  :sha256 (arcdocdb.evidence:file-sha256 (getf entry :path)))))
    (check (equal (getf audit :input-observations-before) (getf audit :input-observations-after)) :observed-inputs-stable)
    (setf *findings* (nreverse *findings*))
    (setf (getf audit :checks) *checks* (getf audit :findings) *findings*
          (getf audit :status) (if *findings* :failed :ok)
          (getf audit :limits) '(:per-file-local-observation :not-atomic-snapshot
                                :no-engine-or-release-gate-inference :original-campaigns-not-rerun))
    (with-open-file (stream output :direction :output :if-exists :error :if-does-not-exist :create)
      (let ((*print-readably* t)) (write audit :stream stream :pretty t) (terpri stream)))
    (format t "Recorded-data audit ~S, ~D checks, ~D findings. Output: ~A~%"
            (getf audit :status) *checks* (length *findings*) output)
    (when *findings* (format t "Findings: ~S~%" (getf audit :findings)) (sb-ext:exit :code 1))))

(main)
