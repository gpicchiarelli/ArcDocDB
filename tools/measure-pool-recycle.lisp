;;;; C4: ROOM e FULL reali con ricircolo, claim se room, begin/pop/ack/end.
;;;; Cinque fixture indipendenti: 4096 cicli +128 warmup, 4226 payload/writer, quantum1.
;;;; Factory, claim iniziale, GC e drain finale fuori clock; nessun reset privato.
;;;; Il clock include il protocollo C1 che ristabilisce RESCHEDULE e gli oracoli scalari.
;;;; --self-test | --bench directory-nuova/. Feature: :arcdocdb-pool-recycle-measure-library.
;;; REQ: REQ-CON-005 REQ-AFF-008 REQ-THR-001 REQ-BEN-001 REQ-BEN-002
;;; OWNER: dispatcher, contesto, link, target e sensore allo stesso thread C4.
;;; SHARED: ready autentico privato alla fixture; nessun coordinatore concorrente nel clock.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :asdf)
  (unless (find-package "ARCDOCDB.POOL-LIFECYCLE.MEASURE")
    (let ((*features* (cons :arcdocdb-pool-lifecycle-measure-library *features*)))
      (load "tools/measure-pool-lifecycle.lisp"))))
(defpackage #:arcdocdb.pool-recycle.measure
  (:use #:cl)
  (:import-from #:arcdocdb.pool-lifecycle.measure
                #:lookup-function #:sample #:sample-record #:acquire-directory #:write-report
                #:load-product #:+iterations+ #:+warmup+ #:+replicas+))
(in-package #:arcdocdb.pool-recycle.measure)
(declaim (optimize (safety 3) (speed 2) (debug 2)))
(defconstant +payload-count+ 4226)

(defun fingerprints ()
  "Stabilita: biblioteca, questo sensore e tutti i sorgenti/test prodotto."
  (append (arcdocdb.pool-lifecycle.measure::fingerprints)
          (list (list :file "tools/measure-pool-recycle.lisp"
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file "tools/measure-pool-recycle.lisp") 'list))))))
(defun api (name &optional (package "ARCDOCDB.SCHEDULER.DISPATCH"))
  "Risolve API pubbliche prima del clock, senza ricerca nomi nel tratto misurato."
  (multiple-value-bind (symbol visibility) (find-symbol name package)
    (unless (and symbol (eq :external visibility) (fboundp symbol))
      (error "COD-60: API pubblica ~A/~A assente." package name))
    (symbol-function symbol)))
(defun make-series ()
  "Backend pubblico C4 locale, nessun I/O nel protocollo C1 della campagna."
  (let* ((backend (funcall (api "MAKE-BACKEND" "ARCDOCDB.IO")
                           (lambda (path mode) (declare (ignore path mode)) 812)
                           (lambda (&rest arguments) (declare (ignore arguments))
                             (error "COD-60: lettura I/O inattesa nella fixture recycle."))
                           (lambda (fd bytes start count) (declare (ignore fd bytes start)) count)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)
                           (lambda (fd) (declare (ignore fd)) 0)))
         (file (funcall (api "CREA-TEMPORANEO" "ARCDOCDB.IO") "pool-recycle-C4.tmp" :backend backend))
         (log (funcall (api "CREA-LOG-IO" "ARCDOCDB.WAL") file :segment 812)))
    (values (funcall (api "CREA-CONTROLLORE-SERIE" "ARCDOCDB.SERIES")
                     (funcall (api "CREA-REGISTRO-CSN" "ARCDOCDB.CSN") :capacity 4) log :capacity 2)
            file)))
(defun preload-writer (index payload)
  "4226 payload simbolici immutabili; accettazione e obbligo iniziale verificati fuori clock."
  (let ((writer (funcall (api "CREA-WRITER-PROGRAMMABILE" "ARCDOCDB.EXECUTION")
                          :capacity 8192 :quantum 1 :routing-index index))
        (enqueue (api "ACCODA-LAVORO-WRITER" "ARCDOCDB.EXECUTION")))
    (dotimes (i +payload-count+)
      (multiple-value-bind (count action) (funcall enqueue writer payload)
        (unless (and (= (1+ i) count) (eq (if (zerop i) :schedule :queued) action))
          (error "COD-60: preload perde count o obbligo iniziale."))))
    writer))
(defun make-fixture (full)
  "Un ring autentico capacity1, uno/due writer, dispatcher e tabella preallocati."
  (multiple-value-bind (controller file) (make-series)
    (let* ((ready (funcall (api "CREA-LISTA-WRITER-PRONTI" "ARCDOCDB.EXECUTION") :shards 1 :capacity 1))
           (context (funcall (api "CREA-CONTESTO-WORKER-WRITER" "ARCDOCDB.EXECUTION") ready))
           (other (when full (multiple-value-list (make-series))))
           (port (funcall (api "CREA-PORTA-WORKER-POOL" "ARCDOCDB.SCHEDULER") context))
           (a (preload-writer 0 :recycle-a)) (b (when full (preload-writer 1 :recycle-b)))
           (writers (if full (vector a b) (vector a)))
           (controllers (if full (vector controller (first other)) (vector controller)))
           (registry (funcall (api "CREA-REGISTRO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES")
                              writers controllers))
           (table (funcall (api "CREA-TABELLA-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES") context registry))
           (links (funcall (lookup-function "TABELLA-WORKER-SERIE-LINKS" "ARCDOCDB.EXECUTION.SERIES") table))
           (dispatcher (funcall (api "CREA-DISPATCHER-WRITER-POOL") port table)))
      (unless (= 1 (funcall (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION") ready 0 a))
        (error "COD-60: pubblicazione A iniziale difforme."))
      (multiple-value-bind (link action cursor lifecycle)
          (funcall (api "PRENDI-COLLEGAMENTO-POOL") dispatcher)
        (unless (and (eq (svref links 0) link) (eq :claimed action)
                     (zerop cursor) (eq :unchanged lifecycle))
          (error "COD-60: claim iniziale difforme.")))
      (when full
        (unless (= 1 (funcall (api "PUBBLICA-WRITER-PRONTO" "ARCDOCDB.EXECUTION") ready 0 b))
          (error "COD-60: pubblicazione B iniziale difforme.")))
      (values dispatcher context writers links
              (if full (vector file (second other)) (vector file))))))
(defun consume-one (context target payload begin pop ack end)
  "Una lease, un payload con token, un ack e un end; nessuna collezione di risultati."
  (unless (plusp (funcall begin context)) (error "COD-60: lease non positiva."))
  (multiple-value-bind (count status token) (funcall pop context target 0 1)
    (unless (and (= 1 count) (eq :messages status) (plusp token) (eq payload (svref target 0)))
      (error "COD-60: payload/count/token di pop difforme."))
    (funcall ack context token))
  (funcall end context))
(defun verify-recycle (recycle dispatcher expected status count)
  "Oracolo indipendente su tutti e tre i risultati, compresa identita del link."
  (multiple-value-bind (link action actual-count) (funcall recycle dispatcher)
    (unless (and (eq expected link) (eq status action) (eql count actual-count))
      (error "COD-60: recycle ~S/~S/~S invece di ~S/~S/~S."
             link action actual-count expected status count))))
(defun drain-fixture (dispatcher context writers files)
  "Fuori clock: drena ogni obbligo soltanto con API pubbliche, limite2*4226+4."
  (let ((claim (api "PRENDI-COLLEGAMENTO-POOL")) (recycle (api "RICIRCOLA-COLLEGAMENTO-POOL"))
        (state (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
        (writer (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
        (begin (api "INIZIA-TRATTO-WORKER" "ARCDOCDB.EXECUTION"))
        (pop (api "PRELEVA-LAVORI-WORKER" "ARCDOCDB.EXECUTION"))
        (ack (api "CONFERMA-LAVORI-WORKER" "ARCDOCDB.EXECUTION"))
        (end (api "TERMINA-TRATTO-WORKER" "ARCDOCDB.EXECUTION")) (target (vector nil)))
    (unwind-protect
         (loop repeat (+ (* 2 +payload-count+) 4)
               do (case (funcall state context)
                    (:reschedule (funcall recycle dispatcher))
                    (:idle (multiple-value-bind (link status) (funcall claim dispatcher)
                             (declare (ignore link))
                             (when (eq status :empty) (return-from drain-fixture :drained))
                             (unless (eq status :claimed) (error "COD-60: drain claim difforme."))))
                    (:claimed nil)
                    (otherwise (error "COD-60: drain con fase inattesa.")))
                  (when (eq :claimed (funcall state context))
                    (consume-one context target
                                 (if (eq (svref writers 0) (funcall writer context)) :recycle-a :recycle-b)
                                 begin pop ack end))
               finally (error "COD-60: drain fuori budget esplicito."))
      (loop for file across files do (funcall (api "CHIUDI" "ARCDOCDB.IO") file)))))
(defun create-cycle (full)
  "ROOM: recycle+claim+tratto; FULL: recycle+tratto, alternando A/B; un ciclo ritorna RESCHEDULE."
  (multiple-value-bind (dispatcher context writers links file) (make-fixture full)
    (let ((recycle (api "RICIRCOLA-COLLEGAMENTO-POOL")) (claim (api "PRENDI-COLLEGAMENTO-POOL"))
          (begin (api "INIZIA-TRATTO-WORKER" "ARCDOCDB.EXECUTION"))
          (pop (api "PRELEVA-LAVORI-WORKER" "ARCDOCDB.EXECUTION"))
          (ack (api "CONFERMA-LAVORI-WORKER" "ARCDOCDB.EXECUTION"))
          (end (api "TERMINA-TRATTO-WORKER" "ARCDOCDB.EXECUTION"))
          (state (api "STATO-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (writer (api "WRITER-WORKER-WRITER" "ARCDOCDB.EXECUTION"))
          (link-state (api "STATO-WORKER-SERIE" "ARCDOCDB.EXECUTION.SERIES"))
          (cursor (lookup-function "CONTESTO-WORKER-WRITER-CURSOR" "ARCDOCDB.EXECUTION"))
          (target (vector nil)) (index 0))
      (unless (eq :schedule (consume-one context target :recycle-a begin pop ack end))
        (error "COD-60: tratto iniziale non produce RESCHEDULE."))
      (values
       (lambda ()
         (declare (type fixnum index))
         (when full (setf index (- 1 index)))
         (verify-recycle recycle dispatcher (when full (svref links index))
                         (if full :claimed :published) 1)
         (unless full
           (multiple-value-bind (link status next action) (funcall claim dispatcher)
             (unless (and (eq (svref links 0) link) (eq :claimed status)
                          (zerop next) (eq :unchanged action))
               (error "COD-60: claim ROOM difforme."))))
         (unless (and (eq :claimed (funcall state context))
                      (eq (svref writers index) (funcall writer context))
                      (eq :idle (funcall link-state (svref links index)))
                      (zerop (funcall cursor context)))
           (error "COD-60: obbligo/link/cursore dopo ricircolo difforme."))
         (unless (and (eq :schedule (consume-one context target (if (zerop index) :recycle-a :recycle-b)
                                               begin pop ack end))
                      (eq :reschedule (funcall state context))
                      (eq (svref writers index) (funcall writer context))
                      (zerop (funcall cursor context)))
           (error "COD-60: fine ciclo non conserva RESCHEDULE/cursore/writer."))
         (if full 43 31))
       (if full 43 31) (lambda () (drain-fixture dispatcher context writers file))))))
(defun create-room-cycle () (create-cycle nil))
(defun create-full-cycle () (create-cycle t))
(defun campaign-group (name maker report checkpoint)
  "Nuova fixture per ciascuna replica: budget payload indipendente e cleanup sempre fuori clock."
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
  "Due costi composti preregistrati; nessuna attribuzione al solo wrapper C3."
  (campaign-group :room #'create-room-cycle report checkpoint)
  (campaign-group :full #'create-full-cycle report checkpoint)
  (setf (getf report :current-replica) nil) report)
(defun make-report ()
  "Raw, costi inclusi e limiti: protocollo C1 reale, nessuna misura di park/wake o coordinatore vivo."
  (list :schema-version 1 :kind :pool-recycle-benchmark :status :running :stage :pending
        :diagnostic nil :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time) :self-test nil
        :samples nil :current-replica nil :sbcl (lisp-implementation-version)
        :machine (machine-type) :os (software-type) :os-version (software-version) :safety 3
        :iterations +iterations+ :warmup +warmup+ :replicas +replicas+
        :timer-units-per-second internal-time-units-per-second
        :campaigns '((:room :shards 1 :ring-capacity 1 :writers 1 :writer-capacity 8192
                     :payloads-per-writer 4226 :quantum 1 :recycle-per-cycle 1 :claim-per-cycle 1
                     :begin-pop-ack-end-per-cycle 1 :token 31)
                    (:full :shards 1 :ring-capacity 1 :writers 2 :writer-capacity 8192
                     :payloads-per-writer 4226 :quantum 1 :recycle-per-cycle 1 :claim-per-cycle 0
                     :begin-pop-ack-end-per-cycle 1 :alternating-writer-identity t :token 43))
        :token-formula "sample=N*cycle-token+N*(N-1)/2; ROOM=31; FULL=43"
        :limits '(:fresh-fixture-per-replica :preallocated-product-and-inputs
                  :startup-claim-first-tratto-drain-and-gc-excluded :public-bounded-drain-after-clock
                  :c1-protocol-and-scalar-oracles-in-clock :not-isolated-wrapper-throughput
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-time-threshold-no-tuning-claim
                  :no-io-in-cycle :no-bridge-begin-or-live-series-lease-in-clock
                  :no-concurrent-coordinator :no-physical-worker-lifecycle-qualification)))
(defun run-driver (args &key (product-loader #'load-product) (tester #'self-test) (runner #'campaign))
  "Driver recycle compatto; riusa I/O esclusivo e sensore qualificati, preserva raw del fallimento."
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
  "Ciascuno dei tre risultati ricircolo difforme deve essere respinto."
  (dolist (row '((:unexpected :published 1) (nil :claimed 1) (nil :published 2)))
    (unless (handler-case
                (progn (verify-recycle (lambda (dispatcher) (declare (ignore dispatcher)) (values-list row))
                                       nil nil :published 1) nil)
              (error () t))
      (error "COD-60: risultato recycle difforme non respinto: ~S." row)))
  :passed)
(defun self-test ()
  "Sensore comune heap/sink/clock/partial, tre risultati e due protocolli reali con drain."
  (list :status :ok :shared-sensor (arcdocdb.pool-lifecycle.measure::self-test)
        :recycle-oracles (self-test-oracle) :recycle-cli-and-partial-raw (self-test-reporter)
        :room (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-room-cycle)
        :full (arcdocdb.pool-lifecycle.measure::self-test-composed #'create-full-cycle)))
(defun main ()
  "Rapporto leggibile; errore nonzero anche per fonte cambiata o heap osservato positivo."
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* "~&tools/measure-pool-recycle.lisp: ~A~%" (getf report :diagnostic))
      (uiop:quit 1))))
(unless (member :arcdocdb-pool-recycle-measure-library *features*) (main))
