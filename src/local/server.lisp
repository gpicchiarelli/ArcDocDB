;;; OWNER: un attore seriale, otto slot massimi; attese peer fuori dalle chiamate del motore.
;;; SHARED: listener locale dopo recovery; nessun thread o stato globale per richiesta.
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-002 REQ-AFF-001
(defun local-transfer-step (socket buffer start end direction &optional io-backend)
  "Pre: socket posseduto e span valido. Post: un passo nativo, progresso/wait/EOF; niente retry.
EINTR/EAGAIN tornano al giro dell'attore conservando offset e deadline assoluta."
  (unless (and (typep buffer 'b:octets) (member direction '(:input :output))
               (<= 0 start end (length buffer)) (< start end))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-transfer-span))
  (let ((fd socket))
    (multiple-value-bind (n errno)
        (if (eq direction :input) (native-recv-span fd buffer start (- end start) io-backend)
            (native-send-span fd buffer start (- end start) io-backend))
      (cond ((and (integerp n) (< 0 n) (<= n (- end start))) (values :progress n))
            ((and (eql n -1) (member errno (list sb-posix:eintr sb-posix:eagain sb-posix:ewouldblock)))
             (values :wait 0))
            ((and (eql n 0) (eq direction :input)) (values :eof 0))
            (t (error 'arcdocdb.conditions:io-fault :reason :local-transfer
                      :operation direction :errno (and (typep errno 'fixnum) errno)))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun local-prefix-size (buffer limit)
  "Pre: quattro byte ricevuti nel buffer posseduto. Post: corpo valido prima di riceverlo."
  (let ((size (logior (ash (aref buffer 0) 24) (ash (aref buffer 1) 16)
                      (ash (aref buffer 2) 8) (aref buffer 3))))
    (unless (<= 1 size limit) (error 'protocol-error :reason :local-frame-length))
    size))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun close-local-connection (connection)
  "Pre: slot dell'attore. Post: ownership consumata prima di close, anche se close fallisce."
  (let ((socket (local-connection-socket connection)))
    (setf (local-connection-socket connection) nil (local-connection-state connection) :closed)
    (when socket (close-local-socket socket)))
  nil)

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun reset-local-input (connection now)
  "Pre: risposta interamente inviata. Post: sola richiesta successiva, nessun residuo riusato."
  (setf (local-connection-received connection) 0 (local-connection-needed connection) 4
        (local-connection-written connection) 0 (local-connection-size connection) 0
        (local-connection-frame-started connection) nil (local-connection-state connection) :request
        (local-connection-idle connection) (local-until now 300))
  nil)

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun queue-local-output (connection size state now)
  "Pre: frame completo gia' copiato nel buffer riservato. Post: deadline non rinnovabile all'invio."
  (unless (<= 5 size (+ 4 (local-connection-limit connection)))
    (error 'arcdocdb.conditions:invariant-violation :reason :local-response-budget))
  (setf (local-connection-written connection) 0 (local-connection-size connection) size
        (local-connection-state connection) state (local-connection-deadline connection) (local-until now 30))
  nil)

;;; REQ: REQ-IPC-002 REQ-REC-001
(defun finish-local-input (engine connection clock)
  "Pre: corpo esatto ricevuto. Post: WELCOME o risposta prenotata; mai richiesta prima di WELCOME."
  (let* ((buffer (local-connection-input connection))
         (envelope (decode-local-envelope buffer 4 (local-connection-needed connection)
                     :space (local-connection-space connection))))
    (if (eq :hello (local-connection-state connection))
        (multiple-value-bind (frame inflight) (decode-local-hello buffer envelope)
          (declare (ignore inflight)) ; il profilo negozia sempre un solo lavoro in volo.
          (setf (local-connection-limit connection) (min 65536 frame))
          (queue-local-output connection
            (encode-local-welcome (local-connection-output connection) (local-connection-limit connection))
            :welcome (local-now clock)))
        (let ((id (envelope-id envelope)))
          (unless (and (= 2 (envelope-kind envelope)) (< (local-connection-last-id connection) id))
            (error 'protocol-error :reason :local-request-id))
          (setf (local-connection-last-id connection) id)
          (let ((size (local-dispatch engine connection envelope)))
            (queue-local-output connection size :response (local-now clock)))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun step-local-input (engine connection now clock)
  "Pre: slot en HELLO/REQUEST. Post: al piu' un recv, prefisso verificato prima del corpo."
  (multiple-value-bind (status count)
      (local-transfer-step (local-connection-socket connection) (local-connection-input connection)
        (local-connection-received connection) (local-connection-needed connection) :input
        (local-connection-io-backend connection))
    (case status
      (:eof (close-local-connection connection))
      (:progress
       (unless (local-connection-frame-started connection)
         (setf (local-connection-frame-started connection) t)
         (unless (eq :hello (local-connection-state connection))
           (setf (local-connection-deadline connection) (local-until now 30))))
       (incf (local-connection-received connection) count)
       (when (= (local-connection-received connection) (local-connection-needed connection))
         (if (= 4 (local-connection-needed connection))
             (setf (local-connection-needed connection)
                   (+ 4 (local-prefix-size (local-connection-input connection) (local-connection-limit connection))))
             (finish-local-input engine connection clock)))))
    (eq status :progress)))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun step-local-output (connection now)
  "Pre: risposta riservata, nessun pin EBR. Post: un send, conservazione fino all'ultimo byte."
  (multiple-value-bind (status count)
      (local-transfer-step (local-connection-socket connection) (local-connection-output connection)
        (local-connection-written connection) (local-connection-size connection) :output
        (local-connection-io-backend connection))
    (when (eq status :progress)
      (incf (local-connection-written connection) count)
      (when (= (local-connection-written connection) (local-connection-size connection))
        (if (= (local-connection-last-id connection) #xffffffffffffffff)
            (close-local-connection connection) (reset-local-input connection now))))
    (eq status :progress)))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun step-local-connection (engine connection now clock)
  "Pre: slot attivo nell'attore. Post: passo finito o scadenza; un peer non arresta gli altri."
  (let ((state (local-connection-state connection)))
    (unless (eq state :closed)
      (cond
        ((>= now (if (and (eq state :request) (not (local-connection-frame-started connection)))
                     (local-connection-idle connection) (local-connection-deadline connection)))
         (close-local-connection connection) t)
        ((member state '(:welcome :response)) (step-local-output connection now))
        (t (step-local-input engine connection now clock))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(defun accept-local-connection (listener connections now)
  "Pre: listener non bloccante. Post: al piu' un accept; senza slot il nuovo peer viene chiuso."
  (let ((socket (accept-local-socket listener)))
    (when socket
      (let ((slot (find :closed connections :key #'local-connection-state)))
        (if slot
            (progn
              (setf (local-connection-socket slot) socket (local-connection-last-id slot) 0
                    (local-connection-limit slot) 4096)
              (reset-local-input slot now)
              (setf (local-connection-state slot) :hello (local-connection-deadline slot) (local-until now 5)))
            (close-local-socket socket)))
      t)))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(defun local-server-loop (engine listener connections clock stop)
  "Pre: READY, tutte le risorse riservate. Post: arresto esplicito o errore motore propagato.
Ogni giro visita tutti gli slot una volta; attesa inattiva finita senza servire eventi estranei."
  (loop until (funcall stop) do
    (let* ((now (local-now clock)) (progress (accept-local-connection listener connections now)))
      (loop for connection across connections do
        (handler-case
            (when (step-local-connection engine connection (local-now clock) clock) (setf progress t))
          (protocol-error (condition)
            (unless (eq :ready (e:stato-motore engine)) (error condition))
            (close-local-connection connection))
          (arcdocdb.conditions:io-fault (condition)
            (unless (eq :ready (e:stato-motore engine)) (error condition))
            (close-local-connection connection))))
      (unless progress (sleep 0.001))))
  nil)

;;; REQ: REQ-IPC-003 REQ-AFF-004
(defun cleanup-local-server (connections listener engine namespace primary)
  "Pre: admission fermata. Post: tutte le risorse tentate; primaria e secondarie conservate."
  (let ((failures nil))
    (flet ((attempt (function)
             (handler-case (funcall function) (error (condition) (push condition failures)))))
      (loop for connection across connections do (attempt (lambda () (close-local-connection connection))))
      (when listener (attempt (lambda () (close-local-listener listener))))
      (when engine (attempt (lambda () (e:chiudi-motore engine))))
      (when namespace
        (attempt (lambda ()
                   (dolist (failure (close-local-namespace namespace)) (push failure failures))))))
    (when failures
      (error 'local-cleanup-error :reason :local-server-cleanup :primary primary :failures (nreverse failures))))
  nil)

;;; REQ: REQ-IPC-001 REQ-IPC-002 REQ-IPC-003 REQ-REC-001
(defun serve-local (directory archive-id series-id path
                    &key create (version 2) (clock #'get-internal-real-time) observer
                         (stop (constantly nil)) ready (max-connections 8) io-backend)
  "Pre: directory dati/runtime distinte e private, identita' esplicite, un attore chiamante.
Post: startup e recovery reali prima del listener; servizio fino a STOP, cleanup completo.
Callback fidati non rientrabili; STOP/READY non sono certificazioni del recovery. Nessun retry."
  (unless (and (functionp clock) (functionp stop) (typep ready '(or null function))
               (typep max-connections '(integer 1 8)))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-server-config))
  (%native-check-backend io-backend)
  (local-until (local-now clock) 300)
  (let ((connections (map 'simple-vector (lambda (i) (declare (ignore i))
                                         (make-local-connection :io-backend io-backend))
                          (make-array max-connections)))
        (engine nil) (listener nil) (namespace nil) (primary nil) (space (arcdocdb.cbor:crea-spazio-cbor)))
    (unwind-protect
         (handler-case
             (progn
               (setf namespace (open-local-namespace path))
               (let ((stat (sb-posix:stat (namestring (pathname directory)))))
                 (multiple-value-bind (device inode) (local-namespace-identity namespace)
                   (when (and (= device (sb-posix:stat-dev stat)) (= inode (sb-posix:stat-ino stat)))
                     (error 'arcdocdb.conditions:invalid-argument :reason :local-runtime-is-storage))))
               (setf engine (e:apri-motore directory archive-id series-id :create create :version version
                              :clock clock :observer observer :record-validator (local-record-validator space)))
               (unless (eq :ready (e:stato-motore engine))
                 (error 'arcdocdb.conditions:invariant-violation :reason :local-startup-gate))
               (setf listener (open-local-listener path :namespace namespace))
               (when (and ready (funcall ready))
                 (error 'arcdocdb.conditions:invalid-argument :reason :local-ready-result))
               (local-server-loop engine listener connections clock stop))
           (error (condition) (setf primary condition) (error condition)))
      (cleanup-local-server connections listener engine namespace primary))))
