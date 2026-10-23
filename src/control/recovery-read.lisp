;;; OWNER: pool I/O legge un file congelato; scratch esclusivo dell'intera chiamata.
;;; SHARED: sola lettura della capacità e della vista; nessuna scrittura tra Serie.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (arcdocdb.get:vista-get-serie file-io index octets index index
                          index arcdocdb.binary:u32 index arcdocdb.binary:u32 arcdocdb.binary:u32) null)
                verifica-lettura-control))
(defun verifica-lettura-control (view input size scratch chunk max-bytes batches records edits segments outcomes)
  "Pre: EOF fisico autorevole e stabile, input readonly, scratch esclusivo. Post: preflight senza I/O.
Alias rifiutato prima di controllare il range; tutti i budget verificati prima di leggere.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED/IO-FAULT, nessuna mutazione delle capacità."
  (arcdocdb.io::esigi-aperto input :input)
  (when (eq scratch (arcdocdb.get::vista-get-serie-identity view))
    (error 'invalid-argument :reason :control-recovery-alias))
  (unless (and (plusp chunk) (>= size +log-header-bytes+) (>= max-bytes +log-header-bytes+))
    (error 'invalid-argument :reason :control-recovery-arguments))
  (when (> size max-bytes) (error 'resource-exhausted :reason :control-recovery-byte-budget))
  (check-range scratch 0 size)
  (verifica-capienza-lettura input (min size chunk))
  (arcdocdb.recovery.manifest::checked-manifest-limits
   edits segments outcomes segments segments outcomes +metadata-max-bytes+)
  (unless (= (arcdocdb.recovery.scan::check-scan-arguments
              scratch +log-header-bytes+ size 0 2 :control 0 size max-bytes batches records max-bytes max-bytes)
             size)
    (error 'invariant-violation :reason :control-recovery-preflight))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (file-io index octets index) null) leggi-control-completo))
(defun leggi-control-completo (input size scratch chunk)
  "Pre: preflight conclusa, EOF stabile, scratch esclusivo, pool I/O. Post: SIZE byte letti dallo stesso FD.
Ciclo limitato a CEILING(size/chunk), ogni ritorno controllato; nessun risultato parziale esportato.
IO-FAULT propagato senza retry, mutazione, chiusura o troncatura del file."
  (unless (plusp chunk) (error 'invalid-argument :reason :control-recovery-chunk))
  (check-range scratch 0 size)
  (loop repeat (ceiling size chunk) for start from 0 by chunk
        for end = (min size (+ start chunk))
        do (unless (= (leggi-esatto input scratch start end start) end)
             (error 'invariant-violation :reason :control-recovery-read :offset start)))
  (arcdocdb.io::esigi-aperto input :input)
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (arcdocdb.get:vista-get-serie file-io index octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-batch-records arcdocdb.binary:u32) (:max-edits index)
                               (:max-segmenti arcdocdb.binary:u32) (:max-esiti arcdocdb.binary:u32))
                         control-recuperato) leggi-control-recuperato))
(defun leggi-control-recuperato (view input size scratch
                               &key (chunk-bytes 65536) (max-bytes 67108864) (max-batches 65536)
                                    (max-batch-records 65536) (max-edits 65536)
                                    (max-segmenti 65536) (max-esiti 65536))
  "Pre: recovery esclusivo, vista e control.log autorevoli dal catalogo, EOF fisico SIZE attestato.
Scratch privato di SIZE byte; file/FD/namespace congelati fino alla futura pubblicazione.
Post: header CRC/Serie/formato e intero scanner fino a EOF verificati, manifest posseduto del prefisso.
TAIL ammessa solo dopo ricerca completa dei testimoni; LOG-CORRUPTION e altri errori propagano.
Nessun risultato parziale, append, fsync, rinomina, CSN o troncatura; percorso di apertura con allocazioni."
  (verifica-lettura-control view input size scratch chunk-bytes max-bytes max-batches max-batch-records
                           max-edits max-segmenti max-esiti)
  (leggi-control-completo input size scratch chunk-bytes)
  (multiple-value-bind (start version)
      (verifica-header-log scratch 0 size :control (arcdocdb.get::vista-get-serie-identity view))
    (unless (= start +log-header-bytes+) (error 'invariant-violation :reason :control-recovery-header))
    (multiple-value-bind (manifest prefix status)
        (ricostruisci-manifest scratch start size :version version :file-size size
                              :max-bytes max-bytes :max-batches max-batches :max-batch-records max-batch-records
                              :max-batch-bytes max-bytes :max-search-bytes max-bytes :max-edits max-edits
                              :max-segmenti max-segmenti :max-esiti max-esiti :max-chiusi-per-edit max-segmenti
                              :max-rimossi-per-edit max-segmenti :max-esiti-per-edit max-esiti)
      (unless (and (<= start prefix size) (eq (eq status :complete) (= prefix size)))
        (error 'invariant-violation :reason :control-recovery-prefix))
      (arcdocdb.io::esigi-aperto input :input)
      (%make-control-recuperato view input manifest size prefix status version))))
