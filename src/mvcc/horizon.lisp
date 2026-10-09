;;; OWNER: il contesto di commit conserva la prenotazione e il CSN originale degli eventi.
;;; SHARED: mutex per Archivio, una sezione breve per riserva/completamento, mai per GET.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (registro-csn) csn-slot) trova-slot-csn))
(defun trova-slot-csn (registry)
  "Pre: mutex posseduto e almeno un credito libero. Post: slot zero, senza modifica.
Visita al massimo K parole; INVARIANT-VIOLATION se il contatore non corrisponde agli slot."
  (let* ((slots (registro-csn-slots registry)) (capacity (length slots))
         (cursor (registro-csn-cursor registry)))
    (dotimes (step capacity)
      (let* ((candidate (+ cursor step))
             (slot (if (< candidate capacity) candidate (- candidate capacity))))
        (when (zerop (aref slots slot)) (return-from trova-slot-csn slot))))
    (guasto-registro-csn registry :csn-credit-accounting)))

;;; REQ: REQ-MVC-008 REQ-MVC-006 REQ-AFF-008
(declaim (ftype (function (prenotazione-csn) u64) riserva-csn))
(defun riserva-csn (reservation)
  "Pre: contenuto del lotto fissato; contesto libero/concluso senza vecchi consumatori.
Post: CSN nuovo e slot registrati indivisibilmente; restituisce il CSN da sigillare.
RESOURCE-EXHAUSTED senza mutazione per capacità/u64 esauriti; INVALID-ARGUMENT se già attiva."
  (let ((registry (prenotazione-csn-registry reservation)))
    (sb-thread:with-mutex ((registro-csn-mutex registry))
      (esigi-registro-csn registry)
      (when (eq (prenotazione-csn-state reservation) :attiva)
        (error 'invalid-argument :reason :csn-reservation-active))
      (let* ((slots (registro-csn-slots registry)) (capacity (length slots))
             (counters (registro-csn-counters registry)) (last (aref counters 0)))
        (declare (type u64 last))
        (when (= (registro-csn-pending registry) capacity)
          (error 'resource-exhausted :reason :csn-capacity))
        (when (= last +max-csn+)
          (error 'resource-exhausted :reason :csn-sequence-exhausted))
        (let ((slot (trova-slot-csn registry)) (next (1+ last)) (complete nil))
          (declare (type u64 next))
          (unwind-protect
               (progn
                 (setf (aref slots slot) next (aref counters 0) next
                       (aref (prenotazione-csn-word reservation) 0) next
                       (prenotazione-csn-slot reservation) slot
                       (prenotazione-csn-state reservation) :attiva
                       (registro-csn-cursor registry) (if (= (1+ slot) capacity) 0 (1+ slot)))
                 (incf (registro-csn-pending registry))
                 (setf complete t)
                 next)
            (unless complete (setf (registro-csn-state registry) :faulted))))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(declaim (ftype (function (registro-csn csn-slot) u64) orizzonte-dopo-rilascio))
(defun orizzonte-dopo-rilascio (registry released-slot)
  "Pre: mutex posseduto, slot attivo verificato. Post: H candidato senza mutazioni.
Scansione K parole; INVARIANT-VIOLATION per conteggi/frontiere incoerenti, con fail-stop."
  (let* ((slots (registro-csn-slots registry)) (counters (registro-csn-counters registry))
         (last (aref counters 0)) (old (aref counters 1)) (minimum +max-csn+) (remaining 0))
    (declare (type u64 last old minimum))
    (dotimes (slot (length slots))
      (let ((csn (aref slots slot)))
        (declare (type u64 csn))
        (unless (zerop csn)
          (unless (and (< old csn) (<= csn last))
            (guasto-registro-csn registry :csn-frontier-inconsistent))
          (unless (= slot released-slot)
            (incf remaining)
            (setf minimum (min minimum csn))))))
    (unless (= (1+ remaining) (registro-csn-pending registry))
      (guasto-registro-csn registry :csn-credit-accounting))
    (let ((next (if (zerop remaining) last (1- minimum))))
      (declare (type u64 next))
      (unless (<= old next last)
        (guasto-registro-csn registry :csn-horizon-regression))
      next)))

;;; REQ: REQ-MVC-008 REQ-MVC-005 REQ-AFF-004
(declaim (ftype (function (prenotazione-csn u64) (values u64 boolean &optional)) concludi-csn))
(defun concludi-csn (reservation expected-csn)
  "Pre: commit pubblicato per intero o annullato con dati inaccessibili; evento col CSN originale.
Post: credito rilasciato, H monotono; restituisce H e se è avanzato. Non pubblica dati.
INVALID-ARGUMENT senza mutazione per completamenti duplicati/tardivi o identità errata."
  (let ((registry (prenotazione-csn-registry reservation)))
    (sb-thread:with-mutex ((registro-csn-mutex registry))
      (esigi-registro-csn registry)
      (unless (and (eq (prenotazione-csn-state reservation) :attiva)
                   (plusp expected-csn)
                   (= expected-csn (aref (prenotazione-csn-word reservation) 0)))
        (error 'invalid-argument :reason :csn-completion-identity))
      (let* ((slot (prenotazione-csn-slot reservation)) (slots (registro-csn-slots registry))
             (counters (registro-csn-counters registry)) (old (aref counters 1)))
        (declare (type u64 old))
        (unless (and (< slot (length slots)) (= (aref slots slot) expected-csn))
          (guasto-registro-csn registry :csn-slot-identity))
        (let ((next (orizzonte-dopo-rilascio registry slot)) (complete nil))
          (declare (type u64 next))
          (unwind-protect
               (progn
                 (setf (aref slots slot) 0 (aref counters 1) next
                       (prenotazione-csn-state reservation) :conclusa)
                 (decf (registro-csn-pending registry))
                 (setf complete t)
                 (values next (> next old)))
            (unless complete (setf (registro-csn-state registry) :faulted))))))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(declaim (ftype (function (registro-csn) (values u64 u64 (integer 0 65536) &optional))
                leggi-orizzonte))
(defun leggi-orizzonte (registry)
  "Pre: registro sano. Post: H, ultimo CSN e pendenti coerenti, sotto lo stesso mutex.
INVARIANT-VIOLATION dopo FAULTED; non registra snapshot e non attende commit."
  (sb-thread:with-mutex ((registro-csn-mutex registry))
    (esigi-registro-csn registry)
    (let ((counters (registro-csn-counters registry)))
      (values (aref counters 1) (aref counters 0) (registro-csn-pending registry)))))

;;; REQ: REQ-MVC-008
(declaim (ftype (function (prenotazione-csn)
                         (values (member :libera :attiva :conclusa) u64 &optional))
                leggi-prenotazione))
(defun leggi-prenotazione (reservation)
  "Pre: registro sano. Post: stato e CSN coerenti (zero prima della prima riserva).
Il consumatore conserva il CSN del proprio evento; non lo rilegge dopo un riuso."
  (let ((registry (prenotazione-csn-registry reservation)))
    (sb-thread:with-mutex ((registro-csn-mutex registry))
      (esigi-registro-csn registry)
      (values (prenotazione-csn-state reservation) (aref (prenotazione-csn-word reservation) 0)))))

;;; REQ: REQ-MVC-008 REQ-MVC-005
(declaim (ftype (function (registro-csn u64) boolean) orizzonte-raggiunto-p))
(defun orizzonte-raggiunto-p (registry csn)
  "Pre: CSN catturato da uno snapshot già registrato. Post: H>=CSN sotto mutex, senza attesa.
INVALID-ARGUMENT per CSN futuro; la registrazione e il parcheggio spettano al manager snapshot."
  (sb-thread:with-mutex ((registro-csn-mutex registry))
    (esigi-registro-csn registry)
    (let ((counters (registro-csn-counters registry)))
      (when (> csn (aref counters 0))
        (error 'invalid-argument :reason :csn-snapshot-in-future))
      (>= (aref counters 1) csn))))
