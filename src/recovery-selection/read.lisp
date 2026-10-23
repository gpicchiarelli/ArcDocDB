;;; OWNER: il worker consegna scalari soltanto dopo aver considerato l'intero insieme autorevole della chiave.
;;; SHARED: nessun accesso agli array interni o pubblicazione di tombstone nell'indice dei vivi.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata)
                         (values (member :none :put :tombstone) u64 u64 index index (member 1 2) u8 &optional))
                leggi-versione-selezionata))
(defun leggi-versione-selezionata (selector)
  "Pre: chiave inizializzata, worker esclusivo; completezza dei candidati attestata fuori dal selettore.
Post: tipo, CSN effettivo, segment-id, offset fisico, lunghezza, versione e flag; NONE/0/0/0/0/2/0 se vuoto.
AMBIGUOUS rifiutato, FAULTED mai riaperto; scalari non sono un pin o prova di ammissione del traffico.
TOMBSTONE deve sopprimere la chiave solo alla fine; nessun array, body o riferimento al buffer esportato."
  (esigi-selettore-pronto selector)
  (when (eq (selection-state selector) :ambiguous)
    (error 'invalid-argument :reason :recovery-selection-ambiguous))
  (when (eq (selection-state selector) :ready)
    (return-from leggi-versione-selezionata (values :none 0 0 0 0 2 0)))
  (verifica-tupla-selezione selector (selection-current selector))
  (let* ((words (selection-current selector)) (tag (aref words 4))
         (kind (ldb (byte 8 0) tag)) (version (ldb (byte 8 16) tag)))
    (values (if (= kind +put+) :put :tombstone) (aref words 0) (aref words 1)
            (aref words 2) (aref words 3) version (ldb (byte 8 8) tag))))
