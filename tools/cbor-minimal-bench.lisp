;;;; Misure seriali del lettore delle testate CBOR minime; buffer preallocati e nessun I/O nella misura.
;;;; Uso: --self-test oppure --bench; metodo cbor-minimo-metodo.md.
;;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.cbor-minimal.bench (:use #:cl))
(in-package #:arcdocdb.cbor-minimal.bench)
(declaim (optimize (safety 3) (debug 2)))
(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra prodotto e driver; il confronto verifica stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/cbor-minimal-bench.lisp")
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
      (write (list :schema-version 1 :kind :cbor-minimal-benchmark :status :failed
                   :phase :load-product :diagnostic (princ-to-string condition)
                   :source-fingerprints-before *before* :source-fingerprints-after (fingerprints))
             :pretty t)
      (terpri))
    (sb-ext:exit :code 1)))

(defun expected-sink (iterations token)
  "Somma indipendente dei conteggi attesi e degli indici delle invocazioni."
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample (function iterations token &key (warmup +warmup+))
  "Warmup e GC sono fuori da heap/clock; il risultato deve alimentare il sink atteso."
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error "Parametri benchmark CBOR fuori budget."))
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

(defun self-test ()
  "Baseline nulla e controllo positivo 16 × 1 MiB, con oggetto vivo e sink verificato."
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

(defun return-token (major ai high low next form)
  "Tutti i sei valori alimentano un fixnum osservabile, senza materializzare u64."
  (+ major (* 8 ai) (* 256 high) (* 65536 low) (* 1048576 next)
     (* 16777216 (ecase form (:argument 1) (:indefinite 2) (:break 3)))))

(defun campaign (name pattern expected token)
  "Costanti indipendenti per sei valori; input e sentinelle restano immutabili."
  (let* ((size (length pattern))
         (buffer (make-array (+ size 4) :element-type '(unsigned-byte 8) :initial-element 165))
         (end (+ size 2)))
    (replace buffer pattern :start1 2)
    (let* ((original (copy-seq buffer))
           (function (lambda ()
                       (multiple-value-bind (major ai high low next form)
                           (arcdocdb.cbor:leggi-header-cbor-minimo buffer 2 end)
                         (unless (and (= major (first expected)) (= ai (second expected))
                                      (= high (third expected)) (= low (fourth expected))
                                      (= next (fifth expected)) (eq form (sixth expected)))
                           (error "Sei valori CBOR diversi dalla fixture indipendente."))
                         (return-token major ai high low next form))))
           (samples (loop repeat +replicas+ collect (sample function +iterations+ token))))
      (unless (equalp original buffer) (error "Buffer CBOR modificato dal prodotto."))
      (list :name name :unit pattern :expected-values expected :expected-token token
            :start 2 :end end :input-unchanged t :samples samples))))

(defun main ()
  "Report anche sul fallimento; zero heap richiesto senza criteri di velocità o scaling."
  (let* ((args (rest sb-ext:*posix-argv*))
         (report (list :schema-version 1 :kind :cbor-minimal-benchmark :status :running
                       :source-fingerprints-before *before* :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :os (software-type) :os-version (software-version) :workers 1 :safety 3
                       :timer-units-per-second internal-time-units-per-second
                       :limits '(:minimum-header-width-only :success-path-only :serial :preallocated-inputs :no-payload-or-float-decode
                                 :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                                 :no-document-map-key-or-tag-profile :no-pool-or-device-throughput :no-scaling-or-latency-threshold))))
    (handler-case
        (progn
          (unless (member args '(("--self-test") ("--bench")) :test #'equal)
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (setf (getf report :campaigns)
                  (loop for (name pattern expected token) in
                        '((:u64-maximum (27 255 255 255 255 255 255 255 255) (0 27 4294967295 4294967295 11 :argument) 282574516584408)
                          (:float16-payload-nan (249 124 1) (7 25 0 31745 5 :argument) 2102460623)
                          (:float32-finite (250 63 128 0 1) (7 26 0 1065353217 7 :argument) 69819012546775)
                          (:float32-subnormal (250 0 0 0 1) (7 26 0 1 7 :argument) 24182999)
                          (:float32-payload-nan (250 127 128 0 1) (7 26 0 2139095041 7 :argument) 140187756724439)
                          (:float64-finite (251 63 240 0 0 0 0 0 1) (7 27 1072693248 1 11 :argument) 274637848799)
                          (:float64-subnormal (251 0 0 0 0 0 0 0 1) (7 27 0 1 11 :argument) 28377311)
                          (:float64-payload-nan (251 127 240 0 0 0 0 0 1) (7 27 2146435072 1 11 :argument) 549515755743))
                        collect (campaign name pattern expected token)))
            (unless (every (lambda (cell)
                             (every (lambda (entry) (zerop (getf entry :heap-bytes)))
                                    (getf cell :samples))) (getf report :campaigns))
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
