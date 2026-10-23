;;;; Confine record/payload: verifica CRC, tipo, flag e lunghezza prima dei conteggi.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-002 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index index u8 integer index)
                         (values index index u8 &optional)) cornice-di-controllo))
(defun cornice-di-controllo (buffer start end kind version max-bytes)
  "Pre: record stabile, versione esplicita dal file. Post: CRC completi, tipo e consumo esatto.
Restituisce range payload e flag; CORRUPTION-DETECTED o UNSUPPORTED-FORMAT altrimenti.
Non materializza lo stamp u64; budget dei byte applicato prima di qualsiasi scansione CRC."
  (check-range buffer start end)
  (unless (<= max-bytes +metadata-max-bytes+)
    (error 'invalid-argument :reason :metadata-byte-budget :offset start))
  (esigi-budget (- end start) (+ +header-bytes+ max-bytes) start)
  (multiple-value-bind (next actual-kind flags ks ke vs ve)
      (verifica-cornice buffer start end :version version)
    (declare (ignore ks ke)) ; il tipo di controllo impone chiave vuota nella cornice
    (unless (and (= next end) (= actual-kind kind))
      (error 'corruption-detected :reason :control-record :offset start))
    (values vs ve flags)))

;;; REQ: REQ-FOR-002 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (octets index index &key (:version integer)
                                (:max-chiusi u32) (:max-rimossi u32)
                                (:max-esiti u32) (:max-bytes index))
                         (values index index index u32 index u32 u32 u8 &optional))
                verifica-record-edit))
(defun verifica-record-edit (buffer start end &key (version 0)
                            (max-chiusi +default-list-budget+)
                            (max-rimossi +default-list-budget+)
                            (max-esiti +default-list-budget+)
                            (max-bytes +metadata-max-bytes+))
  "Pre: range stabile, versione obbligatoria dal file (zero non è un formato).
Post: record EDIT e payload completamente verificati; range valore/chiusi/rimossi, count,
totale esiti e flag. Propaga errori tipizzati. Non attesta commit o stato del manifest."
  (multiple-value-bind (vs ve flags) (cornice-di-controllo buffer start end +edit+ version max-bytes)
    (multiple-value-bind (cs cc rs rc total)
        (valida-valore-edit buffer vs ve flags :max-chiusi max-chiusi
                           :max-rimossi max-rimossi :max-esiti max-esiti :max-bytes max-bytes)
      (values vs ve cs cc rs rc total flags))))

;;; REQ: REQ-FOR-002 REQ-FOR-003 REQ-TXM-001 REQ-AFF-008
(declaim (ftype (function (octets index index &key (:version integer)
                                (:max-partecipanti u16) (:max-bytes index))
                         (values index index index u16 &optional)) verifica-record-decision))
(defun verifica-record-decision (buffer start end &key (version 0)
                                (max-partecipanti +max-participants+)
                                (max-bytes +metadata-max-bytes+))
  "Pre: range stabile e versione esplicita dal file. Post: CRC e struttura DECISION validi.
Restituisce offset CSN, inizio/fine partecipanti e count. Propaga errori tipizzati.
Il TXID rimane nello stamp del record; validità del catalogo e commit spettano al proprietario."
  (multiple-value-bind (vs ve flags) (cornice-di-controllo buffer start end +decision+ version max-bytes)
    (declare (ignore flags)) ; la cornice impone zero per DECISION
    (valida-valore-decision buffer vs ve :max-partecipanti max-partecipanti :max-bytes max-bytes)))
