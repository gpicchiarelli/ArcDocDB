;;; OWNER: writer della riserva e del lotto SEALED, prima della consegna all'I/O.
;;; SHARED: nessuno stato tra Serie; lettura del token locale, nessuna consultazione di H.
(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-004 REQ-WAL-005 REQ-CON-002
(declaim (ftype (function (f:riserve-full-text w:lotto keyword) nil) errore-riferimento-put))
(defun errore-riferimento-put (pool batch reason)
  "Pre: invariante interna falsa. Post: pool/lotto FAULTED, byte e costi conservati.
Il confine del writer ferma la Serie; nessun rollback, risoluzione CSN o ACK."
  (setf (w::lotto-state batch) :faulted)
  (f::errore-interno-riserve pool reason))

;;; REQ: REQ-SEC-004 REQ-SEC-006 REQ-WAL-005
(declaim (ftype (function (f:riserve-full-text f:riserva-full-text w:lotto u32 u32)
                         (values u32 u32 &optional)) verifica-header-riferimento-put))
(defun verifica-header-riferimento-put (pool slot batch high low)
  "Pre: intervallo vivo e token WAL pendente esatto. Post: stamp verificato in due u32.
CRC del solo header (20 byte), corpo immutabile attestato dal worker; nessuna scansione body.
Header incoerente => pool/lotto FAULTED; prepared conserva TXID, ordinario usa CSN lotto."
  (handler-case
      (let* ((buffer (w::lotto-buffer batch)) (start (f::riserva-full-text-record-start slot))
             (end (f::riserva-full-text-record-end slot)))
        (multiple-value-bind (next kind flags key-size value-size)
            (r::checked-header buffer start end (w::lotto-version batch) r:+max-document-bytes+)
          (declare (ignore key-size value-size)) ; decoder verifica limiti e forma; qui span esatto.
          (unless (and (= next end) (= kind r:+put+) (= flags (f::riserva-full-text-put-flags slot))
                       (or (zerop flags) (= flags r:+prepared+))
                       (<= end (- (w::lotto-used batch) w::+seal-total+)))
            (errore-riferimento-put pool batch :fulltext-reference-header))
          (let ((actual-high (leggi-u32 buffer (+ start r::+stamp-offset+ 4)))
                (actual-low (leggi-u32 buffer (+ start r::+stamp-offset+))))
            (unless (if (zerop flags) (and (= high actual-high) (= low actual-low))
                        (and (= actual-high (f::riserva-full-text-put-high slot))
                             (= actual-low (f::riserva-full-text-put-low slot))
                             (or (plusp actual-high) (plusp actual-low))))
              (errore-riferimento-put pool batch :fulltext-reference-stamp))
            (values actual-high actual-low))))
    (arcdocdb-error (condition)
      (setf (f::riserve-full-text-state pool) :faulted (w::lotto-state batch) :faulted)
      (error condition))))

;;; REQ: REQ-SEC-004 REQ-SEC-006 REQ-WAL-005
(declaim (ftype (function (f:riserve-full-text f:riserva-full-text w:lotto t t) (values u32 u32 &optional))
                preflight-riferimento-put))
(defun preflight-riferimento-put (pool slot batch registry log)
  "Pre: lease/token/legame vivi. Post: lotto chiuso prima dell'I/O, autorita e offset validi.
Rifiuti ordinari senza mutazioni; non e una verifica di durability o esito prepared."
  (unless (and (typep registry 'arcdocdb.csn:registro-csn) (typep log 'w:log-io))
    (error 'invalid-argument :reason :fulltext-reference-authority))
  (unless (eq :absent (f::riserva-full-text-physical-state slot))
    (error 'invalid-argument :reason :fulltext-reference-captured))
  (unless (and (eq :sealed (w::lotto-state batch)) (null (w::lotto-owner batch)))
    (error 'invalid-argument :reason :fulltext-reference-phase))
  (multiple-value-bind (token high low) (w:leggi-csn-lotto batch)
    (w:verifica-token-lotto batch registry log token high low)
    (w:verifica-log-segmento log)
    (unless (<= (+ (w::lotto-start batch) (f::riserva-full-text-record-end slot)) most-positive-fixnum)
      (errore-riferimento-put pool batch :fulltext-reference-offset))
    (verifica-header-riferimento-put pool slot batch high low)))
