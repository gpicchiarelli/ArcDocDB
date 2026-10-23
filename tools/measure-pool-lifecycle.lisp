;;;; C4: attuazione logica worker; APPLY e REGISTRY separati dalle barriere della fixture.
;;;; Preregistrato: cinque repliche di 4096 cicli, 128 warmup, GC completa prima del sensore.
;;;; APPLY usa richiesta privata quiescente; REGISTRY usa due owner reali preavviati.
;;;; Nessun clock, thread o attesa in prodotto; questo file contiene soltanto il sensore C4.
;;;; --self-test oppure --bench directory-nuova/; startup/errori esclusi dal percorso caldo.
;;;; Feature biblioteca: :arcdocdb-pool-lifecycle-measure-library.
;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
;;; OWNER: sensore/registri al coordinatore; ogni contesto al suo worker di startup.
;;; SHARED: solo pubblicazione iniziale C4 e porte del protocollo, senza messaggi nel clock.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf) (require :sb-md5) (require :sb-posix))
(defpackage #:arcdocdb.pool-lifecycle.measure (:use #:cl))
(in-package #:arcdocdb.pool-lifecycle.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))
(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "ASD, controller, test e sensore: confronto di stabilita, non autenticita."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/measure-pool-lifecycle.lisp")
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
                               (error "COD-01 tools/measure-pool-lifecycle.lisp: ~A." c)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb/tests" :force t))))

(defun api (name)
  "Risolve soltanto API pubbliche prima del clock; un nome mancante e difetto C4."
  (multiple-value-bind (symbol visibility) (find-symbol name "ARCDOCDB.SCHEDULER")
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60 tools/measure-pool-lifecycle.lisp: API ~A assente." name))
    (symbol-function symbol)))

(defun lookup-function (name package &optional setter)
  "API e accessor C4 risolti prima del clock; niente simboli o closure nel percorso caldo."
  (let ((symbol (find-symbol name package)))
    (unless symbol (error "COD-60: simbolo ~A/~A assente." package name))
    (fdefinition (if setter (list 'setf symbol) symbol))))

(defun verify-apply (apply port active status)
  "Oracolo scalare indipendente per ciascun risultato applicato o ripetuto."
  (multiple-value-bind (actual action) (funcall apply port)
    (unless (and (eq active actual) (eq status action))
      (error "COD-60: applica restituisce ~S/~S invece di ~S/~S." actual action active status))))

(defun verify-registry (read registry actual target pending)
  "Tre risultati pubblici distinti; un comando non vale una conferma."
  (multiple-value-bind (a b c) (funcall read registry)
    (unless (and (eql a actual) (eql b target) (eq c pending))
      (error "COD-60: registro diverso dall'oracolo ~S/~S/~S." actual target pending))))

(defun make-context ()
  "Contesto C1 autentico e IDLE, creato fuori dalla misura sul suo owner."
  (let ((ready (lookup-function "CREA-LISTA-WRITER-PRONTI" "ARCDOCDB.EXECUTION"))
        (context (lookup-function "CREA-CONTESTO-WORKER-WRITER" "ARCDOCDB.EXECUTION")))
    (funcall context (funcall ready :shards 1 :capacity 1))))

(defun create-apply-cycle ()
  "Fixture C4 privata: un thread svolge serialmente ruoli owner/coordinator.
Scrive REQUEST soltanto dopo la conferma precedente; nessun lease, reset o wrap.
Quattro applicazioni/ciclo: retired, unchanged, activated, unchanged; token fisso78."
  (let* ((port (funcall (api "CREA-PORTA-WORKER-POOL") (make-context)))
         (apply (api "APPLICA-STATO-WORKER-POOL"))
         (set-request (lookup-function "PORTA-WORKER-POOL-REQUEST" "ARCDOCDB.SCHEDULER" t))
         (read-ack (lookup-function "PORTA-WORKER-POOL-ACK" "ARCDOCDB.SCHEDULER"))
         (generation 0))
    (values
     (lambda ()
       (declare (type fixnum generation))
       (let ((retired (* 2 (incf generation))))
         (funcall set-request retired port)
         (verify-apply apply port nil :retired)
         (verify-apply apply port nil :unchanged)
         (unless (= retired (the fixnum (funcall read-ack port)))
           (error "COD-60: conferma ritiro diversa dalla generazione richiesta.")))
       (let ((activated (1+ (* 2 (incf generation)))))
         (funcall set-request activated port)
         (verify-apply apply port t :activated)
         (verify-apply apply port t :unchanged)
         (unless (= activated (the fixnum (funcall read-ack port)))
           (error "COD-60: conferma attivazione diversa dalla generazione richiesta.")))
       78)
     78 (constantly nil))))

(defun fixture-worker (index ports failures coordinator ready stop)
  "Solo startup C4: due contesti del worker, pubblicazione e attesa bounded fuori clock."
  (handler-case
      (progn
        (dolist (offset '(0 2))
          (setf (svref ports (+ index offset))
                (funcall (api "CREA-PORTA-WORKER-POOL") (make-context)
                         :coordinator coordinator :active (zerop index))))
        (sb-thread:signal-semaphore ready)
        (loop repeat 120 when (sb-thread:wait-on-semaphore stop :timeout 1d0) return t))
    (error (condition)
      (setf (svref failures index) condition)
      (sb-thread:signal-semaphore ready))))

(defun fixture-cleanup (threads stop)
  "Termina soltanto i thread della fixture, con timeout esplicito; niente kill."
  (dolist (thread threads) (declare (ignore thread)) (sb-thread:signal-semaphore stop))
  (dolist (thread threads)
    (when (eq :join-timeout (sb-thread:join-thread thread :timeout 5d0 :default :join-timeout))
      (error "COD-60: owner fixture non terminato entro il budget.")))
  nil)

(defun create-registry-cycle ()
  "Due registri distinti su due owner reali; attese e startup fuori dal sensore.
HOLD target1 CPU900, PENDING target2 actual1 pubblicato da un vero grow iniziale.
Ogni ciclo contiene due update e due letture; nessuna conferma finta; token34."
  (let* ((ports (make-array 4 :initial-element nil)) (failures (make-array 2 :initial-element nil))
         (ready (sb-thread:make-semaphore)) (stop (sb-thread:make-semaphore))
         (coordinator sb-thread:*current-thread*) (threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (index 2)
             (let ((i index))
               (push (sb-thread:make-thread
                      (lambda () (fixture-worker i ports failures coordinator ready stop))
                      :name "pool-lifecycle-C4-startup") threads)))
           (dotimes (index 2)
             (unless (sb-thread:wait-on-semaphore ready :timeout 5d0)
               (error "COD-60: owner fixture non avviato entro il budget.")))
           (dotimes (index 2) (when (svref failures index) (error (svref failures index))))
           (let* ((create (api "CREA-CONTROLLORE-POOL")) (register (api "CREA-REGISTRO-POOL"))
                  (update (api "AGGIORNA-REGISTRO-POOL")) (read (api "LEGGI-REGISTRO-POOL"))
                  (hold (funcall register (funcall create 1 :maximum 2 :initial 1 :period 1 :dwell 1)
                                 (vector (svref ports 0) (svref ports 1))))
                  (pending (funcall register (funcall create 1 :maximum 2 :initial 1 :period 1 :dwell 1)
                                    (vector (svref ports 2) (svref ports 3)))) (tick 1))
             (funcall update hold 1 128 900 900)
             (funcall update pending 0 128 100 900)
             (multiple-value-bind (target action actual outstanding) (funcall update pending 1 128 100 900)
               (unless (and (= 2 target) (eq :grow action) (= 1 actual) outstanding)
                 (error "COD-60: grow iniziale non ha prodotto comando pendente.")))
             (verify-registry read hold 1 1 nil) (verify-registry read pending 1 2 t)
             (setf complete t)
             (values
              (lambda ()
                (declare (type fixnum tick))
                (incf tick)
                (multiple-value-bind (target action actual outstanding) (funcall update hold tick 128 900 900)
                  (unless (and (= 1 target) (eq :hold action) (= 1 actual) (null outstanding))
                    (error "COD-60: wrapper hold diverso dall'oracolo.")))
                (verify-registry read hold 1 1 nil)
                (multiple-value-bind (target action actual outstanding) (funcall update pending tick 128 100 900)
                  (unless (and (= 2 target) (eq :pending action) (= 1 actual) outstanding)
                    (error "COD-60: wrapper pending diverso dall'oracolo.")))
                (verify-registry read pending 1 2 t)
                34)
              34 (lambda () (fixture-cleanup threads stop)))))
      (unless complete (fixture-cleanup threads stop)))))

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

(defun campaign-group (name maker report checkpoint)
  "Una fixture startup e cinque repliche; gli errori mantengono anche il raw parziale."
  (multiple-value-bind (function token cleanup) (funcall maker)
    (unwind-protect
         (dotimes (replica +replicas+)
           (let ((progress (sample-record replica +iterations+ +warmup+ token)))
             (setf (getf progress :campaign) name (getf report :current-replica) replica
                   (getf report :samples) (append (getf report :samples) (list progress)))
             (funcall checkpoint)
             (sample function +iterations+ token progress)
             (funcall checkpoint)
             (unless (zerop (getf progress :heap-bytes))
               (setf (getf progress :status) :failed (getf progress :diagnostic) "COD-30: heap osservato positivo.")
               (error "COD-30: heap positivo nella campagna ~S replica ~D." name replica))))
      (funcall cleanup)))
  report)

(defun campaign (report checkpoint)
  "APPLY e REGISTRY misurati separatamente; nessuna sincronizzazione nel tratto caldo."
  (campaign-group :owner-apply #'create-apply-cycle report checkpoint)
  (campaign-group :coordinator-registry #'create-registry-cycle report checkpoint)
  (setf (getf report :current-replica) nil)
  report)

(defun make-report ()
  "Confini espliciti: conferme logiche e fixture C4, nessuna misura park/wake o motore vivo."
  (list :schema-version 1 :kind :pool-lifecycle-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:owner-apply :real-context t :roles-serialized t :private-request-fixture t
                     :apply-per-cycle 4 :generation-increments-per-cycle 2 :token 78)
                    (:coordinator-registry :registries 2 :workers 2 :contexts 4 :ports 4
                     :updates-per-cycle 2 :reads-per-cycle 2 :token 34))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; APPLY=78; REGISTRY=34"
        :limits '(:preallocated-product-and-inputs :startup-and-gc-excluded
                  :fixture-thread-barriers-outside-clock :no-thread-harness-heap-attribution
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :no-physical-start-retire-park-wake-shutdown-io-durability-qualification)))

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
                         (format nil "arcdocdb-pool-lifecycle-measure-~D-~D-~D/"
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
        (error "COD-60 tools/measure-pool-lifecycle.lisp: campione invalido accettato o errore non tipizzato."))
      (unless (equal before (multiple-value-list (funcall read controller)))
        (error "COD-60 tools/measure-pool-lifecycle.lisp: campione invalido muta il controller."))))
  :passed)

(defun self-test-composed (maker)
  "Fixture positive API prima della campagna; cleanup bounded anche dopo l'errore."
  (multiple-value-bind (function token cleanup) (funcall maker)
    (let ((progress (sample-record 0 4 0 token)))
      (unwind-protect (sample function 4 token progress :warmup 0)
        (funcall cleanup))
      progress)))

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
    (setf composed (self-test-composed #'create-apply-cycle))
    (unless (handler-case
                (progn (verify-apply (lambda (port) (declare (ignore port)) (values nil :retired))
                                     nil t :activated) nil)
              (error () t))
      (error "COD-60: risultato owner difforme non respinto."))
    (unless (handler-case
                (progn (verify-registry (lambda (registry) (declare (ignore registry)) (values 1 1 nil))
                                        nil 1 2 t) nil)
              (error () t))
      (error "COD-60: risultato registro difforme non respinto."))
    (let ((called nil))
      (dolist (args '(nil ("--bench") ("--bad") ("--bench" "directory" "extra")))
        (unless (and (eq :failed (getf (run-driver args :product-loader (lambda () (setf called t))) :status))
                     (null called))
          (error "COD-60: CLI invalida eseguita."))))
    (list :status :ok :baseline baseline :positive-control positive :wrong-sink-probe wrong
          :zero-clock-probe zero :composed-api-probe composed
          :composed-registry-probe (self-test-composed #'create-registry-cycle) :invalid-cli :rejected
          :owner-and-registry-oracle-positive-negative :passed :invalid-non-hot (self-test-invalid-input)
          :existing-destination-and-partial-raw (self-test-reporter)
          :measured-partial-raw (self-test-partial-sample))))

(defun main ()
  "Rapporto leggibile; ogni errore esce nonzero con diagnosi C4."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-lifecycle.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-lifecycle-measure-library *features*) (main))
