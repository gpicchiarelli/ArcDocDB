;;; OWNER: coordinatore esclusivo prima di pubblicare fonti/indice e ammettere richieste.
;;; SHARED: directory nuova privata; nessuna radice, contatore o capacità del caller mutata.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-IDX-001 REQ-CMP-007 REQ-MVC-007 REQ-AFF-008
(declaim (ftype (function (archivio-recovery arcdocdb.get:vista-get-serie
                          arcdocdb.control:control-recuperato t t
                          &key (:max-segmenti t) (:budget-payload t))
                         arcdocdb.get.directory:directory-get-serie) adotta-directory-closed))
(defun adotta-directory-closed (archive view control closed maps
                               &key (max-segmenti 65536) (budget-payload 1310720))
  "Pre: bootstrap esclusivo, catalogo/fonti autorevoli e congelati; runtime già canonico.
CLOSED e MAPS paralleli, completi per CONTROL, ordinati per ID; owner fisico mantiene tutti i FD.
Post: directory nel nuovo scope, wrapper propri e righe readonly condivise; input non trattenuti.
Budget/autorità/insieme/metadati verificati prima dei wrapper. Errori tipizzati senza risultati parziali.
Nessun I/O, close, CSN o punto durevole: pubblicazione, primary e ammissione restano al coordinatore."
  (let* ((count (verifica-budget-closed-runtime closed maps max-segmenti budget-payload))
         (old (verifica-autorita-closed-runtime archive view control))
         (previous 0))
    (declare (type u32 previous))
    (arcdocdb.recovery.closed:verifica-closed-completi control closed :max-segmenti max-segmenti)
    (dotimes (i count)
      (setf previous (verifica-mappa-closed-runtime old (svref closed i) (svref maps i) previous)))
    (let ((owned (make-array count :initial-element nil)))
      (dotimes (i count)
        (setf (svref owned i) (trasferisci-mappa-closed-runtime view (svref maps i))))
      (let ((result (arcdocdb.get.directory:crea-directory-get-serie
                     view owned :max-segments max-segmenti
                     :budget-payload (* count arcdocdb.get.directory::+directory-entry-bytes+))))
        (unless (= count (arcdocdb.get.directory:conta-segmenti-directory-get result))
          (error 'invariant-violation :reason :runtime-closed-directory-result))
        (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
        result))))
