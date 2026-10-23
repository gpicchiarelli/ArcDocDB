;;; OWNER: il worker confronta e copia solo tuple private della stessa chiave.
;;; SHARED: selettori distinti lavorano in parallelo; nessun aggiornamento dell'indice pubblico.
(in-package #:arcdocdb.recovery.selection)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata)
                         (member :selected :kept :duplicate :ambiguous)) confronta-versioni-recuperate))
(defun confronta-versioni-recuperate (selector)
  "Pre: tuple verificate di una chiave. Post: massimo CSN; a parita, offset maggiore nello stesso segmento.
CSN uguale in segmenti diversi o metadata discordanti alla stessa location => AMBIGUOUS.
Nessun ordinamento per segment-id, assunzione di lineage o uguaglianza del body dedotta dai CRC."
  (verifica-tupla-selezione selector (selection-current selector))
  (verifica-tupla-selezione selector (selection-candidate selector))
  (let ((current (selection-current selector)) (candidate (selection-candidate selector)))
    (cond ((> (aref candidate 0) (aref current 0)) :selected)
          ((< (aref candidate 0) (aref current 0)) :kept)
          ((/= (aref candidate 1) (aref current 1)) :ambiguous)
          ((> (aref candidate 2) (aref current 2)) :selected)
          ((< (aref candidate 2) (aref current 2)) :kept)
          ((loop for i from 3 below +selection-words+ always (= (aref current i) (aref candidate i))) :duplicate)
          (t :ambiguous))))

;;; REQ: REQ-REC-001 REQ-IDX-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata) null) adotta-candidato-recuperato))
(defun adotta-candidato-recuperato (selector)
  "Pre: candidato verificato e vincente. Post: tuple copiata; ambiguita precedente conservata salvo CSN maggiore.
Interruzione della copia => FAULTED terminale; nessuna consegna di una tupla parziale."
  (esigi-selettore-pronto selector)
  (verifica-tupla-selezione selector (selection-candidate selector))
  (let* ((current (selection-current selector)) (candidate (selection-candidate selector))
         (ambiguous (and (eq (selection-state selector) :ambiguous) (= (aref current 0) (aref candidate 0))))
         (complete nil))
    (unwind-protect
         (progn
           (replace current candidate)
           (setf (selection-state selector) (if ambiguous :ambiguous :selected))
           (unless (equalp current candidate)
             (error 'invariant-violation :reason :recovery-selection-copy))
           (setf complete t))
      (unless complete (setf (selection-state selector) :faulted))))
  nil)

;;; REQ: REQ-REC-001 REQ-IDX-001 REQ-IDX-006 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (selettore-versione-recuperata octets index index u64 index
                          &key (:version integer) (:prepared-csn (or null u64)))
                         (member :selected :kept :duplicate :ambiguous)) considera-record-recuperato))
(defun considera-record-recuperato (selector buffer start end segment offset &key (version 2) (prepared-csn nil))
  "Pre: worker esclusivo; solo record committed della chiave, prefissi canonici e file immutabili.
OFFSET assoluto nel file, distinto da START nel buffer; prepared richiede CSN dalla risoluzione autorevole.
Post: vincitore provvisorio PUT/TOMBSTONE indipendente dall'ordine, oppure AMBIGUOUS senza risultato consegnabile.
Ambiguita risolta solo da CSN strettamente maggiore o abbandono esplicito della chiave.
CRC/forma/range errati non modificano il vincitore; nessun I/O, CSN allocato o indice pubblicato."
  (prepara-candidato-recuperato selector buffer start end segment offset version prepared-csn)
  (let ((result (if (eq (selection-state selector) :ready) :selected
                    (confronta-versioni-recuperate selector))))
    (case result
      (:selected (adotta-candidato-recuperato selector))
      (:ambiguous (setf (selection-state selector) :ambiguous))
      ((:kept :duplicate) nil)
      (otherwise
       (setf (selection-state selector) :faulted)
       (error 'invariant-violation :reason :recovery-selection-result)))
    (if (eq (selection-state selector) :ambiguous) :ambiguous result)))
