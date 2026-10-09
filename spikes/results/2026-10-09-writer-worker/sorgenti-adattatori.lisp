(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :PART 1 :PARTS 1 :SOURCES
 ((:PATH #A((44) BASE-CHAR . "spikes/out/worker-publication-functions.lisp") :BYTES 24521 :SHA256
   "01ce7104faa1905afa2f6b48a03bee04c176ee4c9f68e16ddb1ff435d70a028b" :GIT-BLOB
   "0f07134b815897b8bd75ee04e9f7e9a1b3eab49f" :TEXT
   ";;;; Adattatore della sola conservazione: definizioni, nessuna pubblicazione al LOAD.
;;;; Copie binarie esclusive; descriptor originale letto separatamente dal decoded.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(in-package #:cl-user)

(defparameter *worker-publication-directory*
  #p\"spikes/results/2026-10-09-writer-worker/\")

(defun worker-leaf-p (name)
  (and (stringp name) (plusp (length name))
       (not (member name '(\".\" \"..\") :test #'string=))
       (not (find-if (lambda (character)
                       (or (zerop (char-code character))
                           (find character \"/\\\\*?[]\"))) name))))

(defun worker-read-raw-data (path)
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

(defun worker-byte-record (path)
  (list :path (namestring (pathname path))
        :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)
        :git-blob
        (string-trim '(#\\Newline #\\Space)
                     (uiop:run-program
                      (list \"git\" \"hash-object\" \"--\" (namestring (pathname path)))
                      :output :string))))

(defun worker-source-record (path)
  \"Bundle lossless di sorgenti/log UTF-8 con path, bytes, SHA256 e Git blob.\"
  (let* ((before (worker-byte-record path))
         (text (uiop:read-file-string path :external-format :utf-8))
         (octets (sb-ext:string-to-octets text :external-format :utf-8))
         (after (worker-byte-record path)))
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
    (unless (equal before (worker-byte-record path))
      (error \"Sorgente cambiata durante la verifica UTF-8: ~A\" path))
    (append before (list :text text))))

(defun worker-exclusive-output (path)
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

(defun worker-copy-exclusive (source target)
  \"Conserva esattamente i bytes originali e rifiuta destinazioni già esistenti.\"
  (let ((before (worker-byte-record source))
        (buffer (make-array 65536 :element-type '(unsigned-byte 8))))
    (with-open-file (input source :direction :input :element-type '(unsigned-byte 8))
      (with-open-stream (output (worker-exclusive-output target))
        (loop for count = (read-sequence buffer input) until (zerop count)
              do (write-sequence buffer output :end count))))
    (let ((after (worker-byte-record source)) (copy (worker-byte-record target)))
      (unless (and (equal before after)
                   (= (getf before :bytes) (getf copy :bytes))
                   (string= (getf before :sha256) (getf copy :sha256))
                   (string= (getf before :git-blob) (getf copy :git-blob)))
        (error \"Copia non lossless o sorgente cambiata: ~A -> ~A\" source target))
      copy)))

(defun worker-data-octets (data)
  \"Serializzazione unica usata sia dal preflight sia dalla scrittura bounded.\"
  (sb-ext:string-to-octets
   (with-output-to-string (stream)
     (let ((*print-readably* t) (*print-circle* nil)
           (*print-length* nil) (*print-level* nil)
           (*print-right-margin* 100) (*print-miser-width* nil))
       (write data :stream stream :pretty t) (terpri stream)))
   :external-format :utf-8))

(defun worker-byte-records-equal-p (left right)
  (and left right (= (getf left :bytes) (getf right :bytes))
       (string= (getf left :sha256) (getf right :sha256))
       (string= (getf left :git-blob) (getf right :git-blob))))

(defun worker-octets-match-file-p (octets path)
  (and (= (length octets) (arcdocdb.evidence:file-bytes path))
       (with-open-file (input path :direction :input :element-type '(unsigned-byte 8))
         (let ((buffer (make-array 65536 :element-type '(unsigned-byte 8))) (position 0))
           (loop for count = (read-sequence buffer input) until (zerop count)
                 do (unless (and (<= (+ position count) (length octets))
                                 (loop for i below count
                                       always (= (aref buffer i) (aref octets (+ position i)))))
                      (return-from worker-octets-match-file-p nil))
                    (incf position count))
           (= position (length octets))))))

(defun worker-validate-serialized-data (data path &key (max-expanded-bytes 1048576))
  \"Validità reader distinta dall'identità dei bytes serializzati; #: non usa EQ.\"
  (arcdocdb.evidence:read-evidence path :max-expanded-bytes max-expanded-bytes)
  (unless (worker-octets-match-file-p (worker-data-octets data) path)
    (error \"Bytes serializzati differenti dai dati richiesti: ~A\" path))
  t)

(defun worker-evidence-byte-proof (path &key (max-expanded-bytes 134217728))
  \"Reader valido + raw e bytes espansi verificati; nessun EQUALP di fresh #:.
Il descriptor è letto separatamente, con basename e bytes del payload originali.\"
  (unless (sb-posix:s-isreg (sb-posix:stat-mode (sb-posix:lstat (namestring (pathname path)))))
    (error \"Evidence proof richiede file regolare, senza symlink: ~A\" path))
  (let* ((before (worker-byte-record path))
         (raw (worker-read-raw-data path))
         (descriptor (eq (getf raw :kind) :compressed-evidence))
         (payload (and descriptor (getf raw :payload))))
    (when (and payload (not (worker-leaf-p payload)))
      (error \"Payload proof non leaf: ~S\" payload))
    (let* ((payload-path (and payload
                              (merge-pathnames payload (uiop:pathname-directory-pathname path))))
           (payload-before (and payload-path (worker-byte-record payload-path)))
           (decoded (arcdocdb.evidence:read-evidence path :max-expanded-bytes max-expanded-bytes))
           (expanded (arcdocdb.evidence:call-with-evidence-bytes
                      path (lambda (expanded-path) (worker-byte-record expanded-path))
                      :max-expanded-bytes max-expanded-bytes))
           (after (worker-byte-record path))
           (payload-after (and payload-path (worker-byte-record payload-path))))
      (unless (and (worker-byte-records-equal-p before after)
                   (or (null payload-path)
                       (worker-byte-records-equal-p payload-before payload-after)))
        (error \"Evidence o payload cambiati durante il proof: ~A\" path))
      (values (list :raw before :expanded expanded :payload-name payload
                    :payload-record payload-before)
              decoded))))

(defun worker-evidence-proofs-equal-p (left right)
  (and (worker-byte-records-equal-p (getf left :raw) (getf right :raw))
       (worker-byte-records-equal-p (getf left :expanded) (getf right :expanded))
       (equal (getf left :payload-name) (getf right :payload-name))
       (if (getf left :payload-name)
           (worker-byte-records-equal-p (getf left :payload-record) (getf right :payload-record))
           (null (getf right :payload-record)))))

(defun worker-stage-data (data directory)
  \"Prevalida dati UTF-8 in un tempfile esclusivo; massimo un MiB plain.
Il tempfile viene preservato se la lettura o l'uguaglianza dei dati fallisce.\"
  (let ((octets (worker-data-octets data)))
    (when (> (length octets) 1048576)
      (error \"Dati plain oltre un MiB prima della scrittura: ~D bytes.\" (length octets)))
    (multiple-value-bind (fd name)
        (sb-posix:mkstemp (namestring (merge-pathnames \".worker-data-XXXXXX\" directory)))
      (let ((path (pathname name)))
        (unwind-protect
             (with-open-stream
                 (stream (prog1 (sb-sys:make-fd-stream fd :output t
                                                      :element-type '(unsigned-byte 8)
                                                      :auto-close t)
                           (setf fd nil)))
               (write-sequence octets stream))
          (when fd (sb-posix:close fd)))
        (worker-validate-serialized-data data path)
        path))))

(defun worker-save-data (data path)
  \"Prevalida bytes/decoded in out, poi copia esclusivamente senza sovrascrivere.\"
  (let ((temporary (worker-stage-data data #p\"spikes/out/\")))
    (prog1 (worker-copy-exclusive temporary path)
      (worker-validate-serialized-data data path)
      (delete-file temporary))))

(defun worker-copy-evidence (source target)
  \"Copia esclusiva, validità reader e identità raw/expanded bytes; #: non usa EQ.\"
  (multiple-value-bind (before decoded) (worker-evidence-byte-proof source)
    (let* ((payload (getf before :payload-name))
           (source-payload (and payload (merge-pathnames payload (uiop:pathname-directory-pathname source))))
           (target-payload (and payload (merge-pathnames payload (uiop:pathname-directory-pathname target)))))
      (when (> (getf (getf before :raw) :bytes) 1048576)
        (error \"Originale plain/descriptor oltre un MiB: ~A\" source))
      (when (and payload (> (getf (getf before :payload-record) :bytes) 8388608))
        (error \"Payload gzip oltre otto MiB: ~A\" source-payload))
      (unless (worker-leaf-p (file-namestring (pathname target)))
        (error \"Destinazione evidence non leaf: ~A\" target))
      (when (or (probe-file target) (and target-payload (probe-file target-payload)))
        (error \"Destinazione o payload già esistente: ~A\" target))
      (when source-payload (worker-copy-exclusive source-payload target-payload))
      (let ((copied (worker-copy-exclusive source target)))
        (unless (and (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof source))
                     (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof target)))
          (error \"Raw/expanded bytes divergenti dopo copia: ~A -> ~A\" source target))
        (values decoded copied (and target-payload (worker-byte-record target-payload)))))))

(defun worker-copy-evidence-resume (source target)
  \"Skip solo dopo proof completo; nessun file esistente viene sovrascritto.\"
  (let* ((before (worker-evidence-byte-proof source))
         (payload (getf before :payload-name))
         (target-payload (and payload (merge-pathnames payload (uiop:pathname-directory-pathname target)))))
    (when (> (getf (getf before :raw) :bytes) 1048576)
      (error \"Originale plain/descriptor oltre un MiB: ~A\" source))
    (when (and payload (> (getf (getf before :payload-record) :bytes) 8388608))
      (error \"Payload gzip oltre otto MiB: ~A\" payload))
    (cond
      ((probe-file target)
       (unless (and (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof target))
                    (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof source)))
         (error \"Resume rifiutato: evidence esistente diversa; nessun overwrite: ~A\" target))
       (format t \"Evidence esistente verificata senza overwrite: ~A~%\" target)
       :verified-existing)
      ((and target-payload (probe-file target-payload))
       ;; Interruzione tra payload e descriptor: si completa soltanto se il gzip
       ;; esistente coincide esattamente con l'originale valido e ancora stabile.
       (unless (and (worker-byte-records-equal-p (getf before :payload-record)
                                                (worker-byte-record target-payload))
                    (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof source)))
         (error \"Resume rifiutato: payload esistente diverso; nessun overwrite: ~A\" target-payload))
       (worker-copy-exclusive source target)
       (unless (and (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof target))
                    (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof source)))
         (error \"Resume descriptor divergente; files preservati: ~A\" target))
       :completed-descriptor)
      (t (worker-copy-evidence source target) :copied))))

(defun worker-validate-compacted-review-results ()
  \"Riusa esclusivamente lo stage già valido: niente gzip e niente overwrite.\"
  (let* ((source #p\"spikes/out/worker-review-results-data.lisp\")
         (target #p\"spikes/out/worker-review-results-compacted/worker-review-results-data.lisp\")
         (source-proof (worker-evidence-byte-proof source))
         (target-proof (worker-evidence-byte-proof target))
         (summary (arcdocdb.evidence:read-evidence \"spikes/out/worker-review-summary-data.lisp\")))
    (unless (and (string= (getf summary :original-sha256)
                         (getf (getf source-proof :raw) :sha256))
                 (string= (getf target-proof :payload-name) \"worker-review-results-data.lisp.gz\")
                 (worker-byte-records-equal-p (getf source-proof :expanded)
                                              (getf target-proof :expanded))
                 (worker-evidence-proofs-equal-p source-proof (worker-evidence-byte-proof source)))
      (error \"Stage full esistente diverso dall'originale; nessun overwrite.\"))
    (format t \"Stage full esistente verificato raw/expanded: ~A, ~D bytes logici.~%\"
            target (getf (getf source-proof :expanded) :bytes))
    target))

(defun worker-compact-review-results ()
  \"Compatta una copia ignored del full; il plain originale non viene modificato.
La nuova directory e tutti i file sono esclusivi. Ogni errore conserva i file
prodotti per diagnosi; il payload gzip ha un basename unico e verificato.\"
  (let* ((source #p\"spikes/out/worker-review-results-data.lisp\")
         (directory #p\"spikes/out/worker-review-results-compacted/\")
         (target (merge-pathnames (file-namestring source) directory))
         (payload-name (concatenate 'string (file-namestring source) \".gz\"))
         (payload (merge-pathnames payload-name directory))
         (before (worker-byte-record source))
         (original-valid (progn (arcdocdb.evidence:read-evidence source) t))
         (summary (arcdocdb.evidence:read-evidence
                   \"spikes/out/worker-review-summary-data.lisp\")))
    (declare (ignore original-valid))
    (unless (string= (getf before :sha256) (getf summary :original-sha256))
      (error \"Summary non riferito ai bytes del full originale.\"))
    (sb-posix:mkdir (namestring directory) #o700)
    (with-open-stream (output (worker-exclusive-output payload))
      (uiop:run-program (list \"gzip\" \"-n\" \"-9\" \"-c\" \"--\" (namestring source))
                        :output output :error-output :string))
    (when (> (arcdocdb.evidence:file-bytes payload) 8388608)
      (error \"Payload full compattato oltre otto MiB; file ignored preservati.\"))
    (unless (equal before (worker-byte-record source))
      (error \"Full originale cambiato durante gzip; file ignored preservati.\"))
    (let* ((descriptor
             (list :schema-version 1 :kind :compressed-evidence :codec :gzip
                   :payload payload-name :uncompressed-bytes (getf before :bytes)
                   :uncompressed-sha256 (getf before :sha256)
                   :compressed-bytes (arcdocdb.evidence:file-bytes payload)
                   :compressed-sha256 (arcdocdb.evidence:file-sha256 payload)))
           (octets (worker-data-octets descriptor)))
      (when (> (length octets) 1048576)
        (error \"Descriptor full oltre un MiB prima della scrittura.\"))
      (with-open-stream (output (worker-exclusive-output target))
        (write-sequence octets output))
      ;; READ-EVIDENCE qui è intenzionalmente distinto dalla lettura raw del
      ;; descriptor: il full espanso è 29 MB e usa il limite pubblico del reader.
      (unless (and (worker-octets-match-file-p octets target)
                   (worker-byte-records-equal-p
                    (getf (worker-evidence-byte-proof source) :expanded)
                    (getf (worker-evidence-byte-proof target) :expanded))
                   (equal before (worker-byte-record source)))
        (error \"Descriptor o decoded full divergenti; originali preservati.\"))
      (format t \"Full audit compattato senza modificare il plain: ~D -> ~D bytes, SHA logico ~A.~%\"
              (getf before :bytes) (arcdocdb.evidence:file-bytes payload)
              (getf before :sha256))
      target)))

(defun worker-copy-process (record stem &key (directory *worker-publication-directory*))
  \"Copia report e conservazione con nomi flat; nessun overwrite implicito.\"
  (unless (and (worker-leaf-p record) (worker-leaf-p stem))
    (error \"Record o stem non leaf: ~S / ~S\" record stem))
  (dolist (part '(\"report\" \"conservazione\"))
    (worker-copy-evidence
     (format nil \"spikes/out/~A/~A.lisp\" record part)
     (merge-pathnames
      (format nil \"~A~A.lisp\" stem (if (string= part \"report\") \"\" \"-conservazione\"))
      directory))))

(defun worker-save-source-bundle (paths target kind &key version)
  (worker-save-data
   (append (list :schema-version 1 :kind kind)
           (when version (list :version version))
           (list :sources (mapcar #'worker-source-record paths))) target))

(defun worker-source-bundle-data (sources kind version part parts)
  (append (list :schema-version 1 :kind kind)
          (when version (list :version version))
          (list :part part :parts parts :sources sources)))

(defun worker-plan-source-bundles (paths stem kind &key version)
  \"Legge ogni sorgente intero una volta e pianifica bundle sotto un MiB.
Nessuna scrittura, neppure temporanea; i nomi sono determinati prima delle copie.
Il record conserva path/bytes/SHA256/Git blob/text originali senza frammenti.\"
  (unless (and paths (worker-leaf-p stem))
    (error \"Bundle senza sorgenti o stem leaf: ~S\" stem))
  (unless (= (length paths) (length (remove-duplicates paths :test #'equal)))
    (error \"Sorgenti duplicate nel bundle ~A.\" stem))
  (let ((groups nil) (group nil) (part-bound (length paths)))
    (dolist (path paths)
      (let* ((record (worker-source-record path))
             (candidate (append group (list record))))
        ;; Il massimo indice/numero di parti è il numero di sorgenti: riserva
        ;; esattamente lo spazio di metadata sufficiente per qualsiasi split.
        (if (<= (length (worker-data-octets
                         (worker-source-bundle-data candidate kind version
                                                    part-bound part-bound)))
                1048576)
            (setf group candidate)
            (progn
              (unless group
                (error \"Sorgente singola oltre un MiB serializzato: ~A\" path))
              (push group groups)
              (setf group (list record))
              (when (> (length (worker-data-octets
                               (worker-source-bundle-data group kind version
                                                          part-bound part-bound)))
                       1048576)
                (error \"Sorgente singola oltre un MiB serializzato: ~A\" path))))))
    (push group groups)
    (setf groups (nreverse groups))
    (loop with parts = (length groups)
          for sources in groups for part from 1
          for leaf = (if (= parts 1) (format nil \"~A.lisp\" stem)
                         (format nil \"~A-~D.lisp\" stem part))
          for data = (worker-source-bundle-data sources kind version part parts)
          for bytes = (length (worker-data-octets data))
          do (when (> bytes 1048576)
               (error \"Piano bundle oltre un MiB: ~A (~D).\" leaf bytes))
          collect (list :leaf leaf :data data :bytes bytes))))

(defun worker-validate-source-plans (plans)
  \"Verifica che i bytes conservati nel piano si riferiscano ancora ai sorgenti.\"
  (dolist (plan plans)
    (dolist (source (getf (getf plan :data) :sources))
      (let ((current (worker-byte-record (getf source :path))))
        (unless (and (= (getf source :bytes) (getf current :bytes))
                     (string= (getf source :sha256) (getf current :sha256))
                     (string= (getf source :git-blob) (getf current :git-blob)))
          (error \"Sorgente cambiata dopo il piano: ~A\" (getf source :path))))))
  t)

(defun worker-write-catalog (data target)
  \"Sostituisce soltanto il catalogo del componente, dopo staging verificato.\"
  (unless (string= (file-namestring (pathname target)) \"catalogo.lisp\")
    (error \"La sostituzione è consentita soltanto per catalogo.lisp: ~A\" target))
  (let ((previous (and (probe-file target) (arcdocdb.evidence:read-evidence target))))
    (when (and previous
               (not (and (eq (getf previous :kind) :evidence-catalog)
                         (eq (getf previous :component) :writer-worker))))
      (error \"Catalogo esistente di un altro componente: ~A\" target))
    (let* ((temporary (worker-stage-data data (uiop:pathname-directory-pathname target)))
           (before (worker-byte-record temporary)))
      (sb-posix:rename (namestring temporary) (namestring (pathname target)))
      (let ((after (worker-byte-record target)))
        (unless (and (= (getf before :bytes) (getf after :bytes))
                     (string= (getf before :sha256) (getf after :sha256))
                     (string= (getf before :git-blob) (getf after :git-blob))
                     (worker-validate-serialized-data data target))
          (error \"Catalogo differente dopo rename verificato: ~A\" target))
        after))))

(defun worker-refresh-catalog (base &key historical-bases
                                        (directory *worker-publication-directory*))
  \"Catalogo flat dei dati validati, path originali, hashes e Git blobs dei files.\"
  (let* ((paths (sort (directory (merge-pathnames \"*.lisp\" directory)) #'string<
                      :key #'namestring))
         (entries
           (loop for path in paths
                 unless (string= (file-namestring path) \"catalogo.lisp\")
                 collect
                 (progn
                   (unless (worker-leaf-p (file-namestring path))
                     (error \"Artifact non flat: ~A\" path))
                   (arcdocdb.evidence:read-evidence path)
                   (let ((raw (worker-read-raw-data path)))
                     (append (list :artifact (file-namestring path))
                             (worker-byte-record path)
                             (when (eq (getf raw :kind) :compressed-evidence)
                               (let ((payload (getf raw :payload)))
                                 (list :payload
                                       (append (list :artifact payload)
                                               (worker-byte-record
                                                (merge-pathnames payload directory))))))))))))
    (worker-write-catalog
     (list :schema-version 1 :kind :evidence-catalog :component :writer-worker
           :base base :historical-bases historical-bases :entries entries)
     (merge-pathnames \"catalogo.lisp\" directory))))
")
  (:PATH #A((38) BASE-CHAR . "spikes/out/worker-refresh-catalog.lisp") :BYTES 263 :SHA256
   "836fd4b47889108a40bde0f478ad5fdc6534d59c9092fa9234f9a363414e23e3" :GIT-BLOB
   "fec377f61f6867058ce3e2f5012493cfb63a8a76" :TEXT
   ";;;; Definizioni soltanto: la base e l'istante finale vengono scelti dal root.
(load \"spikes/out/worker-publication-functions.lisp\")
(defun worker-final-catalog (base &optional historical-bases)
  (worker-refresh-catalog base :historical-bases historical-bases))
")
  (:PATH #A((30) BASE-CHAR . "spikes/out/worker-publish.lisp") :BYTES 16052 :SHA256
   "22819aa0b3a3dca046bc971e094dc3bc0b31c108ed4b8d4fbde7f41234e447cb" :GIT-BLOB
   "7b3ddd059f20d7c73b4db4485bad383004d8f488" :TEXT
   ";;;; Manifest/driver: LOAD definisce soltanto, non pubblica e non esegue campagne.
;;;; Il root completa i processi finali e autorizza WORKER-RUN-PUBLICATION.
(load \"spikes/out/worker-publication-functions.lisp\")

(defparameter *worker-process-manifest*
  '((\"4000545928-command-51771-0\" \"strict-iniziale-storico-processo\")
    (\"4000547204-command-93189-0\" \"check-finale-processo\")
    (\"4000547204-command-93188-0\" \"copertura-processo\")
    (\"4000547249-command-95826-0\" \"copertura-export-processo\")
    (\"4000547329-command-479-0\" \"probe-root-processo\")
    (\"4000547221-command-94073-0\" \"bench-self-test-processo\")
    (\"4000547221-command-94074-0\" \"mutazioni-self-test-processo\")
    (\"4000547268-command-97067-0\" \"mutazioni-processo\")
    (\"4000547268-command-97066-0\" \"allocazioni-processo\")
    (\"4000547296-command-98426-0\" \"revisione-copertura-processo\")
    (\"4000547904-command-30631-0\" \"pubblicazione-piano-processo\")
    (\"4000547596-command-16195-0\" \"revisione-mappa-sorgenti-processo\")
    (\"4000547809-command-24892-0\" \"revisione-summary-fallito-processo\")
    (\"4000547879-command-29495-0\" \"revisione-summary-processo\")
    (\"4000548017-command-37007-0\" \"scope-integrazione-processo\")
    (\"4000548048-command-40192-0\" \"check-integrazione-processo\")
    (\"4000548534-command-60644-0\" \"revisione-indipendente-integrazione-processo\")))

;; Placeholder esplicito: il processo autore e gli altri processi finali
;; saranno aggiunti soltanto dopo che il root ne avrà fornito il manifest.
(defparameter *worker-final-process-manifest* nil)

(defparameter *worker-data-manifest*
  '((\"spikes/out/worker-coverage-export.lisp\" \"copertura-grezza.lisp\")
    (\"spikes/out/worker-publication-unrecorded-planning-data.lisp\" \"pubblicazione-piano-tentativo-non-registrato.lisp\")
    (\"spikes/out/worker-review-coverage-data.lisp\" \"revisione-copertura-dati.lisp\")
    (\"spikes/out/worker-review-forms-data.lisp\" \"revisione-mappa-sorgenti-dati.lisp\")
    (\"spikes/out/worker-review-results-compacted/worker-review-results-data.lisp\" \"revisione-risultati-integrale.lisp\")
    (\"spikes/out/worker-review-summary-data.lisp\" \"revisione-risultati-sommario.lisp\")
    (\"spikes/out/worker-mutations/report.lisp\" \"mutazioni-dati.lisp\")
    (\"spikes/out/worker-allocations/report.lisp\" \"allocazioni-dati.lisp\")
    (\"spikes/out/4000547222-worker-signal-self-test-94121/report.lisp\" \"segnale-os-dati.lisp\")
    (\"spikes/out/4000547284-check-97964-0/report.lisp\" \"spikes-finali.lisp\")
    (\"spikes/out/4000547284-check-97964-0/conservazione.lisp\" \"spikes-finali-conservazione.lisp\")))

(defparameter *worker-adapter-manifest*
  '(\"spikes/out/worker-publication-functions.lisp\"
    \"spikes/out/worker-refresh-catalog.lisp\"
    \"spikes/out/worker-publish.lisp\"
    \"spikes/out/worker-publication-plan.lisp\"
    \"spikes/out/worker-tool-self-test.lisp\"
    \"spikes/out/worker-tool-campaign.lisp\"
    \"spikes/out/worker-export-coverage.lisp\"
    \"spikes/out/worker-root-summary.lisp\"
    \"spikes/out/worker-strict-product.lisp\"
    \"spikes/out/worker-author-review.lisp\"
    \"spikes/out/worker-review-coverage.lisp\"
    \"spikes/out/worker-review-forms.lisp\"
    \"spikes/out/worker-review-results.lisp\"
    \"spikes/out/worker-review-summary.lisp\"
    \"spikes/out/worker-review-summary-failed.lisp\"
    \"spikes/out/worker-review-html.py\"
    \"spikes/out/worker-c1-integration-addendum-read.lisp\"
    \"arcdocdb.asd\"
    \"src/execution/package.lisp\"
    \"src/execution/queue.lisp\"
    \"src/execution/writer.lisp\"
    \"src/execution/handoff.lisp\"
    \"src/execution/ready-types.lisp\"
    \"src/execution/ready.lisp\"
    \"src/execution/ready-recycle.lisp\"
    \"src/execution/worker-types.lisp\"
    \"src/execution/worker-boundary.lisp\"
    \"src/execution/worker-claim.lisp\"
    \"src/execution/worker-run.lisp\"
    \"tests/execution/support.lisp\"
    \"tests/execution/handoff.lisp\"
    \"tests/execution/ready.lisp\"
    \"tests/execution/ready-recycle.lisp\"
    \"tests/execution/worker.lisp\"
    \"tools/writer-worker-bench.lisp\"
    \"tools/writer-worker-mutation.lisp\"
    \"tools/build.lisp\"
    \"docs/implementazione/writer-worker-metodo.md\"))

(defparameter *worker-review-manifest*
  '((\"spikes/out/worker-c1-initial.lisp\" \"revisione-indipendente-iniziale.lisp\")
    (\"spikes/out/worker-c1-initial-closed.lisp\" \"revisione-indipendente-iniziale-chiusa.lisp\")
    (\"spikes/out/worker-c1-final.lisp\" \"revisione-indipendente-finale.lisp\")
    (\"spikes/out/worker-c1-integration-addendum.lisp\" \"revisione-indipendente-integrazione.lisp\")
    (\"spikes/out/worker-author-review-data.lisp\" \"revisione-autore.lisp\")))

(defun worker-publication-target (leaf)
  (unless (worker-leaf-p leaf) (error \"Target non flat: ~S\" leaf))
  (merge-pathnames leaf *worker-publication-directory*))

(defun worker-publication-pairs (review-records final-processes extra-processes)
  \"Coppie source/target: ogni processo conserva report e conservazione originali.\"
  (append
   (loop for (record stem) in (append *worker-process-manifest*
                                     final-processes extra-processes)
         do (unless (and (worker-leaf-p record) (worker-leaf-p stem))
              (error \"Record/stem processo non leaf: ~S / ~S\" record stem))
         append
         (loop for part in '(\"report\" \"conservazione\")
               collect (list (format nil \"spikes/out/~A/~A.lisp\" record part)
                             (format nil \"~A~A.lisp\" stem
                                     (if (string= part \"report\") \"\" \"-conservazione\")))))
   *worker-data-manifest* review-records))

(defun worker-coverage-html-paths ()
  (let ((html (sort (directory \"spikes/out/worker-coverage/*.html\") #'string<
                    :key #'namestring)))
    (unless (and (= 12 (length html))
                 (find \"cover-index.html\" html :test #'string= :key #'file-namestring))
      (error \"Copertura HTML: richiesti indice e undici file.\"))
    (mapcar #'namestring html)))

(defun worker-mutation-log-paths ()
  (let* ((data (arcdocdb.evidence:read-evidence \"spikes/out/worker-mutations/report.lisp\"))
         (paths (cons (getf data :baseline-log)
                      (mapcar (lambda (entry) (getf entry :log)) (getf data :mutants)))))
    (unless (and (every #'stringp paths)
                 (= 13 (length paths))
                 (= 13 (length (remove-duplicates paths :test #'equal))))
      (error \"Mutazioni: richiesti baseline e dodici log distinti.\"))
    paths))

(defun worker-preflight-publication (pairs plans)
  \"Valida originali, dimensioni e collisioni prima di qualsiasi copia canonica.\"
  (let ((targets (list \"catalogo.lisp\")) (payloads nil))
    (dolist (pair pairs)
      (let* ((source (first pair)) (leaf (second pair))
             (target (worker-publication-target leaf))
             (raw (progn (arcdocdb.evidence:read-evidence source)
                         (worker-read-raw-data source))))
        (when (> (arcdocdb.evidence:file-bytes source) 1048576)
          (error \"Originale plain/descriptor oltre un MiB: ~A\" source))
        (when (or (member leaf targets :test #'string=) (probe-file target))
          (error \"Artifact già esistente o ripetuto: ~A\" target))
        (push leaf targets)
        (when (eq (getf raw :kind) :compressed-evidence)
          (let ((payload (getf raw :payload)))
            (unless (worker-leaf-p payload) (error \"Payload non leaf: ~S\" payload))
            (when (> (arcdocdb.evidence:file-bytes
                      (merge-pathnames payload (uiop:pathname-directory-pathname source)))
                     8388608)
              (error \"Payload gzip oltre otto MiB: ~A\" payload))
            (when (or (member payload payloads :test #'string=)
                      (probe-file (worker-publication-target payload)))
              (error \"Collisione payload preservato: ~S\" payload))
            (push payload payloads)))))
    (dolist (plan plans)
      (let ((leaf (getf plan :leaf)))
        (when (or (member leaf targets :test #'string=)
                  (member leaf payloads :test #'string=)
                  (probe-file (worker-publication-target leaf)))
          (error \"Bundle già esistente o in conflitto: ~S\" leaf))
        (unless (= (getf plan :bytes) (length (worker-data-octets (getf plan :data))))
          (error \"Dimensione bundle cambiata dopo il piano: ~A\" leaf))
        (when (> (getf plan :bytes) 1048576)
          (error \"Bundle oltre un MiB: ~A\" leaf))
        (push leaf targets)))
    (when (intersection targets payloads :test #'string=)
      (error \"Un payload preservato collide con un artifact.\"))
    (worker-validate-source-plans plans)
    t))

(defun worker-run-publication (&key (review-records *worker-review-manifest*)
                                   (final-processes *worker-final-process-manifest*)
                                   extra-processes adapter-sources)
  \"Pubblica soltanto il manifest finale autorizzato. Nessun catalogo scritto qui.
I bundle vengono pianificati in memoria prima di creare la directory canonica.\"
  (unless (and review-records final-processes
               (find \"revisione-autore-processo\" final-processes
                     :test #'string= :key #'second))
    (error \"Manifest finale autore/C1 non ancora fornito dal root.\"))
  (let* ((pairs (worker-publication-pairs review-records final-processes extra-processes))
         (logs (worker-mutation-log-paths)) (html (worker-coverage-html-paths))
         (signal '(\"spikes/out/4000547222-worker-signal-self-test-94121/test.log\"
                   \"spikes/out/4000547222-worker-signal-self-test-94121/tools/writer-worker-isolated-build.lisp\"))
         (adapters (append *worker-adapter-manifest* adapter-sources))
         (plans (append
                 (worker-plan-source-bundles logs \"mutazioni-log\" :raw-mutation-logs)
                 (worker-plan-source-bundles
                  '(\"spikes/out/worker-coverage/coverage-state.lisp\")
                  \"copertura-native\" :raw-coverage-native :version :eleven-execution-files)
                 (worker-plan-source-bundles
                  html \"copertura-html\" :raw-coverage-html :version :eleven-execution-files)
                 (worker-plan-source-bundles signal \"segnale-os-originali\"
                                             :process-signal-raw-sources)
                 (worker-plan-source-bundles adapters \"sorgenti-adattatori\"
                                             :verification-adapter-sources)))
         (staged nil))
    ;; Solo il full oversize richiede uno staging ignored compattato. Il plain
    ;; originale rimane intatto; nessun target canonico esiste prima del preflight.
    (worker-compact-review-results)
    (worker-preflight-publication pairs plans)
    ;; Il reader bounded valida TUTTI i bundle in out prima della prima copia
    ;; canonica. Tempfile preservati in caso di errore; nessun overwrite.
    (setf staged (loop for plan in plans
                       collect (worker-stage-data (getf plan :data) #p\"spikes/out/\")))
    (worker-validate-source-plans plans)
    (dolist (plan plans)
      (format t \"Bundle preflight ~A: ~D bytes, ~D sorgenti.~%\"
              (getf plan :leaf) (getf plan :bytes)
              (length (getf (getf plan :data) :sources))))
    (ensure-directories-exist (worker-publication-target \"catalogo.lisp\"))
    (dolist (pair pairs)
      (worker-copy-evidence (first pair) (worker-publication-target (second pair))))
    (worker-validate-source-plans plans)
    (loop for plan in plans for temporary in staged
          for target = (worker-publication-target (getf plan :leaf))
          do (worker-copy-exclusive temporary target)
             (unless (equalp (getf plan :data)
                             (arcdocdb.evidence:read-evidence target
                                                              :max-expanded-bytes 1048576))
               (error \"Bundle copiato diverso dal piano: ~A\" target))
             (delete-file temporary))
    (worker-validate-source-plans plans)
    (format t \"Manifest pubblicato: ~D coppie, ~D bundle, ~D log, native e 12 HTML; copie lossless validate.~%\"
            (length pairs) (length plans) (length logs))
    t))

(defparameter *worker-integration-publication-directory*
  #p\"spikes/results/2026-10-09-writer-worker-integration/\")
(defparameter *worker-integration-master-record* \"4000548134-check-44515-0\")

(defun worker-run-integration-evidence
    (&key (record *worker-integration-master-record*)
          (directory *worker-integration-publication-directory*)
          (base \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\")
          (historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"))
          metadata)
  \"Pubblica il master v2 in una directory flat separata, conservando report.lisp.gz.
Il catalogo iniziale identifica base integrata e base storica. LOAD non pubblica;
il root può aggiornarlo dopo la conservazione del processo di pubblicazione.\"
  (unless (worker-leaf-p record) (error \"Master integration non leaf: ~S\" record))
  (let* ((*worker-publication-directory* directory)
         (pairs (list (list (format nil \"spikes/out/~A/report.lisp\" record)
                            \"spikes-finali.lisp\")
                      (list (format nil \"spikes/out/~A/conservazione.lisp\" record)
                            \"spikes-finali-conservazione.lisp\")))
         (plans (when metadata
                  (list (list :leaf \"integrazione-metadata.lisp\" :data metadata
                              :bytes (length (worker-data-octets metadata)))))))
    (worker-preflight-publication pairs plans)
    (let ((staged (when metadata (worker-stage-data metadata #p\"spikes/out/\"))))
      (ensure-directories-exist (worker-publication-target \"catalogo.lisp\"))
      (dolist (pair pairs)
        (worker-copy-evidence (first pair) (worker-publication-target (second pair))))
      (when staged
        (let ((target (worker-publication-target \"integrazione-metadata.lisp\")))
          (worker-copy-exclusive staged target)
          (unless (equalp metadata (arcdocdb.evidence:read-evidence target
                                                                 :max-expanded-bytes 1048576))
            (error \"Metadata integration diversi dopo copia.\"))
          (delete-file staged))))
    (worker-refresh-catalog base :historical-bases historical-bases :directory directory)
    (format t \"Master integrazione ~A conservato in ~A; payload originale preservato, catalogo writer-worker base ~A.~%\"
            record directory base)
    t))

(defparameter *worker-review-publication-directory*
  #p\"spikes/results/2026-10-09-writer-worker-review/\")
(defparameter *worker-review-process-record* \"4000547689-command-21967-0\")

(defun worker-run-review-process-evidence
    (&key (record *worker-review-process-record*)
          (directory *worker-review-publication-directory*)
          (base \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\")
          (historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\")))
  \"Conserva il processo audit oversize in un terzo canonico, senza rinominare gzip.
Il descriptor originale è distinto dal full auditdata nel canonico principale.\"
  (unless (worker-leaf-p record) (error \"Processo review non leaf: ~S\" record))
  (let* ((*worker-publication-directory* directory)
         (pairs (list (list (format nil \"spikes/out/~A/report.lisp\" record)
                            \"revisione-risultati-processo.lisp\")
                      (list (format nil \"spikes/out/~A/conservazione.lisp\" record)
                            \"revisione-risultati-processo-conservazione.lisp\"))))
    (worker-preflight-publication pairs nil)
    (ensure-directories-exist (worker-publication-target \"catalogo.lisp\"))
    (dolist (pair pairs)
      (worker-copy-evidence (first pair) (worker-publication-target (second pair))))
    (worker-refresh-catalog base :historical-bases historical-bases :directory directory)
    (format t \"Processo review ~A conservato in ~A; report.lisp.gz originale e catalogo flat verificati.~%\"
            record directory)
    t))
")
  (:PATH #A((39) BASE-CHAR . "spikes/out/worker-publication-plan.lisp") :BYTES 1168 :SHA256
   "63549fb3561848294e6c3a914cd53501dd1b92845b76e6ab6d1b70f69fe21bce" :GIT-BLOB
   "d77cf133a255c7b1bb201dfa5701c51d15f3fd21" :TEXT
   ";;;; Controllo di caricamento/piano senza alcuna scrittura canonica.
;;;; Chiamato esclusivamente tramite record-command.
(load \"spikes/out/worker-publish.lisp\")
(defun worker-run-publication-planning ()
  (let ((plans (append
                (worker-plan-source-bundles (worker-mutation-log-paths)
                                            \"mutazioni-log\" :raw-mutation-logs)
                (worker-plan-source-bundles
                 '(\"spikes/out/worker-coverage/coverage-state.lisp\")
                 \"copertura-native\" :raw-coverage-native :version :eleven-execution-files)
                (worker-plan-source-bundles (worker-coverage-html-paths)
                                            \"copertura-html\" :raw-coverage-html
                                            :version :eleven-execution-files))))
    (worker-validate-source-plans plans)
    (dolist (plan plans)
      (format t \"~A ~D bytes ~D sources~%\" (getf plan :leaf) (getf plan :bytes)
              (length (getf (getf plan :data) :sources))))
    (format t \"Read-only planning completed; publication directory exists: ~S~%\"
            (probe-file *worker-publication-directory*))
    t))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/worker-tool-self-test.lisp") :BYTES 1615 :SHA256
   "c94dce7f9817be01d19a95be267ff890b2b170c3a4a00a5de8e1bb04af53a200" :GIT-BLOB
   "f645a1948219f1401d1c524cd2ddcfbd8a803f4d" :TEXT
   ";;;; C4: compile the entire selected tool; execute its FASL self-test, isolated cache.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((mode (first (uiop:command-line-arguments)))
       (source (cond ((equal mode \"bench\") \"tools/writer-worker-bench.lisp\")
                     ((equal mode \"mutation\") \"tools/writer-worker-mutation.lisp\")
                     (t (error \"Mode must be bench or mutation.\"))))
       (cache (merge-pathnames (format nil \"spikes/out/worker-~A-asdf-cache/\" mode)
                               (truename \"./\")))
       (fasl (merge-pathnames (format nil \"spikes/out/worker-~A-fasl/tool.fasl\" mode)
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
  (:PATH #A((36) BASE-CHAR . "spikes/out/worker-tool-campaign.lisp") :BYTES 1179 :SHA256
   "db62166ae1203d8bb8569e6852088ed33e4c8e8f403adb8a047efa785477ff50" :GIT-BLOB
   "5ac7b30ca240c38cb8646ce0d659fbb706e52891" :TEXT
   ";;;; C4: execute already strictly compiled selected tool with a private campaign cache.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((args (uiop:command-line-arguments))
       (mode (first args))
       (cache (merge-pathnames (format nil \"spikes/out/worker-~A-campaign-cache/\" mode)
                               (truename \"./\")))
       (fasl (merge-pathnames (format nil \"spikes/out/worker-~A-fasl/tool.fasl\" mode)
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
  (:PATH #A((38) BASE-CHAR . "spikes/out/worker-export-coverage.lisp") :BYTES 3056 :SHA256
   "ec126a84fc9a00bd131e7c85c0b9ccf21287147d5385e5b4bcb6486ff36c35a5" :GIT-BLOB
   "1088034e95eb2a21bbab7f099b88082feeceae3e" :TEXT "(require :asdf)
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
       (path \"spikes/out/worker-coverage/coverage-state.lisp\")
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
                     :html-index (uiop:read-file-string \"spikes/out/worker-coverage/cover-index.html\")
                     :counts counts :limits '(:raw-denominator :no-exclusions :not-mcdc))))
  (unless (= 11 (length records)) (error \"COD-60: scope execution incompleto.\"))
  (with-open-file (output \"spikes/out/worker-coverage-export.lisp\" :direction :output :if-exists :error)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (dolist (entry counts)
    (let ((r (getf entry :counts)))
      (format t \"~A: ~D/~D espressioni, ~D/~D esiti di ramo.~%\"
              (getf entry :file) (getf r :expressions) (getf r :expression-total)
              (getf r :branches) (getf r :branch-total)))))
")
  (:PATH #A((35) BASE-CHAR . "spikes/out/worker-root-summary.lisp") :BYTES 1574 :SHA256
   "f4942692d580c11c6fe2a302fbd0fc00d0bdebc817ad7a8b3c1f002404bdf76a" :GIT-BLOB
   "150780af583f1dfe8f5d7568db061d370e5205cb" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun summary-command (id)
  (let* ((data (arcdocdb.evidence:read-evidence (format nil \"spikes/out/~A/report.lisp\" id)))
         (text (getf data :stdout)))
    (format t \"PROCESS ~A: ~S/~S exit~S~%\" id (getf data :status) (getf data :source-consistency) (getf data :exit-code))
    (dolist (line (uiop:split-string (or text \"\") :separator '(#\\Newline)))
      (when (or (search \"test superati\" line) (search \"tests-complete\" line)
                (search \"Smoke\" line) (search \"violazioni\" line) (search \"Linter\" line)
                (search \"tracciabilità\" line) (search \"Link\" line) (search \"conservati\" line))
        (write-line line)))
    (unless (and (eq (getf data :status) :ok) (eq (getf data :source-consistency) :stable)
                 (zerop (getf data :exit-code))) (error \"Gate incompleto: ~A\" id))))
(dolist (id (uiop:command-line-arguments)) (summary-command id))
(let* ((data (arcdocdb.evidence:read-evidence \"spikes/out/worker-coverage-export.lisp\"))
       (total '(0 0 0 0)) (new '(0 0 0 0)))
  (dolist (entry (getf data :counts))
    (let* ((file (getf entry :file)) (c (getf entry :counts))
           (values (list (getf c :expressions) (getf c :expression-total)
                         (getf c :branches) (getf c :branch-total))))
      (setf total (mapcar #'+ total values))
      (when (search \"worker-\" file) (setf new (mapcar #'+ new values)))
      (format t \"COVERAGE ~A ~S missing~D~%\" file values (length (getf c :missing)))))
  (format t \"COVERAGE TOTAL ~S NEW ~S~%\" total new))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/worker-strict-product.lisp") :BYTES 202 :SHA256
   "019436bbf5dbe8359daed1301da3db3f2c376016bcbc0ba5026f49de4d7b008b" :GIT-BLOB
   "e80cff4688b044d73523a055e4524649a44bbec6" :TEXT "(require :asdf)
(push (truename \"./\") asdf:*central-registry*)
(handler-bind ((warning (lambda (condition) (error condition))))
 (asdf:load-system \"arcdocdb\" :force t))
(format t \"STRICT PRODUCT OK~%\")
")
  (:PATH #A((36) BASE-CHAR . "spikes/out/worker-author-review.lisp") :BYTES 2634 :SHA256
   "587bd80e17cff7985f5c24cae792fdde73b9dcf60c8e2fc7ce04fe82736f1edc" :GIT-BLOB
   "77595866ada1bf33ecd6b6120d9b62c8009acec1" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((args (uiop:command-line-arguments)) (check-id (first args))
       (check (arcdocdb.evidence:read-evidence (format nil \"spikes/out/~A/report.lisp\" check-id)))
       (review \"docs/implementazione/writer-worker-revisione.md\")
       (text (uiop:read-file-string review :external-format :utf-8))
       (points (remove-if-not (lambda (line)
                  (and (> (length line) 2) (char= #\\| (char line 0))
                       (digit-char-p (char line 2))))
                (uiop:split-string text :separator '(#\\Newline))))
       (files '(\"src/execution/worker-types.lisp\" \"src/execution/worker-boundary.lisp\"
                \"src/execution/worker-claim.lisp\" \"src/execution/worker-run.lisp\")))
  (unless (and (= 12 (length points)) (eq (getf check :status) :ok)
               (eq (getf check :source-consistency) :stable) (zerop (getf check :exit-code)))
    (error \"C1: checklist o gate finale incompleto.\"))
  (let ((data (list :schema-version 1 :kind :c1-author-review :component :writer-worker
              :sources (mapcar (lambda (file)
                        (list :path file :sha256 (arcdocdb.evidence:file-sha256 file)
                              :git-blob (string-trim '(#\\Space #\\Newline)
                                 (uiop:run-program (list \"git\" \"hash-object\" \"--\" file) :output :string))
                              :text (uiop:read-file-string file :external-format :utf-8))) files)
              :checklist points :review-text text :integration-verification-record check-id
              :execution-verification-record \"4000547204-command-93189-0\"
              :execution-tests 89 :new-tests 23
              :mutation-record \"4000547268-command-97067-0\" :detected 12
              :allocation-record \"4000547268-command-97066-0\" :samples 20
              :coverage-probe \"4000547296-command-98426-0\"
              :coverage '(1427 1660 199 230) :worker-coverage '(498 600 65 76)
              :historical-base \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
              :integration-base \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
              :limits '(:local-component :no-mcdc :no-approved-exclusions :not-full-pool
                        :faulted-local-only :ack-caller-attestation))))
    (with-open-file (output \"spikes/out/worker-author-review-data.lisp\"
                    :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write data :stream output :pretty t) (terpri output)))
    (format t \"C1 autore:12 punti;4sorgenti;record integrazione~A;raw worker preservati.~%\" check-id)))
")
  (:PATH #A((38) BASE-CHAR . "spikes/out/worker-review-coverage.lisp") :BYTES 4399 :SHA256
   "d98d49c1319a82ff8aa12d40157d9ccf2867607dac85caa536bdc760889b3056" :GIT-BLOB
   "0471552a359c3ea81270c72cdbbe140512c29e5a" :TEXT
   ";;;; Probe indipendente sui dati congelati, non campagna di prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil *print-pretty* nil)

(defun review-native-row (entry)
  (let ((eh 0) (et 0) (bh 0) (bt 0) (missing nil))
    (assert (= (length (cadr entry)) (length (cddr entry))))
    (loop for path across (cadr entry) for bit across (cddr entry)
          do (assert (member bit '(0 1)))
             (if (member (car path) '(:then :else))
                 (progn (incf bt) (incf bh bit))
                 (progn (incf et) (incf eh bit)))
             (when (= bit 0)
               (push (list :kind (if (member (car path) '(:then :else)) :branch :expression)
                           :path path) missing)))
    (list :file (file-namestring (car entry))
          :expressions-hit eh :expressions-total et :branches-hit bh :branches-total bt
          :missing (nreverse missing))))

(let ((row (review-native-row (list* \"fixture\" #((0) (1) (:then 2) (:else 2)) #*1010))))
  (assert (= 1 (getf row :expressions-hit) (getf row :branches-hit)))
  (assert (= 2 (getf row :expressions-total) (getf row :branches-total)))
  (assert (equal (getf row :missing)
                 '((:kind :expression :path (1)) (:kind :branch :path (:else 2))))))
(assert (handler-case (progn (review-native-row (list* \"bad\" #((0)) #*00)) nil)
          (error () t)))

(let* ((native-path \"spikes/out/worker-coverage/coverage-state.lisp\")
       (export-path \"spikes/out/worker-coverage-export.lisp\")
       (raw (with-open-file (input native-path :external-format :utf-8) (read input)))
       (rows (sort (loop for entry in raw
                         when (search \"/src/execution/\" (car entry))
                           collect (review-native-row entry))
                   #'string< :key (lambda (row) (getf row :file))))
       (html (read-from-string
               (uiop:run-program '(\"python3\" \"spikes/out/worker-review-html.py\"
                                   \"spikes/out/worker-coverage/cover-index.html\") :output :string)))
       (counts (mapcar (lambda (row)
                         (list (getf row :file) (getf row :expressions-hit) (getf row :expressions-total)
                               (getf row :branches-hit) (getf row :branches-total))) rows))
       (export (arcdocdb.evidence:read-evidence export-path))
       (export-rows (sort (copy-list (getf export :counts)) #'string<
                          :key (lambda (row) (getf row :file))))
       (total (loop for column from 1 to 4 collect (loop for row in counts sum (nth column row))))
       (report-path \"spikes/out/worker-review-coverage-data.lisp\"))
  (assert (equal (mapcar #'first counts)
                 '(\"handoff.lisp\" \"package.lisp\" \"queue.lisp\" \"ready-recycle.lisp\" \"ready-types.lisp\"
                   \"ready.lisp\" \"worker-boundary.lisp\" \"worker-claim.lisp\" \"worker-run.lisp\"
                   \"worker-types.lisp\" \"writer.lisp\")))
  (assert (equal counts html))
  (assert (string= (getf (getf export :native) :text)
                   (uiop:read-file-string native-path :external-format :utf-8)))
  (assert (= (length rows) (length export-rows)))
  (loop for row in rows for exported in export-rows
        for c = (getf exported :counts)
        do (assert (string= (getf row :file) (getf exported :file)))
           (assert (= (getf row :expressions-hit) (getf c :expressions)))
           (assert (= (getf row :expressions-total) (getf c :expression-total)))
           (assert (= (getf row :branches-hit) (getf c :branches)))
           (assert (= (getf row :branches-total) (getf c :branch-total)))
           (assert (equal (getf row :missing) (getf c :missing))))
  (let ((report (list :schema-version 1 :kind :independent-coverage-audit
                      :status :equal :native-path native-path :export-path export-path
                      :native-sha256 (arcdocdb.evidence:file-sha256 native-path)
                      :export-sha256 (arcdocdb.evidence:file-sha256 export-path)
                      :files rows :total total :self-test :passed
                      :exclusions nil :mcdc-inferred nil)))
    (with-open-file (output report-path :direction :output :if-exists :error
                                       :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&~S~%\" report)))
")
  (:PATH #A((35) BASE-CHAR . "spikes/out/worker-review-forms.lisp") :BYTES 2547 :SHA256
   "88e90e72df97c78155bdbc84be8cab0960ef7dfac27eab5ead949b59fa9add35" :GIT-BLOB
   "3e53e954a645a178e46891444729cbb6b7a9d5bf" :TEXT
   ";;;; Mappa indipendente dei percorsi sorgente; nessuna valutazione del prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(unless (find-package \"ARCDOCDB.CONDITIONS\")
  (let ((package (make-package \"ARCDOCDB.CONDITIONS\" :use nil)))
    (export (intern \"ERROR-REASON\" package) package)))
(defun review-source-forms (path)
  (with-open-file (input path :external-format :utf-8)
    (loop for form = (read input nil :eof) until (eq form :eof) collect form)))
(defun review-source-at (forms path)
  (let ((value forms))
    (dolist (index (reverse (if (member (first path) '(:then :else)) (rest path) path)))
      (assert (typep index '(integer 0 *)))
      (assert (listp value))
      (assert (< index (length value)))
      (setf value (nth index value)))
    value))
(assert (equal (review-source-at '((a b (c d))) '(1 2 0)) 'd))
(assert (equal (review-source-at '((a b (c d))) '(:else 1 2 0)) 'd))
(let* ((raw (arcdocdb.evidence:read-evidence \"spikes/out/worker-review-coverage-data.lisp\"))
       (rows nil))
  (dolist (name '(\"worker-types.lisp\" \"worker-boundary.lisp\" \"worker-claim.lisp\" \"worker-run.lisp\"))
    (let* ((path (concatenate 'string \"src/execution/\" name))
           (forms (review-source-forms path))
           (row (find name (getf raw :files) :key (lambda (entry) (getf entry :file)) :test #'string=)))
      (assert row)
      (push (list :file name :sha256 (arcdocdb.evidence:file-sha256 path)
                  :top-level (loop for form in forms for index from 0
                                   collect (list :index index :operator (first form)
                                                 :name (when (member (first form) '(defun defmacro defstruct))
                                                         (second form))))
                  :missing (loop for missing in (getf row :missing)
                                 collect (append missing
                                                 (list :source-form
                                                       (review-source-at forms (getf missing :path)))))) rows)))
  (let ((report (list :schema-version 1 :kind :independent-source-path-mapping
                      :self-test :passed :files (nreverse rows) :read-eval nil)))
    (with-open-file (output \"spikes/out/worker-review-forms-data.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&~S~%\" report)))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/worker-review-results.lisp") :BYTES 8190 :SHA256
   "35a9db6be672af4e35843fd9c6f8245b42f2a65113dfc5319c050ba41034dd04" :GIT-BLOB
   "af0d90dcca5179c09503b94f516c260b3204dea3" :TEXT
   ";;;; Rilettura indipendente dei report congelati; nessun test del prodotto rieseguito.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil *print-pretty* nil)
(defun read-data (path) (arcdocdb.evidence:read-evidence path))
(defun text-data (path) (uiop:read-file-string path :external-format :utf-8))
(defun event-lines (prefix text)
  (remove-if-not (lambda (line) (uiop:string-prefix-p prefix line))
                 (uiop:split-string text :separator '(#\\Newline))))
(defun pairs (raw keys) (loop for key in keys append (list key (getf raw key))))
(defvar *audit* nil)
(defun audit (value) (push value *audit*) (format t \"~&~S~%\" value))
(dolist (id '(\"4000547204-command-93188-0\" \"4000547249-command-95826-0\"
              \"4000547221-command-94073-0\" \"4000547221-command-94074-0\"
              \"4000547268-command-97066-0\" \"4000547268-command-97067-0\"
              \"4000547204-command-93189-0\" \"4000547296-command-98426-0\"
              \"4000547596-command-16195-0\"))
  (let* ((path (format nil \"spikes/out/~A/report.lisp\" id)) (raw (read-data path))
         (warnings (remove-if-not
                     (lambda (line)
                       (some (lambda (prefix) (uiop:string-prefix-p prefix line))
                             '(\"WARNING:\" \"; caught WARNING:\" \"; caught STYLE-WARNING:\")))
                     (uiop:split-string (getf raw :stderr) :separator '(#\\Newline)))))
    (assert (eq (getf raw :status) :ok))
    (assert (eq (getf raw :source-consistency) :stable))
    (assert (eql (getf raw :exit-code) 0))
    (assert (null warnings))
    (audit (append (list :process id :record-sha256 (arcdocdb.evidence:file-sha256 path))
                   (pairs raw '(:status :source-consistency :exit-code :wall-seconds))
                   (list :warning-lines warnings
                         :stdout-lines (remove-if-not
                                         (lambda (line)
                                           (some (lambda (needle) (search needle line))
                                                 '(\"test superati\" \"file, \" \"REQ\" \"link\" \"nessun avviso\"
                                                   \"STRICT-SELF-TEST-PASS\")))
                                         (uiop:split-string (getf raw :stdout)
                                                            :separator '(#\\Newline))))))))
(let ((raw (read-data \"spikes/out/worker-mutations/report.lisp\")))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (getf raw :planned-mutants) 12)) (assert (= (getf raw :detected) 12))
  (assert (every #'zerop (mapcar (lambda (key) (getf raw key))
                               '(:survived :compilation-failures :before-tests :worker-errors))))
  (assert (eq (getf raw :baseline) :passed))
  (assert (= (getf raw :baseline-exit-code) 0)) (assert (null (getf raw :baseline-signal)))
  (assert (= (length (getf raw :mutants)) 12))
  (audit (append '(:mutations) (pairs raw '(:status :source-consistency :planned-mutants
                           :baseline :baseline-exit-code :baseline-signal :detected :survived
                           :compilation-failures :before-tests :worker-errors))))
  (dolist (entry (cons (list :name \"baseline\" :log (getf raw :baseline-log)
                           :exit-code (getf raw :baseline-exit-code) :signal (getf raw :baseline-signal))
                       (getf raw :mutants)))
    (let* ((text (text-data (getf entry :log))) (starts (event-lines \"execution-test-start \" text))
           (oks (event-lines \"ok    TEST-\" text))
           (complete (event-lines \"execution-tests-complete \" text))
           (baseline (string= (getf entry :name) \"baseline\")))
      (if baseline
          (progn (assert (= (length starts) 89)) (assert (= (length oks) 89))
                 (assert (equal complete '(\"execution-tests-complete 89\"))))
          (progn (assert (eq (getf entry :result) :detected))
                 (assert (= (getf entry :exit-code) 1)) (assert (null (getf entry :signal)))
                 (assert (null complete))
                 (assert (some (lambda (line) (search \"-WORKER-\" line)) starts))))
      (audit (list :mutation-log (getf entry :name) :path (getf entry :log)
                   :sha256 (arcdocdb.evidence:file-sha256 (getf entry :log))
                   :starts (length starts) :oks (length oks) :last-start (car (last starts))
                   :complete complete :exit-code (getf entry :exit-code) :signal (getf entry :signal))))))
(let* ((raw (read-data \"spikes/out/worker-allocations/report.lisp\"))
       (self (getf raw :self-test)) (campaigns (getf raw :campaigns)))
  (assert (eq (getf raw :status) :ok)) (assert (eq (getf raw :source-consistency) :stable))
  (assert (= (length campaigns) 4))
  (assert (= (getf (getf self :positive-control) :heap-bytes) 16777472))
  (assert (eq (getf self :wrong-sink) :rejected))
  (assert (eq (getf self :zero-clock) :below-resolution))
  (assert (eq (getf self :partial-report) :preserved))
  (assert (eq (getf self :existing-destination) :preserved))
  (audit (list :benchmark-controls :status (getf self :status)
               :positive-heap (getf (getf self :positive-control) :heap-bytes)
               :wrong-sink (getf self :wrong-sink) :zero-clock (getf self :zero-clock)
               :partial-report (getf self :partial-report)
               :existing-destination (getf self :existing-destination)))
  (dolist (campaign campaigns)
    (let* ((k (getf campaign :shards)) (c (getf campaign :capacity-per-shard)) (m (* k (1+ c)))
           ;; Conteggio ricavato dal ciclo: full 189+115C, room 227, pubblicazioni triangolari.
           (token (+ (* k (+ 189 227 (* 115 c) (/ (* 3 c (1+ c)) 2)))
                     (* 7 (+ c 3) (/ (* k (1- k)) 2))
                     (* 5 (/ (* m (1+ m)) 2)) 29 (* 7 (mod 1 k))))
           (calls (+ 1 (* k (+ 8 5 14 (* 2 c) (* 5 c)))))
           (batches (* k (+ 1 (1+ c) 2)))
           (expected-sink (+ (* 4096 token) (/ (* 4096 4095) 2)))
           (samples (getf campaign :samples)))
      (assert (= token (getf campaign :expected-token)))
      (assert (= calls (getf campaign :calls-per-cycle)))
      (assert (= batches (getf campaign :processed-batches-per-cycle)))
      (assert (= (length samples) 5))
      (dolist (sample samples)
        (assert (eq (getf sample :status) :ok)) (assert (zerop (getf sample :heap-bytes)))
        (assert (= (getf sample :completed-iterations) 4096))
        (assert (= expected-sink (getf sample :sink) (getf sample :expected-sink)))
        (assert (= token (getf sample :expected-return-token))))
      (audit (list :benchmark :shards k :capacity c :independent-token token
                   :independent-calls-per-cycle calls :independent-batches-per-cycle batches
                   :independent-sink expected-sink :sample-count 5 :samples samples)))))
(let* ((path \"spikes/out/4000547222-worker-signal-self-test-94121/report.lisp\") (raw (read-data path))
       (mutants (getf raw :mutants)))
  (assert (= (getf raw :worker-errors) 1)) (assert (zerop (getf raw :detected)))
  (assert (= (length mutants) 1))
  (assert (= (getf (first mutants) :signal) 9))
  (assert (= (getf (first mutants) :exit-code) 137))
  (audit (append (list :signal-fixture :record-sha256 (arcdocdb.evidence:file-sha256 path))
                 (pairs raw '(:status :source-consistency :detected :worker-errors :mutants)))))
(let* ((path \"spikes/out/4000547284-check-97964-0/report.lisp\") (raw (read-data path)))
  (assert (eq (getf raw :status) :complete)) (assert (= (length (getf raw :runs)) 10))
  (assert (= (length (getf raw :run-artifacts)) 10))
  (audit (list :spikes :record-sha256 (arcdocdb.evidence:file-sha256 path)
               :status (getf raw :status) :runs (getf raw :runs) :run-artifacts (getf raw :run-artifacts))))
(with-open-file (output \"spikes/out/worker-review-results-data.lisp\"
                        :direction :output :if-exists :error :external-format :utf-8)
  (let ((*print-readably* t))
    (write (list :schema-version 1 :kind :independent-results-audit :entries (nreverse *audit*))
           :stream output :pretty t) (terpri output)))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/worker-review-summary.lisp") :BYTES 2078 :SHA256
   "18fc2402ddfbdd2100db04bbc9426016d4b511c31106dc32fd8b94577040f197" :GIT-BLOB
   "aa1f505f23509d9dceffeccc77797a2ac74748cc" :TEXT
   ";;;; Proiezione compatta dell'audit integrale preservato, senza nuove campagne.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((original \"spikes/out/worker-review-results-data.lisp\")
       (raw (arcdocdb.evidence:read-evidence original))
       (rows (loop for entry in (getf raw :entries)
                   collect
                   (cond
                     ((eq (first entry) :process)
                      (loop for key in '(:process :record-sha256 :status :source-consistency
                                         :exit-code :wall-seconds :warning-lines)
                            append (list key (getf entry key))))
                     ((eq (first entry) :spikes)
                      (let ((runs (getf (rest entry) :runs)))
                        (assert (= (length runs) 10))
                        (assert (every (lambda (run) (= (getf run :exit-code) 0)) runs))
                        (assert (every (lambda (run) (eq (getf run :source-consistency) :stable)) runs))
                        (list :spikes :complete :run-count (length runs)
                              :artifact-count (length (getf (rest entry) :run-artifacts))
                              :run-statuses (loop for run in runs
                                                  collect (loop for key in '(:id :status :exit-code
                                                                           :source-consistency)
                                                                append (list key (getf run key)))))))
                     (t entry))))
       (report (list :schema-version 1 :kind :independent-results-summary
                     :original original :original-sha256 (arcdocdb.evidence:file-sha256 original)
                     :entries rows)))
  (with-open-file (output \"spikes/out/worker-review-summary-data.lisp\"
                          :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (format t \"~&~S~%\" report))
")
  (:PATH #A((44) BASE-CHAR . "spikes/out/worker-review-summary-failed.lisp") :BYTES 1950 :SHA256
   "0c9d677922949c10dd45fd9d8f169b7534fe252e336da372681381a99f98e742" :GIT-BLOB
   "d81ec73877bad00cd21879c69bdb91ecf0669356" :TEXT
   ";;;; Proiezione compatta dell'audit integrale preservato, senza nuove campagne.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((original \"spikes/out/worker-review-results-data.lisp\")
       (raw (arcdocdb.evidence:read-evidence original))
       (rows (loop for entry in (getf raw :entries)
                   collect
                   (cond
                     ((getf entry :process)
                      (loop for key in '(:process :record-sha256 :status :source-consistency
                                         :exit-code :wall-seconds :warning-lines)
                            append (list key (getf entry key))))
                     ((getf entry :spikes)
                      (let ((runs (getf entry :runs)))
                        (assert (= (length runs) 10))
                        (assert (every (lambda (run) (= (getf run :exit-code) 0)) runs))
                        (list :spikes :complete :run-count (length runs)
                              :artifact-count (length (getf entry :run-artifacts))
                              :run-statuses (loop for run in runs
                                                  collect (loop for key in '(:spike :status :exit-code
                                                                           :source-consistency)
                                                                append (list key (getf run key)))))))
                     (t entry))))
       (report (list :schema-version 1 :kind :independent-results-summary
                     :original original :original-sha256 (arcdocdb.evidence:file-sha256 original)
                     :entries rows)))
  (with-open-file (output \"spikes/out/worker-review-summary-data.lisp\"
                          :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
  (format t \"~&~S~%\" report))
")
  (:PATH #A((32) BASE-CHAR . "spikes/out/worker-review-html.py") :BYTES 1070 :SHA256
   "14cae39560b4923dc734fe445714b16b624e228d1b0bbb47d6efb43fc392848d" :GIT-BLOB
   "e1f10c0871d94f3961570203ab71353eb2dca4d5" :TEXT "from html.parser import HTMLParser
from pathlib import Path
import sys


class Summary(HTMLParser):
    def __init__(self):
        super().__init__()
        self.cells = []
        self.cell = None
        self.rows = []

    def handle_starttag(self, tag, attrs):
        if tag == \"tr\":
            self.cells = []
        if tag == \"td\":
            self.cell = []

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if tag == \"td\" and self.cell is not None:
            self.cells.append(\"\".join(self.cell).strip())
            self.cell = None
        if tag == \"tr\" and len(self.cells) == 7 and self.cells[0].endswith(\".lisp\"):
            self.rows.append((self.cells[0], *(int(self.cells[i]) for i in (1, 2, 4, 5))))


parser = Summary()
parser.feed(Path(sys.argv[1]).read_text(encoding=\"utf-8\"))
assert len(parser.rows) == 11
assert len({row[0] for row in parser.rows}) == 11
print(\"(\" + \" \".join('(\\\"%s\\\" %d %d %d %d)' % row for row in sorted(parser.rows)) + \")\")
")
  (:PATH #A((51) BASE-CHAR . "spikes/out/worker-c1-integration-addendum-read.lisp") :BYTES 4444
   :SHA256 "f2281d53ab3f3a00e012334f7e59107a28b8a9507f689673d7016a49abe6712f" :GIT-BLOB
   "392a53b27be6a6ad47578e971c0e325c560100e1" :TEXT
   ";;;; Addendum indipendente: legge evidenze esistenti, nessun gate rieseguito.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let ((records nil) (code nil))
  (dolist (id '(\"4000548017-command-37007-0\" \"4000548048-command-40192-0\"))
    (let* ((path (format nil \"spikes/out/~A/report.lisp\" id))
           (raw (arcdocdb.evidence:read-evidence path))
           (lines (remove-if-not
                    (lambda (line)
                      (and (< (length line) 400)
                           (not (uiop:string-prefix-p \"ok    \" line))
                           (some (lambda (word) (search word line))
                                 '(\"test superati\" \"file, \" \" REQ,\" \"link\" \"nessun avviso\"))))
                    (uiop:split-string (getf raw :stdout) :separator '(#\\Newline)))))
      (assert (eq (getf raw :status) :ok))
      (assert (eq (getf raw :source-consistency) :stable))
      (assert (= (getf raw :exit-code) 0))
      (assert (null (remove-if-not
                     (lambda (line)
                       (some (lambda (prefix) (uiop:string-prefix-p prefix line))
                             '(\"WARNING:\" \"; caught WARNING:\" \"; caught STYLE-WARNING:\")))
                     (uiop:split-string (getf raw :stderr) :separator '(#\\Newline)))))
      (push (list :process id :path path :sha256 (arcdocdb.evidence:file-sha256 path)
                  :status (getf raw :status) :source-consistency (getf raw :source-consistency)
                  :exit-code (getf raw :exit-code) :wall-seconds (getf raw :wall-seconds)
                  :stdout-summary lines) records)))
  (dolist (expected '((\"worker-types.lisp\" \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\")
                      (\"worker-boundary.lisp\" \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\")
                      (\"worker-claim.lisp\" \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\")
                      (\"worker-run.lisp\" \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\")))
    (let* ((path (concatenate 'string \"src/execution/\" (first expected)))
           (hash (arcdocdb.evidence:file-sha256 path)))
      (assert (string= hash (second expected)))
      (push (list :path path :sha256 hash :same-as-frozen-review t) code)))
  (let* ((scope (uiop:run-program
                 '(\"python3\" \"-c\" \"import json; from pathlib import Path; s=json.loads(Path('spikes/out/worker-integration-scope.json').read_text()); assert s['status']=='passed'; assert s['head']==s['upstream']=='e2f7a75f3c7a45dffd91343b91d3a889fc3ee056'; a=s['frozen_execution_test_tool_stability']; assert all(x['v1_sha256']==x['integration_sha256'] for x in a); print(len(a))\")
                 :output :string))
         (report (list :schema-version 1 :kind :independent-c1-integration-addendum
                       :scope :record-reading-and-unchanged-worker-bytes
                       :base \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
                       :previous-frozen-base \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                       :prior-final-report-preserved t
                       :records (nreverse records) :code (nreverse code)
                       :scope-data \"spikes/out/worker-integration-scope.json\"
                       :scope-data-sha256 (arcdocdb.evidence:file-sha256 \"spikes/out/worker-integration-scope.json\")
                       :unchanged-execution-test-tool-files (parse-integer (string-trim '(#\\Newline #\\Space) scope))
                       :new-integration-check-tests 400 :smoke t
                       :execution-tests 89 :recovery-tests 95
                       :lint-files 66 :lint-violations 0 :trace '(114 65 13 52)
                       :documents 224 :links 2017 :broken-links 0
                       :spike-master \"4000548134-check-44515-0\"
                       :limits '(:no-worker-campaign-rerun :scoped-campaigns-retain-cf60913
                                 :no-document-snapshot-relabeling :no-new-coverage-or-mcdc-qualification
                                 :no-whole-pool-or-series-fault-controller-qualification))))
    (with-open-file (output \"spikes/out/worker-c1-integration-addendum.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&~S~%\" report)))
")
  (:PATH #A((12) BASE-CHAR . "arcdocdb.asd") :BYTES 5891 :SHA256
   "bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153" :GIT-BLOB
   "422845acd196e9fd59298d2b633485a80ed30795" :TEXT
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
                             (:file \"cbor-package\") (:file \"cbor-header\")
                             (:file \"cbor-space\") (:file \"cbor-scan-input\")
                             (:file \"cbor-scan-stack\") (:file \"cbor-scan-items\")
                             (:file \"cbor-scan\")))
               (:module \"csn\" :serial t
                :components ((:file \"package\") (:file \"registry\")))
               (:module \"execution\" :serial t
                :components ((:file \"package\") (:file \"queue\") (:file \"writer\")
                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")
                             (:file \"ready-recycle\")
                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))
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
                             (:file \"group\") (:file \"executor\") (:file \"csn\")))
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
                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")
                             (:file \"cbor-structure-support\") (:file \"cbor-structure\")
                             (:file \"cbor-structure-threads\")))
               (:module \"csn\" :serial t
                :components ((:file \"support\") (:file \"registry\") (:file \"threads\")))
               (:module \"execution\" :serial t
                :components ((:file \"support\") (:file \"queue\") (:file \"threads\")
                             (:file \"handoff\") (:file \"ready\") (:file \"ready-recycle\") (:file \"worker\")))
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
                             (:file \"native\") (:file \"csn\") (:file \"csn-threads\"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
")
  (:PATH #A((26) BASE-CHAR . "src/execution/package.lisp") :BYTES 1157 :SHA256
   "bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643" :GIT-BLOB
   "cdc776ff97c2b500b3b8a802a3b1e0e69fc19cee" :TEXT
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
           #:pubblica-writer-pronto #:preleva-writer-pronto #:ricircola-writer-pronto
           #:contesto-worker-writer #:crea-contesto-worker-writer
           #:stato-worker-writer #:writer-worker-writer #:errore-worker-writer #:prendi-writer-worker
           #:inizia-tratto-worker #:preleva-lavori-worker #:conferma-lavori-worker
           #:termina-tratto-worker #:ricircola-worker
           #:adotta-writer-worker #:cede-writer-worker))
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
  (:PATH #A((30) BASE-CHAR . "src/execution/ready-types.lisp") :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f" :GIT-BLOB
   "5b3c26f78d5c4aa53ca200abdd3e0f753f926b54" :TEXT
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
  (:PATH #A((32) BASE-CHAR . "src/execution/ready-recycle.lisp") :BYTES 3387 :SHA256
   "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b" :GIT-BLOB
   "58981c7e41ce2694dbfcaed99010a3a53e3c1dea" :TEXT
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
  (:PATH #A((31) BASE-CHAR . "src/execution/worker-types.lisp") :BYTES 8461 :SHA256
   "62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317" :GIT-BLOB
   "6d36e1f64d79f24c95209fd70551953e40c62335" :TEXT
   ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (contesto-worker-writer
             (:constructor %make-contesto-worker-writer (ready owner cursor)) (:copier nil))
  \"Pre: lista valida e proprietario unico non rientrante. Post: IDLE senza obblighi.
Nessun thread creato; batch generation locale monotona e mai azzerata.\"
  (ready (error 'invariant-violation :reason :worker-state) :type lista-writer-pronti :read-only t)
  (owner (error 'invariant-violation :reason :worker-state) :type sb-thread:thread :read-only t)
  (cursor 0 :type index) (home 0 :type index)
  (writer nil :type (or null writer-programmabile))
  (lease 0 :type index) (pending 0 :type index) (batch-generation 0 :type index)
  (fault nil :type (or null condition))
  (state :idle :type (member :idle :claimed :running :batch :finishing :reschedule :faulted)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-owner-worker))
(defun %check-owner-worker (context)
  \"Pre: contesto locale. Post: thread corrente proprietario; INVALID-ARGUMENT altrimenti.\"
  (unless (eq (contesto-worker-writer-owner context) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :worker-owner))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-libero-worker))
(defun %check-libero-worker (context)
  \"Pre: owner verificato, IDLE. Post: riferimento, lease e debito vuoti; invarianti typed.\"
  (unless (null (contesto-worker-writer-writer context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-obbligo-worker))
(defun %check-obbligo-worker (context)
  \"Pre: owner verificato, CLAIMED/RESCHEDULE. Post: writer senza lease/debito; invarianti typed.\"
  (unless (typep (contesto-worker-writer-writer context) 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-lease-worker))
(defun %check-lease-worker (context)
  \"Pre: owner verificato. Post: writer e lease correnti; invarianti o lease invalida typed.\"
  (let ((writer (contesto-worker-writer-writer context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (%check-lease (writer-programmabile-queue writer) (contesto-worker-writer-lease context)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-attivo-worker))
(defun %check-attivo-worker (context)
  \"Pre: owner verificato, RUNNING/FINISHING. Post: lease corrente senza batch; invarianti typed.\"
  (%check-lease-worker context)
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-batch-worker))
(defun %check-batch-worker (context)
  \"Pre: owner verificato, BATCH. Post: lease corrente e batch positivo; invarianti typed.\"
  (%check-lease-worker context)
  (unless (plusp (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (unless (<= (contesto-worker-writer-pending context)
              (coda-writer-extracted
               (writer-programmabile-queue (contesto-worker-writer-writer context))))
    (error 'invariant-violation :reason :worker-state))
  (unless (plusp (contesto-worker-writer-batch-generation context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-worker))
(defun %check-worker (context)
  \"Pre: accesso esclusivo non rientrante. Post: owner, indici e stato coerenti.
INVALID-ARGUMENT owner; indici privati sono invarianti, lease come verificatori delegati.\"
  (%check-owner-worker context)
  (unless (null (contesto-worker-writer-fault context))
    (error 'invariant-violation :reason :worker-state))
  (let ((size (length (lista-writer-pronti-partitions (contesto-worker-writer-ready context)))))
    (unless (< (contesto-worker-writer-cursor context) size)
      (error 'invariant-violation :reason :worker-state))
    (unless (< (contesto-worker-writer-home context) size)
      (error 'invariant-violation :reason :worker-state)))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-cursor context))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-home context))
  (case (contesto-worker-writer-state context)
    (:idle (%check-libero-worker context))
    ((:claimed :reschedule) (%check-obbligo-worker context))
    ((:running :finishing) (%check-attivo-worker context))
    (:batch (%check-batch-worker context))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer symbol) null) %richiedi-worker))
(defun %richiedi-worker (context state)
  \"Pre: owner esclusivo e fase richiesta. Post: forma e fase verificate.
RESOURCE-EXHAUSTED :WORKER-STATE per operazione fuori fase; verificatori typed.\"
  (%check-worker context)
  (unless (eq (contesto-worker-writer-state context) state)
    (error 'resource-exhausted :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti &key (:start t)) contesto-worker-writer) crea-contesto-worker-writer))
(defun crea-contesto-worker-writer (ready &key (start 0))
  \"Pre: lista valida; creazione sul thread proprietario prima del percorso caldo.
Post: IDLE preallocato con cursore START; INVALID-ARGUMENT indice, invarianti lista.\"
  (%partizione-verificata ready start)
  (let ((context (%make-contesto-worker-writer ready sb-thread:*current-thread* (the index start))))
    (%check-worker context)
    context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :claimed :running :batch :finishing :reschedule :faulted)) stato-worker-writer))
(defun stato-worker-writer (context)
  \"Pre: owner corrente. Post: fase locale, leggibile anche per diagnosi di fault.
INVALID-ARGUMENT owner; nessuna mutazione o verifica del writer sotto guard.\"
  (%check-owner-worker context)
  (contesto-worker-writer-state context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null writer-programmabile)) writer-worker-writer))
(defun writer-worker-writer (context)
  \"Pre: owner corrente. Post: riferimento locale opaco per diagnosi/integrazione.
INVALID-ARGUMENT owner; non trasferisce obblighi né consente di duplicarli.\"
  (%check-owner-worker context)
  (contesto-worker-writer-writer context))


;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null condition)) errore-worker-writer))
(defun errore-worker-writer (context)
  \"Pre: owner corrente. Post: condizione originale del fault locale o NIL.
INVALID-ARGUMENT owner; non resetta il fault né trasferisce lease/obblighi.\"
  (%check-owner-worker context)
  (contesto-worker-writer-fault context))
")
  (:PATH #A((34) BASE-CHAR . "src/execution/worker-boundary.lisp") :BYTES 2309 :SHA256
   "4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a" :GIT-BLOB
   "720f16e96203f00e308727b430b66b28689dc7bb" :TEXT
   ";;;; Confine del worker: fault locale persistente, campi diagnostici conservati.
;;; OWNER: solo thread creatore; il controller della Serie resta da integrare.
;;; SHARED: nessuno stato globale o tra worker; handler solo in questo confine.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer list list error) null) %classifica-guasto-worker))
(defun %classifica-guasto-worker (context resources arguments condition)
  \"Pre: owner verificato e errore nel passo. Post: recuperabile propagato oppure
FAULTED con condizione e campi conservati; non nasconde né risolleva l'errore.
Liste di ragioni letterali bounded; solo resource/invalid attesi sono recuperabili.\"
  (when (typep condition 'resource-exhausted)
    (when (member (arcdocdb.conditions:error-reason condition) resources)
      (return-from %classifica-guasto-worker nil)))
  (when (typep condition 'invalid-argument)
    (when (member (arcdocdb.conditions:error-reason condition) arguments)
      (return-from %classifica-guasto-worker nil)))
  (setf (contesto-worker-writer-fault context) condition
        (contesto-worker-writer-state context) :faulted)
  (unless (eq (contesto-worker-writer-fault context) condition)
    (error 'invariant-violation :reason :worker-state))
  (unless (eq (contesto-worker-writer-state context) :faulted)
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(defmacro %passo-worker ((context resources arguments) &body body)
  \"Pre: contesto owner-only non rientrante, ragioni letterali bounded. Post:
valori del corpo oppure errore propagato e fault locale registrato se inatteso.
Owner e FAULTED rifiutati prima del handler; nessun callback applicativo o retry.\"
  (let ((value (gensym \"WORKER\")) (handler (gensym \"WORKER-ERROR\")))
    `(let ((,value ,context))
       (%check-owner-worker ,value)
       (when (eq (contesto-worker-writer-state ,value) :faulted)
         (error 'resource-exhausted :reason :worker-state))
       (flet ((,handler (condition)
                (%classifica-guasto-worker ,value ',resources ',arguments condition)))
         (declare (dynamic-extent #',handler))
         (handler-bind ((error #',handler)) ,@body)))))
")
  (:PATH #A((31) BASE-CHAR . "src/execution/worker-claim.lisp") :BYTES 6401 :SHA256
   "62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e" :GIT-BLOB
   "4f34d18152d77fbf63bf708ebd0aabac178c3ac1" :TEXT
   ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t index) null) %assegna-worker))
(defun %assegna-worker (context writer home)
  \"Pre: IDLE/RESCHEDULE verificato, trasferimento riuscito dal ring. Post: CLAIMED.
INVARIANT-VIOLATION writer/fase incoerenti; nessun rollback dopo fault interno.\"
  (%check-worker context)
  (unless (typep writer 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (case (contesto-worker-writer-state context)
    ((:idle :reschedule) nil)
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (setf (contesto-worker-writer-writer context) writer
        (contesto-worker-writer-home context) home
        (contesto-worker-writer-state context) :claimed)
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :empty :busy) index &optional)) prendi-writer-worker))
(defun prendi-writer-worker (context)
  \"Pre: IDLE e owner corrente. Post: CLAIMED con obbligo/home, oppure IDLE con
cursore ruotato per EMPTY/BUSY. Verificatori typed, fase errata RESOURCE-EXHAUSTED;
EMPTY resta locale, mai prova di quiescenza per parcheggio o arresto.\"
  (%passo-worker (context (:worker-state) ())
  (%richiedi-worker context :idle)
  (let ((ready (contesto-worker-writer-ready context)))
    (multiple-value-bind (writer status next)
        (preleva-writer-pronto ready (contesto-worker-writer-cursor context))
      (setf (contesto-worker-writer-cursor context) next)
      (case status
        (:writer
         (%assegna-worker context writer
           (mod (+ next (1- (length (lista-writer-pronti-partitions ready))))
                (length (lista-writer-pronti-partitions ready))))
         (values writer :claimed next))
        ((:empty :busy) (%check-worker context) (values nil status next))
        (otherwise (error 'invariant-violation :reason :worker-state)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) index) inizia-tratto-worker))
(defun inizia-tratto-worker (context)
  \"Pre: CLAIMED senza lease. Post: RUNNING con lease del thread corrente.
Busy conserva CLAIMED; not-ready/generation restano fault permanenti del compito;
condizioni handoff e verificatori typed, nessun retry o perdita del riferimento.\"
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%richiedi-worker context :claimed)
  (let ((lease (inizia-tratto-writer (contesto-worker-writer-writer context))))
    (setf (contesto-worker-writer-lease context) lease
          (contesto-worker-writer-state context) :running)
    (%check-worker context)
    lease)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :published) index &optional)) ricircola-worker))
(defun ricircola-worker (context)
  \"Pre: RESCHEDULE, obbligo unico, owner corrente. Post: full trasferisce nuova
testa al contesto CLAIMED; room pubblica e libera IDLE. Busy conserva obbligo.
Condizioni ready/verificatori typed; nessun retry o dedup, count full invariato.\"
  (%passo-worker (context (:worker-state :ready-queue-busy) ())
  (%richiedi-worker context :reschedule)
  (multiple-value-bind (writer status count)
      (ricircola-writer-pronto (contesto-worker-writer-ready context)
                              (contesto-worker-writer-home context)
                              (contesto-worker-writer-writer context))
    (case status
      (:writer (%assegna-worker context writer (contesto-worker-writer-home context))
               (values writer :claimed count))
      (:published
       (unless (null writer) (error 'invariant-violation :reason :worker-state))
       (setf (contesto-worker-writer-writer context) nil
             (contesto-worker-writer-state context) :idle)
       (%check-worker context)
       (values nil :published count))
      (otherwise (error 'invariant-violation :reason :worker-state))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t) null) adotta-writer-worker))
(defun adotta-writer-worker (context writer home)
  \"Pre: IDLE, obbligo unico non nel ring affidato al caller e home stabile.
Post: CLAIMED sul contesto, obbligo trasferito dal caller; INVALID-ARGUMENT
writer/home prima delle scritture, fase/owner/verificatori typed. Nessun dedup.\"
  (%passo-worker (context (:worker-state) (:worker-writer :ready-target))
  (%richiedi-worker context :idle)
  (unless (typep writer 'writer-programmabile)
    (error 'invalid-argument :reason :worker-writer))
  (%partizione-verificata (contesto-worker-writer-ready context) home)
  (%assegna-worker context writer (the index home))
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer)
                         (values writer-programmabile index &optional)) cede-writer-worker))
(defun cede-writer-worker (context)
  \"Pre: CLAIMED/RESCHEDULE senza lease o batch. Post: IDLE, obbligo al caller
con home, generation conservata; mai cedere una lease attiva. Fase/owner e
verificatori typed; nessuna pubblicazione implicita, il caller non abbandona il ref.\"
  (%passo-worker (context (:worker-state) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:claimed :reschedule) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (let ((writer (contesto-worker-writer-writer context))
        (home (contesto-worker-writer-home context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (setf (contesto-worker-writer-writer context) nil
          (contesto-worker-writer-state context) :idle)
    (%check-worker context)
    (values writer home))))
")
  (:PATH #A((29) BASE-CHAR . "src/execution/worker-run.lisp") :BYTES 5125 :SHA256
   "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847" :GIT-BLOB
   "b1137f303cb707f8bf322f9deea764f716424d77" :TEXT
   ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t t) (values index (member :messages :empty :yield) index &optional)) preleva-lavori-worker))
(defun preleva-lavori-worker (context target start end)
  \"Pre: RUNNING senza batch; target privato, span valido. Post: BATCH con token
locale nuovo se messaggi, RUNNING/token0 se empty/yield. Busy/target invalido non
estraggono; RESOURCE-EXHAUSTED generation prima del pop, anche empty/yield.
Token non globale: ack usa la coppia contesto/token; condizioni writer delegate.\"
  (%passo-worker (context (:worker-state :worker-generation :writer-queue-busy) (:writer-target))
  (%richiedi-worker context :running)
  (%check-target (writer-programmabile-queue (contesto-worker-writer-writer context))
                 target start end)
  (when (= (contesto-worker-writer-batch-generation context) most-positive-fixnum)
    (error 'resource-exhausted :reason :worker-generation))
  (multiple-value-bind (count status)
      (preleva-lavori-writer (contesto-worker-writer-writer context)
                             (contesto-worker-writer-lease context) target start end)
    (case status
      (:messages
       (unless (plusp count) (error 'invariant-violation :reason :worker-state))
       (incf (contesto-worker-writer-batch-generation context))
       (setf (contesto-worker-writer-pending context) count
             (contesto-worker-writer-state context) :batch))
      ((:empty :yield)
       (unless (zerop count) (error 'invariant-violation :reason :worker-state)))
      (otherwise (error 'invariant-violation :reason :worker-state)))
    (%check-worker context)
    (values count status (if (plusp count) (contesto-worker-writer-batch-generation context) 0)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t) null) conferma-lavori-worker))
(defun conferma-lavori-worker (context token)
  \"Pre: BATCH elaborato completamente dal caller, token corrente locale.
Post: RUNNING senza debito; INVALID-ARGUMENT token errato/stale prima delle
scritture, fase/owner/verificatori typed. Attesta il caller, non effetti esterni.\"
  (%passo-worker (context (:worker-state) (:worker-batch))
  (%richiedi-worker context :batch)
  (unless (typep token 'index) (error 'invalid-argument :reason :worker-batch))
  (unless (plusp token) (error 'invalid-argument :reason :worker-batch))
  (unless (= token (contesto-worker-writer-batch-generation context))
    (error 'invalid-argument :reason :worker-batch))
  (setf (contesto-worker-writer-pending context) 0
        (contesto-worker-writer-state context) :running)
  (%check-worker context)
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer (member :idle :schedule)) null) %concludi-worker))
(defun %concludi-worker (context action)
  \"Pre: handoff terminato, contesto FINISHING senza debito. Post: IDLE libero
o RESCHEDULE con obbligo; INVARIANT-VIOLATION fase/debito/esito incoerenti.\"
  (%check-owner-worker context)
  (unless (eq (contesto-worker-writer-state context) :finishing)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (setf (contesto-worker-writer-lease context) 0)
  (case action
    (:idle (setf (contesto-worker-writer-writer context) nil
                 (contesto-worker-writer-state context) :idle))
    (:schedule (setf (contesto-worker-writer-state context) :reschedule))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :schedule)) termina-tratto-worker))
(defun termina-tratto-worker (context)
  \"Pre: RUNNING dopo ack oppure FINISHING da ritentare. Post: IDLE/RESCHEDULE.
Prima della chiamata fissa FINISHING: busy conserva lease/riferimento e impedisce
nuovi pop/ack. Solo retry del termine; condizioni handoff/verificatori typed.
Nessun cleanup sul writer dopo end, nessun cambiamento durevole o callback.\"
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:running :finishing) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (setf (contesto-worker-writer-state context) :finishing)
  (%check-worker context)
  (let ((action (termina-tratto-writer (contesto-worker-writer-writer context)
                                      (contesto-worker-writer-lease context))))
    (%concludi-worker context action)
    action)))

")
  (:PATH #A((28) BASE-CHAR . "tests/execution/support.lisp") :BYTES 4469 :SHA256
   "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43" :GIT-BLOB
   "b8bac07926727a644f0246f6b57d600332288310" :TEXT
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
  (:PATH #A((28) BASE-CHAR . "tests/execution/handoff.lisp") :BYTES 33278 :SHA256
   "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e" :GIT-BLOB
   "ba702352ee63241b9ac993b0aca8f162c3deef1b" :TEXT
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
  (:PATH #A((34) BASE-CHAR . "tests/execution/ready-recycle.lisp") :BYTES 30075 :SHA256
   "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae" :GIT-BLOB
   "1dff8707436ca52f20f62e9946621ca1037f33d2" :TEXT
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
  (:PATH #A((27) BASE-CHAR . "tests/execution/worker.lisp") :BYTES 59783 :SHA256
   "ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06" :GIT-BLOB
   "2a14573906b94b254712a1e9322058ec1081f6f8" :TEXT
   ";;;; Un contesto per il thread proprietario; obblighi pubblici unici da handoff.
;;;; Liste/payload dell'oracolo non leggono gli indici o lo stato privato writer.
;;;; Accessor privati solo per snapshot di rifiuto o FI quiescente dichiarata.
;;;; Thread, semafori e retry bounded appartengono soltanto alla fixture.
(in-package #:arcdocdb.execution.tests)

(defun worker-check-state (context expected-state expected-writer)
  (is (eq expected-state (arcdocdb.execution:stato-worker-writer context)))
  (is (eq expected-writer (arcdocdb.execution:writer-worker-writer context)))
  (unless (eq expected-state :faulted)
    (is (null (arcdocdb.execution:errore-worker-writer context)))))

(defun worker-test-writer (items &optional (quantum 1))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile
                 :capacity (max 4 (length items)) :quantum quantum)))
    (loop for item in items for count from 1
          do (handoff-check-enqueue writer item count (if (= count 1) :schedule :queued)))
    writer))

(defun worker-check-claim (context expected expected-status expected-cursor)
  (multiple-value-bind (writer status cursor) (arcdocdb.execution:prendi-writer-worker context)
    (is (eq writer expected)) (is (eq status expected-status)) (is (= cursor expected-cursor))
    (worker-check-state context (if expected :claimed :idle) expected)
    writer))

(defun worker-check-pop (context target start end expected expected-status)
  \"Verifica FIFO per identità e tutte le celle non scritte del buffer caller.\"
  (let ((before (copy-seq target)))
    (multiple-value-bind (count status token)
        (arcdocdb.execution:preleva-lavori-worker context target start end)
      (is (= count (length expected))) (is (eq status expected-status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref target i) (svref before i)))))
      (if (eq status :messages)
          (progn (is (and (typep token 'fixnum) (plusp token)))
                 (is (eq :batch (arcdocdb.execution:stato-worker-writer context))))
          (progn (is (zerop token))
                 (is (eq :running (arcdocdb.execution:stato-worker-writer context)))))
      token)))

(defun worker-check-ack (context token writer)
  (is (null (arcdocdb.execution:conferma-lavori-worker context token)))
  (worker-check-state context :running writer))

(defun worker-check-end (context writer expected)
  (is (eq expected (arcdocdb.execution:termina-tratto-worker context)))
  (worker-check-state context (if (eq expected :schedule) :reschedule :idle)
                      (and (eq expected :schedule) writer)))

(defun worker-check-recycle (context expected expected-status expected-count)
  (multiple-value-bind (writer status count) (arcdocdb.execution:ricircola-worker context)
    (is (eq writer expected)) (is (eq status expected-status)) (is (= count expected-count))
    (worker-check-state context (if expected :claimed :idle) expected)
    writer))

(defun worker-complete-one (context writer item)
  (let ((lease (arcdocdb.execution:inizia-tratto-worker context)))
    (is (and (typep lease 'fixnum) (plusp lease))))
  (worker-check-state context :running writer)
  (worker-check-ack context (worker-check-pop context (vector :left :kept :right)
                                             1 2 (list item) :messages) writer)
  (worker-check-end context writer :idle))

(defun worker-fi-snapshot (context)
  \"Solo immagine di rifiuti/FI; mai ordine atteso delle liste o dei payload.\"
  (list (arcdocdb.execution::contesto-worker-writer-cursor context)
        (arcdocdb.execution::contesto-worker-writer-home context)
        (arcdocdb.execution::contesto-worker-writer-writer context)
        (arcdocdb.execution::contesto-worker-writer-lease context)
        (arcdocdb.execution::contesto-worker-writer-pending context)
        (arcdocdb.execution::contesto-worker-writer-batch-generation context)
        (arcdocdb.execution::contesto-worker-writer-state context)
        (arcdocdb.execution::contesto-worker-writer-fault context)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-004-worker-factory-preflight-and-empty-cursor-rotation
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1)))
    (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
      (signals invalid-argument
        (arcdocdb.execution:crea-contesto-worker-writer ready :start bad) :ready-target))
    (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready)))
      (worker-check-state context :idle nil)
      (dotimes (step 9) (worker-check-claim context nil :empty (mod (1+ step) 3))))
    (dotimes (start 3)
      (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready :start start)))
        (worker-check-claim context nil :empty (mod (1+ start) 3))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-001-worker-claim-batch-ack-and-idle-release
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (item (vector :only)) (writer (worker-test-writer (list item)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 1 writer 1)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer item)
    (worker-check-claim context nil :empty 1)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-quantum-yield-reschedule-and-monotone-tokens
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (items (list (vector 0) (vector 1) (vector 2)))
         (writer (worker-test-writer items))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (last-token 0) (last-lease 0))
    (ready-check-publish ready 0 writer 1)
    (loop for item in items for last = (eq item (third items))
          do (worker-check-claim context writer :claimed 0)
             (let ((lease (arcdocdb.execution:inizia-tratto-worker context)))
               (is (> lease last-lease)) (setf last-lease lease))
             (let ((token (worker-check-pop context (vector nil nil nil) 1 2 (list item) :messages)))
               (is (> token last-token)) (setf last-token token)
               (worker-check-ack context token writer))
             (worker-check-pop context (vector :untouched) 0 1 nil :yield)
             (worker-check-end context writer (if last :idle :schedule))
             (unless last (worker-check-recycle context nil :published 1)))
    (worker-check-claim context nil :empty 0)))

(defun worker-check-idle-only-refusals (context)
  (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context) :worker-state)
  (signals resource-exhausted
    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context 1) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
  (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-004
(deftest test-REQ-CON-005-worker-batch-debt-blocks-more-pop-finish-and-transfer
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (worker-check-idle-only-refusals context)
    (ready-check-publish ready 0 writer 1)
    (worker-check-claim context writer :claimed 0)
    (signals resource-exhausted (arcdocdb.execution:prendi-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
    (arcdocdb.execution:inizia-tratto-worker context)
    (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
    (let* ((target (vector :left :middle :right))
           (token (worker-check-pop context target 1 2 '(:one) :messages))
           (before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      (signals resource-exhausted
        (arcdocdb.execution:preleva-lavori-worker context target 0 3) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
      (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :one :right)))
      (worker-check-ack context token writer))
    (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:two) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-current-token-required-and-stale-ack-keeps-debt
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1)
    (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((first (worker-check-pop context (vector nil) 0 1 '(:one) :messages)))
      (let ((before (worker-fi-snapshot context)))
        (dolist (bad (list nil -1 0 1.0 :token (1+ most-positive-fixnum) (1+ first)))
          (signals invalid-argument (arcdocdb.execution:conferma-lavori-worker context bad)
                   :worker-batch))
        (is (equalp before (worker-fi-snapshot context))))
      (worker-check-ack context first writer)
      (signals resource-exhausted
        (arcdocdb.execution:conferma-lavori-worker context first) :worker-state)
      (let ((second (worker-check-pop context (vector nil) 0 1 '(:two) :messages)))
        (is (> second first))
        (let ((before (worker-fi-snapshot context)))
          (signals invalid-argument
            (arcdocdb.execution:conferma-lavori-worker context first) :worker-batch)
          (is (equalp before (worker-fi-snapshot context))))
        (worker-check-ack context second writer)))
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-buffer-range-and-private-alias-preflight
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:kept)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-worker context target (first range) (second range))
          :writer-target))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :kept)
                        (arcdocdb.execution::coda-writer-slots queue)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-worker context bad 0 1) :writer-target))
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :middle :right))))
    (worker-check-ack context (worker-check-pop context target 1 2 '(:kept) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-begin-busy-retains-claimed-reference
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:once)))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (with-execution-guard (queue)
      (let ((before (worker-fi-snapshot context)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context)
                 :writer-queue-busy)
        (is (equalp before (worker-fi-snapshot context)))))
    (ready-check-take ready 0 nil :empty 0)
    (worker-complete-one context writer :once)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-pop-busy-retains-lease-buffer-and-generation
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:once)))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (with-execution-guard (queue)
      (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted
          (arcdocdb.execution:preleva-lavori-worker context target 1 2) :writer-queue-busy)
        (is (equalp before (worker-fi-snapshot context)))
        (is (equalp writer-before (handoff-fi-snapshot writer)))
        (is (equalp target #(:left :middle :right)))))
    (worker-check-ack context (worker-check-pop context target 1 2 '(:once) :messages) writer)
    (worker-check-end context writer :idle)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-end-busy-is-finishing-and-blocks-new-pop
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:one) :messages) writer)
    (with-execution-guard (queue)
      (let ((writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                 :writer-queue-busy)
        (worker-check-state context :finishing writer)
        (let ((before (worker-fi-snapshot context)))
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                   :writer-queue-busy)
          (signals resource-exhausted
            (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-state)
          (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context 1)
                   :worker-state)
          (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
          (is (equalp before (worker-fi-snapshot context))))
        (is (equalp writer-before (handoff-fi-snapshot writer)))))
    (worker-check-end context writer :schedule)
    (worker-check-recycle context nil :published 1)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer :two)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-worker-scanned-home-and-full-recycle-retained-on-busy
  (dolist (home '(1 2 3))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 4 :capacity 1))
           (writer (worker-test-writer '(:one :two)))
           (blocker (worker-test-writer '(:blocker)))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (partition (ready-test-partition ready home)))
      (ready-check-publish ready home writer 1)
      (ready-call-with-guards
       (list (ready-test-partition ready 0))
       (lambda () (worker-check-claim context writer :claimed (mod (1+ home) 4))))
      (arcdocdb.execution:inizia-tratto-worker context)
      (worker-check-ack context (worker-check-pop context (vector nil) 0 1 '(:one) :messages) writer)
      (worker-check-end context writer :schedule)
      (ready-check-publish ready home blocker 1)
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (worker-fi-snapshot context)) (ring-before (ready-fi-snapshot partition)))
           (signals resource-exhausted (arcdocdb.execution:ricircola-worker context)
                    :ready-queue-busy)
           (is (equalp before (worker-fi-snapshot context)))
           (is (equalp ring-before (ready-fi-snapshot partition))))))
      (worker-check-recycle context blocker :claimed 1)
      (worker-complete-one context blocker :blocker)
      (worker-check-claim context writer :claimed (mod (1+ home) 4))
      (worker-complete-one context writer :two)
      (worker-check-claim context nil :empty (mod (+ 2 home) 4)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-worker-two-contexts-full-refill-preserves-all-obligations
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 2))
         (writers (vector (worker-test-writer '(:a0 :a1)) (worker-test-writer '(:b0 :b1))
                          (worker-test-writer '(:c)) (worker-test-writer '(:d))))
         (contexts (vector (arcdocdb.execution:crea-contesto-worker-writer ready)
                           (arcdocdb.execution:crea-contesto-worker-writer ready))))
    (dotimes (i 2) (ready-check-publish ready 0 (svref writers i) (1+ i)))
    (dotimes (i 2)
      (let ((context (svref contexts i)) (writer (svref writers i)))
        (worker-check-claim context writer :claimed 0)
        (arcdocdb.execution:inizia-tratto-worker context)
        (worker-check-ack context
                          (worker-check-pop context (vector nil) 0 1 (list (if (zerop i) :a0 :b0))
                                            :messages) writer)))
    (dotimes (i 2) (ready-check-publish ready 0 (svref writers (+ i 2)) (1+ i)))
    (dotimes (i 2) (worker-check-end (svref contexts i) (svref writers i) :schedule))
    ;; Due swap, nessun dequeue aggiuntivo o duplicazione dell'obbligo A/B.
    (dotimes (i 2)
      (worker-check-recycle (svref contexts i) (svref writers (+ i 2)) :claimed 2))
    (dotimes (i 2)
      (worker-complete-one (svref contexts i) (svref writers (+ i 2)) (if (zerop i) :c :d)))
    (dotimes (i 2)
      (worker-check-claim (svref contexts i) (svref writers i) :claimed 0)
      (worker-complete-one (svref contexts i) (svref writers i) (if (zerop i) :a1 :b1)))
    (worker-check-claim (svref contexts 0) nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-worker-empty-observation-and-new-wave-after-idle
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:initial) 3))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    (let ((first (worker-check-pop context (vector nil) 0 1 '(:initial) :messages)))
      (worker-check-ack context first writer)
      (worker-check-pop context (vector :untouched) 0 1 nil :empty)
      (handoff-check-enqueue writer :before-release 1 :queued)
      (let ((next (worker-check-pop context (vector nil) 0 1 '(:before-release) :messages)))
        (is (> next first)) (worker-check-ack context next writer)))
    (worker-check-end context writer :idle)
    (handoff-check-enqueue writer :next-wave 1 :schedule)
    (ready-check-publish ready 0 writer 1)
    (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
    (worker-check-claim context writer :claimed 0)
    (worker-complete-one context writer :next-wave)))

(defun worker-check-foreign-owner (context writer)
  (signals invalid-argument (arcdocdb.execution:stato-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:writer-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:errore-worker-writer context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:prendi-writer-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:inizia-tratto-worker context) :worker-owner)
  (signals invalid-argument
    (arcdocdb.execution:preleva-lavori-worker context (vector nil) 0 1) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:conferma-lavori-worker context 0) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:termina-tratto-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:ricircola-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:cede-writer-worker context) :worker-owner)
  (signals invalid-argument (arcdocdb.execution:adotta-writer-worker context writer 0) :worker-owner))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CON-002-worker-foreign-thread-refuses-all-six-phases
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:one :two) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore)) (threads nil))
    (unwind-protect
         (progn
           (push (execution-thread
                  \"worker foreign reused observer\"
                  (lambda ()
                    (dotimes (phase 6)
                      (execution-wait go) (worker-check-foreign-owner context writer)
                      (sb-thread:signal-semaphore done))
                    :ok)) threads)
           (flet ((probe ()
                    (let ((before (worker-fi-snapshot context))
                          (writer-before (handoff-fi-snapshot writer)))
                      (sb-thread:signal-semaphore go) (execution-wait done)
                      (is (equalp before (worker-fi-snapshot context)))
                      (is (equalp writer-before (handoff-fi-snapshot writer))))))
             (probe)
             (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
             (probe)
             (arcdocdb.execution:inizia-tratto-worker context) (probe)
             (let ((token (worker-check-pop context (vector nil) 0 1 '(:one) :messages)))
               (probe) (worker-check-ack context token writer))
             (with-execution-guard (queue)
               (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context)
                        :writer-queue-busy)
               (probe))
             (worker-check-end context writer :schedule) (probe))
           (execution-join (first threads))
           (worker-check-recycle context nil :published 1)
           (worker-check-claim context writer :claimed 0)
           (worker-complete-one context writer :two))
      (sb-thread:signal-semaphore go) (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-local-generation-limit-can-cede-into-fresh-context
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writer (worker-test-writer '(:last :preserved) 2))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (fresh (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (vector :left :middle :right)))
    (ready-check-publish ready 1 writer 1) (worker-check-claim context writer :claimed 0)
    (arcdocdb.execution:inizia-tratto-worker context)
    ;; FI locale, nessun pop/debito attivo; raggiunge l'ultimo token rappresentabile.
    (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context)
          (1- most-positive-fixnum))
    (let ((token (worker-check-pop context target 1 2 '(:last) :messages)))
      (is (= token most-positive-fixnum)) (worker-check-ack context token writer))
    (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
      ;; Target/range ha precedenza, ma una forma valida non può mutare dopo overflow.
      (signals invalid-argument
        (arcdocdb.execution:preleva-lavori-worker context nil 0 1) :writer-target)
      (signals resource-exhausted
        (arcdocdb.execution:preleva-lavori-worker context target 0 1) :worker-generation)
      (is (equalp before (worker-fi-snapshot context)))
      (is (equalp writer-before (handoff-fi-snapshot writer)))
      (is (equalp target #(:left :last :right))))
    (worker-check-end context writer :schedule)
    (multiple-value-bind (owned home) (arcdocdb.execution:cede-writer-worker context)
      (is (eq owned writer)) (is (= home 1)) (worker-check-state context :idle nil)
      (is (= most-positive-fixnum
             (arcdocdb.execution::contesto-worker-writer-batch-generation context)))
      (is (null (arcdocdb.execution:adotta-writer-worker fresh owned home))))
    (worker-check-state fresh :claimed writer)
    (worker-complete-one fresh writer :preserved)
    (worker-check-claim fresh nil :empty 1)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-CON-002-worker-cede-adopt-validates-home-and-single-caller-obligation
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1))
         (writer (worker-test-writer '(:kept)))
         (source (arcdocdb.execution:crea-contesto-worker-writer ready))
         (target (arcdocdb.execution:crea-contesto-worker-writer ready :start 2)))
    (ready-check-publish ready 1 writer 1) (worker-check-claim source writer :claimed 2)
    (multiple-value-bind (owned home) (arcdocdb.execution:cede-writer-worker source)
      (is (eq owned writer)) (is (= home 1)) (worker-check-state source :idle nil)
      (let ((before (worker-fi-snapshot target)))
        (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
          (signals invalid-argument (arcdocdb.execution:adotta-writer-worker target owned bad)
                   :ready-target))
        (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
          (signals invalid-argument (arcdocdb.execution:adotta-writer-worker target bad home)
                   :worker-writer))
        (is (equalp before (worker-fi-snapshot target))))
      (is (null (arcdocdb.execution:adotta-writer-worker target owned home))))
    (worker-check-state target :claimed writer)
    (signals resource-exhausted
      (arcdocdb.execution:adotta-writer-worker target writer 1) :worker-state)
    (worker-check-claim source nil :empty 0)
    (worker-complete-one target writer :kept)))

(defstruct worker-oracle
  ready context lists writers payloads phases homes leases
  (state :idle) (index nil) (home 0) (cursor 0) (remaining 0) (token 0)
  (accepted 0) (delivered 0))

(defun worker-oracle-publish (oracle index capacity)
  (when (eq (svref (worker-oracle-phases oracle) index) :pending)
    (let* ((home (svref (worker-oracle-homes oracle) index))
           (items (svref (worker-oracle-lists oracle) home))
           (writer (svref (worker-oracle-writers oracle) index)))
      (if (= (length items) capacity)
          (signals resource-exhausted
            (arcdocdb.execution:pubblica-writer-pronto (worker-oracle-ready oracle) home writer)
            :ready-queue-full)
          (progn
            (ready-check-publish (worker-oracle-ready oracle) home writer (1+ (length items)))
            (setf (svref (worker-oracle-lists oracle) home) (append items (list writer))
                  (svref (worker-oracle-phases oracle) index) :published))))))

(defun worker-oracle-enqueue (oracle index payload capacity)
  (let ((items (svref (worker-oracle-payloads oracle) index))
        (phase (svref (worker-oracle-phases oracle) index)))
    (when (< (length items) 4)
      (handoff-check-enqueue (svref (worker-oracle-writers oracle) index) payload (1+ (length items))
                             (if (eq phase :idle) :schedule :queued))
      (setf (svref (worker-oracle-payloads oracle) index) (append items (list payload)))
      (incf (worker-oracle-accepted oracle))
      (when (eq phase :idle)
        (setf (svref (worker-oracle-phases oracle) index) :pending)
        (worker-oracle-publish oracle index capacity)))))

(defun worker-oracle-claim (oracle)
  (when (eq (worker-oracle-state oracle) :idle)
    (let* ((lists (worker-oracle-lists oracle)) (shards (length lists))
           (start (worker-oracle-cursor oracle)))
      (dotimes (distance shards)
        (let* ((home (mod (+ start distance) shards)) (items (svref lists home)))
          (when items
            (let ((index (position (first items) (worker-oracle-writers oracle) :test #'eq)))
              (is (eq (svref (worker-oracle-phases oracle) index) :published))
              (worker-check-claim (worker-oracle-context oracle) (first items) :claimed
                                  (mod (1+ home) shards))
              (setf (svref lists home) (rest items)
                    (svref (worker-oracle-phases oracle) index) :owned
                    (worker-oracle-state oracle) :claimed (worker-oracle-index oracle) index
                    (worker-oracle-home oracle) home
                    (worker-oracle-cursor oracle) (mod (1+ home) shards))
              (return-from worker-oracle-claim t)))))
      (setf (worker-oracle-cursor oracle) (mod (1+ start) shards))
      (worker-check-claim (worker-oracle-context oracle) nil :empty (worker-oracle-cursor oracle))
      nil)))

(defun worker-oracle-begin (oracle quantum)
  (when (eq (worker-oracle-state oracle) :claimed)
    (let* ((index (worker-oracle-index oracle))
           (lease (arcdocdb.execution:inizia-tratto-worker (worker-oracle-context oracle))))
      (is (> lease (svref (worker-oracle-leases oracle) index)))
      (setf (svref (worker-oracle-leases oracle) index) lease
            (svref (worker-oracle-phases oracle) index) :active
            (worker-oracle-state oracle) :running (worker-oracle-remaining oracle) quantum)
      (worker-check-state (worker-oracle-context oracle) :running
                          (svref (worker-oracle-writers oracle) index)))))

(defun worker-oracle-pop (oracle start span)
  (when (eq (worker-oracle-state oracle) :running)
    (let* ((index (worker-oracle-index oracle))
           (items (svref (worker-oracle-payloads oracle) index))
           (remaining (worker-oracle-remaining oracle))
           (count (min span remaining (length items)))
           (status (cond ((zerop remaining) :yield) ((zerop count) :empty) (t :messages)))
           (token (worker-check-pop (worker-oracle-context oracle)
                                    (make-array (+ start span 2) :initial-element :untouched)
                                    start (+ start span) (subseq items 0 count) status)))
      (when (plusp count)
        (is (> token (worker-oracle-token oracle)))
        (setf (worker-oracle-token oracle) token (worker-oracle-state oracle) :batch
              (svref (worker-oracle-payloads oracle) index) (nthcdr count items))
        (decf (worker-oracle-remaining oracle) count)
        (incf (worker-oracle-delivered oracle) count)))))

(defun worker-oracle-ack (oracle)
  (when (eq (worker-oracle-state oracle) :batch)
    (worker-check-ack (worker-oracle-context oracle) (worker-oracle-token oracle)
                      (svref (worker-oracle-writers oracle) (worker-oracle-index oracle)))
    (setf (worker-oracle-state oracle) :running)))

(defun worker-oracle-end (oracle)
  (when (eq (worker-oracle-state oracle) :running)
    (let* ((index (worker-oracle-index oracle))
           (action (if (svref (worker-oracle-payloads oracle) index) :schedule :idle)))
      (worker-check-end (worker-oracle-context oracle)
                        (svref (worker-oracle-writers oracle) index) action)
      (setf (worker-oracle-state oracle) (if (eq action :schedule) :reschedule :idle)
            (svref (worker-oracle-phases oracle) index) (if (eq action :schedule) :owned :idle)
            (worker-oracle-remaining oracle) 0)
      (when (eq action :idle) (setf (worker-oracle-index oracle) nil)))))

(defun worker-oracle-recycle (oracle capacity)
  (when (eq (worker-oracle-state oracle) :reschedule)
    (let* ((home (worker-oracle-home oracle)) (lists (worker-oracle-lists oracle))
           (items (svref lists home)) (full (= (length items) capacity))
           (old (and full (first items))) (index (worker-oracle-index oracle)))
      (worker-check-recycle (worker-oracle-context oracle) old (if full :claimed :published)
                            (if full capacity (1+ (length items))))
      (setf (svref lists home)
            (append (if full (rest items) items) (list (svref (worker-oracle-writers oracle) index)))
            (svref (worker-oracle-phases oracle) index) :published)
      (if old
          (let ((old-index (position old (worker-oracle-writers oracle) :test #'eq)))
            (is (eq (svref (worker-oracle-phases oracle) old-index) :published))
            (setf (svref (worker-oracle-phases oracle) old-index) :owned
                  (worker-oracle-index oracle) old-index (worker-oracle-state oracle) :claimed))
          (setf (worker-oracle-index oracle) nil (worker-oracle-state oracle) :idle)))))

(defun worker-oracle-drain (oracle capacity quantum)
  \"Limite dérivato dai payload accettati e dal numero di writer; nessun retry infinito.\"
  (loop repeat (+ 100 (* 8 (worker-oracle-accepted oracle)))
        do (case (worker-oracle-state oracle)
             (:idle
              (dotimes (i (length (worker-oracle-writers oracle)))
                (worker-oracle-publish oracle i capacity))
              (unless (worker-oracle-claim oracle)
                (is (every (lambda (phase) (eq phase :idle)) (worker-oracle-phases oracle)))
                (return-from worker-oracle-drain t)))
             (:claimed (worker-oracle-begin oracle quantum))
             (:batch (worker-oracle-ack oracle))
             (:reschedule (worker-oracle-recycle oracle capacity))
             (:running
              (if (or (zerop (worker-oracle-remaining oracle))
                      (null (svref (worker-oracle-payloads oracle) (worker-oracle-index oracle))))
                  (worker-oracle-end oracle)
                  (worker-oracle-pop oracle 1 3)))
             (otherwise (error \"Fase inattesa nell'oracolo worker.\"))))
  (error \"Drain worker oltre il limite indipendente.\"))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-worker-seeded-independent-obligations-payloads-and-batch-debt
  (let ((seed #x31e45a92))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dolist (shards '(1 4))
        (dolist (capacity '(1 2))
          (dolist (quantum '(1 2))
            (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti
                           :shards shards :capacity capacity))
                   (writers (make-array 13)) (homes (make-array 13))
                   (oracle (make-worker-oracle
                            :ready ready :context (arcdocdb.execution:crea-contesto-worker-writer ready)
                            :lists (make-array shards :initial-element nil) :writers writers :homes homes
                            :payloads (make-array 13 :initial-element nil)
                            :phases (make-array 13 :initial-element :idle)
                            :leases (make-array 13 :initial-element 0))))
              (dotimes (i 13)
                (setf (svref writers i) (worker-test-writer nil quantum)
                      (svref homes i) (mod i shards)))
              (dotimes (step 1000)
                (let ((index (mod (ash (next) -8) 13)))
                  (case (mod (ash (next) -8) 9)
                    ((0 1) (worker-oracle-enqueue oracle index
                                                  (vector shards capacity quantum step) capacity))
                    (2 (worker-oracle-publish oracle index capacity))
                    (3 (worker-oracle-claim oracle))
                    (4 (worker-oracle-begin oracle quantum))
                    (5 (worker-oracle-pop oracle (1+ (mod (next) 3))
                                          (1+ (mod (ash (next) -8) 3))))
                    (6 (worker-oracle-ack oracle))
                    (7 (worker-oracle-end oracle))
                    (8 (worker-oracle-recycle oracle capacity)))))
              (is (worker-oracle-drain oracle capacity quantum))
              (is (= (worker-oracle-accepted oracle) (worker-oracle-delivered oracle)))
              (is (every #'null (worker-oracle-payloads oracle)))
              (is (every #'null (worker-oracle-lists oracle)))
              (worker-check-state (worker-oracle-context oracle) :idle nil))))))))

(defun worker-fi-restore (context snapshot)
  \"Solo FI quiescente del checker privato; nessun reset di un contesto faulted.\"
  (destructuring-bind (cursor home writer lease pending generation state fault) snapshot
    (setf (arcdocdb.execution::contesto-worker-writer-cursor context) cursor
          (arcdocdb.execution::contesto-worker-writer-home context) home
          (arcdocdb.execution::contesto-worker-writer-writer context) writer
          (arcdocdb.execution::contesto-worker-writer-lease context) lease
          (arcdocdb.execution::contesto-worker-writer-pending context) pending
          (arcdocdb.execution::contesto-worker-writer-batch-generation context) generation
          (arcdocdb.execution::contesto-worker-writer-state context) state
          (arcdocdb.execution::contesto-worker-writer-fault context) fault)))

(defun worker-fi-corrupt (context fault writer)
  (case fault
    (:idle-writer (setf (arcdocdb.execution::contesto-worker-writer-writer context) writer))
    ((:idle-lease :claimed-lease)
     (setf (arcdocdb.execution::contesto-worker-writer-lease context) 1))
    ((:idle-pending :claimed-pending :running-pending)
     (setf (arcdocdb.execution::contesto-worker-writer-pending context) 1))
    ((:claimed-writer :running-writer)
     (setf (arcdocdb.execution::contesto-worker-writer-writer context) nil))
    (:batch-pending
     (setf (arcdocdb.execution::contesto-worker-writer-pending context) 0))
    (:batch-generation
     (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context) 0))
    (:batch-extracted (setf (arcdocdb.execution::contesto-worker-writer-pending context) 2))
    (:cursor (setf (arcdocdb.execution::contesto-worker-writer-cursor context) 2))
    (:home (setf (arcdocdb.execution::contesto-worker-writer-home context) 2))
    (:fault (setf (arcdocdb.execution::contesto-worker-writer-fault context)
                  (make-condition 'simple-error :format-control \"FI nonnil fault\")))
    (otherwise (error \"FI worker sconosciuta.\"))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-private-shapes-and-pending-count-invariants
  (dolist (fault '(:idle-writer :idle-lease :idle-pending :claimed-writer :claimed-lease
                   :claimed-pending :running-writer :running-pending :batch-pending
                   :batch-generation :batch-extracted :cursor :home :fault))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (claimed (member fault '(:claimed-writer :claimed-lease :claimed-pending)))
           (active (member fault '(:running-writer :running-pending :batch-pending
                                   :batch-generation :batch-extracted)))
           (writer (if (or claimed active) (worker-test-writer '(:kept)) (ready-test-writer)))
           (batch-token nil))
      (when (or claimed active)
        (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 1))
      (when active (arcdocdb.execution:inizia-tratto-worker context))
      (when (member fault '(:batch-pending :batch-generation :batch-extracted))
        (setf batch-token (worker-check-pop context (vector nil) 0 1 '(:kept) :messages)))
      (let ((original (worker-fi-snapshot context)))
        (worker-fi-corrupt context fault writer)
        (let ((before (worker-fi-snapshot context)))
          (signals arcdocdb.conditions:invariant-violation
            (arcdocdb.execution::%check-worker context) :worker-state)
          (is (equalp before (worker-fi-snapshot context))))
        ;; Solo il checker privato è stato chiamato, senza confine/mutazione/fault.
        (worker-fi-restore context original))
      (cond (batch-token (worker-check-ack context batch-token writer)
                         (worker-check-end context writer :idle))
            (claimed (worker-complete-one context writer :kept))
            (active
             (worker-check-ack context
                               (worker-check-pop context (vector nil) 0 1 '(:kept) :messages) writer)
             (worker-check-end context writer :idle))
            (t (worker-check-state context :idle nil))))))

(defun worker-capture-condition (thunk type reason)
  (let ((condition (handler-case (progn (funcall thunk) nil) (error (condition) condition))))
    (is (typep condition type))
    (when reason (is (eq (arcdocdb.conditions:error-reason condition) reason)))
    condition))

(defun worker-check-faulted (context writer condition)
  (worker-check-state context :faulted writer)
  (is (eq condition (arcdocdb.execution:errore-worker-writer context)))
  (let ((before (worker-fi-snapshot context)))
    (signals resource-exhausted (arcdocdb.execution:prendi-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-worker context) :worker-state)
    (signals resource-exhausted
      (arcdocdb.execution:preleva-lavori-worker context nil 0 1) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:conferma-lavori-worker context nil) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:termina-tratto-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:ricircola-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:cede-writer-worker context) :worker-state)
    (signals resource-exhausted (arcdocdb.execution:adotta-writer-worker context nil 0) :worker-state)
    (is (equalp before (worker-fi-snapshot context))))
  (is (eq condition (arcdocdb.execution:errore-worker-writer context))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-worker-private-index-corruption-poisons-before-adopt
  (dolist (fault '(:cursor :home :fault))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (fresh (arcdocdb.execution:crea-contesto-worker-writer ready))
           (writer (worker-test-writer '(:kept))))
      (worker-fi-corrupt context fault writer)
      (let ((condition
              (worker-capture-condition
               (lambda () (arcdocdb.execution:adotta-writer-worker context writer 0))
               'arcdocdb.conditions:invariant-violation :worker-state)))
        (worker-check-faulted context nil condition))
      ;; L'adozione fallita non aveva trasferito l'obbligo unico del caller.
      (is (null (arcdocdb.execution:adotta-writer-worker fresh writer 0)))
      (worker-complete-one fresh writer :kept))))

(defun worker-tree-symbol-count (symbol form)
  (cond ((eq symbol form) 1)
        ((consp form) (+ (worker-tree-symbol-count symbol (car form))
                         (worker-tree-symbol-count symbol (cdr form))))
        (t 0)))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-boundary-expansion-values-once-and-error-identity
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready)) (evaluations 0)
         (expansion (macroexpand-1
                     '(arcdocdb.execution::%passo-worker
                       ((worker-boundary-context) (:worker-state) (:worker-batch)) (values :a :b)))))
    (is (= 1 (worker-tree-symbol-count 'worker-boundary-context expansion)))
    (multiple-value-bind (a b c)
        (arcdocdb.execution::%passo-worker
            ((progn (incf evaluations) context) (:worker-state) (:worker-batch))
          (values :a :b :c))
      (is (eq a :a)) (is (eq b :b)) (is (eq c :c)))
    (is (= evaluations 1)) (worker-check-state context :idle nil)
    (dolist (condition (list (make-condition 'resource-exhausted :reason :worker-state)
                             (make-condition 'invalid-argument :reason :worker-batch)))
      (is (eq condition
              (worker-capture-condition
               (lambda ()
                 (arcdocdb.execution::%passo-worker (context (:worker-state) (:worker-batch))
                   (error condition)))
               (type-of condition) (arcdocdb.conditions:error-reason condition))))
      (worker-check-state context :idle nil))
    (let ((unexpected (make-condition 'simple-error :format-control \"Boundary fixture\")))
      (is (eq unexpected
              (worker-capture-condition
               (lambda ()
                 (arcdocdb.execution::%passo-worker (context (:worker-state) (:worker-batch))
                   (error unexpected))) 'simple-error nil)))
      (worker-check-faulted context nil unexpected))
    (dolist (unexpected (list (make-condition 'resource-exhausted :reason :writer-generation)
                              (make-condition 'resource-exhausted :reason :writer-not-ready)
                              (make-condition 'invalid-argument :reason :writer-lease)
                              (make-condition 'arcdocdb.conditions:invariant-violation
                                              :reason :worker-state)))
      (let ((fresh (arcdocdb.execution:crea-contesto-worker-writer ready)))
        (is (eq unexpected
                (worker-capture-condition
                 (lambda ()
                   (arcdocdb.execution::%passo-worker (fresh (:worker-state) (:worker-batch))
                     (error unexpected)))
                 (type-of unexpected) (arcdocdb.conditions:error-reason unexpected))))
        (worker-check-faulted fresh nil unexpected)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-stale-not-ready-reference-cannot-steal-new-wave
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer '(:old)))
         (context (arcdocdb.execution:crea-contesto-worker-writer ready))
         (fresh (arcdocdb.execution:crea-contesto-worker-writer ready)) (threads nil))
    (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
    ;; FI: bypass handoff del contesto consuma il vecchio obbligo prima del begin.
    ;; Il riferimento CLAIMED diventa stale; questa duplicazione non è protocollo pubblico.
    (is (equal '(:old) (handoff-drain writer 1)))
    (let ((condition (worker-capture-condition
                      (lambda () (arcdocdb.execution:inizia-tratto-worker context))
                      'resource-exhausted :writer-not-ready)))
      (worker-check-faulted context writer condition)
      (unwind-protect
           (progn
             (push (execution-thread
                    \"faulted worker foreign owner\"
                    (lambda () (worker-check-foreign-owner context writer) :ok)) threads)
             (execution-join (first threads)))
        (execution-stop-threads threads))
      (worker-check-faulted context writer condition)
      (handoff-check-enqueue writer :new 1 :schedule)
      (ready-check-publish ready 0 writer 1)
      (worker-check-faulted context writer condition)
      (worker-check-claim fresh writer :claimed 0)
      (worker-complete-one fresh writer :new)
      (worker-check-faulted context writer condition))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-008
(deftest test-REQ-AFF-008-worker-generation-overflow-precedes-empty-and-yield-pop
  (dolist (quantum '(1 3))
    (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
           (writer (worker-test-writer '(:last) quantum))
           (context (arcdocdb.execution:crea-contesto-worker-writer ready))
           (target (vector :untouched)))
      (ready-check-publish ready 0 writer 1) (worker-check-claim context writer :claimed 0)
      (arcdocdb.execution:inizia-tratto-worker context)
      (setf (arcdocdb.execution::contesto-worker-writer-batch-generation context)
            (1- most-positive-fixnum))
      (let ((token (worker-check-pop context (vector nil) 0 1 '(:last) :messages)))
        (is (= token most-positive-fixnum)) (worker-check-ack context token writer))
      (let ((before (worker-fi-snapshot context)) (writer-before (handoff-fi-snapshot writer)))
        (signals resource-exhausted
          (arcdocdb.execution:preleva-lavori-worker context target 0 1) :worker-generation)
        (is (equalp before (worker-fi-snapshot context)))
        (is (equalp writer-before (handoff-fi-snapshot writer)))
        (is (equalp target #(:untouched))))
      (worker-check-end context writer :idle))))

(defun worker-wave-read (context writer expected last-token)
  (let* ((target (vector :left :untouched :right))
         (token (worker-check-pop context target 1 2 (list expected) :messages)))
    (is (> token last-token))
    (is (= (svref expected 4) (reference-crc (svref (svref target 1) 3) 0 256)))
    (worker-check-ack context token writer)
    token))

(defun worker-wave-producer (ready home writer messages go published third-go third-published finish)
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
  (execution-wait finish)
  :ok)

(defun worker-wave-consumer (ready home writer messages go taken finish drained results)
  ;; Il contesto è creato sul proprietario una volta e riusato per tutte le ondate.
  (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready :start home))
        (last-token 0))
    (dotimes (wave (length messages))
      (execution-wait go)
      (worker-check-claim context writer :claimed (mod (1+ home) 2))
      (arcdocdb.execution:inizia-tratto-worker context)
      (setf last-token (worker-wave-read context writer (first (svref messages wave)) last-token))
      (sb-thread:signal-semaphore taken)
      (execution-wait finish)
      (worker-check-end context writer :schedule)
      (worker-check-recycle context nil :published 1)
      (loop for item in (rest (svref messages wave)) for sequence from 1
            do (worker-check-claim context writer :claimed (mod (1+ home) 2))
               (arcdocdb.execution:inizia-tratto-worker context)
               (setf last-token (worker-wave-read context writer item last-token))
               (worker-check-end context writer (if (= sequence 2) :idle :schedule))
               (unless (= sequence 2) (worker-check-recycle context nil :published 1)))
      (worker-check-state context :idle nil)
      (setf (svref results wave) :verified)
      (sb-thread:signal-semaphore drained)))
  :ok)

(defun worker-start-wave-threads (ready writers messages semaphores results producers final-go)
  (let ((threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (series 2)
             (let ((s series))
               (let ((producer
                       (execution-thread
                        \"worker live reused producer\"
                        (lambda ()
                          (worker-wave-producer
                           ready s (svref writers s) (svref messages s)
                           (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                           (svref (svref semaphores 4) s) (svref (svref semaphores 5) s)
                           (svref final-go s))))))
                 (push producer threads) (setf (svref producers s) producer))
               (push (execution-thread
                      \"worker local reused consumer\"
                      (lambda ()
                        (worker-wave-consumer
                         ready s (svref writers s) (svref messages s)
                         (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                         (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                         (svref results s)))) threads)))
           (setf complete t) threads)
      (unless complete (execution-stop-threads threads)))))

(defun worker-drive-wave (ready semaphores results producers wave)
  (ready-pair-signal (svref semaphores 0)) (ready-pair-wait (svref semaphores 1))
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
     (is (eq :verified (svref (svref results 1) wave)))))
  (sb-thread:signal-semaphore (svref (svref semaphores 2) 0))
  (execution-wait (svref (svref semaphores 3) 0))
  (is (every #'sb-thread:thread-alive-p producers))
  (sb-thread:signal-semaphore (svref (svref semaphores 4) 0))
  (execution-wait (svref (svref semaphores 5) 0))
  (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
  (execution-wait (svref (svref semaphores 7) 0))
  (is (eq :verified (svref (svref results 0) wave)))
  (ready-check-take ready (mod wave 2) nil :empty (mod (1+ wave) 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-worker-reused-owner-contexts-live-producers-and-independent-shards
  (let* ((waves 6)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writers (vector (ready-test-writer) (ready-test-writer)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (producers (vector nil nil)) (semaphores (make-array 8))
         (final-go (ready-semaphore-pair)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (ready-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (worker-start-wave-threads ready writers messages semaphores results
                                                   producers final-go))
           (is (= 4 (length threads)))
           (dotimes (wave waves) (worker-drive-wave ready semaphores results producers wave))
           (ready-pair-signal final-go)
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series))))
           (format t \"  Worker: 4 thread riusati, ~D ondate, ~D payload CRC, contesti owner-only.~%\"
                   waves (* 2 waves 3)))
      (dotimes (i 8) (ready-pair-signal (svref semaphores i)))
      (ready-pair-signal final-go) (execution-stop-threads threads))))

(defun worker-competing-consumer (ready writer items go done results index)
  (let ((context (arcdocdb.execution:crea-contesto-worker-writer ready)) (last-token 0))
    (dotimes (wave (length items))
      (execution-wait go)
      (multiple-value-bind (actual status cursor) (arcdocdb.execution:prendi-writer-worker context)
        (is (zerop cursor))
        (if (eq status :claimed)
            (progn
              (is (eq actual writer))
              (arcdocdb.execution:inizia-tratto-worker context)
              (let ((token (worker-check-pop context (vector nil) 0 1
                                              (list (svref items wave)) :messages)))
                (is (> token last-token)) (setf last-token token)
                (worker-check-ack context token writer))
              (worker-check-end context writer :idle))
            (progn (is (null actual)) (is (member status '(:empty :busy)))))
        (setf (svref results index) status))
      (worker-check-state context :idle nil)
      (sb-thread:signal-semaphore done)))
  :ok)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-worker-competing-owner-contexts-claim-one-obligation-per-wave
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (worker-test-writer nil)) (items (make-array waves))
         (go (ready-semaphore-pair)) (done (ready-semaphore-pair))
         (results (vector nil nil)) (threads nil))
    (dotimes (wave waves) (setf (svref items wave) (vector wave :only)))
    (unwind-protect
         (progn
           (dotimes (i 2)
             (let ((index i))
               (push (execution-thread
                      \"worker competing owner context\"
                      (lambda ()
                        (worker-competing-consumer ready writer items (svref go index)
                                                    (svref done index) results index))) threads)))
           (dotimes (wave waves)
             (handoff-check-enqueue writer (svref items wave) 1 :schedule)
             (ready-check-publish ready 0 writer 1)
             (ready-pair-signal go) (ready-pair-wait done)
             (is (= 1 (count :claimed results)))
             (is (= 1 (+ (count :empty results) (count :busy results))))
             (ready-check-take ready 0 nil :empty 0))
           (dolist (thread threads) (execution-join thread))
           (format t \"  Worker: 2 consumer owner riusati, ~D ondate, un solo obbligo per ondata.~%\" waves))
      (ready-pair-signal go) (execution-stop-threads threads))))
")
  (:PATH #A((30) BASE-CHAR . "tools/writer-worker-bench.lisp") :BYTES 26228 :SHA256
   "aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1" :GIT-BLOB
   "1208ddc9971179fc3fcb9300a9ba3c22fcd4a8b9" :TEXT
   ";;;; Allocazioni seriali del contesto worker composto con handoff e lista pronta; nessun I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-worker-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-worker.bench (:use #:cl))
(in-package #:arcdocdb.writer-worker.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  \"Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità.\"
  (loop for path in (append '(#p\"arcdocdb.asd\" #p\"tools/writer-worker-bench.lisp\")
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
    (error \"COD-60: parametri benchmark worker fuori budget.\"))
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
        (error \"COD-60: clock/heap invalido o sink worker ~D diverso da ~D.\"
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun enqueue-message (enqueue writer payload expected-count expected-action)
  \"Accettazione unica; schedule/queued verificati prima del trasferimento pronto.\"
  (multiple-value-bind (count action) (funcall enqueue writer payload)
    (unless (and (= expected-count count) (eq expected-action action))
      (error \"COD-60: conteggio/obbligo enqueue worker incoerente.\"))
    (+ count (if (eq action :schedule) 11 17))))

(defun publish-message (publish ready shard writer expected-count)
  \"Una pubblicazione per obbligo conservato; ritorno count verificato.\"
  (let ((count (funcall publish ready shard writer)))
    (unless (= expected-count count) (error \"COD-60: count pubblicazione worker incoerente.\"))
    (+ 31 (* 3 count))))

(defun claim-writer (claim context expected-writer expected-cursor)
  \"Identità assegnata al contesto e cursore verificati a ogni prelievo.\"
  (multiple-value-bind (writer status cursor) (funcall claim context)
    (unless (and (eq writer expected-writer) (eq status :claimed) (= cursor expected-cursor))
      (error \"COD-60: identità/status/cursor claim worker incoerenti.\"))
    (+ 17 (* 7 cursor))))

(defun consume-current (start pop confirm finish context target nonces index batches payload status)
  \"Lease e batch monotoni; uno span posseduto, conferma esplicita e fine attesa.\"
  (let ((lease (funcall start context)) (token 19))
    (declare (type fixnum token))
    (unless (= lease (incf (the fixnum (svref nonces index))))
      (error \"COD-60: lease del contesto worker incoerente.\"))
    (multiple-value-bind (count result batch) (funcall pop context target 1 2)
      (unless (and (= 1 count) (eq :messages result)
                   (= batch (incf (the fixnum (svref batches 0))))
                   (eql payload (svref target 1))
                   (eq :outside (svref target 0)) (eq :outside (svref target 2)))
        (error \"COD-60: batch/span/payload worker incoerenti.\"))
      (incf token (+ (* 3 count) (* 5 (the fixnum (svref target 1)))))
      (unless (null (funcall confirm context batch))
        (error \"COD-60: conferma worker non restituisce NIL.\"))
      (incf token 7))
    (unless (eq status (funcall finish context))
      (error \"COD-60: termine worker diverso da schedule/idle atteso.\"))
    (+ token (if (eq status :idle) 23 13))))

(defun expected-token (shards capacity)
  \"M=K(C+1): full include i payload role-id 1..M, room solo payload zero.\"
  (let ((writers (* shards (1+ capacity))))
    (+ (* shards (+ 416 (* 115 capacity) (/ (* 3 capacity (1+ capacity)) 2)))
       (/ (* 7 (+ capacity 3) shards (1- shards)) 2)
       (/ (* 5 writers (1+ writers)) 2) 29 (* 7 (mod 1 shards)))))

(defun cycle-function (shards capacity)
  \"Contesto privato: backlog→full, drain/idle, backlog→room; identità riusate e ruotate.\"
  (let* ((create-ready (execution-function \"CREA-LISTA-WRITER-PRONTI\"))
         (publish (execution-function \"PUBBLICA-WRITER-PRONTO\"))
         (create-context (execution-function \"CREA-CONTESTO-WORKER-WRITER\"))
         (claim (execution-function \"PRENDI-WRITER-WORKER\"))
         (start (execution-function \"INIZIA-TRATTO-WORKER\"))
         (pop (execution-function \"PRELEVA-LAVORI-WORKER\"))
         (confirm (execution-function \"CONFERMA-LAVORI-WORKER\"))
         (finish (execution-function \"TERMINA-TRATTO-WORKER\"))
         (recycle (execution-function \"RICIRCOLA-WORKER\"))
         (create-writer (execution-function \"CREA-WRITER-PROGRAMMABILE\"))
         (enqueue (execution-function \"ACCODA-LAVORO-WRITER\"))
         (ready (funcall create-ready :shards shards :capacity capacity))
         (context (funcall create-context ready :start 0))
         (per-shard (1+ capacity)) (writers (make-array (* per-shard shards)))
         (nonces (make-array (* per-shard shards) :initial-element 0))
         (batches (make-array 1 :initial-element 0))
         (target (make-array 3 :initial-element :outside)) (phase 0))
    (declare (type fixnum phase shards capacity per-shard))
    (dotimes (i (length writers)) (setf (svref writers i) (funcall create-writer :capacity 2 :quantum 1)))
    (lambda ()
      (let ((token 0))
        (declare (type fixnum token))
        (dotimes (shard shards)
          (let* ((base (* per-shard shard)) (a-index (+ base phase))
                 (a-writer (svref writers a-index)) (next (mod (1+ shard) shards)))
            (incf token (enqueue-message enqueue a-writer 0 1 :schedule))
            (incf token (enqueue-message enqueue a-writer (1+ base) 2 :queued))
            (incf token (publish-message publish ready shard a-writer 1))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :schedule))
            (dotimes (ordinal capacity)
              (let* ((role (1+ ordinal)) (index (+ base (mod (+ phase role) per-shard)))
                     (writer (svref writers index)))
                (incf token (enqueue-message enqueue writer (+ base role 1) 1 :schedule))
                (incf token (publish-message publish ready shard writer (1+ ordinal)))))
            (let ((index (+ base (mod (1+ phase) per-shard))))
              (multiple-value-bind (writer status count) (funcall recycle context)
                (unless (and (eq writer (svref writers index)) (eq status :claimed) (= count capacity))
                  (error \"COD-60: ricircolo worker full non trasferisce FIFO/count atteso.\"))
                (incf token (+ 13 (* 3 count))))
              (incf token (consume-current start pop confirm finish context target nonces index batches (+ base 2) :idle)))
            (dotimes (ordinal capacity)
              (let* ((role (mod (+ ordinal 2) per-shard))
                     (index (+ base (mod (+ phase role) per-shard)))
                     (writer (svref writers index)))
                (incf token (claim-writer claim context writer next))
                (incf token (consume-current start pop confirm finish context target nonces index batches (+ base role 1) :idle))))
            ;; Lo shard è vuoto: secondo obbligo sul medesimo writer passa al ring con spazio.
            (incf token (enqueue-message enqueue a-writer 0 1 :schedule))
            (incf token (enqueue-message enqueue a-writer 0 2 :queued))
            (incf token (publish-message publish ready shard a-writer 1))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :schedule))
            (multiple-value-bind (writer status count) (funcall recycle context)
              (unless (and (null writer) (eq :published status) (= 1 count))
                (error \"COD-60: ricircolo worker room non pubblica un solo obbligo.\"))
              (incf token (+ 31 (* 3 count))))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :idle))))
        (multiple-value-bind (writer status cursor) (funcall claim context)
          (unless (and (null writer) (eq status :empty) (= cursor (mod 1 shards)))
            (error \"COD-60: scansione worker vuota/cursor incoerenti.\"))
          (incf token (+ 29 (* 7 cursor))))
        (setf phase (mod (1+ phase) per-shard))
        token))))

(defun campaign-record (scenario shards capacity)
  \"Quattro scenari preregistrati; payload e ritorni determinano un token esatto indipendente.\"
  (unless (and (member shards '(1 4)) (member capacity '(1 3)))
    (error \"COD-60: configurazione worker fuori dal preregistrato.\"))
  (list :scenario scenario :shards shards :capacity-per-shard capacity
        :workers 1 :writers-per-shard (1+ capacity) :contexts 1
        :full-exchanges-per-cycle shards :room-publications-per-cycle shards
        :processed-batches-per-cycle (* shards (+ capacity 4))
        :calls-per-cycle (1+ (* shards (+ (* 7 capacity) 27)))
        :expected-token (expected-token shards capacity) :token-rule
        '(:enqueue-count-plus-schedule-11-or-queued-17 :publish-31-plus-count-times-3
          :claim-17-plus-cursor-times-7 :lease-19 :taken-times-3 :payload-times-5
          :confirm-nil-7 :finish-idle-23-or-schedule-13
          :recycle-claimed-13-or-published-31-plus-count-times-3 :empty-29-plus-cursor-times-7)
        :token-formula \"K[416+115C+3C(C+1)/2]+7(C+3)K(K-1)/2+5M(M+1)/2+29+7*(1 mod K); M=K(C+1)\"
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
  (list :schema-version 1 :kind :writer-worker-benchmark :status :running :stage :pending
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-owner-context-handoff-ready-and-recycle-cycles :preallocated-inputs
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
              (getf report :diagnostic) \"COD-61: sorgenti cambiati durante il benchmark worker.\")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  \"Fixture temporanea esclusiva, con limite di mille collisioni.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-worker-bench-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture benchmark worker non disponibile.\"))

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
    (dolist (spec '((1 1 578) (1 3 858) (4 1 2520) (4 3 4084)))
      (destructuring-bind (shards capacity token) spec
        (unless (= token (expected-token shards capacity))
          (error \"COD-60: oracolo algebrico worker diverso dalla derivazione indipendente.\"))
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
      (format *error-output* \"~&writer-worker-bench.lisp: ~A~%\" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
")
  (:PATH #A((33) BASE-CHAR . "tools/writer-worker-mutation.lisp") :BYTES 27110 :SHA256
   "5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c" :GIT-BLOB
   "568bccdb1229b124e43e5c1b756cf726ead6fcbc" :TEXT
   ";;;; Mutazioni semantiche del contesto worker in copie isolate.
;;;; Uso: --self-test oppure --run directory-nuova/; writer-worker-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-005 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-worker.mutation (:use #:cl))
(in-package #:arcdocdb.writer-worker.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *worker-mutants*
  '((\"worker-owner-check-ignored\" \"src/execution/worker-types.lisp\"
     ((\"(eq (contesto-worker-writer-owner context) sb-thread:*current-thread*)\"
       \"(eq (contesto-worker-writer-owner context) (contesto-worker-writer-owner context))\")))
    (\"worker-claim-cursor-stays\" \"src/execution/worker-claim.lisp\"
     ((\"(setf (contesto-worker-writer-cursor context) next)\"
       \"(setf (contesto-worker-writer-cursor context) (contesto-worker-writer-cursor context))\")))
    (\"worker-claim-home-is-next\" \"src/execution/worker-claim.lisp\"
     ((\"(mod (+ next (1- (length (lista-writer-pronti-partitions ready))))
                (length (lista-writer-pronti-partitions ready)))\"
       \"next\")))
    (\"worker-start-keeps-claimed\" \"src/execution/worker-claim.lisp\"
     ((\"(setf (contesto-worker-writer-lease context) lease
          (contesto-worker-writer-state context) :running)\"
       \"(setf (contesto-worker-writer-lease context) lease
          (contesto-worker-writer-state context) :claimed)\")))
    (\"worker-batch-generation-stays\" \"src/execution/worker-run.lisp\"
     ((\"(incf (contesto-worker-writer-batch-generation context))\"
       \"(contesto-worker-writer-batch-generation context)\")))
    (\"worker-ack-stale-token-accepted\" \"src/execution/worker-run.lisp\"
     ((\"(unless (= token (contesto-worker-writer-batch-generation context))\"
       \"(unless (= token token)\")))
    (\"worker-ack-keeps-pending\" \"src/execution/worker-run.lisp\"
     ((\"(setf (contesto-worker-writer-pending context) 0\"
       \"(setf (contesto-worker-writer-pending context) (contesto-worker-writer-pending context)\")))
    (\"worker-end-skips-finishing-latch\" \"src/execution/worker-run.lisp\"
     ((\"(setf (contesto-worker-writer-state context) :finishing)\"
       \"(setf (contesto-worker-writer-state context) :running)\")))
    (\"worker-end-keeps-lease\" \"src/execution/worker-run.lisp\"
     ((\"(setf (contesto-worker-writer-lease context) 0)\"
       \"(setf (contesto-worker-writer-lease context) (contesto-worker-writer-lease context))\")))
    (\"worker-schedule-goes-idle\" \"src/execution/worker-run.lisp\"
     ((\"(:schedule (setf (contesto-worker-writer-state context) :reschedule))\"
       \"(:schedule (setf (contesto-worker-writer-state context) :idle))\")))
    (\"worker-recycle-room-keeps-writer\" \"src/execution/worker-claim.lisp\"
     ((\"(:published
       (unless (null writer) (error 'invariant-violation :reason :worker-state))
       (setf (contesto-worker-writer-writer context) nil\"
       \"(:published
       (unless (null writer) (error 'invariant-violation :reason :worker-state))
       (setf (contesto-worker-writer-writer context) (contesto-worker-writer-writer context)\")))
    (\"worker-recycle-full-keeps-old-writer\" \"src/execution/worker-claim.lisp\"
     ((\"(%assegna-worker context writer (contesto-worker-writer-home context))\"
       \"(%assegna-worker context (contesto-worker-writer-writer context) (contesto-worker-writer-home context))\")))))

(defun mutation-list ()
  \"Dodici mutanti semantici worker fissati prima della campagna.\"
  *worker-mutants*)

(defun source-files ()
  \"ASD, build, sorgenti e test richiesti dalle copie; nessuna evidenza o Git copiati.\"
  (append '(#p\"arcdocdb.asd\" #p\"tools/build.lisp\")
          (sort (append (directory \"src/**/*.lisp\") (directory \"tests/**/*.lisp\"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  \"MD5 dei file copiati e del driver: controllo di stabilità, non di autenticità.\"
  (loop for file in (append (source-files) '(#p\"tools/writer-worker-mutation.lisp\"))
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
  \"Dodici nomi unici; ogni bersaglio appare una sola volta nei sorgenti congelati.\"
  (unless (= 12 (length mutants)) (error \"COD-60: numero mutanti worker diverso da dodici.\"))
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
  \"Compilazione rigorosa e intera suite execution registrata, inclusi i test del contesto worker.\"
  (let ((path (merge-pathnames \"tools/writer-worker-isolated-build.lisp\" directory)))
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
                  (unless (and (probe-file \"tests/execution/worker.lisp\")
                               (asdf:find-component (asdf:find-system \"arcdocdb/tests\")
                                                    '(\"execution\" \"worker\")))
                    (error \"Test worker assente o non registrato in ASDF.\"))
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
                     \"--disable-debugger\" \"--script\" \"tools/writer-worker-isolated-build.lisp\")
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
  (list :schema-version 1 :kind :writer-worker-mutations :status :running :stage :validation
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
            (getf report :diagnostic) \"COD-61: sorgenti cambiati durante la campagna worker.\")))
  (write-report directory report)
  (format t \"~&Writer worker: ~A, baseline ~A, rilevati ~D/~D; ~A~%\"
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
            (unless passed (error \"COD-61: baseline worker fallita; ~A\" baseline)))
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
            (error \"COD-61: mutanti worker rilevati ~D/~D.\" (getf report :detected) (length mutants)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (finish-report directory report)))

(defun assert-self-test (expression description)
  \"Il self-test segnala la regola dello strumento che non è stata rilevata.\"
  (unless expression (error \"COD-60: writer-worker-mutation.lisp, self-test ~A.\" description)))

(defun fresh-self-test-directory ()
  \"Fixture esclusiva, al più mille collisioni, nessun percorso esterno da rimuovere.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-worker-mutation-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture worker non disponibile.\"))

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
                    (format nil \"spikes/out/~D-worker-signal-self-test-~D/\"
                            (get-universal-time) (sb-posix:getpid))))
         (runner (merge-pathnames \"tools/writer-worker-isolated-build.lisp\" directory))
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
    (format t \"~&Writer worker: self-test segnale OS superato; ~A~%\"
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
  (format t \"~&Writer worker: self-test superato, nessuna campagna eseguita.~%\")
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
                   (format *error-output* \"~&writer-worker-mutation.lisp: ~A~%\"
                           (getf report :diagnostic))
                   (uiop:quit 1))))
              (t (error \"COD-61: uso --self-test oppure --run directory-nuova/.\"))))
    (error (condition)
      (format *error-output* \"~&writer-worker-mutation.lisp: ~A~%\" condition)
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
  (:PATH #A((44) BASE-CHAR . "docs/implementazione/writer-worker-metodo.md") :BYTES 7583 :SHA256
   "e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7" :GIT-BLOB
   "a12ac9c53969f6755c8cb0de21212f06e7e03e4b" :TEXT "# Metodo del contesto worker dei writer

Preregistrazione del 2026-10-09 sulla base `cf60913`, prima delle campagne
congelate di correttezza, mutazione e allocazione. Il primo probe di sviluppo
`4000545928-command-51771-0` compila i primi tre sorgenti, prima dell'aggiunta
delle API di adozione/cessione: non viene attribuito al codice finale.
REQ-CON-001/002/004/005 e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4;
ADR-0005 e ADR-0045 §§6/8. Codice C1, strumenti C4.

## Contratto e stati

Contesto preallocato una volta sul thread worker che ne rimane proprietario,
non rientrante. Ready/owner read-only; cursor/home/ref/lease/pending e
batch-generation locali, nessun contatore globale. Sei fasi operative e una terminale:

- idle: nessun riferimento, lease o batch; take bounded aggiorna cursor anche
  dopo empty/busy. Una testa restituita diventa claimed, home è il predecessore
  modulo K del cursore restituito da ready, senza ricercare il writer.
- claimed: riferimento posseduto, begin separato acquisisce lease e passa running.
  Busy conserva il riferimento. Not-ready e generation esaurita non sono retry ciechi.
- running: pop con target/span/alias verificati prima dell'overflow locale.
  Messaggi creano batch con count positivo e token locale nuovo; empty/yield
  mantengono running con token0 e non incrementano generation. Busy non muta il contesto.
- batch: debito esplicito; vietati nuovo pop e termine. Ack valido attesta che
  il caller ha elaborato tutto il batch, elimina pending e torna running.
  Token monotono legato alla coppia contesto/token, non unico tra contesti.
- finishing: end viene latched prima della chiamata handoff; busy conserva
  lease e riferimento e consente solo il retry del termine. Nessuna rielaborazione.
- reschedule: end ha già rilasciato lease, riferimento conserva un obbligo.
  Recycle room pubblica e libera idle; full trasferisce la testa al contesto
  claimed conservando home e count. Busy conserva l'obbligo, senza ripetere end.

Adotta da idle un obbligo unico non nel ring; cede da claimed/reschedule al
caller la coppia writer/home e libera idle, senza azzerare batch-generation.
Nessuna cessione di lease/batch attivi. Permette restituzione esplicita degli
obblighi prima del ritiro o esaurimento del contesto, senza promettere un pool.
A overflow batch-generation, pop rifiuta anche se sarebbe empty/yield; end
rimane disponibile, seguito da cessione e adozione in altro contesto.

## Confini

Fase errata è resource-exhausted :worker-state, owner/ack/adozione invalidi
sono invalid-argument; overflow è resource-exhausted :worker-generation.
Busy di begin/pop/recycle conserva tutti i campi. Il primo end busy cambia
solo running→finishing, latch intenzionale; retry successivi conservano tutto.
Il confine di ciascun passo registra la condizione originale e passa a faulted
su errori inattesi/permanenti (not-ready, writer generation, lease privata,
invarianti o errori runtime); propaga la stessa condizione, conserva i campi e
blocca tutti i passi successivi, inclusa cessione. Solo ragioni recuperabili
esplicite per tipo/operazione conservano la fase. Wrong-thread e contesto già
faulted sono rifiutati fuori dal handler, senza alterare la diagnosi originale.
Nessun reset o rollback dopo mutazione; handler interno dynamic-extent.
Getter owner-only consentono diagnosi del riferimento e condizione anche a fault; non
trasferiscono proprietà o autorizzano doppia pubblicazione.

Non vi sono thread, callback, I/O, timer, retry o attese nel prodotto.
Take usa la scansione esistente ≤64 shard/128 CAS; gli altri passaggi sono
O(1), oltre alla copia batch già bounded dal writer. Work e ack fuori dalle
guard ready. Empty non autorizza park/shutdown. Catene full locali, quote,
admission, wake/park, controller FAULTED, adattamento del pool e applicazione
WAL restano da integrare. Ack non verifica effetti esterni del caller.

## Verifiche preregistrate

- Oracolo indipendente a liste: 8 configurazioni K1/4, readycapacity1/2,
  quantum1/2, 13 writer e 1000 passi ciascuna, payload unici e drain finale.
- Tutte le fasi, quota cumulativa, buffer privati/sentinelle, alias/span,
  ack stale nel batch successivo, ordine preflight, overflow senza wrap,
  cessione/adozione e impossibilità di cedere un batch/lease attivi.
- Busy di begin/pop/finish/recycle con snapshot; home corretto su scansioni
  ruotate, regressione ring full per tutti i consumer, nuova ondata senza cleanup.
- Thread reali riusati e producer vivi, shard indipendente che progredisce
  durante guard occupata, wrong-thread rifiutato prima di mutare.
- Due letture C1 con dodici punti, inventario di ogni decisione e raw coverage
  di tutti gli undici file execution, senza esclusioni o MC/DC dedotta da sb-cover.
- Dodici mutanti semantici dei soli nuovi worker files, sostituzioni uniche
  preregistrate nel driver prima delle campagne. Baseline execution completa;
  segnali OS/late failure sono worker-error, non detection. Raw baseline+12log.
- Composizione handoff/ready/worker: K1/4 × C1/3, cinque campioni ×4096cicli,
  warmup128 e GC fuori misura. Full backlog→recycle→nuova testa e room→publish;
  idle, batch ack, identità/count/status/cursor, lease e token crescenti verificati.
  Writer C+1 per shard distinti; ruolo iniziale ruotato; generazioni reali non
  azzerate per rendere costante il sink. Derivazione indipendente in appendice.
- Heap positivo, sink errato, clockzero distinto, reporter parziali e directory
  preesistente, strict COMPILE-FILE completo e self-test FASL dei C4 con avvisi fatali.
- Make check completo una volta sul codice finale; altre chat integrate prima
  del congelamento. Si ripete solo se cambia codice/base rilevante o un gate fallisce.

Ogni tentativo è registrato con record-command; dati raw/output/argv/ambiente
conservati, source snapshot prima/dopo stabili. Cache/processi separati su copia
congelata; grandi dati compressi senza perdita. I risultati osservati non
qualificano zero heap universale, throughput, P99, fairness o l'intero motore.

## Oracolo composto e mutanti esatti

Il driver fissa dodici sostituzioni uniche: owner-check-ignored, claim-cursor-stays,
claim-home-is-next, start-keeps-claimed, batch-generation-stays,
ack-stale-token-accepted, ack-keeps-pending, end-skips-finishing-latch,
end-keeps-lease, schedule-goes-idle, recycle-room-keeps-writer,
recycle-full-keeps-old-writer. I bersagli before/after sono letterali in
[`writer-worker-mutation.lisp`](../../tools/writer-worker-mutation.lisp),
verificati prima di ogni copia; non si mutano queue, writer, handoff o ready.
I difetti di forma e quelli con forma ancora valida sono entrambi inclusi.

Benchmark: in ogni shard A ha due payload e produce backlog, altri C writer
riempiono il ring prima del ricircolo full; il caller completa la testa, i
riferimenti residui e A. Un secondo ciclo room sullo stesso A ricircola
sul ring vuoto e completa il residuo. Ruolo di A ruota tra C+1 identità.
Lo score esclude i contatori assoluti di lease/batch, che vengono verificati
separatamente e persistono tra warmup, cicli e repliche.

Per M=K(C+1), derivazione del token fissata prima dell'esecuzione:
`T=K[416+115C+3C(C+1)/2]+7(C+3)K(K−1)/2+5M(M+1)/2+29+7(1 mod K)`.
Per (K,C)=(1,1)/(1,3)/(4,1)/(4,3): 578/858/2520/4084.
Le chiamate per ciclo sono `K(7C+27)+1`: 35/49/137/193.
Sink dei4096cicli, inclusi gli indici i: 10754048/11900928/18708480/25114624.
Il ricalcolo dell'autore e la lettura indipendente controlleranno la
formula contro le operazioni effettive, prima della misura congelata.
")
  (:PATH #A((51) BASE-CHAR . "spikes/out/worker-publication-functions-failed.lisp") :BYTES 18191
   :SHA256 "e97e2073f44af2987e7d4fd2faea5db6a018c5ce87c8031f1901e19f76b4d49e" :GIT-BLOB
   "1273fc314cb86d1ba56553d796d66ce56d56f865" :TEXT
   ";;;; Adattatore della sola conservazione: definizioni, nessuna pubblicazione al LOAD.
;;;; Copie binarie esclusive; descriptor originale letto separatamente dal decoded.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(in-package #:cl-user)

(defparameter *worker-publication-directory*
  #p\"spikes/results/2026-10-09-writer-worker/\")

(defun worker-leaf-p (name)
  (and (stringp name) (plusp (length name))
       (not (member name '(\".\" \"..\") :test #'string=))
       (not (find-if (lambda (character)
                       (or (zerop (char-code character))
                           (find character \"/\\\\*?[]\"))) name))))

(defun worker-read-raw-data (path)
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

(defun worker-byte-record (path)
  (list :path (namestring (pathname path))
        :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)
        :git-blob
        (string-trim '(#\\Newline #\\Space)
                     (uiop:run-program
                      (list \"git\" \"hash-object\" \"--\" (namestring (pathname path)))
                      :output :string))))

(defun worker-source-record (path)
  \"Bundle lossless di sorgenti/log UTF-8 con path, bytes, SHA256 e Git blob.\"
  (let* ((before (worker-byte-record path))
         (text (uiop:read-file-string path :external-format :utf-8))
         (octets (sb-ext:string-to-octets text :external-format :utf-8))
         (after (worker-byte-record path)))
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
    (unless (equal before (worker-byte-record path))
      (error \"Sorgente cambiata durante la verifica UTF-8: ~A\" path))
    (append before (list :text text))))

(defun worker-exclusive-output (path)
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

(defun worker-copy-exclusive (source target)
  \"Conserva esattamente i bytes originali e rifiuta destinazioni già esistenti.\"
  (let ((before (worker-byte-record source))
        (buffer (make-array 65536 :element-type '(unsigned-byte 8))))
    (with-open-file (input source :direction :input :element-type '(unsigned-byte 8))
      (with-open-stream (output (worker-exclusive-output target))
        (loop for count = (read-sequence buffer input) until (zerop count)
              do (write-sequence buffer output :end count))))
    (let ((after (worker-byte-record source)) (copy (worker-byte-record target)))
      (unless (and (equal before after)
                   (= (getf before :bytes) (getf copy :bytes))
                   (string= (getf before :sha256) (getf copy :sha256))
                   (string= (getf before :git-blob) (getf copy :git-blob)))
        (error \"Copia non lossless o sorgente cambiata: ~A -> ~A\" source target))
      copy)))

(defun worker-data-octets (data)
  \"Serializzazione unica usata sia dal preflight sia dalla scrittura bounded.\"
  (sb-ext:string-to-octets
   (with-output-to-string (stream)
     (let ((*print-readably* t) (*print-circle* nil)
           (*print-length* nil) (*print-level* nil)
           (*print-right-margin* 100) (*print-miser-width* nil))
       (write data :stream stream :pretty t) (terpri stream)))
   :external-format :utf-8))

(defun worker-stage-data (data directory)
  \"Prevalida dati UTF-8 in un tempfile esclusivo; massimo un MiB plain.
Il tempfile viene preservato se la lettura o l'uguaglianza dei dati fallisce.\"
  (let ((octets (worker-data-octets data)))
    (when (> (length octets) 1048576)
      (error \"Dati plain oltre un MiB prima della scrittura: ~D bytes.\" (length octets)))
    (multiple-value-bind (fd name)
        (sb-posix:mkstemp (namestring (merge-pathnames \".worker-data-XXXXXX\" directory)))
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

(defun worker-save-data (data path)
  \"Prevalida bytes/decoded in out, poi copia esclusivamente senza sovrascrivere.\"
  (let ((temporary (worker-stage-data data #p\"spikes/out/\")))
    (prog1 (worker-copy-exclusive temporary path)
      (unless (equalp data (arcdocdb.evidence:read-evidence path :max-expanded-bytes 1048576))
        (error \"Dati salvati diversi dai dati richiesti: ~A\" path))
      (delete-file temporary))))

(defun worker-copy-evidence (source target)
  \"Valida l'originale e il decoded copiato. Il payload conserva il nome originale.\"
  (let* ((decoded (arcdocdb.evidence:read-evidence source))
         (raw (worker-read-raw-data source))
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
    (unless (worker-leaf-p (file-namestring (pathname target)))
      (error \"Destinazione evidence senza nome leaf valido: ~A\" target))
    (when (and payload (not (worker-leaf-p payload)))
      (error \"Payload descriptor non leaf: ~S\" payload))
    (when (or (probe-file target) (and target-payload (probe-file target-payload)))
      (error \"Destinazione o payload già esistente: ~A\" target))
    ;; Il descriptor diventa visibile soltanto dopo una copia valida del payload.
    (when source-payload (worker-copy-exclusive source-payload target-payload))
    (let ((copied (worker-copy-exclusive source target)))
      (unless (and (equalp raw (worker-read-raw-data target))
                   (equalp raw (worker-read-raw-data source))
                   (equalp decoded (arcdocdb.evidence:read-evidence source))
                   (equalp decoded (arcdocdb.evidence:read-evidence target)))
        (error \"Originale/descriptor/decoded divergenti dopo copia: ~A -> ~A\" source target))
      (values decoded copied
              (and target-payload (worker-byte-record target-payload))))))

(defun worker-compact-review-results ()
  \"Compatta una copia ignored del full; il plain originale non viene modificato.
La nuova directory e tutti i file sono esclusivi. Ogni errore conserva i file
prodotti per diagnosi; il payload gzip ha un basename unico e verificato.\"
  (let* ((source #p\"spikes/out/worker-review-results-data.lisp\")
         (directory #p\"spikes/out/worker-review-results-compacted/\")
         (target (merge-pathnames (file-namestring source) directory))
         (payload-name (concatenate 'string (file-namestring source) \".gz\"))
         (payload (merge-pathnames payload-name directory))
         (before (worker-byte-record source))
         (original (arcdocdb.evidence:read-evidence source))
         (summary (arcdocdb.evidence:read-evidence
                   \"spikes/out/worker-review-summary-data.lisp\")))
    (unless (string= (getf before :sha256) (getf summary :original-sha256))
      (error \"Summary non riferito ai bytes del full originale.\"))
    (sb-posix:mkdir (namestring directory) #o700)
    (with-open-stream (output (worker-exclusive-output payload))
      (uiop:run-program (list \"gzip\" \"-n\" \"-9\" \"-c\" \"--\" (namestring source))
                        :output output :error-output :string))
    (when (> (arcdocdb.evidence:file-bytes payload) 8388608)
      (error \"Payload full compattato oltre otto MiB; file ignored preservati.\"))
    (unless (equal before (worker-byte-record source))
      (error \"Full originale cambiato durante gzip; file ignored preservati.\"))
    (let* ((descriptor
             (list :schema-version 1 :kind :compressed-evidence :codec :gzip
                   :payload payload-name :uncompressed-bytes (getf before :bytes)
                   :uncompressed-sha256 (getf before :sha256)
                   :compressed-bytes (arcdocdb.evidence:file-bytes payload)
                   :compressed-sha256 (arcdocdb.evidence:file-sha256 payload)))
           (octets (worker-data-octets descriptor)))
      (when (> (length octets) 1048576)
        (error \"Descriptor full oltre un MiB prima della scrittura.\"))
      (with-open-stream (output (worker-exclusive-output target))
        (write-sequence octets output))
      ;; READ-EVIDENCE qui è intenzionalmente distinto dalla lettura raw del
      ;; descriptor: il full espanso è 29 MB e usa il limite pubblico del reader.
      (unless (and (equalp descriptor (worker-read-raw-data target))
                   (equalp original (arcdocdb.evidence:read-evidence target))
                   (equal before (worker-byte-record source)))
        (error \"Descriptor o decoded full divergenti; originali preservati.\"))
      (format t \"Full audit compattato senza modificare il plain: ~D -> ~D bytes, SHA logico ~A.~%\"
              (getf before :bytes) (arcdocdb.evidence:file-bytes payload)
              (getf before :sha256))
      target)))

(defun worker-copy-process (record stem &key (directory *worker-publication-directory*))
  \"Copia report e conservazione con nomi flat; nessun overwrite implicito.\"
  (unless (and (worker-leaf-p record) (worker-leaf-p stem))
    (error \"Record o stem non leaf: ~S / ~S\" record stem))
  (dolist (part '(\"report\" \"conservazione\"))
    (worker-copy-evidence
     (format nil \"spikes/out/~A/~A.lisp\" record part)
     (merge-pathnames
      (format nil \"~A~A.lisp\" stem (if (string= part \"report\") \"\" \"-conservazione\"))
      directory))))

(defun worker-save-source-bundle (paths target kind &key version)
  (worker-save-data
   (append (list :schema-version 1 :kind kind)
           (when version (list :version version))
           (list :sources (mapcar #'worker-source-record paths))) target))

(defun worker-source-bundle-data (sources kind version part parts)
  (append (list :schema-version 1 :kind kind)
          (when version (list :version version))
          (list :part part :parts parts :sources sources)))

(defun worker-plan-source-bundles (paths stem kind &key version)
  \"Legge ogni sorgente intero una volta e pianifica bundle sotto un MiB.
Nessuna scrittura, neppure temporanea; i nomi sono determinati prima delle copie.
Il record conserva path/bytes/SHA256/Git blob/text originali senza frammenti.\"
  (unless (and paths (worker-leaf-p stem))
    (error \"Bundle senza sorgenti o stem leaf: ~S\" stem))
  (unless (= (length paths) (length (remove-duplicates paths :test #'equal)))
    (error \"Sorgenti duplicate nel bundle ~A.\" stem))
  (let ((groups nil) (group nil) (part-bound (length paths)))
    (dolist (path paths)
      (let* ((record (worker-source-record path))
             (candidate (append group (list record))))
        ;; Il massimo indice/numero di parti è il numero di sorgenti: riserva
        ;; esattamente lo spazio di metadata sufficiente per qualsiasi split.
        (if (<= (length (worker-data-octets
                         (worker-source-bundle-data candidate kind version
                                                    part-bound part-bound)))
                1048576)
            (setf group candidate)
            (progn
              (unless group
                (error \"Sorgente singola oltre un MiB serializzato: ~A\" path))
              (push group groups)
              (setf group (list record))
              (when (> (length (worker-data-octets
                               (worker-source-bundle-data group kind version
                                                          part-bound part-bound)))
                       1048576)
                (error \"Sorgente singola oltre un MiB serializzato: ~A\" path))))))
    (push group groups)
    (setf groups (nreverse groups))
    (loop with parts = (length groups)
          for sources in groups for part from 1
          for leaf = (if (= parts 1) (format nil \"~A.lisp\" stem)
                         (format nil \"~A-~D.lisp\" stem part))
          for data = (worker-source-bundle-data sources kind version part parts)
          for bytes = (length (worker-data-octets data))
          do (when (> bytes 1048576)
               (error \"Piano bundle oltre un MiB: ~A (~D).\" leaf bytes))
          collect (list :leaf leaf :data data :bytes bytes))))

(defun worker-validate-source-plans (plans)
  \"Verifica che i bytes conservati nel piano si riferiscano ancora ai sorgenti.\"
  (dolist (plan plans)
    (dolist (source (getf (getf plan :data) :sources))
      (let ((current (worker-byte-record (getf source :path))))
        (unless (and (= (getf source :bytes) (getf current :bytes))
                     (string= (getf source :sha256) (getf current :sha256))
                     (string= (getf source :git-blob) (getf current :git-blob)))
          (error \"Sorgente cambiata dopo il piano: ~A\" (getf source :path))))))
  t)

(defun worker-write-catalog (data target)
  \"Sostituisce soltanto il catalogo del componente, dopo staging verificato.\"
  (unless (string= (file-namestring (pathname target)) \"catalogo.lisp\")
    (error \"La sostituzione è consentita soltanto per catalogo.lisp: ~A\" target))
  (let ((previous (and (probe-file target) (arcdocdb.evidence:read-evidence target))))
    (when (and previous
               (not (and (eq (getf previous :kind) :evidence-catalog)
                         (eq (getf previous :component) :writer-worker))))
      (error \"Catalogo esistente di un altro componente: ~A\" target))
    (let* ((temporary (worker-stage-data data (uiop:pathname-directory-pathname target)))
           (before (worker-byte-record temporary)))
      (sb-posix:rename (namestring temporary) (namestring (pathname target)))
      (let ((after (worker-byte-record target)))
        (unless (and (= (getf before :bytes) (getf after :bytes))
                     (string= (getf before :sha256) (getf after :sha256))
                     (string= (getf before :git-blob) (getf after :git-blob))
                     (equalp data (arcdocdb.evidence:read-evidence target)))
          (error \"Catalogo differente dopo rename verificato: ~A\" target))
        after))))

(defun worker-refresh-catalog (base &key historical-bases
                                        (directory *worker-publication-directory*))
  \"Catalogo flat dei dati validati, path originali, hashes e Git blobs dei files.\"
  (let* ((paths (sort (directory (merge-pathnames \"*.lisp\" directory)) #'string<
                      :key #'namestring))
         (entries
           (loop for path in paths
                 unless (string= (file-namestring path) \"catalogo.lisp\")
                 collect
                 (progn
                   (unless (worker-leaf-p (file-namestring path))
                     (error \"Artifact non flat: ~A\" path))
                   (arcdocdb.evidence:read-evidence path)
                   (let ((raw (worker-read-raw-data path)))
                     (append (list :artifact (file-namestring path))
                             (worker-byte-record path)
                             (when (eq (getf raw :kind) :compressed-evidence)
                               (let ((payload (getf raw :payload)))
                                 (list :payload
                                       (append (list :artifact payload)
                                               (worker-byte-record
                                                (merge-pathnames payload directory))))))))))))
    (worker-write-catalog
     (list :schema-version 1 :kind :evidence-catalog :component :writer-worker
           :base base :historical-bases historical-bases :entries entries)
     (merge-pathnames \"catalogo.lisp\" directory))))
")
  (:PATH #A((41) BASE-CHAR . "spikes/out/worker-publication-resume.lisp") :BYTES 5553 :SHA256
   "2911f6ae6c646d025c86a39f32edc1633279a0c1bfe67a188b4704f6cf0851a1" :GIT-BLOB
   "c6c802032ca9bfc18c6fdf345b498b1a1db389bd" :TEXT
   ";;;; Ripresa della sola conservazione: LOAD definisce, non pubblica.
;;;; Il driver primo tentativo rimane intatto e il suo helper è preservato.
(load \"spikes/out/worker-publish.lisp\")

(defun worker-preflight-resume-publication (pairs plans)
  \"Controlla tutte le collisioni e ogni file esistente prima di completare copie.\"
  (let ((targets (list \"catalogo.lisp\")) (payloads nil))
    (dolist (pair pairs)
      (let* ((source (first pair)) (leaf (second pair))
             (target (worker-publication-target leaf))
             (proof (worker-evidence-byte-proof source))
             (payload (getf proof :payload-name))
             (target-payload (and payload (worker-publication-target payload))))
        (when (> (getf (getf proof :raw) :bytes) 1048576)
          (error \"Originale plain/descriptor oltre un MiB: ~A\" source))
        (when (member leaf targets :test #'string=)
          (error \"Artifact ripetuto nel manifest resume: ~A\" leaf))
        (push leaf targets)
        (when payload
          (when (or (member payload payloads :test #'string=)
                    (> (getf (getf proof :payload-record) :bytes) 8388608))
            (error \"Payload ripetuto o oltre limite nel resume: ~A\" payload))
          (push payload payloads))
        (cond
          ((probe-file target)
           (unless (worker-evidence-proofs-equal-p proof (worker-evidence-byte-proof target))
             (error \"File canonico esistente diverso: ~A; nessun overwrite.\" target)))
          ((and target-payload (probe-file target-payload))
           (unless (worker-byte-records-equal-p (getf proof :payload-record)
                                                (worker-byte-record target-payload))
             (error \"Payload canonico esistente diverso: ~A; nessun overwrite.\" target-payload))))))
    (dolist (plan plans)
      (let ((leaf (getf plan :leaf)))
        (when (or (member leaf targets :test #'string=)
                  (member leaf payloads :test #'string=))
          (error \"Bundle resume in conflitto: ~A\" leaf))
        (when (> (getf plan :bytes) 1048576) (error \"Bundle resume oltre un MiB: ~A\" leaf))
        (when (probe-file (worker-publication-target leaf))
          (worker-validate-serialized-data (getf plan :data) (worker-publication-target leaf)))
        (push leaf targets)))
    (when (intersection targets payloads :test #'string=)
      (error \"Collisione artifact/payload nel resume.\"))
    (worker-validate-source-plans plans)
    t))

(defun worker-resume-publication
    (&key (review-records *worker-review-manifest*)
          (final-processes *worker-final-process-manifest*)
          extra-processes adapter-sources)
  \"Completa il canonico parziale senza rigenerare gzip né sostituire file.
Ogni skip richiede validità reader e identità raw/expanded bytes/SHA256/Git blob.\"
  (unless (and review-records final-processes
               (find \"revisione-autore-processo\" final-processes :test #'string= :key #'second))
    (error \"Manifest finale autore/C1 necessario per resume.\"))
  (worker-validate-compacted-review-results)
  (let* ((pairs (worker-publication-pairs
                 review-records final-processes
                 (append extra-processes
                         '((\"4000548817-command-74667-0\" \"pubblicazione-fallita-processo\")))))
         (logs (worker-mutation-log-paths)) (html (worker-coverage-html-paths))
         (signal '(\"spikes/out/4000547222-worker-signal-self-test-94121/test.log\"
                   \"spikes/out/4000547222-worker-signal-self-test-94121/tools/writer-worker-isolated-build.lisp\"))
         (adapters (append *worker-adapter-manifest*
                           '(\"spikes/out/worker-publication-functions-failed.lisp\"
                             \"spikes/out/worker-publication-resume.lisp\")
                           adapter-sources))
         (plans (append
                 (worker-plan-source-bundles logs \"mutazioni-log\" :raw-mutation-logs)
                 (worker-plan-source-bundles '(\"spikes/out/worker-coverage/coverage-state.lisp\")
                                             \"copertura-native\" :raw-coverage-native
                                             :version :eleven-execution-files)
                 (worker-plan-source-bundles html \"copertura-html\" :raw-coverage-html
                                             :version :eleven-execution-files)
                 (worker-plan-source-bundles signal \"segnale-os-originali\" :process-signal-raw-sources)
                 (worker-plan-source-bundles adapters \"sorgenti-adattatori\" :verification-adapter-sources)))
         (staged nil))
    (worker-preflight-resume-publication pairs plans)
    (setf staged (loop for plan in plans collect (worker-stage-data (getf plan :data) #p\"spikes/out/\")))
    (worker-validate-source-plans plans)
    (ensure-directories-exist (worker-publication-target \"catalogo.lisp\"))
    (dolist (pair pairs)
      (worker-copy-evidence-resume (first pair) (worker-publication-target (second pair))))
    (worker-validate-source-plans plans)
    (loop for plan in plans for temporary in staged
          for target = (worker-publication-target (getf plan :leaf))
          do (worker-copy-evidence-resume temporary target)
             (worker-validate-serialized-data (getf plan :data) target)
             (delete-file temporary))
    (worker-validate-source-plans plans)
    (format t \"Resume completato: ~D coppie, ~D bundle, 13 log, native e 12 HTML. Nessun file esistente sovrascritto.~%\"
            (length pairs) (length plans))
    t))
")
  (:PATH #A((36) BASE-CHAR . "spikes/out/worker-publish-final.lisp") :BYTES 1322 :SHA256
   "e034fbb928019fb2e7ab6ab6e7b350bdec421daddb1ef13cd43793773b210099" :GIT-BLOB
   "e70b319d0c0431bef4ef79736c0701c5d56f77df" :TEXT "(load \"spikes/out/worker-publish.lisp\")
(worker-run-publication
 :final-processes '((\"4000548709-command-71943-0\" \"revisione-autore-processo\"))
 :extra-processes '((\"4000548460-command-59017-0\" \"integrazione-summary-processo\")
                    (\"4000548562-command-61816-0\" \"integrazione-copia-processo\")
                    (\"4000548698-command-70081-0\" \"integrazione-addendum-copia-processo\"))
 :adapter-sources '(\"spikes/out/worker-publish-final.lisp\"
                    \"spikes/out/worker-attach-integration-addendum.lisp\"
                    \"spikes/out/worker-integration-preparation.json\"
                    \"spikes/out/worker-integration-scope.py\"
                    \"spikes/out/worker-integration-scope.json\"
                    \"spikes/out/worker-integration-summary.lisp\"
                    \"spikes/out/worker-integration-summary.lisp-data\"
                    \"spikes/out/worker-integration-copy.py\"
                    \"spikes/out/worker-integration-copy-receipt.json\"
                    \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/arcdocdb.asd\"
                    \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/README.md\"))
(worker-run-integration-evidence)
(worker-run-review-process-evidence)
")
  (:PATH #A((43) BASE-CHAR . "spikes/out/worker-publish-resume-final.lisp") :BYTES 2184 :SHA256
   "2a056508cdda1560c482d7bb28183320fd713722965b224d218e0c755f1e92a0" :GIT-BLOB
   "e0ed410a80af4a384ec1d232c49eace2ed06ab57" :TEXT
   "(load \"spikes/out/worker-publication-resume.lisp\")
(setf *worker-data-manifest*
 (append *worker-data-manifest*
 '((\"spikes/out/worker-publication-independent-audit-4000549513-15040/report.lisp\" \"pubblicazione-fix-audit-dati.lisp\"))))
(worker-resume-publication
 :final-processes '((\"4000548709-command-71943-0\" \"revisione-autore-processo\"))
 :extra-processes '((\"4000548460-command-59017-0\" \"integrazione-summary-processo\")
                    (\"4000548562-command-61816-0\" \"integrazione-copia-processo\")
                    (\"4000548698-command-70081-0\" \"integrazione-addendum-copia-processo\")
                    (\"4000549499-command-13945-0\" \"pubblicazione-ripresa-load-processo\")
                    (\"4000549424-command-9085-0\" \"pubblicazione-fix-audit-fallito-processo\")
                    (\"4000549512-command-14958-0\" \"pubblicazione-fix-audit-processo\")
                    (\"4000549715-command-34672-0\" \"pubblicazione-fix-audit-summary-processo\"))
 :adapter-sources '(\"spikes/out/worker-publish-final.lisp\"
                    \"spikes/out/worker-publish-resume-final.lisp\"
                    \"spikes/out/worker-publication-independent-audit.lisp\"
                    \"spikes/out/worker-publication-independent-audit-v2.lisp\"
                    \"spikes/out/worker-publication-independent-audit-summary.lisp\"
                    \"spikes/out/worker-attach-integration-addendum.lisp\"
                    \"spikes/out/worker-integration-preparation.json\"
                    \"spikes/out/worker-integration-scope.py\"
                    \"spikes/out/worker-integration-scope.json\"
                    \"spikes/out/worker-integration-summary.lisp\"
                    \"spikes/out/worker-integration-summary.lisp-data\"
                    \"spikes/out/worker-integration-copy.py\"
                    \"spikes/out/worker-integration-copy-receipt.json\"
                    \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/arcdocdb.asd\"
                    \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/README.md\"))
(worker-run-integration-evidence)
(worker-run-review-process-evidence)
")
  (:PATH #A((52) BASE-CHAR . "spikes/out/worker-publication-independent-audit.lisp") :BYTES 13710
   :SHA256 "40e1664e957deb3544270329e1006fde7795ea278a2e7058b2e18622f96dfe24" :GIT-BLOB
   "1d6f8066f81e65002e6849a16431511e6ca2c58c" :TEXT "(require :asdf)
(require :sb-posix)
(load \"spikes/out/worker-publication-functions.lisp\")

(defparameter *audit-root* (truename \"./\"))
(defparameter *audit-helper-before* (worker-byte-record \"spikes/out/worker-publication-functions.lisp\"))
(defparameter *audit-directory*
  (merge-pathnames (format nil \"spikes/out/worker-publication-independent-audit-~D-~D/\"
                          (get-universal-time) (sb-posix:getpid)) *audit-root*))
(sb-posix:mkdir (namestring *audit-directory*) #o700)
(defparameter *audit-results* nil)

(defun audit-write-octets (path octets)
  (with-open-stream (out (worker-exclusive-output path)) (write-sequence octets out))
  path)
(defun audit-write-text (path text)
  (audit-write-octets path (sb-ext:string-to-octets text :external-format :utf-8)))
(defun audit-bytes (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (assert (= (length bytes) (read-sequence bytes in))) bytes)))
(defun audit-dir (leaf)
  (let ((directory (merge-pathnames (format nil \"~A/\" leaf) *audit-directory*)))
    (sb-posix:mkdir (namestring directory) #o700) directory))
(defun audit-pass (name &rest metadata)
  (push (append (list :name name :status :passed) metadata) *audit-results*)
  (format t \"AUDIT-PASS ~A~%\" name))
(defun audit-reject-unchanged (name thunk paths)
  (let ((before (mapcar #'worker-byte-record paths)) (caught nil))
    (handler-case (funcall thunk) (error (condition) (setf caught (princ-to-string condition))))
    (assert caught)
    (assert (equal before (mapcar #'worker-byte-record paths)))
    (audit-pass name :diagnostic caught :unchanged before)))
(defun audit-same (source target)
  (assert (equalp (audit-bytes source) (audit-bytes target)))
  (assert (worker-evidence-proofs-equal-p (worker-evidence-byte-proof source)
                                       (worker-evidence-byte-proof target))))

;; Three #: symbols include a reader label sharing the first identity. Reading
;; twice must produce different identities despite exact same original bytes.
(let* ((source (merge-pathnames \"shared-gensyms.lisp\" *audit-directory*))
       (copied (merge-pathnames \"shared-gensyms-copy.lisp\" *audit-directory*))
       (text (format nil \"(:schema-version 1 :kind :audit-fixture :symbols (#1=#:A #1# #:A))~%\")))
  (audit-write-text source text)
  (let ((one (arcdocdb.evidence:read-evidence source))
        (two (arcdocdb.evidence:read-evidence source)))
    (assert (not (equalp one two)))
    (assert (eq (first (getf one :symbols)) (second (getf one :symbols))))
    (assert (not (eq (first (getf one :symbols)) (third (getf one :symbols))))))
  (worker-copy-evidence source copied)
  (audit-same source copied)
  (audit-pass :copy-shared-and-repeated-uninterned-symbols :source (worker-byte-record source)
              :copy (worker-byte-record copied))
  (let ((before (worker-byte-record copied)))
    (assert (eq :verified-existing (worker-copy-evidence-resume source copied)))
    (assert (equal before (worker-byte-record copied)))
    (audit-pass :resume-identical-plain-no-clobber))
  (audit-reject-unchanged :exclusive-copy-existing-no-clobber
                          (lambda () (worker-copy-evidence source copied)) (list copied))
  (let* ((g (make-symbol \"A\"))
         (data (list :schema-version 1 :kind :serialized-gensyms :symbols (list g g (make-symbol \"A\"))))
         (expected (worker-data-octets data))
         (staged (worker-stage-data data *audit-directory*))
         (saved (merge-pathnames \"saved-gensyms.lisp\" *audit-directory*)))
    (assert (equalp expected (audit-bytes staged)))
    (assert (not (equalp data (arcdocdb.evidence:read-evidence staged))))
    (worker-save-data data saved)
    (assert (equalp expected (audit-bytes saved)))
    (audit-pass :stage-and-save-uninterned-symbols :staged (worker-byte-record staged)
                :saved (worker-byte-record saved))
    (audit-reject-unchanged :save-existing-no-clobber
                            (lambda () (worker-save-data data saved)) (list saved))
    (let ((wrong (merge-pathnames \"wrong-serialized.lisp\" *audit-directory*)))
      (audit-write-text wrong \"(:schema-version 1 :kind :wrong)\")
      (audit-reject-unchanged :validate-wrong-serialized-bytes
                              (lambda () (worker-validate-serialized-data data wrong)) (list wrong))))
  (dolist (entry '((\"different-valid.lisp\" \"(:schema-version 1 :kind :audit-fixture :symbols (#:B #:B #:B))\")
                   (\"malformed.lisp\" \"(:schema-version 1 :kind\")))
    (let ((target (merge-pathnames (first entry) *audit-directory*)))
      (audit-write-text target (second entry))
      (audit-reject-unchanged (if (string= (first entry) \"malformed.lisp\")
                                :resume-malformed-plain :resume-different-valid-plain)
                              (lambda () (worker-copy-evidence-resume source target)) (list target))))
  ;; Gzip cases independently use original source bytes and descriptor hashes.
  (let* ((source-dir (audit-dir \"gzip-source\"))
         (payload (merge-pathnames \"payload.lisp.gz\" source-dir))
         (descriptor (merge-pathnames \"source.lisp\" source-dir)))
    (with-open-stream (out (worker-exclusive-output payload))
      (uiop:run-program (list \"gzip\" \"-n\" \"-9\" \"-c\" \"--\" (namestring source))
                        :output out :error-output :string))
    (worker-save-data
     (list :schema-version 1 :kind :compressed-evidence :codec :gzip :payload \"payload.lisp.gz\"
           :uncompressed-bytes (arcdocdb.evidence:file-bytes source)
           :uncompressed-sha256 (arcdocdb.evidence:file-sha256 source)
           :compressed-bytes (arcdocdb.evidence:file-bytes payload)
           :compressed-sha256 (arcdocdb.evidence:file-sha256 payload)) descriptor)
    (let* ((target-dir (audit-dir \"gzip-copy\"))
           (target (merge-pathnames \"copy.lisp\" target-dir))
           (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir)))
      (assert (eq :copied (worker-copy-evidence-resume descriptor target)))
      (audit-same descriptor target)
      (let ((records (mapcar #'worker-byte-record (list target target-payload))))
        (assert (eq :verified-existing (worker-copy-evidence-resume descriptor target)))
        (assert (equal records (mapcar #'worker-byte-record (list target target-payload)))))
      (audit-pass :gzip-copy-and-resume-uninterned-symbols))
    (let* ((target-dir (audit-dir \"gzip-payload-only\"))
           (target (merge-pathnames \"copy.lisp\" target-dir))
           (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir)))
      (worker-copy-exclusive payload target-payload)
      (let ((before (worker-byte-record target-payload)))
        (assert (eq :completed-descriptor (worker-copy-evidence-resume descriptor target)))
        (assert (equal before (worker-byte-record target-payload))))
      (audit-same descriptor target)
      (audit-pass :gzip-payload-only-resume-without-overwrite))
    (dolist (has-descriptor '(nil t))
      (let* ((target-dir (audit-dir (if has-descriptor \"gzip-corrupt-complete\" \"gzip-corrupt-payload-only\")))
             (target (merge-pathnames \"copy.lisp\" target-dir))
             (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir))
             (corrupt (audit-bytes payload)))
        (setf (aref corrupt 0) (logxor 1 (aref corrupt 0)))
        (audit-write-octets target-payload corrupt)
        (when has-descriptor (worker-copy-exclusive descriptor target))
        (audit-reject-unchanged
         (if has-descriptor :resume-corrupt-gzip-complete :resume-corrupt-gzip-payload-only)
         (lambda () (worker-copy-evidence-resume descriptor target))
         (if has-descriptor (list target target-payload) (list target-payload)))
        (unless has-descriptor (assert (not (probe-file target))))))))
  (let* ((catalog-dir (audit-dir \"catalog\"))
         (catalog (merge-pathnames \"catalogo.lisp\" catalog-dir))
         (data (list :schema-version 1 :kind :evidence-catalog :component :writer-worker
                     :version 1 :symbols (list (make-symbol \"A\") (make-symbol \"A\")))))
    (worker-write-catalog data catalog)
    (assert (equalp (worker-data-octets data) (audit-bytes catalog)))
    (setf (getf data :version) 2)
    (worker-write-catalog data catalog)
    (assert (equalp (worker-data-octets data) (audit-bytes catalog)))
    (audit-pass :catalog-uninterned-symbols-and-authorized-replacement))
  ;; Exercise hardcoded compaction paths in a fixture cwd, never the real stage.
  (let ((compact-root (audit-dir \"compact-root\")))
    (ensure-directories-exist (merge-pathnames \"spikes/out/fixture\" compact-root))
    (uiop:with-current-directory (compact-root)
      (worker-copy-exclusive source \"spikes/out/worker-review-results-data.lisp\")
      (worker-save-data (list :schema-version 1 :kind :summary
                              :original-sha256 (arcdocdb.evidence:file-sha256 source))
                        \"spikes/out/worker-review-summary-data.lisp\")
      (let* ((compact (worker-compact-review-results))
             (before (worker-evidence-byte-proof compact)))
        (worker-validate-compacted-review-results)
        (assert (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof compact)))
        (assert (worker-byte-records-equal-p
                 (getf (worker-evidence-byte-proof source) :expanded)
                 (getf before :expanded)))
        (audit-pass :compact-and-reuse-uninterned-symbols :proof before))))))

;; Verify the interrupted canonical copies readonly against independent mapping.
(let* ((directory #p\"spikes/results/2026-10-09-writer-worker/\")
       (processes
         '((\"4000545928-command-51771-0\" \"strict-iniziale-storico-processo\")
           (\"4000547204-command-93189-0\" \"check-finale-processo\")
           (\"4000547204-command-93188-0\" \"copertura-processo\")
           (\"4000547249-command-95826-0\" \"copertura-export-processo\")
           (\"4000547329-command-479-0\" \"probe-root-processo\")
           (\"4000547221-command-94073-0\" \"bench-self-test-processo\")
           (\"4000547221-command-94074-0\" \"mutazioni-self-test-processo\")
           (\"4000547268-command-97067-0\" \"mutazioni-processo\")
           (\"4000547268-command-97066-0\" \"allocazioni-processo\")
           (\"4000547296-command-98426-0\" \"revisione-copertura-processo\")
           (\"4000547904-command-30631-0\" \"pubblicazione-piano-processo\")
           (\"4000547596-command-16195-0\" \"revisione-mappa-sorgenti-processo\")
           (\"4000547809-command-24892-0\" \"revisione-summary-fallito-processo\")
           (\"4000547879-command-29495-0\" \"revisione-summary-processo\")
           (\"4000548017-command-37007-0\" \"scope-integrazione-processo\")
           (\"4000548048-command-40192-0\" \"check-integrazione-processo\")
           (\"4000548534-command-60644-0\" \"revisione-indipendente-integrazione-processo\")
           (\"4000548709-command-71943-0\" \"revisione-autore-processo\")
           (\"4000548460-command-59017-0\" \"integrazione-summary-processo\")
           (\"4000548562-command-61816-0\" \"integrazione-copia-processo\")
           (\"4000548698-command-70081-0\" \"integrazione-addendum-copia-processo\")))
       (pairs
         (append
          (loop for (id stem) in processes append
            (loop for part in '(\"report\" \"conservazione\")
                  collect (list (format nil \"spikes/out/~A/~A.lisp\" id part)
                                (format nil \"~A~A.lisp\" stem
                                        (if (string= part \"report\") \"\" \"-conservazione\")))))
          '((\"spikes/out/worker-coverage-export.lisp\" \"copertura-grezza.lisp\")
            (\"spikes/out/worker-publication-unrecorded-planning-data.lisp\" \"pubblicazione-piano-tentativo-non-registrato.lisp\")
            (\"spikes/out/worker-review-coverage-data.lisp\" \"revisione-copertura-dati.lisp\")
            (\"spikes/out/worker-review-forms-data.lisp\" \"revisione-mappa-sorgenti-dati.lisp\"))))
       (before (directory (merge-pathnames \"*.lisp\" directory))) (proofs nil))
  (assert (= 46 (length before) (length pairs)))
  (dolist (pair pairs)
    (let* ((source (first pair)) (target (merge-pathnames (second pair) directory))
           (source-before (worker-evidence-byte-proof source))
           (target-before (worker-evidence-byte-proof target)))
      (assert (equalp (audit-bytes source) (audit-bytes target)))
      (assert (worker-evidence-proofs-equal-p source-before target-before))
      (assert (worker-evidence-proofs-equal-p source-before (worker-evidence-byte-proof source)))
      (assert (worker-evidence-proofs-equal-p target-before (worker-evidence-byte-proof target)))
      (push (list :source source :target (namestring target) :source-proof source-before
                  :target-proof target-before) proofs)))
  (assert (equal before (directory (merge-pathnames \"*.lisp\" directory))))
  (audit-pass :canonical-interrupted-copies-byte-identical :count (length pairs)
              :proofs (nreverse proofs)))
(assert (equal *audit-helper-before* (worker-byte-record \"spikes/out/worker-publication-functions.lisp\")))
(worker-save-data (list :schema-version 1 :kind :independent-publication-byte-audit
                        :status :passed :helper *audit-helper-before*
                        :adapter (worker-byte-record \"spikes/out/worker-publication-independent-audit.lisp\")
                        :results (nreverse *audit-results*))
                  (merge-pathnames \"report.lisp\" *audit-directory*))
(format t \"INDEPENDENT-PUBLICATION-AUDIT-PASS ~D cases; report ~A~%\"
        (length *audit-results*) (merge-pathnames \"report.lisp\" *audit-directory*))
")
  (:PATH #A((55) BASE-CHAR . "spikes/out/worker-publication-independent-audit-v2.lisp") :BYTES
   13788 :SHA256 "7683c28c700b6af33e96f13981f2589d351336f86f7a62079bb63a58ef40b04c" :GIT-BLOB
   "c38df7cc0a62072b3c818fa93bfdd37e6a44593d" :TEXT "(require :asdf)
(require :sb-posix)
(load \"spikes/out/worker-publication-functions.lisp\")

(defparameter *audit-root* (truename \"./\"))
(defparameter *audit-helper-before* (worker-byte-record \"spikes/out/worker-publication-functions.lisp\"))
(defparameter *audit-directory*
  (merge-pathnames (format nil \"spikes/out/worker-publication-independent-audit-~D-~D/\"
                          (get-universal-time) (sb-posix:getpid)) *audit-root*))
(sb-posix:mkdir (namestring *audit-directory*) #o700)
(defparameter *audit-results* nil)

(defun audit-write-octets (path octets)
  (with-open-stream (out (worker-exclusive-output path)) (write-sequence octets out))
  path)
(defun audit-write-text (path text)
  (audit-write-octets path (sb-ext:string-to-octets text :external-format :utf-8)))
(defun audit-bytes (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (assert (= (length bytes) (read-sequence bytes in))) bytes)))
(defun audit-dir (leaf)
  (let ((directory (merge-pathnames (format nil \"~A/\" leaf) *audit-directory*)))
    (sb-posix:mkdir (namestring directory) #o700) directory))
(defun audit-pass (name &rest metadata)
  (push (append (list :name name :status :passed) metadata) *audit-results*)
  (format t \"AUDIT-PASS ~A~%\" name))
(defun audit-reject-unchanged (name thunk paths)
  (let ((before (mapcar #'worker-byte-record paths)) (caught nil))
    (handler-case (funcall thunk) (error (condition) (setf caught (princ-to-string condition))))
    (assert caught)
    (assert (equal before (mapcar #'worker-byte-record paths)))
    (audit-pass name :diagnostic caught :unchanged before)))
(defun audit-same (source target)
  (assert (equalp (audit-bytes source) (audit-bytes target)))
  (assert (worker-evidence-proofs-equal-p (worker-evidence-byte-proof source)
                                       (worker-evidence-byte-proof target))))

;; Three #: symbols include a reader label sharing the first identity. Reading
;; twice must produce different identities despite exact same original bytes.
(let* ((source (merge-pathnames \"shared-gensyms.lisp\" *audit-directory*))
       (copied (merge-pathnames \"shared-gensyms-copy.lisp\" *audit-directory*))
       (text (format nil \"(:schema-version 1 :kind :audit-fixture :symbols (#1=#:A #1# #:A))~%\")))
  (audit-write-text source text)
  (let ((one (arcdocdb.evidence:read-evidence source))
        (two (arcdocdb.evidence:read-evidence source)))
    (assert (not (equalp one two)))
    (assert (eq (first (getf one :symbols)) (second (getf one :symbols))))
    (assert (not (eq (first (getf one :symbols)) (third (getf one :symbols))))))
  (worker-copy-evidence source copied)
  (audit-same source copied)
  (audit-pass :copy-shared-and-repeated-uninterned-symbols :source (worker-byte-record source)
              :copy (worker-byte-record copied))
  (let ((before (worker-byte-record copied)))
    (assert (eq :verified-existing (worker-copy-evidence-resume source copied)))
    (assert (equal before (worker-byte-record copied)))
    (audit-pass :resume-identical-plain-no-clobber))
  (audit-reject-unchanged :exclusive-copy-existing-no-clobber
                          (lambda () (worker-copy-evidence source copied)) (list copied))
  (let* ((g (make-symbol \"A\"))
         (data (list :schema-version 1 :kind :serialized-gensyms :symbols (list g g (make-symbol \"A\"))))
         (expected (worker-data-octets data))
         (staged (worker-stage-data data *audit-directory*))
         (saved (merge-pathnames \"saved-gensyms.lisp\" *audit-directory*)))
    (assert (equalp expected (audit-bytes staged)))
    (assert (not (equalp data (arcdocdb.evidence:read-evidence staged))))
    (worker-save-data data saved)
    (assert (equalp expected (audit-bytes saved)))
    (audit-pass :stage-and-save-uninterned-symbols :staged (worker-byte-record staged)
                :saved (worker-byte-record saved))
    (audit-reject-unchanged :save-existing-no-clobber
                            (lambda () (worker-save-data data saved)) (list saved))
    (let ((wrong (merge-pathnames \"wrong-serialized.lisp\" *audit-directory*)))
      (audit-write-text wrong \"(:schema-version 1 :kind :wrong)\")
      (audit-reject-unchanged :validate-wrong-serialized-bytes
                              (lambda () (worker-validate-serialized-data data wrong)) (list wrong))))
  (dolist (entry '((\"different-valid.lisp\" \"(:schema-version 1 :kind :audit-fixture :symbols (#:B #:B #:B))\")
                   (\"malformed.lisp\" \"(:schema-version 1 :kind\")))
    (let ((target (merge-pathnames (first entry) *audit-directory*)))
      (audit-write-text target (second entry))
      (audit-reject-unchanged (if (string= (first entry) \"malformed.lisp\")
                                :resume-malformed-plain :resume-different-valid-plain)
                              (lambda () (worker-copy-evidence-resume source target)) (list target))))
  ;; Gzip cases independently use original source bytes and descriptor hashes.
  (let* ((source-dir (audit-dir \"gzip-source\"))
         (payload (merge-pathnames \"payload.lisp.gz\" source-dir))
         (descriptor (merge-pathnames \"source.lisp\" source-dir)))
    (with-open-stream (out (worker-exclusive-output payload))
      (uiop:run-program (list \"gzip\" \"-n\" \"-9\" \"-c\" \"--\" (namestring source))
                        :output out :error-output :string))
    (audit-write-octets descriptor
     (worker-data-octets
      (list :schema-version 1 :kind :compressed-evidence :codec :gzip :payload \"payload.lisp.gz\"
            :uncompressed-bytes (arcdocdb.evidence:file-bytes source)
            :uncompressed-sha256 (arcdocdb.evidence:file-sha256 source)
            :compressed-bytes (arcdocdb.evidence:file-bytes payload)
            :compressed-sha256 (arcdocdb.evidence:file-sha256 payload))))
    (worker-evidence-byte-proof descriptor)
    (let* ((target-dir (audit-dir \"gzip-copy\"))
           (target (merge-pathnames \"copy.lisp\" target-dir))
           (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir)))
      (assert (eq :copied (worker-copy-evidence-resume descriptor target)))
      (audit-same descriptor target)
      (let ((records (mapcar #'worker-byte-record (list target target-payload))))
        (assert (eq :verified-existing (worker-copy-evidence-resume descriptor target)))
        (assert (equal records (mapcar #'worker-byte-record (list target target-payload)))))
      (audit-pass :gzip-copy-and-resume-uninterned-symbols))
    (let* ((target-dir (audit-dir \"gzip-payload-only\"))
           (target (merge-pathnames \"copy.lisp\" target-dir))
           (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir)))
      (worker-copy-exclusive payload target-payload)
      (let ((before (worker-byte-record target-payload)))
        (assert (eq :completed-descriptor (worker-copy-evidence-resume descriptor target)))
        (assert (equal before (worker-byte-record target-payload))))
      (audit-same descriptor target)
      (audit-pass :gzip-payload-only-resume-without-overwrite))
    (dolist (has-descriptor '(nil t))
      (let* ((target-dir (audit-dir (if has-descriptor \"gzip-corrupt-complete\" \"gzip-corrupt-payload-only\")))
             (target (merge-pathnames \"copy.lisp\" target-dir))
             (target-payload (merge-pathnames \"payload.lisp.gz\" target-dir))
             (corrupt (audit-bytes payload)))
        (setf (aref corrupt 0) (logxor 1 (aref corrupt 0)))
        (audit-write-octets target-payload corrupt)
        (when has-descriptor (worker-copy-exclusive descriptor target))
        (audit-reject-unchanged
         (if has-descriptor :resume-corrupt-gzip-complete :resume-corrupt-gzip-payload-only)
         (lambda () (worker-copy-evidence-resume descriptor target))
         (if has-descriptor (list target target-payload) (list target-payload)))
        (unless has-descriptor (assert (not (probe-file target)))))))
  (let* ((catalog-dir (audit-dir \"catalog\"))
         (catalog (merge-pathnames \"catalogo.lisp\" catalog-dir))
         (data (list :schema-version 1 :kind :evidence-catalog :component :writer-worker
                     :version 1 :symbols (list (make-symbol \"A\") (make-symbol \"A\")))))
    (worker-write-catalog data catalog)
    (assert (equalp (worker-data-octets data) (audit-bytes catalog)))
    (setf (getf data :version) 2)
    (worker-write-catalog data catalog)
    (assert (equalp (worker-data-octets data) (audit-bytes catalog)))
    (audit-pass :catalog-uninterned-symbols-and-authorized-replacement))
  ;; Exercise hardcoded compaction paths in a fixture cwd, never the real stage.
  (let ((compact-root (audit-dir \"compact-root\")))
    (ensure-directories-exist (merge-pathnames \"spikes/out/fixture\" compact-root))
    (uiop:with-current-directory (compact-root)
      (worker-copy-exclusive source \"spikes/out/worker-review-results-data.lisp\")
      (worker-save-data (list :schema-version 1 :kind :summary
                              :original-sha256 (arcdocdb.evidence:file-sha256 source))
                        \"spikes/out/worker-review-summary-data.lisp\")
      (let* ((compact (worker-compact-review-results))
             (before (worker-evidence-byte-proof compact)))
        (worker-validate-compacted-review-results)
        (assert (worker-evidence-proofs-equal-p before (worker-evidence-byte-proof compact)))
        (assert (worker-byte-records-equal-p
                 (getf (worker-evidence-byte-proof source) :expanded)
                 (getf before :expanded)))
        (audit-pass :compact-and-reuse-uninterned-symbols :proof before)))))

;; Verify the interrupted canonical copies readonly against independent mapping.
(let* ((directory #p\"spikes/results/2026-10-09-writer-worker/\")
       (processes
         '((\"4000545928-command-51771-0\" \"strict-iniziale-storico-processo\")
           (\"4000547204-command-93189-0\" \"check-finale-processo\")
           (\"4000547204-command-93188-0\" \"copertura-processo\")
           (\"4000547249-command-95826-0\" \"copertura-export-processo\")
           (\"4000547329-command-479-0\" \"probe-root-processo\")
           (\"4000547221-command-94073-0\" \"bench-self-test-processo\")
           (\"4000547221-command-94074-0\" \"mutazioni-self-test-processo\")
           (\"4000547268-command-97067-0\" \"mutazioni-processo\")
           (\"4000547268-command-97066-0\" \"allocazioni-processo\")
           (\"4000547296-command-98426-0\" \"revisione-copertura-processo\")
           (\"4000547904-command-30631-0\" \"pubblicazione-piano-processo\")
           (\"4000547596-command-16195-0\" \"revisione-mappa-sorgenti-processo\")
           (\"4000547809-command-24892-0\" \"revisione-summary-fallito-processo\")
           (\"4000547879-command-29495-0\" \"revisione-summary-processo\")
           (\"4000548017-command-37007-0\" \"scope-integrazione-processo\")
           (\"4000548048-command-40192-0\" \"check-integrazione-processo\")
           (\"4000548534-command-60644-0\" \"revisione-indipendente-integrazione-processo\")
           (\"4000548709-command-71943-0\" \"revisione-autore-processo\")
           (\"4000548460-command-59017-0\" \"integrazione-summary-processo\")
           (\"4000548562-command-61816-0\" \"integrazione-copia-processo\")
           (\"4000548698-command-70081-0\" \"integrazione-addendum-copia-processo\")))
       (pairs
         (append
          (loop for (id stem) in processes append
            (loop for part in '(\"report\" \"conservazione\")
                  collect (list (format nil \"spikes/out/~A/~A.lisp\" id part)
                                (format nil \"~A~A.lisp\" stem
                                        (if (string= part \"report\") \"\" \"-conservazione\")))))
          '((\"spikes/out/worker-coverage-export.lisp\" \"copertura-grezza.lisp\")
            (\"spikes/out/worker-publication-unrecorded-planning-data.lisp\" \"pubblicazione-piano-tentativo-non-registrato.lisp\")
            (\"spikes/out/worker-review-coverage-data.lisp\" \"revisione-copertura-dati.lisp\")
            (\"spikes/out/worker-review-forms-data.lisp\" \"revisione-mappa-sorgenti-dati.lisp\"))))
       (before (directory (merge-pathnames \"*.lisp\" directory))) (proofs nil))
  (assert (= 46 (length before) (length pairs)))
  (dolist (pair pairs)
    (let* ((source (first pair)) (target (merge-pathnames (second pair) directory))
           (source-before (worker-evidence-byte-proof source))
           (target-before (worker-evidence-byte-proof target)))
      (assert (equalp (audit-bytes source) (audit-bytes target)))
      (assert (worker-evidence-proofs-equal-p source-before target-before))
      (assert (worker-evidence-proofs-equal-p source-before (worker-evidence-byte-proof source)))
      (assert (worker-evidence-proofs-equal-p target-before (worker-evidence-byte-proof target)))
      (push (list :source source :target (namestring target) :source-proof source-before
                  :target-proof target-before) proofs)))
  (assert (equal before (directory (merge-pathnames \"*.lisp\" directory))))
  (audit-pass :canonical-interrupted-copies-byte-identical :count (length pairs)
              :proofs (nreverse proofs)))
(assert (equal *audit-helper-before* (worker-byte-record \"spikes/out/worker-publication-functions.lisp\")))
(worker-save-data (list :schema-version 1 :kind :independent-publication-byte-audit
                        :status :passed :helper *audit-helper-before*
                        :adapter (worker-byte-record \"spikes/out/worker-publication-independent-audit-v2.lisp\")
                        :results (nreverse *audit-results*))
                  (merge-pathnames \"report.lisp\" *audit-directory*))
(format t \"INDEPENDENT-PUBLICATION-AUDIT-PASS ~D cases; report ~A~%\"
        (length *audit-results*) (merge-pathnames \"report.lisp\" *audit-directory*))
")
  (:PATH #A((60) BASE-CHAR . "spikes/out/worker-publication-independent-audit-summary.lisp") :BYTES
   2109 :SHA256 "645e730025fd64600f6ccb7211604ab8e001ebc043eadfb89a84bdcfb0f05772" :GIT-BLOB
   "48681cb4667611bf3a24c2540ca21ce5cd21a063" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(let* ((process (arcdocdb.evidence:read-evidence \"spikes/out/4000549512-command-14958-0/report.lisp\"))
       (data-path \"spikes/out/worker-publication-independent-audit-4000549513-15040/report.lisp\")
       (data (arcdocdb.evidence:read-evidence data-path))
       (cases (getf data :results))
       (expected '(:copy-shared-and-repeated-uninterned-symbols
                   :resume-identical-plain-no-clobber :exclusive-copy-existing-no-clobber
                   :stage-and-save-uninterned-symbols :save-existing-no-clobber
                   :validate-wrong-serialized-bytes :resume-different-valid-plain
                   :resume-malformed-plain :gzip-copy-and-resume-uninterned-symbols
                   :gzip-payload-only-resume-without-overwrite
                   :resume-corrupt-gzip-payload-only :resume-corrupt-gzip-complete
                   :catalog-uninterned-symbols-and-authorized-replacement
                   :compact-and-reuse-uninterned-symbols
                   :canonical-interrupted-copies-byte-identical))
       (canonical (find :canonical-interrupted-copies-byte-identical cases
                        :key (lambda (entry) (getf entry :name)))))
  (assert (and (eq :ok (getf process :status)) (eq :stable (getf process :source-consistency))
               (zerop (getf process :exit-code)) (eq :passed (getf data :status))))
  (assert (equal expected (mapcar (lambda (entry) (getf entry :name)) cases)))
  (assert (every (lambda (entry) (eq :passed (getf entry :status))) cases))
  (assert (= 15 (length cases)))
  (assert (= 46 (getf canonical :count) (length (getf canonical :proofs))))
  (format t \"INDEPENDENT-PUBLICATION-AUDIT-PROJECTION-PASS 15 cases, 46 canonical copies, process OK/STABLE/exit0; data ~A SHA256 ~A.~%The original final stdout counter is 1 because NREVERSE left its global list head at the old tail; the saved report preserves all 15 results. This projection rereads existing records only; no fixture or product campaign repeated.~%\"
          data-path (arcdocdb.evidence:file-sha256 data-path)))
")
  (:PATH #A((50) BASE-CHAR . "spikes/out/worker-attach-integration-addendum.lisp") :BYTES 810
   :SHA256 "2b655c6da5fd090ea8a0414f14ef454ef7abdc1c80f1dedd8226178bdef7da3c" :GIT-BLOB
   "b8f6b173ca73bf1732b80080e5e36d31aeb630f2" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(let ((root #p\"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/\"))
  (dolist (name '(\"worker-c1-integration-addendum.lisp\" \"worker-c1-integration-addendum-read.lisp\"))
    (worker-copy-exclusive (merge-pathnames (format nil \"spikes/out/~A\" name) root)
                           (format nil \"spikes/out/~A\" name)))
  (let ((id \"4000548534-command-60644-0\"))
    (dolist (name '(\"report.lisp\" \"conservazione.lisp\"))
      (let* ((relative (format nil \"spikes/out/~A/~A\" id name)) (target (pathname relative)))
        (ensure-directories-exist target)
        (worker-copy-evidence (merge-pathnames relative root) target))))
  (format t \"Addendum indipendente e processo conservati con copie esclusive verificate.~%\"))
")
  (:PATH #A((46) BASE-CHAR . "spikes/out/worker-integration-preparation.json") :BYTES 25332 :SHA256
   "b4f25aa7205b6140a0d752b9677f159069b43394ff05402ececabe46c81bee19" :GIT-BLOB
   "20143f6485c6596b8de05df2a40376b2f1c67ec6" :TEXT "{
  \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB\",
  \"v1\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6\",
  \"primary\": \"/Users/gpicchiarelli/Documents/ArcDocDB\",
  \"integration\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc\",
  \"baseline\": \"cf6091367853ec311fed7b05961a2812fd05a8f1\",
  \"upstream\": \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\",
  \"clone_stdout\": \"\",
  \"clone_stderr\": \"Cloning into '/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc'...\\ndone.\\n\",
  \"clone_exit_code\": 0,
  \"checkout_stdout\": \"\",
  \"checkout_stderr\": \"HEAD is now at e2f7a75 Merge pull request #3 from gpicchiarelli/codex/recovery-inventory\\n\",
  \"checkout_exit_code\": 0,
  \"owned_files\": [
    \"arcdocdb.asd\",
    \"src/execution/package.lisp\",
    \"src/execution/worker-types.lisp\",
    \"src/execution/worker-boundary.lisp\",
    \"src/execution/worker-claim.lisp\",
    \"src/execution/worker-run.lisp\",
    \"tests/execution/worker.lisp\",
    \"tools/writer-worker-bench.lisp\",
    \"tools/writer-worker-mutation.lisp\",
    \"docs/implementazione/writer-worker-metodo.md\",
    \"docs/implementazione/writer-worker.md\",
    \"docs/implementazione/writer-worker-decisioni.md\",
    \"docs/implementazione/writer-worker-risultati.md\",
    \"docs/implementazione/writer-worker-revisione.md\",
    \"docs/implementazione/README.md\",
    \"docs/affidabilita/copertura-eccezioni.md\"
  ],
  \"stub_files\": [
    \"docs/affidabilita/copertura-eccezioni.md\",
    \"docs/implementazione/writer-worker-decisioni.md\",
    \"docs/implementazione/writer-worker-revisione.md\",
    \"docs/implementazione/writer-worker-risultati.md\"
  ],
  \"merges\": [
    {
      \"file\": \"arcdocdb.asd\",
      \"command\": [
        \"git\",
        \"merge-file\",
        \"-p\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/ours\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/base\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/theirs\"
      ],
      \"exit_code\": 0,
      \"stdout\": \";;;; arcdocdb.asd \\u2014 definizione di sistema ASDF.\\n;;;;\\n;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.\\n\\n(in-package #:asdf-user)\\n\\n(defsystem \\\"arcdocdb\\\"\\n  :description \\\"Database server documentale general-purpose, append-only, in Common Lisp (SBCL).\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :version \\\"0.0.0\\\"\\n  :pathname \\\"src/\\\"\\n  :serial t\\n  :depends-on (\\\"sb-posix\\\")\\n  :components ((:file \\\"package\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"conditions\\\")\\n                             (:file \\\"binary\\\") (:file \\\"crc32c\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"utf8\\\")\\n                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")\\n                             (:file \\\"cbor-space\\\") (:file \\\"cbor-scan-input\\\")\\n                             (:file \\\"cbor-scan-stack\\\") (:file \\\"cbor-scan-items\\\")\\n                             (:file \\\"cbor-scan\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"registry\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"queue\\\") (:file \\\"writer\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")\\n                             (:file \\\"ready-recycle\\\")\\n                             (:file \\\"worker-types\\\") (:file \\\"worker-boundary\\\") (:file \\\"worker-claim\\\") (:file \\\"worker-run\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"formats\\\") (:file \\\"segment-header\\\")\\n                             (:file \\\"log-header\\\") (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\") (:file \\\"payload-record\\\")\\n                             (:file \\\"payload-write\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"native\\\")\\n                             (:file \\\"lifecycle\\\") (:file \\\"transfer\\\") (:file \\\"flush\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"builder\\\")\\n                             (:file \\\"group\\\") (:file \\\"executor\\\") (:file \\\"csn\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"scan\\\")\\n                             (:file \\\"decisions-package\\\") (:file \\\"decisions-types\\\")\\n                             (:file \\\"decisions-sort\\\") (:file \\\"decisions-radix\\\") (:file \\\"decisions-build\\\")\\n                             (:file \\\"decisions-query\\\")\\n                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")\\n                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")\\n                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\")\\n                             (:file \\\"inventory-types\\\") (:file \\\"inventory-build\\\")\\n                             (:file \\\"inventory-query\\\"))))\\n  :in-order-to ((test-op (test-op \\\"arcdocdb/tests\\\"))))\\n\\n(defsystem \\\"arcdocdb/tests\\\"\\n  :description \\\"Test di ArcDocDB.\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :depends-on (\\\"arcdocdb\\\")\\n  :pathname \\\"tests/\\\"\\n  :serial t\\n  :components ((:file \\\"smoke\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"binary\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"utf8\\\") (:file \\\"threads\\\")\\n                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")\\n                             (:file \\\"cbor-structure-support\\\") (:file \\\"cbor-structure\\\")\\n                             (:file \\\"cbor-structure-threads\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"registry\\\") (:file \\\"threads\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"queue\\\") (:file \\\"threads\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready\\\") (:file \\\"ready-recycle\\\") (:file \\\"worker\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"segment-header\\\") (:file \\\"log-header\\\")\\n                             (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"transfer\\\") (:file \\\"native\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"scan\\\") (:file \\\"corruption\\\")\\n                             (:file \\\"decisions-support\\\") (:file \\\"decisions\\\")\\n                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")\\n                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")\\n                             (:file \\\"inventory-support\\\") (:file \\\"inventory\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"builder\\\") (:file \\\"group\\\") (:file \\\"fault\\\")\\n                             (:file \\\"native\\\") (:file \\\"csn\\\") (:file \\\"csn-threads\\\"))))\\n  :perform (test-op (o c)\\n             (uiop:symbol-call '#:arcdocdb.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))\\n\",
      \"stderr\": \"\",
      \"ours_sha256\": \"bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153\",
      \"base_sha256\": \"1f194a585165cf8aef43779b6f9e14cf5431550014884381b2b668f6b6b7aea5\",
      \"theirs_sha256\": \"259676d70854e9d1e65142daaf89a903d3392925a0cc689fe50656a8f1c6fc2d\"
    },
    {
      \"file\": \"docs/implementazione/README.md\",
      \"command\": [
        \"git\",
        \"merge-file\",
        \"-p\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/ours\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/base\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/theirs\"
      ],
      \"exit_code\": 0,
      \"stdout\": \"# Implementazione\\n\\nFondazioni introdotte dopo la richiesta dell'autore del 2026-10-08 di iniziare la scrittura\\ndel codice. L'autorizzazione non equivale alla chiusura dei criteri della Fase 0 o alla\\nqualifica del motore completo.\\n\\n| Modulo | Contratto e verifica | Codice |\\n|---|---|---|\\n| Fondazioni binarie | [Record v1/v2, CRC32C e lotti SEAL](fondazioni-binarie.md) | [`src/foundation/`](../../src/foundation/) |\\n| Testo UTF-8 | [Validazione limitata, pura e parallela](utf8.md) | [`src/codec/utf8.lisp`](../../src/codec/utf8.lisp) |\\n| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |\\n| Struttura CBOR | [Item completo, UTF-8 e budget con scratch per worker](cbor-struttura.md) | [`src/codec/cbor-scan.lisp`](../../src/codec/cbor-scan.lisp) |\\n| CSN di Archivio | [Registro dei commit in corso e orizzonte](csn.md) | [`src/csn/`](../../src/csn/) |\\n| Metadati storage | [Header dei segmenti, EDIT e DECISION](metadati-storage.md) | [`src/storage/`](../../src/storage/) |\\n| Header dei log | [Identit\\u00e0 e integrit\\u00e0 di control e multiserie](header-log.md) | [`src/storage/log-header.lisp`](../../src/storage/log-header.lisp) |\\n| Segmenti compattati | [Prefisso CLOSED e record ordinari](segmenti-compattati.md) | [`src/storage/compaction-scan.lisp`](../../src/storage/compaction-scan.lisp) |\\n| Code dei writer | [MPSC locale, gettone e tratti limitati](code-writer.md) | [`src/execution/`](../../src/execution/) |\\n| Consegna dei writer | [Idle, pronto, in esecuzione e obbligo di scheduling](writer-handoff.md) | [`src/execution/handoff.lisp`](../../src/execution/handoff.lisp) |\\n| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |\\n| Ricircolo dei writer pronti | [Scambio FIFO atomico a ring pieno](writer-recycle.md) | [`src/execution/ready-recycle.lisp`](../../src/execution/ready-recycle.lisp) |\\n| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n| Confine I/O | [Append, pread e flush durevole](io.md) | [`src/io/`](../../src/io/) |\\n| Lotti WAL | [Formazione, SEAL e group commit](wal.md) | [`src/wal/`](../../src/wal/) |\\n| CSN dei lotti WAL | [Chiusura, token e risoluzione](wal-csn.md) | [`src/wal/csn.lisp`](../../src/wal/csn.lisp) |\\n| Scansione recovery | [Prefisso dei log e testimonianze SEAL](scansione-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Decisioni multiserie | [Tabella TXID, CSN e partecipanti](decisioni-multiserie.md) | [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) |\\n| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Inventario recovery | [Piano di riconciliazione dei nomi dei segmenti](inventario.md) | [`src/recovery/inventory-build.lisp`](../../src/recovery/inventory-build.lisp) |\\n| Ordinamento delle decisioni | [Radix misurato e query concorrenti](decisioni-radix-risultati.md) | [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) |\\n\\nLe evidenze hanno un ambito esplicito: un test del codec non verifica transazioni,\\ndurability, recovery o prestazioni del database.\\n\",
      \"stderr\": \"\",
      \"ours_sha256\": \"e5fa537d4e6b15662597fbdff94b54407cc466a8d28bdab31511ccc2709a01f7\",
      \"base_sha256\": \"ca349da2b7d546a1959db6704b4cd8554c07491a9e567823093a84011a04d4ef\",
      \"theirs_sha256\": \"b4a77fe7082c6b7c4b5f4748ba7e939fe75bf89f9a1a9506717ea16562ebe98b\"
    }
  ],
  \"copied_files\": [
    {
      \"file\": \"arcdocdb.asd\",
      \"origin\": \"worktree\",
      \"sha256\": \"5d616c52780bc2b1d55083bcb62800eaa0636f3f3236d48f0bb3821a8e631c83\"
    },
    {
      \"file\": \"src/execution/package.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
    },
    {
      \"file\": \"src/execution/worker-types.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
    },
    {
      \"file\": \"src/execution/worker-boundary.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
    },
    {
      \"file\": \"src/execution/worker-claim.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
    },
    {
      \"file\": \"src/execution/worker-run.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
    },
    {
      \"file\": \"tests/execution/worker.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
    },
    {
      \"file\": \"tools/writer-worker-bench.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
    },
    {
      \"file\": \"tools/writer-worker-mutation.lisp\",
      \"origin\": \"worktree\",
      \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
    },
    {
      \"file\": \"docs/implementazione/writer-worker-metodo.md\",
      \"origin\": \"worktree\",
      \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    },
    {
      \"file\": \"docs/implementazione/writer-worker.md\",
      \"origin\": \"worktree\",
      \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    },
    {
      \"file\": \"docs/implementazione/writer-worker-decisioni.md\",
      \"origin\": \"v1-stub\",
      \"sha256\": \"1f3a100420672e42cfbf44029ccc9d3bc1ae1388aad669efe80d515975b5f6a3\"
    },
    {
      \"file\": \"docs/implementazione/writer-worker-risultati.md\",
      \"origin\": \"v1-stub\",
      \"sha256\": \"f8249a5ab76d84b28fe130e076496f79239397e3af9b67f5c9f50e7732194742\"
    },
    {
      \"file\": \"docs/implementazione/writer-worker-revisione.md\",
      \"origin\": \"v1-stub\",
      \"sha256\": \"a14e362b6fb745a3caa7d412ad4644c9d2659a454e83472afa63eb109f193150\"
    },
    {
      \"file\": \"docs/implementazione/README.md\",
      \"origin\": \"worktree\",
      \"sha256\": \"faf354f521631b0735d31459717d3dfc08150e08d97f0f7afb782909d97dd11d\"
    },
    {
      \"file\": \"docs/affidabilita/copertura-eccezioni.md\",
      \"origin\": \"v1-stub\",
      \"sha256\": \"2795f5f57edb2c0806885f249d5b4e7ca7e6f87d905497488078fc1aaf445a76\"
    }
  ],
  \"upstream_changed_files\": [
    \"arcdocdb.asd\",
    \"docs/implementazione/README.md\",
    \"docs/implementazione/inventario-decisioni.md\",
    \"docs/implementazione/inventario-metodo.md\",
    \"docs/implementazione/inventario.md\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-01.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-02.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-03.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-04.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-05.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-06.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-07.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-07.lisp.gz\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-08.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-09.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/SPK-10.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/catalogo-finale-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/catalogo-finale.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/catalogo.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/check-core-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/check-core.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/foundation-mutation-source.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/foundation-self-test-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/foundation-self-test.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/inventory-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/inventory-query.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/arcdocdb.asd.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/tools/mutation-isolated-build.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-dati.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-processo-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-processo.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/metodo.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/pubblicazione.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/raccolta-source.lisp.txt\",
    \"spikes/results/2026-10-09-inventory-integration/report.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/report.lisp.gz\",
    \"spikes/results/2026-10-09-inventory-integration/riepilogo.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-copier-dati.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-copier/arcdocdb.asd.txt\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo-dati.lisp\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/0/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/1/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/3/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/4/test.log\",
    \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/worker-fixture.lisp.txt\",
    \"spikes/results/2026-10-09-inventory/SPK-01.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-02.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-03.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-04.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-05.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-06.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-07.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-07.lisp.gz\",
    \"spikes/results/2026-10-09-inventory/SPK-08.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-09.lisp\",
    \"spikes/results/2026-10-09-inventory/SPK-10.lisp\",
    \"spikes/results/2026-10-09-inventory/build-preliminare-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/build-preliminare.lisp\",
    \"spikes/results/2026-10-09-inventory/build-test-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/build-test.lisp\",
    \"spikes/results/2026-10-09-inventory/catalogo-verifica-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/catalogo-verifica.lisp\",
    \"spikes/results/2026-10-09-inventory/catalogo.lisp\",
    \"spikes/results/2026-10-09-inventory/check-completo-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/check-completo.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-copia-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-copia-processo.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-dati.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-processo-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-processo.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-pubblicazione-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-pubblicazione-processo.lisp\",
    \"spikes/results/2026-10-09-inventory/copertura-riepilogo.lisp\",
    \"spikes/results/2026-10-09-inventory/diagnostica-lettura.lisp\",
    \"spikes/results/2026-10-09-inventory/lettura-c1-prima.lisp\",
    \"spikes/results/2026-10-09-inventory/lettura-c1-seconda.lisp\",
    \"spikes/results/2026-10-09-inventory/mutazioni-dati.lisp\",
    \"spikes/results/2026-10-09-inventory/mutazioni-processo-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/mutazioni-processo.lisp\",
    \"spikes/results/2026-10-09-inventory/pubblicazione-finale-metodo.lisp\",
    \"spikes/results/2026-10-09-inventory/pubblicazione-metodo.lisp\",
    \"spikes/results/2026-10-09-inventory/report.lisp.gz\",
    \"spikes/results/2026-10-09-inventory/self-test-mutazioni-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/self-test-mutazioni-dati.lisp\",
    \"spikes/results/2026-10-09-inventory/self-test-mutazioni.lisp\",
    \"spikes/results/2026-10-09-inventory/spikes-conservazione.lisp\",
    \"spikes/results/2026-10-09-inventory/spikes-report.lisp\",
    \"src/recovery/inventory-build.lisp\",
    \"src/recovery/inventory-query.lisp\",
    \"src/recovery/inventory-types.lisp\",
    \"src/recovery/manifest-package.lisp\",
    \"tests/recovery/inventory-support.lisp\",
    \"tests/recovery/inventory.lisp\",
    \"tools/foundation-mutation.lisp\"
  ],
  \"execution_baseline_unchanged\": true,
  \"scope_record\": null,
  \"check_record\": null,
  \"scope_status\": \"pending\",
  \"check_status\": \"pending\"
}
")
  (:PATH #A((38) BASE-CHAR . "spikes/out/worker-integration-scope.py") :BYTES 3379 :SHA256
   "f62428f6d61cb7ca0aa40d32eefa5f7ad844ebb0e51f98845161299d4126776a" :GIT-BLOB
   "55381d19c390e42c80f94a824e49fc08c102aa09" :TEXT "from pathlib import Path
import json, hashlib, subprocess
root=Path.cwd()
preparation=json.loads((root/'spikes/out/worker-integration-preparation.json').read_text())
v1=Path(preparation['v1']);base=preparation['baseline'];upstream=preparation['upstream']
def git(*args): return subprocess.check_output(['git',*args],cwd=root,text=True)
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def tree(commit,path):
    result={}
    for line in git('ls-tree','-r',commit,'--',path).splitlines():
        meta,name=line.split('\\t',1);result[name]=meta.split()[2]
    return result
baseline_execution={};source_stability=[];upstream_stability=[]
for prefix in ['src/execution','tests/execution']:
    before=tree(base,prefix);after=tree(upstream,prefix)
    assert before==after,(prefix,before,after)
    baseline_execution[prefix]=[{'file':name,'baseline_blob':blob,'upstream_blob':after[name]} for name,blob in before.items()]
    for current in sorted((root/prefix).glob('*.lisp')):
        rel=current.relative_to(root).as_posix();old=v1/rel
        assert current.read_bytes()==old.read_bytes(),rel
        source_stability.append({'file':rel,'v1_sha256':sha(old),'integration_sha256':sha(current)})
for rel in ['tools/writer-worker-bench.lisp','tools/writer-worker-mutation.lisp']:
    assert (root/rel).read_bytes()==(v1/rel).read_bytes(),rel
    source_stability.append({'file':rel,'v1_sha256':sha(v1/rel),'integration_sha256':sha(root/rel)})
for rel in ['src/recovery/inventory-types.lisp','src/recovery/inventory-build.lisp','src/recovery/inventory-query.lisp','src/recovery/manifest-package.lisp','tests/recovery/inventory-support.lisp','tests/recovery/inventory.lisp','tools/foundation-mutation.lisp']:
    expected=subprocess.check_output(['git','show',upstream+':'+rel],cwd=root)
    assert (root/rel).read_bytes()==expected,rel
    upstream_stability.append({'file':rel,'upstream_blob':git('rev-parse',upstream+':'+rel).strip(),'integration_sha256':sha(root/rel)})
asd=(root/'arcdocdb.asd').read_text();readme=(root/'docs/implementazione/README.md').read_text()
for component in ['inventory-types','inventory-build','inventory-query','inventory-support','inventory','worker-types','worker-boundary','worker-claim','worker-run','worker']:
    assert '(:file \"'+component+'\")' in asd,component
assert 'inventario.md' in readme and 'writer-worker.md' in readme
for copied in preparation['copied_files']:
    assert sha(root/copied['file'])==copied['sha256'],copied['file']
assert all(item['exit_code']==0 for item in preparation['merges'])
report={'schema_version':1,'kind':'writer-worker-integration-scope','status':'passed','baseline':base,'upstream':upstream,'head':git('rev-parse','HEAD').strip(),'preparation_observations':preparation,'execution_baseline_unchanged':baseline_execution,'frozen_execution_test_tool_stability':source_stability,'upstream_inventory_preserved':upstream_stability,'merged_asd_sha256':sha(root/'arcdocdb.asd'),'merged_readme_sha256':sha(root/'docs/implementazione/README.md'),'limits':['scope-and-byte-stability-check','mutation-benchmark-coverage-retain-cf609-scope','integration-check-core-runs-separately','four-editorial-stubs-v1-final-link-closure-pending']}
assert report['head']==upstream
(root/'spikes/out/worker-integration-scope.json').write_text(json.dumps(report,indent=2)+'\\n')
print(json.dumps(report,indent=2))
")
  (:PATH #A((40) BASE-CHAR . "spikes/out/worker-integration-scope.json") :BYTES 35804 :SHA256
   "90f4a47b33397f5f7367347cd1bde61cadc8b71d63f80f7219f6e5115753f629" :GIT-BLOB
   "db5b761551b0cfe734ee4198c4d28599fb1ce522" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"writer-worker-integration-scope\",
  \"status\": \"passed\",
  \"baseline\": \"cf6091367853ec311fed7b05961a2812fd05a8f1\",
  \"upstream\": \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\",
  \"head\": \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\",
  \"preparation_observations\": {
    \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB\",
    \"v1\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6\",
    \"primary\": \"/Users/gpicchiarelli/Documents/ArcDocDB\",
    \"integration\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc\",
    \"baseline\": \"cf6091367853ec311fed7b05961a2812fd05a8f1\",
    \"upstream\": \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\",
    \"clone_stdout\": \"\",
    \"clone_stderr\": \"Cloning into '/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc'...\\ndone.\\n\",
    \"clone_exit_code\": 0,
    \"checkout_stdout\": \"\",
    \"checkout_stderr\": \"HEAD is now at e2f7a75 Merge pull request #3 from gpicchiarelli/codex/recovery-inventory\\n\",
    \"checkout_exit_code\": 0,
    \"owned_files\": [
      \"arcdocdb.asd\",
      \"src/execution/package.lisp\",
      \"src/execution/worker-types.lisp\",
      \"src/execution/worker-boundary.lisp\",
      \"src/execution/worker-claim.lisp\",
      \"src/execution/worker-run.lisp\",
      \"tests/execution/worker.lisp\",
      \"tools/writer-worker-bench.lisp\",
      \"tools/writer-worker-mutation.lisp\",
      \"docs/implementazione/writer-worker-metodo.md\",
      \"docs/implementazione/writer-worker.md\",
      \"docs/implementazione/writer-worker-decisioni.md\",
      \"docs/implementazione/writer-worker-risultati.md\",
      \"docs/implementazione/writer-worker-revisione.md\",
      \"docs/implementazione/README.md\",
      \"docs/affidabilita/copertura-eccezioni.md\"
    ],
    \"stub_files\": [
      \"docs/affidabilita/copertura-eccezioni.md\",
      \"docs/implementazione/writer-worker-decisioni.md\",
      \"docs/implementazione/writer-worker-revisione.md\",
      \"docs/implementazione/writer-worker-risultati.md\"
    ],
    \"merges\": [
      {
        \"file\": \"arcdocdb.asd\",
        \"command\": [
          \"git\",
          \"merge-file\",
          \"-p\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/ours\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/base\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-1v_n4t5_/theirs\"
        ],
        \"exit_code\": 0,
        \"stdout\": \";;;; arcdocdb.asd \\u2014 definizione di sistema ASDF.\\n;;;;\\n;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.\\n\\n(in-package #:asdf-user)\\n\\n(defsystem \\\"arcdocdb\\\"\\n  :description \\\"Database server documentale general-purpose, append-only, in Common Lisp (SBCL).\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :version \\\"0.0.0\\\"\\n  :pathname \\\"src/\\\"\\n  :serial t\\n  :depends-on (\\\"sb-posix\\\")\\n  :components ((:file \\\"package\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"conditions\\\")\\n                             (:file \\\"binary\\\") (:file \\\"crc32c\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"utf8\\\")\\n                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")\\n                             (:file \\\"cbor-space\\\") (:file \\\"cbor-scan-input\\\")\\n                             (:file \\\"cbor-scan-stack\\\") (:file \\\"cbor-scan-items\\\")\\n                             (:file \\\"cbor-scan\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"registry\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"queue\\\") (:file \\\"writer\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")\\n                             (:file \\\"ready-recycle\\\")\\n                             (:file \\\"worker-types\\\") (:file \\\"worker-boundary\\\") (:file \\\"worker-claim\\\") (:file \\\"worker-run\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"formats\\\") (:file \\\"segment-header\\\")\\n                             (:file \\\"log-header\\\") (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\") (:file \\\"payload-record\\\")\\n                             (:file \\\"payload-write\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"native\\\")\\n                             (:file \\\"lifecycle\\\") (:file \\\"transfer\\\") (:file \\\"flush\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"builder\\\")\\n                             (:file \\\"group\\\") (:file \\\"executor\\\") (:file \\\"csn\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"scan\\\")\\n                             (:file \\\"decisions-package\\\") (:file \\\"decisions-types\\\")\\n                             (:file \\\"decisions-sort\\\") (:file \\\"decisions-radix\\\") (:file \\\"decisions-build\\\")\\n                             (:file \\\"decisions-query\\\")\\n                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")\\n                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")\\n                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\")\\n                             (:file \\\"inventory-types\\\") (:file \\\"inventory-build\\\")\\n                             (:file \\\"inventory-query\\\"))))\\n  :in-order-to ((test-op (test-op \\\"arcdocdb/tests\\\"))))\\n\\n(defsystem \\\"arcdocdb/tests\\\"\\n  :description \\\"Test di ArcDocDB.\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :depends-on (\\\"arcdocdb\\\")\\n  :pathname \\\"tests/\\\"\\n  :serial t\\n  :components ((:file \\\"smoke\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"binary\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"utf8\\\") (:file \\\"threads\\\")\\n                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")\\n                             (:file \\\"cbor-structure-support\\\") (:file \\\"cbor-structure\\\")\\n                             (:file \\\"cbor-structure-threads\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"registry\\\") (:file \\\"threads\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"queue\\\") (:file \\\"threads\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready\\\") (:file \\\"ready-recycle\\\") (:file \\\"worker\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"segment-header\\\") (:file \\\"log-header\\\")\\n                             (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"transfer\\\") (:file \\\"native\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"scan\\\") (:file \\\"corruption\\\")\\n                             (:file \\\"decisions-support\\\") (:file \\\"decisions\\\")\\n                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")\\n                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")\\n                             (:file \\\"inventory-support\\\") (:file \\\"inventory\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"builder\\\") (:file \\\"group\\\") (:file \\\"fault\\\")\\n                             (:file \\\"native\\\") (:file \\\"csn\\\") (:file \\\"csn-threads\\\"))))\\n  :perform (test-op (o c)\\n             (uiop:symbol-call '#:arcdocdb.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))\\n\",
        \"stderr\": \"\",
        \"ours_sha256\": \"bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153\",
        \"base_sha256\": \"1f194a585165cf8aef43779b6f9e14cf5431550014884381b2b668f6b6b7aea5\",
        \"theirs_sha256\": \"259676d70854e9d1e65142daaf89a903d3392925a0cc689fe50656a8f1c6fc2d\"
      },
      {
        \"file\": \"docs/implementazione/README.md\",
        \"command\": [
          \"git\",
          \"merge-file\",
          \"-p\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/ours\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/base\",
          \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/worker-merge-a5xig8mx/theirs\"
        ],
        \"exit_code\": 0,
        \"stdout\": \"# Implementazione\\n\\nFondazioni introdotte dopo la richiesta dell'autore del 2026-10-08 di iniziare la scrittura\\ndel codice. L'autorizzazione non equivale alla chiusura dei criteri della Fase 0 o alla\\nqualifica del motore completo.\\n\\n| Modulo | Contratto e verifica | Codice |\\n|---|---|---|\\n| Fondazioni binarie | [Record v1/v2, CRC32C e lotti SEAL](fondazioni-binarie.md) | [`src/foundation/`](../../src/foundation/) |\\n| Testo UTF-8 | [Validazione limitata, pura e parallela](utf8.md) | [`src/codec/utf8.lisp`](../../src/codec/utf8.lisp) |\\n| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |\\n| Struttura CBOR | [Item completo, UTF-8 e budget con scratch per worker](cbor-struttura.md) | [`src/codec/cbor-scan.lisp`](../../src/codec/cbor-scan.lisp) |\\n| CSN di Archivio | [Registro dei commit in corso e orizzonte](csn.md) | [`src/csn/`](../../src/csn/) |\\n| Metadati storage | [Header dei segmenti, EDIT e DECISION](metadati-storage.md) | [`src/storage/`](../../src/storage/) |\\n| Header dei log | [Identit\\u00e0 e integrit\\u00e0 di control e multiserie](header-log.md) | [`src/storage/log-header.lisp`](../../src/storage/log-header.lisp) |\\n| Segmenti compattati | [Prefisso CLOSED e record ordinari](segmenti-compattati.md) | [`src/storage/compaction-scan.lisp`](../../src/storage/compaction-scan.lisp) |\\n| Code dei writer | [MPSC locale, gettone e tratti limitati](code-writer.md) | [`src/execution/`](../../src/execution/) |\\n| Consegna dei writer | [Idle, pronto, in esecuzione e obbligo di scheduling](writer-handoff.md) | [`src/execution/handoff.lisp`](../../src/execution/handoff.lisp) |\\n| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |\\n| Ricircolo dei writer pronti | [Scambio FIFO atomico a ring pieno](writer-recycle.md) | [`src/execution/ready-recycle.lisp`](../../src/execution/ready-recycle.lisp) |\\n| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n| Confine I/O | [Append, pread e flush durevole](io.md) | [`src/io/`](../../src/io/) |\\n| Lotti WAL | [Formazione, SEAL e group commit](wal.md) | [`src/wal/`](../../src/wal/) |\\n| CSN dei lotti WAL | [Chiusura, token e risoluzione](wal-csn.md) | [`src/wal/csn.lisp`](../../src/wal/csn.lisp) |\\n| Scansione recovery | [Prefisso dei log e testimonianze SEAL](scansione-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Decisioni multiserie | [Tabella TXID, CSN e partecipanti](decisioni-multiserie.md) | [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) |\\n| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Inventario recovery | [Piano di riconciliazione dei nomi dei segmenti](inventario.md) | [`src/recovery/inventory-build.lisp`](../../src/recovery/inventory-build.lisp) |\\n| Ordinamento delle decisioni | [Radix misurato e query concorrenti](decisioni-radix-risultati.md) | [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) |\\n\\nLe evidenze hanno un ambito esplicito: un test del codec non verifica transazioni,\\ndurability, recovery o prestazioni del database.\\n\",
        \"stderr\": \"\",
        \"ours_sha256\": \"e5fa537d4e6b15662597fbdff94b54407cc466a8d28bdab31511ccc2709a01f7\",
        \"base_sha256\": \"ca349da2b7d546a1959db6704b4cd8554c07491a9e567823093a84011a04d4ef\",
        \"theirs_sha256\": \"b4a77fe7082c6b7c4b5f4748ba7e939fe75bf89f9a1a9506717ea16562ebe98b\"
      }
    ],
    \"copied_files\": [
      {
        \"file\": \"arcdocdb.asd\",
        \"origin\": \"worktree\",
        \"sha256\": \"5d616c52780bc2b1d55083bcb62800eaa0636f3f3236d48f0bb3821a8e631c83\"
      },
      {
        \"file\": \"src/execution/package.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
      },
      {
        \"file\": \"src/execution/worker-types.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
      },
      {
        \"file\": \"src/execution/worker-boundary.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
      },
      {
        \"file\": \"src/execution/worker-claim.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
      },
      {
        \"file\": \"src/execution/worker-run.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
      },
      {
        \"file\": \"tests/execution/worker.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
      },
      {
        \"file\": \"tools/writer-worker-bench.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
      },
      {
        \"file\": \"tools/writer-worker-mutation.lisp\",
        \"origin\": \"worktree\",
        \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
      },
      {
        \"file\": \"docs/implementazione/writer-worker-metodo.md\",
        \"origin\": \"worktree\",
        \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
      },
      {
        \"file\": \"docs/implementazione/writer-worker.md\",
        \"origin\": \"worktree\",
        \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
      },
      {
        \"file\": \"docs/implementazione/writer-worker-decisioni.md\",
        \"origin\": \"v1-stub\",
        \"sha256\": \"1f3a100420672e42cfbf44029ccc9d3bc1ae1388aad669efe80d515975b5f6a3\"
      },
      {
        \"file\": \"docs/implementazione/writer-worker-risultati.md\",
        \"origin\": \"v1-stub\",
        \"sha256\": \"f8249a5ab76d84b28fe130e076496f79239397e3af9b67f5c9f50e7732194742\"
      },
      {
        \"file\": \"docs/implementazione/writer-worker-revisione.md\",
        \"origin\": \"v1-stub\",
        \"sha256\": \"a14e362b6fb745a3caa7d412ad4644c9d2659a454e83472afa63eb109f193150\"
      },
      {
        \"file\": \"docs/implementazione/README.md\",
        \"origin\": \"worktree\",
        \"sha256\": \"faf354f521631b0735d31459717d3dfc08150e08d97f0f7afb782909d97dd11d\"
      },
      {
        \"file\": \"docs/affidabilita/copertura-eccezioni.md\",
        \"origin\": \"v1-stub\",
        \"sha256\": \"2795f5f57edb2c0806885f249d5b4e7ca7e6f87d905497488078fc1aaf445a76\"
      }
    ],
    \"upstream_changed_files\": [
      \"arcdocdb.asd\",
      \"docs/implementazione/README.md\",
      \"docs/implementazione/inventario-decisioni.md\",
      \"docs/implementazione/inventario-metodo.md\",
      \"docs/implementazione/inventario.md\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-01.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-02.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-03.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-04.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-05.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-06.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-07.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-07.lisp.gz\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-08.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-09.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/SPK-10.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/catalogo-finale-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/catalogo-finale.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/catalogo.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/check-core-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/check-core.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/foundation-mutation-source.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/foundation-self-test-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/foundation-self-test.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/0/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/1/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/2/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/3/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/4/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/5/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/inventory-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/6/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/inventory-query.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/7/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/arcdocdb.asd.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-integrated-mutations/baseline/tools/mutation-isolated-build.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-dati.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-processo-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/inventory-mutations-processo.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/metodo.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/pubblicazione.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/raccolta-source.lisp.txt\",
      \"spikes/results/2026-10-09-inventory-integration/report.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/report.lisp.gz\",
      \"spikes/results/2026-10-09-inventory-integration/riepilogo.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-copier-dati.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-copier/arcdocdb.asd.txt\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo-dati.lisp\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/0/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/1/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/3/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/4/test.log\",
      \"spikes/results/2026-10-09-inventory-integration/self-test-parallelo/worker-fixture.lisp.txt\",
      \"spikes/results/2026-10-09-inventory/SPK-01.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-02.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-03.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-04.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-05.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-06.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-07.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-07.lisp.gz\",
      \"spikes/results/2026-10-09-inventory/SPK-08.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-09.lisp\",
      \"spikes/results/2026-10-09-inventory/SPK-10.lisp\",
      \"spikes/results/2026-10-09-inventory/build-preliminare-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/build-preliminare.lisp\",
      \"spikes/results/2026-10-09-inventory/build-test-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/build-test.lisp\",
      \"spikes/results/2026-10-09-inventory/catalogo-verifica-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/catalogo-verifica.lisp\",
      \"spikes/results/2026-10-09-inventory/catalogo.lisp\",
      \"spikes/results/2026-10-09-inventory/check-completo-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/check-completo.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-copia-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-copia-processo.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-dati.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-processo-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-processo.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-pubblicazione-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-pubblicazione-processo.lisp\",
      \"spikes/results/2026-10-09-inventory/copertura-riepilogo.lisp\",
      \"spikes/results/2026-10-09-inventory/diagnostica-lettura.lisp\",
      \"spikes/results/2026-10-09-inventory/lettura-c1-prima.lisp\",
      \"spikes/results/2026-10-09-inventory/lettura-c1-seconda.lisp\",
      \"spikes/results/2026-10-09-inventory/mutazioni-dati.lisp\",
      \"spikes/results/2026-10-09-inventory/mutazioni-processo-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/mutazioni-processo.lisp\",
      \"spikes/results/2026-10-09-inventory/pubblicazione-finale-metodo.lisp\",
      \"spikes/results/2026-10-09-inventory/pubblicazione-metodo.lisp\",
      \"spikes/results/2026-10-09-inventory/report.lisp.gz\",
      \"spikes/results/2026-10-09-inventory/self-test-mutazioni-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/self-test-mutazioni-dati.lisp\",
      \"spikes/results/2026-10-09-inventory/self-test-mutazioni.lisp\",
      \"spikes/results/2026-10-09-inventory/spikes-conservazione.lisp\",
      \"spikes/results/2026-10-09-inventory/spikes-report.lisp\",
      \"src/recovery/inventory-build.lisp\",
      \"src/recovery/inventory-query.lisp\",
      \"src/recovery/inventory-types.lisp\",
      \"src/recovery/manifest-package.lisp\",
      \"tests/recovery/inventory-support.lisp\",
      \"tests/recovery/inventory.lisp\",
      \"tools/foundation-mutation.lisp\"
    ],
    \"execution_baseline_unchanged\": true,
    \"scope_record\": null,
    \"check_record\": null,
    \"scope_status\": \"pending\",
    \"check_status\": \"pending\"
  },
  \"execution_baseline_unchanged\": {
    \"src/execution\": [
      {
        \"file\": \"src/execution/handoff.lisp\",
        \"baseline_blob\": \"a030e7af1afd6db760088f74615fe2396d928b64\",
        \"upstream_blob\": \"a030e7af1afd6db760088f74615fe2396d928b64\"
      },
      {
        \"file\": \"src/execution/package.lisp\",
        \"baseline_blob\": \"f140cee3f2f661c99fb7d860e4a642a66175c484\",
        \"upstream_blob\": \"f140cee3f2f661c99fb7d860e4a642a66175c484\"
      },
      {
        \"file\": \"src/execution/queue.lisp\",
        \"baseline_blob\": \"bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0\",
        \"upstream_blob\": \"bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0\"
      },
      {
        \"file\": \"src/execution/ready-recycle.lisp\",
        \"baseline_blob\": \"58981c7e41ce2694dbfcaed99010a3a53e3c1dea\",
        \"upstream_blob\": \"58981c7e41ce2694dbfcaed99010a3a53e3c1dea\"
      },
      {
        \"file\": \"src/execution/ready-types.lisp\",
        \"baseline_blob\": \"5b3c26f78d5c4aa53ca200abdd3e0f753f926b54\",
        \"upstream_blob\": \"5b3c26f78d5c4aa53ca200abdd3e0f753f926b54\"
      },
      {
        \"file\": \"src/execution/ready.lisp\",
        \"baseline_blob\": \"4119f86231b7d8698fc3558868ff8a5bcbdf3090\",
        \"upstream_blob\": \"4119f86231b7d8698fc3558868ff8a5bcbdf3090\"
      },
      {
        \"file\": \"src/execution/writer.lisp\",
        \"baseline_blob\": \"8e5102497f628796fa8faffa2085a165496af230\",
        \"upstream_blob\": \"8e5102497f628796fa8faffa2085a165496af230\"
      }
    ],
    \"tests/execution\": [
      {
        \"file\": \"tests/execution/handoff.lisp\",
        \"baseline_blob\": \"ba702352ee63241b9ac993b0aca8f162c3deef1b\",
        \"upstream_blob\": \"ba702352ee63241b9ac993b0aca8f162c3deef1b\"
      },
      {
        \"file\": \"tests/execution/queue.lisp\",
        \"baseline_blob\": \"546d4215f9f63007f632c522f0f8c1e75ac4bbeb\",
        \"upstream_blob\": \"546d4215f9f63007f632c522f0f8c1e75ac4bbeb\"
      },
      {
        \"file\": \"tests/execution/ready-recycle.lisp\",
        \"baseline_blob\": \"1dff8707436ca52f20f62e9946621ca1037f33d2\",
        \"upstream_blob\": \"1dff8707436ca52f20f62e9946621ca1037f33d2\"
      },
      {
        \"file\": \"tests/execution/ready.lisp\",
        \"baseline_blob\": \"9f81552333f86fe0b20f2d5e8ba48b20634f5a09\",
        \"upstream_blob\": \"9f81552333f86fe0b20f2d5e8ba48b20634f5a09\"
      },
      {
        \"file\": \"tests/execution/support.lisp\",
        \"baseline_blob\": \"b8bac07926727a644f0246f6b57d600332288310\",
        \"upstream_blob\": \"b8bac07926727a644f0246f6b57d600332288310\"
      },
      {
        \"file\": \"tests/execution/threads.lisp\",
        \"baseline_blob\": \"4212f8cc4be686e923cdbec9ded24f42f1da74ba\",
        \"upstream_blob\": \"4212f8cc4be686e923cdbec9ded24f42f1da74ba\"
      }
    ]
  },
  \"frozen_execution_test_tool_stability\": [
    {
      \"file\": \"src/execution/handoff.lisp\",
      \"v1_sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\",
      \"integration_sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
    },
    {
      \"file\": \"src/execution/package.lisp\",
      \"v1_sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\",
      \"integration_sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
    },
    {
      \"file\": \"src/execution/queue.lisp\",
      \"v1_sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\",
      \"integration_sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
    },
    {
      \"file\": \"src/execution/ready-recycle.lisp\",
      \"v1_sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\",
      \"integration_sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
    },
    {
      \"file\": \"src/execution/ready-types.lisp\",
      \"v1_sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\",
      \"integration_sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
    },
    {
      \"file\": \"src/execution/ready.lisp\",
      \"v1_sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\",
      \"integration_sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
    },
    {
      \"file\": \"src/execution/worker-boundary.lisp\",
      \"v1_sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\",
      \"integration_sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
    },
    {
      \"file\": \"src/execution/worker-claim.lisp\",
      \"v1_sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\",
      \"integration_sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
    },
    {
      \"file\": \"src/execution/worker-run.lisp\",
      \"v1_sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\",
      \"integration_sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
    },
    {
      \"file\": \"src/execution/worker-types.lisp\",
      \"v1_sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\",
      \"integration_sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
    },
    {
      \"file\": \"src/execution/writer.lisp\",
      \"v1_sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\",
      \"integration_sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
    },
    {
      \"file\": \"tests/execution/handoff.lisp\",
      \"v1_sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\",
      \"integration_sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
    },
    {
      \"file\": \"tests/execution/queue.lisp\",
      \"v1_sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\",
      \"integration_sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
    },
    {
      \"file\": \"tests/execution/ready-recycle.lisp\",
      \"v1_sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\",
      \"integration_sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
    },
    {
      \"file\": \"tests/execution/ready.lisp\",
      \"v1_sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\",
      \"integration_sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
    },
    {
      \"file\": \"tests/execution/support.lisp\",
      \"v1_sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\",
      \"integration_sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
    },
    {
      \"file\": \"tests/execution/threads.lisp\",
      \"v1_sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\",
      \"integration_sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
    },
    {
      \"file\": \"tests/execution/worker.lisp\",
      \"v1_sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\",
      \"integration_sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
    },
    {
      \"file\": \"tools/writer-worker-bench.lisp\",
      \"v1_sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\",
      \"integration_sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
    },
    {
      \"file\": \"tools/writer-worker-mutation.lisp\",
      \"v1_sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\",
      \"integration_sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
    }
  ],
  \"upstream_inventory_preserved\": [
    {
      \"file\": \"src/recovery/inventory-types.lisp\",
      \"upstream_blob\": \"68c357d2d522fcabe79284c540c2631e5fa87780\",
      \"integration_sha256\": \"df84220d8e679322bc1a68d9e279e25985e6a07d64c95782191d9085987624e9\"
    },
    {
      \"file\": \"src/recovery/inventory-build.lisp\",
      \"upstream_blob\": \"60057f6a50c657f016bee3c21c21911b582f86fe\",
      \"integration_sha256\": \"cc486c3dcb7e83656301a0bea59442f8e654543740b0d6950290450f5e2f415e\"
    },
    {
      \"file\": \"src/recovery/inventory-query.lisp\",
      \"upstream_blob\": \"47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4\",
      \"integration_sha256\": \"8b151ca6e8cee66a4e9035398349e21f0f3b4d1fdb564557ed60d3cf52fe7bfb\"
    },
    {
      \"file\": \"src/recovery/manifest-package.lisp\",
      \"upstream_blob\": \"5405bd515df8b26b792bd0430c9ec3dbadce63e7\",
      \"integration_sha256\": \"0575efe36245b73db5c99f53577f3ed17039b8b796fa1e9095bdb8a0c6cdc5dc\"
    },
    {
      \"file\": \"tests/recovery/inventory-support.lisp\",
      \"upstream_blob\": \"06eeff2101a97f9abdec6b6f14aa621c2fec29fd\",
      \"integration_sha256\": \"2c6e1e6fb7a641c17f08b9dc4f425c86b6feb03f871496d918a08215957bcb27\"
    },
    {
      \"file\": \"tests/recovery/inventory.lisp\",
      \"upstream_blob\": \"0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9\",
      \"integration_sha256\": \"e6342511c85b67ba9f1bef190bbf141e7e2fbcb92005ea3e43851488988c7fb9\"
    },
    {
      \"file\": \"tools/foundation-mutation.lisp\",
      \"upstream_blob\": \"fd285d0ae73d312d7234a2a142d16897c9adbcf7\",
      \"integration_sha256\": \"88ce773e9c0f1c3c64cddb6a84f21df178228792d43a867df05f43609bdd1a1d\"
    }
  ],
  \"merged_asd_sha256\": \"5d616c52780bc2b1d55083bcb62800eaa0636f3f3236d48f0bb3821a8e631c83\",
  \"merged_readme_sha256\": \"faf354f521631b0735d31459717d3dfc08150e08d97f0f7afb782909d97dd11d\",
  \"limits\": [
    \"scope-and-byte-stability-check\",
    \"mutation-benchmark-coverage-retain-cf609-scope\",
    \"integration-check-core-runs-separately\",
    \"four-editorial-stubs-v1-final-link-closure-pending\"
  ]
}
")
  (:PATH #A((42) BASE-CHAR . "spikes/out/worker-integration-summary.lisp") :BYTES 3882 :SHA256
   "32613fbef7f7c74c40276426f139312f1c894bb8fa46efbc6b299136bc49b616" :GIT-BLOB
   "9f9042330fa74f8a8c1439e55b28d38684482329" :TEXT
   ";;;; Read completed records only; no compilation, campaigns or tests are repeated.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun leading-number (line)
  (when (and (plusp (length line)) (digit-char-p (char line 0)))
    (multiple-value-bind (number end) (parse-integer line :junk-allowed t)
      (when (and number (< end (length line)) (char= #\\Space (char line end))) number))))
(let* ((check-path \"spikes/out/4000548048-command-40192-0/report.lisp\")
       (scope-path \"spikes/out/4000548017-command-37007-0/report.lisp\")
       (spikes-path \"spikes/out/4000548134-check-44515-0/report.lisp\")
       (check (arcdocdb.evidence:read-evidence check-path))
       (scope (arcdocdb.evidence:read-evidence scope-path))
       (spikes (arcdocdb.evidence:read-evidence spikes-path))
       (stdout (getf check :stdout))
       (lines (uiop:split-string stdout :separator '(#\\Newline)))
       (modules (loop for line in lines for n = (leading-number line)
                      when (and n (search \" test\" line) (search \"superati.\" line))
                      collect (list :count n :raw-line line)))
       (lint (find-if (lambda (line) (and (leading-number line) (search \"file, 0 violazioni\" line))) lines))
       (links (find-if (lambda (line) (and (leading-number line) (search \"link controllati, 0 rotti\" line))) lines))
       (trace (find-if (lambda (line) (and (leading-number line) (search \"requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\" line))) lines))
       (sum (reduce #'+ modules :key (lambda (entry) (getf entry :count))))
       (runs (getf spikes :runs)))
  (dolist (record (list check scope))
    (assert (and (eq :ok (getf record :status)) (eq :stable (getf record :source-consistency))
                 (eql 0 (getf record :exit-code))
                 (equal (getf record :source-blobs-before) (getf record :source-blobs-after)))))
  (assert (and (= 10 (length modules)) (= 400 sum)))
  (assert (and lint (= 66 (leading-number lint)) links (= 224 (leading-number links))
               (search \"2017 link\" links) trace (= 114 (leading-number trace))))
  (assert (and (search \"build e test: nessun avviso, tutti i controlli superati\" stdout)
               (search \"ok    package ARCDOCDB presente\" stdout)
               (search \"ok    ARCDOCDB:*VERSION* è una stringa\" stdout)))
  (assert (and (eq :complete (getf spikes :status)) (= 10 (length runs))
               (every (lambda (run) (and (eql 0 (getf run :exit-code))
                                         (eq :stable (getf run :source-consistency)))) runs)))
  (let ((report (list :schema-version 1 :kind :writer-worker-integration-summary :status :passed
                      :check-path check-path :scope-path scope-path :spikes-path spikes-path
                      :baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      :integration-head \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
                      :test-sum sum :test-modules modules :smoke :passed :compile :no-warnings
                      :lint-raw lint :links-raw links :trace-raw trace
                      :spikes (mapcar (lambda (run) (list :id (getf run :id) :status (getf run :status)
                                                         :exit-code (getf run :exit-code)
                                                         :source-consistency (getf run :source-consistency))) runs)
                      :limits '(:read-only-summary :one-make-check-core :four-v1-editorial-stubs
                                :no-repeat-of-mutation-benchmark-or-coverage :final-editorial-link-closure-pending))))
    (with-open-file (stream \"spikes/out/worker-integration-summary.lisp-data\" :direction :output :if-exists :error)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))))
")
  (:PATH #A((47) BASE-CHAR . "spikes/out/worker-integration-summary.lisp-data") :BYTES 2069 :SHA256
   "2ff58c6dd6f585dae289924bc23ab14899030e8e1f284d0033b50835bd3b168a" :GIT-BLOB
   "8a0e33dc4d53672c1f2185c3820a43ebcb917732" :TEXT
   "(:SCHEMA-VERSION 1 :KIND :WRITER-WORKER-INTEGRATION-SUMMARY :STATUS :PASSED
 :CHECK-PATH \"spikes/out/4000548048-command-40192-0/report.lisp\" :SCOPE-PATH
 \"spikes/out/4000548017-command-37007-0/report.lisp\" :SPIKES-PATH
 \"spikes/out/4000548134-check-44515-0/report.lisp\" :BASELINE
 \"cf6091367853ec311fed7b05961a2812fd05a8f1\" :INTEGRATION-HEAD
 \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\" :TEST-SUM 400 :TEST-MODULES
 ((:COUNT 28 :RAW-LINE \"28 test delle fondazioni superati.\")
  (:COUNT 17 :RAW-LINE \"17 test UTF-8 superati.\")
  (:COUNT 17 :RAW-LINE \"17 test degli header CBOR superati.\")
  (:COUNT 24 :RAW-LINE \"24 test della struttura CBOR superati.\")
  (:COUNT 20 :RAW-LINE \"20 test del registro CSN superati.\")
  (:COUNT 89 :RAW-LINE \"89 test delle code writer superati.\")
  (:COUNT 44 :RAW-LINE \"44 test dei metadati storage superati.\")
  (:COUNT 18 :RAW-LINE \"18 test I/O superati.\")
  (:COUNT 95 :RAW-LINE \"95 test recovery superati.\")
  (:COUNT 48 :RAW-LINE \"48 test WAL superati.\"))
 :SMOKE :PASSED :COMPILE :NO-WARNINGS :LINT-RAW \"66 file, 0 violazioni\"
 :LINKS-RAW \"224 file, 2017 link controllati, 0 rotti\" :TRACE-RAW
 \"114 requisiti, 65 invarianti, 13 scenari FI, 52 ADR: 0 errori\" :SPIKES
 ((:ID \"SPK-01\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-02\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-03\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-04\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-05\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-06\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-07\" :STATUS :PASS :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-08\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-09\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE)
  (:ID \"SPK-10\" :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE))
 :LIMITS
 (:READ-ONLY-SUMMARY :ONE-MAKE-CHECK-CORE :FOUR-V1-EDITORIAL-STUBS
  :NO-REPEAT-OF-MUTATION-BENCHMARK-OR-COVERAGE
  :FINAL-EDITORIAL-LINK-CLOSURE-PENDING))
")
  (:PATH #A((37) BASE-CHAR . "spikes/out/worker-integration-copy.py") :BYTES 2225 :SHA256
   "3d57d5bec2dc2a78550bfd75f72f1eb752c2f87e64c00322f0f29ad71ea60da6" :GIT-BLOB
   "def3c147a86ed2fa3ba03d42711826300abd1f19" :TEXT "from pathlib import Path
import os, json, hashlib
source=Path(\"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc\")
destination=Path(\"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6\")
process_dirs=[\"spikes/out/4000548017-command-37007-0\",\"spikes/out/4000548048-command-40192-0\",\"spikes/out/4000548460-command-59017-0\",\"spikes/out/4000548134-check-44515-0\"]
paths=[]
for directory in process_dirs:
    paths.extend(p.relative_to(source).as_posix() for p in sorted((source/directory).iterdir()) if p.is_file())
paths.extend([\"spikes/out/worker-integration-preparation.json\",\"spikes/out/worker-integration-scope.py\",\"spikes/out/worker-integration-scope.json\",\"spikes/out/worker-integration-summary.lisp\",\"spikes/out/worker-integration-summary.lisp-data\",\"spikes/out/worker-integration-copy.py\"])
assert len(paths)==len(set(paths))
for rel in paths:
    assert (source/rel).is_file(),rel
    assert not (destination/rel).exists(),rel
copies=[]
for rel in paths:
    original=source/rel;target=destination/rel;data=original.read_bytes();before=hashlib.sha256(data).hexdigest()
    target.parent.mkdir(parents=True,exist_ok=True)
    fd=os.open(target,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(fd,'wb') as stream: stream.write(data)
    after=hashlib.sha256(original.read_bytes()).hexdigest();copied=hashlib.sha256(target.read_bytes()).hexdigest()
    assert before==after==copied,rel
    copies.append({'relative_path':rel,'source':str(original),'destination':str(target),'bytes':len(data),'sha256_before':before,'sha256_after':after,'sha256_destination':copied,'exclusive_create':True})
report={'schema_version':1,'kind':'worker-integration-evidence-copy','status':'passed','source':str(source),'destination':str(destination),'copies':copies,'limits':['ignored-evidence-only','original-absolute-paths-retained','no-source-tests-tools-or-docs-modified','no-campaigns-or-compilation-repeated']}
receipt=destination/'spikes/out/worker-integration-copy-receipt.json'
fd=os.open(receipt,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
with os.fdopen(fd,'w') as stream: json.dump(report,stream,indent=2);stream.write('\\n')
print(json.dumps(report,indent=2))
")
  (:PATH #A((47) BASE-CHAR . "spikes/out/worker-integration-copy-receipt.json") :BYTES 19320
   :SHA256 "24bd117f1cd150ee692a3e5f96f18d85db211e758d0529e6835d0a26a8eacbca" :GIT-BLOB
   "cba141925253a1cacf69b57fe97935da9e903780" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"worker-integration-evidence-copy\",
  \"status\": \"passed\",
  \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc\",
  \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6\",
  \"copies\": [
    {
      \"relative_path\": \"spikes/out/4000548017-command-37007-0/conservazione.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548017-command-37007-0/conservazione.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548017-command-37007-0/conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256_before\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\",
      \"sha256_after\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\",
      \"sha256_destination\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548017-command-37007-0/report.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548017-command-37007-0/report.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548017-command-37007-0/report.lisp\",
      \"bytes\": 132676,
      \"sha256_before\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\",
      \"sha256_after\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\",
      \"sha256_destination\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548048-command-40192-0/conservazione.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548048-command-40192-0/conservazione.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548048-command-40192-0/conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256_before\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\",
      \"sha256_after\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\",
      \"sha256_destination\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548048-command-40192-0/report.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548048-command-40192-0/report.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548048-command-40192-0/report.lisp\",
      \"bytes\": 232551,
      \"sha256_before\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\",
      \"sha256_after\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\",
      \"sha256_destination\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548460-command-59017-0/conservazione.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548460-command-59017-0/conservazione.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548460-command-59017-0/conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256_before\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\",
      \"sha256_after\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\",
      \"sha256_destination\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548460-command-59017-0/report.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548460-command-59017-0/report.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548460-command-59017-0/report.lisp\",
      \"bytes\": 97258,
      \"sha256_before\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\",
      \"sha256_after\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\",
      \"sha256_destination\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-01.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-01.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-01.lisp\",
      \"bytes\": 27228,
      \"sha256_before\": \"7e6d1032bf1f933dc33c28ee738c623a8eb2528d4f08f3ac52646f0bac8b6d55\",
      \"sha256_after\": \"7e6d1032bf1f933dc33c28ee738c623a8eb2528d4f08f3ac52646f0bac8b6d55\",
      \"sha256_destination\": \"7e6d1032bf1f933dc33c28ee738c623a8eb2528d4f08f3ac52646f0bac8b6d55\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-02.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-02.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-02.lisp\",
      \"bytes\": 1607,
      \"sha256_before\": \"c0193ee6ede2efd2db84a6387965530895cfc1fd1f58a7687cf358230359d678\",
      \"sha256_after\": \"c0193ee6ede2efd2db84a6387965530895cfc1fd1f58a7687cf358230359d678\",
      \"sha256_destination\": \"c0193ee6ede2efd2db84a6387965530895cfc1fd1f58a7687cf358230359d678\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-03.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-03.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-03.lisp\",
      \"bytes\": 3704,
      \"sha256_before\": \"72800102e0792176947ec6c4855a601f08ce526f7b7917ddf9c9caa870eee7d6\",
      \"sha256_after\": \"72800102e0792176947ec6c4855a601f08ce526f7b7917ddf9c9caa870eee7d6\",
      \"sha256_destination\": \"72800102e0792176947ec6c4855a601f08ce526f7b7917ddf9c9caa870eee7d6\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-04.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-04.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-04.lisp\",
      \"bytes\": 6752,
      \"sha256_before\": \"38166dbb5751a5d11226a0fa10e164432a0848e721c3b6cf2a6b3b40e5e079c8\",
      \"sha256_after\": \"38166dbb5751a5d11226a0fa10e164432a0848e721c3b6cf2a6b3b40e5e079c8\",
      \"sha256_destination\": \"38166dbb5751a5d11226a0fa10e164432a0848e721c3b6cf2a6b3b40e5e079c8\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-05.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-05.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-05.lisp\",
      \"bytes\": 10119,
      \"sha256_before\": \"5fcf4bfe7b444311edcc8ece046d0f48039e5bc825c36b9130a941022895e5fa\",
      \"sha256_after\": \"5fcf4bfe7b444311edcc8ece046d0f48039e5bc825c36b9130a941022895e5fa\",
      \"sha256_destination\": \"5fcf4bfe7b444311edcc8ece046d0f48039e5bc825c36b9130a941022895e5fa\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-06.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-06.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-06.lisp\",
      \"bytes\": 24112,
      \"sha256_before\": \"a9bff5cb84ff6fef93a5ef26db4d70a86bb9beead7b14fbd2fb1de73b70eff53\",
      \"sha256_after\": \"a9bff5cb84ff6fef93a5ef26db4d70a86bb9beead7b14fbd2fb1de73b70eff53\",
      \"sha256_destination\": \"a9bff5cb84ff6fef93a5ef26db4d70a86bb9beead7b14fbd2fb1de73b70eff53\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-07.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-07.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-07.lisp\",
      \"bytes\": 318,
      \"sha256_before\": \"d98dbcaaad49b5b9e8a3754ebc1b04d58acc02bc6ff0aea0556e36e1777f924c\",
      \"sha256_after\": \"d98dbcaaad49b5b9e8a3754ebc1b04d58acc02bc6ff0aea0556e36e1777f924c\",
      \"sha256_destination\": \"d98dbcaaad49b5b9e8a3754ebc1b04d58acc02bc6ff0aea0556e36e1777f924c\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-07.lisp.gz\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-07.lisp.gz\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-07.lisp.gz\",
      \"bytes\": 410637,
      \"sha256_before\": \"90b9aa48faa7dd10264793c845f8fa3a47f421aecc2018a1608bb0d046b67e2d\",
      \"sha256_after\": \"90b9aa48faa7dd10264793c845f8fa3a47f421aecc2018a1608bb0d046b67e2d\",
      \"sha256_destination\": \"90b9aa48faa7dd10264793c845f8fa3a47f421aecc2018a1608bb0d046b67e2d\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-08.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-08.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-08.lisp\",
      \"bytes\": 292334,
      \"sha256_before\": \"8bb7e56a8a1966e801a4950675db8bca71879694eabb0b1ab60dd6744a4057e7\",
      \"sha256_after\": \"8bb7e56a8a1966e801a4950675db8bca71879694eabb0b1ab60dd6744a4057e7\",
      \"sha256_destination\": \"8bb7e56a8a1966e801a4950675db8bca71879694eabb0b1ab60dd6744a4057e7\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-09.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-09.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-09.lisp\",
      \"bytes\": 2472,
      \"sha256_before\": \"a8a8b7ff2c39a16a88fbd041a7cfa6262aa57ed57e05daf33e8ff172fd58b33f\",
      \"sha256_after\": \"a8a8b7ff2c39a16a88fbd041a7cfa6262aa57ed57e05daf33e8ff172fd58b33f\",
      \"sha256_destination\": \"a8a8b7ff2c39a16a88fbd041a7cfa6262aa57ed57e05daf33e8ff172fd58b33f\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/SPK-10.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-10.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/SPK-10.lisp\",
      \"bytes\": 22977,
      \"sha256_before\": \"a655d062272e8a3d269729fc528d75cb21d5c95946936703d2d061723135959c\",
      \"sha256_after\": \"a655d062272e8a3d269729fc528d75cb21d5c95946936703d2d061723135959c\",
      \"sha256_destination\": \"a655d062272e8a3d269729fc528d75cb21d5c95946936703d2d061723135959c\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/conservazione.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/conservazione.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/conservazione.lisp\",
      \"bytes\": 2452,
      \"sha256_before\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\",
      \"sha256_after\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\",
      \"sha256_destination\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/report.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/report.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/report.lisp\",
      \"bytes\": 318,
      \"sha256_before\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\",
      \"sha256_after\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\",
      \"sha256_destination\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/4000548134-check-44515-0/report.lisp.gz\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/report.lisp.gz\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000548134-check-44515-0/report.lisp.gz\",
      \"bytes\": 467437,
      \"sha256_before\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\",
      \"sha256_after\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\",
      \"sha256_destination\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-preparation.json\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-preparation.json\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-preparation.json\",
      \"bytes\": 25332,
      \"sha256_before\": \"b4f25aa7205b6140a0d752b9677f159069b43394ff05402ececabe46c81bee19\",
      \"sha256_after\": \"b4f25aa7205b6140a0d752b9677f159069b43394ff05402ececabe46c81bee19\",
      \"sha256_destination\": \"b4f25aa7205b6140a0d752b9677f159069b43394ff05402ececabe46c81bee19\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-scope.py\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-scope.py\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-scope.py\",
      \"bytes\": 3379,
      \"sha256_before\": \"f62428f6d61cb7ca0aa40d32eefa5f7ad844ebb0e51f98845161299d4126776a\",
      \"sha256_after\": \"f62428f6d61cb7ca0aa40d32eefa5f7ad844ebb0e51f98845161299d4126776a\",
      \"sha256_destination\": \"f62428f6d61cb7ca0aa40d32eefa5f7ad844ebb0e51f98845161299d4126776a\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-scope.json\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-scope.json\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-scope.json\",
      \"bytes\": 35804,
      \"sha256_before\": \"90f4a47b33397f5f7367347cd1bde61cadc8b71d63f80f7219f6e5115753f629\",
      \"sha256_after\": \"90f4a47b33397f5f7367347cd1bde61cadc8b71d63f80f7219f6e5115753f629\",
      \"sha256_destination\": \"90f4a47b33397f5f7367347cd1bde61cadc8b71d63f80f7219f6e5115753f629\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-summary.lisp\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-summary.lisp\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-summary.lisp\",
      \"bytes\": 3882,
      \"sha256_before\": \"32613fbef7f7c74c40276426f139312f1c894bb8fa46efbc6b299136bc49b616\",
      \"sha256_after\": \"32613fbef7f7c74c40276426f139312f1c894bb8fa46efbc6b299136bc49b616\",
      \"sha256_destination\": \"32613fbef7f7c74c40276426f139312f1c894bb8fa46efbc6b299136bc49b616\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-summary.lisp-data\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-summary.lisp-data\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-summary.lisp-data\",
      \"bytes\": 2069,
      \"sha256_before\": \"2ff58c6dd6f585dae289924bc23ab14899030e8e1f284d0033b50835bd3b168a\",
      \"sha256_after\": \"2ff58c6dd6f585dae289924bc23ab14899030e8e1f284d0033b50835bd3b168a\",
      \"sha256_destination\": \"2ff58c6dd6f585dae289924bc23ab14899030e8e1f284d0033b50835bd3b168a\",
      \"exclusive_create\": true
    },
    {
      \"relative_path\": \"spikes/out/worker-integration-copy.py\",
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-integration-copy.py\",
      \"destination\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-integration-copy.py\",
      \"bytes\": 2225,
      \"sha256_before\": \"3d57d5bec2dc2a78550bfd75f72f1eb752c2f87e64c00322f0f29ad71ea60da6\",
      \"sha256_after\": \"3d57d5bec2dc2a78550bfd75f72f1eb752c2f87e64c00322f0f29ad71ea60da6\",
      \"sha256_destination\": \"3d57d5bec2dc2a78550bfd75f72f1eb752c2f87e64c00322f0f29ad71ea60da6\",
      \"exclusive_create\": true
    }
  ],
  \"limits\": [
    \"ignored-evidence-only\",
    \"original-absolute-paths-retained\",
    \"no-source-tests-tools-or-docs-modified\",
    \"no-campaigns-or-compilation-repeated\"
  ]
}
")
  (:PATH
   #A((98) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/arcdocdb.asd")
   :BYTES 6104 :SHA256 "5d616c52780bc2b1d55083bcb62800eaa0636f3f3236d48f0bb3821a8e631c83" :GIT-BLOB
   "3ad7c6b499003a8f332fa91b298fba575b0a8468" :TEXT
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
                             (:file \"cbor-package\") (:file \"cbor-header\")
                             (:file \"cbor-space\") (:file \"cbor-scan-input\")
                             (:file \"cbor-scan-stack\") (:file \"cbor-scan-items\")
                             (:file \"cbor-scan\")))
               (:module \"csn\" :serial t
                :components ((:file \"package\") (:file \"registry\")))
               (:module \"execution\" :serial t
                :components ((:file \"package\") (:file \"queue\") (:file \"writer\")
                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")
                             (:file \"ready-recycle\")
                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))
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
                             (:file \"group\") (:file \"executor\") (:file \"csn\")))
               (:module \"recovery\"
                :serial t
                :components ((:file \"package\") (:file \"scan\")
                             (:file \"decisions-package\") (:file \"decisions-types\")
                             (:file \"decisions-sort\") (:file \"decisions-radix\") (:file \"decisions-build\")
                             (:file \"decisions-query\")
                             (:file \"manifest-package\") (:file \"manifest-types\")
                             (:file \"manifest-decode\") (:file \"manifest-fold\")
                             (:file \"manifest-build\") (:file \"manifest-query\")
                             (:file \"inventory-types\") (:file \"inventory-build\")
                             (:file \"inventory-query\"))))
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
                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")
                             (:file \"cbor-structure-support\") (:file \"cbor-structure\")
                             (:file \"cbor-structure-threads\")))
               (:module \"csn\" :serial t
                :components ((:file \"support\") (:file \"registry\") (:file \"threads\")))
               (:module \"execution\" :serial t
                :components ((:file \"support\") (:file \"queue\") (:file \"threads\")
                             (:file \"handoff\") (:file \"ready\") (:file \"ready-recycle\") (:file \"worker\")))
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
                             (:file \"manifest\") (:file \"manifest-audit\")
                             (:file \"inventory-support\") (:file \"inventory\")))
               (:module \"wal\" :serial t
                :components ((:file \"support\") (:file \"builder\") (:file \"group\") (:file \"fault\")
                             (:file \"native\") (:file \"csn\") (:file \"csn-threads\"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
")
  (:PATH
   #A((116) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/README.md")
   :BYTES 3372 :SHA256 "faf354f521631b0735d31459717d3dfc08150e08d97f0f7afb782909d97dd11d" :GIT-BLOB
   "64e81ab228f7069989affd1b0f095629f0768d71" :TEXT "# Implementazione

Fondazioni introdotte dopo la richiesta dell'autore del 2026-10-08 di iniziare la scrittura
del codice. L'autorizzazione non equivale alla chiusura dei criteri della Fase 0 o alla
qualifica del motore completo.

| Modulo | Contratto e verifica | Codice |
|---|---|---|
| Fondazioni binarie | [Record v1/v2, CRC32C e lotti SEAL](fondazioni-binarie.md) | [`src/foundation/`](../../src/foundation/) |
| Testo UTF-8 | [Validazione limitata, pura e parallela](utf8.md) | [`src/codec/utf8.lisp`](../../src/codec/utf8.lisp) |
| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
| Struttura CBOR | [Item completo, UTF-8 e budget con scratch per worker](cbor-struttura.md) | [`src/codec/cbor-scan.lisp`](../../src/codec/cbor-scan.lisp) |
| CSN di Archivio | [Registro dei commit in corso e orizzonte](csn.md) | [`src/csn/`](../../src/csn/) |
| Metadati storage | [Header dei segmenti, EDIT e DECISION](metadati-storage.md) | [`src/storage/`](../../src/storage/) |
| Header dei log | [Identità e integrità di control e multiserie](header-log.md) | [`src/storage/log-header.lisp`](../../src/storage/log-header.lisp) |
| Segmenti compattati | [Prefisso CLOSED e record ordinari](segmenti-compattati.md) | [`src/storage/compaction-scan.lisp`](../../src/storage/compaction-scan.lisp) |
| Code dei writer | [MPSC locale, gettone e tratti limitati](code-writer.md) | [`src/execution/`](../../src/execution/) |
| Consegna dei writer | [Idle, pronto, in esecuzione e obbligo di scheduling](writer-handoff.md) | [`src/execution/handoff.lisp`](../../src/execution/handoff.lisp) |
| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
| Ricircolo dei writer pronti | [Scambio FIFO atomico a ring pieno](writer-recycle.md) | [`src/execution/ready-recycle.lisp`](../../src/execution/ready-recycle.lisp) |
| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |
| Confine I/O | [Append, pread e flush durevole](io.md) | [`src/io/`](../../src/io/) |
| Lotti WAL | [Formazione, SEAL e group commit](wal.md) | [`src/wal/`](../../src/wal/) |
| CSN dei lotti WAL | [Chiusura, token e risoluzione](wal-csn.md) | [`src/wal/csn.lisp`](../../src/wal/csn.lisp) |
| Scansione recovery | [Prefisso dei log e testimonianze SEAL](scansione-log.md) | [`src/recovery/`](../../src/recovery/) |
| Decisioni multiserie | [Tabella TXID, CSN e partecipanti](decisioni-multiserie.md) | [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) |
| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
| Inventario recovery | [Piano di riconciliazione dei nomi dei segmenti](inventario.md) | [`src/recovery/inventory-build.lisp`](../../src/recovery/inventory-build.lisp) |
| Ordinamento delle decisioni | [Radix misurato e query concorrenti](decisioni-radix-risultati.md) | [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) |

Le evidenze hanno un ambito esplicito: un test del codec non verifica transazioni,
durability, recovery o prestazioni del database.
")))
