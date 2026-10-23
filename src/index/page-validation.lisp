;;; OWNER: buffer stabile per tutta la verifica, input/output distinti nel writer.
;;; SHARED: nessuna scrittura; nessuna dipendenza dal writer o dal GC.
(in-package #:arcdocdb.index.page)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-009 REQ-AFF-004
(declaim (ftype (function (t page-error keyword) null) esigi-pagina))
(defun esigi-pagina (predicate condition reason)
  "Pre: classe interna canonica e predicato gia' calcolato. Post: NIL se valido.
Altrimenti condizione tipizzata senza mutazioni; nessun errore viene catturato."
  (unless predicate (error condition :reason reason)) nil)

;;; REQ: REQ-IDX-009
(declaim (ftype (function (octets index index) boolean) pagina-zero-p))
(defun pagina-zero-p (buffer start end)
  "Pre: intervallo verificato. Post: T per byte tutti zero; nessun dato modificato."
  (loop for i from start below end always (zerop (aref buffer i))))

;;; REQ: REQ-IDX-009
(declaim (ftype (function (page-number page-number identita-pagina index page-error) null)
                verifica-riferimento-pagina))
(defun verifica-riferimento-pagina (page generation identity size condition)
  "Pre: numeri nel dominio, taglia valida. Post: assente o figlio precedente allineato.
Condizione richiesta per coppia parziale, self/forward reference o generazione futura."
  (unless (plusp (nth-value 0 (geometria-pagina size)))
    (error 'invariant-violation :reason :index-page-reference-size))
  (esigi-pagina
   (or (and (zerop page) (zerop generation))
       (and (plusp page) (plusp generation) (zerop (mod page size))
            (< page (identita-pagina-page identity))
            (<= generation (identita-pagina-generation identity))))
   condition :index-page-reference)
  nil)

;;; REQ: REQ-IDX-009
(declaim (ftype (function (octets index identita-pagina index page-error) null)
                verifica-ref-binario))
(defun verifica-ref-binario (buffer offset identity size condition)
  "Pre: sedici byte presenti. Post: riferimento canonico verificato senza conservarlo.
Condizione richiesta per numero fuori dominio o riferimento non valido."
  (let ((page (leggi-u64 buffer offset))
        (generation (leggi-u64 buffer (+ offset +reference-generation+))))
    (esigi-pagina (and (<= page +page-id-max+) (<= generation +page-id-max+))
                  condition :index-page-reference-domain)
    (verifica-riferimento-pagina page generation identity size condition))
  nil)

;;; REQ: REQ-IDX-009
(declaim (ftype (function (identita-pagina index page-error) null) verifica-identita-allineata))
(defun verifica-identita-allineata (identity size condition)
  "Pre: identita' canonica e taglia ammessa. Post: offset fisico allineato.
Condizione richiesta se incoerente; nessuna allocazione o prenotazione."
  (esigi-pagina (zerop (mod (identita-pagina-page identity) size))
                condition :index-page-alignment)
  nil)

;;; REQ: REQ-IDX-009
(declaim (ftype (function (page-kind) (integer 1 3)) codice-tipo-pagina))
(defun codice-tipo-pagina (kind)
  "Pre: tipo canonico interno. Post: codice persistente; INVARIANT-VIOLATION se inatteso."
  (case kind (:bucket 1) (:directory 2) (:chiave 3)
        (otherwise (error 'invariant-violation :reason :index-page-kind-code))))
