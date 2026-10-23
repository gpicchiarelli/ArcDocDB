;;;; C4: attesa fuori dall'adattatore; codec/frame possono ancora allocare.
;;; REQ: REQ-VAL-001 REQ-IPC-002
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defun finish-io-span (socket span &optional allow-eof)
  "Supervisione C4 limitata: ogni passo e una syscall, mai FD/SAP prestati oltre il passo."
  (loop repeat (+ 1000 (* 3 (- (io-span-end span) (io-span-start span)))) do
    (let ((status (io-step span (get-internal-real-time))))
      (case status
        (:done (return-from finish-io-span span))
        (:eof (if allow-eof (return-from finish-io-span span)
                  (error 'rejection :reason :truncated)))
        (:progress nil)
        ((:would-block :interrupted) (wait-socket socket (io-span-direction span) (io-span-until span)))
        (:expired (error 'rejection :reason :deadline))
        (otherwise (error 'rejection :reason :io-fault)))))
  (error 'rejection :reason :io-step-bound))

(defun native-send-bytes (socket input chunk until)
  "Fixture C4 copiata una volta nel buffer posseduto; nessuna slice per passo nativo."
  (let* ((buffer (io-guarded-buffer (length input)))
         (span (make-io-span (sb-bsd-sockets:socket-file-descriptor socket) buffer 2
                            (+ 2 (length input)) :output chunk until (get-internal-real-time))))
    (replace buffer input :start1 2)
    (finish-io-span socket span)
    (check-io-content buffer input)
    (io-span-calls span)))

(defun native-read-fixed (socket size chunk until)
  "Buffer C4 creato prima dello span; guardie verificate prima di estrarre la fixture."
  (let* ((buffer (io-guarded-buffer size))
         (span (make-io-span (sb-bsd-sockets:socket-file-descriptor socket)
                            buffer 2 (+ 2 size) :input chunk until (get-internal-real-time))))
    (finish-io-span socket span)
    (check-io-guards buffer)
    (subseq buffer 2 (+ 2 size))))

(defun native-receive-count (socket count chunk until)
  "Il prefisso di controllo viene validato prima del buffer del corpo C4."
  (loop repeat count collect
    (let* ((header (native-read-fixed socket 4 chunk until))
           (size (loop for byte across header for value = byte then (+ (ash value 8) byte)
                       finally (return value))))
      (demand (<= 1 size 4096) :length)
      (native-read-fixed socket size chunk until))))

(defun client-native-session (socket until)
  "Client nativo contro server precedente, con gli stessi golden byte indipendenti."
  (native-send-bytes socket (frame (hello-wire)) 1 until)
  (same-frames (native-receive-count socket 1 1 until)
               (list (bytes #x85 1 1 0 0 #xa3 0 #x19 #x10 0 1 2 2 #x81 0)))
  (native-send-bytes socket (concatenate 'io-octets (frame (ping 1)) (frame (ping 2))) 64 until)
  (same-frames (native-receive-count socket 2 1 until) (list (ping 2 3) (ping 1 3)))
  t)

(defun server-native-session (socket until)
  "Sessione C4 invariata; soltanto il server usa recv/send su span posseduti."
  (let* ((session (make-model-session))
         (hello (first (native-receive-count socket 1 1 until)))
         (welcome (model-hello session hello 0)))
    (native-send-bytes socket (frame welcome) 1 until)
    (model-welcome-sent session 0)
    (dolist (request (native-receive-count socket 2 64 until)) (model-request session request 0))
    (dolist (id '(2 1))
      (let ((response (model-response session id)))
        (native-send-bytes socket response 1 until)
        (model-sent session id (length response) 0)))
    (demand (zerop (model-session-queued-bytes session)) :sent-credit)
    (list :status :ok :native-side :server :response-order '(2 1) :engine-called nil)))

(defun server-native-truncated (socket until)
  "EOF reale dopo cinque byte in uno span da dieci: progresso preservato."
  (let* ((buffer (io-guarded-buffer 10))
         (span (make-io-span (sb-bsd-sockets:socket-file-descriptor socket)
                            buffer 2 12 :input 3 until (get-internal-real-time))))
    (finish-io-span socket span t)
    (demand (and (eq :eof (io-span-state span)) (= 7 (io-span-cursor span))) :io-partial-eof)
    (same-frames (list (subseq buffer 2 7)) (list (bytes 0 0 0 6 #x85)))
    (check-io-guards buffer)
    (let ((calls (io-span-calls span)))
      (demand (eq :eof (io-step span (get-internal-real-time))) :io-terminal)
      (demand (= calls (io-span-calls span)) :io-call-count))
    (list :status :ok :confirmed-bytes 5 :state :eof)))

(defun call-with-native-pair (directory function)
  "Coppia locale con listener/FD posseduti e chiusura dopo il callback sincrono."
  (let* ((path (concatenate 'string directory "/native.sock")) (listener (new-socket))
         (client (new-socket)) (peer nil) (identity nil))
    (unwind-protect
         (progn
           (bind-unoccupied listener path)
           (setf identity (node-identity path))
           (sb-bsd-sockets:socket-listen listener 1)
           (connect-local client path (deadline))
           (wait-socket listener :input (deadline))
           (setf peer (sb-bsd-sockets:socket-accept listener))
           (demand peer :accept-interrupted)
           (setf (sb-bsd-sockets:non-blocking-mode peer) t)
           (funcall function client peer))
      (close-socket peer) (close-socket client) (close-socket listener)
      (when identity (unlink-owned path identity)))))

(defun check-native-empty-and-closed (client peer)
  "EAGAIN reale e peer chiuso; SIGPIPE non deve terminare lo spike."
  (let* ((buffer (io-guarded-buffer 4)) (fd (sb-bsd-sockets:socket-file-descriptor client))
         (read (make-io-span fd buffer 2 6 :input 4 (deadline) (get-internal-real-time))))
    (demand (eq :would-block (io-step read (get-internal-real-time))) :io-empty-recv)
    (demand (= 2 (io-span-cursor read)) :io-offset)
    (check-io-guards buffer)
    (close-socket peer)
    (let ((write (make-io-span fd buffer 2 6 :output 4 (deadline) (get-internal-real-time))))
      (demand (eq :faulted (io-step write (get-internal-real-time))) :io-closed-send)
      (demand (member (io-span-errno write) (list sb-posix:epipe sb-posix:econnreset)) :io-errno)
      (demand (= 2 (io-span-cursor write)) :io-offset)
      (list :status :ok :empty-errno (io-span-errno read) :closed-errno (io-span-errno write)
            :sigpipe-survived t))))

(defun check-native-saturation (client peer)
  "Nessun reader: entro 64 MiB/65536 passi il socket deve produrre EAGAIN."
  (declare (ignore peer))
  (setf (sb-bsd-sockets:sockopt-send-buffer client) 4096)
  (let* ((buffer (make-array (* 64 1024 1024) :element-type '(unsigned-byte 8) :initial-element 7))
         (span (make-io-span (sb-bsd-sockets:socket-file-descriptor client) buffer 0
                            (length buffer) :output 65536 (deadline) (get-internal-real-time))))
    (loop repeat 65536 do
      (let ((before (io-span-cursor span)) (status (io-step span (get-internal-real-time))))
        (case status
          (:would-block
           (demand (and (plusp before) (= before (io-span-cursor span))) :io-saturation-progress)
           (return-from check-native-saturation
             (list :status :ok :confirmed-bytes before :calls (io-span-calls span)
                   :errno (io-span-errno span) :state (io-span-state span))))
          (:progress nil)
          (otherwise (error 'rejection :reason :io-saturation-status)))))
    (error 'rejection :reason :io-saturation-bound)))

(defun native-allocation-window (send receive iterations)
  "Solo passi e reset dei due contesti gia preallocati; nessun clock/attesa/report."
  (declare (type io-span send receive) (type (integer 1 100000) iterations))
  (let ((before (sb-ext:get-bytes-consed)))
    (dotimes (i iterations)
      (setf (io-span-state send) :active (io-span-cursor send) 2
            (io-span-state receive) :active (io-span-cursor receive) 2)
      (demand (eq :done (io-step send 0)) :io-allocation-send)
      (demand (eq :done (io-step receive 0)) :io-allocation-recv))
    (values before (sb-ext:get-bytes-consed))))

(defun native-empty-window (span iterations)
  "Recv EAGAIN senza condizioni Lisp per il percorso ordinario di attesa."
  (declare (type io-span span) (type (integer 1 100000) iterations))
  (setf (io-span-state span) :active (io-span-cursor span) 2)
  (let ((before (sb-ext:get-bytes-consed)))
    (dotimes (i iterations) (demand (eq :would-block (io-step span 0)) :io-allocation-empty))
    (values before (sb-ext:get-bytes-consed))))

(defun check-native-allocations (client peer)
  "Contatore Lisp con controllo positivo; non misura malloc/kernel/RSS o il ciclo di vita."
  (let* ((input (io-guarded-buffer 1)) (output (io-guarded-buffer 1))
         (send (make-io-span (sb-bsd-sockets:socket-file-descriptor client) input 2 3 :output 1 1 0))
         (receive (make-io-span (sb-bsd-sockets:socket-file-descriptor peer) output 2 3 :input 1 1 0))
         (positive (make-array 32 :initial-element nil)))
    (native-allocation-window send receive 32)
    (native-empty-window receive 32)
    (multiple-value-bind (start stop) (native-allocation-window send receive 4096)
      (multiple-value-bind (empty-start empty-stop) (native-empty-window receive 4096)
        (let ((positive-start (sb-ext:get-bytes-consed)))
          (dotimes (i 32) (setf (aref positive i) (make-array 65536 :element-type '(unsigned-byte 8))))
          (let ((positive-stop (sb-ext:get-bytes-consed)))
            ;; Il contatore SBCL non e una somma esatta dei payload richiesti:
            ;; il controllo deve rilevare il MiB noto, non uguagliare byte/regioni.
            (demand (> (- positive-stop positive-start) 1048576) :io-allocation-counter)
            (demand (every (lambda (array) (= 65536 (length array))) positive) :io-allocation-sink)
            (demand (and (= start stop) (= empty-start empty-stop)) :io-allocation-observed)
            (demand (= #xa5 (aref output 2)) :io-content)
            (check-io-guards input) (check-io-guards output)
            (list :status :ok :iterations 4096 :success-before start :success-after stop
                  :success-bytes-consed (- stop start) :empty-before empty-start :empty-after empty-stop
                  :empty-bytes-consed (- empty-stop empty-start)
                  :positive-control-payload (* 32 65536) :positive-before positive-start
                  :positive-minimum-detected 1048576
                  :positive-after positive-stop :positive-bytes-consed (- positive-stop positive-start)
                  :native-allocator-traced nil)))))))

(defun check-native-io (directory)
  "Unisce fault injection, socket reali e osservazioni limitate dell'allocazione."
  (check-io-platform)
  (list :status :ok :scripts (check-io-scripts)
        :empty-and-closed (call-with-native-pair directory #'check-native-empty-and-closed)
        :saturation (call-with-native-pair directory #'check-native-saturation)
        :allocation (call-with-native-pair directory #'check-native-allocations)
        :disassembly (loop for name in '(native-recv-span native-send-span io-step)
                           collect (list :function (symbol-name name)
                                         :code (with-output-to-string (*standard-output*)
                                                 (let ((*print-readably* nil))
                                                   (disassemble (symbol-function name))))))))
