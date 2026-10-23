;;;; C4: claim bounded dal gate pool; EMPTY, INACTIVE e SWITCH separati.
;;;; Cinque repliche di 4096 cicli, warmup128, quattro o sei chiamate/ciclo, GC fuori clock.
;;;; SWITCH usa richieste private seriali quiescenti; non qualifica il coordinatore concorrente.
;;;; Riusa sensore heap/clock/sink, checkpoint e fixture negative del lifecycle qualificato.
;;;; --self-test | --bench directory-nuova/. Feature: :arcdocdb-pool-claim-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: contesto e sensore allo stesso thread C4; startup e risoluzione API fuori clock.
;;; SHARED: nessuno nel clock; REQUEST privato della fixture SWITCH senza worker concorrenti.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-LIFECYCLE.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-lifecycle-measure-library *features*)))
      (load "tools/measure-pool-lifecycle.lisp"))))
(defpackage #:arcdocdb.pool-claim.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:api #:lookup-function #:sample #:sample-record #:campaign-group
                #:acquire-directory #:write-report #:load-product
                #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-claim.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun fingerprints ()
  "Stabilita: include la biblioteca, questo sensore e tutti i sorgenti/test prodotto."
  (append (arcdocdb.pool-lifecycle.measure::fingerprints)
          (list (list :file "tools/measure-pool-claim.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-claim.lisp") 'list))))))

(defun make-port (active cursor)
  "Quattro shard vuoti autentici, contesto owner C1; fixture preallocata prima del clock."
  (let* ((ready (lookup-function "CREA-LISTA-WRITER-PRONTI" "ARCDOCDB.EXECUTION"))
         (context (lookup-function "CREA-CONTESTO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
         (queue (funcall ready :shards 4 :capacity 1)))
    (funcall (api "CREA-PORTA-WORKER-POOL") (funcall context queue :start cursor) :active active)))

(defun verify-claim (claim port status cursor lifecycle)
  "Oracolo scalare indipendente di tutti i quattro valori, senza cons nel percorso riuscito."
  (multiple-value-bind (writer outcome next action) (funcall claim port)
    (unless (and (null writer) (eq status outcome) (eql cursor next) (eq lifecycle action))
      (error "COD-60: claim ~S/~S/~S/~S invece di NIL/~S/~S/~S."
             writer outcome next action status cursor lifecycle))))

(defun create-empty-cycle ()
  "EMPTY attivo: quattro osservazioni locali e rotazione0->1->2->3->0; token12."
  (let ((port (make-port t 0)) (claim (api "PRENDI-WRITER-POOL")))
    (values (lambda ()
              (verify-claim claim port :empty 1 :unchanged)
              (verify-claim claim port :empty 2 :unchanged)
              (verify-claim claim port :empty 3 :unchanged)
              (verify-claim claim port :empty 0 :unchanged)
              12)
            12 (constantly nil))))

(defun create-inactive-cycle ()
  "INACTIVE da cursor2: quattro rifiuti preservano lo stesso cursore; token20."
  (let ((port (make-port nil 2)) (claim (api "PRENDI-WRITER-POOL")))
    (values (lambda ()
              (dotimes (i 4) (verify-claim claim port :inactive 2 :unchanged))
              20)
            20 (constantly nil))))

(defun create-switch-cycle ()
  "Sei claim: retired/inactive, inactive, activated/empty e altri tre EMPTY; token46.
Ruoli seriali C4; generazioni monotone, una richiesta solo dopo la conferma precedente.
Quattro EMPTY ruotano0->1->2->3->0; ritiro e INACTIVE lo conservano, nessun reset."
  (let ((port (make-port t 0)) (claim (api "PRENDI-WRITER-POOL"))
        (set-request (lookup-function "PORTA-WORKER-POOL-REQUEST" "ARCDOCDB.SCHEDULER" t))
        (ack (lookup-function "PORTA-WORKER-POOL-ACK" "ARCDOCDB.SCHEDULER"))
        (generation 0))
    (values
     (lambda ()
       (declare (type fixnum generation))
       (let ((retired (* 2 (incf generation))))
         (funcall set-request retired port)
         (verify-claim claim port :inactive 0 :retired)
         (verify-claim claim port :inactive 0 :unchanged)
         (unless (= retired (the fixnum (funcall ack port)))
           (error "COD-60: ritiro non confermato nella generazione richiesta.")))
       (let ((activated (1+ (* 2 (incf generation)))))
         (funcall set-request activated port)
         (verify-claim claim port :empty 1 :activated)
         (verify-claim claim port :empty 2 :unchanged)
         (verify-claim claim port :empty 3 :unchanged)
         (verify-claim claim port :empty 0 :unchanged)
         (unless (= activated (the fixnum (funcall ack port)))
           (error "COD-60: attivazione non confermata nella generazione richiesta.")))
       46)
     46 (constantly nil))))

(defun campaign (report checkpoint)
  "Tre campagne predefinite: startup, API, GC e serializzazione dei report fuori clock."
  (campaign-group :empty #'create-empty-cycle report checkpoint)
  (campaign-group :inactive #'create-inactive-cycle report checkpoint)
  (campaign-group :switch #'create-switch-cycle report checkpoint)
  (setf (getf report :current-replica) nil)
  report)

(defun make-report ()
  "Raw dei tre percorsi e confini C4, senza attribuire latenza o heap al coordinatore vivo."
  (list :schema-version 1 :kind :pool-claim-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:empty :shards 4 :initial-cursor 0 :claim-per-cycle 4 :token 12)
                    (:inactive :shards 4 :initial-cursor 2 :claim-per-cycle 4 :token 20)
                    (:switch :shards 4 :initial-cursor 0 :claim-per-cycle 6 :token 46
                     :roles-serialized t :private-request-fixture t :generation-increments-per-cycle 2))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; EMPTY=12; INACTIVE=20; SWITCH=46"
        :limits '(:preallocated-product-and-inputs :startup-and-gc-excluded
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :empty-is-local-observation :no-real-queued-claim-measured
                  :no-concurrent-coordinator-or-physical-worker-lifecycle-qualification)))

(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "Driver claim compatto; riusa I/O esclusivo e sensore qualificati, preserva raw del fallimento."
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

(defun self-test-oracle ()
  "Il sensore deve rifiutare separatamente writer, esito, cursore e azione errati."
  (dolist (row '((:unexpected :empty 1 :unchanged) (nil :inactive 1 :unchanged)
                 (nil :empty 2 :unchanged) (nil :empty 1 :activated)))
    (unless (handler-case
                (progn (verify-claim (lambda (port) (declare (ignore port)) (values-list row))
                                     nil :empty 1 :unchanged) nil)
              (error () t))
      (error "COD-60: valore claim difforme non respinto: ~S." row)))
  :passed)

(defun self-test-reporter ()
  "Il driver claim rifiuta CLI/destinazione e conserva replica conclusa più raw parziale."
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

(defun self-test ()
  "Sensore comune positivo/negativo e tre nuove fixture con oracoli dei quattro valori."
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :four-value-oracle (self-test-oracle) :claim-cli-and-partial-raw (self-test-reporter)
        :empty (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-empty-cycle)
        :inactive (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-inactive-cycle)
        :switch (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-switch-cycle)))

(defun main ()
  "Rapporto leggibile e uscita nonzero, anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-claim.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-claim-measure-library *features*) (main))
