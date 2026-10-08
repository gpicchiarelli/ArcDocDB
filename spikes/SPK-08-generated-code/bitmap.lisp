;;;; SPK-08: kernel scalari bitmap equivalenti, senza dipendenze dal motore.
;;; REQ: REQ-SIM-001 REQ-BEN-001 REQ-BEN-002
(defpackage #:arcdocdb.spk08.bitmap
  (:use #:cl)
  (:export #:check #:prepara-bitmap #:bitmap-byte #:bitmap-word))
(in-package #:arcdocdb.spk08.bitmap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype words () '(simple-array (unsigned-byte 64) (*)))
(deftype indice () '(and fixnum (integer 0 *)))
(defconstant +massimo-byte+ 65536)

;;; REQ: REQ-SIM-001
(define-condition argomento-invalido (error)
  ((motivo :initarg :motivo :reader motivo-argomento))
  (:report (lambda (condizione flusso)
             (format flusso "SPK-08: argomento del kernel bitmap invalido: ~S."
                     (motivo-argomento condizione)))))

;;; REQ: REQ-SIM-001
(declaim (ftype (function (keyword) nil) rifiuta))
(defun rifiuta (motivo)
  "Segnala un dominio invalido prima di accedere agli elementi degli array."
  (error 'argomento-invalido :motivo motivo))

;;; REQ: REQ-SIM-001
(declaim (ftype (function (t t) (values indice &optional)) valida-byte))
(defun valida-byte (a b)
  "Pre: argomenti generici. Post: due octet array semplici della stessa lunghezza,
multipla di otto e non oltre 64 KiB; nessun elemento letto o modificato."
  (unless (and (typep a 'octets) (typep b 'octets)) (rifiuta :bitmap-byte-dominio))
  (let ((n (length a)))
    (unless (and (= n (length b)) (<= n +massimo-byte+) (zerop (mod n 8)))
      (rifiuta :bitmap-byte-lunghezza))
    n))

;;; REQ: REQ-SIM-001
(declaim (ftype (function (t t) (values indice &optional)) valida-word))
(defun valida-word (a b)
  "Pre: argomenti generici. Post: due u64 array semplici della stessa lunghezza,
al massimo 8.192 parole; nessun accesso agli elementi prima della validazione."
  (unless (and (typep a 'words) (typep b 'words)) (rifiuta :bitmap-word-dominio))
  (let ((n (length a)))
    (unless (and (= n (length b)) (<= n (/ +massimo-byte+ 8)))
      (rifiuta :bitmap-word-lunghezza))
    n))

;;; REQ: REQ-SIM-001 REQ-BEN-001
(declaim (ftype (function (t t) (values indice &optional)) bitmap-byte))
(defun bitmap-byte (a b)
  "Pre: bitmap equivalenti per dominio e lunghezza. Post: numero dei bit comuni,
senza modificare gli input; kernel scalare octet LOGAND/LOGCOUNT, safety 3."
  (let ((n (valida-byte a b)) (aa (the octets a)) (bb (the octets b)) (totale 0))
    (declare (type indice n totale) (type octets aa bb))
    (dotimes (i n)
      (incf totale (logcount (logand (aref aa i) (aref bb i)))))
    totale))

;;; REQ: REQ-SIM-001 REQ-BEN-001
(declaim (ftype (function (t t) (values indice &optional)) bitmap-word))
(defun bitmap-word (a b)
  "Pre: u64 bitmap di uguale lunghezza entro il budget. Post: numero dei bit comuni,
input immutati; kernel scalare u64 LOGAND/LOGCOUNT, safety 3."
  (let ((n (valida-word a b)) (aa (the words a)) (bb (the words b)) (totale 0))
    (declare (type indice n totale) (type words aa bb))
    (dotimes (i n)
      (incf totale (logcount (logand (aref aa i) (aref bb i)))))
    totale))

;;; REQ: REQ-SIM-001 REQ-BEN-002
(declaim (ftype (function (octets) (values words &optional)) impacchetta-bitmap))
(defun impacchetta-bitmap (byte)
  "Pre: bitmap octet entro il budget. Post: parole little-endian equivalenti,
costruite fuori dalle misure; non dipende dall'endianness nativa."
  (let* ((n (valida-byte byte byte))
         (word (make-array (/ n 8) :element-type '(unsigned-byte 64) :initial-element 0)))
    (dotimes (i (/ n 8))
      (let ((valore 0))
        (dotimes (b 8)
          (setf valore (logior valore (ash (aref byte (+ (* i 8) b)) (* 8 b)))))
        (setf (aref word i) valore)))
    word))

;;; REQ: REQ-SIM-001 REQ-BEN-002
(declaim (ftype (function (octets octets) (values indice &optional)) oracolo-bitmap))
(defun oracolo-bitmap (a b)
  "Oracolo indipendente: un test per singolo bit, senza LOGAND né LOGCOUNT."
  (let ((n (valida-byte a b)) (totale 0))
    (dotimes (i n)
      (dotimes (bit 8)
        (when (and (logbitp bit (aref a i)) (logbitp bit (aref b i))) (incf totale))))
    totale))

;;; REQ: REQ-SIM-001 REQ-BEN-002
(declaim (ftype (function (t &key (:pattern t)) (values octets octets words words indice &optional))
                prepara-bitmap))
(defun prepara-bitmap (bytes &key (pattern :mixed))
  "Pre: lunghezza multipla di otto da zero a 65.536, pattern MIXED/ZERO/ONES.
Post: due bitmap deterministiche, rappresentazioni u64 little-endian equivalenti
e conteggio dell'oracolo bit-per-bit. La costruzione appartiene alla preparazione."
  (unless (and (typep bytes 'indice) (<= bytes +massimo-byte+) (zerop (mod bytes 8)))
    (rifiuta :prepara-bitmap-lunghezza))
  (unless (member pattern '(:mixed :zero :ones)) (rifiuta :prepara-bitmap-pattern))
  (let ((a (make-array bytes :element-type '(unsigned-byte 8)
                             :initial-element (if (eq pattern :ones) 255 0)))
        (b (make-array bytes :element-type '(unsigned-byte 8)
                             :initial-element (if (eq pattern :ones) 255 0))) (seed 1))
    (when (eq pattern :mixed)
      (dotimes (i bytes)
        (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223))
              (aref a i) (ldb (byte 8 24) seed)
              seed (logand #xffffffff (+ (* seed 1664525) 1013904223))
              (aref b i) (ldb (byte 8 24) seed))))
    (values a b (impacchetta-bitmap a) (impacchetta-bitmap b) (oracolo-bitmap a b))))

;;; REQ: REQ-SIM-001
(declaim (ftype (function (t keyword) null) esigi))
(defun esigi (condizione nome)
  "Fa fallire il check se l'oracolo identificato non è soddisfatto."
  (unless condizione (error "SPK-08 bitmap: check fallito: ~S." nome))
  nil)

;;; REQ: REQ-SIM-001
(declaim (ftype (function (function keyword) null) esigi-rifiuto))
(defun esigi-rifiuto (funzione motivo)
  "Esige il motivo di dominio atteso; propaga ogni altro tipo di condizione."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (argomento-invalido (condizione)
        (esigi (eq motivo (motivo-argomento condizione)) :motivo-rifiuto)
        (setf rilevato t)))
    (esigi rilevato :rifiuto-atteso))
  nil)

;;; REQ: REQ-SIM-001
(declaim (ftype (function (octets octets words words indice) null) check-fixture))
(defun check-fixture (a b wa wb atteso)
  "Confronta i layout byte-per-byte, i kernel e l'oracolo; tutti gli input restano immutati."
  (let ((a-prima (copy-seq a)) (b-prima (copy-seq b))
        (wa-prima (copy-seq wa)) (wb-prima (copy-seq wb)))
    (dotimes (i (length a))
      (let ((parola (floor i 8)) (byte (mod i 8)))
        (esigi (= (aref a i) (ldb (byte 8 (* byte 8)) (aref wa parola))) :layout-a)
        (esigi (= (aref b i) (ldb (byte 8 (* byte 8)) (aref wb parola))) :layout-b)))
    (esigi (= atteso (oracolo-bitmap a b) (bitmap-byte a b) (bitmap-word wa wb)) :bitmap-oracoli)
    (esigi (and (equalp a a-prima) (equalp b b-prima)
                (equalp wa wa-prima) (equalp wb wb-prima)) :bitmap-input-immutati))
  nil)

;;; REQ: REQ-SIM-001
(declaim (ftype (function () (values list &optional)) check))
(defun check ()
  "Prove finite degli scalari: zero, ones, misti, alternati e high bit, dominio e immutabilità.
Nessuna misura di tempo o promessa di SIMD; il runner ispeziona il codice generato."
  (let ((casi 0) (rifiuti 0))
    (dolist (dimensione '(0 8 16 128 8192 65536))
      (dolist (pattern '(:zero :ones :mixed))
        (multiple-value-bind (a b wa wb atteso) (prepara-bitmap dimensione :pattern pattern)
          (check-fixture a b wa wb atteso)
          (when (eq pattern :ones) (esigi (= atteso (* 8 dimensione)) :tutti-bit-a-uno))
          (when (eq pattern :zero) (esigi (zerop atteso) :tutti-bit-a-zero))
          (incf casi))))
    (dolist (pattern '((0 0 0) (255 255 1024) (170 85 0) (170 170 512)
                      (128 128 128) (255 0 0)))
      (destructuring-bind (aa bb atteso) pattern
        (let ((a (make-array 128 :element-type '(unsigned-byte 8) :initial-element aa))
              (b (make-array 128 :element-type '(unsigned-byte 8) :initial-element bb)))
          (check-fixture a b (impacchetta-bitmap a) (impacchetta-bitmap b) atteso)
          (incf casi))))
    (let ((byte (make-array 8 :element-type '(unsigned-byte 8) :initial-element 255))
          (word (make-array 1 :element-type '(unsigned-byte 64) :initial-element #xffffffffffffffff)))
      (let ((byte-prima (copy-seq byte)) (word-prima (copy-seq word)))
        (dolist (invalido (list nil #(1 2) (make-array 8 :element-type '(unsigned-byte 16))
                               (make-array 8 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 8)))
          (esigi-rifiuto (lambda () (bitmap-byte byte invalido)) :bitmap-byte-dominio)
          (esigi-rifiuto (lambda () (bitmap-byte invalido byte)) :bitmap-byte-dominio)
          (esigi-rifiuto (lambda () (bitmap-word word invalido)) :bitmap-word-dominio)
          (esigi-rifiuto (lambda () (bitmap-word invalido word)) :bitmap-word-dominio)
          (incf rifiuti 4))
        (dolist (n '(0 16))
          (esigi-rifiuto (lambda () (bitmap-byte byte (make-array n :element-type '(unsigned-byte 8))))
                         :bitmap-byte-lunghezza)
          (incf rifiuti))
        (dolist (n '(7 65544))
          (let ((invalido (make-array n :element-type '(unsigned-byte 8))))
            (esigi-rifiuto (lambda () (bitmap-byte invalido invalido)) :bitmap-byte-lunghezza)
            (incf rifiuti)))
        (dolist (n '(0 2))
          (esigi-rifiuto (lambda () (bitmap-word word (make-array n :element-type '(unsigned-byte 64))))
                         :bitmap-word-lunghezza)
          (incf rifiuti))
        (let ((invalido (make-array 8193 :element-type '(unsigned-byte 64))))
          (esigi-rifiuto (lambda () (bitmap-word invalido invalido)) :bitmap-word-lunghezza)
          (incf rifiuti))
        (esigi (and (equalp byte byte-prima) (equalp word word-prima)) :rifiuti-input-immutati)))
    (dolist (dimensione '(-1 1 65544 nil))
      (esigi-rifiuto (lambda () (prepara-bitmap dimensione)) :prepara-bitmap-lunghezza)
      (incf rifiuti))
    (dolist (pattern '(:unknown nil 0))
      (esigi-rifiuto (lambda () (prepara-bitmap 8 :pattern pattern)) :prepara-bitmap-pattern)
      (incf rifiuti))
    (list :status :ok :bitmap-fixtures casi :invalid-arguments rifiuti
          :input-immutability :checked :oracle :bitmap-bit-by-bit
          :layouts :little-endian-byte-word-equivalence :kernels '(:scalar-octet :scalar-u64))))
