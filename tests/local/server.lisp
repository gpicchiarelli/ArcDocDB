(defpackage #:arcdocdb.local.server.tests
  (:use #:cl)
  (:local-nicknames (#:l #:arcdocdb.local) (#:e #:arcdocdb.engine))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:export #:run))
(in-package #:arcdocdb.local.server.tests)
(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun bytes (&rest values)
  (make-array (length values) :element-type '(unsigned-byte 8) :initial-contents values))
(defun id (n) (make-array 16 :element-type '(unsigned-byte 8) :initial-element n))
(defun engine (root &key create observer)
  (e:apri-motore root (id 73) (id 41) :create create :clock (lambda () 10) :observer observer
    :index-capacity 32 :key-arena-bytes 4096))
(defun request (connection id opcode key document)
  (let* ((buffer (l::local-connection-input connection))
         (end (l::encode-local-request buffer id opcode key document)))
    (l::decode-local-envelope buffer 4 end)))
(defun dispatch (engine connection id opcode &optional key document)
  (let* ((end (l::local-dispatch engine connection (request connection id opcode key document)))
         (envelope (l::decode-local-envelope (l::local-connection-output connection) 4 end)))
    (values (l::envelope-code envelope) envelope)))
(defun decoded-result (connection envelope opcode)
  (l::decode-local-response (l::local-connection-output connection) envelope
    (l::local-connection-space connection) opcode))
(defmacro with-engine ((engine root &rest options) &body body)
  `(arcdocdb.engine.tests::with-root (,root)
     (let ((,engine (engine ,root ,@options)))
       (unwind-protect (progn ,@body) (e:chiudi-motore ,engine)))))

;;; REQ: REQ-IPC-002 REQ-WAL-006 REQ-IDX-001
(deftest test-REQ-IPC-002-dispatch-real-strong-put-get-delete
  (with-engine (engine root :create t)
    (let ((connection (l::make-local-connection :limit 65536)))
      (multiple-value-bind (status envelope) (dispatch engine connection 1 1 (bytes 5) (bytes #x18 #x2a))
        (is (zerop status)) (is (= 1 (decoded-result connection envelope 1))))
      (multiple-value-bind (status envelope) (dispatch engine connection 2 2 (bytes 5))
        (is (zerop status))
        (multiple-value-bind (found document) (decoded-result connection envelope 2)
          (is (eq found :found)) (is (equalp document (bytes #x18 #x2a)))))
      (multiple-value-bind (status envelope) (dispatch engine connection 3 3 (bytes 5))
        (is (zerop status)) (is (= 2 (decoded-result connection envelope 3))))
      (multiple-value-bind (status envelope) (dispatch engine connection 4 2 (bytes 5))
        (is (zerop status))
        (is (equal '(:absent nil) (multiple-value-list (decoded-result connection envelope 2))))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003 REQ-WAL-006
(deftest test-REQ-IPC-002-get-frame-budget-before-admission
  (with-engine (engine root :create t)
    (let ((connection (l::make-local-connection :limit 4096)))
      (is (= 5 (dispatch engine connection 1 2 (bytes 1))))
      (is (eq :ready (e:stato-motore engine)))
      (is (equal '(0 0 0 0) (multiple-value-list (e:frontiere-motore engine)))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003 REQ-WAL-006
(deftest test-REQ-IPC-002-index-busy-never-committed
  (with-engine (engine root :create t)
    (let ((connection (l::make-local-connection :limit 65536)))
      (loop for n from 1 to 28 do (is (zerop (dispatch engine connection n 1 (bytes n) (bytes 0)))))
      (let ((originals (arcdocdb.engine.tests::images root)))
        (is (= 2 (dispatch engine connection 29 1 (bytes 29) (bytes 0))))
        (is (eq :ready (e:stato-motore engine)))
        (is (equal '(0 28 0 28) (multiple-value-list (e:frontiere-motore engine))))
        (arcdocdb.engine.tests::check-images root originals)))))

;;; REQ: REQ-IPC-002 REQ-AFF-004 REQ-WAL-006
(deftest test-REQ-IPC-002-post-commit-fault-is-not-busy
  (let ((cause (make-condition 'arcdocdb.conditions:io-fault :reason :local-fi :operation :test)))
    (with-engine (engine root :create t
                         :observer (lambda (engine phase)
                                     (declare (ignore engine))
                                     (when (eq phase :after-commit) (error cause)) nil))
      (let ((connection (l::make-local-connection :limit 65536)) (seen nil))
        (handler-case (dispatch engine connection 1 1 (bytes 1) (bytes 0))
          (arcdocdb.conditions:io-fault (condition) (is (eq cause condition)) (setf seen t)))
        (is seen) (is (eq :faulted (e:stato-motore engine)))))))

;;; REQ: REQ-IPC-002 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-IPC-002-incompatible-recovery-before-checkpoint
  (arcdocdb.engine.tests::with-root (root)
    (let ((engine (engine root :create t)))
      (unwind-protect (e:scrivi-documento engine (bytes 1) (bytes #xff)) (e:chiudi-motore engine)))
    (let ((originals (arcdocdb.engine.tests::images root)))
      (signals arcdocdb.conditions:corruption-detected
        (e:apri-motore root (id 73) (id 41) :clock (lambda () 10)
          :record-validator (l::local-record-validator (arcdocdb.cbor:crea-spazio-cbor))))
      (arcdocdb.engine.tests::check-images root originals))
    (let ((engine (engine root)))
      (unwind-protect (is (eq :ready (e:stato-motore engine))) (e:chiudi-motore engine)))))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-client-owner-and-id-exhaustion
  (let ((client (l::make-local-client :state :ready :next-id 18446744073709551616)) (rejected nil))
    (signals arcdocdb.conditions:resource-exhausted (l:client-ping client))
    (is (eq :ready (l::local-client-state client)))
    (sb-thread:join-thread
     (sb-thread:make-thread
      (lambda ()
        (handler-case (l:close-local client)
          (arcdocdb.conditions:invalid-argument () (setf rejected t))))))
    (is rejected) (l:close-local client) (l:close-local client)
    (signals arcdocdb.conditions:invalid-argument (l:client-ping client))))

(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  t)

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-deadlines-close-only-expired-slot
  (dolist (state '(:hello :request :response))
    (let ((expired (l::make-local-connection :state state :deadline 30 :idle 30))
          (other (l::make-local-connection :state :request :deadline 99 :idle 99)))
      (is (l::step-local-connection nil expired 30 (lambda () 30)))
      (is (eq :closed (l::local-connection-state expired)))
      (is (eq :request (l::local-connection-state other)))
      (is (= 99 (l::local-connection-idle other))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-partial-progress-never-renews-deadline
  (let* ((backend (l::make-native-backend
                    :recv (lambda (fd buffer start count)
                            (declare (ignore fd count)) (setf (aref buffer start) 0) (values 1 0))
                    :send (lambda (fd buffer start count)
                            (declare (ignore fd buffer start count)) (values 1 0))))
         (input (l::make-local-connection :state :request
                                         :idle (l::local-until 0 300) :io-backend backend))
         (output (l::make-local-connection :state :response
                                          :deadline (l::local-until 0 30) :size 10 :io-backend backend)))
    (unwind-protect
         (progn
           (setf (l::local-connection-socket input) (l::new-local-socket)
                 (l::local-connection-socket output) (l::new-local-socket))
           (is (l::step-local-connection nil input 10 (lambda () 10)))
           (let ((deadline (l::local-connection-deadline input)))
             (is (= deadline (l::local-until 10 30)))
             (is (l::step-local-connection nil input 20 (lambda () 20)))
             (is (= deadline (l::local-connection-deadline input)))
             (is (= 2 (l::local-connection-received input)))
             (is (l::step-local-connection nil input deadline (lambda () deadline)))
             (is (eq :closed (l::local-connection-state input))))
           (let ((deadline (l::local-connection-deadline output)))
             (is (l::step-local-connection nil output 10 (lambda () 10)))
             (is (l::step-local-connection nil output 20 (lambda () 20)))
             (is (= 2 (l::local-connection-written output)))
             (is (= deadline (l::local-connection-deadline output)))
             (is (l::step-local-connection nil output deadline (lambda () deadline)))
             (is (eq :closed (l::local-connection-state output)))))
      (l::close-local-connection input) (l::close-local-connection output))))
