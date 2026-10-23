;;; OWNER: inizializzazione del sistema, prima di ammettere reader/writer.
;;; SHARED: dopo il load, kernel e backend immutati; soltanto letture per richiesta.
(in-package #:arcdocdb.binary)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-AFF-004
#+arcdocdb-crc32c-arm64
(declaim (ftype (function (octets index index &optional u32) (values u32 &optional)) crc32c-arm64))
#+arcdocdb-crc32c-arm64
(defun crc32c-arm64 (buffer start end &optional (seed 0))
  "Pre: CPU CRC32C qualificata dal selettore cold, vettore Lisp stabile e span valido.
Post: checksum finalizzato compatibile col software e incrementale; buffer immutato.
INVALID-ARGUMENT prima dei load se span invalido; bounds check SB-SIMD/aref sempre attivi."
  (declare (type octets buffer) (type index start end) (type u32 seed)
           (optimize (speed 3) (safety 3)))
  (check-range buffer start end)
  (assert (<= 0 start end (length buffer)))
  (let ((crc (logxor seed #xffffffff)) (cursor start))
    (declare (type u32 crc) (type index cursor))
    (dotimes (block (floor (- end start) 16))
      (multiple-value-bind (low high)
          (sb-simd-neon:u64.2-values
           (sb-simd-neon:u64.2! (sb-simd-neon:u8.16-aref buffer cursor)))
        (setf crc (%crc32c-word (%crc32c-word crc low) high)))
      (incf cursor 16))
    (assert (<= 0 (- end cursor) 15))
    (loop for position from cursor below end
          do (setf crc (%crc32c-byte crc (aref buffer position))))
    (logxor crc #xffffffff)))

;;; REQ: REQ-FOR-003 REQ-AFF-002
#+arcdocdb-crc32c-arm64
(when (eq :arm64-crc32c
          (scegli-backend-crc32c
           (arcdocdb.io.cpu::compilatore-crc32c-qualificato-p
            *features* (lisp-implementation-version))
           (arcdocdb.io.cpu:crc32c-disponibile-p)
           (sb-simd-internals:instruction-set-case (:neon t) (() nil))))
  (setf +crc32c-kernel+ #'crc32c-arm64 +crc32c-backend+ :arm64-crc32c))
