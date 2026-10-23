;;; OWNER: controller osserva il risultato immutabile dopo consegna; mantiene il FD readonly fino al reclaim.
;;; SHARED: query scalari e capacità opache; nessun array o workspace esportato.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-009
(declaim (ftype (function (active-recuperato)
                         (values index index (member :complete :tail) (member 1 2) &optional))
                frontiere-active-recuperato))
(defun frontiere-active-recuperato (recovered)
  "Pre: risultato completo. Post: EOF attestato, prefisso assoluto, stato e formato verificato.
Nessuna prova di dimensione/salute attuale; TYPE-ERROR per tipi invalidi."
  (values (active-recuperato-size recovered) (active-recuperato-prefix recovered)
          (active-recuperato-status recovered) (arcdocdb.get::segmento-get-version (active-recuperato-segment recovered))))

;;; REQ: REQ-REC-001 REQ-TXM-007
(declaim (ftype (function (active-recuperato) (values index index index index index index &optional))
                statistiche-active-recuperato))
(defun statistiche-active-recuperato (recovered)
  "Pre: risultato completo. Post: lotti, record esclusi SEAL, TXID prepared distinti, commit locali/derivati, abort.
TXID prepared = locali + derivati + abort; nessun conteggio della coda o table esposta."
  (values (active-recuperato-batches recovered) (active-recuperato-records recovered)
          (active-recuperato-prepared recovered) (active-recuperato-local recovered)
          (length (active-recuperato-ids recovered)) (active-recuperato-aborted recovered)))

;;; REQ: REQ-REC-001 REQ-FOR-001
(declaim (ftype (function (active-recuperato) segmento-get) segmento-active-recuperato))
(defun segmento-active-recuperato (recovered)
  "Pre: risultato completo. Post: capacità del vecchio segmento readonly dal FD verificato, senza trasferire ownership.
Non rende CLOSED il file o certifica durata EBR; il caller mantiene capacità fino al reclaim."
  (active-recuperato-segment recovered))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (active-recuperato u64) (values boolean u64 &optional)) esito-chiusura-active))
(defun esito-chiusura-active (recovered txid)
  "Pre: risultato completo, TXID u64. Post: presenza e CSN da DECISION da conservare nell'EDIT, NIL/0 se assente.
Assenza NON classifica la transazione: può già avere OUTCOME nel segmento. Nessun array esportato.
Ricerca limitata a INTEGER-LENGTH(N), INVARIANT-VIOLATION per limiti o forme discordanti."
  (let* ((ids (active-recuperato-ids recovered)) (csns (active-recuperato-csns recovered))
         (count (length ids)) (left 0) (right count))
    (unless (= count (length csns)) (error 'invariant-violation :reason :active-recovery-query-shape))
    (loop repeat (integer-length count) while (< left right)
          do (let ((middle (+ left (floor (- right left) 2))))
               (unless (<= 0 left middle (1- right) (1- count))
                 (error 'invariant-violation :reason :active-recovery-query-range))
               (let ((actual (aref ids middle)))
                 (cond ((= actual txid) (return-from esito-chiusura-active (values t (aref csns middle))))
                       ((< actual txid) (setf left (1+ middle)))
                       (t (setf right middle))))))
    (when (< left right) (error 'invariant-violation :reason :active-recovery-query-bound))
    (values nil 0)))
