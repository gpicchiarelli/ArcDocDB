;;; OWNER: publisher osserva durante il compito; controller legge soltanto dopo consegna/join.
;;; SHARED: osservazioni scalari, nessun nuovo permesso concorrente o prova di salute corrente.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(declaim (ftype (function (control-preparato)
                         (values (member :prepared :publishing :published :faulted) boolean &optional))
                stato-pubblicazione-control))
(defun stato-pubblicazione-control (prepared)
  "Pre: proprietario o controller dopo join. Post: stato e successo rename osservato al confine.
NIL non prova assenza di effetti: FAULTED richiede sempre nuova riconciliazione autorevole.
Non è una fotografia concorrente dei due slot o autorizzazione a ritentare/chiudere/eliminare."
  (values (control-preparato-publication-state prepared) (control-preparato-rename-observed prepared)))

;;; REQ: REQ-WAL-002 REQ-REC-001
(declaim (ftype (function (control-pubblicato) log-io) log-control-pubblicato))
(defun log-control-pubblicato (published)
  "Pre: risultato di pubblicazione completato. Post: log canonico del nuovo control.log.
Non attesta salute corrente o la quiescenza del vecchio log; caller mantiene ownership."
  (control-preparato-log (control-pubblicato-prepared published)))

;;; REQ: REQ-REC-001
(declaim (ftype (function (control-pubblicato) arcdocdb.recovery.manifest::manifest) manifest-control-pubblicato))
(defun manifest-control-pubblicato (published)
  "Pre: risultato completo. Post: manifest del checkpoint installato; query in sola lettura.
Inventario, indici e decisioni multiserie devono ancora essere riconciliati dal recovery."
  (control-preparato-manifest (control-pubblicato-prepared published)))

;;; REQ: REQ-REC-001 REQ-STO-003
(declaim (ftype (function (control-pubblicato) segmento-attivo-preparato) active-control-pubblicato))
(defun active-control-pubblicato (published)
  "Pre: risultato completo. Post: dipendenza ACTIVE canonica nominata dal checkpoint installato.
Non crea controller o pubblica una root GET; adozione e gate del recovery restano al caller."
  (control-preparato-active (control-pubblicato-prepared published)))
