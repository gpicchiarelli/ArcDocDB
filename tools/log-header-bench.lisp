;;;; Misure seriali degli header control/multiserie, senza I/O nel ciclo misurato.
;;;; Uso: --self-test oppure --bench; metodo in docs/implementazione/header-log-metodo.md.
;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.log-header.bench (:use #:cl))
(in-package #:arcdocdb.log-header.bench)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +iterazioni+ 262144)
(defconstant +warmup+ 1024)
(defconstant +repliche+ 5)

(defun octets (n)
  "Crea un buffer esclusivo fuori dal periodo misurato."
  (make-array n :element-type '(unsigned-byte 8) :initial-element 0))

(defun fingerprints ()
  "Fotografa ASD, fondazioni, storage e driver; MD5 verifica stabilità, non autenticità."
  (loop for file in (append '(#p"arcdocdb.asd" #p"tools/log-header-bench.lisp")
                           (sort (append (directory "src/foundation/*.lisp")
                                         (directory "src/storage/*.lisp"))
                                 #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun load-product ()
  "Carica il prodotto con avvisi fatali; eventuali messaggi ASDF vanno a stderr."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condizione) (error condizione))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
      (asdf:load-system "arcdocdb"))))

;;; Il package del codec deve esistere prima di leggere le funzioni delle campagne.
(defparameter *source-before* (fingerprints))
(handler-case (load-product)
  (error (condizione)
    (let ((*print-readably* t))
      (write (list :schema-version 1 :kind :log-header-benchmark :status :failed
                   :phase :load-product :diagnostic (princ-to-string condizione)
                   :source-fingerprints-before *source-before*
                   :source-fingerprints-after (fingerprints)) :pretty t)
      (terpri))
    (sb-ext:exit :code 1)))

(defun sample (funzione iterazioni bytes &key (warmup +warmup+))
  "Warmup e GC precedono i contatori; risultato fixnum osservabile, report costruito dopo."
  (unless (and (typep iterazioni '(integer 1 262144))
               (typep warmup '(integer 0 1024)))
    (error "Benchmark header log: iterazioni o warmup fuori budget."))
  (dotimes (i (min iterazioni warmup)) (funcall funzione))
  (sb-ext:gc :full t)
  (let* ((inizio (get-internal-real-time)) (prima (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i iterazioni)
      (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall funzione))))))
    (let* ((allocati (- (sb-ext:get-bytes-consed) prima))
           (ticks (- (get-internal-real-time) inizio))
           (secondi (/ ticks (float internal-time-units-per-second 1d0))))
      (unless (and (>= allocati 0) (>= ticks 0))
        (error "Benchmark header log: contatore o clock regredito."))
      (list :iterations iterazioni :warmup-iterations (min iterazioni warmup)
            :bytes-per-operation bytes :seconds secondi :raw-ticks ticks
            :heap-bytes allocati :sink sink
            :operations-per-second (when (plusp secondi) (/ iterazioni secondi))))))

(defun self-test ()
  "Baseline nulla e controllo positivo 16×1 MiB; verifica il contatore prima delle campagne."
  (let ((baseline (sample (lambda () 42) 4096 0)) (probe nil))
    (unless (zerop (getf baseline :heap-bytes))
      (error "Benchmark header log: baseline del contatore non zero."))
    (let ((positivo (sample (lambda () (setf probe (octets 1048576)) (length probe))
                            16 1048576 :warmup 0)))
      (unless (and (= (length probe) 1048576) (>= (getf positivo :heap-bytes) (* 16 1048576)))
        (error "Benchmark header log: allocazioni deliberate non rilevate."))
      (list :status :ok :baseline baseline :positive-control positivo))))

(defun campaign (log-kind version operazione funzione)
  "Cinque repliche predefinite dello stesso percorso e degli stessi buffer."
  (list :log-kind log-kind :version version :operation operazione
        :samples (loop repeat +repliche+ collect (sample funzione +iterazioni+ 64))))

(defun campaigns ()
  "Otto campagne: due tipi, due versioni, scrittura e verifica in memoria."
  (loop for log-kind in '(:control :multiserie)
        append (loop for version in '(1 2)
                     append
                     (let ((buffer (octets 79)) (id (octets 16)))
                       (dotimes (i 16) (setf (aref id i) (mod (+ 128 (* i 17)) 256)))
                       (arcdocdb.storage.format:scrivi-header-log buffer 7 log-kind id :version version)
                       (list
                        (campaign log-kind version :write
                                  (lambda () (arcdocdb.storage.format:scrivi-header-log
                                              buffer 7 log-kind id :version version)))
                        (campaign log-kind version :read
                                  (lambda ()
                                    (multiple-value-bind (next actual-version)
                                        (arcdocdb.storage.format:verifica-header-log buffer 7 71 log-kind id)
                                      (+ next actual-version)))))))))

(defun main ()
  "Stampa una plist verificabile anche in caso di errore; exit nonzero per esito invalido."
  (let* ((args (rest sb-ext:*posix-argv*)) (before *source-before*)
         (report (list :schema-version 1 :kind :log-header-benchmark :status :running
                       :source-fingerprints-before before :recorded-at (get-universal-time)
                       :sbcl (lisp-implementation-version) :machine (machine-type)
                       :cpu (machine-version) :os (software-type) :os-version (software-version)
                       :workers 1 :safety 3 :timer-units-per-second internal-time-units-per-second
                       :limits '(:memory-codec-only :counter-does-not-prove-absolute-nonallocation
                                 :no-io-in-measured-loop :no-durability :no-concurrency
                                 :no-performance-threshold :external-load-uncontrolled))))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test")) (equal args '("--bench")))
            (error "Usare --self-test oppure --bench."))
          (setf (getf report :self-test) (self-test))
          (when (equal args '("--bench"))
            (setf (getf report :campaigns) (campaigns))
            (unless (and (= 8 (length (getf report :campaigns)))
                         (every (lambda (campaign)
                                  (every (lambda (sample) (zerop (getf sample :heap-bytes)))
                                         (getf campaign :samples)))
                                (getf report :campaigns)))
              (error "Benchmark header log: criterio zero heap non soddisfatto.")))
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
