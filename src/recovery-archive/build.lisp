;;; OWNER: compito I/O dell'Archivio prima del recovery delle Serie; scratch e workspace esclusivi.
;;; SHARED: solo il risultato completo è condivisibile in lettura; nessun effetto durevole.
(in-package #:arcdocdb.recovery.archive)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-FOR-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-009
(declaim (ftype (function (archivio-recovery file-io index octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-batch-records u32) (:max-batch-bytes index) (:max-decisions index)
                               (:max-participants index) (:max-participants-per-decision u16))
                         decisioni-recuperate) leggi-decisioni-recuperate))
(defun leggi-decisioni-recuperate (archive input size scratch
                                 &key (chunk-bytes 65536) (max-bytes 67108864) (max-batches 65536)
                                      (max-batch-records 65536) (max-batch-bytes 67108864)
                                      (max-decisions 65536) (max-participants 65536)
                                      (max-participants-per-decision 65535))
  "Pre: Archivio canonico dal catalogo, EOF fisico SIZE completo e attestato, compito I/O esclusivo.
File/FD/namespace congelati fino al termine del recovery delle Serie; scratch privato fino al ritorno.
Post: header verificato sullo stesso FD, scansione a EOF e tabella completa posseduta del prefisso sigillato.
TAIL richiede ricerca completa dei testimoni; duplicati/conflitti/budget dal replay canonico.
Propaga condizioni originali; nessun append, fsync, troncatura, rename, CSN o ammissione traffico."
  (verifica-lettura-decisioni archive input size scratch chunk-bytes max-bytes max-batches
                            max-batch-records max-batch-bytes max-decisions
                            max-participants max-participants-per-decision)
  (let ((version (leggi-header-decisioni archive input scratch)))
    (leggi-corpo-decisioni input size scratch chunk-bytes)
    (multiple-value-bind (table prefix status)
        (ricostruisci-decisioni scratch +log-header-bytes+ size :version version :file-size size
                               :max-bytes max-bytes :max-batches max-batches :max-batch-records max-batch-records
                               :max-batch-bytes max-batch-bytes :max-search-bytes max-bytes
                               :max-decisions max-decisions :max-participants max-participants
                               :max-participants-per-decision max-participants-per-decision)
      (unless (and (<= +log-header-bytes+ prefix size)
                   (if (eq status :complete) (= prefix size) (< prefix size)))
        (error 'invariant-violation :reason :archive-recovery-prefix))
      (arcdocdb.io::esigi-aperto input :input)
      (%make-decisioni-recuperate archive input table size prefix status version))))
