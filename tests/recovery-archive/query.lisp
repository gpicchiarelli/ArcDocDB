;;;; Contratti degli oggetti e query scalari del recovery Archivio.
;;; OWNER: runner seriale; spec e buffer privati, nessuna FI globale o sorgente prodotto modificato.
;;; SHARED: risultati interrogati senza scritture, FD/array interni mai esportati dalle API usate.
;;; Limiti: matrici finite v1/v2, file <=4096 byte, query su tutti i 128 bit di ID16.
;;; REQ: REQ-REC-001 REQ-TXM-001 REQ-TXM-005 REQ-AFF-008 REQ-AFF-017
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun darq-specs ()
  (let ((ids (list (rt::participant-id 0) (rt::participant-id #xffffffffffffffff #x80)
                   (rt::participant-id 1 #xff))))
    (list (rt::decision-spec #xffffffffffffffff #xffffffffffffffff (reverse ids))
          (rt::decision-spec #x100000001 #x8000000000000000 ids)
          (rt::decision-spec 0 0 (reverse ids))
          (rt::decision-spec #x8000000000000000 #x100000001 ids)
          (rt::decision-spec 1 #xffffffffffffffff ids))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-TYPES-constructor-rejects-invalid-identity-and-scope
  (let* ((view (ct::crr-view (av::av-identity)))
         (scope (arcdocdb.get::vista-get-serie-scope view)))
    (dolist (size '(0 15 17 64))
      (let ((identity (ct::crr-bytes size)))
        (dar-expect 'invalid-argument :archive-recovery-identity
          (lambda () (da:crea-archivio-recovery scope identity)))))
    (dolist (identity (list nil "0123456789abcdef" (make-array 16 :initial-element 0)))
      (dar-expect 'type-error nil
        (lambda () (dar-invoke 'da:crea-archivio-recovery scope identity))))
    (dolist (invalid-scope (list nil view :not-an-archive-scope))
      (dar-expect 'type-error nil
        (lambda () (dar-invoke 'da:crea-archivio-recovery invalid-scope (dar-identity)))))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-001 REQ-AFF-017
(deftest test-REQ-AFF-017-ARCHIVE-TYPES-owns-caller-uuid-with-separate-serie-scope
  (dolist (version '(1 2))
    (let* ((identity (dar-identity)) (before (copy-seq identity))
           (view (ct::crr-view (av::av-identity)))
           (scope (arcdocdb.get::vista-get-serie-scope view))
           (source (dar-log (list (darr-specs)) :version version :identity identity)))
      (dar-with-input source
        (lambda (f)
          (is (typep (dar-fixture-archive f) 'da:archivio-recovery))
          (is (equalp identity before))
          (fill identity 0)
          ;; L'header conserva l'UUID autorevole copiato prima della modifica del caller.
          (darr-success f version (darr-specs))
          (is (every #'zerop identity))
          (is (equalp (arcdocdb.get::vista-get-serie-identity view) (av::av-identity))))
        :scope scope :identity identity))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-TXM-001-ARCHIVE-QUERY-u64-zero-high-maximum-and-missing
  (dolist (version '(1 2))
    (let ((specs (darq-specs)))
      (dolist (order (list specs (reverse specs)))
        (dar-with-input (dar-log (list order) :version version)
          (lambda (f)
            (let ((result (dar-call f)))
              (dar-clear f)
              (darr-result result (dar-fixture-size f) (dar-fixture-size f) :complete version)
              (darr-table result specs '(2 #x100000000 #x8000000000000001 #xfffffffffffffffe))
              (is (equal '(t 0 3) (multiple-value-list (da:trova-decisione-recuperata result 0))))
              (is (equal '(nil 0 0) (multiple-value-list (da:trova-decisione-recuperata result 2))))
              (darr-events f nil) (dar-noeffects f))))))))

;;; REQ: REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-AFF-017-ARCHIVE-QUERY-owns-result-after-scratch-and-caller-reuse
  (dolist (version '(1 2))
    (let* ((specs (darq-specs))
           (oracle (mapcar (lambda (spec)
                             (rt::decision-spec (first spec) (second spec) (mapcar #'copy-seq (third spec))))
                           specs))
           (source (dar-log (list specs) :version version)))
      (dar-with-input source
        (lambda (f)
          (let ((first (dar-call f)))
            (fill (dar-fixture-scratch f) #xff)
            (fill source 0)
            (dolist (spec specs) (dolist (id (third spec)) (fill id 0)))
            (dar-clear f) (darr-table first oracle) (darr-events f nil)
            ;; Una seconda lettura riusa lo stesso scratch senza invalidare il primo risultato.
            (let ((second (dar-call f :chunk-bytes 1)))
              (is (not (eq first second)))
              (dar-clear f) (fill (dar-fixture-scratch f) #xa5)
              (darr-table first oracle) (darr-table second oracle)
              (darr-result first (dar-fixture-size f) (dar-fixture-size f) :complete version)
              (darr-events f nil) (dar-noeffects f))))))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-TXM-001-ARCHIVE-QUERY-participant-all-bits-and-nonzero-slice
  (dolist (version '(1 2))
    (let* ((base (ct::crr-bytes 16 #x80)) (other (ct::crr-bytes 16 #xff))
           (spec (rt::decision-spec 0 0 (list other base))))
      (dar-with-input (dar-log (list (list spec)) :version version)
        (lambda (f)
          (let* ((result (dar-call f)) (slice (ct::crr-bytes 22 #x55)))
            (replace slice base :start1 3)
            (dar-clear f)
            (is (da:partecipante-decisione-recuperata-p result 0 slice 3 19))
            (is (not (da:partecipante-decisione-recuperata-p result 1 slice 3 19)))
            (dotimes (byte 16)
              (dotimes (bit 8)
                (let ((query (copy-seq base)))
                  (setf (aref query byte) (logxor (aref query byte) (ash 1 bit)))
                  (is (not (da:partecipante-decisione-recuperata-p result 0 query 0 16))))))
            (fill slice 0)
            (is (not (da:partecipante-decisione-recuperata-p result 0 slice 3 19)))
            (is (da:partecipante-decisione-recuperata-p result 0 base 0 16))
            (is (da:partecipante-decisione-recuperata-p result 0 other 0 16))
            (darr-events f nil) (dar-noeffects f)))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005
(deftest test-REQ-AFF-008-ARCHIVE-QUERY-invalid-ranges-even-for-absent-txid
  (dolist (version '(1 2))
    (dar-with-input (dar-log (list (darr-specs)) :version version)
      (lambda (f)
        (let* ((result (dar-call f)) (identity (ct::crr-bytes 20 #x80))
               (before (copy-seq identity)))
          (dar-clear f)
          (dolist (txid '(17 1024))
            (dolist (range '((-1 15) (0 -1) (17 16) (0 21) (21 21)))
              (dar-expect 'invalid-argument :buffer-range
                (lambda () (da:partecipante-decisione-recuperata-p
                             result txid identity (first range) (second range)))))
            (dolist (range '((0 0) (0 15) (0 17) (3 18) (3 20) (20 20)))
              (let ((condition (dar-expect 'invalid-argument :serie-id-length
                                 (lambda () (da:partecipante-decisione-recuperata-p
                                              result txid identity (first range) (second range))))))
                (is (= (first range) (error-offset condition)))))
            (is (not (da:partecipante-decisione-recuperata-p result txid identity 2 18))))
          (is (equalp before identity)) (darr-events f nil) (dar-noeffects f))))))

;;; REQ: REQ-AFF-008 REQ-TXM-001 REQ-TXM-005
(deftest test-REQ-AFF-008-ARCHIVE-QUERY-invalid-types-have-no-io
  (dar-with-input (dar-log (list (darr-specs)))
    (lambda (f)
      (let ((result (dar-call f)) (identity (rt::participant-id 1)))
        (dar-clear f)
        (dolist (invalid (list nil :not-recovered (dar-fixture-archive f)))
          (dolist (function (list #'da:frontiere-decisioni-recuperate #'da:numero-decisioni-recuperate))
            (dar-expect 'type-error nil (lambda () (funcall function invalid))))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da:trova-decisione-recuperata invalid 17)))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da:partecipante-decisione-recuperata-p invalid 17 identity 0 16))))
        (dolist (txid (list -1 #x10000000000000000 1/2 :not-a-txid))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da:trova-decisione-recuperata result txid)))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da:partecipante-decisione-recuperata-p result txid identity 0 16))))
        (dolist (buffer (list nil "0123456789abcdef" (make-array 16 :initial-element 0)))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da:partecipante-decisione-recuperata-p result 17 buffer 0 16))))
        (darr-events f nil) (dar-noeffects f)))))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-AFF-017-ARCHIVE-QUERY-two-archives-keep-independent-decisions
  (dolist (version '(1 2))
    (let* ((a (first (darr-specs)))
           (b (rt::decision-spec (first a) #xffffffffffffffff
                                 (list (rt::participant-id 3) (rt::participant-id 4 #xff))))
           (other-id (rt::participant-id #xffffffffffffffff #xe2)))
      (dar-with-input (dar-log (list (list a)) :version version)
        (lambda (left)
          (let ((first (dar-call left)))
            (dar-with-input (dar-log (list (list b)) :version version :identity other-id)
              (lambda (right)
                (let ((second (dar-call right)))
                  (dar-clear left) (dar-clear right)
                  (darr-table first (list a)) (darr-table second (list b))
                  (is (not (da:partecipante-decisione-recuperata-p first (first a) (first (third b)) 0 16)))
                  (is (not (da:partecipante-decisione-recuperata-p second (first a) (first (third a)) 0 16)))
                  (darr-events left nil) (darr-events right nil)
                  (dar-noeffects left) (dar-noeffects right)))
              :identity other-id)))))))
