;;;; C4: framing sperimentale, mai caricato dal prodotto.
;;; REQ: REQ-VAL-001 REQ-IPC-002
(defpackage #:arcdocdb.spk11 (:use #:cl) (:export #:check #:client))
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defconstant +frame-limit+ (* 17 1024 1024))
(defconstant +document-limit+ (* 16 1024 1024))

(define-condition rejection (error)
  ((reason :initarg :reason :reader reason))
  (:report (lambda (condition stream) (format stream "SPK-11: ~S" (reason condition)))))

(defun demand (predicate reason)
  "Oracolo C4: fallimento esplicito, mai convertito in successo."
  (unless predicate (error 'rejection :reason reason)))

(defun bytes (&rest values)
  "Fixture binaria specializzata indipendente dal decoder."
  (make-array (length values) :element-type '(unsigned-byte 8) :initial-contents values))

(defun prefix (size)
  "u32 big-endian senza dipendenze dal formato dello storage."
  (apply #'bytes (loop for shift in '(24 16 8 0) collect (ldb (byte 8 shift) size))))

(defun frame (body)
  "Fixture completa: il prefisso conta solo il corpo."
  (concatenate '(simple-array (unsigned-byte 8) (*)) (prefix (length body)) body))

(defstruct decoder
  "Stato esclusivo C4; ALLOCATIONS conta solo la creazione dei corpi."
  (header-count 0 :type fixnum) (size 0 :type integer) (limit +frame-limit+ :type integer)
  (body nil :type (or null (simple-array (unsigned-byte 8) (*))))
  (offset 0 :type fixnum) (allocations 0 :type fixnum))

(defun feed (state input start end)
  "Consuma uno span finito; restituisce i frame completi in ordine, conserva il parziale."
  (let ((cursor start) (completed nil))
    (loop while (< cursor end) do
      (if (< (decoder-header-count state) 4)
          (progn
            (setf (decoder-size state) (+ (ash (decoder-size state) 8) (aref input cursor)))
            (incf cursor) (incf (decoder-header-count state))
            (when (= (decoder-header-count state) 4)
              (demand (<= 1 (decoder-limit state) +frame-limit+) :decoder-limit)
              (unless (<= 1 (decoder-size state) (decoder-limit state))
                (error 'rejection :reason :length))
              (setf (decoder-body state)
                    (make-array (decoder-size state) :element-type '(unsigned-byte 8)))
              (incf (decoder-allocations state))))
          (let ((count (min (- end cursor) (- (decoder-size state) (decoder-offset state)))))
            (demand (plusp count) :decoder-progress)
            (replace (decoder-body state) input :start1 (decoder-offset state)
                     :start2 cursor :end2 (+ cursor count))
            (incf cursor count) (incf (decoder-offset state) count)
            (when (= (decoder-offset state) (decoder-size state))
              (push (decoder-body state) completed)
              (setf (decoder-header-count state) 0 (decoder-size state) 0
                    (decoder-body state) nil (decoder-offset state) 0)))))
    (nreverse completed)))

(defun finish-decoder (state)
  "EOF e valido soltanto fra frame; nessun successo su corpo/prefisso incompleto."
  (unless (zerop (decoder-header-count state)) (error 'rejection :reason :truncated))
  t)

(defun expect-rejection (expected thunk)
  "Sensibilita dell'oracolo: richiede la ragione esatta, propaga errori estranei."
  (demand (handler-case (progn (funcall thunk) nil)
            (rejection (condition) (eq expected (reason condition)))) :missing-rejection))

(defun same-frames (actual expected)
  "Confronto indipendente byte per byte, non solo dei conteggi."
  (demand (equalp actual expected) :frame-content))

(defun ping (id &optional (kind 2))
  "Fixture proposta [version, kind, id, PING/status, null], ID piccolo del test."
  (bytes #x85 1 kind id 0 #xf6))

(defun check-codec (body &optional (start 0) (end (length body)))
  "Riusa il validatore CBOR minimo di prodotto; non certifica la canonicalita delle mappe."
  (arcdocdb.cbor:verifica-struttura-cbor-minima
   body start end (arcdocdb.cbor:crea-spazio-cbor) :max-bytes +document-limit+))

(defun maximum-body ()
  "Array CBOR [documento map da 16MiB, chiave bstr da 65535 byte], esatto e deterministico."
  (let* ((key-start (1+ +document-limit+))
         (body (make-array (+ key-start 3 65535) :element-type '(unsigned-byte 8)
                           :initial-element #x61)))
    (replace body (bytes #x82 #xa1 0 #x5a))
    (replace body (prefix (- +document-limit+ 7)) :start1 4)
    (replace body (bytes #x59 #xff #xff) :start1 key-start)
    body))

(defun check-framing ()
  "Partizioni esaustive di due frame piccoli, limiti, EOF e sensibilita con mutazioni note."
  (let* ((expected (list (ping 1) (ping 2)))
         (input (concatenate '(simple-array (unsigned-byte 8) (*))
                             (frame (first expected)) (frame (second expected)))))
    (dotimes (split (1+ (length input)))
      (let ((state (make-decoder)))
        (same-frames (append (feed state input 0 split) (feed state input split (length input))) expected)
        (finish-decoder state)))
    (let ((state (make-decoder)) (actual nil))
      (dotimes (i (length input)) (setf actual (append actual (feed state input i (1+ i)))))
      (same-frames actual expected) (finish-decoder state))
    (dolist (size (list 0 (1+ +frame-limit+) #xffffffff))
      (let ((state (make-decoder)))
        (expect-rejection :length (lambda () (feed state (prefix size) 0 4)))
        (demand (and (zerop (decoder-allocations state)) (null (decoder-body state))) :allocation-before-limit)))
    (dotimes (cut (length (frame (ping 1))))
      (when (plusp cut)
        (let ((state (make-decoder)))
          (feed state input 0 cut)
          (expect-rejection :truncated (lambda () (finish-decoder state))))))
    (let ((state (make-decoder)))
      (feed state (prefix +frame-limit+) 0 4)
      (demand (= +frame-limit+ (length (decoder-body state))) :maximum-frame)
      (expect-rejection :truncated (lambda () (finish-decoder state))))
    (expect-rejection :frame-content (lambda () (same-frames (list (ping 2)) (list (ping 1))))))
  (check-codec (ping 1))
  (demand (handler-case (progn (check-codec (bytes #x85 1 2 1 0 #xff)) nil)
            (arcdocdb.conditions:corruption-detected () t)) :malformed-cbor)
  (list :status :ok :split-points 21 :invalid-lengths 3 :truncated-prefix-or-body 9
        :maximum-frame-bytes +frame-limit+ :oracle-negative-controls 3))
