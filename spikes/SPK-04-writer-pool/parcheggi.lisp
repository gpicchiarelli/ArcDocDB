;;;; SPK-04: modello finito delle attese di ADR-0045, senza thread o I/O.
;;; REQ: REQ-CON-004 REQ-AFF-008 REQ-VAL-001

(defpackage #:arcdocdb.spk04.parcheggi
  (:use #:cl)
  (:export #:check))

(in-package #:arcdocdb.spk04.parcheggi)
(declaim (optimize (safety 3) (speed 1) (debug 3)))

(defconstant +max-contesti+ 4)
(defconstant +max-generazione+ 16)
(defconstant +max-tempo+ 255)
(defconstant +max-evento+ 31)
(defconstant +max-risoluzioni+ 64)

(deftype indice-contesto () '(integer 0 3))
(deftype generazione () '(integer 0 16))
(deftype tempo-logico () '(integer 0 255))
(deftype tipo-lista () '(member :clienti-lotto :snapshot :coordinatori))

(define-condition errore-spike (error)
  ((messaggio :initarg :messaggio :reader messaggio-spike :type string))
  (:report (lambda (condizione stream)
             (write-string (messaggio-spike condizione) stream))))

(declaim (ftype (function (t string) null) esigi))
(defun esigi (condizione messaggio)
  "Segnala una precondizione interna o una verifica del modello fallita."
  (unless condizione
    (error 'errore-spike :messaggio messaggio))
  nil)

;;; OWNER: il singolo produttore della lista nel simulatore a flusso unico.
;;; Nessuna lista e nessuna coda sono condivise fra Serie in questo modello.
(defstruct (contesto (:constructor nuovo-contesto ()))
  "Lo slot identifica il contesto; la generazione impedisce il riuso del token."
  (stato :libero :type (member :libero :parcheggiato :pronto))
  (generazione 0 :type generazione)
  (evento -1 :type (integer -1 31))
  (scadenza 0 :type tempo-logico)
  (esito :nessuno :type (member :nessuno :evento :resource-exhausted))
  (pubblicazioni 0 :type (integer 0 1))
  (riprese 0 :type (integer 0 1)))

(defstruct (lista (:constructor %nuova-lista
                                (tipo capacita tempo-massimo contesti
                                 slot-pronti generazioni-pronte)))
  "Tutti gli array nascono insieme alla lista e non crescono mai."
  (tipo :clienti-lotto :type tipo-lista :read-only t)
  (capacita 1 :type (integer 1 4) :read-only t)
  (tempo-massimo 1 :type (integer 1 255) :read-only t)
  (contesti #() :type simple-vector :read-only t)
  (slot-pronti (make-array 0 :element-type 'fixnum)
              :type (simple-array fixnum (*)) :read-only t)
  (generazioni-pronte (make-array 0 :element-type 'fixnum)
                     :type (simple-array fixnum (*)) :read-only t)
  (orologio 0 :type tempo-logico)
  (parcheggiati 0 :type (integer 0 4))
  (pronti 0 :type (integer 0 4))
  (testa 0 :type indice-contesto)
  (pubblicazioni 0 :type (integer 0 64))
  (riprese 0 :type (integer 0 64)))

(declaim
 (ftype (function (tipo-lista (integer 1 4) (integer 1 255)) lista)
        nuova-lista)
 (ftype (function (lista integer) boolean) slot-valido-p)
 (ftype (function (lista) null) verifica-lista)
 (ftype (function (lista integer) keyword) avanza-orologio)
 (ftype (function (lista integer integer integer)
                  (values keyword generazione &optional)) parcheggia)
 (ftype (function (lista indice-contesto contesto keyword) keyword) risolvi)
 (ftype (function (lista integer integer integer) keyword) pubblica-evento)
 (ftype (function (lista) (integer 0 4)) pubblica-scadenze)
 (ftype (function (lista)
                  (values keyword integer generazione keyword &optional))
        riprendi))

;;; REQ: REQ-CON-004 REQ-AFF-008
(defun nuova-lista (tipo capacita tempo-massimo)
  "Configurazione finita del modello; non e un limite suggerito per il motore."
  (esigi (member tipo '(:clienti-lotto :snapshot :coordinatori))
         "REQ-CON-004: tipo di parcheggio inatteso.")
  (esigi (<= 1 capacita +max-contesti+)
         "REQ-AFF-008: capacita fuori dal dominio finito.")
  (esigi (<= 1 tempo-massimo +max-tempo+)
         "REQ-AFF-008: tempo massimo fuori dal dominio finito.")
  (let ((contesti (make-array capacita :element-type t)))
    (dotimes (i capacita)
      (setf (aref contesti i) (nuovo-contesto)))
    (%nuova-lista tipo capacita tempo-massimo contesti
                  (make-array capacita :element-type 'fixnum :initial-element -1)
                  (make-array capacita :element-type 'fixnum :initial-element 0))))

(defun slot-valido-p (lista slot)
  (<= 0 slot (1- (lista-capacita lista))))

(defun verifica-lista (lista)
  "Verifica i crediti dei contesti e le sole celle occupate della coda."
  (let ((parcheggiati 0) (pronti 0) (capacita (lista-capacita lista)))
    (dotimes (i capacita)
      (let ((contesto (aref (lista-contesti lista) i)))
        (case (contesto-stato contesto)
          (:libero nil)
          (:parcheggiato (incf parcheggiati))
          (:pronto (incf pronti))
          (otherwise (esigi nil "REQ-CON-004: stato interno inatteso.")))))
    (esigi (= parcheggiati (lista-parcheggiati lista))
           "REQ-AFF-008: conteggio dei parcheggi incoerente.")
    (esigi (= pronti (lista-pronti lista))
           "REQ-CON-004: conteggio delle riprese incoerente.")
    (esigi (<= (+ parcheggiati pronti) capacita)
           "REQ-AFF-008: crediti dei contesti superati.")
    (dotimes (i pronti)
      (let* ((posizione (mod (+ (lista-testa lista) i) capacita))
             (slot (aref (lista-slot-pronti lista) posizione)))
        (esigi (slot-valido-p lista slot)
               "REQ-CON-004: slot pronto fuori limite.")
        (let ((contesto (aref (lista-contesti lista) slot)))
          (esigi (and (eq (contesto-stato contesto) :pronto)
                      (= (contesto-generazione contesto)
                         (aref (lista-generazioni-pronte lista) posizione)))
                 "REQ-CON-004: token pronto obsoleto."))
        (dotimes (precedente i)
          (esigi (/= slot (aref (lista-slot-pronti lista)
                               (mod (+ (lista-testa lista) precedente) capacita)))
                 "REQ-CON-004: contesto duplicato nella coda."))))
    (esigi (<= (lista-riprese lista) (lista-pubblicazioni lista)
               +max-risoluzioni+)
           "REQ-CON-004: numero di risoluzioni incoerente."))
  nil)

(defun avanza-orologio (lista tempo)
  "Clock logico iniettato: regressione o esaurimento rifiutano senza effetti."
  (if (<= (lista-orologio lista) tempo +max-tempo+)
      (progn (setf (lista-orologio lista) tempo) :ok)
      :resource-exhausted))

;;; REQ: REQ-CON-004 REQ-AFF-008
(defun parcheggia (lista slot evento scadenza)
  "Termina il compito registrando un contesto; nessuna attesa ne trattiene il worker.
Un token e la coppia di valori (slot, generazione), senza wrap della generazione.
Le precondizioni precedono ogni mutazione; scadenza == clock e gia scaduta."
  (verifica-lista lista)
  (unless (and (slot-valido-p lista slot) (<= 0 evento +max-evento+)
               (< (lista-orologio lista) scadenza)
               (<= scadenza +max-tempo+)
               (<= (- scadenza (lista-orologio lista))
                   (lista-tempo-massimo lista)))
    (return-from parcheggia (values :resource-exhausted 0)))
  (let ((contesto (aref (lista-contesti lista) slot)))
    (unless (and (eq (contesto-stato contesto) :libero)
                 (< (contesto-generazione contesto) +max-generazione+)
                 (< (+ (lista-parcheggiati lista) (lista-pronti lista))
                    (lista-capacita lista)))
      (return-from parcheggia (values :resource-exhausted 0)))
    (incf (contesto-generazione contesto))
    (setf (contesto-stato contesto) :parcheggiato
          (contesto-evento contesto) evento
          (contesto-scadenza contesto) scadenza
          (contesto-esito contesto) :nessuno
          (contesto-pubblicazioni contesto) 0
          (contesto-riprese contesto) 0)
    (incf (lista-parcheggiati lista))
    (verifica-lista lista)
    (values :parcheggiato (contesto-generazione contesto))))

;;; REQ: REQ-CON-004 REQ-AFF-008
(defun risolvi (lista slot contesto esito)
  "Accoda una sola ripresa; il credito del contesto riserva anche quello di coda.
Evento e timeout hanno lo stesso punto di risoluzione nel simulatore."
  (esigi (eq (contesto-stato contesto) :parcheggiato)
         "REQ-CON-004: risoluzione di contesto non parcheggiato.")
  (esigi (member esito '(:evento :resource-exhausted))
         "REQ-CON-004: esito di risoluzione inatteso.")
  (esigi (< (lista-pronti lista) (lista-capacita lista))
         "REQ-AFF-008: credito riservato di coda assente.")
  (esigi (< (lista-pubblicazioni lista) +max-risoluzioni+)
         "REQ-AFF-008: dominio delle risoluzioni esaurito.")
  (let ((posizione (mod (+ (lista-testa lista) (lista-pronti lista))
                       (lista-capacita lista))))
    (setf (aref (lista-slot-pronti lista) posizione) slot
          (aref (lista-generazioni-pronte lista) posizione)
          (contesto-generazione contesto)
          (contesto-stato contesto) :pronto
          (contesto-esito contesto) esito
          (contesto-pubblicazioni contesto) 1)
    (decf (lista-parcheggiati lista))
    (incf (lista-pronti lista))
    (incf (lista-pubblicazioni lista)))
  (verifica-lista lista)
  :pubblicato)

;;; REQ: REQ-CON-004 REQ-AFF-008
(defun pubblica-evento (lista slot generazione evento)
  "Il produttore usa il token registrato; una callback vecchia non tocca il riuso.
Alla scadenza il rifiuto prevale sull'evento, anche prima della scansione timeout."
  (verifica-lista lista)
  (unless (and (slot-valido-p lista slot) (<= 1 generazione +max-generazione+)
               (<= 0 evento +max-evento+))
    (return-from pubblica-evento :token-invalido))
  (let ((contesto (aref (lista-contesti lista) slot)))
    (unless (= generazione (contesto-generazione contesto))
      (return-from pubblica-evento :obsoleto))
    (when (eq (contesto-stato contesto) :libero)
      (return-from pubblica-evento :obsoleto))
    (unless (= evento (contesto-evento contesto))
      (return-from pubblica-evento :evento-inatteso))
    (when (eq (contesto-stato contesto) :pronto)
      (return-from pubblica-evento :gia-risolto))
    (risolvi lista slot contesto
             (if (>= (lista-orologio lista) (contesto-scadenza contesto))
                 :resource-exhausted :evento))))

(defun pubblica-scadenze (lista)
  "Scansione bounded in ordine di slot; i timeout pronti non si pubblicano di nuovo."
  (verifica-lista lista)
  (let ((numero 0))
    (dotimes (slot (lista-capacita lista))
      (let ((contesto (aref (lista-contesti lista) slot)))
        (when (and (eq (contesto-stato contesto) :parcheggiato)
                   (>= (lista-orologio lista) (contesto-scadenza contesto)))
          (esigi (eq (risolvi lista slot contesto :resource-exhausted) :pubblicato)
                 "REQ-CON-004: timeout non pubblicato.")
          (incf numero))))
    numero))

(defun riprendi (lista)
  "Consuma un solo compito pronto FIFO e libera il contesto dopo la sua ripresa.
Non chiama continuazioni esterne: registra soltanto l'esito della fixture."
  (verifica-lista lista)
  (when (zerop (lista-pronti lista))
    (return-from riprendi (values :vuota -1 0 :nessuno)))
  (let* ((testa (lista-testa lista))
         (slot (aref (lista-slot-pronti lista) testa))
         (generazione (aref (lista-generazioni-pronte lista) testa))
         (contesto (aref (lista-contesti lista) slot))
         (esito (contesto-esito contesto)))
    (esigi (and (= (contesto-pubblicazioni contesto) 1)
                (zerop (contesto-riprese contesto)))
           "REQ-CON-004: doppia ripresa del contesto.")
    (setf (contesto-stato contesto) :libero
          (contesto-evento contesto) -1
          (contesto-scadenza contesto) 0
          (contesto-esito contesto) :nessuno
          (contesto-riprese contesto) 1
          (aref (lista-slot-pronti lista) testa) -1
          (aref (lista-generazioni-pronte lista) testa) 0
          (lista-testa lista) (mod (1+ testa) (lista-capacita lista)))
    (decf (lista-pronti lista))
    (incf (lista-riprese lista))
    (verifica-lista lista)
    (values :ripreso slot generazione esito)))

;;; Le allocazioni seguenti appartengono alle fixture, non ai percorsi del modello.
(declaim (ftype (function (lista) list) immagine-lista)
         (ftype (function (lista integer integer integer) generazione)
                attendi-fixture)
         (ftype (function (lista integer generazione keyword) null)
                verifica-ripresa)
         (ftype (function (lista keyword) null) verifica-immutata))

(defun immagine-lista (lista)
  "Copia dello stato della fixture per rilevare effetti parziali di un rifiuto."
  (list (lista-orologio lista) (lista-parcheggiati lista) (lista-pronti lista)
        (lista-testa lista) (lista-pubblicazioni lista) (lista-riprese lista)
        (coerce (lista-slot-pronti lista) 'list)
        (coerce (lista-generazioni-pronte lista) 'list)
        (loop for i below (lista-capacita lista)
              for contesto = (aref (lista-contesti lista) i)
              collect (list (contesto-stato contesto)
                            (contesto-generazione contesto)
                            (contesto-evento contesto)
                            (contesto-scadenza contesto)
                            (contesto-esito contesto)
                            (contesto-pubblicazioni contesto)
                            (contesto-riprese contesto)))))

(defun attendi-fixture (lista slot evento scadenza)
  (multiple-value-bind (esito generazione) (parcheggia lista slot evento scadenza)
    (esigi (eq esito :parcheggiato) "REQ-CON-004: fixture non parcheggiata.")
    generazione))

(defun verifica-ripresa (lista slot generazione esito)
  (multiple-value-bind (stato ricevuto token risultato) (riprendi lista)
    (esigi (and (eq stato :ripreso) (= ricevuto slot) (= token generazione)
                (eq risultato esito))
           "REQ-CON-004: ordine, token o esito della ripresa inatteso."))
  nil)

(defun verifica-immutata (lista operazione)
  "Esegue un singolo rifiuto nominato su una fixture e confronta lo stato intero."
  (let ((prima (immagine-lista lista))
        (esito
          (case operazione
            (:slot (parcheggia lista +max-contesti+ 1 1))
            (:evento (parcheggia lista 0 (1+ +max-evento+) 1))
            (:scaduta (parcheggia lista 0 1 (lista-orologio lista)))
            (:tempo (parcheggia lista 0 1
                               (+ (lista-orologio lista)
                                  (lista-tempo-massimo lista) 1)))
            (:occupato (parcheggia lista 0 1 1))
            (:generazione (parcheggia lista 0 1 1))
            (:clock (avanza-orologio lista (1+ +max-tempo+)))
            (:regressione (avanza-orologio lista (1- (lista-orologio lista))))
            (otherwise (esigi nil "REQ-VAL-001: operazione di fixture inattesa.")))))
    (esigi (eq esito :resource-exhausted) "REQ-AFF-008: rifiuto non esplicito.")
    (esigi (equal prima (immagine-lista lista)) "REQ-AFF-008: rifiuto con effetti."))
  nil)

(declaim
 (ftype (function (tipo-lista) list)
        test-req-con-004-eventi test-req-con-004-scadenze
        test-req-con-004-riuso test-req-aff-008-limiti test-req-aff-008-capacita)
 (ftype (function () list) check))

;;; REQ: REQ-CON-004 REQ-VAL-001
(defun test-req-con-004-eventi (tipo)
  "FIFO segue l'ordine di pubblicazione, non quello degli slot o dei parcheggi."
  (let* ((lista (nuova-lista tipo 2 8))
         (primo (attendi-fixture lista 0 3 8))
         (secondo (attendi-fixture lista 1 7 8))
         (prima (immagine-lista lista)))
    (esigi (eq (pubblica-evento lista 0 primo 7) :evento-inatteso)
           "REQ-CON-004: evento differente accettato.")
    (esigi (equal prima (immagine-lista lista))
           "REQ-CON-004: evento differente ha mutato il contesto.")
    (esigi (eq (pubblica-evento lista 1 secondo 7) :pubblicato)
           "REQ-CON-004: secondo evento non pubblicato.")
    (esigi (eq (pubblica-evento lista 0 primo 3) :pubblicato)
           "REQ-CON-004: primo evento non pubblicato.")
    (let ((pronta (immagine-lista lista)))
      (esigi (eq (pubblica-evento lista 1 secondo 7) :gia-risolto)
             "REQ-CON-004: duplicato non riconosciuto.")
      (esigi (equal pronta (immagine-lista lista))
             "REQ-CON-004: evento duplicato ha effetti."))
    (verifica-ripresa lista 1 secondo :evento)
    (let ((terzo (attendi-fixture lista 1 9 8)))
      (esigi (eq (pubblica-evento lista 1 terzo 9) :pubblicato)
             "REQ-CON-004: riuso della coda circolare fallito.")
      (verifica-ripresa lista 0 primo :evento)
      (verifica-ripresa lista 1 terzo :evento))
    (esigi (eq (riprendi lista) :vuota) "REQ-CON-004: doppio compito pronto.")
    (esigi (= (lista-pubblicazioni lista) (lista-riprese lista) 3)
           "REQ-CON-004: conteggio completamenti inatteso.")
    (list :case "REQ-CON-004/eventi-fifo-idempotenti" :tipo tipo :status :ok)))

;;; REQ: REQ-CON-004 REQ-AFF-008 REQ-VAL-001
(defun test-req-con-004-scadenze (tipo)
  (let* ((lista (nuova-lista tipo 2 4))
         (primo (attendi-fixture lista 0 3 4))
         (secondo (attendi-fixture lista 1 7 4)))
    (esigi (eq (avanza-orologio lista 3) :ok) "REQ-CON-004: clock rifiutato.")
    (esigi (zerop (pubblica-scadenze lista)) "REQ-CON-004: timeout prematuro.")
    (esigi (eq (avanza-orologio lista 4) :ok) "REQ-CON-004: limite rifiutato.")
    (esigi (eq (pubblica-evento lista 1 secondo 7) :pubblicato)
           "REQ-CON-004: evento al limite non risolto.")
    (esigi (= (pubblica-scadenze lista) 1) "REQ-CON-004: timeout perso.")
    (let ((prima (immagine-lista lista)))
      (esigi (zerop (pubblica-scadenze lista)) "REQ-CON-004: timeout duplicato.")
      (esigi (eq (pubblica-evento lista 0 primo 3) :gia-risolto)
             "REQ-CON-004: evento tardivo non idempotente.")
      (esigi (equal prima (immagine-lista lista)) "REQ-CON-004: risoluzione doppia."))
    (verifica-ripresa lista 1 secondo :resource-exhausted)
    (verifica-ripresa lista 0 primo :resource-exhausted)
    (verifica-immutata lista :scaduta)
    (verifica-immutata lista :regressione)
    (list :case "REQ-CON-004/scadenza-inclusiva-evento-tardivo"
          :tipo tipo :status :ok)))

;;; REQ: REQ-CON-004 REQ-AFF-008 REQ-VAL-001
(defun test-req-con-004-riuso (tipo)
  (let* ((lista (nuova-lista tipo 1 4))
         (vecchio (attendi-fixture lista 0 3 4)))
    (esigi (eq (pubblica-evento lista 0 vecchio 3) :pubblicato)
           "REQ-CON-004: risoluzione per riuso fallita.")
    (verifica-immutata lista :occupato)
    (verifica-ripresa lista 0 vecchio :evento)
    (let ((nuovo (attendi-fixture lista 0 3 4)) (prima (immagine-lista lista)))
      (esigi (= nuovo (1+ vecchio)) "REQ-CON-004: token riutilizzato.")
      (esigi (eq (pubblica-evento lista 0 vecchio 3) :obsoleto)
             "REQ-CON-004: callback vecchia ha raggiunto il riuso.")
      (esigi (equal prima (immagine-lista lista))
             "REQ-CON-004: callback vecchia ha effetti.")
      (esigi (eq (pubblica-evento lista 0 nuovo 3) :pubblicato)
             "REQ-CON-004: callback nuova rifiutata.")
      (verifica-ripresa lista 0 nuovo :evento)
      (let ((libera (immagine-lista lista)))
        (esigi (eq (pubblica-evento lista 0 nuovo 3) :obsoleto)
               "REQ-CON-004: callback gia consumata accettata.")
        (esigi (equal libera (immagine-lista lista))
               "REQ-CON-004: callback consumata ha effetti.")))
    (list :case "REQ-CON-004/riuso-token-generazionale"
          :tipo tipo :status :ok)))

;;; REQ: REQ-AFF-008 REQ-CON-004 REQ-VAL-001
(defun test-req-aff-008-limiti (tipo)
  (let ((lista (nuova-lista tipo 1 4)))
    (dolist (operazione '(:slot :evento :scaduta :tempo :clock))
      (verifica-immutata lista operazione))
    (let ((token (attendi-fixture lista 0 1 1)))
      (verifica-immutata lista :occupato)
      (esigi (eq (pubblica-evento lista 0 token 1) :pubblicato)
             "REQ-AFF-008: risoluzione sotto saturazione persa.")
      (verifica-ripresa lista 0 token :evento))
    (dotimes (i (1- +max-generazione+))
      (let ((token (attendi-fixture lista 0 1 1)))
        (esigi (= token (+ i 2)) "REQ-AFF-008: generazione non monotona.")
        (esigi (eq (pubblica-evento lista 0 token 1) :pubblicato)
               "REQ-AFF-008: evento prima del limite perso.")
        (verifica-ripresa lista 0 token :evento)))
    (verifica-immutata lista :generazione)
    (esigi (eq (avanza-orologio lista +max-tempo+) :ok)
           "REQ-AFF-008: ultimo tick logico rifiutato.")
    (verifica-immutata lista :clock)
    (list :case "REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap"
          :tipo tipo :status :ok)))

;;; REQ: REQ-AFF-008 REQ-CON-004 REQ-VAL-001
(defun test-req-aff-008-capacita (tipo)
  "La capacita massima copre coda piena e tutte le generazioni senza wrap."
  (let ((lista (nuova-lista tipo +max-contesti+ 1)))
    (dotimes (generazione +max-generazione+)
      (dotimes (slot +max-contesti+)
        (esigi (= (attendi-fixture lista slot slot 1) (1+ generazione))
               "REQ-AFF-008: generazione nello slot inattesa."))
      (verifica-immutata lista :occupato)
      (dotimes (slot +max-contesti+)
        (esigi (eq (pubblica-evento lista slot (1+ generazione) slot) :pubblicato)
               "REQ-AFF-008: pubblicazione con credito riservato persa."))
      (verifica-immutata lista :occupato)
      (dotimes (slot +max-contesti+)
        (verifica-ripresa lista slot (1+ generazione) :evento)))
    (verifica-immutata lista :generazione)
    (esigi (= (lista-pubblicazioni lista) (lista-riprese lista)
              +max-risoluzioni+)
           "REQ-AFF-008: dominio totale delle risoluzioni non coperto.")
    (list :case "REQ-AFF-008/capacita-massima-crediti-coda"
          :tipo tipo :status :ok)))

;;; REQ: REQ-VAL-001 REQ-CON-004 REQ-AFF-008
(defun check ()
  "Fixture finite ripetibili; nessuna misura di durata, thread, GC o motore reale."
  (let ((casi nil))
    (dolist (tipo '(:clienti-lotto :snapshot :coordinatori))
      (push (test-req-con-004-eventi tipo) casi)
      (push (test-req-con-004-scadenze tipo) casi)
      (push (test-req-con-004-riuso tipo) casi)
      (push (test-req-aff-008-limiti tipo) casi)
      (push (test-req-aff-008-capacita tipo) casi))
    (list :status :ok :cases (nreverse casi)
          :limits
          (list :contesti-per-lista +max-contesti+
                :generazione-massima +max-generazione+
                :clock-logico-massimo +max-tempo+
                :evento-massimo +max-evento+
                :coda-riprese :credito-riservato-per-contesto
                :timeout :clock-logico-iniettato
                :ordine-riprese :fifo-di-pubblicazione
                :modello :flusso-unico-deterministico
                :esclusioni '(:thread-reali :attese-clock-reale
                              :callback-esterne :allocazioni-misurate
                              :durabilita :prestazioni)))))
