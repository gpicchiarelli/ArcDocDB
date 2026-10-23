;;;; Misure seriali di scrittura valori semplici CBOR; buffer preallocato per fixture.
;;;; Uso: --self-test oppure --bench; warmup 128, 4096 chiamate × 5 repliche.
;;;; Prereg: sei fixture 0/20/22/23/32/255, start2, byte e token indipendenti.
;;;; REQ: REQ-CBR-003 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.cbor-simple-write.bench (:use #:cl))
(in-package #:arcdocdb.cbor-simple-write.bench)
(declaim (optimize (safety 3) (debug 2)))
(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra prodotto e driver; il confronto verifica stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/cbor-simple-write-bench.lisp")
                            (sort (directory "src/**/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Carica prima della misura, con avvisi fatali e output diagnostico separato."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb"))))

(defparameter *before* (fingerprints))
(handler-case (load-product)
  (error (condition)
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :cbor-simple-write-benchmark :status :failed
                   :phase :load-product :diagnostic (princ-to-string condition)
                   :source-fingerprints-before *before* :source-fingerprints-after (fingerprints))
             :pretty t)
      (terpri))
    (sb-ext:exit :code 1)))

(defun expected-sink (iterations token)
  "Somma aritmetica dei token attesi e degli indici delle invocazioni."
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample (function iterations token &key (warmup +warmup+))
  "Warmup e GC fuori da heap/clock; il risultato alimenta il sink atteso."
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 *)) (<= token most-positive-fixnum))
    (error "Parametri benchmark scrittura CBOR fuori budget."))
  (dotimes (i warmup) (funcall function))
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
      (list :iterations iterations :warmup-iterations warmup :heap-bytes heap
            :raw-ticks ticks :seconds seconds :sink sink :expected-sink expected
            :expected-return-token token
            :calls-per-second (when (plusp seconds) (/ iterations seconds))))))

(defun checked-token (buffer expected next expected-next)
  "Controlla tutto l'output, sentinelle comprese; NEXT e ogni byte alimentano il sink."
  (unless (and (= next expected-next) (= (length buffer) (length expected)))
    (error "NEXT o lunghezza buffer diversi dalla fixture CBOR indipendente."))
  (let ((token next))
    (declare (type fixnum token))
    (dotimes (i (length buffer) token)
      (unless (= (aref buffer i) (aref expected i))
        (error "Byte ~D della scrittura CBOR diverso dalla fixture indipendente." i))
      (incf token (* (1+ i) (aref buffer i))))))

(defun expect-check-rejection (function)
  "Un dato deliberatamente alterato deve essere rifiutato dal controllo osservabile."
  (let ((rejected nil))
    (handler-case (funcall function) (error () (setf rejected t)))
    (unless rejected (error "Self-test benchmark: dato alterato non rilevato."))))

(defun check-cold-values (values expected-next)
  "Rifiuta qualunque arità diversa da uno, compreso un secondo valore NIL."
  (unless (and (= 1 (length values)) (eql expected-next (first values)))
    (error "Arità o NEXT freddo CBOR diversi dalla costante indipendente."))
  expected-next)

(defun arity-self-test ()
  "Un valore esatto accettato; zero, due/extra NIL e NEXT errato rifiutati."
  (unless (= 7 (check-cold-values '(7) 7))
    (error "Self-test benchmark: NEXT singolo non conservato."))
  (dolist (values '(nil (7 8) (7 nil) (8)))
    (expect-check-rejection (lambda () (check-cold-values values 7))))
  (list :status :ok :single-value-accepted t :wrong-arity-or-next-rejected 4))

(defun checker-self-test ()
  "Token positivo e sei alterazioni: NEXT, prefisso, due byte, residuo e coda fisica."
  (let* ((expected (make-array 8 :element-type '(unsigned-byte 8)
                               :initial-contents '(165 165 248 32 165 165 165 165)))
         (buffer (copy-seq expected)))
    (unless (= 5661 (checked-token buffer expected 4 4))
      (error "Self-test benchmark: token indipendente errato."))
    (expect-check-rejection (lambda () (checked-token buffer expected 3 4)))
    (dolist (index '(0 2 3 4 7))
      (setf (aref buffer index) (logxor 1 (aref buffer index)))
      (expect-check-rejection (lambda () (checked-token buffer expected 4 4)))
      (setf (aref buffer index) (aref expected index)))
    (list :status :ok :expected-token 5661 :altered-next-rejected t
          :altered-prefix-lead-value-residual-tail-rejected 5)))

(defun check-zero-heap (samples)
  "Criterio locale sui dati osservati; non è una prova assoluta di non allocazione."
  (unless (every (lambda (entry) (zerop (getf entry :heap-bytes))) samples)
    (error "Criterio zero heap non soddisfatto."))
  t)

(defun sensor-self-test ()
  "Rifiuta un sink diverso dal token indipendente e un campione con heap non nullo."
  (expect-check-rejection (lambda () (sample (lambda () 1) 16 0 :warmup 0)))
  (unless (check-zero-heap '((:heap-bytes 0)))
    (error "Self-test benchmark: campione heap nullo rifiutato."))
  (expect-check-rejection (lambda () (check-zero-heap '((:heap-bytes 1)))))
  (list :status :ok :wrong-sink-rejected t :nonzero-heap-rejected t))

(defun self-test ()
  "Baseline nulla e controllo positivo 16 × 1 MiB, con oggetto vivo e sink verificato."
  (let ((baseline (sample (lambda () 0) +iterations+ 0)) (probe nil))
    (check-zero-heap (list baseline))
    (let ((positive (sample (lambda ()
                             (setf probe (make-array 1048576 :element-type '(unsigned-byte 8)
                                                            :initial-element 0))
                             (length probe))
                           16 1048576 :warmup 0)))
      (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
        (error "Allocazioni deliberate non rilevate."))
      (list :status :ok :baseline baseline :positive-control positive
            :output-checker (checker-self-test) :arity-checker (arity-self-test)
            :sensor-checker (sensor-self-test)))))

(defun campaign (name value bytes token)
  "Octets letterali freddi; due byte residui e due dopo END verificati a ogni chiamata."
  (let* ((size (length bytes)) (next (+ size 2)) (end (+ next 2))
         (buffer (make-array (+ size 6) :element-type '(unsigned-byte 8) :initial-element 165))
         (expected (make-array (+ size 6) :element-type '(unsigned-byte 8) :initial-element 165)))
    (replace expected bytes :start1 2)
    (unless (every (lambda (byte) (= byte 165)) buffer)
      (error "Fixture benchmark CBOR non inizializzata alle sentinelle."))
    (let ((cold-values (multiple-value-list
                        (arcdocdb.cbor:scrivi-semplice-cbor-minimo buffer 2 end value))))
      (check-cold-values cold-values next)
      (unless (= token (checked-token buffer expected (first cold-values) next))
        (error "Token freddo diverso dalla costante aritmetica indipendente."))
      (let* ((function (lambda ()
                         (checked-token buffer expected
                                        (arcdocdb.cbor:scrivi-semplice-cbor-minimo
                                         buffer 2 end value) next)))
             (samples (loop repeat +replicas+ collect (sample function +iterations+ token))))
        (list :name name :value value :unit-bytes size :expected-bytes bytes
              :expected-full-buffer (coerce expected 'list)
              :expected-next next :expected-token token :cold-values cold-values
              :cold-value-count (length cold-values) :start 2 :end end
              :private-preallocated-buffer t :complete-output-checked-per-call t
              :samples samples)))))

(defun main ()
  "Report anche sul fallimento; zero heap richiesto senza soglie di velocità o scaling."
  (let* ((args (rest sb-ext:*posix-argv*))
         (report (list :schema-version 1 :kind :cbor-simple-write-benchmark :status :running :campaigns nil
                       :source-fingerprints-before *before* :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :os (software-type) :os-version (software-version) :workers 1 :safety 3
                       :timer-units-per-second internal-time-units-per-second
                       :limits '(:success-path-only :serial :preallocated-private-buffers
                                 :simple-values-major-7-only :wire-code-without-application-semantics
                                 :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                                 :output-check-cost-included :no-pool-or-device-throughput
                                 :no-scaling-or-latency-threshold))))
    (handler-case
        (progn
          (unless (member args '(("--self-test") ("--bench")) :test #'equal)
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (dolist (fixture '((:simple-0 0 (224) 4800)
                               (:simple-20 20 (244) 4860)
                               (:simple-22 22 (246) 4866)
                               (:simple-23 23 (247) 4869)
                               (:simple-32 32 (248 32) 5661)
                               (:simple-255 255 (248 255) 6553)))
              (setf (getf report :campaigns)
                    (append (getf report :campaigns) (list (apply #'campaign fixture)))))
            (dolist (entry (getf report :campaigns))
              (check-zero-heap (getf entry :samples))))
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
