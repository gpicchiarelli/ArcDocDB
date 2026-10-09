;;; OWNER: buffer di input privato del writer; dati stabili verificati anche dai reader.
;;; SHARED: nessuna modifica nei predicati; nessuna interpretazione del layout v1.
(in-package #:arcdocdb.index.slots)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-LIM-001 REQ-LIM-003 REQ-AFF-004
(declaim (inline metadati-chiave-validi-p record-slot-valido-p
                 contenuto-vivo-valido-p contenuto-vuoto-p esigi-contenuto-slot))
(declaim (ftype (function (u64) boolean) metadati-chiave-validi-p))
(defun metadati-chiave-validi-p (key)
  "Pre: parola v2 privata o acquisita coerentemente. Post: T per chiave viva rappresentabile.
NIL per flag, riservato, lunghezza o intervallo invalido; non verifica l'arena effettiva."
  (let ((length (ldb (byte 16 32) key)) (offset (ldb (byte 32 0) key)))
    (and (= 1 (ldb (byte 8 48) key)) (zerop (ldb (byte 8 56) key))
         (plusp length) (<= (+ offset length) #x100000000))))

;;; REQ: REQ-IDX-001 REQ-LIM-001 REQ-LIM-003 REQ-AFF-004
(declaim (ftype (function (u64 u64 u64) boolean) record-slot-valido-p))
(defun record-slot-valido-p (location key length-word)
  "Pre: parole v2 private o acquisite coerentemente. Post: T per limiti record/location validi.
NIL per riservato, lunghezza/documento o fine fuori segmento; non legge bytes storage."
  (let ((key-length (ldb (byte 16 32) key)) (record-length (ldb (byte 32 0) length-word))
        (offset (ldb (byte 32 0) location)))
    (and (zerop (ldb (byte 32 32) length-word))
         (<= (+ +header-bytes+ key-length) record-length +max-record-bytes+)
         (<= (- record-length +header-bytes+ key-length) +max-document-bytes+)
         (<= (+ offset record-length) #xffffffff))))

;;; REQ: REQ-IDX-001 REQ-LIM-001 REQ-LIM-003 REQ-AFF-004
(declaim (ftype (function (u64 u64 u64 u64 u64 boolean) boolean) contenuto-vivo-valido-p))
(defun contenuto-vivo-valido-p (csn location key length-word end retained)
  "Pre: campi privati o acquisiti con seqlock stabile; nessuna lettura condivisa qui.
Post: T solo per contenuto v2 vivo e rappresentabile; NIL senza effetti su dato invalido.
Non verifica appartenenza all'arena, bytes del record, manifest o decisione di commit."
  (and (plusp csn) (metadati-chiave-validi-p key) (record-slot-valido-p location key length-word)
       (if retained (> end csn) (zerop end))))

;;; REQ: REQ-IDX-003 REQ-IDX-006
(declaim (ftype (function (u64 u64 u64 u64 u64) boolean) contenuto-vuoto-p))
(defun contenuto-vuoto-p (csn location key length-word end)
  "Pre: campi privati o acquisiti coerentemente. Post: T solo se tutti i campi sono zero.
Nessun effetto; lo slot vuoto non è un tombstone dello storage."
  (zerop (logior csn location key length-word end)))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-004
(declaim (ftype (function (banco-slot contenuto-slot) null) esigi-contenuto-slot))
(defun esigi-contenuto-slot (bank source)
  "Pre: SOURCE di cinque parole esclusivo del writer, non modificato per tutta l'operazione.
Post: contenuto vivo v2 valido; INVALID-ARGUMENT senza toccare il banco su input invalido."
  (unless (contenuto-vivo-valido-p (aref source 0) (aref source 1) (aref source 2)
                                 (aref source 3) (aref source 4) (banco-slot-retained bank))
    (error 'invalid-argument :reason :index-slot-payload))
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (inline verifica-campi-slot))
(declaim (ftype (function (banco-slot u64 u64 u64 u64 u64) boolean) verifica-campi-slot))
(defun verifica-campi-slot (bank csn location key length-word end)
  "Pre: dati interni stabili dopo seqlock o sotto writer esclusivo.
Post: T vivo, NIL completamente vuoto; altrimenti FAULTED e INVARIANT-VIOLATION."
  (cond ((contenuto-vuoto-p csn location key length-word end) nil)
        ((contenuto-vivo-valido-p csn location key length-word end (banco-slot-retained bank)) t)
        (t (guasto-slot bank :index-slot-inconsistent))))
