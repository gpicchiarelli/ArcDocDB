;;;; SPK-10: codec sperimentale v1/v2; il parent carica prima SPK-09.
;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-FOR-003 REQ-FOR-004
;;; REQ: REQ-AFF-002 REQ-AFF-008

(defpackage #:arcdocdb.spk10.codec
  (:use #:cl)
  (:export #:check #:benchmark #:costruisci-record #:verifica-record
           #:costruisci-hint-entry #:verifica-hint-entry
           #:codec-error #:codec-error-reason #:parameter-invalid
           #:limit-exceeded #:record-invalid #:hint-invalid #:check-failed))

(in-package #:arcdocdb.spk10.codec)
(declaim (optimize (speed 2) (safety 3) (debug 1)))

(deftype ottetti () '(simple-array (unsigned-byte 8) (*)))
(defconstant +header-byte+ 24)
(defconstant +hint-byte+ 24)
(defconstant +chiave-v1+ 255)
(defconstant +chiave-v2+ 65535)
(defconstant +documento-byte+ 16777216)
(defconstant +record-v1+ #xffffff)
(defconstant +record-v2+ 16842775)
(defconstant +segmento-byte+ #xffffffff)
(defconstant +header-crc-off+ 0)
(defconstant +body-crc-off+ 4)
(defconstant +tipo-off+ 8)
(defconstant +flag-off+ 9)
(defconstant +chiave-off+ 10)
(defconstant +riservato-v1-off+ 11)
(defconstant +valore-off+ 12)
(defconstant +stamp-off+ 16)
(defconstant +hint-offset-off+ 0)
(defconstant +hint-lunghezza-off+ 4)
(defconstant +hint-csn-off+ 8)
(defconstant +hint-key-off+ 16)
(defconstant +hint-key-len-off+ 20)
(defconstant +hint-tipo-v1-off+ 21)
(defconstant +hint-flag-v1-off+ 22)
(defconstant +hint-riservato-v1-off+ 23)
(defconstant +hint-tipo-v2-off+ 22)
(defconstant +hint-flag-v2-off+ 23)
(defconstant +tipo-put+ 1)
(defconstant +tipo-tombstone+ 2)

(define-condition codec-error (error)
  ((reason :initarg :reason :type keyword :reader codec-error-reason))
  (:report (lambda (condizione stream)
             (format stream "Codec SPK-10: ~S (~A)."
                     (codec-error-reason condizione) (type-of condizione)))))
(define-condition parameter-invalid (codec-error) ())
(define-condition limit-exceeded (codec-error) ())
(define-condition record-invalid (codec-error) ())
(define-condition hint-invalid (codec-error) ())
(define-condition check-failed (codec-error) ())

(declaim (ftype (function (symbol keyword) nil) rifiuta))
(defun rifiuta (classe motivo)
  "Segnala una condizione tipizzata; non restituisce dati non verificati."
  (error classe :reason motivo))

(declaim (ftype (function (t) ottetti) controlla-ottetti))
(defun controlla-ottetti (dati)
  "Richiede un vettore semplice specializzato, prima di accedere ai byte."
  (unless (typep dati 'ottetti) (rifiuta 'parameter-invalid :octets))
  dati)

(declaim (ftype (function (t integer integer keyword) integer) parametro-intero))
(defun parametro-intero (valore minimo massimo motivo)
  "Verifica tipo e intervallo di un parametro; segnala PARAMETER-INVALID."
  (unless (and (integerp valore) (<= minimo valore massimo))
    (rifiuta 'parameter-invalid motivo))
  valore)

(declaim (ftype (function (t) (integer 1 2)) controlla-versione))
(defun controlla-versione (versione)
  "Solo 1 e 2; nessuna inferenza del layout dai byte della cornice."
  (case versione
    ((1 2) versione)
    (otherwise (rifiuta 'parameter-invalid :unknown-version))))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function ((integer 1 2) t t t)
                         (values integer integer integer &optional)) limiti))
(defun limiti (versione massimo-chiave massimo-valore massimo-record)
  "Controlla i cap del chiamante e restituisce quelli effettivi del formato."
  (let ((cap (if (= versione 1) +record-v1+ +record-v2+)))
    (parametro-intero massimo-chiave 1 +chiave-v2+ :key-cap)
    (parametro-intero massimo-valore 0 +documento-byte+ :value-cap)
    (when massimo-record
      (parametro-intero massimo-record +header-byte+ cap :record-cap))
    (values (min massimo-chiave (if (= versione 1) +chiave-v1+ +chiave-v2+))
            massimo-valore (or massimo-record cap))))

(declaim (ftype (function (t) (integer 1 2)) codice-tipo))
(defun codice-tipo (tipo)
  "I soli tipi esercitati sono PUT e TOMBSTONE, senza log di controllo."
  (case tipo
    (:put +tipo-put+)
    (:tombstone +tipo-tombstone+)
    (otherwise (rifiuta 'parameter-invalid :type))))

(declaim (ftype (function (ottetti t t symbol) null) intervallo))
(defun intervallo (buffer inizio fine classe)
  "Verifica l'intervallo prima del primo accesso al buffer."
  (unless (and (integerp inizio) (integerp fine)
               (<= 0 inizio fine (length buffer) 1073741824))
    (rifiuta classe :bounds))
  nil)

(declaim (ftype (function (ottetti integer integer) integer) leggi-intero)
         (ftype (function (ottetti integer integer integer) ottetti) scrivi-intero))
(defun leggi-intero (buffer posizione quanti)
  "Intero little-endian; chiamante ha verificato l'intervallo completo."
  (loop for i below quanti
        sum (ash (aref buffer (+ posizione i)) (* i 8))))

(defun scrivi-intero (buffer posizione valore quanti)
  "Scrive byte little-endian in un buffer privato già dimensionato."
  (dotimes (i quanti buffer)
    (setf (aref buffer (+ posizione i)) (ldb (byte 8 (* i 8)) valore))))

(declaim (ftype (function (ottetti integer integer) (unsigned-byte 32)) crc))
(defun crc (buffer inizio fine)
  "Solo il kernel esportato safety 3 SPK-09; intervallo già controllato."
  (arcdocdb.spk09:crc32c-slicing8-safety3 buffer inizio fine))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (integer integer integer integer integer integer integer)
                         integer) semantica-record))
(defun semantica-record (tipo flag chiave-byte valore-byte cap-chiave cap-valore cap-record)
  "Controlla tutti i limiti PRIMA dell'allocazione del record."
  (unless (zerop (logand flag #xfa)) (rifiuta 'record-invalid :flags))
  (when (logbitp 0 flag) (rifiuta 'record-invalid :prepared-not-supported))
  (unless (<= 1 chiave-byte cap-chiave) (rifiuta 'limit-exceeded :key-length))
  (when (> valore-byte cap-valore) (rifiuta 'limit-exceeded :value-length))
  (case tipo
    (1 (when (zerop valore-byte) (rifiuta 'record-invalid :empty-document)))
    (2 (unless (zerop valore-byte) (rifiuta 'record-invalid :tombstone-value)))
    (otherwise (rifiuta 'record-invalid :type)))
  (let ((totale (+ +header-byte+ chiave-byte valore-byte)))
    (when (> totale cap-record) (rifiuta 'limit-exceeded :record-length))
    totale))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-FOR-003 REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (t t t t &key (:tipo t) (:flag t)
                          (:massimo-chiave t) (:massimo-valore t) (:massimo-record t))
                         ottetti) costruisci-record))
(defun costruisci-record (versione chiave valore csn
                         &key (tipo :put) (flag 0) (massimo-chiave +chiave-v2+)
                           (massimo-valore +documento-byte+) (massimo-record nil))
  "Costruisce un record ordinario dopo i limiti; non valida il CBOR.
Pre: vettori semplici di ottetti. Post: CRC integrali. Condizioni: CODEC-ERROR."
  (let ((v (controlla-versione versione)) (codice (codice-tipo tipo)))
    (controlla-ottetti chiave)
    (controlla-ottetti valore)
    (parametro-intero csn 0 (1- (ash 1 64)) :csn)
    (parametro-intero flag 0 255 :flag)
    (multiple-value-bind (cap-chiave cap-valore cap-record)
        (limiti v massimo-chiave massimo-valore massimo-record)
      (let* ((totale (semantica-record codice flag (length chiave) (length valore)
                                      cap-chiave cap-valore cap-record))
             (buffer (make-array totale :element-type '(unsigned-byte 8)
                                        :initial-element 0)))
        (setf (aref buffer +tipo-off+) codice (aref buffer +flag-off+) flag)
        (scrivi-intero buffer +chiave-off+ (length chiave) (if (= v 1) 1 2))
        (scrivi-intero buffer +valore-off+ (length valore) 4)
        (scrivi-intero buffer +stamp-off+ csn 8)
        (replace buffer chiave :start1 +header-byte+)
        (replace buffer valore :start1 (+ +header-byte+ (length chiave)))
        (scrivi-intero buffer +body-crc-off+ (crc buffer +header-byte+ totale) 4)
        (scrivi-intero buffer +header-crc-off+ (crc buffer +body-crc-off+ +header-byte+) 4)
        buffer))))

;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-AFF-008 REQ-LIM-001 REQ-LIM-003
(declaim (ftype (function (t t t t t t t &key (:tipo t) (:flag-entry t)
                          (:massimo-chiave t) (:massimo-valore t) (:massimo-record t))
                         (values integer integer (unsigned-byte 64) &optional))
                verifica-record))
(defun verifica-record (versione buffer inizio fine chiave csn totale-atteso
                       &key (tipo :put) (flag-entry 0) (massimo-chiave +chiave-v2+)
                         (massimo-valore +documento-byte+) (massimo-record nil))
  "Restituisce offset/fine/CSN solo dopo CRC, chiave e versione verificati.
Pre: intervallo esatto e entry attesa. Nessun prepared restituito. CODEC-ERROR."
  (let ((v (controlla-versione versione)) (codice (codice-tipo tipo)))
    (controlla-ottetti buffer)
    (controlla-ottetti chiave)
    (parametro-intero csn 0 (1- (ash 1 64)) :csn)
    (parametro-intero totale-atteso +header-byte+ +record-v2+ :expected-length)
    (parametro-intero flag-entry 0 1 :entry-flag)
    (intervallo buffer inizio fine 'record-invalid)
    (multiple-value-bind (cap-chiave cap-valore cap-record)
        (limiti v massimo-chiave massimo-valore massimo-record)
      (when (< (- fine inizio) +header-byte+) (rifiuta 'record-invalid :truncated-header))
      (let ((corpo (+ inizio +header-byte+)))
        ;; Nessuna lunghezza esterna viene letta prima di questo confronto.
        (unless (= (leggi-intero buffer (+ inizio +header-crc-off+) 4)
                   (crc buffer (+ inizio +body-crc-off+) corpo))
          (rifiuta 'record-invalid :header-crc))
        (when (and (= v 1) (plusp (aref buffer (+ inizio +riservato-v1-off+))))
          (rifiuta 'record-invalid :reserved))
        (unless (= (aref buffer (+ inizio +tipo-off+)) codice)
          (rifiuta 'record-invalid :type))
        (let* ((key-len (leggi-intero buffer (+ inizio +chiave-off+) (if (= v 1) 1 2)))
               (value-len (leggi-intero buffer (+ inizio +valore-off+) 4))
               (flag (aref buffer (+ inizio +flag-off+)))
               (totale (semantica-record codice flag key-len value-len
                                        cap-chiave cap-valore cap-record)))
          (when (= flag-entry 1) (rifiuta 'record-invalid :prepared-not-supported))
          (unless (= totale totale-atteso) (rifiuta 'record-invalid :entry-length))
          (when (> totale (- fine inizio)) (rifiuta 'record-invalid :truncated-body))
          (unless (= totale (- fine inizio)) (rifiuta 'record-invalid :trailing-bytes))
          (unless (= (leggi-intero buffer (+ inizio +body-crc-off+) 4) (crc buffer corpo fine))
            (rifiuta 'record-invalid :body-crc))
          (unless (and (= key-len (length chiave))
                       (loop for i below key-len
                             always (= (aref buffer (+ corpo i)) (aref chiave i))))
            (rifiuta 'record-invalid :key-mismatch))
          (unless (= (leggi-intero buffer (+ inizio +stamp-off+) 8) csn)
            (rifiuta 'record-invalid :csn-mismatch))
          (values (+ corpo key-len) fine csn))))))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (integer integer integer integer integer integer integer
                          integer integer) null) semantica-hint))
(defun semantica-hint (offset lunghezza key-off key-len tipo flag
                      cap-chiave cap-valore cap-record)
  "Controlla packing, semantica e intervalli u32 di una entry hint."
  (unless (<= 1 key-len cap-chiave) (rifiuta 'limit-exceeded :key-length))
  (unless (<= 0 flag 1) (rifiuta 'hint-invalid :flags))
  (let ((valore-byte (- lunghezza +header-byte+ key-len)))
    (when (> lunghezza cap-record) (rifiuta 'limit-exceeded :record-length))
    (when (> valore-byte cap-valore) (rifiuta 'limit-exceeded :value-length))
    (case tipo
      (1 (unless (plusp valore-byte) (rifiuta 'hint-invalid :record-length)))
      (2 (unless (zerop valore-byte) (rifiuta 'hint-invalid :tombstone-value)))
      (otherwise (rifiuta 'hint-invalid :type))))
  (when (> (+ offset lunghezza) +segmento-byte+) (rifiuta 'hint-invalid :segment-bounds))
  (when (> (+ key-off key-len) +segmento-byte+) (rifiuta 'hint-invalid :key-bounds))
  nil)

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (t t t t t t &key (:tipo t) (:flag t)
                          (:massimo-chiave t) (:massimo-valore t) (:massimo-record t))
                         ottetti) costruisci-hint-entry))
(defun costruisci-hint-entry (versione offset lunghezza csn key-off key-len
                             &key (tipo :put) (flag 0) (massimo-chiave +chiave-v2+)
                               (massimo-valore +documento-byte+) (massimo-record nil))
  "Costruisce 24 byte; l'hint prepared è metadato, mai prova del CSN."
  (let ((v (controlla-versione versione)) (codice (codice-tipo tipo)))
    (parametro-intero offset 0 +segmento-byte+ :offset)
    (parametro-intero lunghezza +header-byte+ +segmento-byte+ :length)
    (parametro-intero csn 0 (1- (ash 1 64)) :csn)
    (parametro-intero key-off 0 +segmento-byte+ :key-off)
    (parametro-intero key-len 0 +segmento-byte+ :key-len)
    (parametro-intero flag 0 255 :flag)
    (multiple-value-bind (cap-chiave cap-valore cap-record)
        (limiti v massimo-chiave massimo-valore massimo-record)
      (semantica-hint offset lunghezza key-off key-len codice flag
                      cap-chiave cap-valore cap-record)
      (let ((buffer (make-array +hint-byte+ :element-type '(unsigned-byte 8)
                                           :initial-element 0)))
        (scrivi-intero buffer +hint-offset-off+ offset 4)
        (scrivi-intero buffer +hint-lunghezza-off+ lunghezza 4)
        (scrivi-intero buffer +hint-csn-off+ csn 8)
        (scrivi-intero buffer +hint-key-off+ key-off 4)
        (scrivi-intero buffer +hint-key-len-off+ key-len (if (= v 1) 1 2))
        (setf (aref buffer (if (= v 1) +hint-tipo-v1-off+ +hint-tipo-v2-off+)) codice
              (aref buffer (if (= v 1) +hint-flag-v1-off+ +hint-flag-v2-off+)) flag)
        buffer))))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (t t t t t t &key (:massimo-chiave t)
                          (:massimo-valore t) (:massimo-record t)) list)
                verifica-hint-entry))
(defun verifica-hint-entry (versione buffer inizio fine lunghezza-chiavi lunghezza-segmento
                           &key (massimo-chiave +chiave-v2+)
                             (massimo-valore +documento-byte+) (massimo-record nil))
  "Verifica una entry e i suoi limiti; CRC delle sezioni a carico del parent.
Post: solo metadati, non documento committed. Segnala CODEC-ERROR."
  (let ((v (controlla-versione versione)))
    (controlla-ottetti buffer)
    (parametro-intero lunghezza-chiavi 0 +segmento-byte+ :keys-size)
    (parametro-intero lunghezza-segmento 0 +segmento-byte+ :segment-size)
    (intervallo buffer inizio fine 'hint-invalid)
    (unless (= (- fine inizio) +hint-byte+) (rifiuta 'hint-invalid :entry-size))
    (when (and (= v 1) (plusp (aref buffer (+ inizio +hint-riservato-v1-off+))))
      (rifiuta 'hint-invalid :reserved))
    (multiple-value-bind (cap-chiave cap-valore cap-record)
        (limiti v massimo-chiave massimo-valore massimo-record)
      (let ((offset (leggi-intero buffer (+ inizio +hint-offset-off+) 4))
            (lunghezza (leggi-intero buffer (+ inizio +hint-lunghezza-off+) 4))
            (csn (leggi-intero buffer (+ inizio +hint-csn-off+) 8))
            (key-off (leggi-intero buffer (+ inizio +hint-key-off+) 4))
            (key-len (leggi-intero buffer (+ inizio +hint-key-len-off+) (if (= v 1) 1 2)))
            (tipo (aref buffer (+ inizio (if (= v 1) +hint-tipo-v1-off+ +hint-tipo-v2-off+))))
            (flag (aref buffer (+ inizio (if (= v 1) +hint-flag-v1-off+ +hint-flag-v2-off+)))))
        (semantica-hint offset lunghezza key-off key-len tipo flag
                        cap-chiave cap-valore cap-record)
        (when (> (+ key-off key-len) lunghezza-chiavi) (rifiuta 'hint-invalid :key-bounds))
        (when (> (+ offset lunghezza) lunghezza-segmento) (rifiuta 'hint-invalid :segment-bounds))
        (list :offset offset :lunghezza lunghezza :csn csn :key-off key-off
              :key-len key-len :tipo (if (= tipo +tipo-put+) :put :tombstone)
              :flag flag :prepared (= flag 1))))))

;;;; Fixture e verifiche locali: nessuna dipendenza dagli altri moduli SPK-10.

(declaim (ftype (function (t keyword) (integer 1 1)) conferma)
         (ftype (function (function symbol keyword) (integer 1 1)) attendi-rifiuto))
(defun conferma (vero motivo)
  "Una verifica riuscita vale un caso; un difetto segnala CHECK-FAILED."
  (unless vero (rifiuta 'check-failed motivo))
  1)

(defun attendi-rifiuto (funzione classe motivo)
  "Controlla classe e motivo della condizione; nessuna cattura generica."
  (handler-case
      (progn (funcall funzione) (rifiuta 'check-failed :missing-rejection))
    (codec-error (condizione)
      (conferma (and (typep condizione classe)
                     (eq (codec-error-reason condizione) motivo)) :wrong-rejection))))

(declaim (ftype (function (integer &optional (unsigned-byte 8)) ottetti) ottetti-fixture)
         (ftype (function (integer) ottetti) documento-fixture)
         (ftype (function (ottetti) ottetti) ricalcola-crc))
(defun ottetti-fixture (quanti &optional (byte 17))
  "Alloca una fixture bounded, con elemento esplicitamente specializzato."
  (make-array quanti :element-type '(unsigned-byte 8) :initial-element byte))

(defun documento-fixture (totale)
  "Bytestring CBOR deterministica: header big-endian 5 byte, payload bounded."
  (parametro-intero totale 65541 (1+ +documento-byte+) :fixture-size)
  (let ((valore (ottetti-fixture totale 0)) (payload (- totale 5)))
    (setf (aref valore 0) #x5a)
    (dotimes (i 4) (setf (aref valore (+ i 1)) (ldb (byte 8 (* (- 3 i) 8)) payload)))
    valore))

(defun ricalcola-crc (buffer)
  "Ricalcola CRC su una fixture alterata, per esercitare la semantica."
  (scrivi-intero buffer +body-crc-off+ (crc buffer +header-byte+ (length buffer)) 4)
  (scrivi-intero buffer +header-crc-off+ (crc buffer +body-crc-off+ +header-byte+) 4))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function (ottetti integer integer) (unsigned-byte 32)) crc-riferimento))
(defun crc-riferimento (buffer inizio fine)
  "Oracolo bit a bit indipendente dalle tabelle SPK-09, limitato a 4096 byte."
  (intervallo buffer inizio fine 'check-failed)
  (when (> (- fine inizio) 4096) (rifiuta 'check-failed :reference-budget))
  (let ((accumulatore #xffffffff))
    (loop for posizione from inizio below fine do
      (setf accumulatore (logxor accumulatore (aref buffer posizione)))
      (dotimes (i 8)
        (setf accumulatore
              (if (oddp accumulatore) (logxor (ash accumulatore -1) #x82f63b78)
                  (ash accumulatore -1)))))
    (logxor accumulatore #xffffffff)))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function () integer) check-req-for-003-crc))
(defun check-req-for-003-crc ()
  "Confronto differenziale deterministico su 8 allineamenti e 15 taglie."
  (let ((buffer (ottetti-fixture 1040 0)) (casi 0)
        (noto (make-array 9 :element-type '(unsigned-byte 8)
                           :initial-contents '(49 50 51 52 53 54 55 56 57))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ (* 73 i) 19) 256)))
    (incf casi (conferma (= (crc noto 0 9) #xe3069283) :known-crc))
    (incf casi (conferma (= (crc-riferimento noto 0 9) #xe3069283) :known-reference))
    (dotimes (inizio 8)
      (dolist (quanti '(0 1 2 3 7 8 9 15 16 17 31 32 255 256 1024))
        (incf casi (conferma (= (crc buffer inizio (+ inizio quanti))
                               (crc-riferimento buffer inizio (+ inizio quanti))) :differential-crc))))
    casi))

;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-LIM-001
(declaim (ftype (function () integer) check-req-for-003-golden))
(defun check-req-for-003-golden ()
  "Golden fissi in posizioni indipendenti: CRC precalcolati bit a bit."
  (let* ((casi 0) (chiave (ottetti-fixture 3)) (valore (ottetti-fixture 2))
         (golden (make-array 29 :element-type '(unsigned-byte 8)
                      :initial-contents '(151 17 18 68 114 157 69 8 1 4 3 0 2 0 0 0
                                           8 7 6 5 4 3 2 1 17 34 51 24 42))))
    (replace chiave #(17 34 51))
    (replace valore #(24 42))
    (dolist (v '(1 2))
      (incf casi (conferma (equalp golden (costruisci-record v chiave valore #x0102030405060708
                                                          :flag 4)) :golden-encoder))
      (multiple-value-bind (inizio fine csn)
          (verifica-record v golden 0 29 chiave #x0102030405060708 29)
        (incf casi (conferma (and (= inizio 27) (= fine 29) (= csn #x0102030405060708))
                            :golden-decoder))))
    (incf casi (conferma (= (leggi-intero golden 0 4) (crc-riferimento golden 4 24)) :golden-header-crc))
    (incf casi (conferma (= (leggi-intero golden 4 4) (crc-riferimento golden 24 29)) :golden-body-crc))
    (let ((lungo (ottetti-fixture 281)) (key (ottetti-fixture 256)))
      (replace lungo #(245 56 11 210 245 240 17 235 1 0 0 1 1 0 0 0 8 7 6 5 4 3 2 1))
      (setf (aref lungo 280) 0)
      (incf casi (conferma (equalp lungo (costruisci-record 2 key (ottetti-fixture 1 0)
                                                         #x0102030405060708)) :golden-key-u16))
      (incf casi (conferma (= (verifica-record 2 lungo 0 281 key #x0102030405060708 281) 280)
                          :golden-long-decoder))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 1 lungo 0 281 key
                                                            #x0102030405060708 281))
                                'record-invalid :reserved)))
    casi))

;;; REQ: REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function () integer) check-req-lim-003-chiavi))
(defun check-req-lim-003-chiavi ()
  "Chiavi ai confini, cap inferiori, TOMBSTONE e u64 massimo."
  (let ((casi 0) (valore (ottetti-fixture 1 0)))
    (dolist (v '(1 2))
      (dolist (taglia '(0 1 255 256 65535 65536))
        (let ((key (ottetti-fixture taglia)))
          (if (<= 1 taglia (if (= v 1) 255 65535))
              (dolist (tipo '(:put :tombstone))
                (let* ((val (if (eq tipo :put) valore (ottetti-fixture 0)))
                       (record (costruisci-record v key val #xffffffffffffffff :tipo tipo)))
                  (multiple-value-bind (a b stamp)
                      (verifica-record v record 0 (length record) key #xffffffffffffffff
                                       (length record) :tipo tipo)
                    (incf casi (conferma (and (= a (+ 24 taglia)) (= b (length record))
                                             (= stamp #xffffffffffffffff)) :key-boundary)))))
              (incf casi (attendi-rifiuto (lambda () (costruisci-record v key valore 7))
                                        'limit-exceeded :key-length)))))
      (let* ((key (ottetti-fixture 256)) (record (costruisci-record 2 key valore 7)))
        (incf casi (attendi-rifiuto (lambda () (costruisci-record v key valore 7 :massimo-chiave 255))
                                  'limit-exceeded :key-length))
        (when (= v 2)
          (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 (length record)
                                                              key 7 (length record) :massimo-chiave 255))
                                    'limit-exceeded :key-length)))))
    casi))

;;; REQ: REQ-LIM-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (ottetti ottetti integer) integer) check-req-lim-001-troncamenti))
(defun check-req-lim-001-troncamenti (record key csn)
  "Confini significativi sulla fixture massima, senza nuove copie del corpo."
  (let ((casi 0) (totale (length record)))
    (dolist (fine (list 0 4 8 9 10 11 12 16 23 24
                       (1- (+ 24 (length key))) (+ 24 (length key))
                       (1+ (+ 24 (length key))) (1- totale)))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 fine key csn totale))
                                'record-invalid (if (< fine 24) :truncated-header :truncated-body))))
    (let ((header (subseq record 0 24)))
      (scrivi-intero header 12 (1+ +documento-byte+) 4)
      (scrivi-intero header 0 (crc header 4 24) 4)
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 header 0 24 key csn totale))
                                'limit-exceeded :value-length)))
    casi))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function () list) check-req-lim-001-documenti))
(defun check-req-lim-001-documenti ()
  "CRC completo del massimo v2, confine totale v1 e rifiuti prima del record."
  (let* ((casi 0) (key (ottetti-fixture 65535))
         (valore (documento-fixture +documento-byte+))
         (record (costruisci-record 2 key valore 17)))
    (incf casi (conferma (= (length record) +record-v2+) :maximum-record-size))
    (incf casi (conferma (equalp (subseq valore 0 5) #(90 0 255 255 251)) :maximum-cbor-fixture))
    (multiple-value-bind (a b csn) (verifica-record 2 record 0 (length record) key 17 (length record))
      (incf casi (conferma (and (= a 65559) (= (- b a) +documento-byte+) (= csn 17)) :maximum-value)))
    (incf casi (check-req-lim-001-troncamenti record key 17))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key valore 17
                                                                          :massimo-valore (1- +documento-byte+)))
                              'limit-exceeded :value-length))
    (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 (length record) key 17
                                                        (length record) :massimo-valore (1- +documento-byte+)))
                              'limit-exceeded :value-length))
    (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 (length record) key 17
                                                        (length record) :massimo-record (1- +record-v2+)))
                              'limit-exceeded :record-length))
    (setf (aref record (1- (length record))) 1)
    (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 (length record) key 17 (length record)))
                              'record-invalid :body-crc))
    (let* ((oltre (documento-fixture (1+ +documento-byte+)))
           (prima (sb-ext:get-bytes-consed)))
      (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key oltre 17)) 'limit-exceeded :value-length))
      (let ((allocazione (- (sb-ext:get-bytes-consed) prima)))
        (incf casi (conferma (< allocazione 1048576) :rejection-allocation-budget))
        (let* ((key-v1 (ottetti-fixture 255))
               (val-v1 (documento-fixture (- +record-v1+ 24 255)))
               (record-v1 (costruisci-record 1 key-v1 val-v1 19)))
          (incf casi (conferma (= (length record-v1) +record-v1+) :maximum-v1-size))
          (incf casi (conferma (= (verifica-record 1 record-v1 0 (length record-v1)
                                                 key-v1 19 (length record-v1)) 279) :maximum-v1-crc))
          (incf casi (attendi-rifiuto (lambda () (costruisci-record 1 key-v1 valore 19))
                                    'limit-exceeded :record-length)))
        (list :cases casi :document-bytes +documento-byte+ :record-bytes +record-v2+
              :v1-record-bytes +record-v1+ :rejection-bytes-consed allocazione)))))

;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function () integer) check-req-for-003-malformati))
(defun check-req-for-003-malformati ()
  "Header corrotto prima delle lunghezze; campi alterati con CRC rigenerato."
  (let* ((casi 0) (key (ottetti-fixture 3)) (valore (ottetti-fixture 2 0))
         (record (costruisci-record 2 key valore 7)))
    (labels ((rifiuto (dati motivo &optional (classe 'record-invalid))
               (incf casi (attendi-rifiuto (lambda () (verifica-record 2 dati 0 (length dati) key 7 29))
                                         classe motivo)))
             (campo (off valore quanti motivo &optional (classe 'record-invalid))
               (let ((dati (copy-seq record)))
                 (scrivi-intero dati off valore quanti)
                 (ricalcola-crc dati)
                 (rifiuto dati motivo classe))))
      (dotimes (off 24)
        (let ((dati (copy-seq record)))
          (setf (aref dati off) (logxor (aref dati off) 128))
          (rifiuto dati :header-crc)))
      (loop for off from 24 below 29 do
        (let ((dati (copy-seq record)))
          (setf (aref dati off) (logxor (aref dati off) 1))
          (rifiuto dati :body-crc)))
      (dolist (flag '(2 3 6 8 16 32 64 128 255)) (campo 9 flag 1 :flags))
      (dolist (flag '(1 5)) (campo 9 flag 1 :prepared-not-supported))
      (campo 8 2 1 :type)
      (campo 8 255 1 :type)
      (campo 10 0 2 :key-length 'limit-exceeded)
      (campo 10 65535 2 :entry-length)
      (campo 12 #xffffffff 4 :value-length 'limit-exceeded)
      (campo 12 0 4 :empty-document)
      (campo 12 1 4 :entry-length)
      (campo 16 8 8 :csn-mismatch)
      (let ((dati (copy-seq record))) (setf (aref dati 24) 18) (rifiuto (ricalcola-crc dati) :key-mismatch))
      (let ((dati (copy-seq record)))
        (scrivi-intero dati 12 #xffffffff 4) (rifiuto dati :header-crc))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 1 (ricalcola-crc
                     (let ((d (copy-seq record))) (setf (aref d 11) 1) d)) 0 29 key 7 29))
                                'record-invalid :reserved)))
    casi))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function () integer) check-req-aff-002-intervalli))
(defun check-req-aff-002-intervalli ()
  "Troncamenti a tutti i confini del record breve e sottointervalli esatti."
  (let* ((casi 0) (key (ottetti-fixture 3)) (record (costruisci-record 2 key (ottetti-fixture 2 0) 7))
         (esteso (ottetti-fixture 41 253)))
    (dotimes (fine 29)
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 fine key 7 29))
                                'record-invalid (if (< fine 24) :truncated-header :truncated-body))))
    (dolist (limiti '((-1 29) (0 30) (10 9) (:invalid 29) (0 29.0d0)))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record (first limiti) (second limiti) key 7 29))
                                'record-invalid :bounds)))
    (replace esteso record :start1 7)
    (multiple-value-bind (a b csn) (verifica-record 2 esteso 7 36 key 7 29)
      (incf casi (conferma (and (= a 34) (= b 36) (= csn 7)) :prefixed-record)))
    (incf casi (attendi-rifiuto (lambda () (verifica-record 2 esteso 7 37 key 7 29))
                              'record-invalid :trailing-bytes))
    (dolist (csn '(6 8))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 29 key csn 29))
                                'record-invalid :csn-mismatch)))
    (dolist (totale '(28 30))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 29 key 7 totale))
                                'record-invalid :entry-length)))
    (dolist (taglia '(2 4))
      (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 29 (ottetti-fixture taglia) 7 29))
                                'record-invalid :key-mismatch)))
    (incf casi (attendi-rifiuto (lambda () (verifica-record 2 record 0 29 key 7 29 :flag-entry 1))
                              'record-invalid :prepared-not-supported))
    casi))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function () integer) check-req-lim-001-hint-golden))
(defun check-req-lim-001-hint-golden ()
  "Posizioni hint v1/v2 fisse, CSN risolto e riservato distinto dal flag."
  (let ((casi 0))
    (dolist (v '(1 2))
      (let* ((golden (make-array 24 :element-type '(unsigned-byte 8)
                       :initial-contents (append '(4 3 2 1 29 0 0 0 8 7 6 5 4 3 2 1 4 3 2 0)
                                                 (if (= v 1) '(3 1 1 0) '(3 0 1 1)))))
             (entry (costruisci-hint-entry v #x01020304 29 #x0102030405060708 #x00020304 3 :flag 1))
             (campi (verifica-hint-entry v golden 0 24 #x00020307 #x01020321)))
        (incf casi (conferma (equalp golden entry) :hint-golden-encoder))
        (incf casi (conferma (and (= (getf campi :offset) #x01020304)
                                 (= (getf campi :lunghezza) 29) (= (getf campi :csn) #x0102030405060708)
                                 (= (getf campi :key-off) #x00020304) (= (getf campi :key-len) 3)
                                 (eq (getf campi :tipo) :put) (= (getf campi :flag) 1)
                                 (getf campi :prepared)) :hint-golden-decoder))
        (when (= v 1)
          (setf (aref entry 23) 1)
          (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry 1 entry 0 24 #x00020307 #x01020321))
                                    'hint-invalid :reserved)))))
    (let* ((entry (costruisci-hint-entry 2 0 281 7 0 256))
           (dati (verifica-hint-entry 2 entry 0 24 256 281)))
      (incf casi (conferma (and (= (aref entry 20) 0) (= (aref entry 21) 1)
                               (= (aref entry 22) 1) (= (aref entry 23) 0)
                               (= (getf dati :key-len) 256)) :hint-key-u16)))
    casi))

;;; REQ: REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function () integer) check-req-lim-003-hint))
(defun check-req-lim-003-hint ()
  "Hint ai confini chiave, sezioni, semantica, cap e troncamenti."
  (let ((casi 0))
    (dolist (v '(1 2))
      (dolist (taglia '(0 1 255 256 65535 65536))
        (if (<= 1 taglia (if (= v 1) 255 65535))
            (dolist (tipo '(:put :tombstone))
              (let* ((totale (+ 24 taglia (if (eq tipo :put) 1 0)))
                     (entry (costruisci-hint-entry v 10 totale 7 20 taglia :tipo tipo))
                     (campi (verifica-hint-entry v entry 0 24 (+ 20 taglia) (+ 10 totale))))
                (incf casi (conferma (and (= (getf campi :key-len) taglia)
                                         (eq (getf campi :tipo) tipo)) :hint-key-boundary))))
            (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry v 0 (+ 25 taglia) 7 0 taglia))
                                      'limit-exceeded :key-length))))
      (let ((entry (costruisci-hint-entry v 10 29 7 20 3)))
        (dotimes (fine 24)
          (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 fine 23 39))
                                    'hint-invalid :entry-size)))
        (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 24 22 39))
                                  'hint-invalid :key-bounds))
        (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 24 23 38))
                                  'hint-invalid :segment-bounds))
        (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 24 23 39 :massimo-chiave 2))
                                  'limit-exceeded :key-length))
        (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 24 23 39 :massimo-valore 1))
                                  'limit-exceeded :value-length))
        (dolist (flag '(2 4 8 255))
          (let ((dati (copy-seq entry)))
            (setf (aref dati (if (= v 1) 22 23)) flag)
            (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v dati 0 24 23 39))
                                      'hint-invalid :flags))))
        (let ((dati (copy-seq entry)))
          (setf (aref dati (if (= v 1) 21 22)) 3)
          (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v dati 0 24 23 39))
                                    'hint-invalid :type)))))
    (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry 2 #xffffffff 26 7 0 1))
                              'hint-invalid :segment-bounds))
    (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry 2 0 26 7 #xffffffff 1))
                              'hint-invalid :key-bounds))
    (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry 2 0 26 7 0 1 :tipo :tombstone))
                              'hint-invalid :tombstone-value))
    casi))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function () integer) check-req-lim-001-hint-limiti))
(defun check-req-lim-001-hint-limiti ()
  "Massimi reali v1/v2, ultimo intervallo u32 e cap inferiori prima del packing."
  (let ((casi 0))
    (dolist (v '(1 2))
      (let* ((taglia (if (= v 1) 255 65535))
             (totale (if (= v 1) +record-v1+ +record-v2+))
             (offset (- +segmento-byte+ totale))
             (key-off (- +segmento-byte+ taglia))
             (entry (costruisci-hint-entry v offset totale #xffffffffffffffff key-off taglia))
             (campi (verifica-hint-entry v entry 0 24 +segmento-byte+ +segmento-byte+)))
        (incf casi (conferma (and (= (getf campi :lunghezza) totale)
                                 (= (getf campi :csn) #xffffffffffffffff)) :maximum-hint))
        (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry v 0 (1+ totale) 7 0 taglia))
                                  'limit-exceeded :record-length)))
      (let* ((entry (costruisci-hint-entry v 0 29 7 0 3))
             (prefisso (ottetti-fixture 32 253)))
        (replace prefisso entry :start1 5)
        (incf casi (conferma (= (getf (verifica-hint-entry v prefisso 5 29 3 29) :lunghezza) 29)
                            :hint-prefixed))
        (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v entry 0 24 3 29 :massimo-record 28))
                                  'limit-exceeded :record-length))
        (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry v 0 29 7 0 3 :massimo-valore 1))
                                  'limit-exceeded :value-length))
        (incf casi (attendi-rifiuto (lambda () (costruisci-hint-entry v 0 29 7 0 3 :massimo-chiave 2))
                                  'limit-exceeded :key-length))
        (let ((dati (copy-seq entry)))
          (scrivi-intero dati 4 26 4)
          (incf casi (attendi-rifiuto (lambda () (verifica-hint-entry v dati 0 24 3 29))
                                    'hint-invalid :record-length)))))
    casi))

;;; REQ: REQ-FOR-004 REQ-LIM-001 REQ-AFF-008
(declaim (ftype (function () integer) check-req-aff-008-parametri))
(defun check-req-aff-008-parametri ()
  "Versioni sconosciute rifiutate da tutte le API; cap e input tipizzati."
  (let* ((casi 0) (key (ottetti-fixture 1)) (val (ottetti-fixture 1 0))
         (record (costruisci-record 2 key val 7)) (hint (costruisci-hint-entry 2 0 26 7 0 1)))
    (dolist (v '(0 3 65535 :unknown 1.0d0 nil))
      (dolist (f (list (lambda () (costruisci-record v key val 7))
                      (lambda () (verifica-record v record 0 26 key 7 26))
                      (lambda () (costruisci-hint-entry v 0 26 7 0 1))
                      (lambda () (verifica-hint-entry v hint 0 24 1 26))))
        (incf casi (attendi-rifiuto f 'parameter-invalid :unknown-version))))
    (dolist (flag '(1 5))
      (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :flag flag))
                                'record-invalid :prepared-not-supported)))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :flag 2)) 'record-invalid :flags))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :massimo-chiave 65536))
                              'parameter-invalid :key-cap))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :massimo-valore 16777217))
                              'parameter-invalid :value-cap))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 1 key val 7 :massimo-record 16842775))
                              'parameter-invalid :record-cap))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :massimo-record 25))
                              'limit-exceeded :record-length))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :massimo-valore 0))
                              'limit-exceeded :value-length))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key (ottetti-fixture 0) 7))
                              'record-invalid :empty-document))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val 7 :tipo :tombstone))
                              'record-invalid :tombstone-value))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 #(1) val 7)) 'parameter-invalid :octets))
    (incf casi (attendi-rifiuto (lambda () (costruisci-record 2 key val -1)) 'parameter-invalid :csn))
    casi))

;;; REQ: REQ-LIM-001 REQ-LIM-003 REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function () list) check))
(defun check ()
  "Verifiche deterministiche bounded; plist OK solo dopo tutti i controlli."
  (let* ((crc-casi (check-req-for-003-crc))
         (golden-casi (check-req-for-003-golden))
         (chiavi-casi (check-req-lim-003-chiavi))
         (documenti (check-req-lim-001-documenti))
         (malformati (check-req-for-003-malformati))
         (intervalli (check-req-aff-002-intervalli))
         (hint-golden (check-req-lim-001-hint-golden))
         (hint-casi (+ (check-req-lim-003-hint) (check-req-lim-001-hint-limiti)))
         (parametri (check-req-aff-008-parametri)))
    (list :status :ok :cases (+ crc-casi golden-casi chiavi-casi (getf documenti :cases)
                               malformati intervalli hint-golden hint-casi parametri)
          :counts (list :crc crc-casi :record-golden golden-casi :keys chiavi-casi
                        :documents (getf documenti :cases) :malformed malformati
                        :intervals intervalli :hint-golden hint-golden :hints hint-casi :parameters parametri)
          :limits (list :versions '(1 2) :key-v1 255 :key-v2 65535 :document-v2 16777216
                        :record-v1 #xffffff :record-v2 16842775 :header 24 :hint 24)
          :maximum-document documenti :prepared-records :prepared-not-supported
          :cbor-validation :separate-module :hint-section-crc :caller-responsibility)))

;;; REQ: REQ-AFF-008
(declaim (ftype (function (&key (:secondi t)) list) benchmark))
(defun benchmark (&key (secondi 0.25d0))
  "Misura locale bounded di un record breve; nessun check implicito.
Durata richiesta >0 e <=3 s; tetto anche di 1000000 iterazioni, nessun gate."
  (unless (and (realp secondi) (< 0 secondi) (<= secondi 3))
    (rifiuta 'parameter-invalid :benchmark-duration))
  (let* ((key (ottetti-fixture 16)) (val (ottetti-fixture 1 0))
         (record (costruisci-record 2 key val 7)) (casi 0) (somma 0)
         (inizio (get-internal-real-time))
         (durata (ceiling (* secondi internal-time-units-per-second))))
    (loop repeat 1000000
          while (< (- (get-internal-real-time) inizio) durata) do
      (incf somma (verifica-record 2 record 0 (length record) key 7 (length record)))
      (incf casi))
    (list :status :ok :iterations casi :requested-seconds secondi :checksum somma
          :elapsed-seconds (/ (- (get-internal-real-time) inizio)
                              (float internal-time-units-per-second 1d0))
          :record-bytes (length record) :iteration-cap 1000000)))
