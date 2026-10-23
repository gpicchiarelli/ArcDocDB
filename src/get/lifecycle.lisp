;;; OWNER: worker esegue la richiesta in UNWIND-PROTECT; risultato privato fino alla conferma.
;;; SHARED: contesto read proprio, nessuna coda, attesa o scrittura comune fra Serie.
(in-package #:arcdocdb.get)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-004 REQ-CMP-007
(declaim (ftype (function (contesto-get keyword) nil) guasto-get))
(defun guasto-get (context reason)
  "Pre: incoerenza interna del compito. Post: FAULTED terminale prima della condizione.
Il cleanup rilascia EBR; il confine del worker deve isolare Serie/Archivio secondo la causa."
  (setf (contesto-get-state context) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-CON-004 REQ-AFF-004 REQ-CMP-007
(declaim (ftype (function (contesto-get get-state) null) esigi-stato-get))
(defun esigi-stato-get (context state)
  "Pre: worker esclusivo. Post: stato richiesto ed EBR coerente; nessun accesso fisico qui.
INVALID-ARGUMENT per ordine/riuso; incoerenza interna rende FAULTED prima di segnalare."
  (unless (eq (contesto-get-state context) state)
    (error 'invalid-argument :reason :get-worker-state))
  (unless (eq (stato-contesto-lettura (contesto-get-reader context))
              (if (eq state :idle) :idle :active))
    (guasto-get context :get-read-state))
  nil)

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (contesto-get) null) abbandona-get))
(defun abbandona-get (context)
  "Pre: stesso worker, ultimo accesso concluso; cleanup esterno installato prima di AVVIA-GET.
Post: pin e riferimenti fisici scartati, scratch logico zero; nessun risultato autorizzato.
IDLE idempotente; FAULTED permanente. Interruzione del cleanup lascia FAULTED."
  (let ((faulted (or (eq (contesto-get-state context) :faulted)
                     (eq (stato-contesto-lettura (contesto-get-reader context)) :faulted))))
    (setf (contesto-get-state context) :faulted)
    (abbandona-lettura (contesto-get-reader context))
    (setf (contesto-get-view context) nil (contesto-get-key context) nil
          (contesto-get-snapshot-p context) nil
          (contesto-get-value-start context) 0 (contesto-get-value-end context) 0)
    (fill (contesto-get-content context) 0)
    (fill (contesto-get-limit context) 0)
    (unless faulted (setf (contesto-get-state context) :idle)))
  nil)

;;; REQ: REQ-CCH-002 REQ-MVC-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get octets index) index) copia-valore-get))
(defun copia-valore-get (context destination start)
  "Pre: VERIFIED, destinazione esclusiva, distinta da buffer del compito e chiave.
Post: copia provvisoria del valore, stato COPIED, fine output; nessun dato ancora consegnabile.
Concludere con tempo fresco dopo la copia; su errore/uscita non locale scartare l'output."
  (esigi-stato-get context :verified)
  (let ((completed nil))
    (unwind-protect
         (let* ((bytes (contesto-get-bytes context)) (vs (contesto-get-value-start context))
                (ve (contesto-get-value-end context)))
           (when (or (eq destination bytes) (eq destination (contesto-get-proof context))
                     (eq destination (contesto-get-key context)))
             (error 'invalid-argument :reason :get-output-alias))
           (unless (< vs ve) (guasto-get context :get-value-range))
           (unless (<= ve (length bytes)) (guasto-get context :get-value-overflow))
           (let ((size (- ve vs)))
             (check-range destination start (length destination))
             (when (> size (- (length destination) start))
               (error 'invalid-argument :reason :get-output-range))
             (let ((end (the index (+ start size))))
               (check-range destination start end)
               (replace destination bytes :start1 start :end1 end :start2 vs :end2 ve)
               (setf (contesto-get-state context) :copied completed t)
               end)))
      (unless completed (abbandona-get context)))))

;;; REQ: REQ-MVC-001 REQ-MVC-004 REQ-MVC-005 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get u64)
                         (values (member :found :absent :history-required :retry) index &optional))
                concludi-get))
(defun concludi-get (context now)
  "Pre: COPIED, ABSENT, HISTORY-REQUIRED o RETRY ammesso; NOW fresco dopo ogni copia/accesso.
Post: verifica snapshot finale e rilascio EBR prima del ritorno; FOUND autorizza la copia privata.
ABSENT solo GET corrente. Ogni condizione/uscita non locale invalida il risultato e libera il pin."
  (let* ((state (contesto-get-state context))
         (result (case state
                   (:copied :found) (:absent :absent) (:history-required :history-required)
                   (:retry :retry)
                   (otherwise (error 'invalid-argument :reason :get-result-not-ready))))
         (size (if (eq state :copied)
                   (- (contesto-get-value-end context) (contesto-get-value-start context)) 0)))
    (unwind-protect
         (progn
           (esigi-stato-get context state)
           (when (and (eq state :absent) (contesto-get-snapshot-p context))
             (guasto-get context :get-snapshot-absence))
           (setf (contesto-get-state context) :finishing)
           (concludi-lettura (contesto-get-reader context) now)
           (values result size))
      (abbandona-get context))))
