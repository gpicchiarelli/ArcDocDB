;;; OWNER: compilatore SBCL; VOP privati, nessuno stato applicativo per chiamata.
;;; SHARED: definizioni del compilatore solo durante compilazione/caricamento.
(in-package #:arcdocdb.binary)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-AFF-004
#+arcdocdb-crc32c-arm64
(declaim (ftype (function (u32 sb-c:tn sb-c:tn sb-c:tn) null) emetti-crc-arm64))
#+arcdocdb-crc32c-arm64
(defun emetti-crc-arm64 (opcode result crc value)
  "Pre: generatore del compilatore, opcode CRC32C ammesso e TN interi. Post: una istruzione A64.
Asserzioni sui campi prima di emettere; nessun indirizzo/dato esterno o codice runtime modificato."
  (assert (member opcode '(#x9ac05c00 #x1ac05000)))
  (let ((rd (sb-c:tn-offset result)) (rn (sb-c:tn-offset crc)) (rm (sb-c:tn-offset value)))
    (assert (and (<= 0 rd 30) (<= 0 rn 31) (<= 0 rm 31)))
    (let ((word (logior opcode rd (ash rn 5) (ash rm 16))))
      (dotimes (position 4)
        (sb-assem:inst sb-arm64-asm::byte (ldb (byte 8 (* position 8)) word))))))

;;; REQ: REQ-FOR-003 REQ-AFF-002
#+arcdocdb-crc32c-arm64
(sb-c:defknown %crc32c-word (u32 u64) u32 (sb-c:flushable sb-c:movable))
;;; REQ: REQ-FOR-003 REQ-AFF-002
#+arcdocdb-crc32c-arm64
(sb-c:define-vop (%crc32c-word)
  (:translate %crc32c-word) (:policy :fast-safe)
  (:args (crc :scs (sb-vm::unsigned-reg)) (value :scs (sb-vm::unsigned-reg)))
  (:arg-types sb-vm::unsigned-num sb-vm::unsigned-num)
  (:results (result :scs (sb-vm::unsigned-reg))) (:result-types sb-vm::unsigned-num)
  (:generator 1 (emetti-crc-arm64 #x9ac05c00 result crc value)))

;;; REQ: REQ-FOR-003 REQ-AFF-002
#+arcdocdb-crc32c-arm64
(sb-c:defknown %crc32c-byte (u32 u8) u32 (sb-c:flushable sb-c:movable))
;;; REQ: REQ-FOR-003 REQ-AFF-002
#+arcdocdb-crc32c-arm64
(sb-c:define-vop (%crc32c-byte)
  (:translate %crc32c-byte) (:policy :fast-safe)
  (:args (crc :scs (sb-vm::unsigned-reg)) (value :scs (sb-vm::unsigned-reg)))
  (:arg-types sb-vm::unsigned-num sb-vm::unsigned-num)
  (:results (result :scs (sb-vm::unsigned-reg))) (:result-types sb-vm::unsigned-num)
  (:generator 1 (emetti-crc-arm64 #x1ac05000 result crc value)))
