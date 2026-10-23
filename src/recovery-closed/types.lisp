;;; OWNER: risultato completo del recovery; controller conserva CONTROL e input fino al reclaim.
;;; SHARED: legami immutabili, nessun buffer, array o workspace trattenuto/esportato.
(in-package #:arcdocdb.recovery.closed)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-008
(defstruct (closed-recuperato
             (:constructor %make-closed-recuperato
                 (control input id prefix version origin batches records prepared local closure aborted
                  csn-present max-csn))
             (:copier nil))
  "Pre: header dal medesimo FD e prefisso CLOSED interamente verificati, prepared risolti localmente.
Post: capacità readonly e scalari posseduti, nessun buffer/workspace; ID completo u64 incluso zero.
Non attesta EOF fisico, inventario, autorità del catalogo o ammissione del traffico."
  (control nil :type control-recuperato :read-only t)
  (input nil :type file-io :read-only t)
  (id 0 :type u64 :read-only t)
  (prefix 0 :type index :read-only t)
  (version 2 :type (member 1 2) :read-only t)
  (origin 1 :type (member 1 2) :read-only t)
  (batches 0 :type index :read-only t)
  (records 0 :type index :read-only t)
  (prepared 0 :type index :read-only t)
  (local 0 :type index :read-only t)
  (closure 0 :type index :read-only t)
  (aborted 0 :type index :read-only t)
  (csn-present nil :type boolean :read-only t)
  (max-csn 0 :type u64 :read-only t))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-STO-006
(declaim (ftype (function (closed-recuperato)
                         (values u64 index (member 1 2) (member 1 2) &optional)) frontiere-closed-recuperato))
(defun frontiere-closed-recuperato (recovered)
  "Pre: risultato completo. Post: ID, P dal manifest, versione e origine; nessuna misura dell'EOF.
TYPE-ERROR per tipi invalidi; nessun FD numerico o prova di salute corrente."
  (values (closed-recuperato-id recovered) (closed-recuperato-prefix recovered)
          (closed-recuperato-version recovered) (closed-recuperato-origin recovered)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (closed-recuperato) (values index index index index index index &optional))
                statistiche-closed-recuperato))
(defun statistiche-closed-recuperato (recovered)
  "Pre: risultato completo. Post: lotti, record esclusi SEAL, TXID prepared, commit locali, da EDIT e abort.
Compaction: zero lotti/prepared/esiti, record PUT+TOMBSTONE; TYPE-ERROR per tipi invalidi.
I conteggi riguardano solo il prefisso e non attestano visibilità o ricostruzione degli indici."
  (values (closed-recuperato-batches recovered) (closed-recuperato-records recovered)
          (closed-recuperato-prepared recovered) (closed-recuperato-local recovered)
          (closed-recuperato-closure recovered) (closed-recuperato-aborted recovered)))
