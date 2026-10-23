;;; OWNER: solo writer sotto lease; dati scalari, nessun handle di preparazione esposto.
;;; SHARED: nessuno stato fra Serie; non acquisisce viste o snapshot per i reader.
(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-004 REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (t t t)
                         (values (member :absent :pending :sealed) u32 index index (integer 0 2)
                                 (member :none :csn :txid) u32 u32 &optional)) leggi-riferimento-riga-full-text))
(defun leggi-riferimento-riga-full-text (pool lease row)
  "Pre: pool canonico, lease writer e row u32. Post: stato, segmento, offset, size, formato,
stamp-kind, high,low. ABSENT/PENDING restituiscono 0 e :NONE, senza handle o parziali.
SEALED conserva CSN/TXID distinti e sopravvive al riuso WAL; non prova commit o MVCC.
INVALID-ARGUMENT per lease/row; mapping incoerente => pool FAULTED, nessun I/O o heap."
  (multiple-value-bind (status slot generation) (f:trova-riga-trasferita-full-text pool lease row)
    (case status
      (:absent (values :absent 0 0 0 0 :none 0 0))
      (:pending (values :pending 0 0 0 0 :none 0 0))
      (:transferred
       (case (f::riserva-full-text-physical-state slot)
         (:absent (values :pending 0 0 0 0 :none 0 0))
         (:sealed
          (multiple-value-bind (actual segment offset size version kind high low)
              (leggi-riferimento-put-full-text pool lease slot generation)
            (unless (= actual row) (f::errore-interno-riserve pool :fulltext-row-reference))
            (values :sealed segment offset size version kind high low)))
         (otherwise (f::errore-interno-riserve pool :fulltext-row-reference))))
      (otherwise (f::errore-interno-riserve pool :fulltext-row-reference)))))
