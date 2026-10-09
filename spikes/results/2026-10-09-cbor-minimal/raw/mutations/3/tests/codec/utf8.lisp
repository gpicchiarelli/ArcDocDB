(in-package #:arcdocdb.utf8.tests)

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-reference-is-strict
  ;; Nessuna replacement e nessun restart: questo self-check precede i confronti esaustivi.
  (dolist (entry '(((0) 1) ((13 10) 2) ((#xc2 #x80) 1) ((#xe0 #xa0 #x80) 1)
                   ((#xed #x9f #xbf) 1) ((#xf4 #x8f #xbf #xbf) 1)
                   ((#xef #xbb #xbf) 1) ((#xef #xbf #xbe) 1)))
    (let ((buffer (apply #'bytes (first entry))))
      (multiple-value-bind (valid count) (utf8-strict-reference buffer 0 (length buffer))
        (is valid) (is (= (second entry) count)))))
  (dolist (contents '((#xc0 #x80) (#xc1 #xbf) (#x80) (#xf5 #x80 #x80 #x80)
                      (#xe0 #x9f #xbf) (#xed #xa0 #x80) (#xf0 #x8f #xbf #xbf)
                      (#xf4 #x90 #x80 #x80) (#xe2 #x82) (#xe2 #x41 #xac)))
    (let ((buffer (apply #'bytes contents)))
      (multiple-value-bind (valid count) (utf8-strict-reference buffer 0 (length buffer))
        (is (not valid)) (is (null count))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-empty-ascii-and-default-budget
  (utf8-accept (bytes) 0 0 0)
  (utf8-accept (bytes #xff #xff #xff) 2 2 0 :max-bytes 0)
  (let ((ascii (make-array 128 :element-type '(unsigned-byte 8))))
    (dotimes (i 128) (setf (aref ascii i) i))
    (multiple-value-bind (buffer start end) (utf8-fixture ascii :prefix 3)
      (utf8-accept buffer start end 128)
      (utf8-accept buffer start (1+ start) 1 :max-bytes 1))))

;;; REQ: REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-004-utf8-invalid-range-and-buffer
  (let ((buffer (bytes 0 65 127)))
    (dolist (range '((-1 1) (2 1) (0 4) (4 4) (nil 1) (0 nil) (0 1.0) (1.0 2)))
      (utf8-reject buffer (first range) (second range) 'invalid-argument :utf8-range))
    (utf8-reject buffer 0 (1+ most-positive-fixnum) 'invalid-argument :utf8-range)
    (utf8-reject buffer -1 1 'invalid-argument :utf8-range :max-bytes nil))
  (let* ((base (bytes 1 2 3 4))
         (displaced (make-array 2 :element-type '(unsigned-byte 8) :displaced-to base)))
    (dolist (buffer (list nil '(65) #(65) "A"
                          (make-array 2 :element-type '(unsigned-byte 8) :adjustable t)
                          (make-array 2 :element-type '(unsigned-byte 8) :fill-pointer 1)
                          (make-array '(2 2) :element-type '(unsigned-byte 8)) displaced))
      (utf8-reject buffer 0 0 'invalid-argument :utf8-range :max-bytes nil))
    (is (equalp base (bytes 1 2 3 4)))))

;;; REQ: REQ-LIM-001 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-AFF-008-utf8-invalid-budget
  (dolist (bad (list -1 nil 1.0 :unbounded (1+ +utf8-test-limit+) (1+ most-positive-fixnum)))
    (utf8-reject (bytes #xff) 0 1 'invalid-argument :utf8-budget :max-bytes bad)
    (utf8-reject (bytes) 0 0 'invalid-argument :utf8-budget :max-bytes bad)))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-AFF-008-utf8-byte-budget-precedes-content
  (utf8-accept (bytes) 0 0 0 :max-bytes 0)
  (utf8-accept (bytes 65 66 67) 0 3 3 :max-bytes 3)
  (utf8-reject (bytes 65 66 67) 0 3 'resource-exhausted :utf8-byte-budget :max-bytes 2)
  (dolist (buffer (list (bytes #xff) (bytes #xe0 0) (bytes #xed #xa0 #x80)))
    (utf8-reject buffer 0 (length buffer) 'resource-exhausted :utf8-byte-budget :max-bytes 0)))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-all-256-single-byte-inputs
  (multiple-value-bind (buffer start end) (utf8-fixture '(0))
    (let ((accepted 0) (leading 0) (truncated 0))
      (dotimes (octet 256)
        (setf (aref buffer start) octet)
        (multiple-value-bind (valid count) (utf8-strict-reference buffer start end)
          (is (eql valid (< octet #x80)))
          (cond (valid (is (= count 1)) (incf accepted) (utf8-accept buffer start end 1))
                ((or (<= #xc2 octet #xdf) (<= #xe0 octet #xef) (<= #xf0 octet #xf4))
                 (incf truncated)
                 (utf8-reject buffer start end 'corruption-detected :utf8-truncated :offset end))
                (t (incf leading)
                   (utf8-reject buffer start end 'corruption-detected :utf8-leading :offset start)))))
      (is (= accepted 128)) (is (= leading 77)) (is (= truncated 51)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-all-65536-two-byte-inputs
  (multiple-value-bind (buffer start end) (utf8-fixture '(0 0) :prefix 5)
    (let ((accepted 0) (rejected 0) (scalar-total 0))
      (dotimes (first 256)
        (dotimes (second 256)
          (setf (aref buffer start) first (aref buffer (1+ start)) second)
          ;; Grammatica dell'intero span: due ASCII oppure una codifica a due byte.
          (let ((expected (cond ((and (< first #x80) (< second #x80)) 2)
                                ((and (<= #xc2 first #xdf) (<= #x80 second #xbf)) 1)
                                (t nil))))
            (multiple-value-bind (valid count) (utf8-strict-reference buffer start end)
              (is (eql valid (not (null expected))))
              (if valid
                  (progn (is (= count expected)) (incf accepted) (incf scalar-total expected)
                         (utf8-accept buffer start end expected))
                  (let ((before (copy-seq buffer)) (observed nil) (returned nil))
                    (handler-case (progn (arcdocdb.utf8:verifica-utf8 buffer start end)
                                         (setf returned t))
                      (corruption-detected (condition) (setf observed condition)))
                    (is (and observed (not returned))) (is (equalp before buffer))
                    (incf rejected)))))))
      (is (= accepted 18304)) (is (= rejected 47232)) (is (= scalar-total 34688))
      (format t "  UTF-8 esaustivo: 65536 coppie, 18304 valide, 47232 rifiutate.~%"))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-manual-scalar-boundaries
  (dolist (contents '((#x00) (#x7f) (#xc2 #x80) (#xdf #xbf)
                      (#xe0 #xa0 #x80) (#xe0 #xbf #xbf) (#xe1 #x80 #x80)
                      (#xec #xbf #xbf) (#xed #x80 #x80) (#xed #x9f #xbf)
                      (#xee #x80 #x80) (#xef #xbf #xbf)
                      (#xf0 #x90 #x80 #x80) (#xf0 #xbf #xbf #xbf)
                      (#xf1 #x80 #x80 #x80) (#xf3 #xbf #xbf #xbf)
                      (#xf4 #x80 #x80 #x80) (#xf4 #x8f #xbf #xbf)))
    (multiple-value-bind (buffer start end) (utf8-fixture contents)
      (utf8-accept buffer start end 1))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-nul-bom-noncharacters-and-no-normalization
  (dolist (contents '((0) (#xef #xbb #xbf) (#xef #xb7 #x90) (#xef #xbf #xbe)
                      (#xef #xbf #xbf) (#xf0 #x9f #xbf #xbe) (#xf4 #x8f #xbf #xbf)))
    (multiple-value-bind (buffer start end) (utf8-fixture contents)
      (utf8-accept buffer start end 1)))
  (utf8-accept (bytes #xc3 #xa9) 0 2 1)
  (utf8-accept (bytes #x65 #xcc #x81) 0 3 2)
  (utf8-accept (bytes 13 10) 0 2 2))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-illegal-leading-offset
  (dolist (lead (append (loop for b from #x80 to #xbf collect b)
                        '(#xc0 #xc1) (loop for b from #xf5 to #xff collect b)))
    (multiple-value-bind (buffer start end) (utf8-fixture (list 65 66 lead #x80 #x80 #x80))
      (utf8-reject buffer start end 'corruption-detected :utf8-leading :offset (+ start 2)))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-truncation-before-content
  (dolist (contents '((#xc2 #x80) (#xdf #xbf) (#xe0 #xa0 #x80) (#xed #x9f #xbf)
                      (#xef #xbf #xbf) (#xf0 #x90 #x80 #x80) (#xf4 #x8f #xbf #xbf)))
    (multiple-value-bind (buffer start end) (utf8-fixture (append '(65 66) contents))
      (declare (ignore end))
      (loop for length from 1 below (length contents)
            for limit = (+ start 2 length)
            do (utf8-reject buffer start limit 'corruption-detected :utf8-truncated :offset limit))))
  ;; Secondo byte invalido o scalar vietato: la width incompleta ha priorita.
  (dolist (contents '((#xe0 0) (#xed #xa0) (#xf0 #xff) (#xf4 #x90 0)))
    (multiple-value-bind (buffer start end) (utf8-fixture contents)
      (utf8-reject buffer start end 'corruption-detected :utf8-truncated :offset end))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-continuation-offset-and-priority
  (dolist (contents '((#xc2 #x80) (#xe1 #x80 #x80) (#xf1 #x80 #x80 #x80)))
    (loop for position from 1 below (length contents)
          do (dolist (bad '(0 #x7f #xc0 #xc1 #xf5 #xff))
               (let ((altered (copy-list contents)))
                 (setf (nth position altered) bad)
                 (multiple-value-bind (buffer start end) (utf8-fixture (append '(65) altered))
                   (utf8-reject buffer start end 'corruption-detected :utf8-continuation
                                :offset (+ start 1 position)))))))
  (dolist (entry '(((#xe0 #x9f #x41) 2) ((#xed #xa0 #x7f) 2)
                   ((#xf0 #x8f #xbf 0) 3) ((#xf4 #x90 #xff #xbf) 2)
                   ((#xf1 0 0 0) 1)))
    (multiple-value-bind (buffer start end) (utf8-fixture (first entry))
      (utf8-reject buffer start end 'corruption-detected :utf8-continuation
                   :offset (+ start (second entry))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-scalar-restrictions-after-continuations
  (dolist (lead '(#xe0 #xed #xf0 #xf4))
    (loop for second from #x80 to #xbf
          do (let* ((contents (append (list lead second #x80) (when (>= lead #xf0) '(#x80))))
                    (valid (case lead (#xe0 (>= second #xa0)) (#xed (<= second #x9f))
                                      (#xf0 (>= second #x90)) (#xf4 (<= second #x8f)))))
               (multiple-value-bind (buffer start end) (utf8-fixture (append '(65 66) contents))
                 (if valid (utf8-accept buffer start end 3)
                     (utf8-reject buffer start end 'corruption-detected :utf8-scalar
                                  :offset (+ start 3))))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-seeded-scalar-stream-and-slices
  (let ((seed #x3629) (scalars '(0 #x7f #x80 #x7ff #x800 #xd7ff #xe000 #xffff #x10000 #x10ffff)))
    (dotimes (i 511)
      (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))
      (let ((scalar (mod seed #x110000)))
        (when (<= #xd800 scalar #xdfff) (incf scalar #x800))
        (push scalar scalars)))
    (multiple-value-bind (encoded ends) (utf8-encode-scalars scalars)
      (multiple-value-bind (buffer start end) (utf8-fixture encoded :prefix 3)
        (utf8-accept buffer start end (length scalars))
        (multiple-value-bind (valid count) (utf8-strict-reference buffer start end)
          (is valid) (is (= count (length scalars))))
        (loop for boundary in ends for count from 1
              do (utf8-accept buffer start (+ start boundary) count))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-utf8-differential-fuzz-4096-inputs
  ;; Seme e budget registrati, nessun RANDOM globale o expected dal prodotto.
  (let ((seed #x3629a11f) (accepted 0) (rejected 0))
    (flet ((advance () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (sample 4096)
        (let* ((length (+ 3 (mod (ash (advance) -16) 6)))
               (start (1+ (mod (ash (advance) -16) 7)))
               (end (+ start length))
               (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xff)))
          (dotimes (i length) (setf (aref buffer (+ start i)) (ldb (byte 8 24) (advance))))
          (multiple-value-bind (valid count) (utf8-strict-reference buffer start end)
            (if valid
                (progn (incf accepted) (utf8-accept buffer start end count :max-bytes length))
                (let ((before (copy-seq buffer)) (observed nil) (returned nil))
                  (handler-case (progn (arcdocdb.utf8:verifica-utf8 buffer start end :max-bytes length)
                                       (setf returned t))
                    (corruption-detected (condition) (setf observed condition)))
                  (is (and observed (not returned))) (is (equalp before buffer))
                  (incf rejected)))))))
    (is (= 4096 (+ accepted rejected))) (is (plusp accepted)) (is (plusp rejected))
    (format t "  UTF-8 fuzz: seed 3629A11F, 4096 input di 3..8 byte, ~D validi, ~D rifiutati.~%"
            accepted rejected)))

;;; REQ: REQ-LIM-001 REQ-AFF-008
(deftest test-REQ-LIM-001-utf8-exact-sixteen-mib-and-over-budget
  (let* ((start 3) (end (+ start +utf8-test-limit+))
         (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element 65)))
    (dotimes (i start) (setf (aref buffer i) #xff))
    (loop for i from end below (length buffer) do (setf (aref buffer i) #xff))
    ;; Omette la keyword: verifica il default pubblico e il massimo conteggio.
    (utf8-accept buffer start end +utf8-test-limit+)
    (utf8-reject buffer start (1+ end) 'resource-exhausted :utf8-byte-budget)))
