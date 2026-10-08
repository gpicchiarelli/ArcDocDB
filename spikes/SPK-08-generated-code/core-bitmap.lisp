;;;; Campagna finita SPK-08: bitmap in byte e in parole, senza I/O nel ciclo.
;;; REQ: REQ-SIM-001 REQ-SIM-002 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(defpackage #:arcdocdb.spk08.bitmap.campagna
  (:use #:cl)
  (:export #:check #:benchmark))
(in-package #:arcdocdb.spk08.bitmap.campagna)
(declaim (optimize (safety 3) (speed 2) (debug 2)))
(defvar *sentinella-allocazione* nil)

(defun esigi (condizione regola)
  "Segnala un errore dell'oracolo prima di pubblicare un esito positivo."
  (unless condizione (error "SPK-08 bitmap: ~S." regola))
  nil)

(defun disassemblato (funzione)
  "Conserva il testo prodotto da SBCL per la funzione effettivamente usata."
  (let ((*print-readably* nil))
    (with-output-to-string (*standard-output*) (disassemble funzione))))

(defun sensore-allocazione ()
  "Array osservabile di 1 MiB: un delta non positivo fa fallire la campagna."
  (sb-ext:gc :full t)
  (let ((prima (sb-ext:get-bytes-consed)))
    (setf *sentinella-allocazione*
          (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 19))
    (let ((delta (- (sb-ext:get-bytes-consed) prima)))
      (esigi (and (plusp delta) (= 19 (aref *sentinella-allocazione* 1048575)))
              (list :sensore :prima prima :delta delta))
      (list :status :ok :positive-control-payload-bytes 1048576 :bytes-consed delta))))

(defun misura (funzione passaggi atteso)
  "Pre: thunk finito, risultato fixnum. Post: sink verificato e campione grezzo.
GC e report fuori dal ciclo; nessuna sottrazione della baseline o promessa temporale."
  (declare (type function funzione) (type fixnum passaggi atteso))
  (esigi (and (<= 1 passaggi 65536) (<= 0 atteso 524288)) :parametri-misura)
  (dotimes (n 8) (esigi (= atteso (funcall funzione)) :warmup))
  (sb-ext:gc :full t)
  (let* ((sink 0) (prima-byte (sb-ext:get-bytes-consed))
         (inizio (get-internal-real-time)))
    (declare (type fixnum sink))
    (dotimes (n passaggi) (incf sink (the fixnum (funcall funzione))))
    (let* ((fine (get-internal-real-time)) (dopo-byte (sb-ext:get-bytes-consed))
           (ticks (- fine inizio)) (byte (- dopo-byte prima-byte)))
      (esigi (= sink (* atteso passaggi)) :sink)
      (esigi (and (plusp ticks) (>= byte 0)) :clock-e-contatore)
      (list :passes passaggi :expected-result atteso :sink sink
            :start-ticks inizio :end-ticks fine :elapsed-ticks ticks
            :seconds (/ ticks (coerce internal-time-units-per-second 'double-float))
            :bytes-consed byte :bytes-consed-per-pass (/ byte (coerce passaggi 'double-float))))))

(defun check ()
  "Controlla entrambi i kernel; il disassemblato non sostituisce gli oracoli."
  (let ((esito (arcdocdb.spk08.bitmap:check)))
    (esigi (eq (getf esito :status) :ok) :check-kernel)
    (list :status :ok :module :spk08-bitmap :kernels esito
          :disassembly
          (list :bitmap-byte (disassemblato #'arcdocdb.spk08.bitmap:bitmap-byte)
                :bitmap-word (disassemblato #'arcdocdb.spk08.bitmap:bitmap-word)
                :measurement-loop (disassemblato #'misura))
          :scope :scalar-array-kernels-no-engine-integration)))

(defun benchmark ()
  "90 campioni fissi, in serie, sulle stesse bitmap; packing escluso."
  (let ((sensore (sensore-allocazione)) (campioni nil)
        (baseline (misura (lambda () 0) 65536 0)))
    (dolist (bytes '(128 8192 65536))
      (dolist (pattern '(:mixed :zero :ones))
        (multiple-value-bind (a b wa wb atteso)
            (arcdocdb.spk08.bitmap:prepara-bitmap bytes :pattern pattern)
          (let ((varianti (list (cons :byte (lambda () (arcdocdb.spk08.bitmap:bitmap-byte a b)))
                                (cons :word (lambda () (arcdocdb.spk08.bitmap:bitmap-word wa wb)))))
                (copie (mapcar #'copy-seq (list a b wa wb)))
                (passaggi (/ (* 16 1024 1024) (* 2 bytes))))
            (dotimes (replica 5)
              (dolist (variante (if (evenp replica) varianti (reverse varianti)))
                (let* ((mesure (misura (cdr variante) passaggi atteso))
                       (secondi (getf mesure :seconds)) (trattati (* passaggi 2 bytes)))
                  (push (append (list :variant (car variante) :pattern pattern :replica replica
                                      :bytes-per-bitmap bytes :processed-input-bytes trattati
                                      :input-mib-per-second (/ trattati (* 1048576d0 secondi)))
                                mesure) campioni))))
            (esigi (every #'equalp copie (list a b wa wb)) :input-immutati)))))
    (esigi (= 90 (length campioni)) :matrice-completa)
    (list :status :ok :module :spk08-bitmap :sample-count 90
          :samples (nreverse campioni) :allocation-sensor sensore :empty-call-baseline baseline
          :parameters (list :bytes-per-bitmap '(128 8192 65536) :patterns '(:mixed :zero :ones)
                            :replicas 5 :warmup-passes 8 :input-bytes-per-sample (* 16 1024 1024)
                            :clock-ticks-per-second internal-time-units-per-second
                            :packing :outside-measurement :baseline-subtracted nil)
          :limits '(:local-small-array :uncontrolled-cache-and-external-load
                    :no-x86-measurement :no-engine-or-concurrency :no-simd-loop-claim
                    :zero-allocation-is-an-observation))))
