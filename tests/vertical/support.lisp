;;;; Prova C4: orchestrazione esplicita, API di prodotto e processi separati.
;;; OWNER: namespace 0700 del parent; capacità e indice esclusivi del figlio.
;;; SHARED: nessuno; il solo passaggio fra processi è costituito dai file.
(defpackage #:arcdocdb.vertical.tests
  (:use #:cl)
  (:local-nicknames (#:io #:arcdocdb.io) (#:w #:arcdocdb.wal)
                   (#:s #:arcdocdb.series) (#:p #:arcdocdb.index.primary)
                   (#:g #:arcdocdb.get) (#:gd #:arcdocdb.get.directory)
                   (#:r #:arcdocdb.get.resolver) (#:a #:arcdocdb.active)
                   (#:c #:arcdocdb.control) (#:ra #:arcdocdb.recovery.active)
                   (#:dar #:arcdocdb.recovery.archive) (#:mf #:arcdocdb.recovery.manifest)
                   (#:b #:arcdocdb.binary) (#:f #:arcdocdb.storage.format))
  (:import-from #:arcdocdb.foundation.tests #:is)
  (:export #:run #:child-main))
(in-package #:arcdocdb.vertical.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defstruct (environment (:constructor %make-environment)) root version registry index scope view directory
  controller lease source sources active append (fds nil) (recovery-sets nil))

(define-condition oracle-value-mismatch (error) ()
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string "VERTICAL-ORACLE-MISMATCH: valore diverso dall'atteso indipendente." stream))))

(define-condition oracle-csn-mismatch (error)
  ((expected :initarg :expected :reader expected-csn)
   (observed :initarg :observed :reader observed-csn))
  (:report (lambda (condition stream)
             (format stream "VERTICAL-CSN-MISMATCH: atteso ~D, osservato ~D."
                     (expected-csn condition) (observed-csn condition)))))

(defun check-csn (expected high low)
  (let ((observed (logior (ash high 32) low)))
    (unless (= expected observed)
      (error 'oracle-csn-mismatch :expected expected :observed observed))))

(defun bytes (count &optional (value 0))
  (make-array count :element-type '(unsigned-byte 8) :initial-element value))
(defun key-bytes (id) (bytes 16 id))
(defun value-bytes (id) (bytes 23 (+ 128 id)))
(defun series-id () (bytes 16 41))
(defun archive-id () (bytes 16 73))
(defun leaf (env name) (merge-pathnames name (environment-root env)))

(defun owned (env file)
  (push file (environment-fds env)) file)
(defun input (env name)
  (multiple-value-bind (file size)
      (io:apri-lettura-nella-directory (environment-directory env) name
                                     :max-transfer 8192 :max-file-bytes 8192)
    (values (owned env file) size)))
(defun output (env name)
  (owned env (io:crea-temporaneo-nella-directory
              (environment-directory env) name :max-transfer 8192 :max-file-bytes 8192)))
(defun segment-leaf (id form)
  (string-downcase (format nil "~16,'0X.seg~A" id (ecase form (:temporary ".tmp") (:final "")))))
(defun segment-name (env id)
  (let ((final (segment-leaf id :final)) (temporary (segment-leaf id :temporary)))
    (cond ((probe-file (leaf env final)) final)
          ((probe-file (leaf env temporary)) temporary)
          (t (error "Segmento ~D assente." id)))))
(defun file-image (path)
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let* ((size (file-length stream)) (buffer (bytes size)))
      (is (<= size 8192))
      (is (= size (read-sequence buffer stream))) buffer)))

(defun make-environment (root version &key (initial-csn 0))
  (is (typep initial-csn '(unsigned-byte 64)))
  (let* ((registry (arcdocdb.csn:crea-registro-csn :capacity 16
                    :initial-high (ldb (byte 32 32) initial-csn)
                    :initial-low (ldb (byte 32 0) initial-csn)))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot registry 4 20 5))
         (epochs (arcdocdb.epochs:crea-registro-epoche 1 4))
         (scope (g:crea-ambito-get epochs snapshots))
         (index (p:crea-indice-primario :capacity 16 :arena-bytes 1024 :max-depth 1
                   :directory-budget-bytes 4096 :fragment-budget-bytes 8192
                   :hash-seed-high #x12345678 :hash-seed-low #x9abcdef0))
         (env (%make-environment :root root :version version :registry registry
                               :index index :scope scope)))
    (setf (environment-view env) (g:crea-vista-get-serie scope index nil (series-id))
          (environment-directory env) (owned env (io:apri-directory root)))
    env))

(defun close-environment (env)
  (when (environment-lease env)
    (s:rilascia-controllore-serie (environment-controller env) (environment-lease env))
    (setf (environment-lease env) nil))
  (dolist (pair (environment-recovery-sets env)) (mf:chiudi-fonti-recovery (cdr pair)))
  (dolist (file (environment-fds env)) (io:chiudi file)))

(defun prepare-active (env id)
  (let* ((name (segment-leaf id :temporary)) (append (output env name))
         (input (input env name)))
    (values (a:prepara-segmento-attivo (environment-view env) input append
                (environment-directory env) id 0 (bytes 64) (bytes 64)
                :version (environment-version env)) append)))

(defun start-active (env prepared append maps)
  (setf (environment-active env) prepared (environment-append env) append
        (environment-controller env)
        (s:crea-controllore-serie (environment-registry env)
          (a:log-segmento-attivo-preparato prepared) :capacity 8 :next-offset 64)
        (environment-lease env) (s:acquisisci-controllore-serie (environment-controller env))
        (environment-source env)
        (a:crea-sorgente-get-preparata (environment-controller env) (environment-lease env) prepared)
        (environment-sources env)
        (gd:crea-fonti-get-serie (gd:crea-directory-get-serie (environment-view env) maps)))
  (is (environment-lease env))
  (gd:inizializza-fonti-get-attive (environment-source env) (environment-lease env)
                                (environment-sources env)))

(defun empty-edit (id)
  (let ((payload (bytes 24)))
    (is (= 24 (f:scrivi-valore-edit payload 0 (1+ id) id (bytes 0) 0 (bytes 0) :completo t)))
    payload))

(defun prepare-control (env plan)
  (let* ((append (output env "control.log.tmp")) (input (input env "control.log.tmp")))
    (c:prepara-checkpoint-control plan input append (environment-directory env) (bytes 8192)
                                 :chunk-bytes 127)))

(defun bootstrap (env prepared)
  "Il bootstrap C4 possiede il namespace nuovo: nessun control precedente da sostituire."
  (let ((plan (c:crea-checkpoint-control prepared (empty-edit 1) 1)))
    (prepare-control env plan)
    (io:rinomina-nella-directory (environment-directory env) "control.log.tmp" "control.log")
    (is (zerop (io:durable-flush (environment-directory env)))))
  (let ((header (bytes 64)) (append (output env "multiserie.tmp")))
    (is (= 64 (f:scrivi-header-log header 0 :multiserie (archive-id) :version (environment-version env))))
    (is (= 64 (io:append-esatto append header 0 64)))
    (is (= 64 (io:durable-flush append)))
    (io:rinomina-nella-directory (environment-directory env) "multiserie.tmp" "multiserie.log")
    (is (zerop (io:durable-flush (environment-directory env))))))

(defun publish-index (env id offset size csn kind key)
  "Coordinamento seriale C4 dopo la pubblicazione della radice; niente atomicità concorrente implicita."
  (let* ((index (environment-index env)) (scratch (p:crea-contesto-indice)))
    (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 (length key))
      (let ((fragment (p:frammento-corrente-indice index high)))
        (ecase kind
          (1 (let ((words (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
               (setf (aref words 0) csn (aref words 1) (logior (ash id 32) offset)
                     (aref words 2) (logior (ash (length key) 32) (ash 1 48)) (aref words 3) size)
               (p:pubblica-chiave-indice index fragment key 0 (length key) high low words scratch)))
          (2 (unless (p:rimuovi-chiave-indice index fragment key 0 (length key) high low scratch)
               ;; NIL è l'assenza preesistente: l'oracolo GET deve confermarla.
               (check-get env key nil))))))))

(defun commit-record (env id kind key value expected-csn)
  (let* ((controller (environment-controller env)) (lease (environment-lease env))
         (source (environment-source env)) (previous (s:leggi-radice-serie controller))
         (start (io:posizione-scritta (environment-append env)))
         (batch (w:crea-lotto :segment id :version (environment-version env) :capacity 512 :max-records 1))
         (log (a:log-segmento-attivo-preparato (environment-active env))))
    (w:aggiungi-record batch kind key value)
    (r:verifica-capienza-get-attiva source lease batch previous)
    (multiple-value-bind (sealed-bytes high low)
        (w:sigilla-lotto-con-csn batch (environment-registry env) log start
                               (io:posizione-durevole (environment-append env)))
      (is (<= 56 sealed-bytes 512))
      (check-csn expected-csn high low))
    (multiple-value-bind (event generation root)
        (gd:registra-lotto-fonti-get-attivo source lease batch previous (environment-sources env) :group)
      (is (typep root 'r:radice-get-attiva))
      (let ((group (w:crea-gruppo log :max-lots 1)))
        (s:inizia-io-commit-serie controller lease event generation)
        (w:aggiungi-lotto group batch) (w:chiudi-gruppo group)
        (w:scrivi-gruppo group) (w:sincronizza-gruppo group)
        (multiple-value-bind (status high low) (s:pubblica-commit-serie controller lease event generation)
          (is (eq status :risolto)) (check-csn expected-csn high low))
        (publish-index env id start (+ 24 (length key) (length value)) expected-csn kind key)
        (s:completa-io-commit-serie controller lease event generation)
        (w:riusa-gruppo group) (s:riusa-commit-serie controller lease event generation)))))

(defun check-get (env key expected &optional directory)
  (let ((context (g:crea-contesto-get (environment-scope env) 0 :record-bytes 256 :budget-payload 1024))
        (buffer (bytes 31 204)))
    (unwind-protect
         (let ((state (g:avvia-get context (environment-view env) key nil 0 10)))
           (if expected
               (progn
                 (is (eq state :candidate))
                 (is (eq :segment (if directory (gd:leggi-record-directory-get context directory)
                                     (gd:leggi-record-serie-get context (environment-controller env)))))
                 (is (= (+ 3 (length expected)) (g:copia-valore-get context buffer 3)))
                 (unless (equalp expected (subseq buffer 3 (+ 3 (length expected))))
                   (error 'oracle-value-mismatch))
                 (is (every (lambda (byte) (= byte 204)) (subseq buffer 0 3)))
                 (is (every (lambda (byte) (= byte 204)) (subseq buffer (+ 3 (length expected))))))
               (progn (is (eq state :absent)) (is (every (lambda (byte) (= byte 204)) buffer))))
           (is (equal (list (if expected :found :absent) (if expected (length expected) 0))
                      (multiple-value-list (g:concludi-get context 11)))))
      (g:abbandona-get context))))

(defun read-control (env)
  (multiple-value-bind (input size) (input env "control.log")
    (c:leggi-control-recuperato (environment-view env) input size (bytes size)
                              :max-bytes 8192 :max-batches 4 :max-edits 4 :max-segmenti 8)))

(defun read-decisions (env archive)
  (multiple-value-bind (input size) (input env "multiserie.log")
    (dar:leggi-decisioni-recuperate archive input size (bytes size) :max-bytes 8192)))

(defun recovery-sources (env manifest)
  "Set posseduto per manifest canonico C4; chiuso soltanto dopo tutti i reader."
  (or (cdr (assoc manifest (environment-recovery-sets env) :test #'eq))
      (let ((sources (mf:apri-fonti-recovery
                      manifest (environment-directory env) :max-files 16 :max-segmenti 8
                      :max-names 64 :max-total-name-bytes 8192 :max-name-bytes 255
                      :max-transfer 8192 :max-file-bytes 8192 :max-total-file-bytes 65536)))
        (push (cons manifest sources) (environment-recovery-sets env)) sources)))

(defun recovery-input (sources wanted)
  (dotimes (i (mf:numero-fonti-recovery sources))
    (multiple-value-bind (id state form file size) (mf:fonte-recovery sources i)
      (declare (ignore state form))
      (when (= id wanted) (return-from recovery-input (values file size)))))
  (error "Fonte recovery ~D assente dal set completo." wanted))

(defun read-active (env control)
  (let* ((archive (dar:crea-archivio-recovery (environment-scope env) (archive-id)))
         (decisions (read-decisions env archive))
         (manifest (c:manifest-control-recuperato control))
         (id (mf:segmento-attivo manifest)))
    (is (zerop (dar:numero-decisioni-recuperate decisions)))
    (multiple-value-bind (input size) (recovery-input (recovery-sources env manifest) id)
      (dar:leggi-active-con-decisioni control input size decisions
                                    (bytes size) :max-bytes 8192 :max-records 32))))

(defun closed-maps (env manifest)
  (let ((maps nil) (sources (recovery-sources env manifest)))
    (dotimes (i (mf:numero-fonti-recovery sources))
      (multiple-value-bind (id state form file size) (mf:fonte-recovery sources i)
        (declare (ignore form size))
        (when (eq state :closed)
          (push (r:crea-mappa-segmento-get (environment-view env) file
                   manifest id (bytes 8192) :max-bytes 8192 :max-records 32 :max-batches 16
                   :max-batch-records 4 :max-batch-bytes 8192) maps))))
    (coerce (nreverse maps) 'simple-vector)))

(defun next-id (env manifest)
  "Un solo inventario di prodotto sul parent posseduto; otto ID restano il budget C4."
  (multiple-value-bind (id next plan)
      (mf:scegli-id-segmento-recovery-directory
       manifest (environment-directory env) :max-files 16 :max-segmenti 8
       :max-names 64 :max-total-name-bytes 8192 :max-name-bytes 255)
    (is (= next (1+ id))) (is (<= id 8))
    (is (eq :ready (mf:stato-riconciliazione plan)))
    id))

(defun checkpoint (env &optional stop-before-publication)
  (let* ((control (read-control env)) (recovered (read-active env control))
         (id (next-id env (c:manifest-control-recuperato control))))
    (multiple-value-bind (prepared append) (prepare-active env id)
      (when (probe-file (leaf env "control.log.tmp"))
        (io:rinomina-nella-directory (environment-directory env) "control.log.tmp" "unpublished-control.tmp")
        (is (zerop (io:durable-flush (environment-directory env)))))
      (let* ((stamp (1+ (b:leggi-u64 (file-image (leaf env "control.log")) 80)))
             (plan (arcdocdb.recovery.checkpoint:crea-checkpoint-da-active recovered prepared stamp))
             (next (prepare-control env plan)))
        (when stop-before-publication (kill-writer :checkpoint-prepared))
        (ra:pubblica-control-da-active next recovered)
        (values prepared append (c:manifest-control-preparato next))))))
