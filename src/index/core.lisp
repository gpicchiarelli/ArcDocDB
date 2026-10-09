;;; OWNER: controlli locali del writer; i reader pubblicano solo guasti terminali.
;;; SHARED: nessun accesso a root, arena, risorsa esterna o coordinamento tra Serie.
(in-package #:arcdocdb.index.slots)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot) null) invalida-banco-slot))
(defun invalida-banco-slot (bank)
  "Pre: confine fidato o difetto interno; invalidazione ripetibile senza mutex.
Post: salute terminale FAULTED, nessuna parola cancellata; non isola da sola la Serie."
  (sb-thread:barrier (:write))
  (setf (banco-slot-health bank) :faulted)
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot keyword) nil) guasto-slot))
(defun guasto-slot (bank reason)
  "Pre: invariante del banco violata. Post: FAULTED prima dell'errore tipizzato.
INVARIANT-VIOLATION propagata al confine della Serie; nessun tentativo di riparazione."
  (invalida-banco-slot bank)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (inline esigi-banco-sano base-slot esigi-banco-writer))
(declaim (ftype (function (banco-slot) null) esigi-banco-sano))
(defun esigi-banco-sano (bank)
  "Pre: banco canonico. Post: salute acquisita OPEN, senza mutex o scrittura.
INVARIANT-VIOLATION se terminale; il chiamante scarta tutti i dati letti."
  (let ((health (banco-slot-health bank)))
    (sb-thread:barrier (:read))
    (unless (eq health :open) (guasto-slot bank :index-slot-faulted)))
  nil)

;;; REQ: REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (banco-slot integer) fixnum) base-slot))
(defun base-slot (bank slot)
  "Pre: banco canonico; slot fornito dal sondaggio. Post: base valida nell'array contiguo.
INVALID-ARGUMENT per slot fuori capacità, prima di leggere o modificare i campi."
  (unless (<= 0 slot (1- (banco-slot-capacity bank)))
    (error 'invalid-argument :reason :index-slot-range))
  (* slot (if (banco-slot-retained bank) 6 5)))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (banco-slot) null) esigi-banco-writer))
(defun esigi-banco-writer (bank)
  "Pre: gettone writer della Serie; nessun altro writer modifica o congela il banco.
Post: sano e scrivibile; INVALID-ARGUMENT se FROZEN, INVARIANT-VIOLATION se FAULTED."
  (esigi-banco-sano bank)
  (unless (eq (banco-slot-state bank) :writable)
    (error 'invalid-argument :reason :index-slot-frozen))
  nil)

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (banco-slot) null) congela-banco-slot))
(defun congela-banco-slot (bank)
  "Pre: writer esclusivo, nessuna mutazione in corso; usare prima della sostituzione della root.
Post: FROZEN permanente, dati ancora leggibili. Ripetibile; FAULTED rifiutato.
Non pubblica una directory e non congela altri banchi del frammento."
  (esigi-banco-sano bank)
  (sb-thread:barrier (:write))
  (setf (banco-slot-state bank) :frozen)
  (esigi-banco-sano bank)
  nil)
