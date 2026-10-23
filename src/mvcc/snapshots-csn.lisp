;;; OWNER: solo il coordinamento snapshot usa l'API pubblica del registro CSN dell'Archivio.
;;; SHARED: ordine snapshot->CSN, un tentativo per campione; mai nel GET corrente o nel lookup.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-CON-004 REQ-AFF-004
(declaim (ftype (function (registro-snapshot) (values u64 u64 &optional)) frontiere-snapshot))
(defun frontiere-snapshot (registry)
  "Pre: mutex snapshot posseduto, registro sano dell'Archivio. Post: H e ultimo CSN coerenti.
RESOURCE-EXHAUSTED :CSN-BUSY senza attesa. Guasto CSN invalida gli snapshot e rilancia la condizione.
Conversione u32/u64 solo nel coordinamento; non legge slot o mutex privati del componente CSN."
  (esigi-snapshot-sano registry)
  (handler-case
      (multiple-value-bind (last-high last-low horizon-high horizon-low)
          (leggi-frontiere-csn (registro-snapshot-csns registry))
        (declare (type u32 last-high last-low horizon-high horizon-low))
        (let ((horizon (logior (ash horizon-high 32) horizon-low))
              (last (logior (ash last-high 32) last-low)))
          (declare (type u64 horizon last))
          (esigi-snapshot-sano registry)
          (when (> horizon last) (guasto-snapshot registry :snapshot-csn-frontier-inconsistent))
          (values horizon last)))
    (invariant-violation (condition)
      (invalida-registro-snapshot registry)
      (error condition))))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (registro-snapshot) (values boolean u64 u64 &optional))
                tenta-cattura-snapshot))
(defun tenta-cattura-snapshot (registry)
  "Pre: soglia già annunciata dal chiamante. Post: T,H,CSN se acquisito; NIL,0,0 solo per CSN-BUSY.
Nessun retry, pin o modifica. Il chiamante deve ripristinare la sola soglia provvisoria su NIL.
Ogni altra condizione resta propagata, senza trasformarla in normale contesa."
  (handler-case
      (multiple-value-bind (horizon csn) (frontiere-snapshot registry)
        (values t horizon csn))
    (resource-exhausted (condition)
      (unless (eq (error-reason condition) :csn-busy) (error condition))
      (values nil 0 0))))

;;; REQ: REQ-MVC-005 REQ-CON-004
(declaim (ftype (function (registro-snapshot u64) boolean) orizzonte-snapshot-raggiunto-p))
(defun orizzonte-snapshot-raggiunto-p (registry csn)
  "Pre: CSN dello snapshot registrato, mutex snapshot posseduto.
Post: H>=CSN da frontiere coerenti; INVALID-ARGUMENT per CSN futuro, CSN-BUSY senza attesa."
  (multiple-value-bind (horizon last) (frontiere-snapshot registry)
    (when (> csn last) (error 'invalid-argument :reason :csn-snapshot-in-future))
    (>= horizon csn)))
