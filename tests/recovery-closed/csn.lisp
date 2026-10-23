;;;; Massimi osservati CLOSED e aggregazione completa della Serie.
;;; OWNER: runner seriale; CONTROL reale e tutti i FD restano aperti fino al cleanup.
;;; SHARED: nessun registro CSN o oggetto del prodotto costruito manualmente.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-TXM-007 REQ-AFF-008
(in-package #:arcdocdb.recovery.closed.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun cdrc-maximum (result expected)
  "I due valori distinguono CSN zero realmente presente dall'assenza."
  (is (equal expected (multiple-value-list (cr:massimo-csn-closed-recuperato result)))))

(defun cdrc-active (f batches version)
  "ACTIVE9 reale, backend del CONTROL della fixture e tabella canonica completa vuota."
  (let* ((bytes (rac::ra-active-bytes version (ct::crr-uuid) batches))
         (input (cdr-add-input f bytes)) (scratch (ct::crr-bytes (length bytes) #xa5))
         (decisions (av::av-decision-table nil version)))
    (values (arcdocdb.recovery.active:leggi-active-recuperato
             (cdr-fixture-control f) input (length bytes) decisions scratch
             :max-bytes 4096 :max-batches 16 :max-records 32
             :max-batch-records 16 :max-batch-bytes 4096 :max-prepared 16 :max-outcomes 16)
            input scratch)))

(defun cdrc-serie (f active closed expected &rest options)
  "Massimo completo dal gate pubblico; nessuna rilettura dei file per la query."
  (cdr-clear f)
  (is (equal expected
             (multiple-value-list (apply #'cr:massimo-csn-serie-recuperata active closed options))))
  (is (null (cdr-events f)))
  (cdr-noeffects f))

;;; CSR-D02/D03: writer vuoto e compaction vuota non osservano alcun CSN.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006
(deftest test-REQ-MVC-005-CLOSED-csn-vuoto-contro-zero-presente
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (cdr-with-fixture (cdr-log nil :version version :origin origin)
        (lambda (f)
          (let ((result (cdr-call f)))
            (cdr-clear f)
            (cdrc-maximum result '(nil 0))
            (is (null (cdr-events f)))
            (cdr-noeffects f)))
        :version version)
      (let ((source (if (= origin 1)
                        (cdr-log (list (cdr-batch 0 (cdr-record :put 0))) :version version)
                        (cdr-log nil :version version :origin 2 :records (list (cdr-record :put 0))))))
        (cdr-with-fixture source
          (lambda (f)
            (let ((result (cdr-call f)))
              (cdr-clear f)
              (cdrc-maximum result '(t 0))
              (is (null (cdr-events f)))
              (cdr-noeffects f)))
          :version version)))))

;;; CSR-D01/D03: uno stamp prepared e' TXID; il SEAL contribuisce anche senza ordinari.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-TXM-007
(deftest test-REQ-MVC-005-CLOSED-seal-prepared-only-non-confonde-txid
  (dolist (version '(1 2))
    (dolist (csn '(0 #x100000001 #x8000000000000001 #xffffffffffffffff))
      (let ((source (cdr-log
                     (list (cdr-batch csn (cdr-record :prepared-put #xffffffffffffffff)
                                          (cdr-record :prepared-tombstone #xffffffffffffffff)))
                     :version version)))
        (cdr-with-fixture source
          (lambda (f)
            (let ((result (cdr-call f)))
              (is (equal '(1 2 1 0 0 1)
                         (multiple-value-list (cr:statistiche-closed-recuperato result))))
              (cdrc-maximum result (list t csn))
              (cdr-noeffects f)))
          :version version)))))

;;; CSR-D05: gli esiti EDIT orfani contribuiscono anche su P64, senza creare record.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-TXM-007 REQ-CMP-009
(deftest test-REQ-MVC-005-CLOSED-edit-orfani-writer-compaction-anche-vuoti
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (csn '(0 #x100000001 #x8000000000000001 #xffffffffffffffff))
        (let ((outcomes (list (list 0 csn) (list #xffffffffffffffff 0))))
          (cdr-with-fixture (cdr-log nil :version version :origin origin)
            (lambda (f)
              (let ((result (cdr-call f)) (manifest (c:manifest-control-recuperato (cdr-fixture-control f))))
                (is (equal '(0 0 0 0 0 0)
                           (multiple-value-list (cr:statistiche-closed-recuperato result))))
                (cdr-clear f)
                (fill (cdr-fixture-scratch f) #x5a)
                (dotimes (repeat 2)
                  (cdrc-maximum result (list t csn))
                  (dolist (pair outcomes)
                    (is (equal (list t (second pair))
                               (multiple-value-list
                                (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 (first pair)))))))
                (is (null (cdr-events f)))
                (cdr-noeffects f)))
            :version version :outcomes outcomes))))))

;;; CSR-D01/D03: massimo fra fonti, non ultimo lotto ne' TXID dell'OUTCOME/prepared.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-TXM-007
(deftest test-REQ-MVC-005-CLOSED-writer-massimo-ordinari-outcome-seal-edit
  (dolist (version '(1 2))
    (dolist (facts '((0 0 0 0 0)
                     (#xffffffffffffffff 7 3 1 #xffffffffffffffff)
                     (7 #xffffffffffffffff 3 1 #xffffffffffffffff)
                     (7 3 #xffffffffffffffff 1 #xffffffffffffffff)
                     (7 3 1 #xffffffffffffffff #xffffffffffffffff)
                     (#x100000001 #x8000000000000001 3 1 #x8000000000000001)))
      (destructuring-bind (ordinary outcome seal edit expected) facts
        (let ((source
                (cdr-log
                 (list (cdr-batch ordinary (cdr-record :put ordinary) (cdr-record :tombstone ordinary))
                       (cdr-batch seal (cdr-record :prepared-put #xffffffffffffffff))
                       (cdr-batch 0 (cdr-record :outcome #xfffffffffffffffe :csn outcome)))
                 :version version)))
          (cdr-with-fixture source
            (lambda (f)
              (let ((result (cdr-call f)))
                (is (equal '(3 4 1 0 0 1)
                           (multiple-value-list (cr:statistiche-closed-recuperato result))))
                (cdr-clear f)
                (cdrc-maximum result (list t expected))
                (is (null (cdr-events f)))
                (cdr-noeffects f)))
            :version version :outcomes (list (list #xfffffffffffffffd edit))))))))

;;; CSR-D02/D06: PUT e TOMBSTONE conservano ciascuno tutti i bit, ordine CSN libero.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-CMP-009
(deftest test-REQ-MVC-005-CLOSED-compaction-massimo-put-o-tombstone-u64
  (dolist (version '(1 2))
    (dolist (kind '(:put :tombstone))
      (dolist (csn '(0 #x100000001 #x8000000000000001 #xffffffffffffffff))
        (let ((source (cdr-log nil :version version :origin 2
                               :records (list (cdr-record kind csn) (cdr-record :put 0)
                                              (cdr-record :tombstone 0)))))
          (cdr-with-fixture source
            (lambda (f)
              (let ((result (cdr-call f)))
                (is (equal '(0 3 0 0 0 0)
                           (multiple-value-list (cr:statistiche-closed-recuperato result))))
                (cdrc-maximum result (list t csn))
                (cdr-noeffects f)))
            :version version))))))

;;; CSR-D07: la coda e' integra e contiene CSN maggiori, ma non viene neppure letta.
;;; REQ: REQ-MVC-005 REQ-REC-001 REQ-STO-006
(deftest test-REQ-MVC-005-CLOSED-massimo-esclude-tutto-oltre-p-anche-p64
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (empty-prefix '(nil t))
        (multiple-value-bind (source layouts full-prefix)
            (if (= origin 1)
                (cdr-log (list (cdr-batch 7 (cdr-record :put 7))
                               (cdr-batch #xffffffffffffffff
                                 (cdr-record :outcome #xffffffffffffffff :csn #xffffffffffffffff)))
                         :version version)
                (cdr-log nil :version version :origin 2
                         :records (list (cdr-record :put 7)
                                        (cdr-record :tombstone #xffffffffffffffff))))
          (let ((prefix (if empty-prefix 64 (getf (first layouts) :end))))
            (is (< prefix full-prefix))
            (cdr-with-fixture source
              (lambda (f)
                (setf (cdr-fixture-hook f)
                      (lambda (fixture fd buffer start count offset)
                        (is (= fd 502))
                        (is (<= (+ offset count) prefix))
                        (cdr-transfer fixture fd buffer start count offset)))
                (let ((result (cdr-call f :chunk-bytes 31)))
                  (is (equal (if empty-prefix '(0 0 0 0 0 0)
                                 (if (= origin 1) '(1 1 0 0 0 0) '(0 1 0 0 0 0)))
                             (multiple-value-list (cr:statistiche-closed-recuperato result))))
                  (is (= prefix (second (multiple-value-list (cr:frontiere-closed-recuperato result)))))
                  (cdr-clear f)
                  (fill (cdr-fixture-scratch f) #x5a)
                  (dotimes (repeat 2) (cdrc-maximum result (if empty-prefix '(nil 0) '(t 7))))
                  (is (null (cdr-events f)))
                  (cdr-noeffects f)))
              :version version :prefix prefix)))))))

;;; CSR-D02/D08: insieme veramente vuoto, CLOSED P64, poi zero proveniente da ACTIVE.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-STO-006
(deftest test-REQ-MVC-005-SERIE-insieme-vuoto-e-zero-presente
  (dolist (version '(1 2))
    (dolist (has-closed '(nil t))
      (dolist (has-zero '(nil t))
        (cdr-with-fixture (cdr-log nil :version version)
          (lambda (f)
            (let* ((closed (if has-closed (vector (cdr-call f)) #()))
                   (active (cdrc-active f (when has-zero (list (cdr-batch 0 (cdr-record :put 0)))) version)))
              (cdrc-serie f active closed (if has-zero '(t 0) '(nil 0))
                          :max-segmenti (if has-closed 1 0))))
          :version version :closed (when has-closed '((2 64 nil))))))))

;;; Ogni fonte puo detenere il massimo: ACTIVE9, CLOSED2 writer, CLOSED7 compaction.
;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-STO-006 REQ-CMP-009
(deftest test-REQ-MVC-005-SERIE-massimo-completo-fonti-miste-ordine-libero
  (dolist (version '(1 2))
    (dolist (facts '((0 0 0 0)
                     (#xffffffffffffffff 1 2 #xffffffffffffffff)
                     (1 #xffffffffffffffff 2 #xffffffffffffffff)
                     (1 2 #xffffffffffffffff #xffffffffffffffff)
                     (#x100000001 3 #x8000000000000001 #x8000000000000001)))
      (destructuring-bind (active-csn edit-csn compact-csn expected) facts
        (let* ((writer (cdr-log (list (cdr-batch 0 (cdr-record :prepared-put #xffffffffffffffff)))
                                :version version))
               (compact (cdr-log nil :version version :id 7 :origin 2
                                 :records (list (cdr-record :tombstone compact-csn))))
               (closed (list (list 2 (length writer) (list (list #xffffffffffffffff edit-csn)))
                             (list 7 (length compact) nil))))
          (cdr-with-fixture writer
            (lambda (f)
              (let* ((a (cdr-call f)) (b (cdrs-extra f compact 7))
                     (active (cdrc-active f
                               (list (cdr-batch active-csn (cdr-record :prepared-tombstone #xffffffffffffffff)))
                               version)))
                (cdrc-serie f active (vector a b) (list t expected) :max-segmenti 2)
                (cdrc-serie f active (vector b a) (list t expected) :max-segmenti 2)))
            :version version :closed closed))))))

;;; CSR-D08: l'aggregatore deve propagare il gate, senza restituire massimi parziali.
;;; REQ: REQ-MVC-005 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-MVC-005-SERIE-rifiuta-mancanti-extra-duplicati-altro-control-budget
  (dolist (version '(1 2))
    (cdr-with-fixture (cdr-log nil :version version)
      (lambda (f)
        (let* ((a (cdr-call f)) (b (cdrs-extra f (cdr-log nil :version version :id 7) 7))
               (active (cdrc-active f nil version))
               (other (cdrs-altro-control f))
               (foreign (cr:leggi-closed-recuperato other (cdr-fixture-input f) 2 (ct::crr-bytes 64))))
          (cdr-clear f)
          (dolist (bad (list #() (vector a) (vector a b a)))
            (cdr-expect 'invalid-argument :closed-recovery-set-count
                        (lambda () (cr:massimo-csn-serie-recuperata active bad))))
          (dolist (bad (list (vector a a) (vector b b)))
            (cdr-expect 'invalid-argument :closed-recovery-set-duplicate
                        (lambda () (cr:massimo-csn-serie-recuperata active bad))))
          (cdr-expect 'invalid-argument :closed-recovery-set-control
                      (lambda () (cr:massimo-csn-serie-recuperata active (vector foreign b))))
          (dolist (budget '(0 1))
            (cdr-expect 'resource-exhausted :closed-recovery-set-budget
                        (lambda () (cr:massimo-csn-serie-recuperata active (vector a b) :max-segmenti budget))))
          (cdr-expect 'resource-exhausted :closed-recovery-set-budget
                      (lambda () (cr:massimo-csn-serie-recuperata active (vector a a a) :max-segmenti 2)))
          (is (null (cdr-events f)))
          (cdrc-serie f active (vector b a) '(nil 0) :max-segmenti 2)))
      :version version :closed '((2 64 nil) (7 64 nil)))))

;;; Le query scalari descrivono la lettura conclusa; la Serie richiede FD ancora aperti.
;;; REQ: REQ-MVC-005 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-MVC-005-SERIE-rifiuta-active-closed-control-chiusi
  (dolist (version '(1 2))
    (dolist (target '(:active :closed :control))
      (cdr-with-fixture (cdr-log nil :version version)
        (lambda (f)
          (let ((closed (cdr-call f)))
            (multiple-value-bind (active active-input) (cdrc-active f nil version)
              (cdr-noeffects f)
              (io:chiudi (ecase target
                           (:active active-input)
                           (:closed (cdr-fixture-input f))
                           (:control (cdr-fixture-control-input f))))
              (cdr-clear f)
              (cdrc-maximum closed '(nil 0))
              (cdr-expect 'io-fault :io-unavailable
                          (lambda () (cr:massimo-csn-serie-recuperata active (vector closed))))
              (cdrs-immagini-invariate f))))
        :version version))))
