;;;; Merge bottom-up limitato dalla lunghezza; solo vettori privati di costruzione.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index octets index) (values (member -1 0 1) &optional))
                compare-id16))
(defun compare-id16 (left left-start right right-start)
  "Pre: due ID16 nei rispettivi buffer stabili. Post: ordine lessicografico esatto.
INVALID-ARGUMENT per range non disponibile; nessuna copia o modifica."
  (check-range left left-start (+ left-start +participant-id-bytes+))
  (check-range right right-start (+ right-start +participant-id-bytes+))
  (dotimes (i +participant-id-bytes+ 0)
    (let ((a (aref left (+ left-start i))) (b (aref right (+ right-start i))))
      (when (/= a b) (return-from compare-id16 (if (< a b) -1 1))))))

;;; REQ: REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (octets index octets index) null) copy-id16))
(defun copy-id16 (target target-index source source-index)
  "Pre: vettori privati distinti; indici espressi in ID16. Post: un ID copiato esattamente.
INVALID-ARGUMENT per range invalido, prima della modifica; nessun I/O."
  (let ((to (* target-index +participant-id-bytes+)) (from (* source-index +participant-id-bytes+)))
    (check-range target to (+ to +participant-id-bytes+))
    (check-range source from (+ from +participant-id-bytes+))
    (replace target source :start1 to :end1 (+ to +participant-id-bytes+)
                          :start2 from :end2 (+ from +participant-id-bytes+)))
  nil)

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets octets index index index) null) merge-id-runs))
(defun merge-id-runs (source target left middle right)
  "Pre: vettori privati distinti della stessa misura; due run ID16 ordinati.
Post: run unito completo in TARGET; sorgente invariata, cicli limitati a RIGHT-LEFT.
Segnala INVARIANT-VIOLATION per range o consumo interno incoerente."
  (unless (and (/= (length source) 0) (= (length source) (length target))
               (not (eq source target)) (zerop (mod (length source) +participant-id-bytes+)))
    (error 'invariant-violation :reason :decision-sort-arrays))
  (unless (<= 0 left middle right (floor (length source) +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-sort-range))
  (let ((a left) (b middle))
    (dotimes (step (- right left))
      (let ((take-left (or (= b right)
                           (and (< a middle)
                                (<= (compare-id16 source (* a +participant-id-bytes+)
                                                  source (* b +participant-id-bytes+)) 0)))))
        (copy-id16 target (+ left step) source (if take-left a b))
        (if take-left (incf a) (incf b))))
    (unless (and (= a middle) (= b right))
      (error 'invariant-violation :reason :decision-sort-consumption)))
  nil)

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 u64) null) check-participant-order))
(defun check-participant-order (participants count source-offset)
  "Pre: vettore privato contenente COUNT ID16. Post: ordine crescente, nessun duplicato.
CORRUPTION-DETECTED per partecipante ripetuto, offset assoluto del record;
INVARIANT-VIOLATION per misura o ordinamento interno errato."
  (unless (= (length participants) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (loop for i from 1 below count
        do (case (compare-id16 participants (* (1- i) +participant-id-bytes+)
                               participants (* i +participant-id-bytes+))
             (-1 nil)
             (0 (error 'corruption-detected :reason :decision-duplicate-participant
                       :offset source-offset))
             (otherwise (error 'invariant-violation :reason :decision-participant-order))))
  nil)

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 u64) (values octets &optional)) sort-participants))
(defun sort-participants (participants count source-offset)
  "Pre: copia privata di COUNT ID16. Post: copia posseduta ordinata, tutti ID distinti.
Propaga duplicati tipizzati; INVARIANT-VIOLATION per misura interna incoerente.
Merge limitato a integer-length(COUNT-1) passate; allocazioni solo in apertura."
  (unless (= (length participants) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (let ((source participants)
        (target (make-array (length participants) :element-type '(unsigned-byte 8))))
    (loop repeat (integer-length (max 0 (1- count)))
          for width = 1 then (* width 2)
          do (loop repeat (ceiling count (* width 2))
                   for left = 0 then (+ left (* width 2))
                   do (merge-id-runs source target left (min count (+ left width))
                                     (min count (+ left (* width 2)))))
             (rotatef source target))
    (check-participant-order source count source-offset)
    source))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector simple-vector index index index) null) merge-entry-runs))
(defun merge-entry-runs (source target left middle right)
  "Pre: vettori privati distinti, stessa misura, due run ordinati per TXID.
Post: unione stabile completa; a TXID uguale conserva l'ordine fisico dei record.
INVARIANT-VIOLATION per range o consumo; ciclo limitato a RIGHT-LEFT."
  (unless (and (= (length source) (length target)) (not (eq source target)))
    (error 'invariant-violation :reason :decision-sort-arrays))
  (unless (<= 0 left middle right (length source))
    (error 'invariant-violation :reason :decision-sort-range))
  (let ((a left) (b middle))
    (dotimes (step (- right left))
      (let ((take-left
              (or (= b right)
                  (and (< a middle)
                       (<= (%entry-txid (the decision-entry (aref source a)))
                           (%entry-txid (the decision-entry (aref source b))))))))
        (setf (aref target (+ left step)) (aref source (if take-left a b)))
        (if take-left (incf a) (incf b))))
    (unless (and (= a middle) (= b right))
      (error 'invariant-violation :reason :decision-sort-consumption)))
  nil)

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values simple-vector &optional)) sort-entries))
(defun sort-entries (entries)
  "Pre: vettore privato di entry possedute. Post: ordine TXID non decrescente e stabile.
INVARIANT-VIOLATION per entry malformata o ordinamento interno errato; nessun I/O.
Merge limitato a integer-length(N-1) passate, ciascuna limitata a N entry."
  (let* ((count (length entries)) (source entries)
         (target (make-array count :element-type t)))
    (dotimes (i count) (check-entry-shape (the decision-entry (aref entries i))))
    (loop repeat (integer-length (max 0 (1- count)))
          for width = 1 then (* width 2)
          do (loop repeat (ceiling count (* width 2))
                   for left = 0 then (+ left (* width 2))
                   do (merge-entry-runs source target left (min count (+ left width))
                                        (min count (+ left (* width 2)))))
             (rotatef source target))
    (loop for i from 1 below count
          unless (<= (%entry-txid (the decision-entry (aref source (1- i))))
                     (%entry-txid (the decision-entry (aref source i))))
            do (error 'invariant-violation :reason :decision-entry-order))
    source))
