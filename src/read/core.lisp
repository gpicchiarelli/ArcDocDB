;;; OWNER: worker esclusivo; il confine del compito gestisce gli errori e isola FAULTED.
;;; SHARED: cleanup del solo annuncio EBR proprio, anche se il dominio è FAULTED.
(in-package #:arcdocdb.read)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-004 REQ-CMP-007
(declaim (ftype (function (contesto-lettura keyword) nil) guasto-contesto-lettura))
(defun guasto-contesto-lettura (context reason)
  "Pre: invariante locale incoerente. Post: contesto FAULTED prima dell'errore tipizzato.
Non libera un reader ancora in uso; il confine del compito deve eseguire il cleanup."
  (setf (contesto-lettura-state context) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(declaim (inline esigi-lettura-inattiva esigi-lettura-attiva))
(declaim (ftype (function (contesto-lettura) null) esigi-lettura-inattiva))
(defun esigi-lettura-inattiva (context)
  "Pre: worker proprietario. Post: stato e buffer inattivi, annuncio EBR libero.
INVALID-ARGUMENT per riuso/annidamento; stato inattivo con dati residui porta a FAULTED."
  (unless (eq (contesto-lettura-state context) :idle)
    (error 'invalid-argument :reason :read-context-not-idle))
  (when (epoca-attiva-p (contesto-lettura-reader context))
    (error 'invalid-argument :reason :read-worker-busy))
  (unless (and (null (contesto-lettura-snapshot context))
               (zerop (aref (contesto-lettura-words context) +word-generation+))
               (zerop (aref (contesto-lettura-words context) +word-snapshot-csn+))
               (zerop (aref (contesto-lettura-words context) +word-start-time+))
               (zerop (aref (contesto-lettura-words context) +word-confirmed-csn+)))
    (guasto-contesto-lettura context :read-idle-data))
  nil)

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-MVC-005 REQ-AFF-004
(declaim (ftype (function (contesto-lettura) null) esigi-lettura-attiva))
(defun esigi-lettura-attiva (context)
  "Pre: worker proprietario. Post: stato attivo, epoca annunciata e modalità coerente.
INVALID-ARGUMENT per stato non attivo; incoerenza interna porta a FAULTED."
  (unless (eq (contesto-lettura-state context) :active)
    (error 'invalid-argument :reason :read-context-not-active))
  (unless (epoca-attiva-p (contesto-lettura-reader context))
    (guasto-contesto-lettura context :read-epoch-missing))
  (let ((snapshot (contesto-lettura-snapshot context)) (words (contesto-lettura-words context)))
    (if snapshot
        (unless (and (plusp (aref words +word-generation+))
                     (snapshot-del-registro-p snapshot (contesto-lettura-snapshots context)))
          (guasto-contesto-lettura context :read-snapshot-binding))
        (unless (and (zerop (aref words +word-generation+))
                     (zerop (aref words +word-snapshot-csn+)))
          (guasto-contesto-lettura context :read-current-binding))))
  nil)

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (contesto-lettura) null) libera-contesto-lettura))
(defun libera-contesto-lettura (context)
  "Pre: sezione posseduta solo da questo contesto; ultimo accesso terminato.
Post: epoca libera e buffer azzerato; FAULTED preesistente non diventa riutilizzabile.
Interruzione del cleanup lascia FAULTED. Non nasconde errori e non compie I/O."
  (let ((faulted (eq (contesto-lettura-state context) :faulted)))
    (setf (contesto-lettura-state context) :faulted)
    (when (epoca-attiva-p (contesto-lettura-reader context))
      (esci-epoca (contesto-lettura-reader context)))
    (setf (contesto-lettura-snapshot context) nil)
    (dotimes (i 4) (setf (aref (contesto-lettura-words context) i) 0))
    (when (epoca-attiva-p (contesto-lettura-reader context))
      (guasto-contesto-lettura context :read-epoch-not-released))
    (unless faulted (setf (contesto-lettura-state context) :idle)))
  nil)
