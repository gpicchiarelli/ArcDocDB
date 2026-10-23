;;;; C4: profilo di controllo della proposta M16; mai caricato dal prodotto.
;;; REQ: REQ-VAL-001 REQ-IPC-002
(in-package #:arcdocdb.spk11)
(declaim (optimize (safety 3) (debug 3)))

(defun uint-wire (value)
  "Encoder di fixture indipendente dal decoder CBOR del prodotto."
  (demand (typep value '(unsigned-byte 64)) :fixture-uint)
  (let* ((count (cond ((< value 24) 0) ((<= value #xff) 1) ((<= value #xffff) 2)
                      ((<= value #xffffffff) 4) (t 8)))
         (wire (make-array (1+ count) :element-type '(unsigned-byte 8))))
    (setf (aref wire 0) (if (zerop count) value (+ 24 (position count '(1 2 4 8)))))
    (dotimes (i count) (setf (aref wire (1+ i)) (ldb (byte 8 (* 8 (- count i 1))) value)))
    wire))

(defun control-wire (kind id code payload)
  "Fixture [1,kind,id,code,payload]; il payload e gia codificato."
  (concatenate '(simple-array (unsigned-byte 8) (*)) (bytes #x85 1)
               (uint-wire kind) (uint-wire id) (uint-wire code) payload))

(defun hello-wire (&optional (size 8192) (inflight 2))
  "Fixture HELLO con chiavi unsigned esatte 0/1."
  (control-wire 0 0 0 (concatenate '(simple-array (unsigned-byte 8) (*))
                                  (bytes #xa2 0) (uint-wire size) (bytes 1) (uint-wire inflight))))

(defun welcome-wire (size inflight enabled)
  "Fixture WELCOME; la lista ordinata e vuota oppure contiene soltanto PING."
  (control-wire 1 0 0 (concatenate '(simple-array (unsigned-byte 8) (*))
                                  (bytes #xa3 0) (uint-wire size) (bytes 1) (uint-wire inflight)
                                  (if enabled (bytes 2 #x81 0) (bytes 2 #x80)))))

(defun wire-uint (body cursor maximum)
  "Lettura unsigned minima dal codec comune, limite prima di usarne il valore."
  (multiple-value-bind (major ai high low next form)
      (arcdocdb.cbor:leggi-header-cbor-minimo body cursor (length body))
    (declare (ignore ai))
    (demand (and (= major 0) (eq form :argument)) :control-uint)
    (let ((value (logior (ash high 32) low)))
      (demand (<= value maximum) :control-uint-limit)
      (values value next))))

(defun encoded-key-less-p (body left-start left-end right-start right-end)
  "Ordine RFC8949 core: lessicografico sui byte, non ordinamento per lunghezza."
  (loop for left from left-start below left-end
        for right from right-start below right-end
        for a = (aref body left) for b = (aref body right)
        when (< a b) do (return-from encoded-key-less-p t)
        when (> a b) do (return-from encoded-key-less-p nil))
  (< (- left-end left-start) (- right-end right-start)))

(defun ordered-control-item (body start depth)
  "Secondo passaggio C4: stack array/map <=8; i tag sono saltati iterativamente.
Il codec comune ha gia verificato sintassi, span, UTF8, nodi e header minimi."
  (let ((cursor start))
    (loop repeat (length body) do
      (multiple-value-bind (major ai high low next form)
          (arcdocdb.cbor:leggi-header-cbor-minimo body cursor (length body))
        (declare (ignore ai form))
        (if (= major 6) (setf cursor next)
            (return-from ordered-control-item
              (case major
                ((0 1 7) next)
                ((2 3) (demand (zerop high) :control-string-size) (+ next low))
                ((4 5)
                 (demand (and (< depth 8) (zerop high)) :control-depth)
                 (let ((position next) (previous-start nil) (previous-end nil))
                   (dotimes (i low)
                     (let* ((key-start position)
                            (key-end (ordered-control-item body position (1+ depth))))
                       (when (and (= major 5) previous-start)
                         (demand (encoded-key-less-p body previous-start previous-end key-start key-end)
                                 :control-map-order))
                       (setf previous-start key-start previous-end key-end
                             position (if (= major 5) (ordered-control-item body key-end (1+ depth)) key-end))))
                   position))
                (otherwise (error 'rejection :reason :control-major)))))))
    (error 'rejection :reason :control-tag-bound)))

(defun canonical-control (body)
  "Profilo C4 entro 4096 byte: un solo item, testate minime e mappe ordinate."
  (demand (<= 1 (length body) 4096) :control-bytes)
  (arcdocdb.cbor:verifica-struttura-cbor-minima
   body 0 (length body) (arcdocdb.cbor:crea-spazio-cbor) :max-bytes 4096 :max-depth 8)
  (demand (= (length body) (ordered-control-item body 0 0)) :control-canonical-end)
  t)

(defun decode-capacities (body cursor welcome-p)
  "Mappe HELLO/WELCOME a chiavi esatte; array opcode strettamente crescente."
  (demand (= (aref body cursor) (if welcome-p #xa3 #xa2)) :hello-map)
  (incf cursor)
  (demand (= (aref body cursor) 0) :hello-map) (incf cursor)
  (multiple-value-bind (size next) (wire-uint body cursor +frame-limit+)
    (demand (>= size 4096) :hello-frame)
    (demand (= (aref body next) 1) :hello-map)
    (multiple-value-bind (inflight position) (wire-uint body (1+ next) 16)
      (demand (plusp inflight) :hello-inflight)
      (let ((opcodes nil))
        (when welcome-p
          (demand (= (aref body position) 2) :hello-map)
          (multiple-value-bind (major ai high count after form)
              (arcdocdb.cbor:leggi-header-cbor-minimo body (1+ position) (length body))
            (declare (ignore ai form))
            (demand (and (= major 4) (zerop high) (<= count (length body))) :welcome-opcodes)
            (setf position after)
            (dotimes (i count)
              (multiple-value-bind (opcode end) (wire-uint body position #xffff)
                (when opcodes (demand (< (car opcodes) opcode) :welcome-opcodes))
                (push opcode opcodes) (setf position end)))))
        (demand (= position (length body)) :hello-map)
        (list :max-frame size :max-inflight inflight :opcodes (nreverse opcodes))))))

(defun decode-control (body)
  "Envelope esatto, ID u64; il significato del payload REQUEST e del dispatcher."
  (canonical-control body)
  (demand (= (aref body 0) #x85) :control-envelope)
  (multiple-value-bind (version a) (wire-uint body 1 #xffff)
    (demand (= version 1) :control-version)
    (multiple-value-bind (kind b) (wire-uint body a 3)
      (multiple-value-bind (id c) (wire-uint body b #xffffffffffffffff)
        (multiple-value-bind (code payload) (wire-uint body c #xffff)
          (let ((result (list :kind kind :id id :code code
                              :payload-null (and (= payload (1- (length body))) (= (aref body payload) #xf6)))))
            (if (<= kind 1)
                (progn (demand (and (zerop id) (zerop code)) :hello-envelope)
                       (append result (decode-capacities body payload (= kind 1))))
                (progn (demand (plusp id) :request-id)
                       (when (= kind 3) (demand (<= code 5) :response-status)) result))))))))
