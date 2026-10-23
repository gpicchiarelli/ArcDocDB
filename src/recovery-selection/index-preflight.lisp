;;; OWNER: il writer di bootstrap possiede selettore, indice e due scratch distinti.
;;; SHARED: sola preparazione del payload privato; nessuna pubblicazione o coordinamento fra Serie.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (u64 u64 index index) null) verifica-location-indice-recuperata))
(defun verifica-location-indice-recuperata (csn segment offset bytes)
  "Pre: vincitore PUT verificato. Post: CSN positivo e location rappresentabile nel primary v2/GET corrente.
INVALID-ARGUMENT per CSN zero, ID non positivo u32, offset/fine oltre u32; nessun troncamento o effetto.
Sono limiti del destinatario, non nuovi limiti del reader o dei segment-id u64 del recovery."
  (unless (plusp csn) (error 'invalid-argument :reason :recovery-index-csn))
  (unless (<= 1 segment #xffffffff) (error 'invalid-argument :reason :recovery-index-segment-id))
  (unless (and (<= offset #xffffffff) (<= (+ offset bytes) #xffffffff))
    (error 'invalid-argument :reason :recovery-index-location))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata contenuto-slot
                          (member :none :put :tombstone) u64 u64 index index) null)
                prepara-payload-indice-recuperato))
(defun prepara-payload-indice-recuperato (selector source kind csn segment offset bytes)
  "Pre: lettura del selettore riuscita, contesto libero e SOURCE distinta; chiave completa attestata dal caller.
Post: payload vivo v2 per PUT, cinque zeri per NONE/TOMBSTONE; nessun indice modificato.
Compatibilita prima delle scritture; incoerenza privata => selettore FAULTED, no payload consegnabile."
  (case kind
    (:put
     (verifica-location-indice-recuperata csn segment offset bytes)
     (setf (aref source 0) csn (aref source 1) (logior (ash segment 32) offset)
           (aref source 2) (logior (ash (selection-length selector) 32) (ash 1 48))
           (aref source 3) bytes (aref source 4) 0)
     (unless (arcdocdb.index.slots::contenuto-vivo-valido-p
              (aref source 0) (aref source 1) (aref source 2) (aref source 3) (aref source 4) nil)
       (guasto-selettore selector :recovery-index-payload)))
    ((:none :tombstone) (fill source 0))
    (otherwise (guasto-selettore selector :recovery-index-kind)))
  nil)
