;;;; C4: percorso seriale routing worker/Serie, preregistrato prima di qualsiasi campagna.
;;;; Un payload 5 per ciclo; enqueue/publish/claim/routing/start/lease/pop/ack/end; nessun I/O nel ciclo.
;;;; Cinque repliche ordinate di 4096 cicli, ciascuna dopo 128 warmup e GC completa.
;;;; Fixture, API, target e contatori preallocati; heap/ticks raw, nessuna soglia temporale.
;;;; Oracolo indipendente per ciclo: 12+17+19+13+11+13+3+25+7+23 = 143.
;;;; --self-test oppure --bench directory-nuova/; fonti congelate per la campagna.
;;;; Per caricare il FASL senza CLI: feature :arcdocdb-worker-routing-bench-library.
;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
;;; OWNER: un thread possiede fixture, contesto, collegamento e sensore; nessuno SHARED.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (require :sb-md5)
  (require :sb-posix))
(defpackage #:arcdocdb.worker-routing.bench (:use #:cl))
(in-package #:arcdocdb.worker-routing.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)
(defconstant +cycle-token+ 143)

(defun fingerprints ()
  "ASD, prodotto, fixture e sensore: confronto di stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/worker-routing-bench.lisp")
                            (sort (append (directory "src/**/*.lisp")
                                          (directory "tests/**/*.lisp"))
                                  #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Compila prodotto e fixture prima della misura; warning/style-warning di compilazione fatali.
Come tools/build.lisp, la sola ridefinizione runtime di macro tra compile/load ASDF
non è un difetto di compilazione; nessuna eccezione nel COMPILE-FILE del C4 stesso."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error "COD-01: avviso non ammesso: ~A." condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb/tests" :force t))))

(defun api (package name &optional (visibility :external))
  "Risolve le API prima del clock; un nome mancante o non esportato è errore del sensore."
  (multiple-value-bind (symbol actual) (find-symbol name package)
    (unless (and symbol (eq actual visibility) (fboundp symbol))
      (error "COD-60: API ~A:~A non disponibile." package name))
    (symbol-function symbol)))

(defun with-controller (thunk)
  "Fixture mock I/O posseduta; lease iniziale rilasciata prima di invocare THUNK."
  (funcall (api "ARCDOCDB.SERIES.TESTS" "CALL-WITH-SERIES-FIXTURE" :internal)
           (lambda (fixture)
             (let* ((controller (funcall (api "ARCDOCDB.SERIES.TESTS" "SERIES-FIXTURE-CONTROLLER" :internal)
                                        fixture))
                    (lease (funcall (api "ARCDOCDB.SERIES.TESTS" "SERIES-FIXTURE-LEASE" :internal) fixture))
                    (lease-symbol (find-symbol "SERIES-FIXTURE-LEASE" "ARCDOCDB.SERIES.TESTS")))
               (funcall (api "ARCDOCDB.SERIES" "RILASCIA-CONTROLLORE-SERIE") controller lease)
               (funcall (fdefinition (list 'setf lease-symbol)) nil fixture)
               (funcall thunk controller lease)))
           :capacity 1 :csn-capacity 1))

(defun with-cycle (thunk)
  "Due Serie vive in fixture distinte; un worker alterna i due writer sul ring."
  (with-controller
   (lambda (first-controller first-lease)
     (with-controller
      (lambda (second-controller second-lease)
        (funcall thunk (cycle-function (vector first-controller second-controller)
                                       (vector first-lease second-lease))))))))

(defun enqueue-claim-function (writers worker ready table identities)
  "API e identita risolte a startup; due lookup verificano riuso dello stesso link."
  (let ((enqueue (api "ARCDOCDB.EXECUTION" "ACCODA-LAVORO-WRITER"))
        (publish (api "ARCDOCDB.EXECUTION" "PUBBLICA-WRITER-PRONTO"))
        (claim (api "ARCDOCDB.EXECUTION" "PRENDI-WRITER-WORKER"))
        (routing-index (api "ARCDOCDB.EXECUTION" "INDICE-ROUTING-WRITER"))
        (route (api "ARCDOCDB.EXECUTION.SERIES" "COLLEGA-WRITER-WORKER-SERIE"))
        (worker-writer (api "ARCDOCDB.EXECUTION" "WRITER-WORKER-WRITER"))
        (worker-state (api "ARCDOCDB.EXECUTION" "STATO-WORKER-WRITER"))
        (state (api "ARCDOCDB.EXECUTION.SERIES" "STATO-WORKER-SERIE")))
    (lambda (index)
      (let ((writer (svref writers index)) (sink 0))
        (declare (type fixnum sink))
        (multiple-value-bind (count action) (funcall enqueue writer 5)
          (unless (and (= count 1) (eq action :schedule))
            (error "COD-60: enqueue non trasferisce un obbligo unico."))
          (incf sink (+ count 11)))
        (unless (= 1 (funcall publish ready 0 writer))
          (error "COD-60: pubblicazione non trasferisce l'obbligo al ring."))
        (incf sink 17)
        (multiple-value-bind (actual status next) (funcall claim worker)
          (unless (and (eq writer actual) (eq status :claimed) (= next 0)
                       (eq writer (funcall worker-writer worker))
                       (eq :claimed (funcall worker-state worker)))
            (error "COD-60: prelievo non consegna il writer atteso.")))
        (incf sink 19)
        (let ((link (funcall route table)))
          (unless (and (= index (funcall routing-index writer))
                       (eq link (funcall route table)) (eq :idle (funcall state link)))
            (error "COD-60: indice/routing/identita o fase del link incoerenti."))
          (if (null (svref identities index))
              (setf (svref identities index) link)
              (unless (eq link (svref identities index))
                (error "COD-60: routing non riusa il link preallocato.")))
          (values link (+ sink 13)))))))

(defun transfer-function (target bridge-tokens series-leases batch-counter)
  "Un batch per ciclo; token per link, lease per Serie e token batch del worker monotoni."
  (let ((start (api "ARCDOCDB.EXECUTION.SERIES" "INIZIA-WORKER-SERIE"))
        (lease (api "ARCDOCDB.EXECUTION.SERIES" "LEASE-WORKER-SERIE"))
        (pop (api "ARCDOCDB.EXECUTION.SERIES" "PRELEVA-WORKER-SERIE"))
        (ack (api "ARCDOCDB.EXECUTION.SERIES" "CONFERMA-WORKER-SERIE"))
        (end (api "ARCDOCDB.EXECUTION.SERIES" "TERMINA-WORKER-SERIE"))
        (state (api "ARCDOCDB.EXECUTION.SERIES" "STATO-WORKER-SERIE")))
    (lambda (link index)
      (let ((sink 0))
        (declare (type fixnum sink))
        (multiple-value-bind (token status reason) (funcall start link)
          (unless (and (= token (incf (the fixnum (svref bridge-tokens index))))
                       (eq status :active) (null reason))
            (error "COD-60: token/stato di avvio incoerenti."))
          (incf sink 11)
          (unless (= (funcall lease link token) (incf (the fixnum (svref series-leases index))))
            (error "COD-60: lease Serie non monotona."))
          (incf sink 13)
          (multiple-value-bind (count status batch) (funcall pop link token target 1 2)
            (unless (and (= count 1) (eq status :messages)
                         (= batch (incf (the fixnum (svref batch-counter 0))))
                         (eql 5 (svref target 1)) (eq :outside (svref target 0))
                         (eq :outside (svref target 2)))
              (error "COD-60: batch/payload/span incoerenti."))
            (incf sink (+ (* 3 count) (* 5 (the fixnum (svref target 1)))))
            (unless (null (funcall ack link token batch))
              (error "COD-60: conferma batch non restituisce NIL."))
            (incf sink 7))
          (unless (and (eq :idle (funcall end link token)) (eq :idle (funcall state link)))
            (error "COD-60: termine non rilascia il collegamento."))
          (incf sink 23))
        sink))))

(defun cycle-function (controllers initial-leases)
  "Registro e tabella preallocati; due cicli startup fissano identita prima del sensore."
  (let* ((create-writer (api "ARCDOCDB.EXECUTION" "CREA-WRITER-PROGRAMMABILE"))
         (create-ready (api "ARCDOCDB.EXECUTION" "CREA-LISTA-WRITER-PRONTI"))
         (create-worker (api "ARCDOCDB.EXECUTION" "CREA-CONTESTO-WORKER-WRITER"))
         (create-registry (api "ARCDOCDB.EXECUTION.SERIES" "CREA-REGISTRO-WORKER-SERIE"))
         (create-table (api "ARCDOCDB.EXECUTION.SERIES" "CREA-TABELLA-WORKER-SERIE"))
         (writers (vector (funcall create-writer :capacity 1 :quantum 1 :routing-index 0)
                          (funcall create-writer :capacity 1 :quantum 1 :routing-index 1)))
         (ready (funcall create-ready :shards 1 :capacity 1))
         (worker (funcall create-worker ready))
         (registry (funcall create-registry writers controllers))
         (table (funcall create-table worker registry))
         (identities (vector nil nil)) (cursor (vector 0))
         (claim (enqueue-claim-function writers worker ready table identities))
         (transfer (transfer-function (make-array 3 :initial-element :outside)
                                      (vector 0 0) (copy-seq initial-leases) (vector 0))))
    (flet ((cycle ()
             (let ((index (svref cursor 0)))
               (setf (svref cursor 0) (- 1 (the fixnum index)))
               (multiple-value-bind (link sink) (funcall claim index)
                 (+ (the fixnum sink) (the fixnum (funcall transfer link index)))))))
      (unless (and (= +cycle-token+ (cycle)) (= +cycle-token+ (cycle))
                   (not (eq (svref identities 0) (svref identities 1))))
        (error "COD-60: startup non fissa due identita distinte e il sink atteso."))
      #'cycle)))

(defun sample-record (replica iterations warmup token)
  "Tutti i campi esistono prima di warmup, heap e clock; oracolo calcolato indipendentemente."
  (list :replica replica :status :running :stage :warmup :iterations iterations
        :warmup-iterations warmup :completed-iterations 0 :heap-bytes nil :raw-ticks nil
        :seconds nil :time-quality :pending :sink nil :diagnostic nil
        :expected-sink (logand most-positive-fixnum
                              (+ (* iterations token) (/ (* iterations (1- iterations)) 2)))))

(defun sample (function iterations token progress &key (warmup +warmup+) (clock #'get-internal-real-time))
  "Misura bounded, GC prima del clock; anche l'errore conserva cicli e raw parziali."
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error "COD-60: parametri fuori dal budget preregistrato."))
  (dotimes (i warmup) (funcall function))
  (sb-ext:gc :full t)
  (setf (getf progress :stage) :measured)
  (let ((before (funcall clock)) (heap-before (sb-ext:get-bytes-consed)) (sink 0) (failure nil))
    (declare (type fixnum sink))
    (handler-case
        (dotimes (i iterations)
          (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall function))))
                (getf progress :completed-iterations) (1+ i)))
      (error (condition) (setf failure condition)))
    (let ((heap (- (sb-ext:get-bytes-consed) heap-before)) (ticks (- (funcall clock) before)))
      (setf (getf progress :heap-bytes) heap (getf progress :raw-ticks) ticks
            (getf progress :sink) sink (getf progress :time-quality)
            (if (zerop ticks) :below-resolution :measured)
            (getf progress :seconds) (when (plusp ticks) (/ ticks (float internal-time-units-per-second 1d0))))
      (when failure (error failure))
      (unless (and (>= heap 0) (>= ticks 0) (= sink (getf progress :expected-sink)))
        (error "COD-60: heap/clock negativo o sink ~D diverso da ~D." sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun campaign (report checkpoint)
  "Cinque campioni nello stesso contesto; checkpoint prima e dopo ogni misura."
  (with-cycle
   (lambda (function)
     (dotimes (replica +replicas+)
       (let ((progress (sample-record replica +iterations+ +warmup+ +cycle-token+)))
         (setf (getf report :current-replica) replica
               (getf report :samples) (append (getf report :samples) (list progress)))
         (funcall checkpoint)
         (sample function +iterations+ +cycle-token+ progress)
         (funcall checkpoint)
         (unless (zerop (getf progress :heap-bytes))
           (setf (getf progress :status) :failed
                 (getf progress :diagnostic) "COD-30: heap osservato positivo.")
           (error "COD-30: heap osservato positivo nella replica ~D." replica))))))
  (setf (getf report :current-replica) nil)
  report)

(defun make-report ()
  "Metadati, formula e limiti espliciti; il sensore non qualifica parallelismo o I/O."
  (list :schema-version 1 :kind :worker-routing-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version)
        :workers 1 :writers 2 :series 2 :startup-cycles 2 :shards 1
        :writer-capacity 1 :ready-capacity 1 :serie-capacity 1 :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+ :payload 5
        :timer-units-per-second internal-time-units-per-second :expected-cycle-token +cycle-token+
        :token-formula "12+17+19+13+11+13+3+5*5+7+23=143; sample=N*143+N*(N-1)/2"
        :limits '(:success-path-only :serial-owner :alternating-two-writers-and-series
                  :preallocated-inputs :mock-io-startup-only
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-contention-pool-device-durability-or-release-qualification
                  :no-startup-allocation-claim)))

(defun acquire-directory (path)
  "Directory esclusiva 0700; rifiuta una destinazione precedente senza scriverla."
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report directory)
  "Checkpoint esclusivo nella directory reclamata; ultimo rapporto leggibile conservato."
  (with-open-file (stream (merge-pathnames "report.next.lisp" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames "report.next.lisp" directory)
                                     (merge-pathnames "report.lisp" directory)))

(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "CLI, load e sensori conservati; fallimenti mantengono replica e contatori già raccolti."
  (let ((report (make-report)) (directory nil))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= 2 (length args)) (string= "--bench" (first args))))
            (error "COD-61: uso --self-test oppure --bench directory-nuova/."))
          (when (= 2 (length args)) (setf directory (acquire-directory (second args))))
          (setf (getf report :stage) :load-product)
          (when directory (write-report report directory))
          (funcall product-loader)
          (setf (getf report :stage) :self-test (getf report :self-test) (funcall tester))
          (when directory
            (setf (getf report :stage) :campaign)
            (funcall runner report (lambda () (write-report report directory))))
          (setf (getf report :status) :ok (getf report :stage) :complete))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
        (let ((last (car (last (getf report :samples)))))
          (when (and last (eq :running (getf last :status)))
            (setf (getf last :status) :failed (getf last :diagnostic) (princ-to-string condition))))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after (getf report :source-consistency)
            (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
      (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
        (setf (getf report :status) :source-changed (getf report :diagnostic) "COD-61: sorgenti cambiati.")))
    (when directory (write-report report directory))
    report))

(defun fresh-self-test-directory ()
  "Fixture temporanea esclusiva; limite esplicito di mille collisioni."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-worker-routing-bench-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "COD-60: impossibile acquisire directory della fixture."))

(defun read-self-test-report (directory)
  "Legge soltanto la fixture prodotta dal sensore; nessuna valutazione del dato."
  (let ((*read-eval* nil))
    (with-open-file (stream (merge-pathnames "report.lisp" directory)) (read stream))))

(defun self-test-reporter ()
  "Destinazione precedente intatta; campione completo e raw parziale sopravvivono all'errore."
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames "existing/" root)))
                (failed (merge-pathnames "failed/" root)))
           (write-report '(:sentinel :unchanged) existing)
           (unless (and (eq :failed (getf (run-driver (list "--bench" (namestring existing))
                                                    :product-loader (constantly nil)
                                                    :tester (constantly :passed)) :status))
                        (equal (read-self-test-report existing) '(:sentinel :unchanged)))
             (error "COD-60: report precedente non conservato."))
           (run-driver (list "--bench" (namestring failed))
                       :product-loader (constantly nil) :tester (constantly :passed)
                       :runner (lambda (report checkpoint)
                                 (setf (getf report :current-replica) 1 (getf report :samples)
                                       (list (list :status :ok :raw-ticks 3 :heap-bytes 0)
                                             (list :status :running :raw-ticks 7 :heap-bytes 11
                                                   :diagnostic nil)))
                                 (funcall checkpoint)
                                 (error "fixture: replica interrotta")))
           (let* ((saved (read-self-test-report failed)) (samples (getf saved :samples)))
             (unless (and (eq :failed (getf saved :status)) (= 1 (getf saved :current-replica))
                          (= 2 (length samples)) (eq :ok (getf (first samples) :status))
                          (eq :failed (getf (second samples) :status))
                          (= 7 (getf (second samples) :raw-ticks))
                          (= 11 (getf (second samples) :heap-bytes)))
               (error "COD-60: campione precedente o raw del fallimento persi."))))
      ;; La cancellazione C4 riguarda soltanto la directory acquisita da questa fixture.
      (uiop:delete-directory-tree root :validate t)))
  :passed)

(defun self-test-partial-sample ()
  "Errore del ciclo misurato: clock/heap/sink e numero completato sono preservati."
  (let ((progress (sample-record 0 4 0 0)) (calls 0) (clock 0))
    (unless (handler-case
                (progn (sample (lambda ()
                                 (incf calls)
                                 (when (= calls 2) (error "fixture: misura interrotta"))
                                 0)
                               4 0 progress :warmup 0 :clock (lambda () (incf clock 7)))
                       nil)
              (error (condition)
                (setf (getf progress :status) :expected-rejection
                      (getf progress :diagnostic) (princ-to-string condition)) t))
      (error "COD-60: ciclo difettoso non interrotto."))
    (unless (and (= calls 2) (= 1 (getf progress :completed-iterations))
                 (= 0 (getf progress :sink)) (= 7 (getf progress :raw-ticks))
                 (>= (getf progress :heap-bytes) 0) (eq :measured (getf progress :stage)))
      (error "COD-60: raw parziale della misura non conservato."))
    progress))

(defun self-test ()
  "Prove sensore: allocazione positiva, sink errato, clock nullo, ciclo API e CLI invalida."
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0))
         (positive (sample-record 0 16 0 1048576)) (probe nil)
         (wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0))
         (composed (sample-record 0 4 0 +cycle-token+)))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error "COD-60: contatore baseline non nullo."))
    (sample (lambda ()
              (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
              (length probe)) 16 1048576 positive :warmup 0)
    (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error "COD-60: allocazione deliberata non rilevata."))
    (unless (handler-case (progn (sample (lambda () 1) 2 0 wrong :warmup 0) nil)
              (error (condition)
                (setf (getf wrong :status) :expected-rejection
                      (getf wrong :diagnostic) (princ-to-string condition)) t))
      (error "COD-60: sink errato non respinto."))
    (sample (lambda () 0) 2 0 zero :warmup 0 :clock (constantly 0))
    (unless (and (eq :below-resolution (getf zero :time-quality)) (null (getf zero :seconds)))
      (error "COD-60: clock nullo convertito in durata."))
    (with-cycle (lambda (function) (sample function 4 +cycle-token+ composed :warmup 0)))
    (let ((called nil))
      (dolist (args '(nil ("--bench") ("--bad") ("--bench" "directory" "extra")))
        (unless (and (eq :failed (getf (run-driver args :product-loader (lambda () (setf called t))) :status))
                     (null called))
          (error "COD-60: CLI invalida eseguita."))))
    (list :status :ok :baseline baseline :positive-control positive :wrong-sink-probe wrong
          :zero-clock-probe zero :composed-api-probe composed :invalid-cli :rejected
          :existing-destination-and-partial-raw (self-test-reporter)
          :measured-partial-raw (self-test-partial-sample))))

(defun main ()
  "CLI C4: rapporto leggibile, errore esplicito e exit nonzero per ogni fallimento."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&worker-routing-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))

(unless (member :arcdocdb-worker-routing-bench-library *features*) (main))
