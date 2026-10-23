;;;; C4: composizione pool/routing; EMPTY, INACTIVE e ROUTE-CURRENT separati.
;;;; Cinque repliche di 4096 cicli, 128 warmup e quattro chiamate per ciclo.
;;;; Factory, claim iniziale, cleanup e GC fuori clock; nessun begin nel ciclo misurato.
;;;; Riusa invariati sample/record e fixture negative del lifecycle qualificato.
;;;; --self-test | --bench directory-nuova/. Feature: :arcdocdb-pool-dispatch-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: dispatcher, contesto, link e sensore allo stesso thread C4.
;;; SHARED: ready autentico privato alla fixture; nessun coordinatore concorrente nel clock.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-LIFECYCLE.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-lifecycle-measure-library *features*)))
      (load "tools/measure-pool-lifecycle.lisp"))))
(defpackage #:arcdocdb.pool-dispatch.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:lookup-function #:sample #:sample-record #:campaign-group
                #:acquire-directory #:write-report #:load-product
                #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-dispatch.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun fingerprints ()
  "Stabilita: biblioteca, questo sensore e tutti i sorgenti/test prodotto."
  (append (arcdocdb.pool-lifecycle.measure::fingerprints)
          (list (list :file "tools/measure-pool-dispatch.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-dispatch.lisp") 'list))))))

(defun api (name &optional (package "ARCDOCDB.SCHEDULER.DISPATCH"))
  "Risolve soltanto funzioni pubbliche prima del clock, senza nomi nel percorso caldo."
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60: API pubblica ~A/~A assente." package name))
    (symbol-function symbol)))

(defun make-series ()
  "Backend pubblico C4 locale, nessun I/O richiesto dai lookup della campagna."
  (let* ((backend (funcall (api "MAKE-BACKEND" "ARCDOCDB.IO")
                           (lambda (path mode) (declare (ignore path mode)) 811)
                           (lambda (&rest arguments) (declare (ignore arguments))
                             (error "COD-60: lettura I/O inattesa nella fixture dispatch."))
                           (lambda (fd bytes start count) (declare (ignore fd bytes start)) count)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)))
         (file (funcall (api "CREA-TEMPORANEO" "ARCDOCDB.IO") "pool-dispatch-C4.tmp" :backend backend))
         (log (funcall (api "CREA-LOG-IO" "ARCDOCDB.WAL") file :segment 811)))
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

(defun verify-claim (claim dispatcher expected status cursor lifecycle)
  "Oracolo scalare dei quattro risultati; identita del link attesa dal caller."
  (multiple-value-bind (link outcome next action) (funcall claim dispatcher)
    (unless (and (eq expected link) (eq status outcome) (eql cursor next) (eq lifecycle action))
      (error "COD-60: dispatch ~S/~S/~S/~S invece di ~S/~S/~S/~S."
             link outcome next action expected status cursor lifecycle))))

(defun verify-current (route dispatcher expected context writer read-state read-writer read-link-state)
  "Lookup ripetibile: stesso link IDLE e obbligo CLAIMED, nessun begin o pool ACK."
  (unless (and (eq expected (funcall route dispatcher))
               (eq :claimed (funcall read-state context))
               (eq writer (funcall read-writer context))
               (eq :idle (funcall read-link-state expected)))
    (error "COD-60: lookup current altera o perde il link/obbligo CLAIMED.")))

(defun create-empty-cycle ()
  "Quattro EMPTY attivi: rotazione0->1->2->3->0; token12."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch t 0)
    (declare (ignore context ready writer link))
    (let ((claim (api "PRENDI-COLLEGAMENTO-POOL")))
      (values (lambda ()
                (verify-claim claim dispatcher nil :empty 1 :unchanged)
                (verify-claim claim dispatcher nil :empty 2 :unchanged)
                (verify-claim claim dispatcher nil :empty 3 :unchanged)
                (verify-claim claim dispatcher nil :empty 0 :unchanged)
                12)
              12 (lambda () (close-fixture file))))))

(defun create-inactive-cycle ()
  "Quattro INACTIVE preservano cursor2; token20."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch nil 2)
    (declare (ignore context ready writer link))
    (let ((claim (api "PRENDI-COLLEGAMENTO-POOL")))
      (values (lambda ()
                (dotimes (i 4) (verify-claim claim dispatcher nil :inactive 2 :unchanged))
                20)
              20 (lambda () (close-fixture file))))))

(defun drain-claim (context writer)
  "Cleanup C4 fuori clock: consuma e conferma il solo payload sentinel, poi termina IDLE."
  (let ((target (vector nil)))
    (unless (plusp (funcall (api "INIZIA-TRATTO-WORKER" "ARCDOCDB.EXECUTION") context))
      (error "COD-60: cleanup begin senza lease."))
    (multiple-value-bind (count status token)
        (funcall (api "PRELEVA-LAVORI-WORKER" "ARCDOCDB.EXECUTION") context target 0 1)
      (unless (and (= 1 count) (eq :messages status) (eq :dispatch-C4 (svref target 0)) (plusp token))
        (error "COD-60: cleanup perde il payload della fixture."))
      (funcall (api "CONFERMA-LAVORI-WORKER" "ARCDOCDB.EXECUTION") context token))
    (unless (and (eq writer (funcall (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION") context))
                 (eq :idle (funcall (api "TERMINA-TRATTO-WORKER" "ARCDOCDB.EXECUTION") context)))
      (error "COD-60: cleanup non termina il compito IDLE."))))

(defun create-current-cycle ()
  "Quattro lookup del link CLAIMED stabile; claim iniziale e drain fuori clock; token28."
  (multiple-value-bind (dispatcher context ready writer link file) (make-dispatch t 0)
    (let ((claim (api "PRENDI-COLLEGAMENTO-POOL")) (route (api "COLLEGA-OBBLIGO-POOL"))
          (read-state (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (read-writer (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (read-link-state (api "STATO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES")))
      (multiple-value-bind (count status)
          (funcall (api "ACCODA-LAVORO-WRITER" "ARCDOCDB.EXECUTION") writer :dispatch-C4)
        (unless (and (= 1 count) (eq :schedule status)) (error "COD-60: enqueue iniziale difforme.")))
      (unless (= 1 (funcall (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION") ready 0 writer))
        (error "COD-60: pubblicazione iniziale difforme."))
      (verify-claim claim dispatcher link :claimed 1 :unchanged)
      (values (lambda ()
                (dotimes (i 4)
                  (verify-current route dispatcher link context writer read-state read-writer read-link-state))
                28)
              28 (lambda () (unwind-protect (drain-claim context writer) (close-fixture file)))))))

(defun campaign (report checkpoint)
  "Tre campagne preregistrate; startup, GC e serializzazione dei report esclusi dal clock."
  (campaign-group :empty #'create-empty-cycle report checkpoint)
  (campaign-group :inactive #'create-inactive-cycle report checkpoint)
  (campaign-group :route-current #'create-current-cycle report checkpoint)
  (setf (getf report :current-replica) nil)
  report)

(defun make-report ()
  "Raw e confini C4: nessuna misura di begin, doppia lease o coordinatore vivo."
  (list :schema-version 1 :kind :pool-dispatch-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:empty :shards 4 :initial-cursor 0 :calls-per-cycle 4 :token 12)
                    (:inactive :shards 4 :initial-cursor 2 :calls-per-cycle 4 :token 20)
                    (:route-current :shards 4 :initial-cursor 0 :calls-per-cycle 4 :token 28
                     :initial-claim-outside-clock t :worker-phase :claimed :link-phase :idle
                     :scalar-state-oracle-in-cycle t))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; EMPTY=12; INACTIVE=20; ROUTE-CURRENT=28"
        :limits '(:preallocated-product-and-inputs :startup-claim-drain-and-gc-excluded
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :empty-is-local-observation :no-real-queued-claim-measured
                  :current-is-repeated-claimed-lookup-with-scalar-oracles
                  :no-begin-or-live-lease-in-clock :no-concurrent-coordinator
                  :no-physical-worker-lifecycle-qualification)))
(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "Driver dispatch compatto; riusa I/O esclusivo e sensore qualificati, preserva raw del fallimento."
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
  "Ogni risultato claim e ogni identita/fase current sbagliati devono essere respinti."
  (dolist (row '((:unexpected :empty 1 :unchanged) (nil :inactive 1 :unchanged)
                 (nil :empty 2 :unchanged) (nil :empty 1 :activated)))
    (unless (handler-case
                (progn (verify-claim (lambda (dispatcher) (declare (ignore dispatcher)) (values-list row))
                                     nil nil :empty 1 :unchanged) nil)
              (error () t))
      (error "COD-60: risultato dispatch difforme non respinto: ~S." row)))
  (dolist (row '((:wrong :claimed :writer :idle) (:link :idle :writer :idle)
                 (:link :claimed :wrong :idle) (:link :claimed :writer :active)))
    (unless (handler-case
                (progn (verify-current (lambda (dispatcher) (declare (ignore dispatcher)) (first row))
                                        nil :link nil :writer (constantly (second row))
                                        (constantly (third row)) (constantly (fourth row))) nil)
              (error () t))
      (error "COD-60: identita o fase current difforme non respinta: ~S." row)))
  :passed)

(defun self-test ()
  "Sensore comune positivo/negativo, quattro risultati claim e lookup current reali."
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :dispatch-oracles (self-test-oracle) :dispatch-cli-and-partial-raw (self-test-reporter)
        :empty (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-empty-cycle)
        :inactive (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-inactive-cycle)
        :route-current (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-current-cycle)))

(defun main ()
  "Rapporto leggibile; errore nonzero anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-dispatch.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-dispatch-measure-library *features*) (main))
