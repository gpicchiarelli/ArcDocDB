;;; OWNER: worker esegue il compito in UNWIND-PROTECT, senza parcheggi o rete nella sezione.
;;; SHARED: verifica snapshot in sola lettura; nessuna location/risorsa viene conservata qui.
(in-package #:arcdocdb.read)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-MVC-005 REQ-AFF-008
(declaim (inline verifica-identita-lettura))
(declaim (ftype (function (contesto-lettura (or null contesto-snapshot) u64) null)
                verifica-identita-lettura))
(defun verifica-identita-lettura (context snapshot generation)
  "Pre: input della richiesta; contesto inattivo. Post: identità associata all'Archivio corretto.
INVALID-ARGUMENT prima di annunciare EBR per generazione zero, estranea o inattesa."
  (if snapshot
      (unless (and (plusp generation)
                   (snapshot-del-registro-p snapshot (contesto-lettura-snapshots context)))
        (error 'invalid-argument :reason :read-snapshot-identity))
      (unless (zerop generation) (error 'invalid-argument :reason :read-current-generation)))
  nil)

;;; REQ: REQ-CON-004 REQ-CMP-005 REQ-CMP-007 REQ-MVC-004 REQ-MVC-005 REQ-AFF-008
(declaim (inline avvia-lettura copia-limite-lettura))
(declaim (ftype (function (contesto-lettura (or null contesto-snapshot) u64 u64) boolean)
                avvia-lettura))
(defun avvia-lettura (context snapshot generation now)
  "Pre: worker esclusivo, nessun indice/location già letto; NOW fresco e monotono.
Post: T ammette il lookup; NIL richiede riaccodare senza location. Un tentativo EBR soltanto.
Snapshot verificato dopo ingresso; UNWIND-PROTECT esterno già installato prima della chiamata."
  (esigi-lettura-inattiva context)
  (verifica-identita-lettura context snapshot generation)
  (let ((words (contesto-lettura-words context)) (ready nil))
    (unwind-protect
         (progn
           (setf (contesto-lettura-state context) :entering
                 (contesto-lettura-snapshot context) snapshot
                 (aref words +word-generation+) generation
                 (aref words +word-start-time+) now)
           (when (entra-epoca (contesto-lettura-reader context))
             (when snapshot
               (verifica-snapshot-in-buffer snapshot generation now words +word-snapshot-csn+))
             (setf (contesto-lettura-state context) :active ready t)))
      (unless ready (libera-contesto-lettura context)))
    ready))

;;; REQ: REQ-MVC-005 REQ-AFF-008
(declaim (ftype (function (contesto-lettura read-words integer) boolean) copia-limite-lettura))
(defun copia-limite-lettura (context destination index)
  "Pre: lookup nel compito ammesso; DESTINATION privato del worker, indice valido.
Post: T copia il CSN snapshot senza ritorno u64; NIL indica GET corrente e non scrive.
INVALID-ARGUMENT per range/stato; nessuna scelta della versione senza controllare il booleano."
  (esigi-lettura-attiva context)
  (unless (<= 0 index (1- (length destination)))
    (error 'invalid-argument :reason :read-result-range))
  (if (contesto-lettura-snapshot context)
      (progn
        (setf (aref destination index) (aref (contesto-lettura-words context) +word-snapshot-csn+))
        t)
      nil))

;;; REQ: REQ-CON-004 REQ-MVC-004 REQ-MVC-005 REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (contesto-lettura u64) null) concludi-lettura))
(defun concludi-lettura (context now)
  "Pre: lookup finito, anche su miss; bytes eventualmente copiati in risposta privata, NOW fresco.
Post: controllo snapshot finale riuscito ed epoca libera. Solo allora consegnare il risultato.
Su scadenza/fine/errore nessun risultato ammesso; cleanup anche se la verifica fallisce."
  (unless (eq (contesto-lettura-state context) :active)
    (error 'invalid-argument :reason :read-context-not-active))
  (unwind-protect
       (let ((words (contesto-lettura-words context)) (snapshot (contesto-lettura-snapshot context)))
         (esigi-lettura-attiva context)
         (when (< now (aref words +word-start-time+))
           (error 'invalid-argument :reason :read-clock-regression))
         (when snapshot
           (verifica-snapshot-in-buffer snapshot (aref words +word-generation+)
                                        now words +word-confirmed-csn+)
           (unless (= (aref words +word-snapshot-csn+) (aref words +word-confirmed-csn+))
             (guasto-contesto-lettura context :read-snapshot-csn-changed))))
    (libera-contesto-lettura context))
  nil)

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (contesto-lettura) null) abbandona-lettura))
(defun abbandona-lettura (context)
  "Pre: stesso worker, ultimo accesso concluso; chiamare nel cleanup di UNWIND-PROTECT.
Post: nessun pin; nessun risultato autorizzato. Inattivo idempotente; FAULTED resta tale.
Prima della migrazione abbandonare, scartare location e accodare solo la richiesta originale."
  (case (contesto-lettura-state context)
    (:idle (esigi-lettura-inattiva context))
    ((:entering :active :faulted) (libera-contesto-lettura context))
    (otherwise (guasto-contesto-lettura context :read-context-state)))
  nil)
