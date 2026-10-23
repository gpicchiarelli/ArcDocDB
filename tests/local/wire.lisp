;;;; Fixture wire indipendenti dal writer prodotto. Suite da eseguire solo dopo il freeze.
(defpackage #:arcdocdb.local.wire.tests
  (:use #:cl)
  (:local-nicknames (#:l #:arcdocdb.local) (#:cbor #:arcdocdb.cbor))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:export #:run #:run-local-wire-tests))
(in-package #:arcdocdb.local.wire.tests)
(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun bytes (&rest values)
  (make-array (length values) :element-type '(unsigned-byte 8) :initial-contents values))
(defun output (&optional (size l:+output-buffer-size+))
  (make-array size :element-type '(unsigned-byte 8) :initial-element #xcc))
(defun join (&rest parts)
  (apply #'concatenate '(simple-array (unsigned-byte 8) (*)) parts))
(defun uint (value &optional (major 0))
  "Fixture indipendente: header minimo big endian, senza chiamare il codec prodotto."
  (let* ((width (cond ((< value 24) 0) ((<= value #xff) 1) ((<= value #xffff) 2)
                      ((<= value #xffffffff) 4) (t 8)))
         (result (make-array (1+ width) :element-type '(unsigned-byte 8))))
    (setf (aref result 0) (logior (ash major 5)
                                (if (zerop width) value (+ 24 (position width '(1 2 4 8))))))
    (dotimes (i width)
      (setf (aref result (1+ i)) (ldb (byte 8 (* 8 (- width i 1))) value)))
    result))
(defun bstr (data) (join (uint (length data) 2) data))
(defun body (kind id code payload)
  (join (bytes #x85 1) (uint kind) (uint id) (uint code) payload))
(defun framed (data)
  (let ((prefix (bytes 0 0 0 0)) (size (length data)))
    (dotimes (i 4) (setf (aref prefix i) (ldb (byte 8 (* 8 (- 3 i))) size)))
    (join prefix data)))
(defun request (opcode payload &optional (id 1)) (framed (body 2 id opcode payload)))
(defun hello (frame inflight)
  (framed (body 0 0 0 (join (bytes #xa2 0) (uint frame) (bytes 1) (uint inflight)))))
(defun envelope (wire &rest options)
  (multiple-value-bind (size next) (l:read-frame-length wire 0 (length wire))
    (unless (= (+ size next) (length wire))
      (error 'l:protocol-error :reason :test-frame-truncated))
    (apply #'l:decode-local-envelope wire next (length wire) options)))
(defun command-status (wire &rest options)
  (l:decode-local-command wire (apply #'envelope wire options) (cbor:crea-spazio-cbor)))
(defun get-document (size)
  "Un item bstr CBOR di SIZE byte totali; contenuto binario che include NUL e FF."
  (let* ((width (cond ((<= size 24) 1) ((<= size 257) 2) (t 3)))
         (content (make-array (- size width) :element-type '(unsigned-byte 8) :initial-element #xff)))
    (when (plusp (length content)) (setf (aref content 0) 0))
    (bstr content)))
(defun raw-put (key document &optional (id 1))
  (request 1 (join (bytes #x82) (bstr key) (bstr document)) id))
(defun response (opcode payload &optional (status 0))
  (let* ((wire (framed (body 3 1 status payload))) (env (envelope wire)))
    (l:decode-local-response wire env (cbor:crea-spazio-cbor) opcode)))

;;; REQ: REQ-IPC-002
(deftest test-REQ-IPC-002-independent-ping-and-hello-fixtures
  (let ((out (output)))
    (let ((end (l:encode-local-request out 1 0 nil nil)))
      (is (equalp (bytes 0 0 0 6 #x85 1 2 1 0 #xf6) (subseq out 0 end)))
      (is (= 0 (command-status (subseq out 0 end)))))
    (let ((end (l:encode-local-response out 1 0)))
      (is (equalp (bytes 0 0 0 6 #x85 1 3 1 0 #xf6) (subseq out 0 end)))
      (is (null (response 0 (bytes #xf6)))))
    (let ((end (l:encode-local-hello out 4096)))
      (is (equalp (bytes 0 0 0 12 #x85 1 0 0 0 #xa2 0 #x19 #x10 0 1 1)
                  (subseq out 0 end))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-exact-welcome-capacities
  (let* ((out (output)) (end (l:encode-local-welcome out 65536))
         (wire (subseq out 0 end)) (env (envelope wire)))
    (is (equalp (bytes 0 0 0 20 #x85 1 1 0 0 #xa3 0 #x1a 0 1 0 0 1 1 2 #x84 0 1 2 3) wire))
    (multiple-value-bind (frame inflight) (l:decode-local-welcome wire env)
      (is (= frame 65536)) (is (= inflight 1)))
    (signals l:protocol-error (l:decode-local-hello wire env)))
  (dolist (offer '(4096 65536 17825792))
    (let* ((out (output)) (end (l:encode-local-hello out offer :inflight 16))
           (wire (subseq out 0 end)) (env (envelope wire)))
      (is (equalp wire (hello offer 16)))
      (multiple-value-bind (frame inflight) (l:decode-local-hello wire env)
        (is (= frame offer)) (is (= inflight 16))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-prefix-bounds-before-body
  (signals l:protocol-error (l:read-frame-length (bytes 0 0 0 0) 0 4))
  (signals l:protocol-error (l:read-frame-length (bytes 0 1 0 1) 0 4))
  (signals l:protocol-error (l:read-frame-length (bytes 0 0 0) 0 3))
  (multiple-value-bind (size next) (l:read-frame-length (bytes 73 0 1 0 0 74) 1 6)
    (is (= size 65536)) (is (= next 5)))
  (signals l:protocol-error (envelope (bytes 0 0 0 13 #x85 1 0 0 0 #xa2 0 #x19 #x10 0 1 1)))
  (signals l:protocol-error (l:decode-local-envelope (bytes) 0 0)))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-api-typeguards-before-array-access
  (dolist (bad '(nil "abc" #(1 2 3)))
    (signals arcdocdb.conditions:invalid-argument (l:decode-local-envelope bad 0 1))
    (signals arcdocdb.conditions:invalid-argument (l:read-frame-length bad 0 4)))
  (let ((wire (request 0 (bytes #xf6))))
    (signals arcdocdb.conditions:invalid-argument (l:decode-local-envelope wire -1 10))
    (signals arcdocdb.conditions:invalid-argument (l:decode-local-envelope wire 4 999))
    (signals arcdocdb.conditions:invalid-argument (envelope wire :direction :bogus))
    (signals arcdocdb.conditions:invalid-argument (envelope wire :last-id -1))
    (signals arcdocdb.conditions:invalid-argument (envelope wire :space :invalid))
    (signals arcdocdb.conditions:invalid-argument
      (l:decode-local-command wire (envelope wire) nil))
    (signals arcdocdb.conditions:invalid-argument
      (l:decode-local-command (copy-seq wire) (envelope wire) (cbor:crea-spazio-cbor))))
  (signals arcdocdb.conditions:invalid-argument (l:encode-local-request (output) "id" 0 nil nil))
  (signals arcdocdb.conditions:invalid-argument (l:encode-local-response (output) 1 0 :found :yes)))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-reuses-supplied-scratch-after-protocol-error
  (let ((space (cbor:crea-spazio-cbor)) (wire (request 0 (bytes #xf6))))
    (signals l:protocol-error
      (envelope (framed (bytes #x85 1 2 1 0 #x18 0)) :space space))
    (loop repeat 3 do
      (let ((env (envelope wire :space space)))
        (is (= 2 (l:envelope-kind env)))
        (is (= 0 (l:decode-local-command wire env space)))))
    (let* ((put (raw-put (bytes 255 0) (bytes #xa0))) (env (envelope put :space space)))
      (multiple-value-bind (status key document) (l:decode-local-command put env space)
        (is (zerop status)) (is (equalp key (bytes 255 0))) (is (equalp document (bytes #xa0)))))))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-envelope-rejects-nonminimal-shape-and-trailing
  (dolist (data (list (bytes #x98 5 1 2 1 0 #xf6)
                     (bytes #x85 #x18 1 2 1 0 #xf6)
                     (bytes #x85 2 2 1 0 #xf6)
                     (bytes #x85 1 4 1 0 #xf6)
                     (bytes #x85 1 2 0 0 #xf6)
                     (bytes #x85 1 2 #x20 0 #xf6)
                     (bytes #x85 1 2 1 #x19 0 0 #xf6)
                     (bytes #x85 1 2 1 0 #xf6 0)
                     (bytes #x9f 1 2 1 0 #xf6 #xff)
                     (body 3 1 6 (bytes #xf6))
                     (body 2 1 65536 (bytes #xf6))))
    (signals l:protocol-error (envelope (framed data)))))

;;; REQ: REQ-IPC-002
(deftest test-REQ-IPC-002-ids-direction-and-correlation
  (dolist (id '(1 23 24 255 256 65535 65536 4294967295 4294967296 18446744073709551615))
    (let* ((wire (request 0 (bytes #xf6) id)) (env (envelope wire :last-id (1- id))))
      (is (= id (l:envelope-id env)))
      (signals l:protocol-error (envelope wire :last-id id))
      (signals l:protocol-error (envelope wire :direction :server-to-client))
      (signals l:protocol-error (envelope wire :expected-kind 0))))
  (let ((wire (framed (body 3 9 0 (bytes #xf6)))))
    (is (= 9 (l:envelope-id (envelope wire :expected-id 9 :direction :server-to-client))))
    (signals l:protocol-error (envelope wire :expected-id 8))
    (signals l:protocol-error (envelope wire :direction :client-to-server)))
  (signals l:protocol-error (envelope (framed (body 0 1 0 (bytes #xa2 0 #x19 #x10 0 1 1)))))
  (signals l:protocol-error (envelope (framed (body 1 0 1 (bytes #xa0))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-handshake-exact-maps-and-limits
  (dolist (payload (list (bytes #xa2 0 #x19 #x10 0 0 1)
                        (bytes #xa2 1 1 0 #x19 #x10 0)
                        (bytes #xa2 0 #x19 #x10 0 2 1)
                        (bytes #xa3 0 #x19 #x10 0 1 1 2 0)
                        (bytes #xa2 0 #x19 #x0f #xff 1 1)
                        (bytes #xa2 0 #x19 #x10 0 1 0)
                        (bytes #xa2 0 #x19 #x10 0 1 17)
                        (join (bytes #xa2 0) (uint 17825793) (bytes 1 1))))
    (signals l:protocol-error (envelope (framed (body 0 0 0 payload)))))
  (dolist (payload (list (bytes #xa3 0 #x19 #x10 0 1 1 2 #x84 0 1 1 3)
                        (bytes #xa3 0 #x19 #x10 0 1 1 2 #x83 0 1 2)
                        (bytes #xa3 0 #x19 #x10 0 1 2 2 #x84 0 1 2 3)
                        (join (bytes #xa3 0) (uint 65537) (bytes 1 1 2 #x84 0 1 2 3))))
    (signals l:protocol-error (envelope (framed (body 1 0 0 payload))))))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-unknown-payload-nested-map-order-and-duplicates
  (is (= 4 (command-status (request 4 (bytes #xa2 0 #x81 #xa1 0 1 1 #xf6)))))
  (is (= 4 (command-status (request 65535 (bytes #xd8 32 #xa1 0 #xa1 1 #xf6)))))
  (dolist (payload (list (bytes #xa2 1 0 0 0)
                        (bytes #xa2 0 0 0 1)
                        (bytes #x81 #xa2 1 0 0 0)
                        (bytes #xa1 0 #x81 #xa2 0 0 0 1)
                        (bytes #xa1 0 #xd8 32 #xa2 1 0 0 0)
                        (bytes #x18 0) (bytes #x9f #xff) (bytes #xf6 0)))
    (signals l:protocol-error (command-status (request 4 payload)))))

;;; REQ: REQ-IPC-002 REQ-LIM-002
(deftest test-REQ-IPC-002-envelope-depth-and-tag-chain-bounded
  (let ((seven (make-array 7 :element-type '(unsigned-byte 8) :initial-element #x81))
        (eight (make-array 8 :element-type '(unsigned-byte 8) :initial-element #x81))
        (tags (make-array 100 :element-type '(unsigned-byte 8) :initial-element #xc0)))
    (is (= 4 (command-status (request 4 (join seven (bytes 0))))))
    (signals l:protocol-error (command-status (request 4 (join eight (bytes 0)))))
    (is (= 4 (command-status (request 4 (join tags (bytes #xf6))))))))

;;; REQ: REQ-IPC-002
(deftest test-REQ-IPC-002-command-shapes-status-one
  (dolist (wire (list (request 0 (bytes 0)) (request 0 (bytes #x80))
                     (request 1 (bytes #xf6)) (request 1 (bytes #x81 #x41 1))
                     (request 1 (bytes #x82 1 #x41 0)) (request 1 (bytes #x82 #x41 1 0))
                     (request 2 (bytes #x61 65)) (request 3 (bytes #x81 #x41 1))
                     (request 2 (bytes #x40))
                     (raw-put (bytes) (bytes 0)) (raw-put (bytes 1) (bytes))))
    (multiple-value-bind (status key document) (command-status wire)
      (is (= status 1)) (is (null key)) (is (null document)))))

;;; REQ: REQ-IPC-002 REQ-AFF-008
(deftest test-REQ-IPC-002-put-get-delete-preserve-binary-and-copy-ownership
  (let* ((key (bytes 0 255 128 0)) (document (bytes #x43 0 255 128)) (out (output))
         (end (l:encode-local-request out 18446744073709551615 1 key document))
         (wire (subseq out 0 end)))
    (is (equalp wire (raw-put key document 18446744073709551615)))
    (is (= 18446744073709551615 (l:envelope-id (envelope wire))))
    (multiple-value-bind (status copied-key copied-document) (command-status wire)
      (is (zerop status)) (is (equalp key copied-key)) (is (equalp document copied-document))
      (is (not (eq copied-key key))) (is (not (eq copied-document document)))
      (fill wire 0) (is (equalp key copied-key)) (is (equalp document copied-document))))
  (dolist (opcode '(2 3))
    (let ((key (bytes 255 0 128)))
      (multiple-value-bind (status copy doc) (command-status (request opcode (bstr key)))
        (is (zerop status)) (is (equalp copy key)) (is (null doc))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-separate-key-document-budgets
  (let ((max-key (make-array 1024 :element-type '(unsigned-byte 8) :initial-element 0))
        (over-key (make-array 1025 :element-type '(unsigned-byte 8) :initial-element 0))
        (max-doc (get-document 60000)) (over-doc (get-document 60001)))
    (is (= 60000 (length max-doc)))
    (is (= 0 (command-status (raw-put max-key max-doc))))
    (is (= 5 (command-status (raw-put over-key (bytes #xf6)))))
    (is (= 5 (command-status (raw-put (bytes 1) over-doc))))
    (dolist (opcode '(2 3)) (is (= 5 (command-status (request opcode (bstr over-key))))))))

;;; REQ: REQ-IPC-002 REQ-LIM-002
(deftest test-REQ-IPC-002-document-minimal-complete-and-depth100-separate
  (dolist (document (list (bytes #x18 0) (bytes #xf6 0) (bytes #x9f #xff)
                         (bytes #x61 #xff) (bytes #x43 1 2) (bytes #xff)))
    (is (= 1 (command-status (raw-put (bytes 0) document)))))
  (let ((hundred (make-array 100 :element-type '(unsigned-byte 8) :initial-element #x81))
        (hundred-one (make-array 101 :element-type '(unsigned-byte 8) :initial-element #x81)))
    (is (= 0 (command-status (raw-put (bytes 255) (join hundred (bytes #xf6))))))
    (is (= 5 (command-status (raw-put (bytes 255) (join hundred-one (bytes #xf6))))))))

;;; REQ: REQ-IPC-002 REQ-LIM-003
(deftest test-REQ-IPC-002-get-budget-before-engine
  (let ((wire (request 2 (bstr (bytes 0 255)))))
    (is (= 5 (command-status wire :max-frame 4096)))
    (is (= 5 (command-status wire :max-frame 60031)))
    (is (= 0 (command-status wire :max-frame 60032)))
    (is (= 0 (command-status wire :max-frame 65536))))
  (is (= 0 (command-status (request 3 (bstr (bytes 0))) :max-frame 4096))))

;;; REQ: REQ-IPC-002
(deftest test-REQ-IPC-002-response-shapes-and-supplied-found-nil
  (let ((out (output)))
    (dolist (csn '(1 4294967296 18446744073709551615))
      (let ((end (l:encode-local-response out 1 0 :csn csn)))
        (is (equalp (subseq out 0 end) (framed (body 3 1 0 (uint csn)))))
        (is (= csn (response 1 (uint csn)))) (is (= csn (response 3 (uint csn))))))
    (let ((end (l:encode-local-response out 1 0 :found nil :document (output 60000) :document-end 0)))
      (is (equalp (subseq out 0 end) (framed (body 3 1 0 (bytes #x82 #xf4 #xf6))))))
    (multiple-value-bind (status document) (response 2 (bytes #x82 #xf4 #xf6))
      (is (eq :absent status)) (is (null document)))
    (let* ((document (bytes #x43 0 255 128)) (source (join document (bytes 73 74)))
           (end (l:encode-local-response out 1 0 :found t :document source :document-end 4)))
      (is (equalp (subseq out 0 end) (framed (body 3 1 0 (join (bytes #x82 #xf5) (bstr document))))))
      (multiple-value-bind (status copied) (response 2 (join (bytes #x82 #xf5) (bstr document)))
        (is (eq :found status)) (is (equalp copied document)) (is (not (eq copied document)))))))

;;; REQ: REQ-IPC-002 REQ-AFF-004
(deftest test-REQ-IPC-002-response-errors-null-and-typed-rejections
  (let ((out (output)))
    (loop for status from 1 to 5 do
      (let ((end (l:encode-local-response out 1 status)))
        (is (equalp (subseq out 0 end) (framed (body 3 1 status (bytes #xf6))))))
      (let ((seen nil))
        (handler-case (response 1 (bytes #xf6) status)
          (l:request-rejected (condition)
            (is (= status (l:rejection-status condition))) (setf seen t)))
        (is seen))
      (signals l:protocol-error (response 1 (bytes 0) status))))
  (dolist (payload (list (bytes #x82 #xf5 #xf6) (bytes #x82 #xf4 #x40)
                        (bytes #x82 1 #xf6) (bytes #x82 #xf5 #x40)
                        (join (bytes #x82 #xf5) (bstr (bytes #x18 0)))))
    (signals l:protocol-error (response 2 payload)))
  (signals l:protocol-error (response 0 (bytes 0)))
  (signals l:protocol-error (response 1 (bytes #xf6)))
  (signals l:protocol-error (response 1 (bytes 0)))
  (signals l:protocol-error (response 3 (bytes 0)))
  (signals l:protocol-error (response 4 (bytes #xf6))))

;;; REQ: REQ-IPC-002 REQ-LIM-003 REQ-AFF-008
(deftest test-REQ-IPC-002-output-preflight-preserves-buffer-and-input
  (let* ((small (output 9)) (before (copy-seq small)))
    (signals arcdocdb.conditions:resource-exhausted (l:encode-local-request small 1 0 nil nil))
    (is (equalp small before)))
  (let* ((out (output)) (before (copy-seq out)) (key (bytes 0)))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-request out 0 0 nil nil))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-response out 1 0 :csn 0))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-request out 1 1 key out))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-response out 1 0 :found t :document out))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-welcome out 65537))
    (signals arcdocdb.conditions:invalid-argument (l:encode-local-hello out 17825793))
    (is (equalp out before)))
  (let* ((out (output)) (end (l:encode-local-request out 1 1 (bytes 0) (bytes #xf6))))
    (is (every (lambda (byte) (= byte #xcc)) (subseq out end)))))

(defun run-local-wire-tests ()
  "Esegue soltanto questa suite quando il parent autorizza il gate dopo freeze e review."
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test wire locale superati.~%" (length *tests*))
  t)
(defun run () (run-local-wire-tests))
