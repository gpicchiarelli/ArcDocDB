;;; OWNER: resolver del controller fornisce capacità, frontiera committed e flag autorevoli.
;;; SHARED: dati acquisiti entro EBR; nessun hint, stato cache o file size decide il commit.
(in-package #:arcdocdb.get)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get segmento-get u32 u8) null) verifica-target-get))
(defun verifica-target-get (context segment valid-bytes flags)
  "Pre: CANDIDATE/LOADING, capacità e limite committed acquisiti dal controller sotto EBR.
Post: stessa vista/segmento, record entro prefisso e formato; flag storage verificati.
INVALID-ARGUMENT per vista/flag; discordanza della location rende il contesto FAULTED.
Non inventa il limite da stat/file size; non interpreta LIVE come PREPARED."
  (unless (eq (segmento-get-owner segment) (contesto-get-view context))
    (error 'invalid-argument :reason :get-source-owner))
  (unless (zerop (logand flags (logxor 255 (allowed-flags +put+))))
    (error 'invalid-argument :reason :get-record-flags))
  (let* ((content (contesto-get-content context)) (location (aref content 1))
         (offset (ldb (byte 32 0) location)) (size (ldb (byte 32 0) (aref content 3)))
         (key (contesto-get-key context)))
    (declare (type u64 location) (type u32 offset size))
    (unless (and (zerop (segmento-get-high segment))
                 (= (segmento-get-low segment) (ldb (byte 32 32) location))
                 (plusp (segmento-get-low segment))
                 (<= +segment-header-bytes+ offset (+ offset size) valid-bytes +segment-max-bytes+))
      (guasto-get context :get-source-location))
    (multiple-value-bind (key-limit record-limit) (format-limits (segmento-get-version segment))
      (unless (and key (<= 1 (length key) key-limit)
                   (<= (+ +header-bytes+ (length key) 1) size record-limit))
        (guasto-get context :get-source-format)))
    (when (and (= (segmento-get-origin segment) +compaction-origin+)
               (not (zerop (logand flags +prepared+))))
      (guasto-get context :get-compacted-prepared)))
  nil)

;;; REQ: REQ-CCH-002 REQ-AFF-002 REQ-FOR-004
(declaim (ftype (function (contesto-get segmento-get u8 boolean)
                         (values (member :hit :miss :verify-failed :disabled) index index &optional))
                verifica-cache-get))
(defun verifica-cache-get (context segment flags prepared)
  "Pre: target valido, scratch sufficiente, prova own già letta se PREPARED.
Post: esito cache e range verificati; nessun esito negativo autorizza lo scratch.
NIL cache => DISABLED; gli errori tipizzati del modulo cache propagano al confine del compito."
  (let* ((cache (vista-get-serie-cache (segmento-get-owner segment)))
         (content (contesto-get-content context)))
    (unless cache (return-from verifica-cache-get (values :disabled 0 0)))
    (cerca-record-cache
     cache (segmento-get-high segment) (segmento-get-low segment)
     (ldb (byte 32 0) (aref content 1)) (ldb (byte 32 0) (aref content 3))
     (contesto-get-key context) (ldb (byte 32 32) (aref content 0))
     (ldb (byte 32 0) (aref content 0)) flags (contesto-get-bytes context) 0
     :version (segmento-get-version segment)
     :proof-buffer (if prepared (contesto-get-proof context) nil)
     :proof-start 0 :proof-end (if prepared +get-proof-bytes+ 0))))

;;; REQ: REQ-CCH-002 REQ-AFF-002
(declaim (ftype (function (contesto-get index index) null) marca-valore-get))
(defun marca-valore-get (context start end)
  "Pre: range dal verificatore comune su scratch privato stabile.
Post: VERIFIED solo per un valore non vuoto interamente presente; nulla consegnato al client.
Range incoerente rende FAULTED; CRC/chiave/CSN sono stati controllati dal verificatore."
  (unless (< start end) (guasto-get context :get-empty-value))
  (unless (<= end (length (contesto-get-bytes context))) (guasto-get context :get-value-overflow))
  (setf (contesto-get-value-start context) start (contesto-get-value-end context) end
        (contesto-get-state context) :verified)
  nil)

;;; REQ: REQ-CCH-002 REQ-CCH-004 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-get segmento-get u32 u8)
                         (member :hit :miss :verify-failed :disabled :proof-required :buffer-required))
                sonda-cache-get))
(defun sonda-cache-get (context segment valid-bytes flags)
  "Pre: CANDIDATE, target autorevole del resolver. Post: HIT lascia VERIFIED; altri esiti CANDIDATE.
Nessun I/O: PREPARED richiede prova dal pool I/O; BUFFER-REQUIRED richiede worker più capiente.
VERIFY-FAILED richiede metrica/allarme e percorso I/O. Errori/uscite non locali liberano EBR."
  (esigi-stato-get context :candidate)
  (let ((completed nil))
    (unwind-protect
         (progn
           (verifica-target-get context segment valid-bytes flags)
           (let ((result
                   (cond
                     ((> (aref (contesto-get-content context) 3) (length (contesto-get-bytes context)))
                      :buffer-required)
                     ((not (zerop (logand flags +prepared+))) :proof-required)
                     (t (multiple-value-bind (status start end) (verifica-cache-get context segment flags nil)
                          (case status
                            (:hit (marca-valore-get context start end))
                            ((:miss :verify-failed :disabled) nil)
                            (otherwise (guasto-get context :get-cache-result)))
                          status)))))
             (setf completed t)
             result))
      (unless completed (abbandona-get context)))))
