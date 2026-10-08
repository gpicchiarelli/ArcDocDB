;;;; Diagnostica C4: separa generazione, hash e lookup su una chiave fissa.
;;; REQ: REQ-VAL-001 REQ-BEN-001 REQ-BEN-002
(in-package #:arcdocdb.spk01)
(declaim (optimize (speed 3) (safety 3) (debug 1)))

(defun misura-profilo (nome funzione)
  "Misura un milione di chiamate dopo warmup e GC fuori dalla finestra."
  (funcall funzione 10000)
  (sb-ext:gc :full t)
  (let ((before (sb-ext:get-bytes-consed)) (start (get-internal-real-time)))
    (let* ((sink (funcall funzione 1000000))
           (bytes (- (sb-ext:get-bytes-consed) before))
           (wall (secondi (- (get-internal-real-time) start))))
      (list :case nome :operations 1000000 :warmup-operations 10000
            :wall-seconds wall :allocation-bytes bytes
            :allocation-bytes-per-operation (/ bytes 1000000d0) :sink sink))))

(defun profile ()
  "Attribuisce il residuo a tre percorsi separati; non prova assenza di allocazioni."
  (let* ((buffer (make-array 16 :element-type '(unsigned-byte 8)))
         (out (make-array 1 :element-type '(unsigned-byte 64)))
         (idx (make-indice)))
    (scrivi-chiave buffer 0) (inserisci-pattern idx buffer 1)
    (list :spike :spk-01 :status :ok :kind :allocation-profile
          :parameters '(:capacity 8192 :words 4 :fixed-id 0 :safety 3 :reader-speed 2)
          :cases
          (list
           (misura-profilo :key-generation
             (lambda (n)
               (dotimes (s n) (scrivi-chiave buffer (mod s 100000)))
               (aref buffer 0)))
           (misura-profilo :hash-to-u64-array
             (lambda (n)
               (dotimes (s n) (setf (aref out 0) (hash-chiave buffer 0)))
               (aref out 0)))
           (progn
             (scrivi-chiave buffer 0)
             (misura-profilo :lookup-fixed-key
               (lambda (n)
                 (let ((sink 0))
                   (dotimes (s n sink)
                     (setf sink (nth-value 0 (leggi idx buffer)))))))))
          :limits '(:single-key :process-allocation-counter
                    :no-zero-allocation-guarantee :no-gc-attribution
                    :no-database-throughput :format-v1))))
