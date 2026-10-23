;;; OWNER: recovery esclusivo della Serie mantiene input e vista canonici fino alla pubblicazione.
;;; SHARED: manifest posseduto immutabile; nessun buffer o stato tra Serie.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-008
(defstruct (control-recuperato
             (:constructor %make-control-recuperato (view input manifest size prefix status version)) (:copier nil))
  "Pre: file readonly letto fino all'EOF attestato dal caller; header e prefisso EDIT verificati.
Post: legami canonici e manifest posseduto, senza alias al buffer di lettura.
Non attesta il catalogo, la misura fisica di EOF, l'inventario o il prefisso dei segmenti."
  (view nil :type arcdocdb.get:vista-get-serie :read-only t)
  (input nil :type file-io :read-only t)
  (manifest nil :type arcdocdb.recovery.manifest::manifest :read-only t)
  (size 0 :type index :read-only t)
  (prefix 0 :type index :read-only t)
  (status :complete :type (member :complete :tail) :read-only t)
  (version 2 :type (member 1 2) :read-only t))

;;; REQ: REQ-REC-001 REQ-AFF-009
(declaim (ftype (function (control-recuperato)
                         (values index index (member :complete :tail) (member 1 2) &optional))
                frontiere-control-recuperato))
(defun frontiere-control-recuperato (recovered)
  "Pre: risultato completo. Post: EOF attestato, prefisso assoluto, stato e formato del file letto.
Nessun buffer, FD numerico o prova di salute corrente; TYPE-ERROR per tipi invalidi."
  (values (control-recuperato-size recovered) (control-recuperato-prefix recovered)
          (control-recuperato-status recovered) (control-recuperato-version recovered)))

;;; REQ: REQ-REC-001 REQ-FOR-003
(declaim (ftype (function (control-recuperato) arcdocdb.recovery.manifest::manifest)
                manifest-control-recuperato))
(defun manifest-control-recuperato (recovered)
  "Pre: risultato completo. Post: manifest posseduto del prefisso sigillato, da consultare tramite query.
Nessuna tabella esposta o conferma di presenza/integrità dei segmenti nominati."
  (control-recuperato-manifest recovered))
