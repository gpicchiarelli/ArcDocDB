;;;; C4: due processi reali, sessione di controllo; gate e comandi rimangono un modello.
;;; REQ: REQ-VAL-001 REQ-IPC-002 REQ-IPC-004
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defun invalid-hello-wire ()
  "HELLO con chiave 0 ripetuta: sintassi valida, ordine/unicita invalidi."
  (bytes #x85 1 0 0 0 #xa2 0 #x19 #x20 0 0 2))

(defun client-session-exchange (socket mode until)
  "Client C4: WELCOME deve precedere le richieste e confermare limiti/opcode attesi."
  (cond
    ((string= mode "session-oversize-hello")
     (send-bytes socket (prefix 4097) 4 until)
     (same-frames (receive-frames socket 0 64 until 4096) nil))
    ((member mode '("session-invalid-hello" "session-pre-hello") :test #'string=)
     (send-bytes socket (frame (if (string= mode "session-invalid-hello") (invalid-hello-wire) (ping 1))) 1 until)
     (same-frames (receive-frames socket 0 64 until 4096) nil))
    (t
     (send-bytes socket (frame (hello-wire)) 1 until)
     (let* ((welcome (first (receive-count socket 1 1 until 4096)))
            (message (decode-control welcome)))
       (same-frames (list welcome) (list (bytes #x85 1 1 0 0 #xa3 0 #x19 #x10 0 1 2 2 #x81 0)))
       (demand (and (= 4096 (getf message :max-frame)) (= 2 (getf message :max-inflight))
                    (equal '(0) (getf message :opcodes))) :client-negotiation))
     (if (string= mode "session-id-reuse")
         (progn
           (send-bytes socket (concatenate '(simple-array (unsigned-byte 8) (*)) (frame (ping 1)) (frame (ping 1))) 64 until)
           (same-frames (receive-frames socket 0 64 until 4096) nil))
         (let ((client (make-model-client)))
           (model-issued client 1) (model-issued client 2)
           (send-bytes socket (concatenate '(simple-array (unsigned-byte 8) (*)) (frame (ping 1)) (frame (ping 2))) 64 until)
           (let ((responses (receive-count socket 2 1 until 4096)))
             (same-frames responses (list (ping 2 3) (ping 1 3)))
             (dolist (response responses) (demand (zerop (model-received client response)) :client-status))
             (demand (equal '(2 1) (reverse (model-client-completed client))) :client-correlation))))))
  t)

(defun server-session-exchange (socket mode until)
  "Profilo controllo 4096: rifiuti prima della risposta; nessuna API del motore."
  (let ((session (make-model-session)))
    (cond
      ((string= mode "session-oversize-hello")
       (expect-rejection :length (lambda () (receive-frames socket 0 4 until 4096))))
      ((member mode '("session-invalid-hello" "session-pre-hello") :test #'string=)
       (let ((body (first (receive-count socket 1 1 until 4096))))
         (expect-rejection (if (string= mode "session-invalid-hello") :control-map-order :hello-required)
                           (lambda () (model-hello session body 0)))))
      (t
       (let* ((hello (first (receive-count socket 1 1 until 4096)))
              (welcome (model-hello session hello 0)))
         (demand (zerop (model-session-calls session)) :handshake-no-admission)
         (send-bytes socket (frame welcome) 1 until)
         (model-welcome-sent session 0))
       (let ((requests (receive-count socket 2 64 until (model-session-max-frame session))))
         (model-request session (first requests) 0)
         (if (string= mode "session-id-reuse")
             (expect-rejection :request-order (lambda () (model-request session (second requests) 0)))
             (progn
               (model-request session (second requests) 0)
               (demand (= 20 (model-session-queued-bytes session)) :queued-credit)
               (dolist (id '(2 1))
                 (let ((response (model-response session id)))
                   (send-bytes socket response 1 until)
                   (model-sent session id (length response) 0)))
               (demand (zerop (model-session-queued-bytes session)) :sent-credit))))))
    (list :status :ok :profile :control :max-frame (model-session-max-frame session)
          :max-inflight (model-session-max-inflight session) :model-calls (model-session-calls session)
          :pending-at-close (hash-table-count (model-session-pending session)) :engine-called nil)))
