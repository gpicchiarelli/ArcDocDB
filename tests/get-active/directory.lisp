;;;; Geometria locale ACTIVE: directory sintetiche separate dai lotti nativi.
;;; OWNER: test seriale, array esclusivi; nessuna pubblicazione sintetica nel controller.
;;; SHARED: il contesto reale rimane sotto EBR fino al cleanup esplicito del test.
(in-package #:arcdocdb.get.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun active-directory-page (segment rank)
  "Pagina sintetica senza PUT, fine 65+rank: oracolo solo della ricerca locale."
  (r::%make-mappa-segmento-get
   segment (+ 65 rank) (make-array 0 :element-type '(unsigned-byte 32))))

(defun active-directory-snapshot (directory)
  "Cattura identità e sedici riferimenti di ogni nodo, al massimo quattro livelli."
  (let ((result nil))
    (labels ((walk (node depth)
               (when node
                 (is (and (typep node 'simple-vector) (= 16 (length node))))
                 (push (cons node (copy-seq node)) result)
                 (when (< depth 3)
                   (dotimes (i 16) (walk (svref node i) (1+ depth)))))))
      (walk directory 0))
    result))

(defun active-directory-unchanged-p (snapshot)
  (every (lambda (pair)
           (loop for actual across (car pair) for expected across (cdr pair)
                 always (eql actual expected)))
         snapshot))

(defun active-reference-directory (segment count)
  "Oracolo diretto: quattro nibble di rank, senza append/lookup del prodotto."
  (let ((directory (make-array 16 :initial-element nil)) (pages (make-array count)))
    (dotimes (rank count)
      (let ((node directory))
        (dolist (shift '(12 8 4))
          (let ((slot (ldb (byte 4 shift) rank)))
            (unless (svref node slot)
              (setf (svref node slot) (make-array 16 :initial-element nil)))
            (setf node (svref node slot))))
        (setf (aref pages rank) (active-directory-page segment rank)
              (svref node (ldb (byte 4 0) rank)) (aref pages rank))))
    (values directory pages)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-active-directory-nibble-transitions-persistent
  (with-active-fixture (f :publish-count 1)
    (let ((directory nil) (nodes 0) (pages nil))
      (loop for rank in '(0 15 16 255 256 4095 4096)
            for expected-added in '(4 0 1 1 2 2 3)
            do (let ((page (active-directory-page (af-segment f) rank))
                     (before (active-directory-snapshot directory)))
                 (multiple-value-bind (next added)
                     (r::appendi-pagina-attiva directory rank page 12)
                   (is (= expected-added added))
                   (is (active-directory-unchanged-p before))
                   (setf directory next) (incf nodes added)
                   (push (cons rank page) pages))))
      (is (= 13 nodes))
      (let ((root (r::%make-radice-get-attiva (af-source f) directory 4097 0 nodes 4161 nil)))
        (is (eq :candidate (active-begin f 0)))
        (unwind-protect
             (dolist (pair pages)
               (is (eq (cdr pair) (r::pagina-attiva (af-context f) root (car pair)))))
          (g:abbandona-get (af-context f)))
        (is (active-clean-p f))))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-active-directory-65536-final-convergence
  (with-active-fixture (f :publish-count 1)
    (multiple-value-bind (directory pages) (active-reference-directory (af-segment f) 65536)
      (let ((root (r::%make-radice-get-attiva (af-source f) directory 65536 0 4369 65600 nil)))
        (is (= 559232 (r:payload-radice-get-attiva root)))
        (is (eq :candidate (active-begin f 0)))
        (unwind-protect
             (dolist (rank '(0 1 15 16 255 256 4095 4096 32767 32768 65534 65535))
               (is (eq (aref pages rank) (r::pagina-attiva (af-context f) root rank)))
               (is (eq (aref pages rank)
                       (r::trova-pagina-attiva (af-context f) root (+ 64 rank)))))
          (g:abbandona-get (af-context f)))
        (is (active-clean-p f))))))

;;; REQ: REQ-IDX-001 REQ-AFF-002
(deftest test-REQ-IDX-001-active-directory-malformed-local-guards
  ;; FI rispettano il tipo SIMPLE-VECTOR della radice; figli hanno tipo T.
  ;; PAGINA-ATTIVA è un helper locale: il test possiede esplicitamente il cleanup.
  (dolist (mode '(:missing :width :leaf :rank))
    (with-active-fixture (f :publish-count 1)
      (multiple-value-bind (directory pages) (active-reference-directory (af-segment f) 1)
        (is (= 1 (length pages)))
        (ecase mode
          (:missing (setf (svref directory 0) nil))
          (:width (setf (svref directory 0) (make-array 15 :initial-element nil)))
          (:leaf (setf (svref (svref (svref (svref directory 0) 0) 0) 0) 17))
          (:rank nil))
        (let ((root (r::%make-radice-get-attiva (af-source f) directory 1 0 4 65 nil)))
          (is (eq :candidate (active-begin f 0)))
          (unwind-protect
               (progn
                 (signals invariant-violation
                   (r::pagina-attiva (af-context f) root (if (eq mode :rank) 1 0))
                   (ecase mode (:missing :active-directory-shape) (:width :active-directory-shape)
                     (:leaf :active-page-type) (:rank :active-page-rank)))
                 (is (eq :faulted (g:stato-contesto-get (af-context f)))))
            (g:abbandona-get (af-context f)))
          (is (active-clean-p f :faulted)))))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-active-directory-occupied-append-preserves-graph
  (with-active-fixture (f :publish-count 1)
    (multiple-value-bind (directory pages) (active-reference-directory (af-segment f) 1)
      (let ((before (active-directory-snapshot directory)))
        (signals invariant-violation
          (r::appendi-pagina-attiva directory 0 (aref pages 0) 12) :active-directory-occupied)
        (is (active-directory-unchanged-p before))
        (signals invariant-violation
          (r::appendi-pagina-attiva (make-array 15 :initial-element nil) 1 (aref pages 0) 12)
          :active-directory-shape)
        (is (active-directory-unchanged-p before))))))
