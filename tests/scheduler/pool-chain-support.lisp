;;;; Catena pubblica su thread reali; nessuna FI o stato globale nuovo.
;;;; OWNER: context/port/table/link sul worker; coordinator sul chiamante del test.
;;;; SHARED: ready per tratto, registro immutabile, canali C4 con timeout 15s.
(in-package #:arcdocdb.scheduler.tests)

(defun pool-chain-local (ready registry coordinator &optional (start 0))
  "Costruisce sul vero owner le risorse locali di un worker della catena."
  (let* ((context (arcdocdb.execution:crea-contesto-worker-writer ready :start start))
         (port (arcdocdb.scheduler:crea-porta-worker-pool context :coordinator coordinator))
         (table (arcdocdb.execution.series:crea-tabella-worker-serie context registry)))
    (values context port
            (arcdocdb.scheduler.dispatch:crea-dispatcher-writer-pool port table))))

(defun pool-chain-take (dispatcher context writer origin detail)
  "Oracolo pubblico: un CLAIMED del writer atteso, con link ancora IDLE."
  (multiple-value-bind (link status actual-origin actual-detail action)
      (arcdocdb.scheduler.dispatch:passo-dispatcher-pool dispatcher)
    (is (typep link 'arcdocdb.execution.series:collegamento-worker-serie))
    (is (eq :claimed status)) (is (eq origin actual-origin))
    (is (= detail actual-detail))
    (is (eq (if (eq origin :claim) :unchanged nil) action))
    (is (eq :claimed (arcdocdb.execution:stato-worker-writer context)))
    (is (eq writer (arcdocdb.execution:writer-worker-writer context)))
    (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
    link))

(defun pool-chain-begin (dispatcher link)
  (multiple-value-bind (actual token phase reason)
      (arcdocdb.scheduler.dispatch:inizia-obbligo-pool dispatcher)
    (is (eq actual link)) (is (plusp token)) (is (eq :active phase))
    (is (null reason))
    (is (plusp (arcdocdb.execution.series:lease-worker-serie link token)))
    token))

(defun pool-chain-ack-end (context link token batch action)
  "Debito verificato e confermato esplicitamente, poi rilascio di entrambe le lease."
  (is (eq :batch (arcdocdb.execution:stato-worker-writer context)))
  (is (null (arcdocdb.execution.series:conferma-worker-serie link token batch)))
  (is (eq :running (arcdocdb.execution:stato-worker-writer context)))
  (is (eq action (arcdocdb.execution.series:termina-worker-serie link token)))
  (is (eq :idle (arcdocdb.execution.series:stato-worker-serie link)))
  (is (null (arcdocdb.execution.series:errore-worker-serie link)))
  (is (eq (if (eq action :idle) :idle :reschedule)
          (arcdocdb.execution:stato-worker-writer context))))

(defun pool-chain-finish (dispatcher context link item action)
  (let* ((token (pool-chain-begin dispatcher link))
         (batch (pool-claim-bridge-pop link token item)))
    (pool-chain-ack-end context link token batch action)))

(defun pool-chain-published (dispatcher count)
  (pool-step-check dispatcher nil :published :recycle count nil))

(defun pool-chain-empty (dispatcher context cursor)
  (pool-step-check dispatcher nil :empty :claim cursor :unchanged)
  (is (eq :idle (arcdocdb.execution:stato-worker-writer context)))
  (is (null (arcdocdb.execution:writer-worker-writer context)))
  (is (null (arcdocdb.execution:errore-worker-writer context))))

(defun pool-chain-writer (count ordinal)
  (let ((writer (arcdocdb.execution:crea-writer-programmabile
                 :capacity 64 :quantum 1 :routing-index ordinal)))
    (dotimes (index count)
      (arcdocdb.execution.tests::handoff-check-enqueue
       writer index (1+ index) (if (zerop index) :schedule :queued)))
    writer))
