;;;; C4: controllo statico del contratto workflow/toolchain, senza parser YAML esterno.
;;; REQ: REQ-VAL-001 REQ-AFF-012
;;; Il coordinator crea il package e carica data.lisp prima di questo modulo.
;;; Nessuna forma al toplevel avvia controlli, processi o scritture.
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))
(declaim (ftype (function (t t) list) ci-workflow-build-checks))

(defun ci-workflow-source (relative)
  "Legge al massimo 256 KiB di sorgente regolare UTF-8 sotto la root CI."
  (ci-relative-path relative)
  (let* ((path (merge-pathnames relative *ci-root*)) (size (ci-bytes path)))
    (unless (<= 0 size 262144)
      (error 'simple-error :format-control "Sorgente workflow oltre limite: ~A"
                          :format-arguments (list relative)))
    (with-open-file (stream path :element-type '(unsigned-byte 8))
      (let ((bytes (make-array size :element-type '(unsigned-byte 8))))
        (unless (and (= size (read-sequence bytes stream))
                     (eq :eof (read-byte stream nil :eof)))
          (error 'simple-error :format-control "Sorgente workflow mutato: ~A"
                              :format-arguments (list relative)))
        (sb-ext:octets-to-string bytes :external-format :utf-8)))))

(defun ci-workflow-occurrences (needle text)
  "Conta occorrenze disgiunte; ogni avanzamento consuma almeno un carattere."
  (unless (plusp (length needle))
    (error 'simple-error :format-control "Pattern workflow vuoto."))
  (loop with start = 0 with count = 0
        for position = (search needle text :start2 start)
        while position
        do (incf count) (setf start (+ position (length needle)))
        finally (return count)))

(defun ci-workflow-check (file rule expected observed)
  "Costruisce un singolo esito wire; nessun conteggio deriva da log umani."
  (list :file file :rule rule :status (if (equal expected observed) :passed :failed)
        :expected expected :observed observed))

(defun ci-workflow-contract (file text required forbidden)
  "Controlla i frammenti del sottoinsieme YAML posseduto da questo writer."
  (append
   (loop for (needle count) in required
         collect (ci-workflow-check file needle count (ci-workflow-occurrences needle text)))
   (loop for needle in forbidden
         collect (ci-workflow-check file needle 0 (ci-workflow-occurrences needle text)))))

(defun ci-workflow-lines (text)
  "Divide il sorgente limitato; preserva indentazione e testo delle righe."
  (uiop:split-string text :separator '(#\Newline)))

(defun ci-workflow-field-values (text field)
  "Legge valori di campi su riga propria; non interpreta YAML generale."
  (let ((prefix (concatenate 'string field ":")) (values nil))
    (dolist (line (ci-workflow-lines text))
      (let* ((trimmed (string-trim '(#\Space #\Return) line))
             (body (if (and (>= (length trimmed) 2) (string= "- " trimmed :end2 2))
                       (subseq trimmed 2) trimmed)))
        (when (and (>= (length body) (length prefix))
                   (string= prefix body :end2 (length prefix)))
          (let* ((value (string-trim " " (subseq body (length prefix))))
                 (comment (search " #" value)))
            (push (string-right-trim " " (subseq value 0 comment)) values)))))
    (nreverse values)))

(defun ci-workflow-block (text header)
  "Estrae un job con indentazione fissa; assenza o duplicato sono errori."
  (let* ((lines (ci-workflow-lines text))
         (matches (count header lines :test #'string=))
         (tail (member header lines :test #'string=))
         (indent (position-if-not (lambda (char) (char= char #\Space)) header)))
    (unless (= matches 1)
      (error 'simple-error :format-control "Job assente/duplicato: ~A"
                          :format-arguments (list header)))
    (with-output-to-string (stream)
      (write-line (car tail) stream)
      (loop for line in (cdr tail)
            for first = (position-if-not (lambda (char) (char= char #\Space)) line)
            while (or (null first) (char= (char line first) #\#) (> first indent))
            do (write-line line stream)))))

(defun ci-workflow-action-pins ()
  "Commit risolti dai tag dei repository ufficiali tramite API il 2026-10-17."
  '(("actions/checkout" "v4.2.2" "11bd71901bbe5b1630ceea73d27597364c9af683")
    ("actions/upload-artifact" "v4.6.2" "ea165f8d65b6e75b540449e92b4886f43607fa02")
    ("actions/download-artifact" "v4.3.0" "d3f86a106a0bac45b974a628896c90dbdf5c8093")))

(defun ci-workflow-pins-checks (producer publisher lock)
  "Rifiuta action sconosciute, tag mobili, pin discordanti e passi uses aggiunti."
  (let* ((pins (ci-workflow-action-pins))
         (uses (mapcar (lambda (pin) (format nil "~A@~A" (first pin) (third pin))) pins))
         (setup "./.github/actions/setup-sbcl")
         (expected-producer (append (make-list 6 :initial-element (first uses))
                                    (make-list 6 :initial-element (second uses))
                                    (make-list 2 :initial-element (third uses)) (make-list 6 :initial-element setup)))
         (expected-publisher (list (first uses) setup))
         (checks nil))
    (push (ci-workflow-check ".github/workflows/ci.yml" "uses-pins"
                            (sort expected-producer #'string<)
                            (sort (ci-workflow-field-values producer "uses") #'string<)) checks)
    (push (ci-workflow-check ".github/workflows/ci-results.yml" "uses-pins"
                            (sort expected-publisher #'string<)
                            (sort (ci-workflow-field-values publisher "uses") #'string<)) checks)
    (dolist (pin pins)
      (let* ((repository (first pin))
             (record (find repository (getf lock :actions)
                           :key (lambda (item) (getf item :repository)) :test #'equal)))
        (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" repository
                                (list (second pin) :commit (third pin)
                                      (format nil "https://api.github.com/repos/~A/git/ref/tags/~A"
                                              repository (second pin)))
                                (list (getf record :tag) (getf record :ref-type)
                                      (getf record :commit) (getf record :api-ref))) checks)))
    (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" "action-count" 3
                            (length (getf lock :actions))) checks)
    (nreverse checks)))

(defun ci-workflow-lock-schema (lock)
  "Schema chiuso; le keyword sono anche il vocabolario wire del lock locale."
  (ci-plist-check lock
                  '(:schema-version :kind :sbcl-version :recipe-path :observed-date
                    :digest-method :platforms :upstream :actions)
                  '(:schema-version :kind :sbcl-version :recipe-path :observed-date
                    :digest-method :platforms :upstream :actions))
  (dolist (platform (getf lock :platforms))
    (ci-plist-check platform
                    '(:runner :runner-os :architecture :recipe-id :distribution :bootstrap :build)
                    '(:runner :runner-os :architecture :recipe-id :distribution :bootstrap :build))
    (ci-plist-check (getf platform :distribution)
                    '(:kind :version :url :sha256) '(:kind :version :url :sha256))
    (when (getf platform :bootstrap)
      (ci-plist-check (getf platform :bootstrap) '(:kind :version :architecture :url :sha256)
                      '(:kind :version :architecture :url :sha256)))
    (when (getf platform :build)
      (ci-plist-check (getf platform :build)
                      '(:arch :dynamic-space-mib :with-features :without-features :xc-host
                        :environment :compiler-origin :compiler-version
                        :installed-output-sha256 :installed-output-policy)
                      '(:arch :dynamic-space-mib :with-features :without-features :xc-host
                        :environment :compiler-origin :compiler-version
                        :installed-output-sha256 :installed-output-policy))))
  (ci-plist-check (getf lock :upstream)
                  '(:platform-table :build-instructions :source-tag :source-tag-type
                    :source-tag-object :source-commit)
                  '(:platform-table :build-instructions :source-tag :source-tag-type
                    :source-tag-object :source-commit))
  (dolist (action (getf lock :actions))
    (ci-plist-check action '(:repository :tag :ref-type :commit :api-ref)
                    '(:repository :tag :ref-type :commit :api-ref)))
  lock)

(defun ci-workflow-installation-schema (record)
  "Valida la forma del record locale; non attesta misure ricevute da producer esterni.
Le keyword sono note al parser wire dopo il caricamento di questo modulo."
  (let ((keys '(:schema-version :kind :sbcl-version :runner-os :architecture :recipe-id
                :distribution-sha256 :bootstrap-sha256 :runtime-sha256 :core-sha256
                :compiler-provenance-sha256)))
    (ci-plist-check record keys keys))
  (unless (and (eql 1 (getf record :schema-version))
               (eq :ci-toolchain-installation (getf record :kind))
               (equal "2.6.9" (getf record :sbcl-version))
               (member (list (getf record :runner-os) (getf record :architecture))
                       '(("Linux" "x86_64") ("macOS" "arm64")) :test #'equal))
    (error 'simple-error :format-control "Record installazione: identità non ammessa."))
  (dolist (key '(:distribution-sha256 :bootstrap-sha256 :runtime-sha256 :core-sha256
                 :compiler-provenance-sha256))
    (let ((value (getf record key)))
      (unless (or (and (null value) (member key '(:bootstrap-sha256 :compiler-provenance-sha256)))
                  (and (stringp value) (= 64 (length value))
                       (every (lambda (char) (or (char<= #\0 char #\9)
                                                (char<= #\a char #\f))) value)))
        (error 'simple-error :format-control "Record installazione: digest non ammesso ~S."
                            :format-arguments (list key)))))
  record)

(defun ci-workflow-toolchain-checks (action lock)
  "Confronta distribuzioni/bootstrap del lock con i byte fissati nell'azione."
  (let* ((platforms (getf lock :platforms)) (linux (first platforms)) (mac (second platforms))
         (source (getf mac :distribution)) (bootstrap (getf mac :bootstrap))
         (expected
           '(("ubuntu-24.04" "Linux" "x86_64" "sbcl-2.6.9-linux-binary-v1" :binary "2.6.9"
              "39fac28407405841003e4c2abfbe0d96abd93b7701e8b61cdd35e713943b46d6")
             ("macos-15" "macOS" "arm64" "sbcl-2.6.9-darwin-source-v1" :source "2.6.9"
              "c6fd1d735570eb4ff34caf9609988ca77ed0bd12b55d09a4fed075be890da513")))
         (checks nil))
    (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" "platforms" expected
                            (loop for platform in platforms for dist = (getf platform :distribution)
                                  collect (list (getf platform :runner) (getf platform :runner-os)
                                                (getf platform :architecture) (getf platform :recipe-id)
                                                (getf dist :kind) (getf dist :version) (getf dist :sha256)))) checks)
    (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" "bootstrap"
                            '(:binary "2.4.0" "arm64"
                              "1d01fac2d9748f769c9246a0a11a2c011d7843337f8f06ca144f5a500e10c117")
                            (list (getf bootstrap :kind) (getf bootstrap :version)
                                  (getf bootstrap :architecture) (getf bootstrap :sha256))) checks)
    (dolist (dist (list (getf linux :distribution) source bootstrap))
      (let* ((version (getf dist :version))
             (suffix (cond ((eq dist source) "source")
                           ((eq dist bootstrap) "arm64-darwin-binary")
                           (t "x86-64-linux-binary")))
             (url (format nil "https://downloads.sourceforge.net/project/sbcl/sbcl/~A/sbcl-~A-~A.tar.bz2"
                          version version suffix)))
        (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" suffix url (getf dist :url)) checks)
        (dolist (value (list url (getf dist :sha256)))
          (push (ci-workflow-check ".github/actions/setup-sbcl/action.yml" value 1
                                  (ci-workflow-occurrences value action)) checks))))
    (push (ci-workflow-check ".github/ci-toolchain.lock.lisp" "linux-bootstrap-build"
                            '(NIL NIL) (list (getf linux :bootstrap) (getf linux :build))) checks)
    (append (nreverse checks) (ci-workflow-build-checks mac lock))))

(defun ci-workflow-build-checks (mac lock)
  "Verifica opzioni e provenienza senza attribuire un digest inventato alla build."
  (let ((file ".github/ci-toolchain.lock.lisp") (build (getf mac :build)))
    (list
     (ci-workflow-check file "lock-version-recipe"
                        '(1 :ci-toolchain-lock "2.6.9" ".github/actions/setup-sbcl/action.yml"
                          :sha256-of-downloaded-bytes)
                        (loop for key in '(:schema-version :kind :sbcl-version :recipe-path :digest-method)
                              collect (getf lock key)))
     (ci-workflow-check file "source-build"
                        '("arm64" 2048 ("sb-thread") ("sb-core-compression")
                          "sbcl --dynamic-space-size 2048 --noinform --no-sysinit --no-userinit --disable-debugger"
                          (("CC" "clang") ("LC_ALL" "C") ("SBCL_MACOSX_VERSION_MIN" "15.0")
                           ("SBCL_MAKE_JOBS" "-j2") ("SBCL_CONTRIB_BLOCKLIST" ""))
                          :runner-apple-clang :record-at-installation NIL :measure-on-runner)
                        (loop for key in '(:arch :dynamic-space-mib :with-features :without-features
                                           :xc-host :environment :compiler-origin :compiler-version
                                           :installed-output-sha256 :installed-output-policy)
                              collect (getf build key))))))

(defun ci-workflow-producer-checks (text)
  "Contratti globali: trigger, runner, merge PR, permessi e numero di comandi."
  (append
   (ci-workflow-contract ".github/workflows/ci.yml" text
    '(("name: CI" 1) ("  push:" 1) ("    branches: [main]" 1) ("  pull_request:" 1)
      ("  workflow_dispatch:" 1) ("  contents: read" 1)
      ("CI_HEAD_SHA: ${{ github.event.pull_request.head.sha }}" 1)
      ("CI_BASE_SHA: ${{ github.event.pull_request.base.sha }}" 1)
      ("    runs-on: ubuntu-24.04" 5) ("    runs-on: ${{ matrix.os }}" 1)
      ("          - os: ubuntu-24.04" 1) ("          - os: macos-15" 1)
      ("            job: verify-linux" 1) ("            job: verify-macos" 1)
      ("            minutes: 30" 1) ("            minutes: 65" 1)
      ("      fail-fast: false" 1) ("    needs: plan" 3) ("    needs: [plan, verify]" 1)
      ("          CI_NORMAL_TEST_REPORT: ${{ runner.temp }}/arcdocdb-normal-verify/result.lisp" 1)
      ("          if-no-files-found: warn" 6) ("          retention-days: 30" 6)
      ("          compression-level: 0" 6) ("          persist-credentials: false" 6))
    '("contents: write" "actions: write" "secrets." "GH_TOKEN:" "pull_request_target:"
      "continue-on-error:" "concurrency:" "cancel-in-progress:" "make check"
      "ubuntu-latest" "macos-latest" "ref: refs/heads/" "inputs.benchmark"))
   (list (ci-workflow-check ".github/workflows/ci.yml" "run-count" 7
                            (length (ci-workflow-field-values text "run"))))))

(defun ci-workflow-job-checks (text)
  "Ogni upload possiede il proprio percorso e conserva l'identità run/attempt/job."
  (let ((file ".github/workflows/ci.yml") (checks nil))
    (dolist (job '("plan" "verify" "audit" "coverage" "bench" "seal"))
      (let* ((block (ci-workflow-block text (format nil "  ~A:" job)))
             (suffix (cond ((string= job "verify") "${{ matrix.job }}") (t job)))
             (out (cond ((string= job "seal") "sealed") (t suffix)))
             (timeout (cond ((member job '("plan" "seal") :test #'equal) 10)
                            ((string= job "bench") 20) (t 30))))
        (push (ci-workflow-check file (format nil "~A/artifact-name" job)
                                1 (ci-workflow-occurrences
                                   (format nil "name: ci-${{ github.run_id }}-${{ github.run_attempt }}-~A" suffix)
                                   block)) checks)
        (push (ci-workflow-check file (format nil "~A/upload-path" job)
                                (if (string= job "seal")
                                    (list "${{ runner.temp }}/arcdocdb-ci-downloaded"
                                          "spikes/out/ci/sealed/packet/")
                                    (if (string= job "coverage")
                                        (list "${{ runner.temp }}/arcdocdb-normal-verify"
                                              (format nil "spikes/out/ci/~A/packet/" out))
                                        (list (format nil "spikes/out/ci/~A/packet/" out))))
                                (ci-workflow-field-values block "path")) checks)
        (push (ci-workflow-check file (format nil "~A/timeout" job)
                                (if (string= job "verify") (list "${{ matrix.minutes }}" "30")
                                    (list (format nil "~D" timeout)))
                                (ci-workflow-field-values block "timeout-minutes")) checks)
        (push (ci-workflow-check file (format nil "~A/upload-always" job)
                                (if (string= job "seal") 2 1)
                                (count "always()" (ci-workflow-field-values block "if")
                                       :test #'equal)) checks)))
    (nreverse checks)))

(defun ci-workflow-invocation-checks (text)
  "Comandi attesi, senza caricare o eseguire alcun producer."
  (let ((checks nil) (file ".github/workflows/ci.yml"))
    (dolist (entry
              '(("plan" "sbcl --script tools/ci.lisp plan --out spikes/out/ci/plan")
                ("verify" "sbcl --script tools/ci.lisp run --job \"$CI_JOB\" --out \"spikes/out/ci/$CI_JOB\"")
                ("audit" "sbcl --script tools/ci.lisp run --job audit --out spikes/out/ci/audit")
                ("coverage" "sbcl --script tools/ci.lisp run --job coverage --out spikes/out/ci/coverage")
                ("bench" "sbcl --script tools/ci.lisp run --job bench --out spikes/out/ci/bench")
                ("seal" "mkdir -p \"$RUNNER_TEMP/arcdocdb-ci-downloaded\""
                 "sbcl --script tools/ci.lisp seal --input \"$RUNNER_TEMP/arcdocdb-ci-downloaded\" --out spikes/out/ci/sealed")))
      (push (ci-workflow-check file (format nil "~A/invocations" (first entry)) (rest entry)
                              (ci-workflow-field-values
                               (ci-workflow-block text (format nil "  ~A:" (first entry))) "run")) checks))
    (append (nreverse checks)
            (ci-workflow-contract file text
             '(("(github.event_name == 'push' && github.ref == 'refs/heads/main') ||" 1)
               ("      github.event_name == 'workflow_dispatch'" 1)
               ("    needs: [plan, verify, audit, coverage, bench]" 1)
               ("pattern: ci-${{ github.run_id }}-${{ github.run_attempt }}-*" 1)
               ("          merge-multiple: false" 1)
               ("if: always() && steps.checkout.outcome == 'success' && steps.setup.outcome == 'success'" 1)
               ("          CI_JOB: ${{ matrix.job }}" 1)) nil))))

(defun ci-workflow-publisher-checks (text)
  "Confine privilegiato: main fidato, token esplicito e recupero limitato."
  (append
   (ci-workflow-contract ".github/workflows/ci-results.yml" text
    '(("  workflow_run:" 1) ("    workflows: [CI]" 1) ("    types: [completed]" 1)
      ("  workflow_dispatch:" 1) ("      run_id:" 1) ("      run_attempt:" 1)
      ("      dry_run:" 1) ("        default: true" 1) ("  schedule:" 1)
      ("    - cron: '23 */6 * * *'" 1) ("permissions: {}" 1)
      ("      actions: read" 1) ("      contents: write" 1) ("      pull-requests: read" 1)
      ("    if: github.event_name != 'workflow_dispatch' || github.ref == 'refs/heads/main'" 1)
      ("          repository: ${{ github.repository }}" 1) ("          ref: refs/heads/main" 1)
      ("          persist-credentials: false" 1) ("          fetch-depth: 0" 1)
      ("          GH_TOKEN: ${{ github.token }}" 2)
      ("          CI_PUBLISH_RUN_ID: ${{ github.event_name == 'workflow_run' && github.event.workflow_run.id || inputs.run_id }}" 1)
      ("          CI_PUBLISH_RUN_ATTEMPT: ${{ github.event_name == 'workflow_run' && github.event.workflow_run.run_attempt || inputs.run_attempt }}" 1)
      ("          CI_PUBLISH_DRY_RUN: ${{ github.event_name == 'workflow_dispatch' && inputs.dry_run }}" 1)
      ("sbcl --script tools/ci.lisp publish --run-id \"$CI_PUBLISH_RUN_ID\" --attempt \"$CI_PUBLISH_RUN_ATTEMPT\" --dry-run" 1)
      ("sbcl --script tools/ci.lisp publish --run-id \"$CI_PUBLISH_RUN_ID\" --attempt \"$CI_PUBLISH_RUN_ATTEMPT\"" 2)
      ("sbcl --script tools/ci.lisp reconcile --limit 100" 1)
      ("        if: github.event_name != 'schedule'" 1) ("        if: github.event_name == 'schedule'" 1))
    '("workflow_run.conclusion" "workflow_run.head_sha" "pull_request.head" "concurrency:"
      "cancel-in-progress:" "continue-on-error:" "secrets." "download-artifact@" "git checkout"
      "--force" "pull_request_target:"))
   (list (ci-workflow-check ".github/workflows/ci-results.yml" "run-count" 2
                            (length (ci-workflow-field-values text "run"))))))

(defun ci-workflow-setup-checks (text)
  "Fissa installazione prima del check versione, bootstrap e provenienza misurata."
  (ci-workflow-contract ".github/actions/setup-sbcl/action.yml" text
   '(("set -euo pipefail" 1) ("task_sbcl_download()" 1)
     ("task_sbcl_recipe=sbcl-2.6.9-linux-binary-v1" 1)
     ("task_sbcl_recipe=sbcl-2.6.9-darwin-source-v1" 1)
     ("shasum -a 256 --check" 1) ("--max-filesize 67108864" 1)
     ("--proto '=https' --proto-redir '=https'" 1)
     ("mktemp -d \"$RUNNER_TEMP/arcdocdb-sbcl.XXXXXXXX\"" 1)
     ("Linux/x86_64)" 1) ("macOS/arm64)" 1)
     ("test \"$(sbcl --version)\" = 'SBCL 2.4.0'" 1)
     ("test \"$(\"$task_sbcl_prefix/bin/sbcl\" --version)\" = 'SBCL 2.6.9'" 1)
     ("--arch=arm64" 1) ("--dynamic-space-size=2048 --with-sb-thread --without-sb-core-compression" 1)
     ("--xc-host='sbcl --dynamic-space-size 2048 --noinform --no-sysinit --no-userinit --disable-debugger'" 1)
     ("export CC=clang" 1) ("export SBCL_MACOSX_VERSION_MIN=15.0" 1)
     ("export SBCL_MAKE_JOBS=-j2" 1) ("export SBCL_CONTRIB_BLOCKLIST=''" 1)
     ("clang --version > \"$task_sbcl_work/compiler.txt\"" 1)
     ("shasum -a 256 \"$task_sbcl_prefix/bin/sbcl\"" 1)
     ("shasum -a 256 \"$SBCL_HOME/sbcl.core\"" 1)
     ("ARCDOCDB_CI_TOOLCHAIN_RECORD=%s" 1)
     (":bootstrap-sha256 $task_sbcl_bootstrap_record" 1)
     (":compiler-provenance-sha256 $task_sbcl_compiler_record" 1))
   '("brew " "inputs:" "actions/cache@" "sudo " "curl |")))

(defun ci-workflow-checks (producer publisher action lock)
  "Unione finita dei controlli testuali; nessun interprete dei workflow."
  (append (ci-workflow-producer-checks producer) (ci-workflow-job-checks producer)
          (ci-workflow-invocation-checks producer) (ci-workflow-publisher-checks publisher)
          (ci-workflow-setup-checks action) (ci-workflow-pins-checks producer publisher lock)
          (ci-workflow-toolchain-checks action lock)))

(defun ci-workflow-replace-once (text before after)
  "Fixture in memoria: ritorna anche T se il punto da mutare esisteva."
  (let ((position (search before text)))
    (if position
        (values (concatenate 'string (subseq text 0 position) after
                             (subseq text (+ position (length before)))) t)
        (values text nil))))

(defun ci-workflow-negative-checks (producer publisher action lock)
  "Controlli negativi nominati: il rifiuto deve citare la regola bersaglio."
  (let ((checks nil))
    (dolist (fixture
              '((:producer "11bd71901bbe5b1630ceea73d27597364c9af683" "v4" "uses-pins")
                (:producer "contents: read" "contents: write" "  contents: read")
                (:producer "if-no-files-found: warn" "if-no-files-found: error"
                 "          if-no-files-found: warn")
                (:producer "path: spikes/out/ci/audit/packet/" "path: spikes/out/" "audit/upload-path")
                (:publisher "ref: refs/heads/main" "ref: ${{ github.event.workflow_run.head_sha }}"
                 "          ref: refs/heads/main")
                (:publisher "    types: [completed]"
                 "    types: [completed] # workflow_run.conclusion gate" "workflow_run.conclusion")
                (:publisher "permissions: {}" "concurrency: publisher" "concurrency:")
                (:publisher "pull-requests: read" "pull-requests: write" "      pull-requests: read")
                (:action "1d01fac2d9748f769c9246a0a11a2c011d7843337f8f06ca144f5a500e10c117" "missing"
                 "1d01fac2d9748f769c9246a0a11a2c011d7843337f8f06ca144f5a500e10c117")))
      (destructuring-bind (which before after target) fixture
        (let ((original (ecase which (:producer producer) (:publisher publisher) (:action action))))
          (multiple-value-bind (mutated found) (ci-workflow-replace-once original before after)
            (let* ((results (ci-workflow-checks (if (eq which :producer) mutated producer)
                                               (if (eq which :publisher) mutated publisher)
                                               (if (eq which :action) mutated action) lock))
                   (detected (find-if (lambda (check) (and (equal target (getf check :rule))
                                                         (eq :failed (getf check :status)))) results)))
              (push (ci-workflow-check "fixture:workflow" (format nil "~A/~A" which target)
                                      T (and found (not (null detected)))) checks))))))
    (nreverse checks)))

(defun ci-workflow-self-test (out)
  "Controlli C4 solo sorgente; salva un nuovo report esclusivo e restituisce la plist.
OUT è la directory posseduta dal chiamante. Nessun processo viene avviato.
Un fallimento di lettura/schema è un esito fallito; un errore di scrittura propaga.
La chiusura del file è il completamento locale: non promette atomicità durevole."
  (let* ((checks
           (handler-case
               (let* ((producer (ci-workflow-source ".github/workflows/ci.yml"))
                      (publisher (ci-workflow-source ".github/workflows/ci-results.yml"))
                      (action (ci-workflow-source ".github/actions/setup-sbcl/action.yml"))
                      (lock (ci-workflow-lock-schema
                             (ci-read (merge-pathnames ".github/ci-toolchain.lock.lisp" *ci-root*)
                                      :max-bytes 65536))))
                 (append (ci-workflow-checks producer publisher action lock)
                         (ci-workflow-negative-checks producer publisher action lock)))
             (error (condition)
               (list (ci-workflow-check "workflow-sources" "read-or-schema" NIL
                                        (princ-to-string condition))))))
         (failed (count :failed checks :key (lambda (check) (getf check :status))))
         (report (list :schema-version 1 :kind :ci-workflow-self-test
                       :scope :source-contract :runtime-executed NIL
                       :status (if (zerop failed) :passed :failed)
                       :planned (length checks) :passed (- (length checks) failed)
                       :failed failed :not-run 0 :checks checks))
         (directory (uiop:ensure-directory-pathname (merge-pathnames out *ci-root*)))
         (path (merge-pathnames "workflow-self-test.lisp" directory)))
    (ensure-directories-exist path)
    (ci-save path report)
    report))
