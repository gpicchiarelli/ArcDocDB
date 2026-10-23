;;; OWNER: recovery confronta due manifest completi e immutabili prima di qualunque effetto.
;;; SHARED: sole letture delle tabelle possedute; nessun lock o pubblicazione tra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function (manifest u64 manifest-closed) null) verifica-chiuso-conservato))
(defun verifica-chiuso-conservato (current id previous-entry)
  "Pre: manifest completi e stabili. Post: CLOSED conserva lunghezza ed esiti esattamente uguali.
INVALID-ARGUMENT al primo disaccordo; presenza distinta da CSN zero, u64 senza troncamento.
Ciclo limitato al numero di esiti della entry già verificata; nessuna modifica o I/O."
  (multiple-value-bind (state size count) (trova-segmento current id)
    (unless (and (eq state :closed) (= size (%closed-valid-bytes previous-entry))
                 (= count (hash-table-count (%closed-outcomes previous-entry))))
      (error 'invalid-argument :reason :recovery-closed-changed)))
  (loop for txid being the hash-keys of (%closed-outcomes previous-entry) using (hash-value expected)
        do (multiple-value-bind (present csn) (trova-esito-chiusura current id txid)
             (unless (and present (= csn expected))
               (error 'invalid-argument :reason :recovery-outcome-changed))))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-FOR-003 REQ-AFF-018
(declaim (ftype (function (manifest manifest) null) verifica-forma-transizione-recovery))
(defun verifica-forma-transizione-recovery (previous current)
  "Pre: manifest ricostruiti, recovery esclusivo senza compaction. Post: nuovo ID e sola chiusura del vecchio ACTIVE.
RESOURCE-EXHAUSTED per ID esauriti; INVALID-ARGUMENT per riuso, ACTIVE perso o cardinalità diversa.
Non valida i byte/esiti del vecchio ACTIVE: provengono dalla sua scansione autorevole."
  (multiple-value-bind (available next) (prossimo-id-segmento previous)
    (unless available (error 'resource-exhausted :reason :recovery-segment-ids))
    (unless (>= (segmento-attivo current) next)
      (error 'invalid-argument :reason :recovery-active-reused)))
  (unless (eq (nth-value 0 (trova-segmento current (segmento-attivo previous))) :closed)
    (error 'invalid-argument :reason :recovery-active-not-closed))
  (unless (and (= (numero-segmenti-chiusi current) (1+ (numero-segmenti-chiusi previous)))
               (= (numero-segmenti-rimossi current) (numero-segmenti-rimossi previous)))
    (error 'invalid-argument :reason :recovery-segment-counts))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(declaim (ftype (function (manifest manifest) null) verifica-transizione-recovery))
(defun verifica-transizione-recovery (previous current)
  "Pre: manifest completi immutabili, nuovo checkpoint chiude ACTIVE senza CLEAN/MERGE o reclaim.
Post: conserva tutti CLOSED con lunghezze/esiti e tutti REMOVED, chiude ACTIVE, apre ID mai riusato.
Numero CLOSED cresce esattamente di uno; nessun altro segmento può essere inserito/omesso.
Errori di transizione tipizzati prima di I/O; non prova inventario, catalogo o dati del vecchio ACTIVE.
Cicli limitati ai conteggi CLOSED/REMOVED e agli esiti già verificati dei manifest; zero effetti durevoli."
  (verifica-forma-transizione-recovery previous current)
  (loop for id being the hash-keys of (%manifest-closed previous) using (hash-value entry)
        do (verifica-chiuso-conservato current id entry))
  (loop for id being the hash-keys of (%manifest-removed previous)
        do (unless (eq (nth-value 0 (trova-segmento current id)) :removed)
             (error 'invalid-argument :reason :recovery-removed-changed)))
  ;; Un secondo controllo locale non promuove le precondizioni di stabilità a una prova concorrente.
  (verifica-forma-transizione-recovery previous current)
  nil)
