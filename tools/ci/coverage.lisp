;;;; Copertura C4: immagine nuova, cache privata, LCOV DA/BA e contatori SBCL fissati.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *ci-coverage-normal-report* nil)
(defparameter *ci-coverage-counter-keys*
  '(:lines-covered :lines-total :lcov-branches-covered :lcov-branches-total
    :expressions-covered :expressions-total :branches-covered :branches-total))
(defconstant +ci-coverage-byte-limit+ 134217728)
(defconstant +ci-coverage-line-limit+ 4000000)

(defun ci-coverage-relative (path)
  (let ((relative (if (uiop:absolute-pathname-p path)
                      (progn
                        (unless (uiop:subpathp (pathname path) *ci-root*)
                          (error "Copertura fuori dal checkout: ~A." path))
                        (enough-namestring path *ci-root*)) path)))
    (ci-relative-path relative)))

(defun ci-coverage-nul-rows (text)
  (unless (or (zerop (length text)) (char= #\Null (char text (1- (length text)))))
    (error "Inventario Git non terminato da NUL."))
  (let ((rows (remove "" (uiop:split-string text :separator '(#\Null)) :test #'equal)))
    (arcdocdb.ci.tests::proper-size rows 10000) rows))

(defun ci-coverage-expected-files ()
  "Unione ASDF + inventario tracked dello SHA. Un orfano resta nel denominatore atteso."
  (let ((table (make-hash-table :test #'equal)))
    (dolist (entry (ci-coverage-nul-rows (ci-git '("ls-tree" "-r" "-z" "HEAD" "--" "src/"))))
      (let* ((tab (position #\Tab entry))
             (header (and tab (uiop:split-string (subseq entry 0 tab) :separator '(#\Space))))
             (path (and tab (ci-coverage-relative (subseq entry (1+ tab))))))
        (unless (and (= (length header) 3) (equal (second header) "blob")
                     (member (first header) '("100644" "100755") :test #'equal)
                     path (ci-regular-file-p (merge-pathnames path *ci-root*)))
          (error "Sorgente tracked non regolare o inventario invalido: ~A." entry))
        (when (gethash path table) (error "Sorgente tracked duplicato ~A." path))
        (setf (gethash path table) (list :path path :tracked t :asdf nil :blob (third header)))))
    (dolist (source (ci-test-asdf-files))
      (let* ((path (ci-coverage-relative (namestring source))) (row (gethash path table)))
        (unless (and (<= 4 (length path)) (string= path "src/" :end1 4))
          (error "Sorgente ASDF fuori da src/: ~A." path))
        (if row (setf (getf row :asdf) t)
            (setf (gethash path table) (list :path path :tracked nil :asdf t :blob nil)))))
    (sort (loop for row being the hash-values of table collect row)
          #'string< :key (lambda (r) (getf r :path)))))

(defun ci-coverage-pair (text)
  (let ((comma (position #\, text)))
    (unless (and comma (not (position #\, text :start (1+ comma))))
      (error "Record LCOV non binario: ~A." text))
    (values (parse-integer text :end comma :junk-allowed nil)
            (parse-integer text :start (1+ comma) :junk-allowed nil))))

(defun ci-coverage-parse-lcov (text)
  "Dialetto SBCL 2.6.9: DA(line,0|1), BA(line,1|2); BA ripetuto = direzioni distinte.
Non accetta BRDA come sostituto di BA, né ricava dati da HTML."
  (when (> (length text) +ci-coverage-byte-limit+) (error "LCOV oltre budget."))
  (let ((files nil) (current nil) (seen (make-hash-table :test #'equal))
        (lines nil) (branches nil) (line-count 0))
    (with-input-from-string (stream text)
      (loop for raw = (read-line stream nil nil) while raw
            for line = (string-right-trim '(#\Return) raw)
            do (when (or (> (incf line-count) +ci-coverage-line-limit+) (> (length line) 8192))
                 (error "LCOV oltre budget righe."))
               (cond
                 ((zerop (length line)))
                 ((and (>= (length line) 3) (string= line "SF:" :end1 3))
                  (when current (error "LCOV: record precedente non chiuso."))
                  (let ((path (ci-coverage-relative (subseq line 3))))
                    (when (gethash path seen) (error "LCOV: file duplicato ~A." path))
                    (setf (gethash path seen) t
                          current (list :path path :lines-covered 0 :lines-total 0
                                        :lcov-branches-covered 0 :lcov-branches-total 0)
                          lines (make-hash-table) branches (make-hash-table))))
                 ((equal line "end_of_record")
                  (unless current (error "LCOV: chiusura senza file."))
                  (maphash (lambda (number ignored)
                             (declare (ignore ignored))
                             (unless (gethash number lines)
                               (error "LCOV: BA senza DA sulla riga ~D." number))) branches)
                  (push current files) (setf current nil))
                 ((and (>= (length line) 3)
                       (member (subseq line 0 3) '("DA:" "BA:") :test #'equal))
                  (unless current (error "LCOV: contatore senza file."))
                  (multiple-value-bind (number value) (ci-coverage-pair (subseq line 3))
                    (unless (<= 1 number +ci-coverage-line-limit+) (error "Numero di riga LCOV invalido."))
                    (if (char= (char line 0) #\D)
                        (progn
                          (unless (member value '(0 1)) (error "DA SBCL richiede 0 o 1."))
                          (when (gethash number lines) (error "DA duplicato sulla riga ~D." number))
                          (setf (gethash number lines) t)
                          (incf (getf current :lines-total))
                          (incf (getf current :lines-covered) value))
                        (progn
                          (unless (member value '(1 2)) (error "BA SBCL richiede 1 o 2."))
                          (setf (gethash number branches) t)
                          (incf (getf current :lcov-branches-total))
                          (when (= value 2) (incf (getf current :lcov-branches-covered)))))))
                 (t (error "Record LCOV SBCL sconosciuto: ~A." line)))))
    (when current (error "LCOV troncato prima di end_of_record."))
    (sort files #'string< :key (lambda (r) (getf r :path)))))

(defun ci-coverage-native-counts (absolute)
  "Adattatore privato v1 fissato a SBCL 2.6.9, COMPUTE-FILE-STATES -> SAMPLE-COUNT.
Fonte: https://github.com/sbcl/sbcl/blob/sbcl-2.6.9/contrib/sb-cover/cover.lisp
Non legge né interpreta SAVE-COVERAGE: lo stato opaco non è un formato di scambio."
  (unless (equal (lisp-implementation-version) "2.6.9")
    (error "Adattatore SB-COVER v1 richiede esattamente SBCL 2.6.9."))
  (multiple-value-bind (counts states lengths branch-lines)
      (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "COMPUTE-FILE-STATES" t) absolute)
    (when (null counts) (return-from ci-coverage-native-counts nil))
    (unless (and (vectorp states) (vectorp lengths) (vectorp branch-lines)
                 (= (length branch-lines) (1+ (length lengths)))
                 (equal (loop for tail on counts by #'cddr collect (car tail)) '(:branch :expression)))
      (error "Formato COMPUTE-FILE-STATES incompatibile per ~A." absolute))
    (let ((result nil))
      (dolist (spec '((:expression :expressions-covered :expressions-total)
                      (:branch :branches-covered :branches-total)))
        (let* ((sample (getf counts (first spec)))
               (covered (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "OK-OF" t) sample))
               (total (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "ALL-OF" t) sample)))
          (unless (and (integerp covered) (integerp total) (<= 0 covered total 100000000))
            (error "Contatori forme SBCL incompatibili per ~A." absolute))
          (setf (getf result (second spec)) covered (getf result (third spec)) total)))
      result)))

(defun ci-coverage-totals (files)
  "Denominatore ignoto => totali NIL; solo il subtotal esplicitamente parziale è sommabile."
  (let* ((known (remove-if-not (lambda (r) (eq :measured (getf r :status))) files))
         (complete (= (length known) (length files)))
         (subtotal (loop for key in *ci-coverage-counter-keys*
                         append (list key (reduce #'+ known :initial-value 0
                                                  :key (lambda (r) (getf r key)))))))
    (append (list :status (if complete :measured :partial)
                  :expected-files (length files) :known-files (length known)
                  :known-subtotal (when known subtotal))
            (loop for key in *ci-coverage-counter-keys*
                  append (list key (when complete (getf subtotal key)))))))

(defun ci-coverage-normal-proof (directory identity)
  "Ingresso esplicito o tests.lisp nella stessa directory; nessuna ricerca del vecchio verde."
  (let* ((path (or *ci-coverage-normal-report* (merge-pathnames "tests.lisp" directory)))
         (normal (when (ci-regular-file-p path) (ci-read path))))
    (loop for id in arcdocdb.ci.tests::*coverage-exclusions*
          for row = (and normal (find id (getf normal :tests)
                                     :key (lambda (r) (getf r :id)) :test #'equal))
          for valid = (or (and (eq (getf normal :kind) :ci-tests)
                           (eq (getf normal :profile) :verify)
                           (eq (getf normal :status) :passed)
                           (equal (getf normal :identity) identity)
                           (eq (getf row :status) :passed))
                          (and (eq (getf normal :kind) :ci-job-result)
                               (equal (getf normal :job) "verify-linux")
                               (eq (getf normal :status) :passed)
                               (every (lambda (key) (equal (getf (getf normal :identity) key)
                                                          (getf identity key)))
                                      '(:tested-sha :source-id :policy-id))
                               (let ((metrics (getf normal :metrics)))
                                 (and (integerp (getf metrics :planned))
                                      (= (getf metrics :planned) (getf metrics :passed))
                                      (eql 0 (getf metrics :failed))
                                      (eql 0 (getf metrics :not-run))
                                      (eql 0 (getf metrics :skipped))))))
          collect (list :id id :status :not-run :reason :instrumentation-changes-allocation
                        :normal-status (if valid :passed :missing)
                        :normal-reason (unless valid :normal-verification-same-sha-required)
                        :normal-report (when normal (namestring (pathname path)))
                        :normal-report-sha256 (when normal (ci-sha256 path))))))

(defun ci-coverage-reconcile (expected lcov)
  (loop for item in expected
        for path = (getf item :path)
        for line-counts = (find path lcov :key (lambda (r) (getf r :path)) :test #'equal)
        for native = (and line-counts
                          (ci-coverage-native-counts (namestring (merge-pathnames path *ci-root*))))
        collect
        (if (and (getf item :tracked) (getf item :asdf) line-counts native)
            (progn
              (unless (= (getf native :branches-total) (getf line-counts :lcov-branches-total))
                (error "Denominatori rami LCOV/SBCL discordanti per ~A." path))
              (unless (= (getf native :branches-covered) (getf line-counts :lcov-branches-covered))
                (error "Numeratori rami LCOV/SBCL discordanti per ~A." path))
              (append (copy-list item) (list :status :measured)
                      (cddr line-counts) native))
            (append (copy-list item)
                    (list :status :missing :reason
                          (cond ((not (getf item :tracked)) :untracked-asdf-source)
                                ((not (getf item :asdf)) :tracked-source-outside-asdf)
                                ((null line-counts) :not-instrumented)
                                (t :unknown-denominator)))
                    (loop for key in *ci-coverage-counter-keys* append (list key nil))))))

(defun ci-coverage-worker (out)
  "Solo il figlio fresco chiama questo ingresso. Errori precoci al coordinator."
  (unless (and (equal (software-type) "Linux") (equal (lisp-implementation-version) "2.6.9"))
    (error "Profilo copertura: Linux e SBCL 2.6.9 richiesti."))
  (require :sb-cover)
  (let* ((directory (ci-directory out)) (identity (ci-test-identity)))
    (unless (ci-working-clean-p) (error "Coverage: checkout iniziale non pulito."))
    (asdf:load-asd (merge-pathnames "arcdocdb.asd" *ci-root*))
    (let ((expected (ci-coverage-expected-files)))
      (ci-save (merge-pathnames "coverage.expected.lisp" directory)
               (list :kind :ci-coverage-plan :identity identity :expected-files expected
                     :suites (arcdocdb.ci.tests:suite-specifications)))
      (ci-test-load-systems directory :coverage t)
      ;; Reset DOPO tutti i load, immediatamente prima del medesimo catalogo verify.
      (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "RESET-COVERAGE" t))
      (let* ((tests (arcdocdb.ci.tests:run
                     :report-path (merge-pathnames "coverage-tests.lisp" directory)
                     :excluded-tests arcdocdb.ci.tests::*coverage-exclusions*))
             (lcov-path (merge-pathnames "coverage.lcov" directory)))
        (when (probe-file lcov-path) (error "LCOV già esistente."))
        ;; LCOV-REPORT fa REFRESH-COVERAGE-BITS prima di COMPUTE-FILE-STATES.
        (funcall (arcdocdb.ci.tests::lookup "SB-COVER" "LCOV-REPORT" t) lcov-path)
        (when (> (ci-bytes lcov-path) +ci-coverage-byte-limit+) (error "LCOV oltre budget."))
        (let* ((lcov (ci-coverage-parse-lcov (uiop:read-file-string lcov-path :external-format :utf-8)))
               (files (ci-coverage-reconcile expected lcov))
               (missing (loop for file in files unless (eq :measured (getf file :status))
                              collect (getf file :path)))
               (excluded (ci-coverage-normal-proof directory identity))
               (clean (and (ci-working-clean-p) (equal identity (ci-test-identity))))
               (report
                 (list :schema-version 1 :kind :ci-coverage
                       :status (if (and clean (eq :passed (getf tests :status))) :partial :failed)
                       :identity identity :tested-sha (getf identity :tested-sha)
                       :source-id (getf identity :source-id)
                       :method :sbcl-2-6-9-compute-file-states-v1 :lcov-dialect :sbcl-da-ba
                       :coverage-reset-after-load t :private-fasl t :fresh-image t
                       :files files :totals (ci-coverage-totals files)
                       :expected-files expected :missing-files missing
                       :excluded-tests excluded :tests-status (getf tests :status)
                       :lcov "coverage.lcov" :lcov-sha256 (ci-sha256 lcov-path)
                       :uninstrumented-children
                       (list (list :suite "ARCDOCDB.VERTICAL.TESTS" :status :unsupported
                                   :reason :child-processes-have-no-coverage-merge)
                             (list :suite "ARCDOCDB.ENGINE.TESTS" :status :unsupported
                                   :reason :child-processes-have-no-coverage-merge)
                             (list :suite "ARCDOCDB.LOCAL.PROCESS.TESTS" :status :unsupported
                                   :reason :child-processes-have-no-coverage-merge))
                       :limits '(:partial-child-process-coverage :not-mcdc :not-c1-qualification
                                 :zero-denominator-is-not-applicable
                                 :unknown-denominator-prevents-global-percentage)
                       :condition (unless clean "Sorgenti mutati durante coverage."))))
          (ci-save (merge-pathnames "coverage.lisp" directory) report)
          report)))))

(defun ci-run-coverage (out)
  "Lancia un nuovo SBCL senza init. Nessun codice del prodotto viene caricato nel parent.
Timeout figlio 1500s, cache out/fasl; dati e LCOV in out. La cache è esclusa dal publisher."
  (let* ((directory (ci-directory out)) (process nil)
         (command
           (append
            (list (namestring sb-ext:*runtime-pathname*) "--dynamic-space-size" "4096"
                  "--noinform" "--no-userinit" "--no-sysinit" "--non-interactive"
                  "--eval" "(require :asdf)" "--eval" "(require :sb-posix)"
                  "--eval" "(defpackage :arcdocdb.ci (:use :cl))"
                  "--eval" (format nil "(defparameter arcdocdb.ci::*ci-root* (pathname ~S))"
                                   (namestring *ci-root*)))
            (loop for module in '("tests/ci-catalog.lisp" "tools/ci/data.lisp" "tools/ci/identity.lisp"
                                  "tools/ci/support.lisp" "tools/ci/tests.lisp" "tools/ci/coverage.lisp")
                  append (list "--load" (namestring (merge-pathnames module *ci-root*))))
            (list "--eval" (format nil "(setf arcdocdb.ci::*ci-coverage-normal-report* ~S)"
                                   (when *ci-coverage-normal-report* (namestring *ci-coverage-normal-report*)))
                  "--eval" (format nil "(let ((r (arcdocdb.ci::ci-coverage-worker ~S))) (sb-ext:exit :code (if (eq (getf r :status) :failed) 1 0)))"
                                   (namestring directory))))))
    (when (probe-file (merge-pathnames "coverage.lisp" directory))
      (error "Rapporto coverage già esistente."))
    (unwind-protect
         (progn
           (setf process (sb-ext:run-program (first command) (rest command) :search nil :wait nil
                                           :directory *ci-root*
                                           :output (merge-pathnames "coverage.stdout.log" directory)
                                           :error (merge-pathnames "coverage.stderr.log" directory)
                                           :if-output-exists :error :if-error-exists :error))
           (sb-ext:with-timeout 1500 (sb-ext:process-wait process))
           (let ((path (merge-pathnames "coverage.lisp" directory)))
             (unless (and (eq :exited (sb-ext:process-status process)) (ci-regular-file-p path))
               (error "Child coverage interrotto o senza rapporto: ~S/~S."
                      (sb-ext:process-status process) (sb-ext:process-exit-code process)))
             (let ((report (ci-read path)))
               (unless (and (eq :ci-coverage (getf report :kind))
                            (or (eql 0 (sb-ext:process-exit-code process))
                                (eq :failed (getf report :status))))
                 (error "Esito child coverage incoerente."))
               report)))
      (when process
        (when (member (sb-ext:process-status process) '(:running :stopped))
          (sb-ext:process-kill process sb-posix:sigkill))
        (sb-ext:process-wait process) (sb-ext:process-close process)))))
