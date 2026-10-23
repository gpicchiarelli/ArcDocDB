;;;; C4: EMPTY e quattro tratti ACTIVE completi; non isola il costo dell'adapter.
;;;; Cinque fixture fresche per campagna, 4096 cicli e 128 warmup per replica.
;;;; --self-test | --bench directory-nuova/. Library: :arcdocdb-pool-start-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: fixture e sensore sul thread C4; nessun coordinatore concorrente.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-STEP.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-step-measure-library *features*)))
      (load "tools/measure-pool-step.lisp"))))
(defpackage #:arcdocdb.pool-start.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:acquire-directory #:write-report #:load-product
                #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-start.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun fingerprints ()
  (append (arcdocdb.pool-step.measure::fingerprints)
          (list (list :file "tools/measure-pool-start.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-start.lisp") 'list))))))

(defun api (name &optional (package "ARCDOCDB.SCHEDULER.DISPATCH"))
  (arcdocdb.pool-step.measure::api name package))

(defun verify-preparation (function dispatcher expected token state reason origin detail action)
  "Oracolo scalare dei sette risultati, incluso token0 degli esiti senza begin."
  (multiple-value-bind (link actual-token actual-state actual-reason actual-origin actual-detail actual-action)
      (funcall function dispatcher)
    (unless (and (eq expected link) (eql token actual-token) (eq state actual-state)
                 (eq reason actual-reason) (eq origin actual-origin) (eql detail actual-detail)
                 (eq action actual-action))
      (error "COD-60: risultati prepara-tratto-pool difformi."))))

(defun create-empty-cycle ()
  (multiple-value-bind (dispatcher context ready writer link file)
      (arcdocdb.pool-step.measure::make-dispatch t 0)
    (declare (ignore context ready writer link))
    (let ((prepare (api "PREPARA-TRATTO-POOL")))
      (values (lambda ()
                (verify-preparation prepare dispatcher nil 0 :empty nil :claim 1 :unchanged)
                (verify-preparation prepare dispatcher nil 0 :empty nil :claim 2 :unchanged)
                (verify-preparation prepare dispatcher nil 0 :empty nil :claim 3 :unchanged)
                (verify-preparation prepare dispatcher nil 0 :empty nil :claim 0 :unchanged)
                12)
              12 (lambda () (arcdocdb.pool-step.measure::close-fixture file))))))

(defun create-active-cycle ()
  "Quattro payload reali: enqueue/publish/prepare/pop/ACK/end, interamente nel clock."
  (multiple-value-bind (dispatcher context ready writer link file)
      (arcdocdb.pool-step.measure::make-dispatch t 0)
    (declare (ignore context))
    (let ((prepare (api "PREPARA-TRATTO-POOL"))
          (enqueue (api "ACCODA-LAVORO-WRITER" "ARCDOCDB.EXECUTION"))
          (publish (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION"))
          (take (api "PRELEVA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (ack (api "CONFERMA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (finish (api "TERMINA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (target (vector :left nil :right)) (generation 0))
      (declare (type fixnum generation))
      (values
       (lambda ()
         (dotimes (index 4)
           (multiple-value-bind (count action) (funcall enqueue writer :start-C4)
             (unless (and (= 1 count) (eq :schedule action)) (error "COD-60: enqueue ACTIVE.")))
           (unless (= 1 (funcall publish ready 0 writer)) (error "COD-60: publish ACTIVE."))
           (incf generation)
           (verify-preparation prepare dispatcher link generation :active nil :claim 1 :unchanged)
           (multiple-value-bind (count status batch) (funcall take link generation target 1 2)
             (unless (and (= 1 count) (eq :messages status) (plusp batch)
                          (eq :left (svref target 0)) (eq :start-C4 (svref target 1))
                          (eq :right (svref target 2)))
               (error "COD-60: payload/count/token ACTIVE."))
             (unless (null (funcall ack link generation batch)) (error "COD-60: ACK ACTIVE.")))
           (unless (eq :idle (funcall finish link generation)) (error "COD-60: end ACTIVE.")))
         28)
       28 (lambda () (arcdocdb.pool-step.measure::close-fixture file))))))

(defun campaign (report checkpoint)
  (arcdocdb.pool-step.measure::campaign-group :empty #'create-empty-cycle report checkpoint)
  (arcdocdb.pool-step.measure::campaign-group :active-cycle #'create-active-cycle report checkpoint)
  (setf (getf report :current-replica) nil) report)

(defun make-report ()
  (list :schema-version 1 :kind :pool-start-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:empty :fixtures 5 :shards 4 :preparations-per-cycle 4 :token 12)
                    (:active-cycle :fixtures 5 :shards 4 :preparations-per-cycle 4 :payloads-per-cycle 4
                     :includes-enqueue-publish-pop-ack-end t :token 28))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; EMPTY=12; ACTIVE-CYCLE=28"
        :limits '(:fresh-fixture-per-replica :factory-api-resolution-and-gc-excluded
                  :complete-active-cycle-in-clock :not-adapter-only-cost
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :no-concurrent-coordinator :no-recycle-or-refusal-latency-measured
                  :fixture-backend-close-on-failure :no-product-rollback-or-cleanup
                  :no-physical-worker-lifecycle-or-whole-engine-qualification)))

(defun self-test-oracle ()
  (dolist (row '((:bad 17 :active nil :claim 1 :unchanged)
                 (:link 18 :active nil :claim 1 :unchanged)
                 (:link 17 :closing nil :claim 1 :unchanged)
                 (:link 17 :active :serie-busy :claim 1 :unchanged)
                 (:link 17 :active nil :current 1 :unchanged)
                 (:link 17 :active nil :claim 2 :unchanged)
                 (:link 17 :active nil :claim 1 :activated)))
    (unless (handler-case
                (progn
                  (verify-preparation (lambda (value) (declare (ignore value)) (values-list row))
                                      nil :link 17 :active nil :claim 1 :unchanged)
                  nil)
              (error () t))
      (error "COD-60: oracolo sette risultati non rileva errore.")))
  :passed)

(defun self-test ()
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :seven-values (self-test-oracle) :cli-and-partial (self-test-reporter)
        :empty (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-empty-cycle)
        :active-cycle (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-active-cycle)))

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

(defun main ()
  "Rapporto leggibile; errore nonzero anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-start.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-start-measure-library *features*) (main))
