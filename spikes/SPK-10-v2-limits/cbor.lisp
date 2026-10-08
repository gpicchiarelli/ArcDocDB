;;;; SPK-10: validazione iterativa di un sottoinsieme CBOR deterministico.
;;;; Esperimento indipendente; profilo e limiti in metodo-cbor.md.
;;; REQ: REQ-LIM-002
;;; REQ: REQ-AFF-008
;;; REQ: REQ-SIM-002

(defpackage #:arcdocdb.spk10.cbor
  (:use #:cl)
  (:export #:check #:benchmark #:valida-documento #:errore-cbor
           #:ragione #:posizione #:nodi #:profondita #:tag-letti))

(in-package #:arcdocdb.spk10.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 1)))

(defconstant +documento-max+ 16777216)
(defconstant +contenitori-max+ 100)
(deftype ottetti () '(simple-array (unsigned-byte 8) (*)))
(deftype indice () '(integer 0 16777216))

(define-condition errore-cbor (error)
  ((ragione :initarg :reason :reader ragione :type keyword)
   (posizione :initarg :offset :initform 0 :reader posizione :type indice)
   (nodi :initarg :nodes :initform 0 :reader nodi :type indice)
   (profondita :initarg :depth :initform 0 :reader profondita
               :type (integer 0 100))
   (tag-letti :initarg :tags :initform 0 :reader tag-letti :type indice))
  (:report (lambda (condizione stream)
             (format stream "CBOR rifiutato: ~S, byte ~D, nodi ~D, profondita ~D."
                     (ragione condizione) (posizione condizione)
                     (nodi condizione) (profondita condizione)))))

(define-condition errore-fixture (error)
  ((dettaglio :initarg :dettaglio :reader dettaglio-fixture :type t))
  (:report (lambda (condizione stream)
             (format stream "Controllo CBOR fallito: ~S"
                     (dettaglio-fixture condizione)))))

(defstruct contenitore
  "Frame preallocato: figli ancora da completare e span delle chiavi."
  (tipo 4 :type (integer 4 5))
  (residui 0 :type indice)
  (inizio 0 :type indice)
  (chiave-inizio -1 :type (integer -1 16777216))
  (chiave-fine 0 :type indice))

(defstruct (validazione (:constructor crea-validazione))
  "Stato locale di una chiamata; nessun contenuto dell'input viene copiato."
  (buffer (make-array 0 :element-type '(unsigned-byte 8))
          :type ottetti :read-only t)
  (lunghezza 0 :type indice :read-only t)
  (budget-nodi 0 :type indice :read-only t)
  (limite-profondita 0 :type (integer 0 100) :read-only t)
  (pila #() :type simple-vector :read-only t)
  (cima 0 :type (integer 0 100))
  (posizione 0 :type indice)
  (nodi 0 :type indice)
  (profondita 0 :type (integer 0 100))
  (tag-letti 0 :type indice)
  (conclusa nil :type boolean))

(declaim (ftype (function (keyword &optional (or null validazione)) nil) rifiuta))
(defun rifiuta (motivo &optional stato)
  "Segnala un errore esplicito con i contatori al momento del rifiuto."
  (if stato
      (error 'errore-cbor :reason motivo
             :offset (validazione-posizione stato)
             :nodes (validazione-nodi stato)
             :depth (validazione-profondita stato)
             :tags (validazione-tag-letti stato))
      (error 'errore-cbor :reason motivo)))

(defun controlla-parametri (buffer limite-documento limite-profondita
                           budget-nodi budget-byte)
  "Configura solo limiti entro i tetti: nessuna lettura o pila prima dei controlli."
  (unless (typep buffer 'ottetti) (rifiuta :invalid-buffer))
  (unless (typep limite-documento '(integer 1 16777216))
    (rifiuta :invalid-limit))
  (unless (typep limite-profondita '(integer 0 100))
    (rifiuta :invalid-limit))
  (unless (and (typep budget-nodi 'indice) (typep budget-byte 'indice))
    (rifiuta :invalid-budget))
  (when (> (length buffer) limite-documento) (rifiuta :document-limit))
  (when (> (length buffer) budget-byte) (rifiuta :byte-budget))
  (when (zerop budget-nodi) (rifiuta :node-budget))
  (when (zerop (length buffer)) (rifiuta :truncated))
  t)

(declaim (ftype (function (validazione (integer 0 *)) null) esigi-byte))
(defun esigi-byte (stato quanti)
  "Verifica la disponibilita con sottrazione prima di sommare offset non fidati."
  (when (> quanti (- (validazione-lunghezza stato)
                    (validazione-posizione stato)))
    (rifiuta :truncated stato))
  nil)

(defun leggi-argomento (stato aggiuntivo)
  "Legge al massimo otto byte, imponendo la rappresentazione minima."
  (declare (type validazione stato) (type (integer 0 30) aggiuntivo))
  (when (< aggiuntivo 24) (return-from leggi-argomento aggiuntivo))
  (let ((quanti (case aggiuntivo
                 (24 1) (25 2) (26 4) (27 8)
                 (otherwise (rifiuta :reserved stato))))
        (valore 0))
    (declare (type (unsigned-byte 64) valore))
    (esigi-byte stato quanti)
    (dotimes (i quanti)
      (setf valore (logior (ash valore 8)
                          (aref (validazione-buffer stato)
                                (validazione-posizione stato))))
      (incf (validazione-posizione stato)))
    (when (< valore (case quanti
                      (1 24) (2 256) (4 65536) (8 4294967296)
                      (otherwise (rifiuta :internal-invariant stato))))
      (rifiuta :nonminimal stato))
    valore))

(defun leggi-semplice (stato aggiuntivo)
  "Ammette solo false/true/null; verifica prima i payload di tipi non supportati."
  (declare (type validazione stato) (type (integer 0 30) aggiuntivo))
  (case aggiuntivo
    ((20 21 22) aggiuntivo)
    (24 (esigi-byte stato 1)
        (let ((valore (aref (validazione-buffer stato)
                            (validazione-posizione stato))))
          (incf (validazione-posizione stato))
          (when (< valore 32) (rifiuta :malformed-simple stato))
          (rifiuta :unsupported stato)))
    ((25 26 27)
     (let ((quanti (ash 1 (- aggiuntivo 24))))
       (esigi-byte stato quanti)
       (incf (validazione-posizione stato) quanti)
       (rifiuta :unsupported stato)))
    (otherwise (rifiuta :unsupported stato))))

(defun leggi-testata (stato)
  "Restituisce tipo, argomento e inizio; rifiuta forme indefinite e riservate."
  (declare (type validazione stato))
  (esigi-byte stato 1)
  (let* ((inizio (validazione-posizione stato))
         (byte (aref (validazione-buffer stato) inizio))
         (tipo (ash byte -5)) (aggiuntivo (logand byte 31)))
    (incf (validazione-posizione stato))
    (when (= aggiuntivo 31) (rifiuta :indefinite stato))
    (when (<= 28 aggiuntivo 30) (rifiuta :reserved stato))
    (values tipo (if (= tipo 7) (leggi-semplice stato aggiuntivo)
                    (leggi-argomento stato aggiuntivo)) inizio)))

(defun larghezza-utf8 (stato byte)
  "Larghezza di uno scalar UTF-8, rifiutando lead overlong e fuori intervallo."
  (declare (type validazione stato) (type (unsigned-byte 8) byte))
  (cond ((< byte #x80) 1)
        ((<= #xc2 byte #xdf) 2)
        ((<= #xe0 byte #xef) 3)
        ((<= #xf0 byte #xf4) 4)
        (t (rifiuta :utf8 stato))))

(defun controlla-suite-utf8 (stato inizio quanti)
  "Controlla continuazioni, surrogate, overlong e limite U+10FFFF."
  (declare (type validazione stato) (type indice inizio)
           (type (integer 2 4) quanti))
  (let* ((buffer (validazione-buffer stato))
         (lead (aref buffer inizio)) (secondo (aref buffer (1+ inizio))))
    (loop for j from 1 below quanti do
      (unless (<= #x80 (aref buffer (+ inizio j)) #xbf)
        (rifiuta :utf8 stato)))
    (when (or (and (= lead #xe0) (< secondo #xa0))
              (and (= lead #xed) (> secondo #x9f))
              (and (= lead #xf0) (< secondo #x90))
              (and (= lead #xf4) (> secondo #x8f)))
      (rifiuta :utf8 stato)))
  nil)

(defun controlla-utf8 (stato fine)
  "Scansione iterativa senza costruire caratteri: al piu un passo per byte."
  (declare (type validazione stato) (type indice fine))
  (loop repeat (- fine (validazione-posizione stato))
        while (< (validazione-posizione stato) fine) do
    (let* ((inizio (validazione-posizione stato))
           (quanti (larghezza-utf8 stato
                                  (aref (validazione-buffer stato) inizio))))
      (when (> quanti (- fine inizio)) (rifiuta :utf8 stato))
      (when (> quanti 1) (controlla-suite-utf8 stato inizio quanti))
      (incf (validazione-posizione stato) quanti)))
  nil)

(defun confronta-span (buffer a-inizio a-fine b-inizio b-fine)
  "Ordine lessicografico dei byte, senza allocazioni; risultato -1, 0, 1."
  (declare (type ottetti buffer)
           (type indice a-inizio a-fine b-inizio b-fine))
  (let ((a-len (- a-fine a-inizio)) (b-len (- b-fine b-inizio)))
    (dotimes (i (min a-len b-len))
      (let ((a (aref buffer (+ a-inizio i)))
            (b (aref buffer (+ b-inizio i))))
        (when (< a b) (return-from confronta-span -1))
        (when (> a b) (return-from confronta-span 1))))
    (cond ((< a-len b-len) -1) ((> a-len b-len) 1) (t 0))))

(defun completa-chiave (stato frame inizio)
  "Una chiave e gia validata per intero, anche quando e un contenitore."
  (declare (type validazione stato) (type contenitore frame)
           (type indice inizio))
  (when (>= (contenitore-chiave-inizio frame) 0)
    (case (confronta-span (validazione-buffer stato)
                         (contenitore-chiave-inizio frame)
                         (contenitore-chiave-fine frame)
                         inizio (validazione-posizione stato))
      (-1 nil)
      (0 (rifiuta :duplicate-key stato))
      (1 (rifiuta :key-order stato))
      (otherwise (rifiuta :internal-invariant stato))))
  (setf (contenitore-chiave-inizio frame) inizio
        (contenitore-chiave-fine frame) (validazione-posizione stato))
  nil)

(defun completa-nodo (stato inizio)
  "Risale gli antenati sulla pila esplicita, al piu limite-profondita + 1 passi."
  (declare (type validazione stato) (type indice inizio))
  (loop repeat (1+ (validazione-limite-profondita stato)) do
    (when (zerop (validazione-cima stato))
      (setf (validazione-conclusa stato) t)
      (return-from completa-nodo nil))
    (let ((frame (aref (validazione-pila stato)
                       (1- (validazione-cima stato)))))
      (declare (type contenitore frame))
      (unless (plusp (contenitore-residui frame))
        (rifiuta :internal-invariant stato))
      (when (and (= (contenitore-tipo frame) 5)
                 (evenp (contenitore-residui frame)))
        (completa-chiave stato frame inizio))
      (decf (contenitore-residui frame))
      (unless (zerop (contenitore-residui frame))
        (return-from completa-nodo nil))
      (setf inizio (contenitore-inizio frame))
      (decf (validazione-cima stato))))
  (rifiuta :internal-invariant stato))

(defun apri-contenitore (stato tipo quanti inizio)
  "Conta anche contenitori vuoti; nessuna allocazione dal conteggio dichiarato."
  (declare (type validazione stato) (type (integer 4 5) tipo)
           (type (unsigned-byte 64) quanti) (type indice inizio))
  (let ((livello (1+ (validazione-cima stato)))
        (figli (if (= tipo 5) (* 2 quanti) quanti)))
    (when (> livello (validazione-limite-profondita stato))
      (rifiuta :depth-limit stato))
    (setf (validazione-profondita stato)
          (max livello (validazione-profondita stato)))
    (esigi-byte stato figli)
    (when (> figli (- (validazione-budget-nodi stato) (validazione-nodi stato)))
      (rifiuta :node-budget stato))
    (when (zerop figli)
      (completa-nodo stato inizio)
      (return-from apri-contenitore nil))
    (let ((frame (aref (validazione-pila stato) (validazione-cima stato))))
      (declare (type contenitore frame))
      (setf (contenitore-tipo frame) tipo (contenitore-residui frame) figli
            (contenitore-inizio frame) inizio
            (contenitore-chiave-inizio frame) -1
            (contenitore-chiave-fine frame) 0)
      (incf (validazione-cima stato))))
  nil)

(defun consuma-nodo (stato)
  "Ogni passo consuma un nodo; i tag consumano nodi e nessuna profondita."
  (declare (type validazione stato))
  (when (>= (validazione-nodi stato) (validazione-budget-nodi stato))
    (rifiuta :node-budget stato))
  (incf (validazione-nodi stato))
  (multiple-value-bind (tipo argomento inizio) (leggi-testata stato)
    (case tipo
      ((0 1 7) (completa-nodo stato inizio))
      ((2 3)
       (esigi-byte stato argomento)
       (let ((fine (+ (validazione-posizione stato) argomento)))
         (if (= tipo 3) (controlla-utf8 stato fine)
             (setf (validazione-posizione stato) fine)))
       (completa-nodo stato inizio))
      ((4 5) (apri-contenitore stato tipo argomento inizio))
      (6 (incf (validazione-tag-letti stato)) (rifiuta :unsupported stato))
      (otherwise (rifiuta :internal-invariant stato))))
  nil)

(defun limiti (limite-documento limite-profondita budget-nodi budget-byte)
  "Plist del contratto effettivamente applicato, senza inferire limiti del motore."
  (list :document-bytes limite-documento :container-depth limite-profondita
        :nodes budget-nodi :input-bytes budget-byte
        :stack-frames limite-profondita))

(declaim (ftype (function (t &key (:limite-documento t) (:limite-profondita t)
                                  (:budget-nodi t) (:budget-byte t)) list)
                valida-documento))
(defun valida-documento (buffer &key (limite-documento +documento-max+)
                                    (limite-profondita +contenitori-max+)
                                    (budget-nodi +documento-max+)
                                    (budget-byte +documento-max+))
  "Valida un solo item, safety 3, input immutabile. Segnala errore-cbor.
Sottoinsieme deterministico parziale: tag e floating point non supportati."
  (controlla-parametri buffer limite-documento limite-profondita budget-nodi budget-byte)
  (let ((pila (make-array limite-profondita :element-type t)))
    (dotimes (i limite-profondita) (setf (aref pila i) (make-contenitore)))
    (let ((stato (crea-validazione :buffer buffer :lunghezza (length buffer)
                                  :budget-nodi budget-nodi :pila pila
                                  :limite-profondita limite-profondita)))
      ;; Ogni item occupa almeno un byte; il tetto include il rifiuto finale.
      (loop repeat (1+ (min budget-nodi (length buffer))) do
        (consuma-nodo stato)
        (when (validazione-conclusa stato)
          (unless (= (validazione-posizione stato) (length buffer))
            (rifiuta :trailing-data stato))
          (return-from valida-documento
            (list :status :ok :bytes (length buffer)
                  :nodes (validazione-nodi stato)
                  :depth (validazione-profondita stato) :tags 0
                  :scope :partial :profile :rfc8949-core-deterministic
                  :limits (limiti limite-documento limite-profondita
                                  budget-nodi budget-byte)))))
      (rifiuta :internal-invariant stato))))

;;; Fixture: non sono encoder/decoder di prodotto e non dipendono da altri moduli.
;;; REQ: REQ-LIM-002
;;; REQ: REQ-AFF-008
;;; REQ: REQ-SIM-002

(defun ottetti-fixture (lista)
  "Converte esclusivamente sequenze fidate delle fixture in ottetti specializzati."
  (coerce lista '(simple-array (unsigned-byte 8) (*))))

(defun fixture-profondita (quanti &optional (dove :array))
  "Costruisce solo catene note: quanti contenitori, con ultimo array vuoto."
  (declare (type (integer 1 101) quanti))
  (when (and (= quanti 1) (member dove '(:chiave :valore)))
    (return-from fixture-profondita (ottetti-fixture '(#xa0))))
  (case dove
    (:array (let ((buffer (make-array quanti :element-type '(unsigned-byte 8)
                                     :initial-element #x81)))
              (setf (aref buffer (1- quanti)) #x80) buffer))
    ((:chiave :valore)
     (let ((buffer (make-array (1+ quanti) :element-type '(unsigned-byte 8)
                              :initial-element #x81)))
       (setf (aref buffer 0) #xa1)
       (if (eq dove :chiave)
           (setf (aref buffer (1- quanti)) #x80 (aref buffer quanti) #xf6)
           (setf (aref buffer 1) 0 (aref buffer quanti) #x80))
       buffer))
    (otherwise (error 'errore-fixture :dettaglio :modalita-sconosciuta))))

(defun fixture-profondita-mappe (quanti chiavi-p)
  "Catena nota di mappe: ogni contenitore interno e una chiave o un valore."
  (declare (type (integer 1 101) quanti) (type boolean chiavi-p))
  (let ((buffer (make-array (1- (* 2 quanti)) :element-type '(unsigned-byte 8)
                            :initial-element #xf6)))
    (if chiavi-p
        (progn
          (dotimes (i (1- quanti)) (setf (aref buffer i) #xa1))
          (setf (aref buffer (1- quanti)) #xa0))
        (progn
          (dotimes (i (1- quanti))
            (setf (aref buffer (* 2 i)) #xa1 (aref buffer (1+ (* 2 i))) 0))
          (setf (aref buffer (1- (length buffer))) #xa0)))
    buffer))

(defun fixture-stringa (dimensione &optional (tipo 2))
  "Buffer di dimensione totale nota, indipendente dal parser, ASCII o binario."
  (declare (type (integer 1024 16777217) dimensione)
           (type (integer 2 3) tipo))
  (let* ((testata (if (<= dimensione 65538) 3 5))
         (payload (- dimensione testata))
         (buffer (make-array dimensione :element-type '(unsigned-byte 8)
                             :initial-element #x61)))
    (setf (aref buffer 0) (logior (ash tipo 5) (if (= testata 3) 25 26)))
    (loop for i from 1 below testata do
      (setf (aref buffer i) (ldb (byte 8 (* 8 (- testata i 1))) payload)))
    buffer))

(defun esigi (predicato testo)
  "Asserzione di fixture sempre attiva; nessun errore del parser viene nascosto."
  (unless predicato (error 'errore-fixture :dettaglio testo))
  t)

(defun verifica-attesa (nome buffer atteso &key nodes depth offset tags opzioni)
  "Oracolo di fixture: controlla la ragione precisa, propagando errori inattesi."
  (handler-case
      (let ((risultato (apply #'valida-documento buffer opzioni)))
        (esigi (eq atteso :ok) nome)
        (esigi (eq (getf risultato :status) :ok) nome)
        (when nodes (esigi (= nodes (getf risultato :nodes)) nome))
        (when depth (esigi (= depth (getf risultato :depth)) nome))
        (esigi (= (length buffer) (getf risultato :bytes)) nome)
        :ok)
    (errore-cbor (condizione)
      (esigi (eq (ragione condizione) atteso) (list nome atteso (ragione condizione)))
      (when nodes (esigi (= nodes (nodi condizione)) nome))
      (when depth (esigi (= depth (profondita condizione)) nome))
      (when offset (esigi (= offset (posizione condizione)) nome))
      (when tags (esigi (= tags (tag-letti condizione)) nome))
      :rejected)))

(defun fixture-valide-req-aff-008 ()
  "Vettori espliciti validi, con numero di nodi e profondita attesi."
  '((:zero (0) :ok 1 0) (:negativo (#x20) :ok 1 0)
               (:u8 (#x18 #x18) :ok 1 0) (:u16 (#x19 1 0) :ok 1 0)
               (:u32 (#x1a 0 1 0 0) :ok 1 0)
               (:u64 (#x1b 0 0 0 1 0 0 0 0) :ok 1 0)
               (:u64-max (#x1b 255 255 255 255 255 255 255 255) :ok 1 0)
               (:negativo-min (#x3b 255 255 255 255 255 255 255 255) :ok 1 0)
               (:bool-null (#x83 #xf4 #xf5 #xf6) :ok 4 1)
               (:binario (#x43 0 255 128) :ok 1 0)
               (:testo-vuoto (#x60) :ok 1 0) (:binario-vuoto (#x40) :ok 1 0)
               (:utf8 (#x6e 0 127 #xc2 #x80 #xe0 #xa0 #x80 #xed #x9f #xbf
                              #xf4 #x8f #xbf #xbf) :ok 1 0)
               (:utf8-4-min (#x64 #xf0 #x90 #x80 #x80) :ok 1 0)
               (:mappa-vuota (#xa0) :ok 1 1) (:array-vuoto (#x80) :ok 1 1)
               (:ordine-core (#xa2 #x18 100 0 #x20 0) :ok 5 1)
               (:chiavi-tipi-distinti (#xa2 #x41 97 0 #x61 97 0) :ok 5 1)
               (:chiave-array (#xa2 #x80 0 #x81 0 0) :ok 6 2)
               (:chiave-mappa (#xa2 #xa0 0 #xa1 0 1 0) :ok 7 2)
               (:fratelli (#x83 #x81 #x80 #xa1 0 #x80 #x80) :ok 7 3)))

(defun fixture-rifiutate-req-aff-008 ()
  "Vettori espliciti invalidi o fuori ambito, con ragione precisa attesa."
  '((:ordine-length-first (#xa2 #x20 0 #x18 100 0) :key-order)
               (:duplicato (#xa2 0 1 0 2) :duplicate-key)
               (:duplicato-array (#xa2 #x81 0 #xf6 #x81 0 #xf6) :duplicate-key)
               (:duplicato-mappa (#xa2 #xa1 0 1 #xf6 #xa1 0 1 #xf6) :duplicate-key)
               (:chiave-invalida (#xa1 #x61 #x80 0) :utf8)
               (:chiave-nonminima (#xa1 #x81 #x18 0 0) :nonminimal)
               (:nullo-extra (#xf6 0) :trailing-data)
               (:vuoto () :truncated) (:payload-troncato (#x42 0) :truncated)
               (:array-troncato (#x82 0) :truncated)
               (:mappa-troncata (#xa1 0) :truncated)
               (:testata-troncata (#x19 1) :truncated)
               (:array-enorme (#x9b 255 255 255 255 255 255 255 255 0) :truncated)
               (:mappa-enorme (#xbb 255 255 255 255 255 255 255 255 0) :truncated)
               (:stringa-enorme (#x5b 255 255 255 255 255 255 255 255) :truncated)
               (:intero-nonminimo (#x18 0) :nonminimal)
               (:negativo-nonminimo (#x38 0) :nonminimal)
               (:u16-nonminimo (#x19 0 255) :nonminimal)
               (:u32-nonminimo (#x1a 0 0 255 255) :nonminimal)
               (:u64-nonminimo (#x1b 0 0 0 0 255 255 255 255) :nonminimal)
               (:lunghezza-nonminima (#x58 0) :nonminimal)
               (:array-nonminimo (#x98 0) :nonminimal)
               (:mappa-nonminima (#xb8 0) :nonminimal)
               (:tag-nonminimo (#xd8 0 #xf6) :nonminimal)
               (:utf8-continuazione (#x61 #x80) :utf8)
               (:utf8-overlong-2 (#x62 #xc0 #x80) :utf8)
               (:utf8-overlong-3 (#x63 #xe0 #x9f #xbf) :utf8)
               (:utf8-overlong-4 (#x64 #xf0 #x8f #xbf #xbf) :utf8)
               (:utf8-surrogate (#x63 #xed #xa0 #x80) :utf8)
               (:utf8-oltre (#x64 #xf4 #x90 #x80 #x80) :utf8)
               (:utf8-lead (#x64 #xf5 #x80 #x80 #x80) :utf8)
               (:utf8-suite (#x62 #xc2 0) :utf8)
               (:utf8-incompleto (#x61 #xc2) :utf8)
               (:indefinito-array (#x9f #xff) :indefinite)
               (:indefinito-mappa (#xbf #xff) :indefinite)
               (:indefinito-binario (#x5f #xff) :indefinite)
               (:indefinito-testo (#x7f #xff) :indefinite)
               (:break (#xff) :indefinite) (:riservato (#x1c) :reserved)
               (:tag (#xc0 #xf6) :unsupported 1 0)
               (:float16 (#xf9 0 0) :unsupported)
               (:float32 (#xfa 0 0 0 0) :unsupported)
               (:float64 (#xfb 0 0 0 0 0 0 0 0) :unsupported)
               (:float-troncato (#xf9 0) :truncated)
               (:undefined (#xf7) :unsupported)
               (:simple (#xf8 32) :unsupported)
               (:simple-malformato (#xf8 20) :malformed-simple)))

(defun check-req-aff-008-fixture ()
  "Vettori espliciti: aspettative dichiarate senza usare un secondo parser."
  (let ((validi 0) (rifiutati 0))
    (dolist (caso (append (fixture-valide-req-aff-008) (fixture-rifiutate-req-aff-008)))
      (destructuring-bind (nome bytes atteso &optional nodes depth) caso
        (if (eq :ok (verifica-attesa (list :req-aff-008 nome)
                                     (ottetti-fixture bytes) atteso
                                     :nodes nodes :depth depth))
            (incf validi) (incf rifiutati))))
    (list :valid validi :rejected rifiutati)))

(defun check-req-lim-002-profondita ()
  "100/101 livelli, chiavi e valori anche tutti mappe; tag senza livelli aggiunti."
  (let ((casi 0))
    (dolist (dove '(:array :chiave :valore))
      (verifica-attesa (list :req-lim-002 dove 100) (fixture-profondita 100 dove) :ok
                       :depth 100 :nodes (if (eq dove :array) 100 101))
      (verifica-attesa (list :req-lim-002 dove 101) (fixture-profondita 101 dove)
                       :depth-limit :depth 100)
      (incf casi 2))
    (dolist (chiavi-p '(t nil))
      (verifica-attesa (list :req-lim-002 :mappe chiavi-p 100)
                       (fixture-profondita-mappe 100 chiavi-p) :ok :depth 100 :nodes 199)
      (verifica-attesa (list :req-lim-002 :mappe chiavi-p 101)
                       (fixture-profondita-mappe 101 chiavi-p) :depth-limit :depth 100)
      (incf casi 2))
    (let ((buffer (fixture-profondita 100)))
      (setf (aref buffer 99) #xc0)
      (verifica-attesa :req-lim-002-tag-livello-99 buffer :unsupported
                       :nodes 100 :depth 99 :tags 1)
      ;; Un tag completo dentro 100 array: nodo 101, profondita ancora 100.
      (let ((tag (make-array 102 :element-type '(unsigned-byte 8)
                            :initial-element #x81)))
        (setf (aref tag 100) #xc0 (aref tag 101) #xf6)
        (verifica-attesa :req-lim-002-tag-livello-100 tag :unsupported
                         :nodes 101 :depth 100 :tags 1)))
    (+ casi 2)))

(defun check-req-aff-008-budget ()
  "Limiti ridotti, saturazione, zero, negativi e tipi di configurazione errati."
  (let ((buffer (ottetti-fixture '(#x82 0 1))) (casi 0))
    (dolist (caso '((:ok (:budget-nodi 3 :budget-byte 3 :limite-documento 3))
                   (:node-budget (:budget-nodi 2))
                   (:node-budget (:budget-nodi 0))
                   (:invalid-budget (:budget-nodi -1))
                   (:invalid-budget (:budget-byte -1))
                   (:byte-budget (:budget-byte 0))
                   (:byte-budget (:budget-byte 2))
                   (:document-limit (:limite-documento 2))
                   (:depth-limit (:limite-profondita 0))
                   (:invalid-limit (:limite-profondita 101))
                   (:invalid-limit (:limite-profondita -1))
                   (:invalid-limit (:limite-documento 0))
                   (:invalid-limit (:limite-documento 16777217))
                   (:invalid-budget (:budget-nodi 16777217))
                   (:invalid-budget (:budget-byte 16777217))
                   (:invalid-budget (:budget-nodi 1.0))))
      (verifica-attesa :req-aff-008-budget buffer (first caso) :opzioni (second caso))
      (incf casi))
    (verifica-attesa :req-aff-008-buffer #(0) :invalid-buffer)
    (verifica-attesa :req-aff-008-scalare (ottetti-fixture '(0)) :ok
                     :depth 0 :nodes 1 :opzioni '(:limite-profondita 0 :budget-nodi 1))
    (verifica-attesa :req-aff-008-esaurimento (ottetti-fixture '(#x81 #x81 0))
                     :node-budget :opzioni '(:budget-nodi 2))
    (+ casi 3)))

(defun check-req-lim-002-dimensione ()
  "Esattamente 16 MiB codificati, poi 16 MiB + 1 rifiutati a offset/nodi zero."
  (let ((esatto (fixture-stringa +documento-max+))
        (oltre (fixture-stringa (1+ +documento-max+))))
    (verifica-attesa :req-lim-002-documento-esatto esatto :ok :nodes 1 :depth 0)
    (verifica-attesa :req-lim-002-documento-oltre oltre :document-limit
                     :nodes 0 :depth 0 :offset 0)
    (verifica-attesa :req-aff-008-byte-prima-del-parser esatto :byte-budget
                     :nodes 0 :offset 0 :opzioni '(:budget-byte 16777215))
    (list :cases 3 :encoded-bytes +documento-max+ :payload-bytes (- +documento-max+ 5)
          :oversize-bytes (1+ +documento-max+) :live-fixture-bytes (+ 1 (* 2 +documento-max+)))))

(defun check-req-aff-008-mutazioni ()
  "512 trasformazioni con esito indipendente noto, quattro semi e otto famiglie."
  (let ((validi 0) (rifiutati 0) (semi '(1 48 8949 20261008)))
    (dolist (iniziale semi)
      (let ((seme iniziale))
        (dotimes (i 128)
          (setf seme (logand #xffffffff (+ (* seme 1664525) 1013904223)))
          (let* ((buffer (ottetti-fixture '(#x83 0 #x62 97 98 #xf6)))
                 (k (mod seme 24))
                 (atteso (case (mod i 8)
                           (0 (setf (aref buffer 1) k) :ok)
                           (1 (setf (aref buffer 3) (mod seme 128)) :ok)
                           (2 (setf (aref buffer 3) #x80) :utf8)
                           (3 (setf (aref buffer 1) #x18 (aref buffer 2) k) :nonminimal)
                           (4 (setf (aref buffer 0) #x9f) :indefinite)
                           (5 (setf buffer (concatenate 'ottetti buffer (ottetti-fixture '(0))))
                              :trailing-data)
                           (6 (setf buffer (subseq buffer 0 5)) :truncated)
                           (7 (setf buffer (ottetti-fixture (list #xa2 k #xf6 k #xf6)))
                              :duplicate-key)
                           (otherwise (error 'errore-fixture :dettaglio :famiglia-inattesa)))))
            (if (eq :ok (verifica-attesa (list :req-aff-008 iniziale i) buffer atteso))
                (incf validi) (incf rifiutati))))))
    (list :seeds semi :cases (+ validi rifiutati) :valid validi :rejected rifiutati
          :oracle :known-transformations)))

(defun check ()
  "Controlli locali bounded: nessun benchmark, nessuna affermazione sul gate v2."
  (let* ((inizio (get-internal-real-time))
         (fixture (check-req-aff-008-fixture))
         (profondita (check-req-lim-002-profondita))
         (budget (check-req-aff-008-budget))
         (dimensione (check-req-lim-002-dimensione))
         (mutazioni (check-req-aff-008-mutazioni)))
    (list :spike :spk-10 :module :cbor :status :ok :scope :partial :safety 3
          :cases (+ (getf fixture :valid) (getf fixture :rejected) profondita budget
                    (getf dimensione :cases) (getf mutazioni :cases))
          :fixtures fixture :depth-cases profondita :budget-cases budget
          :size dimensione :mutations mutazioni
          :limits (limiti +documento-max+ +contenitori-max+ +documento-max+ +documento-max+)
          :unsupported '(:tags :floating-point :other-simple-values)
          :elapsed-seconds (/ (- (get-internal-real-time) inizio)
                              (coerce internal-time-units-per-second 'double-float)))))

;;; Misure opzionali: il parent le esegue in serie con gli altri moduli.
;;; REQ: REQ-LIM-002
;;; REQ: REQ-AFF-008
;;; REQ: REQ-SIM-002

(defun misura-caso (nome buffer attesi-nodi attesa-profondita tick-budget)
  "Finestra limitata anche a 100000 chiamate; massimo un parsing oltre la scadenza."
  (let ((inizio (get-internal-real-time)) (allocati (sb-ext:get-bytes-consed))
        (operazioni 0) (sink 0))
    (loop repeat 100000
          while (< (- (get-internal-real-time) inizio) tick-budget) do
      (let ((risultato (valida-documento buffer)))
        (esigi (and (eq (getf risultato :status) :ok)
                    (= (getf risultato :nodes) attesi-nodi)
                    (= (getf risultato :depth) attesa-profondita)) nome)
        (incf sink (getf risultato :bytes)) (incf operazioni)))
    (let ((secondi (/ (- (get-internal-real-time) inizio)
                      (coerce internal-time-units-per-second 'double-float))))
      (list :case nome :encoded-bytes (length buffer) :nodes attesi-nodi
            :depth attesa-profondita :operations operazioni :seconds secondi
            :allocated-bytes (- (sb-ext:get-bytes-consed) allocati) :sink sink
            :encoded-mib-per-second (if (plusp secondi) (/ sink 1048576d0 secondi) 0d0)))))

(defun benchmark (&key (seconds 2.5d0))
  "Misura la validazione, budget totale obiettivo <= 3s; check separato."
  (unless (and (realp seconds) (<= 0 seconds 3)) (rifiuta :invalid-benchmark-budget))
  (let* ((inizio (get-internal-real-time))
         (casi (list (list :binary-1k (fixture-stringa 1024) 1 0)
                     (list :text-1k (fixture-stringa 1024 3) 1 0)
                     (list :binary-16m (fixture-stringa +documento-max+) 1 0)
                     (list :text-64k (fixture-stringa 65536 3) 1 0)
                     (list :depth-100 (fixture-profondita 100) 100 100)
                     (list :nodes-4096
                           (concatenate 'ottetti (ottetti-fixture '(#x99 #x10 0))
                                        (make-array 4096 :element-type '(unsigned-byte 8)
                                                    :initial-element 0))
                           4097 1)))
         (tick (max 0 (floor (/ (* seconds internal-time-units-per-second)
                               (length casi)))))
         (risultati '()))
    (dolist (caso casi) (push (apply #'misura-caso (append caso (list tick))) risultati))
    (list :spike :spk-10 :module :cbor :status :ok :scope :partial :safety 3
          :parameters (list :seconds seconds :max-operations-per-case 100000
                            :cases (length casi) :timing :get-internal-real-time
                            :throughput-basis :encoded-document-size
                            :binary-payload :skipped-after-length-check)
          :environment (list :lisp (lisp-implementation-type)
                             :version (lisp-implementation-version)
                             :machine (machine-type) :software (software-type)
                             :software-version (software-version))
          :results (nreverse risultati)
          :elapsed-seconds (/ (- (get-internal-real-time) inizio)
                              (coerce internal-time-units-per-second 'double-float)))))
