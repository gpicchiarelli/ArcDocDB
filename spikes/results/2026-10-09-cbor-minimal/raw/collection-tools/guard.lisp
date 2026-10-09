;;;; Guard C4 e2e del collector: fixture private, bytes originali e processi separati.
;;;; Uso: --self-test [directory-nuova-in-spikes/out/]. Non carica rapporti come codice.
(require :asdf)
(require :sb-posix)
(load "tools/evidence-storage.lisp") ; Solo libreria fidata del repository.
(defpackage #:cbor-minimal.collection.guard (:use #:cl))
(in-package #:cbor-minimal.collection.guard)
(declaim (optimize (safety 3) (debug 2)))
(defconstant +timeout-seconds+ 30)
(defconstant +max-files+ 128)
(defconstant +max-fixture-bytes+ 262144)

(defun check (truth control &rest arguments)
  "Ogni difetto della fixture o del risultato arresta il guard con diagnostica."
  (unless truth (error (apply #'format nil control arguments))))

(defun fingerprint (path)
  (list :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)))

(defun source-fingerprints ()
  (loop for path in '("spikes/out/cbor-minimal-collection/collect.lisp"
                     "spikes/out/cbor-minimal-collection/guard.lisp"
                     "tools/evidence-storage.lisp")
        collect (append (list :path path) (fingerprint path))))

(defun read-one (path)
  "Lettura dati protetta con EOF; nessun load/eval dei record o dell'indice."
  (check (<= (arcdocdb.evidence:file-bytes path) +max-fixture-bytes+) "Fixture troppo grande: ~A" path)
  (with-open-file (stream path :external-format :utf-8)
    (let* ((*read-eval* nil) (eof (gensym)) (datum (read stream nil eof)))
      (check (and (not (eq datum eof)) (eq eof (read stream nil eof)))
             "Una sola forma dati richiesta: ~A" path)
      datum)))

(defun save-one (path datum)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :if-exists :error
                               :if-does-not-exist :create :external-format :utf-8)
    (let ((*print-readably* t)) (write datum :stream stream :pretty t) (terpri stream))))

(defun save-text (path text)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :if-exists :error
                               :if-does-not-exist :create :external-format :utf-8)
    (write-string text stream)))

(defun read-bytes (path)
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((size (file-length stream)))
      (check (<= size +max-fixture-bytes+) "Byte fixture fuori limite: ~A" path)
      (let ((bytes (make-array size :element-type '(unsigned-byte 8))))
        (check (= size (read-sequence bytes stream)) "Lettura accorciata: ~A" path)
        (check (eq :eof (read-byte stream nil :eof)) "Lettura cresciuta: ~A" path)
        bytes))))

(defun copy-bytes (source target)
  (ensure-directories-exist target)
  (with-open-file (stream target :direction :output :element-type '(unsigned-byte 8)
                                :if-exists :error :if-does-not-exist :create)
    (write-sequence (read-bytes source) stream)))

(defun new-directory (name)
  "MKDIR esclusivo; destinazioni soltanto sotto spikes/out, senza traversal."
  (let* ((base (truename "./"))
         (directory (merge-pathnames (uiop:ensure-directory-pathname name) base))
         (allowed (namestring (merge-pathnames "spikes/out/" base)))
         (components (pathname-directory directory))
         (parent (make-pathname :defaults directory :directory (butlast components)
                               :name "placeholder" :type nil)))
    (check (and (uiop:string-prefix-p allowed (namestring directory))
                (not (member :up components))
                (not (member ".." components :test #'equal)))
           "Directory guard esterna all'area privata: ~A" directory)
    (ensure-directories-exist parent)
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun regular-files (directory)
  "Albero finito della fixture, al massimo 128 file; nessuna eliminazione."
  (let ((files nil) (count 0))
    (labels ((walk (base)
               (dolist (file (uiop:directory-files base))
                 (check (<= (incf count) +max-files+) "Troppi file nella fixture.")
                 (push file files))
               (dolist (sub (uiop:subdirectories base)) (walk sub))))
      (walk directory))
    (sort files #'string< :key #'namestring)))

(defun snapshot (directory)
  (loop for file in (regular-files directory)
        collect (append (list :path (enough-namestring file directory)) (fingerprint file))))

(defun copy-fixture-tree (source destination)
  (let ((target (new-directory destination)))
    (dolist (file (regular-files source))
      (copy-bytes file (merge-pathnames (enough-namestring file source) target)))
    (check (equal (snapshot source) (snapshot target)) "Clone fixture diverso dai byte originali.")
    target))

(defun execute-child (program arguments stdout stderr)
  "Processo fidato, timeout e chiusura; stdout/stderr su file regolari originali."
  (let ((process nil) (exit nil) (status nil) (diagnostic nil))
    (unwind-protect
         (handler-case
             (with-open-file (out stdout :direction :output :element-type '(unsigned-byte 8)
                                        :if-exists :error :if-does-not-exist :create)
               (with-open-file (err stderr :direction :output :element-type '(unsigned-byte 8)
                                          :if-exists :error :if-does-not-exist :create)
                 (setf process (sb-ext:run-program program arguments :search t :wait nil
                                                                     :input nil :output out :error err))
                 (check process "Processo ~A non avviato." program)
                 (sb-ext:with-timeout +timeout-seconds+ (sb-ext:process-wait process))
                 (setf status (sb-ext:process-status process) exit (sb-ext:process-exit-code process))))
           (error (condition) (setf diagnostic (princ-to-string condition))))
      (when process
        (handler-case
            (progn
              (when (member (sb-ext:process-status process) '(:running :stopped))
                (sb-ext:process-kill process sb-posix:sigkill))
              (sb-ext:with-timeout +timeout-seconds+ (sb-ext:process-wait process))
              (sb-ext:process-close process))
          (error (condition)
            (setf diagnostic (format nil "~A; cleanup: ~A" diagnostic condition))))))
    (values exit status diagnostic)))

(defun invoke (report root label program arguments &key stdout)
  "Conserva ogni invocazione, anche con timeout o errore infrastrutturale."
  (let* ((out (or stdout (merge-pathnames (format nil "logs/~A.stdout.log" label) root)))
         (err (merge-pathnames (format nil "logs/~A.stderr.log" label) root))
         (started (get-universal-time)) (ticks (get-internal-real-time)))
    (ensure-directories-exist out)
    (ensure-directories-exist err)
    (multiple-value-bind (exit status diagnostic) (execute-child program arguments out err)
      (let ((entry (list :label label :program program :arguments arguments :exit-code exit
                         :process-status status :diagnostic diagnostic :timeout-seconds +timeout-seconds+
                         :started-at-universal-time started :finished-at-universal-time (get-universal-time)
                         :raw-ticks (- (get-internal-real-time) ticks)
                         :stdout-file (namestring out) :stderr-file (namestring err)
                         :stdout-format (if stdout :binary :utf-8) :logs-original-byte-streams t)))
        (setf (getf report :invocations) (append (getf report :invocations) (list entry)))
        (check (null diagnostic) "Invocazione ~A invalida: ~A" label diagnostic)
        entry))))

(defun collector (report root label arguments)
  (invoke report root label "sbcl"
          (append '("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger"
                    "--script" "spikes/out/cbor-minimal-collection/collect.lisp") arguments)))

(defun require-exit (entry expected &optional marker)
  (check (and (eq :exited (getf entry :process-status)) (eql expected (getf entry :exit-code)))
         "Exit ~A atteso ~D, osservato ~S/~S." (getf entry :label) expected
         (getf entry :process-status) (getf entry :exit-code))
  (when marker
    (let ((path (getf entry (if (zerop expected) :stdout-file :stderr-file))))
      (check (search marker (uiop:read-file-string path :external-format :utf-8) :test #'char-equal)
             "Diagnostica ~S mancante in ~A." marker path)))
  entry)

(defun note-case (report name entry &rest details)
  (setf (getf report :cases)
        (append (getf report :cases)
                (list (append (list :name name :status :ok :invocation (getf entry :label)) details)))))

(defun command-fixture (name)
  (list :schema-version 1 :kind :command-verification :synthetic t :status :ok :exit-code 0
        :source-consistency :stable :command (list "synthetic-guard-fixture" name)
        :stdout (format nil "fixture ~A: è ü~%~A~%" name (make-string 4096 :initial-element #\x))
        :stderr "" :limits '(:synthetic-collector-fixture-only :no-product-execution-or-result)))

(defun compressed-fixture (report root label directory datum)
  "Gzip originale e descriptor SHA256; decompressione letta solo come dati."
  (let* ((original (merge-pathnames "original.lisp" directory))
         (payload (merge-pathnames "report.lisp.gz" directory))
         (descriptor (merge-pathnames "report.lisp" directory)))
    (save-one original datum)
    (require-exit (invoke report root label "gzip" (list "-n" "-c" (namestring original))
                          :stdout payload) 0)
    (save-one descriptor
              (list :schema-version 1 :kind :compressed-evidence :codec :gzip :payload "report.lisp.gz"
                    :uncompressed-bytes (arcdocdb.evidence:file-bytes original)
                    :uncompressed-sha256 (arcdocdb.evidence:file-sha256 original)
                    :compressed-bytes (arcdocdb.evidence:file-bytes payload)
                    :compressed-sha256 (arcdocdb.evidence:file-sha256 payload)))
    (check (equalp datum (arcdocdb.evidence:read-evidence descriptor)) "Fixture gzip illeggibile.")
    descriptor))

(defun make-fixtures (report root)
  "Due processi, un tree filtrato e un file binario; tutte le fonti restano intatte."
  (let* ((plain (merge-pathnames "fixtures/plain/report.lisp" root))
         (compressed-base (merge-pathnames "fixtures/compressed/" root))
         (tree-base (merge-pathnames "fixtures/tree/" root))
         (extra (merge-pathnames "fixtures/extra.bin" root))
         (manifest (merge-pathnames "manifest.lisp" root)))
    (save-one plain (command-fixture "plain"))
    (save-text (merge-pathnames "raw.log" (uiop:pathname-directory-pathname plain))
               (format nil "log plain originale è~%  spazi finali   ~%"))
    (save-text (merge-pathnames "extra.txt" (uiop:pathname-directory-pathname plain)) "process mode conserva txt")
    (let ((compressed (compressed-fixture report root "gzip-process" compressed-base
                                          (command-fixture "compressed"))))
      (save-text (merge-pathnames "raw.log" compressed-base) (format nil "log gzip originale~%"))
      (compressed-fixture report root "gzip-tree" tree-base
                          '(:schema-version 1 :kind :synthetic-raw-fixture :status :ok :value "è ü"))
      (save-text (merge-pathnames "raw.log" tree-base) (format nil "raw tree originale   ~%"))
      (save-text (merge-pathnames "excluded.txt" tree-base) "tree filter deve escludere txt")
      (save-one (merge-pathnames "fasl/hidden.lisp" tree-base) '(:hidden t))
      (ensure-directories-exist extra)
      (with-open-file (stream extra :direction :output :element-type '(unsigned-byte 8)
                                   :if-exists :error :if-does-not-exist :create)
        (write-sequence #(0 255 128 127 10 13 0) stream))
      (save-one manifest
                (list :schema-version 1 :processes (list (list "plain" (namestring plain))
                                                       (list "compressed" (namestring compressed)))
                      :trees (list (list "gzip-tree" (namestring tree-base) :lisp-and-log))
                      :files (list (list "extra.bin" (namestring extra))))))
    manifest))

(defun verify-originals (root archive manifest)
  "L'indice copre bytes/SHA; gzip deve essere presente e rileggibile anche nel tree."
  (let* ((index (read-one (merge-pathnames "archive-index.lisp" archive)))
         (files (getf index :files)) (paths (mapcar (lambda (x) (getf x :path)) files)))
    (check (and (= 1 (getf index :schema-version)) (eq :original-command-archive (getf index :kind)))
           "Indice collector invalido.")
    (check (= (length paths) (length (remove-duplicates paths :test #'equal))) "Path duplicati nell'indice.")
    (dolist (entry files)
      (let ((source (getf entry :source)) (target (merge-pathnames (getf entry :path) archive)))
        (check (and (equalp (read-bytes source) (read-bytes target))
                    (equal (fingerprint source) (fingerprint target))
                    (equal (list :bytes (getf entry :bytes) :sha256 (getf entry :sha256)) (fingerprint target)))
               "Byte/SHA originali non conservati per ~A." source)))
    (dolist (path '("processes/compressed/report.lisp.gz" "raw/gzip-tree/report.lisp.gz"
                    "collection-manifest.lisp" "collection-source.lisp" "raw/extra.bin"))
      (check (member path paths :test #'equal) "File obbligatorio assente: ~A." path))
    (check (and (not (probe-file (merge-pathnames "raw/gzip-tree/excluded.txt" archive)))
                (not (probe-file (merge-pathnames "raw/gzip-tree/fasl/hidden.lisp" archive))))
           "Filtro tree TXT/FASL non rispettato.")
    (check (equalp (read-one manifest) (read-one (merge-pathnames "collection-manifest.lisp" archive)))
           "Manifest originale non conservato.")
    (dolist (pair '(("fixtures/compressed/report.lisp" "processes/compressed/report.lisp")
                    ("fixtures/tree/report.lisp" "raw/gzip-tree/report.lisp")))
      (check (equalp (arcdocdb.evidence:read-evidence (merge-pathnames (first pair) root))
                     (arcdocdb.evidence:read-evidence (merge-pathnames (second pair) archive)))
             "Descriptor gzip copiato illeggibile: ~A." (second pair)))
    (length files)))

(defun positive-cases (report root manifest archive)
  (let ((entry (require-exit (collector report root "collect-positive"
                                       (list "--collect" (namestring manifest) (namestring archive))) 0 "Raccolta:")))
    (note-case report :collect-preserves-plain-and-two-gzip-fixtures entry
               :original-files-checked (verify-originals root archive manifest) :byte-and-sha256-match t
               :process-and-filtered-tree-gzip-readable t))
  (let ((entry (require-exit (collector report root "audit-positive" (list "--audit" (namestring archive)))
                             0 "Audit:")))
    (note-case report :cli-audit-positive entry)))

(defun existing-and-duplicate-cases (report root manifest archive)
  (let* ((before (snapshot archive))
         (entry (require-exit (collector report root "existing-target"
                                         (list "--collect" (namestring manifest) (namestring archive)))
                               1 "Raccolta esistente:")))
    (check (equal before (snapshot archive)) "Tentativo existing-target altera il positivo.")
    (note-case report :existing-target-rejected entry :original-archive-unchanged t))
  (let* ((duplicate (merge-pathnames "duplicate-manifest.lisp" root))
         (data (copy-tree (read-one manifest)))
         (destination (merge-pathnames "archive-duplicate/" root)))
    (setf (getf data :files) (append (getf data :files) (copy-tree (getf data :files))))
    (save-one duplicate data)
    (let ((entry (require-exit (collector report root "duplicate-path"
                                         (list "--collect" (namestring duplicate) (namestring destination)))
                               1 "Destinazione esistente:")))
      (note-case report :duplicate-destination-path-rejected entry :guard :exclusive-copy-target))))

(defun damaged-raw-cases (report root archive)
  (let* ((missing (copy-fixture-tree archive (merge-pathnames "archive-missing/" root)))
         (old (merge-pathnames "processes/compressed/report.lisp.gz" missing))
         (kept (merge-pathnames "processes/compressed/report.lisp.gz.missing" missing)))
    (rename-file old kept)
    (let ((entry (require-exit (collector report root "missing-raw" (list "--audit" (namestring missing)))
                               1 "Evidenza non valida")))
      (check (search "report.lisp.gz" (uiop:read-file-string (getf entry :stderr-file) :external-format :utf-8))
             "Missing-raw fallisce su un file estraneo.")
      (note-case report :missing-gzip-raw-audit-rejected entry :original-byte-copy-kept-at (namestring kept))))
  (let* ((corrupt (copy-fixture-tree archive (merge-pathnames "archive-corrupt/" root)))
         (payload (merge-pathnames "raw/gzip-tree/report.lisp.gz" corrupt)))
    (with-open-file (stream payload :direction :io :element-type '(unsigned-byte 8)
                                   :if-exists :overwrite :if-does-not-exist :error)
      (let ((byte (read-byte stream))) (file-position stream 0) (write-byte (logxor byte 1) stream)))
    (let ((entry (require-exit (collector report root "corrupted-raw" (list "--audit" (namestring corrupt)))
                               1 "Artefatto alterato:")))
      (note-case report :corrupted-gzip-raw-audit-rejected entry :corruption :one-bit-same-size))))

(defun manifest-reader-cases (report root manifest)
  (let* ((reader (merge-pathnames "reader-eval-manifest.lisp" root))
         (sentinel (merge-pathnames "reader-eval-was-executed.txt" root))
         (destination (merge-pathnames "archive-reader-eval/" root)))
    (save-text reader
               (format nil "#.(progn (with-open-file (s ~S :direction :output :if-exists :error) (write-line ~S s)) '~S)~%"
                       (namestring sentinel) "reader eval fixture executed" (read-one manifest)))
    (let ((entry (require-exit (collector report root "reader-eval"
                                         (list "--collect" (namestring reader) (namestring destination)))
                               1 "READ-EVAL")))
      (check (not (probe-file sentinel)) "Manifest reader-eval ha eseguito effetti collaterali.")
      (note-case report :reader-eval-manifest-rejected entry :side-effect-sentinel-absent t)))
  (let ((trailing (merge-pathnames "trailing-manifest.lisp" root))
        (destination (merge-pathnames "archive-trailing/" root)))
    (save-one trailing (read-one manifest))
    (with-open-file (stream trailing :direction :output :if-exists :append :external-format :utf-8)
      (write-line "(:unexpected-second-form t)" stream))
    (let ((entry (require-exit (collector report root "trailing-form"
                                         (list "--collect" (namestring trailing) (namestring destination)))
                               1 "Una sola forma richiesta")))
      (note-case report :trailing-manifest-form-rejected entry))))

(defun main ()
  "Schema 1 anche sul fallimento; sorgenti stabili, tutte le prove e log trattenuti."
  (let* ((args (uiop:command-line-arguments)) (before (source-fingerprints)) (root nil)
         (started (get-universal-time)) (ticks (get-internal-real-time))
         (report (list :schema-version 1 :kind :cbor-minimal-collection-guard :status :running
                       :cases nil :invocations nil ; Celle condivise: i callee non aggiungono una testa locale.
                       :formats nil :argv (copy-list sb-ext:*posix-argv*) :source-fingerprints-before before
                       :environment (list :sbcl (lisp-implementation-version) :machine (machine-type)
                                          :os (software-type) :os-version (software-version) :pid (sb-posix:getpid))
                       :started-at-universal-time started :timer-units-per-second internal-time-units-per-second
                       :limits '(:synthetic-fixtures-only :collector-cli-processes :no-product-campaigns
                                 :read-eval-nil-and-eof :duplicates-tested-at-collection-target
                                 :no-general-filesystem-adversary-or-release-qualification))))
    (handler-case
        (progn
          (check (and (<= 1 (length args) 2) (string= "--self-test" (first args)))
                 "Uso: --self-test [directory-nuova-in-spikes/out/].")
          (setf root (new-directory (or (second args)
                                       (format nil "spikes/out/cbor-minimal-collection/guard-~D-~D/"
                                               started (sb-posix:getpid))))
                (getf report :output-directory) (namestring root))
          (let ((manifest (make-fixtures report root)) (archive (merge-pathnames "archive-positive/" root)))
            (positive-cases report root manifest archive)
            (existing-and-duplicate-cases report root manifest archive)
            (damaged-raw-cases report root archive)
            (manifest-reader-cases report root manifest))
          (check (= 8 (length (getf report :cases))) "Conteggio casi guard inatteso.")
          (setf (getf report :status) :ok (getf report :case-count) 8))
      (error (condition) (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (let ((after (source-fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed)
            (getf report :finished-at-universal-time) (get-universal-time)
            (getf report :raw-ticks) (- (get-internal-real-time) ticks))
      (when (not (equal before after)) (setf (getf report :status) :source-changed)))
    (when root (save-one (merge-pathnames "report.lisp" root) report))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))

(main)
