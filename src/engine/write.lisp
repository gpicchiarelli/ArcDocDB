;;; OWNER: thread proprietario del motore; writer e attore I/O seriale coincidono in M1.
;;; SHARED: nessun reader concorrente; MOTORE-BUSY chiude il rientro anche nei callback.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (motore (member 1 2) b:octets b:octets) b:index)
                verifica-input-scrittura-motore))
(defun verifica-input-scrittura-motore (engine kind key value)
  "Pre: owner, motore READY, input octets stabili. Post: dimensioni e alias validati
prima di modificare il lotto o prendere un CSN. INVALID-ARGUMENT per forma dell'input,
RESOURCE-EXHAUSTED per formato/budget; lotto e gruppo restano invariati."
  (unless (<= 1 (length key) arcdocdb.record:+max-key-bytes+)
    (error 'arcdocdb.conditions:invalid-argument :reason :engine-key-length))
  (unless (if (= kind arcdocdb.record:+put+)
              (<= 1 (length value) arcdocdb.record:+max-document-bytes+)
              (zerop (length value)))
    (error 'arcdocdb.conditions:invalid-argument :reason :engine-value-length))
  (let* ((batch (motore-batch engine))
         (size (arcdocdb.record::encoding-size
                (w::lotto-buffer batch) 0 kind 0 key value (w::lotto-version batch)
                arcdocdb.record:+max-document-bytes+)))
    (when (> size (motore-max-record-bytes engine))
      (error 'arcdocdb.conditions:resource-exhausted :reason :engine-record-budget))
    size))

;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-WAL-006 REQ-MVC-008 REQ-IDX-001 REQ-AFF-001
(declaim (ftype (function (motore (member 1 2) b:octets b:octets) b:u64)
                commetti-record-motore))
(defun commetti-record-motore (engine kind key value)
  "Pre: owner, input validati, MOTORE-BUSY vero; un lotto da un record e un gruppo da un lotto.
Post: SEAL durevole, root pubblicata e CSN risolto, indice aggiornato, capacità riusate.
Root prima dell'indice: l'esclusione seriale e il gate del motore sono obbligatori.
Ogni errore/uscita incompleta richiede FAULTED dal confine chiamante, senza rollback."
  (let* ((controller (motore-controller engine)) (lease (motore-lease engine))
         (batch (motore-batch engine)) (group (motore-group engine))
         (append (motore-append engine))
         (log (a:log-segmento-attivo-preparato (motore-active engine)))
         (previous (s:leggi-radice-serie controller))
         (start (io:posizione-scritta append)))
    (unless (and (eq (w:stato-lotto batch) :open) (zerop (w:lunghezza-lotto batch))
                 (eq (w:stato-csn-lotto batch) :libero)
                 (eq (w:stato-gruppo group) :building))
      (error 'arcdocdb.conditions:invariant-violation :reason :engine-write-residue))
    (w:aggiungi-record batch kind key value)
    ;; Catturare la sola cornice prima che SEAL aumenti LUNGHEZZA-LOTTO.
    (let* ((record-bytes (w:lunghezza-lotto batch))
           (total (+ record-bytes w::+seal-total+)))
      (io:verifica-capienza-append append total total)
      (r:verifica-capienza-get-attiva (motore-source engine) lease batch previous)
      (multiple-value-bind (sealed-bytes high low)
          (w:sigilla-lotto-con-csn batch (motore-registry engine) log start
                                 (io:posizione-durevole append))
        (declare (type b:u32 high low))
        (unless (= sealed-bytes total)
          (error 'arcdocdb.conditions:invariant-violation :reason :engine-sealed-size))
        (let ((csn (logior (ash high 32) low)) (segment (w::log-io-file-id log)))
          (declare (type b:u64 csn segment))
          (multiple-value-bind (event generation)
              (gd:registra-lotto-fonti-get-attivo
               (motore-source engine) lease batch previous (motore-sources engine) :strong)
            (s:inizia-io-commit-serie controller lease event generation)
            (w:aggiungi-lotto group batch)
            (w:chiudi-gruppo group)
            (osserva-motore engine :before-append)
            (w:scrivi-gruppo group)
            (osserva-motore engine :after-append)
            (w:sincronizza-gruppo group)
            (osserva-motore engine :after-flush)
            (multiple-value-bind (status published-high published-low)
                (s:pubblica-commit-serie controller lease event generation)
              (unless (eq status :risolto)
                (error 'arcdocdb.conditions:resource-exhausted :reason :engine-commit-pending))
              (unless (and (= high published-high) (= low published-low))
                (error 'arcdocdb.conditions:invariant-violation :reason :engine-commit-csn)))
            (pubblica-location-motore engine kind key csn segment start record-bytes)
            (s:completa-io-commit-serie controller lease event generation)
            (w:riusa-gruppo group)
            ;; RIUSA-COMMIT-SERIE riapre anche il lotto; nessun secondo RIUSA-LOTTO.
            (s:riusa-commit-serie controller lease event generation)
            (osserva-motore engine :after-commit)
            csn))))))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-CON-002 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (motore (member 1 2) b:octets b:octets) b:u64)
                scrivi-record-motore))
(defun scrivi-record-motore (engine kind key value)
  "Pre: chiamante owner; nessun'altra API attiva sul motore. Post: CSN u64 confermato.
Input rifiutato in preflight senza consumare CSN o sporcare il lotto. Dopo l'ingresso
con MOTORE-BUSY, ogni errore rende FAULTED e propaga la stessa condizione; anche THROW/RETURN
incompleti rendono FAULTED. I callback non possono rientrare nel motore READY."
  (esigi-motore-pronto engine)
  (verifica-input-scrittura-motore engine kind key value)
  (verifica-capienza-indice-motore engine kind key)
  (let ((complete nil) (cause nil))
    (unwind-protect
         (handler-case
             (progn
               (setf (motore-busy engine) t)
               (let ((csn (commetti-record-motore engine kind key value)))
                 (declare (type b:u64 csn))
                 (unless (and (motore-busy engine) (eq (motore-state engine) :ready)
                              (eq (s:stato-controllore-serie (motore-controller engine)) :healthy))
                   (error 'arcdocdb.conditions:invariant-violation :reason :engine-write-state))
                 (setf complete t)
                 csn))
           (error (condition)
             (setf cause condition)
             (handler-case (guasta-motore engine condition)
               (error (cleanup) (push cleanup (motore-cleanup-failures engine))))
             (error condition)))
      (unwind-protect
           (unless (or complete cause)
             (handler-case
                 (guasta-motore engine
                                (make-condition 'arcdocdb.conditions:invariant-violation
                                                :reason :engine-write-unwind))
               (error (cleanup) (push cleanup (motore-cleanup-failures engine)))))
        (setf (motore-busy engine) nil)))))

;;; REQ: REQ-IDX-001 REQ-WAL-005 REQ-WAL-006 REQ-AFF-004 REQ-LIM-001
(declaim (ftype (function (motore b:octets b:octets) b:u64) scrivi-documento))
(defun scrivi-documento (engine key value)
  "Pre: thread owner, motore READY, KEY/VALUE octets stabili fino al ritorno; API non rientrabile.
Post: PUT ordinario durevole e leggibile, CSN u64 completo restituito dopo pubblicazione
e riuso. Input invalido prima del CSN; qualsiasi errore nel commit rende il motore FAULTED
e propaga la causa originale. Nessuna conferma parziale o ripetizione automatica."
  (scrivi-record-motore engine arcdocdb.record:+put+ key value))

;;; REQ: REQ-IDX-001 REQ-WAL-005 REQ-WAL-006 REQ-AFF-004 REQ-LIM-001
(declaim (ftype (function (motore b:octets) b:u64) cancella-documento))
(defun cancella-documento (engine key)
  "Pre: thread owner, motore READY, KEY octets stabile; API non rientrabile.
Post: tombstone ordinario durevole, chiave assente dall'indice, CSN u64 completo.
La chiave già assente produce comunque un commit. Stesso preflight e confine FAULTED
di SCRIVI-DOCUMENTO; il valore vuoto è quello preallocato nel motore."
  (scrivi-record-motore engine arcdocdb.record:+tombstone+ key (motore-empty engine)))
