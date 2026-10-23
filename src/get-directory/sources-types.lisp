;;; OWNER: writer locale prepara il contenuto immutabile prima dell'adozione WAL.
;;; SHARED: fonti raggiungibili dal SOLO CAS esistente del controller Serie.
(in-package #:arcdocdb.get.directory)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-008
(defstruct (fonti-get-serie (:constructor %make-fonti-get-serie (directory content)) (:copier nil))
  "Pre: directory CLOSED verificata e contenuto caller immutabile.
Post: due riferimenti immutabili; nessun indice, FD o array duplicato.
Il controller conserva tutte le fonti necessarie ai candidati dei reader già ammessi."
  (directory nil :type directory-get-serie :read-only t)
  (content nil :type t :read-only t))

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-CMP-007
(declaim (ftype (function (directory-get-serie &key (:content t)) fonti-get-serie) crea-fonti-get-serie)
         (ftype (function (fonti-get-serie) t) contenuto-fonti-get-serie))
(defun crea-fonti-get-serie (directory &key (content nil))
  "Pre: directory completa, contenuto/grafo immutabili fino all'ultimo reader.
Post: contenitore privato pronto come root CLOSED oppure content di root ACTIVE.
TYPE-ERROR per directory estranea al tipo; non pubblica, non certifica lifetime/manifest."
  (%make-fonti-get-serie directory content))

;;; REQ: REQ-IDX-001 REQ-WAL-006
(defun contenuto-fonti-get-serie (sources)
  "Pre: fonti preparate oppure acquisite sotto EBR. Post: contenuto originale del caller.
Non prova pubblicazione, immutabilità del grafo esterno o quiescenza per reclaim."
  (fonti-get-serie-content sources))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (directory-get-serie u32) boolean) contiene-segmento-directory-get))
(defun contiene-segmento-directory-get (directory id)
  "Pre: directory canonica immutabile. Post: presenza dell'ID con al più diciassette pivot.
Usata per respingere ACTIVE duplicato in CLOSED; nessuna allocazione, I/O o ricerca di riga.
Geometria/convergenza impossibili INVARIANT-VIOLATION; il caller applica il proprio fail-stop."
  (let ((ids (directory-get-serie-ids directory)) (left 0) (right (conta-segmenti-directory-get directory)))
    (declare (type index left right))
    (unless (and (= right (length (directory-get-serie-maps directory))) (<= right +directory-max-segments+))
      (error 'invariant-violation :reason :directory-shape))
    (loop repeat +directory-search-attempts+
          do (when (= left right) (return-from contiene-segmento-directory-get nil))
             (let* ((middle (+ left (floor (- right left) 2))) (actual (aref ids middle)))
               (cond ((< actual id) (setf left (1+ middle)))
                     ((> actual id) (setf right middle))
                     (t (return-from contiene-segmento-directory-get t)))))
    (unless (= left right) (error 'invariant-violation :reason :directory-search-bound))
    nil))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-001
(declaim (ftype (function (sorgente-get-attiva t fonti-get-serie) null) verifica-fonti-get-attive))
(defun verifica-fonti-get-attive (source lease sources)
  "Pre: fonti immutabili e sorgente ACTIVE. Post: lease/salute, owner e ID non duplicato verificati.
INVALID-ARGUMENT prima di qualsiasi adozione; geometria impossibile => Archivio FAULTED.
Nessun I/O/pubblicazione; lifetime e copertura delle location restano al writer."
  (let* ((directory (fonti-get-serie-directory sources))
         (segment (sorgente-get-attiva-segment source))
         (controller (sorgente-get-attiva-controller source)))
    (arcdocdb.series::%check-owner controller lease)
    (arcdocdb.series::%require-healthy controller)
    (unless (eq (directory-get-serie-view directory) (segmento-get-owner segment))
      (error 'invalid-argument :reason :sources-owner))
    (handler-case
        (when (contiene-segmento-directory-get directory (segmento-get-low segment))
          (error 'invalid-argument :reason :sources-active-duplicate))
      (invariant-violation (condition)
        (arcdocdb.series::%mark-fault controller :archive)
        (error condition)))
    nil))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva t fonti-get-serie) radice-get-attiva)
                inizializza-fonti-get-attive))
(defun inizializza-fonti-get-attive (source lease sources)
  "Pre: nuovo ACTIVE con solo header durevole, EDIT deciso, fonti recuperate; ammissione chiusa.
Post: root ACTIVE vuota con CLOSED consultabili dal CAS canonico, senza lotto/CSN/I/O.
Owner/duplicato rifiutati prima dell'effetto; frontiera/avvio propagati dalla factory.
Il caller conserva fonti e FD sotto EBR; il primo lotto usa la root restituita come PREVIOUS."
  (verifica-fonti-get-attive source lease sources)
  (inizializza-radice-get-attiva source lease :content sources))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007
(declaim (ftype (function (sorgente-get-attiva t arcdocdb.wal:lotto (or null radice-get-attiva)
                          fonti-get-serie (member :async :group :strong))
                         (values arcdocdb.series:commit-serie index radice-get-attiva &optional))
                registra-lotto-fonti-get-attivo))
(defun registra-lotto-fonti-get-attivo (source lease batch previous sources level)
  "Pre: lease e SEALED/CSN del normale protocollo ACTIVE; fonti e content immutabili.
Post: root pianificata con fonti della stessa vista e ID ACTIVE assente da CLOSED.
INVALID-ARGUMENT prima dell'adozione per owner/duplicato; resto delegato al protocollo WAL.
Solo PUBBLICA-COMMIT-SERIE rende la root visibile; SEAL conserva il punto durevole."
  (verifica-fonti-get-attive source lease sources)
  (registra-lotto-get-attivo source lease batch previous sources level))
