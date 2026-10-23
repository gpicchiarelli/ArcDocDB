;;;; Aggregazione, provenienza e lifetime del piano CSN Archivio: ACR-D06/07/08/09.
;;; OWNER: runner seriale; il supporto possiede file, viste e token reali fino al cleanup.
;;; SHARED: nessuna FI globale, costruzione privata di wrapper o modifica dei sorgenti.
;;; Limiti: matrici finite v1/v2, quattro Serie, 4096 byte/file e budget del supporto.
;;; Il ramo P incompatibile con lo stesso CONTROL immutabile resta alle FI del file guards.
;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(in-package #:arcdocdb.recovery.archive.csn.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun acrp-uuid< (left right)
  "Ordine lessicografico indipendente dei sedici byte dichiarati dalla fixture."
  (loop for i below 16
        when (/= (aref left i) (aref right i))
          do (return-from acrp-uuid< (< (aref left i) (aref right i))))
  nil)

(defun acrp-decision (txid csn &optional (participants '(81 82)))
  "Partecipanti distinti e ordinati prima del packing bytewise comune."
  (rt::decision-spec txid csn (sort (mapcar #'acr-identity participants) #'acrp-uuid<)))

(defun acrp-check (plan expected series segments)
  "Oracoli scalari espliciti: presenza, massimo, cardinalita e parole dell'ultimo CSN."
  (is (typep plan 'ac:piano-csn-archivio))
  (is (equal expected (multiple-value-list (ac:massimo-csn-archivio plan))))
  (is (equal (list series segments)
             (multiple-value-list (ac:statistiche-piano-csn-archivio plan))))
  (is (equal (list (ldb (byte 32 32) (second expected)) (ldb (byte 32 0) (second expected)))
             (multiple-value-list (ac:parole-base-csn-archivio plan)))))

(defun acrp-success (f expected series segments &rest options)
  "Il piano e le query non devono aggiungere I/O o modificare le immagini della fixture."
  (acr-clear f)
  (let ((plan (apply #'acr-plan f options)))
    (acrp-check plan expected series segments)
    (acr-noeffects f)
    plan))

(defun acrp-plan (f &key (set (acr-fixture-set f)) (decisions (acr-fixture-decisions f))
                        (active (acr-fixture-active f)) (closed (acr-fixture-closed f)))
  "Vettori alternativi del caller; nessuna modifica dei token o dei vettori canonici."
  (ac:crea-piano-csn-archivio set decisions active closed))

;;; ACR-D09: nessuna fonte distinta dal valore zero realmente osservato.
;;; REQ: REQ-REC-001 REQ-MVC-006
(deftest test-REQ-MVC-006-ACR-D09-assenza-contro-zero-in-ogni-fonte
  (dolist (version '(1 2))
    (dolist (source '(:nessuna :decision :active :closed-writer :closed-compaction :edit))
      (let* ((closed (case source
                       (:closed-writer (list (acr-closed 2 :batches (list (cd::cdr-batch 0 (cd::cdr-record :put 0))))))
                       (:closed-compaction (list (acr-closed 2 :origin 2 :records (list (cd::cdr-record :tombstone 0)))))
                       (:edit (list (acr-closed 2 :outcomes '((99 0)))))
                       (otherwise nil)))
             (series (list (acr-serie 1 :active (when (eq source :active)
                                                (list (cd::cdr-batch 0 (cd::cdr-record :put 0))))
                                       :closed closed))))
        (acr-with-fixture
         (lambda (f)
           (acrp-success f (if (eq source :nessuna) '(nil 0) '(t 0)) 1 (if closed 2 1)))
         :version version :series series
         :decisions (when (eq source :decision) (list (acrp-decision #xffffffffffffffff 0))))))))

;;; ACR-D08/09: il massimo puo provenire da DECISION, ACTIVE o CLOSED, in qualsiasi ordine.
;;; REQ: REQ-MVC-006 REQ-TXM-005 REQ-STO-006
(deftest test-REQ-MVC-006-ACR-D08-massimo-log-e-serie-maggiore-minore-uguale
  (dolist (version '(1 2))
    (dolist (facts '((0 0 0 0) (17 3 5 17) (3 17 5 17) (3 5 17 17) (17 17 17 17)
                     (#x100000001 7 9 #x100000001)
                     (7 #x8000000000000001 9 #x8000000000000001)
                     (7 9 #xffffffffffffffff #xffffffffffffffff)
                     (#xffffffffffffffff 9 7 #xffffffffffffffff)))
      (destructuring-bind (decision active closed expected) facts
        (let ((series (list (acr-serie 1 :active (list (cd::cdr-batch active (cd::cdr-record :put active))))
                            (acr-serie 2 :closed (list (acr-closed 2 :origin 2
                                                        :records (list (cd::cdr-record :tombstone closed))))))))
          (dolist (order (list series (reverse series)))
            (acr-with-fixture
             (lambda (f) (acrp-success f (list t expected) 2 3))
             :version version :series order :decisions (list (acrp-decision 99 decision)))))))))

;;; ACR-D08/09: stamp prepared e TXID DECISION sono identificativi, non CSN.
;;; REQ: REQ-MVC-006 REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-MVC-006-ACR-D09-txid-alti-non-diventano-csn
  (dolist (version '(1 2))
    (dolist (csn '(0 #x100000001 #x8000000000000001))
      (acr-with-fixture
       (lambda (f)
         (acrp-success f (list t csn) 1 1)
         (is (equal '(1 1 1 0 0 1)
                    (multiple-value-list
                     (arcdocdb.recovery.active:statistiche-active-recuperato (aref (acr-fixture-active f) 0)))))
         (acr-noeffects f))
       :version version
       :series (list (acr-serie 1 :active (list (cd::cdr-batch 0 (cd::cdr-record :prepared-put #xffffffffffffffff)))))
       :decisions (list (acrp-decision #xfffffffffffffffe csn))))))

;;; ACR-D08: una DECISION contribuisce anche senza partecipanti o prepared locali.
;;; REQ: REQ-MVC-006 REQ-TXM-005
(deftest test-REQ-MVC-006-ACR-D08-decisioni-orfane-ordine-txid-csn-indipendente
  (dolist (version '(1 2))
    (let ((decisions (list (acrp-decision #xffffffffffffffff 0)
                            (acrp-decision 0 #xffffffffffffffff)
                            (acrp-decision #x8000000000000001 #x100000001))))
      (dolist (order (list decisions (reverse decisions) (append (rest decisions) (list (first decisions)))))
        (acr-with-fixture
         (lambda (f)
           (acrp-success f '(t #xffffffffffffffff) 2 2)
           (is (= 3 (da:numero-decisioni-recuperate (acr-fixture-decisions f))))
           (dolist (txid '(0 #x8000000000000001 #xffffffffffffffff))
             (dolist (number '(1 2))
               (is (not (da:partecipante-decisione-recuperata-p
                         (acr-fixture-decisions f) txid (acr-identity number) 0 16)))))
           (acr-noeffects f))
         :version version :series (list (acr-serie 1) (acr-serie 2)) :decisions order)))))

;;; ACR-D08/09: le code contengono cornici integre con CSN maggiore, senza SEAL nuovo.
;;; REQ: REQ-MVC-006 REQ-REC-001 REQ-TXM-005 REQ-STO-006
(deftest test-REQ-MVC-006-ACR-D08-code-decision-active-closed-escluse
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (decision-tail '(nil t))
        (dolist (active-tail '(nil t))
          (dolist (closed-tail '(nil t))
            (let* ((record-tail (rac::ra-encode-record (cd::cdr-record :put #xffffffffffffffff) version))
                   (closed (acr-closed 2 :origin origin
                                       :batches (when (= origin 1) (list (cd::cdr-batch 7 (cd::cdr-record :put 7))))
                                       :records (when (= origin 2) (list (cd::cdr-record :put 7)))
                                       :tail (when closed-tail record-tail))))
              (acr-with-fixture
               (lambda (f)
                 (acrp-success f '(t 7) 1 2)
                 (is (eq (if decision-tail :tail :complete)
                         (nth-value 2 (da:frontiere-decisioni-recuperate (acr-fixture-decisions f)))))
                 (is (eq (if active-tail :tail :complete)
                         (nth-value 2 (arcdocdb.recovery.active:frontiere-active-recuperato
                                       (aref (acr-fixture-active f) 0)))))
                 (acr-noeffects f))
               :version version :decisions (list (acrp-decision 17 7))
               :decision-tail (when decision-tail
                                (rt::reference-decision-record (acrp-decision 99 #xffffffffffffffff) version))
               :series (list (acr-serie 1 :active (list (cd::cdr-batch 7 (cd::cdr-record :tombstone 7)))
                                         :tail (when active-tail record-tail) :closed (list closed)))))))))))

;;; ACR-D08/09: SEAL prepared-only ed EDIT orfani restano fonti, anche senza versioni ordinarie.
;;; REQ: REQ-MVC-006 REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-MVC-006-ACR-D09-seal-ed-edit-orfani-con-bit-alti
  (dolist (version '(1 2))
    (dolist (facts '((#xffffffffffffffff 0 0 #xffffffffffffffff)
                     (0 #xffffffffffffffff 0 #xffffffffffffffff)
                     (0 0 #xffffffffffffffff #xffffffffffffffff)
                     (#x100000001 0 #x8000000000000001 #x8000000000000001)))
      (destructuring-bind (active-csn writer-edit compact-edit expected) facts
        (acr-with-fixture
         (lambda (f) (acrp-success f (list t expected) 2 4))
         :version version
         :series (list
                  (acr-serie 1 :active (list (cd::cdr-batch active-csn (cd::cdr-record :prepared-put #xffffffffffffffff)))
                               :closed (list (acr-closed 2 :outcomes (list (list 77 writer-edit)))))
                  (acr-serie 2 :closed (list (acr-closed 2 :origin 2 :outcomes (list (list 88 compact-edit)))))))))))

;;; ACR-D06: due replay reali degli stessi byte hanno marker distinti, anche su ACTIVE vuoto.
;;; REQ: REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-replay-distinto-stessi-byte-active-vuoto-o-prepared
  (dolist (version '(1 2))
    (dolist (prepared '(nil t))
      (dolist (has-decision '(nil t))
        (acr-with-fixture
         (lambda (f)
           (let* ((replay (acr-replay f))
                  (reread (acr-read-active f 0 (acr-fixture-decisions f)))
                  (foreign (acr-read-active f 0 replay))
                  (expected (cond (has-decision '(t 7)) (prepared '(t 0)) (t '(nil 0)))))
             (is (not (eq replay (acr-fixture-decisions f))))
             (acr-clear f)
             (acrp-check (acrp-plan f :active (vector reread)) expected 1 1)
             (acr-expect 'invalid-argument :archive-csn-active-decision-source
                         (lambda () (acrp-plan f :decisions replay)))
             (acr-expect 'invalid-argument :archive-csn-active-decision-source
                         (lambda () (acrp-plan f :active (vector foreign))))
             (acrp-check (acrp-plan f :decisions replay :active (vector foreign)) expected 1 1)
             (acr-noeffects f)))
         :version version :decisions (when has-decision (list (acrp-decision 77 7)))
         :series (list (acr-serie 1 :active (when prepared
                                            (list (cd::cdr-batch 0 (cd::cdr-record :prepared-tombstone 99)))))))))))

;;; ACR-D06: stesso UUID e stesso ambito non sostituiscono l'identita EQ della vista.
;;; REQ: REQ-TXM-005 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-vista-clone-stesso-uuid-stesso-ambito
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((view (acr-view 1 (acr-fixture-scope f)))
              (control (acr-read-control f 0 view))
              (active (acr-read-active f 0 (acr-fixture-decisions f) control))
              (set (ac:crea-insieme-serie-recovery (acr-fixture-archive f) view (vector view))))
         (is (not (eq view (aref (acr-fixture-views f) 0))))
         (acr-clear f)
         (acr-expect 'invalid-argument :archive-csn-active-view
                     (lambda () (acrp-plan f :active (vector active))))
         (acr-expect 'invalid-argument :archive-csn-active-view
                     (lambda () (acrp-plan f :set set)))
         (acrp-check (acrp-plan f :set set :active (vector active)) '(nil 0) 1 1)
         (acr-noeffects f)))
     :version version)))

;;; ACR-D07: anche una Serie successiva priva del massimo deve superare il gate completo.
;;; REQ: REQ-MVC-006 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-STO-006-ACR-D07-closed-mancanti-extra-duplicati-in-serie-successiva
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((entries (aref (acr-fixture-closed f) 1)) (a (aref entries 0)) (b (aref entries 1)))
         (acr-clear f)
         (dolist (bad (list #() (vector a) (vector b) (vector a b a)))
           (let ((closed (copy-seq (acr-fixture-closed f))))
             (setf (aref closed 1) bad)
             (acr-expect 'invalid-argument :closed-recovery-set-count
                         (lambda () (acrp-plan f :closed closed)) nil)))
         (dolist (bad (list (vector a a) (vector b b)))
           (let ((closed (copy-seq (acr-fixture-closed f))))
             (setf (aref closed 1) bad)
             (acr-expect 'invalid-argument :closed-recovery-set-duplicate
                         (lambda () (acrp-plan f :closed closed)) nil)))
         (let ((closed (copy-seq (acr-fixture-closed f))))
           (setf (aref closed 1) (vector b a))
           (acrp-check (acrp-plan f :closed closed) '(t #xffffffffffffffff) 2 4))
         (acr-noeffects f)))
     :version version :series (list (acr-serie 1)
                                   (acr-serie 2 :closed (list (acr-closed 2) (acr-closed 7 :origin 2))))
     :decisions (list (acrp-decision 99 #xffffffffffffffff)))))

;;; ACR-D07: decodificare ancora gli stessi byte produce un'altra autorita CONTROL.
;;; REQ: REQ-STO-006 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-STO-006-ACR-D07-closed-altro-control-stessi-byte-e-p
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((control (acr-read-control f 0))
              (foreign (acr-read-closed f 0 0 control))
              (canonical (acr-read-closed f 0 0))
              (active (acr-read-active f 0 (acr-fixture-decisions f) control)))
         (is (not (eq control (aref (acr-fixture-controls f) 0))))
         (is (equal (multiple-value-list (cr:frontiere-closed-recuperato canonical))
                    (multiple-value-list (cr:frontiere-closed-recuperato foreign))))
         (acr-clear f)
         (acr-expect 'invalid-argument :closed-recovery-set-control
                     (lambda () (acrp-plan f :closed (vector (vector foreign)))) nil)
         (acr-expect 'invalid-argument :closed-recovery-set-control
                     (lambda () (acrp-plan f :active (vector active))) nil)
         (acrp-check (acrp-plan f :closed (vector (vector canonical))) '(nil 0) 1 2)
         (acrp-check (acrp-plan f :active (vector active) :closed (vector (vector foreign))) '(nil 0) 1 2)
         (acr-noeffects f)))
     :version version :series (list (acr-serie 1 :closed (list (acr-closed 2)))))))

;;; ACR-D07: tutte le capacita restano necessarie, anche con massimo DECISION dominante.
;;; REQ: REQ-MVC-006 REQ-STO-006 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-AFF-008-ACR-D07-fd-decision-active-control-closed-chiusi
  (dolist (version '(1 2))
    (dolist (target '(:decision :active :control :closed))
      (acr-with-fixture
       (lambda (f)
         (acrp-success f '(t #xffffffffffffffff) 2 4)
         (acr-clear f)
         (io:chiudi (ecase target
                      (:decision (acr-fixture-decision-input f))
                      (:active (aref (acr-fixture-active-inputs f) 1))
                      (:control (aref (acr-fixture-control-inputs f) 1))
                      (:closed (aref (aref (acr-fixture-closed-inputs f) 1) 0))))
         (acr-clear f)
         (acr-expect 'io-fault :io-unavailable (lambda () (acr-plan f)) nil)
         (acr-noeffects f))
       :version version :series (list (acr-serie 1 :closed (list (acr-closed 2)))
                                     (acr-serie 2 :closed (list (acr-closed 2 :origin 2))))
       :decisions (list (acrp-decision 99 #xffffffffffffffff))))))

;;; Il piano consegnato conserva scalari: chiudere le fonti ne impedisce solo una nuova costruzione.
;;; REQ: REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-MVC-006-ACR-D09-piano-consegnato-interrogabile-dopo-chiusura-fonti
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((plan (acrp-success f '(t #xffffffffffffffff) 1 2)))
         (acr-clear f)
         (io:chiudi (acr-fixture-decision-input f))
         (io:chiudi (aref (acr-fixture-control-inputs f) 0))
         (io:chiudi (aref (acr-fixture-active-inputs f) 0))
         (io:chiudi (aref (aref (acr-fixture-closed-inputs f) 0) 0))
         (acr-clear f)
         (dotimes (repeat 2) (acrp-check plan '(t #xffffffffffffffff) 1 2))
         (acr-expect 'io-fault :io-unavailable (lambda () (acr-plan f)) nil)
         (acr-noeffects f)))
     :version version :series (list (acr-serie 1 :closed (list (acr-closed 2))))
     :decisions (list (acrp-decision 99 #xffffffffffffffff)))))

;;; ACR-D06: risultati validi per le rispettive Serie, ma ordine del vettore sbagliato.
;;; REQ: REQ-TXM-005 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-active-scambiati-o-ripetuti
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((a (aref (acr-fixture-active f) 0)) (b (aref (acr-fixture-active f) 1)))
         (acr-clear f)
         (dolist (bad (list (vector b a) (vector a a) (vector b b)))
           (acr-expect 'invalid-argument :archive-csn-active-view
                       (lambda () (acrp-plan f :active bad))))
         (acr-noeffects f)
         (acrp-success f '(t 7) 2 2)))
     :version version :series (list (acr-serie 1) (acr-serie 2))
     :decisions (list (acrp-decision 99 7)))))

;;; ACR-D06: un nuovo contesto Archivio con UUID uguale non e' l'autorita dell'insieme.
;;; REQ: REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-altro-archivio-stesso-uuid-replay-reale
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((archive (da:crea-archivio-recovery (acr-fixture-scope f) (acr-archive-id)))
              (replay (acr-replay f archive))
              (active (acr-read-active f 0 replay))
              (set (ac:crea-insieme-serie-recovery archive (acr-fixture-registri f) (acr-fixture-views f))))
         (is (not (eq archive (acr-fixture-archive f))))
         (acr-clear f)
         (acr-expect 'invalid-argument :archive-csn-decision-owner
                     (lambda () (acrp-plan f :decisions replay)))
         (acr-expect 'invalid-argument :archive-csn-decision-owner
                     (lambda () (acrp-plan f :set set)))
         (acr-expect 'invalid-argument :archive-csn-active-decision-source
                     (lambda () (acrp-plan f :set set :decisions replay)))
         (acrp-check (acrp-plan f :set set :decisions replay :active (vector active)) '(nil 0) 1 1)
         (acr-noeffects f)))
     :version version)))

;;; ACR-D09: code prive di SEAL non introducono neppure la presenza di un CSN su P64.
;;; REQ: REQ-MVC-006 REQ-REC-001 REQ-STO-006
(deftest test-REQ-MVC-006-ACR-D09-code-sole-non-creano-presenza-csn
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let ((tail (rac::ra-encode-record (cd::cdr-record :put #xffffffffffffffff) version)))
        (acr-with-fixture
         (lambda (f)
           (acrp-success f '(nil 0) 1 2)
           (is (= 64 (nth-value 1 (da:frontiere-decisioni-recuperate (acr-fixture-decisions f)))))
           (is (= 64 (nth-value 1 (arcdocdb.recovery.active:frontiere-active-recuperato
                                   (aref (acr-fixture-active f) 0)))))
           (is (= 64 (nth-value 1 (cr:frontiere-closed-recuperato
                                   (aref (aref (acr-fixture-closed f) 0) 0)))))
           (acr-noeffects f))
         :version version
         :decision-tail (rt::reference-decision-record (acrp-decision 0 #xffffffffffffffff) version)
         :series (list (acr-serie 1 :tail tail :closed (list (acr-closed 2 :origin origin :tail tail)))))))))

;;; ACR-D06: l'ingresso ACTIVE di basso livello non sostituisce l'autorita del replay Archivio.
;;; REQ: REQ-TXM-005 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-tabella-indipendente-low-level-active-vuoto
  (dolist (version '(1 2))
    (dolist (has-decision '(nil t))
      (let ((specs (when has-decision (list (acrp-decision 99 7)))))
        (acr-with-fixture
         (lambda (f)
           (let* ((bytes (aref (acr-fixture-active-bytes f) 0))
                  (table (av::av-decision-table specs version))
                  (active (arcdocdb.recovery.active:leggi-active-recuperato
                           (aref (acr-fixture-controls f) 0) (aref (acr-fixture-active-inputs f) 0)
                           (length bytes) table (ct::crr-bytes (length bytes)))))
             (acr-clear f)
             (acr-expect 'invalid-argument :archive-csn-active-decision-source
                         (lambda () (acrp-plan f :active (vector active))) nil)
             (acr-noeffects f)
             (acrp-success f (if has-decision '(t 7) '(nil 0)) 1 1)))
         :version version :decisions specs)))))

;;; ACR-D06: anche l'ambito di un altro Archivio e' distinto, pur con UUID del log uguale.
;;; REQ: REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-TXM-005-ACR-D06-altro-archivio-ambito-diverso
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (acr-with-fixture
        (lambda (other)
          (let ((replay (acr-replay f (acr-fixture-archive other))))
            (is (not (eq (acr-fixture-scope other) (acr-fixture-scope f))))
            (acr-clear f)
            (acr-expect 'invalid-argument :archive-csn-decision-owner
                        (lambda () (acrp-plan f :decisions replay)) nil)
            (acr-expect 'invalid-argument :active-recovery-archive
                        (lambda () (acr-read-active f 0 replay)) nil)
            (acr-noeffects f)
            (acr-noeffects other)))
        :version version))
     :version version)))
