;;; OWNER: worker usa scratch propri; l'indice pubblica solo versioni committed per contratto.
;;; SHARED: indice e snapshot in lettura; conferma root e assenza delegate al lookup bounded.
(in-package #:arcdocdb.get)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-001 REQ-MVC-005 REQ-IDX-001
(declaim (ftype (function (contesto-get (member :live :absent :retry-limit)) get-state)
                scegli-candidato-get))
(defun scegli-candidato-get (context result)
  "Pre: EBR attivo, indice confermato; buffer scritto soltanto per LIVE.
Post: CANDIDATE se versione corrente visibile; snapshot con miss/versione nuova richiede storico.
Non dichiara assenza storica e non legge payload su miss/retry; stato inatteso rende FAULTED."
  (case result
    (:live
     (let ((csn (aref (contesto-get-content context) 0))
           (limit (aref (contesto-get-limit context) 0)))
       (declare (type u64 csn limit))
       (if (or (not (contesto-get-snapshot-p context)) (<= csn limit)) :candidate :history-required)))
    (:absent (if (contesto-get-snapshot-p context) :history-required :absent))
    (:retry-limit :retry)
    (otherwise (guasto-get context :get-primary-result))))

;;; REQ: REQ-CON-004 REQ-IDX-001 REQ-MVC-001 REQ-MVC-005 REQ-AFF-008
(declaim (ftype (function (contesto-get vista-get-serie octets
                                      (or null contesto-snapshot) u64 u64)
                         (member :candidate :absent :history-required :retry)) avvia-get))
(defun avvia-get (context view key snapshot generation now)
  "Pre: IDLE, richiesta/chiave stabili, seme dell'indice configurato, stesso Archivio.
Post: un ingresso EBR e un lookup bounded; risultato provvisorio, pin fino a conclusione/abbandono.
RETRY con IDLE significa mancata ammissione: riaccodare originale. Cleanup esterno già installato.
Riuso respinto prima di acquisire risorse; gli altri errori liberano il compito senza risultato."
  (esigi-stato-get context :idle)
  (unless (eq (contesto-get-scope context) (vista-get-serie-scope view))
    (error 'invalid-argument :reason :get-archive-owner))
  (unless (<= 1 (length key) +max-key-bytes+) (error 'invalid-argument :reason :get-key-range))
  (when (or (eq key (contesto-get-bytes context)) (eq key (contesto-get-proof context)))
    (error 'invalid-argument :reason :get-key-alias))
  (unless (and (null (contesto-get-view context)) (null (contesto-get-key context))
               (zerop (contesto-get-value-start context)) (zerop (contesto-get-value-end context)))
    (guasto-get context :get-worker-residue))
  (let ((completed nil))
    (unwind-protect
         (progn
           (setf (contesto-get-state context) :starting (contesto-get-view context) view
                 (contesto-get-key context) key)
           (unless (avvia-lettura (contesto-get-reader context) snapshot generation now)
             (abbandona-get context)
             (setf completed t)
             (return-from avvia-get :retry))
           (setf (contesto-get-snapshot-p context)
                 (copia-limite-lettura (contesto-get-reader context) (contesto-get-limit context) 0))
           (multiple-value-bind (high low)
               (digest-chiave-indice (vista-get-serie-primary view) key 0 (length key))
             (let ((state (scegli-candidato-get
                           context (leggi-indice-primario
                                    (vista-get-serie-primary view) key 0 (length key) high low
                                    (contesto-get-probe context) (contesto-get-content context)))))
               (setf (contesto-get-state context) state completed t)
               state)))
      (unless completed (abbandona-get context)))))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (contesto-get get-content) null) copia-candidato-get))
(defun copia-candidato-get (context destination)
  "Pre: CANDIDATE, output privato del resolver nel medesimo compito EBR.
Post: cinque word copiate senza ritorno u64; location/CSN non attraversano la migrazione.
INVALID-ARGUMENT per stato/alias. Il flag dello slot è LIVE, non il flag del record."
  (esigi-stato-get context :candidate)
  (when (eq destination (contesto-get-content context))
    (error 'invalid-argument :reason :get-candidate-alias))
  (replace destination (contesto-get-content context))
  nil)
