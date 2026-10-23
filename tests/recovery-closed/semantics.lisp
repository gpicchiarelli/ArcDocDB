;;;; Semantica CLOSED writer/compaction e insieme completo del CONTROL.
;;; OWNER: runner seriale; ogni fixture possiede sorgenti, scratch e capacita readonly.
;;; SHARED: nessuna sostituzione globale o mutazione di oggetti del prodotto.
;;; Oracoli dichiarativi; file <=4096 byte, eventi limitati dal supporto comune.
;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-006 REQ-CMP-009 REQ-AFF-008
(in-package #:arcdocdb.recovery.closed.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun cdrs-check (result id prefix version origin expected)
  "Frontiere e partizione attese dai fatti della fixture, usando sole query pubbliche."
  (is (typep result 'cr:closed-recuperato))
  (is (equal (list id prefix version origin)
             (multiple-value-list (cr:frontiere-closed-recuperato result))))
  (is (equal expected (multiple-value-list (cr:statistiche-closed-recuperato result))))
  (destructuring-bind (batches records prepared local edit aborted) expected
    (is (<= batches (+ records 1)))
    (is (= prepared (+ local edit aborted)))))

(defun cdrs-success (f origin expected &rest options)
  "Un risultato completo e nessun effetto sui file; non assume P uguale all'EOF."
  (let ((result (apply #'cdr-call f options)))
    (cdrs-check result (cdr-fixture-id f) (cdr-fixture-prefix f)
                (cdr-fixture-version f) origin expected)
    (cdr-noeffects f)
    result))

(defun cdrs-extra (f bytes id &optional (control (cdr-fixture-control f)))
  "Nuova capacita readonly sul medesimo backend; risultato sempre dal lettore pubblico."
  (let ((input (cdr-add-input f bytes)) (scratch (ct::crr-bytes (length bytes) #xa5)))
    (values (cr:leggi-closed-recuperato control input id scratch :max-bytes 4096)
            input scratch)))

(defun cdrs-altro-control (f)
  "Stessi byte e vista, nuovo oggetto CONTROL realmente decodificato su un FD distinto."
  (let* ((bytes (cdr-fixture-control-source f)) (input (cdr-add-input f bytes)))
    (c:leggi-control-recuperato (cdr-fixture-view f) input (length bytes)
                              (ct::crr-bytes (length bytes)))))

(defun cdrs-immagini-invariate (f)
  "Oracolo dopo una chiusura intenzionale del caller: nessuna nuova operazione I/O."
  (loop for fd being the hash-keys of (cdr-fixture-images f) using (hash-value bytes)
        do (is (equalp bytes (gethash fd (cdr-fixture-references f)))))
  (is (null (cdr-events f))))

;;; CDR-D06: ciascuna presenza indipendente, entrambe presenti con CSN uguale.
;;; REQ: REQ-REC-001 REQ-TXM-007
(deftest test-REQ-TXM-007-CLOSED-writer-outcome-edit-tutte-le-presenze
  (dolist (version '(1 2))
    (dolist (txid '(0 #x8000000000000001 #xffffffffffffffff))
      (dolist (csn '(0 #x100000001 #xffffffffffffffff))
        (dolist (local '(nil t))
          (dolist (edit '(nil t))
            (let* ((batches (list (cdr-batch 11
                                    (cdr-record :prepared-put txid)
                                    (cdr-record :prepared-tombstone txid))))
                   (outcomes (when edit (list (list txid csn)))))
              (when local
                (setf batches (append batches
                                      (list (cdr-batch 17 (cdr-record :outcome txid :csn csn))))))
              (cdr-with-fixture (cdr-log batches :version version)
                (lambda (f)
                  (cdrs-success f 1 (list (if local 2 1) (if local 3 2) 1
                                          (if local 1 0) (if (and edit (not local)) 1 0)
                                          (if (or local edit) 0 1))))
                :version version :outcomes outcomes))))))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-writer-outcome-edit-conflitti-zero-bit-alti
  (dolist (version '(1 2))
    (dolist (pair '((0 1) (1 0) (1 #x100000001)
                    (#x7fffffffffffffff #xffffffffffffffff)
                    (#xffffffffffffffff 0)))
      (dolist (txid '(0 #xffffffffffffffff))
        (let ((source (cdr-log
                       (list (cdr-batch 3 (cdr-record :prepared-put txid))
                             (cdr-batch 5 (cdr-record :outcome txid :csn (first pair))))
                       :version version)))
          (cdr-with-fixture source
            (lambda (f)
              (let ((condition (cdr-expect 'corruption-detected :closed-recovery-outcome-conflict
                                           (lambda () (cdr-call f)))))
                (is (null (error-offset condition))))
              (cdr-noeffects f))
            :version version :outcomes (list (list txid (second pair)))))))))

;;; CDR-D05: record ordinari senza SEAL; EDIT orfani non modificano gli stamp.
;;; REQ: REQ-REC-001 REQ-CMP-009 REQ-FOR-003
(deftest test-REQ-CMP-009-CLOSED-compaction-put-tombstone-senza-seal
  (dolist (version '(1 2))
    (let ((source (cdr-log nil :version version :origin 2
                           :records (list (cdr-record :put 0)
                                          (cdr-record :tombstone #x8000000000000001)
                                          (cdr-record :put #xffffffffffffffff)))))
      (cdr-with-fixture source
        (lambda (f) (cdrs-success f 2 '(0 3 0 0 0 0)))
        :version version :outcomes '((77 0) (88 #xffffffffffffffff))))))

;;; REQ: REQ-REC-001 REQ-STO-006
(deftest test-REQ-STO-006-CLOSED-insieme-vuoto-solo-manifest-vuoto
  (dolist (version '(1 2))
    (let ((source (cdr-log nil :version version)))
      (cdr-with-fixture source
        (lambda (f)
          (is (null (cr:verifica-closed-completi (cdr-fixture-control f) #() :max-segmenti 0)))
          (is (null (cdr-events f)))
          (cdr-noeffects f))
        :version version :closed nil)
      (cdr-with-fixture source
        (lambda (f)
          (cdr-expect 'invalid-argument :closed-recovery-set-count
                      (lambda () (cr:verifica-closed-completi (cdr-fixture-control f) #())))
          (is (null (cdr-events f)))
          (cdr-noeffects f))
        :version version))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-outcome-duplicati-identici-una-classificazione
  (dolist (version '(1 2))
    (dolist (csn '(0 #x8000000000000001 #xffffffffffffffff))
      (dolist (edit '(nil t))
        (dolist (separati '(nil t))
          (let* ((p (cdr-record :prepared-put #xffffffffffffffff))
                 (o (cdr-record :outcome #xffffffffffffffff :csn csn))
                 (batches (if separati
                              (list (cdr-batch 1 p) (cdr-batch 2 o) (cdr-batch 3 o))
                              (list (cdr-batch 1 p o o)))))
            (cdr-with-fixture (cdr-log batches :version version)
              (lambda (f)
                (cdrs-success f 1 (list (if separati 3 1) 3 1 1 0 0)
                              :max-outcomes 2 :max-prepared 1)
                (cdr-clear f)
                (cdr-expect 'resource-exhausted :active-recovery-outcome-budget
                            (lambda () (cdr-call f :max-outcomes 1)))
                (cdr-noeffects f))
              :version version :outcomes (when edit (list (list #xffffffffffffffff csn))))))))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-outcome-duplicati-discordi-anche-orfani
  (dolist (version '(1 2))
    (dolist (pair '((0 1) (1 0) (1 #x100000001) (#xffffffffffffffff 0)))
      (dolist (orfano '(nil t))
        (let ((batches (list
                        (apply #'cdr-batch 3
                               (append (unless orfano (list (cdr-record :prepared-put 0)))
                                       (list (cdr-record :outcome 0 :csn (first pair)))))
                        (cdr-batch 5 (cdr-record :outcome 0 :csn (second pair))))))
          (multiple-value-bind (source layouts) (cdr-log batches :version version)
            (cdr-with-fixture source
              (lambda (f)
                (cdr-expect 'corruption-detected :active-recovery-outcome-conflict
                            (lambda () (cdr-call f)) (first (getf (second layouts) :records)))
                (cdr-noeffects f))
              :version version)))))))

;;; CDR-G03: il TXID non puo attraversare lotti o ricomparire dopo OUTCOME.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-ordine-prepared-outcome-e-confine-lotti
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (kind '(:prepared-put :prepared-tombstone))
        (let ((p (cdr-record kind txid)) (o (cdr-record :outcome txid :csn 0)))
          (dolist (spec (list
                         (list :active-recovery-prepared-batches
                               (list (cdr-batch 1 p) (cdr-batch 2) (cdr-batch 3 p)))
                         (list :active-recovery-outcome-before-prepare (list (cdr-batch 1 o p)))
                         (list :active-recovery-outcome-before-prepare (list (cdr-batch 1 p o p)))
                         (list :active-recovery-outcome-before-prepare
                               (list (cdr-batch 1 o) (cdr-batch 2 p)))
                         (list :active-recovery-outcome-before-prepare
                               (list (cdr-batch 1 p o) (cdr-batch 2 p)))))
            (multiple-value-bind (source layouts) (cdr-log (second spec) :version version)
              (let ((offset (car (last (getf (car (last layouts)) :records)))))
                (cdr-with-fixture source
                  (lambda (f)
                    (cdr-expect 'corruption-detected (first spec) (lambda () (cdr-call f)) offset)
                    (cdr-noeffects f))
                  :version version :outcomes (list (list txid 0)))))))))))

;;; Conteggi fisici e TXID distinti: cinque prepared, due locali, due EDIT, un abort.
;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-conteggi-misti-e-metadati-orfani
  (dolist (version '(1 2))
    (let ((source
            (cdr-log
             (list (cdr-batch 7 (cdr-record :put 7) (cdr-record :tombstone 7)
                               (cdr-record :prepared-put 0) (cdr-record :prepared-tombstone 0)
                               (cdr-record :prepared-put 1) (cdr-record :prepared-tombstone 2)
                               (cdr-record :prepared-put 3) (cdr-record :prepared-tombstone 4))
                   (cdr-batch 11 (cdr-record :outcome 0 :csn 0)
                                (cdr-record :outcome 1 :csn #x8000000000000001)
                                (cdr-record :outcome 99 :csn #xffffffffffffffff)))
             :version version)))
      (cdr-with-fixture source
        (lambda (f)
          (cdrs-success f 1 '(2 11 5 2 2 1) :max-records 11 :max-prepared 5
                        :max-outcomes 3 :max-esiti-chiusura 4)
          (cdr-clear f)
          (cdr-expect 'resource-exhausted :active-recovery-prepared-budget
                      (lambda () (cdr-call f :max-prepared 4)))
          (cdr-noeffects f))
        :version version :outcomes '((0 0) (2 #x100000001) (3 0) (88 #xffffffffffffffff))))))

;;; CDR-D05/CSR-D06: entrambe le specie prepared e ogni tipo non ordinario rifiutati.
;;; REQ: REQ-CMP-009 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-CMP-009-CLOSED-compaction-rifiuta-prepared-outcome-seal
  (dolist (version '(1 2))
    (dolist (kind '(:prepared-put :prepared-tombstone :outcome))
      (cdr-with-fixture
          (cdr-log nil :version version :origin 2 :records (list (cdr-record kind 0 :csn 0)))
        (lambda (f)
          (cdr-expect 'corruption-detected
                      (if (eq kind :outcome) :compaction-record-kind :compaction-prepared)
                      (lambda () (cdr-call f)) 64)
          (cdr-noeffects f))
        :version version))
    (let ((source (cdr-log (list (cdr-batch 0)) :version version)))
      ;; Si cambia solo l'header della fixture, mantenendo un SEAL integro nel corpo.
      (replace source (cdr-log nil :version version :origin 2) :end1 64)
      (cdr-with-fixture source
        (lambda (f)
          (cdr-expect 'corruption-detected :compaction-record-kind (lambda () (cdr-call f)) 64)
          (cdr-noeffects f))
        :version version))))

;;; CDR-G04: ID zero, bit63 e massimo u64 da CONTROL pubblico, ordine libero.
;;; REQ: REQ-REC-001 REQ-STO-006 REQ-FOR-001
(deftest test-REQ-STO-006-CLOSED-insieme-completo-id-u64-ordine-libero
  (dolist (version '(1 2))
    (let* ((ids '(2 0 #x8000000000000001 #xffffffffffffffff))
           (closed (mapcar (lambda (id) (list id 64 nil)) ids)))
      (cdr-with-fixture (cdr-log nil :version version)
        (lambda (f)
          (let ((results (cons (cdrs-success f 1 '(0 0 0 0 0 0))
                               (loop for id in (rest ids)
                                     collect (cdrs-extra f (cdr-log nil :version version :id id) id)))))
            (loop for result in results for id in ids
                  do (cdrs-check result id 64 version 1 '(0 0 0 0 0 0))
                     (is (equal '(nil 0) (multiple-value-list (cr:massimo-csn-closed-recuperato result)))))
            (cdr-clear f)
            (dolist (order (list results (reverse results) (append (rest results) (list (first results)))))
              (is (null (cr:verifica-closed-completi (cdr-fixture-control f) (coerce order 'simple-vector)
                                                  :max-segmenti 4))))
            (is (null (cdr-events f)))
            (cdr-noeffects f)))
        :version version :closed closed))))

;;; REQ: REQ-STO-006 REQ-AFF-008
(deftest test-REQ-STO-006-CLOSED-insieme-mancante-extra-duplicato
  (dolist (version '(1 2))
    (cdr-with-fixture (cdr-log nil :version version)
      (lambda (f)
        (let* ((a (cdr-call f))
               (b (cdrs-extra f (cdr-log nil :version version :id 7) 7))
               (control (cdr-fixture-control f)))
          (cdr-clear f)
          (dolist (bad (list #() (vector a) (vector b) (vector a b a)))
            (cdr-expect 'invalid-argument :closed-recovery-set-count
                        (lambda () (cr:verifica-closed-completi control bad))))
          (dolist (bad (list (vector a a) (vector b b)))
            (cdr-expect 'invalid-argument :closed-recovery-set-duplicate
                        (lambda () (cr:verifica-closed-completi control bad))))
          (is (null (cr:verifica-closed-completi control (vector b a))))
          (is (null (cdr-events f)))
          (cdr-noeffects f)))
      :version version :closed '((2 64 nil) (7 64 nil)))))

;;; Stessa identita logica e stessi byte non sostituiscono l'autorita EQ del token.
;;; REQ: REQ-STO-006 REQ-AFF-008
(deftest test-REQ-STO-006-CLOSED-insieme-altro-control-reale
  (dolist (version '(1 2))
    (cdr-with-fixture (cdr-log nil :version version)
      (lambda (f)
        (let* ((original (cdr-call f)) (other (cdrs-altro-control f))
               (foreign (cr:leggi-closed-recuperato other (cdr-fixture-input f) 2
                                                   (ct::crr-bytes 64))))
          (is (not (eq other (cdr-fixture-control f))))
          (cdr-clear f)
          (cdr-expect 'invalid-argument :closed-recovery-set-control
                      (lambda () (cr:verifica-closed-completi (cdr-fixture-control f) (vector foreign))))
          (cdr-expect 'invalid-argument :closed-recovery-set-control
                      (lambda () (cr:verifica-closed-completi other (vector original))))
          (is (null (cr:verifica-closed-completi other (vector foreign))))
          (is (null (cdr-events f)))
          (cdr-noeffects f)))
      :version version)))

;;; Le chiusure qui sono azioni intenzionali del caller, mai FI nei risultati del prodotto.
;;; REQ: REQ-STO-006 REQ-AFF-008
(deftest test-REQ-STO-006-CLOSED-insieme-fd-closed-o-control-chiuso
  (dolist (version '(1 2))
    (dolist (target '(:segmento :control))
      (cdr-with-fixture (cdr-log nil :version version)
        (lambda (f)
          (let ((result (cdr-call f)))
            (cdr-noeffects f)
            (io:chiudi (if (eq target :segmento) (cdr-fixture-input f) (cdr-fixture-control-input f)))
            (cdr-clear f)
            (cdr-expect 'io-fault :io-unavailable
                        (lambda () (cr:verifica-closed-completi (cdr-fixture-control f) (vector result))))
            (cdrs-immagini-invariate f)))
        :version version))))

;;; Il budget precede cardinalita e tabella seen; il limite esatto deve riuscire.
;;; REQ: REQ-STO-006 REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-insieme-budget-esatto-e-prima-del-count
  (dolist (version '(1 2))
    (cdr-with-fixture (cdr-log nil :version version)
      (lambda (f)
        (let* ((result (cdr-call f)) (control (cdr-fixture-control f)))
          (cdr-clear f)
          (is (null (cr:verifica-closed-completi control (vector result) :max-segmenti 1)))
          (cdr-expect 'resource-exhausted :closed-recovery-set-budget
                      (lambda () (cr:verifica-closed-completi control (vector result) :max-segmenti 0)))
          (cdr-expect 'resource-exhausted :closed-recovery-set-budget
                      (lambda () (cr:verifica-closed-completi control (vector result result) :max-segmenti 1)))
          (is (null (cdr-events f)))
          (cdr-noeffects f)))
      :version version)))

;;; CSR-D04: OUTCOME e EDIT omonimi devono concordare anche senza prepared locale.
;;; REQ: REQ-TXM-007 REQ-MVC-005 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-TXM-007-CLOSED-outcome-orfano-edit-omonimo-accordo-e-conflitto
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (facts '((0 0 t)
                       (#x100000001 #x100000001 t)
                       (#x8000000000000001 #x8000000000000001 t)
                       (#xffffffffffffffff #xffffffffffffffff t)
                       (0 1 nil) (1 0 nil)
                       (1 #x100000001 nil) (#x100000001 1 nil)
                       (#x7fffffffffffffff #xffffffffffffffff nil)
                       (#xffffffffffffffff #x7fffffffffffffff nil)
                       (0 #xffffffffffffffff nil) (#xffffffffffffffff 0 nil)))
        (destructuring-bind (local-csn edit-csn agrees) facts
          (cdr-with-fixture
              (cdr-log (list (cdr-batch 0 (cdr-record :outcome txid :csn local-csn))) :version version)
            (lambda (f)
              (if agrees
                  (let ((result (cdr-call f)))
                    (cdr-clear f)
                    (is (equal '(1 1 0 0 0 0)
                               (multiple-value-list (cr:statistiche-closed-recuperato result))))
                    (is (equal (list t local-csn)
                               (multiple-value-list (cr:massimo-csn-closed-recuperato result))))
                    (is (null (cdr-events f))))
                  (let ((condition (cdr-expect 'corruption-detected :closed-recovery-outcome-conflict
                                               (lambda () (cdr-call f)))))
                    (is (null (error-offset condition)))))
              (cdr-noeffects f))
            :version version :outcomes (list (list txid edit-csn))))))))
