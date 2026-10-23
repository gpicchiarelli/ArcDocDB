;;;; Un item strutturale/UTF8 con sole testate minime, un solo attraversamento.
;;; OWNER: buffer immutabile e scratch esclusivo del chiamante, privato di ogni worker.
;;; SHARED: nessuna scrittura, attesa o I/O tra Serie (INV-P6); nessun thread creato.
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t &key (:max-bytes t) (:max-nodes t) (:max-depth t))
                         (values index (integer 0 100) index &optional))
                verifica-struttura-cbor-minima))
(defun verifica-struttura-cbor-minima (buffer start end space
                                      &key (max-bytes +cbor-scan-max-bytes+)
                                        (max-nodes +cbor-scan-max-bytes+)
                                        (max-depth +cbor-scan-max-depth+))
  "Pre: simple u8 immutabile, span half-open, scratch esclusivo e budget verificati.
Post: esattamente NODES, picco soli array/map, END per un item esatto con header minimi.
Propaga prima la sintassi header, poi :cbor-nonminimal sul lead prima di contesto,
nodi, depth o payload/UTF8; radice conclusa controlla :cbor-trailing senza leggere coda.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED di preflight senza mutare lo spazio; reset prima
del singolo attraversamento, scratch riusabile dopo errore runtime. Propaga anche
CORRUPTION-DETECTED e INVARIANT-VIOLATION; nessuna semantica tag, ordine o deduplica mappe.
Buffer immutabile, float/u64 solo parole; lavoro bounded, nessuna attesa/I/O."
  (verifica-struttura-cbor-interna buffer start end space max-bytes max-nodes max-depth t))
