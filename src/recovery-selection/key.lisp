;;; OWNER: il worker copia la chiave una volta; il buffer esterno puo essere riusato al ritorno.
;;; SHARED: nessuna identita di chiave o risultato passa fra worker tramite questo oggetto.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-LIM-003 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata octets index index) null)
                inizializza-chiave-recuperata))
(defun inizializza-chiave-recuperata (selector key start end)
  "Pre: worker esclusivo, precedente chiave terminata o abbandonata esplicitamente; span stabile.
Post: copia privata della chiave, nessun vincitore e tuple azzerate; nessun array per nuova chiave.
Rifiuti di stato/range/budget prima delle mutazioni; interruzione della copia => FAULTED terminale."
  (when (eq (selection-state selector) :faulted)
    (error 'invalid-argument :reason :recovery-selection-state))
  (check-range key start end)
  (unless (<= 1 (- end start) +max-key-bytes+)
    (error 'invalid-argument :reason :recovery-selection-key-length))
  (when (> (- end start) (length (selection-key selector)))
    (error 'resource-exhausted :reason :recovery-selection-key-capacity))
  (let ((complete nil))
    (unwind-protect
         (progn
           (replace (selection-key selector) key :start2 start :end2 end)
           (fill (selection-current selector) 0) (fill (selection-candidate selector) 0)
           (setf (selection-length selector) (- end start) (selection-state selector) :ready)
           (esigi-selettore-pronto selector)
           (setf complete t))
      (unless complete (setf (selection-state selector) :faulted))))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata octets index index) boolean)
                chiave-selezione-uguale-p))
(defun chiave-selezione-uguale-p (selector buffer start end)
  "Pre: span candidato verificato dal codec, chiave inizializzata. Post: confronto binario esatto senza copia.
Nessuna normalizzazione, hash o confronto del solo prefisso; ciclo entro la capacita della chiave."
  (and (= (- end start) (selection-length selector))
       (loop for i below (selection-length selector)
             always (= (aref (selection-key selector) i) (aref buffer (+ start i))))))
