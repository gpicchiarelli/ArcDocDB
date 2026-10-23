;;;; C4: varianti isolate, nessuna modifica al kernel di prodotto.
;;; REQ: REQ-FOR-003 REQ-SIM-001 REQ-VAL-001
(defpackage #:arcdocdb.spk08.crc32c32
  (:use #:cl) (:local-nicknames (#:b #:arcdocdb.binary))
  (:export #:crc32-byte-tail #:crc32-word-tail))
(in-package #:arcdocdb.spk08.crc32c32)
(declaim (optimize (speed 3) (safety 3) (debug 2)))

#+arcdocdb-crc32c-arm64
(sb-c:defknown crc-four (b::u32 b::u32) b::u32 (sb-c:flushable sb-c:movable))
#+arcdocdb-crc32c-arm64
(sb-c:define-vop (crc-four)
  (:translate crc-four) (:policy :fast-safe)
  (:args (crc :scs (sb-vm::unsigned-reg)) (value :scs (sb-vm::unsigned-reg)))
  (:arg-types sb-vm::unsigned-num sb-vm::unsigned-num)
  (:results (result :scs (sb-vm::unsigned-reg))) (:result-types sb-vm::unsigned-num)
  (:generator 1
    (let ((rd (sb-c:tn-offset result)) (rn (sb-c:tn-offset crc)) (rm (sb-c:tn-offset value)))
      (assert (and (<= 0 rd 30) (<= 0 rn 31) (<= 0 rm 31)))
      (let ((word (logior #x1ac05800 rd (ash rn 5) (ash rm 16))))
        (dotimes (i 4) (sb-assem:inst sb-arm64-asm::byte (ldb (byte 8 (* i 8)) word)))))))

;;; C4: la macro elimina soltanto la duplicazione del kernel tra le due code.
(defmacro define-variant (name word-tail-p)
  `(defun ,name (buffer start end &optional (seed 0))
     (declare (type b::octets buffer) (type b::index start end) (type b::u32 seed))
     (b::check-range buffer start end)
     (assert (<= 0 start end (length buffer)))
     (let ((crc (logxor seed #xffffffff)) (cursor start))
       (declare (type b::u32 crc) (type b::index cursor))
       (macrolet ((consume (offset)
                    `(multiple-value-bind (low high)
                         (sb-simd-neon:u64.2-values
                          (sb-simd-neon:u64.2! (sb-simd-neon:u8.16-aref buffer ,offset)))
                       (setf crc (b::%crc32c-word (b::%crc32c-word crc low) high)))))
         (dotimes (block (floor (- end start) 32))
           (consume cursor) (consume (+ cursor 16)) (incf cursor 32)))
       ,@(when word-tail-p
           '((dotimes (block (floor (- end cursor) 4))
               (setf crc (crc-four crc (b::leggi-u32 buffer cursor))) (incf cursor 4))))
       (assert (<= 0 (- end cursor) ,(if word-tail-p 3 31)))
       (loop for position from cursor below end
             do (setf crc (b::%crc32c-byte crc (aref buffer position))))
       (logxor crc #xffffffff))))

#+arcdocdb-crc32c-arm64
(define-variant crc32-byte-tail nil)
#+arcdocdb-crc32c-arm64
(define-variant crc32-word-tail t)
