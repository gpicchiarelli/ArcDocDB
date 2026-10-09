;;;; Allocazioni seriali dell'handoff, input e target preallocati; niente I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-handoff-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-handoff.bench (:use #:cl))
(in-package #:arcdocdb.writer-handoff.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/writer-handoff-bench.lisp")
                            (sort (directory "src/**/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Forza compilazione rigorosa prima delle fixture e della misura."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error "~A non ammesso (COD-01): ~A" (type-of condition) condition)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb" :force t))))

(defun execution-function (name)
  "Risolve una API esportata prima del clock; nessuna ricerca di simboli nel ciclo."
  (multiple-value-bind (symbol visibility) (find-symbol name "ARCDOCDB.EXECUTION")
    (unless (and symbol (eq visibility :external) (fboundp symbol))
      (error "COD-60: API execution non disponibile: ~A." name))
    (symbol-function symbol)))

(defun expected-sink (iterations token)
  "Oracolo indipendente: somma dei token fissi e degli indici delle chiamate."
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample-record (replica iterations warmup token)
  "Tutte le chiavi della misura sono allocate prima di warmup, heap e clock."
  (list :replica replica :status :running :stage :warmup :iterations iterations
        :warmup-iterations (min warmup iterations) :completed-iterations 0
        :heap-bytes nil :raw-ticks nil :seconds nil :time-quality :pending
        :sink nil :expected-sink (expected-sink iterations token)
        :expected-return-token token :diagnostic nil))

(defun sample (function iterations token progress &key (warmup +warmup+) (clock #'get-internal-real-time))
  "Warmup e GC prima della misura; raw e numero di cicli conservati anche al fallimento."
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error "COD-60: parametri benchmark handoff fuori budget."))
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
        (error "COD-60: clock/heap invalido o sink handoff ~D diverso da ~D."
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun enqueue-batch (enqueue writer messages)
  "Count 1..N e una sola notifica, confrontati con l'oracolo prima di avviare il tratto."
  (let ((token 0))
    (declare (type fixnum token))
    (dotimes (i (length messages) token)
      (multiple-value-bind (count action) (funcall enqueue writer (svref messages i))
        (unless (and (= count (1+ i)) (eq action (if (zerop i) :schedule :queued)))
          (error "COD-60: count/notifica dell'accettazione handoff incoerenti."))
        (incf token (+ count (if (zerop i) 11 7)))))))

(defun consume-tranche (pop writer lease messages target offset quantum)
  "FIFO, status e span verificati; quantum esaurito o empty alimentano token distinto."
  (let ((taken-expected (min quantum (- (length messages) offset))) (token 0))
    (declare (type fixnum taken-expected token))
    (multiple-value-bind (taken status) (funcall pop writer lease target 2 (+ 2 taken-expected))
      (unless (and (= taken taken-expected) (eq status :messages))
        (error "COD-60: prelievo handoff non corrisponde alla lista FIFO."))
      (incf token (* 3 taken))
      (dotimes (i taken)
        (unless (eql (svref target (+ 2 i)) (svref messages (+ offset i)))
          (error "COD-60: payload handoff duplicato, perso o riordinato."))
        (incf token (* 5 (the fixnum (svref target (+ 2 i)))))))
    (multiple-value-bind (taken status) (funcall pop writer lease target 2 (+ 2 taken-expected))
      (let ((yield (= taken-expected quantum)))
        (unless (and (zerop taken) (eq status (if yield :yield :empty)))
          (error "COD-60: empty/quota cumulativa handoff incoerenti."))
        (incf token (if yield 29 13))))
    (unless (and (eq :outside (svref target 0)) (eq :outside (svref target 1))
                 (eq :outside (svref target (- (length target) 2)))
                 (eq :outside (svref target (1- (length target)))))
      (error "COD-60: prelievo handoff fuori dallo span del target."))
    token))

(defun cycle-function (count quantum)
  "Fixture privata una volta; il nonce e tutte le risposte API contribuiscono al controllo."
  (let* ((create (execution-function "CREA-WRITER-PROGRAMMABILE"))
         (enqueue (execution-function "ACCODA-LAVORO-WRITER"))
         (start (execution-function "INIZIA-TRATTO-WRITER"))
         (pop (execution-function "PRELEVA-LAVORI-WRITER"))
         (finish (execution-function "TERMINA-TRATTO-WRITER"))
         (writer (funcall create :capacity count :quantum quantum))
         (messages (make-array count))
         (target (make-array (+ 4 (min count quantum)) :initial-element :outside)) (nonce 0))
    (declare (type fixnum nonce count quantum))
    (dotimes (i count) (setf (svref messages i) (1+ i)))
    (lambda ()
      (let ((token (enqueue-batch enqueue writer messages)))
        (declare (type fixnum token))
        (loop for offset below count by quantum
              do (let ((lease (funcall start writer)))
                   (unless (= lease (incf nonce)) (error "COD-60: nonce handoff incoerente."))
                   (incf token 19)
                   (incf token (consume-tranche pop writer lease messages target offset quantum))
                   (let ((pending (< (+ offset quantum) count)))
                     (unless (eq (funcall finish writer lease) (if pending :schedule :idle))
                       (error "COD-60: obbligo di riaccodamento handoff incoerente."))
                     (incf token (if pending 23 17)))))
        token))))

(defun campaign-record (scenario count quantum)
  "Record preallocato: empty-cycle 69, backlog/quantum/requeue 3628 per ciclo."
  (let ((token (ecase scenario (:empty-cycle 69) (:backlog-quantum-requeue 3628))))
    (list :scenario scenario :capacity count :quantum quantum :messages-per-cycle count
          :calls-per-cycle (ecase scenario (:empty-cycle 5) (:backlog-quantum-requeue 40))
          :expected-token token :token-rule
          '(:enqueue-count :first-schedule-11 :queued-7 :start-19 :taken-times-3
            :payload-times-5 :empty-13 :yield-29 :reschedule-23 :idle-17)
          :status :running :stage :fixture :current-replica nil :samples nil :diagnostic nil)))

(defun campaign (progress checkpoint)
  "Cinque campioni; ogni prova corrente è collegata al report prima dell'esecuzione."
  (let ((function (cycle-function (getf progress :capacity) (getf progress :quantum))))
    (dotimes (replica +replicas+)
      (let ((measurement (sample-record replica +iterations+ +warmup+ (getf progress :expected-token))))
        (setf (getf progress :current-replica) replica (getf progress :stage) :replica
              (getf progress :samples) (append (getf progress :samples) (list measurement)))
        (when checkpoint (funcall checkpoint))
        (sample function +iterations+ (getf progress :expected-token) measurement)
        (when checkpoint (funcall checkpoint))
        (unless (zerop (getf measurement :heap-bytes))
          (error "COD-30: heap osservato non nullo nella replica ~D di ~A."
                 replica (getf progress :scenario)))))
    (setf (getf progress :status) :ok (getf progress :stage) :complete
          (getf progress :current-replica) nil))
  progress)

(defun run-campaigns (report &key checkpoint (runner #'campaign))
  "I due scenari vengono registrati in ordine e conservati anche al fallimento."
  (dolist (spec '((:empty-cycle 1 2) (:backlog-quantum-requeue 32 16)))
    (let ((progress (apply #'campaign-record spec)))
      (setf (getf report :current-campaign) progress
            (getf report :campaigns) (append (getf report :campaigns) (list progress)))
      (when checkpoint (funcall checkpoint))
      (funcall runner progress checkpoint)))
  report)

(defun make-report ()
  "Metadati di misura e limiti; tutte le chiavi condivise esistono prima degli aggiornamenti."
  (list :schema-version 1 :kind :writer-handoff-benchmark :status :running :stage :pending
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-handoff-cycles :preallocated-inputs
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-pool-ready-list-device-durability-or-release-qualification)))

(defun acquire-directory (path)
  "MKDIR esclusivo 0700; una destinazione precedente non viene mai scritta."
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report directory)
  "Scrive esclusivamente nella directory reclamata; conserva l'ultima plist completa."
  (with-open-file (stream (merge-pathnames "report.next.lisp" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames "report.next.lisp" directory)
                                     (merge-pathnames "report.lisp" directory))
  report)

(defun mark-failed (report condition)
  "L'errore conserva sample e scenario correnti, inclusi raw raccolti prima del controllo."
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
  "Directory, load e ogni prova registrati; fallimenti visibili senza sovrascrivere altro."
  (let ((report (make-report)) (owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= 2 (length args)) (string= "--bench" (first args))))
            (error "COD-61: uso --self-test oppure --bench directory-nuova/."))
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
              (getf report :diagnostic) "COD-61: sorgenti cambiati durante il benchmark handoff.")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  "Fixture temporanea esclusiva, con limite di mille collisioni."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-handoff-bench-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "COD-60: directory fixture benchmark handoff non disponibile."))

(defun self-test-partial-run (report &key checkpoint)
  "Primo scenario completo; secondo interrompe la replica dopo un raw sintetico."
  (run-campaigns report :checkpoint checkpoint
    :runner (lambda (progress persist)
              (setf (getf progress :stage) :replica (getf progress :current-replica) 0
                    (getf progress :samples)
                    (list (list :status :running :raw-ticks 7 :heap-bytes 0 :diagnostic nil)))
              (when persist (funcall persist))
              (if (eq :empty-cycle (getf progress :scenario))
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (error "fixture: seconda campagna interrotta")))))

(defun self-test-reporter ()
  "Rifiuta una destinazione esistente e conserva scenario precedente e replica fallita."
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames "existing/" root)))
                (failed-directory (merge-pathnames "failed/" root)))
           (write-report '(:sentinel :unchanged) existing)
           (unless (eq :failed (getf (run-driver (list "--bench" (namestring existing))
                                               :self-tester (constantly :passed)
                                               :product-loader (constantly nil)) :status))
             (error "COD-60: destinazione precedente accettata."))
           (let ((*read-eval* nil))
             (with-open-file (input (merge-pathnames "report.lisp" existing))
               (unless (equal (read input) '(:sentinel :unchanged))
                 (error "COD-60: report precedente modificato."))))
           (run-driver (list "--bench" (namestring failed-directory))
                       :self-tester (constantly :passed) :product-loader (constantly nil)
                       :campaign-runner #'self-test-partial-run)
           (let* ((*read-eval* nil)
                  (saved (with-open-file (input (merge-pathnames "report.lisp" failed-directory))
                           (read input))) (cases (getf saved :campaigns))
                  (partial (first (getf (second cases) :samples))))
             (unless (and (eq :failed (getf saved :status)) (= 2 (length cases))
                          (eq :ok (getf (first cases) :status))
                          (eq :failed (getf (second cases) :status))
                          (eq :replica (getf (second cases) :stage))
                          (= 0 (getf (second cases) :current-replica))
                          (eq :failed (getf partial :status)) (= 7 (getf partial :raw-ticks))
                          (= 0 (getf partial :heap-bytes)))
               (error "COD-60: campagna precedente o prova parziale perse."))))
      ;; C4: ROOT è soltanto la directory acquisita dalla fixture.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  "Controllo positivo heap, sink errato respinto, clock nullo e reporter dei fallimenti."
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0)) (probe nil)
         (positive (sample-record 0 16 0 1048576)))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error "COD-60: baseline contatore non nulla."))
    (sample (lambda ()
              (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
              (length probe)) 16 1048576 positive :warmup 0)
    (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error "COD-60: allocazione deliberata non rilevata."))
    (let ((wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0)))
      (unless (handler-case (progn (sample (lambda () 1) 2 0 wrong :warmup 0) nil)
                (error () t)) (error "COD-60: sink errato non respinto."))
      (sample (lambda () 0) 2 0 zero :warmup 0 :clock (constantly 0))
      (unless (and (eq :below-resolution (getf zero :time-quality))
                   (null (getf zero :seconds))) (error "COD-60: clock nullo utilizzato come durata.")))
    (self-test-reporter)
    (list :status :ok :baseline baseline :positive-control positive
          :wrong-sink :rejected :zero-clock :below-resolution :partial-report :preserved
          :existing-destination :preserved)))

(defun main ()
  "CLI C4; risultato strutturato anche senza destinazione e diagnostica con exit nonzero."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&writer-handoff-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
