;;;; Harness XXH64 freddo: nessuna dipendenza dagli helper hash del prodotto.
;;; Fonte dell'oracolo, congelata prima di leggere src/hash:
;;; https://raw.githubusercontent.com/Cyan4973/xxHash/v0.8.3/doc/xxhash_spec.md
;;; Solo la sezione XXH64; NON XXH3. Bignum/heap ammessi nell'oracolo.
;;; OWNER: registro del loader seriale; fixture e PRNG locali a ciascun test.
(defpackage #:arcdocdb.hash64.tests
  (:use #:cl)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.hash64.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))
(declaim (notinline arcdocdb.hash64:xxh64 hash-entry-point))

(defvar *tests* nil)

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defmacro is (expression)
  `(unless ,expression (error "Asserzione XXH64 fallita: ~S" ',expression)))

(defun run ()
  "Runner seriale: chiamare solo dopo il freeze del prodotto. Nessun autorun."
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test XXH64 superati.~%" (length *tests*))
  t)

(defun hash-entry-point ()
  "Lookup opaco al compilatore: preserva TUTTI i valori del ritorno pubblico."
  (let* ((package (or (find-package "ARCDOCDB.HASH64")
                      (error "Package pubblico XXH64 assente.")))
         (symbol (find-symbol "XXH64" package)))
    (is symbol)
    (is (fboundp symbol))
    (symbol-function symbol)))

(defun hash-cold-values (buffer start end seed-high seed-low)
  ;; Nessun FTYPE ristretto sul funcall; niente inline del nome pubblico.
  (multiple-value-list
   (funcall (hash-entry-point) buffer start end seed-high seed-low)))

(defun hash-public-values (buffer start end seed-high seed-low)
  "Chiamata nominata con argomenti T: espone FTYPE pubblici troppo restrittivi."
  (declare (type t buffer start end seed-high seed-low))
  (multiple-value-list
   (arcdocdb.hash64:xxh64 buffer start end seed-high seed-low)))

(defun hash-check-values (actual expected)
  (is (= 2 (length actual)))
  (is (every (lambda (word)
               (and (typep word '(unsigned-byte 32)) (typep word 'fixnum)))
             actual))
  (is (equal actual expected))
  actual)

(defun hash-snapshot (object)
  "Array: anche celle oltre fill-pointer, dimensioni e displacement."
  (cond ((arrayp object)
         (multiple-value-bind (base offset) (array-displacement object)
           (let ((cells (make-array (array-total-size object)
                                    :element-type (array-element-type object))))
             (dotimes (i (array-total-size object))
               (setf (aref cells i) (row-major-aref object i)))
             (list (array-dimensions object) (array-element-type object)
                   (adjustable-array-p object) base offset
                   (and (vectorp object) (array-has-fill-pointer-p object))
                   (and (vectorp object) (array-has-fill-pointer-p object)
                        (fill-pointer object))
                   cells))))
        ((consp object) (copy-tree object))
        (t object)))

(defun hash-unchanged-p (object before)
  (if (arrayp object)
      (let ((after (hash-snapshot object)))
        ;; Il backing array deve mantenere anche l'identita, non solo EQUALP.
        (and (eq (fourth before) (fourth after))
             (equalp before after)))
      (equalp before object)))

(defun hash-accept (buffer start end seed-high seed-low expected)
  "Controlli freddi: arita esatta, ordine high/low, u32 fixnum e intero buffer."
  ;; Le fixture valide sono simple u8: una copia specializzata evita liste grandi.
  (is (typep buffer '(simple-array (unsigned-byte 8) (*))))
  (let ((before (copy-seq buffer)))
    (unwind-protect
         (hash-check-values (hash-cold-values buffer start end seed-high seed-low)
                            expected)
      (is (equalp before buffer)))))

(defun hash-reject (buffer start end seed-high seed-low reason)
  "Entrambi i caller devono ottenere INVALID-ARGUMENT e reason, senza mutazioni."
  (let ((before (hash-snapshot buffer)))
    (dolist (caller '(hash-cold-values hash-public-values))
      (let ((returned nil) (observed nil))
        (unwind-protect
             (progn
               (handler-case
                   (progn (funcall caller buffer start end seed-high seed-low)
                          (setf returned t))
                 (arcdocdb-error (condition) (setf observed condition)))
               (is (not returned))
               (is (typep observed 'invalid-argument))
               (is (eq reason (error-reason observed))))
          (is (hash-unchanged-p buffer before)))))
    t))

(defun hash-octets (&rest contents)
  (make-array (length contents) :element-type '(unsigned-byte 8)
              :initial-contents contents))

(defun hash-fixture (contents &key (prefix 0) (suffix 31) (guard #xa5))
  (let* ((end (+ prefix (length contents)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8)
                             :initial-element guard)))
    (replace buffer contents :start1 prefix)
    (values buffer prefix end)))

(defun hash-corpus-bytes (size &optional (state #x6483a11f))
  "PRNG aritmetico locale, seme fisso; nessun uso di *RANDOM-STATE*."
  (let ((buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf state (mod (+ (* state 1664525) 1013904223) 4294967296)
            (aref buffer i) (floor state 16777216)))))

(defparameter *hash-seeds*
  '((0 0) (0 1) (#xffffffff #xffffffff) (1 0)
    (#x80000000 0) (#xffffffff 0) (0 #xffffffff)
    (#x01234567 #x89abcdef)))

(defun hash-u64-mod (integer) (mod integer 18446744073709551616))

(defun hash-reference-rotate (integer count)
  ;; Rotazione aritmetica: nessun helper, maschera o parola high/low del prodotto.
  (let* ((word (hash-u64-mod integer)) (factor (expt 2 (- 64 count))))
    (+ (* (mod word factor) (expt 2 count)) (floor word factor))))

(defun hash-reference-lane (buffer start width)
  (loop for i below width
        sum (* (aref buffer (+ start i)) (expt 256 i))))

(defun hash-reference (buffer start end seed-high seed-low)
  "XXH64 originale, span valido. MOD/FLOOR e interi arbitrari, senza stato.
Ritorna una lista high/low soltanto nell'oracolo freddo; zero chiamate al prodotto."
  (let* ((p1 #x9e3779b185ebca87) (p2 #xc2b2ae3d27d4eb4f)
         (p3 #x165667b19e3779f9) (p4 #x85ebca77c2b2ae63)
         (p5 #x27d4eb2f165667c5)
         (seed (+ (* seed-high 4294967296) seed-low))
         (size (- end start)) (position start) (accumulator 0))
    (labels ((round-lane (accumulator lane)
               (hash-u64-mod
                (* (hash-reference-rotate (+ accumulator (* lane p2)) 31) p1)))
             (merge-lane (accumulator lane)
               (hash-u64-mod (+ (* (logxor accumulator (round-lane 0 lane)) p1) p4))))
      (if (< size 32)
          (setf accumulator (hash-u64-mod (+ seed p5)))
          (let ((lanes (vector (hash-u64-mod (+ seed p1 p2))
                               (hash-u64-mod (+ seed p2)) seed
                               (hash-u64-mod (- seed p1)))))
            (loop while (<= (+ position 32) end)
                  do (dotimes (lane 4)
                       (setf (aref lanes lane)
                             (round-lane (aref lanes lane)
                                         (hash-reference-lane buffer (+ position (* lane 8)) 8))))
                     (incf position 32))
            (setf accumulator
                  (hash-u64-mod
                   (loop for lane across lanes for rotation in '(1 7 12 18)
                         sum (hash-reference-rotate lane rotation))))
            (loop for lane across lanes
                  do (setf accumulator (merge-lane accumulator lane)))))
      (setf accumulator (hash-u64-mod (+ accumulator size)))
      (loop while (<= (+ position 8) end)
            do (setf accumulator
                     (hash-u64-mod
                      (+ (* (hash-reference-rotate
                             (logxor accumulator
                                     (round-lane 0 (hash-reference-lane buffer position 8))) 27)
                            p1) p4)))
               (incf position 8))
      (when (<= (+ position 4) end)
        (setf accumulator
              (hash-u64-mod
               (+ (* (hash-reference-rotate
                      (logxor accumulator
                              (hash-u64-mod (* (hash-reference-lane buffer position 4) p1))) 23)
                     p2) p3)))
        (incf position 4))
      (loop while (< position end)
            do (setf accumulator
                     (hash-u64-mod
                      (* (hash-reference-rotate
                          (logxor accumulator
                                  (hash-u64-mod (* (aref buffer position) p5))) 11) p1)))
               (incf position))
      (setf accumulator (hash-u64-mod (* (logxor accumulator (floor accumulator (expt 2 33))) p2))
            accumulator (hash-u64-mod (* (logxor accumulator (floor accumulator (expt 2 29))) p3))
            accumulator (logxor accumulator (floor accumulator 4294967296)))
      (list (floor accumulator 4294967296) (mod accumulator 4294967296)))))

(defun hash-compare-reference (buffer start end seed-high seed-low)
  (hash-accept buffer start end seed-high seed-low
               (hash-reference buffer start end seed-high seed-low)))

(defun hash-check-offset-matrix (contents seeds &optional (offsets (loop for i below 32 collect i)))
  "Un oracolo per payload/seme; tutti gli offset confrontati con quel digest."
  (let ((expected (loop for (high low) in seeds
                        collect (hash-reference contents 0 (length contents) high low)))
        (cases 0))
    (dolist (offset offsets cases)
      (multiple-value-bind (buffer start end) (hash-fixture contents :prefix offset)
        (loop for (high low) in seeds for digest in expected
              do (hash-accept buffer start end high low digest) (incf cases))))))

(defun hash-fold-calls (entry buffer start end seed-high seed-low repetitions)
  "Solo chiamate al prodotto e sink fixnum; fixture/oracolo/format fuori intervallo."
  (declare (type function entry)
           (type (simple-array (unsigned-byte 8) (*)) buffer)
           (type (integer 0 #.most-positive-fixnum) start end)
           (type (unsigned-byte 32) seed-high seed-low)
           (type (integer 0 4096) repetitions))
  (let ((sink 0))
    (declare (type (unsigned-byte 32) sink))
    (dotimes (i repetitions sink)
      (multiple-value-bind (high low) (funcall entry buffer start end seed-high seed-low)
        (declare (type (unsigned-byte 32) high low))
        (setf sink (logxor sink high low))))))
