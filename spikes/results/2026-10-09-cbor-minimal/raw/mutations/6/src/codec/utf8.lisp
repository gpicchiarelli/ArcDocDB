;;;; UTF-8 rigoroso secondo RFC 3629, senza decodifica o normalizzazione.
;;; OWNER: chiamante; BUFFER resta immutabile per l'intera verifica.
;;; SHARED: sola lettura del buffer; cursore e conteggio locali a ogni chiamata.
(in-package #:arcdocdb.utf8)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-008
(defconstant +max-utf8-bytes+ 16777216)

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t) (values index &optional)) check-utf8-arguments))
(defun check-utf8-arguments (buffer start end max-bytes)
  "Pre: argomenti esterni non verificati. Post: span index entro budget, anche vuoto.
INVALID-ARGUMENT per tipo/range o budget; RESOURCE-EXHAUSTED se lo span supera
il budget. Controlli nell'ordine range, budget, esaurimento; nessun byte letto."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason :utf8-range))
  (unless (and (typep max-bytes 'index) (<= max-bytes +max-utf8-bytes+))
    (error 'invalid-argument :reason :utf8-budget))
  (let ((span (- end start)))
    (declare (type index span))
    (when (> span max-bytes)
      (error 'resource-exhausted :reason :utf8-byte-budget))
    span))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index (integer 1 4))
                         (values index &optional)) verifica-suite-utf8))
(defun verifica-suite-utf8 (buffer cursor end width)
  "Pre: CURSOR sul lead e WIDTH 1..4. Post: fine index e continuazioni verificate
da sinistra a destra. INVARIANT-VIOLATION per confini interni incoerenti;
CORRUPTION-DETECTED per sequenza troncata (offset END) o continuazione invalida."
  (unless (< cursor end)
    (error 'invariant-violation :reason :utf8-continuation-range :offset cursor))
  (unless (<= end (length buffer))
    (error 'invariant-violation :reason :utf8-continuation-range :offset end))
  (when (> width (- end cursor))
    (error 'corruption-detected :reason :utf8-truncated :offset end))
  (let ((next (+ cursor width)))
    (declare (type index next))
    (dotimes (step (1- width) next)
      (let ((position (+ cursor 1 step)))
        (declare (type index position))
        (unless (<= #x80 (aref buffer position) #xbf)
          (error 'corruption-detected :reason :utf8-continuation :offset position))))))

;;; REQ: REQ-AFF-004
(declaim (ftype (function (u8 u8 index) (values null &optional)) verifica-scalare-utf8))
(defun verifica-scalare-utf8 (lead second position)
  "Pre: lead di 3/4 byte e SECOND continuazione verificata. Post: scalare Unicode
senza codifiche lunghe, surrogati o valori oltre U+10FFFF; non lo materializza.
INVARIANT-VIOLATION per contesto interno; CORRUPTION-DETECTED all'offset POSITION."
  (unless (<= #xe0 lead #xf4)
    (error 'invariant-violation :reason :utf8-scalar-context :offset position))
  (unless (<= #x80 second #xbf)
    (error 'invariant-violation :reason :utf8-scalar-context :offset position))
  (let ((minimum (if (= lead #xe0) #xa0 (if (= lead #xf0) #x90 #x80)))
        (maximum (if (= lead #xed) #x9f (if (= lead #xf4) #x8f #xbf))))
    (declare (type u8 minimum maximum))
    (unless (<= minimum second maximum)
      (error 'corruption-detected :reason :utf8-scalar :offset position)))
  nil)

;;; REQ: REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index) (values index &optional))
                verifica-carattere-utf8))
(defun verifica-carattere-utf8 (buffer cursor end)
  "Pre: span stabile e non vuoto. Post: cursore crescente entro END per un solo
scalare verificato. INVARIANT-VIOLATION per confini/progresso; CORRUPTION-DETECTED
per lead invalido (offset CURSOR); propaga errori ordinati di suite e scalare."
  (unless (< cursor end)
    (error 'invariant-violation :reason :utf8-character-range :offset cursor))
  (unless (<= end (length buffer))
    (error 'invariant-violation :reason :utf8-character-range :offset end))
  (let* ((lead (aref buffer cursor))
         (width (cond ((<= lead #x7f) 1)
                      ((<= #xc2 lead #xdf) 2)
                      ((<= #xe0 lead #xef) 3)
                      ((<= #xf0 lead #xf4) 4)
                      (t (error 'corruption-detected :reason :utf8-leading
                                :offset cursor))))
         (next (verifica-suite-utf8 buffer cursor end width)))
    (declare (type u8 lead) (type (integer 1 4) width) (type index next))
    (when (>= width 3)
      (verifica-scalare-utf8 lead (aref buffer (1+ cursor)) (1+ cursor)))
    (unless (and (< cursor next) (<= next end))
      (error 'invariant-violation :reason :utf8-progress :offset cursor))
    next))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t &key (:max-bytes t)) (values index &optional))
                verifica-utf8))
(defun verifica-utf8 (buffer start end &key (max-bytes +max-utf8-bytes+))
  "Pre: BUFFER immutabile, simple u8; span half-open e budget 0..16 MiB verificati.
Post: numero di scalari solo dopo verifica integrale; vuoto 0, nessuna mutazione.
Propaga INVALID-ARGUMENT, RESOURCE-EXHAUSTED e CORRUPTION-DETECTED; INVARIANT-
VIOLATION per conteggio/fine interni. Al piu 16 MiB di passi, senza attese o CBOR;
NUL, BOM e noncaratteri ammessi; nessuna normalizzazione o sostituzione."
  (let ((span (check-utf8-arguments buffer start end max-bytes)))
    (declare (type index span))
    (let ((bytes (the octets buffer)) (begin (the index start))
          (limit (the index end)) (cursor (the index start)) (count 0))
      (declare (type octets bytes) (type index begin limit cursor count))
      (loop repeat span
            do (when (= cursor limit) (return))
               (setf cursor (verifica-carattere-utf8 bytes cursor limit))
               (incf count)
               (unless (<= count (- cursor begin))
                 (error 'invariant-violation :reason :utf8-count :offset cursor)))
      (unless (= cursor limit)
        (error 'invariant-violation :reason :utf8-result :offset cursor))
      (unless (<= count span)
        (error 'invariant-violation :reason :utf8-count :offset cursor))
      count)))
