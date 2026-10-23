(in-package #:arcdocdb.fulltext.index)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (t &key (:max-work t)) keyword) sigilla-indice-posizionale))
(defun sigilla-indice-posizionale (run &key (max-work 268435456))
  "Pre: run BUILDING, campi interamente copiati. Post: avvia ordinamento riprendibile.
Il limite include copia gia svolta. Non rende durevole o READY un indice di Serie.
INVALID-ARGUMENT per stato/limite, RESOURCE-EXHAUSTED per budget gia consumato."
  (unless (and (typep run 'indice-posizionale) (eq :building (indice-posizionale-state run))
               (typep max-work 'index) (plusp max-work))
    (error 'invalid-argument :reason :fulltext-index-seal))
  (when (< max-work (indice-posizionale-work run))
    (error 'resource-exhausted :reason :fulltext-index-work))
  (setf (indice-posizionale-work-limit run) max-work (indice-posizionale-state run) :heap-build
        (indice-posizionale-heap run) (floor (indice-posizionale-count run) 2)
        (indice-posizionale-heap-end run) (indice-posizionale-count run))
  :running)

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (t t) keyword) passo-indice-posizionale))
(defun passo-indice-posizionale (run quantum)
  "Pre: run esclusivo, quantum 1..65536. Post: BUILDING, RUNNING oppure SEALED.
Un passo copia un byte/record o ripara un heap di profondita massima 32.
Errore di dominio: FAILED e rilascio del prestito SOURCE, nessuna query ammessa."
  (unless (and (typep run 'indice-posizionale) (typep quantum '(integer 1 65536)))
    (error 'invalid-argument :reason :fulltext-index-step))
  (when (eq :failed (indice-posizionale-state run)) (error 'invalid-argument :reason :fulltext-index-failed))
  (handler-case
      (dotimes (i quantum)
        (when (member (indice-posizionale-state run) '(:building :sealed)) (return))
        (consuma-lavoro-indice run)
        (case (indice-posizionale-state run)
          (:copying (copia-passo-full-text run))
          ((:heap-build :heap-sort) (ordina-passo-full-text run))
          (otherwise (error 'invariant-violation :reason :fulltext-index-phase))))
    (arcdocdb-error (condition)
      (setf (indice-posizionale-state run) :failed (indice-posizionale-source run) nil)
      (error condition)))
  (case (indice-posizionale-state run)
    (:building :building) (:sealed :sealed) (otherwise :running)))
