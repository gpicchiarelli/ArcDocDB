;;;; C4 bounded: profilo completamento I/O dell'engine di rinomina, nessun engine duplicato.
;;;; Uso centrale dopo freeze: --self-test|--check spikes/out/<namespace-nuovo>/.
;;;; Copie read-only di scope IO; raw/evidence cattura driver, engine e helper con SHA canonico.
;;; OWNER: ogni invocazione/child possiede profilo, argv, copie, fixture e report dell'engine.
;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-VAL-001
(let ((sb-ext:*posix-argv* (list (first sb-ext:*posix-argv*) "--library")))
  ;; Il binding termina prima di impostare il profilo e dispatchare gli argv reali.
  (load "tools/io-rename-mutation.lisp"))
(in-package #:arcdocdb.io.rename.mutation)
(declaim (optimize (safety 3) (debug 2)))
(setf *profile* :io-completion
      *campaign-kind* :io-completion-mutations
      *campaign-config-kind* :io-completion-mutation-campaign-config
      *config-kind* :io-completion-mutation-config
      *child-kind* :io-completion-mutation-child
      *driver-source* "tools/io-completion-mutation.lisp"
      *engine-source* "tools/io-rename-mutation.lisp"
      *evidence-source* "tools/evidence-storage.lisp"
      *mutant-files* '("src/io/flush.lisp" "src/io/types.lisp" "src/io/transfer.lisp")
      *backend-test-files* '("tests/io/flush-failure.lisp" "tests/io/transfer-failure.lisp")
      *expected-test-count* 21
      *test-suites* '(("ARCDOCDB.IO.TESTS" "*TESTS*" "tests/io/flush-failure.lisp" "FLUSH-GUARD-")
                     ("ARCDOCDB.IO.TESTS" "*TESTS*" "tests/io/transfer-failure.lisp" "TRANSFER-GUARD-"))
      *profile-static-risks* '(:only-four-io-completion-mutants :flush-transfer-types-local-product-required
                              :twenty-one-backend-tests-required :no-native-power-loss-evidence
                              :shared-fallisci-also-used-by-transfer :first-failing-exact-target-required)
      *mutants*
      (list
       (list :name "omit-flush-cleanup" :file "src/io/flush.lisp"
             :test '("ARCDOCDB.IO.TESTS" "TEST-REQ-AFF-004-FLUSH-GUARD-ORIGINAL-CONDITION")
             :before "(when (and (not complete) (eq (file-state file) :open))
          (setf (file-state file) :faulted))"
             :after "(progn complete nil)"
             :expected-failure :incomplete-flush-remains-open)
       (list :name "omit-flush-frontier-check" :file "src/io/flush.lisp"
             :test '("ARCDOCDB.IO.TESTS" "TEST-REQ-AFF-008-FLUSH-GUARD-WRITTEN-MUTATED")
             :before "(unless (= written (file-written file))
             (error 'invariant-violation :reason :io-flush-frontier))"
             :after "(progn written nil)"
             :expected-failure :changed-flush-frontier-admitted)
       (list :name "omit-append-cleanup" :file "src/io/transfer.lisp"
             :test '("ARCDOCDB.IO.TESTS" "TEST-REQ-AFF-004-TRANSFER-GUARD-ORIGINAL-WRITE-CONDITION")
             :before "(when (and (not complete) (eq (file-state file) :open))
          (setf (file-state file) :faulted))"
             :after "(progn complete nil)"
             :expected-failure :incomplete-append-remains-open)
       (list :name "fault-closed-in-fallisci" :file "src/io/types.lisp"
             ;; CLOSE-SUCCESS-REJECTED passa per ESIGI-APERTO, senza FALLISCI.
             ;; CLOSE-ERRNO è la prima asserzione preregistrata che osserva CLOSED alterata.
             :test '("ARCDOCDB.IO.TESTS" "TEST-REQ-AFF-004-FLUSH-GUARD-CLOSE-ERRNO-PRESERVED")
             :before "(when (and (not (eq operation :read)) (eq (file-state file) :open))
      (setf (file-state file) :faulted))"
             :after "(when (not (eq operation :read))
      (setf (file-state file) :faulted))"
             :expected-failure :closed-capability-refaulted)))

(defun completion-registry-self-test (expected)
  "Fixture C4 del registro: due marker nello stesso package, nomi esatti e ordine, senza prodotto."
  (when (find-package "ARCDOCDB.IO.TESTS") (reject "profile self-test requires unloaded IO tests."))
  (let* ((package (make-package "ARCDOCDB.IO.TESTS" :use nil))
         (registry (intern "*TESTS*" package))
         (symbols (mapcar (lambda (test) (intern (second test) package)) expected))
         (unrelated (intern "TEST-REQ-VAL-001-IO-RENAME-UNSELECTED" package)))
    (unwind-protect
         (progn
           (dolist (symbol symbols) (setf (symbol-function symbol) (lambda () t)))
           (setf (symbol-value registry) (reverse (append symbols (list unrelated))))
           (unless (equal expected (registered-tests expected)) (reject "profile marker union rejected."))
           (setf (symbol-value registry)
                 (remove (find-if (lambda (symbol) (search "TRANSFER-GUARD-" (symbol-name symbol))) symbols)
                         (symbol-value registry)))
           (let ((caught nil))
             (handler-case (registered-tests expected) (invalid-campaign () (setf caught t)))
             (unless caught (reject "missing transfer registry name accepted.")))
           (list :marker-union t :unrelated-rename-excluded t :missing-transfer-rejected t))
      (delete-package package))))

(defun completion-profile-self-test (directory)
  "Estende i 54 casi classificatore + 3 anchor negativi dell'engine; nessun compile/child prodotto."
  (let* ((root (truename "./")) (copy (merge-pathnames "profile-copy/" directory))
         (raw (merge-pathnames "profile-raw/" directory))
         (files (append *mutant-files* (source-helpers)))
         (frozen (manifest files root)) (expected (expected-tests))
         (helpers nil) (anchors 0) (helper-negatives 0) (source-negatives 0))
    (unless (and (= 21 (length expected))
                 (equal '("FLUSH-GUARD-" "TRANSFER-GUARD-") (package-markers "ARCDOCDB.IO.TESTS"))
                 (every (lambda (file) (member file (inventory) :test #'string=)) (source-helpers)))
      (reject "profile scope/marker/count/inventory mismatch."))
    (dolist (mutant *mutants*)
      (unless (member (getf mutant :file) *mutant-files* :test #'string=) (reject "profile mutant scope."))
      (let* ((source (uiop:read-file-string (merge-pathnames (getf mutant :file) root) :external-format :utf-8))
             (before (getf mutant :before)) (after (getf mutant :after))
             (modified (substitute-unique source before after)))
        (unless (and (not (string= source modified))
                     (string= source (substitute-unique modified after before)))
          (reject "profile file anchor roundtrip ~A." (getf mutant :file)))
        (incf anchors)))
    (dolist (file files)
      (ensure-directories-exist (merge-pathnames file copy))
      (uiop:copy-file (merge-pathnames file root) (merge-pathnames file copy)))
    (unless (and (equal frozen (manifest files root)) (equal frozen (manifest files copy)))
      (reject "profile self-test source/copy drift."))
    (setf helpers (capture-helpers copy raw))
    (unless (verify-helpers helpers copy raw) (reject "profile helper positive fixture."))
    ;; Negative indipendenti per il wrapper nuovo, l'engine riusato e l'helper canonico:
    ;; sia raw alterato sia fonte copiata alterata devono perdere l'attestazione.
    (dolist (spec (helper-specs))
      (dolist (side '(:raw :source))
        (let ((path (if (eq side :raw) (merge-pathnames (getf spec :raw) raw)
                        (merge-pathnames (getf spec :file) copy))))
          (with-open-file (out path :direction :output :if-exists :append :external-format :utf-8)
            (write-line "; C4 synthetic helper drift" out))
          (when (verify-helpers helpers copy raw) (reject "profile helper SHA drift accepted ~A." path))
          (incf helper-negatives)
          (uiop:copy-file (merge-pathnames (getf spec :file) root) path)
          (unless (verify-helpers helpers copy raw) (reject "profile helper restore failed.")))))
    (dolist (file *mutant-files*)
      (let ((path (merge-pathnames file copy)))
        (with-open-file (out path :direction :output :if-exists :append :external-format :utf-8)
          (write-line "; C4 synthetic IO source drift" out))
        (when (equal frozen (manifest files copy)) (reject "profile IO source SHA drift accepted ~A." file))
        (incf source-negatives)
        (uiop:copy-file (merge-pathnames file root) path)))
    (unless (and (equal frozen (manifest files root)) (equal frozen (manifest files copy)))
      (reject "profile final source/copy drift."))
    (list :status :ok :test-count (length expected) :file-anchor-cases anchors :file-anchor-roundtrip t
          :helper-digest-negative-cases helper-negatives :io-source-digest-negative-cases source-negatives
          :driver-engine-in-inventory t
          :registry (completion-registry-self-test expected) :no-compilation t :no-product-child t)))

(setf *profile-self-test* #'completion-profile-self-test)
(let ((args (uiop:command-line-arguments)))
  (unless (equal args '("--library"))
    (if (and (= 2 (length args)) (string= "--child" (first args))) (child-main (second args)) (main))))
