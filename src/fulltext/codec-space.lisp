;;; OWNER: un solo builder/checker per spazio. SHARED: nessuna mutazione fra Serie.
(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(defstruct (spazio-codec-full-text
             (:constructor %spazio-codec-full-text (lengths starts prefix marks analysis term-capacity)) (:copier nil))
  "Scratch preallocato per pianificazione/validazione; nessun oggetto per entry.
Un errore lascia solo scratch privato parziale; riuso dopo reset all'ingresso."
  (lengths (make-array 6 :element-type 'u64) :type (simple-array (unsigned-byte 64) (6)) :read-only t)
  (starts (make-array 6 :element-type 'u64) :type (simple-array (unsigned-byte 64) (6)) :read-only t)
  (prefix (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (marks #* :type simple-bit-vector :read-only t)
  (analysis (a:crea-spazio-full-text) :type a:spazio-full-text :read-only t)
  (term-capacity 1 :type index :read-only t)
  (work 0 :type index) (work-limit 268435456 :type index))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (&key (:max-lengths t) (:max-positions t) (:max-term-bytes t) (:max-memory t))
                         spazio-codec-full-text) crea-spazio-codec-full-text))
(defun crea-spazio-codec-full-text (&key (max-lengths 65536) (max-positions 1048576)
                                       (max-term-bytes 1024) (max-memory 67108864))
  "Pre: configurazione fredda, capacita positive u32; termini fino a 16MiB per il decoder.
Post: scratch esclusivo entro payload+8192 byte conservativi, oppure rifiuto prima di allocare.
RESOURCE-EXHAUSTED non rende il formato corrotto: il chiamante puo fornire piu scratch."
  (unless (and (typep max-lengths '(integer 1 4294967295))
               (typep max-positions '(integer 1 4294967295))
               (typep max-term-bytes '(integer 1 16777216)) (typep max-memory 'index))
    (error 'invalid-argument :reason :fulltext-codec-capacity))
  (let ((memory (+ (* 4 max-lengths) (ceiling max-positions 8) (* 332 max-term-bytes) 8192)))
    (when (> memory max-memory) (error 'resource-exhausted :reason :fulltext-codec-memory))
    (%spazio-codec-full-text
     (make-array 6 :element-type 'u64 :initial-element 0)
     (make-array 6 :element-type 'u64 :initial-element 0)
     (make-array max-lengths :element-type 'u32 :initial-element 0)
     (make-array max-positions :element-type 'bit :initial-element 0)
     (a:crea-spazio-full-text :max-scalars (* 16 max-term-bytes) :max-tokens max-term-bytes
                             :token-bytes (* 4 max-term-bytes) :max-memory memory)
     max-term-bytes)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (spazio-codec-full-text &optional index) null) lavoro-codec))
(defun lavoro-codec (space &optional (units 1))
  "Pre: scratch esclusivo e contatori validi. Post: lavoro entro limite, senza overflow.
RESOURCE-EXHAUSTED prima di oltrepassarlo; nessun risultato parziale certificato."
  (unless (<= (spazio-codec-full-text-work space) (spazio-codec-full-text-work-limit space))
    (error 'invariant-violation :reason :fulltext-codec-work-state))
  (when (> units (- (spazio-codec-full-text-work-limit space) (spazio-codec-full-text-work space)))
    (error 'resource-exhausted :reason :fulltext-codec-work))
  (incf (spazio-codec-full-text-work space) units) nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index octets index index spazio-codec-full-text)
                         (member -1 0 1)) confronta-span-codec))
(defun confronta-span-codec (x a b y c d space)
  "Pre: span validi. Post: confronto lessicografico a byte, lavoro addebitato.
Nessun buffer modificato; al piu la minore lunghezza piu un confronto."
  (unless (and (<= a b (length x)) (<= c d (length y)))
    (error 'invariant-violation :reason :fulltext-codec-compare-span))
  (loop for i below (min (- b a) (- d c)) do
    (lavoro-codec space)
    (let ((p (aref x (+ a i))) (q (aref y (+ c i))))
      (when (< p q) (return-from confronta-span-codec -1))
      (when (> p q) (return-from confronta-span-codec 1))))
  (lavoro-codec space)
  (cond ((< (- b a) (- d c)) -1) ((> (- b a) (- d c)) 1) (t 0)))
