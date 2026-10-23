;;;; OWNER: il chiamante possiede spazio e input; un solo compito muta lo spazio.
;;; SHARED: solo letture delle tabelle Unicode fra Serie; nessuno stato scrivibile comune.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(defstruct (spazio-full-text
             (:constructor %crea-spazio-full-text (a b previous next ri stack begins ends bytes))
             (:copier nil))
  "Scratch esclusivo; input preso in prestito fino a completamento/errore.
Array creati solo nel costruttore; risultati utilizzabili solo dopo :DONE."
  (a (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (b (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (previous (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (next (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (ri (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (stack (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (begins (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (ends (make-array 0 :element-type 'u32) :type vettore-u32 :read-only t)
  (bytes (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  (input nil :type (or null octets))
  (input-pos 0 :type index) (input-end 0 :type index)
  (phase :idle :type keyword) (pass 1 :type (integer 1 2))
  (a-count 0 :type index) (b-count 0 :type index)
  (cursor 0 :type index) (stack-top 0 :type (integer 0 64))
  (order-pos 0 :type index) (write 0 :type index)
  (starter -1 :type fixnum) (last-ccc 0 :type u32)
  (significant +nessuno+ :type u32) (ri-count 0 :type u32)
  (boundary 1 :type index) (word-start 0 :type index) (has-letter nil :type boolean)
  (emit-pos 0 :type index) (emit-end 0 :type index) (term-start 0 :type index)
  (byte-count 0 :type index) (token-count 0 :type index)
  (term-limit 1024 :type index) (token-limit 1048576 :type index)
  (work 0 :type index) (work-limit 268435456 :type index)
  (nfc-only nil :type boolean))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (index) vettore-u32) crea-array-full-text))
(defun crea-array-full-text (length)
  "Pre: lunghezza gia ammessa dal costruttore. Post: nuovo array u32 esclusivo."
  (make-array length :element-type 'u32 :initial-element 0))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (&key (:max-scalars t) (:max-tokens t) (:token-bytes t) (:max-memory t))
                         spazio-full-text) crea-spazio-full-text))
(defun crea-spazio-full-text (&key (max-scalars 1048576) (max-tokens 1048576)
                                 (token-bytes 4194304) (max-memory 67108864))
  "Pre: configurazione del worker, percorso freddo. Post: scratch senza condivisioni.
INVALID-ARGUMENT per capacita non valide, RESOURCE-EXHAUSTED prima delle allocazioni
se payload degli array piu 4096 byte di overhead conservativo supera MAX-MEMORY."
  (unless (and (typep max-scalars '(integer 1 4294967295))
               (typep max-tokens '(integer 1 4294967295)) (typep token-bytes 'index)
               (typep max-memory 'index) (plusp token-bytes))
    (error 'invalid-argument :reason :fulltext-space-budget))
  (when (> (+ (* 20 max-scalars) (* 8 max-tokens) token-bytes 4096) max-memory)
    (error 'resource-exhausted :reason :fulltext-space-memory))
  (%crea-spazio-full-text
   (crea-array-full-text max-scalars) (crea-array-full-text max-scalars)
   (crea-array-full-text max-scalars) (crea-array-full-text max-scalars)
   (crea-array-full-text max-scalars) (crea-array-full-text +stack-capacity+)
   (crea-array-full-text max-tokens) (crea-array-full-text max-tokens)
   (make-array token-bytes :element-type '(unsigned-byte 8) :initial-element 0)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text &optional index) null) consuma-lavoro-full-text))
(defun consuma-lavoro-full-text (space &optional (units 1))
  "Pre: spazio esclusivo. Post: lavoro incrementato entro budget; nessun overflow.
RESOURCE-EXHAUSTED prima del superamento del budget."
  (when (> units (- (spazio-full-text-work-limit space) (spazio-full-text-work space)))
    (error 'resource-exhausted :reason :fulltext-analysis-work))
  (incf (spazio-full-text-work space) units)
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text vettore-u32 index scalare) index) aggiungi-scalare))
(defun aggiungi-scalare (space buffer count scalar)
  "Pre: spazio esclusivo e scalare Unicode. Post: un valore aggiunto, nuova lunghezza.
RESOURCE-EXHAUSTED prima di scrivere oltre la capacita; conteggio del lavoro esplicito."
  (when (= count (length buffer)) (error 'resource-exhausted :reason :fulltext-scalar-capacity))
  (consuma-lavoro-full-text space)
  (setf (aref buffer count) scalar)
  (1+ count))
