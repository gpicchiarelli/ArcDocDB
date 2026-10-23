;;; OWNER: I/O costruisce il risultato completo; il controller adotta un solo log.
;;; SHARED: wrapper immutabile prima dei compiti, senza buffer o puntatori nativi.
(in-package #:arcdocdb.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-AFF-001 REQ-STO-003
(defstruct (segmento-attivo-preparato
             (:constructor %make-segmento-attivo-preparato (log segment association)) (:copier nil))
  "Pre: nuovo header writer durevole, riletto e uguale; directory sincronizzata dal proprietario.
Post: tre riferimenti immutabili, senza trattenere buffer; nessun EDIT o ACTIVE pubblicato.
Il caller conserva le capacità e adotta un solo controller per log, dopo la decisione del catalogo."
  (log nil :type log-io :read-only t)
  (segment nil :type segmento-get :read-only t)
  (association nil :type associazione-file :read-only t))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(declaim (ftype (function (segmento-attivo-preparato) log-io) log-segmento-attivo-preparato))
(defun log-segmento-attivo-preparato (prepared)
  "Pre: risultato completo, capacità ancora possedute. Post: log canonico per un solo controller.
Non certifica salute corrente, pubblicazione nel catalogo o durata dei reader."
  (segmento-attivo-preparato-log prepared))
