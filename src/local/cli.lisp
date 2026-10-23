;;; OWNER: processo CLI dedicato; dati esterni soltanto hex e argomenti verificati.
;;; SHARED: nessun reader Lisp, configurazione implicita o file di coordinamento test.
(in-package #:arcdocdb.local)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IPC-001 REQ-AFF-008
(defun local-unhex (text maximum &optional exact)
  "Pre: argomento CLI non fidato. Post: ottetti finiti; nessun reader o codice esterno."
  (unless (and (stringp text) (evenp (length text)) (<= 2 (length text) (* 2 maximum))
               (or (null exact) (= (length text) (* 2 exact))))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-cli-hex-length))
  (let ((result (make-array (/ (length text) 2) :element-type '(unsigned-byte 8))))
    (dotimes (i (length result) result)
      (let ((high (digit-char-p (char text (* i 2)) 16))
            (low (digit-char-p (char text (1+ (* i 2))) 16)))
        (unless (and high low)
          (error 'arcdocdb.conditions:invalid-argument :reason :local-cli-hex-digit))
        (setf (aref result i) (+ (* high 16) low))))))

;;; REQ: REQ-IPC-001 REQ-AFF-008
(defun local-hex (bytes)
  "Pre: risultato octets autorizzato. Post: rappresentazione hex senza contenuto Lisp."
  (let ((result (make-string (* 2 (length bytes)))) (digits "0123456789ABCDEF"))
    (dotimes (i (length bytes) result)
      (let ((byte (aref bytes i)))
        (setf (char result (* 2 i)) (char digits (ash byte -4))
              (char result (1+ (* 2 i))) (char digits (logand byte 15)))))))

;;; REQ: REQ-IPC-001 REQ-REC-001
(defun server-cli-options (args)
  "Pre: opzioni residue CLI. Post: init/version espliciti senza duplicati."
  (let ((create nil) (version 2) (seen-version nil))
    (loop while args do
      (let ((option (pop args)))
        (cond ((and (string= option "--create") (not create)) (setf create t))
              ((and (string= option "--version") args (not seen-version)
                    (member (first args) '("1" "2") :test #'string=))
               (setf version (if (string= (pop args) "1") 1 2) seen-version t))
              (t (error 'arcdocdb.conditions:invalid-argument :reason :local-cli-option)))))
    (values create version)))

;;; REQ: REQ-IPC-001 REQ-IPC-002 REQ-REC-001
(defun server-cli-main (args)
  "Pre: processo dedicato, DATA SOCKET ARCHIVE32 SERIES32 [--create] [--version 1|2].
Post: servizio reale fino a SIGTERM/SIGINT, poi cleanup; stampa READY solo dopo listen."
  (unless (<= 4 (length args) 7)
    (error 'arcdocdb.conditions:invalid-argument :reason :local-server-cli-arguments))
  (multiple-value-bind (create version) (server-cli-options (nthcdr 4 args))
    (let ((stopping nil))
      (flet ((stop-signal (signal info context)
               (declare (ignore signal info context)) (setf stopping t)))
        (sb-sys:enable-interrupt sb-posix:sigterm #'stop-signal)
        (sb-sys:enable-interrupt sb-posix:sigint #'stop-signal)
        (serve-local (first args) (local-unhex (third args) 16 16)
          (local-unhex (fourth args) 16 16) (second args) :create create :version version
          :stop (lambda () stopping)
          :ready (lambda ()
                   (format t "~S~%" (list :kind :local-server :state :ready :pid (sb-posix:getpid)))
                   (finish-output) nil))))))

;;; REQ: REQ-IPC-001 REQ-IPC-002
(defun client-cli-command (client operation args)
  "Pre: connessione negoziata e numero argomenti verificato. Post: risultato del comando reale."
  (cond
    ((string= operation "ping") (client-ping client) (list :operation :ping :result nil))
    ((string= operation "put")
     (list :operation :put :csn
           (client-put client (local-unhex (first args) 1024) (local-unhex (second args) 60000))))
    ((string= operation "delete")
     (list :operation :delete :csn (client-delete client (local-unhex (first args) 1024))))
    (t (multiple-value-bind (status document) (client-get client (local-unhex (first args) 1024))
         (list :operation :get :found (eq status :found) :document (and document (local-hex document)))))))

;;; REQ: REQ-IPC-001 REQ-AFF-008
(defun client-cli-main (args)
  "Pre: SOCKET ping|get KEY|delete KEY|put KEY DOCUMENT, ottetti hex. Post: una risposta verificata.
Nessun retry; un errore dopo l'invio di una mutazione resta OUTCOME-UNKNOWN."
  (unless (and (<= 2 (length args) 4)
               (= (length args) (cond ((string= (second args) "ping") 2)
                                     ((string= (second args) "put") 4)
                                     ((member (second args) '("get" "delete") :test #'string=) 3)
                                     (t -1))))
    (error 'arcdocdb.conditions:invalid-argument :reason :local-client-cli-arguments))
  (let ((client (connect-local (first args))) (primary nil))
    (unwind-protect
         (handler-case
             (progn (format t "~S~%" (list* :kind :local-client
                                             (client-cli-command client (second args) (cddr args))))
                    (finish-output) nil)
           (error (condition) (setf primary condition) (error condition)))
      (handler-case (close-local client)
        (error (cleanup)
          (error 'local-cleanup-error :reason :local-cli-cleanup
                 :primary primary :failures (list cleanup)))))))
