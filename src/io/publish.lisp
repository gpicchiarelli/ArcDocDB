;;;; Completamento di un temporaneo deciso, senza sovrascrivere un nome esistente.
;;; OWNER: compito I/O del controller; parent, sorgente, nomi e namespace esclusivi/stabili.
;;; SHARED: nessun lock o stato fra Serie; capacita' prestate, nessun trasferimento di ownership.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string) null) verifica-capacita-pubblicazione))
(defun verifica-capacita-pubblicazione (directory source source-name target-name)
  "Pre: capacita' e nomi stabili del controller. Post: preflight senza I/O sui file o mutazioni.
INVALID-ARGUMENT per modo, nomi o backend; IO-FAULT per capacita' non aperta.
UNSUPPORTED-FORMAT per callback/ABI/piattaforma/simbolo mancanti, nessun fallback."
  (esigi-aperto directory :directory) (esigi-aperto source :input)
  (esigi-nome-foglia source-name) (esigi-nome-foglia target-name)
  (verifica-nomi-temporaneo source-name target-name)
  (unless (eq (file-backend directory) (file-backend source))
    (error 'invalid-argument :reason :io-identity-backend))
  (let ((backend (file-backend directory)))
    (if backend
        (when (or (null (backend-identity backend)) (null (backend-entry-identity backend))
                  (null (backend-rename-exclusive backend)))
          (error 'unsupported-format :reason :io-publish-unavailable))
        (esigi-rinomina-esclusiva-nativa)))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string) null) pubblica-temporaneo))
(defun pubblica-temporaneo (directory source source-name target-name)
  "Pre: decisione autorevole durevole e contenuto verificato dal caller; namespace esclusivo.
SOURCE readonly aperto, source-name = target-name + .tmp; nessuna close o sostituzione concorrente.
Post: target prima assente, ora legato allo stesso FD regolare; capacita' ancora aperte.
Punto atomico: rinomina esclusiva, completamento della decisione; fsync parent resta al caller.
Nessun retry, scrittura/troncamento dei segmenti, close, unlink o flush implicito.
Rifiuti pre-effetto non mutano stato; ogni uscita incompleta dall'effetto guasta il parent.
Un ritorno perso si riconcilia da un nuovo inventario, non ripetendo questa chiamata."
  (verifica-capacita-pubblicazione directory source source-name target-name)
  (let ((source-leaf (map 'simple-base-string #'identity source-name))
        (target-leaf (map 'simple-base-string #'identity target-name)))
    (verifica-legame-nome-file directory source source-leaf)
    (rinomina-con-nomi-privati
     directory source-leaf target-leaf
     (lambda ()
       (verifica-legame-nome-file directory source target-leaf)
       (esigi-aperto source :input))
     t))
  nil)
