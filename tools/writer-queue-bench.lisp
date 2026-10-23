;;;; Misure seriali della coda MPSC e del gettone; nessun I/O nel ciclo misurato.
;;;; Uso: --self-test oppure --bench; metodo code-writer-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.writer-queue.bench (:use #:cl))
(in-package #:arcdocdb.writer-queue.bench)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra i file del prodotto e del driver; confronta stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/writer-queue-bench.lisp")
                            (sort (directory "src/**/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Gli avvisi sono fatali; carica il prodotto prima di leggere simboli qualificati."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb"))))

(defparameter *before* (fingerprints))
(handler-case (load-product)
  (error (condition)
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :writer-queue-benchmark :status :failed
                   :phase :load-product :diagnostic (princ-to-string condition)
                   :source-fingerprints-before *before* :source-fingerprints-after (fingerprints))
             :pretty t)
      (terpri))
    (sb-ext:exit :code 1)))

(defun expected-sink (iterations token)
  "Risultato osservabile indipendente: somma dei token e degli indici delle chiamate."
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample (function iterations token &key (warmup +warmup+))
  "Warmup e GC precedono heap e clock; verifica il sink dopo la misura."
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error "Parametri benchmark coda fuori budget."))
  (dotimes (i (min warmup iterations)) (funcall function))
  (sb-ext:gc :full t)
  (let ((ticks-before (get-internal-real-time)) (heap-before (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i iterations)
      (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall function))))))
    (let* ((heap (- (sb-ext:get-bytes-consed) heap-before))
           (ticks (- (get-internal-real-time) ticks-before))
           (seconds (/ ticks (float internal-time-units-per-second 1d0)))
           (expected (expected-sink iterations token)))
      (unless (and (>= heap 0) (>= ticks 0) (= expected sink))
        (error "Clock/heap invalido oppure sink ~D diverso da ~D." sink expected))
      (list :iterations iterations :warmup-iterations (min warmup iterations)
            :heap-bytes heap :raw-ticks ticks :seconds seconds :sink sink :expected-sink expected
            :expected-return-token token
            :cycles-per-second (when (plusp seconds) (/ iterations seconds))))))

(defun self-test ()
  "Baseline vuota e controllo positivo 16 × 1 MiB con riferimenti vivi e sink atteso."
  (let ((baseline (sample (lambda () 0) +iterations+ 0)) (probe nil))
    (unless (zerop (getf baseline :heap-bytes)) (error "Baseline del contatore non nulla."))
    (let ((positive (sample (lambda ()
                             (setf probe (make-array 1048576 :element-type '(unsigned-byte 8)
                                                            :initial-element 0))
                             (length probe))
                           16 1048576 :warmup 0)))
      (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
        (error "Allocazioni deliberate non rilevate."))
      (list :status :ok :baseline baseline :positive-control positive))))

(defun fixture (count)
  "Due celle: capacità/tratto 1 o 32; messaggi e target privati preallocati."
  (let ((queue (arcdocdb.execution:crea-coda-writer :capacity count :quantum count))
        (messages (make-array count)) (target (make-array (+ count 4) :initial-element :outside)))
    (dotimes (i count) (setf (svref messages i) (1+ i)))
    (values queue messages target)))

(defun cycle-function (queue messages target)
  "Il nonce è controllato ad ogni ciclo; enqueues, count, status e payload alimentano il token."
  (let ((nonce 0) (count (length messages)))
    (declare (type fixnum nonce count))
    (lambda ()
      (let ((lease (arcdocdb.execution:acquisisci-writer queue)) (token 0))
        (unless (= lease (incf nonce)) (error "Generazione del gettone incoerente."))
        (dotimes (i count)
          (incf token (arcdocdb.execution:accoda-messaggio queue (svref messages i))))
        (multiple-value-bind (taken status)
            (arcdocdb.execution:preleva-messaggi queue lease target 2 (+ count 2))
          (unless (and (= count taken) (eq status :messages))
            (error "Conteggio/status del batch incoerenti."))
          (incf token (* 3 taken))
          (dotimes (i taken) (incf token (* 5 (the fixnum (svref target (+ i 2)))))))
        (multiple-value-bind (taken status)
            (arcdocdb.execution:preleva-messaggi queue lease target 2 (+ count 2))
          (unless (and (zerop taken) (eq status :yield)) (error "Quota del tratto non rispettata."))
          (incf token 7))
        (when (arcdocdb.execution:rilascia-writer queue lease) (error "Rilascio non nullo."))
        (unless (and (eq (svref target 0) :outside) (eq (svref target 1) :outside)
                     (eq (svref target (+ count 2)) :outside)
                     (eq (svref target (+ count 3)) :outside))
          (error "Scrittura fuori dallo span del target."))
        token))))

(defun campaign (count)
  "Cinque repliche di cicli completi con array preparati una volta per campagna."
  (multiple-value-bind (queue messages target) (fixture count)
    (let* ((function (cycle-function queue messages target))
           (sum (/ (* count (1+ count)) 2)) (token (+ (* 6 sum) (* 3 count) 7)))
      (list :capacity count :quantum count :messages-per-cycle count
            :calls-per-cycle (+ count 4) :expected-token token
            :token-rule :enqueue-counts-plus-three-taken-plus-five-payload-plus-seven-yield
            :samples (loop repeat +replicas+ collect (sample function +iterations+ token))))))

(defun main ()
  "Report anche sui fallimenti; nessun criterio temporale, zero heap osservato richiesto."
  (let* ((args (rest sb-ext:*posix-argv*))
         (report (list :schema-version 1 :kind :writer-queue-benchmark :status :running
                       :source-fingerprints-before *before* :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :os (software-type) :os-version (software-version) :workers 1 :safety 3
                       :timer-units-per-second internal-time-units-per-second
                       :limits '(:success-path-only :serial-queue-cycles :preallocated-inputs
                                 :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                                 :no-pool-or-device-throughput :no-scaling-or-latency-threshold))))
    (handler-case
        (progn
          (unless (member args '(("--self-test") ("--bench")) :test #'equal)
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (setf (getf report :campaigns) (mapcar #'campaign '(1 32)))
            (unless (every (lambda (campaign)
                             (every (lambda (sample) (zerop (getf sample :heap-bytes)))
                                    (getf campaign :samples))) (getf report :campaigns))
              (error "Criterio zero heap non soddisfatto.")))
          (setf (getf report :status) :ok))
      (error (condition) (setf (getf report :status) :failed
                               (getf report :diagnostic) (princ-to-string condition))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal *before* after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal *before* after)))
        (setf (getf report :status) :source-changed)))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
