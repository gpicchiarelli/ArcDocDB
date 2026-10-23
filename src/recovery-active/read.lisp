;;; OWNER: compito I/O esclusivo; input readonly e control log canonici restano aperti.
;;; SHARED: sola lettura della vista dell'Archivio; nessuno stato mutabile tra Serie.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-002
(declaim (ftype (function (control-recuperato file-io index octets index index index u32 index) null)
                verifica-lettura-active))
(defun verifica-lettura-active (control input size scratch chunk bytes batches batch-records batch-bytes)
  "Pre: EOF fisico SIZE autorevole e stabile, scratch esclusivo. Post: preflight senza syscall/mutazioni.
Alias con l'identità rifiutato prima del range; budget, capacità e backend controllati.
CORRUPTION-DETECTED per header assente; argomenti/budget/capacità con condizioni tipizzate."
  (let* ((previous (arcdocdb.control::control-recuperato-input control))
         (view (arcdocdb.control::control-recuperato-view control)))
    (arcdocdb.io::esigi-aperto previous :input)
    (arcdocdb.io::esigi-aperto input :input)
    (when (eq scratch (arcdocdb.get::vista-get-serie-identity view))
      (error 'invalid-argument :reason :active-recovery-alias))
    (unless (and (plusp chunk) (>= bytes +segment-header-bytes+))
      (error 'invalid-argument :reason :active-recovery-arguments))
    (when (< size +segment-header-bytes+)
      (error 'corruption-detected :reason :active-recovery-header-truncated :offset 0))
    (when (or (> size bytes) (> size arcdocdb.storage.format::+segment-max-bytes+))
      (error 'resource-exhausted :reason :active-recovery-byte-budget))
    (check-range scratch 0 size)
    (verifica-capienza-lettura input (max +segment-header-bytes+ (min (- size +segment-header-bytes+) chunk)))
    (unless (eq (arcdocdb.io::file-backend previous) (arcdocdb.io::file-backend input))
      (error 'invalid-argument :reason :active-recovery-backend))
    (unless (= size (arcdocdb.recovery.scan::check-scan-arguments
                     scratch +segment-header-bytes+ size (segmento-attivo (manifest-control-recuperato control))
                     2 :segment 0 size bytes batches batch-records batch-bytes bytes))
      (error 'invariant-violation :reason :active-recovery-preflight)))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (file-io index octets index) null) leggi-corpo-active))
(defun leggi-corpo-active (input size scratch chunk)
  "Pre: header già letto nello scratch, preflight conclusa, EOF stabile nel pool I/O.
Post: corpo fino a EOF letto dallo stesso FD e capacità ancora aperta; nessun header riletto.
Ciclo CEILING((size-64)/chunk); errori I/O originali propagati, nessuna chiusura/troncatura."
  (unless (and (plusp chunk) (>= size +segment-header-bytes+))
    (error 'invalid-argument :reason :active-recovery-read-range))
  (check-range scratch 0 size)
  (loop repeat (ceiling (- size +segment-header-bytes+) chunk)
        for start from +segment-header-bytes+ by chunk for end = (min size (+ start chunk))
        do (unless (= (leggi-esatto input scratch start end start) end)
             (error 'invariant-violation :reason :active-recovery-read :offset start)))
  (arcdocdb.io::esigi-aperto input :input)
  nil)
