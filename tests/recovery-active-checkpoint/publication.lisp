;;;; Collegamento del risultato ACTIVE reale al publisher unico CONTROL.
;;; OWNER: fixture nativa esclusiva; nessun worker o mutazione globale.
;;; SHARED: solo lettura dei risultati; cleanup dopo l'intera chiamata.
;;; Oracoli: CLOSED2/128 storico, REMOVED3, nuovo ACTIVE13/next14,
;;; vecchio ACTIVE9 chiuso al prefisso noto con soli (101,0)/(102,4294967298).
(in-package #:arcdocdb.recovery.active.checkpoint.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun ra-publication-case (version thunk &key tail)
  (ra-with-case version
      (list (ra-batch 41 (ra-record :put 101 :flags 1 :value #(17))
                            (ra-record :tombstone 102 :flags 1)))
      (list (ra-decision 101 0) (ra-decision 102 #x100000002))
    thunk :tail (when tail (ct::zeros 17))))

(defun ra-publish-check-originals (case deadline)
  "Le nuove capacità del checkpoint non appartengono alla fotografia iniziale della fixture."
  (let ((before (ct::rp-data-observations (ra-case-native case))))
    (ct::native-read-bytes (ra-case-control-input case) (ra-case-control-bytes case) deadline)
    (ct::native-read-bytes (ra-case-input case) (ra-case-bytes case) deadline)
    (ct::native-read-bytes (ra-case-decision-input case) (ra-case-decision-bytes case) deadline)
    (is (equal before (ct::rp-data-observations (ra-case-native case))))))

(defun ra-next-checkpoint (case deadline prefix outcomes)
  "Dati attesi dichiarati prima delle factory; nessun esito estratto dal risultato ACTIVE."
  (let* ((fixture (ra-case-native case))
         (active (ct::native-active fixture (ra-case-directory case) (ra-case-path case)
                                    (ra-case-view case) 13 (ra-case-version case) deadline))
         (payload (ct::rp-payload 13 14
                    (list '(2 128 ((101 4294967298) (102 0))) (list 9 prefix outcomes)) '(3)))
         (expected (ct::control-reference-checkpoint
                    (ra-case-identity case) (ra-case-version case) payload 23))
         (plan (c:crea-checkpoint-control active payload 23 :max-segmenti 4 :max-esiti 8))
         (next (ct::native-prepare-plan fixture (ra-case-path case) (ra-case-directory case)
                                        "control.log.tmp" plan deadline)))
    (is (equalp expected (ct::native-checkpoint-bytes next)))
    (ct::native-read-bytes (ct::native-checkpoint-input next) expected deadline)
    next))

(defun ra-publish (next recovered deadline)
  (ct::native-bounded deadline :active-recovery-publication
    (lambda () (ra:pubblica-control-da-active (ct::native-checkpoint-prepared next) recovered))))

(defun ra-publication-state (next state observed)
  (is (equal (list state observed)
             (multiple-value-list (c:stato-pubblicazione-control (ct::native-checkpoint-prepared next))))))

(defun ra-check-published-manifest (manifest prefix)
  (is (= 13 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
  (is (equal '(t 14) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
  (dolist (entry (list '(:active 0 0 13) '(:closed 128 2 2) '(:removed 0 0 3)
                       (list :closed prefix 2 9)))
    (is (equal (subseq entry 0 3)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest (fourth entry))))))
  (dolist (fact '((2 101 t 4294967298) (2 102 t 0) (9 101 t 0) (9 102 t 4294967298) (9 999 nil 0)))
    (is (equal (cddr fact)
               (multiple-value-list
                (arcdocdb.recovery.manifest:trova-esito-chiusura manifest (first fact) (second fact)))))))

(defun ra-reopen-published (case next deadline)
  "Reopen del nome deciso, byte attesi indipendenti e nuovo recovery pubblico."
  (let* ((fixture (ra-case-native case))
         (input (ct::native-open fixture (merge-pathnames "control.log" (ra-case-path case)) :input deadline))
         (expected (ct::native-checkpoint-bytes next)) (size (length expected)))
    (is (equal (ct::native-identity input) (ct::native-identity (ct::native-checkpoint-input next))))
    (is (not (equal (ct::native-identity input) (ct::native-identity (ra-case-control-input case)))))
    (ct::native-absent (merge-pathnames "control.log.tmp" (ra-case-path case)))
    (ct::native-read-bytes input expected deadline)
    (let ((control (c:leggi-control-recuperato
                    (ra-case-view case) input size (ct::zeros size) :chunk-bytes 31
                    :max-bytes 4096 :max-batches 1 :max-batch-records 1
                    :max-edits 1 :max-segmenti 4 :max-esiti 8)))
      (is (equal (list size size :complete (ra-case-version case))
                 (multiple-value-list (c:frontiere-control-recuperato control))))
      (ra-check-published-manifest (c:manifest-control-recuperato control) (ra-case-prefix case)))
    (ct::native-read-bytes (ra-case-control-input case) (ra-case-control-bytes case) deadline)
    (ra-publish-check-originals case deadline)))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-REC-001-ACTIVE-RECOVERY-publication-native-reopen-complete-and-tail
  (dolist (version '(1 2))
    (dolist (tail '(nil t))
      (ra-publication-case version
        (lambda (case deadline)
          (let* ((recovered (ra-read case))
                 (next (ra-next-checkpoint case deadline (ra-case-prefix case) '((101 0) (102 4294967298))))
                 (before (ct::rp-observations (ra-case-native case))))
            (ra-reset-calls case)
            (let ((published (ra-publish next recovered deadline)))
              (is (typep published 'c:control-pubblicato))
              (is (equalp #(0 0 0 0 1 0 3 3 1) (ra-calls case)))
              (is (equal before (ct::rp-observations (ra-case-native case))))
              (ra-publication-state next :published t)
              (ra-check-published-manifest (c:manifest-control-pubblicato published) (ra-case-prefix case)))
            (ra-reopen-published case next deadline))) :tail tail))))

(defun ra-publish-rejected (case deadline next recovered type reason)
  (let ((before (ct::rp-observations (ra-case-native case))) (delivered nil))
    (ra-reset-calls case)
    (let ((condition (ct::native-capture-product-error
                     (lambda () (setf delivered (ra-publish next recovered deadline))))))
      (is (typep condition type)) (is (eq reason (arcdocdb.conditions:error-reason condition)))
      (is (null delivered)))
    (is (every #'zerop (ra-calls case)))
    (is (equal before (ct::rp-observations (ra-case-native case))))
    (ra-publication-state next :prepared nil)
    (is (equal (ct::native-path-identity (merge-pathnames "control.log" (ra-case-path case)))
               (ct::native-identity (ra-case-control-input case)))))
  nil)

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-001
(deftest test-REQ-REC-001-ACTIVE-RECOVERY-publication-rejects-wrong-prefix-before-claim
  (dolist (version '(1 2))
    (dolist (delta '(-1 1))
      (ra-publication-case version
        (lambda (case deadline)
          (let* ((recovered (ra-read case))
                 (next (ra-next-checkpoint case deadline (+ delta (ra-case-prefix case)) '((101 0) (102 4294967298)))))
            (ra-publish-rejected case deadline next recovered 'arcdocdb.conditions:invalid-argument
                                 :active-recovery-closure)
            (ra-publish-check-originals case deadline)))))))

;;; REQ: REQ-TXM-007 REQ-REC-001 REQ-AFF-001
(deftest test-REQ-TXM-007-ACTIVE-RECOVERY-publication-rejects-omitted-extra-or-changed-outcome
  (dolist (version '(1 2))
    (dolist (outcomes '(((101 0)) ((101 0) (102 4294967298) (103 7))
                        ((101 1) (102 4294967298)) ((101 0) (103 4294967298))))
      (ra-publication-case version
        (lambda (case deadline)
          (let* ((recovered (ra-read case))
                 (next (ra-next-checkpoint case deadline (ra-case-prefix case) outcomes)))
            (ra-publish-rejected case deadline next recovered 'arcdocdb.conditions:invalid-argument
                                 (if (= 2 (length outcomes)) :active-recovery-closure-outcome :active-recovery-closure))
            (ra-publish-check-originals case deadline)))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-REC-001-ACTIVE-RECOVERY-publication-rejects-closed-old-segment-before-claim
  (dolist (version '(1 2))
    (ra-publication-case version
      (lambda (case deadline)
        (let* ((recovered (ra-read case))
               (next (ra-next-checkpoint case deadline (ra-case-prefix case) '((101 0) (102 4294967298)))))
          (ra-publish-check-originals case deadline)
          (io:chiudi (ra-case-input case))
          (ra-publish-rejected case deadline next recovered 'arcdocdb.conditions:io-fault :io-unavailable))))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-002 REQ-AFF-018
(deftest test-REQ-AFF-002-ACTIVE-RECOVERY-publication-original-fsync-fault-after-rename
  (dolist (version '(1 2))
    (ra-publication-case version
      (lambda (case deadline)
        (let* ((recovered (ra-read case))
               (next (ra-next-checkpoint case deadline (ra-case-prefix case) '((101 0) (102 4294967298))))
               (fixture (ra-case-native case)) (observer (ct::native-fixture-observer fixture))
               (before (ct::rp-data-observations fixture))
               (original (make-condition 'arcdocdb.conditions:io-fault :reason :active-recovery-fsync
                                         :operation :flush :errno sb-posix:eio)) (delivered nil))
          (setf (ct::native-observer-directory-failure observer) original)
          (ra-reset-calls case)
          (let ((condition (ct::native-capture-product-error
                           (lambda () (setf delivered (ra-publish next recovered deadline))))))
            (is (eq original condition)) (is (null delivered)))
          (is (equalp #(0 0 0 0 1 0 3 3 1) (ra-calls case)))
          (ra-publication-state next :faulted t)
          (is (eq :faulted (io:stato-file (ra-case-directory case))))
          (is (equal before (ct::rp-data-observations fixture)))
          (setf (ct::native-observer-directory-failure observer) nil)
          ;; Le query verificano il rename osservato, senza affermare fsync riuscito.
          (ra-reopen-published case next deadline))))))
