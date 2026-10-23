;;;; Writer prima di Serie; Serie prima dell'handoff del writer, sempre bounded.
;;; OWNER: contesto e binding del thread creatore; debito batch non cancellato.
;;; SHARED: owner della sola Serie per tratto; nessuna scrittura globale per messaggio.
(in-package #:arcdocdb.execution.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie)
                         (member nil :serie-busy :serie-lease-generation)) %acquire-worker-serie))
(defun %acquire-worker-serie (link)
  "Pre: writer acquisito, bridge CLOSING con Serie lease0. Post: ACTIVE con
Serie corrente, oppure CLOSING per busy/esaurimento senza alcun pop.
Altri errori propagati; nessun gate healthy per permettere il drenaggio I/O."
  (%passo-worker-serie (link () ())
  (unless (eq (collegamento-worker-serie-state link) :closing)
    (error 'invariant-violation :reason :worker-serie-state))
  (unless (zerop (collegamento-worker-serie-series-lease link))
    (error 'invariant-violation :reason :worker-serie-lease))
  (let ((refusal
          (handler-case
              (let ((lease (acquisisci-controllore-serie (collegamento-worker-serie-controller link))))
                (setf (collegamento-worker-serie-series-lease link) lease
                      (collegamento-worker-serie-state link) :active)
                nil)
            (resource-exhausted (condition)
              (unless (member (error-reason condition) '(:serie-busy :serie-lease-generation))
                (error condition))
              (error-reason condition)))))
    (%check-worker-serie link)
    refusal)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie)
                         (values index (member :active :closing)
                                 (member nil :serie-busy :serie-lease-generation) &optional)) inizia-worker-serie))
(defun inizia-worker-serie (link)
  "Pre: IDLE, worker CLAIMED del writer associato. Post: token nuovo e ACTIVE
solo con entrambe le lease; seconda acquisizione rifiutata => CLOSING/token.
Caller termina CLOSING prima del ricircolo, senza pop/retry dell'acquisizione.
Binding/generation/fase controllati prima del begin; writer busy lascia IDLE."
  (%passo-worker-serie (link (:worker-serie-state :worker-state :worker-serie-generation :writer-queue-busy)
                            (:worker-serie-binding))
    (%require-worker-serie link '(:idle))
    (let ((context (collegamento-worker-serie-context link)))
      (arcdocdb.execution::%richiedi-worker context :claimed)
      (unless (eq (writer-worker-writer context) (collegamento-worker-serie-writer link))
        (error 'invalid-argument :reason :worker-serie-binding))
      (when (= (collegamento-worker-serie-generation link) most-positive-fixnum)
        (error 'resource-exhausted :reason :worker-serie-generation))
      (let ((lease (inizia-tratto-worker context)))
        (setf (collegamento-worker-serie-writer-lease link) lease
              (collegamento-worker-serie-state link) :closing)
        (incf (collegamento-worker-serie-generation link)))
      (let ((refusal (%acquire-worker-serie link)))
        (values (collegamento-worker-serie-generation link)
                (collegamento-worker-serie-state link) refusal)))))

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie t) index) lease-worker-serie))
(defun lease-worker-serie (link token)
  "Pre: ACTIVE, token del tratto corrente. Post: lease Serie per le API del controller.
INVALID-ARGUMENT token; fase rifiutata prima di leggere Serie, invarianti delegate."
  (%passo-worker-serie (link (:worker-serie-state) (:worker-serie-token))
    (%require-worker-serie link '(:active))
    (%check-token-worker-serie link token)
    (collegamento-worker-serie-series-lease link)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie t t t t)
                         (values index (member :messages :empty :yield) index &optional)) preleva-worker-serie))
(defun preleva-worker-serie (link token target start end)
  "Pre: ACTIVE/token corrente, target privato. Post: batch sotto entrambe le
lease, risultati e debito delegati al worker. Busy/span/alias rifiutati senza pop;
token di tratto distinto da batch; errori inattesi conservati al confine."
  (%passo-worker-serie (link (:worker-serie-state :worker-state :worker-generation :writer-queue-busy)
                            (:worker-serie-token :writer-target))
    (%require-worker-serie link '(:active))
    (%check-token-worker-serie link token)
    (preleva-lavori-worker (collegamento-worker-serie-context link) target start end)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie t t) null) conferma-worker-serie))
(defun conferma-worker-serie (link token batch)
  "Pre: ACTIVE/token e batch completamente applicato dal caller. Post: debito
azzerato solo con token batch corrente; condizioni worker/token prima di mutare.
Non verifica effetti esterni e non permette replay di un prefisso applicato."
  (%passo-worker-serie (link (:worker-serie-state :worker-state) (:worker-serie-token :worker-batch))
    (%require-worker-serie link '(:active))
    (%check-token-worker-serie link token)
    (conferma-lavori-worker (collegamento-worker-serie-context link) batch)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (collegamento-worker-serie t) (member :idle :schedule)) termina-worker-serie))
(defun termina-worker-serie (link token)
  "Pre: ACTIVE senza batch, oppure CLOSING da ritentare; token corrente.
Post: Serie rilasciata PRIMA di endwriter, IDLE locale e obbligo schedule al worker.
Debito rifiutato prima della release; busy end conserva CLOSING e lease writer.
Release fallita conserva token Serie; retry non ripete una release già riuscita."
  (%passo-worker-serie (link (:worker-serie-state :worker-state :writer-queue-busy) (:worker-serie-token))
    (%require-worker-serie link '(:active :closing))
    (%check-token-worker-serie link token)
    (let ((context (collegamento-worker-serie-context link)))
      (unless (member (stato-worker-writer context) '(:running :finishing))
        (error 'resource-exhausted :reason :worker-state))
      (setf (collegamento-worker-serie-state link) :closing)
      (when (plusp (collegamento-worker-serie-series-lease link))
        (%passo-worker-serie (link () ())
          (rilascia-controllore-serie (collegamento-worker-serie-controller link)
                                     (collegamento-worker-serie-series-lease link)))
        (setf (collegamento-worker-serie-series-lease link) 0))
      (let ((action (termina-tratto-worker context)))
        (setf (collegamento-worker-serie-writer-lease link) 0
              (collegamento-worker-serie-state link) :idle)
        (%check-worker-serie link)
        action))))
