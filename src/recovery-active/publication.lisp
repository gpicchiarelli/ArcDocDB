;;; OWNER: recovery mantiene vecchio ACTIVE, control log e namespace fino alla fine del publisher.
;;; SHARED: confronto in sola lettura, unico gettone nel publisher canonico; nessun lock tra Serie.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-003 REQ-AFF-001
(declaim (ftype (function (control-preparato active-recuperato) null) verifica-chiusura-active))
(defun verifica-chiusura-active (prepared recovered)
  "Pre: recovery esclusivo senza mutazioni dei file o namespace; inventario già riconciliato.
Post: checkpoint chiude il vecchio ACTIVE esattamente a P, con tutti e soli gli esiti derivati.
INVALID-ARGUMENT per lunghezza/stato/esiti, IO-FAULT per FD chiuso; nessun claim o syscall."
  (arcdocdb.io::esigi-aperto (arcdocdb.get::segmento-get-file (active-recuperato-segment recovered)) :input)
  (let ((manifest (manifest-control-preparato prepared)) (id (id-active-recuperato recovered))
        (ids (active-recuperato-ids recovered)) (csns (active-recuperato-csns recovered)))
    (unless (= (length ids) (length csns)) (error 'invariant-violation :reason :active-recovery-closure-shape))
    (multiple-value-bind (state prefix count) (trova-segmento manifest id)
      (unless (and (eq state :closed) (= prefix (active-recuperato-prefix recovered)) (= count (length ids)))
        (error 'invalid-argument :reason :active-recovery-closure)))
    (dotimes (i (length ids))
      (multiple-value-bind (present csn) (trova-esito-chiusura manifest id (aref ids i))
        (unless (and present (= csn (aref csns i)))
          (error 'invalid-argument :reason :active-recovery-closure-outcome)))))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-AFF-001 REQ-AFF-018
(declaim (ftype (function (control-preparato active-recuperato) control-pubblicato) pubblica-control-da-active))
(defun pubblica-control-da-active (prepared recovered)
  "Pre: pool I/O, recovery esclusivo; inventario/CLOSED verificati, file e tabella originaria autorevoli.
Post: chiusura da scanner/esiti e transizione conservativa verificate, publisher unico completato.
Punto di atomicità: rinomina del control log; conferma solo dopo fsync parent del publisher canonico.
Rifiuti prima del claim non pubblicano; dopo, errori originali e stato FAULTED del publisher.
Non decide dimenticabilità globale, ricostruisce indici o ammette traffico sulla Serie."
  (verifica-chiusura-active prepared recovered)
  (pubblica-control-validato prepared (active-recuperato-control recovered)))
