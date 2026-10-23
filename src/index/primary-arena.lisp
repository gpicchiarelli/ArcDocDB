;;; OWNER: unico writer; crescita esplicita prima del commit e delle prenotazioni di nuovi byte.
;;; SHARED: array precedente resta immutato; nuovo riferimento pubblicato con barriera.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-AFF-008
(declaim (ftype (function (frammento-indice) fixnum) payload-frammento))
(defun payload-frammento (fragment)
  "Pre: writer/controller, frammento canonico. Post: byte di payload slot/controllo/arena.
Non è RSS, non include header, garbage o array conservati da altri reader/piani."
  (+ (* 41 (banco-slot-capacity (frammento-indice-bank fragment)))
     (length (frammento-indice-arena fragment))))

;;; REQ: REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (root-indice) fixnum) payload-root))
(defun payload-root (root)
  "Pre: root costruita da questo modulo, geometria canonica. Post: directory e frammenti distinti.
Ogni blocco di prefisso compare una volta; somma di payload, senza stima del collector."
  (let* ((directory (root-indice-directory root)) (depth (root-indice-depth root))
         (sum (* 8 (length directory))) (i 0))
    (loop while (< i (length directory))
          do (let ((fragment (aref directory i)))
               (incf sum (payload-frammento fragment))
               (when (> sum most-positive-fixnum)
                 (error 'resource-exhausted :reason :primary-memory-accounting-range))
               (incf i (ash 1 (- depth (frammento-indice-depth fragment))))))
    sum))

;;; REQ: REQ-IDX-005 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice integer integer) null) estendi-arena-indice))
(defun estendi-arena-indice (index fragment new-size transient-budget-bytes)
  "Pre: writer, budget transitorio prenotato dal controller, nessun piano/lavoro non contabilizzato.
Post: stessa chiave agli stessi offset; arena cresce per sostituzione, mai in-place o in riduzione.
Controlla root corrente + frammento building eventuale + arena nuova prima di allocare."
  (esigi-frammento-sano index fragment)
  (esigi-banco-writer (frammento-indice-bank fragment))
  (let* ((old (frammento-indice-arena fragment)) (root (acquisisci-root index))
         (building (eq (frammento-indice-exposure fragment) :building)))
    (unless (and (not (eq (frammento-indice-exposure fragment) :retired))
                 (< (length old) new-size) (<= new-size #x100000000)
                 (<= 1 transient-budget-bytes most-positive-fixnum))
      (error 'invalid-argument :reason :primary-arena-configuration))
    (when (> (+ (* 41 (indice-primario-capacity index)) new-size)
             (indice-primario-fragment-budget index))
      (error 'resource-exhausted :reason :primary-fragment-memory-budget))
    (when (> (+ (payload-root root) (if building (payload-frammento fragment) 0) new-size)
             transient-budget-bytes)
      (error 'resource-exhausted :reason :primary-arena-transient-budget))
    (esigi-revisione index)
    (let ((new (make-array new-size :element-type '(unsigned-byte 8) :initial-element 0)) (complete nil))
      (replace new old)
      (unwind-protect
           (progn
             (incf (indice-primario-revision index))
             (sb-thread:barrier (:write))
             (setf (frammento-indice-arena fragment) new)
             (esigi-frammento-sano index fragment)
             (setf complete t))
        (unless complete (invalida-indice-primario index)))))
  nil)
