(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-008
(declaim (ftype (function (vista-indice-full-text u16 u32 a:spazio-full-text index) fixnum) posting-termine-vista))
(defun posting-termine-vista (view field row query term)
  "Pre: vista e query validate. Post: posting della coppia termine/riga oppure -1."
  (let ((d (cerca-termine-vista view field query term)))
    (if (minusp d) -1 (cerca-posting-vista view d row query))))

;;; REQ: REQ-SEC-004 REQ-SEC-008
(declaim (ftype (function (vista-indice-full-text index u32 a:spazio-full-text) boolean) posizione-vista-p))
(defun posizione-vista-p (view posting ordinal query)
  "Pre: offset posting valido. Post: posizione esatta presente o assente, budget contato."
  (let* ((buffer (vista-indice-full-text-buffer view))
         (low (leggi-u64 buffer (+ posting +posting-first-position+)))
         (high (+ low (leggi-u32 buffer (+ posting +posting-frequency+))))
         (base (aref (vista-indice-full-text-starts view) 4)))
    (loop repeat (1+ (- high low)) while (< low high) do
      (a::consuma-lavoro-full-text query)
      (let* ((mid (floor (+ low high) 2)) (value (leggi-u32 buffer (+ base (* mid +position-width+)))))
        (cond ((< value ordinal) (setf low (1+ mid))) ((> value ordinal) (setf high mid))
              (t (return-from posizione-vista-p t)))))
    nil))

;;; REQ: REQ-SEC-004 REQ-SEC-007
(declaim (ftype (function (vista-indice-full-text u32 u16 a:spazio-full-text u32) boolean)
                continua-frase-vista-p))
(defun continua-frase-vista-p (view row field query ordinal)
  "Pre: primo termine all'ordinale dato. Post: frase consecutiva nella stessa riga/campo."
  (loop for term from 1 below (a::spazio-full-text-token-count query) always
    (let ((posting (posting-termine-vista view field row query term)))
      (and (not (minusp posting)) (<= term (- #xffffffff ordinal))
           (posizione-vista-p view posting (+ ordinal term) query)))))

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-008
(declaim (ftype (function (vista-indice-full-text u32 u16 a:spazio-full-text) boolean) frase-vista-p))
(defun frase-vista-p (view row field query)
  "Pre: query non vuota. Post: esiste un allineamento, incluse le ripetizioni del termine."
  (let ((posting (posting-termine-vista view field row query 0)))
    (when (minusp posting) (return-from frase-vista-p nil))
    (let* ((buffer (vista-indice-full-text-buffer view))
           (first (leggi-u64 buffer (+ posting +posting-first-position+)))
           (frequency (leggi-u32 buffer (+ posting +posting-frequency+)))
           (base (aref (vista-indice-full-text-starts view) 4)))
      (dotimes (i frequency)
        (a::consuma-lavoro-full-text query)
        (when (continua-frase-vista-p view row field query (leggi-u32 buffer (+ base (* (+ first i) +position-width+))))
          (return-from frase-vista-p t)))))
  nil)

;;; REQ: REQ-SEC-004 REQ-SEC-007 REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t t) boolean) corrisponde-riga-indice-full-text))
(defun corrisponde-riga-indice-full-text (view row field query mode)
  "Pre: vista verificata/immutabile e QUERY DONE esclusiva, 1..256 token, modo ALL/ANY/PHRASE.
Post: predicato della singola riga fisica; analisi e tutte le letture addebitate a QUERY.
Nessun fetch, deduplica, filtro MVCC, I/O o certificazione di query della Serie completa.
INVALID-ARGUMENT per stato/tipi/query; RESOURCE-EXHAUSTED non e un risultato negativo."
  (unless (and (typep view 'vista-indice-full-text) (typep row 'u32) (typep field '(integer 1 65535))
               (typep query 'a:spazio-full-text) (eq :done (a::spazio-full-text-phase query))
               (<= 1 (a::spazio-full-text-token-count query) 256) (member mode '(:all :any :phrase)))
    (error 'invalid-argument :reason :fulltext-file-query-input))
  (a::consuma-lavoro-full-text query)
  (case mode
    (:phrase (frase-vista-p view row field query))
    (:all (loop for term below (a::spazio-full-text-token-count query)
                always (not (minusp (posting-termine-vista view field row query term)))))
    (:any (loop for term below (a::spazio-full-text-token-count query)
                thereis (not (minusp (posting-termine-vista view field row query term)))))
    (otherwise (error 'invariant-violation :reason :fulltext-file-query-mode))))
