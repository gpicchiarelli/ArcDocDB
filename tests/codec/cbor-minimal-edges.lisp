(in-package #:arcdocdb.cbor.minimal.tests)

;;; Supplemento dichiarato DOPO la lettura del nuovo prodotto e della tabella D03/D06.
;;; I tre file dell'oracolo blind conservano il loro freeze originale.
;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-cbor-minimal-public-subnormal-alignment-pairs
  (flet ((probe (value minimal-p)
           (dolist (sign '(0 1))
             (let* ((description (list (if (zerop value) :zero :finite) sign value 52))
                    (bits (cm-encode-description description 64)))
               (is (integerp bits))
               (is (eq (cm-float-minimal-p bits 64) minimal-p))
               (multiple-value-bind (buffer start end) (cm-float-fixture 64 bits)
                 (cm-compare buffer start end))))))
    ;; Shift32: LOW decide; un incremento di un'unita binary32 resta rappresentabile.
    (let ((base (expt 2 -129)))
      (probe base nil)
      (probe (+ base (expt 2 -181)) t)
      (probe (+ base (expt 2 -149)) nil))
    ;; Shift33: LOW nonzero e HIGH basso nonzero rendono falsa ciascuna condizione.
    (let ((base (expt 2 -130)))
      (probe base nil)
      (probe (+ base (expt 2 -182)) t)
      (probe (+ base (expt 2 -150)) t)
      (probe (+ base (expt 2 -149)) nil))
    ;; Shift52: prima e ultima zona del significando separato, senza helper prodotto.
    (let ((base (expt 2 -149)))
      (probe base nil)
      (probe (+ base (expt 2 -201)) t)
      (probe (+ base (expt 2 -169)) t))
    ;; D06: zero, subnormal LOW-only e HIGH-only, con ambedue i segni.
    (probe 0 nil)
    (probe (expt 2 -1074) t)
    (probe (expt 2 -1042) t)))
