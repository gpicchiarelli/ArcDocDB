;;; OWNER: buffer candidato stabile nel worker; tuple private, nessun riferimento al corpo trattenuto.
;;; SHARED: il coordinatore attesta prefisso committed e CSN prepared prima dell'ingresso.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-002 REQ-AFF-004
(declaim (ftype (function (selettore-versione-recuperata octets index index integer)
                         (values index u8 u8 u64 index index index index &optional))
                verifica-record-selezione))
(defun verifica-record-selezione (selector buffer start end version)
  "Pre: span stabile del chiamante. Post: ritorni originali del codec dopo CRC e forma completi.
INVARIANT-VIOLATION del codec guasta il selettore e conserva la causa; rifiuti esterni propagati."
  (handler-case (verifica-record buffer start end :version version)
    (invariant-violation (condition)
      (setf (selection-state selector) :faulted)
      (error condition))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (u8 u64 (or null u64)) u64) csn-candidato-recuperato))
(defun csn-candidato-recuperato (flags stamp prepared-csn)
  "Pre: flag/header verificati, record gia ammesso come committed dal recovery canonico.
Post: stamp ordinario oppure CSN prepared esplicito, incluso zero; TXID mai interpretato come CSN.
INVALID-ARGUMENT per prova prepared assente o fornita a un record ordinario; nessuna decisione 2PC qui."
  (if (logtest flags +prepared+)
      (progn
        (unless prepared-csn (error 'invalid-argument :reason :recovery-selection-prepared-csn-required))
        prepared-csn)
      (progn
        (when prepared-csn (error 'invalid-argument :reason :recovery-selection-ordinary-csn))
        stamp)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-FOR-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata octets index index u64 index integer (or null u64)) null)
                prepara-candidato-recuperato))
(defun prepara-candidato-recuperato (selector buffer start end segment offset version prepared-csn)
  "Pre: chiave inizializzata; buffer stabile dal segmento/prefisso autorevole, offset fisico assoluto.
Post: CRC completi, chiave/tipo/offset e CSN verificati prima di scrivere lo scratch candidato.
Solo PUT/TOMBSTONE; propaga condizioni del codec, rifiuti senza modificare il vincitore o lo stato.
Non prova SEAL, appartenenza al manifest, identita FD o commit: obblighi del reader chiamante."
  (esigi-selettore-pronto selector)
  (multiple-value-bind (next kind flags stamp ks ke vs ve)
      (verifica-record-selezione selector buffer start end version)
    (declare (ignore vs ve)) ; range gia verificati integralmente dal codec; non indicano errore.
    (unless (or (= kind +put+) (= kind +tombstone+))
      (error 'invalid-argument :reason :recovery-selection-record-kind))
    (unless (chiave-selezione-uguale-p selector buffer ks ke)
      (error 'invalid-argument :reason :recovery-selection-record-key))
    (unless (<= arcdocdb.storage.format:+segment-header-bytes+ offset (- most-positive-fixnum (- next start)))
      (error 'invalid-argument :reason :recovery-selection-record-offset))
    (let ((csn (csn-candidato-recuperato flags stamp prepared-csn)) (words (selection-candidate selector)))
      (setf (aref words 0) csn (aref words 1) segment (aref words 2) offset
            (aref words 3) (- next start) (aref words 4) (logior kind (ash flags 8) (ash version 16))
            (aref words 5) (leggi-u32 buffer start)
            (aref words 6) (leggi-u32 buffer (+ start +body-crc-offset+)))))
  nil)
