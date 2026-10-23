;;;; Item MT2/3 definite-length: testata minima e payload, nessun AST.
;;; OWNER: destinazione esclusiva; byte sorgente stabili fino al ritorno.
;;; SHARED: sola lettura della sorgente, nessuna scrittura/attesa tra Serie (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t keyword) (values index &optional))
                check-span-string-cbor-write))
(defun check-span-string-cbor-write (buffer start end reason)
  "Pre: array e confini esterni; REASON identifica il range. Post: span index.
INVALID-ARGUMENT per tipo/range, offset NIL, prima di leggere byte.
INVARIANT-VIOLATION per lunghezza incoerente; span anche vuoto, nessuna mutazione."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason reason))
  (let ((span (- (the index end) (the index start))))
    (declare (type index span))
    (unless (= (+ start span) end)
      (error 'invariant-violation :reason :cbor-string-span))
    span))

;;; REQ: REQ-CBR-002 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t)
                         (values index (member 1 2 3 5) index &optional))
                check-input-string-cbor-write))
(defun check-input-string-cbor-write (buffer start end major source source-start source-end max-bytes)
  "Pre: argomenti esterni. Post: span sorgente, header-size e item-size limitati.
Ordine: range destinazione, major, range sorgente, budget, capacita.
INVALID-ARGUMENT o RESOURCE-EXHAUSTED con offset NIL, prima di byte letti/scritti;
INVARIANT-VIOLATION per selezione interna incoerente. Budget include la testata."
  (check-span-string-cbor-write buffer start end :cbor-range)
  (unless (typep major '(integer 2 3))
    (error 'invalid-argument :reason :cbor-string-major))
  (let ((span (check-span-string-cbor-write source source-start source-end
                                          :cbor-string-source-range)))
    (declare (type index span))
    (unless (and (typep max-bytes 'index) (<= max-bytes +cbor-scan-max-bytes+))
      (error 'invalid-argument :reason :cbor-string-budget))
    (let ((budget (the index max-bytes)))
      (when (> span budget)
        (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-string-byte-budget))
      (let* ((header-size (the (member 1 2 3 5)
                              (nth-value 1 (seleziona-header-cbor 0 (the u32 span)))))
             (item-size (+ header-size span)))
        (declare (type index item-size))
        (unless (<= 1 header-size item-size)
          (error 'invariant-violation :reason :cbor-string-selection))
        (when (> item-size budget)
          (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-string-byte-budget))
        (when (> item-size (- (the index end) (the index start)))
          (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-string-capacity))
        (values span header-size item-size)))))

;;; REQ: REQ-CBR-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index octets index index)
                         (values null &optional)) check-overlap-string-cbor-write))
(defun check-overlap-string-cbor-write (buffer start next source source-start source-end)
  "Pre: span verificati, NEXT include testata e payload. Post: nessun overlap.
Stesso array disgiunto, confini toccanti e sorgente vuota ammessi.
INVALID-ARGUMENT :cbor-string-overlap, offset NIL; INVARIANT-VIOLATION
per confini interni. Nessun byte letto o scritto."
  (unless (<= start next (length buffer))
    (error 'invariant-violation :reason :cbor-string-target-span))
  (unless (<= source-start source-end (length source))
    (error 'invariant-violation :reason :cbor-string-source-span))
  (when (and (eq buffer source) (< source-start source-end)
             (< start source-end) (< source-start next))
    (error 'invalid-argument :reason :cbor-string-overlap))
  nil)

;;; REQ: REQ-CBR-002 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index octets index index)
                         (values index &optional)) copia-stringa-cbor-write))
(defun copia-stringa-cbor-write (buffer target end source start stop)
  "Pre: sorgente stabile e disgiunta dal footprint di scrittura gia verificato.
Post: copia esatta in [TARGET,END), restituisce END; resto e span sorgente non toccati.
INVARIANT-VIOLATION per confini, lunghezza o progresso; al piu 16 MiB di passi.
Nessun rollback per guasti interni, attesa, I/O o allocazione prevista."
  (unless (<= target end (length buffer))
    (error 'invariant-violation :reason :cbor-string-copy-target))
  (unless (<= start stop (length source))
    (error 'invariant-violation :reason :cbor-string-copy-source))
  (let ((span (- stop start)) (cursor target) (read-cursor start))
    (declare (type index span cursor read-cursor))
    (unless (and (<= span +cbor-scan-max-bytes+) (= span (- end target)))
      (error 'invariant-violation :reason :cbor-string-copy-bound))
    (loop repeat span
          do (setf (aref buffer cursor) (aref source read-cursor))
             (incf cursor) (incf read-cursor))
    (unless (and (= cursor end) (= read-cursor stop))
      (error 'invariant-violation :reason :cbor-string-copy-progress))
    cursor))

;;; REQ: REQ-CBR-002 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t &key (:max-bytes t))
                         (values index &optional)) scrivi-stringa-cbor-minima))
(defun scrivi-stringa-cbor-minima (buffer start end major source source-start source-end
                                 &key (max-bytes +cbor-scan-max-bytes+))
  "Pre: destinazione esclusiva, sorgente stabile simple u8, span half-open, MT2/3.
Post: un solo NEXT, testata minima e payload esatto; byte esterni invariati.
MAX-BYTES 0..16 MiB include testata e payload. Preflight range/major/source/budget,
capacita/overlap/UTF8 prima di scrivere; INVALID-ARGUMENT o RESOURCE-EXHAUSTED
con offset NIL, errori UTF8 propagati con offset assoluto nella sorgente.
Stesso array ammesso solo disgiunto dal footprint; testo contato in byte.
INVARIANT-VIOLATION interno senza rollback. Nessuna pubblicazione atomica/durevole,
allocazione prevista, attesa, I/O, AST o stato condiviso tra Serie."
  (multiple-value-bind (span header-size item-size)
      (check-input-string-cbor-write buffer start end major source source-start source-end max-bytes)
    (let ((bytes (the octets buffer)) (begin (the index start))
          (mt (the (integer 2 3) major)) (src (the octets source))
          (source-begin (the index source-start)) (source-limit (the index source-end))
          (next (+ (the index start) item-size)))
      (declare (type index next))
      (check-overlap-string-cbor-write bytes begin next src source-begin source-limit)
      (when (= mt 3)
        (let ((count (arcdocdb.utf8:verifica-utf8 src source-begin source-limit :max-bytes span)))
          (declare (type index count))
          (unless (<= count span)
            (error 'invariant-violation :reason :cbor-string-utf8-count))))
      (let ((payload-start (scrivi-header-cbor-minimo bytes begin next mt 0 span)))
        (declare (type index payload-start))
        (unless (= payload-start (+ begin header-size))
          (error 'invariant-violation :reason :cbor-string-header-progress))
        (let ((result (copia-stringa-cbor-write bytes payload-start next src source-begin source-limit)))
          (declare (type index result))
          (unless (= result next)
            (error 'invariant-violation :reason :cbor-string-progress))
          result)))))
