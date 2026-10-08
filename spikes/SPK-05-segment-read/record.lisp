;;;; SPK-05: record PUT v2 fisso per confrontare pread e mmap.
;;;; Il payload sintetico misura I/O e verifica della cornice; non è un documento CBOR.
;;; REQ: REQ-AFF-002 REQ-FOR-003 REQ-SIM-002
(defpackage #:arcdocdb.spk05.record
  (:use #:cl)
  (:export #:+record-bytes+ #:+value-bytes+ #:scrivi-fixture #:verifica-record #:check
           #:record-rifiutato #:motivo-rifiuto))

(in-package #:arcdocdb.spk05.record)
(declaim (optimize (speed 3) (safety 3) (debug 1)))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype indice () '(and fixnum (integer 0 *)))
(deftype u32 () '(unsigned-byte 32))

(defconstant +record-bytes+ 2048)
(defconstant +header-bytes+ 24)
(defconstant +key-bytes+ 8)
(defconstant +value-bytes+ 2016)
(defconstant +value-offset+ 32)
(defconstant +polinomio+ #x82f63b78)
(defconstant +maschera-crc+ #xffffffff)

;;; REQ: REQ-AFF-002 REQ-SIM-002
(define-condition record-rifiutato (error)
  ((motivo :initarg :motivo :type keyword :reader motivo-rifiuto))
  (:report (lambda (condizione stream)
             (format stream "Fixture SPK-05 rifiutata: ~S."
                     (motivo-rifiuto condizione)))))

;;; REQ: REQ-AFF-002
(declaim (ftype (function (keyword) nil) rifiuta))
(defun rifiuta (motivo)
  "Segnala un errore esplicito; nessun range del valore è pubblicato."
  (error 'record-rifiutato :motivo motivo))

;;; REQ: REQ-FOR-003
(declaim (ftype (function () (simple-array u32 (256))) costruisci-tabella))
(defun costruisci-tabella ()
  "Costruisce 256 voci CRC32C all'avvio, con otto passi per voce."
  (let ((tabella (make-array 256 :element-type 'u32 :initial-element 0)))
    (dotimes (byte 256)
      (let ((crc byte))
        (declare (type u32 crc))
        (dotimes (bit 8)
          (setf crc (logxor (ash crc -1) (if (oddp crc) +polinomio+ 0))))
        (setf (aref tabella byte) crc)))
    tabella))

;;; OWNER: modulo record; costruzione al caricamento e nessuna mutazione successiva.
;;; SHARED: sola lettura; nessun lock o contatore per operazione.
;;; REQ: REQ-FOR-003
(defparameter *tabella-crc* (costruisci-tabella))
(declaim (type (simple-array u32 (256)) *tabella-crc*))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function (sb-sys:system-area-pointer indice indice)
                         (values u32 &optional)) crc32c-sap))
(defun crc32c-sap (sap inizio fine)
  "Pre: [INIZIO,FINE) già validato e memoria stabile. Post: CRC32C finalizzato.
Nessuna copia del body; il proprietario mantiene vivo buffer o mapping."
  (declare (type sb-sys:system-area-pointer sap) (type indice inizio fine))
  (let ((crc +maschera-crc+) (tabella *tabella-crc*))
    (declare (type u32 crc) (type (simple-array u32 (256)) tabella))
    (loop for posizione of-type indice from inizio below fine
          do (setf crc (logxor (ash crc -8)
                              (aref tabella (logand 255
                                                   (logxor crc (sb-sys:sap-ref-8 sap posizione)))))))
    (logxor crc +maschera-crc+)))

;;; REQ: REQ-FOR-003
(declaim (inline leggi-u16-sap leggi-u32-sap))
(declaim (ftype (function (sb-sys:system-area-pointer indice)
                         (values (unsigned-byte 16) &optional)) leggi-u16-sap)
         (ftype (function (sb-sys:system-area-pointer indice)
                         (values u32 &optional)) leggi-u32-sap))
(defun leggi-u16-sap (sap posizione)
  "Pre: due byte disponibili. Post: u16 little-endian senza copia."
  (declare (type sb-sys:system-area-pointer sap) (type indice posizione))
  (logior (sb-sys:sap-ref-8 sap posizione)
          (ash (sb-sys:sap-ref-8 sap (+ posizione 1)) 8)))

;;; REQ: REQ-FOR-003
(defun leggi-u32-sap (sap posizione)
  "Pre: quattro byte disponibili. Post: u32 little-endian senza boxing u64."
  (declare (type sb-sys:system-area-pointer sap) (type indice posizione))
  (logior (sb-sys:sap-ref-8 sap posizione)
          (ash (sb-sys:sap-ref-8 sap (+ posizione 1)) 8)
          (ash (sb-sys:sap-ref-8 sap (+ posizione 2)) 16)
          (ash (sb-sys:sap-ref-8 sap (+ posizione 3)) 24)))

;;; REQ: REQ-SIM-002 REQ-AFF-002
(declaim (ftype (function (integer integer integer) null) controlla-argomenti))
(defun controlla-argomenti (inizio fine numero)
  "Controlla offset, disponibilità e numero prima di ogni accesso SAP.
FINE è esclusiva; il chiamante garantisce che [0,FINE) sia realmente disponibile."
  (unless (<= 0 inizio fine most-positive-fixnum) (rifiuta :intervallo))
  (unless (<= 0 numero +maschera-crc+) (rifiuta :numero))
  (when (< (- fine inizio) +header-bytes+) (rifiuta :header-troncato))
  (when (< (- fine inizio) +record-bytes+) (rifiuta :record-troncato))
  nil)

;;; REQ: REQ-AFF-002 REQ-FOR-003 REQ-SIM-002
(declaim (ftype (function (sb-sys:system-area-pointer integer integer integer)
                         (values indice indice &optional)) verifica-record))
(defun verifica-record (sap inizio fine numero-atteso)
  "Pre: memoria posseduta e stabile in [0,FINE); nessuna dereferenziazione prima
dei controlli degli argomenti. Post: range esclusivo del valore dopo CRC di header
e body, layout fisso PUT/flag zero, chiave e stamp attesi. Non attesta validità
CBOR, commit o appartenenza a un lotto. Segnala RECORD-RIFIUTATO negli altri casi."
  (declare (type sb-sys:system-area-pointer sap) (type integer inizio fine numero-atteso))
  (controlla-argomenti inizio fine numero-atteso)
  (let* ((posizione (the indice inizio)) (numero (the u32 numero-atteso))
         (body (+ posizione +header-bytes+)) (limite (+ posizione +record-bytes+))
         (stamp (1+ numero)))
    (declare (type indice posizione body limite) (type (integer 1 4294967296) stamp))
    ;; Le lunghezze restano non interpretate fino alla verifica dell'header.
    (unless (= (leggi-u32-sap sap posizione) (crc32c-sap sap (+ posizione 4) body))
      (rifiuta :header-crc))
    (unless (and (= 1 (sb-sys:sap-ref-8 sap (+ posizione 8)))
                 (zerop (sb-sys:sap-ref-8 sap (+ posizione 9)))
                 (= +key-bytes+ (leggi-u16-sap sap (+ posizione 10)))
                 (= +value-bytes+ (leggi-u32-sap sap (+ posizione 12))))
      (rifiuta :layout))
    (unless (= (leggi-u32-sap sap (+ posizione 4)) (crc32c-sap sap body limite))
      (rifiuta :body-crc))
    (unless (and (= numero (leggi-u32-sap sap body))
                 (zerop (leggi-u32-sap sap (+ body 4))))
      (rifiuta :chiave))
    (unless (and (= (logand stamp +maschera-crc+) (leggi-u32-sap sap (+ posizione 16)))
                 (= (ash stamp -32) (leggi-u32-sap sap (+ posizione 20))))
      (rifiuta :stamp))
    (values (+ posizione +value-offset+) limite)))

;;; REQ: REQ-SIM-002 REQ-FOR-003
(declaim (ftype (function (octets indice u32) null) scrivi-u32))
(defun scrivi-u32 (buffer posizione valore)
  "Pre: quattro byte disponibili e buffer esclusivo. Post: u32 little-endian scritto."
  (declare (type octets buffer) (type indice posizione) (type u32 valore))
  (dotimes (byte 4) (setf (aref buffer (+ posizione byte)) (ldb (byte 8 (* 8 byte)) valore)))
  nil)

;;; REQ: REQ-SIM-002 REQ-FOR-003
(declaim (ftype (function (octets integer) (values octets &optional)) scrivi-fixture))
(defun scrivi-fixture (buffer numero-record)
  "Pre: buffer esclusivo di esattamente 2048 octet, numero u32. Post: PUT v2 con
chiave u64=numero, stamp=numero+1 e payload affine sintetico; CRC completi.
Valida tutti gli argomenti prima della prima scrittura."
  (declare (type octets buffer) (type integer numero-record))
  (unless (= (length buffer) +record-bytes+) (rifiuta :dimensione-fixture))
  (unless (<= 0 numero-record +maschera-crc+) (rifiuta :numero))
  (let ((numero (the u32 numero-record)))
    (declare (type u32 numero))
    (fill buffer 0)
    (setf (aref buffer 8) 1 (aref buffer 10) +key-bytes+)
    (scrivi-u32 buffer 12 +value-bytes+)
    (scrivi-u32 buffer 16 (logand (1+ numero) +maschera-crc+))
    (scrivi-u32 buffer 20 (ash (1+ numero) -32))
    (scrivi-u32 buffer +header-bytes+ numero)
    (dotimes (byte +value-bytes+)
      (setf (aref buffer (+ +value-offset+ byte))
            (logand 255 (+ #xa5 (* 17 numero) (* 29 byte)))))
    (sb-sys:with-pinned-objects (buffer)
      (let ((sap (sb-sys:vector-sap buffer)))
        (scrivi-u32 buffer 4 (crc32c-sap sap +header-bytes+ +record-bytes+))
        (scrivi-u32 buffer 0 (crc32c-sap sap 4 +header-bytes+)))))
  buffer)

;;; REQ: REQ-FOR-003 REQ-SIM-002
(declaim (ftype (function (octets indice indice) (values u32 &optional)) crc-reference))
(defun crc-reference (buffer inizio fine)
  "Oracolo bitwise per i check, separato dal kernel SAP a tabella."
  (declare (type octets buffer) (type indice inizio fine))
  (unless (<= inizio fine (length buffer)) (rifiuta :intervallo-oracolo))
  (let ((crc +maschera-crc+))
    (declare (type u32 crc))
    (loop for posizione of-type indice from inizio below fine
          do (setf crc (logxor crc (aref buffer posizione)))
             (dotimes (bit 8)
               (setf crc (logxor (ash crc -1) (if (oddp crc) +polinomio+ 0)))))
    (logxor crc +maschera-crc+)))

;;; REQ: REQ-SIM-002
(declaim (ftype (function (boolean keyword) null) esigi))
(defun esigi (condizione nome)
  "Oracolo esplicito: fallisce se la verifica identificata non è soddisfatta."
  (unless condizione (error "Check SPK-05 fallito: ~S." nome))
  nil)

;;; REQ: REQ-AFF-002 REQ-SIM-002
(declaim (ftype (function (sb-sys:system-area-pointer integer integer integer keyword) null)
                esigi-rifiuto))
(defun esigi-rifiuto (sap inizio fine numero motivo)
  "Esige il rifiuto atteso senza occultare altre condizioni."
  (let ((rifiutato nil))
    (handler-case (verifica-record sap inizio fine numero)
      (record-rifiutato (condizione)
        (esigi (eq motivo (motivo-rifiuto condizione)) :req-aff-002-motivo)
        (setf rifiutato t)))
    (esigi rifiutato :req-aff-002-rifiuto))
  nil)

;;; REQ: REQ-SIM-002 REQ-AFF-002 REQ-FOR-003
(declaim (ftype (function () list) check))
(defun check ()
  "Controlli finiti fuori dalle misure: CRC noto, payload indipendente, offset,
numeri estremi, alterazioni con e senza CRC aggiornato e range invalidi."
  (let ((casi 0) (byte-payload 0)
        (buffer (make-array +record-bytes+ :element-type '(unsigned-byte 8) :initial-element 0)))
    ;; Golden CRC32C del messaggio ASCII 123456789, senza usare il generatore.
    (let ((golden (make-array 9 :element-type '(unsigned-byte 8)
                             :initial-contents '(49 50 51 52 53 54 55 56 57))))
      (sb-sys:with-pinned-objects (golden)
        (esigi (= #xe3069283 (crc32c-sap (sb-sys:vector-sap golden) 0 9)) :req-for-003-golden))
      (esigi (= #xe3069283 (crc-reference golden 0 9)) :req-for-003-golden-reference)
      (incf casi 2))
    (dolist (numero '(0 1 255 65535 #xfffffffe #xffffffff))
      (scrivi-fixture buffer numero)
      ;; L'oracolo del payload usa una ricorrenza, non la funzione del generatore.
      (let ((atteso (mod (+ 165 (* 17 numero)) 256)))
        (dotimes (byte +value-bytes+)
          (esigi (= atteso (aref buffer (+ +value-offset+ byte))) :req-sim-002-payload)
          (setf atteso (mod (+ atteso 29) 256))
          (incf byte-payload)))
      (sb-sys:with-pinned-objects (buffer)
        (let ((sap (sb-sys:vector-sap buffer)))
          (esigi (= (crc-reference buffer 4 +header-bytes+) (leggi-u32-sap sap 0))
                 :req-for-003-header-reference)
          (esigi (= (crc-reference buffer +header-bytes+ +record-bytes+) (leggi-u32-sap sap 4))
                 :req-for-003-body-reference)
          (multiple-value-bind (inizio fine) (verifica-record sap 0 +record-bytes+ numero)
            (esigi (and (= inizio +value-offset+) (= fine +record-bytes+)) :req-aff-002-range))))
      (incf casi 4))
    ;; Anche nel mapping INIZIO è un offset del SAP, non una nuova base.
    (let ((segmento (make-array (* 3 +record-bytes+) :element-type '(unsigned-byte 8)
                                :initial-element 0)))
      (dotimes (numero 3)
        (scrivi-fixture buffer numero)
        (replace segmento buffer :start1 (* numero +record-bytes+)))
      (sb-sys:with-pinned-objects (segmento)
        (let ((sap (sb-sys:vector-sap segmento)))
          (dotimes (numero 3)
            (let ((base (* numero +record-bytes+)))
              (multiple-value-bind (inizio fine)
                  (verifica-record sap base (length segmento) numero)
                (esigi (and (= inizio (+ base +value-offset+)) (= fine (+ base +record-bytes+)))
                       :req-aff-002-offset))
              (incf casi))))))
    ;; Le due corruzioni semplici verificano i CRC prima della pubblicazione.
    (dolist (mutation '((12 :header-crc) (1000 :body-crc)))
      (scrivi-fixture buffer 17)
      (setf (aref buffer (first mutation)) (logxor 1 (aref buffer (first mutation))))
      (sb-sys:with-pinned-objects (buffer)
        (esigi-rifiuto (sb-sys:vector-sap buffer) 0 +record-bytes+ 17 (second mutation)))
      (incf casi))
    ;; CRC ricalcolati dall'oracolo: i controlli semantici restano necessari.
    (dolist (mutation '((8 :layout) (9 :layout) (10 :layout) (11 :layout) (12 :layout)
                       (24 :chiave) (28 :chiave) (16 :stamp) (20 :stamp)))
      (scrivi-fixture buffer 17)
      (setf (aref buffer (first mutation)) (logxor 1 (aref buffer (first mutation))))
      (scrivi-u32 buffer 4 (crc-reference buffer +header-bytes+ +record-bytes+))
      (scrivi-u32 buffer 0 (crc-reference buffer 4 +header-bytes+))
      (sb-sys:with-pinned-objects (buffer)
        (esigi-rifiuto (sb-sys:vector-sap buffer) 0 +record-bytes+ 17 (second mutation)))
      (incf casi))
    (scrivi-fixture buffer 17)
    (sb-sys:with-pinned-objects (buffer)
      (esigi-rifiuto (sb-sys:vector-sap buffer) 0 +record-bytes+ 18 :chiave))
    (incf casi)
    ;; SAP nullo: ogni argomento errato è rifiutato prima della prima lettura.
    (dolist (argumenti `((-1 ,+record-bytes+ 0 :intervallo)
                        (1 0 0 :intervallo)
                        (0 ,(1+ most-positive-fixnum) 0 :intervallo)
                        (0 23 0 :header-troncato)
                        (0 2047 0 :record-troncato)
                        (0 ,+record-bytes+ -1 :numero)
                        (0 ,+record-bytes+ ,(1+ +maschera-crc+) :numero)))
      (esigi-rifiuto (sb-sys:int-sap 0) (first argumenti) (second argumenti)
                    (third argumenti) (fourth argumenti))
      (incf casi))
    ;; Le precondizioni di scrittura preservano il buffer in caso di rifiuto.
    (fill buffer 19)
    (let ((rifiutato nil))
      (handler-case (scrivi-fixture buffer -1)
        (record-rifiutato (c) (esigi (eq :numero (motivo-rifiuto c)) :req-sim-002-numero)
                             (setf rifiutato t)))
      (esigi (and rifiutato (every (lambda (byte) (= byte 19)) buffer)) :req-sim-002-fixture-invariata)
      (incf casi))
    (list :status :ok :cases casi :payload-bytes-checked byte-payload
          :record-bytes +record-bytes+ :payload-format :synthetic-affine-not-cbor)))
