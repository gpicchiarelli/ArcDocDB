;;;; C4: modello di sessione esclusivo, gate/clock simulati; nessun accesso al motore.
;;; REQ: REQ-VAL-001 REQ-IPC-002 REQ-IPC-004
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defstruct model-session
  (state :hello) (server-frame 4096) (server-inflight 2) (max-frame 0) (max-inflight 0)
  (last-id 0) (pending (make-hash-table :test 'eql)) (queued-bytes 0) (output-capacity 128)
  (gate-open t) (calls 0) (now 0) (hello-until 5) (frame-until nil))

(defun model-time (session now)
  "Clock logico monotono: nessuna deadline e rinnovata dal progresso."
  (demand (>= now (model-session-now session)) :clock-regression)
  (setf (model-session-now session) now)
  (when (member (model-session-state session) '(:hello :welcome-pending))
    (demand (< now (model-session-hello-until session)) :hello-deadline))
  (when (model-session-frame-until session)
    (demand (< now (model-session-frame-until session)) :frame-deadline))
  (maphash (lambda (id row) (declare (ignore id))
             (demand (< now (getf row :until)) :output-deadline))
           (model-session-pending session))
  t)

(defun model-hello (session body now)
  "Riserva logica WELCOME; richieste abilitate soltanto dopo invio completo."
  (model-time session now)
  (demand (eq :hello (model-session-state session)) :hello-state)
  (let ((message (decode-control body)))
    (demand (= 0 (getf message :kind)) :hello-required)
    (setf (model-session-max-frame session) (min (getf message :max-frame) (model-session-server-frame session))
          (model-session-max-inflight session) (min (getf message :max-inflight) (model-session-server-inflight session))
          (model-session-state session) :welcome-pending)
    (welcome-wire (model-session-max-frame session) (model-session-max-inflight session)
                  (model-session-gate-open session))))

(defun model-welcome-sent (session now)
  "Punto del modello: ultimo byte WELCOME inviato, non un gate del prodotto."
  (model-time session now)
  (demand (eq :welcome-pending (model-session-state session)) :welcome-state)
  (setf (model-session-state session) :ready))

(defun model-start-frame (session now)
  "La prima parte fissa la deadline, le successive conservano lo stesso limite."
  (model-time session now)
  (demand (eq :ready (model-session-state session)) :request-state)
  (unless (model-session-frame-until session) (setf (model-session-frame-until session) (+ now 30)))
  (model-session-frame-until session))

(defun model-request (session body now)
  "Ammette solo con credito per richiesta e risultato; restituisce :paused senza consumo ID."
  (model-time session now)
  (when (eq :draining (model-session-state session)) (return-from model-request :draining))
  (demand (eq :ready (model-session-state session)) :request-state)
  (when (>= (hash-table-count (model-session-pending session)) (model-session-max-inflight session))
    (return-from model-request :paused))
  (demand (<= (length body) (model-session-max-frame session)) :negotiated-frame)
  (let* ((message (decode-control body)) (id (getf message :id)) (opcode (getf message :code)))
    (demand (= 2 (getf message :kind)) :request-kind)
    (demand (> id (model-session-last-id session)) :request-order)
    (let* ((status (cond ((not (model-session-gate-open session)) 3)
                         ((/= opcode 0) 4) ((not (getf message :payload-null)) 1) (t 0)))
           (response (frame (control-wire 3 id status (bytes #xf6))))
           (size (length response)))
      (when (> size (- (model-session-output-capacity session) (model-session-queued-bytes session)))
        (return-from model-request :paused))
      (setf (gethash id (model-session-pending session))
            (list :wire response :sent 0 :until (+ now 30))
            (model-session-last-id session) id (model-session-frame-until session) nil)
      (incf (model-session-queued-bytes session) size)
      (when (zerop status) (incf (model-session-calls session)))
      (when (= id #xffffffffffffffff) (setf (model-session-state session) :draining))
      id)))

(defun model-response (session id)
  "Prestito readonly del risultato riservato; il credito resta occupato."
  (let ((row (gethash id (model-session-pending session))))
    (demand row :response-unknown)
    (getf row :wire)))

(defun model-sent (session id count now)
  "Rilascia il credito soltanto dopo l'ultimo byte; terminale duplicato rifiutato."
  (model-time session now)
  (let ((row (gethash id (model-session-pending session))))
    (demand row :response-unknown)
    (demand (<= 0 count (- (length (getf row :wire)) (getf row :sent))) :send-count)
    (incf (getf row :sent) count)
    (when (= (getf row :sent) (length (getf row :wire)))
      (decf (model-session-queued-bytes session) (length (getf row :wire)))
      (remhash id (model-session-pending session))
      (when (and (eq :draining (model-session-state session))
                 (zerop (hash-table-count (model-session-pending session))))
        (setf (model-session-state session) :reconnect)))
    t))

(defun model-ready (&rest arguments)
  "Fixture: handshake completo su una sessione del solo modello."
  (let ((session (apply #'make-model-session arguments)))
    (model-hello session (hello-wire) 0) (model-welcome-sent session 0) session))

(defstruct model-client (pending (make-hash-table :test 'eql)) (last-id 0) (completed nil))

(defun model-issued (client id)
  "ID crescenti del client; risposte possono completare in ordine diverso."
  (demand (and (typep id '(integer 1 18446744073709551615)) (> id (model-client-last-id client))) :client-id)
  (setf (gethash id (model-client-pending client)) t (model-client-last-id client) id))

(defun model-received (client body)
  "Una risposta nota, terminale e nulla per PING; ignote/duplicate non consumano altri ID."
  (let* ((message (decode-control body)) (id (getf message :id)))
    (demand (= 3 (getf message :kind)) :response-kind)
    (demand (gethash id (model-client-pending client)) :client-unknown-response)
    (demand (getf message :payload-null) :client-ping-result)
    (remhash id (model-client-pending client))
    (push id (model-client-completed client))
    (getf message :code)))
