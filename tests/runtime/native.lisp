;;;; Nuova factory runtime da recovery nativo v1/v2: nessun allocatore ponte del test.
;;; OWNER: acn-run/rp-run possiede root 0700, FD e cleanup; callback seriali senza worker.
;;; SHARED: nessuna FI globale; vecchio ambito recovery osservato senza mutazioni.
;;; Limiti: <=4 Serie, <=32 FD, <=4096 byte/file, deadline nativa comune di 30 s.
;;; Finestre zero I/O separate dagli oracoli POSIX e dalle letture di confronto dei byte.
;;; Nessuna attestazione di ramo CAS perdente, power loss, prestazioni o traffico ammesso.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-007 REQ-CMP-007 REQ-AFF-008
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun runtime-REQ-MVC-006-native-old-image (fixture)
  "Identita e stato pubblicamente osservabile dei registri del solo ambito recovery."
  (let* ((scope (a::acn-fixture-scope fixture))
         (snapshots (g::ambito-get-snapshots scope)) (epochs (g::ambito-get-epochs scope))
         (csns (arcdocdb.mvcc::registro-snapshot-csns snapshots)))
    (list scope snapshots epochs csns
          (multiple-value-list (csn:leggi-frontiere-csn csns))
          (multiple-value-list (mvcc:leggi-registro-snapshot snapshots))
          (multiple-value-list (ebr:leggi-registro-epoche epochs)))))

(defun runtime-REQ-MVC-006-native-check-links (fixture runtime maximum)
  "Nuova famiglia coerente e distinta dal vecchio scope; base esatta M prima di assegnare."
  (let* ((scope (r:ambito-runtime-archivio runtime))
         (snapshots (r:snapshot-runtime-archivio runtime))
         (epochs (r:epoche-runtime-archivio runtime)) (csns (r:csn-runtime-archivio runtime))
         (old-scope (a::acn-fixture-scope fixture))
         (old-snapshots (g::ambito-get-snapshots old-scope))
         (words (list (ldb (byte 32 32) maximum) (ldb (byte 32 0) maximum))))
    (is (typep runtime 'r:runtime-archivio))
    (is (eq runtime (r:trova-runtime-archivio (a::acn-fixture-archive fixture))))
    (is (not (eq scope old-scope)))
    (is (not (eq snapshots old-snapshots)))
    (is (not (eq epochs (g::ambito-get-epochs old-scope))))
    (is (not (eq csns (arcdocdb.mvcc::registro-snapshot-csns old-snapshots))))
    ;; Accessori privati soltanto per l'identita dei legami; base da query CSN pubblica.
    (is (eq snapshots (g::ambito-get-snapshots scope)))
    (is (eq epochs (g::ambito-get-epochs scope)))
    (is (eq csns (arcdocdb.mvcc::registro-snapshot-csns snapshots)))
    (is (equal (append words words) (multiple-value-list (csn:leggi-frontiere-csn csns))))
    runtime))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-MVC-008 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-MVC-006-runtime-native-complete-plan-factory-first-M-plus-one
  (dolist (version '(1 2))
    (let ((maximum #x12345678ffffffff))
      (a::acn-run version (a::acn-rich-series version) 1
        (list (a::acn-decision 1501 maximum))
        (lambda (fixture)
          (let* ((old (runtime-REQ-MVC-006-native-old-image fixture))
                 (plan (a::acn-noio fixture (lambda () (a::acn-plan fixture))))
                 (runtime
                   (a::acn-noio fixture
                     (lambda ()
                       (r:crea-runtime-archivio plan 20 5 :csn-capacity 4 :snapshot-capacity 3
                                                :worker-capacity 3 :retirement-capacity 3)))))
            (a::acn-check-plan plan t maximum 3 6)
            (a::acn-noio fixture
              (lambda ()
                (runtime-REQ-MVC-006-native-check-links fixture runtime maximum)
                ;; Il helper consuma il registro restituito dalla nuova API, senza crearne altri.
                (rbt-first runtime maximum)
                (is (equal old (runtime-REQ-MVC-006-native-old-image fixture)))))))))))

(defun runtime-REQ-MVC-008-native-one-slot-family (runtime maximum)
  "Capacita tutte pari a uno, distinguibili dal vecchio scope ACR (CSN=3, altri=2)."
  (let* ((csns (r:csn-runtime-archivio runtime))
         (snapshots (r:snapshot-runtime-archivio runtime))
         (epochs (r:epoche-runtime-archivio runtime))
         (first (mvcc:crea-contesto-snapshot snapshots))
         (second (mvcc:crea-contesto-snapshot snapshots)) (identity 0))
    (multiple-value-bind (slot high low) (csn:prendi-csn csns)
      (unwind-protect
           (progn
             (is (= (1+ maximum) (+ (* high #x100000000) low)))
             (signals resource-exhausted (csn:prendi-csn csns) :csn-full))
        (csn:risolvi-csn csns slot high low)))
    (unwind-protect
         (multiple-value-bind (generation captured ready) (mvcc:registra-snapshot first 10)
           (setf identity generation)
           (is (plusp identity)) (is ready) (is (= (1+ maximum) captured))
           (signals resource-exhausted (mvcc:registra-snapshot second 10) :snapshot-capacity)
           (runtime-REQ-MVC-007-read-check first identity (ebr:contesto-epoca epochs 0)
                                         11 t (1+ maximum)))
      (when (plusp identity) (mvcc:termina-snapshot first identity)))
    (signals invalid-argument (ebr:contesto-epoca epochs 1) :epoch-worker-range)
    (multiple-value-bind (ticket generation) (ebr:prenota-ritiro epochs (vector :native-first))
      (unwind-protect
           (signals resource-exhausted
             (ebr:prenota-ritiro epochs (vector :native-second)) :retirement-capacity)
        (ebr:annulla-ritiro ticket generation)))
    (is (zerop (nth-value 0 (mvcc:leggi-registro-snapshot snapshots))))
    (is (equal '(1 1 0 0) (multiple-value-list (ebr:leggi-registro-epoche epochs))))))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-MVC-008 REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-MVC-007-runtime-native-configured-capacities-isolated-from-recovery-scope
  (dolist (version '(1 2))
    (a::acn-run version (a::acn-base-series :compaction 17) 1 nil
      (lambda (fixture)
        (let* ((old (runtime-REQ-MVC-006-native-old-image fixture))
               (plan (a::acn-noio fixture (lambda () (a::acn-plan fixture))))
               (runtime
                 (a::acn-noio fixture
                   (lambda ()
                     (r:crea-runtime-archivio plan 20 5 :csn-capacity 1 :snapshot-capacity 1
                                              :worker-capacity 1 :retirement-capacity 1)))))
          (a::acn-noio fixture
            (lambda ()
              (runtime-REQ-MVC-006-native-check-links fixture runtime 17)
              (runtime-REQ-MVC-008-native-one-slot-family runtime 17)
              (is (equal old (runtime-REQ-MVC-006-native-old-image fixture))))))))))

(defun runtime-REQ-REC-001-native-close-sources (fixture)
  "Chiude solo i FD readonly registrati in ACN; namespace e cleanup restano al proprietario."
  (a::acn-check-files fixture)
  (dolist (image (a::acn-fixture-images fixture))
    (let ((input (first image)))
      (a::acn-readonly input)
      (is (null (ct::native-bounded (a::acn-fixture-deadline fixture) :runtime-native-close
                  (lambda () (io:chiudi input)))))
      (is (eq :closed (io:stato-file input))))))

(defun runtime-REQ-MVC-006-native-closed-sources (fixture bind-before-close)
  "Piano completato a FD vivi; binding prima/dopo la chiusura senza riprendere le fonti."
  (let* ((old (runtime-REQ-MVC-006-native-old-image fixture))
         (plan (a::acn-noio fixture (lambda () (a::acn-plan fixture))))
         (runtime nil) (identities nil))
    (when bind-before-close
      (setf runtime (a::acn-noio fixture (lambda () (r:crea-runtime-archivio plan 20 5)))
            identities (runtime-REQ-MVC-006-identities runtime)))
    (runtime-REQ-REC-001-native-close-sources fixture)
    (a::acn-noio fixture
      (lambda ()
        (unless bind-before-close
          (is (null (r:trova-runtime-archivio (a::acn-fixture-archive fixture))))
          (setf runtime (r:crea-runtime-archivio plan 20 5)
                identities (runtime-REQ-MVC-006-identities runtime)))
        (runtime-REQ-MVC-006-native-check-links fixture runtime 23)
        (is (equal identities (runtime-REQ-MVC-006-identities runtime)))
        (rbt-first runtime 23)
        (is (eq runtime (r:trova-runtime-archivio (a::acn-fixture-archive fixture))))
        (is (equal identities (runtime-REQ-MVC-006-identities runtime)))
        (is (equal old (runtime-REQ-MVC-006-native-old-image fixture)))
        (dolist (image (a::acn-fixture-images fixture))
          (is (eq :closed (io:stato-file (first image)))))))))

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-006-runtime-native-binding-and-getters-after-source-fds-closed
  (dolist (version '(1 2))
    (dolist (bind-before-close '(nil t))
      (a::acn-run version (a::acn-gate-series) 1 nil
        (lambda (fixture)
          (runtime-REQ-MVC-006-native-closed-sources fixture bind-before-close))))))
