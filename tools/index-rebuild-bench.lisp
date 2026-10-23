;;;; C4: primitive reali v2; metodo in indice-ricostruzione-benchmark-metodo.md.
;;;; --self-test|--bench|--parallel|--negative-fixture [directory-nuova/ [20000|100000]]
;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-007 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
;;; OWNER: main possiede rapporti; ciascun worker possiede indice, fixture e finestra.
;;; SHARED: semafori solo all'avvio; get-bytes-consed conta tutto il processo.
(require :asdf)
(require :sb-posix)
(load (merge-pathnames "evidence-storage.lisp" *load-truename*))
(defpackage #:arcdocdb.index-rebuild.bench (:use #:cl))
(in-package #:arcdocdb.index-rebuild.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +replicas+ 5)
(defconstant +warmup+ 256)
(defconstant +deadline-seconds+ 30)
(defconstant +transient-budget+ (* 32 1024 1024))
(deftype words () '(simple-array (unsigned-byte 64) (5)))
(deftype digests () '(simple-array (unsigned-byte 32) (*)))

(define-condition bench-failure (error)
  ((rule :initarg :rule :reader failure-rule) (detail :initarg :detail :reader failure-detail))
  (:report (lambda (condition stream)
             (format stream "tools/index-rebuild-bench.lisp ~A: ~A"
                     (failure-rule condition) (failure-detail condition)))))

(defun fail (rule control &rest arguments)
  "Confine C4: diagnostica con file e regola, conservata anche nel rapporto."
  (error 'bench-failure :rule rule :detail (apply #'format nil control arguments)))

(defun api (name &optional (visibility :external))
  "Nomi costanti del driver; risoluzione prima della misura, mai nel lookup caldo."
  (multiple-value-bind (symbol actual) (find-symbol name "ARCDOCDB.INDEX.PRIMARY")
    (unless (and symbol (eq actual visibility) (fboundp symbol))
      (fail "COD-61" "API ~A (~A) assente dalla definizione ASDF." name visibility))
    (symbol-function symbol)))

(defun field (name object)
  "Ispezione interna di fixture/piani fuori dai clock; nessuna API simulata."
  (funcall (api name :internal) object))

(defun product-symbol (package name)
  "Simboli di formato/condizione risolti solo dopo ASDF; nessun package prodotto al read-time."
  (or (find-symbol name package) (fail "COD-61" "simbolo ~A:~A assente." package name)))

(defun load-product ()
  "Solo sistema ASDF standard; avvisi di compilazione del prodotto come errori."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (fail "COD-01" "~A" condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb" :force t)))
  (api "RICOSTRUISCI-FRAMMENTO-INDICE"))

(defstruct (fixture (:copier nil))
  "Input e oracoli privati, costruiti prima di warmup e clock."
  (index nil :type t :read-only t) (context nil :type t :read-only t)
  (keys #() :type simple-vector :read-only t) (expected #() :type simple-vector :read-only t)
  (highs (make-array 0 :element-type '(unsigned-byte 32)) :type digests :read-only t)
  (lows (make-array 0 :element-type '(unsigned-byte 32)) :type digests :read-only t)
  (output (make-array 5 :element-type '(unsigned-byte 64)) :type words :read-only t)
  (capacity 16 :type fixnum :read-only t) (key-size 16 :type fixnum :read-only t))

(defun new-index (capacity arena-size)
  "Limiti locali espliciti; arena del sorgente include spazio poi cancellato."
  (funcall (api "CREA-INDICE-PRIMARIO") :capacity capacity :arena-bytes (max 1 arena-size)
           :max-depth 6 :fragment-budget-bytes (* 8 1024 1024) :directory-budget-bytes 4096))

(defun seed-depth (index capacity depth)
  "Al più quattro split vuoti reali prima della fixture; tutti i piani sono pubblicati."
  (unless (<= 0 depth 4) (fail "COD-60" "profondità fixture fuori budget."))
  (dotimes (i depth)
    (let ((source (funcall (api "FRAMMENTO-CORRENTE-INDICE") index 0))
          (highs (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0))
          (lows (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0)))
      (multiple-value-bind (plan slots bytes refs payload)
          (funcall (api "RICOSTRUISCI-FRAMMENTO-INDICE") index source highs lows
                   +transient-budget+ :split-p t)
        (unless (and (= slots capacity) (zerop bytes) (= refs (ash 1 (1+ i)))
                     (<= 1 payload +transient-budget+))
          (fail "COD-60" "contatori dello split vuoto incoerenti."))
        (unless (null (funcall (api "PUBBLICA-DIRECTORY-INDICE") plan))
          (fail "COD-23" "ritorno inatteso dalla pubblicazione."))))))

(defun put-key (fixture ordinal)
  "Upsert reale; chiave/sorgente/scratch distinti; ritorno NIL controllato."
  (let* ((index (fixture-index fixture)) (high (aref (fixture-highs fixture) ordinal))
         (fragment (funcall (api "FRAMMENTO-CORRENTE-INDICE") index high)))
    (unless (null (funcall (api "PUBBLICA-CHIAVE-INDICE") index fragment
                          (svref (fixture-keys fixture) ordinal) 0 (fixture-key-size fixture)
                          high (aref (fixture-lows fixture) ordinal)
                          (svref (fixture-expected fixture) ordinal) (fixture-context fixture)))
      (fail "COD-23" "upsert non restituisce NIL."))))

(defun make-input-fixture (capacity count size depth range)
  "Ordine inverso, H2 distinto per chiave, ultimo inserimento cancellato, prima chiave aggiornata."
  (unless (and (member capacity '(16 128 1024)) (<= 2 count (min 96 (* 3 (/ capacity 4))))
               (member size '(16 1024 65535)) (member range '(:low :high)))
    (fail "COD-60" "fixture fuori dal preregistrato."))
  (let* ((index (new-index capacity (* count size)))
         (fixture (make-fixture :index index :context (funcall (api "CREA-CONTESTO-INDICE"))
                               :capacity capacity :key-size size :keys (make-array count)
                               :expected (make-array count)
                               :highs (make-array count :element-type '(unsigned-byte 32))
                               :lows (make-array count :element-type '(unsigned-byte 32)))))
    (seed-depth index capacity depth)
    (let ((fragment (funcall (api "FRAMMENTO-CORRENTE-INDICE") index 0)))
      (when (< (length (field "FRAMMENTO-INDICE-ARENA" fragment)) (* count size))
        (unless (null (funcall (api "ESTENDI-ARENA-INDICE") index fragment (* count size) +transient-budget+))
          (fail "COD-23" "crescita arena della fixture: ritorno inatteso."))))
    (dotimes (j count)
      (let ((key (make-array size :element-type '(unsigned-byte 8) :initial-element (1+ j)))
            (source (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
        (setf (aref source 0) (if (eq range :high) #xfffffffffffffff0 17)
              (aref source 1) (if (eq range :high) #xfedcba9800000040 #x100000040)
              (aref source 2) (logior (ash size 32) (ash 1 48))
              (aref source 3) (+ (symbol-value (product-symbol "ARCDOCDB.RECORD" "+HEADER-BYTES+")) size)
              (svref (fixture-keys fixture) j) key (svref (fixture-expected fixture) j) source
              (aref (fixture-highs fixture) j) (if (oddp j) (ash 1 (- 31 depth)) 0)
              (aref (fixture-lows fixture) j) (logior (ash (* 16 (floor j 16)) 7) j))))
    (dotimes (i count) (put-key fixture (- count i 1)))
    (incf (aref (the words (svref (fixture-expected fixture) 0)) 0))
    (incf (aref (the words (svref (fixture-expected fixture) 0)) 1) 64)
    (put-key fixture 0)
    (let* ((last (1- count)) (high (aref (fixture-highs fixture) last)))
      (unless (funcall (api "RIMUOVI-CHIAVE-INDICE") index
                       (funcall (api "FRAMMENTO-CORRENTE-INDICE") index high)
                       (svref (fixture-keys fixture) last) 0 size high
                       (aref (fixture-lows fixture) last) (fixture-context fixture))
        (fail "COD-60" "cancellazione della fixture non applicata.")))
    fixture))

(defun source-digests (fixture)
  "C u32 per array; sonda-writer recupera lo slot originale, senza assumere slot=ordinale."
  (let* ((capacity (fixture-capacity fixture)) (index (fixture-index fixture))
         (source (funcall (api "FRAMMENTO-CORRENTE-INDICE") index 0))
         (highs (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0))
         (lows (make-array capacity :element-type '(unsigned-byte 32) :initial-element 0))
         (seen (make-array capacity :element-type 'bit :initial-element 0))
         (work (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
         (nonidentity nil))
    (dotimes (j (1- (length (fixture-keys fixture))))
      (multiple-value-bind (slot found)
          (funcall (api "SONDA-WRITER" :internal) source (svref (fixture-keys fixture) j)
                   0 (fixture-key-size fixture) (aref (fixture-lows fixture) j) work)
        (unless (and found (<= 0 slot (1- capacity)) (zerop (sbit seen slot)))
          (fail "COD-60" "mappa slot mancante/duplicata per chiave ~D." j))
        (setf (sbit seen slot) 1 (aref highs slot) (aref (fixture-highs fixture) j)
              (aref lows slot) (aref (fixture-lows fixture) j))
        (unless (= slot j) (setf nonidentity t))))
    (unless nonidentity (fail "COD-60" "fixture non discrimina slot fisico e ordinale."))
    (values source highs lows)))

(defun verify-output (fixture j)
  "Verifica l'output già scritto, senza una seconda lookup che potrebbe mascherare il risultato."
  (let ((output (fixture-output fixture)) (keys (fixture-keys fixture)) (size (fixture-key-size fixture)))
    (if (= j (1- (length keys)))
        (unless (every (lambda (x) (= x #xffffffffffffffff)) output)
          (fail "COD-60" "miss cambia output."))
        (let* ((expected (svref (fixture-expected fixture) j))
               (fragment (funcall (api "FRAMMENTO-CORRENTE-INDICE")
                                  (fixture-index fixture) (aref (fixture-highs fixture) j)))
               (arena (field "FRAMMENTO-INDICE-ARENA" fragment)) (offset (ldb (byte 32 0) (aref output 2))))
          (unless (and (loop for word in '(0 1 3 4) always (= (aref output word) (aref expected word)))
                       (= (ash (aref output 2) -32) (ash (aref expected 2) -32))
                       (<= (+ offset size) (length arena))
                       (loop for k below size always (= (aref arena (+ offset k)) (aref (svref keys j) k))))
            (fail "COD-60" "payload/chiave incoerenti per ~D." j)))))
  t)

(defun verify-fixture (fixture)
  "Oracolo fuori misura: hit/miss, cinque campi v2 e byte dell'arena dopo ogni fase."
  (dotimes (j (length (fixture-keys fixture)))
    (fill (fixture-output fixture) #xffffffffffffffff)
    (let ((status (funcall (api "LEGGI-INDICE-PRIMARIO") (fixture-index fixture)
                           (svref (fixture-keys fixture) j) 0 (fixture-key-size fixture)
                           (aref (fixture-highs fixture) j) (aref (fixture-lows fixture) j)
                           (fixture-context fixture) (fixture-output fixture))))
      (unless (eq status (if (= j (1- (length (fixture-keys fixture)))) :absent :live))
        (fail "COD-60" "status fixture incoerente: ~S." status))
      (verify-output fixture j)))
  t)

(defun lookup-cycle (fixture miss-p)
  "Una lookup reale per ciclo; controlla status, senza leggere/boxare gli u64 restituiti."
  (let ((lookup (api "LEGGI-INDICE-PRIMARIO")) (index (fixture-index fixture))
        (context (fixture-context fixture)) (output (fixture-output fixture))
        (keys (fixture-keys fixture)) (highs (fixture-highs fixture)) (lows (fixture-lows fixture))
        (size (fixture-key-size fixture)) (cursor 0) (live (1- (length (fixture-keys fixture)))))
    (declare (type fixnum size cursor live) (type digests highs lows))
    (values
     (lambda ()
       (let* ((j (if miss-p live cursor))
              (status (funcall lookup index (svref keys j) 0 size (aref highs j) (aref lows j) context output)))
         (unless (eq status (if miss-p :absent :live)) (fail "COD-60" "lookup: ~S." status))
         (setf cursor (if (= (1+ cursor) live) 0 (1+ cursor)))
         1))
     (lambda () (verify-output fixture (if miss-p live (if (zerop cursor) (1- live) (1- cursor))))))))

(defstruct (raw (:copier nil))
  "Risultati aggiornati senza creare liste nella finestra; errori raccolti al confine."
  (completed 0 :type fixnum) (sink 0 :type fixnum) (ticks 0 :type integer)
  (heap 0 :type integer) (failure nil :type (or null condition)))

(defun measure (cycle iterations raw)
  "Solo ciclo e contatori preallocati tra le letture di heap; nessun GC esplicito nella finestra."
  (declare (type fixnum iterations))
  (unless (<= 1 iterations 100000) (fail "COD-60" "numero iterazioni fuori budget."))
  (let ((ticks (get-internal-real-time)) (heap (sb-ext:get-bytes-consed)))
    (handler-case
        (dotimes (i iterations)
          (incf (raw-sink raw) (the fixnum (funcall cycle)))
          (setf (raw-completed raw) (1+ i)))
      (error (condition) (setf (raw-failure raw) condition)))
    (setf (raw-heap raw) (- (sb-ext:get-bytes-consed) heap)
          (raw-ticks raw) (- (get-internal-real-time) ticks)))
  raw)

(defun metric (raw iterations workload scope)
  "Tutti i campi, anche NIL, esistono prima di qualsiasi pubblicazione tramite alias."
  (let* ((ticks (raw-ticks raw)) (seconds (/ ticks (float internal-time-units-per-second 1d0))))
    (list :kind :lookup :status (if (raw-failure raw) :failed :ok) :workload workload
          :iterations iterations :completed (raw-completed raw) :sink (raw-sink raw)
          :heap-bytes (raw-heap raw) :raw-ticks ticks :seconds seconds
          :time-quality (if (zerop ticks) :below-resolution :measured)
          :ops-per-second (when (plusp ticks) (/ (raw-completed raw) seconds))
          :counter-scope scope :diagnostic (when (raw-failure raw) (princ-to-string (raw-failure raw))))))

(defun require-fields (record keys)
  "NIL presente è diverso da una metrica mancante."
  (dolist (key keys)
    (unless (nth-value 0 (get-properties record (list key)))
      (fail "COD-61" "metrica mancante ~S." key))))

(defun validate-metric (record &key zero-heap)
  "Esige completamento, sink, contatori e tempi/rate coerenti; zero tick conserva NIL rate."
  (require-fields record '(:kind :status :workload :iterations :completed :sink :heap-bytes
                          :raw-ticks :seconds :time-quality :ops-per-second :counter-scope :diagnostic))
  (let ((ticks (getf record :raw-ticks)) (heap (getf record :heap-bytes)))
    (unless (and (eq (getf record :status) :ok) (integerp ticks) (>= ticks 0)
                 (integerp heap) (>= heap 0) (typep (getf record :iterations) '(integer 1 100000))
                 (eql (getf record :completed) (getf record :iterations))
                 (eql (getf record :sink) (getf record :iterations))
                 (eql (getf record :seconds) (/ ticks (float internal-time-units-per-second 1d0)))
                 (eq (getf record :time-quality) (if (zerop ticks) :below-resolution :measured))
                 (eql (getf record :ops-per-second)
                      (when (plusp ticks) (/ (getf record :completed) (getf record :seconds)))))
      (fail "COD-61" "finestra o metriche incomplete/incoerenti."))
    (when (and zero-heap (not (zerop heap))) (fail "COD-30" "lookup seriale alloca ~D byte." heap)))
  record)

(defun new-report (mode iterations)
  "Rapporto C4; record-command esterno conserva argv, sorgenti e output della campagna."
  (list :schema-version 1 :kind :index-rebuild-benchmark :status :running :exit-code nil
        :mode mode :iterations iterations :replicas +replicas+ :warmup +warmup+
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :safety 3
        :timer-units-per-second internal-time-units-per-second :metrics nil :parallel nil
        :self-test nil :diagnostic nil :persistence :pending
        :limits '(:primitive-real-v2 :lookup-only-hot-loop-with-status-and-counter-overhead
                  :no-db-or-nvme-throughput-claim :trusted-fixture-digests-not-hashing-benchmark
                  :serial-success-heap-gate :whole-process-heap-counter
                  :parallel-overlapping-heap-not-summable :no-p99-or-performance-threshold
                  :transient-payload-not-rss :external-load-uncontrolled)))

(defun publish-metric (report record)
  "La testa :metrics è preesistente; copia l'albero prima che il produttore possa cambiarlo."
  (require-fields report '(:metrics))
  (push (copy-tree record) (getf report :metrics))
  record)

(defun validate-report (report)
  "Un successo persistito richiede campagne complete e metriche ancora valide dopo la copia."
  (require-fields report '(:mode :status :exit-code :self-test :metrics :parallel))
  (let ((test (getf report :self-test))
        (expected (cond ((string= (getf report :mode) "--self-test") 4)
                        ((string= (getf report :mode) "--bench") 64)
                        ((string= (getf report :mode) "--parallel") 74)
                        (t (fail "COD-61" "modo del rapporto successo inatteso.")))))
    (unless (and (eq (getf report :status) :ok) (eql (getf report :exit-code) 0)
                 (eq (getf test :status) :ok) (eql (getf test :product-fixtures) 4)
                 (getf test :alias-and-copy-guard) (getf test :broken-metrics-rejected)
                 (getf test :nonzero-status-guard) (= (length (getf report :metrics)) expected))
      (fail "COD-61" "autoverifica o campagne del rapporto incomplete.")))
  (dolist (record (getf report :metrics))
    (validate-metric record :zero-heap (and (eq (getf record :kind) :lookup)
                                          (eq (getf record :counter-scope) :whole-process)))
    (case (getf record :kind)
      (:lookup nil)
      (:maintenance
       (require-fields record '(:source-slots :key-bytes :new-directory-refs :transient-payload
                                :full-source-passes :probe-bound-per-call :published :publication-raw-ticks))
       (unless (and (getf record :published) (eql (getf record :full-source-passes) 3)
                    (eql (getf record :probe-bound-per-call) (getf record :source-slots))
                    (typep (getf record :publication-raw-ticks) '(integer 0))
                    (equal (getf record :expected-counters)
                           (mapcar (lambda (key) (getf record key))
                                   '(:source-slots :key-bytes :new-directory-refs :transient-payload))))
         (fail "COD-61" "metriche della manutenzione persistita incomplete.")))
      (otherwise (fail "COD-61" "tipo metrica inatteso."))))
  (when (string= (getf report :mode) "--parallel")
    (unless (= (length (getf report :parallel)) 30) (fail "COD-61" "repliche parallele incomplete."))
    (dolist (group (getf report :parallel))
      (unless (and (eq (getf group :status) :ok) (null (getf group :errors))
                   (= (getf group :worker-count) (length (getf group :workers)))
                   (typep (getf group :process-heap-bytes) '(integer 0))
                   (typep (getf group :process-raw-ticks) '(integer 0)))
        (fail "COD-61" "gruppo parallelo incompleto."))
      (dolist (worker (getf group :workers)) (validate-metric worker))))
  report)

(defun save-report (report directory &optional (leaf "report.lisp"))
  "Scrittura nel run posseduto e rilettura con evidence-storage, anche al fallimento."
  (let ((path (merge-pathnames leaf directory)))
    (when (eq (getf report :status) :ok) (validate-report report))
    (with-open-file (stream path :direction :output :if-exists :supersede
                           :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-readably* t) (*print-length* nil) (*print-level* nil))
        (write report :stream stream :pretty t) (terpri stream)))
    (let ((stored (arcdocdb.evidence:read-evidence path)))
      (unless (equal report stored) (fail "COD-61" "metriche persistite diverse: ~A." path))
      (when (eq (getf stored :status) :ok) (validate-report stored)))))

(defun capture-run (report function)
  "Confine CLI/fixture negativa: fallimento registrato e exit-code 1, senza successo implicito."
  (handler-case
      (progn (funcall function) (setf (getf report :status) :ok (getf report :exit-code) 0))
    (error (condition)
      (setf (getf report :status) :failed (getf report :exit-code) 1
            (getf report :diagnostic)
            (format nil "tools/index-rebuild-bench.lisp COD-61: ~A" condition))))
  report)

(defun expect-rejection (function &optional (condition-type 'bench-failure))
  "Confine dell'autoverifica; un errore inatteso non vale come rilevamento corretto."
  (let ((rejected nil))
    (handler-case (funcall function)
      (error (condition) (if (typep condition condition-type) (setf rejected t) (error condition))))
    (unless rejected (fail "COD-60" "fixture negativa non rilevata.")))
  t)

(defun sensor-self-test (directory)
  "Controllo vuoto reale e quattro MiB trattenuti; metriche corrotte e stato CLI non nullo."
  (let* ((empty (make-raw)) (positive (make-raw)) (retained (make-array 4)) (cursor 0)
         (report (new-report "sensor-fixture" 20000)) (alias report))
    (sb-ext:gc :full t)
    (measure (lambda () 1) 20000 empty)
    (let ((record (metric empty 20000 '(:empty-control) :whole-process)))
      (validate-metric record :zero-heap t)
      (publish-metric report record)
      (unless (and (eq report alias) (not (eq record (first (getf alias :metrics)))))
        (fail "COD-60" "testa alias o copia :metrics persa."))
      (setf (car (getf record :workload)) :mutated)
      (unless (eq :empty-control (car (getf (first (getf alias :metrics)) :workload)))
        (fail "COD-60" "copia metriche condivide dati mutabili.")))
    (sb-ext:gc :full t)
    (measure (lambda ()
               (setf (svref retained cursor)
                     (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
               (incf cursor) 1) 4 positive)
    (unless (and (= cursor 4) (every (lambda (x) (= (length x) 1048576)) retained)
                 (>= (raw-heap positive) (* 4 1048576)))
      (fail "COD-60" "controllo positivo non osserva lo heap trattenuto."))
    (let ((record (metric positive 4 '(:positive-control) :whole-process)))
      (validate-metric record)
      (expect-rejection (lambda () (validate-metric record :zero-heap t)))
      (publish-metric report record))
    (dolist (key '(:completed :sink :seconds :ops-per-second :heap-bytes))
      (let ((broken (copy-tree (metric empty 20000 '(:broken) :whole-process))))
        (remf broken key)
        (expect-rejection (lambda () (validate-metric broken)))))
    (dolist (key '(:completed :sink :raw-ticks :seconds :ops-per-second))
      (let ((broken (copy-tree (metric empty 20000 '(:broken) :whole-process))))
        (setf (getf broken key) -1)
        (expect-rejection (lambda () (validate-metric broken)))))
    (let ((broken (metric empty 20000 '(:nonzero-fixture) :whole-process)))
      (remf broken :completed)
      (capture-run report (lambda () (validate-metric broken)))
      (unless (and (eq (getf report :status) :failed) (= (getf report :exit-code) 1))
        (fail "COD-60" "fixture malformata non produce stato non nullo.")))
    (save-report report directory "self-test-sensor.lisp")
    (dolist (record (getf (arcdocdb.evidence:read-evidence
                          (merge-pathnames "self-test-sensor.lisp" directory)) :metrics))
      (validate-metric record))
    (list :status :ok :empty-heap-bytes (raw-heap empty) :positive-heap-bytes (raw-heap positive)
        :alias-and-copy-guard t :broken-metrics-rejected t :nonzero-status-guard t :product-fixtures nil)))

(defun root-payload (root capacity)
  "Oracolo aritmetico: directory + frammenti distinti, escluse intestazioni e runtime."
  (let ((directory (field "ROOT-INDICE-DIRECTORY" root)))
    (+ (* 8 (length directory))
       (loop for fragment in (remove-duplicates (coerce directory 'list) :test #'eq)
             sum (+ (* 41 capacity) (length (field "FRAMMENTO-INDICE-ARENA" fragment)))))))

(defun maintenance (fixture split-p replica report directory)
  "Clock della sola preparazione; pubblicazione misurata separatamente, oracoli fuori clock."
  (multiple-value-bind (source highs lows) (source-digests fixture)
    (let* ((index (fixture-index fixture)) (capacity (fixture-capacity fixture))
           (old (field "INDICE-PRIMARIO-ROOT" index)) (depth (field "ROOT-INDICE-DEPTH" old))
           (bytes (* (1- (length (fixture-keys fixture))) (fixture-key-size fixture)))
           (refs (ash 1 (+ depth (if split-p 1 0))))
           (expected-payload (+ (root-payload old capacity) (* 8 refs) (* 41 capacity)
                                (if split-p (+ (* 41 capacity) bytes) bytes)))
           (rebuild (api "RICOSTRUISCI-FRAMMENTO-INDICE")) (publish (api "PUBBLICA-DIRECTORY-INDICE")))
      (sb-ext:gc :full t)
      (let ((ticks (get-internal-real-time)) (heap (sb-ext:get-bytes-consed)))
        (multiple-value-bind (plan slots keybytes directoryrefs transientpayload)
            (funcall rebuild index source highs lows +transient-budget+ :split-p split-p)
          (let* ((heap-delta (- (sb-ext:get-bytes-consed) heap))
                 (elapsed (- (get-internal-real-time) ticks))
                 (record (metric (make-raw :completed 1 :sink 1 :ticks elapsed :heap heap-delta) 1
                                 (list :maintenance :split-p split-p :replica replica :capacity capacity
                                       :key-size (fixture-key-size fixture) :depth depth) :whole-process)))
            (setf (getf record :kind) :maintenance)
            (setf record (append record (list :source-slots slots :key-bytes keybytes
                                             :full-source-passes 3 :probe-bound-per-call capacity
                                             :new-directory-refs directoryrefs :transient-payload transientpayload
                                             :expected-counters (list capacity bytes refs expected-payload)
                                             :published nil :publication-raw-ticks nil)))
            (publish-metric report record)
            (unless (and (eq old (field "INDICE-PRIMARIO-ROOT" index))
                         (eq :prepared (field "PUBBLICAZIONE-INDICE-STATE" plan))
                         (equal (list slots keybytes directoryrefs transientpayload)
                                (list capacity bytes refs expected-payload)))
              (fail "COD-60" "piano/contatori rebuild incoerenti."))
            (validate-metric record)
            (let ((before (get-internal-real-time)))
              (unless (null (funcall publish plan)) (fail "COD-23" "pubblicazione: ritorno inatteso."))
              (setf (getf record :publication-raw-ticks) (- (get-internal-real-time) before)))
            (unless (and (eq :published (field "PUBBLICAZIONE-INDICE-STATE" plan))
                         (= refs (length (field "ROOT-INDICE-DIRECTORY" (field "INDICE-PRIMARIO-ROOT" index)))))
              (fail "COD-60" "piano non pubblicato interamente."))
            (verify-fixture fixture)
            (setf (getf record :published) t)
            (setf (car (getf report :metrics)) (copy-tree record))
            (save-report report directory)
            plan))))))

(defun product-self-test (report directory)
  "Casi bounded su API reali: update/delete, rebuild/split, digest/budget/shape e piano riusato."
  (dolist (range '(:low :high))
    (dolist (split '(nil t))
      (let ((fixture (make-input-fixture 16 12 16 0 range)))
        (verify-fixture fixture)
        (multiple-value-bind (source highs lows) (source-digests fixture)
          (let ((root (field "INDICE-PRIMARIO-ROOT" (fixture-index fixture)))
                (rebuild (api "RICOSTRUISCI-FRAMMENTO-INDICE")))
            (expect-rejection
             (lambda () (funcall rebuild (fixture-index fixture) source (subseq highs 1) lows +transient-budget+))
             (product-symbol "ARCDOCDB.CONDITIONS" "INVALID-ARGUMENT"))
            (expect-rejection (lambda () (funcall rebuild (fixture-index fixture) source highs lows 1))
                              (product-symbol "ARCDOCDB.CONDITIONS" "RESOURCE-EXHAUSTED"))
            (let* ((bad (copy-seq lows))
                   (slot (position-if (lambda (control) (< control 128)) (field "FRAMMENTO-INDICE-CONTROLS" source))))
              (unless slot (fail "COD-60" "fixture priva di slot vivo."))
              (setf (aref bad slot) (logxor (aref bad slot) 1))
              (expect-rejection
               (lambda () (funcall rebuild (fixture-index fixture) source highs bad +transient-budget+))
               (product-symbol "ARCDOCDB.CONDITIONS" "INVALID-ARGUMENT")))
            (unless (and (eq root (field "INDICE-PRIMARIO-ROOT" (fixture-index fixture)))
                         (eq :open (field "INDICE-PRIMARIO-HEALTH" (fixture-index fixture))))
              (fail "COD-60" "rifiuto preflight modifica root/salute."))))
        (let ((plan (maintenance fixture split 0 report directory)))
          (expect-rejection (lambda () (funcall (api "PUBBLICA-DIRECTORY-INDICE") plan))
                            (product-symbol "ARCDOCDB.CONDITIONS" "INVALID-ARGUMENT"))))))
  t)

(defun serial-bench (report directory iterations)
  "Cinque finestre di hit e miss, CSN bassi e alti; gate heap per entrambe le fasce."
  (dolist (range '(:low :high))
    (let ((fixture (make-input-fixture 128 96 16 0 range)))
      (verify-fixture fixture)
      (dolist (miss-p '(nil t))
        (multiple-value-bind (cycle check) (lookup-cycle fixture miss-p)
          (dotimes (replica +replicas+)
            (dotimes (i +warmup+) (funcall cycle))
            (sb-ext:gc :full t)
            (let* ((raw (measure cycle iterations (make-raw)))
                   (record (metric raw iterations (list :lookup :range range :miss-p miss-p :replica replica)
                                   :whole-process)))
              (publish-metric report record)
              (validate-metric record :zero-heap t)
              (funcall check)
              (verify-fixture fixture)
              (save-report report directory)))))))
  (dolist (configuration '((16 12 16 0) (128 96 16 2) (1024 96 1024 4) (128 96 65535 0)))
    (dolist (split '(nil t))
      (dotimes (replica +replicas+)
        (let ((fixture (apply #'make-input-fixture (append configuration '(:high)))))
          (verify-fixture fixture)
          (maintenance fixture split replica report directory)))))
  t)

(defun remaining-seconds (deadline)
  "Un'unica deadline assoluta per start/ready/join della replica."
  (/ (max 0 (- deadline (get-internal-real-time))) (float internal-time-units-per-second 1d0)))

(defun worker-main (cycle raw iterations ready start)
  "Confine worker: completa o conserva la condizione; mai ripete una chiamata fallita."
  (let ((signalled nil))
    (handler-case
        (progn
          (dotimes (i +warmup+) (funcall cycle))
          (sb-thread:signal-semaphore ready) (setf signalled t)
          (unless (sb-thread:wait-on-semaphore start :timeout +deadline-seconds+)
            (fail "COD-42" "worker oltre deadline di start."))
          (measure cycle iterations raw))
      (error (condition)
        (setf (raw-failure raw) condition)
        (unless signalled (sb-thread:signal-semaphore ready)))))
  :completed)

(defun stop-workers (threads start)
  "Cleanup limitato dei soli thread del driver; non legge raw di worker ancora vivo."
  (sb-thread:signal-semaphore start (length threads))
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (when (and thread (sb-thread:thread-alive-p thread)) (sb-thread:terminate-thread thread))))
  (dotimes (i (length threads))
    (let ((thread (svref threads i)))
      (when thread (sb-thread:join-thread thread :timeout 2 :default :cleanup-timeout)))))

(defun parallel-run (count range replica iterations report directory)
  "Indici indipendenti; heap worker sovrapposti osservativi, mai sommati; errori tutti raccolti."
  (let* ((fixtures (make-array count)) (raws (make-array count)) (checks (make-array count))
         (threads (make-array count :initial-element nil))
         (ready (sb-thread:make-semaphore :count 0)) (start (sb-thread:make-semaphore :count 0))
         (deadline (+ (get-internal-real-time) (* +deadline-seconds+ internal-time-units-per-second)))
         (group (list :worker-count count :range range :replica replica :status :running
                      :workers nil :errors nil :process-heap-bytes nil :process-raw-ticks nil)))
    (push group (getf report :parallel))
    (dotimes (i count)
      (setf (svref fixtures i) (make-input-fixture 128 96 16 0 range) (svref raws i) (make-raw))
      (verify-fixture (svref fixtures i)))
    (handler-case
        (unwind-protect
             (progn
               (dotimes (i count)
                 (multiple-value-bind (cycle check) (lookup-cycle (svref fixtures i) nil)
                   (let ((raw (svref raws i)))
                     (setf (svref checks i) check (svref threads i)
                           (sb-thread:make-thread (lambda () (worker-main cycle raw iterations ready start))
                                                  :name (format nil "index-rebuild-bench-~D" i))))))
               (dotimes (i count)
                 (unless (sb-thread:wait-on-semaphore ready :timeout (remaining-seconds deadline))
                   (fail "COD-42" "worker non pronto.")))
               (sb-ext:gc :full t)
               (let ((heap (sb-ext:get-bytes-consed)) (ticks (get-internal-real-time)))
                 (sb-thread:signal-semaphore start count)
                 (dotimes (i count)
                   (unless (eq :completed (sb-thread:join-thread (svref threads i)
                                                               :timeout (remaining-seconds deadline) :default :timeout))
                     (push (list :worker i :error :join-timeout) (getf group :errors))))
                 (setf (getf group :process-heap-bytes) (- (sb-ext:get-bytes-consed) heap)
                       (getf group :process-raw-ticks) (- (get-internal-real-time) ticks))))
          (stop-workers threads start))
      (error (condition) (push (list :orchestrator (princ-to-string condition)) (getf group :errors))))
    (dotimes (i count)
      (if (and (svref threads i) (not (sb-thread:thread-alive-p (svref threads i))))
          (let ((record (metric (svref raws i) iterations
                                (list :parallel-lookup :range range :replica replica :workers count :worker i)
                                :whole-process-overlapping)))
            (handler-case (progn (validate-metric record) (funcall (svref checks i))
                                 (verify-fixture (svref fixtures i)))
              (error (condition)
                (setf (getf record :status) :failed (getf record :diagnostic) (princ-to-string condition))
                (push (list :worker i :error (princ-to-string condition)) (getf group :errors))))
            (publish-metric report record) (push (copy-tree record) (getf group :workers)))
          (push (list :worker i :error :not-quiescent) (getf group :errors))))
    (setf (getf group :status) (if (getf group :errors) :failed :ok))
    (save-report report directory)
    (when (getf group :errors) (fail "COD-61" "errori worker: ~S." (getf group :errors)))))

(defun create-directory (requested)
  "Run esclusivo 0700; un percorso già esistente è rifiutato, mai sovrascritto."
  (let ((path (uiop:ensure-directory-pathname
               (merge-pathnames (or requested (format nil "spikes/out/~D-index-rebuild-~D/"
                                                     (get-universal-time) (sb-posix:getpid)))
                                (truename "./")))))
    (ensure-directories-exist (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname path)))
    (sb-posix:mkdir (namestring path) #o700)
    path))

(defun parse-arguments (args)
  "CLI bounded; due soli conteggi preregistrati, nessuna prova implicita."
  (unless (and (<= 1 (length args) 3)
               (member (first args) '("--self-test" "--bench" "--parallel" "--negative-fixture") :test #'string=)
               (or (< (length args) 3) (member (third args) '("20000" "100000") :test #'string=))
               (or (< (length args) 3) (member (first args) '("--bench" "--parallel") :test #'string=)))
    (fail "COD-61" "uso --self-test|--bench|--parallel|--negative-fixture [directory-nuova/ [20000|100000]]."))
  (values (first args) (second args) (if (third args) (parse-integer (third args)) 20000)))

(defun execute-mode (mode iterations report directory)
  "Autoverifica prima dei benchmark; la fixture CLI negativa conserva metriche malformate."
  (if (string= mode "--negative-fixture")
      (let ((broken (metric (make-raw :completed 1 :sink 1) 1 '(:deliberately-broken) :whole-process)))
        (remf broken :completed) (publish-metric report broken) (validate-metric broken))
      (progn
        (setf (getf report :self-test) (sensor-self-test directory))
        (load-product)
        (product-self-test report directory)
        (setf (getf (getf report :self-test) :product-fixtures) 4)
        (cond ((string= mode "--self-test") t)
              ((string= mode "--bench") (serial-bench report directory iterations))
              ((string= mode "--parallel")
               (dolist (count '(1 2 4))
                 (dolist (range '(:low :high))
                   (dotimes (replica +replicas+)
                     (parallel-run count range replica iterations report directory)))))
              (t (fail "COD-61" "mode inatteso."))))))

(defun main ()
  "Confine processo: persistito e riletto prima dell'uscita, errori con stato non nullo."
  (let ((report (new-report nil 20000)) (directory nil))
    (capture-run report
                 (lambda ()
                   (multiple-value-bind (mode requested iterations) (parse-arguments (uiop:command-line-arguments))
                     (unless (>= most-positive-fixnum #xffffffff) (fail "COD-61" "richiesto SBCL a 64 bit."))
                     (setf directory (create-directory requested)
                           (getf report :mode) mode (getf report :iterations) iterations)
                     (save-report report directory)
                     (execute-mode mode iterations report directory))))
    (when directory
      (handler-case
          (progn (save-report report directory) (setf (getf report :persistence) :verified)
                 (save-report report directory))
        (error (condition)
          (setf (getf report :status) :failed (getf report :exit-code) 1 (getf report :persistence) :failed
                (getf report :diagnostic) (format nil "tools/index-rebuild-bench.lisp COD-61: ~A" condition))
          (format *error-output* "~A~%" (getf report :diagnostic)))))
    (format t "~S: ~A~%" (getf report :status) (or directory (getf report :diagnostic)))
    (when (getf report :diagnostic) (format *error-output* "~A~%" (getf report :diagnostic)))
    (sb-ext:exit :code (getf report :exit-code))))

(uiop:with-current-directory ((merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*)))
  (main))
