;;;; FI dichiarate delle guardie runtime; non sono recovery canonici positivi.
;;; OWNER: runner seriale, fixture privata; nessun worker vivo durante le alterazioni.
;;; SHARED: solo slot Archivio alterato temporaneamente e ripristinato con UNWIND-PROTECT.
;;; Limiti: <=4 valori estranei, <=4 piani per matrice; registri candidati di capacita 1.
;;; Nessuna FDEFINITION/primitiva CL sostituita; nessun campo readonly valido modificato.
;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-CMP-007 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun rbg-slot-corruption (archive)
  "FI seriale: conserva e ripristina lo stesso binding, anche su uscita non locale."
  (let ((original (arcdocdb.runtime:trova-runtime-archivio archive)))
    (dolist (foreign (list :foreign 17 #() (cons :foreign nil)))
      (unwind-protect
           (progn
             (setf (arcdocdb.recovery.archive::archivio-recovery-runtime archive) foreign)
             (arcdocdb.recovery.archive.csn.tests::acr-expect
              'arcdocdb.conditions:invariant-violation :archive-runtime-binding
              (lambda () (arcdocdb.runtime:trova-runtime-archivio archive))))
        (setf (arcdocdb.recovery.archive::archivio-recovery-runtime archive) original))
      (is (eq original (arcdocdb.runtime:trova-runtime-archivio archive))))))

(defun rbg-reject-plan (fixture series segments present maximum)
  "FI nel costruttore privato: conteggi/normalizzazione incoerenti senza binding."
  (let* ((archive (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))
         (plan (arcdocdb.recovery.archive.csn::%make-piano-csn-archivio
                archive series segments present maximum)))
    (is (null (arcdocdb.runtime:trova-runtime-archivio archive)))
    (arcdocdb.recovery.archive.csn.tests::acr-expect
     'arcdocdb.conditions:invariant-violation :archive-runtime-plan
     (lambda ()
       (arcdocdb.runtime:crea-runtime-archivio
        plan 20 5 :csn-capacity 1 :snapshot-capacity 1
        :worker-capacity 1 :retirement-capacity 1)))
    (is (null (arcdocdb.runtime:trova-runtime-archivio archive)))
    (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))

(defun rbg-candidate (high low &optional snapshot-csns)
  "Capsula mai pubblicata; SNAPSHOT-CSNS diverso forza soltanto il legame per EQ."
  (let* ((csns (arcdocdb.csn:crea-registro-csn
                :capacity 1 :initial-high high :initial-low low))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot (or snapshot-csns csns) 1 20 5))
         (epochs (arcdocdb.epochs:crea-registro-epoche 1 1)))
    (values (arcdocdb.runtime::%make-runtime-archivio
             csns (arcdocdb.get:crea-ambito-get epochs snapshots)) csns)))

(defun rbg-expect-initial (runtime high low old-scope reason)
  "Invoca la guardia pre-CAS su un candidato privato; nessun binding viene tentato."
  (arcdocdb.recovery.archive.csn.tests::acr-expect
   'arcdocdb.conditions:invariant-violation reason
   (lambda () (arcdocdb.runtime::verifica-runtime-iniziale runtime high low old-scope))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-slot-estraneo-ripristinato
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (let* ((archive (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))
            (plan (arcdocdb.recovery.archive.csn.tests::acr-plan fixture)))
       (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
       (is (null (arcdocdb.runtime:trova-runtime-archivio archive)))
       (rbg-slot-corruption archive)
       (let ((runtime (arcdocdb.runtime:crea-runtime-archivio
                       plan 20 5 :csn-capacity 1 :snapshot-capacity 1
                       :worker-capacity 1 :retirement-capacity 1)))
         (rbg-slot-corruption archive)
         (is (eq runtime (arcdocdb.runtime:trova-runtime-archivio archive))))
       (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-piano-conteggi-incoerenti
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
     (dolist (counts '((0 0) (0 1) (1 0) (2 1)))
       (rbg-reject-plan fixture (first counts) (second counts) nil 0))
     (is (null (arcdocdb.runtime::verifica-piano-runtime
                (arcdocdb.recovery.archive.csn.tests::acr-plan fixture))))
     (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture))))

;;; REQ: REQ-MVC-006 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-piano-assenza-richiede-zero
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
     (dolist (maximum '(1 #x100000000 #xffffffffffffffff))
       (rbg-reject-plan fixture 1 1 nil maximum))
     (is (null (arcdocdb.runtime::verifica-piano-runtime
                (arcdocdb.recovery.archive.csn.tests::acr-plan fixture))))
     (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-snapshot-altro-csn-base-identica
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (let* ((old-scope (arcdocdb.recovery.archive.csn.tests::acr-fixture-scope fixture))
            (other (arcdocdb.csn:crea-registro-csn :capacity 1 :initial-high 3 :initial-low 7)))
       (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
       (multiple-value-bind (runtime csns) (rbg-candidate 3 7 other)
         (is (not (eq csns other)))
         (is (equal (multiple-value-list (arcdocdb.csn:leggi-frontiere-csn other))
                    (multiple-value-list (arcdocdb.csn:leggi-frontiere-csn csns))))
         (is (not (eq old-scope (arcdocdb.runtime:ambito-runtime-archivio runtime))))
         (rbg-expect-initial runtime 3 7 old-scope :archive-runtime-link))
       (is (null (arcdocdb.runtime::verifica-runtime-iniziale
                  (rbg-candidate 3 7) 3 7 old-scope)))
       (is (null (arcdocdb.runtime:trova-runtime-archivio
                  (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))))
       (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))))

;;; REQ: REQ-MVC-006 REQ-CMP-007 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-vecchio-ambito-con-link-csn-corretto
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (let* ((old-scope (arcdocdb.recovery.archive.csn.tests::acr-fixture-scope fixture))
            (snapshots (arcdocdb.get::ambito-get-snapshots old-scope))
            (csns (arcdocdb.mvcc::registro-snapshot-csns snapshots))
            (runtime (arcdocdb.runtime::%make-runtime-archivio csns old-scope)))
       (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
       (is (eq csns (arcdocdb.mvcc::registro-snapshot-csns
                     (arcdocdb.runtime:snapshot-runtime-archivio runtime))))
       (multiple-value-bind (lh ll hh hl) (arcdocdb.csn:leggi-frontiere-csn csns)
         (is (= lh hh)) (is (= ll hl))
         (rbg-expect-initial runtime lh ll old-scope :archive-runtime-link))
       (is (null (arcdocdb.runtime:trova-runtime-archivio
                  (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))))
       (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-base-high-low-indipendenti
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (let* ((old-scope (arcdocdb.recovery.archive.csn.tests::acr-fixture-scope fixture))
            (runtime (rbg-candidate #x80000000 #xfffffffe)))
       (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
       (is (null (arcdocdb.runtime::verifica-runtime-iniziale
                  runtime #x80000000 #xfffffffe old-scope)))
       (rbg-expect-initial runtime #x80000001 #xfffffffe old-scope :archive-runtime-base)
       (rbg-expect-initial runtime #x80000000 #xffffffff old-scope :archive-runtime-base)
       (is (null (arcdocdb.runtime::verifica-runtime-iniziale
                  runtime #x80000000 #xfffffffe old-scope)))
       (is (null (arcdocdb.runtime:trova-runtime-archivio
                  (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))))
       (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-009
(deftest test-REQ-AFF-009-RUNTIME-GUARDS-ultimo-corretto-orizzonte-diverso
  ;; FI di stato iniziale: un CSN preso solo nel candidato privato, mai pubblicato.
  ;; Il token viene risolto anche se l'oracolo fallisce; nessuno slot Archivio e mutato.
  (arcdocdb.recovery.archive.csn.tests::acr-with-fixture
   (lambda (fixture)
     (let ((old-scope (arcdocdb.recovery.archive.csn.tests::acr-fixture-scope fixture)))
       (arcdocdb.recovery.archive.csn.tests::acr-clear fixture)
       (dolist (low '(9 #xffffffff))
         (multiple-value-bind (runtime csns) (rbg-candidate 7 low)
           (multiple-value-bind (slot high next-low) (arcdocdb.csn:prendi-csn csns)
             (unwind-protect
                  (rbg-expect-initial runtime high next-low old-scope :archive-runtime-base)
               (arcdocdb.csn:risolvi-csn csns slot high next-low))
             (is (null (arcdocdb.runtime::verifica-runtime-iniziale
                        runtime high next-low old-scope))))))
       (is (null (arcdocdb.runtime:trova-runtime-archivio
                  (arcdocdb.recovery.archive.csn.tests::acr-fixture-archive fixture))))
       (arcdocdb.recovery.archive.csn.tests::acr-noeffects fixture)))))
