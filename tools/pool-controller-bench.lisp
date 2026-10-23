;;;; C4: controller pool owner-only EWMA/AIMD/isteresi; nessun thread creato o sospeso.
;;;; Preregistrato: cinque repliche di 4096 cicli, 128 warmup, GC completa prima del sensore.
;;;; Ciclo: 80 campioni grow, 80 shrink, un controller pending e uno hold; read dopo ogni update.
;;;; Oracolo lento indipendente genera tutte le attese prima del clock e torna alla base dopo 160 tick.
;;;; --self-test oppure --bench directory-nuova/; startup/errori esclusi dal percorso caldo.
;;;; Feature biblioteca: :arcdocdb-pool-controller-bench-library.
;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
;;; OWNER: un thread possiede controller, trace, contatori e sensore; nessuno SHARED.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf) (require :sb-md5) (require :sb-posix))
(defpackage #:arcdocdb.pool-controller.bench (:use #:cl))
(in-package #:arcdocdb.pool-controller.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))
(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)
(defconstant +phase-length+ 80)

(defun fingerprints ()
  "ASD, controller, test e sensore: confronto di stabilita, non autenticita."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/pool-controller-bench.lisp")
                            (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                                  #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Compila prima della misura; warning/style-warning fatali salvo ridefinizione runtime ASDF."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (c)
                             (unless (typep c 'sb-kernel:redefinition-warning)
                               (error "COD-01 tools/pool-controller-bench.lisp: ~A." c)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb/tests" :force t))))

(defun api (name)
  "Risolve soltanto API pubbliche prima del clock; un nome mancante e difetto C4."
  (multiple-value-bind (symbol visibility) (find-symbol name "ARCDOCDB.SCHEDULER")
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60 tools/pool-controller-bench.lisp: API ~A assente." name))
    (symbol-function symbol)))

(defun action-token (action)
  "Codici di risultato distinti, preregistrati; rifiuta un risultato inatteso."
  (ecase action (:hold 11) (:pending 17) (:grow 23) (:shrink 31)))

(defun reference-trace ()
  "Oracolo matematico startup: EWMA razionale troncata, +1 e floor(3N/4), dwell=1.
Le righe sono vettori (actual target action queue-scaled candidate since-relative).
Non chiama il prodotto. Il giro torna a target=1, EWMA=0 e candidato :hold."
  (let ((rows (make-array (* 2 +phase-length+))) (queue 0) (target 1)
        (candidate :hold) (since 0) (token 0))
    (dotimes (index (length rows))
      (let* ((tick (1+ index)) (actual target) (value (if (< index +phase-length+) 128 0))
             (action :hold))
        (setf queue (floor (+ (* 7 queue) (* 256 value)) 8))
        (let ((direction (cond ((< queue 256) :shrink) ((>= queue 2048) :grow) (t :hold))))
          (cond
            ((or (eq direction :hold) (and (eq direction :grow) (= target 8))
                 (and (eq direction :shrink) (= target 1)))
             (setf candidate :hold since tick))
            ((not (eq direction candidate)) (setf candidate direction since tick))
            ((>= (- tick since) 1)
             (setf target (if (eq direction :grow) (min 8 (1+ target)) (max 1 (floor (* 3 target) 4)))
                   action direction candidate :hold since tick))))
        (setf (svref rows index) (vector actual target action queue candidate since))
        (incf token (+ target (action-token action) queue))))
    (unless (and (= target 1) (= queue 0) (eq candidate :hold) (= since (* 2 +phase-length+)))
      (error "COD-60 tools/pool-controller-bench.lisp: l'oracolo non torna alla base."))
    (values rows (+ token 4 17 4 11))))

(defun verify-state (read controller target queue cpu p99 tick candidate since)
  "Confronta tutti i sette risultati; le attese sono scalari/oggetti preregistrati."
  (multiple-value-bind (a b c d e f g) (funcall read controller)
    (unless (and (eql a target) (eql b queue) (eql c cpu) (eql d p99)
                 (eql e tick) (eq f candidate) (eql g since))
      (error "COD-60 tools/pool-controller-bench.lisp: oracolo del controller difforme al tick ~A." tick))))

(defun create-cycle ()
  "Prealloca tre controller e trace; restituisce funzione caldo e token indipendente.
Controller principale: period=dwell=1, min=1/max=8. Altri due period=dwell=160."
  (let* ((create (api "CREA-CONTROLLORE-POOL")) (update (api "AGGIORNA-CONTROLLORE-POOL"))
         (read (api "LEGGI-CONTROLLORE-POOL"))
         (main (funcall create 4 :minimum 1 :maximum 8 :initial 1 :period 1 :dwell 1))
         (pending (funcall create 4 :initial 4 :period 160 :dwell 160))
         (hold (funcall create 4 :initial 4 :period 160 :dwell 160)) (offset 0))
    (funcall update main 0 0 100 900 1)
    (funcall update pending 0 128 100 900 1)
    (funcall update hold 0 128 900 900 4)
    (multiple-value-bind (rows token) (reference-trace)
      (values
       (lambda ()
         (let ((sink 0))
           (declare (type fixnum sink offset))
           (dotimes (index (length rows))
             (let* ((row (svref rows index)) (tick (+ offset index 1))
                    (value (if (< index +phase-length+) 128 0))
                    (since (+ offset (the fixnum (svref row 5)))))
               (multiple-value-bind (target action) (funcall update main tick value 100 900 (svref row 0))
                 (unless (and (eql target (svref row 1)) (eq action (svref row 2)))
                   (error "COD-60 tools/pool-controller-bench.lisp: decisione difforme al tick ~D." tick))
                 (verify-state read main target (svref row 3) 25600 230400 tick (svref row 4) since)
                 (incf sink (+ (the fixnum target) (action-token action) (the fixnum (svref row 3)))))))
           (incf offset (* 2 +phase-length+))
           (multiple-value-bind (target action) (funcall update pending offset 128 100 900 1)
             (unless (and (eql target 4) (eq action :pending))
               (error "COD-60 tools/pool-controller-bench.lisp: pending non conserva target."))
             (verify-state read pending 4 32768 25600 230400 offset :hold offset)
             (incf sink (+ (the fixnum target) (action-token action))))
           (multiple-value-bind (target action) (funcall update hold offset 128 900 900 4)
             (unless (and (eql target 4) (eq action :hold))
               (error "COD-60 tools/pool-controller-bench.lisp: CPU alta non conserva target."))
             (verify-state read hold 4 32768 230400 230400 offset :hold offset)
             (incf sink (+ (the fixnum target) (action-token action))))
           sink)) token))))

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
  "Cinque repliche owner-only; ogni fixture e all'esterno del tratto misurato."
  (multiple-value-bind (function token) (create-cycle)
    (setf (getf report :expected-cycle-token) token)
    (dotimes (replica +replicas+)
      (let ((progress (sample-record replica +iterations+ +warmup+ token)))
        (setf (getf report :current-replica) replica
              (getf report :samples) (append (getf report :samples) (list progress)))
        (funcall checkpoint)
        (sample function +iterations+ token progress)
        (funcall checkpoint)
        (unless (zerop (getf progress :heap-bytes))
          (setf (getf progress :status) :failed (getf progress :diagnostic) "COD-30: heap osservato positivo.")
          (error "COD-30 tools/pool-controller-bench.lisp: heap positivo nella replica ~D." replica)))))
  (setf (getf report :current-replica) nil)
  report)

(defun make-report ()
  "Metadati, formula e limiti espliciti; misure non qualificano il pool runtime."
  (list :schema-version 1 :kind :pool-controller-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version)
        :controllers 3 :owner-threads 1 :cores-input 4 :minimum 1 :maximum 8 :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+ :samples-per-cycle 162
        :timer-units-per-second internal-time-units-per-second :expected-cycle-token nil
        :trace '(:grow-samples 80 :queue 128 :cpu 100 :p99 900 :shrink-samples 80 :queue 0
                 :pending-actual 1 :pending-target 4 :hold-cpu 900 :hold-target 4)
        :token-formula "sum(target+action-token+queue-scaled) on 160 rows; pending=4+17; hold=4+11; sample=N*token+N*(N-1)/2"
        :limits '(:serial-owner :injected-inputs :preallocated-trace :startup-errors-excluded
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :no-pool-worker-park-wake-contention-io-durability-or-release-qualification)))

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
                         (format nil "arcdocdb-pool-controller-bench-~D-~D-~D/"
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

(defun self-test-invalid-input ()
  "Rifiuto tipizzato fuori misura; il campione invalido non applica un prefisso."
  (let* ((controller (funcall (api "CREA-CONTROLLORE-POOL") 4))
         (update (api "AGGIORNA-CONTROLLORE-POOL")) (read (api "LEGGI-CONTROLLORE-POOL")))
    (funcall update controller 0 128 100 900 1)
    (let ((before (multiple-value-list (funcall read controller))))
      (unless (handler-case
                  (progn (funcall update controller 500 128 1001 900 1) nil)
                (error (condition)
                  (typep condition (find-symbol "INVALID-ARGUMENT" "ARCDOCDB.CONDITIONS"))))
        (error "COD-60 tools/pool-controller-bench.lisp: campione invalido accettato o errore non tipizzato."))
      (unless (equal before (multiple-value-list (funcall read controller)))
        (error "COD-60 tools/pool-controller-bench.lisp: campione invalido muta il controller."))))
  :passed)

(defun self-test ()
  "Fixture positiva/negativa: sensore heap, sink, clock, oracolo API, output e CLI."
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0))
         (positive (sample-record 0 16 0 1048576)) (probe nil)
         (wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0)) (composed nil))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error "COD-60: baseline heap non nullo."))
    (sample (lambda () (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
              (length probe)) 16 1048576 positive :warmup 0)
    (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error "COD-60: allocazione deliberata non rilevata."))
    (unless (handler-case (progn (sample (lambda () 1) 2 0 wrong :warmup 0) nil)
              (error (condition) (setf (getf wrong :status) :expected-rejection
                                      (getf wrong :diagnostic) (princ-to-string condition)) t))
      (error "COD-60: sink errato non respinto."))
    (sample (lambda () 0) 2 0 zero :warmup 0 :clock (constantly 0))
    (unless (and (eq :below-resolution (getf zero :time-quality)) (null (getf zero :seconds)))
      (error "COD-60: clock nullo convertito in durata."))
    (multiple-value-bind (function token) (create-cycle)
      (setf composed (sample-record 0 4 0 token))
      (sample function 4 token composed :warmup 0))
    (unless (handler-case
                (progn (verify-state (lambda (controller) (declare (ignore controller))
                                       (values 2 0 0 0 nil :hold nil)) nil 1 0 0 0 nil :hold nil) nil)
              (error () t))
      (error "COD-60: fixture target difforme non respinta."))
    (let ((called nil))
      (dolist (args '(nil ("--bench") ("--bad") ("--bench" "directory" "extra")))
        (unless (and (eq :failed (getf (run-driver args :product-loader (lambda () (setf called t))) :status))
                     (null called))
          (error "COD-60: CLI invalida eseguita."))))
    (list :status :ok :baseline baseline :positive-control positive :wrong-sink-probe wrong
          :zero-clock-probe zero :composed-api-probe composed :invalid-cli :rejected
          :target-oracle-positive-negative :passed :invalid-non-hot (self-test-invalid-input)
          :existing-destination-and-partial-raw (self-test-reporter)
          :measured-partial-raw (self-test-partial-sample))))

(defun main ()
  "Rapporto leggibile; ogni errore esce nonzero con diagnosi C4."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/pool-controller-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-controller-bench-library *features*) (main))
