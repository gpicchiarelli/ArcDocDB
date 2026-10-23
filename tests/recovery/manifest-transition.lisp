;;;; CRV-D03..06: confronto puro, dopo manifest-audit; nessun I/O né manifest privato.
;;;; Metodo: EDIT/SEAL bytewise di manifest-support, oracle a liste, query pubbliche
;;;; prima/dopo successi e rifiuti. Le sole FI rilegano una query e la ripristinano.
;;; OWNER: ogni test possiede fixture e modelli; i manifest restano immutabili.
;;; SHARED: FI di query esclusivamente seriale nel runner recovery; nessun worker.
(in-package #:arcdocdb.recovery.tests)
(declaim (optimize (safety 3) (debug 2)))

(defun mt-read-history (specs version)
  "Ricostruzione pubblica da al più otto EDIT indipendenti, con budget finiti.
La fixture conserva manifest, oracle, buffer avvelenato e copia dei suoi byte."
  (is (<= (length specs) 8))
  (multiple-value-bind (buffer start end)
      (manifest-log-fixture (mapcar #'list specs) :version version)
    (let ((before (copy-seq buffer)) (model (manifest-oracle specs)))
      (is (<= (- end start) 4096))
      (multiple-value-bind (manifest prefix status)
          (manifest-fixture-read buffer start end :version version
            :max-bytes 4096 :max-batches 8 :max-batch-records 1 :max-batch-bytes 4096
            :max-search-bytes 4096 :max-edits 8 :max-segmenti 128 :max-esiti 256
            :max-chiusi-per-edit 16 :max-rimossi-per-edit 16 :max-esiti-per-edit 64
            :max-metadata-bytes 2048)
        (is (= end prefix)) (is (eq :complete status))
        (is (equalp before buffer))
        (assert-manifest-model manifest model)
        (fill buffer #xff)
        (assert-manifest-model manifest model)
        (list manifest model buffer (copy-seq buffer))))))

(defun mt-read-snapshot (spec version)
  "Un completo valido, sempre attraverso i byte e la ricostruzione pubblica."
  (mt-read-history (list spec) version))

(defun mt-before-spec ()
  "Snapshot con CLOSED vuoto/nonvuoto, CSN zero e parole u64 complete."
  (manifest-spec :completo t :next-id 100 :open 10
    :chiusi '((1 64 ((0 0) (7 17) (#x100000001 #x8000000000000007)
                     (#xffffffffffffffff #xffffffffffffffff)))
              (2 #xffffffff nil))
    :rimossi '(3 4)))

(defun mt-after-spec (previous &key (active (getf previous :next-id))
                                  (valid 128) (outcomes '((99 0))))
  "Checkpoint conservativo; lunghezza/esiti del vecchio ACTIVE sono fatti del caller."
  (manifest-spec :completo t
    :next-id (1+ (reduce #'max
                  (append (list active (getf previous :open))
                          (mapcar #'first (getf previous :chiusi)) (getf previous :rimossi))
                  :initial-value 0))
    :open active
    :chiusi (append (copy-tree (getf previous :chiusi))
                   (list (list (getf previous :open) valid (copy-tree outcomes))))
    :rimossi (copy-list (getf previous :rimossi))))

(defun mt-with-field (spec key value)
  "Una variante possiede la propria copia del fatto logico; non modifica il manifest."
  (let ((copy (copy-tree spec)))
    (setf (getf copy key) (copy-tree value))
    copy))

(defun mt-replace-closed (spec id replacement)
  "Sostituzione/omissione dichiarativa di un CLOSED nella sola fixture bytewise."
  (mt-with-field spec :chiusi
    (append (remove id (getf spec :chiusi) :key #'first :test #'eql)
            (when replacement (list replacement)))))

(defun mt-assert-pair (previous current)
  "Query scalari contro l'oracle, anche sugli ID dell'altro manifest ora sconosciuti."
  (dolist (pair (list (list previous current) (list current previous)))
    (let* ((fixture (first pair)) (other (second pair))
           (model (second fixture)) (rows (getf model :rows))
           (domain (remove-duplicates
                     (append '(0 1024 1025 #xffffffffffffffff)
                             (mapcar #'first (getf (second other) :rows))) :test #'eql))
           (unknown (remove-if (lambda (id) (assoc id rows)) domain)))
      (assert-manifest-model (first fixture) model unknown)
      (is (equalp (third fixture) (fourth fixture))))))

(defun mt-check (previous current &optional reason)
  "Un solo confronto pubblico: NIL esatto oppure tipo/reason/condizione originale.
Ogni uscita normale o rifiuto previsto conserva query e byte delle due fixture."
  (mt-assert-pair previous current)
  (let ((observed nil))
    (if reason
        (let ((condition
                (if (eq reason :recovery-segment-ids)
                    (signals resource-exhausted
                      (handler-bind ((resource-exhausted
                                       (lambda (caught) (setf observed caught))))
                        (arcdocdb.recovery.manifest:verifica-transizione-recovery
                          (first previous) (first current))) reason)
                    (signals invalid-argument
                      (handler-bind ((invalid-argument
                                       (lambda (caught) (setf observed caught))))
                        (arcdocdb.recovery.manifest:verifica-transizione-recovery
                          (first previous) (first current))) reason))))
          (is (eq observed condition))
          (is (null (error-offset condition))))
        (progn
          (is (equal '(nil) (multiple-value-list
                             (arcdocdb.recovery.manifest:verifica-transizione-recovery
                               (first previous) (first current)))))
          (is (null observed))))
    (mt-assert-pair previous current)))

(defun mt-generated-before (closed-count removed-count base)
  "Dominio finito: 0/1/3 CLOSED, 0/2 REMOVED, ID sotto/sopra i bit 32 e 63."
  (manifest-spec :completo t :next-id (+ base 64) :open (+ base 32)
    :chiusi (loop for i below closed-count collect
              (list (+ base i 1) (nth (mod i 3) '(64 65 #xffffffff))
                    (subseq '((0 0) (#x100000007 #x8000000000000007)
                              (#xffffffffffffffff #xffffffffffffffff))
                            0 (1+ (mod i 3)))))
    :rimossi (loop for i below removed-count collect (+ base 16 i))))

(defun mt-shape-mutants (previous current base)
  "Quattro variazioni: ACTIVE riusato, vecchio ACTIVE omesso, conteggi separati."
  (list
    (list (mt-with-field current :open (1- (getf previous :next-id))) :recovery-active-reused)
    (list (mt-replace-closed current (getf previous :open) (list (+ base 48) 128 '((99 0))))
          :recovery-active-not-closed)
    (list (mt-with-field current :chiusi
            (cons (list (+ base 48) 64 nil) (getf current :chiusi))) :recovery-segment-counts)
    (list (mt-with-field current :rimossi (cons (+ base 49) (getf current :rimossi)))
          :recovery-segment-counts)))

(defun mt-closed-mutants (previous current base)
  "Cinque variazioni di un solo CLOSED: lunghezza, count, presenza, CSN, ID."
  (let ((entry (first (getf previous :chiusi))))
    (when entry
      (destructuring-bind (id valid outcomes) entry
        (list
          (list (mt-replace-closed current id (list id (1+ valid) outcomes))
                :recovery-closed-changed)
          (list (mt-replace-closed current id (list id valid (rest outcomes)))
                :recovery-closed-changed)
          ;; L'esito assente restituisce CSN zero: la sola presenza è falsa.
          (list (mt-replace-closed current id (list id valid (cons '(1 0) (rest outcomes))))
                :recovery-outcome-changed)
          (list (mt-replace-closed current id (list id valid (cons '(0 1) (rest outcomes))))
                :recovery-outcome-changed)
          (list (mt-replace-closed current id (list (+ base 48) valid outcomes))
                :recovery-closed-changed))))))

(defun mt-removed-mutants (previous current base)
  "Stesso conteggio REMOVED: un ID precedente diventa UNKNOWN, uno nuovo lo sostituisce."
  (when (getf previous :rimossi)
    (list (list (mt-with-field current :rimossi
                  (cons (+ base 49) (rest (getf current :rimossi)))) :recovery-removed-changed))))

(defun mt-call-with-query-fault (name fault thunk)
  "FI privata seriale, nessun costruttore privato: ripristino anche per errori/nonlocal.
UNWIND-PROTECT rilascia soltanto la rilegatura; non cattura né converte condizioni."
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn
           (setf (fdefinition name)
                 (lambda (&rest arguments) (apply fault original arguments)))
           (funcall thunk))
      (setf (fdefinition name) original))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-all-true-v1-v2
  ;; CRV-D03..06 tutte vere; anche i due incroci di versione, non solo 1/1 e 2/2.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (versions '((1 1) (1 2) (2 1) (2 2)))
      (mt-check (mt-read-snapshot spec (first versions))
                (mt-read-snapshot next (second versions))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-empty-sets-authoritative-active-closure
  ;; La scansione dell'ACTIVE è una precondizione: il confronto accetta questi fatti.
  (let ((spec (manifest-spec :completo t :next-id 2 :open 1)))
    (dolist (version '(1 2))
      (dolist (valid '(64 #xffffffff))
        (dolist (outcomes '(nil ((0 0)) ((#xffffffffffffffff #xffffffffffffffff))))
          (mt-check (mt-read-snapshot spec version)
                    (mt-read-snapshot (mt-after-spec spec :valid valid :outcomes outcomes)
                                      version)))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-AFF-018-manifest-transition-highwater-equality-jump-and-full-u64
  ;; CRV-D06: uguaglianza e salti ammessi; confronto degli ID senza troncamenti.
  (dolist (version '(1 2))
    (dolist (highwater '(100 #x100000008 #x8000000000000008))
      (let* ((spec (mt-with-field (mt-before-spec) :next-id highwater))
             (previous (mt-read-snapshot spec version)))
        (dolist (jump '(0 1 17))
          (mt-check previous (mt-read-snapshot
                               (mt-after-spec spec :active (+ highwater jump)) version)))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-AFF-018-manifest-transition-active-reused-below-highwater
  (dolist (version '(1 2))
    (dolist (case '((100 99) (100 50) (#x100000008 8)
                    (#x8000000000000008 #x100000008)))
      (let* ((spec (mt-with-field (mt-before-spec) :next-id (first case)))
             (current (mt-after-spec spec :active (second case))))
        ;; Checkpoint valido indipendente: fallisce solo la relazione al vecchio high-water.
        (mt-check (mt-read-snapshot spec version) (mt-read-snapshot current version)
                  :recovery-active-reused)))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-AFF-018-manifest-transition-last-id-then-exhaustion
  (let* ((maximum #xffffffffffffffff)
         (initial (mt-with-field (mt-before-spec) :next-id maximum))
         (open-last (manifest-spec :open maximum :chiusi '((10 64 ((0 0)))))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot initial version))
            (current (mt-read-history (list initial open-last) version)))
        (is (equal (list t maximum)
                   (multiple-value-list
                     (arcdocdb.recovery.manifest:prossimo-id-segmento (first previous)))))
        (is (equal '(nil 0) (multiple-value-list
                             (arcdocdb.recovery.manifest:prossimo-id-segmento (first current)))))
        (mt-check previous current))
      ;; ID massimo CLOSED, ACTIVE o REMOVED: lo spazio rimane esaurito anche dopo la rimozione.
      (dolist (history
               (list (list initial (manifest-spec :chiusi (list (list maximum 64 nil))))
                     (list initial open-last)
                     (list initial (manifest-spec :chiusi (list (list maximum 64 nil)))
                           (manifest-spec :rimossi (list maximum)))))
        (let* ((old-active (getf (manifest-oracle history) :active))
               (next-history (append history
                               (list (manifest-spec :open 11
                                       :chiusi (list (list old-active 64 '((0 0))))))))
               (previous (mt-read-history history version))
               (current (mt-read-history next-history version)))
          (is (equal '(nil 0) (multiple-value-list
                               (arcdocdb.recovery.manifest:prossimo-id-segmento (first previous)))))
          (mt-check previous current :recovery-segment-ids))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-old-active-missing-or-removed
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (missing (mt-replace-closed next 10 '(6 128 ((99 0)))))
         (removed (mt-with-field missing :rimossi '(10 4))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (variant (list missing removed))
          (let ((current (mt-read-snapshot variant version)))
            ;; CRV-D05 vero: conteggi invariati per isolare la guardia sul vecchio ACTIVE.
            (is (= 3 (arcdocdb.recovery.manifest:numero-segmenti-chiusi (first current))))
            (is (= 2 (arcdocdb.recovery.manifest:numero-segmenti-rimossi (first current))))
            (mt-check previous current :recovery-active-not-closed)))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-old-active-still-active-and-self
  (dolist (version '(1 2))
    (let* ((spec (mt-before-spec)) (previous (mt-read-snapshot spec version))
           (same-state (mt-read-snapshot spec version)))
      ;; ACTIVE invariato: il primo motivo segnala riuso; tutte le entry restano intatte.
      (mt-check previous same-state :recovery-active-reused)
      (mt-check previous previous :recovery-active-reused))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-closed-length-only-false
  ;; CRV-D03: stato CLOSED e count veri; differisce soltanto la lunghezza.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (case '((1 65) (1 #xffffffff) (2 #xfffffffe)))
          (let* ((entry (assoc (first case) (getf spec :chiusi)))
                 (variant (mt-replace-closed next (first case)
                            (list (first case) (second case) (third entry)))))
            (mt-check previous (mt-read-snapshot variant version) :recovery-closed-changed)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-TXM-007-manifest-transition-closed-outcome-count-only-false
  ;; CRV-D03: stato/lunghezza veri, cardinalità globali invariate, count esiti più/meno uno.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (outcomes (third (assoc 1 (getf spec :chiusi)))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (changed (list (rest outcomes) (cons '(8 19) outcomes)))
          (mt-check previous
                    (mt-read-snapshot (mt-replace-closed next 1 (list 1 64 changed)) version)
                    :recovery-closed-changed))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-closed-state-and-same-count-replacement
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (replacement (mt-replace-closed next 1
                        (cons 6 (rest (assoc 1 (getf spec :chiusi)))))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (variant (list replacement (mt-with-field replacement :rimossi '(1 4))))
          ;; Checkpoint valido: ID 6 sostituisce ID 1 con identico numero di CLOSED.
          (mt-check previous (mt-read-snapshot variant version) :recovery-closed-changed))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-TXM-007-manifest-transition-zero-csn-present-versus-absent
  ;; CRV-D04: falsa solo la presenza, CSN restituito zero; count sempre quattro.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (outcomes (third (assoc 1 (getf spec :chiusi))))
         (variant (mt-replace-closed next 1 (list 1 64 (cons '(8 0) (rest outcomes))))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version))
            (current (mt-read-snapshot variant version)))
        (mt-check previous (mt-read-snapshot next version))
        (is (equal '(t 0) (multiple-value-list
                           (arcdocdb.recovery.manifest:trova-esito-chiusura (first previous) 1 0))))
        (is (equal '(nil 0) (multiple-value-list
                             (arcdocdb.recovery.manifest:trova-esito-chiusura (first current) 1 0))))
        (mt-check previous current :recovery-outcome-changed)))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-TXM-007-manifest-transition-csn-only-false-full-u64
  ;; CRV-D04: presenza vera; le ultime due varianti cambiano soltanto i bit alti del CSN.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (outcomes (third (assoc 1 (getf spec :chiusi)))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (case '((0 1) (7 18) (#x100000001 7) (#xffffffffffffffff #xffffffff)))
          (let ((changed (copy-tree outcomes)))
            (setf (second (assoc (first case) changed)) (second case))
            (mt-check previous
                      (mt-read-snapshot (mt-replace-closed next 1 (list 1 64 changed)) version)
                      :recovery-outcome-changed)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-TXM-007-manifest-transition-txid-full-u64-same-count-replacement
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (outcomes (third (assoc 1 (getf spec :chiusi)))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (case '((#x100000001 1) (#xffffffffffffffff #xffffffff)))
          (let ((changed (copy-tree outcomes)))
            (setf (first (assoc (first case) changed)) (second case))
            (mt-check previous
                      (mt-read-snapshot (mt-replace-closed next 1 (list 1 64 changed)) version)
                      :recovery-outcome-changed)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-TXM-007-manifest-transition-outcome-order-and-identical-duplicates
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)) (variant (copy-tree next)))
    (setf (getf variant :chiusi)
          (loop for entry in (reverse (getf next :chiusi)) collect
            (list (first entry) (second entry)
                  (append (reverse (copy-tree (third entry))) (copy-tree (third entry)))))
          (getf variant :rimossi) '(4 3 4 3))
    (dolist (version '(1 2))
      (mt-check (mt-read-snapshot spec version) (mt-read-snapshot variant version)))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-closed-cardinality-only-false
  ;; CRV-D05: REMOVED uguale; CLOSED più due (inclusione vera) o più zero (omissione).
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (variant (list (mt-with-field next :chiusi
                                 (cons '(6 64 nil) (getf next :chiusi)))
                               (mt-replace-closed next 2 nil)))
          (mt-check previous (mt-read-snapshot variant version) :recovery-segment-counts))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-removed-cardinality-only-false
  ;; CRV-D05: CLOSED precedente più uno vero; cambia solo il conteggio REMOVED, nei due sensi.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (dolist (removed '((3 4 6) (3) nil))
          (mt-check previous (mt-read-snapshot (mt-with-field next :rimossi removed) version)
                    :recovery-segment-counts))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-removed-same-count-replacement
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)))
        (mt-check previous (mt-read-snapshot next version))
        (dolist (removed '((6 4) (3 6)))
          (mt-check previous (mt-read-snapshot (mt-with-field next :rimossi removed) version)
                    :recovery-removed-changed))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-AFF-018-manifest-transition-public-queries-immutable-on-repeated-results
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (bad (mt-replace-closed next 2 '(2 64 nil))))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version))
            (current (mt-read-snapshot next version)) (rejected (mt-read-snapshot bad version)))
        (loop repeat 3 do
          (mt-check previous current)
          (mt-check previous rejected :recovery-closed-changed)
          (mt-check previous current))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-bounded-generative-matrix
  ;; 2 versioni * 3 CLOSED * 2 REMOVED * 3 basi u64 * 2 salti = 72 casi positivi.
  ;; 4 varianti di forma ciascuno, 5 CLOSED per 48 casi, 1 REMOVED per 36: 564 negativi.
  (let ((accepted 0) (rejected 0))
    (dolist (version '(1 2))
      (dolist (closed-count '(0 1 3))
        (dolist (removed-count '(0 2))
          (dolist (base '(0 #x100000000 #x8000000000000000))
            (dolist (jump '(0 7))
              (let* ((spec (mt-generated-before closed-count removed-count base))
                     (next (mt-after-spec spec :active (+ (getf spec :next-id) jump)))
                     (previous (mt-read-snapshot spec version)))
                (mt-check previous (mt-read-snapshot next version)) (incf accepted)
                (dolist (case (append (mt-shape-mutants spec next base)
                                     (mt-closed-mutants spec next base)
                                     (mt-removed-mutants spec next base)))
                  (mt-check previous (mt-read-snapshot (first case) version) (second case))
                  (incf rejected))))))))
    (is (= 72 accepted)) (is (= 564 rejected))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-REC-001-manifest-transition-private-fi-closed-state-only-false
  ;; CRV-D03 solo stato: impossibile con checkpoint valido (fuori CLOSED, lunghezza zero).
  ;; FI distinta: stato forgiato, lunghezza/count originali conservati; nessun manifest privato.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec))
         (name 'arcdocdb.recovery.manifest:trova-segmento))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)) (current (mt-read-snapshot next version)))
        (dolist (fault-state '(:unknown :removed :active))
          (let ((hits 0) (original (fdefinition name)))
            (mt-check previous current)
            (signals invalid-argument
              (mt-call-with-query-fault name
                (lambda (query manifest id)
                  (multiple-value-bind (state size count) (funcall query manifest id)
                    (if (and (eq manifest (first current)) (= id 1))
                        (progn (incf hits) (is (eq :closed state)) (is (= 64 size))
                               (is (= 4 count)) (values fault-state size count))
                        (values state size count))))
                (lambda () (arcdocdb.recovery.manifest:verifica-transizione-recovery
                             (first previous) (first current)))) :recovery-closed-changed)
            (is (= 1 hits)) (is (eq original (fdefinition name)))
            (mt-check previous current)))))))

;;; REQ: REQ-REC-001 REQ-AFF-018 REQ-AFF-004
(deftest test-REQ-AFF-004-manifest-transition-private-fi-original-condition-preserved
  ;; Propagazione dalla seconda lettura del high-water e dalla query di un esito.
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)) (current (mt-read-snapshot next version)))
        (dolist (case '((arcdocdb.recovery.manifest:prossimo-id-segmento 2)
                        (arcdocdb.recovery.manifest:trova-esito-chiusura 1)))
          (let* ((name (first case)) (ordinal (second case)) (calls 0)
                 (query (fdefinition name))
                 (original (make-condition 'corruption-detected
                             :reason :manifest-transition-fi-original :offset 1234))
                 (caught
                   (signals corruption-detected
                     (mt-call-with-query-fault name
                       (lambda (saved &rest arguments)
                         (incf calls)
                         (if (= calls ordinal) (error original) (apply saved arguments)))
                       (lambda () (arcdocdb.recovery.manifest:verifica-transizione-recovery
                                    (first previous) (first current))))
                     :manifest-transition-fi-original)))
            (is (eq original caught)) (is (= 1234 (error-offset caught)))
            (is (= ordinal calls)) (is (eq query (fdefinition name)))
            (mt-check previous current)))))))

;;; REQ: REQ-REC-001 REQ-AFF-018 REQ-AFF-004
(deftest test-REQ-AFF-004-manifest-transition-private-fi-nonlocal-preserved
  (let* ((spec (mt-before-spec)) (next (mt-after-spec spec)))
    (dolist (version '(1 2))
      (let ((previous (mt-read-snapshot spec version)) (current (mt-read-snapshot next version)))
        (dolist (case '((arcdocdb.recovery.manifest:prossimo-id-segmento 2)
                        (arcdocdb.recovery.manifest:trova-esito-chiusura 1)))
          (let* ((name (first case)) (ordinal (second case)) (calls 0)
                 (query (fdefinition name)) (marker (list :manifest-transition-nonlocal)))
            (is (eq marker
                    (block escaped
                      (mt-call-with-query-fault name
                        (lambda (saved &rest arguments)
                          (incf calls)
                          (if (= calls ordinal) (return-from escaped marker)
                              (apply saved arguments)))
                        (lambda () (arcdocdb.recovery.manifest:verifica-transizione-recovery
                                     (first previous) (first current))))
                      :unexpected-return)))
            (is (= ordinal calls)) (is (eq query (fdefinition name)))
            (mt-check previous current)))))))
