(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t) null) prepara-codec))
(defun prepara-codec (descriptor space max-work max-bytes)
  "Pre: confine pubblico. Post: tipi/budget validi e contatore privato azzerato.
INVALID-ARGUMENT per configurazione; RESOURCE-EXHAUSTED per capacita dei termini."
  (unless (and (typep descriptor 'descrittore-full-text) (typep space 'spazio-codec-full-text)
               (typep max-work 'index) (plusp max-work) (typep max-bytes 'index) (plusp max-bytes))
    (error 'invalid-argument :reason :fulltext-codec-input))
  (when (> (descrittore-full-text-term-limit descriptor) (spazio-codec-full-text-term-capacity space))
    (error 'resource-exhausted :reason :fulltext-codec-term-capacity))
  (setf (spazio-codec-full-text-work space) 0 (spazio-codec-full-text-work-limit space) max-work)
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (t t t spazio-codec-full-text descrittore-full-text) null) controlla-buffer-codec))
(defun controlla-buffer-codec (buffer start end space descriptor)
  "Pre: spazio/descrittore validi. Post: span simple u8, nessun alias con buffer interni.
INVALID-ARGUMENT prima di qualunque scrittura o prestito."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason :fulltext-codec-span))
  (when (or (eq buffer (descrittore-full-text-meta descriptor))
            (eq buffer (descrittore-full-text-identity descriptor))
            (eq buffer (a::spazio-full-text-bytes (spazio-codec-full-text-analysis space))))
    (error 'invalid-argument :reason :fulltext-codec-alias))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (descrittore-full-text u32 u16) null) controlla-riga-campo))
(defun controlla-riga-campo (descriptor row field)
  "Pre: riga/campo numerici. Post: campo dichiarato e riga PUT committed nel legame.
CORRUPTION-DETECTED per riga non coperta o campo sconosciuto; non risolve CSN."
  (unless (campo-dichiarato-p descriptor field)
    (error 'corruption-detected :reason :fulltext-undeclared-field))
  (unless (and (< row (length (descrittore-full-text-rows descriptor)))
               (= 1 (sbit (descrittore-full-text-rows descriptor) row)))
    (error 'corruption-detected :reason :fulltext-uncommitted-row))
  nil)

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (spazio-codec-full-text index index) null) prepara-copertura))
(defun prepara-copertura (space length-count position-count)
  "Pre: conteggi del file/run. Post: bitmap privata azzerata dopo riserva del lavoro.
RESOURCE-EXHAUSTED prima di accedere oltre scratch; niente allocazioni per entry."
  (when (or (> length-count (length (spazio-codec-full-text-prefix space)))
            (> position-count (length (spazio-codec-full-text-marks space))))
    (error 'resource-exhausted :reason :fulltext-codec-scratch))
  (lavoro-codec space position-count)
  (fill (spazio-codec-full-text-marks space) 0 :end position-count)
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (spazio-codec-full-text index u32 u32) null) marca-posizione))
(defun marca-posizione (space base count position)
  "Pre: base del campo entro la bitmap riservata. Post: una posizione unica marcata.
CORRUPTION-DETECTED per posizione fuori campo o duplicata anche fra termini distinti."
  (lavoro-codec space)
  (unless (< position count) (error 'corruption-detected :reason :fulltext-position-range))
  (let ((i (+ base position)))
    (unless (< i (length (spazio-codec-full-text-marks space)))
      (error 'invariant-violation :reason :fulltext-position-scratch))
    (when (= 1 (sbit (spazio-codec-full-text-marks space) i))
      (error 'corruption-detected :reason :fulltext-position-duplicate))
    (setf (sbit (spazio-codec-full-text-marks space) i) 1))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (spazio-codec-full-text index) null) verifica-copertura))
(defun verifica-copertura (space count)
  "Pre: tutte le posizioni esaminate. Post: unione esatta [0,COUNT), altrimenti corruzione."
  (unless (<= count (length (spazio-codec-full-text-marks space)))
    (error 'invariant-violation :reason :fulltext-coverage-range))
  (dotimes (i count)
    (lavoro-codec space)
    (unless (= 1 (sbit (spazio-codec-full-text-marks space) i))
      (error 'corruption-detected :reason :fulltext-position-gap)))
  nil)
