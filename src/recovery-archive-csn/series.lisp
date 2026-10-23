;;; OWNER: vettore e tabella UUID privati durante il bootstrap esclusivo, nessun mutamento delle viste.
;;; SHARED: legge l'ambito canonico dell'Archivio; nessuna struttura sul percorso delle richieste.
(in-package #:arcdocdb.recovery.archive.csn)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (archivio-recovery vista-get-serie simple-vector index index)
                         insieme-serie-recovery) copia-serie-recovery))
(defun copia-serie-recovery (archive registri views count budget)
  "Pre: count positivo entro budget prima dell'allocazione, elenco stabile e autorevole del catalogo.
Post: copia completa, stesso ambito, UUID unici e Registri presente per EQ esattamente una volta.
INVALID-ARGUMENT per ambito/UUID/Registri, INVARIANT-VIOLATION per cardinalità; nessun I/O."
  (unless (and (= count (length views)) (plusp count) (<= (* 8 count) budget))
    (error 'invariant-violation :reason :archive-csn-series-preflight))
  (let ((owned (copy-seq views)) (seen (make-hash-table :test 'equalp :size count)) (found nil))
    (loop for item across owned
          do (let ((view (the vista-get-serie item)))
               (unless (eq (arcdocdb.get::vista-get-serie-scope view)
                           (arcdocdb.recovery.archive::archivio-recovery-scope archive))
                 (error 'invalid-argument :reason :archive-csn-series-scope))
               (let ((identity (arcdocdb.get::vista-get-serie-identity view)))
                 (when (gethash identity seen)
                   (error 'invalid-argument :reason :archive-csn-series-duplicate))
                 (setf (gethash identity seen) view))
               (when (eq view registri) (setf found t))))
    (unless found (error 'invalid-argument :reason :archive-csn-registri-missing))
    (unless (= (hash-table-count seen) count)
      (error 'invariant-violation :reason :archive-csn-series-count))
    (%make-insieme-serie-recovery archive owned)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (archivio-recovery vista-get-serie simple-vector
                          &key (:max-series index) (:budget-riferimenti index)) insieme-serie-recovery)
                crea-insieme-serie-recovery))
(defun crea-insieme-serie-recovery (archive registri views &key (max-series 65536) (budget-riferimenti 524288))
  "Pre: bootstrap canonico, tutte le Serie del catalogo incluse, ruolo Registri attestato dal controller.
Post: copia immutabile per il calcolo del CSN; ordine del catalogo conservato, nessun vettore esportato.
INVALID-ARGUMENT sul vuoto; RESOURCE-EXHAUSTED prima di copia/tabella. Budget 8*N byte di riferimenti,
esclude hash table, header Lisp, viste già esistenti e GC; non è un tetto RSS."
  (let ((count (length views)))
    (when (zerop count) (error 'invalid-argument :reason :archive-csn-series-empty))
    (when (or (> count max-series) (> (* 8 count) budget-riferimenti))
      (error 'resource-exhausted :reason :archive-csn-series-budget))
    (copia-serie-recovery archive registri views count budget-riferimenti)))
