;;;; C4: percorso seriale worker/Serie, preregistrato prima di qualsiasi campagna.
;;;; Un payload 5 per ciclo; enqueue/adopt/start/lease/pop/ack/end; nessun I/O nel ciclo.
;;;; Cinque repliche ordinate di 4096 cicli, ciascuna dopo 128 warmup e GC completa.
;;;; Fixture, API, target e contatori preallocati; heap/ticks raw, nessuna soglia temporale.
;;;; Oracolo indipendente per ciclo: 12+7+11+13+3+25+7+23 = 101.
;;;; --self-test oppure --bench directory-nuova/; fonti congelate per la campagna.
;;;; Per caricare il FASL senza CLI: feature :arcdocdb-worker-series-bench-library.
;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
;;; OWNER: un thread possiede fixture, contesto, collegamento e sensore; nessuno SHARED.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (require :sb-md5)
  (require :sb-posix))
(defpackage #:arcdocdb.worker-series.bench (:use #:cl))
(in-package #:arcdocdb.worker-series.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)
(defconstant +cycle-token+ 101)

(defun fingerprints ()
  "ASD, prodotto, fixture e sensore: confronto di stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/worker-series-bench.lisp")
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

(defun with-cycle (thunk)
  "Fixture mock I/O posseduta; lease iniziale rilasciata prima di invocare THUNK."
  (funcall (api "ARCDOCDB.SERIES.TESTS" "CALL-WITH-SERIES-FIXTURE" :internal)
           (lambda (fixture)
             (let* ((controller (funcall (api "ARCDOCDB.SERIES.TESTS" "SERIES-FIXTURE-CONTROLLER" :internal)
                                        fixture))
                    (lease (funcall (api "ARCDOCDB.SERIES.TESTS" "SERIES-FIXTURE-LEASE" :internal) fixture))
                    (lease-symbol (find-symbol "SERIES-FIXTURE-LEASE" "ARCDOCDB.SERIES.TESTS")))
               (funcall (api "ARCDOCDB.SERIES" "RILASCIA-CONTROLLORE-SERIE") controller lease)
               (funcall (fdefinition (list 'setf lease-symbol)) nil fixture)
               (funcall thunk (cycle-function controller lease))))
           :capacity 1 :csn-capacity 1))

(defun cycle-function (controller initial-lease)
  "Un obbligo esterno e un batch per ciclo; token/lease monotoni e span esatti verificati."
  (let* ((create-writer (api "ARCDOCDB.EXECUTION" "CREA-WRITER-PROGRAMMABILE"))
         (create-ready (api "ARCDOCDB.EXECUTION" "CREA-LISTA-WRITER-PRONTI"))
         (create-worker (api "ARCDOCDB.EXECUTION" "CREA-CONTESTO-WORKER-WRITER"))
         (enqueue (api "ARCDOCDB.EXECUTION" "ACCODA-LAVORO-WRITER"))
         (adopt (api "ARCDOCDB.EXECUTION" "ADOTTA-WRITER-WORKER"))
         (worker-writer (api "ARCDOCDB.EXECUTION" "WRITER-WORKER-WRITER"))
         (create-link (api "ARCDOCDB.EXECUTION.SERIES" "CREA-COLLEGAMENTO-WORKER-SERIE"))
         (start (api "ARCDOCDB.EXECUTION.SERIES" "INIZIA-WORKER-SERIE"))
         (lease (api "ARCDOCDB.EXECUTION.SERIES" "LEASE-WORKER-SERIE"))
         (pop (api "ARCDOCDB.EXECUTION.SERIES" "PRELEVA-WORKER-SERIE"))
         (ack (api "ARCDOCDB.EXECUTION.SERIES" "CONFERMA-WORKER-SERIE"))
         (end (api "ARCDOCDB.EXECUTION.SERIES" "TERMINA-WORKER-SERIE"))
         (state (api "ARCDOCDB.EXECUTION.SERIES" "STATO-WORKER-SERIE"))
         (writer (funcall create-writer :capacity 1 :quantum 1))
         (worker (funcall create-worker (funcall create-ready :shards 1 :capacity 1)))
         (link (funcall create-link worker writer controller))
         (target (make-array 3 :initial-element :outside))
         (counters (vector 0 initial-lease 0)))
    (lambda ()
      (let ((sink 0))
        (declare (type fixnum sink))
      (multiple-value-bind (count action) (funcall enqueue writer 5)
        (unless (and (= count 1) (eq action :schedule))
          (error "COD-60: enqueue non trasferisce un obbligo unico."))
        (incf sink (+ count 11)))
      (unless (null (funcall adopt worker writer 0))
        (error "COD-60: adozione worker non restituisce NIL."))
      (incf sink 7)
      (multiple-value-bind (token status reason) (funcall start link)
        (unless (and (= token (incf (the fixnum (svref counters 0))))
                     (eq status :active) (null reason) (eq writer (funcall worker-writer worker)))
          (error "COD-60: identità/token/stato di avvio incoerenti."))
        (incf sink 11)
        (unless (= (funcall lease link token) (incf (the fixnum (svref counters 1))))
          (error "COD-60: lease Serie non monotona."))
        (incf sink 13)
        (multiple-value-bind (count status batch) (funcall pop link token target 1 2)
          (unless (and (= count 1) (eq status :messages)
                       (= batch (incf (the fixnum (svref counters 2))))
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
  (list :schema-version 1 :kind :worker-series-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version)
        :workers 1 :shards 1 :writer-capacity 1 :ready-capacity 1 :serie-capacity 1 :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+ :payload 5
        :timer-units-per-second internal-time-units-per-second :expected-cycle-token +cycle-token+
        :token-formula "12+7+11+13+3+5*5+7+23=101; sample=N*101+N*(N-1)/2"
        :limits '(:success-path-only :serial-owner :preallocated-inputs :mock-io-startup-only
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-contention-pool-device-durability-or-release-qualification)))

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
                         (format nil "arcdocdb-worker-series-bench-~D-~D-~D/"
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
          :existing-destination-and-partial-raw (self-test-reporter))))

(defun main ()
  "CLI C4: rapporto leggibile, errore esplicito e exit nonzero per ogni fallimento."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&worker-series-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))

(unless (member :arcdocdb-worker-series-bench-library *features*) (main))
