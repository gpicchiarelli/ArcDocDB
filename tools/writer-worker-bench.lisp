;;;; Allocazioni seriali del contesto worker composto con handoff e lista pronta; nessun I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-worker-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-worker.bench (:use #:cl))
(in-package #:arcdocdb.writer-worker.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/writer-worker-bench.lisp")
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
    (error "COD-60: parametri benchmark worker fuori budget."))
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
        (error "COD-60: clock/heap invalido o sink worker ~D diverso da ~D."
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun enqueue-message (enqueue writer payload expected-count expected-action)
  "Accettazione unica; schedule/queued verificati prima del trasferimento pronto."
  (multiple-value-bind (count action) (funcall enqueue writer payload)
    (unless (and (= expected-count count) (eq expected-action action))
      (error "COD-60: conteggio/obbligo enqueue worker incoerente."))
    (+ count (if (eq action :schedule) 11 17))))

(defun publish-message (publish ready shard writer expected-count)
  "Una pubblicazione per obbligo conservato; ritorno count verificato."
  (let ((count (funcall publish ready shard writer)))
    (unless (= expected-count count) (error "COD-60: count pubblicazione worker incoerente."))
    (+ 31 (* 3 count))))

(defun claim-writer (claim context expected-writer expected-cursor)
  "Identità assegnata al contesto e cursore verificati a ogni prelievo."
  (multiple-value-bind (writer status cursor) (funcall claim context)
    (unless (and (eq writer expected-writer) (eq status :claimed) (= cursor expected-cursor))
      (error "COD-60: identità/status/cursor claim worker incoerenti."))
    (+ 17 (* 7 cursor))))

(defun consume-current (start pop confirm finish context target nonces index batches payload status)
  "Lease e batch monotoni; uno span posseduto, conferma esplicita e fine attesa."
  (let ((lease (funcall start context)) (token 19))
    (declare (type fixnum token))
    (unless (= lease (incf (the fixnum (svref nonces index))))
      (error "COD-60: lease del contesto worker incoerente."))
    (multiple-value-bind (count result batch) (funcall pop context target 1 2)
      (unless (and (= 1 count) (eq :messages result)
                   (= batch (incf (the fixnum (svref batches 0))))
                   (eql payload (svref target 1))
                   (eq :outside (svref target 0)) (eq :outside (svref target 2)))
        (error "COD-60: batch/span/payload worker incoerenti."))
      (incf token (+ (* 3 count) (* 5 (the fixnum (svref target 1)))))
      (unless (null (funcall confirm context batch))
        (error "COD-60: conferma worker non restituisce NIL."))
      (incf token 7))
    (unless (eq status (funcall finish context))
      (error "COD-60: termine worker diverso da schedule/idle atteso."))
    (+ token (if (eq status :idle) 23 13))))

(defun expected-token (shards capacity)
  "M=K(C+1): full include i payload role-id 1..M, room solo payload zero."
  (let ((writers (* shards (1+ capacity))))
    (+ (* shards (+ 416 (* 115 capacity) (/ (* 3 capacity (1+ capacity)) 2)))
       (/ (* 7 (+ capacity 3) shards (1- shards)) 2)
       (/ (* 5 writers (1+ writers)) 2) 29 (* 7 (mod 1 shards)))))

(defun cycle-function (shards capacity)
  "Contesto privato: backlog→full, drain/idle, backlog→room; identità riusate e ruotate."
  (let* ((create-ready (execution-function "CREA-LISTA-WRITER-PRONTI"))
         (publish (execution-function "PUBBLICA-WRITER-PRONTO"))
         (create-context (execution-function "CREA-CONTESTO-WORKER-WRITER"))
         (claim (execution-function "PRENDI-WRITER-WORKER"))
         (start (execution-function "INIZIA-TRATTO-WORKER"))
         (pop (execution-function "PRELEVA-LAVORI-WORKER"))
         (confirm (execution-function "CONFERMA-LAVORI-WORKER"))
         (finish (execution-function "TERMINA-TRATTO-WORKER"))
         (recycle (execution-function "RICIRCOLA-WORKER"))
         (create-writer (execution-function "CREA-WRITER-PROGRAMMABILE"))
         (enqueue (execution-function "ACCODA-LAVORO-WRITER"))
         (ready (funcall create-ready :shards shards :capacity capacity))
         (context (funcall create-context ready :start 0))
         (per-shard (1+ capacity)) (writers (make-array (* per-shard shards)))
         (nonces (make-array (* per-shard shards) :initial-element 0))
         (batches (make-array 1 :initial-element 0))
         (target (make-array 3 :initial-element :outside)) (phase 0))
    (declare (type fixnum phase shards capacity per-shard))
    (dotimes (i (length writers)) (setf (svref writers i) (funcall create-writer :capacity 2 :quantum 1)))
    (lambda ()
      (let ((token 0))
        (declare (type fixnum token))
        (dotimes (shard shards)
          (let* ((base (* per-shard shard)) (a-index (+ base phase))
                 (a-writer (svref writers a-index)) (next (mod (1+ shard) shards)))
            (incf token (enqueue-message enqueue a-writer 0 1 :schedule))
            (incf token (enqueue-message enqueue a-writer (1+ base) 2 :queued))
            (incf token (publish-message publish ready shard a-writer 1))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :schedule))
            (dotimes (ordinal capacity)
              (let* ((role (1+ ordinal)) (index (+ base (mod (+ phase role) per-shard)))
                     (writer (svref writers index)))
                (incf token (enqueue-message enqueue writer (+ base role 1) 1 :schedule))
                (incf token (publish-message publish ready shard writer (1+ ordinal)))))
            (let ((index (+ base (mod (1+ phase) per-shard))))
              (multiple-value-bind (writer status count) (funcall recycle context)
                (unless (and (eq writer (svref writers index)) (eq status :claimed) (= count capacity))
                  (error "COD-60: ricircolo worker full non trasferisce FIFO/count atteso."))
                (incf token (+ 13 (* 3 count))))
              (incf token (consume-current start pop confirm finish context target nonces index batches (+ base 2) :idle)))
            (dotimes (ordinal capacity)
              (let* ((role (mod (+ ordinal 2) per-shard))
                     (index (+ base (mod (+ phase role) per-shard)))
                     (writer (svref writers index)))
                (incf token (claim-writer claim context writer next))
                (incf token (consume-current start pop confirm finish context target nonces index batches (+ base role 1) :idle))))
            ;; Lo shard è vuoto: secondo obbligo sul medesimo writer passa al ring con spazio.
            (incf token (enqueue-message enqueue a-writer 0 1 :schedule))
            (incf token (enqueue-message enqueue a-writer 0 2 :queued))
            (incf token (publish-message publish ready shard a-writer 1))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :schedule))
            (multiple-value-bind (writer status count) (funcall recycle context)
              (unless (and (null writer) (eq :published status) (= 1 count))
                (error "COD-60: ricircolo worker room non pubblica un solo obbligo."))
              (incf token (+ 31 (* 3 count))))
            (incf token (claim-writer claim context a-writer next))
            (incf token (consume-current start pop confirm finish context target nonces a-index batches 0 :idle))))
        (multiple-value-bind (writer status cursor) (funcall claim context)
          (unless (and (null writer) (eq status :empty) (= cursor (mod 1 shards)))
            (error "COD-60: scansione worker vuota/cursor incoerenti."))
          (incf token (+ 29 (* 7 cursor))))
        (setf phase (mod (1+ phase) per-shard))
        token))))

(defun campaign-record (scenario shards capacity)
  "Quattro scenari preregistrati; payload e ritorni determinano un token esatto indipendente."
  (unless (and (member shards '(1 4)) (member capacity '(1 3)))
    (error "COD-60: configurazione worker fuori dal preregistrato."))
  (list :scenario scenario :shards shards :capacity-per-shard capacity
        :workers 1 :writers-per-shard (1+ capacity) :contexts 1
        :full-exchanges-per-cycle shards :room-publications-per-cycle shards
        :processed-batches-per-cycle (* shards (+ capacity 4))
        :calls-per-cycle (1+ (* shards (+ (* 7 capacity) 27)))
        :expected-token (expected-token shards capacity) :token-rule
        '(:enqueue-count-plus-schedule-11-or-queued-17 :publish-31-plus-count-times-3
          :claim-17-plus-cursor-times-7 :lease-19 :taken-times-3 :payload-times-5
          :confirm-nil-7 :finish-idle-23-or-schedule-13
          :recycle-claimed-13-or-published-31-plus-count-times-3 :empty-29-plus-cursor-times-7)
        :token-formula "K[416+115C+3C(C+1)/2]+7(C+3)K(K-1)/2+5M(M+1)/2+29+7*(1 mod K); M=K(C+1)"
        :status :running :stage :fixture :current-replica nil :samples nil :diagnostic nil))

(defun campaign (progress checkpoint)
  "Cinque campioni; ogni prova corrente è collegata al report prima dell'esecuzione."
  (let ((function (cycle-function (getf progress :shards) (getf progress :capacity-per-shard))))
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
  "I quattro scenari vengono registrati in ordine e conservati anche al fallimento."
  (dolist (spec '((:one-shard-one-slot 1 1) (:one-shard-three-slots 1 3)
                  (:four-shards-one-slot 4 1) (:four-shards-three-slots 4 3)))
    (let ((progress (apply #'campaign-record spec)))
      (setf (getf report :current-campaign) progress
            (getf report :campaigns) (append (getf report :campaigns) (list progress)))
      (when checkpoint (funcall checkpoint))
      (funcall runner progress checkpoint)))
  report)

(defun make-report ()
  "Metadati di misura e limiti; tutte le chiavi condivise esistono prima degli aggiornamenti."
  (list :schema-version 1 :kind :writer-worker-benchmark :status :running :stage :pending
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-owner-context-handoff-ready-and-recycle-cycles :preallocated-inputs
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-pool-device-durability-or-release-qualification)))

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
              (getf report :diagnostic) "COD-61: sorgenti cambiati durante il benchmark worker.")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  "Fixture temporanea esclusiva, con limite di mille collisioni."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-worker-bench-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "COD-60: directory fixture benchmark worker non disponibile."))

(defun self-test-partial-run (report &key checkpoint)
  "Primo scenario completo; secondo interrompe la replica dopo un raw sintetico."
  (run-campaigns report :checkpoint checkpoint
    :runner (lambda (progress persist)
              (setf (getf progress :stage) :replica (getf progress :current-replica) 0
                    (getf progress :samples)
                    (list (list :status :running :raw-ticks 7 :heap-bytes 0 :diagnostic nil)))
              (when persist (funcall persist))
              (if (eq :one-shard-one-slot (getf progress :scenario))
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

(defun self-test-cli ()
  "Ogni argv invalido fallisce prima del load, senza destinazione o campagna."
  (let ((records nil))
    (dolist (args '(nil ("--bench") ("--bad") ("--bench" "directory" "extra")))
      (let ((called nil))
        (let ((report (run-driver args :product-loader (lambda () (setf called t)))))
          (unless (and (null called) (eq :failed (getf report :status))
                       (eq :pending (getf report :stage)) (null (getf report :campaigns))
                       (search "uso --self-test" (getf report :diagnostic)))
            (error "COD-60: CLI invalida accettata o eseguita."))
          (push (list :arguments args :status (getf report :status)
                      :stage (getf report :stage) :diagnostic (getf report :diagnostic)) records))))
    (nreverse records)))

(defun self-test ()
  "Heap positivo, sink errato, clock nullo, cicli legali, CLI e reporter dei fallimenti."
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0)) (probe nil)
         (positive (sample-record 0 16 0 1048576)) (api-probes nil)
         (wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0)))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error "COD-60: baseline contatore non nulla."))
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
    (unless (and (eq :below-resolution (getf zero :time-quality))
                 (null (getf zero :seconds))) (error "COD-60: clock nullo utilizzato come durata."))
    (dolist (spec '((1 1 578) (1 3 858) (4 1 2520) (4 3 4084)))
      (destructuring-bind (shards capacity token) spec
        (unless (= token (expected-token shards capacity))
          (error "COD-60: oracolo algebrico worker diverso dalla derivazione indipendente."))
        (let ((progress (sample-record 0 4 0 token)))
          (sample (cycle-function shards capacity) 4 token progress :warmup 0)
          (push (list :shards shards :capacity-per-shard capacity :probe progress) api-probes))))
    (self-test-reporter)
    (list :status :ok :baseline baseline :positive-control positive
          :wrong-sink :rejected :wrong-sink-probe wrong :zero-clock :below-resolution
          :zero-clock-probe zero :partial-report :preserved :existing-destination :preserved
          :invalid-cli (self-test-cli) :composed-api-probes (nreverse api-probes))))

(defun main ()
  "CLI C4; risultato strutturato anche senza destinazione e diagnostica con exit nonzero."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&writer-worker-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
