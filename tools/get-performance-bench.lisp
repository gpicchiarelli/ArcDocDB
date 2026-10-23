;;;; C4 GET corrente; esecuzione solo dal padre, via record-command dopo source freeze.
;;;; --self-test|--bench|--negative-fixture|--negative-self-test [directory-nuova/]
;;; OWNER: main possiede fixture/report; worker i possiede contesto EBR i e output i.
;;; SHARED: un ambito, indice, cache e FD readonly per fixture; heap dell'intero processo.
;;; REQ: REQ-IDX-003 REQ-CCH-002 REQ-CMP-007 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(defpackage #:arcdocdb.get-performance.bench (:use #:cl))
(in-package #:arcdocdb.get-performance.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +count+ 20000)
(defconstant +warmup+ 1000)
(defconstant +replicas+ 5)
(defconstant +keys+ 8)
(defconstant +sentinel+ 215)
(defconstant +window-seconds+ 30)
(defconstant +run-seconds+ 600)
(defconstant +plain-limit+ 1048576)
(defvar *owned-threads* (make-array 4 :initial-element nil))
(defvar *run-directory* nil)
(deftype octets () '(simple-array (unsigned-byte 8) (*)))

(define-condition bench-failure (error)
  ((rule :initarg :rule :reader failure-rule)
   (detail :initarg :detail :reader failure-detail))
  (:report (lambda (condition stream)
             (format stream "tools/get-performance-bench.lisp ~A: ~A"
                     (failure-rule condition) (failure-detail condition)))))

(defun fail (rule control &rest arguments)
  (error 'bench-failure :rule rule :detail (apply #'format nil control arguments)))

(defun diagnostic (condition)
  "Errore bounded e leggibile anche per condizioni del prodotto o timeout."
  (let ((string (format nil "tools/get-performance-bench.lisp COD-61: ~A" condition)))
    (subseq string 0 (min 2048 (length string)))))

(defun api (package name)
  "Risoluzione cold di soli simboli pubblici, dopo il load ASDF standard."
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq visibility :external) (fboundp symbol))
      (fail "COD-61" "API pubblica assente: ~A:~A." package name))
    (symbol-function symbol)))

(defun call-api (package name &rest args)
  (apply (api package name) args))

(defun load-product ()
  "Nessuna suite di test caricata; warning di compilazione sono diagnostiche COD-01."
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (fail "COD-01" "~A" condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb" :force t)))
  (api "ARCDOCDB.GET" "AVVIA-GET"))

(defun bytes (length &optional (initial 0))
  (make-array length :element-type '(unsigned-byte 8) :initial-element initial))

(defstruct (worker (:copier nil))
  (id 0 :type fixnum) (context nil) (reader nil)
  (output (bytes 0) :type octets))

(defstruct (fixture (:copier nil))
  (size 16 :type fixnum) (csn 7 :type integer)
  scope epochs index cache file path cache-view segment-view cache-segment segment
  (valid-bytes 0 :type fixnum)
  (keys #() :type simple-vector) (absent #() :type simple-vector)
  (values #() :type simple-vector) (checksums #() :type simple-vector)
  (workers #() :type simple-vector))

(defstruct (raw (:copier nil))
  (completed 0 :type fixnum) (checksum 0 :type fixnum) (failure nil))
(defstruct (sample (:copier nil))
  (ticks 0 :type integer) (heap 0 :type integer) (failure nil))

(defun make-key (ordinal absent-p)
  (let ((key (bytes 16)))
    (dotimes (i 16) (setf (aref key i) (mod (+ 19 (* i 13) ordinal) 251)))
    (setf (aref key 0) (if absent-p 128 64) (aref key 1) ordinal)
    key))

(defun make-input-fixture (size csn directory)
  "Otto PUT v2 non prepared; prefisso sintetico committed calcolato prima dei reader."
  (unless (and (member size '(16 256 4096)) (member csn '(7 #xffffffffffffffff)))
    (fail "COD-60" "fixture fuori preregistrazione."))
  (let* ((record-size (+ 24 16 size))
         (valid (+ 64 (* +keys+ record-size)))
         (path (merge-pathnames (format nil "fixture-~D-~D.tmp" size csn) directory))
         (identity (bytes 16 37)) (header (bytes 64)) (record (bytes record-size))
         (epochs (call-api "ARCDOCDB.EPOCHS" "CREA-REGISTRO-EPOCHE" 4 2))
         (csns (call-api "ARCDOCDB.CSN" "CREA-REGISTRO-CSN" :capacity 1
                         :initial-high (ldb (byte 32 32) csn) :initial-low (ldb (byte 32 0) csn)))
         (snapshots (call-api "ARCDOCDB.MVCC" "CREA-REGISTRO-SNAPSHOT" csns 1
                             (* +run-seconds+ internal-time-units-per-second) 1))
         (scope (call-api "ARCDOCDB.GET" "CREA-AMBITO-GET" epochs snapshots))
         (index (call-api "ARCDOCDB.INDEX.PRIMARY" "CREA-INDICE-PRIMARIO"
                         :capacity 16 :arena-bytes 128 :max-depth 0
                         :directory-budget-bytes 8 :fragment-budget-bytes 4096
                         :hash-seed-high #x01234567 :hash-seed-low #x89abcdef))
         (cache (call-api "ARCDOCDB.CACHE" "CREA-CACHE-SERIE"
                         (make-array 1 :element-type '(unsigned-byte 32)
                                       :initial-element (if (= size 4096) 8192 1024))
                         (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)
                         70000 :stripes 1))
         (writer (call-api "ARCDOCDB.INDEX.PRIMARY" "CREA-CONTESTO-INDICE"))
         (content (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
         (fixture (make-fixture :size size :csn csn :scope scope :epochs epochs :index index
                                :cache cache :path path :valid-bytes valid :keys (make-array +keys+)
                                :absent (make-array +keys+) :values (make-array +keys+)
                                :checksums (make-array +keys+) :workers (make-array 4)))
         (append-file nil) (complete nil))
    (unwind-protect
         (progn
           (unless (= 64 (call-api "ARCDOCDB.STORAGE.FORMAT" "SCRIVI-HEADER-SEGMENTO"
                                  header 0 identity 17 0 :version 2 :origine 2))
             (fail "COD-60" "header inatteso."))
           (setf append-file (call-api "ARCDOCDB.IO" "CREA-TEMPORANEO" path
                                      :max-transfer (max 64 record-size) :max-file-bytes valid))
           (unless (= 64 (call-api "ARCDOCDB.IO" "APPEND-ESATTO" append-file header 0 64))
             (fail "COD-60" "append header inatteso."))
           (dotimes (j +keys+)
             (let ((key (make-key j nil)) (value (bytes size)) (sum 1)
                   (offset (+ 64 (* j record-size))))
               ;; Oracolo indipendente dai byte restituiti dal prodotto; tutti i byte variano.
               (dotimes (k size)
                 (let ((byte (mod (+ 11 (* j 17) (* k 29)) 251)))
                   (setf (aref value k) byte) (incf sum byte)))
               (setf (svref (fixture-keys fixture) j) key
                     (svref (fixture-absent fixture) j) (make-key j t)
                     (svref (fixture-values fixture) j) value
                     (svref (fixture-checksums fixture) j) sum)
               (unless (= record-size (call-api "ARCDOCDB.RECORD" "SCRIVI-RECORD-PAROLE"
                                                record 0 1 (ldb (byte 32 32) csn)
                                                (ldb (byte 32 0) csn) key value :version 2 :flags 0))
                 (fail "COD-60" "dimensione record inattesa."))
               (unless (= (+ offset record-size)
                          (call-api "ARCDOCDB.IO" "APPEND-ESATTO" append-file record 0 record-size))
                 (fail "COD-60" "frontiera append inattesa."))
               (setf (aref content 0) csn (aref content 1) (logior (ash 17 32) offset)
                     (aref content 2) (logior (ash 16 32) (ash 1 48))
                     (aref content 3) record-size (aref content 4) 0)
               (multiple-value-bind (high low)
                   (call-api "ARCDOCDB.INDEX.PRIMARY" "DIGEST-CHIAVE-INDICE" index key 0 16)
                 (unless (null (call-api "ARCDOCDB.INDEX.PRIMARY" "PUBBLICA-CHIAVE-INDICE" index
                                         (call-api "ARCDOCDB.INDEX.PRIMARY" "FRAMMENTO-CORRENTE-INDICE" index high)
                                         key 0 16 high low content writer))
                   (fail "COD-60" "pubblicazione indice inattesa.")))
               (multiple-value-bind (status evicted scan)
                   (call-api "ARCDOCDB.CACHE" "INSERISCI-RECORD-CACHE" cache 0 17 offset record-size
                             key (ldb (byte 32 32) csn) (ldb (byte 32 0) csn) 0 record 0 :version 2)
                 (unless (and (eq status :inserted) (null evicted) (null scan))
                   (fail "COD-60" "popolamento cache: ~S." status)))))
           (call-api "ARCDOCDB.IO" "CHIUDI" append-file) (setf append-file nil)
           (setf (fixture-file fixture) (call-api "ARCDOCDB.IO" "APRI-LETTURA" path :max-transfer (max 64 record-size))
                 (fixture-cache-view fixture) (call-api "ARCDOCDB.GET" "CREA-VISTA-GET-SERIE" scope index cache identity)
                 (fixture-segment-view fixture) (call-api "ARCDOCDB.GET" "CREA-VISTA-GET-SERIE" scope index nil identity)
                 (fixture-cache-segment fixture) (call-api "ARCDOCDB.GET" "CREA-SEGMENTO-GET"
                                                          (fixture-cache-view fixture) (fixture-file fixture) 17 header)
                 (fixture-segment fixture) (call-api "ARCDOCDB.GET" "CREA-SEGMENTO-GET"
                                                    (fixture-segment-view fixture) (fixture-file fixture) 17 header))
           (dotimes (id 4)
             (setf (svref (fixture-workers fixture) id)
                   (make-worker :id id :context (call-api "ARCDOCDB.GET" "CREA-CONTESTO-GET" scope id
                                                         :record-bytes record-size :budget-payload (+ record-size 4096))
                                :reader (call-api "ARCDOCDB.EPOCHS" "CONTESTO-EPOCA" epochs id)
                                :output (bytes (+ size 2) +sentinel+))))
           (setf complete t)
           fixture)
      (when append-file (call-api "ARCDOCDB.IO" "CHIUDI" append-file))
      (unless complete
        (when (fixture-file fixture) (call-api "ARCDOCDB.IO" "CHIUDI" (fixture-file fixture)))
        (when (probe-file path) (delete-file path))))))

(defun dispose-fixture (fixture)
  "Il controller chiude solo dopo quiescenza; mai chiude un FD usato da worker vivo."
  (when (some (lambda (thread) (and thread (sb-thread:thread-alive-p thread))) *owned-threads*)
    (fail "COD-61" "cleanup senza quiescenza; FD lasciato al confine processo."))
  (call-api "ARCDOCDB.IO" "CHIUDI" (fixture-file fixture))
  (when (probe-file (fixture-path fixture)) (delete-file (fixture-path fixture))))

(defun cycle-total (fixture scenario)
  (if (eq scenario :absent)
      (* +keys+ (+ 2 (* +sentinel+ (fixture-size fixture))))
      (reduce #'+ (fixture-checksums fixture))))

(defun make-cycle (fixture worker scenario)
  "Tutte le funzioni risolte prima del clock; nessun boxing esplicito del CSN nel driver caldo."
  (let* ((start (api "ARCDOCDB.GET" "AVVIA-GET")) (probe (api "ARCDOCDB.GET" "SONDA-CACHE-GET"))
         (read-record (api "ARCDOCDB.GET" "LEGGI-RECORD-GET")) (copy-value (api "ARCDOCDB.GET" "COPIA-VALORE-GET"))
         (finish (api "ARCDOCDB.GET" "CONCLUDI-GET")) (abandon (api "ARCDOCDB.GET" "ABBANDONA-GET"))
         (state (api "ARCDOCDB.GET" "STATO-CONTESTO-GET")) (active (api "ARCDOCDB.EPOCHS" "EPOCA-ATTIVA-P"))
         (context (worker-context worker)) (reader (worker-reader worker)) (output (worker-output worker))
         (size (fixture-size fixture)) (cursor (worker-id worker))
         (miss-p (eq scenario :absent)) (cache-p (eq scenario :cache-hit))
         (keys (if miss-p (fixture-absent fixture) (fixture-keys fixture)))
         (values (fixture-values fixture))
         (view (if cache-p (fixture-cache-view fixture) (fixture-segment-view fixture)))
         (segment (if cache-p (fixture-cache-segment fixture) (fixture-segment fixture)))
         (valid (fixture-valid-bytes fixture)))
    (declare (type octets output) (type fixnum size cursor valid))
    (lambda ()
      (let ((j cursor) (sum (if miss-p 2 1)))
        (declare (type fixnum j sum))
        (fill output +sentinel+)
        (unwind-protect
             (progn
               (unless (eq (funcall start context view (svref keys j) nil 0 (get-internal-real-time))
                           (if miss-p :absent :candidate))
                 (fail "COD-60" "avvio GET inatteso, scenario ~S." scenario))
               (unless miss-p
                 (unless (eq (funcall probe context segment valid 0) (if cache-p :hit :disabled))
                   (fail "COD-60" "sonda GET inattesa, scenario ~S." scenario))
                 (unless cache-p
                   (multiple-value-bind (source cache insertion evicted scan)
                       (funcall read-record context segment valid 0)
                     (unless (and (eq source :segment) (eq cache :disabled)
                                  (eq insertion :not-attempted) (null evicted) (null scan))
                       (fail "COD-60" "fonte segmento/cache inattesa."))))
                 (unless (= (funcall copy-value context output 1) (1+ size))
                   (fail "COD-60" "fine copia GET inattesa.")))
               (multiple-value-bind (result length) (funcall finish context (get-internal-real-time))
                 (unless (and (eq result (if miss-p :absent :found)) (= length (if miss-p 0 size)))
                   (fail "COD-60" "conclusione GET inattesa: ~S, ~D." result length)))
               (unless (and (eq (funcall state context) :idle) (not (funcall active reader)))
                 (fail "COD-60" "GET non ha rilasciato contesto/EBR."))
               (unless (and (= (aref output 0) +sentinel+) (= (aref output (1+ size)) +sentinel+))
                 (fail "COD-60" "GET ha modificato le guardie dell'output."))
               (let ((expected (the octets (svref values j))))
                 (dotimes (k size)
                   (let ((byte (aref output (1+ k))))
                     (unless (= byte (if miss-p +sentinel+ (aref expected k)))
                       (fail "COD-60" "byte output errato a ~D, scenario ~S." k scenario))
                     (incf sum byte)))))
          (funcall abandon context))
        (setf cursor (logand (1+ cursor) 7))
        sum))))

(defun run-loop (cycle count raw)
  "Una chiamata per iterazione, senza retry; contatori preallocati dopo validazione completa."
  (declare (type fixnum count) (type raw raw))
  (handler-case
      (dotimes (i count)
        (incf (raw-checksum raw) (the fixnum (funcall cycle)))
        (setf (raw-completed raw) (1+ i)))
    (error (condition) (setf (raw-failure raw) condition)))
  raw)

(defun observe (action sample)
  "Un solo intervallo globale, senza GC esplicito; include il confine diagnostico dell'azione."
  (let ((ticks (get-internal-real-time)) (heap (sb-ext:get-bytes-consed)))
    (unwind-protect
         (handler-case (funcall action)
           (error (condition) (setf (sample-failure sample) condition)))
      (setf (sample-heap sample) (- (sb-ext:get-bytes-consed) heap)
            (sample-ticks sample) (- (get-internal-real-time) ticks))))
  sample)

(defun require-fields (record keys)
  (unless (and (listp record) (evenp (length record))
               (loop for tail on record by #'cddr always (keywordp (car tail))))
    (fail "COD-61" "record non è una plist di keyword."))
  (dolist (key keys)
    (unless (nth-value 0 (get-properties record (list key)))
      (fail "COD-61" "metrica mancante: ~S." key))))

(defun worker-metric (raw id count expected)
  (list :worker-id id :status (if (raw-failure raw) :failed :ok)
        :requested count :completed (raw-completed raw) :checksum (raw-checksum raw)
        :expected-checksum expected :diagnostic (when (raw-failure raw) (diagnostic (raw-failure raw)))))

(defun window-metric (sample raws execution scenario size csn replica count cycle-sum)
  (let* ((workers (length raws)) (expected (* (floor count +keys+) cycle-sum))
         (ticks (sample-ticks sample)) (seconds (/ ticks (float internal-time-units-per-second 1d0)))
         (completed (reduce #'+ raws :key #'raw-completed))
         (checksum (reduce #'+ raws :key #'raw-checksum))
         (failed (or (sample-failure sample) (some #'raw-failure raws))))
    (list :execution execution :scenario scenario :value-bytes size :key-bytes 16 :csn csn :replica replica
          :worker-count workers :count-per-worker count :requested (* workers count) :completed completed
          :checksum checksum :checksum-per-eight cycle-sum :expected-checksum (* workers expected)
          :raw-ticks ticks :seconds seconds :heap-bytes (sample-heap sample)
          :time-quality (if (zerop ticks) :below-resolution :measured)
          :ops-per-second (when (plusp ticks) (/ completed seconds))
          :counter-scope :whole-process :thread-setup-in-window (eq execution :parallel)
          :status (if failed :failed :ok) :diagnostic (when failed (diagnostic failed))
          :workers (loop for raw across raws for id from 0 collect (worker-metric raw id count expected)))))

(defun validate-window (record)
  "Nessuna soglia prestazionale o attribuzione dello heap; esige schema, tempi e checksum."
  (require-fields record '(:execution :scenario :value-bytes :key-bytes :csn :replica :worker-count
                          :count-per-worker :requested :completed :checksum :checksum-per-eight
                          :expected-checksum :raw-ticks :seconds :heap-bytes :time-quality
                          :ops-per-second :counter-scope :thread-setup-in-window :status :diagnostic :workers))
  (let* ((count (getf record :count-per-worker)) (workers (getf record :worker-count))
         (ticks (getf record :raw-ticks)) (heap (getf record :heap-bytes))
         (execution (getf record :execution)) (cycle-sum (getf record :checksum-per-eight)))
    (unless (and (member execution '(:serial :parallel))
                 (member (getf record :scenario) '(:cache-hit :segment :absent))
                 (member (getf record :value-bytes) '(16 256 4096)) (eql (getf record :key-bytes) 16)
                 (member (getf record :csn) '(7 #xffffffffffffffff))
                 (typep (getf record :replica) '(integer 0 4)) (member workers '(1 2 4))
                 (or (eq execution :parallel) (= workers 1))
                 (typep count '(integer 8 20000)) (zerop (mod count +keys+))
                 (typep ticks '(integer 0)) (typep heap '(integer 0)) (typep cycle-sum '(integer 1))
                 (eq (getf record :counter-scope) :whole-process)
                 (eq (getf record :thread-setup-in-window) (eq execution :parallel))
                 (eq (getf record :status) :ok) (null (getf record :diagnostic))
                 (eql (getf record :requested) (* workers count))
                 (eql (getf record :completed) (* workers count))
                 (eql (getf record :expected-checksum) (* workers (floor count +keys+) cycle-sum))
                 (eql (getf record :checksum) (getf record :expected-checksum))
                 (eql (getf record :seconds) (/ ticks (float internal-time-units-per-second 1d0)))
                 (eq (getf record :time-quality) (if (zerop ticks) :below-resolution :measured))
                 (eql (getf record :ops-per-second)
                      (when (plusp ticks) (/ (getf record :completed) (getf record :seconds))))
                 (= workers (length (getf record :workers))))
      (fail "COD-61" "finestra incompleta o metriche incoerenti."))
    (loop for worker in (getf record :workers) for id from 0 do
      (require-fields worker '(:worker-id :status :requested :completed :checksum :expected-checksum :diagnostic))
      (unless (and (eql (getf worker :worker-id) id) (eq (getf worker :status) :ok)
                   (null (getf worker :diagnostic)) (eql (getf worker :requested) count)
                   (eql (getf worker :completed) count)
                   (eql (getf worker :checksum) (* (floor count +keys+) cycle-sum))
                   (eql (getf worker :expected-checksum) (getf worker :checksum)))
        (fail "COD-61" "worker ~D incompleto o checksum errato." id))))
  record)

(defun remaining (deadline)
  (/ (max 0 (- deadline (get-internal-real-time))) (float internal-time-units-per-second 1d0)))

(defun stop-workers ()
  "Errore/timeout: termina solo i thread propri; join bounded prima di ogni lettura dei raw."
  (dotimes (i 4)
    (let ((thread (svref *owned-threads* i)))
      (when (and thread (sb-thread:thread-alive-p thread)) (sb-thread:terminate-thread thread))))
  (dotimes (i 4)
    (let ((thread (svref *owned-threads* i)))
      (when thread
        (sb-thread:join-thread thread :timeout 2 :default :cleanup-timeout)
        (when (sb-thread:thread-alive-p thread) (fail "COD-61" "worker ~D non quiescente." i))
        (setf (svref *owned-threads* i) nil)))))

(defun run-window (fixture scenario execution workers replica count warmup)
  "Fixture, closure, semafori, raw e nomi preallocati; setup thread e join inclusi nel parallelo."
  (let* ((cycles (make-array workers)) (raws (make-array workers)) (entries (make-array workers))
         (names (make-array workers)) (sample (make-sample))
         (ready (sb-thread:make-semaphore :count 0)) (start (sb-thread:make-semaphore :count 0))
         (deadline 0))
    (dotimes (id workers)
      (let ((cycle (make-cycle fixture (svref (fixture-workers fixture) id) scenario)) (raw (make-raw)))
        (setf (svref cycles id) cycle (svref raws id) raw
              (svref names id) (format nil "get-performance-~D" id)
              (svref entries id)
              (lambda ()
                (handler-case
                    (progn
                      (sb-thread:signal-semaphore ready)
                      (unless (sb-thread:wait-on-semaphore start :timeout (remaining deadline))
                        (fail "COD-61" "deadline start worker."))
                      (run-loop cycle count raw))
                  (error (condition) (setf (raw-failure raw) condition)))
                :completed))
        ;; Warmup nel main con ownership esclusiva; identici buffer/ciclo e pagecache riscaldata.
        (dotimes (i warmup) (funcall cycle))))
    (let ((action
            (if (eq execution :serial)
                (lambda () (run-loop (svref cycles 0) count (svref raws 0)))
                (lambda ()
                  (unwind-protect
                       (progn
                         (dotimes (id workers)
                           (setf (svref *owned-threads* id)
                                 (sb-thread:make-thread (svref entries id) :name (svref names id))))
                         (dotimes (id workers)
                           (unless (sb-thread:wait-on-semaphore ready :timeout (remaining deadline))
                             (fail "COD-61" "deadline ready worker ~D." id)))
                         (sb-thread:signal-semaphore start workers)
                         (dotimes (id workers)
                           (unless (eq :completed (sb-thread:join-thread (svref *owned-threads* id)
                                                                        :timeout (remaining deadline) :default :timeout))
                             (fail "COD-61" "deadline join worker ~D." id))))
                    (stop-workers))))))
      (sb-ext:gc :full t)
      (setf deadline (+ (get-internal-real-time) (* +window-seconds+ internal-time-units-per-second)))
      ;; Il timer è installato prima dei contatori, anche per il seriale.
      (handler-case (sb-ext:with-timeout +window-seconds+ (observe action sample))
        (sb-ext:timeout (condition) (setf (sample-failure sample) condition))))
    (when (some (lambda (thread) (and thread (sb-thread:thread-alive-p thread))) *owned-threads*)
      (fail "COD-61" "raw non leggibile: worker ancora vivo."))
    (window-metric sample raws execution scenario (fixture-size fixture) (fixture-csn fixture)
                   replica count (cycle-total fixture scenario))))

(defun validate-publication-header (data)
  "Contratto comune del collector, anche per ciascuna foglia self-test."
  (require-fields data '(:schema-version :kind :status))
  (unless (eql (getf data :schema-version) 1)
    (fail "COD-61" "schema-version della foglia deve essere 1."))
  data)

(defun write-data (data directory leaf)
  "Plain UTF-8, meno di un MiB; riletto come dati con READ-EVAL NIL, mai LOAD."
  (validate-publication-header data)
  (let* ((path (merge-pathnames leaf directory))
         (text (with-output-to-string (stream)
                 (let ((*print-readably* t) (*print-pretty* t) (*print-length* nil) (*print-level* nil))
                   (write data :stream stream) (terpri stream))))
         (octets (sb-ext:string-to-octets text :external-format :utf-8)))
    (unless (< (length octets) +plain-limit+) (fail "COD-61" "report oltre budget plain: ~A." leaf))
    (with-open-file (stream path :direction :output :element-type '(unsigned-byte 8)
                           :if-exists :supersede :if-does-not-exist :create)
      (write-sequence octets stream))
    (let ((stored (arcdocdb.evidence:read-evidence path :max-expanded-bytes (1- +plain-limit+))))
      (validate-publication-header stored)
      (unless (equal data stored) (fail "COD-61" "rilettura diversa: ~A." leaf))))
  data)

(defun capture-run (report function)
  (handler-case
      (progn (funcall function) (setf (getf report :status) :ok (getf report :exit-code) 0))
    (error (condition)
      (setf (getf report :status) :failed (getf report :exit-code) 1
            (getf report :diagnostic) (diagnostic condition))))
  report)

(defun expect-rejection (function)
  (let ((rejected nil))
    (handler-case (funcall function)
      (bench-failure (condition)
        (unless (and (string= (failure-rule condition) "COD-61")
                     (search "tools/get-performance-bench.lisp" (princ-to-string condition)))
          (error condition))
        (setf rejected t)))
    (unless rejected (fail "COD-61" "self-test non ha rilevato la regressione.")))
  t)

(defun sensor-self-test (directory)
  "Controllo vuoto e positivo di quattro MiB trattenuti; nessuna misura per componente."
  (let* ((empty (make-raw)) (positive (make-raw)) (empty-sample (make-sample)) (positive-sample (make-sample))
         (retained (make-array 4 :initial-element nil)) (cursor 0)
         (empty-cycle (lambda () 1))
         (positive-cycle (lambda ()
                           (setf (svref retained cursor) (bytes 1048576)) (incf cursor) 1)))
    (let ((action (lambda () (run-loop empty-cycle +count+ empty))))
      (sb-ext:gc :full t) (observe action empty-sample))
    (unless (and (null (sample-failure empty-sample)) (null (raw-failure empty))
                 (= (raw-completed empty) +count+) (= (raw-checksum empty) +count+)
                 (zerop (sample-heap empty-sample)) (>= (sample-ticks empty-sample) 0))
      (fail "COD-61" "controllo vuoto del sensore non valido."))
    (let ((action (lambda () (run-loop positive-cycle 4 positive))))
      (sb-ext:gc :full t) (observe action positive-sample))
    (unless (and (null (sample-failure positive-sample)) (null (raw-failure positive))
                 (= cursor 4) (= (raw-completed positive) 4) (= (raw-checksum positive) 4)
                 (every (lambda (array) (and (typep array 'octets) (= (length array) 1048576))) retained)
                 (>= (sample-heap positive-sample) 4194304) (>= (sample-ticks positive-sample) 0))
      (fail "COD-61" "sensore positivo non osserva quattro MiB trattenuti."))
    (write-data (list :schema-version 1 :kind :get-performance-sensor :status :ok :counter-scope :whole-process
                      :empty-count +count+ :empty-completed (raw-completed empty)
                      :empty-checksum (raw-checksum empty) :empty-heap-bytes (sample-heap empty-sample)
                      :empty-raw-ticks (sample-ticks empty-sample) :retained-arrays 4 :retained-payload-bytes 4194304
                      :positive-completed (raw-completed positive) :positive-checksum (raw-checksum positive)
                      :positive-heap-bytes (sample-heap positive-sample) :positive-raw-ticks (sample-ticks positive-sample))
                directory "self-test-sensor.lisp")))

(defun diagnostics-self-test ()
  "Metriche assenti/corrotte, zero tick, copia tramite alias, fallimento del confine driver."
  (let* ((raw (make-raw :completed 8 :checksum 8))
         (valid (window-metric (make-sample) (vector raw) :serial :cache-hit 16 7 0 8 8))
         (checks 0) (holder (list :metrics nil)) (alias holder))
    (validate-window valid)
    (dolist (key '(:completed :checksum :expected-checksum :heap-bytes :seconds :ops-per-second
                   :counter-scope :workers :thread-setup-in-window))
      (let ((broken (copy-tree valid)))
        (remf broken key) (expect-rejection (lambda () (validate-window broken))) (incf checks)))
    (dolist (key '(:completed :checksum :raw-ticks :heap-bytes :seconds :ops-per-second))
      (let ((broken (copy-tree valid)))
        (setf (getf broken key) -1) (expect-rejection (lambda () (validate-window broken))) (incf checks)))
    (dolist (key '(:status :completed :checksum))
      (let ((broken (copy-tree valid)))
        (setf (getf (first (getf broken :workers)) key) (if (eq key :status) :failed -1))
        (expect-rejection (lambda () (validate-window broken))) (incf checks)))
    (let ((timed (window-metric (make-sample :ticks 1 :heap 64) (vector raw) :serial :cache-hit 16 7 0 8 8)))
      (validate-window timed)
      (setf (getf timed :ops-per-second) nil)
      (expect-rejection (lambda () (validate-window timed))) (incf checks))
    (dolist (kind '(:get-performance-sensor :get-performance-self-test))
      (let ((leaf (list :schema-version 1 :kind kind :status :ok)))
        (validate-publication-header leaf)
        (remf leaf :schema-version)
        (expect-rejection (lambda () (validate-publication-header leaf))) (incf checks)
        (setf (getf leaf :schema-version) 2)
        (expect-rejection (lambda () (validate-publication-header leaf))) (incf checks)))
    (push (copy-tree valid) (getf holder :metrics))
    (setf (getf (first (getf valid :workers)) :completed) 0)
    (unless (and (eq holder alias) (not (eq valid (first (getf alias :metrics)))))
      (fail "COD-61" "testa report/copia metriche persa."))
    (validate-window (first (getf alias :metrics)))
    (let ((boundary (list :status :running :exit-code nil :diagnostic nil)))
      (capture-run boundary (lambda () (validate-window valid)))
      (unless (and (eq (getf boundary :status) :failed) (eql (getf boundary :exit-code) 1)
                   (search "COD-61" (getf boundary :diagnostic)))
        (fail "COD-61" "confine driver senza diagnostica/exit nonzero.")))
    (list :status :ok :rejections checks :zero-ticks-no-rate t :alias-copy-guard t :nonzero-exit-guard t)))

(defun product-self-test (fixtures directory sensor diagnostics &optional fault-first-p)
  "Esiti completi su fixture autonome; preserva metriche parziali anche su fallimento."
  (let ((result (list :schema-version 1 :kind :get-performance-self-test :status :running
                      :product-fixtures 6 :metrics nil :sensor sensor :diagnostics diagnostics)))
    (write-data result directory "self-test-metrics.lisp")
    (handler-case
        (progn
          (dolist (fixture fixtures)
            (dolist (scenario '(:cache-hit :segment :absent))
              (dolist (configuration '((:serial 1) (:parallel 1) (:parallel 2) (:parallel 4)))
                (let ((metric (run-window fixture scenario (first configuration) (second configuration) 0 8 8)))
                  (when (and fault-first-p (null (getf result :metrics))) (remf metric :completed))
                  (setf (getf result :metrics) (nconc (getf result :metrics) (list (copy-tree metric))))
                  ;; Salva prima di validare: una finestra negativa non scompare.
                  (write-data result directory "self-test-metrics.lisp")
                  (validate-window metric)))))
          (unless (= (length (getf result :metrics)) 72) (fail "COD-61" "self-test incompleto."))
          (setf (getf result :status) :ok)
          (write-data result directory "self-test-metrics.lisp")
          (list :status :ok :product-fixtures 6 :windows 72 :sensor-positive t :diagnostics diagnostics))
      (error (condition)
        (setf (getf result :status) :failed (getf result :diagnostic) (diagnostic condition))
        (write-data result directory "self-test-metrics.lisp")
        (error condition)))))

(defun new-report (mode)
  (list :schema-version 1 :kind :get-performance-benchmark :mode mode :status :running :exit-code nil
        :count-per-worker +count+ :warmup-per-worker +warmup+ :replicas +replicas+
        :value-bytes '(16 256 4096) :key-bytes 16 :csn-profiles '(7 #xffffffffffffffff) :worker-counts '(1 2 4)
        :serial nil :parallel nil :self-test nil :diagnostic nil :persistence :pending
        :source-registration :parent-record-command-after-freeze :recorded-at (get-universal-time)
        :environment (list :lisp (lisp-implementation-type) :version (lisp-implementation-version)
                           :machine (machine-type) :os (software-type) :os-version (software-version)
                           :cwd (namestring (truename "./")) :external-load :uncontrolled
                           :safety 3 :speed 2 :debug 2 :timer :get-internal-real-time
                           :timer-units-per-second internal-time-units-per-second :heap :global-get-bytes-consed)
        :budgets (list :run-seconds +run-seconds+ :window-seconds +window-seconds+ :cleanup-join-seconds 2
                       :max-threads 4 :fixture-file-bytes 72192 :max-plain-report-bytes (1- +plain-limit+)
                       :driver-directory-byte-limit 4194304)
        :limits '(:synthetic-committed-prefix :current-get-v2-unprepared :warm-pagecache
                  :fixed-count-no-adaptation :whole-process-heap-no-component-attribution
                  :full-byte-validation-and-checksum-in-loop :parallel-thread-setup-and-join-in-window
                  :no-p99 :no-durability-measurement :no-network-or-controller-scheduling-measurement
                  :no-db-throughput-claim :no-performance-threshold)))

(defun validate-report (report)
  (validate-publication-header report)
  (require-fields report '(:schema-version :kind :mode :status :exit-code :self-test :serial :parallel :count-per-worker :warmup-per-worker :replicas))
  (unless (and (eql (getf report :schema-version) 1) (eq (getf report :kind) :get-performance-benchmark)
               (eq (getf report :status) :ok) (eql (getf report :exit-code) 0)
               (eq (getf (getf report :self-test) :status) :ok)
               (eql (getf report :count-per-worker) +count+) (eql (getf report :warmup-per-worker) +warmup+)
               (eql (getf report :replicas) +replicas+))
    (fail "COD-61" "report successo incompleto."))
  (let ((bench-p (string= (getf report :mode) "--bench")))
    (unless (and (= (length (getf report :serial)) (if bench-p 90 0))
                 (= (length (getf report :parallel)) (if bench-p 270 0)))
      (fail "COD-61" "campagne seriali/parallele incomplete."))
    ;; Esige la matrice esatta, senza righe duplicate che mascherino configurazioni mancanti.
    (when bench-p
      (dolist (execution '(:serial :parallel))
        (let ((records (getf report execution)))
          (dolist (record records) (validate-window record))
          (dolist (size '(16 256 4096))
            (dolist (csn '(7 #xffffffffffffffff))
              (dolist (scenario '(:cache-hit :segment :absent))
                (dotimes (replica +replicas+)
                  (dolist (workers (if (eq execution :serial) '(1) '(1 2 4)))
                    (unless (= 1 (count-if
                                  (lambda (record)
                                    (and (eq (getf record :execution) execution)
                                         (eq (getf record :scenario) scenario) (= (getf record :value-bytes) size)
                                         (= (getf record :csn) csn) (= (getf record :replica) replica)
                                         (= (getf record :worker-count) workers) (= (getf record :count-per-worker) +count+)))
                                  records))
                      (fail "COD-61" "matrice preregistrata incompleta/duplicata.")))))))))))
  report)

(defun save-report (report directory)
  (when (eq (getf report :status) :ok) (validate-report report))
  (write-data report directory "report.lisp"))

(defun run-bench (fixtures report directory)
  (dolist (execution '(:serial :parallel))
    (dolist (fixture fixtures)
      (dolist (scenario '(:cache-hit :segment :absent))
        (dotimes (replica +replicas+)
          (dolist (workers (if (eq execution :serial) '(1) '(1 2 4)))
            (let ((metric (run-window fixture scenario execution workers replica +count+ +warmup+)))
              (push (copy-tree metric) (getf report execution))
              (validate-window metric)))))
      (save-report report directory)))
  (setf (getf report :serial) (nreverse (getf report :serial))
        (getf report :parallel) (nreverse (getf report :parallel))))

(defun create-directory (mode requested)
  "Nuovo run 0700, solo prefix concordati per il collector; nessuna directory riusata."
  (let* ((prefix (if (string= mode "--bench") "get-performance-bench" "get-performance-self-test"))
         (path (uiop:ensure-directory-pathname
                (merge-pathnames (or requested (format nil "spikes/out/~A-~D-~D/" prefix (get-universal-time) (sb-posix:getpid)))
                                 (truename "./"))))
         (leaf (car (last (pathname-directory path)))))
    (unless (and (stringp leaf) (uiop:string-prefix-p prefix leaf))
      (fail "COD-61" "directory run deve iniziare con ~A." prefix))
    (ensure-directories-exist (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname path)))
    (sb-posix:mkdir (namestring path) #o700)
    path))

(defun execute (mode report directory)
  (if (string= mode "--negative-fixture")
      (let ((broken (window-metric (make-sample) (vector (make-raw :completed 8 :checksum 8))
                                  :serial :cache-hit 16 7 0 8 8)))
        (remf broken :completed)
        (push broken (getf report :serial))
        (validate-window broken))
      (let ((fixtures nil))
        (unwind-protect
             (progn
               (load-product)
               (dolist (size '(16 256 4096))
                 (dolist (csn '(7 #xffffffffffffffff)) (push (make-input-fixture size csn directory) fixtures)))
               (setf fixtures (nreverse fixtures))
               (let ((sensor (sensor-self-test directory)) (diagnostics (diagnostics-self-test)))
                 (setf (getf report :self-test) (product-self-test fixtures directory sensor diagnostics
                                                                  (string= mode "--negative-self-test"))))
               (when (string= mode "--bench") (run-bench fixtures report directory)))
          (dolist (fixture fixtures) (dispose-fixture fixture))))))

(defun main ()
  (let ((report (new-report nil)) (directory nil))
    (capture-run report
                 (lambda ()
                   (let ((args (uiop:command-line-arguments)))
                     (unless (and (<= 1 (length args) 2)
                                  (member (first args) '("--self-test" "--bench" "--negative-fixture" "--negative-self-test") :test #'string=))
                       (fail "COD-61" "uso --self-test|--bench|--negative-fixture|--negative-self-test [directory-nuova/]; COUNT è fisso a 20000."))
                     (unless (>= most-positive-fixnum #xffffffff) (fail "COD-61" "richiesto SBCL 64 bit."))
                     (setf (getf report :mode) (first args) directory (create-directory (first args) (second args))
                           *run-directory* directory)
                     (save-report report directory)
                     (sb-ext:with-timeout +run-seconds+ (execute (first args) report directory)))))
    (when directory
      (handler-case
          (progn (setf (getf report :persistence) :verified) (save-report report directory))
        (error (condition)
          (setf (getf report :status) :failed (getf report :exit-code) 1
                (getf report :persistence) :failed (getf report :diagnostic) (diagnostic condition))
          (handler-case (save-report report directory)
            (error (second-condition) (format *error-output* "~A~%" (diagnostic second-condition)))))))
    (format t "~S: ~A~%" (getf report :status) (or directory "nessuna directory run"))
    (when (getf report :diagnostic) (format *error-output* "~A~%" (getf report :diagnostic)))
    (sb-ext:exit :code (or (getf report :exit-code) 1))))

(uiop:with-current-directory ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  ;; C4: riuso delle fixture e degli oracoli dal benchmark di throughput separato.
  (unless (member :arcdocdb-get-bench-library *features*) (main)))
