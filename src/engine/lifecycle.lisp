;;; OWNER: attore del motore; cleanup solo dopo I/O sincrono e borrower GET terminati.
;;; SHARED: invalidazione locale; nessun registro o lock nuovo tra Serie.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (motore) null) esigi-owner-motore))
(defun esigi-owner-motore (engine)
  "Pre: handle valido. Post: attore proprietario esatto; INVALID-ARGUMENT prima di ogni mutazione."
  (unless (eq (motore-owner engine) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :engine-owner))
  nil)

;;; REQ: REQ-REC-001 REQ-CON-002 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (motore) null) esigi-motore-pronto))
(defun esigi-motore-pronto (engine)
  "Pre: richiesta seriale, nessuna reentrata. Post: owner e admission READY, controller sano.
INVALID-ARGUMENT prima dell'ammissione, IO-FAULT per salute guasta; nessun I/O o CSN."
  (esigi-owner-motore engine)
  (unless (eq (motore-state engine) :ready) (error 'invalid-argument :reason :engine-not-ready))
  (when (motore-busy engine) (error 'invalid-argument :reason :engine-request-in-progress))
  (unless (eq (s:stato-controllore-serie (motore-controller engine)) :healthy)
    (error 'io-fault :reason :engine-faulted :operation :engine))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (motore keyword) null) osserva-motore))
(defun osserva-motore (engine phase)
  "Pre: attore proprietario e osservatore fidato/iniettabile, nessuna richiesta reentrante ammessa.
Post: fase notificata senza dati documentali; uscita/errore del callback propaga al confine chiamante."
  (when (motore-observer engine)
    (unless (null (funcall (motore-observer engine) engine phase))
      (error 'invalid-argument :reason :engine-observer-result)))
  nil)

;;; REQ: REQ-AFF-001 REQ-CON-002
(declaim (ftype (function (motore t) null) guasta-motore))
(defun guasta-motore (engine cause)
  "Pre: owner al confine di startup/richiesta, I/O sincrono. Post: admission terminale e causa conservata.
Nessun retry, rollback, CSN inventato o cleanup che nasconda la condizione originale."
  (setf (motore-state engine) :faulted)
  (when (typep cause 'condition) (setf (motore-failure engine) cause))
  (when (and (motore-controller engine) (motore-lease engine))
    (s:fault-controllore-serie (motore-controller engine) (motore-lease engine)))
  nil)

;;; REQ: REQ-AFF-004 REQ-REC-001
(declaim (ftype (function (motore function) null) tenta-cleanup-motore))
(defun tenta-cleanup-motore (engine operation)
  "Pre: operazione cleanup posseduta al confine, nessun borrower attivo. Post: tentata una sola volta.
Errori conservati nell'handle per aggregazione dopo tutti i tentativi, mai ignorati."
  (handler-case (funcall operation)
    (error (condition) (push condition (motore-cleanup-failures engine))))
  nil)

;;; REQ: REQ-AFF-004 REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (motore) null) libera-risorse-motore))
(defun libera-risorse-motore (engine)
  "Pre: attore, nessun compito/GET in volo. Post: tutti i set/FD tentati, parent ultimo rilascia il lock.
Ownership consumata anche con errore; guasti registrati, nessun secondo close o retry."
  (when (motore-lease engine)
    (tenta-cleanup-motore engine (lambda () (s:rilascia-controllore-serie
                                           (motore-controller engine) (motore-lease engine))))
    (setf (motore-lease engine) nil))
  (dolist (set (motore-recovery-sets engine))
    (tenta-cleanup-motore engine (lambda () (mf:chiudi-fonti-recovery set))))
  (setf (motore-recovery-sets engine) nil)
  (dolist (file (motore-fds engine))
    (tenta-cleanup-motore engine (lambda () (io:chiudi file))))
  (setf (motore-fds engine) nil)
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-CON-002
(declaim (ftype (function (motore) null) chiudi-motore))
(defun chiudi-motore (engine)
  "Pre: owner seriale, nessuna richiesta in volo. Post: admission CLOSED e tutte le capacita' tentate.
Close ripetuto no-op. Aggregato con primaria e lista completa cleanup dopo tutti i tentativi."
  (esigi-owner-motore engine)
  (unless (member (motore-state engine) '(:ready :faulted :closed))
    (error 'invalid-argument :reason :engine-not-ready))
  (when (motore-busy engine) (error 'invalid-argument :reason :engine-request-in-progress))
  (unless (eq (motore-state engine) :closed)
    (setf (motore-state engine) :closed)
    (libera-risorse-motore engine)
    (when (motore-cleanup-failures engine)
      (error 'errore-cleanup-motore :reason :engine-close-cleanup :primary (motore-failure engine)
             :errors (reverse (motore-cleanup-failures engine)))))
  nil)

;;; REQ: REQ-REC-001 REQ-CON-002
(declaim (ftype (function (motore) keyword) stato-motore))
(defun stato-motore (engine)
  "Pre: handle valido. Post: stato scalare, non una prenotazione o trasferimento dell'admission."
  (motore-state engine))

;;; REQ: REQ-MVC-005 REQ-MVC-006
(declaim (ftype (function (motore) (values u32 u32 u32 u32 &optional)) frontiere-motore))
(defun frontiere-motore (engine)
  "Pre: owner con motore READY. Post: ultimo CSN e H canonici senza incremento, parole high/low.
Rifiuta admission chiusa; nessuna deduzione da offset, ID o CONTROL."
  (esigi-motore-pronto engine)
  (arcdocdb.csn:leggi-frontiere-csn (motore-registry engine)))
