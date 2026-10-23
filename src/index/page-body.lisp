;;; OWNER: codec, buffer stabile del chiamante; nessuna callback o risorsa acquisita.
;;; SHARED: nessuno; la verifica e' locale a una sola pagina.
(in-package #:arcdocdb.index.page)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-009
(declaim (ftype (function (octets index index index identita-pagina fixnum u32 page-error) null)
                verifica-directory-pagina))
(defun verifica-directory-pagina (buffer start used size identity count parameter condition)
  "Pre: corpo nel buffer, taglia ammessa. Post: radix, PageRef e conteggio esatti.
Condizione richiesta per geometria, dominio o riferimento non canonico."
  (let ((bits (ldb (byte 8 0) parameter)) (shift (ldb (byte 8 8) parameter))
        (maximum (nth-value 2 (geometria-pagina size))) (live 0))
    (esigi-pagina (and (zerop (ash parameter -16)) (<= 1 bits maximum)
                      (<= shift 63) (<= (+ bits shift) 64))
                  condition :index-page-directory-geometry)
    (let ((capacity (ash 1 bits)))
      (esigi-pagina (and (= used (* capacity +reference-bytes+)) (<= count capacity))
                    condition :index-page-directory-layout)
      (dotimes (i capacity)
        (let ((offset (+ start (* i +reference-bytes+))))
          (verifica-ref-binario buffer offset identity size condition)
          (unless (zerop (leggi-u64 buffer offset)) (incf live)))))
    (esigi-pagina (= count live) condition :index-page-directory-count))
  nil)

;;; REQ: REQ-IDX-009 REQ-LIM-003
(declaim (ftype (function (index index fixnum u32 page-number page-error) null)
                verifica-frammento-chiave))
(defun verifica-frammento-chiave (used size count parameter next condition)
  "Pre: corpo limitato e riferimento verificato. Post: frammento pieno salvo l'ultimo.
COUNT e' la lunghezza totale, PARAMETER la posizione; condizione per catena incoerente."
  (esigi-pagina (and (<= 1 count +max-key-bytes+) (< parameter count)
                    (= used (min (- size +page-header+) (- count parameter))))
                condition :index-page-key-fragment)
  (esigi-pagina (if (= (+ parameter used) count) (zerop next) (plusp next))
                condition :index-page-key-next)
  nil)

;;; REQ: REQ-IDX-009
(declaim (ftype (function (octets index index index identita-pagina page-kind fixnum u32
                         page-number page-number page-error) null) verifica-corpo-pagina))
(defun verifica-corpo-pagina (buffer start used size identity kind count parameter
                             next next-generation condition)
  "Pre: buffer e corpo presenti, numeri nel dominio. Post: corpo locale canonico.
Condizione richiesta per limiti o tipo; non visita altre pagine e non certifica una root."
  (esigi-pagina (<= used (- size +page-header+)) condition :index-page-body-range)
  (esigi-pagina (<= (+ start used) (length buffer)) condition :index-page-body-range)
  (verifica-identita-allineata identity size condition)
  (verifica-riferimento-pagina next next-generation identity size condition)
  (case kind
    (:bucket (verifica-bucket-pagina buffer start used size identity count parameter condition))
    (:directory
     (esigi-pagina (zerop next) condition :index-page-directory-next)
     (verifica-directory-pagina buffer start used size identity count parameter condition))
    (:chiave (verifica-frammento-chiave used size count parameter next condition))
    (otherwise (error 'invariant-violation :reason :index-page-body-kind)))
  nil)
