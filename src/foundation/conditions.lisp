;;;; Errori di confine: nessuna gestione del ciclo di vita di Serie in questo strato.
(in-package #:arcdocdb.conditions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-AFF-004
(define-condition arcdocdb-error (error)
  ((reason :initarg :reason :reader error-reason :type keyword)
   (offset :initarg :offset :initform nil :reader error-offset
           :type (or null (integer 0 *))))
  (:documentation "Errore tipizzato; reason non contiene dati del documento.")
  (:report (lambda (condition stream)
             (format stream "ArcDocDB: ~A~@[ all'offset ~D~]"
                     (error-reason condition) (error-offset condition)))))

;;; REQ: REQ-AFF-004
(define-condition invalid-argument (arcdocdb-error) ()
  (:documentation "Argomento o intervallo non valido; nessuna scrittura eseguita."))
;;; REQ: REQ-AFF-004 REQ-AFF-002
(define-condition corruption-detected (arcdocdb-error) ()
  (:documentation "Record o prova incoerenti; nessun dato verificato restituito."))
;;; REQ: REQ-FOR-002
(define-condition unsupported-format (arcdocdb-error) ()
  (:documentation "Versione sconosciuta; nessuna interpretazione per tentativi."))
;;; REQ: REQ-LIM-001 REQ-LIM-003
(define-condition resource-exhausted (arcdocdb-error) ()
  (:documentation "Budget configurato esaurito; rifiuto precedente alla scrittura."))
;;; REQ: REQ-AFF-004
(define-condition invariant-violation (arcdocdb-error) ()
  (:documentation "Invariante interna violata; il proprietario applica fail-stop."))

;;; REQ: REQ-MVC-004 REQ-AFF-004
(define-condition snapshot-too-old (arcdocdb-error) ()
  (:documentation "Snapshot scaduto, terminato o identità riusata; nessun risultato restituito."))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(define-condition io-fault (arcdocdb-error)
  ((operation :initarg :operation :reader error-operation :type keyword)
   (errno :initarg :errno :initform nil :reader error-errno :type (or null fixnum))
   (cleanup-errno :initarg :cleanup-errno :initform nil :reader error-cleanup-errno
                  :type (or null fixnum))
   (transferred :initarg :transferred :initform 0 :reader error-transferred
                :type (integer 0 *)))
  (:documentation "Guasto I/O dichiarato, con errno e progresso noto; nessun retry."))
