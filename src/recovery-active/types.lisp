;;; OWNER: workspace privato di una scansione; risultato pubblicato solo dopo risoluzione completa.
;;; SHARED: risultato immutabile; nessun buffer, tabella decisioni o workspace trattenuto.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftype parole-esiti () '(simple-array (unsigned-byte 64) (*)))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-AFF-009
(defstruct (active-recuperato
             (:constructor %make-active-recuperato
                 (control segment size prefix status batches records prepared local aborted ids csns
                  csn-present max-csn decision-origin)) (:copier nil))
  "Pre: header writer, prefisso e semantica verificati; tutti prepared risolti da prove autorevoli.
Post: capacità readonly e scalari, esiti derivati posseduti e ordinati, senza buffer/workspace.
Non attesta EOF fisico, inventario o autorità della tabella decisioni dell'Archivio."
  (control nil :type control-recuperato :read-only t)
  (segment nil :type segmento-get :read-only t)
  (size 0 :type index :read-only t)
  (prefix 0 :type index :read-only t)
  (status :complete :type (member :complete :tail) :read-only t)
  (batches 0 :type index :read-only t)
  (records 0 :type index :read-only t)
  (prepared 0 :type index :read-only t)
  (local 0 :type index :read-only t)
  (aborted 0 :type index :read-only t)
  (ids #() :type parole-esiti :read-only t)
  (csns #() :type parole-esiti :read-only t)
  (csn-present nil :type boolean :read-only t)
  (max-csn 0 :type u64 :read-only t)
  (decision-origin nil :type arcdocdb.recovery.decisions::origine-decisioni :read-only t))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(defstruct (workspace-active (:constructor %make-workspace-active ()) (:copier nil))
  "Pre: budget verificati, workspace esclusivo. Post: mappe EQL private, contatori zero.
Prepared associa TXID al lotto; outcomes associa TXID al CSN; derived contiene solo esiti mancanti sul file.
Nessun contenitore viene esportato; allocazioni del solo percorso di apertura."
  (prepared (make-hash-table :test 'eql) :type hash-table :read-only t)
  (outcomes (make-hash-table :test 'eql) :type hash-table :read-only t)
  (derived (make-hash-table :test 'eql) :type hash-table :read-only t)
  (outcome-records 0 :type index)
  (local 0 :type index)
  (aborted 0 :type index)
  (csn-present nil :type boolean)
  (max-csn 0 :type u64))
