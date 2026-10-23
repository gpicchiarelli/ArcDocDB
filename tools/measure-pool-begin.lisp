;;;; C4: begin composto ACTIVE con doppia lease e protocollo C1 esplicito di ripetizione.
;;;; Cinque fixture: 4096 cicli +128 warmup; un payload simbolico conservato senza pop nel clock.
;;;; Factory/claim iniziale/GC/drain finale fuori clock; nessun reset privato o consumo finto.
;;;; Il costo comprende end bridge, recycle room, claim C1 e oracoli scalari.
;;;; --self-test | --bench directory-nuova/. Feature: :arcdocdb-pool-begin-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: dispatcher, contesto, link e sensore allo stesso thread C4.
;;; SHARED: ready/controller autentici privati alla fixture; nessun altro owner nel clock.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-LIFECYCLE.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-lifecycle-measure-library *features*)))
      (load "tools/measure-pool-lifecycle.lisp"))))
(defpackage #:arcdocdb.pool-begin.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:lookup-function #:sample #:sample-record #:acquire-directory #:write-report
                #:load-product #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-begin.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun fingerprints ()
  "Stabilita: biblioteca, questo sensore e tutti i sorgenti/test prodotto."
  (append (arcdocdb.pool-lifecycle.measure::fingerprints)
          (list (list :file "tools/measure-pool-begin.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-begin.lisp") 'list))))))
(defun api (name &optional (package "ARCDOCDB.SCHEDULER.DISPATCH"))
  "Risolve API pubbliche prima del clock, senza ricerca nomi nel tratto misurato."
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60: API pubblica ~A/~A assente." package name))
    (symbol-function symbol)))
(defun make-series ()
  "Backend pubblico C4 locale, nessun I/O nel protocollo C1 della campagna."
  (let* ((backend (funcall (api "MAKE-BACKEND" "ARCDOCDB.IO")
                           (lambda (path mode) (declare (ignore path mode)) 813)
                           (lambda (&rest arguments) (declare (ignore arguments))
                             (error "COD-60: lettura I/O inattesa nella fixture recycle."))
                           (lambda (fd bytes start count) (declare (ignore fd bytes start)) count)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)))
         (file (funcall (api "CREA-TEMPORANEO" "ARCDOCDB.IO") "pool-begin-C4.tmp" :backend backend))
         (log (funcall (api "CREA-LOG-IO" "ARCDOCDB.WAL") file :segment 813)))
    (values (funcall (api "CREA-CONTROLLORE-SERIE" "ARCDOCDB.SERIES")
                     (funcall (api "CREA-REGISTRO-CSN" "ARCDOCDB.CSN") :capacity 4) log :capacity 2)
            file)))
(defun make-fixture ()
  "Un payload reale persistente, writer/Serie singoli e ready capacity1; claim fuori clock."
  (multiple-value-bind (controller file) (make-series)
    (let* ((ready (funcall (api "CREA-LISTA-WRITER-PRONTI" "ARCDOCDB.EXECUTION") :shards 1 :capacity 1))
           (context (funcall (api "CREA-CONTESTO-WORKER-WRITER" "ARCDOCDB.EXECUTION") ready))
           (port (funcall (api "CREA-PORTA-WORKER-POOL" "ARCDOCDB.SCHEDULER") context))
           (writer (funcall (api "CREA-WRITER-PROGRAMMABILE" "ARCDOCDB.EXECUTION")
                            :capacity 1 :quantum 1 :routing-index 0))
           (registry (funcall (api "CREA-REGISTRO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES")
                              (vector writer) (vector controller)))
           (table (funcall (api "CREA-TABELLA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") context registry))
           (links (funcall (lookup-function "TABELLA-WORKER-SERIE-LINKS" "ARCDOCDB.EXECUTION.SERIES") table))
           (dispatcher (funcall (api "CREA-DISPATCHER-WRITER-POOL") port table)))
      (multiple-value-bind (count action)
          (funcall (api "ACCODA-LAVORO-WRITER" "ARCDOCDB.EXECUTION") writer :begin-C4)
        (unless (and (= 1 count) (eq :schedule action)) (error "COD-60: preload iniziale difforme.")))
      (unless (= 1 (funcall (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION") ready 0 writer))
        (error "COD-60: pubblicazione iniziale difforme."))
      (multiple-value-bind (actual status cursor)
          (funcall (api "PRENDI-WRITER-WORKER" "ARCDOCDB.EXECUTION") context)
        (unless (and (eq writer actual) (eq :claimed status) (zerop cursor))
          (error "COD-60: claim iniziale difforme.")))
      (values dispatcher context writer (svref links 0) file))))
(defun verify-begin (begin dispatcher expected token status reason)
  "Oracolo scalare indipendente dei quattro risultati; il token verificato viene usato per end."
  (multiple-value-bind (link actual-token actual-status actual-reason) (funcall begin dispatcher)
    (unless (and (eq expected link) (eql token actual-token)
                 (eq status actual-status) (eq reason actual-reason))
      (error "COD-60: begin ~S/~S/~S/~S invece di ~S/~S/~S/~S."
             link actual-token actual-status actual-reason expected token status reason))
    actual-token))
(defun drain-fixture (dispatcher context writer link file expected-token)
  "Fuori clock: begin/pop/ack/end del bridge drena l'unico payload, senza abbandonare lease."
  (unwind-protect
       (let* ((target (vector nil))
              (token (verify-begin (api "INIZIA-OBBLIGO-POOL") dispatcher link expected-token :active nil)))
         (multiple-value-bind (count status batch)
             (funcall (api "PRELEVA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") link token target 0 1)
           (unless (and (= 1 count) (eq :messages status) (plusp batch) (eq :begin-C4 (svref target 0)))
             (error "COD-60: drain perde payload/count/token."))
           (funcall (api "CONFERMA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") link token batch))
         (unless (and (eq writer (funcall (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION") context))
                      (eq :idle (funcall (api "TERMINA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") link token))
                      (eq :idle (funcall (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION") context))
                      (eq :idle (funcall (api "STATO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") link)))
           (error "COD-60: drain non conclude IDLE con entrambe le lease rilasciate.")))
    (funcall (api "CHIUDI" "ARCDOCDB.IO") file)))
(defun create-active-cycle ()
  "ACTIVE con due lease, end senza pop, pubblicazione room e claim espliciti; token47."
  (multiple-value-bind (dispatcher context writer link file) (make-fixture)
    (let ((begin (api "INIZIA-OBBLIGO-POOL"))
          (end (api "TERMINA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (recycle (api "RICIRCOLA-WORKER" "ARCDOCDB.EXECUTION"))
          (claim (api "PRENDI-WRITER-WORKER" "ARCDOCDB.EXECUTION"))
          (state (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (read-writer (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (link-state (api "STATO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (series-lease (api "LEASE-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (worker-lease (lookup-function "CONTESTO-WORKER-WRITER-LEASE" "ARCDOCDB.EXECUTION"))
          (cursor (lookup-function "CONTESTO-WORKER-WRITER-CURSOR" "ARCDOCDB.EXECUTION"))
          (generation 0))
      (values
       (lambda ()
         (declare (type fixnum generation))
         (let ((token (verify-begin begin dispatcher link (incf generation) :active nil)))
           (unless (and (eq :active (funcall link-state link))
                        (eq :running (funcall state context))
                        (eq writer (funcall read-writer context))
                        (plusp (funcall worker-lease context))
                        (plusp (funcall series-lease link token))
                        (zerop (funcall cursor context)))
             (error "COD-60: ACTIVE senza doppia lease o binding/cursore coerente."))
           (unless (and (eq :schedule (funcall end link token))
                        (eq :idle (funcall link-state link))
                        (eq :reschedule (funcall state context)))
             (error "COD-60: end senza pop perde l'obbligo reale.")))
         (multiple-value-bind (actual action count) (funcall recycle context)
           (unless (and (null actual) (eq :published action) (= 1 count))
             (error "COD-60: ricircolo room del ciclo difforme.")))
         (multiple-value-bind (actual status next) (funcall claim context)
           (unless (and (eq writer actual) (eq :claimed status) (zerop next)
                        (eq :claimed (funcall state context))
                        (eq :idle (funcall link-state link)))
             (error "COD-60: claim esplicito non ripristina il ciclo.")))
         47)
       47 (lambda () (drain-fixture dispatcher context writer link file (1+ generation)))))))
(defun campaign-group (name maker report checkpoint)
  "Nuova fixture per ciascuna replica: generation indipendente e cleanup sempre fuori clock."
  (dotimes (replica +replicas+)
    (multiple-value-bind (function token cleanup) (funcall maker)
      (unwind-protect
           (let ((progress (sample-record replica +iterations+ +warmup+ token)))
             (setf (getf progress :campaign) name (getf report :current-replica) replica
                   (getf report :samples) (append (getf report :samples) (list progress)))
             (funcall checkpoint)
             (sample function +iterations+ token progress)
             (funcall checkpoint)
             (unless (zerop (getf progress :heap-bytes))
               (setf (getf progress :status) :failed (getf progress :diagnostic) "COD-30: heap osservato positivo.")
               (error "COD-30: heap positivo nella campagna ~S replica ~D." name replica)))
        (funcall cleanup))))
  report)
(defun campaign (report checkpoint)
  "Un costo composto preregistrato: begin doppia lease e protocollo esplicito C1."
  (campaign-group :active #'create-active-cycle report checkpoint)
  (setf (getf report :current-replica) nil) report)
(defun make-report ()
  "Raw e limiti: nessun payload applicato nel clock, un reale payload drenato a fine fixture."
  (list :schema-version 1 :kind :pool-begin-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:active :shards 1 :ring-capacity 1 :writers 1 :writer-capacity 1
                     :payloads-per-writer 1 :quantum 1 :begin-api-per-cycle 1 :end-bridge-per-cycle 1
                     :recycle-c1-per-cycle 1 :claim-c1-per-cycle 1 :pop-in-clock 0
                     :monotone-expected-token t :double-lease-positive-oracle t :token 47))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; ACTIVE=47"
        :limits '(:fresh-fixture-per-replica :preallocated-product-and-inputs
                  :startup-claim-gc-and-final-drain-excluded :public-bounded-bridge-drain-after-clock
                  :c1-protocol-and-scalar-oracles-in-clock :not-isolated-wrapper-throughput
                  :one-real-payload-preserved-in-clock :end-without-pop-is-legal-no-batch-debt
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :no-io-pop-ack-or-payload-application-in-clock
                  :active-only-not-closing-or-refusal-latency :no-concurrent-coordinator
                  :no-physical-worker-lifecycle-qualification)))
(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "Driver begin compatto; riusa I/O esclusivo e sensore qualificati, preserva raw del fallimento."
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

(defun self-test-reporter ()
  "Il driver dispatch rifiuta CLI/destinazione e conserva replica conclusa più raw parziale."
  (let ((called nil) (root (arcdocdb.pool-lifecycle.measure::fresh-self-test-directory)))
    (unwind-protect
         (progn
           (dolist (args '(nil ("--bench") ("--bad") ("--bench" "directory" "extra")))
             (unless (and (eq :failed (getf (run-driver args :product-loader (lambda () (setf called t))) :status))
                          (null called))
               (error "COD-60: CLI invalida eseguita.")))
           (let* ((existing (acquire-directory (merge-pathnames "existing/" root)))
                  (failed (merge-pathnames "failed/" root)))
             (write-report '(:sentinel :unchanged) existing)
             (unless (and (eq :failed (getf (run-driver (list "--bench" (namestring existing))
                                                      :product-loader (constantly nil)
                                                      :tester (constantly :passed)) :status))
                          (equal (arcdocdb.pool-lifecycle.measure::read-self-test-report existing)
                                 '(:sentinel :unchanged)))
               (error "COD-60: destinazione precedente non conservata."))
             (run-driver (list "--bench" (namestring failed))
                         :product-loader (constantly nil) :tester (constantly :passed)
                         :runner (lambda (report checkpoint)
                                   (setf (getf report :current-replica) 1 (getf report :samples)
                                         (list (list :status :ok :raw-ticks 3 :heap-bytes 0)
                                               (list :status :running :raw-ticks 7 :heap-bytes 11
                                                     :diagnostic nil)))
                                   (funcall checkpoint) (error "fixture: replica interrotta")))
             (let* ((saved (arcdocdb.pool-lifecycle.measure::read-self-test-report failed))
                    (samples (getf saved :samples)))
               (unless (and (eq :failed (getf saved :status)) (= 1 (getf saved :current-replica))
                            (= 2 (length samples)) (eq :ok (getf (first samples) :status))
                            (eq :failed (getf (second samples) :status))
                            (= 7 (getf (second samples) :raw-ticks))
                            (= 11 (getf (second samples) :heap-bytes)))
                 (error "COD-60: replica o raw parziale persi.")))))
      (uiop:delete-directory-tree root :validate t)))
  :passed)


(defun self-test-oracle ()
  "Tutti e quattro i risultati difformi rifiutati; anche CLOSING ha un oracolo positivo."
  (dolist (row '((:wrong 1 :active nil) (:link 2 :active nil)
                 (:link 1 :closing nil) (:link 1 :active :serie-busy)))
    (unless (handler-case
                (progn (verify-begin (lambda (dispatcher) (declare (ignore dispatcher)) (values-list row))
                                     nil :link 1 :active nil) nil)
              (error () t))
      (error "COD-60: risultato begin difforme non respinto: ~S." row)))
  (unless (= 7 (verify-begin (lambda (dispatcher) (declare (ignore dispatcher))
                              (values :link 7 :closing :serie-busy))
                            nil :link 7 :closing :serie-busy))
    (error "COD-60: oracolo CLOSING perde il token originale."))
  :passed)
(defun self-test ()
  "Sensore condiviso heap/sink/clock/partial, quattro risultati e doppia lease reale con drain."
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :begin-oracles (self-test-oracle) :begin-cli-and-partial-raw (self-test-reporter)
        :active (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-active-cycle)))
(defun main ()
  "Rapporto leggibile; errore nonzero anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-begin.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-begin-measure-library *features*) (main))
