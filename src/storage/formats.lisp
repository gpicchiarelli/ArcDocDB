;;;; Unica definizione di offset e dimensioni dei metadati trattati da questo modulo.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defconstant +segment-header-bytes+ 64)
(defconstant +segment-magic-low+ #x44435241) ; ARCD, little-endian
(defconstant +segment-magic-high+ #x31474553) ; SEG1 anche per versione 2
(defconstant +segment-magic-high-offset+ 4)
(defconstant +segment-version-offset+ 8)
(defconstant +segment-origin-offset+ 10)
(defconstant +segment-reserved-a-start+ 11)
(defconstant +segment-reserved-a-end+ 16)
(defconstant +serie-id-offset+ 16)
(defconstant +serie-id-bytes+ 16)
(defconstant +segment-id-offset+ 32)
(defconstant +segment-created-offset+ 40)
(defconstant +segment-reserved-b-start+ 48)
(defconstant +segment-crc-offset+ 56)
(defconstant +segment-reserved-c-start+ 60)
(defconstant +segment-max-bytes+ #xffffffff)
(defconstant +writer-origin+ 1)
(defconstant +compaction-origin+ 2)

;;; REQ: REQ-FOR-001 REQ-FOR-002
(defconstant +log-header-bytes+ 64)
(defconstant +log-magic-low+ #x44435241) ; ARCD, little-endian
(defconstant +control-magic-high+ #x314c5443) ; CTL1, anche per versione 2
(defconstant +multiserie-magic-high+ #x314c534d) ; MSL1, anche per versione 2
(defconstant +log-magic-high-offset+ 4)
(defconstant +log-version-offset+ 8)
(defconstant +log-reserved-a-start+ 10)
(defconstant +log-reserved-a-end+ 16)
(defconstant +log-identity-offset+ 16)
(defconstant +log-identity-bytes+ 16)
(defconstant +log-reserved-b-start+ 32)
(defconstant +log-crc-offset+ 56)
(defconstant +log-reserved-c-start+ 60)

;;; REQ: REQ-FOR-003 REQ-AFF-008
(defconstant +edit-next-id-offset+ 0)
(defconstant +edit-open-offset+ 8)
(defconstant +edit-closed-count-offset+ 16)
(defconstant +edit-closed-start+ 20)
(defconstant +edit-complete+ 8)
(defconstant +closed-fixed-bytes+ 20)
(defconstant +closed-valid-bytes-offset+ 8)
(defconstant +closed-outcome-count-offset+ 16)
(defconstant +closure-outcome-bytes+ 16)
(defconstant +removed-id-bytes+ 8)
(defconstant +count-bytes+ 4)
(defconstant +edit-min-bytes+ 24)
(defconstant +decision-csn-offset+ 0)
(defconstant +decision-count-offset+ 8)
(defconstant +decision-parts-offset+ 10)
(defconstant +participant-id-bytes+ 16)
(defconstant +min-participants+ 2)
(defconstant +max-participants+ 65535)
(defconstant +metadata-max-bytes+ 16777216)
(defconstant +default-list-budget+ 65536)

;;; REQ: REQ-FOR-002
(declaim (ftype (function (integer index) (values u16 &optional)) versione-supportata))
(defun versione-supportata (version offset)
  "Pre: VERSION intero. Post: layout 1 o 2 esplicitamente riconosciuto.
UNSUPPORTED-FORMAT per altro valore; nessuna interpretazione per tentativi."
  (unless (member version '(1 2))
    (error 'unsupported-format :reason :file-version :offset offset))
  version)

;;; REQ: REQ-AFF-008 REQ-FOR-003
(declaim (ftype (function (index index index index) (values index &optional)) spazio-ripetuto))
(defun spazio-ripetuto (start end count width)
  "Pre: range valido e WIDTH positivo. Post: fine dei COUNT campi interamente presenti.
CORRUPTION-DETECTED se il conteggio eccede i byte; controllo prima della moltiplicazione."
  (unless (and (plusp width) (<= start end))
    (error 'invariant-violation :reason :metadata-range :offset start))
  (when (> count (floor (- end start) width))
    (error 'corruption-detected :reason :metadata-truncated :offset start))
  (+ start (* count width)))

;;; REQ: REQ-AFF-008
(declaim (ftype (function (index index index) null) esigi-budget))
(defun esigi-budget (actual budget offset)
  "Pre: grandezze non negative. Post: lavoro entro il budget dichiarato.
RESOURCE-EXHAUSTED prima della scansione se ACTUAL supera BUDGET."
  (when (> actual budget)
    (error 'resource-exhausted :reason :metadata-budget :offset offset))
  nil)
