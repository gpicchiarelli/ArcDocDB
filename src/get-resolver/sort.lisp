;;; OWNER: costruttore, due array OUTCOME e istogramma privati dopo preflight del budget.
;;; SHARED: nessuno; lookup su parole u32, nessun boxing u64 necessario.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(declaim (inline cifra-prova-resolver))
(declaim (ftype (function (resolver-words index (integer 0 7)) u8) cifra-prova-resolver))
(defun cifra-prova-resolver (proofs base digit)
  "Pre: entry completa e DIGIT 0..7. Post: ottetto LSD del TXID senza intero u64.
Controlli degli array safety 3 sempre attivi; nessuna modifica o allocazione esplicita."
  (ldb (byte 8 (* 8 (mod digit 4)))
       (aref proofs (+ base (if (< digit 4) +proof-txid-low+ +proof-txid-high+)))))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (resolver-words resolver-words resolver-words u32 (integer 0 7)) null)
                passata-prove-resolver))
(defun passata-prove-resolver (source target histogram count digit)
  "Pre: array distinti di COUNT entry, 256 contatori. Post: distribuzione LSD stabile.
INVARIANT-VIOLATION per misure, prefissi o consumo incoerenti; cicli COUNT e 256.
Nessuna allocazione durante la passata, nessuna modifica della sorgente."
  (unless (and (= (length source) (* count +proof-words+))
               (= (length source) (length target)) (not (eq source target))
               (= (length histogram) +radix-buckets+))
    (error 'invariant-violation :reason :resolver-radix-shape))
  (fill histogram 0)
  (dotimes (i count)
    (incf (aref histogram (cifra-prova-resolver source (* i +proof-words+) digit))))
  (let ((start 0))
    (declare (type u32 start))
    (dotimes (bucket +radix-buckets+)
      (let ((frequency (aref histogram bucket)))
        (setf (aref histogram bucket) start) (incf start frequency)))
    (unless (= start count) (error 'invariant-violation :reason :resolver-radix-count)))
  (dotimes (i count)
    (let* ((base (* i +proof-words+)) (bucket (cifra-prova-resolver source base digit))
           (position (aref histogram bucket)))
      (unless (< position count) (error 'invariant-violation :reason :resolver-radix-position))
      (dotimes (word +proof-words+)
        (setf (aref target (+ (* position +proof-words+) word)) (aref source (+ base word))))
      (incf (aref histogram bucket))))
  (let ((previous 0))
    (declare (type u32 previous))
    (dotimes (bucket +radix-buckets+)
      (unless (<= previous (aref histogram bucket) count)
        (error 'invariant-violation :reason :resolver-radix-consumption))
      (setf previous (aref histogram bucket)))
    (unless (= previous count) (error 'invariant-violation :reason :resolver-radix-consumption)))
  nil)

;;; REQ: REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (resolver-words) null) verifica-ordine-prove-resolver))
(defun verifica-ordine-prove-resolver (proofs)
  "Pre: array ordinato per TXID, offset fisici stabili su duplicati. Post: ordine e duplicati coerenti.
CSN diversi per TXID uguale sono CORRUPTION-DETECTED; uguali ammessi senza coalescenza.
INVARIANT-VIOLATION per ordine/offset; ciclo su cardinalità verificata."
  (unless (zerop (mod (length proofs) +proof-words+))
    (error 'invariant-violation :reason :resolver-proof-shape))
  (loop for base from +proof-words+ below (length proofs) by +proof-words+
        for prior = (- base +proof-words+)
        for high = (aref proofs (+ base +proof-txid-high+))
        for old-high = (aref proofs (+ prior +proof-txid-high+))
        for low = (aref proofs (+ base +proof-txid-low+))
        for old-low = (aref proofs (+ prior +proof-txid-low+))
        do (unless (or (< old-high high) (and (= old-high high) (<= old-low low)))
             (error 'invariant-violation :reason :resolver-proof-order))
           (when (and (= high old-high) (= low old-low))
             (unless (and (= (aref proofs (+ base +proof-csn-low+))
                             (aref proofs (+ prior +proof-csn-low+)))
                          (= (aref proofs (+ base +proof-csn-high+))
                             (aref proofs (+ prior +proof-csn-high+))))
               (error 'corruption-detected :reason :resolver-conflicting-outcome
                      :offset (aref proofs (+ base +proof-offset+))))
             (unless (< (aref proofs (+ prior +proof-offset+)) (aref proofs (+ base +proof-offset+)))
               (error 'invariant-violation :reason :resolver-proof-physical-order))))
  nil)

;;; REQ: REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (resolver-words) resolver-words) ordina-prove-resolver))
(defun ordina-prove-resolver (proofs)
  "Pre: prove private verificate, budget per due array e istogramma già autorizzato.
Post: array ordinato stabilmente dopo otto passate limitate; zero/una prova senza scratch.
Propaga invarianti/corruzione; percorso freddo con allocazioni esplicite limitate."
  (unless (zerop (mod (length proofs) +proof-words+))
    (error 'invariant-violation :reason :resolver-proof-shape))
  (when (<= (length proofs) +proof-words+)
    (verifica-ordine-prove-resolver proofs) (return-from ordina-prove-resolver proofs))
  (let ((source proofs) (target (make-array (length proofs) :element-type '(unsigned-byte 32)))
        (histogram (make-array +radix-buckets+ :element-type '(unsigned-byte 32) :initial-element 0))
        (count (floor (length proofs) +proof-words+)))
    (dotimes (digit 8)
      (passata-prove-resolver source target histogram count digit) (rotatef source target))
    (verifica-ordine-prove-resolver source)
    source))

;;; REQ: REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (resolver-words u32 u32) (values boolean index &optional)) trova-prova-resolver))
(defun trova-prova-resolver (proofs high low)
  "Pre: prove immutabili ordinate; TXID in due u32. Post: prima entry uguale oppure NIL/0.
Al più 33 passi su cardinalità u32; nessun I/O, lock, scrittura o boxing u64.
INVARIANT-VIOLATION per forma o bound; offset/CSN non sono ancora una prova di lettura."
  (unless (zerop (mod (length proofs) +proof-words+))
    (error 'invariant-violation :reason :resolver-proof-shape))
  (let ((left 0) (right (floor (length proofs) +proof-words+)))
    (declare (type u32 left right))
    (loop repeat +binary-attempts+
          do (when (= left right)
               (let ((base (* left +proof-words+)))
                 (if (and (< base (length proofs))
                          (= high (aref proofs (+ base +proof-txid-high+)))
                          (= low (aref proofs (+ base +proof-txid-low+))))
                     (return-from trova-prova-resolver (values t base))
                     (return-from trova-prova-resolver (values nil 0)))))
             (let* ((middle (+ left (floor (- right left) 2))) (base (* middle +proof-words+))
                    (mh (aref proofs (+ base +proof-txid-high+)))
                    (ml (aref proofs (+ base +proof-txid-low+))))
               (if (or (< mh high) (and (= mh high) (< ml low)))
                   (setf left (1+ middle)) (setf right middle))))
    (error 'invariant-violation :reason :resolver-proof-search-bound)))
