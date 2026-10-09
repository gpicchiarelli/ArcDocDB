;;;; Larghezza preferita dei float CBOR, solo campi IEEE e parole immediate.
;;; OWNER: ogni chiamata possiede parole locali; nessuno stato modificato.
;;; SHARED: nessuna scrittura, attesa o I/O tra Serie (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32) (values boolean &optional)) binary32-accorciabile-cbor-p))
(defun binary32-accorciabile-cbor-p (word)
  "Pre: bit binary32 in WORD u32. Post: T solo se una binary16 espande negli stessi bit,
preservando segno, zero, infinito e payload NaN con padding a destra.
INVARIANT-VIOLATION per campi o allineamento incoerenti; niente float o heap previsti."
  (let ((exponent (ldb (byte 8 23) word)) (fraction (logand word #x7fffff)))
    (declare (type (unsigned-byte 8) exponent) (type (unsigned-byte 23) fraction))
    (unless (and (<= exponent 255) (<= fraction #x7fffff))
      (error 'invariant-violation :reason :cbor-float32-fields))
    (let ((shorter
            (cond ((zerop exponent) (zerop fraction))
                  ((= exponent 255) (zerop (logand fraction #x1fff)))
                  ((<= 113 exponent 141) (zerop (logand fraction #x1fff)))
                  ((<= 103 exponent 112)
                   (zerop (logand (logior #x800000 fraction)
                                  (1- (ash 1 (- 126 exponent))))))
                  (t nil))))
      (when (and shorter (plusp (logand fraction #x1fff)))
        (error 'invariant-violation :reason :cbor-float32-alignment))
      shorter)))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32 u32 (integer 30 52)) (values boolean &optional))
                binary64-allineato-cbor-p))
(defun binary64-allineato-cbor-p (high low shift)
  "Pre: significando binary64 in HIGH21/LOW32, SHIFT 30..52 per destinazione subnormale.
Post: T se tutti i bit sotto SHIFT sono zero, senza unire le parole in un u64.
INVARIANT-VIOLATION per larghezza, shift o allineamento interno incoerenti."
  (unless (<= high #x1fffff)
    (error 'invariant-violation :reason :cbor-float64-significand))
  (unless (<= 30 shift 52)
    (error 'invariant-violation :reason :cbor-float64-shift))
  (let ((aligned
          (if (<= shift 32)
              (zerop (logand low (1- (ash 1 shift))))
              (and (zerop low)
                   (zerop (logand high (1- (ash 1 (- shift 32)))))))))
    (when (and aligned (plusp (logand low #x1fffffff)))
      (error 'invariant-violation :reason :cbor-float64-alignment))
    aligned))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32 u32) (values boolean &optional)) binary64-accorciabile-cbor-p))
(defun binary64-accorciabile-cbor-p (high low)
  "Pre: binary64 in HIGH/LOW u32. Post: T solo se una binary32 espande negli stessi bit,
preservando segno, zero, infinito e payload NaN; nessuna materializzazione u64/float.
INVARIANT-VIOLATION per campi/allineamento incoerenti; al piu confronti e maschere."
  (let ((exponent (ldb (byte 11 20) high)) (fraction-high (logand high #xfffff)))
    (declare (type (unsigned-byte 11) exponent) (type (unsigned-byte 20) fraction-high))
    (unless (and (<= exponent 2047) (<= fraction-high #xfffff))
      (error 'invariant-violation :reason :cbor-float64-fields))
    (let ((shorter
            (cond ((zerop exponent) (and (zerop fraction-high) (zerop low)))
                  ((= exponent 2047) (zerop (logand low #x1fffffff)))
                  ((<= 897 exponent 1150) (zerop (logand low #x1fffffff)))
                  ((<= 874 exponent 896)
                   (binary64-allineato-cbor-p (logior #x100000 fraction-high)
                                              low (- 926 exponent)))
                  (t nil))))
      (when (and shorter (plusp (logand low #x1fffffff)))
        (error 'invariant-violation :reason :cbor-float64-alignment))
      shorter)))
