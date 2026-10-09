;;;; Allocazioni seriali della lista pronta composta con handoff; nessun I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-ready-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-ready.bench (:use #:cl))
(in-package #:arcdocdb.writer-ready.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/writer-ready-bench.lisp")
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
    (error "COD-60: parametri benchmark ready fuori budget."))
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
        (error "COD-60: clock/heap invalido o sink ready ~D diverso da ~D."
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun publish-batch (enqueue publish ready writers shards)
  "Due obblighi per shard, ciascuno pubblicato una volta; count 1/2 indipendente dal ring."
  (let ((token 0))
    (declare (type fixnum token))
    (dotimes (shard shards token)
      (dotimes (ordinal 2)
        (let* ((index (+ (* 2 shard) ordinal)) (writer (svref writers index)))
          (multiple-value-bind (count action) (funcall enqueue writer (1+ index))
            (unless (and (= 1 count) (eq :schedule action))
              (error "COD-60: manca il nuovo obbligo di pubblicazione ready."))
            (incf token (+ count 11)))
          (let ((count (funcall publish ready shard writer)))
            (unless (= (1+ ordinal) count) (error "COD-60: count ready diverso da 1/2."))
            (incf token count)))))))

(defun consume-writer (start pop finish writer target nonces index)
  "Una lease nuova, un payload preallocato, termine idle; nessun obbligo ripetuto."
  (let ((lease (funcall start writer)) (token 19))
    (declare (type fixnum token))
    (unless (= lease (incf (the fixnum (svref nonces index))))
      (error "COD-60: nonce del writer pronto incoerente."))
    (multiple-value-bind (count status) (funcall pop writer lease target 1 2)
      (unless (and (= 1 count) (eq :messages status) (eql (1+ index) (svref target 1))
                   (eq :outside (svref target 0)) (eq :outside (svref target 2)))
        (error "COD-60: payload/ownership/span del writer pronto incoerenti."))
      (incf token (+ (* 3 count) (* 5 (the fixnum (svref target 1))))))
    (unless (eq :idle (funcall finish writer lease))
      (error "COD-60: writer pronto non torna idle dopo il consumo."))
    (+ token 23)))

(defun cycle-function (shards capacity)
  "Fixture preallocata; due giri e passo 2 sul ring di3 verificano FIFO, wrap e cursor."
  (let* ((create-ready (execution-function "CREA-LISTA-WRITER-PRONTI"))
         (publish (execution-function "PUBBLICA-WRITER-PRONTO"))
         (take (execution-function "PRELEVA-WRITER-PRONTO"))
         (create-writer (execution-function "CREA-WRITER-PROGRAMMABILE"))
         (enqueue (execution-function "ACCODA-LAVORO-WRITER"))
         (start (execution-function "INIZIA-TRATTO-WRITER"))
         (pop (execution-function "PRELEVA-LAVORI-WRITER"))
         (finish (execution-function "TERMINA-TRATTO-WRITER"))
         (ready (funcall create-ready :shards shards :capacity capacity))
         (writers (make-array (* 2 shards))) (nonces (make-array (* 2 shards) :initial-element 0))
         (target (make-array 3 :initial-element :outside)) (cursor 0))
    (declare (type fixnum cursor shards capacity))
    (dotimes (i (length writers)) (setf (svref writers i) (funcall create-writer :capacity 1 :quantum 1)))
    (lambda ()
      (let ((token (publish-batch enqueue publish ready writers shards)))
        (declare (type fixnum token))
        (dotimes (ordinal 2)
          (dotimes (visit shards)
            (let ((index (+ (* 2 cursor) ordinal)) (expected-next (mod (1+ cursor) shards)))
              (multiple-value-bind (writer status next) (funcall take ready cursor)
                (unless (and (eq (svref writers index) writer) (eq :writer status) (= expected-next next))
                  (error "COD-60: identità/FIFO/status/cursor della lista pronta incoerenti."))
                (incf token (+ 17 (* 5 (1+ index)) (* 7 next)))
                (incf token (consume-writer start pop finish writer target nonces index))
                (setf cursor next)))))
        (multiple-value-bind (writer status next) (funcall take ready cursor)
          (unless (and (null writer) (eq :empty status) (= (mod (1+ cursor) shards) next))
            (error "COD-60: scansione vuota/cursor ready incoerenti."))
          (setf cursor next)
          (incf token 29))
        token))))

(defun campaign-record (scenario shards capacity)
  "Oracolo: M=2K wrapper, sum=count+identità+cursor+azioni, pari a 27K²+154K+29."
  (unless (= 3 capacity) (error "COD-60: capacità ready preregistrata diversa da tre."))
  (let ((token (+ (* 27 shards shards) (* 154 shards) 29)))
    (list :scenario scenario :shards shards :capacity-per-shard capacity :writers-per-shard 2
          :ready-published-per-cycle (* 2 shards) :calls-per-cycle (1+ (* 12 shards))
          :expected-token token :token-rule
          '(:enqueue-count-plus-schedule-11 :publish-count :ready-writer-17
            :writer-id-times-5 :next-cursor-times-7 :lease-19 :taken-times-3
            :payload-id-times-5 :finish-idle-23 :ready-empty-29)
          :status :running :stage :fixture :current-replica nil :samples nil :diagnostic nil)))

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
  "I due scenari vengono registrati in ordine e conservati anche al fallimento."
  (dolist (spec '((:one-shard 1 3) (:four-shards 4 3)))
    (let ((progress (apply #'campaign-record spec)))
      (setf (getf report :current-campaign) progress
            (getf report :campaigns) (append (getf report :campaigns) (list progress)))
      (when checkpoint (funcall checkpoint))
      (funcall runner progress checkpoint)))
  report)

(defun make-report ()
  "Metadati di misura e limiti; tutte le chiavi condivise esistono prima degli aggiornamenti."
  (list :schema-version 1 :kind :writer-ready-benchmark :status :running :stage :pending
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-composed-handoff-and-ready-cycles :preallocated-inputs
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
              (getf report :diagnostic) "COD-61: sorgenti cambiati durante il benchmark ready.")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  "Fixture temporanea esclusiva, con limite di mille collisioni."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-ready-bench-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "COD-60: directory fixture benchmark ready non disponibile."))

(defun self-test-partial-run (report &key checkpoint)
  "Primo scenario completo; secondo interrompe la replica dopo un raw sintetico."
  (run-campaigns report :checkpoint checkpoint
    :runner (lambda (progress persist)
              (setf (getf progress :stage) :replica (getf progress :current-replica) 0
                    (getf progress :samples)
                    (list (list :status :running :raw-ticks 7 :heap-bytes 0 :diagnostic nil)))
              (when persist (funcall persist))
              (if (eq :one-shard (getf progress :scenario))
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
  "Heap positivo, sink errato, clock nullo, cicli legali e reporter dei fallimenti."
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0)) (probe nil)
         (positive (sample-record 0 16 0 1048576)) (api-probes nil))
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
    (dolist (shards '(1 4))
      (let* ((token (+ (* 27 shards shards) (* 154 shards) 29))
             (progress (sample-record 0 4 0 token)))
        (sample (cycle-function shards 3) 4 token progress :warmup 0)
        (push (list :shards shards :capacity-per-shard 3 :probe progress) api-probes)))
    (self-test-reporter)
    (list :status :ok :baseline baseline :positive-control positive
          :wrong-sink :rejected :zero-clock :below-resolution :partial-report :preserved
          :existing-destination :preserved :composed-api-probes (nreverse api-probes))))

(defun main ()
  "CLI C4; risultato strutturato anche senza destinazione e diagnostica con exit nonzero."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&writer-ready-bench.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
