(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-AFF-009 REQ-FOR-001
(defun reference-crc-patch (buffer start end patch-start target)
  "Risolve 32 bit di CRC con l'oracolo bitwise; tutti i cicli hanno 32 passi."
  (reference-le buffer patch-start 4 0)
  (let ((baseline (reference-crc buffer start end))
        (vectors (make-array 32 :element-type '(unsigned-byte 32) :initial-element 0))
        (masks (make-array 32 :element-type '(unsigned-byte 32) :initial-element 0)))
    (dotimes (bit 32)
      (reference-le buffer patch-start 4 (ash 1 bit))
      (let ((vector (logxor baseline (reference-crc buffer start end)))
            (mask (ash 1 bit)))
        (loop for row downfrom 31 to 0 when (logbitp row vector) do
          (if (zerop (aref vectors row))
              (progn (setf (aref vectors row) vector (aref masks row) mask) (return))
              (setf vector (logxor vector (aref vectors row))
                    mask (logxor mask (aref masks row)))))))
    (let ((residue (logxor baseline target)) (patch 0))
      (loop for row downfrom 31 to 0 when (logbitp row residue) do
        (is (plusp (aref vectors row)))
        (setf residue (logxor residue (aref vectors row))
              patch (logxor patch (aref masks row))))
      (is (zerop residue))
      (reference-le buffer patch-start 4 patch)
      (is (= target (reference-crc buffer start end))))))

;;; REQ: REQ-AFF-009 REQ-AFF-017 REQ-FOR-001 REQ-FOR-003
(deftest test-REQ-AFF-009-every-bit-before-durable-witness
  (let ((cases 0))
    (dolist (version '(1 2))
      (dolist (entry '((:segment 31) (:control 0) (:multiserie 0)))
        (destructuring-bind (log-kind file-id) entry
          (multiple-value-bind (original start end layouts)
              (log-fixture :version version :log-kind log-kind :file-id file-id)
            (let ((second-start (getf (second layouts) :start))
                  (last-start (getf (third layouts) :start)))
              ;; Ogni byte dei primi due lotti: il terzo SEAL resta integro.
              (loop for pos from start below last-start do
                (dotimes (bit 8)
                  (let ((buffer (copy-seq original)))
                    (setf (aref buffer pos) (logxor (aref buffer pos) (ash 1 bit)))
                    (let* ((before (copy-seq buffer))
                           (p (if (< pos second-start) start second-start))
                           (condition
                             (signals log-corruption
                               (scansiona-log buffer start end file-id
                                 :version version :log-kind log-kind
                                 :file-offset 64 :file-size (+ 64 end))
                               :log-durable-corruption)))
                      (is (= p (corruption-prefix-end condition)))
                      (is (= (+ 64 p) (error-offset condition)))
                      (is (> (corruption-durable-offset condition) (+ 64 p)))
                      (is (equalp buffer before))
                      (incf cases))))))))))
    (is (plusp cases))
    (format t "~D mutazioni bit prima del testimone durevole verificate.~%" cases)))

;;; REQ: REQ-AFF-009 REQ-AFF-017 REQ-FOR-001 REQ-FOR-003
(deftest test-REQ-AFF-017-every-bit-in-final-unwitnessed-batch
  (let ((cases 0))
    (dolist (version '(1 2))
      (dolist (entry '((:segment 31) (:control 0) (:multiserie 0)))
        (destructuring-bind (log-kind file-id) entry
          (multiple-value-bind (original start end layouts)
              (log-fixture :version version :log-kind log-kind :file-id file-id)
            (let ((p (getf (third layouts) :start)))
              ;; Nessun SEAL successivo testimonia il terzo lotto danneggiato.
              (loop for pos from p below end do
                (dotimes (bit 8)
                  (let ((buffer (copy-seq original)))
                    (setf (aref buffer pos) (logxor (aref buffer pos) (ash 1 bit)))
                    (let ((before (copy-seq buffer)))
                      (multiple-value-bind (prefix status batches records)
                          (scansiona-log buffer start end file-id
                            :version version :log-kind log-kind
                            :file-offset 64 :file-size (+ 64 end))
                        (is (= prefix p))
                        (is (eq status :tail))
                        (is (= batches 2))
                        (is (= records 4)))
                      (is (equalp buffer before))
                      (incf cases))))))))))
    (is (plusp cases))
    (format t "~D mutazioni bit nel lotto finale senza testimone verificate.~%" cases)))

;;; REQ: REQ-AFF-009 REQ-FOR-001 REQ-FOR-003
(deftest test-REQ-AFF-009-overlapping-seal-after-noncovering-frontier
  (let* ((start 7) (outer-pos 8) (inner-pos (+ outer-pos 32))
         (file-offset (ash 1 40)) (absolute-p (+ file-offset start))
         (end (+ inner-pos 56))
         (buffer (make-array end :element-type '(unsigned-byte 8) :initial-element 0)))
    ;; SEAL interno a +32 del primo: deve essere trovato anche dopo il primo SEAL valido.
    (setf (aref buffer start) #xcc
          (aref buffer (+ inner-pos 8)) 3)
    (reference-le buffer (+ inner-pos 12) 4 32)
    (reference-le buffer (+ inner-pos 24) 8 31)
    (reference-le buffer (+ inner-pos 32) 8 (+ file-offset inner-pos))
    (reference-le buffer (+ inner-pos 40) 8 (1+ absolute-p))
    ;; Header interno = batch-start esterno. Body-crc e header-crc sono riparati
    ;; indipendentemente, agendo rispettivamente su checksum e stamp del SEAL interno.
    (let ((target-body (ldb (byte 32 32) absolute-p))
          (target-header (ldb (byte 32 0) absolute-p)))
      (reference-crc-patch buffer (+ inner-pos 24) end (+ inner-pos 52) target-body)
      (reference-le buffer (+ inner-pos 4) 4 target-body)
      (reference-crc-patch buffer (+ inner-pos 4) (+ inner-pos 24)
                           (+ inner-pos 20) target-header)
      (reference-le buffer inner-pos 4 target-header))
    (setf (aref buffer (+ outer-pos 8)) 3)
    (reference-le buffer (+ outer-pos 12) 4 32)
    (reference-le buffer (+ outer-pos 24) 8 31)
    (repair-reference-record buffer outer-pos (+ outer-pos 56))
    ;; Il primo SEAL è integro con D<P; il secondo è integro con D=P+1.
    (dolist (pos (list outer-pos inner-pos))
      (multiple-value-bind (next kind)
          (arcdocdb.record:verifica-cornice buffer pos (+ pos 56) :version 2)
        (is (= next (+ pos 56))) (is (= kind 3))))
    (is (= absolute-p (arcdocdb.binary:leggi-u64 buffer (+ outer-pos 32))))
    (is (< (arcdocdb.binary:leggi-u64 buffer (+ outer-pos 40)) absolute-p))
    (let* ((before (copy-seq buffer))
           (condition (signals log-corruption
             (scansiona-log buffer start end 31 :version 2
               :file-offset file-offset :file-size (+ file-offset end)))))
      (is (= start (corruption-prefix-end condition)))
      (is (= (+ file-offset inner-pos) (corruption-witness-offset condition)))
      (is (= (1+ absolute-p) (corruption-durable-offset condition)))
      (is (equalp buffer before)))))
