;;; OWNER: risoluzione su workspace completo e manifest della stessa prova CLOSED, tutti readonly.
;;; SHARED: nessuna DECISION globale consultata; il TXID non viene mai interpretato come CSN.
(in-package #:arcdocdb.recovery.replay)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (closed-recuperato (or null workspace-active) u8 u64)
                         (values boolean (or null u64) &optional)) risolvi-record-closed-per-visita))
(defun risolvi-record-closed-per-visita (recovered workspace flags stamp)
  "Pre: PUT/TOMBSTONE da prefisso interamente verificato, semantica OUTCOME/EDIT già risolta.
Post: ordinario T/NIL; prepared committed T/CSN esplicito incluso zero, abortito NIL/NIL.
NIL non è un CSN; workspace mancante o valore interno fuori u64 => INVARIANT-VIOLATION."
  (unless (logtest flags +prepared+)
    (return-from risolvi-record-closed-per-visita (values t nil)))
  (unless workspace (error 'invariant-violation :reason :recovery-replay-prepared-workspace))
  (unless (nth-value 1 (gethash stamp (workspace-active-prepared workspace)))
    (error 'invariant-violation :reason :recovery-replay-unknown-prepared))
  (multiple-value-bind (csn present) (gethash stamp (workspace-active-outcomes workspace))
    (when present
      (unless (typep csn 'u64) (error 'invariant-violation :reason :recovery-replay-outcome-csn))
      (return-from risolvi-record-closed-per-visita (values t csn))))
  (multiple-value-bind (present csn)
      (arcdocdb.recovery.manifest:trova-esito-chiusura
       (arcdocdb.control:manifest-control-recuperato (closed-recuperato-control recovered))
       (closed-recuperato-id recovered) stamp)
    (when present
      (unless (typep csn 'u64) (error 'invariant-violation :reason :recovery-replay-closure-csn)))
    (values present (if present csn nil))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (closed-recuperato (or null workspace-active) octets index index u8 function)
                         (values index index &optional)) visita-dato-closed))
(defun visita-dato-closed (recovered workspace buffer pos next flags visitor)
  "Pre: dato verificato, buffer prestato readonly fino al ritorno del visitor; destinazioni private.
Post: una chiamata solo se committed, ritorna contatori delivered/aborted per record, non per TXID.
Visitor (buffer start end segment-id file-offset version prepared-csn) deve restituire NIL.
Uscite/errori originali propagati; esito diverso da NIL => INVALID-ARGUMENT dopo gli effetti del visitor."
  (unless (and (<= +segment-header-bytes+ pos) (< pos next (1+ (closed-recuperato-prefix recovered))))
    (error 'invariant-violation :reason :recovery-replay-record-range))
  (multiple-value-bind (committed csn)
      (risolvi-record-closed-per-visita recovered workspace flags (leggi-u64 buffer (+ pos +stamp-offset+)))
    (unless committed (return-from visita-dato-closed (values 0 1)))
    (let ((result (funcall visitor buffer pos next (closed-recuperato-id recovered) pos
                           (closed-recuperato-version recovered) csn)))
      (unless (null result) (error 'invalid-argument :reason :recovery-replay-visitor-result)))
    (values 1 0)))
