;;;; Casi integration nativi: predisposti per il runner centralizzato dopo freeze.
;;; OWNER: runner seriale; ciascun caso possiede lease, file, contesti e FI della sua fixture.
;;; SHARED: solo fonti immutabili; interleaving deterministiche senza attese o worker in volo.
(in-package #:arcdocdb.get.directory.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-WAL-006-series-get-empty-active-initialization-native-v1-v2
  (dolist (version '(1 2))
    (dolist (factory '(:resolver :directory))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((source (directory-series-fixture-source fixture))
                (lease (directory-series-fixture-lease fixture))
                (sources (directory-series-fixture-sources fixture))
                (payload (d:contenuto-fonti-get-serie sources)))
           (directory-series-check-initial-state fixture nil)
           (let ((root (ecase factory
                         (:resolver (r:inizializza-radice-get-attiva source lease :content sources))
                         (:directory (d:inizializza-fonti-get-attive source lease sources)))))
             (directory-series-check-empty-root fixture root)
             (is (eq payload (d:contenuto-fonti-get-serie (r:contenuto-radice-get-attiva root))))
             (directory-series-check-initial-state fixture root))))
       :version version :active-p t :publish-active-p nil :content (vector :caller version)))))

;;; REQ: REQ-WAL-006 REQ-CON-002 REQ-MVC-008 REQ-AFF-001
(deftest test-REQ-WAL-006-series-get-initial-controller-root-and-nil-refusal
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let ((controller (directory-series-fixture-controller fixture))
             (lease (directory-series-fixture-lease fixture))
             (root (vector :caller version)))
         (signals invalid-argument
           (arcdocdb.series:inizializza-radice-serie controller lease nil) :serie-initial-root)
         (directory-series-check-initial-state fixture nil)
         (is (eq root (arcdocdb.series:inizializza-radice-serie controller lease root)))
         (directory-series-check-initial-state fixture root)
         (signals invalid-argument
           (arcdocdb.series:inizializza-radice-serie controller lease (vector :replacement)) :serie-started)
         (directory-series-check-initial-state fixture root)))
     :version version :root nil)))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-WAL-006 REQ-CMP-007
(deftest test-REQ-IDX-001-series-get-empty-active-closed-before-first-batch-native-v1-v2
  (dolist (version '(1 2))
    (dolist (prepared-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (controller (directory-series-fixture-controller fixture))
                (context (directory-series-context fixture))
                (empty (directory-series-fixture-root fixture)))
           (directory-series-check-empty-root fixture empty)
           (directory-series-check-initial-state fixture empty)
           (dotimes (ordinal 2)
             (let ((key (aref (directory-fixture-keys directory) ordinal))
                   (value (aref (directory-fixture-values directory) ordinal))
                   (id (aref (directory-fixture-ids directory) ordinal)))
               (is (eq :candidate (directory-series-begin fixture key)))
               (directory-series-observe-acquire
                fixture (lambda ()
                          (is (equal (list (r::mappa-segmento-get-segment
                                            (aref (directory-fixture-maps directory) ordinal))
                                           (aref (directory-fixture-ends directory) ordinal)
                                           (if prepared-p 1 0) (when prepared-p 120))
                                     (multiple-value-list (d:risolvi-candidato-serie-get context controller))))))
               (directory-series-observe-acquire
                fixture (lambda ()
                          (is (eq (if prepared-p :proof-required :disabled)
                                  (d:sonda-cache-serie-get context controller)))))
               (is (null (directory-read-events directory)))
               (is (directory-output-untouched-p directory))
               (directory-series-observe-acquire
                fixture (lambda ()
                          (is (equal '(:segment :disabled :not-attempted nil nil)
                                     (multiple-value-list (d:leggi-record-serie-get context controller))))))
               (directory-series-copy-and-finish fixture value)
               (is (equal (if prepared-p (list (list id 120 32) (list id 64 56))
                              (list (list id 64 56))) (directory-read-events directory)))
               ;; Il backend ACTIVE non deve essere consultato per un candidato CLOSED.
               (is (null (directory-series-fixture-io-events fixture)))
               (directory-series-clear-io-events fixture)))
           (directory-series-check-initial-state fixture empty)))
       :version version :prepared-p prepared-p :empty-active-p t))))

;;; REQ: REQ-AFF-004 REQ-IDX-001 REQ-WAL-006 REQ-CMP-007
(deftest test-REQ-AFF-004-series-get-empty-active-candidate-faulted-native-v1-v2
  (dolist (version '(1 2))
    (dolist (operation '(:resolve :probe :read :explicit))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (context (directory-series-context fixture))
                (controller (directory-series-fixture-controller fixture))
                (empty (directory-series-fixture-root fixture))
                (key (directory-series-fixture-active-key fixture))
                (value (directory-series-fixture-active-value fixture)))
           ;; FI primary anticipata: nessun PUT/WAL corrisponde alla location ACTIVE.
           (directory-publish-key directory key 1 (directory-series-fixture-active-id fixture)
                                  64 (+ 24 (length key) (length value)))
           (is (eq :candidate (directory-series-begin fixture key)))
           (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
           (directory-series-observe-acquire
            fixture
            (lambda ()
              (signals invariant-violation
                (if (eq operation :explicit)
                    (r:risolvi-candidato-radice-attiva-get context empty)
                    (directory-series-operation operation context controller)) :active-location-frontier))
            :expected (if (eq operation :explicit) 0 1))
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))
           (is (null (directory-series-fixture-io-events fixture)))
           (directory-series-check-empty-root fixture empty)
           (is (eq empty (arcdocdb.series:leggi-radice-serie controller)))
           (is (equal '(0 0 0) (multiple-value-list
                                (arcdocdb.series:conta-commit-serie controller (directory-series-fixture-lease fixture)))))
           (is (equal '(0 1 0 1) (multiple-value-list
                                  (arcdocdb.csn:leggi-frontiere-csn (directory-series-fixture-registry fixture)))))
           (signals invalid-argument (g:concludi-get context 12) :get-result-not-ready)
           (signals invalid-argument (directory-series-begin fixture key) :get-worker-state)))
       :version version :empty-active-p t))))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-IDX-001 REQ-MVC-008 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-empty-active-first-batch-publish-and-reuse-native-v1-v2
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((directory (directory-series-fixture-directory fixture))
              (controller (directory-series-fixture-controller fixture))
              (lease (directory-series-fixture-lease fixture))
              (empty (directory-series-fixture-root fixture))
              (key (directory-series-fixture-active-key fixture))
              (value (directory-series-fixture-active-value fixture))
              (size (+ 24 (length key) (length value)))
              ;; SEAL indipendente: 24 byte di cornice e 32 byte di body.
              (end (+ 64 size 56))
              (commit (directory-series-stage fixture key value))
              (batch (directory-series-commit-batch commit))
              (event (directory-series-commit-event commit))
              (root (directory-series-commit-root commit)))
         (is (= 1 (directory-series-commit-generation commit)))
         (is (= 2 (directory-series-commit-csn commit)))
         (is (eq empty (arcdocdb.series::commit-serie-expected-root event)))
         (is (eq empty (arcdocdb.series:leggi-radice-serie controller)))
         (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
         (is (not (eq empty root)))
         (is (= 1 (r::radice-get-attiva-count root)))
         (is (= 1 (r::radice-get-attiva-puts root)))
         (is (= 4 (r::radice-get-attiva-nodes root)))
         (is (= end (r::radice-get-attiva-end root)))
         (is (eq (directory-series-fixture-sources fixture) (r:contenuto-radice-get-attiva root)))
         (is (= 64 (io:posizione-scritta (directory-series-fixture-file fixture))))
         (is (= 64 (io:posizione-durevole (directory-series-fixture-file fixture))))
         (is (null (directory-series-fixture-io-events fixture)))
         (directory-series-check-empty-root fixture empty)
         (directory-series-publish fixture commit)
         (is (eq root (arcdocdb.series:leggi-radice-serie controller)))
         (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
         (is (= end (io:posizione-scritta (directory-series-fixture-file fixture))))
         (is (= end (io:posizione-durevole (directory-series-fixture-file fixture))))
         (is (eq :open (arcdocdb.wal:stato-lotto batch)))
         (is (null (arcdocdb.wal::lotto-owner batch)))
         (is (eq :libero (arcdocdb.series::commit-serie-phase event)))
         (is (null (arcdocdb.series::commit-serie-lotto event)))
         (is (null (arcdocdb.series::commit-serie-expected-root event)))
         (is (null (arcdocdb.series::commit-serie-root event)))
         (is (equal '(0 0 0) (multiple-value-list (arcdocdb.series:conta-commit-serie controller lease))))
         (is (equal '(0 2 0 2) (multiple-value-list
                                (arcdocdb.csn:leggi-frontiere-csn (directory-series-fixture-registry fixture)))))
         (directory-series-check-empty-root fixture empty)
         ;; Mutazione del buffer ormai OPEN: la root deve possedere copie dei dati del lotto.
         (arcdocdb.wal:aggiungi-record batch 1 (directory-key 1001) (directory-value 1001 16))
         (directory-series-clear-io-events fixture)
         (dotimes (ordinal 3)
           (let* ((active-p (= ordinal 2))
                  (read-key (if active-p key (aref (directory-fixture-keys directory) ordinal)))
                  (read-value (if active-p value (aref (directory-fixture-values directory) ordinal)))
                  (id (if active-p (directory-series-fixture-active-id fixture)
                          (aref (directory-fixture-ids directory) ordinal))))
             (is (eq :candidate (directory-series-begin fixture read-key)))
             (directory-series-observe-acquire
              fixture (lambda ()
                        (is (equal '(:segment :disabled :not-attempted nil nil)
                                   (multiple-value-list
                                    (d:leggi-record-serie-get (directory-series-context fixture) controller))))))
             (directory-series-copy-and-finish fixture read-value)
             (is (equal (list (list id 64 (+ 24 (length read-key) (length read-value))))
                        (directory-read-events directory)))
             (directory-series-clear-io-events fixture)))
         (directory-series-check-empty-root fixture empty)))
     :version version :empty-active-p t)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004 REQ-CON-002
(deftest test-REQ-WAL-006-series-get-empty-active-repeated-initialization-refused
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let ((source (directory-series-fixture-source fixture))
             (controller (directory-series-fixture-controller fixture))
             (lease (directory-series-fixture-lease fixture))
             (sources (directory-series-fixture-sources fixture))
             (empty (directory-series-fixture-root fixture)))
         (signals invalid-argument
           (arcdocdb.series:inizializza-radice-serie controller lease (vector :replacement)) :serie-started)
         (directory-series-check-initial-state fixture empty)
         (signals invalid-argument
           (r:inizializza-radice-get-attiva source lease :content sources) :serie-started)
         (directory-series-check-initial-state fixture empty)
         (signals invalid-argument
           (d:inizializza-fonti-get-attive source lease sources) :serie-started)
         (directory-series-check-initial-state fixture empty)
         (directory-series-check-empty-root fixture empty)))
     :version version :empty-active-p t)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-empty-active-foreign-owner-before-initialization
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (call-with-directory-series-fixture
        (lambda (foreign)
          (signals invalid-argument
            (d:inizializza-fonti-get-attive
             (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
             (directory-series-fixture-sources foreign)) :sources-owner)
          (directory-series-check-initial-state fixture nil)
          (directory-series-check-initial-state foreign nil)
          ;; Il rifiuto consente il successivo avvio corretto sullo stesso controller.
          (directory-series-initialize-empty fixture))
        :version version :active-p t :publish-active-p nil))
     :version version :active-p t :publish-active-p nil)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-empty-active-duplicate-before-initialization
  (dolist (version '(1 2))
    (dolist (id '(17 #xffffffff))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (signals invalid-argument
           (d:inizializza-fonti-get-attive
            (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
            (directory-series-fixture-sources fixture)) :sources-active-duplicate)
         (directory-series-check-initial-state fixture nil))
       :version version :active-p t :publish-active-p nil :active-id id))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-CON-002-series-get-empty-active-lease-before-checks
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (call-with-directory-series-fixture
        (lambda (foreign)
          (let* ((controller (directory-series-fixture-controller fixture))
                 (source (directory-series-fixture-source fixture))
                 (stale (directory-series-fixture-lease fixture)))
            (arcdocdb.series:rilascia-controllore-serie controller stale)
            (setf (directory-series-fixture-lease fixture) nil)
            (setf (directory-series-fixture-lease fixture) (arcdocdb.series:acquisisci-controllore-serie controller))
            ;; CLOSED include anche l'ID ACTIVE; la vista foreign precede il controllo duplicato.
            (io:chiudi (directory-series-fixture-readonly fixture))
            (directory-series-clear-io-events fixture)
            (dolist (lease (list nil 0 stale))
              (signals invalid-argument
                (arcdocdb.series:inizializza-radice-serie controller lease nil) :serie-lease)
              (signals invalid-argument
                (r:inizializza-radice-get-attiva source lease) :serie-lease)
              (signals invalid-argument
                (d:inizializza-fonti-get-attive source lease (directory-series-fixture-sources foreign)) :serie-lease)
              (signals invalid-argument
                (d:inizializza-fonti-get-attive source lease (directory-series-fixture-sources fixture)) :serie-lease)
              (directory-series-check-initial-state fixture nil :readonly-state :closed))
            (directory-series-check-initial-state foreign nil)))
        :version version :active-p t :publish-active-p nil))
     :version version :active-p t :publish-active-p nil :active-id 17)))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-WAL-006-series-get-empty-active-file-frontier-refused
  (dolist (version '(1 2))
    (dolist (factory '(:resolver :directory))
      (dolist (mode '(:written :durable :durable-short :offset))
        (call-with-directory-series-fixture
         (lambda (fixture)
           (let ((controller (directory-series-fixture-controller fixture)))
             (ecase mode
               (:written (io:append-esatto (directory-series-fixture-file fixture) (directory-octets 1) 0 1))
               (:durable
                (io:append-esatto (directory-series-fixture-file fixture) (directory-octets 1) 0 1)
                (io:durable-flush (directory-series-fixture-file fixture)))
               ;; FI seriale: written=offset=64 isolano la sola foglia durable!=64.
               (:durable-short (setf (io::file-durable (directory-series-fixture-file fixture)) 63))
               ;; FI metadata locale: source gia' costruita, file nativo fermo al solo header.
               (:offset (setf (arcdocdb.series::controllore-serie-next-offset controller) 65)))
             (directory-series-clear-io-events fixture)
             (signals invalid-argument
               (ecase factory
                 (:resolver (r:inizializza-radice-get-attiva
                             (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)))
                 (:directory (d:inizializza-fonti-get-attive
                              (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
                              (directory-series-fixture-sources fixture)))) :active-root-initial-frontier)
             (directory-series-check-initial-state
              fixture nil :written (if (member mode '(:offset :durable-short)) 64 65)
              :durable (case mode (:durable 65) (:durable-short 63) (otherwise 64))
              :next-offset (if (eq mode :offset) 65 64))))
         :version version :active-p t :publish-active-p nil)))))

;;; REQ: REQ-CMP-007 REQ-WAL-006 REQ-IDX-001 REQ-AFF-001
(deftest test-REQ-CMP-007-series-get-empty-active-fixture-cleanup-native-v1-v2
  (dolist (version '(1 2))
    (let* ((fixture (make-directory-series-fixture :version version :empty-active-p t))
           (directory (directory-series-fixture-directory fixture))
           (path (directory-series-fixture-path fixture))
           (directory-path (directory-fixture-root directory))
           (controller (directory-series-fixture-controller fixture)))
      (unwind-protect
           (progn
             (is (eq :candidate (directory-series-begin fixture (aref (directory-fixture-keys directory) 0))))
             (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
             ;; Cleanup esterno di sicurezza: abbandona un GET ancora CANDIDATE prima dei FD.
             (close-directory-series-fixture fixture)
             (is (directory-check-clean directory))
             (is (null (arcdocdb.series::controllore-serie-owner controller)))
             (is (null (directory-series-fixture-lease fixture)))
             (is (eq :closed (io:stato-file (directory-series-fixture-readonly fixture))))
             (is (eq :closed (io:stato-file (directory-series-fixture-file fixture))))
             (is (every (lambda (file) (eq :closed (io:stato-file file))) (directory-fixture-files directory)))
             (is (null (probe-file path)))
             (is (null (probe-file directory-path)))
             ;; Ripetizione non chiude un FD riusato e non ripete syscall ACTIVE.
             (directory-series-clear-io-events fixture)
             (close-directory-series-fixture fixture)
             (is (null (directory-series-fixture-io-events fixture))))
        (close-directory-series-fixture fixture)))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-001 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-empty-active-closed-capabilities-refused
  (dolist (version '(1 2))
    (dolist (factory '(:resolver :directory))
      ;; Tre falsificazioni di AND: readonly sola, append sola, entrambe.
      (dolist (mode '(:readonly :append :both))
        (call-with-directory-series-fixture
         (lambda (fixture)
           (when (member mode '(:readonly :both)) (io:chiudi (directory-series-fixture-readonly fixture)))
           (when (member mode '(:append :both)) (io:chiudi (directory-series-fixture-file fixture)))
           (directory-series-clear-io-events fixture)
           (is (eq :open (arcdocdb.wal:stato-log (directory-series-fixture-log fixture))))
           (signals invalid-argument
             (ecase factory
               (:resolver (r:inizializza-radice-get-attiva
                           (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)))
               (:directory (d:inizializza-fonti-get-attive
                            (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
                            (directory-series-fixture-sources fixture)))) :active-source-file)
           (directory-series-check-initial-state
            fixture nil :readonly-state (if (eq mode :append) :open :closed)
            :append-state (if (eq mode :readonly) :open :closed)))
         :version version :active-p t :publish-active-p nil)))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007
(deftest test-REQ-IDX-001-series-get-content-roundtrip
  (call-with-directory-series-fixture
   (lambda (fixture)
     (let* ((directory (directory-fixture-directory (directory-series-fixture-directory fixture)))
            (payload (vector :caller (directory-key 123)))
            (sources (d:crea-fonti-get-serie directory :content payload)))
       (is (typep sources 'd:fonti-get-serie))
       (is (eq payload (d:contenuto-fonti-get-serie sources)))
       (is (null (d:contenuto-fonti-get-serie (d:crea-fonti-get-serie directory))))
       (is (null (d:contenuto-fonti-get-serie (d:crea-fonti-get-serie directory :content nil))))
       (is (directory-check-clean (directory-series-fixture-directory fixture)))))))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CMP-007 REQ-WAL-006
(deftest test-REQ-IDX-001-series-get-closed-controller-native-v1-v2
  (dolist (version '(1 2))
    (dolist (prepared-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (context (directory-series-context fixture))
                (controller (directory-series-fixture-controller fixture)))
           (dotimes (ordinal 2)
             (fill (aref (directory-fixture-outputs directory) 0) +directory-sentinel+)
             (is (eq :candidate (directory-begin directory :ordinal ordinal)))
             (directory-series-observe-acquire
              fixture
              (lambda ()
                (is (equal (list (r::mappa-segmento-get-segment (aref (directory-fixture-maps directory) ordinal))
                                 (aref (directory-fixture-ends directory) ordinal)
                                 (if prepared-p 1 0) (when prepared-p 120))
                           (multiple-value-list (d:risolvi-candidato-serie-get context controller))))))
             (directory-series-observe-acquire
              fixture (lambda ()
                        (is (eq (if prepared-p :proof-required :disabled)
                                (d:sonda-cache-serie-get context controller)))))
             (is (null (directory-read-events directory)))
             (is (directory-output-untouched-p directory))
             (directory-series-observe-acquire
              fixture (lambda ()
                        (is (equal '(:segment :disabled :not-attempted nil nil)
                                   (multiple-value-list (d:leggi-record-serie-get context controller))))))
             (directory-copy-and-finish directory 0 ordinal)
             (let ((id (aref (directory-fixture-ids directory) ordinal)))
               (is (equal (if prepared-p (list (list id 120 32) (list id 64 56)) (list (list id 64 56)))
                          (directory-read-events directory))))
             (directory-clear-read-events directory))))
       :version version :prepared-p prepared-p))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CCH-002 REQ-CMP-007
(deftest test-REQ-IDX-001-series-get-active-and-closed-mixed
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((directory (directory-series-fixture-directory fixture))
              (context (directory-series-context fixture))
              (controller (directory-series-fixture-controller fixture))
              (root (arcdocdb.series:leggi-radice-serie controller)))
         (is (eq (directory-series-fixture-sources fixture) (r:contenuto-radice-get-attiva root)))
         (dolist (active-p '(nil t))
           (let ((key (if active-p (directory-series-fixture-active-key fixture)
                          (aref (directory-fixture-keys directory) 0)))
                 (value (if active-p (directory-series-fixture-active-value fixture)
                            (aref (directory-fixture-values directory) 0))))
             (is (eq :candidate (directory-series-begin fixture key)))
             (directory-series-observe-acquire
              fixture (lambda ()
                        (is (equal '(:segment :disabled :not-attempted nil nil)
                                   (multiple-value-list (d:leggi-record-serie-get context controller))))))
             (directory-series-copy-and-finish fixture value)
             (is (equal (list (list (if active-p 13 17) 64 56)) (directory-read-events directory)))
             (directory-clear-read-events directory)
             (fill (aref (directory-fixture-outputs directory) 0) +directory-sentinel+)))))
     :version version :active-p t :content (vector :caller version))))

;;; REQ: REQ-CCH-002 REQ-FOR-004 REQ-CMP-007
(deftest test-REQ-CCH-002-series-get-five-outcomes-cold-and-hot
  (dolist (active-p '(nil t))
    (dolist (prepared-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (context (directory-series-context fixture))
                (controller (directory-series-fixture-controller fixture))
                (key (if active-p (directory-series-fixture-active-key fixture)
                         (aref (directory-fixture-keys directory) 0)))
                (value (if active-p (directory-series-fixture-active-value fixture)
                           (aref (directory-fixture-values directory) 0)))
                (proof-p (and prepared-p (not active-p))))
           (is (eq :candidate (directory-series-begin fixture key)))
           (is (eq (if proof-p :proof-required :miss) (d:sonda-cache-serie-get context controller)))
           (is (null (directory-read-events directory)))
           (is (equal '(:segment :miss :inserted nil nil)
                      (multiple-value-list (d:leggi-record-serie-get context controller))))
           (is (directory-output-untouched-p directory))
           (directory-series-copy-and-finish fixture value)
           (directory-clear-read-events directory)
           (is (eq :candidate (directory-series-begin fixture key)))
           (is (eq (if proof-p :proof-required :hit) (d:sonda-cache-serie-get context controller)))
           (when proof-p
             (is (equal '(:cache :hit :not-attempted nil nil)
                        (multiple-value-list (d:leggi-record-serie-get context controller)))))
           (directory-series-copy-and-finish fixture value)
           (is (equal (when proof-p (list (list 17 120 32))) (directory-read-events directory)))
           (directory-clear-read-events directory)
           (is (eq :candidate (directory-series-begin fixture key)))
           (is (equal '(:cache :hit :not-attempted nil nil)
                      (multiple-value-list (d:leggi-record-serie-get context controller))))
           (directory-series-copy-and-finish fixture value)
           (is (equal (when proof-p (list (list 17 120 32))) (directory-read-events directory)))))
       :active-p active-p :prepared-p prepared-p :cache-p t))))

;;; REQ: REQ-CCH-004 REQ-CCH-002 REQ-IDX-001
(deftest test-REQ-CCH-004-series-get-cache-corruption-native-fallback
  (call-with-directory-series-fixture
   (lambda (fixture)
     (let* ((directory (directory-series-fixture-directory fixture))
            (context (directory-series-context fixture))
            (controller (directory-series-fixture-controller fixture)))
       (is (eq :candidate (directory-begin directory)))
       (is (equal '(:segment :miss :inserted nil nil)
                  (multiple-value-list (d:leggi-record-serie-get context controller))))
       (directory-copy-and-finish directory)
       (directory-corrupt-cached-value directory)
       (directory-clear-read-events directory)
       (is (eq :candidate (directory-begin directory)))
       (is (equal '(:segment :verify-failed :inserted nil nil)
                  (multiple-value-list (d:leggi-record-serie-get context controller))))
       (directory-copy-and-finish directory)
       (is (equal '((17 64 56)) (directory-read-events directory)))))
   :cache-p t))

;;; REQ: REQ-CMP-007 REQ-IDX-001 REQ-AFF-004
(deftest test-REQ-CMP-007-series-get-wrong-owner-cleanup
  (dolist (operation '(:resolve :probe :read))
    (dolist (active-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (call-with-directory-series-fixture
          (lambda (foreign)
            (let ((directory (directory-series-fixture-directory fixture)))
              (is (eq :candidate (directory-begin directory)))
              (signals invalid-argument
                (directory-series-operation operation (directory-series-context fixture)
                                             (directory-series-fixture-controller foreign)) :sources-owner)
              (is (directory-check-clean directory))
              (is (directory-output-untouched-p directory))
              (is (null (directory-read-events directory)))
              (is (null (directory-read-events (directory-series-fixture-directory foreign))))
              (is (directory-check-clean (directory-series-fixture-directory foreign)))))
          :active-p active-p))
       :active-p active-p))))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-AFF-004-series-get-nil-and-corrupt-root-faulted
  (dolist (operation '(:resolve :probe :read))
    (dolist (root (list nil :corrupt #()))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let ((directory (directory-series-fixture-directory fixture)))
           (is (eq :candidate (directory-begin directory)))
           (signals invariant-violation
             (directory-series-operation operation (directory-series-context fixture)
                                          (directory-series-fixture-controller fixture)) :sources-published-root)
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))
           (signals invalid-argument (g:concludi-get (directory-series-context fixture) 12) :get-result-not-ready)))
       :root root))))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-AFF-004-series-get-corrupt-active-content-faulted
  (dolist (operation '(:resolve :probe :read))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (directory-series-publish
        fixture (directory-series-stage fixture (directory-series-fixture-active-key fixture)
                                         (directory-series-fixture-active-value fixture)
                                         :sources :corrupt-content :checked-p nil))
       (let ((directory (directory-series-fixture-directory fixture)))
         (is (eq :candidate (directory-begin directory)))
         (signals invariant-violation
           (directory-series-operation operation (directory-series-context fixture)
                                        (directory-series-fixture-controller fixture)) :sources-published-root)
         (is (directory-check-clean directory 0 :faulted))
         (is (directory-output-untouched-p directory))
         (is (null (directory-read-events directory)))))
     :active-p t :publish-active-p nil)))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-WAL-006
(deftest test-REQ-AFF-004-series-get-source-controller-mismatch-typed-faulted
  (dolist (operation '(:resolve :probe :read))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (call-with-directory-series-fixture
        (lambda (foreign)
          (let ((directory (directory-series-fixture-directory fixture)))
            (is (eq :candidate (directory-begin directory)))
            (signals invariant-violation
              (directory-series-operation operation (directory-series-context fixture)
                                           (directory-series-fixture-controller foreign)) :sources-active-controller)
            (is (directory-check-clean directory 0 :faulted))
            (is (directory-output-untouched-p directory))
            (is (null (directory-read-events directory)))
            (is (null (directory-read-events (directory-series-fixture-directory foreign))))
            (is (eq :healthy (arcdocdb.series:stato-controllore-serie
                              (directory-series-fixture-controller fixture))))))
        :root (directory-series-fixture-root fixture)))
     :active-p t)))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-IDX-001-series-get-missing-closed-id-faulted
  (dolist (operation '(:resolve :probe :read))
    (dolist (active-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let ((directory (directory-series-fixture-directory fixture)) (bad-key (directory-key 2001)))
           ;; ID 18 e' assente fra CLOSED 17 e #xffffffff; non coincide con ACTIVE 13.
           ;; FI su nuova chiave: non viola la monotonia CSN di una chiave gia' pubblicata.
           (directory-publish-key directory bad-key 1 18 64 56)
           (is (eq :candidate (directory-series-begin fixture bad-key)))
           (signals invariant-violation
             (directory-series-operation operation (directory-series-context fixture)
                                          (directory-series-fixture-controller fixture)) :directory-location-absent)
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))
           (signals invalid-argument (directory-begin directory) :get-worker-state)))
       :active-p active-p))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CON-004-series-get-wrong-state-no-pin-steal
  (dolist (operation '(:resolve :probe :read))
    (dolist (state '(:idle :verified :copied))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (context (directory-series-context fixture))
                (controller (directory-series-fixture-controller fixture)))
           (unless (eq state :idle)
             (is (eq :candidate (directory-begin directory)))
             (is (equal '(:segment :disabled :not-attempted nil nil)
                        (multiple-value-list (d:leggi-record-serie-get context controller))))
             (when (eq state :copied)
               (is (= 19 (g:copia-valore-get context (aref (directory-fixture-outputs directory) 0) 3)))))
           (let ((candidate (copy-seq (g::contesto-get-content context)))
                 (reads (directory-read-events directory)))
             (directory-series-observe-acquire
              fixture (lambda ()
                        (signals invalid-argument
                          (directory-series-operation operation context controller) :get-worker-state)) :expected 0)
             (is (eq state (g:stato-contesto-get context)))
             (is (equalp candidate (g::contesto-get-content context)))
             (is (equal reads (directory-read-events directory)))
             (is (eq (not (eq state :idle))
                     (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))))
           (ecase state
             (:idle (is (directory-check-clean directory)))
             (:verified (directory-copy-and-finish directory))
             (:copied
              (is (directory-check-output directory 0 0))
              (is (equal '(:found 16) (multiple-value-list (g:concludi-get context 12))))
              (is (directory-check-clean directory))))))))))

;;; REQ: REQ-WAL-006 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-WAL-006-series-get-one-root-after-pin-during-publication
  ;; FI intenzionale: la nuova directory vuota viola il superset per il candidato CLOSED gia' LIVE.
  ;; Serve a distinguere la singola cattura da una rilettura; non e' rotation/reclaim sano.
  (dolist (operation '(:resolve :probe :read))
    (dolist (active-p '(nil t))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (context (directory-series-context fixture))
                (controller (directory-series-fixture-controller fixture))
                (captured (directory-series-fixture-root fixture))
                (empty (d:crea-fonti-get-serie (d:crea-directory-get-serie (directory-fixture-view directory) #())))
                (next (directory-series-stage fixture (directory-key 1001) (directory-value 1001 16) :sources empty))
                (key (if active-p (directory-series-fixture-active-key fixture)
                         (aref (directory-fixture-keys directory) 0)))
                (value (if active-p (directory-series-fixture-active-value fixture)
                           (aref (directory-fixture-values directory) 0))))
           (is (eq :candidate (directory-series-begin fixture key)))
           (directory-series-observe-acquire
            fixture
            (lambda ()
              (ecase operation
                (:resolve
                 (is (equal (list (if active-p (r::sorgente-get-attiva-segment (directory-series-fixture-source fixture))
                                      (r::mappa-segmento-get-segment (aref (directory-fixture-maps directory) 0)))
                                  (if active-p (r::radice-get-attiva-end captured) 120) 0 nil)
                            (multiple-value-list (d:risolvi-candidato-serie-get context controller)))))
                (:probe (is (eq :disabled (d:sonda-cache-serie-get context controller))))
                (:read (is (equal '(:segment :disabled :not-attempted nil nil)
                                  (multiple-value-list (d:leggi-record-serie-get context controller)))))))
            :after-read (lambda () (directory-series-publish fixture next :publish-key-p nil)))
           (is (eq (directory-series-commit-root next) (arcdocdb.series:leggi-radice-serie controller)))
           (unless (eq operation :read)
             ;; Conclude con le fonti catturate; la FI ha rimosso CLOSED dalla root successiva.
             (multiple-value-bind (segment end flags proof)
                 (if active-p (r:risolvi-candidato-radice-attiva-get context captured)
                     (d:risolvi-candidato-directory-get context (directory-fixture-directory directory)))
               (is (equal '(:segment :disabled :not-attempted nil nil)
                          (multiple-value-list (g:leggi-record-get context segment end flags :outcome-offset proof))))))
           (directory-series-copy-and-finish fixture value)))
       :active-p t))))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-explicit-root-preserves-captured-page
  (call-with-directory-series-fixture
   (lambda (fixture)
     (let* ((context (directory-series-context fixture))
            (key (directory-series-fixture-active-key fixture)))
       (is (eq :candidate (directory-series-begin fixture key)))
       (let ((captured (arcdocdb.series:leggi-radice-serie (directory-series-fixture-controller fixture))))
         (directory-series-publish fixture (directory-series-stage fixture (directory-key 1001) (directory-value 1001 16)))
         (directory-series-observe-acquire
          fixture (lambda ()
                    (is (equal (list (r::sorgente-get-attiva-segment (directory-series-fixture-source fixture)) 176 0 nil)
                               (multiple-value-list (r:risolvi-candidato-radice-attiva-get context captured))))) :expected 0)
         (is (equal '(:segment :disabled :not-attempted nil nil)
                    (multiple-value-list
                     (g:leggi-record-get context (r::sorgente-get-attiva-segment (directory-series-fixture-source fixture))
                                         176 0))))
         (directory-series-copy-and-finish fixture (directory-series-fixture-active-value fixture)))))
   :active-p t))

;;; REQ: REQ-WAL-006 REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-explicit-root-excludes-later-publication
  (call-with-directory-series-fixture
   (lambda (fixture)
     (let* ((directory (directory-series-fixture-directory fixture))
            (new-key (directory-key 1001))
            (next (directory-series-stage fixture new-key (directory-value 1001 16))))
       ;; FI primaria anticipata: candidata oltre la vecchia frontiera, prima del CAS del lotto.
       ;; Non attesta un writer sano; conserva UN pin dalla cattura all'ultimo accesso.
       (directory-publish-key directory new-key (directory-series-commit-csn next) 13
                              (directory-series-commit-start next) (directory-series-commit-size next))
       (is (eq :candidate (directory-series-begin fixture new-key)))
       (let ((captured (arcdocdb.series:leggi-radice-serie (directory-series-fixture-controller fixture))))
         (directory-series-publish fixture next :publish-key-p nil)
         (directory-series-observe-acquire
          fixture (lambda ()
                    (signals invariant-violation
                      (r:risolvi-candidato-radice-attiva-get (directory-series-context fixture) captured)
                      :active-location-frontier)) :expected 0)
         (is (directory-check-clean directory 0 :faulted))
         (is (directory-output-untouched-p directory))
         (is (null (directory-read-events directory))))))
   :active-p t))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-WAL-005-series-get-writer-foreign-owner-before-adoption
  (call-with-directory-series-fixture
   (lambda (fixture)
     (call-with-directory-series-fixture
      (lambda (foreign)
        (let* ((key (directory-series-fixture-active-key fixture))
               (value (directory-series-fixture-active-value fixture))
               (batch (directory-series-seal fixture key value))
               (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto batch)))
               (bytes (copy-seq (arcdocdb.wal::lotto-buffer batch))))
          (signals invalid-argument
            (d:registra-lotto-fonti-get-attivo
             (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
             batch nil (directory-series-fixture-sources foreign) :strong) :sources-owner)
          (directory-series-check-refused-batch fixture batch token bytes)
          ;; Il caller riusa proprio il lotto/token rifiutato, con fonti della vista corretta.
          (directory-series-publish fixture (directory-series-stage fixture key value :batch batch))
          (is (eq :candidate (directory-series-begin fixture key)))
          (is (equal '(:segment :disabled :not-attempted nil nil)
                     (multiple-value-list (d:leggi-record-serie-get (directory-series-context fixture)
                                                                  (directory-series-fixture-controller fixture)))))
          (directory-series-copy-and-finish fixture value)))))
   :active-p t :publish-active-p nil))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-WAL-005-series-get-writer-duplicate-active-before-adoption
  (dolist (id '(17 #xffffffff))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((directory (directory-series-fixture-directory fixture))
              (key (directory-series-fixture-active-key fixture))
              (value (directory-series-fixture-active-value fixture))
              (batch (directory-series-seal fixture key value))
              (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto batch)))
              (bytes (copy-seq (arcdocdb.wal::lotto-buffer batch)))
              (valid (d:crea-fonti-get-serie (d:crea-directory-get-serie (directory-fixture-view directory) #()))))
         (signals invalid-argument
           (d:registra-lotto-fonti-get-attivo
            (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
            batch nil (directory-series-fixture-sources fixture) :strong) :sources-active-duplicate)
         (directory-series-check-refused-batch fixture batch token bytes)
         ;; Fonti vuote consentono ACTIVE: questo test non legge le location CLOSED preesistenti.
         (directory-series-publish fixture (directory-series-stage fixture key value :batch batch :sources valid))
         (is (eq :candidate (directory-series-begin fixture key)))
         (is (equal '(:segment :disabled :not-attempted nil nil)
                    (multiple-value-list (d:leggi-record-serie-get (directory-series-context fixture)
                                                                 (directory-series-fixture-controller fixture)))))
         (directory-series-copy-and-finish fixture value)))
     :active-p t :publish-active-p nil :active-id id)))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-AFF-004-series-get-published-active-duplicate-faulted
  (dolist (operation '(:resolve :probe :read))
    (dolist (id '(17 #xffffffff))
      (call-with-directory-series-fixture
       (lambda (fixture)
         ;; FI: il writer generico bypassa il rifiuto del ponte e pubblica ID ACTIVE anche in CLOSED.
         (directory-series-publish
          fixture (directory-series-stage fixture (directory-series-fixture-active-key fixture)
                                           (directory-series-fixture-active-value fixture) :checked-p nil))
         (let ((directory (directory-series-fixture-directory fixture)))
           (is (eq :candidate (directory-begin directory)))
           (signals invariant-violation
             (directory-series-operation operation (directory-series-context fixture)
                                          (directory-series-fixture-controller fixture)) :sources-active-duplicate)
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))))
       :active-p t :publish-active-p nil :active-id id))))

;;; REQ: REQ-AFF-004 REQ-CMP-007 REQ-IDX-001
(deftest test-REQ-AFF-004-series-get-active-owner-and-id-guards
  (dolist (operation '(:resolve :probe :read))
    (dolist (mode '(:owner :high :zero))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (original (r::sorgente-get-attiva-segment (directory-series-fixture-source fixture)))
                (view (directory-fixture-view directory))
                (owner (if (eq mode :owner)
                           (g:crea-vista-get-serie (directory-fixture-scope directory) (directory-fixture-index directory)
                                                  nil (g::vista-get-serie-identity view)) view))
                ;; FI locale: clone di capacita', stesso FD nativo; non altera la root pubblicata.
                (segment (g::%make-segmento-get owner (g::segmento-get-file original)
                                               (if (eq mode :high) 1 0) (if (eq mode :zero) 0 13)
                                               (g::segmento-get-version original) (g::segmento-get-origin original)))
                (root (directory-series-fi-root-with-segment fixture segment)))
           (is (eq :candidate (directory-begin directory)))
           (directory-series-function-fi
            'arcdocdb.series:leggi-radice-serie
            (lambda (getter)
              (lambda (controller)
                (is (eq controller (directory-series-fixture-controller fixture)))
                (is (eq (funcall getter controller) (directory-series-fixture-root fixture)))
                (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
                root))
            (lambda ()
              (signals invariant-violation
                (directory-series-operation operation (directory-series-context fixture)
                                             (directory-series-fixture-controller fixture))
                (if (eq mode :owner) :sources-active-owner :sources-active-id))))
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))))
       :active-p t))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-series-get-contains-empty-and-id-extremes
  (with-directory-fixture (fixture :count 2 :cache-p nil :observe-io-p t)
    (let ((directory (directory-fixture-directory fixture))
          (empty (d:crea-directory-get-serie (directory-fixture-view fixture) #())))
      (dolist (id '(0 1 16 17 18 #xfffffffe #xffffffff))
        (is (null (d::contiene-segmento-directory-get empty id)))
        (is (eq (not (null (member id '(17 #xffffffff))))
                (d::contiene-segmento-directory-get directory id))))
      (is (null (directory-read-events fixture)))
      (is (directory-check-clean fixture)))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-series-get-contains-65536-geometry-search17
  (with-directory-fixture (fixture :cache-p nil :observe-io-p t)
    ;; Geometria soltanto: 65.536 capacita' sintetiche condividono UN FD nativo.
    ;; Non certifica CLOSED, letture di record, frontiere o 65.536 file reali.
    (let ((maps (make-array 65536 :initial-element nil)))
      (dotimes (i 65536)
        (setf (svref maps i) (directory-fi-segment-map fixture 0 (if (= i 65535) #xffffffff (1+ (* 2 i))))))
      (let ((directory (d:crea-directory-get-serie (directory-fixture-view fixture) maps
                                                 :max-segments 65536 :budget-payload 786432)))
        ;; Il primo ID usa tutti i diciassette pivot; ultimo e miss coprono entrambi i confronti.
        (dolist (id '(1 65535 131069 #xffffffff))
          (is (d::contiene-segmento-directory-get directory id)))
        (dolist (id '(0 2 65536 131070 #xfffffffe))
          (is (null (d::contiene-segmento-directory-get directory id))))
        (is (= 65536 (d:conta-segmenti-directory-get directory)))
        (is (null (directory-read-events fixture)))
        (is (directory-check-clean fixture))))))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-CCH-002
(deftest test-REQ-CON-004-series-get-buffer-required-five-outcomes-and-restart
  (dolist (active-p '(nil t))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((directory (directory-series-fixture-directory fixture))
              (key (if active-p (directory-series-fixture-active-key fixture)
                       (aref (directory-fixture-keys directory) 0)))
              (value (if active-p (directory-series-fixture-active-value fixture)
                         (aref (directory-fixture-values directory) 0)))
              (controller (directory-series-fixture-controller fixture)))
         (is (eq :candidate (directory-series-begin fixture key)))
         (is (eq :buffer-required (d:sonda-cache-serie-get (directory-series-context fixture) controller)))
         (is (equal '(:buffer-required :not-attempted :not-attempted nil nil)
                    (multiple-value-list (d:leggi-record-serie-get (directory-series-context fixture) controller))))
         (is (eq :candidate (g:stato-contesto-get (directory-series-context fixture))))
         (is (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs directory) 0)))
         (is (directory-output-untouched-p directory))
         (is (null (directory-read-events directory)))
         (g:abbandona-get (directory-series-context fixture))
         (is (directory-check-clean directory))
         ;; Solo richiesta/chiave attraversano il riavvio; nuovo buffer e nuovo lookup/pin.
         (setf (aref (directory-fixture-contexts directory) 1)
               (g:crea-contesto-get (directory-fixture-scope directory) 1 :record-bytes 56 :budget-payload 208))
         (is (eq :candidate (directory-series-begin fixture key 1)))
         (is (equal '(:segment :disabled :not-attempted nil nil)
                    (multiple-value-list (d:leggi-record-serie-get (directory-series-context fixture 1) controller))))
         (directory-series-copy-and-finish fixture value 1)))
     :active-p active-p :record-bytes 55)))

;;; REQ: REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-series-get-directory-geometry-reader-faulted
  (dolist (operation '(:resolve :probe :read))
    (dolist (mode '(:maps :oversize))
      (call-with-directory-series-fixture
       (lambda (fixture)
         (let* ((directory (directory-series-fixture-directory fixture))
                (sources (d:crea-fonti-get-serie (directory-series-fi-directory-geometry fixture mode))))
           ;; FI pubblicata via writer generico: ACTIVE 13, CLOSED 17; nessun duplicato maschera la geometria.
           (directory-series-publish
            fixture (directory-series-stage fixture (directory-series-fixture-active-key fixture)
                                             (directory-series-fixture-active-value fixture)
                                             :sources sources :checked-p nil))
           (is (eq :candidate (directory-begin directory)))
           (signals invariant-violation
             (directory-series-operation operation (directory-series-context fixture)
                                          (directory-series-fixture-controller fixture)) :directory-shape)
           ;; Il catch del reader rende GET terminale prima del cleanup, senza mutare il writer.
           (is (directory-check-clean directory 0 :faulted))
           (is (directory-output-untouched-p directory))
           (is (null (directory-read-events directory)))
           (is (eq :healthy (arcdocdb.series:stato-controllore-serie
                             (directory-series-fixture-controller fixture))))))
       :active-p t :publish-active-p nil))))

;;; REQ: REQ-WAL-005 REQ-IDX-001 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-series-get-directory-geometry-writer-archive-faulted
  (dolist (mode '(:maps :oversize))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((directory (directory-series-fixture-directory fixture))
              (batch (directory-series-seal fixture (directory-series-fixture-active-key fixture)
                                             (directory-series-fixture-active-value fixture)))
              (token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto batch)))
              (bytes (copy-seq (arcdocdb.wal::lotto-buffer batch)))
              (sources (d:crea-fonti-get-serie (directory-series-fi-directory-geometry fixture mode))))
         (signals invariant-violation
           (d:registra-lotto-fonti-get-attivo
            (directory-series-fixture-source fixture) (directory-series-fixture-lease fixture)
            batch nil sources :strong) :directory-shape)
         ;; Obbligo ancora al caller: nessuna adozione/annullamento implicito su fault Archivio.
         (directory-series-check-refused-batch fixture batch token bytes :health :faulted :fault-scope :archive)
         (signals arcdocdb.conditions:io-fault
           (arcdocdb.series:leggi-radice-serie (directory-series-fixture-controller fixture)) :serie-faulted)
         (is (directory-check-clean directory))
         (is (directory-output-untouched-p directory))
         (is (null (directory-read-events directory)))))
     :active-p t :publish-active-p nil)))

;;; REQ: REQ-WAL-006 REQ-CCH-002 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-legacy-active-adapters-native
  (dolist (version '(1 2))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let ((context (directory-series-context fixture))
             (directory (directory-series-fixture-directory fixture))
             (source (directory-series-fixture-source fixture)))
         (dolist (operation '(:resolve :probe :read))
           (is (eq :candidate (directory-series-begin fixture (directory-series-fixture-active-key fixture))))
           (directory-series-observe-acquire
            fixture
            (lambda ()
              (ecase operation
                (:resolve (is (equal (list (r::sorgente-get-attiva-segment source) 176 0 nil)
                                     (multiple-value-list (r:risolvi-candidato-attivo-get context source)))))
                (:probe (is (eq :disabled (r:sonda-cache-attiva-get context source))))
                (:read (is (equal '(:segment :disabled :not-attempted nil nil)
                                  (multiple-value-list (r:leggi-record-attivo-get context source))))))))
           (if (eq operation :read)
               (directory-series-copy-and-finish fixture (directory-series-fixture-active-value fixture))
               (g:abbandona-get context))
           (is (directory-check-clean directory))
           (is (equal (if (eq operation :read) '((13 64 56)) nil) (directory-read-events directory)))
           (directory-clear-read-events directory))))
     :active-p t :version version)))

;;; REQ: REQ-WAL-006 REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-WAL-006-series-get-legacy-active-invalid-root-faulted
  (dolist (mode '(:nil :fonti :other-source))
    (call-with-directory-series-fixture
     (lambda (fixture)
       (let* ((context (directory-series-context fixture))
              (source (directory-series-fixture-source fixture))
              (bad (ecase mode
                     (:nil nil) (:fonti (directory-series-fixture-sources fixture))
                     (:other-source (directory-series-fi-root-with-segment fixture
                                     (r::sorgente-get-attiva-segment source))))))
         (is (eq :candidate (directory-series-begin fixture (directory-series-fixture-active-key fixture))))
         (directory-series-function-fi
          'arcdocdb.series:leggi-radice-serie
          (lambda (original) (declare (ignore original)) (lambda (controller) (declare (ignore controller)) bad))
          (lambda () (signals invariant-violation (r:risolvi-candidato-attivo-get context source)
                              :active-published-root)))
         (is (directory-check-clean (directory-series-fixture-directory fixture) 0 :faulted))
         (is (null (directory-read-events (directory-series-fixture-directory fixture))))))
     :active-p t)))

;;; REQ: REQ-CMP-007 REQ-AFF-004 REQ-WAL-006
(deftest test-REQ-CMP-007-series-get-active-owner-before-faulted-controller
  (call-with-directory-series-fixture
   (lambda (source-fixture)
     (arcdocdb.series:fault-controllore-serie (directory-series-fixture-controller source-fixture)
                                            (directory-series-fixture-lease source-fixture))
     (call-with-directory-series-fixture
      (lambda (reader-fixture)
        (dolist (explicit-p '(nil t))
          (is (eq :candidate (directory-begin (directory-series-fixture-directory reader-fixture))))
          (directory-series-observe-acquire
           source-fixture
           (lambda ()
             (signals invalid-argument
               (if explicit-p
                   (r:risolvi-candidato-radice-attiva-get (directory-series-context reader-fixture)
                                                        (directory-series-fixture-root source-fixture))
                   (r:risolvi-candidato-attivo-get (directory-series-context reader-fixture)
                                                  (directory-series-fixture-source source-fixture)))
               :active-source-owner)) :expected 0)
          (is (directory-check-clean (directory-series-fixture-directory reader-fixture)))))))
   :active-p t))

;;; REQ: REQ-WAL-006 REQ-FOR-004 REQ-AFF-004
(deftest test-REQ-WAL-006-series-get-active-unexpected-proof-faulted
  (call-with-directory-series-fixture
   (lambda (fixture)
     (let* ((context (directory-series-context fixture)) (root (directory-series-fixture-root fixture))
            (source (directory-series-fixture-source fixture)))
       (is (eq :candidate (directory-series-begin fixture (directory-series-fixture-active-key fixture))))
       (let* ((page (r::pagina-attiva context root 0)) (rows (copy-seq (r::mappa-segmento-get-rows page))))
         ;; FI tipizzata: mappa prepared in una radice che il writer sano costruisce solo ordinaria.
         ;; Il guasto deve essere rilevato prima di leggere il falso OUTCOME o consegnare byte.
         (setf (aref rows r::+row-flags+) 1 (aref rows r::+row-proof+) 120)
         (multiple-value-bind (directory nodes)
             (r::appendi-pagina-attiva nil 0 (r::%make-mappa-segmento-get (r::sorgente-get-attiva-segment source)
                                                                      176 rows) r::+active-directory-shift+)
           (let ((bad (r::%make-radice-get-attiva source directory 1 1 nodes 176
                                                (directory-series-fixture-sources fixture))))
             (directory-series-function-fi
              'arcdocdb.series:leggi-radice-serie
              (lambda (original) (declare (ignore original)) (lambda (controller) (declare (ignore controller)) bad))
              (lambda () (signals invariant-violation (r:risolvi-candidato-attivo-get context source)
                                  :active-unexpected-proof))))))
       (is (directory-check-clean (directory-series-fixture-directory fixture) 0 :faulted))
       (is (null (directory-read-events (directory-series-fixture-directory fixture))))))
   :active-p t))
