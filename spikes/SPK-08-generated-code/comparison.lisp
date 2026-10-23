;;;; SPK-08: confronto sullo stesso span immutabile, senza integrazione nel motore.
;;; OWNER: campagna seriale; matrici, copie e accumulatori esclusivi del chiamante.
;;; SHARED: soli kernel gia caricati; nessuno stato globale mutabile.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(defpackage #:arcdocdb.spk08.comparison
  (:use #:cl)
  (:export #:check #:bench))
(in-package #:arcdocdb.spk08.comparison)
(declaim (optimize (safety 3) (speed 3) (debug 2)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype masks () '(simple-array (unsigned-byte 16) (*)))
(deftype index () '(and fixnum (integer 0 *)))
(defconstant +max-cases+ 100000)
(defconstant +max-operations+ 200000000)
(defconstant +max-payload+ 4194304)

(define-condition comparison-failure (error)
  ((rule :initarg :rule :reader failure-rule))
  (:report (lambda (condition stream)
             (format stream "SPK-08 comparison.lisp: ~S." (failure-rule condition)))))

(defun require-result (test rule)
  "Interrompe la campagna sulla prima violazione identificata."
  (unless test (error 'comparison-failure :rule rule))
  nil)

(defun loaded-function (package name)
  "Lookup opaco: non introduce riferimenti reader a package nativi assenti."
  (let* ((p (find-package package)) (symbol (and p (find-symbol name p))))
    (require-result (and symbol (fboundp symbol)) (list :missing-kernel package name))
    (symbol-function symbol)))

(defun methods ()
  "Restituisce i kernel e il backend; SIMD entra solo dopo il gate delle istruzioni."
  (let* ((scalar (list (cons :scalar (loaded-function "ARCDOCDB.SPK08.IMPRONTE" "SCALAR16"))
                       (cons :swar-packed (loaded-function "ARCDOCDB.SPK08.IMPRONTE" "PACKEDMASK16"))))
         (native (find-package "ARCDOCDB.SPK08.SIMD"))
         (backend (if native
                      (funcall (loaded-function "ARCDOCDB.SPK08.SIMD" "BACKEND"))
                      :unsupported)))
    (require-result (member backend '(:neon :sse2 :unsupported)) :unknown-backend)
    (values (if (eq backend :unsupported) scalar
                (append scalar (list (cons backend
                                         (loaded-function "ARCDOCDB.SPK08.SIMD" "MASCHERA-SIMD")))))
            backend)))

(defun validate-seconds (seconds)
  "Limite cooperativo esplicito, positivo e non oltre cinque minuti."
  (require-result (and (realp seconds) (< 0 seconds) (<= seconds 300)) :seconds-budget)
  seconds)

(defun deadline (seconds)
  "Fine monotona; nessuna dipendenza dall'orologio civile."
  (+ (get-internal-real-time) (ceiling (* (validate-seconds seconds)
                                         internal-time-units-per-second))))

(defun require-time (end)
  "Esaurimento segnalato come fallimento, mai come campagna parzialmente riuscita."
  (require-result (< (get-internal-real-time) end) :time-budget))

(defun oracle (buffer start query)
  "Oracolo indipendente: somma di potenze per uguaglianza dei sedici byte."
  (let ((mask 0))
    (dotimes (lane 16 mask)
      (when (= query (aref buffer (+ start lane))) (incf mask (expt 2 lane))))))

(defun compare-group (kernels buffer start query end)
  "Confronta tutti i metodi con lo stesso oracle; verifica l'intero input."
  (require-time end)
  (let ((before (copy-seq buffer)) (expected (oracle buffer start query)))
    (unwind-protect
         (dolist (method kernels)
           (require-result (= expected (funcall (cdr method) buffer start query))
                           (list :mask (car method) start query expected)))
      (require-result (equalp before buffer) :modified-input)))
  nil)

(defun fill-group (buffer start query pattern row)
  "Solo ctrl validi del prodotto: H2 0..127, DELETED 254, EMPTY 255."
  (dotimes (lane 16 buffer)
    (setf (aref buffer (+ start lane))
          (ecase pattern
            (:mixed (case (mod (+ row lane) 8)
                      (0 query) (1 255) (2 254)
                      (otherwise (mod (+ (* row 37) (* lane 19)) 128))))
            (:all-hit query)
            (:no-hit (logxor query 1))
            (:special (if (evenp lane) 254 255))
            (:alternating (if (evenp lane) query (logxor query 1)))
            (:first (if (zerop lane) query 255))
            (:last (if (= lane 15) query 254))
            (:borrow (case (mod lane 4) (0 query) (1 (logxor query 1))
                           (2 255) (otherwise 254)))))))

(defun rejection-type (method category)
  "Categoria esatta dell'API esistente: SIMD ammette u8 prima del limite H2."
  (if (or (eq category :type)
          (and (eq category :query-u8) (member method '(:scalar :swar-packed))))
      'type-error
      (let* ((native (member method '(:neon :sse2)))
             (package (find-package (if native "ARCDOCDB.SPK08.SIMD" "ARCDOCDB.SPK08.IMPRONTE")))
             (symbol (and package (find-symbol (if native "GRUPPO-INVALIDO" "ERRORE-IMPRONTE")
                                               package))))
        (require-result symbol :missing-rejection-condition)
        symbol)))

(defun snapshot (buffer)
  "Copia le celle anche oltre il fill pointer; conserva la geometria degli array."
  (if (arrayp buffer)
      (multiple-value-bind (base offset) (array-displacement buffer)
        (list (array-dimensions buffer) (array-element-type buffer)
              (adjustable-array-p buffer) base offset
              (and (vectorp buffer) (array-has-fill-pointer-p buffer)
                   (fill-pointer buffer))
              (loop for i below (array-total-size buffer) collect (row-major-aref buffer i))))
      (if (consp buffer) (copy-tree buffer) buffer)))

(defun reject-group (kernels arguments end &optional (category :window))
  "Argomenti opachi via APPLY; nessuna eliminazione statica di un test negativo."
  (require-time end)
  (let* ((buffer (first arguments)) (before (snapshot buffer)))
    (dolist (method kernels)
      (let ((observed nil))
        (unwind-protect
             (handler-case (apply (cdr method) arguments)
               (error (condition)
                 (require-result (typep condition (rejection-type (car method) category))
                                 (list :unexpected-rejection (car method) (type-of condition)))
                 (setf observed t)))
          (require-result (equalp before (snapshot buffer)) :modified-invalid-input))
        (require-result observed (list :missing-rejection (car method) (rest arguments))))))
  nil)

(defun check-windows (kernels end)
  "Tutte le code 0..15 sono rifiutate; ultimi gruppi esatti a ogni offset 0..15."
  (let ((accepted 0) (rejected 0))
    (dotimes (size 16)
      (reject-group kernels (list (make-array size :element-type '(unsigned-byte 8)) 0 42) end)
      (incf rejected))
    (dotimes (offset 16)
      (let ((buffer (make-array (+ offset 16) :element-type '(unsigned-byte 8)
                                :initial-element 255)))
        (fill-group buffer offset (mod (* offset 17) 128) :last offset)
        (compare-group kernels buffer offset (mod (* offset 17) 128) end)
        (incf accepted)
        (reject-group kernels (list buffer (1+ offset) 42) end)
        (incf rejected)))
    (values accepted rejected)))

(defun check-invalid (kernels end)
  "Tipi, offset e query invalidi, inclusi array non semplici e interi oltre fixnum."
  (let* ((buffer (make-array 32 :element-type '(unsigned-byte 8) :initial-element 255))
         (base (make-array 32 :element-type '(unsigned-byte 8) :initial-element 255))
         (invalid (list nil '(1 2) #(1 2) "1234567890123456"
                        (make-array 32 :element-type '(unsigned-byte 16))
                        (make-array 32 :element-type '(unsigned-byte 8) :adjustable t)
                        (make-array 32 :element-type '(unsigned-byte 8) :fill-pointer 16)
                        (make-array 16 :element-type '(unsigned-byte 8) :displaced-to base)
                        (make-array '(4 8) :element-type '(unsigned-byte 8))))
         (count 0))
    (dolist (bad invalid)
      (reject-group kernels (list bad 0 42) end :type) (incf count))
    (dolist (bad (list -1 17 nil 0.0 :offset most-positive-fixnum (1+ most-positive-fixnum)))
      (reject-group kernels (list buffer bad 42) end (if (typep bad 'fixnum) :window :type))
      (incf count))
    (dolist (bad (list -1 128 255 256 nil 0.0 :query (1+ most-positive-fixnum)))
      (reject-group kernels (list buffer 0 bad) end (if (member bad '(128 255)) :query-u8 :type))
      (incf count))
    count))

(defun expect-detection (function rule)
  "Fixture C4: il controllo deve fallire con la regola precisa, senza successo silenzioso."
  (let ((observed nil))
    (handler-case (funcall function)
      (comparison-failure (condition)
        (let ((actual (failure-rule condition)))
          (require-result (eq rule (if (consp actual) (first actual) actual)) :detection-fixture-rule))
        (setf observed t)))
    (require-result observed :missing-detection))
  nil)

(defun check-detectors (end)
  "Mismatch intenzionale, scadenza e preflight budget esercitano il verificatore stesso."
  (let ((buffer (make-array 16 :element-type '(unsigned-byte 8) :initial-element 42)))
    (expect-detection
     (lambda () (compare-group (list (cons :broken (lambda (&rest args) (declare (ignore args)) 0)))
                               buffer 0 42 end)) :mask))
  (expect-detection (lambda () (require-time (get-internal-real-time))) :time-budget)
  (dolist (entry '(((0 32 2 120 4194304 3) :rows-budget)
                   ((2048 0 2 120 4194304 3) :passes-budget)
                   ((2048 32 0 120 4194304 3) :warmup-budget)
                   ((2048 32 2 0 4194304 3) :seconds-budget)
                   ((2048 32 2 120 0 3) :byte-budget)
                   ((2048 32 2 120 1 3) :payload-budget)
                   ((8192 1024 2 120 4194304 3) :operation-budget)))
    (expect-detection (lambda () (apply #'validate-bench (first entry))) (second entry)))
  9)

(defun disassembly (kernels)
  "Codice degli entry point effettivi e del ciclo condiviso, non prova di correttezza."
  (loop for method in (append kernels (list (cons :shared-cycle #'cycle)))
        collect (list :method (car method)
                      :text (with-output-to-string (*standard-output*)
                              (disassemble (cdr method))))))

(defun check (&key (seconds 120))
  "Campagna finita sullo stesso buffer/query. SIMD assente resta UNSUPPORTED."
  (let ((end (deadline seconds)) (cases 0) (invalid 0) (detectors 0) (code nil))
    (multiple-value-bind (kernels backend) (methods)
      (let ((buffer (make-array 48 :element-type '(unsigned-byte 8) :initial-element 255)))
        (dotimes (query 128)
          (dotimes (offset 16)
            (dolist (pattern '(:mixed :all-hit :no-hit :special :alternating :first :last :borrow))
              (require-result (< cases +max-cases+) :case-budget)
              (fill-group buffer offset query pattern (+ (* query 16) offset))
              (compare-group kernels buffer offset query end)
              (incf cases))))
        (dolist (query '(0 127))
          (dolist (value (append (loop for b below 128 collect b) '(254 255)))
            (dotimes (lane 16)
              (fill buffer 255)
              (setf (aref buffer (+ 7 lane)) value)
              (compare-group kernels buffer 7 query end)
              (incf cases)))))
      (multiple-value-bind (windows rejected) (check-windows kernels end)
        (incf cases windows) (incf invalid rejected))
      (incf invalid (check-invalid kernels end))
      (setf detectors (check-detectors end))
      (require-result (<= cases +max-cases+) :case-budget)
      (setf code (disassembly kernels))
      (require-time end)
      (list :status (if (eq backend :unsupported) :unsupported :ok)
            :module :same-window-comparison :scalar-swar-status :ok
            :native-status (if (eq backend :unsupported) :unsupported :ok) :backend backend
            :group-cases cases :kernel-comparisons (* cases (length kernels))
            :invalid-cases invalid :kernel-rejections (* invalid (length kernels))
            :detector-fixtures detectors :rejection-contract :per-existing-api
            :query-domain '(0 127) :ctrl-domain '(0 127 254 255) :offset-domain '(0 15)
            :case-budget +max-cases+ :seconds-budget seconds :input-immutability :checked
            :disassembly code
            :limits '(:immutable-groups :no-index-or-concurrency :no-production-promotion
                      :no-prepacked-u64-comparison :short-tail-rejected-not-loaded)))))

(defstruct (dataset (:constructor %dataset))
  (buffer (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (offsets (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (queries (make-array 0 :element-type '(unsigned-byte 8)) :type octets)
  (expected (make-array 0 :element-type '(unsigned-byte 16)) :type masks)
  (rows 0 :type index) (sum 0 :type index))

(defun prepare-dataset (rows kind)
  "Matrici byte, offset, query e oracle; nessuna parola preimpacchettata."
  (let ((data (%dataset :buffer (make-array (* rows 32) :element-type '(unsigned-byte 8)
                                                       :initial-element 255)
                       :offsets (make-array rows :element-type '(unsigned-byte 8))
                       :queries (make-array rows :element-type '(unsigned-byte 8))
                       :expected (make-array rows :element-type '(unsigned-byte 16)) :rows rows)))
    (dotimes (row rows data)
      (let* ((offset (mod row 16)) (query (mod (floor row 16) 128))
             (start (+ (* row 32) offset)))
        (fill-group (dataset-buffer data) start query kind row)
        (setf (aref (dataset-offsets data) row) offset
              (aref (dataset-queries data) row) query
              (aref (dataset-expected data) row) (oracle (dataset-buffer data) start query))
        (incf (dataset-sum data) (aref (dataset-expected data) row))))))

(defun dataset-arrays (data)
  "Array che devono restare identici durante warmup e misure."
  (list (dataset-buffer data) (dataset-offsets data) (dataset-queries data)
        (dataset-expected data)))

(defun verify-dataset (data kernels end)
  "Verifica tutti i metodi e ogni riga fuori dalle misure."
  (dotimes (row (dataset-rows data))
    (require-time end)
    (dolist (method kernels)
      (require-result (= (aref (dataset-expected data) row)
                         (funcall (cdr method) (dataset-buffer data)
                                  (+ (* row 32) (aref (dataset-offsets data) row))
                                  (aref (dataset-queries data) row)))
                      (list :dataset-mask (car method) row))))
  nil)

(defun cycle (function data passes end)
  "Stesso ciclo e chiamata indiretta per tutti i kernel, con packing SWAR incluso."
  (declare (type function function) (type dataset data) (type (integer 1 1024) passes))
  (let ((buffer (dataset-buffer data)) (offsets (dataset-offsets data))
        (queries (dataset-queries data)) (rows (dataset-rows data)) (sum 0))
    (declare (type octets buffer offsets queries) (type index rows)
             (type (unsigned-byte 32) sum))
    (dotimes (pass passes sum)
      (require-time end)
      (dotimes (row rows)
        (setf sum (ldb (byte 32 0)
                       (+ sum (the (unsigned-byte 16)
                                   (funcall function buffer (+ (* row 32) (aref offsets row))
                                            (aref queries row))))))))))

(defun validate-bench (rows passes warmup seconds byte-budget method-count)
  "Budget prima dell'allocazione; payload include copie e sensore, non RSS/header."
  (require-result (and (integerp rows) (<= 2048 rows 8192) (zerop (mod rows 2048))) :rows-budget)
  (require-result (and (integerp passes) (<= 1 passes 1024)) :passes-budget)
  (require-result (and (integerp warmup) (<= 1 warmup 64)) :warmup-budget)
  (validate-seconds seconds)
  (require-result (and (integerp byte-budget) (<= 1 byte-budget +max-payload+)) :byte-budget)
  (let ((payload (+ (* rows 72) 1048576))
        (operations (* 3 method-count rows (+ warmup (* 5 passes)))))
    (require-result (<= payload byte-budget) :payload-budget)
    (require-result (<= operations +max-operations+) :operation-budget)
    (values payload operations)))

(defun sample (method data passes end replica order)
  "Solo il ciclo tra contatori; risultato e risoluzione del timer verificati."
  (sb-ext:gc :full t)
  (require-time end)
  (let* ((before (sb-ext:get-bytes-consed)) (start (get-internal-real-time))
         (sum (cycle (cdr method) data passes end)) (finish (get-internal-real-time))
         (bytes (- (sb-ext:get-bytes-consed) before)) (ticks (- finish start))
         (operations (* passes (dataset-rows data))))
    (require-result (= sum (mod (* passes (dataset-sum data)) (expt 2 32))) :sample-checksum)
    (require-result (plusp ticks) :timer-resolution)
    (require-result (>= bytes 0) :allocation-counter)
    (require-time end)
    (list :method (car method) :replica replica :order order :operations operations :sum sum
          :start-ticks start :end-ticks finish :elapsed-ticks ticks
          :timer-units internal-time-units-per-second
          :ns-per-group (/ (* ticks 1d9) (* operations internal-time-units-per-second))
          :bytes-consed bytes :bytes-per-group (/ bytes (coerce operations 'double-float)))))

(defun allocation-sensor ()
  "Controllo positivo osservabile del contatore; fuori dai campioni."
  (sb-ext:gc :full t)
  (let* ((before (sb-ext:get-bytes-consed))
         (buffer (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 91))
         (value (aref buffer 1048575)) (bytes (- (sb-ext:get-bytes-consed) before)))
    (require-result (and (= value 91) (plusp bytes)) :allocation-sensor)
    (values (list :payload-bytes 1048576 :observed-bytes-consed bytes :value value) buffer)))

(defun rotated (kernels amount)
  "Ordine deterministico ruotato fra repliche; tutti i metodi compaiono una volta."
  (let ((position (mod amount (length kernels))))
    (append (nthcdr position kernels) (subseq kernels 0 position))))

(defun measure-dataset (kind number rows passes warmup kernels end)
  "Cinque repliche sullo stesso dato/query/oracle; verifica copie anche su fallimento."
  (let* ((data (prepare-dataset rows kind)) (arrays (dataset-arrays data))
         (copies (mapcar #'copy-seq arrays)) (samples nil))
    (unwind-protect
         (progn
           (verify-dataset data kernels end)
           (dolist (method kernels)
             (require-result (= (cycle (cdr method) data warmup end)
                                (mod (* warmup (dataset-sum data)) (expt 2 32))) :warmup-checksum))
           (dotimes (replica 5)
             (let ((order (rotated kernels (+ number replica))))
               (dolist (method order)
                 (push (list :dataset kind :sample
                             (sample method data passes end replica (mapcar #'car order))) samples)))))
      (require-result (every #'equalp arrays copies) :modified-dataset))
    (nreverse samples)))

(defun bench (&key (rows 2048) (passes 32) (warmup-passes 2) (seconds 120)
                   (byte-budget +max-payload+))
  "Tre dataset identici per metodo, cinque repliche; nessuna soglia di velocita promessa."
  (multiple-value-bind (kernels backend) (methods)
    (multiple-value-bind (payload operations)
        (validate-bench rows passes warmup-passes seconds byte-budget (length kernels))
      (let* ((end (deadline seconds)) (checked (check :seconds seconds)) (samples nil))
        (multiple-value-bind (sensor sensor-buffer) (allocation-sensor)
          (loop for kind in '(:mixed :all-hit :special) for number from 0
                do (setf samples (nconc samples
                                       (measure-dataset kind number rows passes warmup-passes kernels end))))
          (require-time end)
          (require-result (= 91 (aref sensor-buffer 1048575)) :allocation-sensor-retained)
          (require-result (= (length samples) (* 15 (length kernels))) :sample-count)
          (list :status (if (eq backend :unsupported) :unsupported :measured)
                :module :same-window-comparison :backend backend
                :scalar-swar-status :measured
                :native-status (if (eq backend :unsupported) :unsupported :measured)
                :check checked :allocation-sensor sensor :sample-count (length samples) :samples samples
                :parameters (list :rows rows :passes passes :warmup-passes warmup-passes
                                  :replicas 5 :seconds-budget seconds :payload-budget byte-budget
                                  :payload-with-copies-and-sensor payload :operations-with-warmup operations
                                  :max-operations +max-operations+ :query-domain '(0 127)
                                  :offset-domain '(0 15) :group-bytes 16 :row-bytes 32
                                  :packing :inside-swar-kernel :entry :shared-indirect-call-loop)
                :limits '(:immutable-groups :single-worker :uncontrolled-external-load
                          :cache-resident-synthetic-data :not-db-throughput :no-production-promotion
                          :no-prepacked-u64-comparison :payload-not-rss :cooperative-deadline)))))))
