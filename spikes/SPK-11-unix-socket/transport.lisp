;;;; C4: I/O diretto consentito solo nell'esperimento, con deadline e ownership locali.
;;; REQ: REQ-VAL-001 REQ-IPC-001 REQ-IPC-002 REQ-IPC-003
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defun deadline (&optional (seconds 10))
  "Scadenza assoluta monotona; mai rinnovata da un trasferimento parziale."
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun wait-socket (socket direction until)
  "Attesa FD limitata senza servire ricorsivamente eventi estranei alla prova."
  (let ((left (/ (- until (get-internal-real-time)) internal-time-units-per-second)))
    (unless (and (plusp left)
                 (sb-sys:wait-until-fd-usable
                  (sb-bsd-sockets:socket-file-descriptor socket) direction left nil))
      (error 'rejection :reason :deadline))))

(defun new-socket ()
  "Socket stream locale non bloccante, posseduto dal caller."
  (let ((socket (make-instance 'sb-bsd-sockets:local-socket :type :stream :protocol 0)))
    (setf (sb-bsd-sockets:non-blocking-mode socket) t)
    socket))

(defun close-socket (socket)
  "Cleanup solo per il socket locale ancora aperto."
  (when (and socket (sb-bsd-sockets:socket-open-p socket)) (sb-bsd-sockets:socket-close socket)))

(defun send-bytes (socket input chunk until)
  "Invia tutto con offset esplicito e progresso positivo; C4 alloca le slice di invio."
  (let ((offset 0))
    (loop while (< offset (length input)) do
      (wait-socket socket :output until)
      (let* ((slice (subseq input offset (min (length input) (+ offset chunk))))
             (sent (sb-bsd-sockets:socket-send socket slice (length slice) :nosignal t)))
        (when sent
          (demand (<= 1 sent (length slice)) :send-progress)
          (incf offset sent))))
    offset))

(defun receive-frames (socket count chunk until &optional (limit +frame-limit+))
  "Legge COUNT frame ed EOF; un EOF parziale non viene convertito in risultato completo."
  (let ((state (make-decoder :limit limit)) (buffer (make-array chunk :element-type '(unsigned-byte 8)))
        (result nil))
    (loop repeat (+ (* (max 1 count) (+ +frame-limit+ 4)) 1) do
      (wait-socket socket :input until)
      (multiple-value-bind (returned size) (sb-bsd-sockets:socket-receive socket buffer chunk)
        (when returned
          (when (zerop size)
            (finish-decoder state)
            (demand (= count (length result)) :frame-count)
            (return-from receive-frames (values result (decoder-allocations state))))
          (demand (<= 1 size chunk) :receive-progress)
          (setf result (nconc result (feed state buffer 0 size)))
          (demand (<= (length result) count) :extra-frame))))
    (error 'rejection :reason :receive-bound)))

(defun receive-count (socket count chunk until &optional (limit +frame-limit+))
  "Riceve il numero esatto di frame della fase, prima della chiusura bidirezionale."
  (let ((state (make-decoder :limit limit)) (buffer (make-array chunk :element-type '(unsigned-byte 8)))
        (result nil))
    (loop repeat (+ (* count (+ +frame-limit+ 4)) 1) do
      (wait-socket socket :input until)
      (multiple-value-bind (returned size) (sb-bsd-sockets:socket-receive socket buffer chunk)
        (when returned
          (demand (plusp size) :unexpected-eof)
          (setf result (nconc result (feed state buffer 0 size)))
          (demand (<= (length result) count) :extra-frame)
          (when (= count (length result))
            (finish-decoder state)
            (return-from receive-count result)))))
    (error 'rejection :reason :receive-bound)))

(defun node-identity (path)
  "Identita lstat, senza seguire link o confondere l'assenza con altri errori."
  (handler-case
      (let ((stat (sb-posix:lstat path)))
        (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat) (sb-posix:stat-mode stat)))
    (sb-posix:syscall-error (condition)
      (unless (= (sb-posix:syscall-errno condition) sb-posix:enoent) (error condition)) nil)))

(defun unlink-owned (path identity)
  "Rimuove solo l'identita ancora propria nella directory esclusiva della prova."
  (when (equal identity (node-identity path)) (sb-posix:unlink path) t))

(defun bind-unoccupied (socket path)
  "Preflight lstat nella directory privata: un nome occupato non arriva mai al bind."
  (when (node-identity path) (error 'rejection :reason :occupied))
  (sb-bsd-sockets:socket-bind socket path))

(defun connect-local (socket path until)
  "Connect non bloccante verso il listener gia pronto, con verifica SO_ERROR."
  (handler-case (sb-bsd-sockets:socket-connect socket path)
    (sb-bsd-sockets:operation-in-progress () nil)
    (sb-bsd-sockets:interrupted-error () nil))
  (wait-socket socket :output until)
  (let ((code (sb-bsd-sockets:sockopt-error socket)))
    (unless (zerop code) (sb-bsd-sockets:socket-error "SPK-11 connect" code))))

(declaim (ftype (function (t t t) t) client-session-exchange))
(declaim (ftype (function (t t) t) client-native-session))

(defun client (path mode)
  "Figlio reale, senza shell o clock usato per sincronizzarsi con l'accept."
  (let ((socket (new-socket)) (until (deadline)))
    (unwind-protect
         (progn
           (connect-local socket path until)
           (cond
             ((string= mode "native-client") (client-native-session socket until))
             ((string= mode "native-server") (client-session-exchange socket "session" until))
             ((string= mode "native-truncated") (send-bytes socket (bytes 0 0 0 6 #x85) 5 until))
             ((member mode '("session" "session-invalid-hello" "session-pre-hello"
                             "session-oversize-hello" "session-id-reuse") :test #'string=)
              (client-session-exchange socket mode until))
             ((member mode '("fragmented" "coalesced") :test #'string=)
              (let ((input (concatenate '(simple-array (unsigned-byte 8) (*))
                                        (frame (ping 1)) (frame (ping 2)))))
                (send-bytes socket input (if (string= mode "fragmented") 1 20) until)
                (same-frames (receive-count socket 2 1 until) (list (ping 2 3) (ping 1 3)))))
             ((string= mode "maximum")
              (send-bytes socket (frame (maximum-body)) 65536 until)
              (same-frames (receive-count socket 1 64 until) (list (ping 1 3))))
             ((string= mode "zero") (send-bytes socket (prefix 0) 4 until))
             ((string= mode "oversize") (send-bytes socket (prefix (1+ +frame-limit+)) 4 until))
             ((string= mode "truncated") (send-bytes socket (bytes 0 0 0 6 #x85) 5 until))
             (t (error 'rejection :reason :client-mode)))
           (list :status :ok :mode mode :pid (sb-posix:getpid)))
      (close-socket socket))))
