;;; OWNER: un solo coordinatore del bootstrap; massimo e contatori esclusivi della chiamata.
;;; SHARED: tutte le Serie lette, nessun contatore CSN, lock o stato runtime modificato.
(in-package #:arcdocdb.recovery.archive.csn)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate simple-vector simple-vector
                          &key (:max-segmenti-serie index) (:max-segmenti-totali index)) piano-csn-archivio)
                crea-piano-csn-archivio))
(defun crea-piano-csn-archivio (set decisions active closed
                              &key (max-segmenti-serie 65536) (max-segmenti-totali 1048576))
  "Pre: catalogo completo, recovery esclusivo di tutte le Serie concluso; fonti e vettori congelati.
ACTIVE e vettore CLOSED per ogni vista, nel medesimo ordine dell'insieme canonico.
Post: massimo di tutte le Serie e di tutte le DECISION, dopo autorità, budget e insieme CLOSED verificati.
Propaga condizioni tipizzate senza retry; nessun risultato parziale, I/O, registro o ammissione."
  (let ((segments (verifica-piano-csn-preflight set decisions active closed
                                               max-segmenti-serie max-segmenti-totali))
        (views (insieme-serie-recovery-views set)))
    (multiple-value-bind (present maximum) (massimo-csn-decisioni-recuperate decisions)
      (let ((consumed 0))
        (dotimes (i (length views))
          (let ((recovered (the active-recuperato (aref active i)))
                (sources (the simple-vector (aref closed i))))
            (verifica-origine-active-csn (the vista-get-serie (aref views i)) decisions recovered)
            (multiple-value-bind (found csn)
                (massimo-csn-serie-recuperata recovered sources :max-segmenti max-segmenti-serie)
              (when found (setf present t maximum (max maximum csn))))
            (incf consumed (1+ (length sources)))))
        (unless (and (= consumed segments) (or present (zerop maximum)))
          (error 'invariant-violation :reason :archive-csn-result)))
      (arcdocdb.io::esigi-aperto (arcdocdb.recovery.archive::decisioni-recuperate-input decisions) :input)
      (%make-piano-csn-archivio (insieme-serie-recovery-archive set) (length views)
                               segments present maximum))))
