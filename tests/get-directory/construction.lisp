(in-package #:arcdocdb.get.directory.tests)

(defvar *get-directory-tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *get-directory-tests*)))
(defun run ()
  (dolist (test (reverse *get-directory-tests*))
    (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test directory GET superati.~%" (length *get-directory-tests*))
  t)

;;; REQ: REQ-STO-003 REQ-IDX-001 REQ-AFF-002
(deftest test-REQ-STO-003-directory-native-read-nonzero-buffer-start
  (with-directory-fixture (fixture :cache-p nil :observe-io-p t)
    (let* ((end (aref (directory-fixture-ends fixture) 0))
           (buffer (directory-octets end #xcc))
           (image (aref (directory-fixture-images fixture) 0)))
      ;; La API restituisce la fine nel buffer, non la quantità END-64.
      (is (= end (io:leggi-esatto (aref (directory-fixture-files fixture) 0)
                                 buffer 64 end 64)))
      (dotimes (i 64) (is (= #xcc (aref buffer i))))
      (loop for i from 64 below end do (is (= (aref image i) (aref buffer i))))
      (is (equal (list (list #xffffffff 64 (- end 64))) (directory-read-events fixture)))
      (is (directory-check-clean fixture)))))

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-empty-and-payload12N
  (dolist (count '(0 1 4))
    (with-directory-fixture (fixture :count count :cache-p nil)
      (let* ((directory (directory-fixture-directory fixture))
             (maps (directory-fixture-maps fixture))
             (ids (d::directory-get-serie-ids directory))
             (owned (d::directory-get-serie-maps directory)))
        (is (= count (d:conta-segmenti-directory-get directory)))
        (is (= (* 12 count) (d:payload-directory-get-serie directory)))
        (is (typep maps 'simple-vector))
        (is (typep owned 'simple-vector))
        (is (typep ids '(simple-array (unsigned-byte 32) (*))))
        (is (not (eq maps owned)))
        (is (= count (length (directory-fixture-keys fixture)) (length (directory-fixture-values fixture))))
        (is (= 4 (length (directory-fixture-outputs fixture))))
        (is (equalp ids (coerce (directory-fixture-ids fixture) '(vector (unsigned-byte 32)))))
        (dotimes (i count)
          (is (eq (aref maps i) (aref owned i)))
          (is (typep (aref (directory-fixture-keys fixture) i) '(simple-array (unsigned-byte 8) (16))))
          (is (eq :input (io:mode-file (aref (directory-fixture-files fixture) i))))
          (is (eq :open (io:stato-file (aref (directory-fixture-files fixture) i)))))
        (when (plusp count) (is (= #xffffffff (aref ids (1- count)))))
        (is (= (* count 24) (loop for map across maps sum (r:payload-mappa-segmento-get map))))
        (is (eq :idle (g:stato-contesto-get (aref (directory-fixture-contexts fixture) 0))))
        (is (directory-check-clean fixture))))))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(deftest test-REQ-AFF-008-directory-budget-exact-and-one-short
  (with-directory-fixture (fixture :count 3 :cache-p nil)
    (let ((view (directory-fixture-view fixture)) (maps (directory-fixture-maps fixture)))
      (is (= 36 (d:payload-directory-get-serie
                 (d:crea-directory-get-serie view maps :max-segments 3 :budget-payload 36))))
      (signals resource-exhausted
        (d:crea-directory-get-serie view maps :max-segments 2 :budget-payload 36)
        :directory-segment-budget)
      (signals resource-exhausted
        (d:crea-directory-get-serie view maps :max-segments 3 :budget-payload 35)
        :directory-payload-budget)
      (is (every (lambda (file) (eq :open (io:stato-file file))) (directory-fixture-files fixture)))
      (is (= 0 (d:payload-directory-get-serie
                (d:crea-directory-get-serie view #() :max-segments 1 :budget-payload 0)))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-directory-invalid-configuration-and-maps
  (with-directory-fixture (fixture :cache-p nil)
    (let ((view (directory-fixture-view fixture)) (maps (directory-fixture-maps fixture)))
      (dolist (maximum '(0 -1 65537 nil 1/2))
        (signals invalid-argument (d:crea-directory-get-serie view maps :max-segments maximum)
                 :directory-configuration))
      (dolist (budget '(-1 nil 1/2))
        (signals invalid-argument (d:crea-directory-get-serie view maps :budget-payload budget)
                 :directory-configuration))
      (dolist (bad (list nil '(nil) (directory-octets 1)
                        (make-array 1 :initial-element (aref maps 0) :adjustable t)
                        (make-array 1 :initial-element (aref maps 0) :fill-pointer 1)
                        (make-array 1 :displaced-to maps)))
        (signals invalid-argument (d:crea-directory-get-serie view bad) :directory-maps))
      (signals invalid-argument (d:crea-directory-get-serie view (vector nil)) :directory-maps)
      (signals invalid-argument (d:crea-directory-get-serie view (vector (directory-fixture-view fixture)))
               :directory-maps)
      ;; Preflight cardinalità/payload prima di osservare anche un solo elemento.
      (signals resource-exhausted (d:crea-directory-get-serie view (vector nil) :budget-payload 11)
               :directory-payload-budget)
      (signals resource-exhausted (d:crea-directory-get-serie view (make-array 65537 :initial-element nil))
               :directory-segment-budget))))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-IDX-001-directory-input-array-copied
  (with-directory-fixture (fixture :count 4 :cache-p nil)
    (let* ((input (directory-fixture-maps fixture))
           (expected (copy-seq input)))
      ;; Riutilizzo dell'array del caller subito dopo la costruzione, senza mutare le mappe.
      (fill input nil)
      (dotimes (i 4)
        (unwind-protect
             (progn
               (is (eq :candidate (directory-begin fixture :ordinal i)))
               (is (eq (aref expected i)
                       (d:trova-mappa-directory-get (aref (directory-fixture-contexts fixture) 0)
                                                   (directory-fixture-directory fixture)))))
          (g:abbandona-get (aref (directory-fixture-contexts fixture) 0)))
        (is (eq :found (directory-checked-read fixture :ordinal i))))
      (is (= 48 (d:payload-directory-get-serie (directory-fixture-directory fixture)))))))

;;; REQ: REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-duplicates-and-descending-order
  (with-directory-fixture (fixture :count 3 :cache-p nil)
    (let ((maps (directory-fixture-maps fixture)) (view (directory-fixture-view fixture)))
      (signals invalid-argument (d:crea-directory-get-serie view (vector (aref maps 0) (aref maps 0)))
               :directory-source-order)
      (signals invalid-argument (d:crea-directory-get-serie view (reverse maps)) :directory-source-order)
      (signals invalid-argument
        (d:crea-directory-get-serie view (vector (aref maps 0) (aref maps 2) (aref maps 1)))
        :directory-source-order))))

;;; REQ: REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-CMP-007-directory-canonical-owner-and-foreign-owner
  (with-directory-fixture (fixture :cache-p nil)
    (with-directory-fixture (foreign :cache-p nil)
      (let* ((view (directory-fixture-view fixture))
             ;; Stessi legami e byte ID: serve comunque l'identità canonica EQ della vista.
             (copy (g:crea-vista-get-serie (directory-fixture-scope fixture) (directory-fixture-index fixture)
                                         nil (copy-seq (g::vista-get-serie-identity view)))))
        (signals invalid-argument (d:crea-directory-get-serie copy (directory-fixture-maps fixture))
                 :directory-source-owner)
        (signals invalid-argument (d:crea-directory-get-serie view (directory-fixture-maps foreign))
                 :directory-source-owner)
        (is (not (eq (directory-fixture-root fixture) (directory-fixture-root foreign))))
        (is (not (equalp (directory-fixture-paths fixture) (directory-fixture-paths foreign))))))))

(defun directory-fi-segment-map (fixture high low &optional file)
  "FI della capacità senza I/O: clona una mappa reale, sostituisce soltanto segmento/FD."
  (let* ((map (aref (directory-fixture-maps fixture) 0))
         (original (r::mappa-segmento-get-segment map))
         (segment (g::%make-segmento-get (directory-fixture-view fixture)
                                       (or file (g::segmento-get-file original)) high low
                                       (g::segmento-get-version original) (g::segmento-get-origin original))))
    (r::%make-mappa-segmento-get segment (r::mappa-segmento-get-end map) (r::mappa-segmento-get-rows map))))

;;; REQ: REQ-IDX-001 REQ-FOR-002 REQ-CMP-007
(deftest test-REQ-IDX-001-directory-segment-zero-highbits-and-lifetime
  (with-directory-fixture (fixture :cache-p nil)
    (dolist (parts '((0 0) (1 17) (#xffffffff #xffffffff)))
      (signals invalid-argument
        (d:crea-directory-get-serie (directory-fixture-view fixture)
                                    (vector (directory-fi-segment-map fixture (first parts) (second parts))))
        :directory-source-segment))
    ;; File realmente chiuso prima della costruzione: capacità scaduta rifiutata.
    (io:chiudi (aref (directory-fixture-files fixture) 0))
    (signals invalid-argument
      (d:crea-directory-get-serie (directory-fixture-view fixture) (directory-fixture-maps fixture))
      :directory-source-lifetime))
  (with-directory-fixture (fixture :cache-p nil)
    (let ((path (merge-pathnames "append-only.tmp" (directory-fixture-root fixture))))
      (let ((writer (io:crea-temporaneo path)))
        (unwind-protect
             (signals invalid-argument
               (d:crea-directory-get-serie (directory-fixture-view fixture)
                                           (vector (directory-fi-segment-map fixture 0 17 writer)))
               :directory-source-lifetime)
          (io:chiudi writer) (sb-posix:unlink (namestring path)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-IDX-001-directory-65536-first-last-search17
  (with-directory-fixture (fixture :cache-p nil)
    (let* ((maps (make-array 65536)) (view (directory-fixture-view fixture))
           (context (aref (directory-fixture-contexts fixture) 0))
           (first-key (directory-key 100000)))
      ;; Geometria sintetica: ogni capacità usa il solo FD verificato e aperto della fixture.
      ;; Il caso seleziona soltanto mappe; non è prova CLOSED di 65.536 file reali.
      (dotimes (i 65536)
        (setf (aref maps i) (directory-fi-segment-map fixture 0 (if (= i 65535) #xffffffff (1+ (* 2 i))))))
      (let ((directory (d:crea-directory-get-serie view maps :max-segments 65536 :budget-payload 786432)))
        (is (= 65536 (d:conta-segmenti-directory-get directory)))
        (is (= 786432 (d:payload-directory-get-serie directory)))
        (signals resource-exhausted (d:crea-directory-get-serie view maps :budget-payload 786431)
                 :directory-payload-budget)
        (signals resource-exhausted (d:crea-directory-get-serie view maps :max-segments 65535)
                 :directory-segment-budget)
        (is (= 17 d::+directory-search-attempts+))
        ;; In un array di 2^16 elementi, il primo richiede tutti i diciassette passi.
        (directory-publish-key fixture first-key +directory-max-csn+ 1 64 56)
        (dolist (entry (list (list first-key 0) (list (aref (directory-fixture-keys fixture) 0) 65535)))
          (unwind-protect
               (progn
                 (is (eq :candidate (g:avvia-get context view (first entry) nil 0 11)))
                 (is (eq (aref maps (second entry)) (d:trova-mappa-directory-get context directory))))
            (g:abbandona-get context)))
        (is (directory-check-clean fixture))))))
