(in-package #:arcdocdb.fulltext.analysis.tests)

(defun normalized-scalars (space scalars)
  "Esercita la stessa NFC del profilo isolando le altre fasi."
  (replace (a::spazio-full-text-a space) scalars)
  (setf (a::spazio-full-text-a-count space) (length scalars)
        (a::spazio-full-text-b-count space) 0 (a::spazio-full-text-cursor space) 0
        (a::spazio-full-text-stack-top space) 0 (a::spazio-full-text-work space) 0
        (a::spazio-full-text-phase space) :decompose (a::spazio-full-text-nfc-only space) t)
  (complete space)
  (coerce (subseq (a::spazio-full-text-b space) 0 (a::spazio-full-text-b-count space)) 'list))

(deftest req-sec-007-normalization-conformance
  (let ((space (small-space)) (rows 0) (comparisons 0))
    (each-data-line "NormalizationTest.txt"
     (lambda (line number)
       (let ((columns (mapcar #'cp-list (subseq (uiop:split-string line :separator ";") 0 5))))
         (incf rows)
         (loop for input in columns for i from 0 do
           (incf comparisons)
           (unless (equal (normalized-scalars space input) (nth (if (< i 3) 1 3) columns))
             (error "NFC non conforme riga ~D colonna ~D: ~S" number (1+ i) input))))))
    (is (> rows 20000))
    (format t "Unicode 18 NFC: ~D righe, ~D confronti.~%" rows comparisons)))

(defun prepare-word-context (space scalars)
  (replace (a::spazio-full-text-b space) scalars)
  (setf (a::spazio-full-text-b-count space) (length scalars)
        (a::spazio-full-text-work space) 0 (a::spazio-full-text-cursor space) 0
        (a::spazio-full-text-significant space) a::+nessuno+ (a::spazio-full-text-ri-count space) 0
        (a::spazio-full-text-phase space) :left)
  (loop repeat (+ 2 (* 2 (length scalars))) do
    (case (a::spazio-full-text-phase space)
      (:left (a::passo-contesto-sinistro space)) (:right (a::passo-contesto-destro space))
      (otherwise (error "Contesto troppo breve/lungo"))))
  (is (eq :boundaries (a::spazio-full-text-phase space))))

(deftest req-sec-007-word-break-conformance
  (let ((space (small-space)) (rows 0) (checks 0))
    (each-data-line "auxiliary/WordBreakTest.txt"
     (lambda (line number)
       (let ((scalars nil) (boundaries nil))
         (loop for item in (remove "" (uiop:split-string line :separator '(#\Space #\Tab)) :test #'equal)
               for i from 0 do
           (if (evenp i) (push (string= item "÷") boundaries)
               (push (parse-integer item :radix 16 :junk-allowed nil) scalars)))
         (setf scalars (nreverse scalars) boundaries (nreverse boundaries))
         (prepare-word-context space scalars) (incf rows)
         (loop for expected in boundaries for i from 0 do
           (incf checks)
           (unless (eq expected (a::confine-parola-p space i))
             (error "Word_Break non conforme riga ~D confine ~D: ~S" number i scalars))))))
    (is (> rows 1500))
    (format t "Unicode 18 Word_Break: ~D righe, ~D confini.~%" rows checks)))

(deftest req-sec-007-full-case-fold-conformance
  (let ((rows 0))
    (each-data-line "CaseFolding.txt"
     (lambda (line number)
       (let* ((columns (uiop:split-string line :separator ";"))
              (status (string-trim " " (second columns))))
         (when (member status '("C" "F") :test #'equal)
           (let* ((space (small-space)) (cp (first (cp-list (first columns))))
                  (expected (cp-list (third columns)))
                  (entry (a::trova-mapping space a::+fold-records+ cp)))
             (is (not (minusp entry)))
             (let ((offset (aref a::+fold-records+ (1+ entry)))
                   (n (aref a::+fold-records+ (+ entry 2))))
               (unless (equal expected (coerce (subseq a::+fold-data+ offset (+ offset n)) 'list))
                 (error "Case folding non conforme riga ~D" number)))
             (incf rows))))))
    (is (> rows 1500)) (format t "Unicode 18 case fold C/F: ~D mapping.~%" rows)))
