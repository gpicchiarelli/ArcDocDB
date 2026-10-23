;;;; Adozione ACTIVE dopo piano ACR reale; preparazione pubblica su FD nativi v1/v2.
;;; OWNER: ACR possiede le fonti recovery; CT/RP possiede root 0700, FD e cleanup.
;;; SHARED: runner seriale, backend osservato nuovo per fixture; nessuna FI globale.
;;; Limiti: 30 s per fixture CT, 4096 byte/file; nessun worker o prova di CAS conteso.
;;; Decisione catalogo assunta dalla fixture; finestra adozione senza EDIT/replay/ammissione.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun rba-case (version maximum thunk &key (series (rbt-series maximum)))
  "Runtime esclusivamente da ACR-PLAN; namespace nuovo posseduto dai helper nativi CT."
  (a::acr-with-fixture
   (lambda (f)
     (let ((runtime (rbt-check f (rbt-create (rbt-plan f)) maximum)))
       (ct::rp-run
        (lambda (native deadline)
          (funcall thunk f runtime native deadline)))
       (a::acr-noeffects f)))
   :version version :series series))

(defun rba-header (number version id &optional (origin 1))
  "Header indipendente dal buffer prodotto: packing e CRC bitwise CT qualificati."
  (let ((header (ct::control-reference-header (a::acr-identity number) version t)))
    (setf (aref header 10) origin)
    (ct::crr-pack header 32 id 8) (ct::crr-pack header 40 17 8)
    (ct::crr-pack header 56 (ct::crr-crc header 0 56) 4)
    header))

(defun rba-active (native deadline runtime version id &optional scope (number 1))
  "Nessun wrapper fabbricato: vista e ACTIVE nuovi dalle rispettive API pubbliche."
  (let* ((view (a::acr-view number (or scope (r:ambito-runtime-archivio runtime))))
         (directory (ct::native-open native (ct::native-fixture-root native) :directory deadline))
         (prepared (ct::native-active native directory (ct::native-fixture-root native)
                                     view id version deadline)))
    (let ((input (g::segmento-get-file (arcdocdb.active::segmento-attivo-preparato-segment prepared))))
      (a::acn-readonly input)
      (ct::native-read-bytes input (rba-header number version id) deadline))
    (values prepared view)))

(defun rba-noio (native deadline runtime thunk)
  "Finestra senza callback; osservazioni POSIX fuori dai contatori di prodotto."
  (let ((before (ct::rp-observations native))
        (frontiers (multiple-value-list (csn:leggi-frontiere-csn (r:csn-runtime-archivio runtime))))
        (snapshots (multiple-value-list
                    (mvcc:leggi-registro-snapshot (r:snapshot-runtime-archivio runtime))))
        (epochs (multiple-value-list (ebr:leggi-registro-epoche (r:epoche-runtime-archivio runtime)))))
    (ct::native-reset-calls native)
    (multiple-value-prog1 (ct::native-bounded deadline :runtime-active-adoption thunk)
      (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer native))))
      (is (equal before (ct::rp-observations native)))
      (is (equal frontiers (multiple-value-list
                           (csn:leggi-frontiere-csn (r:csn-runtime-archivio runtime)))))
      (is (equal snapshots (multiple-value-list
                           (mvcc:leggi-registro-snapshot (r:snapshot-runtime-archivio runtime)))))
      (is (equal epochs (multiple-value-list
                        (ebr:leggi-registro-epoche (r:epoche-runtime-archivio runtime))))))))

(defun rba-check-controller (runtime prepared controller capacity)
  "Identita interne in sola lettura; root, binding e salute da query pubbliche."
  (let ((log (arcdocdb.active:log-segmento-attivo-preparato prepared)))
    (is (typep controller 'arcdocdb.series:controllore-serie))
    (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
    (is (eq :healthy (arcdocdb.series:stato-controllore-serie controller)))
    (is (eq log (arcdocdb.series::controllore-serie-log controller)))
    (is (eq (r:csn-runtime-archivio runtime)
            (arcdocdb.series::controllore-serie-registry controller)))
    (is (null (arcdocdb.series:leggi-radice-serie controller)))
    (is (null (arcdocdb.series::controllore-serie-planned-root controller)))
    (is (= 64 (arcdocdb.series::controllore-serie-next-offset controller)))
    (is (= capacity (length (arcdocdb.series::controllore-serie-slots controller))))
    (is (null (arcdocdb.series::controllore-serie-owner controller)))
    (is (zerop (arcdocdb.series::controllore-serie-lease-generation controller)))
    (is (zerop (arcdocdb.series::controllore-serie-count controller)))
    (is (zerop (arcdocdb.series::controllore-serie-unresolved controller)))
    (is (zerop (arcdocdb.series::controllore-serie-active-io controller)))
    controller))

;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-CON-002 REQ-WAL-006 REQ-AFF-008
(deftest test-REQ-MVC-006-runtime-adoption-native-v1-v2-default-singleton-noeffects
  (dolist (version '(1 2))
    (rba-case version #x12345678ffffffff
      (lambda (f runtime native deadline)
        (let* ((prepared (rba-active native deadline runtime version 13))
               (log (arcdocdb.active:log-segmento-attivo-preparato prepared)))
          (rba-noio native deadline runtime
            (lambda ()
              (is (null (arcdocdb.series:trova-controllore-serie log)))
              (is (eq log (r::verifica-adozione-active runtime prepared)))
              (is (null (arcdocdb.series:trova-controllore-serie log)))
              (let ((controller (r:adotta-controllore-active runtime prepared)))
                (rba-check-controller runtime prepared controller 64)
                (signals invalid-argument
                  (r:adotta-controllore-active runtime prepared) :serie-log-bound)
                (signals invalid-argument
                  (arcdocdb.series:crea-controllore-serie
                   (r:csn-runtime-archivio runtime) log :capacity 1 :next-offset 64)
                  :serie-log-bound)
                (rba-check-controller runtime prepared controller 64))))
          (a::acr-noeffects f))))))

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-MVC-008
(deftest test-REQ-AFF-008-runtime-adoption-capacity-preflight-no-partial-binding
  (rba-case 2 23
    (lambda (f runtime native deadline)
      (let* ((prepared (rba-active native deadline runtime 2 13))
             (log (arcdocdb.active:log-segmento-attivo-preparato prepared)))
        (rba-noio native deadline runtime
          (lambda ()
            (dolist (bad (list -1 0 1025 nil t 1/2 1.0 "1" #()))
              (a::acr-expect 'invalid-argument :serie-budget
                (lambda () (rbt-invoke 'r:adotta-controllore-active runtime prepared :capacity bad)))
              (is (null (arcdocdb.series:trova-controllore-serie log))))
            (rba-check-controller runtime prepared
              (r:adotta-controllore-active runtime prepared :capacity 1) 1)))
        (a::acr-noeffects f)))))

(defun rba-reject (native deadline runtime prepared type reason)
  "Entrambi gli ingressi rifiutano prima del binding, senza callback o token CSN."
  (let ((log (arcdocdb.active:log-segmento-attivo-preparato prepared)))
    (rba-noio native deadline runtime
      (lambda ()
        (is (null (arcdocdb.series:trova-controllore-serie log)))
        (a::acr-expect type reason (lambda () (r::verifica-adozione-active runtime prepared)))
        (is (null (arcdocdb.series:trova-controllore-serie log)))
        (a::acr-expect type reason (lambda () (r:adotta-controllore-active runtime prepared)))
        (is (null (arcdocdb.series:trova-controllore-serie log)))))))

;;; REQ: REQ-MVC-005 REQ-CMP-007 REQ-AFF-008
(deftest test-REQ-MVC-005-runtime-adoption-exact-scope-even-same-csn-and-epochs
  (dolist (version '(1 2))
    (dolist (kind '(:recovery :clone))
      (rba-case version 23
        (lambda (f runtime native deadline)
          (let* ((scope (r:ambito-runtime-archivio runtime))
                 (foreign (ecase kind
                            (:recovery (a::acr-fixture-scope f))
                            (:clone (g:crea-ambito-get (r:epoche-runtime-archivio runtime)
                                                      (r:snapshot-runtime-archivio runtime)))))
                 (prepared (rba-active native deadline runtime version 13 foreign)))
            (is (not (eq scope foreign)))
            (when (eq kind :clone)
              (is (eq (r:csn-runtime-archivio runtime)
                      (mvcc::registro-snapshot-csns (g::ambito-get-snapshots foreign)))))
            (rba-reject native deadline runtime prepared 'invalid-argument :runtime-active-scope)
            (let ((valid (rba-active native deadline runtime version 14)))
              (rba-noio native deadline runtime
                (lambda ()
                  (rba-check-controller runtime valid
                    (r:adotta-controllore-active runtime valid :capacity 1) 1))))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-STO-003
(deftest test-REQ-AFF-008-runtime-adoption-closed-readonly-or-append-no-binding
  (dolist (version '(1 2))
    (dolist (mode '(:input :append))
      (rba-case version 23
        (lambda (f runtime native deadline)
          (declare (ignore f))
          (let* ((prepared (rba-active native deadline runtime version 13))
                 (log (arcdocdb.active:log-segmento-attivo-preparato prepared))
                 (file (ecase mode
                         (:input (g::segmento-get-file
                                  (arcdocdb.active::segmento-attivo-preparato-segment prepared)))
                         (:append (arcdocdb.wal::log-io-file log)))))
            (ct::native-bounded deadline :runtime-active-close (lambda () (io:chiudi file)))
            (is (eq :closed (io:stato-file file)))
            (rba-reject native deadline runtime prepared 'arcdocdb.conditions:io-fault :io-unavailable)
            (let ((valid (rba-active native deadline runtime version 14)))
              (rba-noio native deadline runtime
                (lambda ()
                  (rba-check-controller runtime valid
                    (r:adotta-controllore-active runtime valid :capacity 1) 1))))))))))

;;; REQ: REQ-WAL-006 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-008-runtime-adoption-advanced-written-and-durable-refused
  (dolist (version '(1 2))
    (dolist (flush '(nil t))
      (rba-case version 23
        (lambda (f runtime native deadline)
          (declare (ignore f))
          (let* ((prepared (rba-active native deadline runtime version 13))
                 (append (arcdocdb.wal::log-io-file
                          (arcdocdb.active:log-segmento-attivo-preparato prepared))))
            (ct::native-bounded deadline :runtime-active-advance
              (lambda ()
                (is (= 65 (io:append-esatto append (ct::crr-bytes 1 #xee) 0 1)))
                (when flush (is (= 65 (io:durable-flush append))))))
            (is (= 65 (io:posizione-scritta append)))
            (is (= (if flush 65 64) (io:posizione-durevole append)))
            (rba-reject native deadline runtime prepared 'invalid-argument :runtime-active-started)
            (let ((valid (rba-active native deadline runtime version 14)))
              (rba-noio native deadline runtime
                (lambda ()
                  (rba-check-controller runtime valid
                    (r:adotta-controllore-active runtime valid :capacity 1) 1))))))))))

;;; REQ: REQ-FOR-001 REQ-STO-003 REQ-AFF-008
(deftest test-REQ-AFF-008-runtime-adoption-exact-file-capabilities-not-inode-only
  (dolist (version '(1 2))
    (rba-case version 23
      (lambda (f runtime native deadline)
        (declare (ignore f))
        (multiple-value-bind (prepared view) (rba-active native deadline runtime version 13)
          (let* ((log (arcdocdb.active:log-segmento-attivo-preparato prepared))
                 (segment (arcdocdb.active::segmento-attivo-preparato-segment prepared))
                 (association (arcdocdb.active::segmento-attivo-preparato-association prepared))
                 (alias (ct::native-open native
                          (merge-pathnames "active-13.tmp" (ct::native-fixture-root native))
                          :input deadline))
                 (alias-segment (ct::native-bounded deadline :runtime-active-alias-header
                                  (lambda () (g:crea-segmento-get view alias 13 (ct::crr-bytes 64)))))
                 (other (rba-active native deadline runtime version 14))
                 (other-log (arcdocdb.wal:crea-log-io
                             (arcdocdb.wal::log-io-file
                              (arcdocdb.active:log-segmento-attivo-preparato other))
                             :segment 13 :version version)))
            (is (not (eq alias (g::segmento-get-file segment))))
            (is (equal (ct::native-identity alias)
                       (ct::native-identity (g::segmento-get-file segment))))
            ;; FI locale: combina solo capacita pubbliche; nessun campo readonly viene mutato.
            (dolist (bad (list (arcdocdb.active::%make-segmento-attivo-preparato
                               log alias-segment association)
                              (arcdocdb.active::%make-segmento-attivo-preparato
                               other-log segment association)))
              (rba-reject native deadline runtime bad 'invalid-argument :io-association-capability))
            ;; Il log canonico originale resta adottabile dopo entrambi i rifiuti.
            (rba-noio native deadline runtime
              (lambda ()
                (rba-check-controller runtime prepared
                  (r:adotta-controllore-active runtime prepared :capacity 1) 1)))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-AFF-008-runtime-adoption-log-id-version-and-kind-preflight
  (dolist (version '(1 2))
    (rba-case version 23
      (lambda (f runtime native deadline)
        (declare (ignore f))
        (let* ((prepared (rba-active native deadline runtime version 13))
               (log (arcdocdb.active:log-segmento-attivo-preparato prepared))
               (append (arcdocdb.wal::log-io-file log))
               (segment (arcdocdb.active::segmento-attivo-preparato-segment prepared))
               (association (arcdocdb.active::segmento-attivo-preparato-association prepared)))
          (dolist (facts (list (list :segment 14 version)
                              (list :segment #x10000000d version)
                              (list :segment 13 (- 3 version))
                              (list :control 0 version) (list :multiserie 0 version)))
            (destructuring-bind (kind id format) facts
              ;; FI sul wrapper esterno; log e segmento derivano da API pubbliche.
              (let* ((wrong-log (arcdocdb.wal:crea-log-io append kind id :version format))
                     (bad (arcdocdb.active::%make-segmento-attivo-preparato
                           wrong-log segment association)))
                (rba-reject native deadline runtime bad
                  (if (eq kind :segment) 'invariant-violation 'invalid-argument)
                  (if (eq kind :segment) :runtime-active-identity :log-segment-kind)))))
          (rba-noio native deadline runtime
            (lambda ()
              (is (null (arcdocdb.series:trova-controllore-serie log)))
              (rba-check-controller runtime prepared
                (r:adotta-controllore-active runtime prepared :capacity 1) 1))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-AFF-008-runtime-adoption-real-compaction-header-is-not-writer
  (dolist (version '(1 2))
    (rba-case version 23
      (lambda (f runtime native deadline)
        (declare (ignore f))
        (let ((view (a::acr-view 1 (r:ambito-runtime-archivio runtime))))
          (multiple-value-bind (input append)
              (ct::rp-seed native (ct::native-fixture-root native) "compaction-13.tmp"
                           (rba-header 1 version 13 2) deadline)
            (let* ((segment (ct::native-bounded deadline :runtime-compaction-header
                              (lambda () (g:crea-segmento-get view input 13 (ct::crr-bytes 64)))))
                   (log (arcdocdb.wal:crea-log-io append :segment 13 :version version))
                   (association (ct::native-bounded deadline :runtime-compaction-association
                                  (lambda () (io:associa-file input append))))
                   ;; Wrapper negativo locale; header compaction realmente letto e verificato.
                   (bad (arcdocdb.active::%make-segmento-attivo-preparato log segment association)))
              (is (= 2 (g::segmento-get-origin segment)))
              (rba-reject native deadline runtime bad 'invariant-violation :runtime-active-identity))))
        (let ((valid (rba-active native deadline runtime version 14)))
          (rba-noio native deadline runtime
            (lambda ()
              (rba-check-controller runtime valid
                (r:adotta-controllore-active runtime valid :capacity 1) 1))))))))

;;; REQ: REQ-WAL-006 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-runtime-adoption-faulted-log-no-partial-binding
  (dolist (version '(1 2))
    (rba-case version 23
      (lambda (f runtime native deadline)
        (declare (ignore f))
        (let* ((prepared (rba-active native deadline runtime version 13))
               (log (arcdocdb.active:log-segmento-attivo-preparato prepared)))
          (arcdocdb.wal:marca-log-faulted log)
          (rba-reject native deadline runtime prepared 'arcdocdb.conditions:io-fault :log-faulted)
          (let ((valid (rba-active native deadline runtime version 14)))
            (rba-noio native deadline runtime
              (lambda ()
                (rba-check-controller runtime valid
                  (r:adotta-controllore-active runtime valid :capacity 1) 1)))))))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008
(deftest test-REQ-CON-002-runtime-adoption-refuses-log-already-bound-by-generic-factory
  (rba-case 2 23
    (lambda (f runtime native deadline)
      (declare (ignore f))
      (let* ((prepared (rba-active native deadline runtime 2 13))
             (log (arcdocdb.active:log-segmento-attivo-preparato prepared))
             (root (vector :generic-root)))
        (rba-noio native deadline runtime
          (lambda ()
            (is (null (arcdocdb.series:trova-controllore-serie log)))
            (let ((controller (arcdocdb.series:crea-controllore-serie
                               (r:csn-runtime-archivio runtime) log
                               :capacity 2 :root root :next-offset 64)))
              (signals invalid-argument (r:adotta-controllore-active runtime prepared) :serie-log-bound)
              (is (eq controller (arcdocdb.series:trova-controllore-serie log)))
              (is (eq root (arcdocdb.series:leggi-radice-serie controller)))
              (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
              (is (= 2 (length (arcdocdb.series::controllore-serie-slots controller))))
              (is (null (arcdocdb.series::controllore-serie-owner controller)))
              (is (zerop (arcdocdb.series::controllore-serie-lease-generation controller))))))))))

(defun rba-frontiers (runtime latest horizon)
  (is (equal (list (ldb (byte 32 32) latest) (ldb (byte 32 0) latest)
                   (ldb (byte 32 32) horizon) (ldb (byte 32 0) horizon))
             (multiple-value-list (csn:leggi-frontiere-csn (r:csn-runtime-archivio runtime))))))

(defun rba-start (prepared view controller)
  "Lease esplicita dopo l'adozione; fonti GET e root iniziale pubblicate separatamente."
  (let ((lease (arcdocdb.series:acquisisci-controllore-serie controller)) (complete nil))
    (unwind-protect
         (let* ((source (arcdocdb.active:crea-sorgente-get-preparata
                         controller lease prepared :max-pages 2 :max-puts 2
                         :batch-records 1 :batch-bytes 512 :budget-payload 2048))
                (directory (arcdocdb.get.directory:crea-directory-get-serie
                            view #() :max-segments 1 :budget-payload 0))
                (sources (arcdocdb.get.directory:crea-fonti-get-serie directory))
                (root (arcdocdb.get.directory:inizializza-fonti-get-attive source lease sources)))
           (is (eq root (arcdocdb.series:leggi-radice-serie controller)))
           (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
           (is (eq sources (arcdocdb.get.resolver:contenuto-radice-get-attiva root)))
           (is (= 64 (arcdocdb.get.resolver::radice-get-attiva-end root)))
           (is (zerop (arcdocdb.get.resolver::radice-get-attiva-count root)))
           (is (zerop (arcdocdb.get.directory:conta-segmenti-directory-get directory)))
           (is (equal '(0 0 0) (multiple-value-list
                               (arcdocdb.series:conta-commit-serie controller lease))))
           (prog1 (list prepared view controller lease source sources root) (setf complete t)))
      (unless complete (arcdocdb.series:rilascia-controllore-serie controller lease)))))

(defun rba-publish-index (view key value id stamp)
  "Location dichiarata a offset 64, pubblicata dopo il CAS della root; stesso ordine C4 verticale."
  (let* ((primary (g::vista-get-serie-primary view))
         (words (make-array 5 :element-type '(unsigned-byte 64)
                  :initial-contents (list stamp (logior (ash id 32) 64)
                                          (logior (ash (length key) 32) (ash 1 48))
                                          (+ 24 (length key) (length value)) 0))))
    (multiple-value-bind (high low) (p:digest-chiave-indice primary key 0 (length key))
      (p:pubblica-chiave-indice primary (p:frammento-corrente-indice primary high)
                               key 0 (length key) high low words (p:crea-contesto-indice)))))

(defun rba-commit (runtime entry deadline version number id expected)
  "Primo lotto reale: M+1 nel token, poi written, durable, root e H; oracolo file bytewise."
  (destructuring-bind (prepared view controller lease source sources previous) entry
    (let* ((log (arcdocdb.active:log-segmento-attivo-preparato prepared))
           (append (arcdocdb.wal::log-io-file log))
           (input (g::segmento-get-file (arcdocdb.active::segmento-attivo-preparato-segment prepared)))
           (key (ct::crr-bytes 16 number)) (value (ct::crr-bytes 1 number))
           (record (arcdocdb.recovery.active.checkpoint.tests::ra-encode-record
                    (cd::cdr-record :put expected :key key :value value) version))
           (image (ct::crr-cat (rba-header number version id) record
                              (cd::cdr-seal (list record) 64 64 expected version id)))
           (end (length image))
           (batch (arcdocdb.wal:crea-lotto :segment id :version version :capacity 512 :max-records 1)))
      (arcdocdb.wal:aggiungi-record batch 1 key value)
      (is (= 1 (arcdocdb.get.resolver:verifica-capienza-get-attiva source lease batch previous)))
      (rba-frontiers runtime (1- expected) (1- expected))
      (multiple-value-bind (size high low)
          (arcdocdb.wal:sigilla-lotto-con-csn batch (r:csn-runtime-archivio runtime) log 64 64)
        (is (= (- end 64) size))
        (is (= expected (logior (ash high 32) low))))
      (rba-frontiers runtime expected (1- expected))
      (multiple-value-bind (event generation root)
          (arcdocdb.get.directory:registra-lotto-fonti-get-attivo
           source lease batch previous sources :group)
        (is (not (eq root previous)))
        (is (eq root (arcdocdb.series::controllore-serie-planned-root controller)))
        (is (= end (arcdocdb.get.resolver::radice-get-attiva-end root)))
        (is (eq sources (arcdocdb.get.resolver:contenuto-radice-get-attiva root)))
        (is (eq previous (arcdocdb.series:leggi-radice-serie controller)))
        (let ((group (arcdocdb.wal:crea-gruppo log :max-lots 1 :max-bytes 512)))
          (arcdocdb.series:inizia-io-commit-serie controller lease event generation)
          (arcdocdb.wal:aggiungi-lotto group batch) (arcdocdb.wal:chiudi-gruppo group)
          (is (= end (arcdocdb.wal:scrivi-gruppo group)))
          (is (eq :written (arcdocdb.wal:stato-lotto batch)))
          (is (= end (io:posizione-scritta append)))
          (is (= 64 (io:posizione-durevole append)))
          (signals invalid-argument
            (arcdocdb.series:pubblica-commit-serie controller lease event generation) :lotto-not-covered)
          (is (eq previous (arcdocdb.series:leggi-radice-serie controller)))
          (rba-frontiers runtime expected (1- expected))
          (is (= end (arcdocdb.wal:sincronizza-gruppo group)))
          (is (eq :durable (arcdocdb.wal:stato-lotto batch)))
          (is (= end (io:posizione-durevole append)))
          (is (eq previous (arcdocdb.series:leggi-radice-serie controller)))
          (rba-frontiers runtime expected (1- expected))
          (multiple-value-bind (status high low)
              (arcdocdb.series:pubblica-commit-serie controller lease event generation)
            (is (eq :risolto status)) (is (= expected (logior (ash high 32) low))))
          (is (eq root (arcdocdb.series:leggi-radice-serie controller)))
          (rba-frontiers runtime expected expected)
          (rba-publish-index view key value id expected)
          (ct::native-read-bytes input image deadline)
          (arcdocdb.series:completa-io-commit-serie controller lease event generation)
          (arcdocdb.wal:riusa-gruppo group)
          (arcdocdb.series:riusa-commit-serie controller lease event generation)
          (is (equal '(0 0 0) (multiple-value-list
                              (arcdocdb.series:conta-commit-serie controller lease))))
          (is (eq root (arcdocdb.series:leggi-radice-serie controller))))))))

(defun rba-get (runtime entry number snapshot generation now)
  "Lo stesso snapshot e lo stesso worker EBR leggono due Serie del runtime canonico."
  (destructuring-bind (prepared view controller lease source sources previous) entry
    (declare (ignore prepared lease source sources previous))
    (let* ((context (g:crea-contesto-get (r:ambito-runtime-archivio runtime) 0
                                        :record-bytes 128 :budget-payload 280))
           (epoch (ebr:contesto-epoca (r:epoche-runtime-archivio runtime) 0))
           (output (ct::crr-bytes 5 #xee)))
      (unwind-protect
           (progn
             (is (eq :candidate (g:avvia-get context view (ct::crr-bytes 16 number)
                                            snapshot generation now)))
             (is (ebr:epoca-attiva-p epoch))
             (is (equal '(:segment :disabled :not-attempted nil nil)
                        (multiple-value-list
                         (arcdocdb.get.directory:leggi-record-serie-get context controller))))
             (is (= 3 (g:copia-valore-get context output 2)))
             (is (equalp (ct::crr-bytes 1 number) (subseq output 2 3)))
             (is (every (lambda (byte) (= byte #xee)) (subseq output 0 2)))
             (is (every (lambda (byte) (= byte #xee)) (subseq output 3)))
             (is (ebr:epoca-attiva-p epoch))
             (is (equal '(:found 1) (multiple-value-list (g:concludi-get context (1+ now)))))
             (is (eq :idle (g:stato-contesto-get context)))
             (is (not (ebr:epoca-attiva-p epoch))))
        (g:abbandona-get context)))))

;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-008 REQ-WAL-006 REQ-IDX-001
(deftest test-REQ-MVC-008-runtime-adoption-native-first-commit-and-common-snapshot-two-series
  (dolist (version '(1 2))
    (let ((maximum #x12345678ffffffff))
      (rba-case version maximum
        (lambda (f runtime native deadline)
          (let ((entries nil) (snapshot nil) (generation 0))
            (unwind-protect
                 (progn
                   (loop for number from 1 to 2 for id from 13 to 14
                         do (multiple-value-bind (prepared view)
                                (rba-active native deadline runtime version id nil number)
                              (let ((controller
                                      (rba-noio native deadline runtime
                                        (lambda ()
                                          (rba-check-controller runtime prepared
                                            (r:adotta-controllore-active runtime prepared :capacity 2) 2)))))
                                (rba-noio native deadline runtime
                                  (lambda () (push (rba-start prepared view controller) entries))))))
                   (setf entries (nreverse entries))
                   (loop for entry in entries for number from 1 for id from 13
                         do (ct::native-bounded deadline :runtime-active-first-commit
                              (lambda () (rba-commit runtime entry deadline version number id
                                                     (+ maximum number)))))
                   (rba-frontiers runtime (+ maximum 2) (+ maximum 2))
                   (setf snapshot (mvcc:crea-contesto-snapshot (r:snapshot-runtime-archivio runtime)))
                   (multiple-value-bind (identity captured ready) (mvcc:registra-snapshot snapshot 10)
                     (setf generation identity)
                     (is (= (+ maximum 2) captured)) (is ready))
                   (is (mvcc:snapshot-del-registro-p snapshot (r:snapshot-runtime-archivio runtime)))
                   (loop for entry in entries for number from 1 for now from 11 by 2
                         do (ct::native-bounded deadline :runtime-active-snapshot-get
                              (lambda () (rba-get runtime entry number snapshot generation now))))
                   (is (= (+ maximum 2) (mvcc:verifica-snapshot snapshot generation 15)))
                   (loop for entry in entries for number from 1 for now from 16 by 2
                         do (ct::native-bounded deadline :runtime-active-current-get
                              (lambda () (rba-get runtime entry number nil 0 now))))
                   (a::acr-noeffects f))
              (when (plusp generation) (mvcc:termina-snapshot snapshot generation))
              (dolist (entry entries)
                (arcdocdb.series:rilascia-controllore-serie (third entry) (fourth entry))))))
        :series (append (rbt-series maximum) (list (a::acr-serie 2)))))))
