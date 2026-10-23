;;;; C4: passo di dispatch; campagne EMPTY e CURRENT-INACTIVE, INACTIVE solo self-test.
;;;; Cinque fixture per campagna: 4096 cicli, 128 warmup e quattro chiamate per ciclo.
;;;; Factory, claim iniziale, cleanup e GC fuori clock; nessun begin nel ciclo misurato.
;;;; CURRENT conserva un CLAIMED reale con porta inattiva, senza begin; priorita dell obbligo.
;;;; --self-test | --bench directory-nuova/. Feature: :arcdocdb-pool-step-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: dispatcher, contesto, link e sensore allo stesso thread C4.
;;; SHARED: ready autentico privato alla fixture; nessun coordinatore concorrente nel clock.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-LIFECYCLE.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-lifecycle-measure-library *features*)))
      (load "tools/measure-pool-lifecycle.lisp"))))
(defpackage #:arcdocdb.pool-step.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:lookup-function #:sample #:sample-record
                #:acquire-directory #:write-report #:load-product
                #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-step.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun fingerprints ()
  "Stabilita: biblioteca, questo sensore e tutti i sorgenti/test prodotto."
  (append (arcdocdb.pool-lifecycle.measure::fingerprints)
          (list (list :file "tools/measure-pool-step.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-step.lisp") 'list))))))

(defun api (name &optional (package "ARCDOCDB.SCHEDULER.DISPATCH"))
  "Risolve soltanto funzioni pubbliche prima del clock, senza nomi nel percorso caldo."
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60: API pubblica ~A/~A assente." package name))
    (symbol-function symbol)))

(defun make-series ()
  "Backend pubblico C4 locale, nessun I/O richiesto dai lookup della campagna."
  (let* ((backend (funcall (api "MAKE-BACKEND" "ARCDOCDB.IO")
                           (lambda (path mode) (declare (ignore path mode)) 814)
                           (lambda (&rest arguments) (declare (ignore arguments))
                             (error "COD-60: lettura I/O inattesa nella fixture step."))
                           (lambda (fd bytes start count) (declare (ignore fd bytes start)) count)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)))
         (file (funcall (api "CREA-TEMPORANEO" "ARCDOCDB.IO") "pool-step-C4.tmp" :backend backend))
         (log (funcall (api "CREA-LOG-IO" "ARCDOCDB.WAL") file :segment 814)))
    (values (funcall (api "CREA-CONTROLLORE-SERIE" "ARCDOCDB.SERIES")
                     (funcall (api "CREA-REGISTRO-CSN" "ARCDOCDB.CSN") :capacity 4) log :capacity 2)
            file)))

(defun make-dispatch (active cursor)
  "Quattro shard autentici e tabella singleton; costruzione e risoluzione API fuori clock."
  (multiple-value-bind (controller file) (make-series)
    (let* ((ready (funcall (api "CREA-LISTA-WRITER-PRONTI" "ARCDOCDB.EXECUTION") :shards 4 :capacity 1))
           (context (funcall (api "CREA-CONTESTO-WORKER-WRITER" "ARCDOCDB.EXECUTION") ready :start cursor))
           (port (funcall (api "CREA-PORTA-WORKER-POOL" "ARCDOCDB.SCHEDULER") context :active active))
           (writer (funcall (api "CREA-WRITER-PROGRAMMABILE" "ARCDOCDB.EXECUTION")
                            :capacity 1 :quantum 1 :routing-index 0))
           (registry (funcall (api "CREA-REGISTRO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES")
                              (vector writer) (vector controller)))
           (table (funcall (api "CREA-TABELLA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") context registry))
           (links (funcall (lookup-function "TABELLA-WORKER-SERIE-LINKS" "ARCDOCDB.EXECUTION.SERIES") table)))
      (values (funcall (api "CREA-DISPATCHER-WRITER-POOL") port table)
              context ready writer (svref links 0) file))))

(defun close-fixture (file)
  "Solo cleanup C4: chiude il backend della fixture dopo ogni misura o rifiuto."
  (funcall (api "CHIUDI" "ARCDOCDB.IO") file))

(defun verify-step (step dispatcher expected status origin detail lifecycle)
  "Oracolo scalare indipendente per tutti e cinque i risultati del passo."
  (multiple-value-bind (link outcome actual-origin actual-detail action) (funcall step dispatcher)
    (unless (and (eq expected link) (eq status outcome) (eq origin actual-origin)
                 (eql detail actual-detail) (eq lifecycle action))
      (error "COD-60: step ~S/~S/~S/~S/~S invece di ~S/~S/~S/~S/~S."
             link outcome actual-origin actual-detail action expected status origin detail lifecycle))))
(defun create-empty-cycle ()
  "Quattro EMPTY attivi: origine CLAIM, cursore0->1->2->3->0, azioneUNCHANGED; token12."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch t 0)
    (declare (ignore context ready writer link))
    (let ((step (api "PASSO-DISPATCHER-POOL")))
      (values (lambda ()
                (verify-step step dispatcher nil :empty :claim 1 :unchanged)
                (verify-step step dispatcher nil :empty :claim 2 :unchanged)
                (verify-step step dispatcher nil :empty :claim 3 :unchanged)
                (verify-step step dispatcher nil :empty :claim 0 :unchanged)
                12)
              12 (lambda () (close-fixture file))))))
(defun create-inactive-cycle ()
  "Solo self-test: quattro INACTIVE IDLE conservano cursore2 e origineCLAIM; token20."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch nil 2)
    (declare (ignore context ready writer link))
    (let ((step (api "PASSO-DISPATCHER-POOL")))
      (values (lambda ()
                (dotimes (i 4) (verify-step step dispatcher nil :inactive :claim 2 :unchanged))
                20)
              20 (lambda () (close-fixture file))))))
(defun drain-claim (context writer)
  "Cleanup C4 fuori clock: consuma e conferma il solo payload sentinel, poi termina IDLE."
  (let ((target (vector nil)))
    (unless (plusp (funcall (api "INIZIA-TRATTO-WORKER" "ARCDOCDB.EXECUTION") context))
      (error "COD-60: cleanup begin senza lease."))
    (multiple-value-bind (count status token)
        (funcall (api "PRELEVA-LAVORI-WORKER" "ARCDOCDB.EXECUTION") context target 0 1)
      (unless (and (= 1 count) (eq :messages status) (eq :step-C4 (svref target 0)) (plusp token))
        (error "COD-60: cleanup perde il payload della fixture."))
      (funcall (api "CONFERMA-LAVORI-WORKER" "ARCDOCDB.EXECUTION") context token))
    (unless (and (eq writer (funcall (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION") context))
                 (eq :idle (funcall (api "TERMINA-TRATTO-WORKER" "ARCDOCDB.EXECUTION") context)))
      (error "COD-60: cleanup non termina il compito IDLE."))))

(defun verify-current (step dispatcher link context writer read-state read-writer read-link-state read-cursor)
  "CLAIMED prioritario con porta inattiva; nessuna lease, gate o rotazione del cursore."
  (verify-step step dispatcher link :claimed :current nil nil)
  (unless (and (eq :claimed (funcall read-state context))
               (eq writer (funcall read-writer context))
               (eq :idle (funcall read-link-state link)) (= 1 (funcall read-cursor context)))
    (error "COD-60: step CURRENT altera obbligo, link IDLE o cursore1.")))
(defun create-current-cycle ()
  "Quattro passi CURRENT su porta inattiva e CLAIMED reale; claim/drain fuori clock; token28."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch nil 0)
    (let ((step (api "PASSO-DISPATCHER-POOL"))
          (read-state (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (read-writer (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (read-link-state (api "STATO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (read-cursor (lookup-function "CONTESTO-WORKER-WRITER-CURSOR" "ARCDOCDB.EXECUTION")))
      (multiple-value-bind (count status)
          (funcall (api "ACCODA-LAVORO-WRITER" "ARCDOCDB.EXECUTION") writer :step-C4)
        (unless (and (= 1 count) (eq :schedule status)) (error "COD-60: enqueue iniziale difforme.")))
      (unless (= 1 (funcall (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION") ready 0 writer))
        (error "COD-60: pubblicazione iniziale difforme."))
      (multiple-value-bind (actual status cursor)
          (funcall (api "PRENDI-WRITER-WORKER" "ARCDOCDB.EXECUTION") context)
        (unless (and (eq writer actual) (eq :claimed status) (= 1 cursor))
          (error "COD-60: claim pubblico iniziale difforme.")))
      (values (lambda ()
                (dotimes (i 4)
                  (verify-current step dispatcher link context writer read-state read-writer read-link-state read-cursor))
                28)
              28 (lambda () (unwind-protect (drain-claim context writer) (close-fixture file)))))))
(defun campaign-group (name maker report checkpoint)
  "Nuova fixture per ciascuna replica: obbligo privato indipendente e cleanup sempre fuori clock."
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
  "Due campagne, fixture nuova per replica; INACTIVE e RECYCLE non misurati."
  (campaign-group :empty #'create-empty-cycle report checkpoint)
  (campaign-group :current-inactive #'create-current-cycle report checkpoint)
  (setf (getf report :current-replica) nil) report)
(defun make-report ()
  "Raw e confini: IDLE governato e CLAIMED prioritario; nessun begin o ricircolo nel clock."
  (list :schema-version 1 :kind :pool-step-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:empty :fixtures-per-campaign 5 :shards 4 :port-active t :initial-cursor 0 :calls-per-cycle 4 :token 12)
                    (:current-inactive :fixtures-per-campaign 5 :shards 4 :port-active nil :initial-cursor 1 :calls-per-cycle 4
                     :initial-claim-outside-clock t :worker-phase :claimed :link-phase :idle
                     :detail nil :lifecycle-action nil :scalar-state-oracle-in-cycle t :token 28))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; EMPTY=12; CURRENT-INACTIVE=28"
        :limits '(:preallocated-product-and-inputs :fresh-fixture-per-replica
                  :startup-claim-drain-and-gc-excluded :public-claim-and-bounded-drain
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :empty-is-local-observation :no-real-queued-idle-claim-measured
                  :current-is-repeated-claimed-lookup-with-inactive-port
                  :no-begin-or-live-lease-in-clock :no-recycle-or-refusal-latency-measured
                  :inactive-idle-only-in-self-test :no-concurrent-coordinator
                  :no-physical-worker-lifecycle-qualification)))
(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "Driver step compatto; riusa I/O esclusivo e sensore qualificati, preserva raw del fallimento."
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
  "Ogni risultato step difforme viene respinto separatamente; RECYCLE ha solo oracolo positivo."
  (dolist (row '((:wrong :empty :claim 1 :unchanged) (nil :inactive :claim 1 :unchanged)
                 (nil :empty :current 1 :unchanged) (nil :empty :claim 2 :unchanged)
                 (nil :empty :claim 1 :activated)))
    (unless (handler-case
                (progn (verify-step (lambda (dispatcher) (declare (ignore dispatcher)) (values-list row))
                                    nil nil :empty :claim 1 :unchanged) nil)
              (error () t))
      (error "COD-60: risultato step difforme non respinto: ~S." row)))
  (verify-step (lambda (dispatcher) (declare (ignore dispatcher)) (values :link :claimed :recycle 1 nil))
               nil :link :claimed :recycle 1 nil)
  :passed)
(defun self-test ()
  "Sensore condiviso heap/sink/clock/partial, cinque risultati e tre fixture pubbliche con drain."
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :step-oracles (self-test-oracle) :step-cli-and-partial-raw (self-test-reporter)
        :empty (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-empty-cycle)
        :inactive (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-inactive-cycle)
        :current-inactive (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-current-cycle)))
(defun main ()
  "Rapporto leggibile; errore nonzero anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-step.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-step-measure-library *features*) (main))
