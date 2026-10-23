;;;; Parser META ristretto: solo array definiti, interi minimi e stringhe UTF-8.
(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index (member 0 4)) (values u32 u32 index &optional)) meta-argomento))
(defun meta-argomento (buffer start end expected)
  "Pre: span META verificato. Post: parole dell'argomento e cursore, forma minima.
CORRUPTION-DETECTED se major o forma non previsti; nessun u64 ricomposto."
  (unless (<= start end (length buffer)) (error 'invariant-violation :reason :fulltext-meta-range))
  (multiple-value-bind (major ai high low next form) (arcdocdb.cbor:leggi-header-cbor-minimo buffer start end)
    (declare (ignore ai))
    (unless (and (= major expected) (eq form :argument))
      (error 'corruption-detected :reason :fulltext-meta-type :offset start))
    (unless (< start next) (error 'invariant-violation :reason :fulltext-meta-progress))
    (values high low next)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index u64) index) meta-intero-esatto))
(defun meta-intero-esatto (buffer start end expected)
  "Pre: argomento atteso autorevole. Post: uguaglianza u64 senza allocare bignum.
CORRUPTION-DETECTED per valore differente o tipo errato."
  (multiple-value-bind (high low next) (meta-argomento buffer start end 0)
    (unless (and (= high (ldb (byte 32 32) expected)) (= low (ldb (byte 32 0) expected)))
      (error 'corruption-detected :reason :fulltext-meta-value :offset start))
    next))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index index index) (values index index &optional)) meta-conteggio))
(defun meta-conteggio (buffer start end minimum maximum)
  "Pre: bounds fixnum. Post: conteggio minimo entro bounds e cursore.
CORRUPTION-DETECTED per intero/array troppo grande prima di usarlo come lunghezza."
  (unless (<= minimum maximum) (error 'invariant-violation :reason :fulltext-meta-count-range))
  (multiple-value-bind (high low next) (meta-argomento buffer start end 4)
    (unless (and (zerop high) (<= minimum low maximum))
      (error 'corruption-detected :reason :fulltext-meta-array :offset start))
    (unless (<= next end) (error 'invariant-violation :reason :fulltext-meta-count-result))
    (values low next)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index index index) (values index index &optional)) meta-testo))
(defun meta-testo (buffer start end minimum maximum)
  "Pre: bounds sui byte del testo. Post: inizio payload e fine, UTF-8 valido.
CORRUPTION-DETECTED per tipo o lunghezza; nessuna stringa Lisp creata."
  (multiple-value-bind (major begin next) (arcdocdb.cbor:leggi-stringa-cbor-minima buffer start end :max-bytes 65536)
    (unless (and (= major 3) (<= minimum (- next begin) maximum))
      (error 'corruption-detected :reason :fulltext-meta-text :offset start))
    (values begin next)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index) (values u32 u32 index &optional)) meta-positivo))
(defun meta-positivo (buffer start end)
  "Pre: META bounded. Post: u64 positivo in due parole e cursore, oppure corruzione."
  (multiple-value-bind (high low next) (meta-argomento buffer start end 0)
    (when (and (zerop high) (zerop low))
      (error 'corruption-detected :reason :fulltext-meta-positive :offset start))
    (values high low next)))
