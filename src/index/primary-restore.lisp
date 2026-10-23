;;; OWNER: writer esclusivo del candidato privato di recovery, ammissione ancora chiusa.
;;; SHARED: solo seqlock e controlli canonici della Serie; nessun nuovo lock o stato fra Serie.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-003 REQ-AFF-008
(declaim (ftype (function (frammento-indice fixnum (or null contenuto-slot) contesto-indice) null)
                verifica-payload-ripristino))
(defun verifica-payload-ripristino (fragment key-bytes source context)
  "Pre: chiave e frammento writer verificati. Post: contesto libero e source valida/distinta se presente.
NIL significa assenza attesa, mai rimozione; INVALID-ARGUMENT prima di toccare lo scratch o l'indice."
  (esigi-contesto-libero context)
  (when source
    (when (eq source (contesto-indice-words context))
      (error 'invalid-argument :reason :primary-source-alias))
    (esigi-contenuto-slot (frammento-indice-bank fragment) source)
    (unless (= key-bytes (ldb (byte 16 32) (aref source 2)))
      (error 'invalid-argument :reason :primary-source-key-length)))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (indice-primario boolean (or null contenuto-slot) contenuto-slot)
                         (member nil :present :absent)) esito-voce-ripristinata))
(defun esito-voce-ripristinata (index found source current)
  "Pre: probe writer completo; CURRENT significativo solo se FOUND. Post: esito idempotente o NIL da inserire.
Una voce esistente deve avere identici CSN/location/length/end/key-len; offset arena escluso.
INVALID-ARGUMENT per voce diversa o presente dove attesa assenza, senza aggiornamenti o rimozioni."
  (esigi-indice-sano index)
  (if source
      (when found
        (unless (versione-corrisponde-p current source)
          (error 'invalid-argument :reason :primary-recovery-existing-key))
        :present)
      (progn
        (when found (error 'invalid-argument :reason :primary-recovery-expected-absent))
        :absent)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice octets fixnum fixnum u32
                                         contenuto-slot contenuto-slot) null) inserisci-voce-ripristinata))
(defun inserisci-voce-ripristinata (index fragment key start end low source work)
  "Pre: primo probe assente, writer esclusivo e source immutata. Post: inserimento canonico verificato.
Secondo probe/preflight usa i normali budget; trovato inatteso o copia discordante => indice FAULTED.
Rifiuti di capacita prima della mutazione; interruzioni dopo l'avvio delegate al writer canonico."
  (multiple-value-bind (slot found offset) (prepara-chiave-writer index fragment key start end low source work)
    (when found (guasto-indice index :primary-recovery-probe-changed))
    (applica-chiave-writer index fragment key start end low slot found offset work)
    (let ((state (tenta-lettura-slot (frammento-indice-bank fragment)
                                    (base-slot (frammento-indice-bank fragment) slot) work)))
      (unless (eq state :live) (guasto-indice index :primary-recovery-post-state)))
    (unless (versione-corrisponde-p work source) (guasto-indice index :primary-recovery-post-copy))
    (esigi-frammento-sano index fragment))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (indice-primario octets integer integer u32 u32
                                         (or null contenuto-slot) contesto-indice)
                         (member :inserted :present :absent)) ripristina-chiave-indice))
(defun ripristina-chiave-indice (index key start end high low source context)
  "Pre: candidato privato di bootstrap, writer esclusivo; chiave completa e digest della Serie.
SOURCE viva gia committed e finale, oppure NIL per assenza finale; nessuna retention o ammissione qui.
Post: INSERTED, PRESENT identico o ABSENT verificato, senza sovrascrivere/rimuovere una voce esistente.
Proba al massimo C slot per passaggio: due probe solo al primo inserimento, nessun retry o array nuovo.
Input/budget invalidi prima delle mutazioni; invarianti => indice FAULTED, causa originale conservata.
Il caller mantiene chiave/source stabili; aggiornamenti in esercizio usano il normale protocollo writer."
  (let* ((fragment (frammento-corrente-indice index high)) (work (contesto-indice-words context)))
    (esigi-chiave key start end)
    (verifica-payload-ripristino fragment (- end start) source context)
    (unwind-protect
         (handler-case
             (progn
               (setf (contesto-indice-busy context) t)
               (multiple-value-bind (slot found) (sonda-writer fragment key start end low work)
                 (when (and found (minusp slot)) (guasto-indice index :primary-recovery-probe-result))
                 (when (and source (minusp slot))
                   (error 'resource-exhausted :reason :primary-fragment-full))
                 (esigi-frammento-sano index fragment)
                 (let ((result (esito-voce-ripristinata index found source work)))
                   (when result (return-from ripristina-chiave-indice result)))
                 (unless source (guasto-indice index :primary-recovery-source-missing))
                 (inserisci-voce-ripristinata index fragment key start end low source work)
                 :inserted))
           (invariant-violation (condition) (invalida-indice-primario index) (error condition)))
      (setf (contesto-indice-busy context) nil))))
