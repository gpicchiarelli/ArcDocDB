;;;; Stack esplicito fisso; tag e chunk definiti non aggiungono frame.
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor) (values (integer 0 6) &optional)) tipo-frame-cbor))
(defun tipo-frame-cbor (space)
  "Pre: scratch esclusivo attivo. Post: kind 0..6 del frame corrente.
INVARIANT-VIOLATION per top/kind incoerente; nessuna mutazione."
  (unless (< (spazio-cbor-top space) +cbor-scan-frames+)
    (error 'invariant-violation :reason :cbor-stack-top))
  (let ((kind (aref (spazio-cbor-kinds space) (spazio-cbor-top space))))
    (unless (and (<= kind 6) (eq (zerop kind) (zerop (spazio-cbor-top space))))
      (error 'invariant-violation :reason :cbor-stack-kind))
    kind))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor) (values null &optional)) depila-frame-cbor))
(defun depila-frame-cbor (space)
  "Pre: frame non radice completato. Post: top diminuito, depth solo per array/map.
INVARIANT-VIOLATION per root o conteggio profondita incoerente."
  (let ((kind (tipo-frame-cbor space)))
    (when (zerop (spazio-cbor-top space))
      (error 'invariant-violation :reason :cbor-pop-root))
    (when (and (<= 1 kind 4) (zerop (spazio-cbor-depth space)))
      (error 'invariant-violation :reason :cbor-pop-depth))
    (when (<= 1 kind 4) (decf (spazio-cbor-depth space)))
    (decf (spazio-cbor-top space))
    nil))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor (integer 1 6) (integer 0 16777216))
                         (values null &optional)) empila-frame-cbor))
(defun empila-frame-cbor (space kind remaining)
  "Pre: arita verificata e profondita ammessa. Post: un frame aggiunto, picco aggiornato.
INVARIANT-VIOLATION su capacita o depth; 102 slot includono root e stringa indefinita."
  (unless (< (spazio-cbor-top space) (1- +cbor-scan-frames+))
    (error 'invariant-violation :reason :cbor-stack-capacity))
  (when (and (<= kind 4) (>= (spazio-cbor-depth space) +cbor-scan-max-depth+))
    (error 'invariant-violation :reason :cbor-stack-depth))
  (incf (spazio-cbor-top space))
  (setf (aref (spazio-cbor-kinds space) (spazio-cbor-top space)) kind
        (aref (spazio-cbor-remaining space) (spazio-cbor-top space)) remaining)
  (when (<= kind 4)
    (incf (spazio-cbor-depth space))
    (setf (spazio-cbor-peak-depth space)
          (max (spazio-cbor-peak-depth space) (spazio-cbor-depth space))))
  nil)

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor) (values null &optional)) inizia-figlio-cbor))
(defun inizia-figlio-cbor (space)
  "Pre: item terminale non-tag ammesso dal contesto. Post: un solo figlio consumato.
I chunk non consumano figli del contenitore esterno; INVARIANT-VIOLATION su arita/fase."
  (let* ((kind (tipo-frame-cbor space)) (top (spazio-cbor-top space))
         (remaining (aref (spazio-cbor-remaining space) top)))
    (declare (type (integer 0 6) kind) (type (integer 0 101) top) (type u32 remaining))
    (unless (<= remaining +cbor-scan-max-bytes+)
      (error 'invariant-violation :reason :cbor-child-count))
    (when (and (<= kind 2) (zerop remaining))
      (error 'invariant-violation :reason :cbor-child-empty))
    (case kind
      ((0 1 2) (decf (aref (spazio-cbor-remaining space) top)))
      (4 (unless (<= remaining 1)
           (error 'invariant-violation :reason :cbor-map-phase))
         (setf (aref (spazio-cbor-remaining space) top) (- 1 remaining)))
      ((3 5 6) nil)
      (otherwise (error 'invariant-violation :reason :cbor-child-kind)))
    nil))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor index u32) (values boolean &optional)) esito-radice-cbor))
(defun esito-radice-cbor (space end remaining)
  "Pre: frame root e cursore entro END. Post: T solo per root esatta completata.
CORRUPTION-DETECTED :cbor-trailing prima dei byte residui; invarianti su arita/depth/tag."
  (unless (<= remaining 1)
    (error 'invariant-violation :reason :cbor-root-state))
  (unless (zerop (spazio-cbor-depth space))
    (error 'invariant-violation :reason :cbor-root-state))
  (when (zerop remaining)
    (when (< (spazio-cbor-cursor space) end)
      (error 'corruption-detected :reason :cbor-trailing :offset (spazio-cbor-cursor space)))
    (when (spazio-cbor-pending-tag space)
      (error 'invariant-violation :reason :cbor-root-tag)))
  (zerop remaining))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor index) (values boolean &optional)) svuota-frame-cbor))
(defun svuota-frame-cbor (space end)
  "Pre: cursore entro END. Post: al piu 102 pop, T solo per root completata a END.
CORRUPTION-DETECTED :cbor-trailing al cursore prima di leggere la coda;
INVARIANT-VIOLATION per range, root/fase o drain incoerente."
  (unless (<= (spazio-cbor-cursor space) end)
    (error 'invariant-violation :reason :cbor-stack-range))
  (loop repeat +cbor-scan-frames+
        do (let* ((kind (tipo-frame-cbor space))
           (remaining (aref (spazio-cbor-remaining space) (spazio-cbor-top space))))
      (declare (type (integer 0 6) kind) (type u32 remaining))
      (cond
        ((zerop kind)
         (return-from svuota-frame-cbor (esito-radice-cbor space end remaining)))
        ((and (<= kind 2) (zerop remaining))
         (when (spazio-cbor-pending-tag space)
           (error 'invariant-violation :reason :cbor-drain-tag))
         (depila-frame-cbor space))
        (t (return-from svuota-frame-cbor nil)))))
  (error 'invariant-violation :reason :cbor-stack-drain))
