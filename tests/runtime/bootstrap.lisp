;;;; Runtime: base recuperata, unicita canonica, configurazione e letture integrate.
;;; OWNER: runner seriale; solo piani pubblici immutabili ottenuti da replay reali.
;;; SHARED: fixture con <=4 Serie, <=4 CLOSED/Serie e 4096 byte/file; nessun thread.
;;; Limiti: nessuna prova di scheduling CAS concorrente o misura delle allocazioni.
;;; Le guardie del piano non vengono forzate alterando piani readonly o primitive CL.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-007 REQ-AFF-008
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-006 REQ-MVC-008
(deftest test-REQ-MVC-006-RUNTIME-assenza-e-zero-osservato-primo-csn-uno
  (dolist (version '(1 2))
    (dolist (present '(nil t))
      (a::acr-with-fixture
       (lambda (f)
         (let ((plan (rbt-plan f)))
           (is (equal (list present 0) (multiple-value-list (ac:massimo-csn-archivio plan))))
           (is (null (r:trova-runtime-archivio (a::acr-fixture-archive f))))
           (rbt-first (rbt-check f (rbt-create plan) 0) 0)
           (a::acr-noeffects f)))
       :version version :series (if present (rbt-series 0) (list (a::acr-serie 1)))))))

;;; REQ: REQ-MVC-006 REQ-TXM-005 REQ-STO-006
(deftest test-REQ-MVC-006-RUNTIME-piu-serie-decision-o-closed-dominanti
  (dolist (version '(1 2))
    (dolist (facts '((#x200000009 17 #x200000009) (11 #x300000007 #x300000007)))
      (destructuring-bind (decision closed maximum) facts
        (a::acr-with-fixture
         (lambda (f)
           (let ((plan (rbt-plan f)))
             (is (equal '(3 4) (multiple-value-list (ac:statistiche-piano-csn-archivio plan))))
             (rbt-first (rbt-check f (rbt-create plan) maximum) maximum)
             (a::acr-noeffects f)))
         :version version :registri 1
         :series (append (rbt-series 7)
                         (list (a::acr-serie 2)
                               (a::acr-serie 3 :closed
                                 (list (a::acr-closed 7 :origin 2
                                         :records (list (cd::cdr-record :tombstone closed)))))))
         :decisions (list (a::acrp-decision 101 decision)))))))

;;; REQ: REQ-MVC-006 REQ-MVC-008
(deftest test-REQ-MVC-006-RUNTIME-riporto-u32-e-bit-alti
  (dolist (version '(1 2))
    (dolist (maximum '(#xffffffff #x12345678ffffffff #x80000000ffffffff))
      (a::acr-with-fixture
       (lambda (f)
         (rbt-first (rbt-check f (rbt-create (rbt-plan f)) maximum) maximum)
         (a::acr-noeffects f))
       :version version :series (rbt-series maximum)))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-008-RUNTIME-limite-u64-nessun-wrap-o-mutazione-su-esaurimento
  (dolist (version '(1 2))
    (dolist (maximum '(#xfffffffffffffffe #xffffffffffffffff))
      (a::acr-with-fixture
       (lambda (f)
         (let* ((runtime (rbt-check f (rbt-create (rbt-plan f) :csn-capacity 1) maximum))
                (registry (r:csn-runtime-archivio runtime)))
           (when (< maximum #xffffffffffffffff) (rbt-first runtime maximum))
           (dotimes (attempt 2)
             (let ((before (multiple-value-list (csn:leggi-frontiere-csn registry))))
               (a::acr-expect 'resource-exhausted :csn-exhausted (lambda () (csn:prendi-csn registry)) nil)
               (is (equal before (multiple-value-list (csn:leggi-frontiere-csn registry))))))
           (a::acr-noeffects f)))
       :version version :series (rbt-series maximum)))))

;;; REQ: REQ-MVC-005 REQ-AFF-008
(deftest test-REQ-MVC-005-RUNTIME-doppio-avvio-stesso-piano-o-piano-distinto-rifiutato
  (a::acr-with-fixture
   (lambda (f)
     (let* ((first (rbt-plan f)) (second (rbt-plan f))
            (runtime (rbt-check f (rbt-create first) 0)))
       (is (not (eq first second)))
       (dolist (plan (list first second))
         (a::acr-expect 'invalid-argument :archive-runtime-bound (lambda () (rbt-create plan)) nil)
         (rbt-check f runtime 0))
       (rbt-first runtime 0)
       (a::acr-noeffects f)))))

;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-MVC-005-RUNTIME-archivi-distinti-stesso-uuid-indipendenti
  (a::acr-with-fixture
   (lambda (left)
     (a::acr-with-fixture
      (lambda (right)
        (let* ((left-plan (rbt-plan left)) (right-plan (rbt-plan right))
               (left-runtime (rbt-check left (rbt-create left-plan) 0)))
          (is (not (eq (a::acr-fixture-archive left) (a::acr-fixture-archive right))))
          (is (null (r:trova-runtime-archivio (a::acr-fixture-archive right))))
          (let ((right-runtime (rbt-check right (rbt-create right-plan) 17)))
            (is (not (eq left-runtime right-runtime)))
            (is (not (eq (r:csn-runtime-archivio left-runtime) (r:csn-runtime-archivio right-runtime))))
            (is (not (eq (r:ambito-runtime-archivio left-runtime) (r:ambito-runtime-archivio right-runtime))))
            (rbt-first left-runtime 0)
            (rbt-check right right-runtime 17)
            (rbt-first right-runtime 17)
            (a::acr-noeffects left) (a::acr-noeffects right))))
      :series (rbt-series 17)))))

;;; REQ: REQ-AFF-008 REQ-CON-004 REQ-MVC-005
(deftest test-REQ-AFF-008-RUNTIME-capacita-invalide-prima-del-binding-poi-successo
  (a::acr-with-fixture
   (lambda (f)
     (let ((plan (rbt-plan f)))
       (dolist (entry '((:csn-capacity 65536) (:snapshot-capacity 65536)
                        (:worker-capacity 4096) (:retirement-capacity 65536)))
         (destructuring-bind (key maximum) entry
           (dolist (bad (list -1 0 (1+ maximum) nil t 1/2 1.0 "1" #()))
             (rbt-reject f (lambda () (rbt-create plan key bad))))))
       (rbt-check f (rbt-create plan :csn-capacity 1 :snapshot-capacity 1
                                     :worker-capacity 1 :retirement-capacity 1) 0)))))

;;; REQ: REQ-AFF-008 REQ-MVC-007 REQ-MVC-005
(deftest test-REQ-AFF-008-RUNTIME-tick-invalidi-prima-del-binding-poi-successo
  (a::acr-with-fixture
   (lambda (f)
     (let ((plan (rbt-plan f)))
       (dolist (bad (list -1 0 #x10000000000000000 nil t 1/2 1.0 "1" #()))
         (rbt-reject f (lambda () (rbt-invoke 'r:crea-runtime-archivio plan bad 1)))
         (rbt-reject f (lambda () (rbt-invoke 'r:crea-runtime-archivio plan 20 bad))))
       (rbt-reject f (lambda () (r:crea-runtime-archivio plan 4 5)))
       (rbt-check f (r:crea-runtime-archivio plan 1 1 :csn-capacity 1 :snapshot-capacity 1
                                                   :worker-capacity 1 :retirement-capacity 1) 0)))))

;;; REQ: REQ-AFF-008 REQ-CON-004 REQ-MVC-005 REQ-MVC-006
(deftest test-REQ-AFF-008-RUNTIME-quattro-capacita-massime-simultanee
  (a::acr-with-fixture
   (lambda (f)
     (let* ((plan (rbt-plan f))
            (runtime (rbt-check f (rbt-create plan :csn-capacity 65536 :snapshot-capacity 65536
                                                  :worker-capacity 4096 :retirement-capacity 65536) 0))
            (epochs (r:epoche-runtime-archivio runtime)))
       (is (equal '(nil 0) (multiple-value-list (ac:massimo-csn-archivio plan))))
       (is (not (ebr:epoca-attiva-p (ebr:contesto-epoca epochs 4095))))
       (a::acr-expect 'invalid-argument :epoch-worker-range (lambda () (ebr:contesto-epoca epochs 4096)) nil)
       (rbt-first runtime 0)
       (a::acr-noeffects f)))))

;;; REQ: REQ-AFF-008 REQ-MVC-005
(deftest test-REQ-AFF-008-RUNTIME-tipi-piano-e-getter-errati-senza-binding-parziale
  (a::acr-with-fixture
   (lambda (f)
     (let ((plan (rbt-plan f)))
       (dolist (bad (list nil 0 #() (a::acr-fixture-archive f)))
         (a::acr-expect 'type-error nil (lambda () (rbt-invoke 'r:crea-runtime-archivio bad 20 5)))
         (is (null (r:trova-runtime-archivio (a::acr-fixture-archive f)))))
       (let ((runtime (rbt-check f (rbt-create plan) 0)))
         (dolist (bad (list nil 0 #() plan (a::acr-fixture-archive f)))
           (dolist (name '(r:csn-runtime-archivio r:ambito-runtime-archivio
                          r:snapshot-runtime-archivio r:epoche-runtime-archivio))
             (a::acr-expect 'type-error nil (lambda () (rbt-invoke name bad)))))
         (dolist (bad (list nil 0 #() plan runtime))
           (a::acr-expect 'type-error nil (lambda () (rbt-invoke 'r:trova-runtime-archivio bad))))
         (rbt-check f runtime 0))))))

;;; REQ: REQ-AFF-008 REQ-MVC-007
(deftest test-REQ-MVC-007-RUNTIME-durate-massime-u64-valide
  (a::acr-with-fixture
   (lambda (f)
     (let* ((runtime (rbt-check f (r:crea-runtime-archivio (rbt-plan f)
                                    #xffffffffffffffff #xffffffffffffffff) 0))
            (context (mvcc:crea-contesto-snapshot (r:snapshot-runtime-archivio runtime))))
       (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot context 0)
         (unwind-protect
              (progn (is (= 1 generation)) (is (zerop csn)) (is ready)
                     (is (zerop (mvcc:verifica-snapshot context generation 1))))
           (mvcc:termina-snapshot context generation)))
       (a::acr-noeffects f)))))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-AFF-002
(deftest test-REQ-REC-001-RUNTIME-piano-chiuso-fonti-chiuse-nessuna-rilettura
  (dolist (version '(1 2))
    (a::acr-with-fixture
     (lambda (f)
       (let ((plan (rbt-plan f)))
         (dolist (input (a::acr-fixture-inputs f)) (is (null (io:chiudi input))))
         (a::acr-clear f)
         (fill (a::acr-fixture-active f) nil)
         (loop for sources across (a::acr-fixture-closed f) do (fill sources nil))
         (fill (a::acr-fixture-closed f) nil)
         (fill (a::acr-fixture-controls f) nil)
         (rbt-first (rbt-check f (rbt-create plan) 23) 23)
         (a::acr-noeffects f)))
     :version version :series (rbt-series 23))))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-MVC-008
(deftest test-REQ-MVC-007-RUNTIME-snapshot-cattura-csn-canonico-attende-orizzonte
  (a::acr-with-fixture
   (lambda (f)
     (let* ((runtime (rbt-check f (rbt-create (rbt-plan f)) 7))
            (registry (r:snapshot-runtime-archivio runtime))
            (first (mvcc:crea-contesto-snapshot registry))
            (second (mvcc:crea-contesto-snapshot registry)) (g1 0) (g2 0))
       (unwind-protect
            (progn
              (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot first 10)
                (setf g1 generation) (is (= 1 generation)) (is (= 7 csn)) (is ready))
              (multiple-value-bind (slot high low) (csn:prendi-csn (r:csn-runtime-archivio runtime))
                (is (equal '(0 8) (list high low)))
                (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot second 11)
                  (setf g2 generation) (is (= 2 generation)) (is (= 8 csn)) (is (null ready)))
                (is (not (mvcc:attiva-snapshot second g2 12)))
                (is (equal '(0 8) (multiple-value-list
                                   (csn:risolvi-csn (r:csn-runtime-archivio runtime) slot high low))))
                (is (mvcc:attiva-snapshot second g2 13)))
              (is (= 7 (mvcc:verifica-snapshot first g1 14)))
              (is (= 8 (mvcc:verifica-snapshot second g2 14)))
              (is (= 7 (mvcc:soglia-snapshot registry)))
              (mvcc:termina-snapshot first g1)
              (is (= 8 (mvcc:soglia-snapshot registry)))
              (a::acr-noeffects f))
         (when (plusp g2) (mvcc:termina-snapshot second g2))
         (when (plusp g1) (mvcc:termina-snapshot first g1)))))
   :series (rbt-series 7)))

;;; REQ: REQ-MVC-005 REQ-MVC-007 REQ-IDX-001 REQ-MVC-004 REQ-FOR-004
(deftest test-REQ-MVC-005-RUNTIME-get-corrente-e-snapshot-legami-e-byte-coerenti
  (dolist (version '(1 2))
    (a::acr-with-fixture
     (lambda (f)
       (let* ((runtime (rbt-check f (rbt-create (rbt-plan f)) 7))
              (target (rbt-get-target f runtime))
              (snapshot (mvcc:crea-contesto-snapshot (r:snapshot-runtime-archivio runtime))))
         (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot snapshot 10)
           (unwind-protect
                (progn
                  (is (= 7 csn)) (is ready)
                  (is (mvcc:snapshot-del-registro-p snapshot (r:snapshot-runtime-archivio runtime)))
                  (rbt-get-read f runtime target snapshot generation)
                  (is (= 7 (mvcc:verifica-snapshot snapshot generation 14)))
                  (rbt-first runtime 7)
                  (is (= 7 (mvcc:verifica-snapshot snapshot generation 15))))
             (mvcc:termina-snapshot snapshot generation)))
         (rbt-get-read f runtime target nil 0 :now 16)
         (a::acr-noeffects f)))
     :version version :series (rbt-series 7))))

;;; REQ: REQ-MVC-005 REQ-CON-004 REQ-CMP-007
(deftest test-REQ-MVC-005-RUNTIME-get-rifiuta-vista-e-snapshot-del-bootstrap-senza-pin
  (a::acr-with-fixture
   (lambda (f)
     (let* ((runtime (rbt-check f (rbt-create (rbt-plan f)) 7))
            (target (rbt-get-target f runtime)) (context (rbt-get-context target))
            (epoch (ebr:contesto-epoca (r:epoche-runtime-archivio runtime) 0))
            (foreign (mvcc:crea-contesto-snapshot
                       (g::ambito-get-snapshots (a::acr-fixture-scope f)))))
       (unwind-protect
            (progn
              (a::acr-expect 'invalid-argument :get-archive-owner
                (lambda () (g:avvia-get context (aref (a::acr-fixture-views f) 0)
                                       (rbt-get-key target) nil 0 11)) nil)
              (is (not (ebr:epoca-attiva-p epoch)))
              (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot foreign 12)
                (unwind-protect
                     (progn
                       (is (zerop csn)) (is ready)
                       (a::acr-expect 'invalid-argument :read-snapshot-identity
                         (lambda () (g:avvia-get context (rbt-get-view target) (rbt-get-key target)
                                                foreign generation 13)) nil))
                  (mvcc:termina-snapshot foreign generation)))
              (is (eq :idle (g:stato-contesto-get context)))
              (is (not (ebr:epoca-attiva-p epoch)))
              (a::acr-noeffects f)
              (rbt-get-read f runtime target nil 0 :now 14))
         (g:abbandona-get context))))
   :series (rbt-series 7)))
