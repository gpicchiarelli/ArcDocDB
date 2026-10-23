;;; OWNER: compito I/O esclusivo; P autorevole dal CONTROL, nessuna ipotesi di EOF fisico.
;;; SHARED: capacità/manifest congelati; solo lo scratch privato viene scritto.
(in-package #:arcdocdb.recovery.closed)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (index index index u32 index) null) verifica-budget-closed))
(defun verifica-budget-closed (chunk bytes batches batch-records batch-bytes)
  "Pre: configurazione tipizzata del lettore. Post: chunk/header e limiti dei lotti coerenti prima di I/O.
INVALID-ARGUMENT per chunk/batch/count nulli o budget insufficienti; nessuna mutazione.
Vale anche sul vuoto e per compaction, prima di leggere l'origine dall'header."
  (unless (and (plusp chunk) (<= +segment-header-bytes+ bytes +segment-max-bytes+) (plusp batches) (plusp batch-records)
               (>= batch-bytes (+ +header-bytes+ +seal-bytes+)))
    (error 'invalid-argument :reason :closed-recovery-arguments))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (control-recuperato file-io u64 octets index index index u32 index u32) index)
                verifica-lettura-closed))
(defun verifica-lettura-closed (control input id scratch chunk bytes batches batch-records batch-bytes outcomes)
  "Pre: CONTROL autorevole, capacità stabili e scratch esclusivo. Post: P CLOSED e preflight senza I/O.
Controlla alias, range, tutti i budget e backend prima della lettura; non sostituisce P con EOF.
Errori di argomenti/risorse/capacità tipizzati; CORRUPTION-DETECTED per frontiera impossibile."
  (let* ((previous (arcdocdb.control::control-recuperato-input control))
         (view (arcdocdb.control::control-recuperato-view control)))
    (arcdocdb.io::esigi-aperto previous :input)
    (arcdocdb.io::esigi-aperto input :input)
    (when (eq scratch (arcdocdb.get::vista-get-serie-identity view))
      (error 'invalid-argument :reason :closed-recovery-alias))
    (verifica-budget-closed chunk bytes batches batch-records batch-bytes)
    (unless (eq (arcdocdb.io::file-backend previous) (arcdocdb.io::file-backend input))
      (error 'invalid-argument :reason :closed-recovery-backend))
    (multiple-value-bind (state prefix count) (trova-segmento (manifest-control-recuperato control) id)
      (unless (eq state :closed) (error 'invalid-argument :reason :closed-recovery-state))
      (unless (<= +segment-header-bytes+ prefix +segment-max-bytes+)
        (error 'corruption-detected :reason :closed-recovery-prefix))
      (when (> prefix bytes) (error 'resource-exhausted :reason :closed-recovery-byte-budget))
      (when (> count outcomes) (error 'resource-exhausted :reason :closed-recovery-closure-budget))
      (check-range scratch 0 prefix)
      (verifica-capienza-lettura input (max +segment-header-bytes+ (min (- prefix +segment-header-bytes+) chunk)))
      (the index prefix))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-002 REQ-AFF-002
(declaim (ftype (function (control-recuperato file-io u64 octets)
                         (values (member 1 2) (member 1 2) &optional)) leggi-header-closed))
(defun leggi-header-closed (control input id scratch)
  "Pre: preflight conclusa, compito I/O. Post: header letto una volta sul medesimo FD readonly.
Verifica Serie/ID u64 completi, CRC, riservati, origine e versione prima del corpo.
Condizioni originali propagate, INVARIANT-VIOLATION per ritorno interno impossibile; nessuna scrittura su file."
  (check-range scratch 0 +segment-header-bytes+)
  (let ((next (leggi-esatto input scratch 0 +segment-header-bytes+ 0)))
    (unless (= next +segment-header-bytes+)
      (error 'invariant-violation :reason :closed-recovery-header-read)))
  (multiple-value-bind (next version origin created-offset)
      (verifica-header-segmento scratch 0 +segment-header-bytes+
       (arcdocdb.get::vista-get-serie-identity (arcdocdb.control::control-recuperato-view control)) id)
    (unless (and (= next +segment-header-bytes+) (< created-offset next))
      (error 'invariant-violation :reason :closed-recovery-header))
    (values (the (member 1 2) version) (the (member 1 2) origin))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (file-io index octets index) null) leggi-corpo-closed))
(defun leggi-corpo-closed (input prefix scratch chunk)
  "Pre: header già verificato, P autorevole, compito I/O e scratch esclusivo. Post: corpo letto fino a P esatto.
Nessun byte oltre P, rilettura header o classificazione TAIL; ciclo CEILING((P-64)/chunk).
Condizioni originali propagate senza retry, close, troncatura o risultato parziale."
  (unless (and (plusp chunk) (>= prefix +segment-header-bytes+))
    (error 'invalid-argument :reason :closed-recovery-read-range))
  (check-range scratch 0 prefix)
  (loop repeat (ceiling (- prefix +segment-header-bytes+) chunk)
        for start from +segment-header-bytes+ by chunk for end = (min prefix (+ start chunk))
        do (let ((next (leggi-esatto input scratch start end start)))
             (unless (= next end)
               (error 'invariant-violation :reason :closed-recovery-read :offset start))))
  (arcdocdb.io::esigi-aperto input :input)
  nil)
