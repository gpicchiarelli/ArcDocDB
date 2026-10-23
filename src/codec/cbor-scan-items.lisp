;;;; Sintassi generica locale: nessuna canonicalita, semantica tag o deduplica mappe.
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor (unsigned-byte 3)
                          (member :argument :indefinite :break) index)
                         (values null &optional)) check-contesto-cbor))
(defun check-contesto-cbor (space major form lead)
  "Pre: header completo, cursore sul lead. Post: chunk non-break definito dello stesso MT.
INVARIANT-VIOLATION per lead/form; CORRUPTION-DETECTED :cbor-chunk-type sul lead,
prima del budget nodi. Break viene verificato separatamente senza caricare nodi."
  (unless (= lead (spazio-cbor-cursor space))
    (error 'invariant-violation :reason :cbor-context-cursor))
  (when (and (eq form :break) (/= major 7))
    (error 'invariant-violation :reason :cbor-context-form))
  (let ((kind (tipo-frame-cbor space)))
    (when (and (>= kind 5) (not (eq form :break)))
      (unless (and (eq form :argument) (= major (- kind 3)))
        (error 'corruption-detected :reason :cbor-chunk-type :offset lead))))
  nil)

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor index) (values null &optional)) chiudi-break-cbor))
(defun chiudi-break-cbor (space lead)
  "Pre: header break completo. Post: un solo frame indefinito chiuso, nessun nodo.
CORRUPTION-DETECTED nell'ordine tag-break, break, map-value sul lead;
INVARIANT-VIOLATION per cursore interno incoerente."
  (unless (= lead (spazio-cbor-cursor space))
    (error 'invariant-violation :reason :cbor-break-cursor))
  (when (spazio-cbor-pending-tag space)
    (error 'corruption-detected :reason :cbor-tag-break :offset lead))
  (let ((kind (tipo-frame-cbor space)))
    (unless (<= 3 kind 6)
      (error 'corruption-detected :reason :cbor-break :offset lead))
    (when (and (= kind 4)
               (plusp (aref (spazio-cbor-remaining space) (spazio-cbor-top space))))
      (error 'corruption-detected :reason :cbor-map-value :offset lead))
    (depila-frame-cbor space))
  nil)

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor (integer 1 16777216) index)
                         (values null &optional)) conta-nodo-cbor))
(defun conta-nodo-cbor (space max-nodes lead)
  "Pre: header e contesto validi, non-break. Post: un nodo aggiunto entro MAX-NODES.
RESOURCE-EXHAUSTED :cbor-node-budget sul lead; INVARIANT-VIOLATION su cursore/conteggio."
  (unless (= lead (spazio-cbor-cursor space))
    (error 'invariant-violation :reason :cbor-node-cursor))
  (unless (<= (spazio-cbor-nodes space) max-nodes)
    (error 'invariant-violation :reason :cbor-node-count))
  (when (>= (spazio-cbor-nodes space) max-nodes)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-node-budget :offset lead))
  (incf (spazio-cbor-nodes space))
  nil)

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor (member 4 5) u32 u32 index index
                          (member :argument :indefinite) (integer 0 100) index)
                         (values null &optional)) apri-contenitore-cbor))
(defun apri-contenitore-cbor (space major high low next end form max-depth lead)
  "Pre: MT4/5 e header completo. Post: frame e profondita aggiunti, anche se vuoto.
Depth-budget sul lead precede count-fit; arita mappa verificata prima di 2*N.
CORRUPTION-DETECTED :cbor-truncated a END; INVARIANT-VIOLATION per range/cursore."
  (unless (<= next end)
    (error 'invariant-violation :reason :cbor-container-range))
  (unless (= lead (spazio-cbor-cursor space))
    (error 'invariant-violation :reason :cbor-container-cursor))
  (when (>= (spazio-cbor-depth space) max-depth)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-depth-budget :offset lead))
  (let ((kind-offset (- major 4)))
    (declare (type (integer 0 1) kind-offset))
    (if (eq form :indefinite)
        (empila-frame-cbor space (+ 3 kind-offset) 0)
        (let ((minimum (if (= major 4) (- end next) (floor (- end next) 2))))
          (declare (type index minimum))
          (unless (and (zerop high) (<= low minimum))
            (error 'corruption-detected :reason :cbor-truncated :offset end))
          (empila-frame-cbor space (+ 1 kind-offset)
                            (if (= major 4) low (* 2 low))))))
  (setf (spazio-cbor-cursor space) next)
  nil)

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets spazio-cbor (member 2 3) u32 u32 index index
                          (member :argument :indefinite))
                         (values null &optional)) verifica-stringa-cbor))
(defun verifica-stringa-cbor (buffer space major high low next end form)
  "Pre: header MT2/3 e contesto ammesso. Post: payload entro span o frame indefinito.
CORRUPTION-DETECTED :cbor-truncated a END prima del payload; propaga motivi UTF8
con offset assoluti, verificando ogni chunk separatamente; invarianti su range/progresso."
  (unless (<= next end (length buffer))
    (error 'invariant-violation :reason :cbor-string-range))
  (unless (< (spazio-cbor-cursor space) next)
    (error 'invariant-violation :reason :cbor-string-progress))
  (if (eq form :indefinite)
      (progn (empila-frame-cbor space (if (= major 2) 5 6) 0)
             (setf (spazio-cbor-cursor space) next))
      (progn
        (unless (and (zerop high) (<= low (- end next)))
          (error 'corruption-detected :reason :cbor-truncated :offset end))
        (let ((limit (+ next low)))
          (declare (type index limit))
          (when (= major 3)
            (let ((scalars (arcdocdb.utf8:verifica-utf8 buffer next limit)))
              (unless (<= scalars low)
                (error 'invariant-violation :reason :cbor-utf8-count))))
          (setf (spazio-cbor-cursor space) limit))))
  nil)

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets spazio-cbor (unsigned-byte 3) u32 u32 index index
                          (member :argument :indefinite) (integer 0 100) index)
                         (values null &optional)) tratta-item-cbor))
(defun tratta-item-cbor (buffer space major high low next end form max-depth lead)
  "Pre: nodo caricato, header/contesto validi. Post: cursore avanza e figlio consumato
soltanto per il terminale non-tag; tag mantengono pending senza frame.
Propaga rifiuti di payload/depth/UTF8; INVARIANT-VIOLATION per range/lead/major."
  (unless (<= next end (length buffer))
    (error 'invariant-violation :reason :cbor-item-range))
  (unless (= lead (spazio-cbor-cursor space))
    (error 'invariant-violation :reason :cbor-item-cursor))
  (unless (= major 6)
    (setf (spazio-cbor-pending-tag space) nil)
    (inizia-figlio-cbor space))
  (case major
    (6 (setf (spazio-cbor-pending-tag space) t (spazio-cbor-cursor space) next))
    ((0 1 7) (setf (spazio-cbor-cursor space) next))
    ((2 3) (verifica-stringa-cbor buffer space major high low next end form))
    ((4 5) (apri-contenitore-cbor space major high low next end form max-depth lead))
    (otherwise (error 'invariant-violation :reason :cbor-item-major)))
  nil)
