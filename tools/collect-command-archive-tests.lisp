;;;; Fixture C4 indipendenti del collector; caricate soltanto da --self-test.
;;; REQ: REQ-VAL-001 REQ-AFF-012
;;;; Conserva fixture, errori e output; nessuna campagna o formato del motore.
(in-package #:arcdocdb.command-archive.collect)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *ct-source* (merge-pathnames "collect-command-archive.lisp" *load-truename*))
(defparameter *ct-checker* (merge-pathnames "check-command-archive.lisp" *load-truename*))
(defvar *ct-root* nil)
(defvar *ct-checks* 0)
(defvar *ct-cases* nil)
(defvar *ct-serial* 0)

(defun ct-check (truth detail)
  (unless truth (error "Self-test collector: ~A" detail))
  (incf *ct-checks*) t)

(defun ct-directory (path)
  (let ((directory (uiop:ensure-directory-pathname path)))
    (when (probe-file directory) (error "Fixture gia presente: ~A" directory))
    (ensure-directories-exist (uiop:pathname-parent-directory-pathname directory))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun ct-octets (path)
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (ct-check (= (length bytes) (read-sequence bytes stream)) "Lettura completa fixture")
      bytes)))

(defun ct-write-bytes (path bytes)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :if-exists :error
                              :element-type '(unsigned-byte 8))
    (write-sequence bytes stream)) path)

(defun ct-write-text (path text)
  (ct-write-bytes path (sb-ext:string-to-octets text :external-format :utf-8)))

(defun ct-text (path)
  (sb-ext:octets-to-string (ct-octets path) :external-format :utf-8))

(defun ct-data-text (data)
  (let ((*print-readably* t) (*print-length* nil) (*print-level* nil) (*print-circle* t))
    (format nil "~S~%" data)))

(defun ct-write-data (path data)
  (ct-write-text path (ct-data-text data)))

(defun ct-snapshot (paths)
  (loop for path in paths collect
        (list path (ct-octets path) (arcdocdb.evidence:file-sha256 path))))

(defun ct-unchanged (snapshot &optional except)
  (dolist (row snapshot)
    (unless (and except (equal (truename (first row)) (truename except)))
      (ct-check (equalp (second row) (ct-octets (first row))) "Interi byte originali immutati")
      (ct-check (string= (third row) (arcdocdb.evidence:file-sha256 (first row)))
                "SHA256 originali immutati"))))

(defun ct-child (argv directory label &key input output)
  "Child senza shell, timeout e kill/reap; output conservato anche per rifiuti."
  (let ((stdout (or output (merge-pathnames (format nil "~A.stdout.lisp" label) directory)))
        (stderr (merge-pathnames (format nil "~A.stderr.log" label) directory))
        (process nil))
    (unwind-protect
         (progn
           (setf process (uiop:launch-program argv :input input :output stdout :error-output stderr
                                                  :if-output-exists :error :if-error-output-exists :error
                                                  :force-shell nil))
           (multiple-value-bind (exit signal)
               (sb-ext:with-timeout 45 (uiop:wait-process process))
             (values exit signal stdout stderr)))
      (when process
        (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t))
        (sb-ext:with-timeout 5 (uiop:wait-process process))
        (uiop:close-streams process)))))

(defun ct-sbcl (script &rest arguments)
  (append (list (namestring sb-ext:*runtime-pathname*) "--noinform" "--no-userinit"
                "--no-sysinit" "--disable-debugger" "--script" (namestring script)) arguments))

(defun ct-record (label status code consistency)
  (list :schema-version 1 :kind :command-verification
        :command (list "fixture" label "literal argument")
        :status status :exit-code code :source-consistency consistency
        :started-at-universal-time 4000000000 :finished-at-universal-time 4000000010
        :stdout (format nil "historical stdout ~A~%" label)
        :stderr (format nil "historical stderr ~A~%" label)
        :environment (list :commit "fixture-history" :working-tree "historical state")))

(defun ct-fixture (directory &key record-edit record-text descriptor-edit)
  "SOURCE relativi al manifest; i file vicini esclusi restano presenti."
  (let* ((inputs (ct-directory (merge-pathnames "inputs/" directory)))
         (manifest (merge-pathnames "config/manifest.lisp" inputs))
         (record-paths '("records/ok.lisp" "records/failed.lisp" "records/changed.lisp"))
         (records (list (ct-record "ok" :ok 0 :stable)
                        (ct-record "failed" :failed nil :stable)
                        (ct-record "changed" :source-changed 0 :changed)))
         (compressed (ct-record "compressed-failed" :failed 7 :stable))
         (original (merge-pathnames "records/gzip/original.lisp" inputs))
         (descriptor-path (merge-pathnames "records/gzip/report.lisp" inputs))
         (payload (merge-pathnames "records/gzip/report.lisp.gz" inputs))
         (binary (merge-pathnames "raw/data.bin" inputs))
         (hidden (merge-pathnames "raw/.hidden.txt" inputs))
         (excluded (merge-pathnames "records/excluded-neighbor.txt" inputs))
         (files nil) (processes nil) (sources nil))
    (loop for relative in record-paths for record in records for index from 0
          for source = (merge-pathnames relative inputs)
          for target = (format nil "processes/~D/report.lisp" index)
          do (when record-edit (setf record (funcall record-edit record index)))
             (if (and record-text (zerop index)) (ct-write-text source record-text)
                 (ct-write-data source record))
             (push source sources)
             (push (list :source (concatenate 'string "../" relative) :path target) files)
             (push (list :label (format nil "process-~D" index) :record-path target) processes))
    (ct-write-data original compressed) (push original sources)
    (multiple-value-bind (exit signal stdout stderr)
        (ct-child '("gzip" "-n" "-9" "-c") directory "prepare-gzip" :input original :output payload)
      (declare (ignore stdout))
      (ct-check (and (eql 0 exit) (null signal)) "Preparazione gzip della fixture")
      (push stderr sources))
    (let ((descriptor
            (list :schema-version 1 :kind :compressed-evidence :codec :gzip
                  :payload "report.lisp.gz"
                  :uncompressed-bytes (length (ct-octets original))
                  :uncompressed-sha256 (arcdocdb.evidence:file-sha256 original)
                  :compressed-bytes (length (ct-octets payload))
                  :compressed-sha256 (arcdocdb.evidence:file-sha256 payload))))
      (when descriptor-edit (setf descriptor (funcall descriptor-edit descriptor)))
      (ct-write-data descriptor-path descriptor))
    (setf files (append (nreverse files)
                        (list (list :source "../records/gzip/report.lisp" :path "processes/gzip/report.lisp")
                              (list :source "../records/gzip/report.lisp.gz" :path "processes/gzip/report.lisp.gz")
                              (list :source "../raw/data.bin" :path "raw/data.bin")
                              (list :source (namestring hidden) :path "raw/.hidden.txt")))
          processes (append (nreverse processes)
                            (list (list :label "gzip-failed" :record-path "processes/gzip/report.lisp"))))
    (ct-write-bytes binary #(0 255 10 0 128))
    (ct-write-text hidden "Selected hidden source")
    (ct-write-text excluded "Explicitly excluded neighboring source")
    (list :manifest-path manifest
          :manifest (list :schema-version 1 :kind :command-archive-manifest :date "2026-10-15"
                          :files files :processes processes)
          :sources (append (nreverse sources) (list descriptor-path payload binary hidden excluded))
          :binary binary :excluded excluded :directory directory
          :destination (merge-pathnames "archive/" directory)
          :observations (merge-pathnames "observations/" directory))))

(defun ct-save-manifest (fixture &optional text)
  (let ((path (getf fixture :manifest-path)))
    (if text (ct-write-text path text) (ct-write-data path (getf fixture :manifest)))
    (setf (getf fixture :sources) (cons path (getf fixture :sources))) path))

(defun ct-expect-rejection (fixture reason &key after-copy source-change)
  (let ((snapshot (ct-snapshot (getf fixture :sources))) (seen nil) (returned nil))
    (handler-case
        (progn (collect-archive (getf fixture :manifest-path) (getf fixture :destination)
                                (getf fixture :observations) :after-copy after-copy)
               (setf returned t))
      (invalid-collection (condition)
        (setf seen condition)
        (ct-check (eq reason (collection-reason condition))
                  (format nil "Motivo ~S, osservato ~S/~A" reason
                          (collection-reason condition) (collection-detail condition)))))
    (ct-check (and seen (not returned)) "Rifiuto typed, nessun successo apparente")
    (ct-unchanged snapshot source-change)
    (unless (or after-copy (member reason '(:existing-destination :path-overlap)))
      (ct-check (not (probe-file (getf fixture :destination))) "Preflight prima della destinazione"))
    (when after-copy
      (ct-check (probe-file (getf fixture :destination)) "Copie parziali conservate")
      (let ((report (arcdocdb.evidence:read-evidence
                     (merge-pathnames "report.lisp" (getf fixture :observations)))))
        (ct-check (eq :failed (getf report :status)) "Osservazione fallita conservata")))
    (list :expected-reason reason :observed-reason (collection-reason seen)
          :diagnostic (collection-detail seen))))

(defun ct-positive (directory)
  (let* ((fixture (ct-fixture directory)) (manifest (ct-save-manifest fixture))
         (snapshot (ct-snapshot (getf fixture :sources)))
         (lock (sb-thread:make-mutex :name "collector self-test observations"))
         (go (sb-thread:make-semaphore)) (threads nil) (targets nil)
         (caller sb-thread:*current-thread*)
         (report
           (collect-archive
            manifest (getf fixture :destination) (getf fixture :observations)
            :after-copy
            (lambda (target)
              (let ((first nil))
                (sb-thread:with-mutex (lock)
                  (unless (member sb-thread:*current-thread* threads :test #'eq)
                    (push sb-thread:*current-thread* threads) (setf first t)
                    (when (= 4 (length threads)) (sb-thread:signal-semaphore go 4)))
                  (push (namestring target) targets))
                (when first
                  (unless (sb-thread:wait-on-semaphore go :timeout 20)
                    (error "Quattro worker della fixture non raggiungono il rendezvous."))))))))
    (ct-check (and (eq :ok (getf report :status)) (eq :complete (getf report :phase))) "Raccolta completa")
    (ct-check (= 4 (getf report :workers) (length threads)) "Quattro worker reali osservati")
    (ct-check (not (member caller threads :test #'eq)) "Le copie non girano nel chiamante")
    (ct-check (every (lambda (thread) (not (sb-thread:thread-alive-p thread))) threads) "Worker raccolti")
    (ct-check (= 3 (getf report :sha-per-copy)) "Tre SHA per copia dichiarati")
    (ct-check (= 9 (getf report :planned-files) (length targets) (length (getf report :copy-results)))
              "Sette ingressi espliciti e due sole aggiunte")
    (ct-check (= 9 (length (remove-duplicates targets :test #'string=))) "Un proprietario per ogni target")
    (ct-check (and (= 4 (length (getf report :worker-copied-counts)))
                   (every #'plusp (getf report :worker-copied-counts))
                   (= 9 (reduce #'+ (getf report :worker-copied-counts)))
                   (equal '(nil nil nil nil) (getf report :worker-errors))) "Contatori worker completi")
    (ct-check (every (lambda (copy) (eq :ok (getf copy :status))) (getf report :copy-results)) "Nessuna copia fallita")
    (let* ((root (getf fixture :destination))
           (index (arcdocdb.evidence:read-evidence (merge-pathnames "archive-index.lisp" root)))
           (indexed (getf index :files)) (processes (getf index :processes))
           (expected (append (mapcar (lambda (file) (getf file :path)) (getf (getf fixture :manifest) :files))
                             '("collection-manifest.lisp" "collection-source.lisp"))))
      (ct-check (null (set-exclusive-or expected (mapcar (lambda (file) (getf file :path)) indexed)
                                        :test #'string=)) "Inventario esplicito esatto")
      (ct-check (= 9 (length indexed)) "Nessun file vicino o sidecar implicito")
      (ct-check (equalp (ct-octets manifest) (ct-octets (merge-pathnames "collection-manifest.lisp" root)))
                "Manifest originale conservato come bytes")
      (ct-check (equalp (ct-octets *ct-source*) (ct-octets (merge-pathnames "collection-source.lisp" root)))
                "Sorgente collector conservato come bytes")
      (ct-check (equal processes (getf report :processes)) "Metadati indice/report uguali")
      (ct-check (= 4 (length processes)) "Quattro processi, anche falliti e source-changed")
      (dolist (entry (getf (getf fixture :manifest) :files))
        (let* ((source (merge-pathnames (getf entry :source) manifest))
               (target (merge-pathnames (getf entry :path) root))
               (row (find (getf entry :path) indexed :test #'string= :key (lambda (file) (getf file :path)))))
          (ct-check (equalp (ct-octets source) (ct-octets target)) "Copia binaria intera, inclusi NUL e hidden")
          (ct-check (= (length (ct-octets source)) (getf row :bytes)) "Bytes indice esatti")
          (ct-check (string= (arcdocdb.evidence:file-sha256 source) (getf row :sha256)) "SHA indice esatto")))
      (dolist (process (getf (getf fixture :manifest) :processes))
        (let* ((relative (getf process :record-path))
               (entry (find relative (getf (getf fixture :manifest) :files) :test #'string=
                            :key (lambda (file) (getf file :path))))
               (original (arcdocdb.evidence:read-evidence (merge-pathnames (getf entry :source) manifest)))
               (copy (arcdocdb.evidence:read-evidence (merge-pathnames relative root)))
               (metadata (find relative processes :test #'string= :key (lambda (row) (getf row :record-path)))))
          (ct-check (equalp original copy) "Record decodificato uguale, incluse diagnostiche storiche")
          (dolist (key '(:command :status :exit-code :source-consistency))
            (ct-check (equal (getf original key) (getf metadata key)) "Nessuna promozione dei metadati storici"))))
      (let* ((closure (getf report :independent-closure)) (audit (getf closure :result)))
        (ct-check (and (eql 0 (getf closure :exit-code)) (null (getf closure :signal))
                       (eq :ok (getf audit :status)) (eq t (getf audit :closed-inventory)))
                  "Checker finale esterno e inventario chiuso")
        (ct-check (= 9 (getf audit :indexed-files)) "Checker vede gli stessi nove file indicizzati")
        (ct-check (= 11 (getf audit :actual-files)) "Solo indice e catalogo fuori dal proprio indice")
        (ct-check (probe-file (getf closure :log)) "Log checker conservato fuori archivio"))
      (multiple-value-bind (exit signal stdout stderr)
          (ct-child (ct-sbcl *ct-checker* "--archive" (namestring root)) directory "independent-recheck")
        (ct-check (and (eql 0 exit) (null signal)) "Seconda lettura esterna non modifica archivio")
        (ct-check (eq t (getf (arcdocdb.evidence:read-evidence stdout) :closed-inventory)) "Chiusura indipendente ricontrollata")
        (ct-check (zerop (length (ct-octets stderr))) "Checker senza diagnostici inattesi")))
    (ct-unchanged snapshot)
    (list :planned-files 9 :workers 4 :historical-statuses '(:ok :failed :source-changed :failed)
          :strict-closure t :input-bytes-unchanged t :scaling-claim nil)))

(defun ct-negative-manifest (directory edit reason &key text)
  (let ((fixture (ct-fixture directory)))
    (when edit (setf (getf fixture :manifest) (funcall edit (getf fixture :manifest))))
    (ct-save-manifest fixture text)
    (ct-expect-rejection fixture reason)))

(defun ct-replace-record (directory edit reason &key text)
  (let ((fixture (ct-fixture directory :record-edit edit :record-text text)))
    (ct-save-manifest fixture) (ct-expect-rejection fixture reason)))

(defun ct-bump-first-byte (path)
  (with-open-file (stream path :direction :io :if-exists :overwrite :element-type '(unsigned-byte 8))
    (let ((first (read-byte stream)))
      (file-position stream 0) (write-byte (logxor first 1) stream))))

(defun ct-case (name function)
  (let* ((directory (ct-directory (merge-pathnames (format nil "case-~2,'0D-~A/" (incf *ct-serial*) name) *ct-root*)))
         (before *ct-checks*) (result nil))
    (handler-case
        (setf result (list :name name :status :ok :detail (funcall function directory)))
      (serious-condition (condition)
        (setf result (list :name name :status :failed :diagnostic (princ-to-string condition)))))
    (setf result (append result (list :case-id *ct-serial* :directory (namestring directory)
                                     :checks (- *ct-checks* before))))
    (ct-write-data (merge-pathnames "case-result.lisp" directory) result)
    (push result *ct-cases*) result))

(defun self-test (&optional argument)
  "Fixture nuove conservate; API e CLI del solo collector, nessuna campagna prodotto."
  (let* ((*ct-checks* 0) (*ct-cases* nil) (*ct-serial* 0)
         (*ct-root*
           (if argument (ct-directory (merge-pathnames (uiop:ensure-directory-pathname argument) (uiop:getcwd)))
               (let ((parent (merge-pathnames "../spikes/out/"
                                              (uiop:pathname-directory-pathname *ct-source*))))
                 (ensure-directories-exist parent)
                 (uiop:ensure-directory-pathname
                  (sb-posix:mkdtemp (namestring (merge-pathnames "command-archive-collector-self-test-XXXXXX" parent))))))))
    (ct-case "explicit-closed-parallel-history" #'ct-positive)
    (dolist (definition '(("schema-version" :schema-version 2 :manifest-schema)
                          ("manifest-kind" :kind :wrong :manifest-schema)
                          ("date-format" :date "2026/10/15" :manifest-schema)
                          ("unknown-trees" :trees ("implicit/") :data-shape)))
      (let ((name (first definition)) (key (second definition))
            (value (third definition)) (reason (fourth definition)))
        (ct-case name (lambda (directory)
                        (ct-negative-manifest directory
                          (lambda (data) (setf (getf data key) value) data) reason)))))
    (ct-case "duplicate-manifest-key"
      (lambda (directory) (ct-negative-manifest directory
                            (lambda (data) (append data '(:date "2026-10-15"))) :duplicate-field)))
    (dolist (path '("../escape.bin" "/absolute.bin" "a//b" "a/./b" "a/../b" "a\\b"))
      (let ((bad path))
        (ct-case "relative-target"
          (lambda (directory) (ct-negative-manifest directory
            (lambda (data) (setf (getf (car (last (getf data :files))) :path) bad) data) :relative-path)))))
    (dolist (path '("archive-index.lisp" "catalogo.lisp" "collection-manifest.lisp" "collection-source.lisp"))
      (let ((reserved path))
        (ct-case "reserved-target"
          (lambda (directory) (ct-negative-manifest directory
            (lambda (data) (setf (getf (car (last (getf data :files))) :path) reserved) data) :reserved-target)))))
    (ct-case "duplicate-target"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (car (last (getf data :files))) :path)
                             (getf (first (getf data :files)) :path)) data) :duplicate-target)))
    (ct-case "file-directory-collision"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (nth 5 (getf data :files)) :path) "raw/node"
                             (getf (nth 6 (getf data :files)) :path) "raw/node/child") data) :path-collision)))
    (ct-case "unknown-file-field"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (first (getf data :files)) :implicit) t) data) :data-shape)))
    (ct-case "unknown-process-field"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (first (getf data :processes)) :status) :ok) data) :data-shape)))
    (dolist (label '("slash/name" ""))
      (let ((bad label))
        (ct-case "invalid-process-label"
          (lambda (directory) (ct-negative-manifest directory
            (lambda (data) (setf (getf (first (getf data :processes)) :label) bad) data) :process-label)))))
    (ct-case "duplicate-process-label"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (second (getf data :processes)) :label)
                             (getf (first (getf data :processes)) :label)) data) :process-label)))
    (ct-case "record-not-in-files"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (first (getf data :processes)) :record-path) "absent/report.lisp") data) :process-record)))
    (ct-case "duplicate-process-record"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (second (getf data :processes)) :record-path)
                             (getf (first (getf data :processes)) :record-path)) data) :process-record)))
    (ct-case "wrong-record-kind"
      (lambda (directory) (ct-replace-record directory
        (lambda (record index) (when (zerop index) (setf (getf record :kind) :not-a-command)) record) :process-schema)))
    (dolist (status '(:running :unknown-terminal))
      (let ((bad status))
        (ct-case "nonterminal-record"
          (lambda (directory) (ct-replace-record directory
            (lambda (record index) (when (zerop index) (setf (getf record :status) bad)) record) :incomplete-process)))))
    (ct-case "unfinished-record"
      (lambda (directory) (ct-replace-record directory
        (lambda (record index) (when (zerop index) (remf record :finished-at-universal-time)) record) :incomplete-process)))
    (ct-case "invalid-record-metadata"
      (lambda (directory) (ct-replace-record directory
        (lambda (record index) (when (zerop index) (setf (getf record :command) '("fixture" 3))) record) :process-metadata)))
    (ct-case "ok-with-failing-exit"
      (lambda (directory) (ct-replace-record directory
        (lambda (record index) (when (zerop index) (setf (getf record :exit-code) 7)) record) :process-metadata)))
    (ct-case "ok-with-changed-source"
      (lambda (directory) (ct-replace-record directory
        (lambda (record index) (when (zerop index) (setf (getf record :source-consistency) :changed)) record) :process-metadata)))
    (ct-case "explicit-gzip-payload-required"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf data :files)
                             (remove "processes/gzip/report.lisp.gz" (getf data :files) :test #'string=
                                     :key (lambda (entry) (getf entry :path)))) data) :decoded-record)))
    (ct-case "accessory-descriptor-also-needs-explicit-payload"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data)
          (setf (getf data :processes) (butlast (getf data :processes))
                (getf data :files)
                (remove "processes/gzip/report.lisp.gz" (getf data :files) :test #'string=
                        :key (lambda (entry) (getf entry :path)))) data) :decoded-record)))
    (ct-case "accessory-compressed-record-retained-with-payload"
      (lambda (directory)
        (let ((fixture (ct-fixture directory)))
          (setf (getf (getf fixture :manifest) :processes)
                (butlast (getf (getf fixture :manifest) :processes)))
          (ct-save-manifest fixture)
          (let* ((before (ct-snapshot (getf fixture :sources)))
                 (report (collect-archive (getf fixture :manifest-path) (getf fixture :destination)
                                          (getf fixture :observations)))
                 (source (merge-pathnames "../records/gzip/report.lisp" (getf fixture :manifest-path)))
                 (target (merge-pathnames "processes/gzip/report.lisp" (getf fixture :destination))))
            (ct-check (and (eq :ok (getf report :status)) (eq :complete (getf report :phase)))
                      "Accessorio compresso ammesso con payload esplicito")
            (ct-check (= 3 (length (getf report :processes))) "Accessorio non promosso a processo")
            (ct-check (equalp (arcdocdb.evidence:read-evidence source)
                              (arcdocdb.evidence:read-evidence target)) "Accessorio decodificato e conservato")
            (ct-check (eq t (getf (getf (getf report :independent-closure) :result) :closed-inventory))
                      "Chiusura anche con descriptor accessorio")
            (ct-unchanged before) (list :processes 3 :accessory-descriptor :preserved)))))
    (ct-case "gzip-target-must-match-descriptor"
      (lambda (directory) (ct-negative-manifest directory
        (lambda (data) (setf (getf (nth 4 (getf data :files)) :path) "processes/gzip/other.gz") data) :decoded-record)))
    (ct-case "descriptor-hash-mismatch"
      (lambda (directory)
        (let ((fixture (ct-fixture directory :descriptor-edit
                          (lambda (data) (setf (getf data :compressed-sha256) (make-string 64 :initial-element #\0)) data))))
          (ct-save-manifest fixture) (ct-expect-rejection fixture :decoded-record))))
    (ct-case "source-leaf-symlink"
      (lambda (directory)
        (let* ((fixture (ct-fixture directory)) (link (merge-pathnames "inputs/raw/link.bin" directory)))
          (sb-posix:symlink (namestring (getf fixture :binary)) (namestring link))
          (setf (getf (nth 5 (getf (getf fixture :manifest) :files)) :source) "../raw/link.bin")
          (ct-save-manifest fixture) (ct-expect-rejection fixture :nonregular-source))))
    (dolist (definition '(("plain-budget-exact-boundary" "raw/data.bin" 1048576)
                          ("gzip-budget-exact-boundary" "raw/data.gz" 8388608)))
      (let ((name (first definition)) (target (second definition)) (size (third definition)))
        (ct-case name
          (lambda (directory)
            (let* ((fixture (ct-fixture directory)) (source (getf fixture :binary)))
              (with-open-file (stream source :direction :io :if-exists :overwrite
                                            :element-type '(unsigned-byte 8))
                (file-position stream (1- size)) (write-byte 0 stream))
              (setf (getf (nth 5 (getf (getf fixture :manifest) :files)) :path) target)
              (ct-save-manifest fixture)
              (let* ((before (ct-snapshot (getf fixture :sources)))
                     (report (collect-archive (getf fixture :manifest-path) (getf fixture :destination)
                                              (getf fixture :observations))))
                (ct-check (eq :ok (getf report :status)) "Esatto limite file ammesso in base al target")
                (ct-check (equalp (ct-octets source)
                                  (ct-octets (merge-pathnames target (getf fixture :destination))))
                          "Payload al limite copiato interamente")
                (ct-unchanged before) (list :bytes size :target target :status :ok)))))))
    (dolist (definition '(("plain-budget-over" "raw/data.bin" 1048577)
                          ("gzip-budget-over" "raw/data.gz" 8388609)))
      (let ((name (first definition)) (target (second definition)) (size (third definition)))
        (ct-case name
          (lambda (directory)
            (let* ((fixture (ct-fixture directory)) (source (getf fixture :binary)))
              (with-open-file (stream source :direction :io :if-exists :overwrite
                                            :element-type '(unsigned-byte 8))
                (file-position stream (1- size)) (write-byte 0 stream))
              (setf (getf (nth 5 (getf (getf fixture :manifest) :files)) :path) target)
              (ct-save-manifest fixture) (ct-expect-rejection fixture :file-budget))))))
    (ct-case "existing-destination-never-overwritten"
      (lambda (directory)
        (let* ((fixture (ct-fixture directory)) (dest (ct-directory (getf fixture :destination)))
               (marker (ct-write-text (merge-pathnames "preserve.txt" dest) "Existing destination bytes"))
               (before (ct-octets marker)))
          (ct-save-manifest fixture)
          (prog1 (ct-expect-rejection fixture :existing-destination)
            (ct-check (equalp before (ct-octets marker)) "Archivio esistente non sovrascritto")))))
    (ct-case "existing-observations-never-overwritten"
      (lambda (directory)
        (let* ((fixture (ct-fixture directory)) (obs (ct-directory (getf fixture :observations)))
               (marker (ct-write-text (merge-pathnames "preserve.txt" obs) "Existing observations bytes"))
               (before (ct-octets marker)))
          (ct-save-manifest fixture)
          (prog1 (ct-expect-rejection fixture :existing-observations)
            (ct-check (equalp before (ct-octets marker)) "Osservazioni esistenti non sovrascritte")))))
    (dolist (mode '(:same :observations-inside :destination-inside))
      (let ((case-mode mode))
        (ct-case "destination-observations-overlap"
          (lambda (directory)
            (let ((fixture (ct-fixture directory)))
              (ecase case-mode
                (:same (setf (getf fixture :observations) (getf fixture :destination)))
                (:observations-inside (setf (getf fixture :observations)
                                            (merge-pathnames "observations/" (getf fixture :destination))))
                (:destination-inside (setf (getf fixture :destination)
                                           (merge-pathnames "archive/" (getf fixture :observations)))))
              (ct-save-manifest fixture) (ct-expect-rejection fixture :path-overlap))))))
    (ct-case "corrupt-copy-retains-failure"
      (lambda (directory)
        (let ((fixture (ct-fixture directory)))
          (ct-save-manifest fixture)
          (ct-expect-rejection fixture :copied-bytes :after-copy
            (lambda (target) (when (equal "data.bin" (file-namestring target)) (ct-bump-first-byte target)))))))
    (ct-case "source-change-retains-failure"
      (lambda (directory)
        (let* ((fixture (ct-fixture directory)) (source (getf fixture :binary)))
          (ct-save-manifest fixture)
          (ct-expect-rejection fixture :source-changed :source-change source :after-copy
            (lambda (target) (when (equal "data.bin" (file-namestring target)) (ct-bump-first-byte source)))))))
    (ct-case "unindexed-extra-rejected-by-final-checker"
      (lambda (directory)
        (let ((fixture (ct-fixture directory)))
          (ct-save-manifest fixture)
          (let* ((detail
                   (ct-expect-rejection fixture :closed-check :after-copy
                     (lambda (target)
                       (when (equal "collection-source.lisp" (file-namestring target))
                         (ct-write-bytes (merge-pathnames ".unindexed-extra.bin"
                                                         (uiop:pathname-directory-pathname target)) #(23 45))))))
                 (log (merge-pathnames "closed-check.log" (getf fixture :observations)))
                 (result (arcdocdb.evidence:read-evidence log)))
            (ct-check (and (probe-file log) (plusp (length (ct-octets log)))) "Log checker fallito conservato")
            (ct-check (and (eq :failed (getf result :status)) (eq :inventory (getf result :reason)))
                      "Checker esterno rifiuta precisamente inventario non chiuso")
            (ct-check (probe-file (merge-pathnames ".unindexed-extra.bin" (getf fixture :destination)))
                      "Extra e archivio parziale conservati per diagnosi")
            (append detail (list :checker-status :failed :checker-reason :inventory :checker-log (namestring log)))))))
    (ct-case "manifest-read-eval-disabled"
      (lambda (directory)
        (let* ((fixture (ct-fixture directory)) (marker (merge-pathnames "read-eval-ran.txt" directory))
               (text (format nil "#.(progn (with-open-file (s ~S :direction :output :if-exists :supersede) (write-line ~S s)) nil)"
                             (namestring marker) "SHOULD NOT EXECUTE")))
          (ct-save-manifest fixture text)
          (prog1 (ct-expect-rejection fixture :data-shape)
            (ct-check (not (probe-file marker)) "Nessuna valutazione #. del manifest")))))
    (ct-case "manifest-eof-required"
      (lambda (directory)
        (let ((fixture (ct-fixture directory)))
          (ct-save-manifest fixture (concatenate 'string (ct-data-text (getf fixture :manifest)) "(:trailing t)"))
          (ct-expect-rejection fixture :data-shape))))
    (ct-case "record-read-eval-disabled"
      (lambda (directory)
        (let* ((marker (merge-pathnames "read-eval-ran.txt" directory))
               (text (format nil "#.(progn (with-open-file (s ~S :direction :output :if-exists :supersede) (write-line ~S s)) nil)"
                             (namestring marker) "SHOULD NOT EXECUTE")))
          (prog1 (ct-replace-record directory nil :data-shape :text text)
            (ct-check (not (probe-file marker)) "Nessuna valutazione #. del record")))))
    (ct-case "record-eof-required"
      (lambda (directory) (ct-replace-record directory nil :data-shape
                            :text (concatenate 'string (ct-data-text (ct-record "bad-tail" :ok 0 :stable)) "(:trailing t)"))))
    (dolist (arguments '(nil ("--unknown") ("--collect")
                         ("--collect" "manifest.lisp" "new/" "--observations" "obs/" "--jobs" "3")
                         ("--collect" "manifest.lisp" "new/" "--observations" "obs/" "--jobs" "4" "extra")))
      (let ((argv arguments))
        (ct-case "cli-arguments"
          (lambda (directory)
            (multiple-value-bind (exit signal stdout stderr)
                (ct-child (apply #'ct-sbcl *ct-source* argv) directory "cli")
              (declare (ignore stderr))
              (ct-check (and (integerp exit) (plusp exit) (null signal)) "CLI invalida con exit nonzero, niente segnale")
              (let ((result (arcdocdb.evidence:read-evidence stdout)))
                (ct-check (and (eq :failed (getf result :status)) (eq :arguments (getf result :reason)))
                          "CLI rifiuta per argomenti, non per guasto estraneo")))))))
    (let* ((cases (nreverse *ct-cases*))
           (success (every (lambda (case) (eq :ok (getf case :status))) cases))
           (report (list :schema-version 1 :kind :command-archive-collector-self-test
                         :status (if success :ok :failed) :checks *ct-checks* :case-count (length cases)
                         :cases cases :root (namestring *ct-root*) :fixtures-preserved t
                         :product-campaigns nil :scaling-claim nil :mcdc-claim nil)))
      (ct-write-data (merge-pathnames "self-test-report.lisp" *ct-root*) report)
      (unless success (error "Self-test collector fallito; fixture e risultati in ~A" *ct-root*))
      report)))
