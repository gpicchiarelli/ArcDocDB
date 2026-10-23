;;;; Ricerca su run SEALED, budget nello scratch esclusivo della query.
;;; OWNER: run immutabile; QUERY esclusiva del lettore. SHARED: sole letture del run.
(in-package #:arcdocdb.fulltext.index)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (indice-posizionale index u16 a:spazio-full-text index u32 u32 boolean)
                         (member -1 0 1)) confronta-token-query))
(defun confronta-token-query (run occurrence field query term row position with-position)
  "Pre: run ordinato, token/query validi. Post: confronto chiave, opzionalmente posizione.
Ogni confronto e byte sono addebitati alla query, mai al run condiviso."
  (a::consuma-lavoro-full-text query)
  (let* ((data (indice-posizionale-tokens run)) (i (* occurrence +token-width+))
         (f (aref data (+ i +field+))) (begin (aref (a::spazio-full-text-begins query) term))
         (size (- (aref (a::spazio-full-text-ends query) term) begin)))
    (unless (= f field) (return-from confronta-token-query (if (< f field) -1 1)))
    (let ((order (confronta-termini (indice-posizionale-bytes run) (aref data (+ i +offset+))
                                  (aref data (+ i +length+)) (a::spazio-full-text-bytes query) begin size query)))
      (unless (zerop order) (return-from confronta-token-query order)))
    (let ((r (aref data (+ i +row+))) (p (aref data (+ i +position+))))
      (cond ((< r row) -1) ((> r row) 1) ((not with-position) 0)
            ((< p position) -1) ((> p position) 1) (t 0)))))

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (indice-posizionale u16 a:spazio-full-text index u32 u32) index)
                limite-token-query))
(defun limite-token-query (run field query term row position)
  "Pre: run SEALED e chiave di ricerca. Post: primo token >= chiave o COUNT.
Ricerca binaria entro COUNT+1 iterazioni, senza liste o cursori condivisi."
  (let ((low 0) (high (indice-posizionale-count run)))
    (loop repeat (1+ high) while (< low high) do
      (let ((mid (floor (+ low high) 2)))
        (if (minusp (confronta-token-query run mid field query term row position t))
            (setf low (1+ mid)) (setf high mid))))
    low))

;;; REQ: REQ-SEC-004 REQ-SEC-007
(declaim (ftype (function (indice-posizionale u16 a:spazio-full-text index u32 u32 boolean) boolean)
                presenza-token-query))
(defun presenza-token-query (run field query term row position with-position)
  "Pre: run SEALED, query analizzata. Post: presenza esatta per riga e campo.
Con WITH-POSITION richiede anche ordinale esatto, altrimenti qualunque posizione."
  (let ((i (limite-token-query run field query term row position)))
    (and (< i (indice-posizionale-count run))
         (zerop (confronta-token-query run i field query term row position with-position)))))

;;; REQ: REQ-SEC-004 REQ-SEC-007
(declaim (ftype (function (indice-posizionale u16 a:spazio-full-text u32 u32) boolean)
                continua-frase-query))
(defun continua-frase-query (run field query row position)
  "Pre: primo termine alla posizione data. Post: tutti i successivi a distanza unitaria.
Nessuna frase attraversa campi o righe/versioni; overflow ordinale escluso prima della somma."
  (loop for term from 1 below (a::spazio-full-text-token-count query) always
    (and (<= term (- #xffffffff position))
         (presenza-token-query run field query term row (+ position term) t))))

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (indice-posizionale u16 a:spazio-full-text u32) boolean) cerca-frase-query))
(defun cerca-frase-query (run field query row)
  "Pre: query non vuota. Post: esiste almeno un allineamento della frase nella riga.
Esamina solo le occorrenze del primo termine su quella riga; lavoro sempre limitato."
  (let ((first (limite-token-query run field query 0 row 0)) (data (indice-posizionale-tokens run)))
    (loop for i from first below (indice-posizionale-count run) do
      (unless (zerop (confronta-token-query run i field query 0 row 0 nil))
        (return-from cerca-frase-query nil))
      (when (continua-frase-query run field query row (aref data (+ (* i +token-width+) +position+)))
        (return-from cerca-frase-query t))))
  nil)

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t t t t) boolean) corrisponde-riga-full-text))
(defun corrisponde-riga-full-text (run row field query mode)
  "Pre: run SEALED, QUERY DONE esclusiva, 1..256 token, MODE :ALL/:ANY/:PHRASE.
Post: predicato su una singola versione identificata da ROW. Nessuna risoluzione MVCC,
enumerazione di documenti, pubblicazione READY o certificazione di query completa.
Analisi e confronti condividono il budget QUERY; saturazione segnala RESOURCE-EXHAUSTED.
INVALID-ARGUMENT per query vuota/non pronta o stato/tipi errati."
  (unless (and (typep run 'indice-posizionale) (eq :sealed (indice-posizionale-state run))
               (typep row 'u32) (typep field '(integer 1 65535)) (typep query 'a:spazio-full-text)
               (eq :done (a::spazio-full-text-phase query))
               (<= 1 (a::spazio-full-text-token-count query) 256) (member mode '(:all :any :phrase)))
    (error 'invalid-argument :reason :fulltext-query-input))
  (a::consuma-lavoro-full-text query)
  (case mode
    (:phrase (cerca-frase-query run field query row))
    (:all (loop for term below (a::spazio-full-text-token-count query)
                always (presenza-token-query run field query term row 0 nil)))
    (:any (loop for term below (a::spazio-full-text-token-count query)
                thereis (presenza-token-query run field query term row 0 nil)))
    (otherwise (error 'invariant-violation :reason :fulltext-query-mode))))
