(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(declaim (ftype (function (t t t t t t t t) index) preflight-inizio-put))
(defun preflight-inizio-put (request key value row prepared high low max-work)
  "Pre: ingresso non fidato. Post: forma, stato, capacita e lavoro verificati senza mutare.
Flags 0/1 soltanto; TXID positivo in parole u32 per prepared, zero per ordinario."
  (unless (and (typep request 'preparazione-put-full-text) (typep key 'octets) (typep value 'octets)
               (typep row 'u32) (typep prepared 'boolean) (typep high 'u32) (typep low 'u32)
               (typep max-work 'index) (plusp max-work))
    (error 'invalid-argument :reason :fulltext-put-input))
  (unless (member (preparazione-put-full-text-state request) '(:idle :prepared :appended :cancelled :failed))
    (error 'invalid-argument :reason :fulltext-put-busy))
  (unless (if prepared (or (plusp high) (plusp low)) (and (zerop high) (zerop low)))
    (error 'invalid-argument :reason :fulltext-put-txid))
  (when (= (preparazione-put-full-text-generation request) most-positive-fixnum)
    (error 'resource-exhausted :reason :fulltext-put-generation))
  (unless (and (<= (length key) (preparazione-put-full-text-key-limit request))
               (<= (length value) (preparazione-put-full-text-document-limit request)))
    (error 'resource-exhausted :reason :fulltext-put-bytes))
  (let ((size (r::encoding-size (preparazione-put-full-text-frame request) 0 r:+put+ (if prepared r:+prepared+ 0)
                              key value (preparazione-put-full-text-version request)
                              (preparazione-put-full-text-document-limit request))))
    (when (> (* 2 size) max-work) (error 'resource-exhausted :reason :fulltext-put-work))
    size))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(declaim (ftype (function (t t t t &key (:prepared t) (:txid-high t) (:txid-low t) (:max-work t)) index)
                inizia-put-full-text))
(defun inizia-put-full-text (request key value row &key (prepared nil) (txid-high 0) (txid-low 0) (max-work 268435456))
  "Pre: input stabili fino al ritorno, proprietario esclusivo. Post: generation e cornice privata,
key/value originari riutilizzabili; tutte le analisi useranno questo esatto valore.
Rifiuti ordinari preservano il risultato precedente. Non valida il contratto generale della Serie.
Una copia/CRC e limitata a un record del formato; nessuna promessa realtime o I/O."
  (let ((size (preflight-inizio-put request key value row prepared txid-high txid-low max-work)) (complete nil))
    (unwind-protect
         (progn
           (incf (preparazione-put-full-text-generation request))
           (setf (preparazione-put-full-text-validated-generation request) 0)
           (r:scrivi-record-parole (preparazione-put-full-text-frame request) 0 r:+put+ txid-high txid-low key value
                                  :version (preparazione-put-full-text-version request) :flags (if prepared r:+prepared+ 0)
                                  :document-limit (preparazione-put-full-text-document-limit request))
           (setf (preparazione-put-full-text-size request) size
                 (preparazione-put-full-text-value-start request) (+ r:+header-bytes+ (length key))
                 (preparazione-put-full-text-row request) row (preparazione-put-full-text-current request) 0
                 (preparazione-put-full-text-active request) nil (preparazione-put-full-text-work request) (* 2 size)
                 (preparazione-put-full-text-work-limit request) max-work (preparazione-put-full-text-pool request) nil
                 (preparazione-put-full-text-slot request) nil (preparazione-put-full-text-slot-generation request) 0
                 (preparazione-put-full-text-state request) :preparing complete t)
           (preparazione-put-full-text-generation request))
      (unless complete (setf (preparazione-put-full-text-state request) :faulted)))))
