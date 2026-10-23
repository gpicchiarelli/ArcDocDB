;;; OWNER: compito I/O esclusivo dell'Archivio; EOF, FD e scratch congelati per l'intera chiamata.
;;; SHARED: sola lettura della capacità, nessuna mutazione condivisa tra Serie.
(in-package #:arcdocdb.recovery.archive)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (archivio-recovery file-io index octets index index index u32 index index index u16)
                         null) verifica-lettura-decisioni))
(defun verifica-lettura-decisioni (archive input size scratch chunk bytes batches batch-records
                                 batch-bytes decisions participants per-decision)
  "Pre: EOF fisico autorevole, scratch esclusivo. Post: preflight senza syscall o scritture.
Capacità readonly aperta, alias/range/budget verificati prima della prima lettura.
CORRUPTION-DETECTED per header troncato; argomenti/capacità/budget con condizioni tipizzate."
  (arcdocdb.io::esigi-aperto input :input)
  (when (eq scratch (archivio-recovery-identity archive))
    (error 'invalid-argument :reason :archive-recovery-alias))
  (unless (and (plusp chunk) (>= bytes +log-header-bytes+))
    (error 'invalid-argument :reason :archive-recovery-arguments))
  (when (< size +log-header-bytes+)
    (error 'corruption-detected :reason :archive-recovery-header-truncated :offset 0))
  (when (> size bytes) (error 'resource-exhausted :reason :archive-recovery-byte-budget))
  (check-range scratch 0 size)
  (verifica-capienza-lettura input (max +log-header-bytes+ (min (- size +log-header-bytes+) chunk)))
  (arcdocdb.recovery.decisions::check-decision-budgets decisions participants per-decision)
  (unless (= size (arcdocdb.recovery.scan::check-scan-arguments
                   scratch +log-header-bytes+ size 0 2 :multiserie 0 size
                   bytes batches batch-records batch-bytes bytes))
    (error 'invariant-violation :reason :archive-recovery-preflight))
  nil)

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-001 REQ-FOR-002 REQ-AFF-002
(declaim (ftype (function (archivio-recovery file-io octets) (values (member 1 2) &optional))
                leggi-header-decisioni))
(defun leggi-header-decisioni (archive input scratch)
  "Pre: preflight conclusa nel pool I/O, capacità e scratch stabili. Post: header letto una volta.
Magic multiserie, CRC, UUID completo, versione e riservati verificati prima del corpo.
Errori originali propagati; nessun risultato o modifica dei file."
  (check-range scratch 0 +log-header-bytes+)
  (let ((next (leggi-esatto input scratch 0 +log-header-bytes+ 0)))
    (unless (= next +log-header-bytes+)
      (error 'invariant-violation :reason :archive-recovery-header-read)))
  (multiple-value-bind (next version)
      (verifica-header-log scratch 0 +log-header-bytes+ :multiserie (archivio-recovery-identity archive))
    (unless (= next +log-header-bytes+)
      (error 'invariant-violation :reason :archive-recovery-header))
    (the (member 1 2) version)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (file-io index octets index) null) leggi-corpo-decisioni))
(defun leggi-corpo-decisioni (input size scratch chunk)
  "Pre: header verificato e EOF stabile, scratch privato, compito I/O. Post: corpo fino a EOF sullo stesso FD.
Ciclo limitato a CEILING((size-64)/chunk), nessuna rilettura dell'header.
Errori I/O propagati senza retry, chiusura o troncatura; nessun risultato parziale."
  (unless (and (plusp chunk) (>= size +log-header-bytes+))
    (error 'invalid-argument :reason :archive-recovery-read-range))
  (check-range scratch 0 size)
  (loop repeat (ceiling (- size +log-header-bytes+) chunk)
        for start from +log-header-bytes+ by chunk for end = (min size (+ start chunk))
        do (let ((next (leggi-esatto input scratch start end start)))
             (unless (= next end)
               (error 'invariant-violation :reason :archive-recovery-read :offset start))))
  (arcdocdb.io::esigi-aperto input :input)
  nil)
