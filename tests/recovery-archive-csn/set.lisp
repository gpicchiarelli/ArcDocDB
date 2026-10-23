;;;; Insieme canonico e preflight del piano CSN: fixture pubbliche, matrici finite v1/v2.
;;; OWNER: runner seriale; il supporto conserva Archivio, viste, replay e capacità readonly.
;;; SHARED: nessuna FI globale, nessun costruttore privato o mutazione di risultati di prodotto.
;;; Limiti: <=4 Serie, <=4 CLOSED/Serie, <=32 FD, <=4096 byte/file, <=65536 eventi.
;;; ACR-D01/02/03/04/05/11: confini indipendenti, copie dei vettori e nessun nuovo I/O.
;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(in-package #:arcdocdb.recovery.archive.csn.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun acrs-set (f views &rest options)
  (apply #'ac:crea-insieme-serie-recovery (acr-fixture-archive f) (acr-fixture-registri f) views options))

(defun acrs-build (f set active closed &rest options)
  (apply #'ac:crea-piano-csn-archivio set (acr-fixture-decisions f) active closed options))

(defun acrs-same-elements (expected actual)
  "Confronto per EQ: il chiamante conserva ordine e riferimenti del proprio vettore."
  (is (= (length expected) (length actual)))
  (is (every #'eq expected actual)))

(defun acrs-reject (f type reason thunk)
  "Il rifiuto non legge file, non modifica byte/frontiere e non chiude capacità."
  (let ((views (copy-seq (acr-fixture-views f)))
        (active (copy-seq (acr-fixture-active f)))
        (closed (copy-seq (acr-fixture-closed f)))
        (entries (map 'simple-vector #'copy-seq (acr-fixture-closed f)))
        (condition (acr-expect type reason thunk)))
    (unless (typep condition 'type-error) (is (null (arcdocdb.conditions:error-offset condition))))
    (acrs-same-elements views (acr-fixture-views f))
    (acrs-same-elements active (acr-fixture-active f))
    (acrs-same-elements closed (acr-fixture-closed f))
    (loop for before across entries for after across (acr-fixture-closed f)
          do (acrs-same-elements before after))
    (acr-noeffects f)
    condition))

(defun acrs-query (plan series segments)
  (is (typep plan 'ac:piano-csn-archivio))
  (is (equal (list series segments) (multiple-value-list (ac:statistiche-piano-csn-archivio plan)))))

(defun acrs-specs (count)
  (loop for number from 1 to count collect (acr-serie number :active nil :closed nil)))

(defun acrs-permute (vector order)
  (map 'simple-vector (lambda (index) (aref vector index)) order))

(defun acrs-close-sources (f)
  "Chiusure intenzionali del caller, soltanto dopo avere ottenuto il piano."
  (io:chiudi (acr-fixture-decision-input f))
  (loop for input across (acr-fixture-control-inputs f) do (io:chiudi input))
  (loop for input across (acr-fixture-active-inputs f) do (io:chiudi input))
  (loop for group across (acr-fixture-closed-inputs f)
        do (loop for input across group do (io:chiudi input)))
  (acr-clear f))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-ACR-D01-D02-exact-series-and-eight-N
  (dolist (version '(1 2))
    (dolist (count '(1 2 3 4))
      (acr-with-fixture
       (lambda (f)
         (let* ((views (copy-seq (acr-fixture-views f))) (before (copy-seq views))
                (set (acrs-set f views :max-series count :budget-riferimenti (* 8 count))))
           (is (typep set 'ac:insieme-serie-recovery))
           (is (= count (ac:numero-serie-recovery set)))
           (acrs-same-elements before views)
           (acrs-query (acrs-build f set (acr-fixture-active f) (acr-fixture-closed f)
                                   :max-segmenti-serie 0 :max-segmenti-totali count)
                       count count)
           (acr-noeffects f)))
       :version version :series (acrs-specs count)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-ACR-D02-empty-before-budgets
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dolist (options '(() (:max-series 0) (:budget-riferimenti 0)
                          (:max-series 0 :budget-riferimenti 0)))
         (acrs-reject f 'arcdocdb.conditions:invalid-argument :archive-csn-series-empty
                      (lambda () (apply #'acrs-set f #() options)))))
     :version version)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-ACR-D02-each-budget-false-independently
  (dolist (version '(1 2))
    (dolist (count '(1 2 3 4))
      (acr-with-fixture
       (lambda (f)
         (let ((views (copy-seq (acr-fixture-views f))))
           (dolist (budgets (list (list (1- count) (* 8 count))
                                  (list count (1- (* 8 count)))
                                  (list (1- count) (1- (* 8 count))) (list 0 0)))
             (destructuring-bind (series bytes) budgets
               (acrs-reject f 'arcdocdb.conditions:resource-exhausted :archive-csn-series-budget
                            (lambda () (acrs-set f views :max-series series :budget-riferimenti bytes)))))
           (acrs-same-elements (acr-fixture-views f) views)))
       :version version :series (acrs-specs count)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-ACR-D01-copy-guard-each-condition
  ;; FI locale dichiarata sui soli argomenti della guardia difensiva interna.
  ;; Archivio e viste sono pubblici; nessuna FDEFINITION o struttura viene alterata.
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((archive (acr-fixture-archive f)) (registri (acr-fixture-registri f))
             (views (acr-fixture-views f)))
         (dolist (case (list (list views 1 16) (list #() 0 0) (list views 2 15)))
           (destructuring-bind (vector count budget) case
             (acrs-reject f 'arcdocdb.conditions:invariant-violation :archive-csn-series-preflight
                          (lambda () (acr-invoke 'ac::copia-serie-recovery archive registri vector count budget)))))
         (let ((set (acrs-set f views :max-series 2 :budget-riferimenti 16)))
           (is (= 2 (ac:numero-serie-recovery set)))
           (acrs-query (acrs-build f set (acr-fixture-active f) (acr-fixture-closed f)) 2 2))
         (acr-noeffects f)))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-budgets-precede-invalid-elements
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dolist (options '((:max-series 0 :budget-riferimenti 8)
                          (:max-series 1 :budget-riferimenti 7)
                          (:max-series 0 :budget-riferimenti 7)))
         ;; NIL non è una vista: il budget deve rifiutare prima della visita degli elementi.
         (acrs-reject f 'resource-exhausted :archive-csn-series-budget
                      (lambda () (apply #'acrs-set f (vector nil) options))))
       (acrs-reject f 'type-error nil
                    (lambda () (acrs-set f (vector nil) :max-series 1 :budget-riferimenti 8))))
     :version version)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-SET-typed-arguments-and-elements
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((archive (acr-fixture-archive f)) (registri (acr-fixture-registri f))
             (views (acr-fixture-views f)))
         (dolist (key '(:max-series :budget-riferimenti))
           (dolist (value (list -1 nil 1/2 (1+ most-positive-fixnum)))
             (acrs-reject f 'type-error nil
                          (lambda () (acr-invoke 'ac:crea-insieme-serie-recovery archive registri views key value)))))
         (dolist (arguments (list (list nil registri views) (list archive nil views)
                                 (list archive registri nil) (list archive registri (coerce views 'list))
                                 (list archive registri (make-array 2 :adjustable t :initial-element registri))
                                 (list archive registri (make-array '(1 2) :initial-element registri))))
           (acrs-reject f 'type-error nil
                        (lambda () (apply #'acr-invoke 'ac:crea-insieme-serie-recovery arguments))))
         (dotimes (index 2)
           (let ((bad (copy-seq views)))
             (setf (aref bad index) 17)
             (acrs-reject f 'type-error nil (lambda () (acrs-set f bad)))))
         (acrs-reject f 'type-error nil (lambda () (acr-invoke 'ac:numero-serie-recovery nil)))))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D03-other-scope-in-each-position
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dotimes (index 4)
         (let* ((views (copy-seq (acr-fixture-views f)))
                (other (acr-view (1+ index))))
           (is (not (eq (g::vista-get-serie-scope other) (acr-fixture-scope f))))
           (is (equalp (g::vista-get-serie-identity other)
                       (g::vista-get-serie-identity (aref views index))))
           (setf (aref views index) other)
           (acrs-reject f 'invalid-argument :archive-csn-series-scope (lambda () (acrs-set f views)))))
       (acr-noeffects f))
     :version version :series (acrs-specs 4))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-ACR-D04-each-outer-cardinality
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((active (acr-fixture-active f)) (closed (acr-fixture-closed f)) (set (acr-fixture-set f)))
         (dolist (counts '((1 2) (3 2) (2 1) (2 3) (1 1) (3 3) (0 2) (2 0)))
           (destructuring-bind (na nc) counts
             (let ((as (make-array na :initial-element (aref active 0)))
                   (cs (make-array nc :initial-element (aref closed 0))))
               (acrs-reject f 'invalid-argument :archive-csn-recovery-count
                            (lambda () (acrs-build f set as cs))))))
         (acrs-query (acrs-build f set active closed :max-segmenti-serie 0 :max-segmenti-totali 2) 2 2)
         (acr-noeffects f)))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-PREFLIGHT-ACR-D04-exact-archive-object
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((clone (da:crea-archivio-recovery (acr-fixture-scope f) (acr-archive-id)))
              (replay (acr-replay f clone)))
         (is (not (eq clone (acr-fixture-archive f))))
         (is (equalp (da::archivio-recovery-identity clone)
                     (da::archivio-recovery-identity (acr-fixture-archive f))))
         (is (eq (da::archivio-recovery-scope clone) (acr-fixture-scope f)))
         (acr-clear f)
         (acrs-reject f 'invalid-argument :archive-csn-decision-owner
                      (lambda ()
                        (ac:crea-piano-csn-archivio (acr-fixture-set f) replay
                          (acr-fixture-active f) (acr-fixture-closed f))))
         ;; Autorità prima anche di count e budget errati, senza visitare i risultati.
         (acrs-reject f 'invalid-argument :archive-csn-decision-owner
                      (lambda ()
                        (ac:crea-piano-csn-archivio (acr-fixture-set f) replay #() #()
                          :max-segmenti-serie 0 :max-segmenti-totali 0)))
         (acrs-query (acr-plan f) 2 2)
         (acr-noeffects f)))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-typed-arguments-and-nested-vectors
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let ((set (acr-fixture-set f)) (decisions (acr-fixture-decisions f))
             (active (acr-fixture-active f)) (closed (acr-fixture-closed f)))
         (dolist (key '(:max-segmenti-serie :max-segmenti-totali))
           (dolist (value (list -1 nil 1/2 (1+ most-positive-fixnum)))
             (acrs-reject f 'type-error nil
                          (lambda () (acr-invoke 'ac:crea-piano-csn-archivio set decisions active closed key value)))))
         (dolist (arguments (list (list nil decisions active closed) (list set nil active closed)
                                 (list set decisions nil closed) (list set decisions active nil)
                                 (list set decisions (coerce active 'list) closed)
                                 (list set decisions active (coerce closed 'list))
                                 (list set decisions (make-array 2 :adjustable t) closed)
                                 (list set decisions active (make-array 2 :adjustable t))))
           (acrs-reject f 'type-error nil
                        (lambda () (apply #'acr-invoke 'ac:crea-piano-csn-archivio arguments))))
         (dotimes (index 2)
           (let ((as (copy-seq active)))
             (setf (aref as index) nil)
             (acrs-reject f 'type-error nil (lambda () (acrs-build f set as closed))))
           (dolist (bad (list nil '(nil) (make-array 0 :adjustable t)))
             (let ((cs (copy-seq closed)))
               (setf (aref cs index) bad)
               (acrs-reject f 'type-error nil (lambda () (acrs-build f set active cs))))))))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-ACR-D05-zero-closed-and-active-inclusive-total
  (dolist (version '(1 2))
    (dolist (count '(1 2 3 4))
      (acr-with-fixture
       (lambda (f)
         (dolist (total (list 0 (1- count)))
           (acrs-reject f 'resource-exhausted :archive-csn-segment-budget
                        (lambda () (acr-plan f :max-segmenti-serie 0 :max-segmenti-totali total))))
         (acrs-query (acr-plan f :max-segmenti-serie 0 :max-segmenti-totali count) count count)
         (acr-noeffects f))
       :version version :series (acrs-specs count)))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-ACR-D05-independent-local-and-global-budgets
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       ;; N=2, CLOSED=(2,1): totale esatto 5, massimo locale esatto 2.
       ;; (1,5) viola solo il locale; (2,3) solo il globale al primo gruppo;
       ;; (1,3) viola entrambi; (2,4) esaurisce il globale al secondo gruppo.
       (dolist (budgets '((1 5) (2 3) (1 3) (2 4) (0 5)))
         (destructuring-bind (per-series total) budgets
           (acrs-reject f 'resource-exhausted :archive-csn-segment-budget
                        (lambda () (acr-plan f :max-segmenti-serie per-series :max-segmenti-totali total)))))
       (acrs-query (acr-plan f :max-segmenti-serie 2 :max-segmenti-totali 5) 2 5)
       (acr-noeffects f))
     :version version
     :series (list (acr-serie 1 :closed (list (acr-closed 2) (acr-closed 3 :origin 2)))
                   (acr-serie 2 :closed (list (acr-closed 2 :origin 2)))))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-cardinality-before-segment-budgets
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dolist (pair (list (list #() (acr-fixture-closed f)) (list (acr-fixture-active f) #())))
         (destructuring-bind (active closed) pair
           (acrs-reject f 'invalid-argument :archive-csn-recovery-count
                        (lambda () (acrs-build f (acr-fixture-set f) active closed
                                              :max-segmenti-serie 0 :max-segmenti-totali 0))))))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D03-eq-uuid-duplicates
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (loop for first below 3 do
         (loop for second from (1+ first) below 4 do
           (let ((views (copy-seq (acr-fixture-views f))))
             (setf (aref views second) (aref views first))
             (acrs-reject f 'invalid-argument :archive-csn-series-duplicate (lambda () (acrs-set f views)))))))
     :version version :series (acrs-specs 4))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D11-owned-catalog-order
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dolist (order '(#(3 2 1 0) #(1 2 3 0) #(2 0 3 1)))
         (let* ((caller (acrs-permute (acr-fixture-views f) order)) (before (copy-seq caller))
                (active (acrs-permute (acr-fixture-active f) order))
                (closed (acrs-permute (acr-fixture-closed f) order))
                (set (acrs-set f caller :max-series 4 :budget-riferimenti 32)))
           (acrs-same-elements before caller)
           (fill caller nil)
           ;; Le verifiche EQ di ACTIVE attestano che la copia conserva anche l'ordine.
           (acrs-query (acrs-build f set active closed :max-segmenti-serie 0 :max-segmenti-totali 4) 4 4)
           (acrs-same-elements (acrs-permute (acr-fixture-active f) order) active)
           (acrs-same-elements (acrs-permute (acr-fixture-closed f) order) closed)
           (acr-noeffects f))))
     :version version :series (acrs-specs 4))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D11-plan-retains-only-archive-and-scalars
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((active (copy-seq (acr-fixture-active f))) (closed (copy-seq (acr-fixture-closed f)))
              (plan (acrs-build f (acr-fixture-set f) active closed))
              ;; Ispezione in sola lettura del risultato pubblico: nessun token sintetico.
              (slots (mapcar #'sb-mop:slot-definition-name (sb-mop:class-slots (class-of plan)))))
         (is (= 5 (length slots)))
         (is (null (set-exclusive-or slots '(ac::archive ac::series ac::segments ac::present ac::maximum))))
         (is (eq (slot-value plan 'ac::archive) (acr-fixture-archive f)))
         (dolist (slot '(ac::series ac::segments ac::present ac::maximum))
           (is (typep (slot-value plan slot) '(or boolean integer))))
         (fill active nil) (fill closed nil)
         (acrs-close-sources f)
         (acrs-query plan 2 2)
         (is (equal '(nil 0) (multiple-value-list (ac:massimo-csn-archivio plan))))
         (is (equal '(0 0) (multiple-value-list (ac:parole-base-csn-archivio plan))))
         (acr-noeffects f)))
     :version version :series (acrs-specs 2))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-ACR-D05-four-series-four-closed-exact
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (acrs-reject f 'resource-exhausted :archive-csn-segment-budget
                    (lambda () (acr-plan f :max-segmenti-serie 3 :max-segmenti-totali 20)))
       (acrs-reject f 'resource-exhausted :archive-csn-segment-budget
                    (lambda () (acr-plan f :max-segmenti-serie 4 :max-segmenti-totali 19)))
       (acrs-query (acr-plan f :max-segmenti-serie 4 :max-segmenti-totali 20) 4 20)
       (acr-noeffects f))
     :version version
     :series (loop for number from 1 to 4
                   collect (acr-serie number :closed (list (acr-closed 0) (acr-closed 2 :origin 2)
                                                          (acr-closed #x100000002)
                                                          (acr-closed #xffffffffffffffff :origin 2)))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-ARCHIVE-CSN-PREFLIGHT-count-and-budgets-before-capacity-gates
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       ;; Revoca intenzionale del caller: rende osservabile l'ordine senza FI globali.
       (io:chiudi (acr-fixture-decision-input f))
       (acr-clear f)
       (acrs-reject f 'invalid-argument :archive-csn-recovery-count
                    (lambda () (acrs-build f (acr-fixture-set f) #() (acr-fixture-closed f))))
       (dolist (budgets '((0 3) (1 2) (0 2)))
         (destructuring-bind (per-series total) budgets
           (acrs-reject f 'resource-exhausted :archive-csn-segment-budget
                        (lambda () (acr-plan f :max-segmenti-serie per-series :max-segmenti-totali total)))))
       ;; Con count e budget esatti si raggiunge il controllo della capacità DECISION.
       (let ((condition (acrs-reject f 'io-fault :io-unavailable
                                    (lambda () (acr-plan f :max-segmenti-serie 1 :max-segmenti-totali 3)))))
         (is (eq :input (arcdocdb.conditions:error-operation condition)))
         (is (zerop (arcdocdb.conditions:error-transferred condition))))
       (is (eq :closed (io:stato-file (acr-fixture-decision-input f))))
       (acr-noeffects f))
     :version version :series (list (acr-serie 1 :closed (list (acr-closed 2))) (acr-serie 2)))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D03-distinct-views-same-uuid
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (loop for first below 3 do
         (loop for second from (1+ first) below 4 do
           (let* ((views (copy-seq (acr-fixture-views f)))
                  (clone (acr-view (1+ first) (acr-fixture-scope f))))
             (is (not (eq clone (aref views first))))
             (is (not (eq (g::vista-get-serie-identity clone)
                          (g::vista-get-serie-identity (aref views first)))))
             (is (equalp (g::vista-get-serie-identity clone)
                         (g::vista-get-serie-identity (aref views first))))
             (setf (aref views second) clone)
             (acrs-reject f 'invalid-argument :archive-csn-series-duplicate (lambda () (acrs-set f views)))))))
     :version version :series (acrs-specs 4))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D03-registri-in-every-position
  (dolist (version '(1 2))
    (dotimes (position 4)
      (acr-with-fixture
       (lambda (f)
         (let* ((views (copy-seq (acr-fixture-views f)))
                (set (acrs-set f views :max-series 4 :budget-riferimenti 32)))
           (is (eq (acr-fixture-registri f) (aref views position)))
           (is (= 4 (ac:numero-serie-recovery set)))
           (acrs-query (acrs-build f set (acr-fixture-active f) (acr-fixture-closed f)) 4 4)
           (acr-noeffects f)))
       :version version :series (acrs-specs 4) :registri position))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D03-registri-absent-or-cloned
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((views (acr-fixture-views f)) (clone (acr-view 1 (acr-fixture-scope f)))
              (replacement (copy-seq views)))
         (is (not (eq clone (acr-fixture-registri f))))
         (is (equalp (g::vista-get-serie-identity clone)
                     (g::vista-get-serie-identity (acr-fixture-registri f))))
         (acrs-reject f 'invalid-argument :archive-csn-registri-missing
                      (lambda () (acrs-set f (subseq views 1))))
         (acrs-reject f 'invalid-argument :archive-csn-registri-missing
                      (lambda () (ac:crea-insieme-serie-recovery (acr-fixture-archive f) clone views)))
         (setf (aref replacement 0) clone)
         (acrs-reject f 'invalid-argument :archive-csn-registri-missing
                      (lambda () (acrs-set f replacement)))
         (is (= 3 (ac:numero-serie-recovery (acrs-set f views))))
         (acr-noeffects f)))
     :version version :series (acrs-specs 3))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-REC-002-ARCHIVE-CSN-SET-ACR-D11-owned-copy-survives-caller-mutation
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (let* ((caller (copy-seq (acr-fixture-views f))) (before (copy-seq caller))
              (set (acrs-set f caller :max-series 4 :budget-riferimenti 32)))
         (acrs-same-elements before caller)
         ;; Solo il vettore del chiamante cambia; viste e risultati canonici restano stabili.
         (fill caller nil)
         (is (= 4 (ac:numero-serie-recovery set)))
         (acrs-query (acrs-build f set (acr-fixture-active f) (acr-fixture-closed f)) 4 4)
         (replace caller (reverse before))
         (acrs-query (acrs-build f set (acr-fixture-active f) (acr-fixture-closed f)) 4 4)
         (acrs-same-elements before (acr-fixture-views f))
         (acr-noeffects f)))
     :version version :series (acrs-specs 4))))
