;;; OWNER: risultato completo immutabile; FD tenuto aperto dal controller nel recovery.
;;; SHARED: query scalari concorrenti; nessun vettore, buffer o stato mutabile esportato.
(in-package #:arcdocdb.recovery.archive)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (decisioni-recuperate) (values boolean u64 &optional))
                massimo-csn-decisioni-recuperate))
(defun massimo-csn-decisioni-recuperate (recovered)
  "Pre: decision log completo legato all'Archivio; controller mantiene il FD aperto.
Post: presenza e massimo CSN di ogni DECISION, anche senza prepared nelle Serie aperte.
Propaga condizioni tipizzate; controlla lifetime, senza I/O, mutazioni o ammissione del traffico."
  (arcdocdb.io::esigi-aperto (decisioni-recuperate-input recovered) :input)
  (arcdocdb.recovery.decisions:massimo-csn-decisioni (decisioni-recuperate-table recovered)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-009
(declaim (ftype (function (decisioni-recuperate)
                         (values index index (member :complete :tail) (member 1 2) &optional))
                frontiere-decisioni-recuperate))
(defun frontiere-decisioni-recuperate (recovered)
  "Pre: risultato completo. Post: EOF attestato, prefisso assoluto, stato e formato letti.
Nessun buffer o FD numerico esportato; TYPE-ERROR per tipi invalidi, nessuna prova di salute futura."
  (values (decisioni-recuperate-size recovered) (decisioni-recuperate-prefix recovered)
          (decisioni-recuperate-status recovered) (decisioni-recuperate-version recovered)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (decisioni-recuperate) (values index &optional)) numero-decisioni-recuperate))
(defun numero-decisioni-recuperate (recovered)
  "Pre: risultato completo. Post: numero dei TXID unici dopo coalescenza dei duplicati identici.
TYPE-ERROR per tipi invalidi; nessuna mutazione o syscall."
  (numero-decisioni (decisioni-recuperate-table recovered)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(declaim (ftype (function (decisioni-recuperate u64) (values boolean u64 u16 &optional))
                trova-decisione-recuperata))
(defun trova-decisione-recuperata (recovered txid)
  "Pre: risultato completo e TXID u64 opaco. Post: presenza, CSN e count; NIL/0/0 se assente.
Zero presente resta distinto dall'assenza; errori tipizzati del replay/query propagati."
  (trova-decisione (decisioni-recuperate-table recovered) txid))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(declaim (ftype (function (decisioni-recuperate u64 octets integer integer) boolean)
                partecipante-decisione-recuperata-p))
(defun partecipante-decisione-recuperata-p (recovered txid identity start end)
  "Pre: risultato completo, ID stabile del caller. Post: presenza esatta del partecipante ID16.
Range e lunghezza verificati anche per TXID assente; condizioni originali propagate, nessun alias esportato."
  (partecipante-decisione-p (decisioni-recuperate-table recovered) txid identity start end))
