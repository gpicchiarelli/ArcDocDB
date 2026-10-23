;;;; Scelta priva di effetti: nessun ID fisico osservato può essere riutilizzato.
;;; OWNER: controller esclusivo possiede manifest/inventario fino alla creazione del temporaneo.
;;; SHARED: piano privato; sole letture, nessun lock o contatore fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (u64 u64 u64 u64) null) verifica-id-segmento-recovery))
(defun verifica-id-segmento-recovery (minimum maximum candidate next)
  "Pre: proposta e frontiere u64. Post: ID fresco, high-water positivo e successore esatto.
INVARIANT-VIOLATION per incoerenza privata; nessuna mutazione o prenotazione."
  (unless (and (plusp minimum) (>= candidate minimum) (> candidate maximum))
    (error 'invariant-violation :reason :recovery-segment-id-frontier))
  (unless (= next (1+ candidate))
    (error 'invariant-violation :reason :recovery-segment-id-successor))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest reconciliation-plan)
                         (values u64 u64 reconciliation-plan &optional)) proponi-id-segmento-da-piano))
(defun proponi-id-segmento-da-piano (manifest plan)
  "Pre: manifest autorevole e suo piano canonico completo, ordinato e posseduto dal caller esclusivo.
Post: proposta >= high-water e oltre i nomi, successore u64 e stesso piano; nessun I/O o prenotazione.
RESOURCE-EXHAUSTED per ID esauriti; INVARIANT-VIOLATION per piano vuoto o frontiere private incoerenti.
Solo le due API di inventario costruiscono il piano; non ricostruire i nomi dalle azioni."
  (let ((count (numero-azioni-riconciliazione plan)))
    (multiple-value-bind (available minimum) (prossimo-id-segmento manifest)
      (unless available (error 'resource-exhausted :reason :recovery-segment-id-exhausted))
      (unless (plusp count) (error 'invariant-violation :reason :recovery-segment-id-empty-plan))
      (multiple-value-bind (maximum form action state) (azione-riconciliazione plan (1- count))
        (declare (ignore form action state)) ; fatti validati dal planner, nessun esito d'errore.
        (let* ((candidate (max minimum (1+ maximum))) (next (1+ candidate)))
          (unless (typep next 'u64)
            (error 'resource-exhausted :reason :recovery-segment-id-exhausted))
          (verifica-id-segmento-recovery minimum maximum (the u64 candidate) next)
          (values candidate next plan))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest simple-vector
                          &key (:max-files integer) (:max-segmenti integer))
                         (values u64 u64 reconciliation-plan &optional)) scegli-id-segmento-recovery))
(defun scegli-id-segmento-recovery (manifest files &key (max-files 65536) (max-segmenti 65536))
  "Pre: recovery esclusivo, manifest autorevole e inventario completo/stabile fino al nuovo temporaneo.
Post: proposta >= high-water e oltre tutti i nomi, successore u64 e piano posseduto; nessun I/O.
Non riserva ID, modifica manifest, risolve anomalie o ammette traffico; nessun punto atomico durevole.
Errori del planner propagati, RESOURCE-EXHAUSTED per ID esauriti, INVARIANT-VIOLATION per forma privata.
Budget verificati dal planner prima della scelta; percorso freddo con allocazioni, senza nuovi lock."
  (proponi-id-segmento-da-piano manifest
    (pianifica-riconciliazione manifest files :max-files max-files :max-segmenti max-segmenti)))
