;;; OWNER: handle privato del thread chiamante, una richiesta completa per chiamata.
;;; SHARED: soltanto byte wire con il server; nessuna dipendenza da test o bootstrap remoto.
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(defun esigi-local-client (client state)
  "Pre: handle esterno. Post: tipo, owner e stato esatti; rientro e handle chiusi rifiutati."
  (unless (and (typep client 'local-client) (eq (local-client-owner client) sb-thread:*current-thread*)
               (eq (local-client-state client) state))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-client-state))
  nil)

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun close-local (client)
  "Pre: handle del thread owner. Post: ownership consumata una volta, anche con close fallita."
  (unless (and (typep client 'local-client) (eq (local-client-owner client) sb-thread:*current-thread*))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-client-owner))
  (let ((socket (local-client-socket client)))
    (setf (local-client-socket client) nil (local-client-state client) :closed)
    (when socket (close-local-socket socket)))
  nil)

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun fail-local-client (client primary mutation)
  "Pre: errore primario, eventuale richiesta mutante iniziata. Post: close senza retry e causa intatta."
  (let ((cause primary))
    (handler-case (close-local client)
      (error (cleanup)
        (setf cause (make-condition 'local-cleanup-error :reason :local-client-cleanup
                                   :primary primary :failures (list cleanup)))))
    (if mutation (error 'outcome-unknown :reason :local-outcome-unknown :cause cause) (error cause))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun transfer-local-client (client buffer start end direction until)
  "Pre: buffer esclusivo e deadline assoluta. Post: span esatto o errore senza conferma parziale."
  (loop while (< start end) do
    (when (>= (local-now (local-client-clock client)) until)
      (error 'protocol-error :reason :local-client-deadline))
    (multiple-value-bind (status count)
        (local-transfer-step (local-client-socket client) buffer start end direction (local-client-io-backend client))
      (case status
        (:progress (incf start count))
        (:wait (sleep 0.001))
        (:eof (error 'protocol-error :reason :local-client-eof)))))
  end)

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun receive-local-client (client limit until)
  "Pre: attesa di un solo frame. Post: envelope esatto; coalescenza residua rimane nel kernel."
  (let ((buffer (local-client-input client)))
    (transfer-local-client client buffer 0 4 :input until)
    (let ((end (+ 4 (local-prefix-size buffer limit))))
      (transfer-local-client client buffer 4 end :input until)
      (decode-local-envelope buffer 4 end :space (local-client-space client)))))

;;; REQ: REQ-IPC-001 REQ-IPC-002
(defun connect-local (path &key (max-frame 65536) (clock #'get-internal-real-time) io-backend)
  "Pre: path Unix esplicito e clock monotono fidato. Post: client owner dopo WELCOME verificato.
Nessuna operazione dati durante handshake; errore chiude sempre il socket posseduto."
  (unless (and (typep max-frame '(integer 4096 17825792)) (functionp clock))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-client-configuration))
  (%native-check-backend io-backend)
  (let* ((client (make-local-client :clock clock :limit (min 65536 max-frame) :io-backend io-backend))
         (until (local-until (local-now clock) 5)))
    (handler-case
        (progn
          (setf (local-client-socket client) (connect-local-socket path until :clock clock))
          (let ((size (encode-local-hello (local-client-output client) max-frame)))
            (transfer-local-client client (local-client-output client) 0 size :output until))
          (let ((envelope (receive-local-client client 4096 until)))
            (multiple-value-bind (frame inflight)
                (decode-local-welcome (local-client-input client) envelope)
              (unless (and (<= 4096 frame (min 65536 max-frame)) (= inflight 1))
                (error 'protocol-error :reason :local-client-negotiation))
              (setf (local-client-limit client) frame)))
          (setf (local-client-state client) :ready)
          client)
      (error (condition) (fail-local-client client condition nil)))))

;;; REQ: REQ-IPC-002 REQ-WAL-006 REQ-AFF-004
(defun exchange-local-client (client opcode key document)
  "Pre: owner READY e argomenti verificati dal codec. Post: risultato terminale correlato.
Dal primo tentativo di invio mutante, la perdita della risposta produce OUTCOME-UNKNOWN."
  (esigi-local-client client :ready)
  (let* ((id (local-client-next-id client)) (out (local-client-output client)))
    (unless (<= id #xffffffffffffffff)
      (error 'arcdocdb.conditions:resource-exhausted :reason :local-client-id-exhausted))
    (let ((size (encode-local-request out id opcode key document))
          (until (local-until (local-now (local-client-clock client)) 30)))
      (unless (<= size (+ 4 (local-client-limit client)))
        (error 'arcdocdb.conditions:resource-exhausted :reason :local-client-frame-budget))
      (setf (local-client-state client) :busy (local-client-next-id client) (1+ id))
      (handler-case
          (progn
            (transfer-local-client client out 0 size :output until)
            (let ((envelope (receive-local-client client (local-client-limit client) until)))
              (unless (and (= 3 (envelope-kind envelope)) (= id (envelope-id envelope)))
                (error 'protocol-error :reason :local-client-response-id))
              (multiple-value-prog1
                  (decode-local-response (local-client-input client) envelope (local-client-space client) opcode)
                (setf (local-client-state client) :ready))))
        (request-rejected (condition) (setf (local-client-state client) :ready) (error condition))
        (error (condition) (fail-local-client client condition (not (null (member opcode '(1 3))))))))))

;;; REQ: REQ-IPC-002 REQ-WAL-006
(defun client-put (client key document)
  "Pre: owner READY, ottetti chiave/CBOR stabili. Post: CSN strong o rifiuto/esito ignoto espliciti."
  (exchange-local-client client 1 key document))

;;; REQ: REQ-IPC-002 REQ-IDX-001
(defun client-get (client key)
  "Pre: owner READY, chiave binaria. Post: values :FOUND documento copiato oppure :ABSENT NIL."
  (exchange-local-client client 2 key nil))

;;; REQ: REQ-IPC-002 REQ-WAL-006
(defun client-delete (client key)
  "Pre: owner READY, chiave binaria. Post: CSN strong della tombstone, senza retry."
  (exchange-local-client client 3 key nil))

;;; REQ: REQ-IPC-002
(defun client-ping (client)
  "Pre: owner READY dopo WELCOME. Post: NIL dopo risposta PING correlata del motore operativo."
  (exchange-local-client client 0 nil nil))
