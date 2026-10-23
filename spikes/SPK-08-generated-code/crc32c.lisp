;;;; Spike C4, non prodotto: CRC32C ARM64 su registri, load SB-SIMD con bounds check.
;;; REQ: REQ-FOR-003 REQ-SIM-001 REQ-VAL-001
(require :asdf)
(require :sb-simd)
(defpackage #:arcdocdb.spk08.crc32c (:use #:cl) (:export #:native-crc #:available-p))
(in-package #:arcdocdb.spk08.crc32c)
(declaim (optimize (safety 3) (speed 3) (debug 1)))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))

(defun available-p ()
  #+(and arm64 darwin)
  (string= "1" (string-trim '(#\Newline #\Space)
                            (uiop:run-program '("/usr/sbin/sysctl" "-n" "hw.optional.armv8_crc32")
                                              :output :string)))
  #-(and arm64 darwin) nil)

#+arm64
(defun emit-crc (opcode result crc value)
  (let ((word (logior opcode (sb-c:tn-offset result)
                     (ash (sb-c:tn-offset crc) 5) (ash (sb-c:tn-offset value) 16))))
    (dotimes (byte 4)
      (sb-assem:inst sb-arm64-asm::byte (ldb (byte 8 (* byte 8)) word)))))

#+arm64
(sb-c:defknown crc-word ((unsigned-byte 32) (unsigned-byte 64)) (unsigned-byte 32)
    (sb-c:foldable sb-c:flushable sb-c:movable))
#+arm64
(sb-c:define-vop (crc-word)
  (:translate crc-word) (:policy :fast-safe)
  (:args (crc :scs (sb-vm::unsigned-reg) :target result) (value :scs (sb-vm::unsigned-reg)))
  (:arg-types sb-vm::unsigned-num sb-vm::unsigned-num)
  (:results (result :scs (sb-vm::unsigned-reg))) (:result-types sb-vm::unsigned-num)
  (:generator 1 (emit-crc #x9ac05c00 result crc value)))

#+arm64
(sb-c:defknown crc-byte ((unsigned-byte 32) (unsigned-byte 8)) (unsigned-byte 32)
    (sb-c:foldable sb-c:flushable sb-c:movable))
#+arm64
(sb-c:define-vop (crc-byte)
  (:translate crc-byte) (:policy :fast-safe)
  (:args (crc :scs (sb-vm::unsigned-reg)) (value :scs (sb-vm::unsigned-reg)))
  (:arg-types sb-vm::unsigned-num sb-vm::unsigned-num)
  (:results (result :scs (sb-vm::unsigned-reg))) (:result-types sb-vm::unsigned-num)
  (:generator 1 (emit-crc #x1ac05000 result crc value)))

(defun native-crc (buffer start end &optional (seed 0))
  (declare (type octets buffer) (type fixnum start end) (type (unsigned-byte 32) seed))
  (unless (<= 0 start end (length buffer)) (error "spike CRC: range invalido"))
  #+arm64
  (let ((crc (logxor seed #xffffffff)) (cursor start))
    (declare (type (unsigned-byte 32) crc) (type fixnum cursor))
    (macrolet ((consume (offset)
                 `(multiple-value-bind (low high)
                      (sb-simd-neon:u64.2-values
                       (sb-simd-neon:u64.2! (sb-simd-neon:u8.16-aref buffer ,offset)))
                    (setf crc (crc-word (crc-word crc low) high)))))
      (dotimes (block (floor (- end start) 64))
        (consume cursor) (consume (+ cursor 16))
        (consume (+ cursor 32)) (consume (+ cursor 48))
        (incf cursor 64))
      (dotimes (block (floor (- end cursor) 16)) (consume cursor) (incf cursor 16)))
    (loop for i fixnum from cursor below end do (setf crc (crc-byte crc (aref buffer i))))
    (logxor crc #xffffffff))
  #-arm64 (error "spike CRC: backend indisponibile"))
