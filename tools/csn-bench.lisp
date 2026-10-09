;;;; ADR-0046: registro CSN, cinque campioni seriali e tre repliche su thread reali.
;;;; Uso dal worktree congelato: --self-test oppure --bench, tramite record-command.lisp.
;;; REQ: REQ-MVC-008 REQ-CON-001 REQ-CON-002 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.csn.bench (:use #:cl))
(in-package #:arcdocdb.csn.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +initial-iterations+ 100000)
(defconstant +maximum-iterations+ 2000000)
(defconstant +minimum-ticks+ 20)
(defconstant +warmup+ 1024)
(defconstant +samples+ 5)
(defconstant +parallel-pairs+ 10000)
(defconstant +parallel-replicas+ 3)
(defconstant +retry-budget+ 1000000)
(defconstant +parallel-seconds+ 30)
(defparameter *create* nil)
(defparameter *take* nil)
(defparameter *resolve* nil)
(defparameter *frontiers* nil)
(defparameter *resource-exhausted* nil)
(defparameter *error-reason* nil)

(defun fingerprints ()
  "Stabilità di ASD, sorgenti e driver; non costituisce prova di autenticità."
  (loop for file in (append '(#p"arcdocdb.asd" #p"tools/csn-bench.lisp")
                           (sort (directory "src/**/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun api-function (name package)
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq visibility :external) (fboundp symbol))
      (error "API esportata assente: ~A:~A." package name))
    (symbol-function symbol)))

(defun load-product ()
  "Compilazione rigorosa fuori dalle finestre misurate."
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb" :force t)))
  (unless (>= most-positive-fixnum #xffffffff)
    (error "Il sensore richiede SBCL con entrambi i limb u32 rappresentabili come fixnum."))
  (setf *create* (api-function "CREA-REGISTRO-CSN" "ARCDOCDB.CSN")
        *take* (api-function "PRENDI-CSN" "ARCDOCDB.CSN")
        *resolve* (api-function "RISOLVI-CSN" "ARCDOCDB.CSN")
        *frontiers* (api-function "LEGGI-FRONTIERE-CSN" "ARCDOCDB.CSN")
        *resource-exhausted* (find-symbol "RESOURCE-EXHAUSTED" "ARCDOCDB.CONDITIONS")
        *error-reason* (api-function "ERROR-REASON" "ARCDOCDB.CONDITIONS")))

(defun window-record (iterations warmup token)
  "Record completo prima della misura, aggiornato anche in caso di errore."
  (list :status :running :iterations iterations :warmup-iterations warmup
        :completed-iterations 0 :heap-bytes nil :raw-ticks nil :seconds nil
        :time-quality :pending :sink nil
        :expected-sink (+ (* iterations token) (truncate (* iterations (1- iterations)) 2))
        :diagnostic nil))

(defun measure-window (function iterations token record &key (warmup +warmup+)
                                                           (clock #'get-internal-real-time))
  "Aritmetica del sink limitata ai fixnum; report e rapporti sono fuori dal clock."
  (unless (and (<= 1 iterations +maximum-iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 1048576)))
    (error "Parametri del sensore CSN fuori budget."))
  (dotimes (i warmup) (funcall function))
  (sb-ext:gc :full t)
  (let ((start (funcall clock)) (before (sb-ext:get-bytes-consed))
        (sink 0) (completed 0) (failure nil))
    (declare (type fixnum sink completed))
    (handler-case
        (dotimes (i iterations)
          (incf sink (+ i (the fixnum (funcall function))))
          (incf completed))
      (error (condition) (setf failure condition)))
    (let ((heap (- (sb-ext:get-bytes-consed) before)) (ticks (- (funcall clock) start)))
      (setf (getf record :heap-bytes) heap (getf record :raw-ticks) ticks
            (getf record :sink) sink (getf record :completed-iterations) completed
            (getf record :time-quality) (if (>= ticks +minimum-ticks+) :valid :below-resolution)
            (getf record :seconds) (/ ticks (float internal-time-units-per-second 1d0)))
      (when failure
        (setf (getf record :status) :failed (getf record :diagnostic) (princ-to-string failure))
        (error failure))
      (unless (and (>= heap 0) (>= ticks 0) (= sink (getf record :expected-sink)))
        (setf (getf record :status) :failed)
        (error "Clock/heap/sink CSN invalido: ~S." record))
      (setf (getf record :status) (if (>= ticks +minimum-ticks+) :ok :below-resolution))))
  record)

(defun adaptive-sample (function token progress &key (iterations +initial-iterations+)
                                                   (warmup +warmup+) (zero-heap t))
  "Al massimo sei finestre; 100000..2000000 iterazioni, mai throughput minimo."
  (loop for count = iterations then (min +maximum-iterations+ (* 2 count))
        for attempt = (window-record count warmup token)
        do (setf (getf progress :attempts) (append (getf progress :attempts) (list attempt)))
           (measure-window function count token attempt :warmup warmup)
           (when (and zero-heap (not (zerop (getf attempt :heap-bytes))))
             (setf (getf attempt :status) :failed)
             (error "Allocazioni nel percorso seriale CSN: ~D byte." (getf attempt :heap-bytes)))
           (when (eq (getf attempt :status) :ok)
             (setf (getf progress :measurement) attempt (getf progress :status) :ok)
             (return progress))
           (when (= count +maximum-iterations+)
             (error "Finestra CSN inferiore a ~D tick al limite di iterazioni." +minimum-ticks+))))

(defun require-valid-time (ticks)
  "Validità del sensore; non una soglia di prestazione del prodotto."
  (unless (and (integerp ticks) (>= ticks +minimum-ticks+))
    (error "Finestra temporale inferiore a ~D tick: ~S." +minimum-ticks+ ticks))
  ticks)

(defun self-test (report)
  "Funzione costante heap zero e controllo positivo con array deliberatamente vivi."
  (let ((baseline (list :status :running :attempts nil :measurement nil))
        (positive (window-record 16 0 1048576)) (probe nil))
    (setf (getf report :self-test)
          (list :status :running :constant-zero baseline :deliberate-allocation positive
                :invalid-timer-rejected nil :counter-scope :whole-process))
    (adaptive-sample (lambda () 0) 0 baseline)
    (measure-window (lambda ()
                      (setf probe (make-array 1048576 :element-type '(unsigned-byte 8)
                                                     :initial-element 0))
                      (length probe))
                    16 1048576 positive :warmup 0)
    (require-valid-time (getf positive :raw-ticks))
    (unless (and probe (= (length probe) 1048576)
                 (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error "Il sensore non rileva le allocazioni deliberate."))
    (dolist (invalid '(0 -1 nil 1 19))
      (let ((rejected nil))
        (handler-case (require-valid-time invalid) (error () (setf rejected t)))
        (unless rejected (error "Il sensore accetta un clock invalido."))))
    (setf (getf (getf report :self-test) :invalid-timer-rejected) t
          (getf (getf report :self-test) :status) :ok)))

(declaim (inline next-pair))
(defun next-pair (high low)
  "Successore indipendente a due limb; nessun u64 materializzato nel ciclo."
  (declare (type (unsigned-byte 32) high low))
  (if (= low #xffffffff) (values (1+ high) 0) (values high (1+ low))))

(defun check-frontiers (registry last-high last-low horizon-high horizon-low)
  (multiple-value-bind (lh ll hh hl) (funcall *frontiers* registry)
    (unless (and (= lh last-high) (= ll last-low) (= hh horizon-high) (= hl horizon-low))
      (error "Frontiere CSN incoerenti: (~S ~S ~S ~S)." lh ll hh hl)))
  t)

(defun serial-fixture (capacity high low pinned)
  "La fixture e l'eventuale più vecchio pendente precedono tutte le finestre."
  (let ((registry (funcall *create* :capacity capacity :initial-high high :initial-low low))
        (last-high high) (last-low low) (old-slot nil) (old-high 0) (old-low 0))
    (when pinned
      (multiple-value-setq (old-slot old-high old-low) (funcall *take* registry))
      (multiple-value-setq (last-high last-low) (next-pair high low))
      (unless (and (= old-high last-high) (= old-low last-low))
        (error "CSN del pendente iniziale incoerente.")))
    (values
     (lambda ()
       (multiple-value-setq (last-high last-low) (next-pair last-high last-low))
       (multiple-value-bind (slot issued-high issued-low) (funcall *take* registry)
         (unless (and (typep slot 'fixnum) (<= 0 slot) (< slot capacity)
                      (or (not pinned) (/= slot old-slot))
                      (= issued-high last-high) (= issued-low last-low))
           (error "Assegnazione CSN o riuso slot incoerente."))
         ;; Questa fixture non ha effetti esterni: annullamento valido prima di risolvere.
         (multiple-value-bind (hh hl) (funcall *resolve* registry slot issued-high issued-low)
           (unless (and (= hh (if pinned high last-high)) (= hl (if pinned low last-low)))
             (error "Orizzonte CSN supera un pendente o non converge."))))
       1)
     (lambda ()
       (check-frontiers registry last-high last-low (if pinned high last-high) (if pinned low last-low))
       (when pinned
         (multiple-value-bind (hh hl) (funcall *resolve* registry old-slot old-high old-low)
           (unless (and (= hh last-high) (= hl last-low))
             (error "Il rilascio del più vecchio non raggiunge l'ultimo CSN."))))
       (check-frontiers registry last-high last-low last-high last-low)
       (list :last-high last-high :last-low last-low :converged t)))))

(defun serial-campaign (capacity high low pinned progress)
  (multiple-value-bind (cycle finish) (serial-fixture capacity high low pinned)
    (dotimes (replica +samples+)
      (let ((sample (list :replica (1+ replica) :status :running :attempts nil :measurement nil)))
        (setf (getf progress :samples) (append (getf progress :samples) (list sample)))
        (adaptive-sample cycle 1 sample)
        (let* ((measurement (getf sample :measurement)) (seconds (getf measurement :seconds)))
          (require-valid-time (getf measurement :raw-ticks))
          (setf (getf measurement :pairs-per-second) (/ (getf measurement :iterations) seconds)))))
    (setf (getf progress :final) (funcall finish) (getf progress :status) :ok))
  progress)

(defun frontier-read-campaign (high low progress)
  "Sensore separato per il successo della lettura coerente a quattro valori."
  (let* ((registry (funcall *create* :capacity 256 :initial-high high :initial-low low))
         (read (lambda () (check-frontiers registry high low high low) 1)))
    (dotimes (replica +samples+)
      (let ((sample (list :replica (1+ replica) :status :running :attempts nil :measurement nil)))
        (setf (getf progress :samples) (append (getf progress :samples) (list sample)))
        (adaptive-sample read 1 sample)
        (let ((measurement (getf sample :measurement)))
          (setf (getf measurement :reads-per-second)
                (/ (getf measurement :iterations) (getf measurement :seconds))))))
    (setf (getf progress :status) :ok))
  progress)

(defstruct worker
  (status :ready) failure
  (completed 0 :type fixnum) (successful-operations 0 :type fixnum)
  (busy-retries 0 :type fixnum) (full-retries 0 :type fixnum)
  start end heap-before heap-after
  (highs (make-array +parallel-pairs+ :element-type '(unsigned-byte 32) :initial-element 0))
  (lows (make-array +parallel-pairs+ :element-type '(unsigned-byte 32) :initial-element 0)))

(defun retry-allowed (condition worker full-allowed)
  "Solo contesa e capacità piena sono retry; risolvi può incontrare solo contesa."
  (unless (typep condition *resource-exhausted*) (error condition))
  (case (funcall *error-reason* condition)
    (:csn-busy (incf (worker-busy-retries worker)))
    (:csn-full (if full-allowed (incf (worker-full-retries worker)) (error condition)))
    (otherwise (error condition)))
  (when (>= (+ (worker-busy-retries worker) (worker-full-retries worker)) +retry-budget+)
    (error "Budget di retry CSN esaurito."))
  (sb-thread:thread-yield))

(defun deadline-check (deadline)
  (when (>= (get-internal-real-time) deadline) (error "Deadline della campagna CSN esaurita.")))

(defun parallel-worker (registry worker ready start)
  "Thread, array e semafori preallocati; attesa e warmup privato precedono il clock."
  (handler-case
      (multiple-value-bind (warm finish) (serial-fixture 1 0 0 nil)
        (dotimes (i 128) (funcall warm))
        (funcall finish))
    (error (condition) (setf (worker-failure worker) condition)))
  (sb-thread:signal-semaphore ready)
  (unless (sb-thread:wait-on-semaphore start :timeout +parallel-seconds+)
    (setf (worker-failure worker) (make-condition 'simple-error :format-control "Start timeout.")))
  (when (worker-failure worker) (setf (worker-status worker) :failed) (return-from parallel-worker nil))
  (let* ((started (get-internal-real-time))
         (deadline (+ started (* +parallel-seconds+ internal-time-units-per-second))))
    (setf (worker-start worker) started (worker-heap-before worker) (sb-ext:get-bytes-consed))
    (handler-case
        (dotimes (i +parallel-pairs+)
          (when (zerop (logand i 255)) (deadline-check deadline))
          (multiple-value-bind (slot high low)
              (loop repeat +retry-budget+
                do (deadline-check deadline)
                (multiple-value-bind (slot high low)
                    (handler-case (funcall *take* registry)
                      (error (condition) (retry-allowed condition worker t) (values -1 0 0)))
                  (unless (= slot -1) (return (values slot high low))))
                finally (error "Limite dei tentativi di assegnazione CSN esaurito."))
            (incf (worker-successful-operations worker))
            (setf (aref (worker-highs worker) i) high (aref (worker-lows worker) i) low)
            ;; La fixture non ha effetti esterni: annullamento valido.
            (loop repeat +retry-budget+
              do (deadline-check deadline)
              (when (handler-case
                        (progn (funcall *resolve* registry slot high low) t)
                      (error (condition) (retry-allowed condition worker nil) nil))
                (incf (worker-successful-operations worker))
                (return))
              finally (error "Limite dei tentativi di risoluzione CSN esaurito."))
            (incf (worker-completed worker))))
      (error (condition) (setf (worker-failure worker) condition)))
    (setf (worker-heap-after worker) (sb-ext:get-bytes-consed)
          (worker-end worker) (get-internal-real-time)
          (worker-status worker) (if (worker-failure worker) :failed :ok)))
  nil)

(defun worker-report (worker index stable)
  "Heap osservato dal contatore globale nella finestra del worker, non attribuibile a lui."
  (unless stable
    (return-from worker-report
      (list :worker index :status :unavailable :window-status :unavailable
            :diagnostic "Thread ancora vivo dopo terminate e join limitato; campi non letti.")))
  (let ((ticks (when (and (worker-start worker) (worker-end worker))
                 (- (worker-end worker) (worker-start worker))))
        (heap (when (and (worker-heap-after worker) (worker-heap-before worker))
                (- (worker-heap-after worker) (worker-heap-before worker)))))
    (list :worker index :status (worker-status worker)
          :completed-pairs (worker-completed worker)
          :successful-operations (worker-successful-operations worker)
          :busy-retries (worker-busy-retries worker) :full-retries (worker-full-retries worker)
          :raw-ticks ticks :process-heap-observed-in-worker-window heap
          :window-status (if (and ticks heap) :complete :unavailable)
          :start-ticks (worker-start worker) :end-ticks (worker-end worker)
          :allocation-scope :global-counter-overlapping-windows-not-summable
          :diagnostic (when (worker-failure worker) (princ-to-string (worker-failure worker))))))

(defun verify-issued (workers indices registry)
  "Unicità esatta per archivio con bitmap fuori dalla misura; checksum confrontato all'oracolo."
  (let* ((expected (* (length indices) +parallel-pairs+))
         (seen (make-array (1+ expected) :element-type 'bit :initial-element 0))
         (count 0) (checksum 0))
    (dolist (index indices)
      (let ((worker (svref workers index)))
        (unless (and (eq (worker-status worker) :ok) (= (worker-completed worker) +parallel-pairs+)
                     (= (worker-successful-operations worker) (* 2 +parallel-pairs+)))
          (error "Worker CSN incompleto."))
        (dotimes (i +parallel-pairs+)
          (let ((high (aref (worker-highs worker) i)) (low (aref (worker-lows worker) i)))
            (unless (and (zerop high) (<= 1 low expected) (zerop (sbit seen low)))
              (error "CSN duplicato o fuori sequenza nella campagna parallela."))
            (setf (sbit seen low) 1)
            (incf count) (incf checksum low)))))
    (unless (and (= count expected) (= checksum (truncate (* expected (1+ expected)) 2)))
      (error "Conteggio/checksum CSN paralleli incoerenti."))
    (check-frontiers registry 0 expected 0 expected)
    (list :unique-issued-count count :checksum checksum
          :expected-checksum (truncate (* expected (1+ expected)) 2)
          :last-high 0 :last-low expected :converged t)))

(defun parallel-campaign (mode count progress)
  "Campagne in sequenza; solo i worker della singola replica sono concorrenti."
  (let* ((shared (eq mode :shared-archive)) (capacity 256)
         (registries (make-array (if shared 1 count)))
         (workers (make-array count)) (threads (make-array count :initial-element nil))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (process-before nil) (process-after nil))
    (dotimes (i (length registries)) (setf (svref registries i) (funcall *create* :capacity capacity)))
    (dotimes (i count) (setf (svref workers i) (make-worker)))
    (unwind-protect
         (progn
           (dotimes (i count)
             (let ((index i))
               (setf (svref threads i)
                     (sb-thread:make-thread
                      (lambda () (parallel-worker (svref registries (if shared 0 index))
                                                   (svref workers index) ready start))
                      :name (format nil "csn-bench-~D" index)))))
           (dotimes (i count)
             (unless (sb-thread:wait-on-semaphore ready :timeout +parallel-seconds+)
               (error "Worker CSN non pronto entro il budget.")))
           (sb-ext:gc :full t)
           (setf process-before (sb-ext:get-bytes-consed))
           (sb-thread:signal-semaphore start count)
           (dotimes (i count)
             (sb-thread:join-thread (svref threads i) :timeout (+ 2 +parallel-seconds+)
                                   :default :timeout)
             (when (sb-thread:thread-alive-p (svref threads i)) (error "Join CSN oltre deadline.")))
           (setf process-after (sb-ext:get-bytes-consed)))
      (sb-thread:signal-semaphore start count)
      (dotimes (i count)
        (when (and (svref threads i) (sb-thread:thread-alive-p (svref threads i)))
          (sb-thread:terminate-thread (svref threads i))))
      (dotimes (i count)
        (when (svref threads i)
          (sb-thread:join-thread (svref threads i) :timeout 2 :default :cleanup-timeout)))
      (when (and process-before
                 (loop for thread across threads always
                   (or (null thread) (not (sb-thread:thread-alive-p thread)))))
        (setf process-after (sb-ext:get-bytes-consed)))
      (setf (getf progress :workers)
            (loop for i below count
                  collect (worker-report (svref workers i) i
                                         (or (null (svref threads i))
                                             (not (sb-thread:thread-alive-p (svref threads i))))))
            (getf progress :process-heap-bytes)
            (when (and process-before process-after) (- process-after process-before))
            (getf progress :process-window-status)
            (if (and process-before process-after) :complete :unavailable)))
    (dotimes (i count)
      (let ((worker (svref workers i)))
        (when (worker-failure worker) (error (worker-failure worker)))
        (require-valid-time (- (worker-end worker) (worker-start worker)))))
    (let* ((first (loop for worker across workers minimize (worker-start worker)))
           (last (loop for worker across workers maximize (worker-end worker)))
           (ticks (require-valid-time (- last first)))
           (seconds (/ ticks (float internal-time-units-per-second 1d0))))
      (setf (getf progress :raw-ticks) ticks (getf progress :seconds) seconds
            (getf progress :completed-pairs) (* count +parallel-pairs+)
            (getf progress :successful-operations) (* 2 count +parallel-pairs+)
            (getf progress :busy-retries) (loop for worker across workers sum (worker-busy-retries worker))
            (getf progress :full-retries) (loop for worker across workers sum (worker-full-retries worker))
            (getf progress :pairs-per-second) (/ (* count +parallel-pairs+) seconds)
            (getf progress :archives)
            (if shared
                (list (verify-issued workers (loop for i below count collect i) (svref registries 0)))
                (loop for i below count collect (verify-issued workers (list i) (svref registries i))))
            (getf progress :status) :ok)))
  progress)

(defun benchmark (report)
  (load-product)
  (dolist (base '((0 0) (#x80000000 #xfffffff0)))
    (destructuring-bind (high low) base
      (dolist (capacity '(1 16 256 1024))
        (let ((campaign (list :scenario :take-resolve :capacity capacity :initial-high high :initial-low low
                              :api-calls-per-pair 2 :oracle-in-measured-loop t :status :running
                              :samples nil :final nil)))
          (setf (getf report :serial) (append (getf report :serial) (list campaign)))
          (serial-campaign capacity high low nil campaign)))
      (let ((campaign (list :scenario :oldest-pinned-recycle :capacity 2 :initial-high high :initial-low low
                            :api-calls-per-pair 2 :oracle-in-measured-loop t :status :running
                            :samples nil :final nil)))
        (setf (getf report :serial) (append (getf report :serial) (list campaign)))
        (serial-campaign 2 high low t campaign))
      (let ((campaign (list :scenario :coherent-frontier-read :capacity 256
                            :initial-high high :initial-low low :api-calls-per-iteration 1
                            :oracle-in-measured-loop t :status :running :samples nil)))
        (setf (getf report :serial) (append (getf report :serial) (list campaign)))
        (frontier-read-campaign high low campaign))))
  (dolist (mode '(:shared-archive :archive-per-worker))
    (dolist (count '(1 2 4))
      (dotimes (replica +parallel-replicas+)
        (let ((campaign (list :mode mode :worker-count count :replica (1+ replica) :capacity-per-archive 256
                              :pairs-per-worker +parallel-pairs+ :status :running :workers nil
                              :raw-ticks nil :seconds nil :pairs-per-second nil
                              :completed-pairs 0 :successful-operations 0 :busy-retries 0 :full-retries 0
                              :process-heap-bytes nil :process-window-status :pending :archives nil)))
          (setf (getf report :parallel) (append (getf report :parallel) (list campaign)))
          (parallel-campaign mode count campaign)))))
  report)

(defun main ()
  "Plist C4 anche in caso di errore; output grezzo conservabile da record-command."
  (let ((before nil)
        (report (list :schema-version 1 :kind :csn-benchmark :status :running
                      :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                      :machine (machine-type) :os (software-type) :os-version (software-version)
                      :timer-units-per-second internal-time-units-per-second :minimum-window-ticks +minimum-ticks+
                      :serial-samples +samples+ :initial-iterations +initial-iterations+
                      :maximum-iterations +maximum-iterations+ :parallel-replicas +parallel-replicas+
                      :retry-budget-per-worker +retry-budget+ :worker-deadline-seconds +parallel-seconds+
                      :self-test nil :serial nil :parallel nil
                      :limits '(:campaigns-run-sequentially :external-load-uncontrolled
                                :sensor-not-absolute-nonallocation-proof :serial-success-path-zero-heap-required
                                :parallel-errors-may-allocate :parallel-heap-is-process-counter
                                :worker-allocation-windows-overlap-and-are-not-summable
                                :process-window-includes-start-gate-and-joins
                                :throughput-includes-oracle-and-retry-overhead :no-throughput-threshold
                                :no-snapshot-or-lockfree-read-claim :no-persistence-qualification))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (setf before (fingerprints) (getf report :source-fingerprints-before) before)
          (unless (member args '(("--self-test") ("--bench")) :test #'equal)
            (error "Usare --self-test oppure --bench."))
          (self-test report)
          (when (equal args '("--bench")) (benchmark report))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (handler-case
        (let ((after (fingerprints)))
          (setf (getf report :source-fingerprints-after) after
                (getf report :source-consistency) (if (equal before after) :stable :changed))
          (when (and (eq (getf report :status) :ok) (not (equal before after)))
            (setf (getf report :status) :source-changed)))
      (error (condition)
        (setf (getf report :status) :failed (getf report :fingerprint-error) (princ-to-string condition))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
