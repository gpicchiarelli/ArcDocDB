;;;; LSD stabile sulle chiavi fisse, selezionato per cardinalità misurate.
;;; OWNER: singola ricostruzione; input e scratch sono copie private.
;;; SHARED: nessuna scrittura condivisa, nessun I/O o pubblicazione.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-AFF-008
(defconstant +decision-radix-buckets+ 256 "Numero di classi dell'algoritmo per un ottetto.")
;;; REQ: REQ-TXM-005 REQ-AFF-008
(deftype radix-histogram () '(simple-array (unsigned-byte 64) (256)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (radix-histogram index) (values boolean &optional))
                radix-prefix-starts))
(defun radix-prefix-starts (histogram count)
  "Pre: conteggi privati di 256 classi. Post: somme verificate, prefissi se necessari.
Restituisce NIL per zero o una classe occupata: la passata non serve.
INVARIANT-VIOLATION per conteggi incompatibili; due cicli limitati a 256."
  (let ((total 0) (occupied 0))
    (declare (type index total occupied))
    (dotimes (digit +decision-radix-buckets+)
      (let ((frequency (aref histogram digit)))
        (unless (<= frequency (- count total))
          (error 'invariant-violation :reason :decision-radix-count))
        (incf total frequency)
        (unless (zerop frequency) (incf occupied))))
    (unless (= total count)
      (error 'invariant-violation :reason :decision-radix-consumption))
    (when (> occupied 1)
      (let ((start 0))
        (declare (type index start))
        (dotimes (digit +decision-radix-buckets+)
          (let ((frequency (aref histogram digit)))
            (setf (aref histogram digit) start)
            (incf start frequency))))
      t)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 index radix-histogram)
                         (values boolean &optional)) radix-id-starts))
(defun radix-id-starts (source count digit histogram)
  "Pre: copia privata di COUNT ID16, DIGIT byte dell'ID. Post: histogram verificato.
Restituisce se occorre distribuire; INVARIANT-VIOLATION per misura o byte incoerente.
SOURCE invariato; conteggio limitato a COUNT, prefissi a 256 classi."
  (unless (= (length source) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (unless (< digit +participant-id-bytes+)
    (error 'invariant-violation :reason :decision-radix-digit))
  (fill histogram 0)
  (dotimes (i count)
    (incf (aref histogram (aref source (+ (* i +participant-id-bytes+) digit)))))
  (radix-prefix-starts histogram count))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector index radix-histogram)
                         (values boolean &optional)) radix-entry-starts))
(defun radix-entry-starts (source digit histogram)
  "Pre: entry private verificate, DIGIT ottetto del TXID u64. Post: conteggi verificati.
Restituisce se occorre distribuire; INVARIANT-VIOLATION per ottetto incoerente.
SOURCE invariato; conteggio limitato alla lunghezza, prefissi a 256 classi."
  (unless (< digit 8)
    (error 'invariant-violation :reason :decision-radix-digit))
  (unless (typep (length source) 'u64)
    (error 'invariant-violation :reason :decision-radix-count))
  (fill histogram 0)
  (dotimes (i (length source))
    (incf (aref histogram
                (ldb (byte 8 (* digit 8)) (%entry-txid (the decision-entry (aref source i)))))))
  (radix-prefix-starts histogram (length source)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (radix-histogram index) null) radix-check-cursors))
(defun radix-check-cursors (histogram count)
  "Pre: cursori dopo distribuzione stabile. Post: estremi crescenti entro COUNT.
Ultima classe termina esattamente a COUNT; INVARIANT-VIOLATION altrimenti.
Nessuna modifica, ciclo limitato a 256 classi."
  (let ((previous 0))
    (declare (type index previous))
    (dotimes (digit +decision-radix-buckets+)
      (let ((cursor (aref histogram digit)))
        (unless (<= previous cursor count)
          (error 'invariant-violation :reason :decision-radix-position))
        (setf previous cursor)))
    (unless (= previous count)
      (error 'invariant-violation :reason :decision-radix-consumption)))
  nil)

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets octets u16 index radix-histogram) null)
                radix-scatter-ids))
(defun radix-scatter-ids (source target count digit histogram)
  "Pre: copie private distinte, prefissi della passata corrente. Post: ID distribuiti.
Stabile nell'ordine della sorgente, nessuna modifica a SOURCE; cursori consumati.
INVARIANT-VIOLATION per misure, byte o posizione; ciclo limitato a COUNT."
  (unless (and (= (length source) (* count +participant-id-bytes+))
               (= (length target) (length source)) (not (eq source target)))
    (error 'invariant-violation :reason :decision-radix-arrays))
  (unless (< digit +participant-id-bytes+)
    (error 'invariant-violation :reason :decision-radix-digit))
  (dotimes (i count)
    (let* ((key (aref source (+ (* i +participant-id-bytes+) digit)))
           (position (aref histogram key)))
      (unless (< position count)
        (error 'invariant-violation :reason :decision-radix-position))
      (copy-id16 target (the index position) source i)
      (incf (aref histogram key))))
  (radix-check-cursors histogram count))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector simple-vector index radix-histogram) null)
                radix-scatter-entries))
(defun radix-scatter-entries (source target digit histogram)
  "Pre: vettori privati distinti, entry verificate e prefissi correnti. Post: run stabile.
TXID uguali conservano l'ordine fisico; SOURCE invariato, cursori consumati.
INVARIANT-VIOLATION per misure, ottetto o posizione; ciclo limitato alla lunghezza."
  (unless (and (= (length source) (length target)) (not (eq source target)))
    (error 'invariant-violation :reason :decision-radix-arrays))
  (unless (< digit 8)
    (error 'invariant-violation :reason :decision-radix-digit))
  (dotimes (i (length source))
    (let* ((entry (the decision-entry (aref source i)))
           (key (ldb (byte 8 (* digit 8)) (%entry-txid entry)))
           (position (aref histogram key)))
      (unless (< position (length source))
        (error 'invariant-violation :reason :decision-radix-position))
      (setf (aref target (the index position)) entry)
      (incf (aref histogram key))))
  (radix-check-cursors histogram (length source)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 u64) (values octets &optional))
                radix-sort-participants))
(defun radix-sort-participants (participants count source-offset)
  "Pre: copia privata di COUNT ID16. Post: risultato posseduto, ordinato e distinto.
Propaga duplicati tipizzati; INVARIANT-VIOLATION per misura interna incoerente.
LSD stabile: al più 16 passate, uniformi saltate; input privato può essere riordinato.
Scratch sulla misura effettiva; percorso di apertura, nessuna promessa zero heap."
  (unless (= (length participants) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (let ((source participants)
        (target (make-array (length participants) :element-type '(unsigned-byte 8)))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0)))
    (dotimes (pass +participant-id-bytes+)
      (let ((digit (- +participant-id-bytes+ 1 pass)))
        (when (radix-id-starts source count digit histogram)
          (radix-scatter-ids source target count digit histogram)
          (rotatef source target))))
    (check-participant-order source count source-offset)
    source))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values simple-vector &optional))
                radix-sort-entries))
(defun radix-sort-entries (entries)
  "Pre: vettore privato di entry possedute. Post: ordine TXID non decrescente e stabile.
INVARIANT-VIOLATION per entry o ordine incoerente; nessun I/O o stato condiviso.
Al più otto passate LSD, uniformi saltate; input privato può essere riordinato.
Scratch sulla lunghezza effettiva; allocazioni ammesse sul percorso di apertura."
  (dotimes (i (length entries))
    (unless (typep (aref entries i) 'decision-entry)
      (error 'invariant-violation :reason :decision-entry-shape))
    (check-entry-shape (aref entries i)))
  (let ((source entries) (target (make-array (length entries) :element-type t))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0)))
    (dotimes (digit 8)
      (when (radix-entry-starts source digit histogram)
        (radix-scatter-entries source target digit histogram)
        (rotatef source target)))
    (loop for i from 1 below (length source)
          unless (<= (%entry-txid (the decision-entry (aref source (1- i))))
                     (%entry-txid (the decision-entry (aref source i))))
            do (error 'invariant-violation :reason :decision-entry-order))
    source))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-BEN-001 REQ-VAL-001
(defconstant +radix-participant-threshold+ 1024
  "Proposta misurata 2026-10-09: LSD per almeno 1024 ID16, merge sotto soglia.")
;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-BEN-001 REQ-VAL-001
(defconstant +radix-entry-threshold+ 256
  "Proposta misurata 2026-10-09: LSD per almeno 256 TXID, merge sotto soglia.")

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 u64) (values octets &optional))
                sort-recovery-participants))
(defun sort-recovery-participants (participants count source-offset)
  "Pre: copia privata di COUNT ID16. Post: ID ordinati e distinti, dati posseduti.
Selezione per cardinalità; entrambi i sorter verificano misura e ordine finale.
Propaga corruzione tipizzata dei duplicati e invarianti interni; nessun I/O.
Workspace sulla misura effettiva, allocazioni ammesse durante il recovery."
  (if (< count +radix-participant-threshold+)
      (sort-participants participants count source-offset)
      (radix-sort-participants participants count source-offset)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values simple-vector &optional))
                sort-recovery-entries))
(defun sort-recovery-entries (entries)
  "Pre: entry private possedute. Post: TXID ordinati stabilmente, senza alias esterni.
Selezione per cardinalità; entrambi i sorter verificano forma e ordine finale.
Propaga INVARIANT-VIOLATION per dati interni incoerenti, senza risultati parziali.
Nessuno stato condiviso o I/O; scratch sulla lunghezza effettiva."
  (if (< (length entries) +radix-entry-threshold+)
      (sort-entries entries)
      (radix-sort-entries entries)))
