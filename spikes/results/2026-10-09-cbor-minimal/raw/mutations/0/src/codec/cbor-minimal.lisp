;;;; Preferenza locale delle testate complete; non valida il profilo dell'item.
;;; OWNER: buffer immutabile del chiamante; parole e cursori locali.
;;; SHARED: sola lettura, nessuna scrittura/attesa tra Serie (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((unsigned-byte 5) u32 u32) (values boolean &optional))
                argomento-minimo-cbor-p))
(defun argomento-minimo-cbor-p (ai high low)
  "Pre: header MT0..6 completo, AI0..27 e parole separate. Post: T se l'argomento
usa la larghezza minima, senza ricostruire un u64. Nessun payload letto.
INVARIANT-VIOLATION per AI o HIGH incompatibile con la larghezza dichiarata."
  (unless (< ai 28)
    (error 'invariant-violation :reason :cbor-minimal-ai))
  (unless (or (= ai 27) (zerop high))
    (error 'invariant-violation :reason :cbor-minimal-words))
  (if (< ai 24) t
      (case ai
        (24 (>= low 25))
        (25 (>= low 256))
        (26 (>= low 65536))
        (27 (not (zerop high)))
        (otherwise (error 'invariant-violation :reason :cbor-minimal-ai)))))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((unsigned-byte 5) u32 u32) (values boolean &optional))
                float-accorciabile-header-cbor-p))
(defun float-accorciabile-header-cbor-p (ai high low)
  "Pre: header MT7 completo, AI0..27 e parole raw. Post: T soltanto per un float
binary32/64 accorciabile; simple e binary16 non sono accorciabili.
INVARIANT-VIOLATION per AI o HIGH incoerente con larghezza; nessun float costruito."
  (unless (< ai 28)
    (error 'invariant-violation :reason :cbor-minimal-ai))
  (unless (or (= ai 27) (zerop high))
    (error 'invariant-violation :reason :cbor-minimal-words))
  (case ai
    ((0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25) nil)
    (26 (binary32-accorciabile-cbor-p low))
    (27 (binary64-accorciabile-cbor-p high low))
    (otherwise (error 'invariant-violation :reason :cbor-minimal-ai))))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t)
                         (values (unsigned-byte 3) (unsigned-byte 5) u32 u32 index
                                 (member :argument) &optional))
                leggi-header-cbor-minimo))
(defun leggi-header-cbor-minimo (buffer start end)
  "Pre: BUFFER immutabile simple u8, span half-open; verifica fredda del lettore base.
Post: gli stessi sei valori MAJOR, AI, HIGH, LOW, NEXT, :ARGUMENT, solo per header minimo.
Propaga prima tutti gli errori sintattici del lettore; poi CORRUPTION-DETECTED
:cbor-nonminimal a START per indefinito/break, argomento o float accorciabile.
INVARIANT-VIOLATION per progresso o forma incoerenti. NaN preserva segno/payload;
nessun u64/float/AST materializzato, nessun payload, stato, attesa o I/O."
  (multiple-value-bind (major ai high low next form) (leggi-header-cbor buffer start end)
    (unless (and (< start next) (<= next end))
      (error 'invariant-violation :reason :cbor-minimal-progress :offset start))
    (unless (if (eq form :argument) (< ai 28) (= ai 31))
      (error 'invariant-violation :reason :cbor-minimal-form :offset start))
    (unless (eq form :argument)
      (error 'corruption-detected :reason :cbor-nonminimal :offset start))
    (when (if (< major 7)
              (not (argomento-minimo-cbor-p ai high low))
              (float-accorciabile-header-cbor-p ai high low))
      (error 'corruption-detected :reason :cbor-nonminimal :offset start))
    (values major ai high low next :argument)))
