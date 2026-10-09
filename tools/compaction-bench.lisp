;;;; Verifica seriale di segmenti compattati in memoria; nessun I/O nel ciclo misurato.
;;;; Uso: --self-test oppure --bench; metodo segmenti-compattati-metodo.md.
;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-CMP-009 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.compaction.bench (:use #:cl))
(in-package #:arcdocdb.compaction.bench)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +iterazioni+ 4096)
(defconstant +warmup+ 128)
(defconstant +repliche+ 5)

(defun octets (n)
  "Crea un buffer esclusivo fuori dal periodo misurato."
  (make-array n :element-type '(unsigned-byte 8) :initial-element 0))

(defun fingerprints ()
  "Fotografa ASD, fondazioni, storage e driver; MD5 verifica stabilità, non autenticità."
  (loop for file in (append '(#p"arcdocdb.asd" #p"tools/compaction-bench.lisp")
                           (sort (append (directory "src/foundation/*.lisp")
                                         (directory "src/storage/*.lisp"))
                                 #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun load-product ()
  "Carica il prodotto con avvisi fatali prima di leggere i riferimenti qualificati."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condizione) (error condizione))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb"))))

(defparameter *source-before* (fingerprints))
(handler-case (load-product)
  (error (condizione)
    (let ((after (fingerprints)) (*print-readably* t))
      (write (list :schema-version 1 :kind :compaction-benchmark :status :failed
                   :phase :load-product :diagnostic (princ-to-string condizione)
                   :source-fingerprints-before *source-before* :source-fingerprints-after after
                   :source-consistency (if (equal *source-before* after) :stable :changed)) :pretty t)
      (terpri))
    (sb-ext:exit :code 1)))

(defun return-token (end version count puts tombstones)
  "Consuma tutte le cinque risposte come somma pesata fixnum osservabile."
  (+ end (* 3 version) (* 5 count) (* 7 puts) (* 11 tombstones)))

(defun expected-sink (iterazioni token)
  "Oracolo del sink: N×token + somma degli indici, dopo eventuale maschera fixnum."
  (logand most-positive-fixnum (+ (* iterazioni token) (/ (* iterazioni (1- iterazioni)) 2))))

(defun sample (funzione iterazioni bytes token &key (warmup +warmup+))
  "Warmup e GC precedono i contatori; sink confrontato dopo la misura con atteso esplicito."
  (unless (and (typep iterazioni '(integer 1 4096)) (typep warmup '(integer 0 128))
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error "Benchmark compaction: parametri fuori budget."))
  (dotimes (i (min iterazioni warmup)) (funcall funzione))
  (sb-ext:gc :full t)
  (let* ((inizio (get-internal-real-time)) (prima (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i iterazioni)
      (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall funzione))))))
    (let* ((allocati (- (sb-ext:get-bytes-consed) prima))
           (ticks (- (get-internal-real-time) inizio))
           (secondi (/ ticks (float internal-time-units-per-second 1d0)))
           (atteso (expected-sink iterazioni token)))
      (unless (and (>= allocati 0) (>= ticks 0) (= sink atteso))
        (error "Benchmark compaction: contatore/clock invalido o sink ~D diverso da ~D." sink atteso))
      (list :iterations iterazioni :warmup-iterations (min iterazioni warmup)
            :bytes-per-operation bytes :seconds secondi :raw-ticks ticks
            :heap-bytes allocati :sink sink :expected-sink atteso :expected-return-token token
            :operations-per-second (when (plusp secondi) (/ iterazioni secondi))))))

(defun self-test ()
  "Baseline di 4.096 chiamate vuote e controllo positivo 16×1 MiB, con sink verificati."
  (let ((baseline (sample (lambda () 0) 4096 0 0)) (probe nil))
    (unless (zerop (getf baseline :heap-bytes))
      (error "Benchmark compaction: baseline del contatore non zero."))
    (let ((positivo (sample (lambda () (setf probe (octets 1048576)) (length probe))
                            16 1048576 1048576 :warmup 0)))
      (unless (and (= (length probe) 1048576) (>= (getf positivo :heap-bytes) (* 16 1048576)))
        (error "Benchmark compaction: allocazioni deliberate non rilevate."))
      (list :status :ok :baseline baseline :positive-control positivo))))

(defun fixture (version count)
  "Encoder del prodotto solo in preparazione; header64 e 0/256 record PUT/TOMBSTONE alternati.
CSN e segment-id u64 massimi, PUT con flag contratto-versionato e payload sintetico."
  (unless (and (member version '(1 2)) (member count '(0 256)))
    (error "Benchmark compaction: fixture non prevista dal metodo."))
  (let* ((puts (/ count 2)) (tombstones (- count puts))
         (bytes (+ arcdocdb.storage.format:+segment-header-bytes+
                   (* count (+ arcdocdb.record:+header-bytes+ 3)) (* puts 17)))
         (buffer (octets bytes)) (id (octets 16)) (key (octets 3))
         (value (octets 17)) (empty (octets 0)))
    (dotimes (i 16) (setf (aref id i) (mod (+ 128 (* i 17)) 256)))
    (dotimes (i 17) (setf (aref value i) (mod (+ 129 (* i 29)) 256)))
    (let ((pos (arcdocdb.storage.format:scrivi-header-segmento
                buffer 0 id #xffffffffffffffff #xffffffffffffffff :version version :origine 2)))
      (dotimes (i count)
        (setf (aref key 0) 128 (aref key 1) (ldb (byte 8 0) i) (aref key 2) 255)
        (setf pos (arcdocdb.record:scrivi-record
                   buffer pos (if (evenp i) arcdocdb.record:+put+ arcdocdb.record:+tombstone+)
                   #xffffffffffffffff key (if (evenp i) value empty)
                   :version version :flags (if (evenp i) 4 0))))
      (unless (= pos bytes) (error "Benchmark compaction: dimensione fixture incoerente.")))
    (values buffer id bytes puts tombstones)))

(defun campaign (version count)
  "Cinque repliche del verificatore; solo buffer e identità preallocati nel ciclo."
  (multiple-value-bind (buffer id bytes puts tombstones) (fixture version count)
    (let ((token (return-token bytes version count puts tombstones)))
      (list :version version :records count :puts puts :tombstones tombstones :file-bytes bytes
            :expected-return-values (list bytes version count puts tombstones)
            :return-value-weights '(1 3 5 7 11)
            :samples
            (loop repeat +repliche+
                  collect (sample (lambda ()
                                    (multiple-value-bind (end actual-version actual-count actual-puts actual-tombs)
                                        (arcdocdb.storage.format:verifica-segmento-compattato
                                         buffer bytes id #xffffffffffffffff)
                                      (return-token end actual-version actual-count actual-puts actual-tombs)))
                                  +iterazioni+ bytes token))))))

(defun main ()
  "Stampa una plist anche su errore; nessun criterio temporale, zero heap misurato richiesto."
  (let* ((args (rest sb-ext:*posix-argv*)) (before *source-before*)
         (report (list :schema-version 1 :kind :compaction-benchmark :status :running
                       :source-fingerprints-before before :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :cpu (machine-version) :os (software-type) :os-version (software-version)
                       :workers 1 :safety 3 :timer-units-per-second internal-time-units-per-second
                       :sink-rule :sum-weighted-return-values-and-iteration-index
                       :limits '(:memory-verifier-only :product-encoder-outside-measurements
                                 :synthetic-payload-not-cbor :counter-not-absolute-nonallocation-proof
                                 :no-io-in-measured-loop :no-durability :no-concurrency
                                 :no-throughput-threshold :external-load-uncontrolled))))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test")) (equal args '("--bench")))
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (setf (getf report :campaigns)
                  (loop for version in '(1 2) append
                        (loop for count in '(0 256) collect (campaign version count))))
            (unless (and (= 4 (length (getf report :campaigns)))
                         (every (lambda (campaign)
                                  (every (lambda (sample) (zerop (getf sample :heap-bytes)))
                                         (getf campaign :samples)))
                                (getf report :campaigns)))
              (error "Benchmark compaction: criterio zero heap non soddisfatto.")))
          (setf (getf report :status) :ok))
      (error (condizione) (setf (getf report :status) :failed
                               (getf report :diagnostic) (princ-to-string condizione))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed)))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
