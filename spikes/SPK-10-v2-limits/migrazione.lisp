;;;; SPK-10: selezione del fileheader e modello finito, senza conversione su disco.
;;; REQ: REQ-FOR-002 REQ-LIM-003 REQ-AFF-007 REQ-AFF-018 REQ-AFF-019

(defpackage #:arcdocdb.spk10.migrazione
  (:use #:cl)
  (:import-from #:arcdocdb.spk09 #:crc32c-reference)
  (:export #:check #:costruisci-fileheader #:versione-fileheader
           #:seleziona-parser #:fileheader-invalido #:motivo-fileheader))

(in-package #:arcdocdb.spk10.migrazione)
(declaim (optimize (safety 3) (speed 1) (debug 2)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype u16 () '(unsigned-byte 16))
(deftype u64 () '(unsigned-byte 64))
(defconstant +fileheader-byte+ 64)
(defconstant +magic-segmento+ #x3147455344435241) ; ARCDSEG1 little-endian.
(defconstant +versione-offset+ 8)
(defconstant +origine-offset+ 10)
(defconstant +serie-offset+ 16)
(defconstant +segmento-offset+ 32)
(defconstant +timestamp-offset+ 40)
(defconstant +crc-offset+ 56)
(defconstant +max-passi+ 32)
(defconstant +max-copie+ 4)
(defconstant +copie-per-tentativo+ 2)
(defconstant +max-fasi+ 10)
(defconstant +max-recovery+ 4)
(defconstant +max-prefissi+ 11)
(defconstant +max-scenari+ 4)
(defconstant +max-crash+ 4)

(define-condition errore-spike (error)
  ((messaggio :initarg :messaggio :type string :reader messaggio-spike))
  (:report (lambda (condizione stream)
             (write-string (messaggio-spike condizione) stream))))

(define-condition fileheader-invalido (errore-spike)
  ((motivo :initarg :motivo :type keyword :reader motivo-fileheader)))

(declaim (ftype (function (t string) null) esigi)
         (ftype (function (keyword) nil) rifiuta-fileheader))
(defun esigi (condizione messaggio)
  "Fallisce esplicitamente una precondizione o il check sperimentale."
  (unless condizione (error 'errore-spike :messaggio messaggio))
  nil)

(defun rifiuta-fileheader (motivo)
  "Non restituisce alcuna versione o funzione parser."
  (error 'fileheader-invalido :motivo motivo
         :messaggio (format nil "Fileheader rifiutato: ~S." motivo)))

(declaim (ftype (function (octets integer integer) (integer 0 *)) leggi-intero)
         (ftype (function (octets integer (integer 0 *) integer) octets)
                scrivi-intero))
(defun leggi-intero (buffer inizio numero-byte)
  "Legge solo interi di 1..8 byte dopo il controllo dell'intervallo."
  (esigi (and (<= 1 numero-byte 8)
              (<= 0 inizio (+ inizio numero-byte) (length buffer)))
         "REQ-FOR-002: intervallo intero non valido.")
  (let ((valore 0))
    (dotimes (i numero-byte valore)
      (setf valore (logior valore (ash (aref buffer (+ inizio i)) (* 8 i)))))))

(defun scrivi-intero (buffer inizio valore numero-byte)
  "Builder di fixture: controlla bounds e rappresentabilita prima di scrivere."
  (esigi (and (<= 1 numero-byte 8)
              (<= 0 inizio (+ inizio numero-byte) (length buffer))
              (< valore (ash 1 (* 8 numero-byte))))
         "REQ-FOR-002: scrittura intero fuori limiti.")
  (dotimes (i numero-byte buffer)
    (setf (aref buffer (+ inizio i)) (ldb (byte 8 (* 8 i)) valore))))

(declaim (ftype (function (octets) octets) aggiorna-crc-fixture)
         (ftype (function (&key (:versione u16) (:origine (unsigned-byte 8))
                               (:serie octets) (:segmento u64) (:timestamp u64))
                          octets) costruisci-fileheader))
(defun aggiorna-crc-fixture (buffer)
  "Fixture esattamente 64 byte; CRC reference SPK-09 sui byte 0..55."
  (esigi (= (length buffer) +fileheader-byte+) "Fixture non lunga 64 byte.")
  (scrivi-intero buffer +crc-offset+
                (crc32c-reference buffer 0 +crc-offset+) 4))

;;; REQ: REQ-FOR-002
(defun costruisci-fileheader (&key (versione 1) (origine 1)
                                  (serie (make-array 16 :element-type
                                                      '(unsigned-byte 8)
                                                       :initial-element 0))
                                  (segmento 1) (timestamp 0))
  "Costruisce SOLO una fixture: ARCDSEG1, versione u16 anche ignota per i test."
  (esigi (= (length serie) 16) "REQ-FOR-002: id Serie non lungo 16 byte.")
  (let ((buffer (make-array +fileheader-byte+ :element-type '(unsigned-byte 8)
                                            :initial-element 0)))
    (scrivi-intero buffer 0 +magic-segmento+ 8)
    (scrivi-intero buffer +versione-offset+ versione 2)
    (setf (aref buffer +origine-offset+) origine)
    (replace buffer serie :start1 +serie-offset+)
    (scrivi-intero buffer +segmento-offset+ segmento 8)
    (scrivi-intero buffer +timestamp-offset+ timestamp 8)
    (aggiorna-crc-fixture buffer)))

(declaim (ftype (function (octets integer) boolean) riservati-zero-p)
         (ftype (function (octets &key (:inizio integer) (:fine integer)) u16)
                versione-fileheader)
         (ftype (function (octets function function
                           &key (:inizio integer) (:fine integer)) function)
                seleziona-parser))
(defun riservati-zero-p (buffer inizio)
  "Tre intervalli fissi: 11..15, 48..55 e 60..63 (17 byte in totale)."
  (and (loop for i from 11 below 16 always (zerop (aref buffer (+ inizio i))))
       (loop for i from 48 below 56 always (zerop (aref buffer (+ inizio i))))
       (loop for i from 60 below 64 always (zerop (aref buffer (+ inizio i))))))

;;; REQ: REQ-FOR-002 REQ-LIM-003
(defun versione-fileheader (buffer &key (inizio 0) (fine (length buffer)))
  "Bounds, magic, CRC e semantica precedono versione e selezione del parser.
Non interpreta record; un'intestazione puo essere un prefisso del segmento."
  (unless (<= 0 inizio fine (length buffer)) (rifiuta-fileheader :bounds))
  (when (< (- fine inizio) +fileheader-byte+) (rifiuta-fileheader :troncato))
  (unless (= (leggi-intero buffer inizio 8) +magic-segmento+)
    (rifiuta-fileheader :magic))
  (unless (= (leggi-intero buffer (+ inizio +crc-offset+) 4)
             (crc32c-reference buffer inizio (+ inizio +crc-offset+)))
    (rifiuta-fileheader :crc))
  (unless (member (aref buffer (+ inizio +origine-offset+)) '(1 2))
    (rifiuta-fileheader :origine))
  (unless (riservati-zero-p buffer inizio) (rifiuta-fileheader :riservato))
  (let ((versione (leggi-intero buffer (+ inizio +versione-offset+) 2)))
    (unless (member versione '(1 2)) (rifiuta-fileheader :versione))
    versione))

(defun seleziona-parser (buffer parser-v1 parser-v2
                        &key (inizio 0) (fine (length buffer)))
  "Restituisce un callback SOLO dopo la verifica completa; non lo invoca."
  (case (versione-fileheader buffer :inizio inizio :fine fine)
    (1 parser-v1)
    (2 parser-v2)
    (otherwise (rifiuta-fileheader :versione))))

;;; Il contenuto e le prove sono fatti/booleani del modello, NON campi su disco.
;;; OWNER: un solo scenario locale; nessuno stato mutabile condiviso tra Serie.
(defstruct (stato (:constructor nuovo-stato
                              (&key (pin 0) (budget-passi +max-passi+)
                                    (budget-copie +max-copie+))))
  "Un sorgente e un output; nome-durevole astrae le alternative del rename."
  (sorgente t :type boolean)
  (contenuto-sorgente :v1-immutabile :type keyword)
  (tmp nil :type boolean)
  (definitivo nil :type boolean)
  (parziale nil :type boolean)
  (scritto nil :type boolean)
  (valido nil :type boolean)
  (verificato nil :type boolean)
  (file-durevole nil :type boolean)
  (nome-durevole :nessuno :type (member :nessuno :tmp :definitivo))
  (edit nil :type boolean)
  (rimozione-registrata nil :type boolean)
  (numero-edit 0 :type (integer 0 2))
  (completato nil :type boolean)
  (reclaimed nil :type boolean)
  (pin 0 :type (integer 0 1))
  (errore :nessuno :type keyword)
  (passi 0 :type (integer 0 32))
  (copie 0 :type (integer 0 4))
  (budget-passi +max-passi+ :type (integer 0 32) :read-only t)
  (budget-copie +max-copie+ :type (integer 0 4) :read-only t))

(declaim (ftype (function () list) fasi-migrazione)
         (ftype (function (stato keyword) boolean) addebita-fase)
         (ftype (function (stato) null) scarta-tmp))
(defun fasi-migrazione ()
  "Dieci fasi fisse, incluse scrittura parziale e durabilita del rename."
  '(:prepare.tmp :write.partial :write.v2 :verify :durable.file
    :durable.directory :publish.edit :complete.rename :complete.directory
    :reclaim))

(defun addebita-fase (stato fase)
  "Rifiuta prima degli effetti: ogni fase costa 1, ogni scrittura una copia."
  (let ((copie (if (member fase '(:write.partial :write.v2)) 1 0)))
    (if (or (>= (stato-passi stato) (stato-budget-passi stato))
            (> (+ (stato-copie stato) copie) (stato-budget-copie stato)))
        (progn (setf (stato-errore stato) :budget) nil)
        (progn (incf (stato-passi stato))
               (incf (stato-copie stato) copie) t))))

(defun scarta-tmp (stato)
  "Prima di EDIT: elimina SOLO tmp non nominato, preserva ogni definitivo."
  (esigi (not (stato-edit stato)) "REQ-AFF-018: tmp gia nominato da EDIT.")
  (when (stato-tmp stato)
    (setf (stato-tmp stato) nil))
  (unless (stato-definitivo stato)
    (setf (stato-parziale stato) nil (stato-scritto stato) nil
          (stato-valido stato) nil (stato-verificato stato) nil
          (stato-file-durevole stato) nil (stato-nome-durevole stato) :nessuno))
  (setf (stato-errore stato) :nessuno)
  nil)

(declaim (ftype (function (stato keyword keyword) null) prepara-o-verifica)
         (ftype (function (stato keyword) null) pubblica-edit)
         (ftype (function (stato keyword keyword) null) completa-o-reclaim)
         (ftype (function (stato keyword) null) ispeziona-output))
(defun prepara-o-verifica (stato fase scenario)
  "Preparazione scartabile; validita reale e responso del verificatore separati."
  (case fase
    (:prepare.tmp (setf (stato-tmp stato) t))
    (:write.partial (setf (stato-parziale stato) t))
    (:write.v2
     (setf (stato-parziale stato) nil (stato-scritto stato) t
           (stato-valido stato) (not (member scenario '(:corrotto :verifica-falsa)))))
    (:verify
     (setf (stato-verificato stato)
           (or (eq scenario :verifica-falsa)
               (and (stato-scritto stato) (stato-valido stato)
                    (not (eq scenario :verifica-negativa)))))
     (unless (stato-verificato stato) (setf (stato-errore stato) :verifica)))
    (:durable.file (setf (stato-file-durevole stato) t))
    (:durable.directory (setf (stato-nome-durevole stato) :tmp))
    (otherwise (error 'errore-spike :messaggio "Fase preparatoria sconosciuta.")))
  nil)

;;; REQ: REQ-AFF-019 REQ-LIM-003
(defun pubblica-edit (stato mutante)
  "UNICO commit del modello: EDIT durevole, prima di qualunque completamento.
La validita reale appartiene all'oracle: un falso verificatore non e infallibile."
  (esigi (and (stato-tmp stato) (stato-scritto stato)
              (stato-file-durevole stato) (eq (stato-nome-durevole stato) :tmp)
              (or (stato-verificato stato) (eq mutante :skip-verification))
              (not (stato-edit stato)))
         "REQ-AFF-019: preparazione o verifica mancante prima di EDIT.")
  (setf (stato-edit stato) t (stato-rimozione-registrata stato) t)
  (incf (stato-numero-edit stato))
  nil)

(defun ispeziona-output (stato fase)
  "Dopo EDIT: tmp O definitivo devono esistere e verificare; altrimenti integrita."
  (esigi (member fase '(:inspect.output :complete.rename)) "Fase ispezione ignota.")
  (unless (and (or (stato-tmp stato) (stato-definitivo stato))
               (stato-scritto stato) (stato-valido stato)
               (stato-file-durevole stato))
    (setf (stato-errore stato) :integrita))
  nil)

;;; REQ: REQ-AFF-007 REQ-AFF-018 REQ-AFF-019
(defun completa-o-reclaim (stato fase mutante)
  "Dopo il commit: rename, syncdir e reclaim idempotenti, senza attese dei pin."
  (esigi (stato-edit stato) "REQ-AFF-019: completamento prima di EDIT.")
  (case fase
    (:complete.rename
     (ispeziona-output stato fase)
     (when (eq (stato-errore stato) :nessuno)
       (setf (stato-tmp stato) nil (stato-definitivo stato) t)))
    (:complete.directory
     (esigi (stato-definitivo stato) "REQ-AFF-007: definitivo mancante.")
     (setf (stato-nome-durevole stato) :definitivo (stato-completato stato) t))
    (:reclaim
     (esigi (and (stato-rimozione-registrata stato) (stato-completato stato)
                 (eq (stato-nome-durevole stato) :definitivo))
            "REQ-AFF-018: reclaim senza prova o completamento.")
     (when (or (zerop (stato-pin stato)) (eq mutante :reclaim-pinned))
       (setf (stato-sorgente stato) nil (stato-reclaimed stato) t)))
    (otherwise (error 'errore-spike :messaggio "Completamento sconosciuto.")))
  nil)

(declaim (ftype (function (stato keyword &key (:scenario keyword)
                                           (:mutante keyword)) stato) avanza))
(defun avanza (precedente fase &key (scenario :sano) (mutante :nessuno))
  "Transizione locale limitata; non altera il predecessore dello scenario."
  (let ((stato (copy-stato precedente)))
    (when (and (eq (stato-errore stato) :nessuno) (addebita-fase stato fase))
      (case fase
        ((:prepare.tmp :write.partial :write.v2 :verify :durable.file
          :durable.directory)
         (unless (and (eq fase :verify) (eq mutante :skip-verification))
           (prepara-o-verifica stato fase scenario))
         (when (and (eq fase :prepare.tmp) (eq mutante :unlink-before-edit))
           (setf (stato-sorgente stato) nil)))
        (:publish.edit (pubblica-edit stato mutante))
        ((:complete.rename :complete.directory :reclaim)
         (completa-o-reclaim stato fase mutante))
        (:discard.tmp (scarta-tmp stato))
        (:report.unknown
         (when (stato-definitivo stato) (setf (stato-errore stato) :anomalia)))
        (:inspect.output (ispeziona-output stato fase))
        (otherwise (error 'errore-spike :messaggio "Transizione sconosciuta."))))
    stato))

(declaim (ftype (function (stato) keyword) oracle-sorgente)
         (ftype (function (stato) keyword) oracle-edit)
         (ftype (function (stato) keyword) oracle))
(defun oracle-sorgente (stato)
  "Oracle indipendente: contenuto immutabile, rimozione e pin, nessuna transizione."
  (cond
    ((not (eq (stato-contenuto-sorgente stato) :v1-immutabile)) :sorgente-mutata)
    ((and (not (stato-edit stato)) (not (stato-sorgente stato))) :unlink-before-edit)
    ((and (plusp (stato-pin stato)) (not (stato-sorgente stato))) :reclaim-pinned)
    ((and (not (stato-sorgente stato))
          (not (and (stato-edit stato) (stato-rimozione-registrata stato)
                    (stato-reclaimed stato) (stato-completato stato))))
     :rimozione-senza-prova)
    ((and (stato-reclaimed stato) (stato-sorgente stato)) :reclaim-incoerente)
    (t :ok)))

(defun oracle-edit (stato)
  "Un solo EDIT; dopo EDIT v2 verificato, durevole e presente prima del reclaim."
  (cond
    ((/= (stato-numero-edit stato) (if (stato-edit stato) 1 0)) :numero-edit)
    ((and (stato-edit stato) (not (stato-verificato stato))) :skip-verification)
    ((and (stato-edit stato)
          (not (and (stato-valido stato) (stato-scritto stato)
                    (stato-file-durevole stato)
                    (not (eq (stato-nome-durevole stato) :nessuno))
                    (or (stato-tmp stato) (stato-definitivo stato)))))
     :output-committed-invalido)
    ((and (not (stato-edit stato)) (stato-rimozione-registrata stato))
     :rimozione-senza-edit)
    ((and (stato-verificato stato) (not (stato-valido stato))) :verifica-falsa)
    (t :ok)))

(defun oracle (stato)
  "Fonte selezionata: v1 prima di EDIT, v2 dopo; oracle non chiama il workflow."
  (let ((sorgente (oracle-sorgente stato)))
    (if (eq sorgente :ok) (oracle-edit stato) sorgente)))

(declaim (ftype (function (stato) list) osservazione)
         (ftype (function (stato boolean boolean) stato) crash)
         (ftype (function (stato &key (:interruzione (integer 0 4))) stato)
                recupera)
         (ftype (function (stato) stato) riesegui-migrazione))
(defun osservazione (stato)
  "Stato logico/durevole: esclude contatori di lavoro e budget dell'esecutore."
  (list (if (stato-edit stato) :v2 :v1)
        (stato-sorgente stato) (stato-contenuto-sorgente stato)
        (stato-tmp stato) (stato-definitivo stato) (stato-parziale stato)
        (stato-scritto stato) (stato-valido stato) (stato-verificato stato)
        (stato-file-durevole stato) (stato-nome-durevole stato)
        (stato-edit stato) (stato-rimozione-registrata stato)
        (stato-numero-edit stato) (stato-completato stato)
        (stato-reclaimed stato) (stato-pin stato) (stato-errore stato)))

(defun crash (precedente conserva-nome conserva-contenuto)
  "Quattro alternative finite; un nome/content durevole non viene perduto.
Rename non sincronizzato: vecchio tmp oppure nuovo definitivo, mai nessuno."
  (let ((stato (copy-stato precedente)))
    (unless conserva-nome
      (case (stato-nome-durevole stato)
        (:nessuno (setf (stato-tmp stato) nil (stato-definitivo stato) nil))
        (:tmp (setf (stato-tmp stato) t (stato-definitivo stato) nil))
        (:definitivo (setf (stato-tmp stato) nil (stato-definitivo stato) t))
        (otherwise (error 'errore-spike :messaggio "Nome durevole sconosciuto."))))
    (when (and (not conserva-contenuto) (not (stato-file-durevole stato)))
      (setf (stato-parziale stato) (or (stato-tmp stato) (stato-definitivo stato))
            (stato-scritto stato) nil (stato-valido stato) nil
            (stato-verificato stato) nil))
    (setf (stato-completato stato)
          (and (stato-definitivo stato)
               (eq (stato-nome-durevole stato) :definitivo))
          (stato-errore stato) :nessuno)
    stato))

;;; REQ: REQ-AFF-007 REQ-AFF-018 REQ-AFF-019
(defun recupera (precedente &key (interruzione +max-recovery+))
  "Ripete solo scarto prima di EDIT o completamenti dopo; massimo quattro passi.
Interruzione N significa fermarsi dopo N effetti astratti, non un crash fisico."
  (let ((stato (copy-stato precedente))
        (fasi (if (stato-edit precedente)
                  '(:inspect.output :complete.rename :complete.directory :reclaim)
                  '(:discard.tmp :report.unknown))))
    (setf (stato-errore stato) :nessuno)
    (loop for fase in fasi for i below interruzione
          while (eq (stato-errore stato) :nessuno)
          do (setf stato (avanza stato fase)))
    stato))

(defun riesegui-migrazione (precedente)
  "Rerun sano: recupera prima; dopo EDIT non converte di nuovo e non ripubblica."
  (let ((stato (recupera precedente)))
    (when (and (not (stato-edit stato)) (eq (stato-errore stato) :nessuno))
      (dolist (fase (fasi-migrazione)) (setf stato (avanza stato fase))))
    stato))

(declaim (ftype (function (octets (or null keyword)
                           &key (:inizio integer) (:fine integer)) null)
                attendi-rifiuto-fileheader))
(defun attendi-rifiuto-fileheader (buffer motivo
                                 &key (inizio 0) (fine (length buffer)))
  "REQ-FOR-002: ogni rifiuto deve precedere l'invocazione del parser."
  (let ((invocazioni 0) (rifiutato nil))
    (flet ((parser () (incf invocazioni)))
      (handler-case
          (funcall (seleziona-parser buffer #'parser #'parser
                                    :inizio inizio :fine fine))
        (fileheader-invalido (condizione)
          (when motivo
            (esigi (eq motivo (motivo-fileheader condizione))
                   "REQ-FOR-002: motivo del rifiuto errato."))
          (setf rifiutato t))))
    (esigi (and rifiutato (zerop invocazioni))
           "REQ-FOR-002: fileheader invalido ammesso a un parser."))
  nil)

(declaim (ftype (function (octets) (integer 0 *)) check-REQ-FOR-002-mutazioni))
(defun check-REQ-FOR-002-mutazioni (header)
  "512 bit flip, 64 troncamenti, 17 riservati con CRC ricalcolato, tre origini."
  (let ((conteggio 0))
    (dotimes (i +fileheader-byte+)
      (dotimes (bit 8)
        (let ((guasto (copy-seq header)))
          (setf (aref guasto i) (logxor (aref guasto i) (ash 1 bit)))
          (attendi-rifiuto-fileheader guasto nil)
          (incf conteggio)))
      (attendi-rifiuto-fileheader header :troncato :fine i)
      (incf conteggio))
    (dolist (intervallo '((11 16) (48 56) (60 64)))
      (loop for i from (first intervallo) below (second intervallo) do
        (let ((guasto (copy-seq header)))
          (setf (aref guasto i) 1)
          (aggiorna-crc-fixture guasto)
          (attendi-rifiuto-fileheader guasto :riservato)
          (incf conteggio))))
    (dolist (origine '(0 3 255))
      (let ((guasto (copy-seq header)))
        (setf (aref guasto +origine-offset+) origine)
        (aggiorna-crc-fixture guasto)
        (attendi-rifiuto-fileheader guasto :origine)
        (incf conteggio)))
    conteggio))

(declaim (ftype (function () list) check-REQ-FOR-002-fileheaders))
(defun check-REQ-FOR-002-fileheaders ()
  "Selezione v1/v2 con magic invariato, intervalli traslati e tutte le mutazioni."
  (let ((accettati 0) (rifiuti 0)
        (serie (make-array 16 :element-type '(unsigned-byte 8))))
    (dotimes (i 16) (setf (aref serie i) (+ i 1)))
    (dolist (versione '(1 2))
      (dolist (origine '(1 2))
        (let* ((header (costruisci-fileheader :versione versione :origine origine
                                            :serie serie :segmento #xffffffffffffffff
                                            :timestamp #xffffffffffffffff))
               (v1 (lambda () :v1)) (v2 (lambda () :v2))
               (traslato (make-array 80 :element-type '(unsigned-byte 8)
                                       :initial-element 255)))
          (esigi (eq (seleziona-parser header v1 v2) (if (= versione 1) v1 v2))
                 "REQ-FOR-002: scelta parser errata.")
          (incf accettati)
          (replace traslato header :start1 8)
          (esigi (= versione (versione-fileheader traslato :inizio 8 :fine 72))
                 "REQ-FOR-002: fileheader traslato errato.")
          (incf accettati)
          (incf rifiuti (check-REQ-FOR-002-mutazioni header)))))
    (dolist (versione '(0 3 256 65535))
      (attendi-rifiuto-fileheader (costruisci-fileheader :versione versione) :versione)
      (incf rifiuti))
    (let ((header (costruisci-fileheader)))
      (dolist (limiti '((-1 64) (0 65) (65 64) (1 0)))
        (attendi-rifiuto-fileheader header :bounds
                                   :inizio (first limiti) :fine (second limiti))
        (incf rifiuti))
      (setf (aref header 7) (char-code #\2))
      (aggiorna-crc-fixture header)
      (attendi-rifiuto-fileheader header :magic)
      (incf rifiuti))
    (list :accettati accettati :rifiutati rifiuti :bit-flip 2048
          :troncamenti 256 :riservati-crc-valido 68 :origini-invalide 12
          :versioni-ignote 4 :bounds-invalidi 4 :magic-alternativo-rifiutato 1
          :parser-invocati-su-header-invalidi 0)))

(declaim (ftype (function (keyword (integer 0 1)) list) prefissi-scenario)
         (ftype (function (stato stato) null) confronta-recupero)
         (ftype (function (stato) list) check-REQ-AFF-007-prefisso))
(defun prefissi-scenario (scenario pin)
  "Al massimo 11 prefissi; ferma al primo rifiuto o falso responso rilevato."
  (let* ((stato (nuovo-stato :pin pin)) (prefissi (list stato)))
    (dolist (fase (fasi-migrazione))
      (when (and (eq (stato-errore stato) :nessuno) (eq (oracle stato) :ok))
        (setf stato (avanza stato fase :scenario scenario))
        (push stato prefissi)))
    (esigi (<= (length prefissi) +max-prefissi+) "Budget prefissi superato.")
    (nreverse prefissi)))

(defun confronta-recupero (ottenuto atteso)
  "Confronta tutti i fatti del modello, esclusi i soli costi dell'esecutore."
  (unless (equal (osservazione ottenuto) (osservazione atteso))
    (error 'errore-spike :messaggio
           (format nil "REQ-AFF-007: recovery/rerun non idempotente: ~S / ~S."
                   (osservazione ottenuto) (osservazione atteso))))
  (esigi (eq (oracle ottenuto) :ok) "REQ-AFF-007: oracle recovery fallito.")
  nil)

(defun check-REQ-AFF-007-prefisso (precedente)
  "Crash in quattro esiti e interruzione di ciascuno dei quattro passi recovery."
  (let ((crash-contati 0) (recovery-contati 0) (rerun-contati 0)
        (massimo 0) (massimo-copie 0))
    (dolist (nome '(nil t))
      (dolist (contenuto '(nil t))
        (let* ((interrotto (crash precedente nome contenuto))
               (atteso (recupera interrotto))
               (ripetuto (recupera atteso))
               (rerun (riesegui-migrazione interrotto))
               (rerun-ripetuto (riesegui-migrazione rerun)))
          (confronta-recupero ripetuto atteso)
          (confronta-recupero rerun-ripetuto rerun)
          (dolist (esito (list atteso ripetuto rerun rerun-ripetuto))
            (setf massimo (max massimo (stato-passi esito))
                  massimo-copie (max massimo-copie (stato-copie esito))))
          (esigi (and (stato-edit rerun) (stato-definitivo rerun)
                      (stato-completato rerun))
                 "REQ-LIM-003: rerun sano non pubblicato.")
          (incf crash-contati)
          (incf rerun-contati)
          (dotimes (interruzione (1+ +max-recovery+))
            (let ((parziale (recupera interrotto :interruzione interruzione)))
              (dolist (nome-recovery '(nil t))
                (dolist (contenuto-recovery '(nil t))
                  (let* ((nuovo-crash (crash parziale nome-recovery contenuto-recovery))
                         (termine (recupera nuovo-crash))
                         (ripetuto (recupera termine)))
                    (confronta-recupero termine atteso)
                    (confronta-recupero ripetuto termine)
                    (setf massimo (max massimo (stato-passi ripetuto))
                          massimo-copie (max massimo-copie (stato-copie ripetuto)))
                    (incf recovery-contati)))))))))
    (list :crash crash-contati :recovery recovery-contati
          :rerun rerun-contati :massimo-passi massimo :massimo-copie massimo-copie)))

(declaim (ftype (function () list) check-REQ-AFF-007-enumerazione))
(defun check-REQ-AFF-007-enumerazione ()
  "Quattro scenari, pin 0/1, ogni prefisso raggiungibile e tutte le interruzioni."
  (let ((prefissi 0) (crash 0) (recovery 0) (rerun 0) (massimo 0) (massimo-copie 0)
        (false-verifiche 0) (rifiuti-verifica 0))
    (dolist (scenario '(:sano :corrotto :verifica-negativa :verifica-falsa))
      (dotimes (pin 2)
        (dolist (stato (prefissi-scenario scenario pin))
          (incf prefissi)
          (case (oracle stato)
            (:ok nil)
            (:verifica-falsa
             (esigi (and (eq scenario :verifica-falsa) (not (stato-edit stato)))
                    "REQ-LIM-003: falso responso fuori scenario.")
             (incf false-verifiche))
            (otherwise (error 'errore-spike :messaggio "Oracle prefisso fallito.")))
          (when (eq (stato-errore stato) :verifica) (incf rifiuti-verifica))
          (let ((risultato (check-REQ-AFF-007-prefisso stato)))
            (incf crash (getf risultato :crash))
            (incf recovery (getf risultato :recovery))
            (incf rerun (getf risultato :rerun))
            (setf massimo (max massimo (getf risultato :massimo-passi))
                  massimo-copie (max massimo-copie (getf risultato :massimo-copie)))))))
    (esigi (and (= false-verifiche 2) (= rifiuti-verifica 4))
           "REQ-LIM-003: scenari di verifica non coperti.")
    (list :scenari 4 :stati-pin 2 :prefissi prefissi :crash crash
          :interruzioni-recovery recovery :rerun rerun :massimo-passi massimo
          :massimo-copie massimo-copie
          :false-verifiche-rilevate-da-oracle false-verifiche
          :verifiche-negative rifiuti-verifica)))

(declaim (ftype (function () stato) stato-pubblicato)
         (ftype (function () list) check-REQ-AFF-018-anomalie))
(defun stato-pubblicato ()
  "Fixture del modello: EDIT appena durevole, solo tmp presente e sorgente intatta."
  (let ((stato (nuovo-stato)))
    (loop for fase in (fasi-migrazione) repeat 7
          do (setf stato (avanza stato fase)))
    stato))

(defun check-REQ-AFF-018-anomalie ()
  "Output mancante = tmp E definitivo assenti; sconosciuti non cancellati."
  (let ((conteggio 0) (pubblicato (stato-pubblicato)))
    (esigi (and (stato-tmp pubblicato) (not (stato-definitivo pubblicato)))
           "REQ-AFF-019: ordine tmp -> EDIT -> rename alterato.")
    (esigi (eq (oracle (recupera pubblicato)) :ok)
           "REQ-AFF-007: solo definitivo assente non e un guasto.")
    (incf conteggio)
    (dolist (guasto '(:mancante :corrotto))
      (let ((stato (copy-stato pubblicato)))
        (case guasto
          (:mancante (setf (stato-tmp stato) nil (stato-definitivo stato) nil))
          (:corrotto (setf (stato-valido stato) nil))
          (otherwise (error 'errore-spike :messaggio "Guasto ignoto.")))
        (let ((recuperato (recupera stato)))
          (esigi (and (eq (stato-errore recuperato) :integrita)
                      (stato-sorgente recuperato) (stato-edit recuperato)
                      (not (stato-reclaimed recuperato)))
                 "REQ-AFF-018: guasto committed non dichiarato.")
          (esigi (equal (osservazione recuperato)
                        (osservazione (recupera recuperato)))
                 "REQ-AFF-007: dichiarazione integrita non idempotente."))
        (incf conteggio)))
    (let* ((sconosciuto (nuovo-stato))
           (preservato (progn (setf (stato-definitivo sconosciuto) t)
                              (recupera sconosciuto))))
      (esigi (and (stato-definitivo preservato) (stato-sorgente preservato)
                  (not (stato-edit preservato))
                  (eq (stato-errore preservato) :anomalia))
             "REQ-AFF-018: definitivo sconosciuto cancellato o non segnalato.")
      (esigi (equal (osservazione preservato)
                    (osservazione (recupera preservato)))
             "REQ-AFF-007: anomalia non idempotente.")
      (incf conteggio))
    (list :casi conteggio :tmp-nominato-rinominato 1
          :errori-integrita 2 :definitivi-sconosciuti-conservati 1)))

(declaim (ftype (function () list) check-REQ-LIM-003-budget-pin)
         (ftype (function () list) check-REQ-AFF-019-mutanti))
(defun check-REQ-LIM-003-budget-pin ()
  "Saturazione in ogni fase, copie 0/1, recovery interrotto, rilascio pin esplicito."
  (let ((budget-contati 0))
    (dotimes (budget +max-fasi+)
      (let ((stato (nuovo-stato :budget-passi budget)))
        (dolist (fase (fasi-migrazione)) (setf stato (avanza stato fase)))
        (esigi (and (eq (stato-errore stato) :budget)
                    (= (stato-passi stato) budget) (eq (oracle stato) :ok)
                    (eq (stato-edit stato) (>= budget 7)))
               "REQ-LIM-003: limite di fasi non controllato.")
        (incf budget-contati)))
    (dotimes (budget 2)
      (let ((stato (nuovo-stato :budget-copie budget)))
        (dolist (fase (fasi-migrazione)) (setf stato (avanza stato fase)))
        (esigi (and (eq (stato-errore stato) :budget)
                    (= (stato-copie stato) budget)
                    (not (stato-edit stato)) (stato-sorgente stato))
               "REQ-LIM-003: budget di copia non controllato.")
        (incf budget-contati)))
    (let* ((pubblicato (stato-pubblicato))
           (senza-budget (copy-stato pubblicato)))
      (setf (stato-passi senza-budget) +max-passi+)
      (let ((fermo (recupera senza-budget)))
        (esigi (and (eq (stato-errore fermo) :budget)
                    (stato-sorgente fermo) (stato-tmp fermo)
                    (eq (oracle fermo) :ok))
               "REQ-AFF-007: recovery oltre budget."))
      (incf budget-contati)
      (setf (stato-pin pubblicato) 1)
      (let ((trattenuto (recupera pubblicato)))
        (esigi (and (stato-sorgente trattenuto) (not (stato-reclaimed trattenuto))
                    (stato-completato trattenuto) (eq (oracle trattenuto) :ok))
               "REQ-LIM-003: sorgente pinned rimossa.")
        (setf (stato-pin trattenuto) 0)
        (let ((liberato (recupera trattenuto)))
          (esigi (and (not (stato-sorgente liberato)) (stato-reclaimed liberato)
                      (= (stato-numero-edit liberato) 1) (eq (oracle liberato) :ok))
                 "REQ-AFF-018: reclaim dopo rilascio pin errato."))))
    (list :saturazioni budget-contati :pin-trattenuto 1 :pin-rilasciato 1)))

(defun check-REQ-AFF-019-mutanti ()
  "Tre mutanti applicati alle transizioni, rilevati dall'oracle indipendente."
  (let ((risultati nil))
    (dolist (mutante '(:unlink-before-edit :skip-verification :reclaim-pinned))
      (let ((stato (nuovo-stato :pin (if (eq mutante :reclaim-pinned) 1 0)))
            (rilevato nil) (fase-rilevata nil))
        (dolist (fase (fasi-migrazione))
          (unless rilevato
            (setf stato (avanza stato fase :mutante mutante))
            (unless (eq (oracle stato) :ok)
              (setf rilevato (oracle stato) fase-rilevata fase))))
        (esigi (eq rilevato mutante) "REQ-AFF-019: mutante sfuggito all'oracle.")
        (push (list :mutante mutante :rilevato t :fase fase-rilevata
                    :oracle rilevato) risultati)))
    (nreverse risultati)))

;;; REQ: REQ-FOR-002 REQ-LIM-003 REQ-AFF-007 REQ-AFF-018 REQ-AFF-019
(declaim (ftype (function () list) check))
(defun check ()
  "Check breve deterministico. Limiti e conteggi reali; nessun gate v2 completato."
  (let ((header (check-REQ-FOR-002-fileheaders))
        (modello (check-REQ-AFF-007-enumerazione))
        (anomalie (check-REQ-AFF-018-anomalie))
        (budget (check-REQ-LIM-003-budget-pin))
        (mutanti (check-REQ-AFF-019-mutanti)))
    (esigi (<= (getf modello :massimo-passi) +max-passi+)
           "REQ-LIM-003: costo per scenario oltre limite.")
    (list :status :ok :fileheaders header :modello modello :anomalie anomalie
          :budget budget :mutanti-rilevati 3 :mutanti-attesi mutanti
          :limiti (list :fileheader-byte +fileheader-byte+ :crc-byte +crc-offset+
                        :sorgenti 1 :output 1 :pin-massimo 1
                        :passi-per-esecuzione +max-passi+ :copie +max-copie+
                        :copie-per-tentativo +copie-per-tentativo+
                        :fasi +max-fasi+ :passi-recovery +max-recovery+
                        :prefissi-per-scenario +max-prefissi+
                        :scenari +max-scenari+ :alternative-crash +max-crash+)
          :conversione-byte nil :crash-reali-verificati nil)))
