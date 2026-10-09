;;;; Query scalari del manifest completato; nessun contenitore privato esportato.
;;; OWNER: proprietario del manifest immutabile restituito dalla ricostruzione.
;;; SHARED: sola lettura; nessuna scrittura o sincronizzazione condivisa tra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (manifest) (values u64 &optional)) segmento-attivo))
(defun segmento-attivo (manifest)
  "Pre: manifest interamente ricostruito. Post: ACTIVE nonzero, nessuna modifica.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (%manifest-active manifest))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-018
(declaim (ftype (function (manifest) (values boolean u64 &optional)) prossimo-id-segmento))
(defun prossimo-id-segmento (manifest)
  "Pre: manifest completo. Post: presenza e high-water u64, NIL/0 se spazio ID esaurito.
Il valore2^64 è solo interno in memoria; nessun sentinel diverso viene letto o scritto su disco.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (let ((next (%manifest-next-id manifest)))
    (if (typep next 'u64) (values t next) (values nil 0))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (manifest) (values index &optional)) numero-segmenti-chiusi))
(defun numero-segmenti-chiusi (manifest)
  "Pre: manifest completo. Post: numero ID CLOSED unici presenti, nessuna modifica.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (hash-table-count (%manifest-closed manifest)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-018
(declaim (ftype (function (manifest) (values index &optional)) numero-segmenti-rimossi))
(defun numero-segmenti-rimossi (manifest)
  "Pre: manifest completo. Post: numero ID REMOVED unici registrati, nessuna modifica.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (hash-table-count (%manifest-removed manifest)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function (manifest u64)
                         (values (member :active :closed :removed :unknown) u64 index &optional))
                trova-segmento))
(defun trova-segmento (manifest id)
  "Pre: manifest completo, ID u64. Post: stato, valid-bytes e numero esiti unici.
Lunghezza/count sono zero per ACTIVE, REMOVED e UNKNOWN; nessun riferimento interno esposto.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (cond
    ((= id (%manifest-active manifest)) (values :active 0 0))
    ((gethash id (%manifest-closed manifest))
     (let ((entry (the manifest-closed (gethash id (%manifest-closed manifest)))))
       (values :closed (%closed-valid-bytes entry) (hash-table-count (%closed-outcomes entry)))))
    ((gethash id (%manifest-removed manifest)) (values :removed 0 0))
    (t (values :unknown 0 0))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (manifest u64 u64) (values boolean u64 &optional)) trova-esito-chiusura))
(defun trova-esito-chiusura (manifest segment-id txid)
  "Pre: manifest completo e ID/TXID u64. Post: presenza e CSN, NIL/0 se segmento/esito assente.
CSN zero presente è distinguibile dall'assenza; tutte le parole u64 sono confrontate.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (let ((entry (gethash segment-id (%manifest-closed manifest))))
    (if entry
        (multiple-value-bind (csn present) (gethash txid (%closed-outcomes entry))
          (if present (values t csn) (values nil 0)))
        (values nil 0))))
