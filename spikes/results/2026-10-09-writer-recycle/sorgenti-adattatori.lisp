(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :SOURCES
 ((:PATH #A((45) BASE-CHAR . "spikes/out/recycle-publication-functions.lisp")
   :BYTES 12085 :SHA256
   "361cc520df4c357bae2c02f5442547ddc265e5917cc5f70439b3c039c57791e1" :GIT-BLOB
   "b7cc855848eb79ea61ab2135cae223429fcdf9e2" :TEXT
   ";;;; Adattatore della sola conservazione: definizioni, nessuna pubblicazione al LOAD.
;;;; Copie binarie esclusive; descriptor originale letto separatamente dal decoded.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(in-package #:cl-user)

(defparameter *recycle-publication-directory*
  #p\"spikes/results/2026-10-09-writer-recycle/\")

(defun recycle-leaf-p (name)
  (and (stringp name) (plusp (length name))
       (not (member name '(\".\" \"..\") :test #'string=))
       (not (find-if (lambda (character)
                       (or (zerop (char-code character))
                           (find character \"/\\\\*?[]\"))) name))))

(defun recycle-read-raw-data (path)
  \"Una sola forma originale UTF-8, senza READ-EVAL, prima di qualsiasi decoding.\"
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)) (*read-base* 10)
        (*read-suppress* nil) (eof (gensym \"EOF\")))
    (with-open-file (stream path :direction :input :external-format :utf-8)
      (let* ((data (read stream nil eof)) (size (and (consp data) (list-length data))))
        (unless (and size (evenp size)
                     (loop for key in data by #'cddr always (keywordp key)))
          (error \"Plist originale non valida: ~A\" path))
        (unless (eq eof (read stream nil eof))
          (error \"Più di una forma originale: ~A\" path))
        data))))

(defun recycle-byte-record (path)
  (list :path (namestring (pathname path))
        :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)
        :git-blob
        (string-trim '(#\\Newline #\\Space)
                     (uiop:run-program
                      (list \"git\" \"hash-object\" \"--\" (namestring (pathname path)))
                      :output :string))))

(defun recycle-source-record (path)
  \"Bundle lossless di sorgenti/log UTF-8 con path, bytes, SHA256 e Git blob.\"
  (let* ((before (recycle-byte-record path))
         (text (uiop:read-file-string path :external-format :utf-8))
         (octets (sb-ext:string-to-octets text :external-format :utf-8))
         (after (recycle-byte-record path)))
    (unless (equal before after) (error \"Sorgente cambiata durante la lettura: ~A\" path))
    (unless (= (length octets) (getf before :bytes))
      (error \"Roundtrip UTF-8 con numero di bytes diverso: ~A\" path))
    (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
      (let ((buffer (make-array 65536 :element-type '(unsigned-byte 8))) (position 0))
        (loop for count = (read-sequence buffer stream) until (zerop count)
              do (unless (and (<= (+ position count) (length octets))
                              (loop for i below count
                                    always (= (aref buffer i) (aref octets (+ position i)))))
                   (error \"Roundtrip UTF-8 non lossless: ~A\" path))
                 (incf position count))
        (unless (= position (length octets)) (error \"Sorgente UTF-8 accorciata: ~A\" path))))
    (unless (equal before (recycle-byte-record path))
      (error \"Sorgente cambiata durante la verifica UTF-8: ~A\" path))
    (append before (list :text text))))

(defun recycle-exclusive-output (path)
  \"O_EXCL e NOFOLLOW: non sostituisce un file o symlink già presente.\"
  (let ((fd (sb-posix:open (namestring (pathname path))
                           (logior sb-posix:o-wronly sb-posix:o-creat sb-posix:o-excl
                                   sb-posix:o-nofollow)
                           #o644)))
    (unwind-protect
         (prog1 (sb-sys:make-fd-stream fd :output t :element-type '(unsigned-byte 8)
                                        :auto-close t)
           (setf fd nil))
      (when fd (sb-posix:close fd)))))

(defun recycle-copy-exclusive (source target)
  \"Conserva esattamente i bytes originali e rifiuta destinazioni già esistenti.\"
  (let ((before (recycle-byte-record source))
        (buffer (make-array 65536 :element-type '(unsigned-byte 8))))
    (with-open-file (input source :direction :input :element-type '(unsigned-byte 8))
      (with-open-stream (output (recycle-exclusive-output target))
        (loop for count = (read-sequence buffer input) until (zerop count)
              do (write-sequence buffer output :end count))))
    (let ((after (recycle-byte-record source)) (copy (recycle-byte-record target)))
      (unless (and (equal before after)
                   (= (getf before :bytes) (getf copy :bytes))
                   (string= (getf before :sha256) (getf copy :sha256))
                   (string= (getf before :git-blob) (getf copy :git-blob)))
        (error \"Copia non lossless o sorgente cambiata: ~A -> ~A\" source target))
      copy)))

(defun recycle-stage-data (data directory)
  \"Prevalida dati UTF-8 in un tempfile esclusivo; massimo un MiB plain.
Il tempfile viene preservato se la lettura o l'uguaglianza dei dati fallisce.\"
  (let* ((text (with-output-to-string (stream)
                 (let ((*print-readably* t))
                   (write data :stream stream :pretty t) (terpri stream))))
         (octets (sb-ext:string-to-octets text :external-format :utf-8)))
    (when (> (length octets) 1048576)
      (error \"Dati plain oltre un MiB prima della scrittura: ~D bytes.\" (length octets)))
    (multiple-value-bind (fd name)
        (sb-posix:mkstemp (namestring (merge-pathnames \".recycle-data-XXXXXX\" directory)))
      (let ((path (pathname name)))
        (unwind-protect
             (with-open-stream
                 (stream (prog1 (sb-sys:make-fd-stream fd :output t
                                                      :element-type '(unsigned-byte 8)
                                                      :auto-close t)
                           (setf fd nil)))
               (write-sequence octets stream))
          (when fd (sb-posix:close fd)))
        (unless (equalp data (arcdocdb.evidence:read-evidence path :max-expanded-bytes 1048576))
          (error \"Dati staged diversi dai dati richiesti: ~A\" path))
        path))))

(defun recycle-save-data (data path)
  \"Prevalida bytes/decoded in out, poi copia esclusivamente senza sovrascrivere.\"
  (let ((temporary (recycle-stage-data data #p\"spikes/out/\")))
    (prog1 (recycle-copy-exclusive temporary path)
      (unless (equalp data (arcdocdb.evidence:read-evidence path :max-expanded-bytes 1048576))
        (error \"Dati salvati diversi dai dati richiesti: ~A\" path))
      (delete-file temporary))))

(defun recycle-copy-evidence (source target)
  \"Valida l'originale e il decoded copiato. Il payload conserva il nome originale.\"
  (let* ((decoded (arcdocdb.evidence:read-evidence source))
         (raw (recycle-read-raw-data source))
         (descriptor (eq (getf raw :kind) :compressed-evidence))
         (payload (and descriptor (getf raw :payload)))
         (source-payload (and payload (merge-pathnames
                                      payload (uiop:pathname-directory-pathname source))))
         (target-payload (and payload (merge-pathnames
                                      payload (uiop:pathname-directory-pathname target)))))
    (when (> (arcdocdb.evidence:file-bytes source) 1048576)
      (error \"Originale plain/descriptor oltre un MiB: ~A\" source))
    (when (and source-payload (> (arcdocdb.evidence:file-bytes source-payload) 8388608))
      (error \"Payload gzip oltre otto MiB: ~A\" source-payload))
    (unless (recycle-leaf-p (file-namestring (pathname target)))
      (error \"Destinazione evidence senza nome leaf valido: ~A\" target))
    (when (and payload (not (recycle-leaf-p payload)))
      (error \"Payload descriptor non leaf: ~S\" payload))
    (when (or (probe-file target) (and target-payload (probe-file target-payload)))
      (error \"Destinazione o payload già esistente: ~A\" target))
    ;; Il descriptor diventa visibile soltanto dopo una copia valida del payload.
    (when source-payload (recycle-copy-exclusive source-payload target-payload))
    (let ((copied (recycle-copy-exclusive source target)))
      (unless (and (equalp raw (recycle-read-raw-data target))
                   (equalp raw (recycle-read-raw-data source))
                   (equalp decoded (arcdocdb.evidence:read-evidence source))
                   (equalp decoded (arcdocdb.evidence:read-evidence target)))
        (error \"Originale/descriptor/decoded divergenti dopo copia: ~A -> ~A\" source target))
      (values decoded copied
              (and target-payload (recycle-byte-record target-payload))))))

(defun recycle-copy-process (record stem &key (directory *recycle-publication-directory*))
  \"Copia report e conservazione con nomi flat; nessun overwrite implicito.\"
  (unless (and (recycle-leaf-p record) (recycle-leaf-p stem))
    (error \"Record o stem non leaf: ~S / ~S\" record stem))
  (dolist (part '(\"report\" \"conservazione\"))
    (recycle-copy-evidence
     (format nil \"spikes/out/~A/~A.lisp\" record part)
     (merge-pathnames
      (format nil \"~A~A.lisp\" stem (if (string= part \"report\") \"\" \"-conservazione\"))
      directory))))

(defun recycle-save-source-bundle (paths target kind &key version)
  (recycle-save-data
   (append (list :schema-version 1 :kind kind)
           (when version (list :version version))
           (list :sources (mapcar #'recycle-source-record paths))) target))

(defun recycle-write-catalog (data target)
  \"Sostituisce soltanto il catalogo del componente, dopo staging verificato.\"
  (unless (string= (file-namestring (pathname target)) \"catalogo.lisp\")
    (error \"La sostituzione è consentita soltanto per catalogo.lisp: ~A\" target))
  (let ((previous (and (probe-file target) (arcdocdb.evidence:read-evidence target))))
    (when (and previous
               (not (and (eq (getf previous :kind) :evidence-catalog)
                         (eq (getf previous :component) :writer-recycle))))
      (error \"Catalogo esistente di un altro componente: ~A\" target))
    (let* ((temporary (recycle-stage-data data (uiop:pathname-directory-pathname target)))
           (before (recycle-byte-record temporary)))
      (sb-posix:rename (namestring temporary) (namestring (pathname target)))
      (let ((after (recycle-byte-record target)))
        (unless (and (= (getf before :bytes) (getf after :bytes))
                     (string= (getf before :sha256) (getf after :sha256))
                     (string= (getf before :git-blob) (getf after :git-blob))
                     (equalp data (arcdocdb.evidence:read-evidence target)))
          (error \"Catalogo differente dopo rename verificato: ~A\" target))
        after))))

(defun recycle-refresh-catalog (base &key historical-bases
                                        (directory *recycle-publication-directory*))
  \"Catalogo flat dei dati validati, path originali, hashes e Git blobs dei files.\"
  (let* ((paths (sort (directory (merge-pathnames \"*.lisp\" directory)) #'string<
                      :key #'namestring))
         (entries
           (loop for path in paths
                 unless (string= (file-namestring path) \"catalogo.lisp\")
                 collect
                 (progn
                   (unless (recycle-leaf-p (file-namestring path))
                     (error \"Artifact non flat: ~A\" path))
                   (arcdocdb.evidence:read-evidence path)
                   (let ((raw (recycle-read-raw-data path)))
                     (append (list :artifact (file-namestring path))
                             (recycle-byte-record path)
                             (when (eq (getf raw :kind) :compressed-evidence)
                               (let ((payload (getf raw :payload)))
                                 (list :payload
                                       (append (list :artifact payload)
                                               (recycle-byte-record
                                                (merge-pathnames payload directory))))))))))))
    (recycle-write-catalog
     (list :schema-version 1 :kind :evidence-catalog :component :writer-recycle
           :base base :historical-bases historical-bases :entries entries)
     (merge-pathnames \"catalogo.lisp\" directory))))
")
  (:PATH #A((39) BASE-CHAR . "spikes/out/recycle-refresh-catalog.lisp") :BYTES
   266 :SHA256
   "dc5ae98c7d7ccbfb49ef59b8b36e821c468322e3a91f9d93e07f61d46c82b325" :GIT-BLOB
   "bd96a96ced5b49b62b12bb153cb8246efd702055" :TEXT
   ";;;; Definizioni soltanto: la base e l'istante finale vengono scelti dal root.
(load \"spikes/out/recycle-publication-functions.lisp\")
(defun recycle-final-catalog (base &optional historical-bases)
  (recycle-refresh-catalog base :historical-bases historical-bases))
")
  (:PATH #A((31) BASE-CHAR . "spikes/out/recycle-publish.lisp") :BYTES 7943
   :SHA256 "2a7fac8d939613189e903d7c06a1ffbec9849773ea0c379ca0b98cbcd5c79af3"
   :GIT-BLOB "8f6c8a57ba0eeb6160b81b29178e39e28ca8b34c" :TEXT
   ";;;; Manifest/driver della pubblicazione: LOAD definisce, non pubblica.
;;;; Root chiama RECYCLE-RUN-PUBLICATION soltanto dopo la copia dei report C1.
(load \"spikes/out/recycle-publication-functions.lisp\")

(defparameter *recycle-process-manifest*
  '((\"4000528494-command-77199-0\" \"check-finale-processo\")
    (\"4000528494-command-77200-0\" \"copertura-processo\")
    (\"4000528526-command-77598-0\" \"copertura-export-processo\")
    (\"4000528631-command-78868-0\" \"probe-root-processo\")
    (\"4000528528-command-77652-0\" \"bench-self-test-processo\")
    (\"4000528528-command-77653-0\" \"mutazioni-self-test-processo\")
    (\"4000528603-command-78553-0\" \"mutazioni-processo\")
    (\"4000528603-command-78552-0\" \"allocazioni-processo\")
    (\"4000528866-command-80492-0\" \"revisione-autore-processo\")
    (\"4000528942-command-81018-0\" \"revisione-probe-native-fallito-processo\")
    (\"4000528971-command-81260-0\" \"revisione-probe-processo\")))

(defparameter *recycle-data-manifest*
  '((\"spikes/out/recycle-coverage-export.lisp\" \"copertura-grezza.lisp\")
    (\"spikes/out/recycle-mutations/report.lisp\" \"mutazioni-dati.lisp\")
    (\"spikes/out/recycle-allocations/report.lisp\" \"allocazioni-dati.lisp\")
    (\"spikes/out/4000528529-recycle-signal-self-test-77690/report.lisp\" \"segnale-os-dati.lisp\")
    (\"spikes/out/4000528568-check-78100-0/report.lisp\" \"spikes-finali.lisp\")
    (\"spikes/out/4000528568-check-78100-0/conservazione.lisp\" \"spikes-finali-conservazione.lisp\")))

(defparameter *recycle-adapter-manifest*
  '(\"spikes/out/recycle-publication-functions.lisp\"
    \"spikes/out/recycle-refresh-catalog.lisp\"
    \"spikes/out/recycle-publish.lisp\"
    \"spikes/out/recycle-tool-self-test.lisp\"
    \"spikes/out/recycle-tool-campaign.lisp\"
    \"spikes/out/recycle-export-coverage.lisp\"
    \"spikes/out/recycle-root-summary.lisp\"
    \"spikes/out/recycle-author-review.lisp\"
    \"spikes/out/recycle-review-audit-native-reader-failed.lisp\"
    \"spikes/out/recycle-review-audit.lisp\"
    \"spikes/out/recycle-review-html.py\"
    \"arcdocdb.asd\"
    \"src/execution/package.lisp\"
    \"src/execution/queue.lisp\"
    \"src/execution/writer.lisp\"
    \"src/execution/handoff.lisp\"
    \"src/execution/ready-types.lisp\"
    \"src/execution/ready.lisp\"
    \"src/execution/ready-recycle.lisp\"
    \"tests/execution/support.lisp\"
    \"tests/execution/handoff.lisp\"
    \"tests/execution/ready.lisp\"
    \"tests/execution/ready-recycle.lisp\"
    \"tools/writer-recycle-bench.lisp\"
    \"tools/writer-recycle-mutation.lisp\"
    \"tools/build.lisp\"
    \"docs/implementazione/writer-recycle-metodo.md\"))

(defparameter *recycle-review-manifest*
  '((\"spikes/out/recycle-c1-initial.lisp\" \"revisione-indipendente-iniziale.lisp\")
    (\"spikes/out/recycle-c1-final.lisp\" \"revisione-indipendente-finale.lisp\")
    (\"spikes/out/recycle-author-review-data.lisp\" \"revisione-autore.lisp\")))

(defun recycle-publication-target (leaf)
  (unless (recycle-leaf-p leaf) (error \"Target non flat: ~S\" leaf))
  (merge-pathnames leaf *recycle-publication-directory*))

(defun recycle-publication-pairs (review-records extra-processes)
  \"Coppie source/target, compresi i record processuali report+conservazione.\"
  (append
   (loop for (record stem) in (append *recycle-process-manifest* extra-processes)
         append
         (loop for part in '(\"report\" \"conservazione\")
               collect (list (format nil \"spikes/out/~A/~A.lisp\" record part)
                             (format nil \"~A~A.lisp\" stem
                                     (if (string= part \"report\") \"\" \"-conservazione\")))))
   *recycle-data-manifest* review-records))

(defun recycle-coverage-source-paths ()
  (let ((html (sort (directory \"spikes/out/recycle-coverage/*.html\") #'string<
                    :key #'namestring)))
    (unless (= 8 (length html)) (error \"Copertura HTML: richiesti indice e sette file.\"))
    (cons \"spikes/out/recycle-coverage/coverage-state.lisp\"
          (mapcar #'namestring html))))

(defun recycle-mutation-log-paths ()
  (let* ((data (arcdocdb.evidence:read-evidence \"spikes/out/recycle-mutations/report.lisp\"))
         (paths (cons (getf data :baseline-log)
                      (mapcar (lambda (entry) (getf entry :log)) (getf data :mutants)))))
    (unless (and (= 12 (length paths))
                 (= 12 (length (remove-duplicates paths :test #'equal))))
      (error \"Mutazioni: richiesti baseline e undici log distinti.\"))
    paths))

(defun recycle-preflight-publication (pairs bundle-paths)
  \"Valida tutti gli originali e le collisioni di nomi prima di creare i target.\"
  (let ((targets nil) (payloads nil))
    (dolist (pair pairs)
      (let* ((source (first pair)) (leaf (second pair))
             (target (recycle-publication-target leaf))
             (raw (progn (arcdocdb.evidence:read-evidence source)
                         (recycle-read-raw-data source))))
        (when (or (member leaf targets :test #'string=) (probe-file target))
          (error \"Artifact già esistente o ripetuto: ~A\" target))
        (push leaf targets)
        (when (eq (getf raw :kind) :compressed-evidence)
          (let ((payload (getf raw :payload)))
            (unless (recycle-leaf-p payload) (error \"Payload non leaf: ~S\" payload))
            (when (or (member payload payloads :test #'string=)
                      (probe-file (recycle-publication-target payload)))
              (error \"Collisione payload preservato: ~S\" payload))
            (push payload payloads)))))
    (dolist (leaf '(\"mutazioni-log.lisp\" \"copertura-native-html.lisp\"
                    \"segnale-os-originali.lisp\" \"sorgenti-adattatori.lisp\"))
      (when (or (member leaf targets :test #'string=)
                (member leaf payloads :test #'string=)
                (probe-file (recycle-publication-target leaf)))
        (error \"Bundle già esistente o in conflitto: ~S\" leaf))
      (push leaf targets))
    (when (intersection targets payloads :test #'string=)
      (error \"Un payload collide con un artifact.\"))
    (dolist (path bundle-paths) (recycle-source-record path))
    t))

(defun recycle-run-publication (&key (review-records *recycle-review-manifest*)
                                    extra-processes adapter-sources)
  \"Pubblica il manifest finale esplicito. Il catalogo viene chiuso dal root dopo
aver copiato anche il record di questo processo; il LOAD da solo non pubblica.\"
  (unless review-records (error \"Manifest dei report C1 non ancora fornito dal root.\"))
  (let* ((pairs (recycle-publication-pairs review-records extra-processes))
         (logs (recycle-mutation-log-paths)) (coverage (recycle-coverage-source-paths))
         (signal '(\"spikes/out/4000528529-recycle-signal-self-test-77690/test.log\"
                   \"spikes/out/4000528529-recycle-signal-self-test-77690/tools/writer-recycle-isolated-build.lisp\"))
         (adapters (append *recycle-adapter-manifest* adapter-sources)))
    (recycle-preflight-publication pairs (append logs coverage signal adapters))
    (ensure-directories-exist (recycle-publication-target \"catalogo.lisp\"))
    (dolist (pair pairs)
      (recycle-copy-evidence (first pair) (recycle-publication-target (second pair))))
    (recycle-save-source-bundle logs (recycle-publication-target \"mutazioni-log.lisp\")
                                :raw-mutation-logs)
    (recycle-save-source-bundle coverage (recycle-publication-target \"copertura-native-html.lisp\")
                                :raw-coverage-native-and-html :version :seven-execution-files)
    (recycle-save-source-bundle signal (recycle-publication-target \"segnale-os-originali.lisp\")
                                :process-signal-raw-sources)
    (recycle-save-source-bundle adapters (recycle-publication-target \"sorgenti-adattatori.lisp\")
                                :verification-adapter-sources)
    (format t \"Manifest pubblicato: ~D coppie, ~D log, native e 8 HTML; copie lossless validate.~%\"
            (length pairs) (length logs))
    t))
")
  (:PATH #A((38) BASE-CHAR . "spikes/out/recycle-tool-self-test.lisp") :BYTES
   1619 :SHA256
   "9a6f493cca71cc130288ccf7353bb0ca2b0dc8dfbe06faf1413b0349582e77de" :GIT-BLOB
   "58ef4069533c8b7c6edf530eaa53bb235cf42671" :TEXT
   ";;;; C4: compile the entire selected tool; execute its FASL self-test, isolated cache.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((mode (first (uiop:command-line-arguments)))
       (source (cond ((equal mode \"bench\") \"tools/writer-recycle-bench.lisp\")
                     ((equal mode \"mutation\") \"tools/writer-recycle-mutation.lisp\")
                     (t (error \"Mode must be bench or mutation.\"))))
       (cache (merge-pathnames (format nil \"spikes/out/recycle-~A-asdf-cache/\" mode)
                               (truename \"./\")))
       (fasl (merge-pathnames (format nil \"spikes/out/recycle-~A-fasl/tool.fasl\" mode)
                              (truename \"./\"))))
  (ensure-directories-exist fasl)
  (asdf:initialize-output-translations
   (list :output-translations (list t cache) :ignore-inherited-configuration))
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error)
  (handler-bind ((warning (lambda (condition)
                           (unless (typep condition 'sb-kernel:redefinition-warning)
                             (error \"~A non ammesso (COD-01): ~A\"
                                    (type-of condition) condition)))))
    (multiple-value-bind (output warnings failure) (compile-file source :output-file fasl)
      (when (or warnings failure (null output))
        (error \"Strict COMPILE-FILE failed: ~S ~S ~S.\" output warnings failure))
      (setf sb-ext:*posix-argv* (list (first sb-ext:*posix-argv*) \"--self-test\"))
      (load output)))
  (format t \"~&RECYCLE-TOOL-STRICT-SELF-TEST-PASS ~A ~A~%\" mode source))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/recycle-tool-campaign.lisp") :BYTES
   1181 :SHA256
   "a2daa8a274e7d6a297f6f0a5aa68a11241add36d4f9ebd023ca8fdecbe9e30e2" :GIT-BLOB
   "703540deafbed88d6d57ae8bb3804c9ae89717cb" :TEXT
   ";;;; C4: execute already strictly compiled selected tool with a private campaign cache.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((args (uiop:command-line-arguments))
       (mode (first args))
       (cache (merge-pathnames (format nil \"spikes/out/recycle-~A-campaign-cache/\" mode)
                               (truename \"./\")))
       (fasl (merge-pathnames (format nil \"spikes/out/recycle-~A-fasl/tool.fasl\" mode)
                              (truename \"./\"))))
  (unless (member mode '(\"bench\" \"mutation\") :test #'equal)
    (error \"Mode must be bench or mutation.\"))
  (asdf:initialize-output-translations
   (list :output-translations (list t cache) :ignore-inherited-configuration))
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error
        sb-ext:*posix-argv* (cons (first sb-ext:*posix-argv*) (rest args)))
  (handler-bind ((warning (lambda (condition)
                           (unless (typep condition 'sb-kernel:redefinition-warning)
                             (error \"~A non ammesso (COD-01): ~A\"
                                    (type-of condition) condition)))))
    (load fasl)))
")
  (:PATH #A((39) BASE-CHAR . "spikes/out/recycle-export-coverage.lisp") :BYTES
   3058 :SHA256
   "9a1ab363dd82268c9ca2dea728280b0d1c4a7211b2a635afc0f8f28b1acb4112" :GIT-BLOB
   "2d01a0d5ebad8bdebcd288a53b35c8a7b04aeaf3" :TEXT "(require :asdf)
(defun coverage-counts (record)
  (let ((events (second record)) (bits (cddr record))
        (expressions 0) (covered 0) (branches 0) (covered-branches 0) (missing nil))
    (unless (and (vectorp events) (typep bits 'bit-vector) (= (length events) (length bits)))
      (error \"COD-60: eventi/bit non corrispondono.\"))
    (dotimes (i (length events))
      (let* ((event (aref events i)) (branch (member (first event) '(:then :else))))
        (if branch
            (progn (incf branches) (incf covered-branches (bit bits i)))
            (progn (incf expressions) (incf covered (bit bits i))))
        (when (zerop (bit bits i))
          (push (list :kind (if branch :branch :expression) :path event) missing))))
    (list :expressions covered :expression-total expressions :branches covered-branches
          :branch-total branches :missing (nreverse missing))))
(let ((fixture (list* \"fixture\" #((0) (:then 1) (:else 1) (2)) #*1100)))
  (let ((r (coverage-counts fixture)))
    (unless (and (= 1 (getf r :expressions)) (= 2 (getf r :expression-total))
                 (= 1 (getf r :branches)) (= 2 (getf r :branch-total))
                 (= 2 (length (getf r :missing))))
      (error \"COD-60: self-test del denominatore fallito.\")))
  (unless (handler-case (progn (coverage-counts (list* \"bad\" #((0)) #*00)) nil)
            (error () t))
    (error \"COD-60: forma incoerente non rifiutata.\")))
(let* ((*read-eval* nil)
       (path \"spikes/out/recycle-coverage/coverage-state.lisp\")
       (native (with-open-file (input path) (read input)))
       (records (remove-if-not (lambda (entry) (search \"/src/execution/\" (first entry))) native))
       (counts (mapcar (lambda (entry) (list :file (file-namestring (first entry))
                                            :counts (coverage-counts entry))) records))
       (report (list :schema-version 1 :kind :raw-coverage-export :scope :execution
                     :self-test :passed :source-format :sb-cover-native
                     :native (list :source-path path :git-blob
                                   (string-trim '(#\\Newline #\\Space)
                                                (uiop:run-program (list \"git\" \"hash-object\" \"--\" path) :output :string))
                                   :text (uiop:read-file-string path))
                     :html-index (uiop:read-file-string \"spikes/out/recycle-coverage/cover-index.html\")
                     :counts counts :limits '(:raw-denominator :no-exclusions :not-mcdc))))
  (unless (= 7 (length records)) (error \"COD-60: scope execution incompleto.\"))
  (with-open-file (output \"spikes/out/recycle-coverage-export.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (dolist (entry counts)
    (let ((r (getf entry :counts)))
      (format t \"~A: ~D/~D espressioni, ~D/~D esiti di ramo.~%\"
              (getf entry :file) (getf r :expressions) (getf r :expression-total)
              (getf r :branches) (getf r :branch-total)))))
")
  (:PATH #A((36) BASE-CHAR . "spikes/out/recycle-root-summary.lisp") :BYTES 850
   :SHA256 "a788061f96fcdd1239b0e77b05ac7b5ccf12e405fd8b7613ab782cd00e2ecaeb"
   :GIT-BLOB "e9391a03c2d89cb6117e960727577599cef692fd" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let ((r (arcdocdb.evidence:read-evidence \"spikes/out/4000528494-command-77199-0/report.lisp\")))
 (format t \"CHECK ~S ~S exit~S~%\" (getf r :status) (getf r :source-consistency) (getf r :exit-code))
 (dolist (line (uiop:split-string (getf r :stdout) :separator '(#\\Newline)))
  (when (or (search \"test superati\" line) (search \"violazioni\" line) (search \"SPK-\" line)
            (search \"superato\" line) (search \"Rapporto completo\" line))
   (write-line line))))
(let* ((*read-eval* nil) (r (with-open-file (in \"spikes/out/recycle-coverage-export.lisp\") (read in))))
 (dolist (entry (getf r :counts))
  (let ((c (getf entry :counts)))
   (format t \"~A ~D/~D expr ~D/~D branches~%\" (getf entry :file) (getf c :expressions)
    (getf c :expression-total) (getf c :branches) (getf c :branch-total)))))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/recycle-author-review.lisp") :BYTES
   1534 :SHA256
   "fe9705ae5319f9ab1ec3a20fa469c5d8557bc296c6d1a21e716ce534bb41cd3c" :GIT-BLOB
   "e492549cda61bae3cd2f6385b4abdfb06c4463d7" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((source \"src/execution/ready-recycle.lisp\")
       (review \"docs/implementazione/writer-recycle-revisione.md\")
       (text (uiop:read-file-string review))
       (points (remove-if-not (lambda (line)
                 (and (> (length line) 2) (char= #\\| (char line 0))
                      (digit-char-p (char line 2))))
                 (uiop:split-string text :separator '(#\\Newline)))))
  (unless (= 12 (length points)) (error \"C1: checklist autore incompleta.\"))
  (let ((record (list :schema-version 1 :kind :c1-author-review :scope :writer-recycle
                :source source :source-git-blob
                (string-trim '(#\\Space #\\Newline) (uiop:run-program
                   (list \"git\" \"hash-object\" \"--\" source) :output :string))
                :source-text (uiop:read-file-string source) :checklist points :review-text text
                :verification-record \"4000528494-command-77199-0\" :tests 309 :execution-tests 66
                :mutation-record \"4000528603-command-78553-0\" :detected 11
                :allocation-record \"4000528603-command-78552-0\" :samples 20
                :limits '(:local-component :no-mcdc :no-approved-exclusions :no-full-engine-qualification))))
   (with-open-file (out \"spikes/out/recycle-author-review-data.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write record :stream out :pretty t) (terpri out)))
   (format t \"C1 autore: 12 punti, sorgente congelato, rapporti completati.~%\")))
")
  (:PATH
   #A((57) BASE-CHAR
      . "spikes/out/recycle-review-audit-native-reader-failed.lisp")
   :BYTES 8030 :SHA256
   "400e04e9e6956ebc65c45a30e62e57573502927b81a50d44296463f27c33004c" :GIT-BLOB
   "ac8a21a1c8259a44c34d6f55884343ee0bf4b9e1" :TEXT
   ";;;; Probe indipendente di dati già congelati: non campagna di prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil *print-pretty* nil)
(defun read-data (path) (arcdocdb.evidence:read-evidence path))
(defun text-data (path) (uiop:read-file-string path :external-format :utf-8))
(defun line-prefix-p (prefix line) (uiop:string-prefix-p prefix line))
(defun event-lines (prefix text)
  (remove-if-not (lambda (line) (line-prefix-p prefix line))
                 (uiop:split-string text :separator '(#\\Newline))))
(defun pairs (raw keys)
  (loop for key in keys append (list key (getf raw key))))
(defun native-counts ()
  (let ((raw (read-data \"spikes/out/recycle-coverage/coverage-state.lisp\")) (rows nil))
    (dolist (entry raw)
      (when (search \"/src/execution/\" (car entry))
        (let ((eh 0) (et 0) (bh 0) (bt 0) (me nil) (mb nil))
          (assert (= (length (cadr entry)) (length (cddr entry))))
          (loop for path across (cadr entry) for bit across (cddr entry)
                do (if (member (car path) '(:then :else))
                       (progn (incf bt) (if (= bit 1) (incf bh) (push path mb)))
                       (progn (incf et) (if (= bit 1) (incf eh) (push path me)))))
          (push (list :file (file-namestring (car entry))
                      :expressions-hit eh :expressions-total et :branches-hit bh :branches-total bt
                      :missing-expressions (nreverse me) :missing-branches (nreverse mb)) rows))))
    (sort rows #'string< :key (lambda (row) (getf row :file)))))
(let* ((rows (native-counts))
       (html (read-from-string
               (uiop:run-program '(\"python3\" \"spikes/out/recycle-review-html.py\"
                                   \"spikes/out/recycle-coverage/cover-index.html\") :output :string)))
       (counts (mapcar (lambda (row)
                         (list (getf row :file) (getf row :expressions-hit) (getf row :expressions-total)
                               (getf row :branches-hit) (getf row :branches-total))) rows))
       (total (loop for column from 1 to 4 collect (loop for row in counts sum (nth column row)))))
  (assert (= (length rows) 7)) (assert (equal counts html))
  (format t \"~&~S~%\" (list :coverage-independent :native-vs-html :equal :files rows :total total)))
(dolist (id '(\"4000528494-command-77200-0\" \"4000528526-command-77598-0\"
              \"4000528528-command-77652-0\" \"4000528528-command-77653-0\"
              \"4000528603-command-78553-0\" \"4000528603-command-78552-0\"
              \"4000528494-command-77199-0\"))
  (let* ((raw (read-data (format nil \"spikes/out/~A/report.lisp\" id)))
         (stdout (getf raw :stdout)) (stderr (getf raw :stderr)))
    (assert (eq (getf raw :status) :ok))
    (assert (eq (getf raw :source-consistency) :stable))
    (assert (eql (getf raw :exit-code) 0))
    (format t \"~&~S~%\" (append (list :process id)
                            (pairs raw '(:status :source-consistency :exit-code :wall-seconds))
                            (list :stdout-lines
                                  (remove-if-not
                                    (lambda (line)
                                      (some (lambda (token) (search token line))
                                            '(\"test superati\" \"file, \" \"REQ\" \"link\" \"nessun avviso\")))
                                    (uiop:split-string stdout :separator '(#\\Newline)))
                                  :warning-lines
                                  (remove-if-not
                                    (lambda (line) (or (line-prefix-p \"WARNING:\" line)
                                                      (line-prefix-p \"; caught WARNING:\" line)
                                                      (line-prefix-p \"; caught STYLE-WARNING:\" line)))
                                    (uiop:split-string stderr :separator '(#\\Newline))))))))
(let ((raw (read-data \"spikes/out/recycle-mutations/report.lisp\")))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (getf raw :detected) 11))
  (assert (every #'zerop (mapcar (lambda (key) (getf raw key))
                               '(:survived :compilation-failures :before-tests :worker-errors))))
  (format t \"~&~S~%\" (append '(:mutations) (pairs raw '(:status :source-consistency :planned-mutants
                               :baseline :baseline-exit-code :baseline-signal :detected :survived
                               :compilation-failures :before-tests :worker-errors))))
  (dolist (entry (cons (list :name \"baseline\" :log (getf raw :baseline-log)) (getf raw :mutants)))
    (let* ((text (text-data (getf entry :log)))
           (starts (event-lines \"execution-test-start \" text))
           (oks (event-lines \"ok    TEST-\" text))
           (complete (event-lines \"execution-tests-complete \" text))
           (baseline (string= (getf entry :name) \"baseline\")))
      (if baseline
          (progn (assert (= (length starts) 66)) (assert (= (length oks) 66))
                 (assert (equal complete '(\"execution-tests-complete 66\"))))
          (progn (assert (eq (getf entry :result) :detected))
                 (assert (= (getf entry :exit-code) 1)) (assert (null (getf entry :signal)))
                 (assert (null complete)) (assert (some (lambda (s) (search \"-RECYCLE-\" s)) starts))))
      (format t \"~&~S~%\" (list :log (getf entry :name) :sha256 (arcdocdb.evidence:file-sha256 (getf entry :log))
                              :starts (length starts) :oks (length oks) :last-start (car (last starts))
                              :complete complete :exit (getf entry :exit-code) :signal (getf entry :signal))))))
(let* ((raw (read-data \"spikes/out/recycle-allocations/report.lisp\"))
       (self (getf raw :self-test)) (campaigns (getf raw :campaigns)))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (length campaigns) 4))
  (assert (= (getf (getf self :positive-control) :heap-bytes) 16777472))
  (assert (eq (getf self :wrong-sink) :rejected))
  (format t \"~&~S~%\" (list :benchmark-controls :status (getf self :status)
                          :positive-heap (getf (getf self :positive-control) :heap-bytes)
                          :wrong-sink (getf self :wrong-sink) :self-test-keys (loop for (k v) on self by #'cddr collect k)))
  (dolist (campaign campaigns)
    (let* ((k (getf campaign :shards)) (c (getf campaign :capacity-per-shard)) (m (* k (1+ c)))
           (token (+ (* 74 m) (* 5 m (1+ m)) (* k (+ (* 31 c) (/ (* 3 c (1+ c)) 2) 13 (* 3 c)))
                     (/ (* 7 c k (1- k)) 2) 29))
           (expected-sink (+ (* 4096 token) (/ (* 4096 4095) 2)))
           (samples (getf campaign :samples)))
      (assert (= token (getf campaign :expected-token))) (assert (= (length samples) 5))
      (dolist (sample samples)
        (assert (eq (getf sample :status) :ok)) (assert (zerop (getf sample :heap-bytes)))
        (assert (= (getf sample :completed-iterations) 4096))
        (assert (= expected-sink (getf sample :sink) (getf sample :expected-sink))))
      (format t \"~&~S~%\" (list :benchmark :shards k :capacity c :independent-token token
                              :independent-sink expected-sink :sample-count 5
                              :heap-bytes (mapcar (lambda (s) (getf s :heap-bytes)) samples))))))
(let ((raw (read-data \"spikes/out/4000528529-recycle-signal-self-test-77690/report.lisp\")))
  (format t \"~&~S~%\" (append '(:signal-fixture) (pairs raw '(:status :source-consistency :detected :worker-errors :mutants)))))
(let ((raw (read-data \"spikes/out/4000528568-check-78100-0/report.lisp\")))
  (assert (eq (getf raw :status) :complete)) (assert (= (length (getf raw :runs)) 10))
  (format t \"~&~S~%\" (list :spikes :status (getf raw :status) :run-count (length (getf raw :runs))
                          :artifact-count (length (getf raw :run-artifacts))
                          :run-keys (loop for (k v) on (first (getf raw :runs)) by #'cddr collect k))))
")
  (:PATH #A((36) BASE-CHAR . "spikes/out/recycle-review-audit.lisp") :BYTES
   8103 :SHA256
   "d62b93d5f2b7f6be111bfacf9101577fbbf50dc7840b8a5723883a9a3b09f56e" :GIT-BLOB
   "8baee6fb37d59e34ddd9bd4509aa7719bb01be39" :TEXT
   ";;;; Probe indipendente di dati già congelati: non campagna di prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil *print-pretty* nil)
(defun read-data (path) (arcdocdb.evidence:read-evidence path))
(defun text-data (path) (uiop:read-file-string path :external-format :utf-8))
(defun line-prefix-p (prefix line) (uiop:string-prefix-p prefix line))
(defun event-lines (prefix text)
  (remove-if-not (lambda (line) (line-prefix-p prefix line))
                 (uiop:split-string text :separator '(#\\Newline))))
(defun pairs (raw keys)
  (loop for key in keys append (list key (getf raw key))))
(defun native-counts ()
  (let ((raw (with-open-file (s \"spikes/out/recycle-coverage/coverage-state.lisp\"
                               :external-format :utf-8) (read s))) (rows nil))
    (dolist (entry raw)
      (when (search \"/src/execution/\" (car entry))
        (let ((eh 0) (et 0) (bh 0) (bt 0) (me nil) (mb nil))
          (assert (= (length (cadr entry)) (length (cddr entry))))
          (loop for path across (cadr entry) for bit across (cddr entry)
                do (if (member (car path) '(:then :else))
                       (progn (incf bt) (if (= bit 1) (incf bh) (push path mb)))
                       (progn (incf et) (if (= bit 1) (incf eh) (push path me)))))
          (push (list :file (file-namestring (car entry))
                      :expressions-hit eh :expressions-total et :branches-hit bh :branches-total bt
                      :missing-expressions (nreverse me) :missing-branches (nreverse mb)) rows))))
    (sort rows #'string< :key (lambda (row) (getf row :file)))))
(let* ((rows (native-counts))
       (html (read-from-string
               (uiop:run-program '(\"python3\" \"spikes/out/recycle-review-html.py\"
                                   \"spikes/out/recycle-coverage/cover-index.html\") :output :string)))
       (counts (mapcar (lambda (row)
                         (list (getf row :file) (getf row :expressions-hit) (getf row :expressions-total)
                               (getf row :branches-hit) (getf row :branches-total))) rows))
       (total (loop for column from 1 to 4 collect (loop for row in counts sum (nth column row)))))
  (assert (= (length rows) 7)) (assert (equal counts html))
  (format t \"~&~S~%\" (list :coverage-independent :native-vs-html :equal :files rows :total total)))
(dolist (id '(\"4000528494-command-77200-0\" \"4000528526-command-77598-0\"
              \"4000528528-command-77652-0\" \"4000528528-command-77653-0\"
              \"4000528603-command-78553-0\" \"4000528603-command-78552-0\"
              \"4000528494-command-77199-0\"))
  (let* ((raw (read-data (format nil \"spikes/out/~A/report.lisp\" id)))
         (stdout (getf raw :stdout)) (stderr (getf raw :stderr)))
    (assert (eq (getf raw :status) :ok))
    (assert (eq (getf raw :source-consistency) :stable))
    (assert (eql (getf raw :exit-code) 0))
    (format t \"~&~S~%\" (append (list :process id)
                            (pairs raw '(:status :source-consistency :exit-code :wall-seconds))
                            (list :stdout-lines
                                  (remove-if-not
                                    (lambda (line)
                                      (some (lambda (token) (search token line))
                                            '(\"test superati\" \"file, \" \"REQ\" \"link\" \"nessun avviso\")))
                                    (uiop:split-string stdout :separator '(#\\Newline)))
                                  :warning-lines
                                  (remove-if-not
                                    (lambda (line) (or (line-prefix-p \"WARNING:\" line)
                                                      (line-prefix-p \"; caught WARNING:\" line)
                                                      (line-prefix-p \"; caught STYLE-WARNING:\" line)))
                                    (uiop:split-string stderr :separator '(#\\Newline))))))))
(let ((raw (read-data \"spikes/out/recycle-mutations/report.lisp\")))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (getf raw :detected) 11))
  (assert (every #'zerop (mapcar (lambda (key) (getf raw key))
                               '(:survived :compilation-failures :before-tests :worker-errors))))
  (format t \"~&~S~%\" (append '(:mutations) (pairs raw '(:status :source-consistency :planned-mutants
                               :baseline :baseline-exit-code :baseline-signal :detected :survived
                               :compilation-failures :before-tests :worker-errors))))
  (dolist (entry (cons (list :name \"baseline\" :log (getf raw :baseline-log)) (getf raw :mutants)))
    (let* ((text (text-data (getf entry :log)))
           (starts (event-lines \"execution-test-start \" text))
           (oks (event-lines \"ok    TEST-\" text))
           (complete (event-lines \"execution-tests-complete \" text))
           (baseline (string= (getf entry :name) \"baseline\")))
      (if baseline
          (progn (assert (= (length starts) 66)) (assert (= (length oks) 66))
                 (assert (equal complete '(\"execution-tests-complete 66\"))))
          (progn (assert (eq (getf entry :result) :detected))
                 (assert (= (getf entry :exit-code) 1)) (assert (null (getf entry :signal)))
                 (assert (null complete)) (assert (some (lambda (s) (search \"-RECYCLE-\" s)) starts))))
      (format t \"~&~S~%\" (list :log (getf entry :name) :sha256 (arcdocdb.evidence:file-sha256 (getf entry :log))
                              :starts (length starts) :oks (length oks) :last-start (car (last starts))
                              :complete complete :exit (getf entry :exit-code) :signal (getf entry :signal))))))
(let* ((raw (read-data \"spikes/out/recycle-allocations/report.lisp\"))
       (self (getf raw :self-test)) (campaigns (getf raw :campaigns)))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (length campaigns) 4))
  (assert (= (getf (getf self :positive-control) :heap-bytes) 16777472))
  (assert (eq (getf self :wrong-sink) :rejected))
  (format t \"~&~S~%\" (list :benchmark-controls :status (getf self :status)
                          :positive-heap (getf (getf self :positive-control) :heap-bytes)
                          :wrong-sink (getf self :wrong-sink) :self-test-keys (loop for (k v) on self by #'cddr collect k)))
  (dolist (campaign campaigns)
    (let* ((k (getf campaign :shards)) (c (getf campaign :capacity-per-shard)) (m (* k (1+ c)))
           (token (+ (* 74 m) (* 5 m (1+ m)) (* k (+ (* 31 c) (/ (* 3 c (1+ c)) 2) 13 (* 3 c)))
                     (/ (* 7 c k (1- k)) 2) 29))
           (expected-sink (+ (* 4096 token) (/ (* 4096 4095) 2)))
           (samples (getf campaign :samples)))
      (assert (= token (getf campaign :expected-token))) (assert (= (length samples) 5))
      (dolist (sample samples)
        (assert (eq (getf sample :status) :ok)) (assert (zerop (getf sample :heap-bytes)))
        (assert (= (getf sample :completed-iterations) 4096))
        (assert (= expected-sink (getf sample :sink) (getf sample :expected-sink))))
      (format t \"~&~S~%\" (list :benchmark :shards k :capacity c :independent-token token
                              :independent-sink expected-sink :sample-count 5
                              :heap-bytes (mapcar (lambda (s) (getf s :heap-bytes)) samples))))))
(let ((raw (read-data \"spikes/out/4000528529-recycle-signal-self-test-77690/report.lisp\")))
  (format t \"~&~S~%\" (append '(:signal-fixture) (pairs raw '(:status :source-consistency :detected :worker-errors :mutants)))))
(let ((raw (read-data \"spikes/out/4000528568-check-78100-0/report.lisp\")))
  (assert (eq (getf raw :status) :complete)) (assert (= (length (getf raw :runs)) 10))
  (format t \"~&~S~%\" (list :spikes :status (getf raw :status) :run-count (length (getf raw :runs))
                          :artifact-count (length (getf raw :run-artifacts))
                          :run-keys (loop for (k v) on (first (getf raw :runs)) by #'cddr collect k))))
")
  (:PATH #A((33) BASE-CHAR . "spikes/out/recycle-review-html.py") :BYTES 1012
   :SHA256 "30c7fbc104f4b14462c231e80b362697e6d97e7de56b7c35654e328fb0bfc5af"
   :GIT-BLOB "668f266c486dbf8f28a94138be7ed011830861fb" :TEXT
   "from html.parser import HTMLParser
from pathlib import Path
import sys

class Summary(HTMLParser):
    def __init__(self):
        super().__init__()
        self.cells = []
        self.cell = None
        self.rows = []
    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.cells = []
        if tag == 'td':
            self.cell = []
    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)
    def handle_endtag(self, tag):
        if tag == 'td' and self.cell is not None:
            self.cells.append(''.join(self.cell).strip())
            self.cell = None
        if tag == 'tr' and len(self.cells) == 7 and self.cells[0].endswith('.lisp'):
            self.rows.append((self.cells[0], *(int(self.cells[i]) for i in (1, 2, 4, 5))))

parser = Summary()
parser.feed(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert len(parser.rows) == 7
print('(' + ' '.join('(\"%s\" %d %d %d %d)' % row for row in sorted(parser.rows)) + ')')
")
  (:PATH #A((12) BASE-CHAR . "arcdocdb.asd") :BYTES 5275 :SHA256
   "80f4d352a7bd78a705c14ec1de7a9268a993d852f85938a4a09a2e4443e4008a" :GIT-BLOB
   "4eebbed2c004f39d4eccba4cb1d8e5a08ea7d45a" :TEXT
   ";;;; arcdocdb.asd — definizione di sistema ASDF.
;;;;
;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.

(in-package #:asdf-user)

(defsystem \"arcdocdb\"
  :description \"Database server documentale general-purpose, append-only, in Common Lisp (SBCL).\"
  :author \"Giacomo Picchiarelli\"
  :license \"BSD-2-Clause\"
  :version \"0.0.0\"
  :pathname \"src/\"
  :serial t
  :depends-on (\"sb-posix\")
  :components ((:file \"package\")
               (:module \"foundation\"
                :serial t
                :components ((:file \"package\") (:file \"conditions\")
                             (:file \"binary\") (:file \"crc32c\")
                             (:file \"record\") (:file \"batch\")))
               (:module \"codec\" :serial t
                :components ((:file \"package\") (:file \"utf8\")
                             (:file \"cbor-package\") (:file \"cbor-header\")))
               (:module \"csn\" :serial t
                :components ((:file \"package\") (:file \"registry\")))
               (:module \"execution\" :serial t
                :components ((:file \"package\") (:file \"queue\") (:file \"writer\")
                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")
                             (:file \"ready-recycle\")))
               (:module \"storage\"
                :serial t
                :components ((:file \"package\") (:file \"formats\") (:file \"segment-header\")
                             (:file \"log-header\") (:file \"compaction-scan\")
                             (:file \"control-payload\") (:file \"payload-record\")
                             (:file \"payload-write\")))
               (:module \"io\" :serial t
                :components ((:file \"package\") (:file \"types\") (:file \"native\")
                             (:file \"lifecycle\") (:file \"transfer\") (:file \"flush\")))
               (:module \"wal\" :serial t
                :components ((:file \"package\") (:file \"types\") (:file \"builder\")
                             (:file \"group\") (:file \"executor\")))
               (:module \"recovery\"
                :serial t
                :components ((:file \"package\") (:file \"scan\")
                             (:file \"decisions-package\") (:file \"decisions-types\")
                             (:file \"decisions-sort\") (:file \"decisions-radix\") (:file \"decisions-build\")
                             (:file \"decisions-query\")
                             (:file \"manifest-package\") (:file \"manifest-types\")
                             (:file \"manifest-decode\") (:file \"manifest-fold\")
                             (:file \"manifest-build\") (:file \"manifest-query\"))))
  :in-order-to ((test-op (test-op \"arcdocdb/tests\"))))

(defsystem \"arcdocdb/tests\"
  :description \"Test di ArcDocDB.\"
  :author \"Giacomo Picchiarelli\"
  :license \"BSD-2-Clause\"
  :depends-on (\"arcdocdb\")
  :pathname \"tests/\"
  :serial t
  :components ((:file \"smoke\")
               (:module \"foundation\"
                :serial t
                :components ((:file \"support\") (:file \"binary\")
                             (:file \"record\") (:file \"batch\")))
               (:module \"codec\" :serial t
                :components ((:file \"support\") (:file \"utf8\") (:file \"threads\")
                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")))
               (:module \"csn\" :serial t
                :components ((:file \"support\") (:file \"registry\") (:file \"threads\")))
               (:module \"execution\" :serial t
                :components ((:file \"support\") (:file \"queue\") (:file \"threads\")
                             (:file \"handoff\") (:file \"ready\") (:file \"ready-recycle\")))
               (:module \"storage\"
                :serial t
                :components ((:file \"support\") (:file \"segment-header\") (:file \"log-header\")
                             (:file \"compaction-scan\")
                             (:file \"control-payload\")))
               (:module \"io\" :serial t
                :components ((:file \"support\") (:file \"transfer\") (:file \"native\")))
               (:module \"recovery\"
                :serial t
                :components ((:file \"support\") (:file \"scan\") (:file \"corruption\")
                             (:file \"decisions-support\") (:file \"decisions\")
                             (:file \"decisions-audit\") (:file \"decisions-radix\") (:file \"manifest-support\")
                             (:file \"manifest\") (:file \"manifest-audit\")))
               (:module \"wal\" :serial t
                :components ((:file \"support\") (:file \"builder\") (:file \"group\") (:file \"fault\")
                             (:file \"native\"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
")
  (:PATH #A((26) BASE-CHAR . "src/execution/package.lisp") :BYTES 797 :SHA256
   "86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb" :GIT-BLOB
   "f140cee3f2f661c99fb7d860e4a642a66175c484" :TEXT
   ";;;; Esecuzione locale: coda bounded e lease esplicita del singolo writer.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defpackage #:arcdocdb.execution
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:coda-writer #:crea-coda-writer #:accoda-messaggio
           #:acquisisci-writer #:preleva-messaggi #:rilascia-writer
           #:writer-programmabile #:crea-writer-programmabile #:accoda-lavoro-writer
           #:inizia-tratto-writer #:preleva-lavori-writer #:termina-tratto-writer
           #:lista-writer-pronti #:crea-lista-writer-pronti
           #:pubblica-writer-pronto #:preleva-writer-pronto #:ricircola-writer-pronto))
")
  (:PATH #A((24) BASE-CHAR . "src/execution/queue.lisp") :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90" :GIT-BLOB
   "bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0" :TEXT
   ";;;; Ring preallocato: serializzazione dei soli indici con un tentativo CAS.
;;; OWNER: payload dal chiamante alla coda soltanto all'accettazione.
;;; SHARED: slots/head/tail/count mutabili soltanto con guard locale posseduta.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(defconstant +max-writer-capacity+ 65536)
(defconstant +max-writer-quantum+ 65536)
(defstruct (coda-writer (:constructor %make-coda-writer (slots capacity quantum))
                       (:copier nil))
  \"Pre: slots privati preallocati e budget finiti. Post: ring vuoto, nessuna lease.
Guard e owner hanno CAS distinti; generation non viene mai riciclata.\"
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (quantum 64 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread))
  (owner nil :type (or null sb-thread:thread))
  (generation 0 :type index) (extracted 0 :type index))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-queue))
(defun %check-queue (queue)
  \"Pre: guard posseduta, oppure coda appena costruita e non pubblicata.
Post: indici bounded e relazione FIFO coerente; INVARIANT-VIOLATION al guasto.\"
  (let ((capacity (coda-writer-capacity queue)) (head (coda-writer-head queue))
        (tail (coda-writer-tail queue)) (count (coda-writer-count queue)))
    (unless (and (<= 1 capacity +max-writer-capacity+)
                 (= (length (coda-writer-slots queue)) capacity)
                 (< head capacity) (< tail capacity) (<= count capacity))
      (error 'invariant-violation :reason :writer-queue-invariant))
    (unless (= tail (mod (+ head count) capacity))
      (error 'invariant-violation :reason :writer-queue-invariant)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) sb-thread:thread) %acquisisci-guard))
(defun %acquisisci-guard (queue)
  \"Pre: operazione breve sul ring. Post: guard locale del thread corrente.
Un solo CAS, senza attesa; RESOURCE-EXHAUSTED se busy, INVARIANT-VIOLATION al guasto.\"
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))
    (unless (eq (coda-writer-guard queue) thread)
      (error 'invariant-violation :reason :writer-guard))
    thread))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %rilascia-guard))
(defun %rilascia-guard (queue thread)
  \"Pre: guard acquisita da THREAD. Post: guard libera tramite un solo CAS.
INVARIANT-VIOLATION per proprietario diverso; nessuna attesa o recupero implicito.\"
  (unless (eq (coda-writer-guard queue) thread)
    (error 'invariant-violation :reason :writer-guard))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-guard queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) coda-writer) crea-coda-writer))
(defun crea-coda-writer (&key (capacity 1024) (quantum 64))
  \"Pre: capacity e quantum interi tra 1 e 65536, indipendenti.
Post: ring SIMPLE-VECTOR privato allocato una volta; INVALID-ARGUMENT al rifiuto.\"
  (unless (and (typep capacity 'index) (<= 1 capacity +max-writer-capacity+))
    (error 'invalid-argument :reason :writer-configuration))
  (unless (and (typep quantum 'index) (<= 1 quantum +max-writer-quantum+))
    (error 'invalid-argument :reason :writer-configuration))
  (let ((queue (%make-coda-writer (make-array capacity :initial-element nil) capacity quantum)))
    (%check-queue queue)
    queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) %accoda-sotto-guard))
(defun %accoda-sotto-guard (queue message)
  \"Pre: guard locale posseduta dal thread corrente, payload del produttore.
Post: una sola accettazione FIFO e count aggiornato; RESOURCE-EXHAUSTED se full
senza mutazioni, INVARIANT-VIOLATION per guard o indici incoerenti.\"
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (%check-queue queue)
  (when (= (coda-writer-count queue) (coda-writer-capacity queue))
    (error 'resource-exhausted :reason :writer-queue-full))
  (let ((tail (coda-writer-tail queue)))
    (setf (svref (coda-writer-slots queue) tail) message
          (coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))
          (coda-writer-count queue) (1+ (coda-writer-count queue))))
  (%check-queue queue)
  (coda-writer-count queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) accoda-messaggio))
(defun accoda-messaggio (queue message)
  \"Pre: payload opaco posseduto dal chiamante, compreso NIL. Post: accettato in FIFO,
ownership alla coda, restituisce il count dopo l'accettazione. RESOURCE-EXHAUSTED
per full/busy senza mutare ring o payload; nessun callback, attesa o wakeup.\"
  (let ((thread (%acquisisci-guard queue)))
    (unwind-protect (%accoda-sotto-guard queue message)
      (%rilascia-guard queue thread))))
")
  (:PATH #A((25) BASE-CHAR . "src/execution/writer.lisp") :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105" :GIT-BLOB
   "8e5102497f628796fa8faffa2085a165496af230" :TEXT
   ";;;; Lease locale del writer; la quota limita ogni acquisizione, non la capacità.
;;; OWNER: generation/extracted solo dal writer con lease corrente; CAS owner separato.
;;; SHARED: payload dalla coda al consumatore solo dopo prelievo, nessun callback.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) %check-lease))
(defun %check-lease (queue lease)
  \"Pre: token opaco fornito dal chiamante. Post: thread/generation correnti e quota valida.
INVALID-ARGUMENT per token stale, errato o altro thread; INVARIANT-VIOLATION per quota.\"
  (unless (and (typep lease 'index) (plusp lease)
               (eq (coda-writer-owner queue) sb-thread:*current-thread*)
               (= lease (coda-writer-generation queue)))
    (error 'invalid-argument :reason :writer-lease))
  (unless (and (<= 1 (coda-writer-quantum queue) +max-writer-quantum+)
               (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %libera-owner))
(defun %libera-owner (queue thread)
  \"Pre: THREAD possiede owner, campi della lease già finalizzati. Post: owner libero.
Un solo CAS; INVARIANT-VIOLATION al guasto, fail-stop del chiamante senza retry.\"
  (unless (eq (coda-writer-owner queue) thread)
    (error 'invariant-violation :reason :writer-owner))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-owner queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) index) acquisisci-writer))
(defun acquisisci-writer (queue)
  \"Pre: chiamante richiede una nuova lease. Post: generation positiva, quota nuova;
RESOURCE-EXHAUSTED per writer busy o generation esaurita. Overflow non incrementa
né cambia extracted e libera il CAS acquisito; nessun wrap, callback o scheduling.\"
  (let ((thread sb-thread:*current-thread*) (committed nil))
    (unless (null (sb-ext:compare-and-swap (coda-writer-owner queue) nil thread))
      (error 'resource-exhausted :reason :writer-busy))
    (unwind-protect
         (progn
           (unless (and (eq (coda-writer-owner queue) thread)
                        (zerop (coda-writer-extracted queue)))
             (error 'invariant-violation :reason :writer-owner))
           (when (= (coda-writer-generation queue) most-positive-fixnum)
             (error 'resource-exhausted :reason :writer-generation))
           (incf (coda-writer-generation queue))
           (setf committed t)
           (coda-writer-generation queue))
      (unless committed (%libera-owner queue thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t)
                         (values simple-vector index index &optional)) %check-target))
(defun %check-target (queue target start end)
  \"Pre: destinazione del consumatore e range dichiarato. Post: SIMPLE-VECTOR e indici
non vuoti validati prima del ring; INVALID-ARGUMENT per alias, tipo o range errati.\"
  (unless (and (typep target 'simple-vector) (not (eq target (coda-writer-slots queue))))
    (error 'invalid-argument :reason :writer-target))
  (unless (and (typep start 'index) (typep end 'index) (< start end) (<= end (length target)))
    (error 'invalid-argument :reason :writer-target))
  (values target (the index start) (the index end)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t t)
                         (values index (member :messages :empty :yield) &optional)) preleva-messaggi))
(defun preleva-messaggi (queue lease target start end)
  \"Pre: lease del thread corrente e destinazione privata non alias degli slots.
Post: FIFO fino a MIN(count, range, quota), slots liberati, ownership al consumatore;
fuori dai messaggi copiati target invariato. :YIELD senza lavoro sul ring a quota zero,
:EMPTY se vuoto, :MESSAGES dopo copia. INVALID-ARGUMENT per lease/target, RESOURCE-
EXHAUSTED per guard busy; errori interni impongono fail-stop al chiamante.\"
  (%check-lease queue lease)
  (multiple-value-bind (destination first limit) (%check-target queue target start end)
    (let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))
      (declare (type index remaining))
      (when (zerop remaining) (return-from preleva-messaggi (values 0 :yield)))
      (let ((thread (%acquisisci-guard queue)))
        (unwind-protect
             (progn
               (%check-queue queue)
               (let* ((count (coda-writer-count queue))
                      (taken (min count (- limit first) remaining))
                      (cursor (coda-writer-head queue))
                      (extracted (coda-writer-extracted queue))
                      (slots (coda-writer-slots queue)) (capacity (coda-writer-capacity queue)))
                 (declare (type index count taken cursor extracted capacity))
                 (dotimes (i taken)
                   (setf (svref destination (+ first i)) (svref slots cursor)
                         (svref slots cursor) nil
                         cursor (mod (1+ cursor) capacity)))
                 (setf (coda-writer-head queue) cursor (coda-writer-count queue) (- count taken)
                       (coda-writer-extracted queue) (+ extracted taken))
                 (%check-queue queue)
                 (unless (and (<= taken remaining)
                              (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
                   (error 'invariant-violation :reason :writer-owner))
                 (values taken (if (zerop taken) :empty :messages))))
          (%rilascia-guard queue thread))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) rilascia-writer))
(defun rilascia-writer (queue lease)
  \"Pre: lease corrente del thread proprietario. Post: quota azzerata prima del CAS owner
verso NIL, generation conservata. INVALID-ARGUMENT per token errato/stale/altro thread;
INVARIANT-VIOLATION al guasto. Nessun ready, wakeup, callback o controller implicito.\"
  (%check-lease queue lease)
  (setf (coda-writer-extracted queue) 0)
  (%libera-owner queue sb-thread:*current-thread*))
")
  (:PATH #A((26) BASE-CHAR . "src/execution/handoff.lisp") :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607" :GIT-BLOB
   "a030e7af1afd6db760088f74615fe2396d928b64" :TEXT
   ";;;; Consegna locale del writer: la guard del ring protegge anche lo scheduling.
;;; OWNER: ogni wrapper e la sua coda privata appartengono a una sola Serie.
;;; SHARED: stato/count sotto la stessa guard; owner/generation con protocollo lease.
;;; Nessuno stato fra Serie: :schedule trasferisce un obbligo al chiamante.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (writer-programmabile (:constructor %make-writer-programmabile (queue))
                                (:copier nil))
  \"Pre: coda privata, mai esposta né usata tramite le API basse. Post: writer IDLE.
Le API trasferiscono obblighi :SCHEDULE, non creano thread né inviano notifiche.\"
  (queue (error 'invariant-violation :reason :writer-scheduling)
         :type coda-writer :read-only t)
  (state :idle :type (member :idle :ready :running)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-writer-inattivo))
(defun %check-writer-inattivo (queue)
  \"Pre: guard posseduta, stato IDLE o READY. Post: nessuna lease e quota zero.
INVARIANT-VIOLATION per guard, owner o quota incompatibili con il passaggio.\"
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (unless (null (coda-writer-owner queue))
    (error 'invariant-violation :reason :writer-scheduling))
  (unless (zerop (coda-writer-extracted queue))
    (error 'invariant-violation :reason :writer-scheduling))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) null) %check-programmabile))
(defun %check-programmabile (writer)
  \"Pre: guard della coda privata posseduta. Post: ring e stato/owner coerenti.
INVARIANT-VIOLATION per guard errata o stato che non rappresenta il lavoro.\"
  (let* ((queue (writer-programmabile-queue writer))
         (count (coda-writer-count queue)) (owner (coda-writer-owner queue)))
    (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
      (error 'invariant-violation :reason :writer-guard))
    (%check-queue queue)
    (case (writer-programmabile-state writer)
      (:idle
       (unless (zerop count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:ready
       (unless (plusp count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:running
       (unless owner (error 'invariant-violation :reason :writer-scheduling)))
      (otherwise (error 'invariant-violation :reason :writer-scheduling))))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) writer-programmabile)
                crea-writer-programmabile))
(defun crea-writer-programmabile (&key (capacity 1024) (quantum 64))
  \"Pre: capacity/quantum nei limiti di CREA-CODA-WRITER. Post: wrapper IDLE
con ring esclusivo preallocato; INVALID-ARGUMENT per configurazione errata.\"
  (let* ((queue (crea-coda-writer :capacity capacity :quantum quantum))
         (writer (%make-writer-programmabile queue)) (thread (%acquisisci-guard queue)))
    (unwind-protect (progn (%check-programmabile writer) writer)
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t)
                         (values index (member :schedule :queued) &optional))
                accoda-lavoro-writer))
(defun accoda-lavoro-writer (writer message)
  \"Pre: payload posseduto dal chiamante. Post: accettazione FIFO; :SCHEDULE solo
su IDLE→READY, :QUEUED se già READY/RUNNING. Il chiamante conserva ed esegue una
sola volta l'obbligo :SCHEDULE; un retry della notifica non ripete l'accettazione.
RESOURCE-EXHAUSTED full/busy prima dell'accettazione; invarianti impongono fail-stop.\"
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (let* ((schedule (eq (writer-programmabile-state writer) :idle))
                  (count (%accoda-sotto-guard queue message)))
             (when schedule (setf (writer-programmabile-state writer) :ready))
             (%check-programmabile writer)
             (values count (if schedule :schedule :queued))))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) index) inizia-tratto-writer))
(defun inizia-tratto-writer (writer)
  \"Pre: compito pronto assegnato dal chiamante. Post: READY→RUNNING con lease
del thread corrente; nessun messaggio estratto. RESOURCE-EXHAUSTED conserva lo
stato: busy richiede retry del compito; not-ready rifiuta un'assegnazione non
eleggibile/duplicata; generation è esaurimento permanente, senza wrap.\"
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (unless (eq (writer-programmabile-state writer) :ready)
             (error 'resource-exhausted :reason :writer-not-ready))
           (let ((lease (acquisisci-writer queue)))
             (setf (writer-programmabile-state writer) :running)
             (%check-programmabile writer)
             lease))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t t t t)
                         (values index (member :messages :empty :yield) &optional))
                preleva-lavori-writer))
(defun preleva-lavori-writer (writer lease target start end)
  \"Pre: lease corrente del tratto e target privato. Post: prelievo FIFO bounded
e quota cumulativa come PRELEVA-MESSAGGI; le medesime condizioni al rifiuto.
La lease impedisce una fine-tratto concorrente; la coda interna resta privata.\"
  (preleva-messaggi (writer-programmabile-queue writer) lease target start end))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t) (member :schedule :idle))
                termina-tratto-writer))
(defun termina-tratto-writer (writer lease)
  \"Pre: messaggi estratti elaborati, lease corrente. Post: quota/gettone rilasciati
e READY/:SCHEDULE se resta lavoro, IDLE/:IDLE se vuoto, sotto la guard del ring.
Il chiamante conserva l'obbligo :SCHEDULE. Busy conserva lease e stato: ritentare
solo il termine, senza rielaborare payload. INVALID-ARGUMENT lease; invarianti
impongono fail-stop. Nessuna notifica o attesa; nessun cambiamento durevole.\"
  (let ((queue (writer-programmabile-queue writer)))
    (%check-lease queue lease)
    (let ((thread (%acquisisci-guard queue)))
      (unwind-protect
           (progn
             (%check-programmabile writer)
             (let ((pending (plusp (coda-writer-count queue))))
               (rilascia-writer queue lease)
               (setf (writer-programmabile-state writer) (if pending :ready :idle))
               (%check-programmabile writer)
               (if pending :schedule :idle)))
        (%rilascia-guard queue thread)))))
")
  (:PATH #A((30) BASE-CHAR . "src/execution/ready-types.lisp") :BYTES 5248
   :SHA256 "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f"
   :GIT-BLOB "5b3c26f78d5c4aa53ca200abdd3e0f753f926b54" :TEXT
   ";;;; Lista pronta partizionata: nessun contatore comune fra i ring.
;;; OWNER: scheduler dell'Archivio; ogni partizione possiede indici e slots.
;;; SHARED: lista Serie pronte (ADR-0045 §8), solo pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-partizioni-pronte+ 64)
;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-capacita-pronta+ 65536)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (partizione-pronta (:constructor %make-partizione-pronta (slots capacity))
                             (:copier nil))
  \"Pre: ring privato preallocato e capacity bounded. Post: vuoto, guard libera.
Slots/indici sono mutati soltanto dal proprietario della guard locale.\"
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (lista-writer-pronti (:constructor %make-lista-writer-pronti (partitions))
                              (:copier nil))
  \"Pre: partizioni private, indipendenti e bounded. Post: lista pronta vuota.
Non deduplica obblighi :SCHEDULE né governa stato o risvegli dei worker.\"
  (partitions #() :type simple-vector :read-only t))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-forma-pronta))
(defun %check-forma-pronta (partition)
  \"Pre: ring appena creato oppure guard posseduta. Post: forma e FIFO coerenti.
INVARIANT-VIOLATION per limiti, indici o relazione head/count/tail errati.\"
  (let ((capacity (partizione-pronta-capacity partition)))
    (unless (<= 1 capacity +max-capacita-pronta+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (length (partizione-pronta-slots partition)) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-head partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-tail partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (<= (partizione-pronta-count partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (partizione-pronta-tail partition)
               (mod (+ (partizione-pronta-head partition)
                       (partizione-pronta-count partition)) capacity))
      (error 'invariant-violation :reason :ready-queue-invariant)))
  nil)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-pronta))
(defun %check-pronta (partition)
  \"Pre: guard locale acquisita. Post: proprietario corrente e forma valida.
INVARIANT-VIOLATION per guard estranea o incoerenza interna.\"
  (unless (eq (partizione-pronta-guard partition) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :ready-queue-guard))
  (%check-forma-pronta partition))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t) partizione-pronta) %partizione-verificata))
(defun %partizione-verificata (ready shard)
  \"Pre: lista costruita con la factory. Post: partizione dell'indice verificato.
INVALID-ARGUMENT per indice errato; INVARIANT-VIOLATION per lista privata invalida.\"
  (let ((partitions (lista-writer-pronti-partitions ready)))
    (unless (<= 1 (length partitions) +max-partizioni-pronte+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (typep shard 'index) (error 'invalid-argument :reason :ready-target))
    (unless (< shard (length partitions)) (error 'invalid-argument :reason :ready-target))
    (let ((partition (svref partitions shard)))
      (unless (typep partition 'partizione-pronta)
        (error 'invariant-violation :reason :ready-queue-invariant))
      partition)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:shards t) (:capacity t)) lista-writer-pronti)
                crea-lista-writer-pronti))
(defun crea-lista-writer-pronti (&key (shards 4) (capacity 1024))
  \"Pre: shards 1..64, capacity per ring 1..65536. Post: ring privati preallocati.
INVALID-ARGUMENT per budget errati; nessuna allocazione sul percorso normale per compito.\"
  (unless (typep shards 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 shards +max-partizioni-pronte+)
    (error 'invalid-argument :reason :ready-configuration))
  (unless (typep capacity 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 capacity +max-capacita-pronta+)
    (error 'invalid-argument :reason :ready-configuration))
  (let ((partitions (make-array shards :initial-element nil)))
    (dotimes (i shards)
      (let ((partition (%make-partizione-pronta
                        (make-array capacity :initial-element nil) capacity)))
        (%check-forma-pronta partition)
        (setf (svref partitions i) partition)))
    (let ((ready (%make-lista-writer-pronti partitions)))
      (%partizione-verificata ready 0)
      ready)))
")
  (:PATH #A((24) BASE-CHAR . "src/execution/ready.lisp") :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327" :GIT-BLOB
   "4119f86231b7d8698fc3558868ff8a5bcbdf3090" :TEXT
   ";;;; Passaggi degli obblighi :schedule; nessuno stato membership o cleanup writer.
;;; OWNER: obbligo al chiamante prima di publish, al ring, poi al worker dopo pop.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) (or null sb-thread:thread)) %prendi-guard-pronta))
(defun %prendi-guard-pronta (partition)
  \"Pre: accesso breve al ring. Post: guard del thread corrente oppure NIL se busy.
Un solo CAS, nessuna attesa; INVARIANT-VIOLATION al guasto della proprietà.\"
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (partizione-pronta-guard partition) nil thread))
      (return-from %prendi-guard-pronta nil))
    (unless (eq (partizione-pronta-guard partition) thread)
      (error 'invariant-violation :reason :ready-queue-guard))
    thread))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta sb-thread:thread) null) %rilascia-guard-pronta))
(defun %rilascia-guard-pronta (partition thread)
  \"Pre: guard posseduta da THREAD. Post: guard libera con un CAS verificato.
INVARIANT-VIOLATION per proprietà errata; nessun retry o recupero implicito.\"
  (unless (eq (partizione-pronta-guard partition) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  (unless (eq (sb-ext:compare-and-swap (partizione-pronta-guard partition) thread nil) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile) index) %pubblica-pronto))
(defun %pubblica-pronto (partition writer)
  \"Pre: guard corrente e obbligo unico del chiamante. Post: una accettazione FIFO.
RESOURCE-EXHAUSTED se full prima della mutazione; INVARIANT-VIOLATION al guasto.\"
  (%check-pronta partition)
  (when (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'resource-exhausted :reason :ready-queue-full))
  (let ((tail (partizione-pronta-tail partition)))
    (unless (null (svref (partizione-pronta-slots partition) tail))
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) tail) writer
          (partizione-pronta-tail partition) (mod (1+ tail) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1+ (partizione-pronta-count partition))))
  (%check-pronta partition)
  (partizione-pronta-count partition))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty) &optional))
                %preleva-pronto))
(defun %preleva-pronto (partition)
  \"Pre: guard corrente. Post: riferimento FIFO al worker, slot liberato; NIL/:EMPTY
se vuoto. INVARIANT-VIOLATION per forma o payload incoerente, fail-stop del chiamante.\"
  (%check-pronta partition)
  (when (zerop (partizione-pronta-count partition))
    (return-from %preleva-pronto (values nil :empty)))
  (let* ((head (partizione-pronta-head partition))
         (writer (svref (partizione-pronta-slots partition) head)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) nil
          (partizione-pronta-head partition) (mod (1+ head) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1- (partizione-pronta-count partition)))
    (%check-pronta partition)
    (values writer :writer)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t) index) pubblica-writer-pronto))
(defun pubblica-writer-pronto (ready shard writer)
  \"Pre: un unico obbligo :SCHEDULE da pubblicare una sola volta. Post: count locale,
obbligo al ring. INVALID-ARGUMENT per shard/writer; RESOURCE-EXHAUSTED full/busy
conserva obbligo al chiamante. Il retry non accetta nuovamente i payload nel writer.\"
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%pubblica-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty :busy) &optional))
                %prova-pronta))
(defun %prova-pronta (partition)
  \"Pre: una partizione candidata. Post: writer/empty dal ring oppure NIL/:BUSY.
Un CAS senza spin; cleanup dopo acquisizione verificata, invarianti fail-stop.\"
  (let ((thread (%prendi-guard-pronta partition)))
    (unless thread (return-from %prova-pronta (values nil :busy)))
    (unwind-protect (%preleva-pronto partition)
      (%rilascia-guard-pronta partition thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t)
                         (values (or null writer-programmabile) (member :writer :empty :busy) index &optional))
                preleva-writer-pronto))
(defun preleva-writer-pronto (ready start)
  \"Pre: start indice valido. Post: al più K tentativi circolari; writer/:WRITER e
cursore seguente alla partizione servita, oppure NIL e :BUSY/:EMPTY con start+1.
EMPTY sono osservazioni locali, non quiescenza globale; un worker conserva il
riferimento fino all'avvio riuscito. INVALID-ARGUMENT indice; invarianti fail-stop.\"
  (%partizione-verificata ready start)
  (let* ((size (length (lista-writer-pronti-partitions ready)))
         (cursor (the index start)) (busy nil))
    (dotimes (i size)
      (multiple-value-bind (writer status) (%prova-pronta (%partizione-verificata ready cursor))
        (case status
          (:writer (return-from preleva-writer-pronto
                     (values writer :writer (mod (1+ cursor) size))))
          (:busy (setf busy t))
          (:empty nil)
          (otherwise (error 'invariant-violation :reason :ready-queue-invariant))))
      (setf cursor (mod (1+ cursor) size)))
    (values nil (if busy :busy :empty) (mod (1+ (the index start)) size))))
")
  (:PATH #A((32) BASE-CHAR . "src/execution/ready-recycle.lisp") :BYTES 3387
   :SHA256 "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b"
   :GIT-BLOB "58981c7e41ce2694dbfcaed99010a3a53e3c1dea" :TEXT
   ";;;; Ricircolo bounded: pubblica e prende una testa nello stesso ring pieno.
;;; OWNER: il ring possiede A dopo successo; il chiamante possiede la testa restituita.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una operazione per tratto, mai per messaggio.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values writer-programmabile (member :writer) index &optional))
                %scambia-pronto))
(defun %scambia-pronto (partition writer)
  \"Pre: guard corrente, ring pieno, obbligo unico. Post: testa al caller e WRITER
in coda, count invariato. INVARIANT-VIOLATION per forma, capienza o testa invalida.\"
  (%check-pronta partition)
  (unless (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'invariant-violation :reason :ready-recycle-full))
  (let* ((head (partizione-pronta-head partition))
         (old (svref (partizione-pronta-slots partition) head))
         (next (mod (1+ head) (partizione-pronta-capacity partition))))
    (unless (typep old 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) writer
          (partizione-pronta-head partition) next
          (partizione-pronta-tail partition) next)
    (%check-pronta partition)
    (values old :writer (partizione-pronta-count partition))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                %ricircola-pronto))
(defun %ricircola-pronto (partition writer)
  \"Pre: guard corrente e obbligo unico. Post: pubblicato, o testa e slot scambiati.
INVARIANT-VIOLATION per ring o payload incoerenti; nessun rifiuto per ring pieno.\"
  (%check-pronta partition)
  (if (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
      (%scambia-pronto partition writer)
      (values nil :published (%pubblica-pronto partition writer))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                ricircola-writer-pronto))
(defun ricircola-writer-pronto (ready shard writer)
  \"Pre: obbligo :SCHEDULE unico e caller capace di prendere un altro writer.
Post: NIL/:PUBLISHED/count se spazio; testa/:WRITER/capacity se pieno: nuovo
obbligo al ring, testa al caller. INVALID-ARGUMENT shard/writer; RESOURCE-EXHAUSTED
busy conserva obbligo. Invarianti fail-stop; nessun retry, attesa o deduplicazione.\"
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%ricircola-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))
")
  (:PATH #A((28) BASE-CHAR . "tests/execution/support.lisp") :BYTES 4469
   :SHA256 "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43"
   :GIT-BLOB "b8bac07926727a644f0246f6b57d600332288310" :TEXT
   ";;;; Oracoli della coda writer; nessuna dipendenza dalla rappresentazione del ring.
(defpackage #:arcdocdb.execution.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals #:reference-crc)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.execution.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t \"ok    ~A~%\" test))
  (format t \"~D test delle code writer superati.~%\" (length *tests*))
  t)

(defmacro with-execution-lease ((lease queue) &body body)
  (let ((q (gensym \"QUEUE\")))
    `(let* ((,q ,queue)
            (,lease (arcdocdb.execution:acquisisci-writer ,q)))
       (unwind-protect (progn ,@body)
         (arcdocdb.execution:rilascia-writer ,q ,lease)))))

(defmacro with-execution-guard ((queue) &body body)
  \"FI dichiarata: prende e restituisce la guardia con gli stessi CAS del contratto.\"
  (let ((q (gensym \"QUEUE\")) (owner (gensym \"OWNER\")))
    `(let ((,q ,queue) (,owner sb-thread:*current-thread*))
       (is (null (sb-ext:compare-and-swap
                  (arcdocdb.execution::coda-writer-guard ,q) nil ,owner)))
       (unwind-protect (progn ,@body)
         (is (eq ,owner (sb-ext:compare-and-swap
                          (arcdocdb.execution::coda-writer-guard ,q) ,owner nil)))))))

(defun execution-check-pop (queue lease target start end expected status)
  \"Lista attesa indipendente; nessuna lettura di head/count/slot del prodotto.\"
  (let ((before (copy-seq target)))
    (multiple-value-bind (count actual-status)
        (arcdocdb.execution:preleva-messaggi queue lease target start end)
      (is (= count (length expected)))
      (is (eq actual-status status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      count)))

(defun execution-drain (queue maximum)
  \"Drain bornato per gli oracoli sequenziali: rinnova il quantum fra i tratti.\"
  (let ((target (make-array (max 1 maximum) :initial-element :untouched)) (items nil))
    (loop repeat (1+ maximum)
          do (with-execution-lease (lease queue)
               (multiple-value-bind (count status)
                   (arcdocdb.execution:preleva-messaggi queue lease target 0 (length target))
                 (is (<= 0 count (length target)))
                 (case status
                   (:messages
                    (is (plusp count))
                    (dotimes (i count) (push (svref target i) items)))
                   (:empty (is (zerop count)) (return-from execution-drain (nreverse items)))
                   (otherwise (error \"Statuto inatteso nel primo prelievo: ~S\" status)))))
          finally (error \"Il drain dell'oracolo ha superato il limite.\"))))

(defun execution-wait (semaphore &optional (seconds 15))
  (unless (sb-thread:wait-on-semaphore semaphore :timeout seconds)
    (error \"Attesa della fixture oltre il limite.\"))
  t)

(defun execution-thread (name thunk)
  \"Gli errori restano risultati del worker e vengono rilanciati dal join.\"
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

(defun execution-join (thread &optional (seconds 20))
  (let ((result (sb-thread:join-thread thread :timeout seconds :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq result :ok))
    result))

(defun execution-stop-threads (threads)
  \"Cleanup solo della fixture, anche dopo timeout o asserzioni del thread principale.\"
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread)
      (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated))
  nil)

(defun execution-buffer (size seed)
  (let ((buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf (aref buffer i) (logand #xff (+ (* i 29) seed))))))

(defun execution-deadline (&optional (seconds 15))
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun execution-before-deadline (deadline)
  (when (>= (get-internal-real-time) deadline)
    (error \"Budget temporale della fixture esaurito.\")))
")
  (:PATH #A((28) BASE-CHAR . "tests/execution/handoff.lisp") :BYTES 33278
   :SHA256 "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e"
   :GIT-BLOB "ba702352ee63241b9ac993b0aca8f162c3deef1b" :TEXT
   ";;;; Oracolo FIFO e fixture del passaggio locale idle/ready/running.
;;;; Semafori e thread appartengono soltanto alla fixture, non al prodotto.
(in-package #:arcdocdb.execution.tests)

(defun handoff-check-enqueue (writer item expected-count expected-status)
  (multiple-value-bind (count status)
      (arcdocdb.execution:accoda-lavoro-writer writer item)
    (is (= count expected-count))
    (is (eq status expected-status))
    count))

(defun handoff-check-pop (writer lease target start end expected expected-status)
  \"Lista attesa indipendente; verifica anche tutte le celle non scritte.\"
  (let ((before (copy-seq target)))
    (multiple-value-bind (count status)
        (arcdocdb.execution:preleva-lavori-writer writer lease target start end)
      (is (= count (length expected)))
      (is (eq status expected-status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      count)))

(defun handoff-drain (writer maximum)
  \"Ready initiale; limite maximum+1, nessuna lettura dei contatori del ring.\"
  (let ((target (make-array (max 1 maximum) :initial-element :untouched)) (items nil))
    (loop repeat (1+ maximum)
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (multiple-value-bind (count status)
                   (arcdocdb.execution:preleva-lavori-writer writer lease target 0 (length target))
                 (is (plusp count)) (is (eq status :messages))
                 (dotimes (i count) (push (svref target i) items)))
               (let ((next (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (is (member next '(:idle :schedule)))
                 (when (eq next :idle) (return-from handoff-drain (nreverse items)))))
          finally (error \"Il drain handoff ha superato il limite della fixture.\"))))

(defun handoff-fi-snapshot (writer)
  \"FI: immagine dei campi prima/dopo un rifiuto, mai oracolo dell'ordine FIFO.\"
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (list (arcdocdb.execution::writer-programmabile-state writer)
          (arcdocdb.execution::coda-writer-head queue)
          (arcdocdb.execution::coda-writer-tail queue)
          (arcdocdb.execution::coda-writer-count queue)
          (arcdocdb.execution::coda-writer-owner queue)
          (arcdocdb.execution::coda-writer-generation queue)
          (arcdocdb.execution::coda-writer-extracted queue)
          (copy-seq (arcdocdb.execution::coda-writer-slots queue)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-configuration-and-limits
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity bad :quantum 3)
      :writer-configuration)
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum bad)
      :writer-configuration))
  (dolist (limits '((1 65536) (65536 1)))
    (let ((writer (arcdocdb.execution:crea-writer-programmabile
                   :capacity (first limits) :quantum (second limits))))
      (handoff-check-enqueue writer nil 1 :schedule)
      (is (equal '(nil) (handoff-drain writer 1)))))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile)))
    (dotimes (i 1024)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (signals resource-exhausted
      (arcdocdb.execution:accoda-lavoro-writer writer :extra) :writer-queue-full)
    (is (equal (loop for i below 1024 collect i) (handoff-drain writer 1024)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-single-obligation-and-duplicate-begin
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 2))
        (target (vector :left :x :y :right)))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)
    ;; Un invio della notifica che fallisce conserva l'obbligo :schedule.
    ;; Il chiamante ritenta la notifica; il payload accettato non viene riaccodato.
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (let ((attempts 0))
        (flet ((notify () (> (incf attempts) 1)))
          (is (null (notify)))
          (is (eq pending :schedule))
          (handoff-check-enqueue writer :b 2 :queued)
          (is (notify))
          (is (= attempts 2))
          (setf pending nil)))
      (is (null pending))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-not-ready)
        (handoff-check-pop writer lease target 1 3 '(:a :b) :messages)
        (handoff-check-pop writer lease target 1 3 nil :yield)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-enqueue-before-and-after-empty-release
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :initial 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 1 '(:initial) :messages)
      (handoff-check-pop writer lease target 0 1 nil :empty)
      ;; Vuoto, ma running: il prossimo lavoro non crea una seconda notifica.
      (handoff-check-enqueue writer :before-release 1 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(:before-release) (handoff-drain writer 2)))
    ;; La pubblicazione successiva al rilascio vuoto crea il nuovo obbligo.
    (handoff-check-enqueue writer :after-release 1 :schedule)
    (is (equal '(:after-release) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-cumulative-quantum-and-successive-slices
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 7 :quantum 3))
        (target (make-array 8 :initial-element :untouched)))
    (dotimes (i 7)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 3 '(0 1) :messages)
      (handoff-check-pop writer lease target 1 7 '(2) :messages)
      (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
        (with-execution-guard (queue)
          (handoff-check-pop writer lease target 1 7 nil :yield)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 7 '(3 4 5) :messages)
      (handoff-check-pop writer lease target 1 7 nil :yield)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(6) (handoff-drain writer 7)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-full-ready-and-running-retain-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (a (vector :a)) (b (vector :b)) (refused (vector :refused)))
    (handoff-check-enqueue writer a 1 :schedule)
    (handoff-check-enqueue writer b 2 :queued)
    (let ((before (handoff-fi-snapshot writer)))
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
               :writer-queue-full)
      (is (equalp before (handoff-fi-snapshot writer))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
                 :writer-queue-full)
        (is (equalp before (handoff-fi-snapshot writer))))
      (handoff-check-pop writer lease (vector :untouched) 0 1 (list a) :messages)
      (handoff-check-enqueue writer refused 2 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equalp refused #(:refused)))
    (is (equal (list b refused) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-busy-idle-and-ready-preserve-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-queue-busy)
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (is (equal '(:kept) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-handoff-busy-release-retains-lease-for-retry
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted
            (arcdocdb.execution:preleva-lavori-writer writer lease target 0 2)
            :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                   :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp target #(:left :right)))
          (is (equalp before (handoff-fi-snapshot writer)))))
      (handoff-check-pop writer lease target 0 2 '(:kept) :messages)
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp before (handoff-fi-snapshot writer)))))
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-005-handoff-early-release-conserves-entire-backlog
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 8)))
    (handoff-check-enqueue writer :a 1 :schedule)
    (handoff-check-enqueue writer :b 2 :queued)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer old)))
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (handoff-check-pop writer fresh (vector :untouched :untouched) 0 2 '(:a :b) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-lease-validation-and-stale-generation
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :old 1 :schedule)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (dolist (bad (list 0 -1 nil :wrong (1+ most-positive-fixnum)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer bad target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer bad)
                 :writer-lease))
      (handoff-check-pop writer old target 0 1 '(:old) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer old)))
      (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
               :writer-lease)
      (handoff-check-enqueue writer :fresh 1 :schedule)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer old target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
                 :writer-lease)
        (handoff-check-pop writer fresh target 0 1 '(:fresh) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-target-preflight-and-private-alias
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 3))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :middle :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let* ((lease (arcdocdb.execution:inizia-tratto-writer writer))
           (before (handoff-fi-snapshot writer)))
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease target
                                                 (first range) (second range)) :writer-target))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :caller)
                        (arcdocdb.execution::coda-writer-slots queue)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease bad 0 1) :writer-target))
      (is (equalp target #(:left :middle :right)))
      (is (equalp before (handoff-fi-snapshot writer)))
      (handoff-check-pop writer lease target 1 3 '(:kept) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-generation-exhaustion-preserves-ready
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    ;; FI quiescente, nessun thread/lease attivo; si raggiunge l'ultimo token lecito.
    (setf (arcdocdb.execution::coda-writer-generation queue) (1- most-positive-fixnum))
    (handoff-check-enqueue writer :last 1 :schedule)
    (let ((last (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (= last most-positive-fixnum))
      (handoff-check-pop writer last (vector nil) 0 1 '(:last) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer last))))
    (handoff-check-enqueue writer :preserved 1 :schedule)
    (let ((before (handoff-fi-snapshot writer)))
      (dotimes (attempt 2)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-generation)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :also-accepted 2 :queued)))

(defun handoff-fi-corrupt-state (writer fault)
  \"FI su oggetto privato sacrificato; gli indici del ring rimangono coerenti.\"
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (when (member fault '(:ready-count :ready-owner :ready-extracted :running-owner))
      (handoff-check-enqueue writer :kept 1 :schedule))
    (case fault
      (:idle-count
       (setf (arcdocdb.execution::coda-writer-count queue) 1
             (arcdocdb.execution::coda-writer-tail queue) 1
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) :unexpected))
      ((:idle-owner :ready-owner)
       (setf (arcdocdb.execution::coda-writer-owner queue) sb-thread:*current-thread*))
      ((:idle-extracted :ready-extracted)
       (setf (arcdocdb.execution::coda-writer-extracted queue) 1))
      (:ready-count
       (setf (arcdocdb.execution::coda-writer-count queue) 0
             (arcdocdb.execution::coda-writer-tail queue) 0
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) nil))
      (:running-owner
       (arcdocdb.execution:inizia-tratto-writer writer)
       (setf (arcdocdb.execution::coda-writer-owner queue) nil))
      (otherwise (error \"FI handoff sconosciuta: ~S\" fault)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-rejects-inconsistent-scheduling-states
  (dolist (fault '(:idle-count :idle-owner :idle-extracted :ready-count
                   :ready-owner :ready-extracted :running-owner))
    (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
           (queue (arcdocdb.execution::writer-programmabile-queue writer)))
      (handoff-fi-corrupt-state writer fault)
      (let ((before (handoff-fi-snapshot writer)))
        (with-execution-guard (queue)
          (signals arcdocdb.conditions:invariant-violation
            (arcdocdb.execution::%check-programmabile writer) :writer-scheduling))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:accoda-lavoro-writer writer :refused) :writer-scheduling)
        (is (equalp before (handoff-fi-snapshot writer)))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-helpers-require-current-thread-guard
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (before (handoff-fi-snapshot writer)) (threads nil))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
    (is (equalp before (handoff-fi-snapshot writer)))
    ;; FI: guard posseduta dal main; il thread estraneo deve rifiutare i tre helper.
    (unwind-protect
         (with-execution-guard (queue)
           (push (execution-thread
                  \"handoff foreign guard\"
                  (lambda ()
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
                    :ok)) threads)
           (execution-join (first threads))
           (is (equalp before (handoff-fi-snapshot writer))))
      (execution-stop-threads threads))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (is (equal '(:kept) (handoff-drain writer 2)))))

(defstruct handoff-model
  (items nil) (state :idle) (remaining 0) (lease 0))

(defun handoff-model-enqueue (writer model item capacity)
  (if (= (length (handoff-model-items model)) capacity)
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer item)
               :writer-queue-full)
      (let ((expected (if (eq (handoff-model-state model) :idle) :schedule :queued)))
        (setf (handoff-model-items model) (append (handoff-model-items model) (list item)))
        (handoff-check-enqueue writer item (length (handoff-model-items model)) expected)
        (when (eq expected :schedule) (setf (handoff-model-state model) :ready)))))

(defun handoff-model-begin (writer model quantum)
  (if (eq (handoff-model-state model) :ready)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh (handoff-model-lease model)))
        (setf (handoff-model-lease model) fresh (handoff-model-state model) :running
              (handoff-model-remaining model) quantum))
      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
               :writer-not-ready)))

(defun handoff-model-pop (writer model start span)
  (when (eq (handoff-model-state model) :running)
    (let* ((remaining (handoff-model-remaining model))
           (items (handoff-model-items model)) (n (min remaining span (length items)))
           (target (make-array (+ start span 2) :initial-element :untouched))
           (status (cond ((zerop remaining) :yield) ((zerop n) :empty) (t :messages))))
      (handoff-check-pop writer (handoff-model-lease model) target start (+ start span)
                         (subseq items 0 n) status)
      (setf (handoff-model-items model) (nthcdr n items))
      (decf (handoff-model-remaining model) n))))

(defun handoff-model-finish (writer model)
  (when (eq (handoff-model-state model) :running)
    (let ((expected (if (handoff-model-items model) :schedule :idle)))
      (is (eq expected (arcdocdb.execution:termina-tratto-writer
                        writer (handoff-model-lease model))))
      (setf (handoff-model-state model) (if (eq expected :schedule) :ready :idle)
            (handoff-model-remaining model) 0))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-handoff-seeded-list-and-scheduling-oracle
  (let ((seed #x9d670f42))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((capacity (1+ (mod (ash (next) -8) 9)))
               (quantum (1+ (mod (ash (next) -8) 12)))
               (writer (arcdocdb.execution:crea-writer-programmabile
                        :capacity capacity :quantum quantum))
               (model (make-handoff-model)))
          (dotimes (step 800)
            (case (mod (ash (next) -8) 7)
              ((0 1) (handoff-model-enqueue writer model
                                            (if (zerop (mod step 7)) nil (vector scenario step))
                                            capacity))
              (2 (handoff-model-begin writer model quantum))
              ((3 4) (handoff-model-pop writer model (1+ (mod (next) 3))
                                        (1+ (mod (ash (next) -8) 7))))
              (5 (handoff-model-finish writer model))
              (6 (if (eq (handoff-model-state model) :ready)
                     (handoff-model-begin writer model quantum)
                     (handoff-model-finish writer model)))
              (otherwise (error \"Operazione dell'oracolo inattesa.\"))))
          (handoff-model-finish writer model)
          (if (handoff-model-items model)
              (is (equal (handoff-model-items model) (handoff-drain writer capacity)))
              (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                       :writer-not-ready)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-CON-001-handoff-foreign-thread-cannot-use-lease
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (threads nil))
    (handoff-check-enqueue writer :original 1 :schedule)
    (unwind-protect
         (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
           (push (execution-thread
                  \"handoff foreign owner\"
                  (lambda ()
                    (let ((target (vector :untouched)))
                      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                               :writer-not-ready)
                      (signals invalid-argument
                        (arcdocdb.execution:preleva-lavori-writer writer lease target 0 1)
                        :writer-lease)
                      (signals invalid-argument
                        (arcdocdb.execution:termina-tratto-writer writer lease) :writer-lease)
                      (is (equalp target #(:untouched)))
                      (handoff-check-enqueue writer :producer 2 :queued)
                      :ok))) threads)
           (execution-join (first threads))
           (handoff-check-pop writer lease (vector nil nil) 0 2 '(:original :producer) :messages)
           (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-002-handoff-transfers-successive-slices-between-reused-threads
  (let* ((waves 4)
         (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (messages (make-array waves)) (first-go (sb-thread:make-semaphore))
         (second-go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore))
         (owners (make-array 2 :initial-element nil)) (threads nil))
    (dotimes (wave waves) (setf (svref messages wave) (list (vector wave 0) (vector wave 1))))
    (unwind-protect
         (progn
           (dotimes (worker 2)
             (let ((index worker))
               (push (execution-thread
                      \"handoff successive owner\"
                      (lambda ()
                        (setf (svref owners index) sb-thread:*current-thread*)
                        (dotimes (wave waves)
                          (execution-wait (if (zerop index) first-go second-go))
                          (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                            (handoff-check-pop writer lease (vector :untouched) 0 1
                                               (list (nth index (svref messages wave))) :messages)
                            (is (eq (if (zerop index) :schedule :idle)
                                    (arcdocdb.execution:termina-tratto-writer writer lease))))
                          (sb-thread:signal-semaphore (if (zerop index) second-go done)))
                        :ok)) threads)))
           (dotimes (wave waves)
             (handoff-check-enqueue writer (first (svref messages wave)) 1 :schedule)
             (handoff-check-enqueue writer (second (svref messages wave)) 2 :queued)
             (sb-thread:signal-semaphore first-go)
             (execution-wait done))
           (dolist (thread threads) (execution-join thread))
           (is (not (eq (svref owners 0) (svref owners 1))))
           (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                    :writer-not-ready))
      (sb-thread:signal-semaphore first-go)
      (sb-thread:signal-semaphore second-go)
      (execution-stop-threads threads))))

(defun handoff-wave-items (series wave)
  \"Identità e CRC atteso costruiti prima dei thread, lista nell'ordine accettato.\"
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 31) (* wave 7) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun handoff-wave-producer (writer messages permission published second-permission second-published)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait permission)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait second-permission)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore second-published)))
  :ok)

(defun handoff-wave-check-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4)
           (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun handoff-wave-consumer (writer messages permission taken finish drained results)
  (dotimes (wave (length messages))
    (execution-wait permission)
    (let* ((items (svref messages wave)) (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-wave-check-message writer lease (first items))
      (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
      (sb-thread:signal-semaphore taken)
      (execution-wait finish)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (loop for item in (rest (svref messages wave)) for last = (eq item (third (svref messages wave)))
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (handoff-wave-check-message writer lease item)
               (is (eq (if last :idle :schedule)
                       (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (setf (svref results wave) :verified)
    (sb-thread:signal-semaphore drained))
  :ok)

(defun handoff-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun handoff-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun handoff-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun handoff-start-four-workers (writers messages semaphores results)
  (let ((threads nil))
    (dotimes (series 2 threads)
      (let ((s series))
        (push (execution-thread
               \"handoff reused producer\"
               (lambda ()
                 (handoff-wave-producer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                  (svref (svref semaphores 4) s) (svref (svref semaphores 5) s)))) threads)
        (push (execution-thread
               \"handoff reused consumer\"
               (lambda ()
                 (handoff-wave-consumer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                  (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                  (svref results s)))) threads)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-handoff-reuses-four-workers-across-independent-series-waves
  (let* ((waves 6)
         (writers (vector (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)
                          (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (handoff-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (handoff-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (handoff-start-four-workers writers messages semaphores results))
           (is (= 4 (length threads)))
           (dotimes (wave waves)
             (handoff-pair-signal (svref semaphores 0))
             (handoff-pair-wait (svref semaphores 1))
             (handoff-pair-signal (svref semaphores 2))
             (handoff-pair-wait (svref semaphores 3))
             (handoff-pair-signal (svref semaphores 4))
             (handoff-pair-wait (svref semaphores 5))
             ;; FI: A conserva guard e lease; B termina due tratti aggiuntivi.
             (let ((queue-a (arcdocdb.execution::writer-programmabile-queue (svref writers 0))))
               (with-execution-guard (queue-a)
                 (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
                 (execution-wait (svref (svref semaphores 7) 1))
                 (is (eq :verified (svref (svref results 1) wave)))))
             (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
             (execution-wait (svref (svref semaphores 7) 0))
             (is (eq :verified (svref (svref results 0) wave))))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series)))
             (signals resource-exhausted
               (arcdocdb.execution:inizia-tratto-writer (svref writers series)) :writer-not-ready))
           (format t \"  Handoff: 4 thread riusati, ~D ondate, ~D messaggi, 2 Serie indipendenti.~%\"
                   waves (* waves 2 3)))
      (dotimes (i 8) (handoff-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))
")
  (:PATH #A((26) BASE-CHAR . "tests/execution/ready.lisp") :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e" :GIT-BLOB
   "9f81552333f86fe0b20f2d5e8ba48b20634f5a09" :TEXT
   ";;;; Liste FIFO indipendenti; i writer sono riferimenti opachi per la lista pronta.
;;;; Ogni riferimento delle prove pubbliche viene da :schedule ed è completato.
;;;; I semafori appartengono solo alla fixture e hanno timeout tramite execution-wait.
(in-package #:arcdocdb.execution.tests)

(defun ready-test-writer ()
  (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 1))

(defun ready-prepare-fixture-writer (&optional (writer (ready-test-writer)))
  \"Un unico payload corrisponde a un obbligo :schedule del writer idle.\"
  (handoff-check-enqueue writer :ready-fixture 1 :schedule)
  writer)

(defun ready-complete-fixture-writer (writer)
  \"Consuma un obbligo dell'oracolo pubblico; il writer torna idle prima del riuso.\"
  (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
    (handoff-check-pop writer lease (vector nil) 0 1 '(:ready-fixture) :messages)
    (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))

(defun ready-check-publish (ready shard writer expected-count)
  (is (= expected-count (arcdocdb.execution:pubblica-writer-pronto ready shard writer))))

(defun ready-check-take (ready start expected expected-status expected-next)
  (multiple-value-bind (writer status next)
      (arcdocdb.execution:preleva-writer-pronto ready start)
    (is (eq writer expected))
    (is (eq status expected-status))
    (is (= next expected-next))
    next))

(defun ready-check-complete-take (ready start expected expected-status expected-next)
  (let ((next (ready-check-take ready start expected expected-status expected-next)))
    (when expected (ready-complete-fixture-writer expected))
    next))

(defun ready-model-publish (ready model shard writer capacity)
  (let ((items (svref model shard)))
    (if (= (length items) capacity)
        (signals resource-exhausted
          (arcdocdb.execution:pubblica-writer-pronto ready shard writer) :ready-queue-full)
        (progn
          (ready-check-publish ready shard writer (1+ (length items)))
          (setf (svref model shard) (append items (list writer)))
          t))))

(defun ready-model-take (ready model start &optional busy-shards)
  \"Primo riferimento nelle liste FIFO, senza leggere indici/count del prodotto.\"
  (let ((shards (length model)))
    (dotimes (distance shards)
      (let* ((shard (mod (+ start distance) shards)) (items (svref model shard)))
        (when (and items (not (member shard busy-shards)))
          (setf (svref model shard) (rest items))
          (return-from ready-model-take
            (values (ready-check-complete-take ready start (first items) :writer
                                              (mod (1+ shard) shards))
                    (first items))))))
    (values (ready-check-take ready start nil (if busy-shards :busy :empty)
                             (mod (1+ start) shards)) nil)))

(defun ready-test-partition (ready shard)
  \"Accessor privato usato solo per FI, mai per l'oracolo FIFO.\"
  (svref (arcdocdb.execution::lista-writer-pronti-partitions ready) shard))

(defun ready-call-with-guards (partitions thunk)
  \"FI: un CAS per guard, rilascio anche se un'asserzione della fixture fallisce.\"
  (let ((thread sb-thread:*current-thread*) (owned nil))
    (unwind-protect
         (progn
           (dolist (partition partitions)
             (is (null (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) nil thread)))
             (push partition owned))
           (funcall thunk))
      (dolist (partition owned)
        (is (eq thread (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) thread nil)))))))

(defun ready-fi-snapshot (partition)
  \"Immagine per rifiuti/FI, senza usarla come ordine FIFO atteso.\"
  (list (arcdocdb.execution::partizione-pronta-head partition)
        (arcdocdb.execution::partizione-pronta-tail partition)
        (arcdocdb.execution::partizione-pronta-count partition)
        (arcdocdb.execution::partizione-pronta-guard partition)
        (copy-seq (arcdocdb.execution::partizione-pronta-slots partition))))

(defun ready-pool-publish (ready model writers phases homes index shard capacity)
  \"Pool dell'oracolo: full conserva pending; published non viene ripubblicato.\"
  (case (svref phases index)
    (:idle
     (ready-prepare-fixture-writer (svref writers index))
     (setf (svref phases index) :pending (svref homes index) shard))
    (:pending nil)
    (:published (return-from ready-pool-publish nil))
    (otherwise (error \"Fase dell'oracolo pronta inattesa.\")))
  (when (ready-model-publish ready model (svref homes index) (svref writers index) capacity)
    (setf (svref phases index) :published)))

(defun ready-pool-take (ready model writers phases start)
  (multiple-value-bind (next writer) (ready-model-take ready model start)
    (when writer
      (let ((index (position writer writers :test #'eq)))
        (is index)
        (is (eq (svref phases index) :published))
        (setf (svref phases index) :idle)))
    next))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-ready-configuration-and-limits
  (dolist (bad '(0 -1 65 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards bad :capacity 3)
      :ready-configuration))
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity bad)
      :ready-configuration))
  (dolist (limits '((1 65536) (64 1)))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti
                  :shards (first limits) :capacity (second limits)))
          (writer (ready-test-writer)))
      (dotimes (shard (first limits))
        (ready-prepare-fixture-writer writer)
        (ready-check-publish ready shard writer 1)
        (ready-check-complete-take ready shard writer :writer
                                   (mod (1+ shard) (first limits))))))
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti)) (writers (make-array 1025)))
    (dotimes (i 1025) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (i 1024) (ready-check-publish ready 3 (svref writers i) (1+ i)))
    (signals resource-exhausted
      (arcdocdb.execution:pubblica-writer-pronto ready 3 (svref writers 1024)) :ready-queue-full)
    (ready-check-complete-take ready 0 (svref writers 0) :writer 0)
    (ready-check-publish ready 3 (svref writers 1024) 1024)
    (loop for i from 1 below 1025
          do (ready-check-complete-take ready 0 (svref writers i) :writer 0))
    (ready-check-take ready 3 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-shard-and-writer-preflight
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
        (writer (ready-prepare-fixture-writer)))
    (ready-check-publish ready 1 writer 1)
    (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready bad writer)
               :ready-target)
      (signals invalid-argument (arcdocdb.execution:preleva-writer-pronto ready bad)
               :ready-target))
    (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready 1 bad)
               :ready-writer))
    (ready-check-complete-take ready 0 writer :writer 2)
    (ready-check-take ready 2 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004
(deftest test-REQ-CON-001-ready-per-shard-fifo-wrap-and-private-opaque-ring
  (dolist (shards '(1 2 3 7))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards shards :capacity 3))
          (model (make-array shards :initial-element nil)) (cursor 0))
      (dotimes (round 31)
        (dotimes (shard shards)
          (loop repeat (- 3 (length (svref model shard)))
                do (ready-model-publish ready model shard (ready-prepare-fixture-writer) 3)))
        (dotimes (i shards) (setf cursor (ready-model-take ready model cursor))))
      (loop repeat (* 3 shards) do (setf cursor (ready-model-take ready model cursor)))
      (is (every #'null model))))
  ;; FI di ring isolato, fuori dal protocollo handoff: nessuna membership/dedup.
  (let ((partition (arcdocdb.execution::%make-partizione-pronta (vector nil nil) 2))
        (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (is (= 1 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (is (= 2 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (dotimes (i 2)
         (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
           (is (eq actual writer)) (is (eq status :writer))))
       (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
         (is (null actual)) (is (eq status :empty)))))))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-cursor-rotates-first-choice-and-empty-scan
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (writers (make-array 6))
         (cursor 0))
    (dotimes (i 6) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (shard 3)
      (dotimes (i 2) (ready-check-publish ready shard (svref writers (+ (* shard 2) i)) (1+ i))))
    (dotimes (turn 6)
      (let ((shard (mod turn 3)))
        (setf cursor (ready-check-complete-take ready cursor
                                               (svref writers (+ (* shard 2) (floor turn 3)))
                                               :writer (mod (1+ shard) 3)))))
    (dotimes (turn 6)
      (let ((next (mod (1+ cursor) 3)))
        (setf cursor (ready-check-take ready cursor nil :empty next))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-001-ready-seeded-independent-lists-and-cursors
  (let ((seed #x7213bc08))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((shards (1+ (mod (ash (next) -8) 7)))
               (capacity (1+ (mod (ash (next) -8) 9)))
               (ready (arcdocdb.execution:crea-lista-writer-pronti
                       :shards shards :capacity capacity))
               (model (make-array shards :initial-element nil))
               (writers (make-array 11)) (phases (make-array 11 :initial-element :idle))
               (homes (make-array 11 :initial-element 0)) (cursor 0))
          (dotimes (i 11) (setf (svref writers i) (ready-test-writer)))
          (dotimes (step 1000)
            (if (< (mod (ash (next) -8) 5) 3)
                (ready-pool-publish ready model writers phases homes
                                    (mod (ash (next) -8) 11) (mod (ash (next) -8) shards) capacity)
                (setf cursor (ready-pool-take ready model writers phases
                                              (if (evenp step) cursor
                                                  (mod (ash (next) -8) shards))))))
          (loop repeat (* shards capacity)
                do (setf cursor (ready-pool-take ready model writers phases cursor)))
          (is (every #'null model))
          (dotimes (i 11)
            (when (eq (svref phases i) :pending)
              (ready-pool-publish ready model writers phases homes i (svref homes i) capacity)
              (is (eq (svref phases i) :published))
              (setf cursor (ready-pool-take ready model writers phases (svref homes i)))))
          (is (every (lambda (phase) (eq phase :idle)) phases)))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-full-preserves-scheduling-obligation
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (blocker (ready-prepare-fixture-writer)) (writer (ready-test-writer)) (target (vector nil nil)))
    (ready-check-publish ready 0 blocker 1)
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
               :ready-queue-full)
      (is (eq pending :schedule))
      (handoff-check-enqueue writer :b 2 :queued)
      (ready-check-complete-take ready 0 blocker :writer 0)
      (ready-check-publish ready 0 writer 1)
      (setf pending nil)
      (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:a) :messages)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-publish ready 0 writer 1)
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:b) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-dequeued-reference-survives-begin-busy
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (handoff-check-enqueue writer :once 1 :schedule)
    (ready-check-publish ready 0 writer 1)
    (multiple-value-bind (dequeued status cursor)
        (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (eq dequeued writer)) (is (eq status :writer)) (is (zerop cursor))
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer dequeued)
                 :writer-queue-busy))
      ;; Nessuna ripubblicazione: il caller conserva il riferimento estratto.
      (ready-check-take ready 0 nil :empty 0)
      (let ((lease (arcdocdb.execution:inizia-tratto-writer dequeued)))
        (handoff-check-pop dequeued lease (vector nil) 0 1 '(:once) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer dequeued lease)))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-ready-skips-busy-home-and-preserves-local-ring
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (a (ready-prepare-fixture-writer)) (b (ready-prepare-fixture-writer))
         (refused (ready-prepare-fixture-writer))
         (home (ready-test-partition ready 0)))
    (ready-check-publish ready 0 a 1)
    (ready-check-publish ready 2 b 1)
    (ready-call-with-guards
     (list home)
     (lambda ()
       (let ((before (ready-fi-snapshot home)))
         (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 refused)
                  :ready-queue-busy)
         (ready-check-complete-take ready 0 b :writer 0)
         (ready-check-take ready 0 nil :busy 1)
         (is (equalp before (ready-fi-snapshot home))))))
    (ready-check-complete-take ready 0 a :writer 1)
    (ready-check-publish ready 0 refused 1)
    (ready-check-complete-take ready 0 refused :writer 1)
    (ready-check-take ready 0 nil :empty 1)))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-busy-observations-and-scan-order-oracle
  (dotimes (pattern 8)
    (dotimes (start 3)
      (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1))
             (model (make-array 3 :initial-element nil))
             (busy (loop for i below 3 when (logbitp i pattern) collect i))
             (partitions (mapcar (lambda (i) (ready-test-partition ready i)) busy)))
        (dotimes (shard 3)
          (when (evenp shard)
            (ready-model-publish ready model shard (ready-prepare-fixture-writer) 1)))
        (ready-call-with-guards
         partitions
         (lambda ()
           (dotimes (attempt 4) (ready-model-take ready model start busy))))
        (dotimes (attempt 3) (ready-model-take ready model start))
        (is (every #'null model))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-busy-publication-retains-obligation-and-payload
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (partition (ready-test-partition ready 0)))
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :once)
      (is (= count 1)) (is (eq pending :schedule))
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (ready-fi-snapshot partition)))
           (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
                    :ready-queue-busy)
           (is (equalp before (ready-fi-snapshot partition))))))
      (is (eq pending :schedule))
      (ready-check-publish ready 0 writer 1)
      (setf pending nil) (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease (vector nil) 0 1 '(:once) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

(defun ready-fi-bad-partition (fault)
  \"FI quiescente: constructor privato senza factory, tipi degli slot rispettati.\"
  (let* ((capacity (case fault (:capacity-zero 0) (:capacity-big 65537) (otherwise 2)))
         (size (if (member fault '(:capacity-zero :capacity-big)) 0
                   (if (eq fault :slots-length) 1 2)))
         (partition (arcdocdb.execution::%make-partizione-pronta
                     (make-array size :initial-element nil) capacity)))
    (case fault
      ((:capacity-zero :capacity-big :slots-length) nil)
      (:head (setf (arcdocdb.execution::partizione-pronta-head partition) 2))
      (:tail (setf (arcdocdb.execution::partizione-pronta-tail partition) 2))
      (:count (setf (arcdocdb.execution::partizione-pronta-count partition) 3))
      (:relation (setf (arcdocdb.execution::partizione-pronta-tail partition) 1))
      (otherwise (error \"FI pronta sconosciuta: ~S\" fault)))
    partition))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-ring-shapes
  (dolist (fault '(:capacity-zero :capacity-big :slots-length :head :tail :count :relation))
    (let* ((partition (ready-fi-bad-partition fault))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
           (before (ready-fi-snapshot partition)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution::%check-forma-pronta partition) :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
      (is (equalp before (ready-fi-snapshot partition))))))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-partition-arrays
  (dolist (partitions (list #() (make-array 65 :initial-element nil) (vector nil)))
    (let ((ready (arcdocdb.execution::%make-lista-writer-pronti partitions)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-inconsistent-occupied-and-free-slots
  (dolist (bad (list nil :foreign (vector :foreign)))
    (let* ((partition (arcdocdb.execution::%make-partizione-pronta (vector bad nil) 2))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition))))
      (setf (arcdocdb.execution::partizione-pronta-count partition) 1
            (arcdocdb.execution::partizione-pronta-tail partition) 1)
      (let ((before (ready-fi-snapshot partition)))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
        (is (equalp before (ready-fi-snapshot partition))))))
  (let* ((partition (arcdocdb.execution::%make-partizione-pronta
                     (vector (ready-test-writer) nil) 2))
         (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
         (before (ready-fi-snapshot partition)))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
      :ready-queue-invariant)
    (is (equalp before (ready-fi-snapshot partition)))))

(defun ready-check-unowned-helpers (partition writer)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%check-pronta partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%pubblica-pronto partition writer) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%preleva-pronto partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%rilascia-guard-pronta partition sb-thread:*current-thread*)
    :ready-queue-guard))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-helpers-reject-missing-and-foreign-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (partition (ready-test-partition ready 0)) (writer (ready-test-writer))
         (before (ready-fi-snapshot partition)) (threads nil))
    (ready-check-unowned-helpers partition writer)
    (unwind-protect
         (ready-call-with-guards
          (list partition)
          (lambda ()
            (push (execution-thread
                   \"ready foreign guard\"
                   (lambda ()
                     (ready-check-unowned-helpers partition writer)
                     (is (null (arcdocdb.execution::%prendi-guard-pronta partition)))
                     (multiple-value-bind (actual status) (arcdocdb.execution::%prova-pronta partition)
                       (is (null actual)) (is (eq status :busy)))
                     :ok)) threads)
            (execution-join (first threads))))
      (execution-stop-threads threads))
    (is (equalp before (ready-fi-snapshot partition)))
    (ready-prepare-fixture-writer writer)
    (ready-check-publish ready 0 writer 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-ready-handoff-before-after-release-and-next-wave
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
        (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (dotimes (wave 4)
      (let ((first (vector wave :initial)) (before (vector wave :before))
            (after (vector wave :after)))
        (handoff-check-enqueue writer first 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list first) :messages)
          (handoff-check-pop writer lease target 0 1 nil :empty)
          (handoff-check-enqueue writer before 1 :queued)
          (ready-check-take ready 0 nil :empty 1)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list before) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (handoff-check-enqueue writer after 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list after) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-take ready 1 nil :empty 0)))))

(defun ready-wave-items (series wave)
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 37) (* wave 11) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun ready-read-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4) (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun ready-wave-producer (ready home writer messages go published third-go third-published)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait go)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (ready-check-publish ready home writer 1)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait third-go)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore third-published)))
  :ok)

(defun ready-wave-consumer (ready home writer messages go taken finish drained results)
  (let ((cursor (mod (1+ home) 2)))
    (dotimes (wave (length messages))
      (execution-wait go)
      (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (ready-read-message writer lease (first (svref messages wave)))
        (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
        (sb-thread:signal-semaphore taken)
        (execution-wait finish)
        (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease)))
        (ready-check-publish ready home writer 1))
      (loop for item in (rest (svref messages wave)) for sequence from 1
            do (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
               (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                 (ready-read-message writer lease item)
                 (is (eq (if (= sequence 2) :idle :schedule)
                         (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (unless (= sequence 2) (ready-check-publish ready home writer 1))))
      (setf (svref results wave) :verified)
      (sb-thread:signal-semaphore drained)))
  :ok)

(defun ready-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun ready-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun ready-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun ready-start-wave-workers (ready writers messages semaphores results producers)
  (let ((threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (series 2)
             (let ((s series))
               (let ((producer
                       (execution-thread
                        \"ready reused producer\"
                        (lambda ()
                          (ready-wave-producer
                           ready s (svref writers s) (svref messages s)
                           (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                           (svref (svref semaphores 4) s) (svref (svref semaphores 5) s))))))
                 (push producer threads) (setf (svref producers s) producer))
               (push (execution-thread
                      \"ready reused consumer\"
                      (lambda ()
                        (ready-wave-consumer
                         ready s (svref writers s) (svref messages s)
                         (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                         (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                         (svref results s)))) threads)))
           (setf complete t)
           threads)
      (unless complete (execution-stop-threads threads)))))

(defun ready-drive-wave (ready semaphores results producers wave)
  \"Ordini causali controllati: B progredisce mentre la guard dello shard A è ferma.\"
  (ready-pair-signal (svref semaphores 0))
  (ready-pair-wait (svref semaphores 1))
  (ready-call-with-guards
   (list (ready-test-partition ready 0))
   (lambda ()
     (sb-thread:signal-semaphore (svref (svref semaphores 2) 1))
     (execution-wait (svref (svref semaphores 3) 1))
     (is (every #'sb-thread:thread-alive-p producers))
     (sb-thread:signal-semaphore (svref (svref semaphores 4) 1))
     (execution-wait (svref (svref semaphores 5) 1))
     (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
     (execution-wait (svref (svref semaphores 7) 1))
     (is (eq :verified (svref (svref results 1) wave)))
     (ready-check-take ready 0 nil :busy 1)))
  (sb-thread:signal-semaphore (svref (svref semaphores 2) 0))
  (execution-wait (svref (svref semaphores 3) 0))
  (is (sb-thread:thread-alive-p (svref producers 0)))
  (sb-thread:signal-semaphore (svref (svref semaphores 4) 0))
  (execution-wait (svref (svref semaphores 5) 0))
  (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
  (execution-wait (svref (svref semaphores 7) 0))
  (is (eq :verified (svref (svref results 0) wave)))
  (ready-check-take ready (mod wave 2) nil :empty (mod (1+ wave) 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-ready-reused-workers-live-producers-and-independent-shards
  (let* ((waves 6)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writers (vector (ready-test-writer) (ready-test-writer)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (producers (vector nil nil)) (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (ready-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (ready-start-wave-workers ready writers messages semaphores results producers))
           (is (= 4 (length threads)))
           (dotimes (wave waves) (ready-drive-wave ready semaphores results producers wave))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series))))
           (format t \"  Ready: 4 thread riusati, ~D ondate, ~D payload, shard fermata e stealing.~%\"
                   waves (* 2 waves 3)))
      (dotimes (i 8) (ready-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))

(defun ready-competing-consumer (ready expected go done results index waves)
  (dotimes (wave waves)
    (execution-wait go)
    (multiple-value-bind (writer status cursor) (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (zerop cursor))
      (if (eq status :writer)
          (progn (is (eq writer expected)) (ready-complete-fixture-writer writer))
          (progn (is (null writer)) (is (member status '(:empty :busy)))))
      (setf (svref results index) status))
    (sb-thread:signal-semaphore done))
  :ok)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-ready-competing-consumers-take-one-reference-per-wave
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (go (ready-semaphore-pair)) (done (ready-semaphore-pair))
         (results (vector nil nil)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (consumer 2)
             (let ((index consumer))
               (push (execution-thread
                      \"ready competing reused consumer\"
                      (lambda () (ready-competing-consumer ready writer (svref go index)
                                                           (svref done index) results index waves))) threads)))
           (dotimes (wave waves)
             (ready-prepare-fixture-writer writer)
             (ready-check-publish ready 0 writer 1)
             (ready-pair-signal go)
             (ready-pair-wait done)
             (is (= 1 (count :writer results)))
             (is (= 1 (+ (count :empty results) (count :busy results))))
             (ready-check-take ready 0 nil :empty 0))
           (dolist (thread threads) (execution-join thread))
           (format t \"  Ready: 2 consumer riusati, ~D ondate, un riferimento estratto per ondata.~%\" waves))
      (ready-pair-signal go)
      (execution-stop-threads threads))))
")
  (:PATH #A((34) BASE-CHAR . "tests/execution/ready-recycle.lisp") :BYTES 30075
   :SHA256 "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae"
   :GIT-BLOB "1dff8707436ca52f20f62e9946621ca1037f33d2" :TEXT
   ";;;; Ricircolo degli obblighi unici :schedule; il ring trasferisce un riferimento.
;;;; Oracoli pubblici: ogni writer pubblicato proviene da handoff ed è completato.
;;;; FI private e duplicati opachi sono dichiarati fuori dal protocollo handoff.
;;;; Thread/semafori/retry bounded appartengono soltanto alla fixture.
(in-package #:arcdocdb.execution.tests)

(defun recycle-check (ready shard writer expected expected-status expected-count)
  (multiple-value-bind (actual status count)
      (arcdocdb.execution:ricircola-writer-pronto ready shard writer)
    (is (eq actual expected))
    (is (eq status expected-status))
    (is (= count expected-count))
    actual))

(defun recycle-fi-complete (writer)
  \"Completa il solo payload della fixture dopo il trasferimento al caller.\"
  (ready-complete-fixture-writer writer))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-001-recycle-room-publishes-and-preserves-fifo
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 3))
        (writers (vector (ready-prepare-fixture-writer)
                         (ready-prepare-fixture-writer)
                         (ready-prepare-fixture-writer))))
    (dotimes (i 3) (recycle-check ready 1 (svref writers i) nil :published (1+ i)))
    (dotimes (i 3) (ready-check-complete-take ready 0 (svref writers i) :writer 2))
    (ready-check-take ready 2 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-capacity-one-transfers-old-and-keeps-new
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (a (ready-test-writer)) (b (ready-test-writer)))
    (dotimes (wave 31)
      (ready-prepare-fixture-writer a)
      (ready-prepare-fixture-writer b)
      (recycle-check ready 0 a nil :published 1)
      (recycle-fi-complete (recycle-check ready 0 b a :writer 1))
      (ready-check-complete-take ready 0 b :writer 0)
      (ready-check-take ready 0 nil :empty 0))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-recycle-full-wrap-preserves-independent-list-order
  (dolist (capacity '(1 2 3 9))
    (dolist (shards '(1 4))
      (let ((ready (arcdocdb.execution:crea-lista-writer-pronti
                    :shards shards :capacity capacity))
            (model (make-array shards :initial-element nil)))
        (dotimes (shard shards)
          (dotimes (i capacity)
            (let ((writer (ready-prepare-fixture-writer)))
              (recycle-check ready shard writer nil :published (1+ i))
              (setf (svref model shard) (append (svref model shard) (list writer))))))
        (dotimes (round (+ 3 (* capacity 4)))
          (dotimes (shard shards)
            (let* ((writer (ready-prepare-fixture-writer))
                   (items (svref model shard)))
              (recycle-fi-complete
               (recycle-check ready shard writer (first items) :writer capacity))
              (setf (svref model shard) (append (rest items) (list writer))))))
        (dotimes (shard shards)
          (dolist (writer (svref model shard))
            (ready-check-complete-take ready shard writer :writer (mod (1+ shard) shards)))
          (setf (svref model shard) nil))
        (is (every #'null model))
        (ready-check-take ready 0 nil :empty (mod 1 shards))))))

(defun recycle-model-transfer (ready lists writers phases home index capacity)
  \"FIFO attesa con liste; il risultato full diventa owned, il nuovo published.\"
  (let* ((writer (svref writers index)) (items (svref lists home))
         (full (= (length items) capacity)) (old (and full (first items))))
    (is (eq (svref phases index) :owned))
    (recycle-check ready home writer old (if full :writer :published)
                   (if full capacity (1+ (length items))))
    (setf (svref lists home) (append (if full (rest items) items) (list writer))
          (svref phases index) :published)
    (when old
      (let ((old-index (position old writers :test #'eq)))
        (is old-index)
        (is (eq (svref phases old-index) :published))
        (setf (svref phases old-index) :owned)))))

(defun recycle-model-enqueue (ready lists writers phases messages homes index payload capacity)
  \"Un idle genera un solo obbligo; le altre fasi accettano senza ripubblicare.\"
  (let ((items (svref messages index)) (phase (svref phases index)))
    (when (< (length items) 3)
      (handoff-check-enqueue (svref writers index) payload (1+ (length items))
                             (if (eq phase :idle) :schedule :queued))
      (setf (svref messages index) (append items (list payload)))
      (when (eq phase :idle)
        (setf (svref phases index) :owned)
        (recycle-model-transfer ready lists writers phases (svref homes index) index capacity))
      t)))

(defun recycle-model-take (ready lists writers phases start)
  \"La scelta viene dalle liste, senza head/tail/count o stato writer privati.\"
  (let ((shards (length lists)))
    (dotimes (distance shards)
      (let* ((home (mod (+ start distance) shards)) (items (svref lists home)))
        (when items
          (let ((index (position (first items) writers :test #'eq)))
            (is index) (is (eq (svref phases index) :published))
            (ready-check-take ready start (first items) :writer (mod (1+ home) shards))
            (setf (svref lists home) (rest items) (svref phases index) :owned)
            (return-from recycle-model-take index)))))
    (ready-check-take ready start nil :empty (mod (1+ start) shards))
    nil))

(defun recycle-model-process (ready lists writers phases messages homes index capacity)
  \"Un quantum di un payload; ogni :schedule viene trasferito una sola volta.\"
  (when (eq (svref phases index) :owned)
    (let* ((writer (svref writers index)) (items (svref messages index))
           (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (is items)
      (handoff-check-pop writer lease (vector :left :untouched :right) 1 2
                         (list (first items)) :messages)
      (setf (svref messages index) (rest items))
      (let ((expected (if (rest items) :schedule :idle)))
        (is (eq expected (arcdocdb.execution:termina-tratto-writer writer lease)))
        (if (eq expected :schedule)
            (recycle-model-transfer ready lists writers phases (svref homes index) index capacity)
            (setf (svref phases index) :idle)))
      t)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-recycle-seeded-obligations-and-payloads-exactly-once
  (let ((seed #x1cf80d29))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dolist (capacity '(1 2 3 9))
        (dolist (shards '(1 4))
          (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti
                         :shards shards :capacity capacity))
                 (lists (make-array shards :initial-element nil))
                 (writers (make-array 11)) (phases (make-array 11 :initial-element :idle))
                 (messages (make-array 11 :initial-element nil)) (homes (make-array 11))
                 (accepted 0) (delivered 0))
            (dotimes (i 11)
              (setf (svref writers i) (ready-test-writer) (svref homes i) (mod i shards)))
            (dotimes (step 1000)
              (let ((index (mod (ash (next) -8) 11)))
                (case (mod (ash (next) -8) 4)
                  ((0 1)
                   (when (recycle-model-enqueue ready lists writers phases messages homes index
                                                (vector capacity shards step) capacity)
                     (incf accepted)))
                  (2 (when (recycle-model-process ready lists writers phases messages homes index
                                                  capacity)
                       (incf delivered)))
                  (3 (recycle-model-take ready lists writers phases
                                         (mod (ash (next) -8) shards))))))
            (loop repeat (1+ accepted)
                  for index = (or (position :owned phases)
                                  (recycle-model-take ready lists writers phases
                                                       (mod (next) shards)))
                  while index
                  do (is (recycle-model-process ready lists writers phases messages homes index
                                                capacity))
                     (incf delivered))
            (is (= accepted delivered))
            (is (every #'null lists)) (is (every #'null messages))
            (is (every (lambda (phase) (eq phase :idle)) phases))
            (ready-check-take ready 0 nil :empty (mod 1 shards))))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-all-consumers-reschedule-after-producer-refills-full
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (a (ready-test-writer)) (b (ready-test-writer))
         (c (ready-prepare-fixture-writer)) (d (ready-prepare-fixture-writer)))
    (dolist (writer (list a b))
      (handoff-check-enqueue writer :first 1 :schedule)
      (handoff-check-enqueue writer :second 2 :queued))
    (ready-check-publish ready 0 a 1) (ready-check-publish ready 0 b 2)
    (ready-check-take ready 0 a :writer 0) (ready-check-take ready 0 b :writer 0)
    (let ((lease-a (arcdocdb.execution:inizia-tratto-writer a))
          (lease-b (arcdocdb.execution:inizia-tratto-writer b)))
      (handoff-check-pop a lease-a (vector nil) 0 1 '(:first) :messages)
      (handoff-check-pop b lease-b (vector nil) 0 1 '(:first) :messages)
      (ready-check-publish ready 0 c 1) (ready-check-publish ready 0 d 2)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer a lease-a)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer b lease-b))))
    ;; Tutti i consumer hanno un obbligo; il retry del vecchio publish non drena.
    (let ((ring-before (ready-fi-snapshot (ready-test-partition ready 0)))
          (a-before (handoff-fi-snapshot a)) (b-before (handoff-fi-snapshot b)))
      (dolist (writer (list a b))
        (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
                 :ready-queue-full))
      (is (equalp ring-before (ready-fi-snapshot (ready-test-partition ready 0))))
      (is (equalp a-before (handoff-fi-snapshot a)))
      (is (equalp b-before (handoff-fi-snapshot b))))
    ;; Nessun dequeue aggiuntivo prima delle due rotazioni: C/D passano al caller.
    (recycle-fi-complete (recycle-check ready 0 a c :writer 2))
    (recycle-fi-complete (recycle-check ready 0 b d :writer 2))
    (dolist (writer (list a b))
      (ready-check-take ready 0 writer :writer 0)
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (handoff-check-pop writer lease (vector nil) 0 1 '(:second) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-busy-retains-obligation-and-both-ring-shapes
  (dolist (full '(nil t))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
           (old (and full (ready-prepare-fixture-writer)))
           (writer (ready-test-writer)) (partition (ready-test-partition ready 0)))
      (when old (ready-check-publish ready 0 old 1))
      (handoff-check-enqueue writer :one 1 :schedule)
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((ring-before (ready-fi-snapshot partition))
               (writer-before (handoff-fi-snapshot writer)))
           (signals resource-exhausted
             (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-busy)
           (is (equalp ring-before (ready-fi-snapshot partition)))
           (is (equalp writer-before (handoff-fi-snapshot writer))))))
      (handoff-check-enqueue writer :two 2 :queued)
      (recycle-check ready 0 writer old (if full :writer :published) 1)
      (when old (recycle-fi-complete old))
      (ready-check-take ready 0 writer :writer 0)
      (is (equal '(:one :two) (handoff-drain writer 2)))
      (ready-check-take ready 0 nil :empty 0))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-shard-writer-preflight-before-held-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writer (ready-prepare-fixture-writer)) (partition (ready-test-partition ready 1)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (let ((before (ready-fi-snapshot partition)))
         (dolist (bad (list -1 2 nil 1.0 (1+ most-positive-fixnum)))
           (signals invalid-argument
             (arcdocdb.execution:ricircola-writer-pronto ready bad writer) :ready-target))
         (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
           (signals invalid-argument
             (arcdocdb.execution:ricircola-writer-pronto ready 1 bad) :ready-writer))
         (is (equalp before (ready-fi-snapshot partition))))))
    (recycle-check ready 1 writer nil :published 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-private-ring-and-partition-shapes-pre-mutation
  ;; FI quiescente su ring sacrificati; mai oracolo del protocollo pubblico.
  (dolist (fault '(:capacity-zero :capacity-big :slots-length :head :tail :count :relation))
    (let* ((partition (ready-fi-bad-partition fault))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
           (writer (ready-prepare-fixture-writer)) (before (ready-fi-snapshot partition)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
      (is (equalp before (ready-fi-snapshot partition)))
      (recycle-fi-complete writer)))
  (dolist (partitions (list #() (make-array 65 :initial-element nil) (vector nil)))
    (let ((ready (arcdocdb.execution::%make-lista-writer-pronti partitions))
          (writer (ready-prepare-fixture-writer)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
      (recycle-fi-complete writer))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-malformed-full-head-and-free-tail-pre-mutation
  ;; FI: le celle del ring privato non rappresentano obblighi pubblici validi.
  (dolist (fault '(:full-nil :full-foreign :free-occupied))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
           (partition (ready-test-partition ready 0))
           (writer (ready-prepare-fixture-writer))
           (slots (arcdocdb.execution::partizione-pronta-slots partition)))
      (if (eq fault :free-occupied)
          (setf (svref slots 0) :occupied)
          (setf (arcdocdb.execution::partizione-pronta-count partition) 2
                (svref slots 0) (if (eq fault :full-nil) nil :foreign)
                (svref slots 1) (ready-test-writer)))
      (let ((before (ready-fi-snapshot partition)) (writer-before (handoff-fi-snapshot writer)))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:ricircola-writer-pronto ready 0 writer) :ready-queue-invariant)
        (is (equalp before (ready-fi-snapshot partition)))
        (is (equalp writer-before (handoff-fi-snapshot writer))))
      (recycle-fi-complete writer)))
  ;; Precondizione del solo helper full, FI privata: un ring vuoto non si scambia.
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (partition (ready-test-partition ready 0)) (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (let ((before (ready-fi-snapshot partition)))
         (signals arcdocdb.conditions:invariant-violation
           (arcdocdb.execution::%scambia-pronto partition writer) :ready-recycle-full)
         (is (equalp before (ready-fi-snapshot partition))))))))

(defun recycle-check-unowned-helper (partition writer)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%ricircola-pronto partition writer) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%scambia-pronto partition writer) :ready-queue-guard))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-recycle-helper-rejects-missing-and-foreign-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (partition (ready-test-partition ready 0)) (writer (ready-prepare-fixture-writer))
         (before (ready-fi-snapshot partition)) (threads nil))
    (recycle-check-unowned-helper partition writer)
    (unwind-protect
         (ready-call-with-guards
          (list partition)
          (lambda ()
            (push (execution-thread
                   \"recycle foreign guard\"
                   (lambda () (recycle-check-unowned-helper partition writer) :ok)) threads)
            (execution-join (first threads))))
      (execution-stop-threads threads))
    (is (equalp before (ready-fi-snapshot partition)))
    (recycle-check ready 0 writer nil :published 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-004
(deftest test-REQ-CON-001-recycle-private-opaque-duplicate-is-outside-handoff-protocol
  ;; FI esclusivamente del helper: due riferimenti allo stesso writer violano
  ;; il protocollo handoff. Questo prova opacità del ring, non membership/dedup.
  (let ((partition (arcdocdb.execution::%make-partizione-pronta (vector nil) 1))
        (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (multiple-value-bind (actual status count)
           (arcdocdb.execution::%ricircola-pronto partition writer)
         (is (null actual)) (is (eq status :published)) (is (= count 1)))
       (multiple-value-bind (actual status count)
           (arcdocdb.execution::%ricircola-pronto partition writer)
         (is (eq actual writer)) (is (eq status :writer)) (is (= count 1)))
       (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
         (is (eq actual writer)) (is (eq status :writer)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-recycle-handoff-before-release-and-new-wave-without-cleanup
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3)))
    (dotimes (wave 4)
      (let ((first (vector wave :first)) (before (vector wave :before))
            (after (vector wave :after)) (blocker (ready-prepare-fixture-writer)))
        (handoff-check-enqueue writer first 1 :schedule)
        (recycle-check ready 0 writer nil :published 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list first) :messages)
          (handoff-check-pop writer lease (vector nil) 0 1 nil :empty)
          (handoff-check-enqueue writer before 1 :queued)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
        (recycle-check ready 0 blocker nil :published 1)
        (recycle-fi-complete (recycle-check ready 0 writer blocker :writer 1))
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list before) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        ;; Nessun cleanup del vecchio worker cancella il nuovo obbligo.
        (handoff-check-enqueue writer after 1 :schedule)
        (recycle-check ready 0 writer nil :published 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease (vector nil) 0 1 (list after) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-take ready 0 nil :empty 0)))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-recycle-returned-obligation-survives-begin-busy
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (old (ready-prepare-fixture-writer)) (new (ready-prepare-fixture-writer))
         (queue (arcdocdb.execution::writer-programmabile-queue old)))
    (recycle-check ready 0 old nil :published 1)
    (let ((owned (recycle-check ready 0 new old :writer 1)))
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer owned)
                 :writer-queue-busy))
      ;; Il riferimento old resta al caller; new resta nel ring senza ripubblicare old.
      (recycle-fi-complete owned)
      (ready-check-complete-take ready 0 new :writer 0))
    (ready-check-take ready 0 nil :empty 0)))

(defun recycle-wave-pop (writer expected expected-end)
  (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
    (ready-read-message writer lease expected)
    (is (eq expected-end (arcdocdb.execution:termina-tratto-writer writer lease)))))

(defun recycle-wave-message (wave writer sequence)
  (let ((buffer (execution-buffer 256 (+ (* wave 13) (* writer 31) sequence))))
    (vector writer wave sequence buffer (reference-crc buffer 0 256))))

(defun recycle-wave-consumer (ready writers messages semaphores attempts returned drained index waves)
  (dotimes (wave waves)
    (execution-wait (svref (svref semaphores 0) index))
    (let* ((writer (svref writers index))
           (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (ready-read-message writer lease (svref (svref messages wave) (* index 2)))
      (sb-thread:signal-semaphore (svref (svref semaphores 1) index))
      (execution-wait (svref (svref semaphores 2) index))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease)))
      (let ((owned nil))
        (dotimes (attempt 2)
          (when (plusp attempt) (execution-wait (svref (svref semaphores 2) index)))
          (handler-case
              (multiple-value-bind (actual status count)
                  (arcdocdb.execution:ricircola-writer-pronto ready 0 writer)
                (is (eq status :writer)) (is (= count 2))
                (is (member actual (list (svref writers 2) (svref writers 3)) :test #'eq))
                (setf owned actual (svref attempts index) :writer))
            (resource-exhausted (condition)
              (is (eq (error-reason condition) :ready-queue-busy))
              (setf (svref attempts index) :busy)))
          (sb-thread:signal-semaphore (svref (svref semaphores 3) index))
          (when owned (return)))
        (is owned)
        (let ((old-index (position owned writers :test #'eq)))
          (setf (svref returned index) owned)
          (recycle-wave-pop owned (svref (svref messages wave) (+ 4 (- old-index 2))) :idle)))
      (sb-thread:signal-semaphore (svref (svref semaphores 4) index)))
    ;; I drain sono autorizzati separatamente: la competizione misurata è FULL recycle.
    (execution-wait (svref (svref semaphores 5) index))
    (multiple-value-bind (writer status next) (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (eq status :writer)) (is (zerop next))
      (let ((old-index (position writer writers :test #'eq)))
        (is (member old-index '(0 1)))
        (setf (svref drained index) writer)
        (recycle-wave-pop writer (svref (svref messages wave) (1+ (* old-index 2))) :idle)))
    (sb-thread:signal-semaphore (svref (svref semaphores 6) index)))
  :ok)

(defun recycle-wave-producer (ready writers messages go filled finish waves)
  (dotimes (wave waves)
    (execution-wait go)
    (dotimes (i 2)
      (let ((writer (svref writers (+ 2 i))))
        (handoff-check-enqueue writer (svref (svref messages wave) (+ 4 i)) 1 :schedule)
        (ready-check-publish ready 0 writer (1+ i))))
    (sb-thread:signal-semaphore filled))
  (execution-wait finish)
  :ok)

(defun recycle-wave-drive (ready writers messages semaphores attempts returned drained
                          producer go filled wave)
  (dotimes (i 2)
    (let ((writer (svref writers i)))
      (handoff-check-enqueue writer (svref (svref messages wave) (* i 2)) 1 :schedule)
      (handoff-check-enqueue writer (svref (svref messages wave) (1+ (* i 2))) 2 :queued)
      (ready-check-publish ready 0 writer (1+ i))))
  ;; Il main trasferisce due riferimenti distinti ai consumer, prima del refill.
  (dotimes (i 2) (ready-check-take ready 0 (svref writers i) :writer 0))
  (ready-pair-signal (svref semaphores 0)) (ready-pair-wait (svref semaphores 1))
  (sb-thread:signal-semaphore go) (execution-wait filled)
  (is (sb-thread:thread-alive-p producer))
  (ready-pair-signal (svref semaphores 2)) (ready-pair-wait (svref semaphores 3))
  (is (<= (count :busy attempts) 1))
  (dotimes (i 2)
    (when (eq (svref attempts i) :busy)
      (sb-thread:signal-semaphore (svref (svref semaphores 2) i))
      (execution-wait (svref (svref semaphores 3) i))))
  (ready-pair-wait (svref semaphores 4))
  (is (every (lambda (status) (eq status :writer)) attempts))
  (is (not (eq (svref returned 0) (svref returned 1))))
  (dotimes (i 2)
    (sb-thread:signal-semaphore (svref (svref semaphores 5) i))
    (execution-wait (svref (svref semaphores 6) i)))
  (is (not (eq (svref drained 0) (svref drained 1))))
  (ready-check-take ready 0 nil :empty 0))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-recycle-two-competing-consumers-and-live-producer-reused
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (writers (vector (ready-test-writer) (ready-test-writer)
                          (ready-test-writer) (ready-test-writer)))
         (messages (make-array waves)) (semaphores (make-array 7))
         (attempts (vector nil nil)) (returned (vector nil nil)) (drained (vector nil nil))
         (go (sb-thread:make-semaphore)) (filled (sb-thread:make-semaphore))
         (finish (sb-thread:make-semaphore)) (threads nil) (producer nil))
    (dotimes (i 7) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (wave waves)
      (setf (svref messages wave)
            (vector (recycle-wave-message wave 0 0) (recycle-wave-message wave 0 1)
                    (recycle-wave-message wave 1 0) (recycle-wave-message wave 1 1)
                    (recycle-wave-message wave 2 0) (recycle-wave-message wave 3 0))))
    (unwind-protect
         (progn
           (setf producer (execution-thread
                           \"recycle live reused producer\"
                           (lambda () (recycle-wave-producer ready writers messages
                                                             go filled finish waves))))
           (push producer threads)
           (dotimes (i 2)
             (let ((index i))
               (push (execution-thread
                      \"recycle competing reused consumer\"
                      (lambda () (recycle-wave-consumer ready writers messages semaphores
                                                       attempts returned drained index waves))) threads)))
           (dotimes (wave waves)
             (recycle-wave-drive ready writers messages semaphores attempts returned drained
                                 producer go filled wave))
           (sb-thread:signal-semaphore finish)
           (dolist (thread threads) (execution-join thread))
           (format t \"  Recycle: 3 thread riusati, ~D ondate, ~D payload, ready FULL e busy bounded.~%\"
                   waves (* 6 waves)))
      (dotimes (i 7) (ready-pair-signal (svref semaphores i)))
      (sb-thread:signal-semaphore go) (sb-thread:signal-semaphore finish)
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-recycle-other-shard-progresses-while-first-guard-is-held
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (old-a (ready-prepare-fixture-writer)) (old-b (ready-prepare-fixture-writer))
         (new-a (ready-prepare-fixture-writer)) (new-b (ready-prepare-fixture-writer))
         (home-a (ready-test-partition ready 0)) (threads nil))
    (ready-check-publish ready 0 old-a 1) (ready-check-publish ready 1 old-b 1)
    (unwind-protect
         (ready-call-with-guards
          (list home-a)
          (lambda ()
            (let ((before (ready-fi-snapshot home-a)) (writer-before (handoff-fi-snapshot new-a)))
              (push (execution-thread
                     \"recycle independent shard\"
                     (lambda ()
                       (signals resource-exhausted
                         (arcdocdb.execution:ricircola-writer-pronto ready 0 new-a)
                         :ready-queue-busy)
                       (recycle-fi-complete (recycle-check ready 1 new-b old-b :writer 1))
                       (ready-check-complete-take ready 1 new-b :writer 0)
                       :ok)) threads)
              (execution-join (first threads))
              (is (equalp before (ready-fi-snapshot home-a)))
              (is (equalp writer-before (handoff-fi-snapshot new-a))))))
      (execution-stop-threads threads))
    (recycle-fi-complete (recycle-check ready 0 new-a old-a :writer 1))
    (ready-check-complete-take ready 0 new-a :writer 1)
    (ready-check-take ready 0 nil :empty 1)))
")
  (:PATH #A((31) BASE-CHAR . "tools/writer-recycle-bench.lisp") :BYTES 23962
   :SHA256 "4f0f1e2feef4079e6b4582a3d1380a05b6c3cf146bb331cc1ca1af08070a4d82"
   :GIT-BLOB "e41b25ceb84621af27f22f11f7ad4ee11bd4a1b8" :TEXT
   ";;;; Allocazioni seriali del ricircolo pronto composto con handoff e lista pronta; nessun I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-recycle-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-recycle.bench (:use #:cl))
(in-package #:arcdocdb.writer-recycle.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  \"Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità.\"
  (loop for path in (append '(#p\"arcdocdb.asd\" #p\"tools/writer-recycle-bench.lisp\")
                            (sort (directory \"src/**/*.lisp\") #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil \"~(~{~2,'0X~}~)\"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  \"Forza compilazione rigorosa prima delle fixture e della misura.\"
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
      (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
      (asdf:load-system \"arcdocdb\" :force t))))

(defun execution-function (name)
  \"Risolve una API esportata prima del clock; nessuna ricerca di simboli nel ciclo.\"
  (multiple-value-bind (symbol visibility) (find-symbol name \"ARCDOCDB.EXECUTION\")
    (unless (and symbol (eq visibility :external) (fboundp symbol))
      (error \"COD-60: API execution non disponibile: ~A.\" name))
    (symbol-function symbol)))

(defun expected-sink (iterations token)
  \"Oracolo indipendente: somma dei token fissi e degli indici delle chiamate.\"
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample-record (replica iterations warmup token)
  \"Tutte le chiavi della misura sono allocate prima di warmup, heap e clock.\"
  (list :replica replica :status :running :stage :warmup :iterations iterations
        :warmup-iterations (min warmup iterations) :completed-iterations 0
        :heap-bytes nil :raw-ticks nil :seconds nil :time-quality :pending
        :sink nil :expected-sink (expected-sink iterations token)
        :expected-return-token token :diagnostic nil))

(defun sample (function iterations token progress &key (warmup +warmup+) (clock #'get-internal-real-time))
  \"Warmup e GC prima della misura; raw e numero di cicli conservati anche al fallimento.\"
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error \"COD-60: parametri benchmark recycle fuori budget.\"))
  (dotimes (i (min warmup iterations)) (funcall function))
  (sb-ext:gc :full t)
  (setf (getf progress :stage) :measured)
  (let ((ticks-before (funcall clock)) (heap-before (sb-ext:get-bytes-consed)) (sink 0) (failure nil))
    (declare (type fixnum sink))
    (handler-case
        (dotimes (i iterations)
          (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall function))))
                (getf progress :completed-iterations) (1+ i)))
      (error (condition) (setf failure condition)))
    (let ((heap (- (sb-ext:get-bytes-consed) heap-before)) (ticks (- (funcall clock) ticks-before)))
      (setf (getf progress :heap-bytes) heap (getf progress :raw-ticks) ticks
            (getf progress :sink) sink (getf progress :time-quality)
            (if (zerop ticks) :below-resolution :measured)
            (getf progress :seconds) (when (plusp ticks) (/ ticks (float internal-time-units-per-second 1d0))))
      (when failure (error failure))
      (unless (and (>= heap 0) (>= ticks 0) (= (getf progress :expected-sink) sink))
        (error \"COD-60: clock/heap invalido o sink recycle ~D diverso da ~D.\"
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun enqueue-batch (enqueue writers)
  \"N obblighi distinti per shard, accettati una volta prima del ricircolo.\"
  (let ((token 0))
    (declare (type fixnum token))
    (dotimes (index (length writers) token)
      (multiple-value-bind (count action) (funcall enqueue (svref writers index) (1+ index))
        (unless (and (= 1 count) (eq :schedule action))
          (error \"COD-60: manca il nuovo obbligo di pubblicazione recycle.\"))
        (incf token (+ count 11))))))

(defun consume-writer (start pop finish writer target nonces index)
  \"Una lease nuova, un payload preallocato, termine idle; nessun obbligo ripetuto.\"
  (let ((lease (funcall start writer)) (token 19))
    (declare (type fixnum token))
    (unless (= lease (incf (the fixnum (svref nonces index))))
      (error \"COD-60: nonce del writer ricircolato incoerente.\"))
    (multiple-value-bind (count status) (funcall pop writer lease target 1 2)
      (unless (and (= 1 count) (eq :messages status) (eql (1+ index) (svref target 1))
                   (eq :outside (svref target 0)) (eq :outside (svref target 2)))
        (error \"COD-60: payload/ownership/span del writer ricircolato incoerenti.\"))
      (incf token (+ (* 3 count) (* 5 (the fixnum (svref target 1))))))
    (unless (eq :idle (funcall finish writer lease))
      (error \"COD-60: writer ricircolato non torna idle dopo il consumo.\"))
    (+ token 23)))

(defun expected-token (shards capacity)
  \"Oracolo algebrico: M=K(C+1); ciascuna identità compare esattamente due volte.\"
  (let ((writers (* shards (1+ capacity))))
    (+ (* 74 writers) (* 5 writers (1+ writers))
       (* shards (+ (* 31 capacity) (/ (* 3 capacity (1+ capacity)) 2) 13 (* 3 capacity)))
       (/ (* 7 capacity shards (1- shards)) 2) 29)))

(defun cycle-function (shards capacity)
  \"C+1 writer per shard; ruoli ruotano, room/full e FIFO/wrap verificati in ogni ciclo.\"
  (let* ((create-ready (execution-function \"CREA-LISTA-WRITER-PRONTI\"))
         (recycle (execution-function \"RICIRCOLA-WRITER-PRONTO\"))
         (take (execution-function \"PRELEVA-WRITER-PRONTO\"))
         (create-writer (execution-function \"CREA-WRITER-PROGRAMMABILE\"))
         (enqueue (execution-function \"ACCODA-LAVORO-WRITER\"))
         (start (execution-function \"INIZIA-TRATTO-WRITER\"))
         (pop (execution-function \"PRELEVA-LAVORI-WRITER\"))
         (finish (execution-function \"TERMINA-TRATTO-WRITER\"))
         (ready (funcall create-ready :shards shards :capacity capacity))
         (per-shard (1+ capacity))
         (writers (make-array (* per-shard shards)))
         (nonces (make-array (* per-shard shards) :initial-element 0))
         (target (make-array 3 :initial-element :outside)) (cursor 0) (phase 0))
    (declare (type fixnum cursor phase shards capacity per-shard))
    (dotimes (i (length writers)) (setf (svref writers i) (funcall create-writer :capacity 1 :quantum 1)))
    (lambda ()
      (let ((token (enqueue-batch enqueue writers)))
        (declare (type fixnum token))
        (dotimes (shard shards)
          (dotimes (ordinal capacity)
            (let ((index (+ (* per-shard shard) (mod (+ phase ordinal) per-shard))))
              (multiple-value-bind (writer status count)
                  (funcall recycle ready shard (svref writers index))
                (unless (and (null writer) (eq :published status) (= (1+ ordinal) count))
                  (error \"COD-60: ricircolo con spazio non pubblica una volta/count errato.\"))
                (incf token (+ 31 (* 3 count))))))
          (let ((new-index (+ (* per-shard shard) (mod (+ phase capacity) per-shard)))
                (old-index (+ (* per-shard shard) phase)))
            (multiple-value-bind (writer status count)
                (funcall recycle ready shard (svref writers new-index))
              (unless (and (eq (svref writers old-index) writer) (eq :writer status) (= capacity count))
                (error \"COD-60: ricircolo pieno non trasferisce il primo/count errato.\"))
              (incf token (+ 13 (* 3 count) 17 (* 5 (1+ old-index))))
              (incf token (consume-writer start pop finish writer target nonces old-index)))))
        (dotimes (ordinal capacity)
          (dotimes (visit shards)
            (let ((index (+ (* per-shard cursor) (mod (+ phase ordinal 1) per-shard)))
                  (expected-next (mod (1+ cursor) shards)))
              (multiple-value-bind (writer status next) (funcall take ready cursor)
                (unless (and (eq (svref writers index) writer) (eq :writer status) (= expected-next next))
                  (error \"COD-60: identità/FIFO/status/cursor dopo il ricircolo incoerenti.\"))
                (incf token (+ 17 (* 5 (1+ index)) (* 7 next)))
                (incf token (consume-writer start pop finish writer target nonces index))
                (setf cursor next)))))
        (multiple-value-bind (writer status next) (funcall take ready cursor)
          (unless (and (null writer) (eq :empty status) (= (mod (1+ cursor) shards) next))
            (error \"COD-60: scansione vuota/cursor recycle incoerenti.\"))
          (setf cursor next phase (mod (1+ phase) per-shard))
          (incf token 29))
        token))))

(defun campaign-record (scenario shards capacity)
  \"M=K(C+1), token da enqueue/recycle/consume/pop; quattro configurazioni preregistrate.\"
  (unless (and (member shards '(1 4)) (member capacity '(1 3)))
    (error \"COD-60: configurazione recycle fuori dal preregistrato.\"))
  (list :scenario scenario :shards shards :capacity-per-shard capacity
        :writers-per-shard (1+ capacity) :ready-published-per-cycle (* shards (1+ capacity))
        :room-publications-per-cycle (* shards capacity) :full-exchanges-per-cycle shards
        :calls-per-cycle (1+ (* shards (+ (* 6 capacity) 5)))
        :expected-token (expected-token shards capacity) :token-rule
        '(:enqueue-count-plus-schedule-11 :recycle-published-31 :recycle-count-times-3
          :recycle-full-status-13 :dispatched-writer-17 :writer-id-times-5
          :next-cursor-times-7 :lease-19 :taken-times-3 :payload-id-times-5
          :finish-idle-23 :ready-empty-29)
        :token-formula \"74M+5M(M+1)+K(31C+3C(C+1)/2+13+3C)+7CK(K-1)/2+29; M=K(C+1)\"
        :status :running :stage :fixture :current-replica nil :samples nil :diagnostic nil))

(defun campaign (progress checkpoint)
  \"Cinque campioni; ogni prova corrente è collegata al report prima dell'esecuzione.\"
  (let ((function (cycle-function (getf progress :shards) (getf progress :capacity-per-shard))))
    (dotimes (replica +replicas+)
      (let ((measurement (sample-record replica +iterations+ +warmup+ (getf progress :expected-token))))
        (setf (getf progress :current-replica) replica (getf progress :stage) :replica
              (getf progress :samples) (append (getf progress :samples) (list measurement)))
        (when checkpoint (funcall checkpoint))
        (sample function +iterations+ (getf progress :expected-token) measurement)
        (when checkpoint (funcall checkpoint))
        (unless (zerop (getf measurement :heap-bytes))
          (error \"COD-30: heap osservato non nullo nella replica ~D di ~A.\"
                 replica (getf progress :scenario)))))
    (setf (getf progress :status) :ok (getf progress :stage) :complete
          (getf progress :current-replica) nil))
  progress)

(defun run-campaigns (report &key checkpoint (runner #'campaign))
  \"I quattro scenari vengono registrati in ordine e conservati anche al fallimento.\"
  (dolist (spec '((:one-shard-one-slot 1 1) (:one-shard-three-slots 1 3)
                  (:four-shards-one-slot 4 1) (:four-shards-three-slots 4 3)))
    (let ((progress (apply #'campaign-record spec)))
      (setf (getf report :current-campaign) progress
            (getf report :campaigns) (append (getf report :campaigns) (list progress)))
      (when checkpoint (funcall checkpoint))
      (funcall runner progress checkpoint)))
  report)

(defun make-report ()
  \"Metadati di misura e limiti; tutte le chiavi condivise esistono prima degli aggiornamenti.\"
  (list :schema-version 1 :kind :writer-recycle-benchmark :status :running :stage :pending
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-composed-handoff-ready-and-recycle-cycles :preallocated-inputs
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-pool-device-durability-or-release-qualification)))

(defun acquire-directory (path)
  \"MKDIR esclusivo 0700; una destinazione precedente non viene mai scritta.\"
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames \"parent-placeholder\" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report directory)
  \"Scrive esclusivamente nella directory reclamata; conserva l'ultima plist completa.\"
  (with-open-file (stream (merge-pathnames \"report.next.lisp\" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames \"report.next.lisp\" directory)
                                     (merge-pathnames \"report.lisp\" directory))
  report)

(defun mark-failed (report condition)
  \"L'errore conserva sample e scenario correnti, inclusi raw raccolti prima del controllo.\"
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (let ((current (getf report :current-campaign)))
    (when current
      (setf (getf current :status) :failed (getf current :diagnostic) (princ-to-string condition))
      (let ((last (car (last (getf current :samples)))))
        (when (and last (eq :running (getf last :status)))
          (setf (getf last :status) :failed (getf last :diagnostic) (princ-to-string condition))))))
  report)

(defun run-driver (args &key (self-tester #'self-test) (campaign-runner #'run-campaigns)
                            (product-loader #'load-product))
  \"Directory, load e ogni prova registrati; fallimenti visibili senza sovrascrivere altro.\"
  (let ((report (make-report)) (owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '(\"--self-test\"))
                      (and (= 2 (length args)) (string= \"--bench\" (first args))))
            (error \"COD-61: uso --self-test oppure --bench directory-nuova/.\"))
          (when (= 2 (length args)) (setf owned-directory (acquire-directory (second args))))
          (setf (getf report :stage) :load-product)
          (when owned-directory (write-report report owned-directory))
          (funcall product-loader)
          (setf (getf report :stage) :self-test (getf report :self-test) (funcall self-tester))
          (when owned-directory
            (write-report report owned-directory)
            (setf (getf report :stage) :campaigns)
            (funcall campaign-runner report :checkpoint (lambda () (write-report report owned-directory))))
          (setf (getf report :status) :ok (getf report :stage) :complete))
      (error (condition) (mark-failed report condition)))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after (getf report :source-consistency)
            (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
      (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
        (setf (getf report :status) :source-changed
              (getf report :diagnostic) \"COD-61: sorgenti cambiati durante il benchmark recycle.\")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  \"Fixture temporanea esclusiva, con limite di mille collisioni.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-recycle-bench-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture benchmark recycle non disponibile.\"))

(defun self-test-partial-run (report &key checkpoint)
  \"Primo scenario completo; secondo interrompe la replica dopo un raw sintetico.\"
  (run-campaigns report :checkpoint checkpoint
    :runner (lambda (progress persist)
              (setf (getf progress :stage) :replica (getf progress :current-replica) 0
                    (getf progress :samples)
                    (list (list :status :running :raw-ticks 7 :heap-bytes 0 :diagnostic nil)))
              (when persist (funcall persist))
              (if (eq :one-shard-one-slot (getf progress :scenario))
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (error \"fixture: seconda campagna interrotta\")))))

(defun self-test-reporter ()
  \"Rifiuta una destinazione esistente e conserva scenario precedente e replica fallita.\"
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames \"existing/\" root)))
                (failed-directory (merge-pathnames \"failed/\" root)))
           (write-report '(:sentinel :unchanged) existing)
           (unless (eq :failed (getf (run-driver (list \"--bench\" (namestring existing))
                                               :self-tester (constantly :passed)
                                               :product-loader (constantly nil)) :status))
             (error \"COD-60: destinazione precedente accettata.\"))
           (let ((*read-eval* nil))
             (with-open-file (input (merge-pathnames \"report.lisp\" existing))
               (unless (equal (read input) '(:sentinel :unchanged))
                 (error \"COD-60: report precedente modificato.\"))))
           (run-driver (list \"--bench\" (namestring failed-directory))
                       :self-tester (constantly :passed) :product-loader (constantly nil)
                       :campaign-runner #'self-test-partial-run)
           (let* ((*read-eval* nil)
                  (saved (with-open-file (input (merge-pathnames \"report.lisp\" failed-directory))
                           (read input))) (cases (getf saved :campaigns))
                  (partial (first (getf (second cases) :samples))))
             (unless (and (eq :failed (getf saved :status)) (= 2 (length cases))
                          (eq :ok (getf (first cases) :status))
                          (eq :failed (getf (second cases) :status))
                          (eq :replica (getf (second cases) :stage))
                          (= 0 (getf (second cases) :current-replica))
                          (eq :failed (getf partial :status)) (= 7 (getf partial :raw-ticks))
                          (= 0 (getf partial :heap-bytes)))
               (error \"COD-60: campagna precedente o prova parziale perse.\"))))
      ;; C4: ROOT è soltanto la directory acquisita dalla fixture.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test-cli ()
  \"Ogni argv invalido fallisce prima del load, senza destinazione o campagna.\"
  (let ((records nil))
    (dolist (args '(nil (\"--bench\") (\"--bad\") (\"--bench\" \"directory\" \"extra\")))
      (let ((called nil))
        (let ((report (run-driver args :product-loader (lambda () (setf called t)))))
          (unless (and (null called) (eq :failed (getf report :status))
                       (eq :pending (getf report :stage)) (null (getf report :campaigns))
                       (search \"uso --self-test\" (getf report :diagnostic)))
            (error \"COD-60: CLI invalida accettata o eseguita.\"))
          (push (list :arguments args :status (getf report :status)
                      :stage (getf report :stage) :diagnostic (getf report :diagnostic)) records))))
    (nreverse records)))

(defun self-test ()
  \"Heap positivo, sink errato, clock nullo, cicli legali, CLI e reporter dei fallimenti.\"
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0)) (probe nil)
         (positive (sample-record 0 16 0 1048576)) (api-probes nil)
         (wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0)))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error \"COD-60: baseline contatore non nulla.\"))
    (sample (lambda ()
              (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
              (length probe)) 16 1048576 positive :warmup 0)
    (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error \"COD-60: allocazione deliberata non rilevata.\"))
    (unless (handler-case (progn (sample (lambda () 1) 2 0 wrong :warmup 0) nil)
              (error (condition)
                (setf (getf wrong :status) :expected-rejection
                      (getf wrong :diagnostic) (princ-to-string condition)) t))
      (error \"COD-60: sink errato non respinto.\"))
    (sample (lambda () 0) 2 0 zero :warmup 0 :clock (constantly 0))
    (unless (and (eq :below-resolution (getf zero :time-quality))
                 (null (getf zero :seconds))) (error \"COD-60: clock nullo utilizzato come durata.\"))
    (dolist (spec '((1 1 257) (1 3 558) (4 1 1223) (4 3 3231)))
      (destructuring-bind (shards capacity token) spec
        (unless (= token (expected-token shards capacity))
          (error \"COD-60: oracolo algebrico recycle diverso dalla derivazione indipendente.\"))
        (let ((progress (sample-record 0 4 0 token)))
          (sample (cycle-function shards capacity) 4 token progress :warmup 0)
          (push (list :shards shards :capacity-per-shard capacity :probe progress) api-probes))))
    (self-test-reporter)
    (list :status :ok :baseline baseline :positive-control positive
          :wrong-sink :rejected :wrong-sink-probe wrong :zero-clock :below-resolution
          :zero-clock-probe zero :partial-report :preserved :existing-destination :preserved
          :invalid-cli (self-test-cli) :composed-api-probes (nreverse api-probes))))

(defun main ()
  \"CLI C4; risultato strutturato anche senza destinazione e diagnostica con exit nonzero.\"
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* \"~&writer-recycle-bench.lisp: ~A~%\" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
")
  (:PATH #A((34) BASE-CHAR . "tools/writer-recycle-mutation.lisp") :BYTES 26744
   :SHA256 "365912245d23c7e2f75539b85c8c34c50ec799bf152ca7e8954c4c7fedc1a3ec"
   :GIT-BLOB "6ed4f867fd875231189f99367958300b2cecaab7" :TEXT
   ";;;; Mutazioni semantiche del ricircolo dei writer pronti in copie isolate.
;;;; Uso: --self-test oppure --run directory-nuova/; writer-recycle-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-005 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-recycle.mutation (:use #:cl))
(in-package #:arcdocdb.writer-recycle.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *recycle-mutants*
  '((\"recycle-fifo-next-slot\" \"src/execution/ready-recycle.lisp\"
     ((\"(old (svref (partizione-pronta-slots partition) head))\"
       \"(old (svref (partizione-pronta-slots partition)
                    (mod (1+ head) (partizione-pronta-capacity partition))))\")))
    (\"recycle-head-wrap-two\" \"src/execution/ready-recycle.lisp\"
     ((\"(partizione-pronta-head partition) next\"
       \"(partizione-pronta-head partition)
          (mod (+ head 2) (partizione-pronta-capacity partition))\")))
    (\"recycle-tail-wrap-two\" \"src/execution/ready-recycle.lisp\"
     ((\"(partizione-pronta-tail partition) next\"
       \"(partizione-pronta-tail partition)
          (mod (+ head 2) (partizione-pronta-capacity partition))\")))
    (\"recycle-full-count-decrement\" \"src/execution/ready-recycle.lisp\"
     ((\"(partizione-pronta-tail partition) next)\"
       \"(partizione-pronta-tail partition) next
          (partizione-pronta-count partition) (1- (partizione-pronta-count partition)))\")))
    (\"recycle-full-keeps-old-slot\" \"src/execution/ready-recycle.lisp\"
     ((\"(setf (svref (partizione-pronta-slots partition) head) writer\"
       \"(setf (svref (partizione-pronta-slots partition) head) (if (eq writer old) writer old)\")))
    (\"recycle-full-boundary\" \"src/execution/ready-recycle.lisp\"
     ((\"(if (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))\"
       \"(if (> (partizione-pronta-count partition) (partizione-pronta-capacity partition))\")))
    (\"recycle-full-returns-new-writer\" \"src/execution/ready-recycle.lisp\"
     ((\"(values old :writer (partizione-pronta-count partition))\"
       \"(values writer :writer (partizione-pronta-count partition))\")))
    (\"recycle-room-returns-writer\" \"src/execution/ready-recycle.lisp\"
     ((\"(values nil :published (%pubblica-pronto partition writer))\"
       \"(values writer :published (%pubblica-pronto partition writer))\")))
    (\"recycle-full-status-published\" \"src/execution/ready-recycle.lisp\"
     ((\"(values writer-programmabile (member :writer) index &optional)\"
       \"(values writer-programmabile (member :published) index &optional)\")
      (\"(values old :writer (partizione-pronta-count partition))\"
       \"(values old :published (partizione-pronta-count partition))\")))
    (\"recycle-release-skipped\" \"src/execution/ready-recycle.lisp\"
     ((\"(%rilascia-guard-pronta partition thread)\" \"nil\")))
    (\"recycle-full-no-rotation\" \"src/execution/ready-recycle.lisp\"
     ((\"(next (mod (1+ head) (partizione-pronta-capacity partition)))\"
       \"(next head)\")))))

(defun mutation-list ()
  \"Undici mutanti semantici recycle fissati prima della campagna.\"
  *recycle-mutants*)

(defun source-files ()
  \"ASD, build, sorgenti e test richiesti dalle copie; nessuna evidenza o Git copiati.\"
  (append '(#p\"arcdocdb.asd\" #p\"tools/build.lisp\")
          (sort (append (directory \"src/**/*.lisp\") (directory \"tests/**/*.lisp\"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  \"MD5 dei file copiati e del driver: controllo di stabilità, non di autenticità.\"
  (loop for file in (append (source-files) '(#p\"tools/writer-recycle-mutation.lisp\"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil \"~(~{~2,'0X~}~)\"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  \"Legge sorgente e log UTF-8 come dati, senza interpretazione.\"
  (uiop:read-file-string path :external-format :utf-8))

(defun mutate-once (source before after name)
  \"COD-60: bersaglio unico e non vuoto, modifica effettiva, nessuna riscrittura originale.\"
  (let ((position (search before source)))
    (unless (and (plusp (length before)) position (not (string= before after))
                 (not (search before source :start2 (1+ position))))
      (error \"COD-60: mutante ~A, bersaglio assente/ambiguo o identico: ~S\" name before))
    (concatenate 'string (subseq source 0 position) after
                 (subseq source (+ position (length before))))))

(defun mutated-source (mutant)
  \"Valida ogni modifica nell'originale e nel risultato delle modifiche precedenti.\"
  (destructuring-bind (name path edits) mutant
    (let* ((original (read-text path)) (result original))
      (unless edits (error \"COD-60: mutante ~A senza modifiche.\" name))
      (dolist (edit edits)
        (destructuring-bind (before after) edit
          (mutate-once original before after name)
          (setf result (mutate-once result before after name))))
      result)))

(defun validate-mutations (mutants)
  \"Undici nomi unici; ogni bersaglio appare una sola volta nei sorgenti congelati.\"
  (unless (= 11 (length mutants)) (error \"COD-60: numero mutanti recycle diverso da undici.\"))
  (let ((names nil))
    (dolist (mutant mutants)
      (when (member (first mutant) names :test #'string=)
        (error \"COD-60: nome mutante ripetuto: ~A\" (first mutant)))
      (push (first mutant) names)
      (mutated-source mutant)))
  nil)

(defun event-at-line-start-p (text marker)
  \"Solo eventi a inizio riga; citazioni e frammenti di backtrace non contano.\"
  (loop for line in (uiop:split-string text :separator '(#\\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun classify-result (text exit &optional signal)
  \"Segnali OS, compilazione e guasti fuori dai test non sono mutanti rilevati.\"
  (cond (signal :worker-error)
        ((or (search \"compilation aborted\" text :test #'char-equal)
             (search \"COMPILE-FILE-ERROR\" text :test #'char-equal)
             (search \"COMPILE-FILE-WARNED\" text :test #'char-equal)
             (search \"non ammesso (COD-01)\" text)) :compilation-failure)
        ((and (integerp exit) (not (zerop exit))
              (event-at-line-start-p text \"execution-tests-complete \")) :worker-error)
        ((or (not (integerp exit))
             (not (event-at-line-start-p text \"execution-test-start \"))) :before-tests)
        ((not (zerop exit)) :detected)
        ((event-at-line-start-p text \"execution-tests-complete \") :survived)
        (t :before-tests)))

(defun copy-test-system (directory)
  \"Copia tutti i sorgenti e test ASDF; gli output delle copie restano privati.\"
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target)))
  nil)

(defun write-runner (directory)
  \"Compilazione rigorosa e intera suite execution registrata, inclusi i test del ricircolo.\"
  (let ((path (merge-pathnames \"tools/writer-recycle-isolated-build.lisp\" directory)))
    (with-open-file (stream path :direction :output :if-exists :error)
      (dolist (form
                '((require :asdf)
                  (setf asdf:*user-cache* (merge-pathnames \"fasl/\" (truename \"./\"))
                        asdf:*compile-file-failure-behaviour* :error
                        asdf:*compile-file-warnings-behaviour* :error)
                  (handler-bind
                      ((warning (lambda (condition)
                                  (unless (typep condition 'sb-kernel:redefinition-warning)
                                    (error \"~A non ammesso (COD-01): ~A\"
                                           (type-of condition) condition)))))
                    (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
                    (asdf:load-system \"arcdocdb\" :force t)
                    (asdf:load-system \"arcdocdb/tests\" :force t))
                  (unless (and (probe-file \"tests/execution/ready-recycle.lisp\")
                               (asdf:find-component (asdf:find-system \"arcdocdb/tests\")
                                                    '(\"execution\" \"ready-recycle\")))
                    (error \"Test recycle assente o non registrato in ASDF.\"))
                  (let* ((package (or (find-package \"ARCDOCDB.EXECUTION.TESTS\")
                                      (error \"Harness execution non caricato.\")))
                         (registry (or (find-symbol \"*TESTS*\" package)
                                       (error \"Registro execution assente.\")))
                         (tests (reverse (symbol-value registry))))
                    (unless (and tests (every #'fboundp tests))
                      (error \"Test execution non caricati dal sistema ASDF.\"))
                    (dolist (test tests)
                      (format t \"~&execution-test-start ~A~%\" test) (finish-output)
                      (funcall test) (format t \"ok    ~A~%\" test))
                    (format t \"~&execution-tests-complete ~D~%\" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    path))

(defun execute-runner (directory)
  \"Conserva log, exit code e segnale OS del processo isolato già preparato.\"
  (let* ((log (merge-pathnames \"test.log\" directory))
         (process (uiop:launch-program
                   '(\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                     \"--disable-debugger\" \"--script\" \"tools/writer-recycle-isolated-build.lisp\")
                   :directory directory :output log :error-output :output)))
    (multiple-value-bind (exit signal) (uiop:wait-process process)
      (values (classify-result (read-text log) exit signal) exit log signal))))

(defun execute-tests (directory)
  \"Conserva il log per ciascun esito, inclusi errori di compilazione o avvio.\"
  (write-runner directory)
  (execute-runner directory))

(defun write-report (directory report)
  \"Sostituisce il registro solo dopo avere scritto la nuova copia completa.\"
  (with-open-file (stream (merge-pathnames \"report.next.lisp\" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames \"report.next.lisp\" directory)
                                     (merge-pathnames \"report.lisp\" directory))
  report)

(defun verify-baseline (directory)
  \"La baseline invariata deve completare tutta execution, con log conservato prima del gate.\"
  (let ((baseline (merge-pathnames \"baseline/\" directory)))
    (copy-test-system baseline)
    (multiple-value-bind (result exit log signal) (execute-tests baseline)
      (list :result result :exit-code exit :signal signal :log (namestring log)))))

(defun execute-mutation (mutant ordinal directory)
  \"Copia privata per mutante, senza modificare il checkout della campagna.\"
  (let ((copy (merge-pathnames (format nil \"~D/\" ordinal) directory)))
    (copy-test-system copy)
    (with-open-file (stream (merge-pathnames (second mutant) copy)
                            :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (mutated-source mutant) stream))
    (multiple-value-bind (result exit log signal) (execute-tests copy)
      (list :name (first mutant) :source-file (second mutant)
            :result result :exit-code exit :signal signal :log (namestring log)))))

(defun acquire-directory (path)
  \"MKDIR esclusivo 0700; la directory preesistente è intangibile.\"
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames \"parent-placeholder\" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun initial-report (directory mutants)
  \"Plist preinizializzata prima della baseline, con sorgenti e ogni tentativo identificabili.\"
  (list :schema-version 1 :kind :writer-recycle-mutations :status :running :stage :validation
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :targets mutants :planned-mutants (length mutants)
        :baseline :pending :baseline-result nil :baseline-exit-code nil :baseline-signal nil
        :baseline-log (namestring (merge-pathnames \"baseline/test.log\" directory))
        :mutants nil :current-ordinal nil :current-mutant nil :current-log nil :diagnostic nil
        :detected 0 :survived 0 :compilation-failures 0 :before-tests 0 :worker-errors 0
        :limits '(:targeted-mutants-only :complete-execution-suite :strict-compilation
                  :test-events-at-line-start :partial-campaign-preserved :exclusive-directory
                  :no-pool-device-durability-or-performance-qualification)))

(defun append-result (report result)
  \"Registra esito e conteggi prima del prossimo mutante.\"
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (dolist (pair '((:detected :detected) (:survived :survived)
                  (:compilation-failures :compilation-failure) (:before-tests :before-tests)
                  (:worker-errors :worker-error)))
    (setf (getf report (first pair))
          (count (second pair) (getf report :mutants) :key (lambda (entry) (getf entry :result)))))
  report)

(defun finish-report (directory report)
  \"Fotografa la stabilità anche al fallimento e salva i risultati raccolti.\"
  (let ((after (fingerprints)))
    (setf (getf report :source-fingerprints-after) after
          (getf report :source-consistency)
          (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
    (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
      (setf (getf report :status) :source-changed
            (getf report :diagnostic) \"COD-61: sorgenti cambiati durante la campagna recycle.\")))
  (write-report directory report)
  (format t \"~&Writer recycle: ~A, baseline ~A, rilevati ~D/~D; ~A~%\"
          (getf report :status) (getf report :baseline) (getf report :detected)
          (getf report :planned-mutants) (merge-pathnames \"report.lisp\" directory))
  report)

(defun run-campaign (path &key (mutants (mutation-list)) (validator #'validate-mutations)
                             (baseline-runner #'verify-baseline) (mutant-runner #'execute-mutation))
  \"Persiste prima e dopo ogni prova; setup, baseline e risultati parziali restano visibili.\"
  (let* ((directory (acquire-directory path)) (report (initial-report directory mutants)))
    (handler-case
        (progn
          (write-report directory report) (funcall validator mutants)
          (setf (getf report :stage) :baseline) (write-report directory report)
          (let* ((baseline (funcall baseline-runner directory))
                 (passed (and (eq :survived (getf baseline :result))
                              (eql 0 (getf baseline :exit-code)))))
            (setf (getf report :baseline) (if passed :passed :failed)
                  (getf report :baseline-result) (getf baseline :result)
                  (getf report :baseline-exit-code) (getf baseline :exit-code)
                  (getf report :baseline-signal) (getf baseline :signal)
                  (getf report :baseline-log) (getf baseline :log))
            (write-report directory report)
            (unless passed (error \"COD-61: baseline recycle fallita; ~A\" baseline)))
          (loop for mutant in mutants for ordinal from 0
                do (setf (getf report :stage) :mutants (getf report :current-ordinal) ordinal
                         (getf report :current-mutant) (first mutant) (getf report :current-log)
                         (namestring (merge-pathnames (format nil \"~D/test.log\" ordinal) directory)))
                   (write-report directory report)
                   (append-result report (funcall mutant-runner mutant ordinal directory))
                   (write-report directory report))
          (setf (getf report :stage) :complete (getf report :current-ordinal) nil
                (getf report :current-mutant) nil (getf report :current-log) nil)
          (unless (= (length mutants) (getf report :detected))
            (error \"COD-61: mutanti recycle rilevati ~D/~D.\" (getf report :detected) (length mutants)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (finish-report directory report)))

(defun assert-self-test (expression description)
  \"Il self-test segnala la regola dello strumento che non è stata rilevata.\"
  (unless expression (error \"COD-60: writer-recycle-mutation.lisp, self-test ~A.\" description)))

(defun fresh-self-test-directory ()
  \"Fixture esclusiva, al più mille collisioni, nessun percorso esterno da rimuovere.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-recycle-mutation-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture recycle non disponibile.\"))

(defun self-test-log (directory relative)
  \"Evento sintetico esplicito; nessun processo figlio durante la fixture del reporter.\"
  (let ((path (merge-pathnames relative directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output :if-exists :error)
      (write-line \"evento sintetico del self-test\" stream))
    (namestring path)))

(defun self-test-process-signal ()
  \"Un child fixture si termina con SIGKILL; trasporto e report conservano la prova.\"
  (let* ((directory (acquire-directory
                    (format nil \"spikes/out/~D-recycle-signal-self-test-~D/\"
                            (get-universal-time) (sb-posix:getpid))))
         (runner (merge-pathnames \"tools/writer-recycle-isolated-build.lisp\" directory))
         (report (initial-report directory '((\"signal-fixture\" \"fixture\" nil)))))
    (setf (getf report :kind) :process-signal-self-test (getf report :stage) :runner)
    (write-report directory report)
    (ensure-directories-exist runner)
    (with-open-file (stream runner :direction :output :if-exists :error)
      (dolist (form '((require :sb-posix)
                      (format t \"~&execution-test-start SIGNAL-FIXTURE~%\")
                      (finish-output)
                      (sb-posix:kill (sb-posix:getpid) sb-posix:sigkill)))
        (write form :stream stream :pretty t) (terpri stream)))
    (multiple-value-bind (result exit log signal) (execute-runner directory)
      (append-result report
        (list :name \"signal-fixture\" :result result :exit-code exit
              :signal signal :log (namestring log)))
      (write-report directory report)
      (assert-self-test (and (eq result :worker-error)
                             (eql signal sb-posix:sigkill)
                             (not (eql exit 0))
                             (event-at-line-start-p (read-text log) \"execution-test-start \"))
                        :signaled-process-never-detected)
      (let* ((*read-eval* nil)
             (saved (with-open-file (stream (merge-pathnames \"report.lisp\" directory))
                      (read stream)))
             (entry (first (getf saved :mutants))))
        (assert-self-test (and (= 1 (getf saved :worker-errors))
                               (zerop (getf saved :detected))
                               (eql exit (getf entry :exit-code))
                               (eql signal (getf entry :signal)))
                          :signal-report-preserved)))
    (setf (getf report :status) :passed (getf report :stage) :complete)
    (finish-report directory report)
    (format t \"~&Writer recycle: self-test segnale OS superato; ~A~%\"
            (merge-pathnames \"report.lisp\" directory))))

(defun self-test-reporter ()
  \"Preserva una destinazione esistente e un risultato prima di un guasto tardivo.\"
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames \"existing/\" root)))
                (marker (self-test-log existing \"unchanged.log\")) (before (read-text marker))
                (campaign (merge-pathnames \"partial/\" root))
                (mutants '((\"fixture-one\" \"source\" nil) (\"fixture-two\" \"source\" nil))))
           (assert-self-test (handler-case (progn (acquire-directory existing) nil) (error () t))
                             :existing-directory-rejected)
           (assert-self-test (string= before (read-text marker)) :existing-directory-preserved)
           (let ((*standard-output* (make-broadcast-stream)))
             (run-campaign campaign :mutants mutants :validator (constantly nil)
               :baseline-runner (lambda (directory)
                                  (list :result :survived :exit-code 0
                                        :log (self-test-log directory \"baseline/test.log\")))
               :mutant-runner (lambda (mutant ordinal directory)
                                (when (= ordinal 1) (error \"fixture: secondo avvio interrotto\"))
                                (list :name (first mutant) :result :detected :exit-code 1
                                      :log (self-test-log directory \"0/test.log\")))))
           (let* ((*read-eval* nil)
                  (saved (with-open-file (stream (merge-pathnames \"report.lisp\" campaign))
                           (read stream))))
             (assert-self-test (and (= 1 (getf saved :schema-version))
                                    (eq :failed (getf saved :status))
                                    (eq :passed (getf saved :baseline))
                                    (= 1 (getf saved :current-ordinal))
                                    (string= \"fixture-two\" (getf saved :current-mutant))
                                    (search \"secondo avvio\" (getf saved :diagnostic))
                                    (= 1 (length (getf saved :mutants)))
                                    (= 1 (getf saved :detected))
                                    (probe-file (getf saved :baseline-log))
                                    (probe-file (getf (first (getf saved :mutants)) :log)))
                               :partial-report-preserved)))
      ;; C4: ROOT appartiene soltanto alla fixture dopo MKDIR esclusivo.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  \"Dimostra marker autentici, classificazioni, bersagli invalidi e report parziali.\"
  (let ((start \"execution-test-start TEST\") (complete \"execution-tests-complete 1\"))
    (assert-self-test (eq :detected (classify-result start 1)) :detected)
    (assert-self-test (eq :survived (classify-result (format nil \"~A~%~A~%\" start complete) 0))
                      :complete-suite)
    (assert-self-test (eq :worker-error
                         (classify-result (format nil \"~A~%~A~%\" start complete) 1))
                      :completed-suite-failure)
    (assert-self-test (eq :worker-error (classify-result complete 1))
                      :completed-marker-failure)
    (assert-self-test (eq :detected
                         (classify-result (format nil \"~A~%Backtrace: ~A\" start complete) 1))
                      :quoted-completion-never-accepted)
    (dolist (text '(\"\" \"prefix execution-test-start TEST\" \"Backtrace: execution-test-start TEST\"
                    \"(FORMAT T \\\"execution-test-start ~A\\\")\"))
      (assert-self-test (eq :before-tests (classify-result text 1)) :quoted-marker))
    (assert-self-test (eq :before-tests (classify-result start 0)) :incomplete-suite)
    (assert-self-test (eq :before-tests (classify-result start nil)) :missing-exit)
    (dolist (failure '(\"compilation aborted\" \"COMPILE-FILE-ERROR\" \"COMPILE-FILE-WARNED\"
                       \"STYLE-WARNING non ammesso (COD-01)\"))
      (assert-self-test (eq :compilation-failure
                           (classify-result (format nil \"~A~%~A\" start failure) 1))
                        :compilation-never-detected)))
  (assert-self-test (string= \"xBy\" (mutate-once \"xAy\" \"A\" \"B\" \"fixture\")) :substitution)
  (dolist (case '((\"AA\" \"A\" \"B\") (\"x\" \"A\" \"B\") (\"A\" \"A\" \"A\") (\"A\" \"\" \"B\")))
    (assert-self-test (handler-case (progn (apply #'mutate-once (append case '(\"fixture\"))) nil)
                        (error () t)) :invalid-mutation))
  (dolist (args '(nil (\"--run\") (\"--bad\") (\"--run\" \"directory\" \"extra\")
                  (\"--self-test\" \"extra\")))
    (assert-self-test (not (valid-arguments-p args)) :invalid-cli))
  (assert-self-test (and (valid-arguments-p '(\"--self-test\"))
                         (valid-arguments-p '(\"--run\" \"directory\"))) :valid-cli)
  (validate-mutations (mutation-list))
  (self-test-process-signal)
  (self-test-reporter)
  (format t \"~&Writer recycle: self-test superato, nessuna campagna eseguita.~%\")
  t)

(defun valid-arguments-p (args)
  \"Accetta solo self-test o run con una destinazione; nessuna campagna implicita.\"
  (or (equal args '(\"--self-test\"))
      (and (= (length args) 2) (string= (first args) \"--run\"))))

(defun main ()
  \"CLI C4, mai campagna implicita, diagnostica e exit nonzero per regola violata.\"
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (unless (valid-arguments-p args)
          (error \"COD-61: uso --self-test oppure --run directory-nuova/.\"))
        (cond ((equal args '(\"--self-test\")) (self-test))
              ((and (= (length args) 2) (string= (first args) \"--run\"))
               (let ((report (run-campaign (second args))))
                 (unless (eq :ok (getf report :status))
                   (format *error-output* \"~&writer-recycle-mutation.lisp: ~A~%\"
                           (getf report :diagnostic))
                   (uiop:quit 1))))
              (t (error \"COD-61: uso --self-test oppure --run directory-nuova/.\"))))
    (error (condition)
      (format *error-output* \"~&writer-recycle-mutation.lisp: ~A~%\" condition)
      (uiop:quit 1))))

(main)
")
  (:PATH #A((16) BASE-CHAR . "tools/build.lisp") :BYTES 1245 :SHA256
   "be55166510051b57c6d6d2f8b0e4143375cec5bfab30aab5a58e5e14445a5832" :GIT-BLOB
   "40879533738e1fc49e74941a9def5b089c551921" :TEXT
   ";;;; build.lisp — compila il sistema e ne esegue i test; ogni avviso è un errore.
;;;;
;;;; Uso:  sbcl --noinform --no-userinit --non-interactive --load tools/build.lisp
;;;;
;;;; Regola COD-01 (docs/affidabilita/standard-di-codifica.md): compilazione senza
;;;; WARNING né STYLE-WARNING. Il caricamento forza la ricompilazione, così un avviso non
;;;; può essere nascosto da una compilazione precedente.
;;;;
;;;; REQ: REQ-AFF-003

(require :asdf)

(setf asdf:*compile-file-failure-behaviour* :error
      asdf:*compile-file-warnings-behaviour* :error)

(defun treat-as-error (condition)
  \"Trasforma un avviso di compilazione in errore, indicando il testo dell'avviso.
Esclusi solo gli avvisi di ridefinizione, prodotti da ASDF quando rilegge il file .asd:
non dipendono dal codice di prodotto.\"
  (unless (typep condition 'sb-kernel:redefinition-warning)
    (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))

(handler-bind ((warning #'treat-as-error)
               (style-warning #'treat-as-error))
  (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
  (asdf:load-system \"arcdocdb\" :force t)
  (asdf:test-system \"arcdocdb\"))

(format t \"~&build e test: nessun avviso, tutti i controlli superati~%\")
")
  (:PATH #A((45) BASE-CHAR . "docs/implementazione/writer-recycle-metodo.md")
   :BYTES 6365 :SHA256
   "80846e2b65a87745a7e3670653f902d91ae8043e49362789544b0da529f50eff" :GIT-BLOB
   "b94583da79c1834c306118ebcc013c795b286ce1" :TEXT
   "# Metodo del ricircolo dei writer pronti

Registrato il 2026-10-09 prima delle campagne, base `673987a`.
Il componente C1 integra la [lista pronta](writer-ready.md) con il
trasferimento di obblighi del [writer](writer-handoff.md), senza creare
thread o implementare un pool. REQ-CON-001/002/004/005 e REQ-AFF-008;
INV-P1/P2/P5/P6, INV-A8 e INV-V4; ADR-0005 e ADR-0045 §§6/8.

## Contratto

`ricircola-writer-pronto(ready, shard, writer)` riceve un obbligo unico
`:schedule` che appartiene al chiamante. Richiede che il chiamante possa
prendere in carico un altro writer. Non legge lo stato dei writer e non
rileva deduplicazione o eleggibilità: valgono le precondizioni già adottate.
Una sola acquisizione CAS della guard locale, nessuna attesa o retry.

- Se il ring ha spazio, pubblica il riferimento in FIFO e restituisce
  NIL, `:published`, nuovo count: l'obbligo passa al ring.
- Se il ring è pieno, trasferisce al chiamante il riferimento in testa e
  inserisce il nuovo in coda nella medesima sezione: restituisce il writer
  estratto, `:writer`, capacity. Head e tail avanzano di uno modulo capacity;
  count resta invariato. In full head=tail, quindi basta sostituire uno slot.
- Busy è `resource-exhausted :ready-queue-busy` prima della mutazione;
  l'obbligo originario resta al chiamante. Indice/riferimento errati sono
  `invalid-argument`; guasti di forma/proprietà/payload sono invarianti
  fail-stop, senza rollback promesso dopo un guasto interno.

Full `[C,B,...,Z]` diventa `[B,...,Z,A]`: A passa al ring e C al chiamante
insieme. Capacity 1 è `[C]`→`[A]`. Un ritorno `:writer` non autorizza a
pubblicare di nuovo A. Il chiamante conserva C durante busy di avvio.
La guard rende lo scambio atomico rispetto a producer e consumer sul ring.
Un pop e una pubblicazione separati non realizzano questo contratto.

## Problema e confini

Con la sola pubblicazione, tutti i consumer possono terminare un tratto
con backlog mentre i ring sono già pieni e restare impegnati a ritentare:
nessuno consuma i riferimenti già pronti. Il modello conserva il
controesempio. Il ricircolo consegna invece una nuova testa direttamente
al consumer, senza una seconda coda o una capacità variabile.

Questo risolve il blocco dovuto alla sola capienza dei ring nel protocollo
modellato. Non qualifica la liveness generale del pool: guard perpetuamente
contese, obblighi abbandonati o duplicati, fault di Serie e admission richiedono
un controller. Una catena full resta sullo stesso shard; non dimostra equità
fra partizioni o assenza di starvation per nuovi producer. Il caller deve
governare le quote e gli altri compiti. Empty resta un'osservazione locale,
mai una prova per parcheggio, arresto o ritiro del worker. Nessun cleanup
sul writer dopo end: una nuova ondata può essere già pubblicata.

Costo O(1), un'acquisizione e un rilascio CAS, nessuno stato globale nuovo
né scrittura comune per messaggio. Factory, ready e handoff restano invariati.

## Prove preregistrate

- Oracolo FIFO indipendente con seme, 8 configurazioni (capacity 1/2/3/9 e
  1/4 shard), writer distinti, obblighi legali, wrap e riuso dopo completamento.
- Modello/fixture con ring riempiti durante tratti in corso: controesempio
  alla sola pubblicazione e avanzamento bounded con ricircolo; proprietà
  unica dell'obbligo, lease singola e elaborazione unica dei payload.
- Full/room, input invalidi, rifiuto busy senza effetti, FI private su forma,
  tipo del riferimento e proprietà; due consumer riusati, producer vivo,
  avanzamento di altra partizione mentre una guard resta occupata.
- Due letture C1, inventario completo delle decisioni e copertura raw dei
  file execution. Nessuna forma sottratta o esclusione approvata; sb-cover
  non prova MC/DC. Compilazione senza warning/style-warning e make check.
- Undici mutanti del nuovo sorgente: fifo-next-slot, head-wrap-two,
  tail-wrap-two, full-count-decrement, full-keeps-old-slot, full-boundary,
  full-returns-new-writer, room-returns-writer, full-status-published,
  release-skipped, full-no-rotation. Baseline completa obbligatoria;
  compilation failure, before-tests e worker-error (segnali OS o guasti dopo
  completion autentica) non contano come rilevamento.
- Misura composta handoff/ready/ricircolo: shard 1/4 × capacity 1/3,
  cinque campioni da 4096 cicli, warmup 128 e GC fuori dal contatore.
  C+1 writer distinti per shard, ruolo iniziale ruotato a ogni ciclo;
  pubblicazione room, scambio full e drain di C riferimenti restanti.
  Identità, count, status, payload e generation controllati; sink esatto
  ricalcolato indipendentemente, controllo heap positivo, sink errato
  rifiutato, clock zero distinto e report parziali preservati.
  I campioni non provano zero allocazioni universale, speedup, throughput
  del pool o P99. Startup e condizioni d'errore sono fuori dalla finestra.

Ogni tentativo di verifica usa record-command, con argv, ambiente, sorgenti
stabili e output integrali. I C4 sono compilati interamente e i FASL eseguono
self-test in processi/cache separati. Campagne su copia congelata; dati grandi
compressi senza perdita, validati dal lettore delle evidenze.

## Oracoli e modifiche esatte preregistrati

Le undici sostituzioni uniche sono fissate in
[`tools/writer-recycle-mutation.lisp`](../../tools/writer-recycle-mutation.lisp)
prima dell'esecuzione. FIFO legge lo slot successivo; head e tail avanzano di
due separatamente; count full decrementa; lo slot conserva OLD usando
`(if (eq writer old) writer old)` per evitare warning estranei; la soglia
full usa `>`; il riferimento restituito diventa WRITER; room restituisce
WRITER invece di NIL; status full diventa `:published`, anche nella ftype;
il cleanup diventa NIL; NEXT diventa HEAD conservando la forma full ma
violando la rotazione FIFO. Ciascun mutante cambia solo il nuovo sorgente.

Derivazione indipendente del benchmark: M=K(C+1), enqueue contribuisce 12M,
consume 45M+5Σid e il trasferimento delle identità 17M+5Σid, con id da 1 a M.
Room aggiunge K(31C+3C(C+1)/2), full K(13+3C); i cursori del drain aggiungono
7CK(K−1)/2 e empty 29. Il token fisso è quindi
`74M+5M(M+1)+K(31C+3C(C+1)/2+13+3C)+7CK(K−1)/2+29`.
Per (K,C)=(1,1)/(1,3)/(4,1)/(4,3): 257/558/1223/3231.
Il sink dei 4096 cicli include Σi: 9439232/10672128/13395968/21620736.
Le chiamate per ciclo sono `K(6C+5)+1`: 12/24/45/93.
")))
