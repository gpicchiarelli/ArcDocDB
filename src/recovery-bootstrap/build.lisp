;;; OWNER: un compito I/O di bootstrap mantiene gli insiemi aperti; output privati fino all'ultimo gate.
;;; SHARED: nessun binding runtime o pubblicazione; il piano canonico usa tutte le DECISION.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-TXM-005 REQ-TXM-007 REQ-MVC-006 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate t t t octets index
                          &key (:max-segmenti-totali index) (:budget-riferimenti index))
                         (values piano-csn-archivio simple-vector simple-vector &optional)) leggi-archivio-recuperato))
(defun leggi-archivio-recuperato (set decisions controls sources limits scratch max-byte-totali
                                &key (max-segmenti-totali 1048576) (budget-riferimenti 16777216))
  "Pre: tutte le Serie autorevoli del catalogo incluse; sorgenti/vettori/namespace congelati e FD mantenuti aperti.
CONTROLS/SOURCES/LIMITS paralleli alle viste; budget byte esplicito; scratch esclusivo nel pool I/O.
Post: piano CSN completo, vettore ACTIVE e vettori CLOSED posseduti, nel medesimo ordine canonico.
Tutti i preflight prima dei dati; piano e risultati consegnati solo dopo il gate completo dell'Archivio.
Errori originali senza close/retry/risultati parziali; scratch modificabile, set ancora del chiamante.
Nessun nuovo CSN, punto durevole, binding runtime, pubblicazione degli indici o ammissione."
  (multiple-value-bind (count segments)
      (verifica-bootstrap-archivio set decisions controls sources limits scratch max-byte-totali
                                  max-segmenti-totali budget-riferimenti)
    (let ((active (make-array count :initial-element nil)) (closed (make-array count :initial-element nil)))
      (dotimes (i count)
        (multiple-value-bind (a c)
            (leggi-serie-recuperata (the control-recuperato (svref controls i))
                                   (the recovery-sources (svref sources i)) decisions scratch
                                   (the limiti-recovery-serie (svref limits i)))
          (setf (svref active i) a (svref closed i) c)))
      (let ((plan (crea-piano-csn-archivio set decisions active closed
                   :max-segmenti-serie max-segmenti-totali :max-segmenti-totali max-segmenti-totali)))
        (multiple-value-bind (actual-series actual-segments) (statistiche-piano-csn-archivio plan)
          (unless (and (= actual-series count) (= actual-segments segments))
            (error 'invariant-violation :reason :archive-bootstrap-result-count)))
        (values plan active closed)))))
