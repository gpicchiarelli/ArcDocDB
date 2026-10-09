;;;; Header dei log: oracoli manuali indipendenti dal codec e dai suoi offset.
(in-package #:arcdocdb.storage.tests)

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defun log-header-identity-fixture ()
  "Identità di 16 byte con zero, bit alti e valori diversi per ogni posizione."
  (bytes #x80 #xff #xa5 #x00 #x11 #x22 #x33 #x44
         #x55 #x66 #x77 #x88 #x99 #xaa #xbb #xcc))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defun log-header-oracle (kind version identity)
  "Header di 64 byte costruito da ASCII, packing manuale e CRC bitwise."
  (let ((buffer (zeros 64))
        (magic (ecase kind (:control "ARCDCTL1") (:multiserie "ARCDMSL1"))))
    (loop for char across magic for i from 0
          do (setf (aref buffer i) (char-code char)))
    (pack-le buffer 8 version 2)
    (replace buffer identity :start1 16 :end1 32)
    (pack-le buffer 56 (reference-crc buffer 0 56) 4)
    buffer))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defun log-header-fixture (kind &key (version 2) (prefix 7))
  "Fixture prodotta solo dall'oracolo, con sentinelle prima e dopo l'header."
  (let* ((identity (log-header-identity-fixture))
         (end (+ prefix 64))
         (buffer (make-array (+ end 9) :element-type '(unsigned-byte 8)
                                      :initial-element #xcc)))
    (replace buffer (log-header-oracle kind version identity) :start1 prefix :end1 end)
    (values buffer prefix end identity)))

;;; REQ: REQ-FOR-001
(defun log-header-repair-crc (buffer start)
  "Ricalcola il CRC con l'oracolo per isolare un campo invalido ma integro."
  (pack-le buffer (+ start 56) (reference-crc buffer start (+ start 56)) 4))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-independent-oracle
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (dolist (start '(1 3 7 13 31))
        (let* ((identity (log-header-identity-fixture))
               (identity-before (copy-seq identity))
               (end (+ start 64))
               (buffer (make-array (+ end 9) :element-type '(unsigned-byte 8)
                                            :initial-element #xcc)))
          (is (= end (arcdocdb.storage.format:scrivi-header-log
                      buffer start kind identity :version version)))
          (is (equalp (subseq buffer start end) (log-header-oracle kind version identity)))
          (is (every (lambda (byte) (= byte #xcc)) (subseq buffer 0 start)))
          (is (every (lambda (byte) (= byte #xcc)) (subseq buffer end)))
          (let ((before (copy-seq buffer)))
            (dolist (limit (list end (length buffer)))
              (multiple-value-bind (next actual-version)
                  (arcdocdb.storage.format:verifica-header-log buffer start limit kind identity)
                (is (= next end))
                (is (= actual-version version))))
            (is (equalp buffer before)))
          (is (equalp identity identity-before)))))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-default-version-is-two
  (dolist (kind '(:control :multiserie))
    (let ((buffer (zeros 64)) (identity (log-header-identity-fixture)))
      (is (= 64 (arcdocdb.storage.format:scrivi-header-log buffer 0 kind identity)))
      (is (equalp buffer (log-header-oracle kind 2 identity)))
      (multiple-value-bind (next version)
          (arcdocdb.storage.format:verifica-header-log buffer 0 64 kind identity)
        (is (= 64 next)) (is (= 2 version))))))

;;; REQ: REQ-FOR-001
(deftest test-REQ-FOR-001-log-header-all-truncations
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end identity) (log-header-fixture kind :version version)
        (let ((before (copy-seq buffer)))
          (loop for limit from start below end
                do (signals corruption-detected
                            (arcdocdb.storage.format:verifica-header-log
                             buffer start limit kind identity)
                            :log-header-truncated))
          (is (equalp buffer before)))))))

;;; REQ: REQ-FOR-001
(deftest test-REQ-FOR-001-log-header-all-bit-flips
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end identity) (log-header-fixture kind :version version)
        (loop for pos from start below end
              do (dotimes (bit 8)
                   (let* ((copy (copy-seq buffer))
                          (mask (ash 1 bit)))
                     (setf (aref copy pos) (logxor mask (aref copy pos)))
                     (let ((before (copy-seq copy)))
                       (signals corruption-detected
                                (arcdocdb.storage.format:verifica-header-log
                                 copy start end kind identity))
                       (is (equalp copy before))))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-every-reserved-byte
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end identity) (log-header-fixture kind :version version)
        (dolist (range '((10 16) (32 56) (60 64)))
          (loop for offset from (first range) below (second range)
                do (let ((copy (copy-seq buffer)))
                     (setf (aref copy (+ start offset)) #xff)
                     (log-header-repair-crc copy start)
                     (let ((before (copy-seq copy)))
                       (signals corruption-detected
                                (arcdocdb.storage.format:verifica-header-log
                                 copy start end kind identity)
                                :log-reserved)
                       (is (equalp copy before))))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-every-identity-byte
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end identity) (log-header-fixture kind :version version)
        (let ((before (copy-seq buffer)) (identity-before (copy-seq identity)))
          (dotimes (i 16)
            (let ((wrong (copy-seq identity)))
              (setf (aref wrong i) (logxor 1 (aref wrong i)))
              (let ((wrong-before (copy-seq wrong)))
                (signals corruption-detected
                         (arcdocdb.storage.format:verifica-header-log
                          buffer start end kind wrong)
                         :log-identity)
                (is (equalp wrong wrong-before)))))
          (is (equalp buffer before))
          (is (equalp identity identity-before)))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-crc-valid-wrong-magic
  (dolist (kind '(:control :multiserie))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end identity) (log-header-fixture kind :version version)
        (dolist (offset '(0 4))
          (let ((copy (copy-seq buffer)))
            (setf (aref copy (+ start offset)) (logxor 1 (aref copy (+ start offset))))
            (log-header-repair-crc copy start)
            (signals corruption-detected
                     (arcdocdb.storage.format:verifica-header-log copy start end kind identity)
                     :log-magic)))
        (signals corruption-detected
                 (arcdocdb.storage.format:verifica-header-log
                  buffer start end (if (eq kind :control) :multiserie :control) identity)
                 :log-magic)
        (let ((copy (copy-seq buffer)))
          (loop for char across "ARCDSEG1" for offset from start
                do (setf (aref copy offset) (char-code char)))
          (log-header-repair-crc copy start)
          (signals corruption-detected
                   (arcdocdb.storage.format:verifica-header-log copy start end kind identity)
                   :log-magic))))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-unknown-version-with-valid-crc
  (dolist (kind '(:control :multiserie))
    (multiple-value-bind (buffer start end identity) (log-header-fixture kind)
      (dolist (version '(0 3 65535))
        (let ((copy (copy-seq buffer)))
          (pack-le copy (+ start 8) version 2)
          (log-header-repair-crc copy start)
          (let ((before (copy-seq copy)))
            (signals unsupported-format
                     (arcdocdb.storage.format:verifica-header-log copy start end kind identity))
            (is (equalp copy before))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-001-log-header-crc-before-unknown-version
  (dolist (kind '(:control :multiserie))
    (multiple-value-bind (buffer start end identity) (log-header-fixture kind)
      (dolist (version '(0 3 65535))
        (let ((copy (copy-seq buffer)))
          (pack-le copy (+ start 8) version 2)
          (log-header-repair-crc copy start)
          (setf (aref copy (+ start 56)) (logxor 1 (aref copy (+ start 56))))
          (signals corruption-detected
                   (arcdocdb.storage.format:verifica-header-log copy start end kind identity)
                   :log-header-crc))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-encoder-preflight-preserves-buffer
  (dolist (kind '(:control :multiserie))
    (let* ((identity (log-header-identity-fixture))
           (identity-before (copy-seq identity))
           (buffer (make-array 80 :element-type '(unsigned-byte 8) :initial-element #xcc))
           (before (copy-seq buffer)))
      (dolist (version '(0 3 65535))
        (signals unsupported-format
                 (arcdocdb.storage.format:scrivi-header-log buffer 7 kind identity :version version))
        (is (equalp buffer before)))
      (dolist (wrong-kind '(:unknown :segment))
        (signals invalid-argument
                 (arcdocdb.storage.format:scrivi-header-log buffer 7 wrong-kind identity)
                 :log-kind)
        (is (equalp buffer before)))
      (dolist (length '(0 15 17))
        (signals invalid-argument
                 (arcdocdb.storage.format:scrivi-header-log buffer 7 kind (zeros length))
                 :log-identity-length)
        (is (equalp buffer before)))
      (dolist (start '(17 80 81))
        (signals invalid-argument
                 (arcdocdb.storage.format:scrivi-header-log buffer start kind identity))
        (is (equalp buffer before)))
      (let* ((short (make-array 63 :element-type '(unsigned-byte 8) :initial-element #xcc))
             (short-before (copy-seq short)))
        (signals invalid-argument
                 (arcdocdb.storage.format:scrivi-header-log short 0 kind identity))
        (is (equalp short short-before)))
      (let* ((alias (copy-seq identity)) (alias-before (copy-seq alias)))
        (signals invalid-argument
                 (arcdocdb.storage.format:scrivi-header-log alias 0 kind alias)
                 :input-alias)
        (is (equalp alias alias-before)))
      (is (equalp identity identity-before)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-log-header-reader-preflight
  (dolist (kind '(:control :multiserie))
    (multiple-value-bind (buffer start end identity) (log-header-fixture kind)
      (let ((before (copy-seq buffer)))
        (dolist (wrong-kind '(:unknown :segment))
          (signals invalid-argument
                   (arcdocdb.storage.format:verifica-header-log buffer start end wrong-kind identity)
                   :log-kind))
        (dolist (length '(0 15 17))
          (signals invalid-argument
                   (arcdocdb.storage.format:verifica-header-log buffer start end kind (zeros length))
                   :log-identity-length))
        (signals invalid-argument
                 (arcdocdb.storage.format:verifica-header-log buffer (1+ end) end kind identity))
        (signals invalid-argument
                 (arcdocdb.storage.format:verifica-header-log
                  buffer start (1+ (length buffer)) kind identity))
        (is (equalp buffer before))))))
