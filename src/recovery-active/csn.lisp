;;; OWNER: workspace privato del recovery; aggiornamento solo dopo verifica integrale del prefisso.
;;; SHARED: due scalari locali, nessun registro CSN o stato condiviso fra Serie.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-TXM-007
(declaim (ftype (function (workspace-active u64) null) registra-csn-active))
(defun registra-csn-active (workspace csn)
  "Pre: CSN da fonte già verificata; mai TXID, offset o ordine di un log di controllo.
Post: massimo osservato e presenza indipendente dal valore zero; solo workspace privato.
TYPE-ERROR per tipi invalidi; nessuna allocazione di contenitori, I/O o assegnazione di versioni."
  (setf (workspace-active-max-csn workspace) (max csn (workspace-active-max-csn workspace))
        (workspace-active-csn-present workspace) t)
  nil)

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-TXM-007
(declaim (ftype (function (active-recuperato) (values boolean u64 &optional))
                massimo-csn-active-recuperato))
(defun massimo-csn-active-recuperato (recovered)
  "Pre: risultato completo immutabile. Post: presenza e massimo CSN osservato nel prefisso e negli esiti risolti.
Include SEAL writer e OUTCOME senza prepared locale; esclude coda e stamp TXID dei prepared.
NIL/0 se nessuna fonte; TYPE-ERROR per tipi invalidi. Non inizializza il registro dell'Archivio."
  (values (active-recuperato-csn-present recovered) (active-recuperato-max-csn recovered)))
