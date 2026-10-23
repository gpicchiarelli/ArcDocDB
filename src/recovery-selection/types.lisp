;;; OWNER: buffer chiave e due tuple privati del worker; nessun oggetto per documento.
;;; SHARED: nessuna pubblicazione dell'accumulatore; solo il risultato scalare puo essere consegnato.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(defconstant +selection-words+ 7)
;;; REQ: REQ-REC-001 REQ-AFF-008
(defconstant +selection-payload+ (* 16 +selection-words+))
;;; REQ: REQ-REC-001 REQ-AFF-008
(deftype parole-selezione () `(simple-array (unsigned-byte 64) (,+selection-words+)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-008
(defstruct (selettore-versione-recuperata
             (:constructor %make-selettore (key current candidate)) (:conc-name selection-) (:copier nil))
  "Pre: payload prenotato, worker esclusivo. Post: chiave privata e due tuple di sette u64.
Tuple: CSN, segment-id, offset fisico, lunghezza, tipo/flag/versione, CRC header e CRC body.
FAULTED terminale; AMBIGUOUS impedisce la consegna finche un CSN maggiore non domina i candidati."
  (key #() :type octets :read-only t)
  (current (make-array +selection-words+ :element-type '(unsigned-byte 64)) :type parole-selezione :read-only t)
  (candidate (make-array +selection-words+ :element-type '(unsigned-byte 64)) :type parole-selezione :read-only t)
  (length 0 :type index)
  (state :empty :type (member :empty :ready :selected :ambiguous :faulted)))

;;; REQ: REQ-REC-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (&key (:key-capacity integer) (:budget-payload integer))
                         selettore-versione-recuperata) crea-selettore-versione-recuperata))
(defun crea-selettore-versione-recuperata
    (&key (key-capacity +max-key-bytes+) (budget-payload (+ +max-key-bytes+ +selection-payload+)))
  "Pre: configurazione del worker, fuori dalle richieste. Post: workspace vuoto, payload <= budget prima degli array.
INVALID-ARGUMENT per capacita/budget; RESOURCE-EXHAUSTED per key-capacity +112 byte oltre budget.
Il payload esclude oggetto/header/GC e non e RSS; nessun file, indice o buffer documento trattenuto."
  (unless (and (<= 1 key-capacity +max-key-bytes+) (<= 0 budget-payload most-positive-fixnum))
    (error 'invalid-argument :reason :recovery-selection-configuration))
  (when (> (+ key-capacity +selection-payload+) budget-payload)
    (error 'resource-exhausted :reason :recovery-selection-payload-budget))
  (%make-selettore (make-array key-capacity :element-type '(unsigned-byte 8) :initial-element 0)
                  (make-array +selection-words+ :element-type '(unsigned-byte 64) :initial-element 0)
                  (make-array +selection-words+ :element-type '(unsigned-byte 64) :initial-element 0)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(declaim (ftype (function (selettore-versione-recuperata) null) esigi-selettore-pronto))
(defun esigi-selettore-pronto (selector)
  "Pre: worker esclusivo, nessuna inizializzazione/considerazione concorrente. Post: chiave inizializzata e stato sano.
INVALID-ARGUMENT per EMPTY/FAULTED; stato privato fuori tipo impedito da safety3, nessun reset implicito."
  (unless (member (selection-state selector) '(:ready :selected :ambiguous))
    (error 'invalid-argument :reason :recovery-selection-state))
  (unless (<= 1 (selection-length selector) (length (selection-key selector)))
    (setf (selection-state selector) :faulted)
    (error 'invariant-violation :reason :recovery-selection-key-shape))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata keyword) nil) guasto-selettore))
(defun guasto-selettore (selector reason)
  "Pre: invariante privata violata. Post: FAULTED prima della condizione, nessun risultato utilizzabile.
Ripetibile; il confine della Serie resta responsabile del proprio fail-stop."
  (setf (selection-state selector) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata parole-selezione) null) verifica-tupla-selezione))
(defun verifica-tupla-selezione (selector words)
  "Pre: tupla privata non vuota. Post: tag, offset/lunghezza e checksum rappresentabili.
Incoerenza interna => selettore FAULTED e INVARIANT-VIOLATION; nessun controllo sui dati nel predicato."
  (let ((tag (aref words 4)) (offset (aref words 2)) (size (aref words 3)))
    (unless (and (member (ldb (byte 8 0) tag) '(1 2)) (member (ldb (byte 8 16) tag) '(1 2))
                 (zerop (ash tag -24)))
      (guasto-selettore selector :recovery-selection-tag))
    (unless (and (<= arcdocdb.storage.format:+segment-header-bytes+ offset most-positive-fixnum)
                 (<= (1+ arcdocdb.record:+header-bytes+) size arcdocdb.record:+max-record-bytes+)
                 (<= (+ offset size) most-positive-fixnum)
                 (<= (aref words 5) #xffffffff) (<= (aref words 6) #xffffffff))
      (guasto-selettore selector :recovery-selection-tuple)))
  nil)
