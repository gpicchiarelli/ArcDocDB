;;;; Misure seriali dello scanner CBOR; input e scratch preallocati per fixture.
;;;; Uso: --self-test oppure --bench; warmup 128, 4096 chiamate × 5 repliche.
;;;; Prereg: otto fixture piccole, start2, nessuna stringa/container indefinito.
;;;; Nodi/profondita/end fissati nel catalogo, conteggiati a mano dai byte seguenti.
;;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.cbor-minimal-scan.bench (:use #:cl))
(in-package #:arcdocdb.cbor-minimal-scan.bench)
(declaim (optimize (safety 3) (debug 2)))
(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  "Registra prodotto e driver; il confronto verifica stabilità, non autenticità."
  (loop for path in (append '(#p"arcdocdb.asd" #p"tools/cbor-minimal-scan-bench.lisp")
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
      (write (list :schema-version 1 :kind :cbor-minimal-scan-benchmark :status :failed
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
    (error "Parametri benchmark struttura CBOR fuori budget."))
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

(defun return-token (nodes depth next)
  "Tutti i tre valori alimentano un fixnum osservabile; nessun u64 materializzato."
  (+ nodes (* 65536 depth) (* 16777216 next)))

(defun fixture-pattern (name)
  "Costruzione fredda da byte e lunghezze fissati prima delle campagne."
  (ecase name
    (:u64-maximum (make-array 9 :element-type '(unsigned-byte 8)
                              :initial-contents '(27 255 255 255 255 255 255 255 255)))
    (:arrays-100
     (let ((pattern (make-array 100 :element-type '(unsigned-byte 8) :initial-element 129)))
       (setf (aref pattern 99) 128)
       pattern))
    (:mixed
     (make-array 17 :element-type '(unsigned-byte 8)
                    :initial-contents '(132 1 161 97 97 192 2 66 0 255 102 195 169 240 159 153 130)))
    (:text-nul-unicode
     (make-array 8 :element-type '(unsigned-byte 8)
                   :initial-contents '(103 0 195 169 240 159 153 130)))
    (:bytes-16
     (make-array 17 :element-type '(unsigned-byte 8)
                    :initial-contents '(80 0 255 192 128 0 1 2 3 4 5 6 7 8 9 10 11)))
    (:floats-array
     (make-array 18 :element-type '(unsigned-byte 8)
                    :initial-contents '(131 249 124 1 250 63 128 0 1
                                        251 63 240 0 0 0 0 0 1)))
    (:array-64
     (let ((pattern (make-array 66 :element-type '(unsigned-byte 8) :initial-element 0)))
       (setf (aref pattern 0) 152 (aref pattern 1) 64)
       pattern))
    (:tags-64
     (let ((pattern (make-array 65 :element-type '(unsigned-byte 8) :initial-element 192)))
       (setf (aref pattern 64) 0)
       pattern))))

(defun campaign (name expected token)
  "Verifica tre costanti indipendenti; riusa soltanto lo scratch privato della fixture."
  (let* ((pattern (fixture-pattern name)) (size (length pattern))
         (buffer (make-array (+ size 4) :element-type '(unsigned-byte 8) :initial-element 165))
         (end (+ size 2)) (space (arcdocdb.cbor:crea-spazio-cbor)))
    (replace buffer pattern :start1 2)
    (let* ((original (copy-seq buffer))
           (function (lambda ()
                       (multiple-value-bind (nodes depth next)
                           (arcdocdb.cbor:verifica-struttura-cbor-minima buffer 2 end space)
                         (unless (and (= nodes (first expected)) (= depth (second expected))
                                      (= next (third expected)))
                           (error "Tre valori CBOR diversi dalla fixture indipendente."))
                         (return-token nodes depth next))))
           (samples (loop repeat +replicas+ collect (sample function +iterations+ token))))
      (unless (equalp original buffer) (error "Buffer CBOR modificato dal prodotto."))
      (list :name name :unit-bytes size :expected-values expected :expected-token token
            :start 2 :end end :private-preallocated-space t :input-unchanged t :samples samples))))

(defun main ()
  "Report anche sul fallimento; zero heap richiesto senza soglie di velocità o scaling."
  (let* ((args (rest sb-ext:*posix-argv*))
         (report (list :schema-version 1 :kind :cbor-minimal-scan-benchmark :status :running
                       :source-fingerprints-before *before* :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :os (software-type) :os-version (software-version) :workers 1 :safety 3
                       :timer-units-per-second internal-time-units-per-second
                       :limits '(:success-path-only :serial :preallocated-inputs-and-scratch
                                 :minimal-header-and-structure-only :no-materialized-document-or-float
                                 :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                                 :no-pool-or-device-throughput :no-scaling-or-latency-threshold))))
    (handler-case
        (progn
          (unless (member args '(("--self-test") ("--bench")) :test #'equal)
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (setf (getf report :campaigns)
                  (loop for (name expected token) in
                        '((:u64-maximum (1 0 11) 184549377)
                          (:arrays-100 (100 100 102) 1717829732)
                          (:tags-64 (65 0 67) 1124073537)
                          (:text-nul-unicode (1 0 10) 167772161)
                          (:bytes-16 (1 0 19) 318767105)
                          (:mixed (8 2 19) 318898184)
                          (:floats-array (4 1 20) 335609860)
                          (:array-64 (65 1 68) 1140916289))
                        collect (campaign name expected token)))
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
