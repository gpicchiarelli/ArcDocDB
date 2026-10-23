;;;; Confronto riproducibile merge/radix; solo ordinamento nel tempo misurato.
;;;; Uso: --self-test oppure --bench directory-nuova/.
;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.decisions.sort-bench (:use #:cl))
(in-package #:arcdocdb.decisions.sort-bench)
(declaim (optimize (safety 3) (debug 2)))

(defun load-product ()
  (let ((root (truename "./")) (*standard-output* *error-output*))
    (asdf:initialize-output-translations
     `(:output-translations (,root ,(merge-pathnames "spikes/out/decisions-bench-fasl/" root))
                            :ignore-inherited-configuration))
    (setf asdf:*compile-file-warnings-behaviour* :error asdf:*compile-file-failure-behaviour* :error)
    (handler-bind ((warning (lambda (c) (if (typep c 'sb-kernel:redefinition-warning)
                                          (muffle-warning c) (error c)))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" root))
      (asdf:load-system "arcdocdb" :force t)
      (unless (fboundp (find-symbol "RADIX-SORT-ENTRIES" "ARCDOCDB.RECOVERY.DECISIONS"))
        (ensure-directories-exist "spikes/out/decisions-bench-fasl/radix.fasl")
        (load (compile-file "src/recovery/decisions-radix.lisp"
                            :output-file "spikes/out/decisions-bench-fasl/radix.fasl"))))))
(load-product)

(defconstant +seed+ #x123456789abcdef0)
(defconstant +mask+ #xffffffffffffffff)
(defconstant +max-copy-bytes+ 67108864)
(defconstant +max-iterations+ 65536)
(defconstant +replicas+ 3)
(defconstant +minimum-duration-ticks+ (ceiling internal-time-units-per-second 20))
(defconstant +calibration-target-ticks+ (ceiling internal-time-units-per-second 10))

(define-condition incorrect-sort (error) ()
  (:documentation "Il risultato misurato differisce dall'oracolo indipendente.")
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string "Ordinamento diverso dall'oracolo." stream))))
(define-condition reporter-probe-failure (error) ()
  (:documentation "Errore intenzionale del self-test del reporter."))

(defun scrambled (number)
  (logand +mask+ (+ +seed+ (* number #x9e3779b97f4a7c15))))

(defun store-be64 (buffer start number)
  (dotimes (i 8) (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 (- 7 i))) number))))

(defun fixture (scope count pattern)
  "Fixture univoche; duplicati ammessi solo nei TXID, con identità fisica preservata."
  (ecase scope
    (:participants
     (let ((buffer (make-array (* 16 count) :element-type '(unsigned-byte 8) :initial-element 0)))
       (dotimes (i count)
         (let ((key (ecase pattern (:ordered i) (:reverse (- count i 1))
                                  (:mixed (scrambled i)) (:full (scrambled i)))))
           (when (eq pattern :full) (store-be64 buffer (* 16 i) key))
           (store-be64 buffer (+ (* 16 i) 8) (if (eq pattern :full) (scrambled key) key))))
       buffer))
    (:entries
     (let ((entries (make-array count))
           (participants (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)))
       (setf (aref participants 31) 1)
       (dotimes (i count)
         (setf (aref entries i)
               (arcdocdb.recovery.decisions::%make-decision-entry
                (ecase pattern (:ordered i) (:reverse (- count i 1)) (:mixed (scrambled i))
                               (:duplicates (scrambled (floor i 4))) (:uniform 0))
                0 2 participants i)))
       entries))))

(defun id-less-p (buffer a b)
  (dotimes (i 16 nil)
    (let ((left (aref buffer (+ (* a 16) i))) (right (aref buffer (+ (* b 16) i))))
      (when (/= left right) (return (< left right))))))

(defun oracle (scope input)
  "Oracolo a stable-sort indipendente dai due algoritmi del prodotto."
  (ecase scope
    (:entries (stable-sort (copy-seq input) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))
    (:participants
     (let* ((count (/ (length input) 16)) (indexes (make-array count)) (result (copy-seq input)))
       (dotimes (i count) (setf (aref indexes i) i))
       (stable-sort indexes (lambda (a b) (id-less-p input a b)))
       (dotimes (i count)
         (replace result input :start1 (* i 16) :end1 (* (1+ i) 16)
                               :start2 (* (aref indexes i) 16) :end2 (* (1+ (aref indexes i)) 16)))
       result))))

(defun matches-p (scope expected actual)
  (and (= (length expected) (length actual))
       (ecase scope
         (:participants (equalp expected actual))
         (:entries (loop for a across expected for b across actual always (eq a b))))))

(defun algorithm (scope name count)
  (ecase scope
    (:entries (ecase name (:merge #'arcdocdb.recovery.decisions::sort-entries)
                         (:radix #'arcdocdb.recovery.decisions::radix-sort-entries)))
    (:participants
     (let ((function (ecase name (:merge #'arcdocdb.recovery.decisions::sort-participants)
                                (:radix #'arcdocdb.recovery.decisions::radix-sort-participants))))
       (lambda (input) (funcall function input count 64))))))

(defun duration-kind (ticks)
  (unless (>= ticks 0) (error "Durata negativa."))
  (if (plusp ticks) :measured :below-resolution))

(defun measurement (ticks heap iterations)
  "Tick grezzi conservati; meno di 50 ms non autorizza una soglia."
  (unless (and (>= ticks 0) (>= heap 0) (plusp iterations))
    (error "Contatore o iterazioni invalidi."))
  (let ((seconds (/ ticks (float internal-time-units-per-second 1d0)))
        (usable (>= ticks +minimum-duration-ticks+)))
    (list :iterations iterations :ticks ticks :seconds seconds :heap-bytes heap
          :status (duration-kind ticks)
          :quality (if usable :target-reached :insufficient-duration)
          :threshold-usable-p usable
          :seconds-per-sort (when (plusp ticks) (/ seconds iterations))
          :heap-bytes-per-sort (/ heap iterations))))

(defun sample (scope input expected function iterations &key (clock #'get-internal-real-time))
  "Copie/oracolo/GC iniziale fuori misura; scratch e GC del sort inclusi.
CLOCK è iniettabile per dimostrare il percorso di durata nulla nel self-test."
  (unless (plusp iterations) (error "Iterazioni non positive."))
  (let ((copies (make-array iterations)) (outputs (make-array iterations)))
    (dotimes (i iterations) (setf (aref copies i) (copy-seq input)))
    (sb-ext:gc :full t)
    (let* ((before (sb-ext:get-bytes-consed)) (start (funcall clock)))
      (dotimes (i iterations) (setf (aref outputs i) (funcall function (aref copies i))))
      (let ((ticks (- (funcall clock) start)) (heap (- (sb-ext:get-bytes-consed) before)))
        (dotimes (i iterations)
          (unless (matches-p scope expected (aref outputs i)) (error 'incorrect-sort)))
        (measurement ticks heap iterations)))))

(defun iteration-cap (scope input)
  "Limita il payload delle copie, non l'heap totale del campione."
  (let ((bytes (* (length input) (if (eq scope :entries) 8 1))))
    (when (> bytes +max-copy-bytes+) (error "Una copia supera il budget."))
    (min +max-iterations+ (floor +max-copy-bytes+ (max 1 bytes)))))

(defun calibrate (scope input expected function progress checkpoint)
  "Al massimo 17 tentativi; progress conserva warmup e ogni prova completata."
  (setf (getf progress :stage) :warmup (getf progress :warmups-completed) 0)
  (when checkpoint (funcall checkpoint))
  (dotimes (i 2)
    (unless (matches-p scope expected (funcall function (copy-seq input))) (error 'incorrect-sort))
    (incf (getf progress :warmups-completed))
    (when checkpoint (funcall checkpoint)))
  (let ((cap (iteration-cap scope input)) (iterations 1))
    (setf (getf progress :iteration-cap) cap
          (getf progress :target-ticks) +calibration-target-ticks+)
    (dotimes (attempt 17)
      (setf (getf progress :stage) :measurement (getf progress :attempt) attempt
            (getf progress :iterations) iterations)
      (when checkpoint (funcall checkpoint))
      (let ((result (sample scope input expected function iterations)))
        (setf (getf progress :probes) (append (getf progress :probes) (list result))
              (getf progress :probe) result)
        (when checkpoint (funcall checkpoint))
        (when (or (>= (getf result :ticks) +calibration-target-ticks+) (= iterations cap))
          (setf (getf progress :quality)
                (if (>= (getf result :ticks) +calibration-target-ticks+)
                    :target-reached :insufficient-duration)
                (getf progress :stage) :complete)
          (when checkpoint (funcall checkpoint))
          (return-from calibrate progress)))
      (setf iterations (min cap (* 2 iterations))))
    (error "Calibrazione oltre il limite.")))

(defun campaign (scope count pattern progress checkpoint)
  "Aggiorna uno scenario già posseduto dal report prima di ogni passo fallibile."
  (setf (getf progress :stage) :fixtures)
  (when checkpoint (funcall checkpoint))
  (let* ((input (fixture scope count pattern)) (original (copy-seq input)) (expected (oracle scope input))
         (merge (algorithm scope :merge count)) (radix (algorithm scope :radix count)))
    (dolist (name '(:merge :radix))
      (let ((state (list :algorithm name :stage :pending :warmups-completed 0
                         :iteration-cap nil :target-ticks nil :attempt nil :iterations nil
                         :probes nil :probe nil :quality nil)))
        (setf (getf progress :stage) :calibration (getf progress :algorithm) name
              (getf progress :calibrations) (append (getf progress :calibrations) (list (cons name state))))
        (calibrate scope input expected (if (eq name :merge) merge radix) state checkpoint)))
    (dotimes (replica +replicas+)
      (dolist (name (if (evenp replica) '(:merge :radix) '(:radix :merge)))
        (setf (getf progress :stage) :replica (getf progress :algorithm) name
              (getf progress :replica) replica)
        (when checkpoint (funcall checkpoint))
        (let* ((calibration (cdr (assoc name (getf progress :calibrations))))
               (result (sample scope input expected (if (eq name :merge) merge radix)
                               (getf calibration :iterations))))
          (unless (eq (getf calibration :quality) :target-reached)
            (setf (getf result :threshold-usable-p) nil))
          (setf (getf progress :samples)
                (append (getf progress :samples)
                        (list (list :algorithm name :replica replica :measurement result))))
          (when checkpoint (funcall checkpoint)))))
    (setf (getf progress :stage) :fixture-check)
    (unless (equalp input original) (error "Fixture modificata."))
    (setf (getf progress :stage) :complete (getf progress :status) :ok)
    (when checkpoint (funcall checkpoint))
    progress))

(defun campaign-specifications ()
  (loop for scope in '(:participants :entries) append
        (loop for count in '(16 64 256 1024 4096 16384 65535) append
              (loop for pattern in (if (eq scope :participants)
                                       '(:ordered :reverse :mixed :full)
                                       '(:ordered :reverse :mixed :duplicates :uniform))
                    collect (list scope count pattern)))))

(defun run-campaigns (report &key checkpoint (runner #'campaign)
                                (specifications (campaign-specifications)))
  "Collega anche lo scenario corrente al report; gli errori lasciano tutte le prove."
  (dolist (spec specifications)
    (destructuring-bind (scope count pattern) spec
      (let ((progress (list :scope scope :count count :pattern pattern :seed +seed+
                            :status :running :stage :pending :algorithm nil :replica nil
                            :calibrations nil :samples nil :diagnostic nil)))
        (setf (getf report :current-campaign) progress
              (getf report :campaigns) (append (getf report :campaigns) (list progress)))
        (when checkpoint (funcall checkpoint))
        (funcall runner scope count pattern progress checkpoint))))
  report)

(defun make-report ()
  (list :schema-version 1 :driver-version 2 :kind :decision-sort-benchmark :status :running
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :seed +seed+ :replicas +replicas+ :workers 1 :safety 3
        :timer-units-per-second internal-time-units-per-second
        :timer-unit-seconds (/ 1 internal-time-units-per-second)
        :minimum-duration-ticks +minimum-duration-ticks+
        :calibration-target-ticks +calibration-target-ticks+
        :max-copy-bytes +max-copy-bytes+ :max-iterations +max-iterations+
        :threshold-policy '(:metric :median-seconds-per-sort :max-radix-over-merge 9/10
                            :separate-scopes t :all-patterns-at-or-above-threshold t
                            :insufficient-duration :keep-merge)
        :limits '(:sort-only :copies-and-oracle-outside-timing :gc-inside-sort-included
                  :copy-payload-budget-is-not-total-heap-budget :full-id-halves-correlated
                  :cold-recovery-allocation-permitted :macos-local-is-not-linux-qualification
                  :external-load-uncontrolled :no-engine-throughput-or-p99-claim)))

(defun claim-directory (requested)
  "Restituisce solo una directory nuova creata da questo run; non scrive se esiste."
  (let* ((directory (uiop:ensure-directory-pathname requested))
         (parent (make-pathname :directory (butlast (pathname-directory directory))
                                :name nil :type nil :defaults directory)))
    (ensure-directories-exist (merge-pathnames "parent.marker" parent))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report owned-directory &key (if-exists :error))
  "La directory è già stata creata dal run, mai una destinazione rifiutata."
  (unless owned-directory (error "Directory non posseduta."))
  (with-open-file (stream (merge-pathnames "report.lisp" owned-directory)
                          :direction :output :if-exists if-exists)
    (write report :stream stream :pretty t) (terpri stream)))

(defun mark-failed (report condition)
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (let ((current (getf report :current-campaign)))
    (when current
      (setf (getf current :status) :failed (getf current :diagnostic) (princ-to-string condition))))
  report)

(defun run-driver (args &key (report (make-report)) (self-tester #'self-test)
                            (campaign-runner #'run-campaigns))
  "Gli errori producono un report; solo una destinazione reclamata può essere scritta."
  (let ((owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= (length args) 2) (string= (first args) "--bench")))
            (error "Usare --self-test oppure --bench directory-nuova/."))
          (when (= (length args) 2) (setf owned-directory (claim-directory (second args))))
          (setf (getf report :self-test) (funcall self-tester))
          (when owned-directory
            (funcall campaign-runner report
                     :checkpoint (lambda () (write-report report owned-directory :if-exists :supersede))))
          (setf (getf report :status) :ok)
          (when owned-directory (write-report report owned-directory :if-exists :supersede)))
      (error (condition)
        (mark-failed report condition)
        (when owned-directory (write-report report owned-directory :if-exists :supersede))))
    report))

(defun self-test-partial-run (report &key checkpoint)
  "Un primo scenario completo e un secondo con prova parziale prima dell'errore."
  (run-campaigns report :checkpoint checkpoint :specifications '((:entries 16 :ordered) (:entries 16 :reverse))
    :runner (lambda (scope count pattern progress persist)
              (unless (and (eq scope :entries) (= count 16)) (error "Spec self-test errata."))
              (setf (getf progress :samples) '((:algorithm :merge :measurement (:ticks 7))))
              (when persist (funcall persist))
              (if (eq pattern :ordered)
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (progn (setf (getf progress :stage) :replica)
                         (error 'reporter-probe-failure))))))

(defun self-test-reporter ()
  "Verifica i report parziali e l'intangibilità della destinazione già esistente."
  (uiop:with-temporary-file (:pathname marker :stream stream)
    (write-line "marker" stream)
    (let* ((base (append (pathname-directory marker) (list (concatenate 'string (pathname-name marker) "-bench"))))
           (fresh (make-pathname :directory base :name nil :type nil :defaults marker))
           (existing (make-pathname :directory (append base '("existing")) :name nil :type nil :defaults marker))
           (owned-base nil))
      (unwind-protect
           (progn
             (setf owned-base (claim-directory fresh))
             (claim-directory existing)
             (write-report '(:sentinel :unchanged) existing)
             (let ((refused (run-driver (list "--bench" (namestring existing))
                                       :self-tester (constantly :passed))))
               (unless (eq (getf refused :status) :failed) (error "Destinazione esistente accettata.")))
             (with-open-file (input (merge-pathnames "report.lisp" existing))
               (let ((*read-eval* nil))
                 (unless (equal (read input) '(:sentinel :unchanged)) (error "Report precedente modificato."))))
             (let* ((failed-directory (make-pathname :directory (append base '("failed"))
                                                      :name nil :type nil :defaults marker))
                    (failed (run-driver (list "--bench" (namestring failed-directory))
                                        :self-tester (constantly :passed) :campaign-runner #'self-test-partial-run)))
               (unless (eq (getf failed :status) :failed) (error "Errore del reporter non rilevato."))
               (with-open-file (input (merge-pathnames "report.lisp" failed-directory))
                 (let* ((*read-eval* nil) (saved (read input)) (cases (getf saved :campaigns)))
                   (unless (and (= (length cases) 2) (eq (getf (first cases) :status) :ok)
                                (eq (getf (second cases) :status) :failed)
                                (eq (getf (second cases) :stage) :replica)
                                (equal (getf (second cases) :samples)
                                       '((:algorithm :merge :measurement (:ticks 7)))))
                     (error "Precedenti o prove parziali persi."))))))
        (when owned-base (uiop:delete-directory-tree owned-base :validate t))))))

(defun self-test ()
  (unless (and (eq (duration-kind 0) :below-resolution) (eq (duration-kind 1) :measured)
               (not (getf (measurement (1- +minimum-duration-ticks+) 0 1) :threshold-usable-p))
               (getf (measurement +minimum-duration-ticks+ 0 1) :threshold-usable-p))
    (error "Classificazione del tempo errata."))
  (dolist (scope '(:participants :entries))
    (let* ((input (fixture scope 17 :mixed)) (expected (oracle scope input)))
      (unless (and (equalp input (fixture scope 17 :mixed)) (not (matches-p scope expected input)))
        (error "Fixture/oracolo incapace di rilevare algoritmo identità."))
      (unless (handler-case (progn (sample scope input expected #'identity 2) nil)
                (incorrect-sort () t))
        (error "Driver incapace di rifiutare algoritmo identità."))
      (dolist (name '(:merge :radix))
        (sample scope input expected (algorithm scope name 17) 2))
      (let ((zero (sample scope input expected (algorithm scope :merge 17) 2 :clock (constantly 0))))
        (unless (and (eq (getf zero :status) :below-resolution)
                     (eq (getf zero :quality) :insufficient-duration)
                     (null (getf zero :seconds-per-sort)) (null (getf zero :threshold-usable-p)))
          (error "Tempo nullo utilizzato come misura.")))))
  (self-test-reporter)
  :passed)

(defun main ()
  (let ((report (run-driver (uiop:command-line-arguments))))
    (if (eq (getf report :status) :ok)
        (format t "Benchmark ordinamenti: self-test superato~A.~%"
                (if (getf report :campaigns)
                    (format nil ", ~D scenari conservati" (length (getf report :campaigns))) ""))
        (progn (format *error-output* "~A~%" (getf report :diagnostic))
               (sb-ext:exit :code 1)))))

(main)
