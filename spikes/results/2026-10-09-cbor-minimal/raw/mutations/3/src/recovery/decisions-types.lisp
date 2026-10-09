;;;; Oggetti privati del risultato; nessun accessore pubblico espone vettori.
;;; OWNER: singola ricostruzione, poi proprietario della tabella restituita.
;;; SHARED: nessuna scrittura condivisa; i campi del risultato sono sola lettura.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-FOR-003
(defstruct (decision-entry
            (:constructor %make-decision-entry (txid csn count participants source-offset))
            (:conc-name %entry-))
  "Pre: DECISION verificata; ID16 copiati, ordinati e distinti, COUNT >=2.
Post: entry posseduta con campi read-only; nessun alias al buffer di input.
I tipi dichiarati sono precondizioni controllate dal runtime con safety 3."
  (txid 0 :type u64 :read-only t)
  (csn 0 :type u64 :read-only t)
  (count 0 :type u16 :read-only t)
  (participants (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  (source-offset 0 :type u64 :read-only t))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(defstruct (decision-table (:constructor %make-decision-table (entries)) (:conc-name %table-))
  "Pre: ENTRIES privato, ordinato per TXID unici; entry verificate e possedute.
Post: tabella completa, campi read-only; nessun vettore esposto dalle API pubbliche.
I tipi dichiarati sono precondizioni rilevate dal runtime; nessun effetto durevole."
  (entries (make-array 0 :element-type t) :type simple-vector :read-only t))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (decision-entry) null) check-entry-shape))
(defun check-entry-shape (entry)
  "Pre: ENTRY privata. Post: almeno due partecipanti e vettore ID16 della misura esatta.
Segnala INVARIANT-VIOLATION per costruzione interna incoerente; nessuna modifica."
  (unless (>= (%entry-count entry) 2)
    (error 'invariant-violation :reason :decision-entry-count))
  (unless (= (length (%entry-participants entry)) (* (%entry-count entry) +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-entry-size))
  nil)
